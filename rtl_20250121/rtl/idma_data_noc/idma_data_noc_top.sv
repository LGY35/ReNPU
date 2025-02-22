module idma_data_noc_top #(
  parameter DATA_FIFO_DEPTH   = 64    ,
  parameter DATA_FIFO_CNT_WID = 6+1   ,
  parameter ADDR_FIFO_DEPTH   = 32    ,
  parameter ADDR_FIFO_CNT_WID = 5+1   ,

  parameter AXI_DATA_WID      = 256   ,
  parameter AXI_ADDR_WID      = 32    ,
  parameter AXI_IDW           = 4     ,
  parameter AXI_LENW          = 4     ,
  parameter AXI_LOCKW         = 2     ,
  parameter AXI_STRBW         = 32    ,
  parameter ID                = 0
)
( 
  input                               aclk             ,
  input                               aresetn          ,
  // apb interface from IDMA_INOC
  input      [11:0]                   paddr            ,
  input      [0:0]                    psel             ,
  input                               penable          ,
  output                              pready           ,
  input                               pwrite           ,
  input      [3:0]                    pstrb            ,
  input      [2:0]                    pprot            ,
  input      [31:0]                   pwdata           ,
  output     [31:0]                   prdata           ,
  output                              pslverr          ,
  // apb interface from Cluster Decoder
  input      [11:0]                   cluster_paddr    ,
  input      [0:0]                    cluster_psel     ,
  input                               cluster_penable  ,
  output                              cluster_pready   ,
  input                               cluster_pwrite   ,
  input      [3:0]                    cluster_pstrb    ,
  input      [2:0]                    cluster_pprot    ,
  input      [31:0]                   cluster_pwdata   ,
  output     [31:0]                   cluster_prdata   ,
  output                              cluster_pslverr  ,
  // interrupt
  output                              interrupt        ,
  // noc interface
  output                              data_out_valid   ,
  output [AXI_DATA_WID-1:0]           data_out_flit    ,
  output                              data_out_last    ,
  input                               data_out_ready   ,
  input                               data_in_valid    ,
  input  [AXI_DATA_WID-1:0]           data_in_flit     ,
  input                               data_in_last     ,
  output                              data_in_ready    ,
  output                              ctrl_out_valid   ,
  output [AXI_DATA_WID-1:0]           ctrl_out_flit    ,
  output                              ctrl_out_last    ,
  input                               ctrl_out_ready   ,
  input                               ctrl_in_valid    ,
  input  [AXI_DATA_WID-1:0]           ctrl_in_flit     ,
  input                               ctrl_in_last     ,
  output                              ctrl_in_ready    ,
  //axi interface
  output                              arvalid          ,
  output [AXI_IDW-1:0]                arid             ,
  output [AXI_ADDR_WID-1:0]           araddr           ,
  output [AXI_LENW-1:0]               arlen            ,
  output [2:0]                        arsize           ,
  output [1:0]                        arburst          ,
  output [AXI_LOCKW-1:0]              arlock           ,
  output [3:0]                        arcache          ,
  output [2:0]                        arprot           ,
  input                               arready          ,
  input                               rvalid           ,
  input  [AXI_IDW-1:0]                rid              ,
  input                               rlast            ,
  input  [AXI_DATA_WID-1:0]           rdata            ,
  input  [1:0]                        rresp            ,
  output                              rready           ,
  output                              awvalid          ,
  output [AXI_IDW-1:0]                awid             ,
  output [AXI_ADDR_WID-1:0]           awaddr           ,
  output [AXI_LENW-1:0]               awlen            ,
  output [2:0]                        awsize           ,
  output [1:0]                        awburst          ,
  output [AXI_LOCKW-1:0]              awlock           ,
  output [3:0]                        awcache          ,
  output [2:0]                        awprot           ,
  input                               awready          ,
  output                              wvalid           ,
  output                              wlast            ,
  output  [AXI_DATA_WID-1:0]          wdata            ,
  output  [AXI_STRBW-1:0]             wstrb            ,
  input                               wready           ,
  input                               bvalid           ,
  input  [AXI_IDW-1:0]                bid              ,
  input  [1:0]                        bresp            ,
  output                              bready           


);

// m0
wire              rd_cfg_ready   ;
wire              rd_afifo_init   ;
wire              rd_dfifo_init   ;
wire     [3:0]    rd_cfg_outstd   ;
wire              rd_cfg_outstd_en   ;
wire              rd_cfg_cross4k_en   ;
wire              rd_cfg_arvld_hold_en   ;
wire     [6:0]    rd_cfg_dfifo_thd   ;
wire              wr_cfg_ready   ;
wire              wr_afifo_init   ;
wire              wr_dfifo_init   ;
wire     [3:0]    wr_cfg_outstd   ;
wire              wr_cfg_outstd_en   ;
wire              wr_cfg_cross4k_en   ;
wire              wr_cfg_arvld_hold_en   ;
wire              wr_cfg_arvld_hold_olen_en   ;
wire     [6:0]    wr_cfg_dfifo_thd   ;
wire              wr_cfg_strb_force   ;
wire              rd_done_intr   ;
wire              wr_done_intr   ;
wire     [15:0]   debug_dma_rd_in_cnt   ;
wire     [15:0]   debug_dma_wr_out_cnt   ;


wire     [31:0]   base_addr_0;
wire     [31:0]   base_addr_1;
wire     [31:0]   base_addr_2;
wire     [31:0]   base_addr_3;
wire     [31:0]   base_addr_4;
wire     [31:0]   base_addr_5;
wire     [31:0]   group_base_addr_0;
wire     [31:0]   group_base_addr_1;
wire     [31:0]   group_base_addr_2;
wire     [31:0]   group_base_addr_3;
wire     [31:0]   group_base_addr_4;
wire     [31:0]   group_base_addr_5;
wire     [31:0]   write_base_addr_0;
wire     [31:0]   write_base_addr_1;
wire     [31:0]   write_base_addr_2;
wire     [31:0]   write_base_addr_3;
wire     [31:0]   write_base_addr_4;
wire     [31:0]   write_base_addr_5;

idma_data_noc_regfile u_idma_data_noc_regfile(
    .io_apb_PADDR                    ( cluster_paddr                ),
    .io_apb_PSEL                     ( cluster_psel                 ),
    .io_apb_PENABLE                  ( cluster_penable              ),
    .io_apb_PREADY                   ( cluster_pready               ),
    .io_apb_PWRITE                   ( cluster_pwrite               ),
    .io_apb_PSTRB                    ( cluster_pstrb                ),
    .io_apb_PPROT                    ( cluster_pprot                ),
    .io_apb_PWDATA                   ( cluster_pwdata               ),
    .io_apb_PRDATA                   ( cluster_prdata               ),
    .io_apb_PSLVERR                  ( cluster_pslverr              ),

    .io_rd_cfg_ready                 ( rd_cfg_ready                 ),
    .io_rd_afifo_init                ( rd_afifo_init                ),
    .io_rd_dfifo_init                ( rd_dfifo_init                ),
    .io_rd_cfg_outstd                ( rd_cfg_outstd                ),
    .io_rd_cfg_outstd_en             ( rd_cfg_outstd_en             ),
    .io_rd_cfg_cross4k_en            ( rd_cfg_cross4k_en            ),
    .io_rd_cfg_arvld_hold_en         ( rd_cfg_arvld_hold_en         ),
    .io_rd_cfg_dfifo_thd             ( rd_cfg_dfifo_thd             ),
    .io_wr_cfg_ready                 ( wr_cfg_ready                 ),
    .io_wr_afifo_init                ( wr_afifo_init                ),
    .io_wr_dfifo_init                ( wr_dfifo_init                ),
    .io_wr_cfg_outstd                ( wr_cfg_outstd                ),
    .io_wr_cfg_outstd_en             ( wr_cfg_outstd_en             ),
    .io_wr_cfg_cross4k_en            ( wr_cfg_cross4k_en            ),
    .io_wr_cfg_arvld_hold_en         ( wr_cfg_arvld_hold_en         ),
    .io_wr_cfg_arvld_hold_olen_en    ( wr_cfg_arvld_hold_olen_en    ),
    .io_wr_cfg_dfifo_thd             ( wr_cfg_dfifo_thd             ),
    .io_wr_cfg_strb_force            ( wr_cfg_strb_force            ),
    .io_rd_done_intr                 ( rd_done_intr                 ),
    .io_wr_done_intr                 ( wr_done_intr                 ),
    .io_debug_dma_rd_in_cnt          ( debug_dma_rd_in_cnt          ),
    .io_debug_dma_wr_out_cnt         ( debug_dma_wr_out_cnt         ),
    .io_intr                         ( interrupt                    ),
    .clk                             ( aclk                         ),
    .resetn                          ( aresetn                      )
);

idma_data_noc_base_addr_regfile u_idma_data_noc_base_addr_regfile(
    .io_apb_PADDR                    ( paddr                        ),
    .io_apb_PSEL                     ( psel                         ),
    .io_apb_PENABLE                  ( penable                      ),
    .io_apb_PREADY                   ( pready                       ),
    .io_apb_PWRITE                   ( pwrite                       ),
    .io_apb_PSTRB                    ( pstrb                        ),
    .io_apb_PPROT                    ( pprot                        ),
    .io_apb_PWDATA                   ( pwdata                       ),
    .io_apb_PRDATA                   ( prdata                       ),
    .io_apb_PSLVERR                  ( pslverr                      ),
    .io_base_addr_0                  ( base_addr_0                  ),
    .io_base_addr_1                  ( base_addr_1                  ),
    .io_base_addr_2                  ( base_addr_2                  ),
    .io_base_addr_3                  ( base_addr_3                  ),
    .io_base_addr_4                  ( base_addr_4                  ),
    .io_base_addr_5                  ( base_addr_5                  ),
    .io_group_base_addr_0            ( group_base_addr_0            ),
    .io_group_base_addr_1            ( group_base_addr_1            ),
    .io_group_base_addr_2            ( group_base_addr_2            ),
    .io_group_base_addr_3            ( group_base_addr_3            ),
    .io_group_base_addr_4            ( group_base_addr_4            ),
    .io_group_base_addr_5            ( group_base_addr_5            ),
    .io_write_base_addr_0            ( write_base_addr_0            ),
    .io_write_base_addr_1            ( write_base_addr_1            ),
    .io_write_base_addr_2            ( write_base_addr_2            ),
    .io_write_base_addr_3            ( write_base_addr_3            ),
    .io_write_base_addr_4            ( write_base_addr_4            ),
    .io_write_base_addr_5            ( write_base_addr_5            ),
    .clk                             ( aclk                         ),
    .resetn                          ( aresetn                      )
);


wire [DATA_FIFO_CNT_WID-1: 0]    rd_dfifo_word_cnt          ;
wire [ADDR_FIFO_CNT_WID-1: 0]    rd_afifo_word_cnt          ;
wire [DATA_FIFO_CNT_WID-1: 0]    wr_dfifo_word_cnt          ;
wire [ADDR_FIFO_CNT_WID-1: 0]    wr_afifo_word_cnt          ;
wire [AXI_IDW-1:0]               wid;

idma_data_noc_kernel#(
    .DATA_FIFO_DEPTH        (DATA_FIFO_DEPTH  ),
    .DATA_FIFO_CNT_WID      (DATA_FIFO_CNT_WID),
    .ADDR_FIFO_DEPTH        (ADDR_FIFO_DEPTH  ),
    .ADDR_FIFO_CNT_WID      (ADDR_FIFO_CNT_WID),
    .AXI_DATA_WID           ( AXI_DATA_WID ),
    .AXI_ADDR_WID           ( AXI_ADDR_WID ),
    .AXI_IDW                ( AXI_IDW ),
    .AXI_LENW               ( AXI_LENW ),
    .AXI_LOCKW              ( AXI_LOCKW ),
    .AXI_STRBW              ( AXI_STRBW ),
    .ID                     ( ID        )
)u_idma_data_noc_kernel(
    .aclk                      ( aclk                      ),
    .aresetn                   ( aresetn                   ),

    .idma_cfg_ready               ( {rd_cfg_ready   , wr_cfg_ready   } ),
    .rd_afifo_init                ( rd_afifo_init                ),
    .rd_dfifo_init                ( rd_dfifo_init                ),
    .rd_dfifo_word_cnt            ( rd_dfifo_word_cnt            ),
    .rd_afifo_word_cnt            ( rd_afifo_word_cnt            ),
    .rd_cfg_outstd                ( rd_cfg_outstd                ),
    .rd_cfg_outstd_en             ( rd_cfg_outstd_en             ),
    .rd_cfg_cross4k_en            ( rd_cfg_cross4k_en            ),
    .rd_cfg_arvld_hold_en         ( rd_cfg_arvld_hold_en         ),
    .rd_cfg_dfifo_thd             ( rd_cfg_dfifo_thd             ),
    .rd_done_intr                 ( rd_done_intr                 ),
    .wr_afifo_init                ( wr_afifo_init                ),
    .wr_dfifo_init                ( wr_dfifo_init                ),
    .wr_dfifo_word_cnt            ( wr_dfifo_word_cnt            ),
    .wr_afifo_word_cnt            ( wr_afifo_word_cnt            ),
    .wr_cfg_outstd                ( wr_cfg_outstd                ),
    .wr_cfg_outstd_en             ( wr_cfg_outstd_en             ),
    .wr_cfg_cross4k_en            ( wr_cfg_cross4k_en            ),
    .wr_cfg_arvld_hold_en         ( wr_cfg_arvld_hold_en         ),
    .wr_cfg_arvld_hold_olen_en    ( wr_cfg_arvld_hold_olen_en    ),
    .wr_cfg_dfifo_thd             ( wr_cfg_dfifo_thd             ),
    .wr_cfg_strb_force            ( wr_cfg_strb_force            ),
    .wr_done_intr                 ( wr_done_intr                 ),
    .debug_dma_rd_in_cnt          ( debug_dma_rd_in_cnt          ),
    .debug_dma_wr_out_cnt         ( debug_dma_wr_out_cnt         ),

    .arvalid                      ( arvalid                      ),
    .arid                         ( arid                         ),
    .araddr                       ( araddr                       ),
    .arlen                        ( arlen                        ),
    .arsize                       ( arsize                       ),
    .arburst                      ( arburst                      ),
    .arlock                       ( arlock                       ),
    .arcache                      ( arcache                      ),
    .arprot                       ( arprot                       ),
    .arready                      ( arready                      ),
    .rvalid                       ( rvalid                       ),
    .rid                          ( rid                          ),
    .rlast                        ( rlast                        ),
    .rdata                        ( rdata                        ),
    .rresp                        ( rresp                        ),
    .rready                       ( rready                       ),
    .awvalid                      ( awvalid                      ),
    .awid                         ( awid                         ),
    .awaddr                       ( awaddr                       ),
    .awlen                        ( awlen                        ),
    .awsize                       ( awsize                       ),
    .awburst                      ( awburst                      ),
    .awlock                       ( awlock                       ),
    .awcache                      ( awcache                      ),
    .awprot                       ( awprot                       ),
    .awready                      ( awready                      ),
    .wvalid                       ( wvalid                       ),
    .wid                          ( wid                          ),
    .wlast                        ( wlast                        ),
    .wdata                        ( wdata                        ),
    .wstrb                        ( wstrb                        ),
    .wready                       ( wready                       ),
    .bvalid                       ( bvalid                       ),
    .bid                          ( bid                          ),
    .bresp                        ( bresp                        ),
    .bready                       ( bready                       ),

    .base_addr_0                  ( base_addr_0               ),
    .base_addr_1                  ( base_addr_1               ),
    .base_addr_2                  ( base_addr_2               ),
    .base_addr_3                  ( base_addr_3               ),
    .base_addr_4                  ( base_addr_4               ),
    .base_addr_5                  ( base_addr_5               ),
    .group_base_addr_0            ( group_base_addr_0            ),
    .group_base_addr_1            ( group_base_addr_1            ),
    .group_base_addr_2            ( group_base_addr_2            ),
    .group_base_addr_3            ( group_base_addr_3            ),
    .group_base_addr_4            ( group_base_addr_4            ),
    .group_base_addr_5            ( group_base_addr_5            ),
    .write_base_addr_0            ( write_base_addr_0            ),
    .write_base_addr_1            ( write_base_addr_1            ),
    .write_base_addr_2            ( write_base_addr_2            ),
    .write_base_addr_3            ( write_base_addr_3            ),
    .write_base_addr_4            ( write_base_addr_4            ),
    .write_base_addr_5            ( write_base_addr_5            ),

    .data_out_valid               ( data_out_valid                ),
    .data_out_flit                ( data_out_flit                 ),
    .data_out_last                ( data_out_last                 ),
    .data_out_ready               ( data_out_ready                ),
    .data_in_valid                ( data_in_valid                 ),
    .data_in_flit                 ( data_in_flit                  ),
    .data_in_last                 ( data_in_last                  ),
    .data_in_ready                ( data_in_ready                 ),

    .ctrl_out_valid               ( ctrl_out_valid                ),
    .ctrl_out_flit                ( ctrl_out_flit                 ),
    .ctrl_out_last                ( ctrl_out_last                 ),
    .ctrl_out_ready               ( ctrl_out_ready                ),
    .ctrl_in_valid                ( ctrl_in_valid                 ),
    .ctrl_in_flit                 ( ctrl_in_flit                  ),
    .ctrl_in_last                 ( ctrl_in_last                  ),
    .ctrl_in_ready                ( ctrl_in_ready                 )
);

endmodule