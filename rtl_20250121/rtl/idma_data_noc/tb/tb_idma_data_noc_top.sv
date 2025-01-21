module tb_idma_data_noc_top();

parameter DATA_FIFO_DEPTH   = 64    ;
parameter DATA_FIFO_CNT_WID = 6+1   ;
parameter ADDR_FIFO_DEPTH   = 32    ;
parameter ADDR_FIFO_CNT_WID = 5+1   ;
parameter AXI_DATA_WID      = 256   ;
parameter AXI_ADDR_WID      = 32    ;
parameter AXI_IDW           = 4     ;
parameter AXI_LENW          = 4     ;
parameter AXI_LOCKW         = 2     ;
parameter AXI_STRBW         = 32    ;

parameter AXI4_ADDRESS_WIDTH = 32;
parameter AXI4_RDATA_WIDTH   = 32;
parameter AXI4_WDATA_WIDTH   = 32;
parameter AXI4_ID_WIDTH      = 16;
parameter AXI4_USER_WIDTH    = 10;
parameter AXI_NUMBYTES       = AXI4_WDATA_WIDTH/8;
parameter BUFF_DEPTH_SLAVE   = 4;
parameter APB_ADDR_WIDTH     = 12;


logic                               aclk          ;
logic                               aresetn       ;
logic      [11:0]                   paddr         ;
logic      [0:0]                    psel          ;
logic                               penable       ;
logic                               pready        ;
logic                               pwrite        ;
logic      [3:0]                    pstrb         ;
logic      [2:0]                    pprot         ;
logic      [31:0]                   pwdata        ;
logic      [31:0]                   prdata        ;
logic                               pslverr       ;
logic                               interrupt     ;

logic                               data_out_valid ;
logic  [AXI_DATA_WID-1:0]           data_out_flit  ;
logic                               data_out_last  ;
logic                               data_out_ready ;
logic                               data_in_valid  ;
logic  [AXI_DATA_WID-1:0]           data_in_flit   ;
logic                               data_in_last   ;
logic                               data_in_ready  ;
logic                               ctrl_out_valid ;
logic  [AXI_DATA_WID-1:0]           ctrl_out_flit  ;
logic                               ctrl_out_last  ;
logic                               ctrl_out_ready ;
logic                               ctrl_in_valid  ;
logic  [AXI_DATA_WID-1:0]           ctrl_in_flit   ;
logic                               ctrl_in_last   ;
logic                               ctrl_in_ready  ;

logic                              	arvalid       ;
logic  [AXI_IDW-1:0]               	arid          ;
logic  [AXI_ADDR_WID-1:0]           araddr        ;
logic  [AXI_LENW-1:0]              	arlen         ;
logic  [2:0]                       	arsize        ;
logic  [1:0]                       	arburst       ;
logic  [AXI_LOCKW-1:0]             	arlock        ;
logic  [3:0]                       	arcache       ;
logic  [2:0]                       	arprot        ;
logic                              	arready       ;
logic                              	rvalid        ;
logic  [AXI_IDW-1:0]               	rid           ;
logic                              	rlast         ;
logic  [AXI_DATA_WID-1:0]          	rdata         ;
logic  [1:0]                       	rresp         ;
logic                              	rready        ;
logic                              	awvalid       ;
logic  [AXI_IDW-1:0]               	awid          ;
logic  [AXI_ADDR_WID-1:0]           awaddr        ;
logic  [AXI_LENW-1:0]              	awlen         ;
logic  [2:0]                       	awsize        ;
logic  [1:0]                       	awburst       ;
logic  [AXI_LOCKW-1:0]             	awlock        ;
logic  [3:0]                       	awcache       ;
logic  [2:0]                       	awprot        ;
logic                              	awready       ;
logic                               wvalid        ;
logic                               wlast         ;
logic   [AXI_DATA_WID-1:0]          wdata         ;
logic   [AXI_STRBW-1:0]             wstrb         ;
logic                             	wready        ;
logic                               bvalid        ;
logic  [AXI_IDW-1:0]                bid           ;
logic  [1:0]                        bresp         ;
logic                               bread         ;

logic   [AXI4_ID_WIDTH-1:0]       cfg_awid;
logic   [AXI4_ADDRESS_WIDTH-1:0]  cfg_awaddr;
logic   [7:0]                     cfg_awlen;
logic   [2:0]                     cfg_awsize;
logic   [1:0]                     cfg_awburst;
logic                             cfg_awlock;
logic   [3:0]                     cfg_awcache;
logic   [2:0]                     cfg_awprot;
logic                             cfg_awvalid;
logic                             cfg_awready;
logic   [AXI4_WDATA_WIDTH-1:0]    cfg_wdata;
logic   [AXI_NUMBYTES-1:0]        cfg_wstrb;
logic                             cfg_wlast;
logic                             cfg_wvalid;
logic                             cfg_wready;
logic   [AXI4_ID_WIDTH-1:0]       cfg_bid;
logic   [1:0]                     cfg_bresp;
logic                             cfg_bvalid;
logic                             cfg_bready;
logic   [AXI4_ID_WIDTH-1:0]       cfg_arid;
logic   [AXI4_ADDRESS_WIDTH-1:0]  cfg_araddr;
logic   [7:0]                     cfg_arlen;
logic   [2:0]                     cfg_arsize;
logic   [1:0]                     cfg_arburst;
logic                             cfg_arlock;
logic   [3:0]                     cfg_arcache;
logic   [2:0]                     cfg_arprot;
logic                             cfg_arvalid;
logic                             cfg_arready;
logic   [AXI4_ID_WIDTH-1:0]       cfg_rid;
logic   [AXI4_RDATA_WIDTH-1:0]    cfg_rdata;
logic   [1:0]                     cfg_rresp;
logic                             cfg_rlast;
logic                             cfg_rvalid;
logic                             cfg_rready;
logic                             cfg_req ;  
logic [AXI4_ADDRESS_WIDTH-1:0]    cfg_addr;  
logic                             cfg_we; 
logic [AXI4_RDATA_WIDTH-1:0]      cfg_data; 
logic [AXI4_RDATA_WIDTH/8-1:0]    cfg_be;
logic [2:0]                       cfg_size;
logic [7:0]                       cfg_len;
logic [AXI4_ID_WIDTH-1:0]         cfg_id;
logic                             cfg_gnt; 
logic                             cfg_rsp_valid;
logic [AXI4_RDATA_WIDTH-1:0]      cfg_rsp_rdata;

logic  [AXI_IDW-1:0]              delay_rid           ;
logic                             delay_rlast         ;
logic  [AXI_DATA_WID-1:0]         delay_rdata         ;
logic  [1:0]                      delay_rresp         ;
logic                             delay_rready        ;


// ================= clk and reset =================
initial begin
  aclk = 1'b0;  
  # 50;
  forever begin
    #2
    aclk = ~aclk;
  end
end
initial begin
  aresetn = 1'b0;
  #50
  aresetn = 1'b1;
end
// ================= Time out =================
initial begin
  #200000
  $display("TimeOut! Simulation finish!\n");
  $finish;
end
// ================= clk and reset =================
initial begin
  $fsdbDumpfile("tb_idma_data_noc_top.fsdb");
  $fsdbDumpvars("+all");
end
// ================= dut =================
idma_data_noc_top#(
    .DATA_FIFO_DEPTH   ( 64 ),
    .DATA_FIFO_CNT_WID ( 6+1 ),
    .ADDR_FIFO_DEPTH   ( 32 ),
    .ADDR_FIFO_CNT_WID ( 5+1 ),
    .AXI_DATA_WID      ( 256 ),
    .AXI_ADDR_WID      ( 32 ),
    .AXI_IDW           ( 4 ),
    .AXI_LENW          ( 4 ),
    .AXI_LOCKW         ( 2 ),
    .AXI_STRBW         ( 32 ),
    .ID                (1 )
)u_idma_data_noc_top(
    .aclk              ( aclk              ),
    .aresetn           ( aresetn           ),
    .paddr             ( paddr             ),
    .psel              ( psel              ),
    .penable           ( penable           ),
    .pready            ( pready            ),
    .pwrite            ( pwrite            ),
    .pstrb             ( pstrb             ),
    .pprot             ( pprot             ),
    .pwdata            ( pwdata            ),
    .prdata            ( prdata            ),
    .pslverr           ( pslverr           ),
    .interrupt         ( interrupt         ),
    .data_out_valid    ( data_out_valid    ),
    .data_out_flit     ( data_out_flit     ),
    .data_out_last     ( data_out_last     ),
    .data_out_ready    ( data_out_ready    ),
    .data_in_valid     ( data_in_valid     ),
    .data_in_flit      ( data_in_flit      ),
    .data_in_last      ( data_in_last      ),
    .data_in_ready     ( data_in_ready     ),
    .ctrl_out_valid    ( ctrl_out_valid    ),
    .ctrl_out_flit     ( ctrl_out_flit     ),
    .ctrl_out_last     ( ctrl_out_last     ),
    .ctrl_out_ready    ( ctrl_out_ready    ),
    .ctrl_in_valid     ( ctrl_in_valid     ),
    .ctrl_in_flit      ( ctrl_in_flit      ),
    .ctrl_in_last      ( ctrl_in_last      ),
    .ctrl_in_ready     ( ctrl_in_ready     ),
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
    .rvalid                       ( delay_rvalid                 ),
    .rid                          ( delay_rid                    ),
    .rlast                        ( delay_rlast                  ),
    .rdata                        ( delay_rdata                  ),
    .rresp                        ( delay_rresp                  ),
    .rready                       ( delay_rready                 ),
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
    .wlast                        ( wlast                        ),
    .wdata                        ( wdata                        ),
    .wstrb                        ( wstrb                        ),
    .wready                       ( wready                       ),
    .bvalid                       ( bvalid                       ),
    .bid                          ( bid                          ),
    .bresp                        ( bresp                        ),
    .bready                       ( bready                       )
);

// ================= other module =================
axi2apb#(
    .AXI4_ADDRESS_WIDTH ( AXI4_ADDRESS_WIDTH ),
    .AXI4_RDATA_WIDTH   ( AXI4_RDATA_WIDTH   ),
    .AXI4_WDATA_WIDTH   ( AXI4_WDATA_WIDTH   ),
    .AXI4_ID_WIDTH      ( AXI4_ID_WIDTH      ),
    .AXI4_USER_WIDTH    ( AXI4_USER_WIDTH    ),
    .AXI_NUMBYTES       ( AXI_NUMBYTES       ),
    .BUFF_DEPTH_SLAVE   ( BUFF_DEPTH_SLAVE   ),
    .APB_ADDR_WIDTH     ( APB_ADDR_WIDTH     )
)u_axi2apb(
    .ACLK         ( aclk         ),
    .ARESETn      ( aresetn      ),
    .test_en_i    ( 1'b0    ),
    .AWID_i       ( cfg_awid ),
    .AWADDR_i     ( cfg_awaddr ),
    .AWLEN_i      ( cfg_awlen  ),
    .AWSIZE_i     ( cfg_awsize ),
    .AWBURST_i    ( cfg_awburst ),
    .AWLOCK_i     ( cfg_awlock ),
    .AWCACHE_i    ( cfg_awcache ),
    .AWPROT_i     ( cfg_awprot ),
    .AWREGION_i   ( 4'b0 ),
    .AWUSER_i     ( {AXI4_USER_WIDTH{1'b0}} ),
    .AWQOS_i      ( 4'b0 ),
    .AWVALID_i    ( cfg_awvalid ),
    .AWREADY_o    ( cfg_awready ),
    .WDATA_i      ( cfg_wdata ),
    .WSTRB_i      ( cfg_wstrb ),
    .WLAST_i      ( cfg_wlast ),
    .WUSER_i      ( {AXI4_USER_WIDTH{1'b0}} ),
    .WVALID_i     ( cfg_wvalid ),
    .WREADY_o     ( cfg_wready ),
    .BID_o        ( cfg_bid ),
    .BRESP_o      ( cfg_bresp ),
    .BVALID_o     ( cfg_bvalid ),
    .BUSER_o      (  ),
    .BREADY_i     ( cfg_bready ),
    .ARID_i       ( cfg_arid ),
    .ARADDR_i     ( cfg_araddr ),
    .ARLEN_i      ( cfg_arlen ),
    .ARSIZE_i     ( cfg_arsize ),
    .ARBURST_i    ( cfg_arburst ),
    .ARLOCK_i     ( cfg_arlock ),
    .ARCACHE_i    ( cfg_arcache ),
    .ARPROT_i     ( cfg_arprot ),
    .ARREGION_i   ( 4'b0 ),
    .ARUSER_i     ({AXI4_USER_WIDTH{1'b0}}  ),
    .ARQOS_i      ( 4'b0 ),
    .ARVALID_i    ( cfg_arvalid ),
    .ARREADY_o    ( cfg_arready ),
    .RID_o        ( cfg_rid ),
    .RDATA_o      ( cfg_rdata ),
    .RRESP_o      ( cfg_rresp ),
    .RLAST_o      ( cfg_rlast ),
    .RUSER_o      (  ),
    .RVALID_o     ( cfg_rvalid ),
    .RREADY_i     ( cfg_rready ),
    .PENABLE      ( penable ),
    .PWRITE       ( pwrite  ),
    .PWSTRB       ( pstrb   ),
    .PADDR        ( paddr   ),
    .PSEL         ( psel    ),
    .PWDATA       ( pwdata  ),
    .PRDATA       ( prdata  ),
    .PREADY       ( pready  ),
    .PSLVERR      ( pslverr )
);
axi_master_mem#(
    .RW_DATA_WIDTH   ( 32 ),
    .RW_ADDR_WIDTH   ( 32 ),
    .AXI_DATA_WIDTH  ( 32 ),
    .AXI_ADDR_WIDTH  ( 32 ),
    .AXI_ID_WIDTH    ( 8 ),
    .AXI_USER_WIDTH  ( 1 )
)u_axi_master_cfg(
    .clk             ( aclk           ),
    .rst_n           ( aresetn        ),
    .rw_cen_i        ( cfg_req        ),
    .rw_wen_i        ( cfg_we         ),
    .rw_addr_i       ( cfg_addr       ),
    .rw_size_i       ( cfg_size       ),
    .rw_len_i        ( cfg_len        ),
    .rw_id_i         ( cfg_id         ),
    .rw_wdata_i      ( cfg_data       ),
    .rw_wmask_i      ( cfg_be         ),
    .rw_ready_o      ( cfg_gnt        ),
    .rw_rdata_o      ( cfg_rsp_rdata  ),
    .rw_rvalid_o     ( cfg_rsp_valid  ),
    .rw_resp_o       (                ),
    .axi_aw_id_o     ( cfg_awid     ),
    .axi_aw_addr_o   ( cfg_awaddr   ),
    .axi_aw_len_o    ( cfg_awlen    ),
    .axi_aw_size_o   ( cfg_awsize   ),
    .axi_aw_burst_o  ( cfg_awburst  ),
    .axi_aw_lock_o   ( cfg_awlock   ),
    .axi_aw_cache_o  ( cfg_awcache  ),
    .axi_aw_prot_o   ( cfg_awprot   ),
    .axi_aw_qos_o    (     ),
    .axi_aw_region_o (     ),
    .axi_aw_user_o   (     ),
    .axi_aw_valid_o  ( cfg_awvalid  ),
    .axi_aw_ready_i  ( cfg_awready  ),
    .axi_w_ready_i   ( cfg_wready   ),
    .axi_w_valid_o   ( cfg_wvalid   ),
    .axi_w_data_o    ( cfg_wdata    ),
    .axi_w_strb_o    ( cfg_wstrb    ),
    .axi_w_last_o    ( cfg_wlast    ),
    .axi_w_user_o    (     ),
    .axi_b_ready_o   ( cfg_bready   ),
    .axi_b_valid_i   ( cfg_bvalid   ),
    .axi_b_resp_i    ( cfg_bresp    ),
    .axi_b_id_i      ( cfg_bid      ),
    .axi_b_user_i    ( 'b0    ),
    .axi_ar_ready_i  ( cfg_arready  ),
    .axi_ar_valid_o  ( cfg_arvalid  ),
    .axi_ar_addr_o   ( cfg_araddr   ),
    .axi_ar_prot_o   ( cfg_arprot   ),
    .axi_ar_id_o     ( cfg_arid     ),
    .axi_ar_user_o   (    ),
    .axi_ar_len_o    ( cfg_arlen    ),
    .axi_ar_size_o   ( cfg_arsize   ),
    .axi_ar_burst_o  ( cfg_arburst  ),
    .axi_ar_lock_o   ( cfg_arlock   ),
    .axi_ar_cache_o  ( cfg_arcache  ),
    .axi_ar_qos_o    (     ),
    .axi_ar_region_o (  ),
    .axi_r_ready_o   ( cfg_rready   ),
    .axi_r_valid_i   ( cfg_rvalid   ),
    .axi_r_resp_i    ( cfg_rresp    ),
    .axi_r_data_i    ( cfg_rdata    ),
    .axi_r_last_i    ( cfg_rlast    ),
    .axi_r_id_i      ( cfg_rid      ),
    .axi_r_user_i    ( 'b0    )
);

// for sim
axi_ram#(
    .DATA_WIDTH         ( AXI_DATA_WID ),
    .ADDR_WIDTH         ( AXI_ADDR_WID ),
    .STRB_WIDTH         ( AXI_DATA_WID/8 ),
    .ID_WIDTH           ( AXI_IDW ),
    .PIPELINE_OUTPUT    ( 0 )
)u_axi_ram_0(
    .clk                ( aclk    ),
    .rst                ( !aresetn),
    .s_axi_awid         ( awid       ),
    .s_axi_awaddr       ( awaddr     ),
    .s_axi_awlen        ( awlen      ),
    .s_axi_awsize       ( awsize     ),
    .s_axi_awburst      ( awburst    ),
    .s_axi_awlock       ( awlock     ),
    .s_axi_awcache      ( awcache    ),
    .s_axi_awprot       ( awprot     ),
    .s_axi_awvalid      ( awvalid    ),
    .s_axi_awready      ( awready    ),
    .s_axi_wdata        ( wdata      ),
    .s_axi_wstrb        ( wstrb      ),
    .s_axi_wlast        ( wlast      ),
    .s_axi_wvalid       ( wvalid     ),
    .s_axi_wready       ( wready     ),
    .s_axi_bid          ( bid        ),
    .s_axi_bresp        ( bresp      ),
    .s_axi_bvalid       ( bvalid     ),
    .s_axi_bready       ( bready     ),
    .s_axi_arid         ( arid       ),
    .s_axi_araddr       ( araddr     ),
    .s_axi_arlen        ( arlen      ),
    .s_axi_arsize       ( arsize     ),
    .s_axi_arburst      ( arburst    ),
    .s_axi_arlock       ( arlock     ),
    .s_axi_arcache      ( arcache    ),
    .s_axi_arprot       ( arprot     ),
    .s_axi_arvalid      ( arvalid    ),
    .s_axi_arready      ( arready    ),
    .s_axi_rid          ( rid        ),
    .s_axi_rdata        ( rdata      ),
    .s_axi_rresp        ( rresp      ),
    .s_axi_rlast        ( rlast      ),
    .s_axi_rvalid       ( rvalid     ),
    .s_axi_rready       ( rready     )
);
// assign awready = 1'b1;
// assign wready  = 1'b1;

fifo_with_flush #(
    .DEPTH       ( 16 ),
    .DATA_W      ( AXI_IDW+AXI_DATA_WID+2+1 )
)u_delay_r_fifo(
    .clk         ( aclk         ),
    .rst_n       ( aresetn      ),
    .flush       ( 1'b0 ),
    .f_valid_in  ( rvalid    ),
    .f_data_in   ( {rid   , rdata   , rresp   , rlast   } ),
    .f_ready_out ( rready    ),
    .b_valid_out ( delay_rvalid    ),
    .b_data_out  ( {delay_rid   , delay_rdata   , delay_rresp   , delay_rlast   } ),
    .b_ready_in  ( delay_rready    )
);

// ================= drive =================
initial begin
  data_out_ready = 1'b0;
  data_in_valid = 1'b0;
  data_in_last  = 1'b0;
  data_in_flit  = 256'd0;
  ctrl_out_ready = 1'b0;
  ctrl_in_valid = 1'b0;
  ctrl_in_last  = 1'b0;
  ctrl_in_flit  = 256'd0;

  // cfg RD_CTRL0   
  // write_cfg('hc, {1'b0, 1'b0, 1'b1, 1'b1, 4'd2}, {4{1'b1}}, 0, 2);
  // cfg RD_CFG_EN   
  // write_cfg('h0, 1, {4{1'b1}}, 0, 2);
  // cfg WR_CTRL0   
  // write_cfg('h2c, {1'b0, 1'b0, 1'b1, 1'b0, 4'd2}, {4{1'b1}}, 0, 2);
  // cfg WR_CFG_EN   
  // write_cfg('h20, 1, {4{1'b1}}, 0, 2);
  // cfg rgb2rgba enable   
  write_cfg('h48, 1, {4{1'b1}}, 0, 2);

  // cfg base addr
  write_cfg('h0,  'h0000_0001, {4{1'b1}}, 0, 2);
  write_cfg('h4,  'h0000_0001, {4{1'b1}}, 0, 2);
  write_cfg('h8,  'h0000_0001, {4{1'b1}}, 0, 2);
  write_cfg('hc,  'h0000_0001, {4{1'b1}}, 0, 2);
  write_cfg('h10, 'h0000_0001, {4{1'b1}}, 0, 2);
  write_cfg('h14, 'h0000_0001, {4{1'b1}}, 0, 2);
  // cfg group base addr
  write_cfg('h18, 'h0000_0001, {4{1'b1}}, 0, 2);
  write_cfg('h1c, 'h0000_0001, {4{1'b1}}, 0, 2);
  write_cfg('h20, 'h0000_0001, {4{1'b1}}, 0, 2);
  write_cfg('h24, 'h0000_0001, {4{1'b1}}, 0, 2);
  write_cfg('h28, 'h0000_0001, {4{1'b1}}, 0, 2);
  write_cfg('h2c, 'h0000_0001, {4{1'b1}}, 0, 2);
  // cfg write base addr
  write_cfg('h30, 'h1110_0001, {4{1'b1}}, 0, 2);
  write_cfg('h34, 'h2220_0001, {4{1'b1}}, 0, 2);
  write_cfg('h38, 'h3330_0001, {4{1'b1}}, 0, 2);
  write_cfg('h3c, 'h4440_0001, {4{1'b1}}, 0, 2);
  write_cfg('h40, 'h5550_0001, {4{1'b1}}, 0, 2);
  write_cfg('h44, 'h6660_0001, {4{1'b1}}, 0, 2);

  // flit
  begin
    // ============== read ==================
    //first
    @(posedge aclk);
    ctrl_in_valid <= 1'b1;
    ctrl_in_last  <= 1'b1;
    //                sel                   len            addr   id                 
    ctrl_in_flit  <= {2'b01, 1'b1, 171'b0, 13'd0, 25'd0, 25'd127, 12'd0, 1'b0, 1'b1, 5'b0};
    wait(ctrl_in_ready);
    @(posedge aclk);
    ctrl_in_valid <= 1'b0;

    //2nd
    @(posedge aclk);
    ctrl_in_valid <= 1'b1;
    ctrl_in_last  <= 1'b1;
    //                                 len            addr      id                 
    ctrl_in_flit  <= {3'b001, 171'b0, 13'd1, 25'd0, 25'h200, 12'd3, 1'b0, 1'b1, 5'b0};
    wait(ctrl_in_ready);
    @(posedge aclk);
    ctrl_in_valid <= 1'b0;

    //3
    @(posedge aclk);
    ctrl_in_valid <= 1'b1;
    ctrl_in_last  <= 1'b1;
    //                                 len            addr      id                 
    ctrl_in_flit  <= {3'b001, 171'b0, 13'd2, 25'd0, 25'h200, 12'd3, 1'b0, 1'b1, 5'b0};
    wait(ctrl_in_ready);
    @(posedge aclk);
    ctrl_in_valid <= 1'b0;

    @(posedge aclk);
    ctrl_in_valid <= 1'b1;
    ctrl_in_last  <= 1'b1;
    //                                 len            addr      id                 
    ctrl_in_flit  <= {3'b001, 171'b0, 13'd3, 25'd0, 25'h200, 12'd3, 1'b0, 1'b1, 5'b0};
    wait(ctrl_in_ready);
    @(posedge aclk);
    ctrl_in_valid <= 1'b0;

    @(posedge aclk);
    ctrl_in_valid <= 1'b1;
    ctrl_in_last  <= 1'b1;
    //                                 len            addr      id                 
    ctrl_in_flit  <= {3'b001, 171'b0, 13'd4, 25'd0, 25'h200, 12'd3, 1'b0, 1'b1, 5'b0};
    wait(ctrl_in_ready);
    @(posedge aclk);
    ctrl_in_valid <= 1'b0;

    @(posedge aclk);
    ctrl_in_valid <= 1'b1;
    ctrl_in_last  <= 1'b1;
    //                                 len            addr      id                 
    ctrl_in_flit  <= {3'b001, 171'b0, 13'd5, 25'd0, 25'h200, 12'd3, 1'b0, 1'b1, 5'b0};
    wait(ctrl_in_ready);
    @(posedge aclk);
    ctrl_in_valid <= 1'b0;

    @(posedge aclk);
    ctrl_in_valid <= 1'b1;
    ctrl_in_last  <= 1'b1;
    //                                 len            addr      id                 
    ctrl_in_flit  <= {3'b001, 171'b0, 13'd6, 25'd0, 25'h200, 12'd3, 1'b0, 1'b1, 5'b0};
    wait(ctrl_in_ready);
    @(posedge aclk);
    ctrl_in_valid <= 1'b0;

    @(posedge aclk);
    ctrl_in_valid <= 1'b1;
    ctrl_in_last  <= 1'b1;
    //                                 len            addr      id                 
    ctrl_in_flit  <= {3'b001, 171'b0, 13'd7, 25'd0, 25'h200, 12'd3, 1'b0, 1'b1, 5'b0};
    wait(ctrl_in_ready);
    @(posedge aclk);
    ctrl_in_valid <= 1'b0;

    //4
    @(posedge aclk);
    ctrl_in_valid <= 1'b1;
    ctrl_in_last  <= 1'b1;
    //                111'b0 gap[144:134] 52'b0 rd_num[81:69] loop[68:58] mode[57] addrB[56:44] 12'b0  addrA[31:19] 19'b0               
    ctrl_in_flit  <= {111'b0, 11'd8,      52'b0, 13'd39,       11'd10,      1'b1,    13'haaa,   12'b0, 13'hbbb,     19'b0};
    wait(ctrl_in_ready);
    @(posedge aclk);
    ctrl_in_valid <= 1'b0;

    // ============== write ==================
    //1 trans
    @(posedge aclk);
    data_in_valid <= 1'b1;
    data_in_last  <= 1'b0;
    //                        len       addr       id 
    data_in_flit  <= {200'b0, 13'd159, 25'd127, 4'd7, 1'b1, 13'b0};
    wait(data_in_ready);
    //wdata
    for(int i =0; i<=159; i++) begin
      @(posedge aclk);
      data_in_valid <= 1'b1;
      data_in_last  <= 1'b0;
      data_in_flit  <= 256'hfade_face_0000 + i;
      // wait(data_in_ready);
      // @(posedge aclk);
      // data_in_valid <= 1'b0;
    end

    //2 trans
    @(posedge aclk);
    data_in_valid <= 1'b1;
    data_in_last  <= 1'b0;
                          //  len    addr    id 
    data_in_flit  <= {200'b0, 13'd6, 25'd0, 4'd8, 1'b1, 13'b0};
    @(posedge aclk);
    wait(data_in_ready);
    //wdata
    for(int i =0; i<=6; i++) begin
      @(posedge aclk);
      data_in_valid <= 1'b1;
      data_in_last  <= 1'b0;
      data_in_flit  <= 256'hdead_beef_0000 + i;
      // wait(data_in_ready);
      // @(posedge aclk);
      // data_in_valid <= 1'b0;
    end

    //3 trans
    @(posedge aclk);
    data_in_valid <= 1'b1;
    data_in_last  <= 1'b0;
                          //  len    addr    id 
    data_in_flit  <= {200'b0, 13'd6, 25'd0, 4'd11, 1'b1, 13'b0};
    @(posedge aclk);
    wait(data_in_ready);
    //wdata
    for(int i =0; i<=6; i++) begin
      @(posedge aclk);
      data_in_valid <= 1'b1;
      data_in_last  <= 1'b0;
      data_in_flit  <= 256'haaaa_aaaa_0000 + i;
      // wait(data_in_ready);
      // @(posedge aclk);
      // data_in_valid <= 1'b0;
    end

  end
end
// ================= back pressure =================
initial begin
  data_out_ready = 1'b1;
  #100;
  @(posedge aclk);
  data_out_ready <= 1'b1;
  forever begin
    @(posedge aclk);
    data_out_ready <= ~data_out_ready;
  end
end
initial begin
  ctrl_out_ready = 1'b0;
  #100;
  @(posedge aclk);
  ctrl_out_ready <= 1'b1;
  forever begin
    @(posedge aclk);
    ctrl_out_ready <= ~ctrl_out_ready;
  end
end
// ================= tasks =================
task write_cfg(input [32-1:0] addr, [32-1:0] wdata, [32/8-1:0] be, [7:0] len, [8-1:0] id);
  @(posedge aclk);
  cfg_addr <= addr;
  cfg_data <= wdata;
  cfg_be <= be;
  cfg_req <= 1'b1;
  cfg_we <= 1'b1;
  cfg_size <= $clog2(32/8);
  cfg_len <= len;
  cfg_id <= id;

  wait(cfg_gnt);
  @(posedge aclk);
  cfg_req <= 1'b0;

endtask
endmodule