/*
    assume 16KB
*/

module L2_dmem_bank(
    input                           clk,
    input                           rst_n,

    input   logic                   bank_core_rd_req,//1
    output  logic                   bank_core_rd_gnt,
    input   logic       [8:0]       bank_core_rd_addr,
    output  logic                   bank_core_rd_valid,
    output  logic       [255:0]     bank_core_rd_data,
    input                           bank_core_rd_ready,

    input   logic                   bank_core_wr_req,//0
    output  logic                   bank_core_wr_gnt,
    input   logic       [8:0]       bank_core_wr_addr,
    input   logic       [255:0]     bank_core_wr_data,
    // output  logic                   bank_core_wr_resp,

    input   logic                   bank_dma_rd_req,//3
    output  logic                   bank_dma_rd_gnt,
    input   logic       [8:0]       bank_dma_rd_addr,
    output  logic                   bank_dma_rd_valid,
    output  logic       [255:0]     bank_dma_rd_data,
    input                           bank_dma_rd_ready,

    input   logic                   bank_dma_wr_req,//2
    output  logic                   bank_dma_wr_gnt,
    input   logic       [8:0]       bank_dma_wr_addr,
    input   logic       [255:0]     bank_dma_wr_data
    // output  logic                   bank_dma_wr_resp

);

logic [1:0][127:0]  wr_data;
logic [1:0][127:0]  rd_data;

logic   ce;
logic   we;
logic [8:0] addr;

logic   [255:0] core_rd_data_pipe_in;
logic           core_rd_valid_pipe_in;
logic           core_rd_ready_pipe_in;

logic           core_rd_valid;
logic           core_rd_ready;
logic           core_rd_sel;
logic   [255:0] core_rd_data_reg;

logic   [255:0] dma_rd_data_pipe_in;
logic           dma_rd_valid_pipe_in;
logic           dma_rd_ready_pipe_in;

logic           dma_rd_valid;
logic           dma_rd_ready;
logic           dma_rd_sel;
logic   [255:0] dma_rd_data_reg;

// logic   [3:0]   
//------------------arb--------------
always_comb begin
    ce = 1'b0;
    addr = bank_dma_rd_addr;
    we = 1'b0;
    wr_data = bank_dma_wr_data;

    bank_core_rd_gnt = 1'b0;
    // bank_core_rd_data = rd_data;

    bank_core_wr_gnt = 1'b0;

    bank_dma_rd_gnt = 1'b0;
    // bank_dma_rd_data = rd_data;

    bank_dma_wr_gnt = 1'b0;

    if(bank_core_wr_req) begin
        bank_core_wr_gnt = 1'b1;
        ce = 1'b1;
        addr = bank_core_wr_addr;
        we = 1'b1;
        wr_data = bank_core_wr_data;
    end
    else if(bank_core_rd_req & core_rd_ready) begin
        bank_core_rd_gnt = 1'b1;
        ce = 1'b1;
        addr = bank_core_rd_addr;
        we = 1'b0;
    end
    else if(bank_dma_wr_req) begin
        bank_dma_wr_gnt = 1'b1;
        ce = 1'b1;
        addr = bank_dma_wr_addr;
        we = 1'b1;
        wr_data = bank_dma_wr_data;
    end
    else if(bank_dma_rd_req & dma_rd_ready) begin
        bank_dma_rd_gnt = 1'b1;
        ce = 1'b1;
        addr = bank_dma_rd_addr;
        we = 1'b0;
    end
end

    // bank_core_rd_valid = 1'b0;
    // bank_dma_rd_valid = 1'b0;

//---------------------core rd-------------------------------

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        core_rd_valid <= 1'b0;
    end
    else if(bank_core_rd_gnt) begin
        core_rd_valid <= 1'b1;
    end
    else if(core_rd_ready_pipe_in) begin
        core_rd_valid <= 1'b0;
    end
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        core_rd_sel <= 1'b0;
    end
    else if(core_rd_valid & (~core_rd_ready_pipe_in)) begin
        core_rd_sel <= 1'b1;
    end
    else if(core_rd_ready_pipe_in) begin
        core_rd_sel <= 1'b0;
    end
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        core_rd_data_reg <= 'd0;
    end
    else if(core_rd_valid & (~core_rd_ready_pipe_in)) begin
        core_rd_data_reg <= rd_data;
    end
    // else if(core_rd_ready_pipe_in) begin
    //     core_rd_data_reg <= 'd0;
    // end
end

assign core_rd_valid_pipe_in = core_rd_valid;
assign core_rd_data_pipe_in = core_rd_sel ? core_rd_data_reg : rd_data;
assign core_rd_ready = (~core_rd_valid) | (core_rd_valid_pipe_in & core_rd_ready_pipe_in);

fwdbwd_pipe #( 
    .DATA_W(256)
)
U_core_rd_pipe
(
    .clk            (clk),
    .rst_n          (rst_n),
//from/to master
    .f_valid_in     (core_rd_valid_pipe_in),
    .f_data_in      (core_rd_data_pipe_in),
    .f_ready_out    (core_rd_ready_pipe_in),
//from/to slave
    .b_valid_out    (bank_core_rd_valid),
    .b_data_out     (bank_core_rd_data),
    .b_ready_in     (bank_core_rd_ready)
);

//----------------------dma rd------------------------------

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        dma_rd_valid <= 1'b0;
    end
    else if(bank_dma_rd_gnt) begin
        dma_rd_valid <= 1'b1;
    end
    else if(dma_rd_ready_pipe_in) begin
        dma_rd_valid <= 1'b0;
    end
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        dma_rd_sel <= 1'b0;
    end
    else if(dma_rd_valid & (~dma_rd_ready_pipe_in)) begin
        dma_rd_sel <= 1'b1;
    end
    else if(dma_rd_ready_pipe_in) begin
        dma_rd_sel <= 1'b0;
    end
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        dma_rd_data_reg <= 'd0;
    end
    else if(dma_rd_valid & (~dma_rd_ready_pipe_in)) begin
        dma_rd_data_reg <= rd_data;
    end
    // else if(dma_rd_ready_pipe_in) begin
    //     dma_rd_data_reg <= 'd0;
    // end
end

assign dma_rd_valid_pipe_in = dma_rd_valid;
assign dma_rd_data_pipe_in = dma_rd_sel ? dma_rd_data_reg : rd_data;
assign dma_rd_ready = (~dma_rd_valid) | (dma_rd_valid_pipe_in & dma_rd_ready_pipe_in);

fwdbwd_pipe #( 
    .DATA_W(256)
)
U_dma_rd_pipe
(
    .clk            (clk),
    .rst_n          (rst_n),
//from/to master
    .f_valid_in     (dma_rd_valid_pipe_in),
    .f_data_in      (dma_rd_data_pipe_in),
    .f_ready_out    (dma_rd_ready_pipe_in),
//from/to slave
    .b_valid_out    (bank_dma_rd_valid),
    .b_data_out     (bank_dma_rd_data),
    .b_ready_in     (bank_dma_rd_ready)
);

//---------------------------------ram-------------------------

// assign wr_data[0] = WR_DATA[127:0];
// assign wr_data[1] = WR_DATA[255:128];
// assign RD_DATA = rd_data;

genvar gen_i;
generate
    for(gen_i = 0; gen_i < 2; gen_i = gen_i + 1) begin: SRAM_BANK
        std_spram512x128 U_sram512x128(
            .clk(clk),
            .CEB(~ce),
            .WEB(~we),
            .A(addr),
            .D(wr_data[gen_i]),
            .Q(rd_data[gen_i])
        );
    end
endgenerate

endmodule
