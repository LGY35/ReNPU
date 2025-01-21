module idma_write_ibuffer
#(
    parameter DATA_WIDTH = 128,
    parameter MEM_AW = 15,
    parameter STRB_WIDTH = (DATA_WIDTH/8)
    
) 
(   
    input clk,
    input rst_n,
    // config
    input  [MEM_AW-1:0]    dma_rd_data_num,

    // dma port
    input                  dma_rd_req,
    input                  dma_rd_data_valid,
    input [DATA_WIDTH-1:0] dma_rd_data,
    output                 dma_rd_data_ready,
    input [STRB_WIDTH-1:0] dma_rd_strb,
    output                 dma_write_done,

    // ibuffer port
    output                 ibuffer_cen,
    output                 ibuffer_wen,
    input                  ibuffer_ready,
    output[MEM_AW-1:0]     ibuffer_addr,
    output[DATA_WIDTH-1:0] ibuffer_wdata,
    output[STRB_WIDTH-1:0] ibuffer_strb
);

wire dma_rd_handshake;
wire dma_read_done;

reg [MEM_AW-1:0] rd_data_cnt;
reg [MEM_AW-1:0] wr_data_cnt;

wire ibuffer_cen_pipe [1:0];
wire ibuffer_wen_pipe [1:0];
wire ibuffer_ready_pipe [1:0];
wire [MEM_AW-1:0] ibuffer_addr_pipe [1:0];
wire [DATA_WIDTH-1:0] ibuffer_wdata_pipe [1:0];
wire [STRB_WIDTH-1:0] ibuffer_strb_pipe [1:0];
wire ibuffer_wr_handshake;

// ===================================
// Stage 0
// ===================================

assign dma_rd_handshake = dma_rd_data_valid && dma_rd_data_ready;
assign dma_read_done = (rd_data_cnt==dma_rd_data_num-1) && dma_rd_handshake;

always @(posedge clk or negedge rst_n) begin
    if (rst_n==1'b0) begin
        rd_data_cnt <= {MEM_AW{1'b0}};
    end
    else if(dma_read_done) begin
        rd_data_cnt <= {MEM_AW{1'b0}};
    end
    else if(dma_rd_handshake) begin
        rd_data_cnt <= rd_data_cnt + 1;
    end
end

assign ibuffer_cen_pipe[0] = dma_rd_data_valid;
assign dma_rd_data_ready = ibuffer_ready_pipe[0];
assign ibuffer_wen_pipe[0] = 1'b1;
assign ibuffer_addr_pipe[0] = rd_data_cnt;
assign ibuffer_wdata_pipe[0] = dma_rd_data;
assign ibuffer_strb_pipe[0]  = dma_rd_strb;

// ===================================
// Stage 1
// ===================================

assign ibuffer_wr_handshake = ibuffer_cen && ibuffer_ready;
assign dma_write_done = (wr_data_cnt==dma_rd_data_num-1) && ibuffer_wr_handshake;

always @(posedge clk or negedge rst_n) begin
    if (rst_n==1'b0) begin
        wr_data_cnt <= {MEM_AW{1'b0}};
    end
    else if(dma_write_done) begin
        wr_data_cnt <= {MEM_AW{1'b0}};
    end
    else if(ibuffer_wr_handshake) begin
        wr_data_cnt <= wr_data_cnt + 1;
    end
end

fwd_pipe #(
    .DATA_W(1+MEM_AW+STRB_WIDTH+DATA_WIDTH)
) u_wen_addr_strb_wdata_pipe(
    .clk(clk),
    .rst_n(rst_n),
    .f_valid_in(ibuffer_cen_pipe[0]),
    .f_data_in({ibuffer_wen_pipe[0], ibuffer_addr_pipe[0], ibuffer_strb_pipe[0], ibuffer_wdata_pipe[0]}),
    .f_ready_out(ibuffer_ready_pipe[0]),
    .b_valid_out(ibuffer_cen_pipe[1]),
    .b_data_out({ibuffer_wen_pipe[1], ibuffer_addr_pipe[1], ibuffer_strb_pipe[1], ibuffer_wdata_pipe[1]}),
    .b_ready_in(ibuffer_ready_pipe[1])
);

assign ibuffer_cen = ibuffer_cen_pipe[1];
assign ibuffer_wen = ibuffer_wen_pipe[1];
assign ibuffer_strb = ibuffer_strb_pipe[1];
assign ibuffer_addr = ibuffer_addr_pipe[1];
assign ibuffer_wdata = ibuffer_wdata_pipe[1];
assign ibuffer_ready_pipe[1] = ibuffer_ready;

endmodule