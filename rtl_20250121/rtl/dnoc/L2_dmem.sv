/*
    4 banks
*/
module L2_dmem(
    input                           clk,
    input                           rst_n,

    input                           L2_dmem_core_rd_req,
    output  logic                   L2_dmem_core_rd_gnt,
    input           [10:0]          L2_dmem_core_rd_addr,
    output  logic                   L2_dmem_core_rd_valid,
    output  logic   [255:0]         L2_dmem_core_rd_data,
    input                           L2_dmem_core_rd_ready,

    input                           L2_dmem_core_wr_req,
    output  logic                   L2_dmem_core_wr_gnt,
    input           [10:0]          L2_dmem_core_wr_addr,
    input           [255:0]         L2_dmem_core_wr_data,
    output  logic                   L2_dmem_core_wr_resp,

    input                           L2_dmem_dma_rd_req,
    output  logic                   L2_dmem_dma_rd_gnt,
    input           [10:0]          L2_dmem_dma_rd_addr,
    output  logic                   L2_dmem_dma_rd_valid,
    output  logic   [255:0]         L2_dmem_dma_rd_data,
    input                           L2_dmem_dma_rd_ready,

    input                           L2_dmem_dma_wr_req,
    output  logic                   L2_dmem_dma_wr_gnt,
    input           [10:0]          L2_dmem_dma_wr_addr,
    input           [255:0]         L2_dmem_dma_wr_data,
    output  logic                   L2_dmem_dma_wr_resp
);

logic   [3:0]            bank_core_rd_req;
logic   [3:0]            bank_core_rd_gnt;
logic        [8:0]       bank_core_rd_addr;
logic   [3:0]            bank_core_rd_valid;
logic   [3:0][255:0]     bank_core_rd_data;
logic   [3:0]            bank_core_rd_ready;

logic   [3:0]            bank_core_wr_req;
logic   [3:0]            bank_core_wr_gnt;
logic        [8:0]       bank_core_wr_addr;
logic        [255:0]     bank_core_wr_data;
// logic                    bank_core_wr_resp;

logic   [3:0]            bank_dma_rd_req;
logic   [3:0]            bank_dma_rd_gnt;
logic        [8:0]       bank_dma_rd_addr;
logic   [3:0]            bank_dma_rd_valid;
logic   [3:0][255:0]     bank_dma_rd_data;
logic   [3:0]            bank_dma_rd_ready;

logic   [3:0]            bank_dma_wr_req;
logic   [3:0]            bank_dma_wr_gnt;
logic        [8:0]       bank_dma_wr_addr;
logic        [255:0]     bank_dma_wr_data;
// logic                    bank_dma_wr_resp;

//-------------------------core rd----------------------------
logic           core_rd_req_fifo_full;
logic           core_rd_req_fifo_empty;
logic           core_rd_req_fifo_push;
logic           core_rd_req_fifo_pop;
logic [1:0]     core_rd_rvalid_mux_sel;

assign core_rd_req_fifo_push = (|(bank_core_rd_req & bank_core_rd_gnt)) & (~core_rd_req_fifo_full);
assign core_rd_req_fifo_pop = L2_dmem_core_rd_valid & (~core_rd_req_fifo_empty);

assign bank_core_rd_req[0] = L2_dmem_core_rd_req & (L2_dmem_core_rd_addr[1:0] == 2'd0);
assign bank_core_rd_req[1] = L2_dmem_core_rd_req & (L2_dmem_core_rd_addr[1:0] == 2'd1);
assign bank_core_rd_req[2] = L2_dmem_core_rd_req & (L2_dmem_core_rd_addr[1:0] == 2'd2);
assign bank_core_rd_req[3] = L2_dmem_core_rd_req & (L2_dmem_core_rd_addr[1:0] == 2'd3);
assign bank_core_rd_addr = L2_dmem_core_rd_addr[10:2];
assign L2_dmem_core_rd_gnt = (|(bank_core_rd_req & bank_core_rd_gnt));

assign L2_dmem_core_rd_valid = (bank_core_rd_valid[0] & (core_rd_rvalid_mux_sel == 2'd0)) | 
                               (bank_core_rd_valid[1] & (core_rd_rvalid_mux_sel == 2'd1)) |
                               (bank_core_rd_valid[2] & (core_rd_rvalid_mux_sel == 2'd2)) |
                               (bank_core_rd_valid[3] & (core_rd_rvalid_mux_sel == 2'd3)) ;

assign L2_dmem_core_rd_data = ({256{bank_core_rd_valid[0] & (core_rd_rvalid_mux_sel == 2'd0)}} & bank_core_rd_data[0]) |
                              ({256{bank_core_rd_valid[1] & (core_rd_rvalid_mux_sel == 2'd1)}} & bank_core_rd_data[1]) |
                              ({256{bank_core_rd_valid[2] & (core_rd_rvalid_mux_sel == 2'd2)}} & bank_core_rd_data[2]) |
                              ({256{bank_core_rd_valid[3] & (core_rd_rvalid_mux_sel == 2'd3)}} & bank_core_rd_data[3]) ;

assign bank_core_rd_ready[0] = L2_dmem_core_rd_ready & (core_rd_rvalid_mux_sel == 2'd0);
assign bank_core_rd_ready[1] = L2_dmem_core_rd_ready & (core_rd_rvalid_mux_sel == 2'd1);
assign bank_core_rd_ready[2] = L2_dmem_core_rd_ready & (core_rd_rvalid_mux_sel == 2'd2);
assign bank_core_rd_ready[3] = L2_dmem_core_rd_ready & (core_rd_rvalid_mux_sel == 2'd3);

ram_req_fifo U_core_rd_req_fifo(
    .clk(clk),
    .rst_n(rst_n),
    .push(core_rd_req_fifo_push),
    .in_data(L2_dmem_core_rd_addr[1:0]),
    .full(core_rd_req_fifo_full),

    .pop(core_rd_req_fifo_pop),
    .out_data(core_rd_rvalid_mux_sel),
    .empty(core_rd_req_fifo_empty)
);

//------------------------core wr-----------------------------------

assign bank_core_wr_req[0] = L2_dmem_core_wr_req & (L2_dmem_core_wr_addr[1:0] == 2'd0);
assign bank_core_wr_req[1] = L2_dmem_core_wr_req & (L2_dmem_core_wr_addr[1:0] == 2'd1);
assign bank_core_wr_req[2] = L2_dmem_core_wr_req & (L2_dmem_core_wr_addr[1:0] == 2'd2);
assign bank_core_wr_req[3] = L2_dmem_core_wr_req & (L2_dmem_core_wr_addr[1:0] == 2'd3);
assign bank_core_wr_addr = L2_dmem_core_wr_addr[10:2];
assign L2_dmem_core_wr_gnt = |(bank_core_wr_gnt & bank_core_wr_req);

assign L2_dmem_core_wr_resp = |(bank_core_wr_gnt & bank_core_wr_req);
assign bank_core_wr_data = L2_dmem_core_wr_data;

//-----------------------dma rd-----------------------------------------
logic           dma_rd_req_fifo_full;
logic           dma_rd_req_fifo_empty;
logic           dma_rd_req_fifo_push;
logic           dma_rd_req_fifo_pop;
logic [1:0]     dma_rd_rvalid_mux_sel;

assign dma_rd_req_fifo_push = (|(bank_dma_rd_req & bank_dma_rd_gnt)) & (~dma_rd_req_fifo_full);
assign dma_rd_req_fifo_pop = L2_dmem_dma_rd_valid & (~dma_rd_req_fifo_empty);

assign bank_dma_rd_req[0] = L2_dmem_dma_rd_req & (L2_dmem_dma_rd_addr[1:0] == 2'd0);
assign bank_dma_rd_req[1] = L2_dmem_dma_rd_req & (L2_dmem_dma_rd_addr[1:0] == 2'd1);
assign bank_dma_rd_req[2] = L2_dmem_dma_rd_req & (L2_dmem_dma_rd_addr[1:0] == 2'd2);
assign bank_dma_rd_req[3] = L2_dmem_dma_rd_req & (L2_dmem_dma_rd_addr[1:0] == 2'd3);
assign bank_dma_rd_addr = L2_dmem_dma_rd_addr[10:2];
assign L2_dmem_dma_rd_gnt = (|(bank_dma_rd_req & bank_dma_rd_gnt));

assign L2_dmem_dma_rd_valid = (bank_dma_rd_valid[0] & (dma_rd_rvalid_mux_sel == 2'd0)) | 
                               (bank_dma_rd_valid[1] & (dma_rd_rvalid_mux_sel == 2'd1)) |
                               (bank_dma_rd_valid[2] & (dma_rd_rvalid_mux_sel == 2'd2)) |
                               (bank_dma_rd_valid[3] & (dma_rd_rvalid_mux_sel == 2'd3)) ;

assign L2_dmem_dma_rd_data = ({256{bank_dma_rd_valid[0] & (dma_rd_rvalid_mux_sel == 2'd0)}} & bank_dma_rd_data[0]) |
                              ({256{bank_dma_rd_valid[1] & (dma_rd_rvalid_mux_sel == 2'd1)}} & bank_dma_rd_data[1]) |
                              ({256{bank_dma_rd_valid[2] & (dma_rd_rvalid_mux_sel == 2'd2)}} & bank_dma_rd_data[2]) |
                              ({256{bank_dma_rd_valid[3] & (dma_rd_rvalid_mux_sel == 2'd3)}} & bank_dma_rd_data[3]) ;

assign bank_dma_rd_ready[0] = L2_dmem_dma_rd_ready & (dma_rd_rvalid_mux_sel == 2'd0);
assign bank_dma_rd_ready[1] = L2_dmem_dma_rd_ready & (dma_rd_rvalid_mux_sel == 2'd1);
assign bank_dma_rd_ready[2] = L2_dmem_dma_rd_ready & (dma_rd_rvalid_mux_sel == 2'd2);
assign bank_dma_rd_ready[3] = L2_dmem_dma_rd_ready & (dma_rd_rvalid_mux_sel == 2'd3);

ram_req_fifo U_dma_rd_req_fifo(
    .clk(clk),
    .rst_n(rst_n),
    .push(dma_rd_req_fifo_push),
    .in_data(L2_dmem_dma_rd_addr[1:0]),
    .full(dma_rd_req_fifo_full),

    .pop(dma_rd_req_fifo_pop),
    .out_data(dma_rd_rvalid_mux_sel),
    .empty(dma_rd_req_fifo_empty)
);

//------------------------dma wr------------------------------------------

assign bank_dma_wr_req[0] = L2_dmem_dma_wr_req & (L2_dmem_dma_wr_addr[1:0] == 2'd0);
assign bank_dma_wr_req[1] = L2_dmem_dma_wr_req & (L2_dmem_dma_wr_addr[1:0] == 2'd1);
assign bank_dma_wr_req[2] = L2_dmem_dma_wr_req & (L2_dmem_dma_wr_addr[1:0] == 2'd2);
assign bank_dma_wr_req[3] = L2_dmem_dma_wr_req & (L2_dmem_dma_wr_addr[1:0] == 2'd3);
assign bank_dma_wr_addr = L2_dmem_dma_wr_addr[10:2];
assign L2_dmem_dma_wr_gnt = |(bank_dma_wr_req & bank_dma_wr_gnt);

assign L2_dmem_dma_wr_resp = |(bank_dma_wr_req & bank_dma_wr_gnt);
assign bank_dma_wr_data = L2_dmem_dma_wr_data;

// always_comb begin
//     bank_core_rd_req = 'd0;
//     L2_dmem_core_rd_gnt = |bank_core_rd_gnt;
//     bank_core_rd_addr = L2_dmem_core_rd_addr[10:2];

// end


genvar gen_i;
generate
    for(gen_i = 0; gen_i < 4; gen_i = gen_i + 1) begin: L2_dmem_banks
        L2_dmem_bank U_L2_dmem_bank(
            .clk(clk),
            .rst_n(rst_n),
            .bank_core_rd_req(bank_core_rd_req[gen_i]),
            .bank_core_rd_gnt(bank_core_rd_gnt[gen_i]),
            .bank_core_rd_addr(bank_core_rd_addr),
            .bank_core_rd_valid(bank_core_rd_valid[gen_i]),
            .bank_core_rd_data(bank_core_rd_data[gen_i]),
            .bank_core_rd_ready(bank_core_rd_ready[gen_i]),

            .bank_core_wr_req(bank_core_wr_req[gen_i]),
            .bank_core_wr_gnt(bank_core_wr_gnt[gen_i]),
            .bank_core_wr_addr(bank_core_wr_addr),
            .bank_core_wr_data(bank_core_wr_data),

            .bank_dma_rd_req(bank_dma_rd_req[gen_i]),
            .bank_dma_rd_gnt(bank_dma_rd_gnt[gen_i]),
            .bank_dma_rd_addr(bank_dma_rd_addr),
            .bank_dma_rd_valid(bank_dma_rd_valid[gen_i]),
            .bank_dma_rd_data(bank_dma_rd_data[gen_i]),
            .bank_dma_rd_ready(bank_dma_rd_ready[gen_i]),

            .bank_dma_wr_req(bank_dma_wr_req[gen_i]),
            .bank_dma_wr_gnt(bank_dma_wr_gnt[gen_i]),
            .bank_dma_wr_addr(bank_dma_wr_addr),
            .bank_dma_wr_data(bank_dma_wr_data)
        );
    end
endgenerate


    
endmodule
