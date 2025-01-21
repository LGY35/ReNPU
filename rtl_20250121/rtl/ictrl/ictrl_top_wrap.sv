module ictrl_top_wrap 
#(
    parameter AXI_DW = 128,
    parameter AXI_AW = 32,
    parameter STRB_WIDTH = (AXI_DW/8),
    parameter ID_WIDTH = 8,
    parameter AXI_LENW = 4,
    parameter AXI_LOCKW = 1,
    parameter FLIT_WIDTH = 32,

    parameter AXI4_ADDRESS_WIDTH = 32,
    parameter AXI4_RDATA_WIDTH   = 32,
    parameter AXI4_WDATA_WIDTH   = 32,
    parameter AXI4_ID_WIDTH      = 8,
    parameter AXI4_USER_WIDTH    = 1,
    parameter AXI_NUMBYTES       = AXI4_WDATA_WIDTH/8,
    parameter BUFF_DEPTH_SLAVE   = 4,
    parameter APB_ADDR_WIDTH     = 12
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

    // config AXI slave port
    input   [AXI4_ID_WIDTH-1:0]       cfg_awid,
    input   [AXI4_ADDRESS_WIDTH-1:0]  cfg_awaddr,
    input   [7:0]                     cfg_awlen,
    input   [2:0]                     cfg_awsize,
    input   [1:0]                     cfg_awburst,
    input                             cfg_awlock,
    input   [3:0]                     cfg_awcache,
    input   [2:0]                     cfg_awprot,
    input                             cfg_awvalid,
    output                            cfg_awready,
    input   [AXI4_WDATA_WIDTH-1:0]    cfg_wdata,
    input   [AXI_NUMBYTES-1:0]        cfg_wstrb,
    input                             cfg_wlast,
    input                             cfg_wvalid,
    output                            cfg_wready,
    output  [AXI4_ID_WIDTH-1:0]       cfg_bid,
    output  [1:0]                     cfg_bresp,
    output                            cfg_bvalid,
    input                             cfg_bready,
    input   [AXI4_ID_WIDTH-1:0]       cfg_arid,
    input   [AXI4_ADDRESS_WIDTH-1:0]  cfg_araddr,
    input   [7:0]                     cfg_arlen,
    input   [2:0]                     cfg_arsize,
    input   [1:0]                     cfg_arburst,
    input                             cfg_arlock,
    input   [3:0]                     cfg_arcache,
    input   [2:0]                     cfg_arprot,
    input                             cfg_arvalid,
    output                            cfg_arready,
    output  [AXI4_ID_WIDTH-1:0]       cfg_rid,
    output  [AXI4_RDATA_WIDTH-1:0]    cfg_rdata,
    output  [1:0]                     cfg_rresp,
    output                            cfg_rlast,
    output                            cfg_rvalid,
    input                             cfg_rready,

    // send to noc
    output [11:0]           send_valid ,
    output [FLIT_WIDTH-1:0] send_flit  [11:0],
    input  [11:0]           send_ready ,

    // receive from noc
    input  [11:0]           recv_valid ,
    input  [FLIT_WIDTH-1:0] recv_flit  [11:0],
    output [11:0]           recv_ready ,
    

    // interrupt
    output                            ictrl_interrupt
);

parameter MEM_AW = 15;
parameter DATA_FIFO_DEPTH   = 64    ;
parameter DATA_FIFO_CNT_WID = 6+1   ;
parameter ADDR_FIFO_DEPTH   = 32    ;
parameter ADDR_FIFO_CNT_WID = 5+1   ;

wire                              rd_cfg_ready        ;
wire                              rd_afifo_init       ;
wire                              rd_dfifo_init       ;
wire  [ADDR_FIFO_CNT_WID-1: 0]    rd_afifo_word_cnt   ;
wire  [DATA_FIFO_CNT_WID-1: 0]    rd_dfifo_word_cnt   ;
wire  [3:0]			              rd_cfg_outstd       ;
wire     			              rd_cfg_outstd_en    ;
wire                              rd_cfg_cross4k_en   ;
wire                              rd_cfg_arvld_hold_en;
wire [DATA_FIFO_CNT_WID-1:0]      rd_cfg_dfifo_thd    ;
wire                              rd_resi_mode        ;//1:resi 0:norm
wire [AXI_AW-1:0]                 rd_resi_fmapA_addr  ;
wire [AXI_AW-1:0]                 rd_resi_fmapB_addr  ;
wire [16-1:0]                     rd_resi_addr_gap    ;
wire [16-1:0]                     rd_resi_loop_num    ;
wire                              rd_req              ;
wire [AXI_AW-1:0]                 rd_addr             ;
wire [31:0]                       rd_num              ;
wire                              rd_addr_ready       ;
wire                              rd_done_intr        ;
wire [16-1:0]                     debug_dma_rd_in_cnt ;
wire                              cfg_send_start      ;
wire [FLIT_WIDTH-1:0]             cfg_group_info      ;
wire                              cfg_group_info_valid;
wire [FLIT_WIDTH-1:0]             cfg_cache_info       ;
wire                              cfg_cache_info_valid ;
wire [11:0]                       nodes_status;
wire                              nodes_intr;


ictrl_top#(
    .AXI_DW            ( AXI_DW ),
    .AXI_AW            ( AXI_AW ),
    .STRB_WIDTH        ( STRB_WIDTH ),
    .ID_WIDTH          ( ID_WIDTH ),
    .AXI_LENW          ( AXI_LENW ),
    .AXI_LOCKW         ( AXI_LOCKW ),
    .MEM_AW            ( MEM_AW ),
    .FLIT_WIDTH        ( FLIT_WIDTH ),
    .DATA_FIFO_DEPTH   ( DATA_FIFO_DEPTH ),
    .DATA_FIFO_CNT_WID ( DATA_FIFO_CNT_WID ),
    .ADDR_FIFO_DEPTH   ( ADDR_FIFO_DEPTH ),
    .ADDR_FIFO_CNT_WID ( ADDR_FIFO_CNT_WID )
)u_ictrl_top(
    .aclk              ( aclk                 ),
    .aresetn           ( aresetn              ),
    .s_axi_awid        ( s_axi_awid           ),
    .s_axi_awaddr      ( s_axi_awaddr         ),
    .s_axi_awlen       ( s_axi_awlen          ),
    .s_axi_awsize      ( s_axi_awsize         ),
    .s_axi_awburst     ( s_axi_awburst        ),
    .s_axi_awlock      ( s_axi_awlock         ),
    .s_axi_awcache     ( s_axi_awcache        ),
    .s_axi_awprot      ( s_axi_awprot         ),
    .s_axi_awvalid     ( s_axi_awvalid        ),
    .s_axi_awready     ( s_axi_awready        ),
    .s_axi_wdata       ( s_axi_wdata          ),
    .s_axi_wstrb       ( s_axi_wstrb          ),
    .s_axi_wlast       ( s_axi_wlast          ),
    .s_axi_wvalid      ( s_axi_wvalid         ),
    .s_axi_wready      ( s_axi_wready         ),
    .s_axi_bid         ( s_axi_bid            ),
    .s_axi_bresp       ( s_axi_bresp          ),
    .s_axi_bvalid      ( s_axi_bvalid         ),
    .s_axi_bready      ( s_axi_bready         ),
    .s_axi_arid        ( s_axi_arid           ),
    .s_axi_araddr      ( s_axi_araddr         ),
    .s_axi_arlen       ( s_axi_arlen          ),
    .s_axi_arsize      ( s_axi_arsize         ),
    .s_axi_arburst     ( s_axi_arburst        ),
    .s_axi_arlock      ( s_axi_arlock         ),
    .s_axi_arcache     ( s_axi_arcache        ),
    .s_axi_arprot      ( s_axi_arprot         ),
    .s_axi_arvalid     ( s_axi_arvalid        ),
    .s_axi_arready     ( s_axi_arready        ),
    .s_axi_rid         ( s_axi_rid            ),
    .s_axi_rdata       ( s_axi_rdata          ),
    .s_axi_rresp       ( s_axi_rresp          ),
    .s_axi_rlast       ( s_axi_rlast          ),
    .s_axi_rvalid      ( s_axi_rvalid         ),
    .s_axi_rready      ( s_axi_rready         ),
    .m_arvalid         ( m_arvalid            ),
    .m_arid            ( m_arid               ),
    .m_araddr          ( m_araddr             ),
    .m_arlen           ( m_arlen              ),
    .m_arsize          ( m_arsize             ),
    .m_arburst         ( m_arburst            ),
    .m_arlock          ( m_arlock             ),
    .m_arcache         ( m_arcache            ),
    .m_arprot          ( m_arprot             ),
    .m_arready         ( m_arready            ),
    .m_rvalid          ( m_rvalid             ),
    .m_rid             ( m_rid                ),
    .m_rlast           ( m_rlast              ),
    .m_rdata           ( m_rdata              ),
    .m_rresp           ( m_rresp              ),
    .m_rready          ( m_rready             ),
    .rd_cfg_ready      ( rd_cfg_ready         ),
    .rd_afifo_init     ( rd_afifo_init        ),
    .rd_dfifo_init     ( rd_dfifo_init        ),
    .rd_dfifo_word_cnt ( rd_dfifo_word_cnt    ),
    .rd_afifo_word_cnt ( rd_afifo_word_cnt    ),
    .rd_cfg_outstd     ( rd_cfg_outstd        ),
    .rd_cfg_outstd_en  ( rd_cfg_outstd_en     ),
    .rd_cfg_cross4k_en ( rd_cfg_cross4k_en    ),
    .rd_cfg_arvld_hold_en( rd_cfg_arvld_hold_en ),
    .rd_cfg_dfifo_thd  ( rd_cfg_dfifo_thd     ),
    .rd_resi_mode      ( rd_resi_mode         ),
    .rd_resi_fmapA_addr( rd_resi_fmapA_addr   ),
    .rd_resi_fmapB_addr( rd_resi_fmapB_addr   ),
    .rd_resi_addr_gap  ( rd_resi_addr_gap     ),
    .rd_resi_loop_num  ( rd_resi_loop_num     ),
    .rd_req            ( rd_req               ),
    .rd_addr           ( rd_addr              ),
    .rd_num            ( rd_num               ),
    .rd_addr_ready     ( rd_addr_ready        ),
    .rd_done_intr      ( rd_done_intr         ),
    .debug_dma_rd_in_cnt( debug_dma_rd_in_cnt  ),
    .cfg_send_start    ( cfg_send_start    ),
    .cfg_group_info    ( cfg_group_info    ),
    .cfg_group_info_valid( cfg_group_info_valid),
    .cfg_cache_info    ( cfg_cache_info    ),
    .cfg_cache_info_valid( cfg_cache_info_valid),
    .send_valid        ( send_valid        ),
    .send_flit         ( send_flit         ),
    .send_ready        ( send_ready        ),
    .recv_valid        ( recv_valid        ),
    .recv_flit         ( recv_flit         ),
    .recv_ready        ( recv_ready        ),
    .nodes_status      ( nodes_status      ),
    .nodes_intr        ( nodes_intr        )

);

ictrl_axi_config#(
    .AXI4_ADDRESS_WIDTH         ( AXI4_ADDRESS_WIDTH ),
    .AXI4_RDATA_WIDTH           ( AXI4_RDATA_WIDTH ),
    .AXI4_WDATA_WIDTH           ( AXI4_WDATA_WIDTH ),
    .AXI4_ID_WIDTH              ( AXI4_ID_WIDTH ),
    .AXI4_USER_WIDTH            ( AXI4_USER_WIDTH  ),
    .AXI_NUMBYTES               ( AXI_NUMBYTES ),
    .BUFF_DEPTH_SLAVE           ( BUFF_DEPTH_SLAVE ),
    .APB_ADDR_WIDTH             ( APB_ADDR_WIDTH )
)u_ictrl_axi_config(
    .aclk                       ( aclk                       ),
    .aresetn                    ( aresetn                    ),
    .awid                       ( cfg_awid                   ),
    .awaddr                     ( cfg_awaddr                 ),
    .awlen                      ( cfg_awlen                  ),
    .awsize                     ( cfg_awsize                 ),
    .awburst                    ( cfg_awburst                ),
    .awlock                     ( cfg_awlock                 ),
    .awcache                    ( cfg_awcache                ),
    .awprot                     ( cfg_awprot                 ),
    .awvalid                    ( cfg_awvalid                ),
    .awready                    ( cfg_awready                ),
    .wdata                      ( cfg_wdata                  ),
    .wstrb                      ( cfg_wstrb                  ),
    .wlast                      ( cfg_wlast                  ),
    .wvalid                     ( cfg_wvalid                 ),
    .wready                     ( cfg_wready                 ),
    .bid                        ( cfg_bid                    ),
    .bresp                      ( cfg_bresp                  ),
    .bvalid                     ( cfg_bvalid                 ),
    .bready                     ( cfg_bready                 ),
    .arid                       ( cfg_arid                   ),
    .araddr                     ( cfg_araddr                 ),
    .arlen                      ( cfg_arlen                  ),
    .arsize                     ( cfg_arsize                 ),
    .arburst                    ( cfg_arburst                ),
    .arlock                     ( cfg_arlock                 ),
    .arcache                    ( cfg_arcache                ),
    .arprot                     ( cfg_arprot                 ),
    .arvalid                    ( cfg_arvalid                ),
    .arready                    ( cfg_arready                ),
    .rid                        ( cfg_rid                    ),
    .rdata                      ( cfg_rdata                  ),
    .rresp                      ( cfg_rresp                  ),
    .rlast                      ( cfg_rlast                  ),
    .rvalid                     ( cfg_rvalid                 ),
    .rready                     ( cfg_rready                 ),
    .io_rd_cfg_ready            ( rd_cfg_ready               ),
    .io_rd_afifo_init           ( rd_afifo_init              ),
    .io_rd_dfifo_init           ( rd_dfifo_init              ),
    .io_rd_cfg_outstd           ( rd_cfg_outstd              ),
    .io_rd_cfg_outstd_en        ( rd_cfg_outstd_en           ),
    .io_rd_cfg_cross4k_en       ( rd_cfg_cross4k_en          ),
    .io_rd_cfg_arvld_hold_en    ( rd_cfg_arvld_hold_en       ),
    .io_rd_cfg_dfifo_thd        ( rd_cfg_dfifo_thd           ),
    .io_rd_cfg_resi_mode        ( rd_resi_mode               ),
    .io_rd_cfg_resi_fmap_a_addr ( rd_resi_fmapA_addr         ),
    .io_rd_cfg_resi_fmap_b_addr ( rd_resi_fmapB_addr         ),
    .io_rd_cfg_resi_addr_gap    ( rd_resi_addr_gap           ),
    .io_rd_cfg_resi_loop_num    ( rd_resi_loop_num           ),
    .io_rd_req                  ( rd_req                     ),
    .io_rd_addr                 ( rd_addr                    ),
    .io_rd_num                  ( rd_num                     ),
    .io_flit_send               ( cfg_send_start             ),
    .io_group_info              ( cfg_group_info             ),
    .io_cache_info              ( cfg_cache_info             ),
    .io_group_info_valid        ( cfg_group_info_valid       ),
    .io_cache_info_valid        ( cfg_cache_info_valid       ),
    .io_rd_done_intr            ( rd_done_intr               ),
    .io_nodes_intr              ( nodes_intr                 ),
    .io_debug_dma_rd_in_cnt     ( debug_dma_rd_in_cnt        ),
    .io_nodes_status            ( nodes_status               ),
    .io_intr                    ( ictrl_interrupt            ),
    .rd_addr_ready              ( rd_addr_ready              )
);



endmodule