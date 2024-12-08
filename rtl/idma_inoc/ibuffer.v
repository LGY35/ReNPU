
// 双端口ibuffer，用于处理两组读写操作（分别通过端口 a 和 b）对共享sram进行访问。

module ibuffer (
    input clk,
    input rst_n,
    // port a
    input           cen_a,  // 使能信号，控制是否允许端口 a 访问内存。
    input           last_a,
    output          ready_a,
    input           wen_a,
    input [14:0]    addr_a,
    input [127:0]   wdata_a,
    input [15:0]    wstrb_a,
    output[127:0]   rdata_a,
    output          rvalid_a,
    output          rlast_a,    //端口 a 的最后一个读周期
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

genvar i;
wire [23:0] bank_cen;
wire [23:0] bank_wen;
wire [9:0]  bank_addr [23:0];
wire [127:0] bank_wdata [23:0];
wire [15:0] bank_wstrb [23:0];
wire [127:0] bank_rdata [23:0];

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

reg gnt_a_or_b; // 0 gnt a; 1 gnt b  // 0 gnt a; 1 gnt b  对端口 a 和 b 的仲裁，确保在同一个时钟周期内不会同时对相同的内存块进行操作。
wire gnt_a;
wire gnt_b;
wire [9:0] bank_addr_a = addr_a[9:0];
wire [9:0] bank_addr_b = addr_b[9:0];
wire [4:0] bank_sel_a = addr_a[14:10];
wire [4:0] bank_sel_b = addr_b[14:10];
wire bank_cen_a = cen_a && ready_a;
wire bank_cen_b = cen_b && ready_b;
wire [127:0] rdata_a_stage1;
wire [127:0] rdata_b_stage1;


// ========================================
// 采用流水方式进行读写
// ========================================


// ========================================
// Stage 0    端口仲裁逻辑
// ========================================

// arbit a/b request
always @(posedge clk or negedge rst_n) begin
    if (rst_n==1'b0) begin
        gnt_a_or_b <= 1'b0;
    end
    else if(gnt_a_or_b==1'b0 && bank_cen_a) begin    // bank_cen_a 表示端口 a 有访问请求
        gnt_a_or_b <= 1'b1;                          // 那么下一个周期给b    
    end
    else if(gnt_a_or_b==1'b1 && bank_cen_b) begin
        gnt_a_or_b <= 1'b0;
    end
end

assign gnt_a = (~cen_b || (gnt_a_or_b==1'b0) || (gnt_a_or_b==1'b1 && bank_sel_a!=bank_sel_b));
assign gnt_b = (~cen_a || (gnt_a_or_b==1'b1) || (gnt_a_or_b==1'b0 && bank_sel_a!=bank_sel_b));

// assign ready_a = sel_ready_pipe_a[0]
assign ready_a = (rready_a || wen_a) && gnt_a; // 只有当端口 a 已经准备好进行下一次读操作（rready_a 为高）或执行写操作（wen_a 为高），且端口 a 获得优先权（gnt_a 为高）时，ready_a 才会为高。
// assign ready_a = ((rready_a && !sel_valid_pipe_a[1]) || wen_a) && gnt_a;

// assign ready_b = sel_ready_pipe_b[0]
assign ready_b = (rready_b || wen_b) && gnt_b;
// assign ready_b = ((rready_b && !sel_valid_pipe_b[1]) || wen_b) && gnt_b;

// pipe stage 0 signals
assign sel_valid_pipe_a[0] = cen_a && ~wen_a && ready_a;    //端口 a 选择了一个有效的读操作，条件是端口 a 被使能（cen_a 为高）、不是写操作（~wen_a 为高），并且端口 a 已经准备好（ready_a 为高）
assign sel_valid_pipe_b[0] = cen_b && ~wen_b && ready_b;
assign sel_pipe_a[0] = bank_sel_a;  // 端口 a 和 b 访问的 bank 选择信号
assign sel_pipe_b[0] = bank_sel_b;

assign last_valid_pipe_a[0] = sel_valid_pipe_a[0];  //两个信号 跟踪端口 a 在传输过程中是否是最后一个读周期的信息。last_a 是传入的信号，用来表明这次操作是否是最后一个周期。
assign last_pipe_a[0] = last_a;


// ========================================
// Stage 1
// ========================================

//通过 generate 语句生成多个存储单元实例，每个存储单元与一个 bank 对应，并为每个 bank 分配不同的控制信号（使能、写使能、地址、数据等）。
generate
    for(i=0; i<24; i=i+1) begin: BANK  // BANK 是一个命名块，便于组织和引用生成的硬件。

        assign bank_cen[i] = ((bank_cen_a && (bank_sel_a==i)) 
                           || (bank_cen_b && (bank_sel_b==i)));
        assign bank_wen[i] = (bank_cen_a & wen_a) 
                           | (bank_cen_b & wen_b);
        assign bank_addr[i]= ({10{bank_cen_a && (bank_sel_a==i)}} & bank_addr_a) 
                           | ({10{bank_cen_b && (bank_sel_b==i)}} & bank_addr_b);
        assign bank_wdata[i]= ({128{bank_cen_a}} & wdata_a) 
                            | ({128{bank_cen_b}} & wdata_b);
        assign bank_wstrb[i]= ({16{bank_cen_a}} & wstrb_a) 
                            | ({16{bank_cen_b}} & wstrb_b);

        sram_1024x128b u_sram_1024x128b(
            .clk(clk),
            .cen(bank_cen[i]),
            .wen(bank_wen[i]),
            .addr(bank_addr[i]),
            .wdata(bank_wdata[i]),
            .wstrb(bank_wstrb[i]),
            .rdata(bank_rdata[i])
        );
    end
endgenerate

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

assign rdata_a_stage1 =   ({128{sel_pipe_a[1]==5'd0}}  & bank_rdata[0]) 
                        | ({128{sel_pipe_a[1]==5'd1}}  & bank_rdata[1])
                        | ({128{sel_pipe_a[1]==5'd2}}  & bank_rdata[2])
                        | ({128{sel_pipe_a[1]==5'd3}}  & bank_rdata[3])
                        | ({128{sel_pipe_a[1]==5'd4}}  & bank_rdata[4])
                        | ({128{sel_pipe_a[1]==5'd5}}  & bank_rdata[5])
                        | ({128{sel_pipe_a[1]==5'd6}}  & bank_rdata[6])
                        | ({128{sel_pipe_a[1]==5'd7}}  & bank_rdata[7])
                        | ({128{sel_pipe_a[1]==5'd8}}  & bank_rdata[8])
                        | ({128{sel_pipe_a[1]==5'd9}}  & bank_rdata[9])
                        | ({128{sel_pipe_a[1]==5'd10}} & bank_rdata[10])
                        | ({128{sel_pipe_a[1]==5'd11}} & bank_rdata[11])
                        | ({128{sel_pipe_a[1]==5'd12}} & bank_rdata[12])
                        | ({128{sel_pipe_a[1]==5'd13}} & bank_rdata[13])
                        | ({128{sel_pipe_a[1]==5'd14}} & bank_rdata[14])
                        | ({128{sel_pipe_a[1]==5'd15}} & bank_rdata[15])
                        | ({128{sel_pipe_a[1]==5'd16}} & bank_rdata[16])
                        | ({128{sel_pipe_a[1]==5'd17}} & bank_rdata[17])
                        | ({128{sel_pipe_a[1]==5'd18}} & bank_rdata[18])
                        | ({128{sel_pipe_a[1]==5'd19}} & bank_rdata[19])
                        | ({128{sel_pipe_a[1]==5'd20}} & bank_rdata[20])
                        | ({128{sel_pipe_a[1]==5'd21}} & bank_rdata[21])
                        | ({128{sel_pipe_a[1]==5'd22}} & bank_rdata[22])
                        | ({128{sel_pipe_a[1]==5'd23}} & bank_rdata[23])
                        ;

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

assign rdata_b_stage1 =   ({128{sel_pipe_b[1]==5'd0}}  & bank_rdata[0]) 
                        | ({128{sel_pipe_b[1]==5'd1}}  & bank_rdata[1])
                        | ({128{sel_pipe_b[1]==5'd2}}  & bank_rdata[2])
                        | ({128{sel_pipe_b[1]==5'd3}}  & bank_rdata[3])
                        | ({128{sel_pipe_b[1]==5'd4}}  & bank_rdata[4])
                        | ({128{sel_pipe_b[1]==5'd5}}  & bank_rdata[5])
                        | ({128{sel_pipe_b[1]==5'd6}}  & bank_rdata[6])
                        | ({128{sel_pipe_b[1]==5'd7}}  & bank_rdata[7])
                        | ({128{sel_pipe_b[1]==5'd8}}  & bank_rdata[8])
                        | ({128{sel_pipe_b[1]==5'd9}}  & bank_rdata[9])
                        | ({128{sel_pipe_b[1]==5'd10}} & bank_rdata[10])
                        | ({128{sel_pipe_b[1]==5'd11}} & bank_rdata[11])
                        | ({128{sel_pipe_b[1]==5'd12}} & bank_rdata[12])
                        | ({128{sel_pipe_b[1]==5'd13}} & bank_rdata[13])
                        | ({128{sel_pipe_b[1]==5'd14}} & bank_rdata[14])
                        | ({128{sel_pipe_b[1]==5'd15}} & bank_rdata[15])
                        | ({128{sel_pipe_b[1]==5'd16}} & bank_rdata[16])
                        | ({128{sel_pipe_b[1]==5'd17}} & bank_rdata[17])
                        | ({128{sel_pipe_b[1]==5'd18}} & bank_rdata[18])
                        | ({128{sel_pipe_b[1]==5'd19}} & bank_rdata[19])
                        | ({128{sel_pipe_b[1]==5'd20}} & bank_rdata[20])
                        | ({128{sel_pipe_b[1]==5'd21}} & bank_rdata[21])
                        | ({128{sel_pipe_b[1]==5'd22}} & bank_rdata[22])
                        | ({128{sel_pipe_b[1]==5'd23}} & bank_rdata[23])
                        ;

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
