module ictrl_kernel
#(
    parameter DATA_WIDTH = 128,
    parameter MEM_AW = 15,
    parameter STRB_WIDTH = (DATA_WIDTH/8),
    parameter FLIT_WIDTH = 32
) 
(
    input clk,
    input rst_n,

    // config ports
    input                  cfg_send_start,
    input [FLIT_WIDTH-1:0] cfg_group_info,
    input                  cfg_group_info_valid,
    input [FLIT_WIDTH-1:0] cfg_cache_info,
    input                  cfg_cache_info_valid,

    // dma port
    input                  dma_rd_req,
    input                  dma_rd_data_valid,
    input [DATA_WIDTH-1:0] dma_rd_data,
    output                 dma_rd_data_ready,
    input [STRB_WIDTH-1:0] dma_rd_strb,
    input [31:0]           dma_rd_addr,
    input [31:0]           dma_rd_num, // how many word

    // ibuffer port
    output                 ibuffer_cen,
    output                 ibuffer_wen,
    input                  ibuffer_ready,
    output[MEM_AW-1:0]     ibuffer_addr,
    output[DATA_WIDTH-1:0] ibuffer_wdata,
    output[STRB_WIDTH-1:0] ibuffer_strb,
    input[DATA_WIDTH-1:0]  ibuffer_rdata,
    input                  ibuffer_rvalid,
    output                 ibuffer_rready,

    // send to noc
    output [11:0]           send_valid ,
    output [FLIT_WIDTH-1:0] send_flit  [11:0],
    input  [11:0]           send_ready ,

    // receive from noc
    input  [11:0]           recv_valid ,
    input  [FLIT_WIDTH-1:0] recv_flit  [11:0],
    output [11:0]           recv_ready ,

    // send intr
    output [11:0]           nodes_status,
    output                  nodes_intr
);

wire [MEM_AW-1:0]     dma_rd_data_num;
wire [MEM_AW+2-1:0]   dma_rd_word_addr;
wire [MEM_AW+2-1:0]   dma_rd_word_addr_end;
wire                  dma_read_to_ibuffer_cen;
wire                  dma_read_to_ibuffer_wen;
wire                  dma_read_to_ibuffer_ready;
wire [MEM_AW-1:0]     dma_read_to_ibuffer_addr;
wire [DATA_WIDTH-1:0] dma_read_to_ibuffer_wdata;
wire [STRB_WIDTH-1:0] dma_read_to_ibuffer_strb;
wire                  dma_read_to_ibuffer_done;

// noc wr port
wire [MEM_AW+$clog2(DATA_WIDTH/FLIT_WIDTH)-1:0] noc_read_from_ibuffer_word_addr; // word addr
wire [12:0]             noc_read_from_ibuffer_word_num; // how many word
wire                    noc_read_from_ibuffer_cen;
wire                    noc_read_from_ibuffer_wen;
wire                    noc_read_from_ibuffer_ready;
wire [MEM_AW-1:0]       noc_read_from_ibuffer_addr;
wire [DATA_WIDTH-1:0]   noc_read_from_ibuffer_rdata;
wire                    noc_read_from_ibuffer_rvalid;
wire                    noc_read_from_ibuffer_rready;
wire                    noc_wr_start;
wire                    noc_wr_done;
wire                    noc_wr_req;
wire                    noc_wr_ready;
wire                    noc_wr_last;
wire [FLIT_WIDTH-1:0]   noc_wr_data;

assign dma_rd_word_addr = dma_rd_addr[2+:(MEM_AW+2)];
assign dma_rd_word_addr_end = dma_rd_word_addr + dma_rd_num[0+:(MEM_AW+2)] - {{MEM_AW+1{1'b0}}, 1'b1};
assign dma_rd_data_num = dma_rd_word_addr_end[2+:MEM_AW] - dma_rd_word_addr[2+:MEM_AW] + {{MEM_AW-1{1'b0}}, 1'b1};
ictrl_dma_read_to_ibuffer#(
    .DATA_WIDTH        ( DATA_WIDTH ),
    .MEM_AW            ( MEM_AW ),
    .STRB_WIDTH        ( STRB_WIDTH )
)u_ictrl_dma_read_to_ibuffer(
    .clk               ( clk               ),
    .rst_n             ( rst_n             ),
    .dma_rd_data_num   ( dma_rd_data_num),
    .dma_rd_req        ( dma_rd_req        ),
    .dma_rd_data_valid ( dma_rd_data_valid ),
    .dma_rd_data       ( dma_rd_data       ),
    .dma_rd_data_ready ( dma_rd_data_ready ),
    .dma_rd_strb       ( dma_rd_strb       ),
    .dma_write_done    ( dma_read_to_ibuffer_done      ),
    .ibuffer_cen       ( dma_read_to_ibuffer_cen       ),
    .ibuffer_wen       ( dma_read_to_ibuffer_wen       ),
    .ibuffer_ready     ( dma_read_to_ibuffer_ready     ),
    .ibuffer_addr      ( dma_read_to_ibuffer_addr      ),
    .ibuffer_wdata     ( dma_read_to_ibuffer_wdata     ),
    .ibuffer_strb      ( dma_read_to_ibuffer_strb      )
);

ictrl_ibuffer_read_to_noc#(
    .DATA_WIDTH      ( DATA_WIDTH ),
    .MEM_AW          ( MEM_AW ),
    .STRB_WIDTH      ( STRB_WIDTH ),
    .WORD_WIDTH      ( FLIT_WIDTH )
)u_ictrl_ibuffer_read_to_noc(
    .clk               ( clk              ),
    .rst_n             ( rst_n            ),
    .ibuffer_word_addr ( noc_read_from_ibuffer_word_addr),
    .ibuffer_word_num  ( noc_read_from_ibuffer_word_num ),
    .ibuffer_cen       ( noc_read_from_ibuffer_cen      ),
    .ibuffer_wen       ( noc_read_from_ibuffer_wen      ),
    .ibuffer_ready     ( noc_read_from_ibuffer_ready    ),
    .ibuffer_addr      ( noc_read_from_ibuffer_addr     ),
    .ibuffer_rdata     ( noc_read_from_ibuffer_rdata    ),
    .ibuffer_rvalid    ( noc_read_from_ibuffer_rvalid   ),
    .ibuffer_rready    ( noc_read_from_ibuffer_rready   ),
    .noc_wr_start      ( noc_wr_start  ),
    .noc_wr_done       ( noc_wr_done   ),
    .noc_wr_req        ( noc_wr_req       ),
    .noc_wr_ready      ( noc_wr_ready     ),
    .noc_wr_last       ( noc_wr_last      ),
    .noc_wr_data       ( noc_wr_data      )
);

ictrl_send_recv_flit#(
    .FLIT_WIDTH               ( FLIT_WIDTH )
)u_ictrl_send_recv_flit(
    .clk                      ( clk                      ),
    .rst_n                    ( rst_n                    ),
    .cfg_send_start           ( cfg_send_start           ),
    .cfg_group_info           ( cfg_group_info           ),
    .cfg_group_info_valid     ( cfg_group_info_valid     ),
    .cfg_cache_info           ( cfg_cache_info           ),
    .cfg_cache_info_valid     ( cfg_cache_info_valid     ),
    .noc_wr_start             ( noc_wr_start             ),
    .noc_wr_ibuffer_word_addr ( noc_read_from_ibuffer_word_addr ),
    .noc_wr_ibuffer_word_num  ( noc_read_from_ibuffer_word_num  ),
    .noc_wr_done              ( noc_wr_done              ),
    .noc_wr_req               ( noc_wr_req               ),
    .noc_wr_ready             ( noc_wr_ready             ),
    .noc_wr_data              ( noc_wr_data              ),
    .noc_wr_last              ( noc_wr_last              ),
    .send_valid               ( send_valid               ),
    .send_flit                ( send_flit                ),
    .send_ready               ( send_ready               ),
    .recv_valid               ( recv_valid               ),
    .recv_flit                ( recv_flit                ),
    .recv_ready               ( recv_ready               ),
    .nodes_status             ( nodes_status             ),
    .nodes_intr               ( nodes_intr               )

);


ictrl_ibuffer_arbiter#(
    .DATA_WIDTH                    ( DATA_WIDTH ),
    .MEM_AW                        ( MEM_AW ),
    .STRB_WIDTH                    ( STRB_WIDTH )
)u_ictrl_ibuffer_arbiter(
    .clk                           ( clk                           ),
    .rst_n                         ( rst_n                         ),
    .dma_read_start                ( dma_rd_req                    ),
    .dma_write_done                ( dma_read_to_ibuffer_done      ),
    .dma_read_to_ibuffer_cen       ( dma_read_to_ibuffer_cen       ),
    .dma_read_to_ibuffer_wen       ( dma_read_to_ibuffer_wen       ),
    .dma_read_to_ibuffer_ready     ( dma_read_to_ibuffer_ready     ),
    .dma_read_to_ibuffer_addr      ( dma_read_to_ibuffer_addr      ),
    .dma_read_to_ibuffer_wdata     ( dma_read_to_ibuffer_wdata     ),
    .dma_read_to_ibuffer_strb      ( dma_read_to_ibuffer_strb      ),
    .noc_read_from_ibuffer_cen     ( noc_read_from_ibuffer_cen         ),
    .noc_read_from_ibuffer_wen     ( noc_read_from_ibuffer_wen         ),
    .noc_read_from_ibuffer_ready   ( noc_read_from_ibuffer_ready       ),
    .noc_read_from_ibuffer_addr    ( noc_read_from_ibuffer_addr        ),
    .noc_read_from_ibuffer_rdata   ( noc_read_from_ibuffer_rdata       ),
    .noc_read_from_ibuffer_rvalid  ( noc_read_from_ibuffer_rvalid      ),
    .noc_read_from_ibuffer_rready  ( noc_read_from_ibuffer_rready      ),
    .ibuffer_cen                   ( ibuffer_cen                   ),
    .ibuffer_wen                   ( ibuffer_wen                   ),
    .ibuffer_ready                 ( ibuffer_ready                 ),
    .ibuffer_addr                  ( ibuffer_addr                  ),
    .ibuffer_wdata                 ( ibuffer_wdata                 ),
    .ibuffer_strb                  ( ibuffer_strb                  ),
    .ibuffer_rdata                 ( ibuffer_rdata                 ),
    .ibuffer_rvalid                ( ibuffer_rvalid                ),
    .ibuffer_rready                ( ibuffer_rready                )
);



endmodule