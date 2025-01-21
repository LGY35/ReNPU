module idma_sync_256b_noc_top_apb #(
  parameter DATA_FIFO_DEPTH   = 64    ,
  parameter DATA_FIFO_CNT_WID = 6+1   ,
  parameter ADDR_FIFO_DEPTH   = 32    ,
  parameter ADDR_FIFO_CNT_WID = 5+1   ,

  parameter AXI_DATA_WID      = 256   ,
  parameter AXI_ADDR_WID      = 32    ,
  parameter AXI_IDW           = 4     ,
  parameter AXI_LENW          = 4     ,
  parameter AXI_LOCKW         = 2     ,
  parameter AXI_STRBW         = 32    
)
( 
  input               aclk                    ,
  input               aresetn                 ,
  // apb interface
  input      [11:0]   apb_PADDR,
  input      [0:0]    apb_PSEL,
  input               apb_PENABLE,
  output              apb_PREADY,
  input               apb_PWRITE,
  input      [3:0]    apb_PSTRB,
  input      [2:0]    apb_PPROT,
  input      [31:0]   apb_PWDATA,
  output     [31:0]   apb_PRDATA,
  output              apb_PSLVERR,
  // interrupt
  output              interrupt,
  // noc interface
  output                              send_valid    ,
  output [AXI_DATA_WID-1:0]           send_flit     ,
  output                              send_last     ,
  input                               send_ready    ,
  input                               recv_valid    ,
  input  [AXI_DATA_WID-1:0]           recv_flit     ,
  input                               recv_last     ,
  output                              recv_ready    ,
  //axi interface
  output                             	arvalid               ,
  output [AXI_IDW-1:0]               	arid                  ,
  output [AXI_ADDR_WID-1:0]           araddr                ,
  output [AXI_LENW-1:0]              	arlen                 ,
  output [2:0]                       	arsize                ,
  output [1:0]                       	arburst               ,
  output [AXI_LOCKW-1:0]             	arlock                ,
  output [3:0]                       	arcache               ,
  output [2:0]                       	arprot                ,
  input                              	arready               ,
  input                              	rvalid                ,
  input  [AXI_IDW-1:0]               	rid                   ,
  input                              	rlast                 ,
  input  [AXI_DATA_WID-1:0]          	rdata                 ,
  input  [1:0]                       	rresp                 ,
  output                             	rready                ,
  output                             	awvalid               ,
  output [AXI_IDW-1:0]               	awid                  ,
  output [AXI_ADDR_WID-1:0]           awaddr                ,
  output [AXI_LENW-1:0]              	awlen                 ,
  output [2:0]                       	awsize                ,
  output [1:0]                       	awburst               ,
  output [AXI_LOCKW-1:0]             	awlock                ,
  output [3:0]                       	awcache               ,
  output [2:0]                       	awprot                ,
  input                              	awready               ,
  output                              wvalid                ,
  output  [AXI_IDW-1:0]               wid                   ,
  output                              wlast                 ,
  output  [AXI_DATA_WID-1:0]          wdata                 ,
  output  [AXI_STRBW-1:0]             wstrb                 ,
  input                             	wready                ,
  input                               bvalid                ,
  input  [AXI_IDW-1:0]                bid                   ,
  input  [1:0]                        bresp                 ,
  output                              bready                


);


wire              rd_cfg_ready;
wire              rd_afifo_init;
wire              rd_dfifo_init;
wire     [3:0]    rd_cfg_outstd;
wire              rd_cfg_outstd_en;
wire              rd_cfg_cross4k_en;
wire              rd_cfg_arvld_hold_en;
wire     [6:0]    rd_cfg_dfifo_thd;
wire              rd_cfg_resi_mode;
wire     [31:0]   rd_cfg_resi_fmap_a_addr;
wire     [31:0]   rd_cfg_resi_fmap_b_addr;
wire     [15:0]   rd_cfg_resi_addr_gap;
wire     [15:0]   rd_cfg_resi_loop_num;
wire              wr_cfg_ready;
wire              wr_afifo_init;
wire              wr_dfifo_init;
wire     [3:0]    wr_cfg_outstd;
wire              wr_cfg_outstd_en;
wire              wr_cfg_cross4k_en;
wire              wr_cfg_arvld_hold_en;
wire              wr_cfg_arvld_hold_olen_en;
wire     [6:0]    wr_cfg_dfifo_thd;
wire              wr_cfg_strb_force;
wire              rd_done_intr;
wire              wr_done_intr;
wire     [15:0]   debug_dma_rd_in_cnt;
wire     [15:0]   debug_dma_wr_out_cnt;
wire     [31:0]   base_addr_0;
wire     [31:0]   base_addr_1;
wire     [31:0]   base_addr_2;
wire     [31:0]   base_addr_3;
wire     [31:0]   base_addr_4;
wire     [31:0]   base_addr_5;
wire     [31:0]   base_addr_6;
wire     [31:0]   base_addr_7;
wire     [31:0]   base_addr_8;
wire     [31:0]   base_addr_9;
wire     [31:0]   base_addr_10;
wire     [31:0]   base_addr_11;

idma_regfile u_idma_regfile(
    .io_apb_PADDR                 ( apb_PADDR                 ),
    .io_apb_PSEL                  ( apb_PSEL                  ),
    .io_apb_PENABLE               ( apb_PENABLE               ),
    .io_apb_PREADY                ( apb_PREADY                ),
    .io_apb_PWRITE                ( apb_PWRITE                ),
    .io_apb_PSTRB                 ( apb_PSTRB                 ),
    .io_apb_PPROT                 ( apb_PPROT                 ),
    .io_apb_PWDATA                ( apb_PWDATA                ),
    .io_apb_PRDATA                ( apb_PRDATA                ),
    .io_apb_PSLVERR               ( apb_PSLVERR               ),
    .io_rd_cfg_ready              ( rd_cfg_ready              ),
    .io_rd_afifo_init             ( rd_afifo_init             ),
    .io_rd_dfifo_init             ( rd_dfifo_init             ),
    .io_rd_cfg_outstd             ( rd_cfg_outstd             ),
    .io_rd_cfg_outstd_en          ( rd_cfg_outstd_en          ),
    .io_rd_cfg_cross4k_en         ( rd_cfg_cross4k_en         ),
    .io_rd_cfg_arvld_hold_en      ( rd_cfg_arvld_hold_en      ),
    .io_rd_cfg_dfifo_thd          ( rd_cfg_dfifo_thd          ),
    .io_rd_cfg_resi_mode          ( rd_cfg_resi_mode          ),
    .io_rd_cfg_resi_fmap_a_addr   ( rd_cfg_resi_fmap_a_addr   ),
    .io_rd_cfg_resi_fmap_b_addr   ( rd_cfg_resi_fmap_b_addr   ),
    .io_rd_cfg_resi_addr_gap      ( rd_cfg_resi_addr_gap      ),
    .io_rd_cfg_resi_loop_num      ( rd_cfg_resi_loop_num      ),
    .io_wr_cfg_ready              ( wr_cfg_ready              ),
    .io_wr_afifo_init             ( wr_afifo_init             ),
    .io_wr_dfifo_init             ( wr_dfifo_init             ),
    .io_wr_cfg_outstd             ( wr_cfg_outstd             ),
    .io_wr_cfg_outstd_en          ( wr_cfg_outstd_en          ),
    .io_wr_cfg_cross4k_en         ( wr_cfg_cross4k_en         ),
    .io_wr_cfg_arvld_hold_en      ( wr_cfg_arvld_hold_en      ),
    .io_wr_cfg_arvld_hold_olen_en ( wr_cfg_arvld_hold_olen_en ),
    .io_wr_cfg_dfifo_thd          ( wr_cfg_dfifo_thd          ),
    .io_wr_cfg_strb_force         ( wr_cfg_strb_force         ),
    .io_rd_done_intr              ( rd_done_intr              ),
    .io_wr_done_intr              ( wr_done_intr              ),
    .io_debug_dma_rd_in_cnt       ( debug_dma_rd_in_cnt       ),
    .io_debug_dma_wr_out_cnt      ( debug_dma_wr_out_cnt      ),
    .io_base_addr_0               ( base_addr_0               ),
    .io_base_addr_1               ( base_addr_1               ),
    .io_base_addr_2               ( base_addr_2               ),
    .io_base_addr_3               ( base_addr_3               ),
    .io_base_addr_4               ( base_addr_4               ),
    .io_base_addr_5               ( base_addr_5               ),
    .io_base_addr_6               ( base_addr_6               ),
    .io_base_addr_7               ( base_addr_7               ),
    .io_base_addr_8               ( base_addr_8               ),
    .io_base_addr_9               ( base_addr_9               ),
    .io_base_addr_10              ( base_addr_10              ),
    .io_base_addr_11              ( base_addr_11              ),
    .io_intr                      ( interrupt                      ),
    .clk                          ( aclk                          ),
    .resetn                       ( aresetn                       )
);

wire [DATA_FIFO_CNT_WID-1: 0]    rd_dfifo_word_cnt       ;
wire [ADDR_FIFO_CNT_WID-1: 0]    rd_afifo_word_cnt       ;
wire [DATA_FIFO_CNT_WID-1: 0]    wr_dfifo_word_cnt       ;
wire [ADDR_FIFO_CNT_WID-1: 0]    wr_afifo_word_cnt       ;

idma_sync_256b_noc_top#(
    .DATA_FIFO_DEPTH        (DATA_FIFO_DEPTH  ),
    .DATA_FIFO_CNT_WID      (DATA_FIFO_CNT_WID),
    .ADDR_FIFO_DEPTH        (ADDR_FIFO_DEPTH  ),
    .ADDR_FIFO_CNT_WID      (ADDR_FIFO_CNT_WID),
    .AXI_DATA_WID           ( AXI_DATA_WID ),
    .AXI_ADDR_WID           ( AXI_ADDR_WID ),
    .AXI_IDW                ( AXI_IDW ),
    .AXI_LENW               ( AXI_LENW ),
    .AXI_LOCKW              ( AXI_LOCKW ),
    .AXI_STRBW              ( AXI_STRBW )
)u_idma_sync_256b_noc_top(
    .aclk                      ( aclk                      ),
    .aresetn                   ( aresetn                   ),
    .idma_cfg_ready            ( {rd_cfg_ready, wr_cfg_ready} ),
    .rd_afifo_init             ( rd_afifo_init             ),
    .rd_dfifo_init             ( rd_dfifo_init             ),
    .rd_dfifo_word_cnt         ( rd_dfifo_word_cnt         ),
    .rd_afifo_word_cnt         ( rd_afifo_word_cnt         ),
    .rd_cfg_outstd             ( rd_cfg_outstd             ),
    .rd_cfg_outstd_en          ( rd_cfg_outstd_en          ),
    .rd_cfg_cross4k_en         ( rd_cfg_cross4k_en         ),
    .rd_cfg_arvld_hold_en      ( rd_cfg_arvld_hold_en      ),
    .rd_cfg_dfifo_thd          ( rd_cfg_dfifo_thd          ),
    .rd_resi_mode              ( rd_cfg_resi_mode          ),
    .rd_resi_fmapA_addr        ( rd_cfg_resi_fmap_a_addr   ),
    .rd_resi_fmapB_addr        ( rd_cfg_resi_fmap_b_addr   ),
    .rd_resi_addr_gap          ( rd_cfg_resi_addr_gap      ),
    .rd_resi_loop_num          ( rd_cfg_resi_loop_num      ),
    .rd_done_intr              ( rd_done_intr              ),
    .wr_afifo_init             ( wr_afifo_init             ),
    .wr_dfifo_init             ( wr_dfifo_init             ),
    .wr_dfifo_word_cnt         ( wr_dfifo_word_cnt         ),
    .wr_afifo_word_cnt         ( wr_afifo_word_cnt         ),
    .wr_cfg_outstd             ( wr_cfg_outstd             ),
    .wr_cfg_outstd_en          ( wr_cfg_outstd_en          ),
    .wr_cfg_cross4k_en         ( wr_cfg_cross4k_en         ),
    .wr_cfg_arvld_hold_en      ( wr_cfg_arvld_hold_en      ),
    .wr_cfg_arvld_hold_olen_en ( wr_cfg_arvld_hold_olen_en ),
    .wr_cfg_dfifo_thd          ( wr_cfg_dfifo_thd          ),
    .wr_cfg_strb_force         ( wr_cfg_strb_force         ),
    .wr_done_intr              ( wr_done_intr              ),
    .debug_dma_rd_in_cnt       ( debug_dma_rd_in_cnt       ),
    .debug_dma_wr_out_cnt      ( debug_dma_wr_out_cnt      ),
    .arvalid                   ( arvalid                   ),
    .arid                      ( arid                      ),
    .araddr                    ( araddr                    ),
    .arlen                     ( arlen                     ),
    .arsize                    ( arsize                    ),
    .arburst                   ( arburst                   ),
    .arlock                    ( arlock                    ),
    .arcache                   ( arcache                   ),
    .arprot                    ( arprot                    ),
    .arready                   ( arready                   ),
    .rvalid                    ( rvalid                    ),
    .rid                       ( rid                       ),
    .rlast                     ( rlast                     ),
    .rdata                     ( rdata                     ),
    .rresp                     ( rresp                     ),
    .rready                    ( rready                    ),
    .awvalid                   ( awvalid                   ),
    .awid                      ( awid                      ),
    .awaddr                    ( awaddr                    ),
    .awlen                     ( awlen                     ),
    .awsize                    ( awsize                    ),
    .awburst                   ( awburst                   ),
    .awlock                    ( awlock                    ),
    .awcache                   ( awcache                   ),
    .awprot                    ( awprot                    ),
    .awready                   ( awready                   ),
    .wvalid                    ( wvalid                    ),
    .wid                       ( wid                       ),
    .wlast                     ( wlast                     ),
    .wdata                     ( wdata                     ),
    .wstrb                     ( wstrb                     ),
    .wready                    ( wready                    ),
    .bvalid                    ( bvalid                    ),
    .bid                       ( bid                       ),
    .bresp                     ( bresp                     ),
    .bready                    ( bready                    ),
    .base_addr_0               ( base_addr_0               ),
    .base_addr_1               ( base_addr_1               ),
    .base_addr_2               ( base_addr_2               ),
    .base_addr_3               ( base_addr_3               ),
    .base_addr_4               ( base_addr_4               ),
    .base_addr_5               ( base_addr_5               ),
    .base_addr_6               ( base_addr_6               ),
    .base_addr_7               ( base_addr_7               ),
    .base_addr_8               ( base_addr_8               ),
    .base_addr_9               ( base_addr_9               ),
    .base_addr_10              ( base_addr_10              ),
    .base_addr_11              ( base_addr_11              ),
    .send_valid                ( send_valid                ),
    .send_flit                 ( send_flit                 ),
    .send_last                 ( send_last                 ),
    .send_ready                ( send_ready                ),
    .recv_valid                ( recv_valid                ),
    .recv_flit                 ( recv_flit                 ),
    .recv_last                 ( recv_last                 ),
    .recv_ready                ( recv_ready                )
);

endmodule