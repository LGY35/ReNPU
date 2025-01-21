module ictrl_top 
#(
    parameter AXI_DW = 128,
    parameter AXI_AW = 32,
    parameter STRB_WIDTH = (AXI_DW/8),
    parameter ID_WIDTH = 8,
    parameter AXI_LENW = 8,
    parameter AXI_LOCKW = 1,
    parameter MEM_AW = 15,
    parameter FLIT_WIDTH = 32,
    // dma
    parameter DATA_FIFO_DEPTH   = 64    ,
    parameter DATA_FIFO_CNT_WID = 6+1   ,
    parameter ADDR_FIFO_DEPTH   = 32    ,
    parameter ADDR_FIFO_CNT_WID = 5+1   
) 
(   
    // axi clk rst_n
    input aclk,
    input aresetn,

    // AXI slave port
    input   [ID_WIDTH-1:0]    s_axi_awid,
    input   [AXI_AW-1:0]      s_axi_awaddr,
    input   [7:0]             s_axi_awlen,
    input   [2:0]             s_axi_awsize,
    input   [1:0]             s_axi_awburst,
    input                     s_axi_awlock,
    input   [3:0]             s_axi_awcache,
    input   [2:0]             s_axi_awprot,
    input                     s_axi_awvalid,
    output                    s_axi_awready,
    input   [AXI_DW-1:0]      s_axi_wdata,
    input   [STRB_WIDTH-1:0]  s_axi_wstrb,
    input                     s_axi_wlast,
    input                     s_axi_wvalid,
    output                    s_axi_wready,
    output  [ID_WIDTH-1:0]    s_axi_bid,
    output  [1:0]             s_axi_bresp,
    output                    s_axi_bvalid,
    input                     s_axi_bready,
    input   [ID_WIDTH-1:0]    s_axi_arid,
    input   [AXI_AW-1:0]      s_axi_araddr,
    input   [7:0]             s_axi_arlen,
    input   [2:0]             s_axi_arsize,
    input   [1:0]             s_axi_arburst,
    input                     s_axi_arlock,
    input   [3:0]             s_axi_arcache,
    input   [2:0]             s_axi_arprot,
    input                     s_axi_arvalid,
    output                    s_axi_arready,
    output  [ID_WIDTH-1:0]    s_axi_rid,
    output  [AXI_DW-1:0]      s_axi_rdata,
    output  [1:0]             s_axi_rresp,
    output                    s_axi_rlast,
    output                    s_axi_rvalid,
    input                     s_axi_rready,

    //dma axi master interface
    output                    m_arvalid,
    output [ID_WIDTH-1:0]     m_arid   ,
    output [AXI_AW-1:0]       m_araddr ,
    output [AXI_LENW-1:0]     m_arlen  ,
    output [2:0]              m_arsize ,
    output [1:0]              m_arburst,
    output [AXI_LOCKW-1:0]    m_arlock ,
    output [3:0]              m_arcache,
    output [2:0]              m_arprot ,
    input                     m_arready,
    input                     m_rvalid ,
    input  [ID_WIDTH-1:0]     m_rid    ,
    input                     m_rlast  ,
    input  [AXI_DW-1:0]       m_rdata  ,
    input  [1:0]              m_rresp  ,
    output                    m_rready ,
    
    // dma rd chn
    input                               rd_cfg_ready        ,
    input                               rd_afifo_init       ,
    input                               rd_dfifo_init       ,
    output  [DATA_FIFO_CNT_WID-1: 0]    rd_dfifo_word_cnt   ,
    output  [ADDR_FIFO_CNT_WID-1: 0]    rd_afifo_word_cnt   ,
    input	[3:0]			            rd_cfg_outstd       ,
    input	     			            rd_cfg_outstd_en    ,
    input                               rd_cfg_cross4k_en   ,
    input                               rd_cfg_arvld_hold_en,
    input  [DATA_FIFO_CNT_WID-1:0]      rd_cfg_dfifo_thd    ,
    input                               rd_resi_mode        ,//1:resi 0:norm
    input  [AXI_AW-1:0]                 rd_resi_fmapA_addr  ,
    input  [AXI_AW-1:0]                 rd_resi_fmapB_addr  ,
    input  [16-1:0]                     rd_resi_addr_gap    ,
    input  [16-1:0]                     rd_resi_loop_num    ,
    input                              	rd_req              ,
    input  [AXI_AW-1:0]                 rd_addr             ,
    input  [31:0]                     	rd_num              ,
    output                             	rd_addr_ready       ,
    output                              rd_done_intr        ,
    output  [16-1:0]                    debug_dma_rd_in_cnt ,
    // config
    input                   cfg_send_start,
    input [FLIT_WIDTH-1:0]  cfg_group_info,
    input                   cfg_group_info_valid,
    input [FLIT_WIDTH-1:0]  cfg_cache_info,
    input                   cfg_cache_info_valid,
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

wire                  rd_data_valid;
wire [AXI_DW-1:0]     rd_data      ;
wire [STRB_WIDTH-1:0] rd_strb      ;
wire                  rd_data_ready;

wire                    s_axi_mem_cen; // mem chip enable
wire                    s_axi_mem_last;
wire  [MEM_AW-1:0]      s_axi_mem_addr; // mem address
wire                    s_axi_mem_ready; // mem req back pressure
wire                    s_axi_mem_wen; // mem write enable
wire  [AXI_DW-1:0]      s_axi_mem_wdata; // write data
wire  [STRB_WIDTH-1:0]  s_axi_mem_wstrb; // write strobe
wire                    s_axi_mem_rvalid; // read valid
wire                    s_axi_mem_rlast;
wire                    s_axi_mem_rready; // resp back pressure
wire  [AXI_DW-1:0]      s_axi_mem_rdata; // read data from mem

wire                   ibuffer_cen;
wire                   ibuffer_wen;
wire                   ibuffer_ready;
wire  [MEM_AW-1:0]     ibuffer_addr;
wire  [AXI_DW-1:0]     ibuffer_wdata;
wire  [STRB_WIDTH-1:0] ibuffer_strb;
wire  [AXI_DW-1:0]     ibuffer_rdata;
wire                   ibuffer_rvalid;
wire                   ibuffer_rready;

//==================================================
// DMA
//==================================================
idma_rd_sync_top #(
    .DATA_FIFO_DEPTH  (DATA_FIFO_DEPTH),
    .DATA_FIFO_CNT_WID(DATA_FIFO_CNT_WID),
    .ADDR_FIFO_DEPTH  (ADDR_FIFO_DEPTH),
    .ADDR_FIFO_CNT_WID(ADDR_FIFO_CNT_WID),
    .AXI_DATA_WID     (AXI_DW),
    .AXI_ADDR_WID     (AXI_AW),
    .AXI_IDW          (ID_WIDTH),
    .AXI_LENW         (AXI_LENW),
    .AXI_LOCKW        (AXI_LOCKW),
    .AXI_STRBW        (STRB_WIDTH)
)
u_idma_rd_sync_top(
    .aclk                      ( aclk                      ),
    .aresetn                   ( aresetn                   ),
    .rd_cfg_ready              ( rd_cfg_ready              ),
    .rd_afifo_init             ( rd_afifo_init             ),
    .rd_dfifo_init             ( rd_dfifo_init             ),
    .rd_afifo_word_cnt         ( rd_afifo_word_cnt         ),
    .rd_dfifo_word_cnt         ( rd_dfifo_word_cnt         ),
    .rd_cfg_outstd             ( rd_cfg_outstd             ),
    .rd_cfg_outstd_en          ( rd_cfg_outstd_en          ),
    .rd_cfg_cross4k_en         ( rd_cfg_cross4k_en         ),
    .rd_cfg_arvld_hold_en      ( rd_cfg_arvld_hold_en      ),
    .rd_cfg_dfifo_thd          ( rd_cfg_dfifo_thd          ),
    .rd_resi_mode              ( rd_resi_mode              ),
    .rd_resi_fmapA_addr        ( rd_resi_fmapA_addr        ),
    .rd_resi_fmapB_addr        ( rd_resi_fmapB_addr        ),
    .rd_resi_addr_gap          ( rd_resi_addr_gap          ),
    .rd_resi_loop_num          ( rd_resi_loop_num          ),
    .rd_req                    ( rd_req                    ),
    .rd_addr                   ( rd_addr                   ),
    .rd_num                    ( rd_num                    ),
    .rd_addr_ready             ( rd_addr_ready             ),
    .rd_data_valid             ( rd_data_valid             ),
    .rd_data                   ( rd_data                   ),
    .rd_data_ready             ( rd_data_ready             ),
    .rd_strb                   ( rd_strb                   ),
    .read_all_done             (               ),
    .rd_done_intr              ( rd_done_intr              ),
    .debug_dma_rd_in_cnt       ( debug_dma_rd_in_cnt       ),
    .o_arvalid                 ( m_arvalid                 ),
    .o_arid                    ( m_arid                    ),
    .o_araddr                  ( m_araddr                  ),
    .o_arlen                   ( m_arlen                   ),
    .o_arsize                  ( m_arsize                  ),
    .o_arburst                 ( m_arburst                 ),
    .o_arlock                  ( m_arlock                  ),
    .o_arcache                 ( m_arcache                 ),
    .o_arprot                  ( m_arprot                  ),
    .i_arready                 ( m_arready                 ),
    .i_rvalid                  ( m_rvalid                  ),
    .i_rid                     ( m_rid                     ),
    .i_rlast                   ( m_rlast                   ),
    .i_rdata                   ( m_rdata                   ),
    .i_rresp                   ( m_rresp                   ),
    .o_rready                  ( m_rready                  )
);

ictrl_kernel#(
    .DATA_WIDTH        ( AXI_DW ),
    .MEM_AW            ( MEM_AW ),
    .STRB_WIDTH        ( STRB_WIDTH ),
    .FLIT_WIDTH        ( FLIT_WIDTH )
)u_ictrl_kernel(
    .clk               ( aclk              ),
    .rst_n             ( aresetn           ),
    .cfg_send_start    ( cfg_send_start    ),
    .cfg_group_info    ( cfg_group_info    ),
    .cfg_group_info_valid( cfg_group_info_valid),
    .cfg_cache_info    ( cfg_cache_info    ),
    .cfg_cache_info_valid( cfg_cache_info_valid),
    .dma_rd_req        ( rd_req            ),
    .dma_rd_data_valid ( rd_data_valid     ),
    .dma_rd_data       ( rd_data           ),
    .dma_rd_data_ready ( rd_data_ready     ),
    .dma_rd_strb       ( rd_strb           ),
    .dma_rd_num        ( rd_num            ),
    .dma_rd_addr       ( rd_addr           ),
    .ibuffer_cen       ( ibuffer_cen       ),
    .ibuffer_wen       ( ibuffer_wen       ),
    .ibuffer_ready     ( ibuffer_ready     ),
    .ibuffer_addr      ( ibuffer_addr      ),
    .ibuffer_wdata     ( ibuffer_wdata     ),
    .ibuffer_strb      ( ibuffer_strb      ),
    .ibuffer_rdata     ( ibuffer_rdata     ),
    .ibuffer_rvalid    ( ibuffer_rvalid    ),
    .ibuffer_rready    ( ibuffer_rready    ),
    .send_valid        ( send_valid        ),
    .send_flit         ( send_flit         ),
    .send_ready        ( send_ready        ),
    .recv_valid        ( recv_valid        ),
    .recv_flit         ( recv_flit         ),
    .recv_ready        ( recv_ready        ),
    .nodes_status      ( nodes_status      ),
    .nodes_intr        ( nodes_intr        )
);



ibuffer u_ibuffer(
    .clk      ( aclk     ),
    .rst_n    ( aresetn  ),
    .cen_a    ( s_axi_mem_cen ),
    .last_a   ( s_axi_mem_last),
    .ready_a  ( s_axi_mem_ready ),
    .wen_a    ( s_axi_mem_wen ),
    .addr_a   ( s_axi_mem_addr ),
    .wdata_a  ( s_axi_mem_wdata ),
    .wstrb_a  ( s_axi_mem_wstrb ),
    .rdata_a  ( s_axi_mem_rdata ),
    .rlast_a  ( s_axi_mem_rlast),
    .rvalid_a ( s_axi_mem_rvalid ),
    .rready_a ( s_axi_mem_rready ),
    .cen_b    ( ibuffer_cen ),
    .wen_b    ( ibuffer_wen ),
    .ready_b  ( ibuffer_ready ),
    .addr_b   ( ibuffer_addr ),
    .wdata_b  ( ibuffer_wdata ),
    .wstrb_b  ( ibuffer_strb ),
    .rdata_b  ( ibuffer_rdata ),
    .rvalid_b ( ibuffer_rvalid ),
    .rready_b ( ibuffer_rready )
);


axi_to_mem#(
    .DATA_WIDTH         ( AXI_DW ),
    .ADDR_WIDTH         ( AXI_AW ),
    .STRB_WIDTH         ( STRB_WIDTH ),
    .ID_WIDTH           ( ID_WIDTH ),
    .INPUT_PIPE_STAGES  ( 1 ),
    .OUTPUT_PIPE_STAGES ( 1 ),
    .MEM_LATENCY        ( 2 ),
    .MEM_ADDR_WIDTH     ( MEM_AW )
)u_axi_to_mem(
    .clk                ( aclk               ),
    .rst_n              ( aresetn            ),
    .s_axi_awid         ( s_axi_awid         ),
    .s_axi_awaddr       ( s_axi_awaddr       ),
    .s_axi_awlen        ( s_axi_awlen        ),
    .s_axi_awsize       ( s_axi_awsize       ),
    .s_axi_awburst      ( s_axi_awburst      ),
    .s_axi_awlock       ( s_axi_awlock       ),
    .s_axi_awcache      ( s_axi_awcache      ),
    .s_axi_awprot       ( s_axi_awprot       ),
    .s_axi_awvalid      ( s_axi_awvalid      ),
    .s_axi_awready      ( s_axi_awready      ),
    .s_axi_wdata        ( s_axi_wdata        ),
    .s_axi_wstrb        ( s_axi_wstrb        ),
    .s_axi_wlast        ( s_axi_wlast        ),
    .s_axi_wvalid       ( s_axi_wvalid       ),
    .s_axi_wready       ( s_axi_wready       ),
    .s_axi_bid          ( s_axi_bid          ),
    .s_axi_bresp        ( s_axi_bresp        ),
    .s_axi_bvalid       ( s_axi_bvalid       ),
    .s_axi_bready       ( s_axi_bready       ),
    .s_axi_arid         ( s_axi_arid         ),
    .s_axi_araddr       ( s_axi_araddr       ),
    .s_axi_arlen        ( s_axi_arlen        ),
    .s_axi_arsize       ( s_axi_arsize       ),
    .s_axi_arburst      ( s_axi_arburst      ),
    .s_axi_arlock       ( s_axi_arlock       ),
    .s_axi_arcache      ( s_axi_arcache      ),
    .s_axi_arprot       ( s_axi_arprot       ),
    .s_axi_arvalid      ( s_axi_arvalid      ),
    .s_axi_arready      ( s_axi_arready      ),
    .s_axi_rid          ( s_axi_rid          ),
    .s_axi_rdata        ( s_axi_rdata        ),
    .s_axi_rresp        ( s_axi_rresp        ),
    .s_axi_rlast        ( s_axi_rlast        ),
    .s_axi_rvalid       ( s_axi_rvalid       ),
    .s_axi_rready       ( s_axi_rready       ),
    .mem_cen            ( s_axi_mem_cen      ),
    .mem_last           ( s_axi_mem_last     ),
    .mem_addr           ( s_axi_mem_addr     ),
    .mem_ready          ( s_axi_mem_ready    ),
    .mem_wen            ( s_axi_mem_wen      ),
    .mem_wdata          ( s_axi_mem_wdata    ),
    .mem_wstrb          ( s_axi_mem_wstrb    ),
    .mem_rvalid         ( s_axi_mem_rvalid   ),
    .mem_rlast          ( s_axi_mem_rlast    ),
    .mem_rready         ( s_axi_mem_rready   ),
    .mem_rdata          ( s_axi_mem_rdata    )
);


endmodule