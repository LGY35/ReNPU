module ibuffer_single_sram (
    input clk,
    input rst_n,
    // port a
    input           cen_a,
    input           last_a,
    output          ready_a,
    input           wen_a,
    input [14:0]    addr_a,
    input [127:0]   wdata_a,
    input [15:0]    wstrb_a,
    output[127:0]   rdata_a,
    output          rvalid_a,
    output          rlast_a,
    input           rready_a,
    // port b
    input           cen_b,
    input           wen_b,
    output          ready_b,
    input [14:0]    addr_b,
    input [127:0]   wdata_b,
    input [15:0]    wstrb_b,
    output reg [127:0] rdata_b,
    output          rvalid_b,
    input           rready_b
);


wire bank_cen;
wire bank_wen;
wire [14:0]  bank_addr;
wire [127:0] bank_wdata;
wire [15:0]  bank_wstrb;
wire [127:0] bank_rdata;

wire [4:0] sel_pipe_a [1:0];
wire       sel_valid_pipe_a [1:0];
wire       sel_ready_pipe_a [1:0];
wire [4:0] sel_pipe_b [1:0];
wire       sel_valid_pipe_b [1:0];
wire       sel_ready_pipe_b [1:0];

wire       last_pipe_a [2:0];
wire       last_valid_pipe_a [2:0];
wire       last_ready_pipe_a [2:0];

wire [127:0] rdata_pipe_a [1:0];
wire       rdata_valid_pipe_a [1:0];
wire       rdata_ready_pipe_a [1:0];
wire [127:0] rdata_pipe_b [1:0];
wire       rdata_valid_pipe_b [1:0];
wire       rdata_ready_pipe_b [1:0];

reg gnt_a_or_b; // 0 gnt a; 1 gnt b
wire gnt_a;
wire gnt_b;
wire bank_cen_a = cen_a && ready_a;
wire bank_cen_b = cen_b && ready_b;
wire [127:0] rdata_a_stage1;
wire [127:0] rdata_b_stage1;

// ========================================
// Stage 0
// ========================================

// arbit a/b request
always @(posedge clk or negedge rst_n) begin
    if (rst_n==1'b0) begin
        gnt_a_or_b <= 1'b0;
    end
    else if(gnt_a_or_b==1'b0 && bank_cen_a) begin
        gnt_a_or_b <= 1'b1;
    end
    else if(gnt_a_or_b==1'b1 && bank_cen_b) begin
        gnt_a_or_b <= 1'b0;
    end
end

assign gnt_a = ~cen_b || (gnt_a_or_b==1'b0);
assign gnt_b = ~cen_a || (gnt_a_or_b==1'b1);

assign ready_a = (rready_a || wen_a) && gnt_a;
assign ready_b = (rready_b || wen_b) && gnt_b;


// pipe stage 0 signals
assign sel_valid_pipe_a[0] = cen_a && ~wen_a && ready_a;
assign sel_valid_pipe_b[0] = cen_b && ~wen_b && ready_b;
assign sel_pipe_a[0] = addr_a[14:10];
assign sel_pipe_b[0] = addr_b[14:10];

assign last_valid_pipe_a[0] = sel_valid_pipe_a[0];
assign last_pipe_a[0] = last_a;


// ========================================
// Stage 1
// ========================================
assign bank_cen = bank_cen_a || bank_cen_b;
assign bank_wen = (bank_cen_a & wen_a) || (bank_cen_b & wen_b);
assign bank_addr = ({10{bank_cen_a}} & addr_a) 
                 | ({10{bank_cen_b}} & addr_b);
assign bank_wdata = ({128{bank_cen_a}} & wdata_a) 
                  | ({128{bank_cen_b}} & wdata_b);
assign bank_wstrb = ({16{bank_cen_a}} & wstrb_a) 
                  | ({16{bank_cen_b}} & wstrb_b);
sram_128b #(
    .DEPTH(1024*24),
    .ADDR_W(10+5)
)
u_sram_128b(
    .clk(clk),
    .cen(bank_cen),
    .wen(bank_wen),
    .addr(bank_addr),
    .wdata(bank_wdata),
    .wstrb(bank_wstrb),
    .rdata(bank_rdata)
);


// select rdata from banks
fwd_pipe #(
    .DATA_W(5)
) u_addr_sel_pipe_a(
    .clk(clk),
    .rst_n(rst_n),
    .f_valid_in(sel_valid_pipe_a[0]),
    .f_data_in(sel_pipe_a[0]),
    .f_ready_out(sel_ready_pipe_a[0]),
    .b_valid_out(sel_valid_pipe_a[1]),
    .b_data_out(sel_pipe_a[1]),
    .b_ready_in(sel_ready_pipe_a[1])
);
assign sel_ready_pipe_a[1] = rdata_ready_pipe_a[0];

assign rdata_a_stage1 = bank_rdata;

fwd_pipe #(
    .DATA_W(5)
) u_addr_sel_pipe_b(
    .clk(clk),
    .rst_n(rst_n),
    .f_valid_in(sel_valid_pipe_b[0]),
    .f_data_in(sel_pipe_b[0]),
    .f_ready_out(sel_ready_pipe_b[0]),
    .b_valid_out(sel_valid_pipe_b[1]),
    .b_data_out(sel_pipe_b[1]),
    .b_ready_in(sel_ready_pipe_b[1])
);
assign sel_ready_pipe_b[1] = rdata_ready_pipe_b[0];

assign rdata_b_stage1 = bank_rdata;

// last flow with pipe
fwd_pipe #(
    .DATA_W(1)
) u_last_a_pipe_stage1(
    .clk(clk),
    .rst_n(rst_n),
    .f_valid_in(last_valid_pipe_a[0]),
    .f_data_in(last_pipe_a[0]),
    .f_ready_out(last_ready_pipe_a[0]),
    .b_valid_out(last_valid_pipe_a[1]),
    .b_data_out(last_pipe_a[1]),
    .b_ready_in(last_ready_pipe_a[1])
);
assign last_ready_pipe_a[1] = rdata_ready_pipe_a[0];

// ========================================
// Stage 2
// ========================================

assign rdata_valid_pipe_a[0] = sel_valid_pipe_a[1];
assign rdata_pipe_a[0] = rdata_a_stage1;
assign rdata_valid_pipe_b[0] = sel_valid_pipe_b[1];
assign rdata_pipe_b[0] = rdata_b_stage1;

// rdata pipe stage
fwdbwd_pipe #(
// fwd_pipe #(
    .DATA_W(128)
) u_rdata_pipe_a(
    .clk(clk),
    .rst_n(rst_n),
    .f_valid_in(rdata_valid_pipe_a[0]),
    .f_data_in(rdata_pipe_a[0]),
    .f_ready_out(rdata_ready_pipe_a[0]),
    .b_valid_out(rdata_valid_pipe_a[1]),
    .b_data_out(rdata_pipe_a[1]),
    .b_ready_in(rdata_ready_pipe_a[1])
);
assign rdata_ready_pipe_a[1] = rready_a;

fwdbwd_pipe #(
// fwd_pipe #(
    .DATA_W(128)
) u_rdata_pipe_b(
    .clk(clk),
    .rst_n(rst_n),
    .f_valid_in(rdata_valid_pipe_b[0]),
    .f_data_in(rdata_pipe_b[0]),
    .f_ready_out(rdata_ready_pipe_b[0]),
    .b_valid_out(rdata_valid_pipe_b[1]),
    .b_data_out(rdata_pipe_b[1]),
    .b_ready_in(rdata_ready_pipe_b[1])
);
assign rdata_ready_pipe_b[1] = rready_b;

// rlast pipe
fwdbwd_pipe #(
// fwd_pipe #(
    .DATA_W(1)
) u_last_a_pipe_stage2(
    .clk(clk),
    .rst_n(rst_n),
    .f_valid_in(last_valid_pipe_a[1]),
    .f_data_in(last_pipe_a[1]),
    .f_ready_out(last_ready_pipe_a[1]),
    .b_valid_out(last_valid_pipe_a[2]),
    .b_data_out(last_pipe_a[2]),
    .b_ready_in(last_ready_pipe_a[2])
);
assign last_ready_pipe_a[2] = rready_a;

// ========================================
// Output
// ========================================
assign rvalid_a = rdata_valid_pipe_a[1];
assign rdata_a  = rdata_pipe_a[1];
assign rvalid_b = rdata_valid_pipe_b[1];
assign rdata_b  = rdata_pipe_b[1];
assign rlast_a  = last_pipe_a[2];
endmodule
