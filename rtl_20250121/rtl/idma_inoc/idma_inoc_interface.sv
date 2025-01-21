module idma_inoc_interface
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
    input                  fsm_start,
    input [16:0]           fsm_base_addr,
    input                  fsm_auto_restart_en, // if 1, auto restart next loop
    input                  fsm_restart, // if pulse asserts, restart next loop

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

    // apb interface master 0
    output [11:0]          m0_paddr  ,
    output [0:0]           m0_psel   ,
    output                 m0_penable,
    input                  m0_pready ,
    output                 m0_pwrite ,
    output [3:0]           m0_pstrb  ,
    output [31:0]          m0_pwdata ,

    // apb interface master 1
    output [11:0]          m1_paddr  ,
    output [0:0]           m1_psel   ,
    output                 m1_penable,
    input                  m1_pready ,
    output                 m1_pwrite ,
    output [3:0]           m1_pstrb  ,
    output [31:0]          m1_pwdata ,


    // send to noc
    output [11:0]           send_valid ,
    output [11:0][FLIT_WIDTH-1:0] send_flit  ,
    input  [11:0]           send_ready ,

    // receive from noc
    input  [11:0]           recv_valid ,
    input  [11:0][FLIT_WIDTH-1:0] recv_flit  ,
    output [11:0]           recv_ready ,

    // send intr
    output [11:0]           nodes_status,
    output                  small_loop_end_int,
    output                  finish_intr
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
wire [MEM_AW+$clog2(DATA_WIDTH/FLIT_WIDTH)-1:0] ibuffer_word_addr; // word addr
wire [12:0]             ibuffer_word_num; // how many word
wire                    op_last_or_finish;
wire                    noc_read_from_ibuffer_cen;
wire                    noc_read_from_ibuffer_wen;
wire                    noc_read_from_ibuffer_ready;
wire [MEM_AW-1:0]       noc_read_from_ibuffer_addr;
wire [DATA_WIDTH-1:0]   noc_read_from_ibuffer_rdata;
wire                    noc_read_from_ibuffer_rvalid;
wire                    noc_read_from_ibuffer_rready;
wire                    ibuffer_rd_start;
wire                    return_done;
wire                    return_valid;
wire                    return_ready;
wire                    return_last;
wire [FLIT_WIDTH-1:0]   return_data;

assign dma_rd_word_addr = dma_rd_addr[2+:(MEM_AW+2)];
assign dma_rd_word_addr_end = dma_rd_word_addr + dma_rd_num[0+:(MEM_AW+2)] - {{MEM_AW+1{1'b0}}, 1'b1};
assign dma_rd_data_num = dma_rd_word_addr_end[2+:MEM_AW] - dma_rd_word_addr[2+:MEM_AW] + {{MEM_AW-1{1'b0}}, 1'b1};


idma_write_ibuffer#(
    .DATA_WIDTH        ( DATA_WIDTH ),
    .MEM_AW            ( MEM_AW ),
    .STRB_WIDTH        ( STRB_WIDTH )
)u_idma_write_ibuffer(
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

idma_inoc_rd_ibuffer#(
    .DATA_WIDTH      ( DATA_WIDTH ),
    .MEM_AW          ( MEM_AW ),
    .STRB_WIDTH      ( STRB_WIDTH ),
    .WORD_WIDTH      ( FLIT_WIDTH )
)u_idma_inoc_rd_ibuffer(
    .clk               ( clk              ),
    .rst_n             ( rst_n            ),
    .ibuffer_rd_start  ( ibuffer_rd_start ),
    .ibuffer_word_addr ( ibuffer_word_addr),
    .ibuffer_word_num  ( ibuffer_word_num ),
    .op_last_or_finish ( op_last_or_finish),
    .ibuffer_cen       ( noc_read_from_ibuffer_cen      ),
    .ibuffer_wen       ( noc_read_from_ibuffer_wen      ),
    .ibuffer_ready     ( noc_read_from_ibuffer_ready    ),
    .ibuffer_addr      ( noc_read_from_ibuffer_addr     ),
    .ibuffer_rdata     ( noc_read_from_ibuffer_rdata    ),
    .ibuffer_rvalid    ( noc_read_from_ibuffer_rvalid   ),
    .ibuffer_rready    ( noc_read_from_ibuffer_rready   ),
    .return_done       ( return_done      ),
    .return_valid      ( return_valid     ),
    .return_ready      ( return_ready     ),
    .return_last       ( return_last      ),
    .return_data       ( return_data      )
);

idma_inoc_control#(
    .FLIT_WIDTH               ( FLIT_WIDTH )
)u_idma_inoc_control(
    .clk                      ( clk               ),
    .rst_n                    ( rst_n             ),
    .fsm_start                ( fsm_start         ),
    .fsm_base_addr            ( fsm_base_addr     ),
    .fsm_auto_restart_en      ( fsm_auto_restart_en),
    .fsm_restart              ( fsm_restart       ),
    .ibuffer_rd_start         ( ibuffer_rd_start  ),
    .ibuffer_word_addr        ( ibuffer_word_addr ),
    .ibuffer_word_num         ( ibuffer_word_num  ),
    .op_last_or_finish        ( op_last_or_finish ),
    .return_done              ( return_done       ),
    .return_valid             ( return_valid      ),
    .return_ready             ( return_ready      ),
    .return_data              ( return_data       ),
    .return_last              ( return_last       ),
    .m0_paddr                 ( m0_paddr          ),
    .m0_psel                  ( m0_psel           ),
    .m0_penable               ( m0_penable        ),
    .m0_pready                ( m0_pready         ),
    .m0_pwrite                ( m0_pwrite         ),
    .m0_pstrb                 ( m0_pstrb          ),
    .m0_pwdata                ( m0_pwdata         ),
    .m1_paddr                 ( m1_paddr          ),
    .m1_psel                  ( m1_psel           ),
    .m1_penable               ( m1_penable        ),
    .m1_pready                ( m1_pready         ),
    .m1_pwrite                ( m1_pwrite         ),
    .m1_pstrb                 ( m1_pstrb          ),
    .m1_pwdata                ( m1_pwdata         ),
    .send_valid               ( send_valid        ),
    .send_flit                ( send_flit         ),
    .send_ready               ( send_ready        ),
    .recv_valid               ( recv_valid        ),
    .recv_flit                ( recv_flit         ),
    .recv_ready               ( recv_ready        ),
    .nodes_status             ( nodes_status      ),
    .small_loop_end_int       ( small_loop_end_int),
    .finish_intr              ( finish_intr       )

);


idma_inoc_ibuffer_arbiter#(
    .DATA_WIDTH                    ( DATA_WIDTH ),
    .MEM_AW                        ( MEM_AW ),
    .STRB_WIDTH                    ( STRB_WIDTH )
)u_idma_inoc_ibuffer_arbiter(
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