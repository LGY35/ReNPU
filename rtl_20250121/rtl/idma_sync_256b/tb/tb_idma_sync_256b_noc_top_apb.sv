module tb_idma_sync_256b_noc_top_apb();

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


logic               aclk                    ;
logic               aresetn                 ;
logic      [11:0]   apb_PADDR;
logic      [0:0]    apb_PSEL;
logic               apb_PENABLE;
logic               apb_PREADY;
logic               apb_PWRITE;
logic      [3:0]    apb_PSTRB;
logic      [2:0]    apb_PPROT;
logic      [31:0]   apb_PWDATA;
logic      [31:0]   apb_PRDATA;
logic               apb_PSLVERR;
logic               interrupt;
logic                               send_valid    ;
logic  [AXI_DATA_WID-1:0]           send_flit     ;
logic                               send_last     ;
logic                               send_ready    ;
logic                               recv_valid    ;
logic  [AXI_DATA_WID-1:0]           recv_flit     ;
logic                               recv_last     ;
logic                               recv_ready    ;
logic                              	arvalid               ;
logic  [AXI_IDW-1:0]               	arid                  ;
logic  [AXI_ADDR_WID-1:0]           araddr                ;
logic  [AXI_LENW-1:0]              	arlen                 ;
logic  [2:0]                       	arsize                ;
logic  [1:0]                       	arburst               ;
logic  [AXI_LOCKW-1:0]             	arlock                ;
logic  [3:0]                       	arcache               ;
logic  [2:0]                       	arprot                ;
logic                              	arready               ;
logic                              	rvalid                ;
logic  [AXI_IDW-1:0]               	rid                   ;
logic                              	rlast                 ;
logic  [AXI_DATA_WID-1:0]          	rdata                 ;
logic  [1:0]                       	rresp                 ;
logic                              	rready                ;
logic                              	awvalid               ;
logic  [AXI_IDW-1:0]               	awid                  ;
logic  [AXI_ADDR_WID-1:0]           awaddr                ;
logic  [AXI_LENW-1:0]              	awlen                 ;
logic  [2:0]                       	awsize                ;
logic  [1:0]                       	awburst               ;
logic  [AXI_LOCKW-1:0]             	awlock                ;
logic  [3:0]                       	awcache               ;
logic  [2:0]                       	awprot                ;
logic                              	awready               ;
logic                               wvalid                ;
logic   [AXI_IDW-1:0]               wid                   ;
logic                               wlast                 ;
logic   [AXI_DATA_WID-1:0]          wdata                 ;
logic   [AXI_STRBW-1:0]             wstrb                 ;
logic                             	wready                ;
logic                               bvalid                ;
logic  [AXI_IDW-1:0]                bid                   ;
logic  [1:0]                        bresp                 ;
logic                               bread;

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
  $fsdbDumpfile("tb_idma_sync_256b_noc_top_apb.fsdb");
  $fsdbDumpvars("+all");
end
// ================= dut =================
idma_sync_256b_noc_top_apb#(
    .DATA_FIFO_DEPTH   ( 64 ),
    .DATA_FIFO_CNT_WID ( 6+1 ),
    .ADDR_FIFO_DEPTH   ( 32 ),
    .ADDR_FIFO_CNT_WID ( 5+1 ),
    .AXI_DATA_WID      ( 256 ),
    .AXI_ADDR_WID      ( 32 ),
    .AXI_IDW           ( 4 ),
    .AXI_LENW          ( 4 ),
    .AXI_LOCKW         ( 2 ),
    .AXI_STRBW         ( 32 )
)u_idma_sync_256b_noc_top_apb(
    .aclk              ( aclk              ),
    .aresetn           ( aresetn           ),
    .apb_PADDR         ( apb_PADDR         ),
    .apb_PSEL          ( apb_PSEL          ),
    .apb_PENABLE       ( apb_PENABLE       ),
    .apb_PREADY        ( apb_PREADY        ),
    .apb_PWRITE        ( apb_PWRITE        ),
    .apb_PSTRB         ( apb_PSTRB         ),
    .apb_PPROT         ( apb_PPROT         ),
    .apb_PWDATA        ( apb_PWDATA        ),
    .apb_PRDATA        ( apb_PRDATA        ),
    .apb_PSLVERR       ( apb_PSLVERR       ),
    .interrupt         ( interrupt         ),
    .send_valid        ( send_valid        ),
    .send_flit         ( send_flit         ),
    .send_last         ( send_last         ),
    .send_ready        ( send_ready        ),
    .recv_valid        ( recv_valid        ),
    .recv_flit         ( recv_flit         ),
    .recv_last         ( recv_last         ),
    .recv_ready        ( recv_ready        ),
    .arvalid           ( arvalid           ),
    .arid              ( arid              ),
    .araddr            ( araddr            ),
    .arlen             ( arlen             ),
    .arsize            ( arsize            ),
    .arburst           ( arburst           ),
    .arlock            ( arlock            ),
    .arcache           ( arcache           ),
    .arprot            ( arprot            ),
    .arready           ( arready           ),
    .rvalid            ( rvalid            ),
    .rid               ( rid               ),
    .rlast             ( rlast             ),
    .rdata             ( rdata             ),
    .rresp             ( rresp             ),
    .rready            ( rready            ),
    .awvalid           ( awvalid           ),
    .awid              ( awid              ),
    .awaddr            ( awaddr            ),
    .awlen             ( awlen             ),
    .awsize            ( awsize            ),
    .awburst           ( awburst           ),
    .awlock            ( awlock            ),
    .awcache           ( awcache           ),
    .awprot            ( awprot            ),
    .awready           ( awready           ),
    .wvalid            ( wvalid            ),
    .wid               ( wid               ),
    .wlast             ( wlast             ),
    .wdata             ( wdata             ),
    .wstrb             ( wstrb             ),
    .wready            ( wready            ),
    .bvalid            ( bvalid            ),
    .bid               ( bid               ),
    .bresp             ( bresp             ),
    .bready            ( bready            )
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
    .PENABLE      ( apb_PENABLE ),
    .PWRITE       ( apb_PWRITE  ),
    .PWSTRB       ( apb_PSTRB   ),
    .PADDR        ( apb_PADDR   ),
    .PSEL         ( apb_PSEL    ),
    .PWDATA       ( apb_PWDATA  ),
    .PRDATA       ( apb_PRDATA  ),
    .PREADY       ( apb_PREADY  ),
    .PSLVERR      ( apb_PSLVERR )
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
)u_axi_ram(
    .clk                ( aclk    ),
    .rst                ( !aresetn),
    .s_axi_awid         ( awid    ),
    .s_axi_awaddr       ( awaddr  ),
    .s_axi_awlen        ( awlen   ),
    .s_axi_awsize       ( awsize  ),
    .s_axi_awburst      ( awburst ),
    .s_axi_awlock       ( awlock  ),
    .s_axi_awcache      ( awcache ),
    .s_axi_awprot       ( awprot  ),
    .s_axi_awvalid      ( awvalid ),
    .s_axi_awready      ( awready ),
    .s_axi_wdata        ( wdata   ),
    .s_axi_wstrb        ( wstrb   ),
    .s_axi_wlast        ( wlast   ),
    .s_axi_wvalid       ( wvalid  ),
    .s_axi_wready       ( wready  ),
    .s_axi_bid          ( bid     ),
    .s_axi_bresp        ( bresp   ),
    .s_axi_bvalid       ( bvalid  ),
    .s_axi_bready       ( bready  ),
    .s_axi_arid         ( arid    ),
    .s_axi_araddr       ( araddr  ),
    .s_axi_arlen        ( arlen   ),
    .s_axi_arsize       ( arsize  ),
    .s_axi_arburst      ( arburst ),
    .s_axi_arlock       ( arlock  ),
    .s_axi_arcache      ( arcache ),
    .s_axi_arprot       ( arprot  ),
    .s_axi_arvalid      ( arvalid ),
    .s_axi_arready      ( arready ),
    .s_axi_rid          ( rid     ),
    .s_axi_rdata        ( rdata   ),
    .s_axi_rresp        ( rresp   ),
    .s_axi_rlast        ( rlast   ),
    .s_axi_rvalid       ( rvalid  ),
    .s_axi_rready       ( rready  )
);
// ================= drive =================
initial begin
  recv_valid = 1'b0;
  recv_last  = 1'b0;
  recv_flit  = 256'd0;
  // cfg IDMA_RD_CTRL0
  write_cfg('hc, {1'b0, 1'b0, 1'b1, 1'b0, 4'd2}, {4{1'b1}}, 0, 2);
  // cfg IDMA_RD_CFG_EN
  write_cfg('h0, 1, {4{1'b1}}, 0, 2);
  // cfg IDMA_WR_CTRL0
  write_cfg('h2c, {1'b0, 1'b0, 1'b1, 1'b0, 4'd2}, {4{1'b1}}, 0, 2);
  // cfg IDMA_WR_CFG_EN
  write_cfg('h20, 1, {4{1'b1}}, 0, 2);
  // cfg base addr
  write_cfg('h30, 'h0000_0000, {4{1'b1}}, 0, 2);
  write_cfg('h34, 'h1000_0000, {4{1'b1}}, 0, 2);
  write_cfg('h38, 'h2000_0000, {4{1'b1}}, 0, 2);
  write_cfg('h3c, 'h3000_0000, {4{1'b1}}, 0, 2);
  write_cfg('h40, 'h4000_0000, {4{1'b1}}, 0, 2);
  write_cfg('h44, 'h5000_0000, {4{1'b1}}, 0, 2);
  write_cfg('h48, 'h6000_0000, {4{1'b1}}, 0, 2);
  write_cfg('h4c, 'h7000_0000, {4{1'b1}}, 0, 2);
  write_cfg('h50, 'h9000_0000, {4{1'b1}}, 0, 2);
  write_cfg('h54, 'ha000_0000, {4{1'b1}}, 0, 2);
  write_cfg('h58, 'hb000_0000, {4{1'b1}}, 0, 2);
  write_cfg('h5c, 'hc000_0000, {4{1'b1}}, 0, 2);
  // flit
  begin
    // ============== read ==================
    //first
    @(posedge aclk);
    recv_valid <= 1'b1;
    recv_last  <= 1'b0;
                          //      data_num     addr         coor        rw
    recv_flit  <= {128'd0, 36'd0, 20'd16,      16'd0, 50'd0, 4'd1, 1'b0, 1'b0};
    wait(recv_ready);
    //2nd
    @(posedge aclk);
    recv_valid <= 1'b1;
    recv_last  <= 1'b1;
    recv_flit  <= 256'hdead_beef;
    wait(recv_ready);
    @(posedge aclk);
    recv_valid <= 1'b0;
    // ============== write ==================
    //first
    @(posedge aclk);
    recv_valid <= 1'b1;
    recv_last  <= 1'b0;
                          //      data_num     addr         coor        rw
    recv_flit  <= {128'd0, 36'd0, 20'd4,      16'd0, 50'd0, 4'd2, 1'b0, 1'b1};
    wait(recv_ready);
    //2nd
    @(posedge aclk);
    recv_valid <= 1'b1;
    recv_last  <= 1'b0;
    recv_flit  <= 256'hdead_beef;
    wait(recv_ready);
    @(posedge aclk);
    recv_valid <= 1'b0;
    //wdata
    for(int i =0; i<4; i++) begin
      @(posedge aclk);
      recv_valid <= 1'b1;
      recv_last  <= 1'b0;
      recv_flit  <= 256'hfade_face_0000 + i;
      wait(recv_ready);
      @(posedge aclk);
      recv_valid <= 1'b0;
    end
  end
end
// ================= back pressure =================
initial begin
  send_ready = 1'b0;
  #100;
  @(posedge aclk);
  send_ready <= 1'b1;
  forever begin
    @(posedge aclk);
    send_ready <= ~send_ready;
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