module fifo_sync_sram #(
    parameter FIFO_WIDTH = 64 ,  
    parameter FIFO_DEPTH = 64  ,    
    parameter FIFO_CNT_WID = 6+1    //ceil[log2 (FIFO_DEPTH) + 1]
    )(
    input                           clk             ,
    input                           rst_n           ,
    input                           fifo_pop        ,
    output     [FIFO_WIDTH-1: 0]    fifo_data_out   ,
    output                          fifo_empty      ,
    input                           fifo_push       ,
    output                          fifo_full       ,
    output                          fifo_afull      ,
    input      [FIFO_WIDTH-1: 0]    fifo_data_in    ,
    output reg [FIFO_CNT_WID-1:0]   fifo_word_cnt   ,
    input                           fifo_init       ,
    output                          sram_re,
    output                          sram_we,
    output     [FIFO_CNT_WID-2: 0]  sram_raddr,
    output     [FIFO_CNT_WID-2: 0]  sram_waddr,
    output     [FIFO_WIDTH-1: 0]    sram_wdata,
    input      [FIFO_WIDTH-1: 0]    sram_rdata   
);

reg [FIFO_CNT_WID-1:0] read_ptr;
reg [FIFO_CNT_WID-1:0] write_ptr;
wire empty =   (read_ptr==write_ptr);
wire full  =   (read_ptr[FIFO_CNT_WID-1]!=write_ptr[FIFO_CNT_WID-1]) 
            && (read_ptr[FIFO_CNT_WID-2]==write_ptr[FIFO_CNT_WID-2]);

reg sram_rvalid;
wire sram_rvalid_pipe [2:0];
wire sram_rready_pipe [2:0];
wire [FIFO_WIDTH-1:0] sram_rdata_pipe [2:0];

// read pointer
always @(posedge clk or negedge rst_n) begin
    if (rst_n==1'b0) begin
        read_ptr <= {FIFO_CNT_WID{1'b0}};
    end
    else if (fifo_init) begin
        read_ptr <= {FIFO_CNT_WID{1'b0}};
    end
    else if(sram_re) begin
        read_ptr <= read_ptr + 1;
    end
end

// write pointer
always @(posedge clk or negedge rst_n) begin
    if (rst_n==1'b0) begin
        write_ptr <= {FIFO_CNT_WID{1'b0}};
    end
    else if (fifo_init) begin
        write_ptr <= {FIFO_CNT_WID{1'b0}};
    end
    else if(sram_we) begin
        write_ptr <= write_ptr + 1;
    end
end

// count data in fifo
always @(posedge clk or negedge rst_n) begin
    if (rst_n==1'b0) begin
        fifo_word_cnt <= {FIFO_CNT_WID{1'b0}};
    end
    else if(sram_we) begin
        fifo_word_cnt <= fifo_word_cnt + 1;
    end
    else if(sram_re) begin
        fifo_word_cnt <= fifo_word_cnt - 1;
    end
end


// sram rdata is valid
always @(posedge clk or negedge rst_n) begin
    if (rst_n==1'b0) begin
        sram_rvalid <= 1'b0;
    end
    else begin
        sram_rvalid <= sram_re;
    end
end


assign sram_rvalid_pipe[0] = sram_rvalid;
assign sram_rdata_pipe[0]  = sram_rdata;
fwdbwd_pipe #(
    .DATA_W(FIFO_WIDTH)
) u_sram_rdata_pipe_stage1(
    .clk(clk),
    .rst_n(rst_n),
    .f_valid_in(sram_rvalid_pipe[0]),
    .f_data_in(sram_rdata_pipe[0]),
    .f_ready_out(sram_rready_pipe[0]),
    .b_valid_out(sram_rvalid_pipe[1]),
    .b_data_out(sram_rdata_pipe[1]),
    .b_ready_in(sram_rready_pipe[1])
);

fwd_pipe #(
    .DATA_W(FIFO_WIDTH)
) u_sram_rdata_pipe_stage2(
    .clk(clk),
    .rst_n(rst_n),
    .f_valid_in(sram_rvalid_pipe[1]),
    .f_data_in(sram_rdata_pipe[1]),
    .f_ready_out(sram_rready_pipe[1]),
    .b_valid_out(sram_rvalid_pipe[2]),
    .b_data_out(sram_rdata_pipe[2]),
    .b_ready_in(sram_rready_pipe[2])
);
assign sram_rready_pipe[2] = fifo_pop;

// output
assign fifo_data_out = sram_rdata_pipe[2];
assign fifo_empty = !sram_rvalid_pipe[2];
assign fifo_full  = full;
assign fifo_afull = (fifo_word_cnt==(FIFO_DEPTH[FIFO_CNT_WID-1:0]-2));
assign sram_re = !empty && !sram_we && sram_rready_pipe[1];
assign sram_we = fifo_push;
assign sram_raddr = read_ptr[FIFO_CNT_WID-2:0];
assign sram_waddr = write_ptr[FIFO_CNT_WID-2:0];
assign sram_wdata = fifo_data_in;


endmodule