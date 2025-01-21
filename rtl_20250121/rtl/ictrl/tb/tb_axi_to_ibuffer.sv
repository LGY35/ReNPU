module tb_axi_to_ibuffer();

parameter AddrWidth = 32;
parameter DataWidth = 128;
parameter IdWidth = 4;
parameter StrbWidth = DataWidth/8;
parameter MEM_ADDR_WIDTH = AddrWidth - $clog2(StrbWidth);
parameter MEM_SIM_DEPTH = 65536;
parameter INPUT_PIPE_STAGES = 1;
parameter MEM_LATENCY = 2;
parameter OUTPUT_PIPE_STAGES = 2;

logic clk, rst_n;

reg [DataWidth-1:0] mem_sim [0:MEM_SIM_DEPTH-1];
logic mem_req       ;   
logic [AddrWidth-1:0] mem_addr      ;  
logic mem_we        ; 
logic [DataWidth-1:0] mem_wdata     ; 
logic [DataWidth/8-1:0] mem_be        ;
logic [2:0] mem_size;
logic [7:0] mem_len;
logic [IdWidth-1:0] mem_id;
logic mem_gnt       ; 
logic mem_rsp_valid ; 
logic [DataWidth-1:0] mem_rsp_rdata ;

logic master_aw_valid  ;
logic master_aw_ready  ;
logic [AddrWidth-1:0] master_aw_addr   ;
logic [IdWidth-1:0] master_aw_id     ; 
logic [7:0] master_aw_len    ;
logic [2:0] master_aw_size   ;
logic [1:0] master_aw_burst  ;
logic master_aw_lock   ;
logic [3:0] master_aw_cache  ;
logic [2:0] master_aw_prot   ;
logic [3:0] master_aw_qos ;
logic [3:0] master_aw_region;
logic master_w_valid   ;
logic master_w_ready   ;
logic [DataWidth-1:0] master_w_data    ;
logic [DataWidth/8-1:0]master_w_strb    ;
logic master_w_last    ;
logic master_b_valid   ;
logic master_b_ready   ;
logic [1:0] master_b_id      ;
logic [1:0] master_b_resp    ;
logic master_ar_valid  ;
logic master_ar_ready  ;
logic [AddrWidth-1:0] master_ar_addr   ;
logic [IdWidth-1:0] master_ar_id     ;
logic [7:0] master_ar_len    ;
logic [2:0] master_ar_size   ;
logic [1:0] master_ar_burst  ;
logic master_ar_lock   ;
logic [3:0] master_ar_cache  ;
logic [2:0] master_ar_prot   ;
logic master_r_valid   ;
logic master_r_ready   ;
logic r_ready;
logic [DataWidth-1:0] master_r_data    ;
logic [IdWidth-1:0] master_r_id      ;
logic [1:0] master_r_resp    ;
logic master_r_last    ;

logic  [IdWidth-1:0]    s_axi_awid;
logic  [AddrWidth-1:0]  s_axi_awaddr;
logic  [7:0]             s_axi_awlen;
logic  [2:0]             s_axi_awsize;
logic  [1:0]             s_axi_awburst;
logic                    s_axi_awlock;
logic  [3:0]             s_axi_awcache;
logic  [2:0]             s_axi_awprot;
logic                    s_axi_awvalid;
logic                    s_axi_awready;
logic  [DataWidth-1:0]  s_axi_wdata;
logic  [StrbWidth-1:0]  s_axi_wstrb;
logic                    s_axi_wlast;
logic                    s_axi_wvalid;
logic                    s_axi_wready;
logic  [IdWidth-1:0]    s_axi_bid;
logic  [1:0]             s_axi_bresp;
logic                    s_axi_bvalid;
logic                    s_axi_bready;
logic  [IdWidth-1:0]    s_axi_arid;
logic  [AddrWidth-1:0]  s_axi_araddr;
logic  [7:0]             s_axi_arlen;
logic  [2:0]             s_axi_arsize;
logic  [1:0]             s_axi_arburst;
logic                    s_axi_arlock;
logic  [3:0]             s_axi_arcache;
logic  [2:0]             s_axi_arprot;
logic                    s_axi_arvalid;
logic                    s_axi_arready;
logic  [IdWidth-1:0]    s_axi_rid;
logic  [DataWidth-1:0]  s_axi_rdata;
logic  [1:0]             s_axi_rresp;
logic                    s_axi_rlast;
logic                    s_axi_rvalid;
logic                    s_axi_rready;

logic                    s_mem_cen; // mem chip enable
logic                    s_mem_last;
logic  [MEM_ADDR_WIDTH-1:0]  s_mem_addr; // mem address
logic                    s_mem_ready; // mem back pressure
logic                    s_mem_wen; // mem write enable
logic  [DataWidth-1:0]  s_mem_wdata; // write data
logic  [DataWidth/8-1:0]  s_mem_wstrb; // write strb
logic                    s_mem_rvalid; // read valid
logic  [DataWidth-1:0]  s_mem_rdata; // read data from mem
logic                    s_mem_rready;
logic                    s_mem_rlast;

logic           ictrl_cen;
logic           ictrl_wen;
logic           ictrl_ready;
logic [14:0]    ictrl_addr;
logic [127:0]   ictrl_wdata;
logic [127:0]   ictrl_rdata;
logic           ictrl_rvalid;
logic           ictrl_rready;

// ========================== clk and reset =============================	 
initial begin
  clk = 1'b0;  
  # 50;
  forever begin
    #2
    clk = ~clk;
  end
end
initial begin
  rst_n = 1'b0;
  #50
  rst_n = 1'b1;
end

// ========================== Time out =============================
initial begin
  #2000000
  $display("\n============== TimeOut ! Simulation finish ! ============\n");
  $finish;
end

// ============================== dump fsdb =============================
initial begin
	$display("\n================== Time:%d, Dump Start ================\n",$time);
	$fsdbDumpfile("tb_axi_to_ibuffer.fsdb");
	$fsdbDumpvars(0, "tb_axi_to_ibuffer", "+mda");
    $fsdbDumpvars("+all");
end

// ========================= access mem ============================
initial begin
  ictrl_cen = 1'b0;
  ictrl_wen = 1'b1;
  ictrl_addr = 15'd0;
  ictrl_wdata = 15'd128;
  // ictrl_rready = 1'b1;
  #100
  // Write
  $display("\n================== Time:%d, Start write Mem ================\n",$time);
  for(int i=0;i<2;i++) begin: writeData
    //        addr            wdata              strb           len   id
    writeMem(i*StrbWidth*16, i*(StrbWidth-1), {StrbWidth{1'b1}}, 15 , 1);
  end

  // Read
  $display("\n================== Time:%d, Start read Mem ================\n",$time);

  fork
    for(int i=0;i<2;i++) begin: readData
      //        addr          len  id
      readMem(i*StrbWidth*16,  15, 2);
    end 

    // b port
    for(int i=0;i<16;i++) begin: B_Port
        @(posedge clk);
        ictrl_cen <= 1'b1;
        ictrl_wen <= 1'b0;
        // ictrl_addr <= i+1024;
        ictrl_addr <= i;
        wait(ictrl_ready);
        @(posedge clk);
        ictrl_cen <= 1'b0;
    end
  join
end


// =================== back pressure ============
initial begin
    r_ready = 1'b0;
    #100
    r_ready = 1'b1;
    forever begin
        @(posedge clk);
        r_ready <= ~r_ready;
    end
end
initial begin
    ictrl_rready = 1'b0;
    #100
    ictrl_rready = 1'b1;
    forever begin
        @(posedge clk);
        ictrl_rready <= ~ictrl_rready;
    end
end

axi_master_mem#(
    .RW_DATA_WIDTH   ( DataWidth ),
    .RW_ADDR_WIDTH   ( AddrWidth ),
    .AXI_DATA_WIDTH  ( DataWidth ),
    .AXI_ADDR_WIDTH  ( AddrWidth ),
    .AXI_ID_WIDTH    ( IdWidth ),
    .AXI_USER_WIDTH  ( 1 )
)u_axi_master_mem(
    .clk             ( clk             ),
    .rst_n           ( rst_n           ),
    .rw_cen_i        ( mem_req        ),
    .rw_wen_i        ( mem_we        ),
    .rw_addr_i       ( mem_addr       ),
    .rw_size_i       ( mem_size     ),
    .rw_len_i        ( mem_len ),
    .rw_id_i         ( mem_id  ),
    .rw_wdata_i      ( mem_wdata      ),
    .rw_wmask_i      ( mem_be      ),
    .rw_ready_o      ( mem_gnt      ),
    .rw_rdata_o      ( mem_rsp_rdata      ),
    .rw_rvalid_o     ( mem_rsp_valid ),
    .rw_resp_o       (        ),
    .axi_aw_id_o     ( master_aw_id     ),
    .axi_aw_addr_o   ( master_aw_addr   ),
    .axi_aw_len_o    ( master_aw_len    ),
    .axi_aw_size_o   ( master_aw_size   ),
    .axi_aw_burst_o  ( master_aw_burst  ),
    .axi_aw_lock_o   ( master_aw_lock   ),
    .axi_aw_cache_o  ( master_aw_cache  ),
    .axi_aw_prot_o   ( master_aw_prot   ),
    .axi_aw_qos_o    ( master_aw_qos    ),
    .axi_aw_region_o ( master_aw_region ),
    .axi_aw_user_o   ( master_aw_user   ),
    .axi_aw_valid_o  ( master_aw_valid  ),
    .axi_aw_ready_i  ( master_aw_ready  ),
    .axi_w_ready_i   ( master_w_ready   ),
    .axi_w_valid_o   ( master_w_valid   ),
    .axi_w_data_o    ( master_w_data    ),
    .axi_w_strb_o    ( master_w_strb    ),
    .axi_w_last_o    ( master_w_last    ),
    .axi_w_user_o    ( master_w_user    ),
    .axi_b_ready_o   ( master_b_ready   ),
    .axi_b_valid_i   ( master_b_valid   ),
    .axi_b_resp_i    ( master_b_resp    ),
    .axi_b_id_i      ( master_b_id      ),
    .axi_b_user_i    ( master_b_user    ),
    .axi_ar_ready_i  ( master_ar_ready  ),
    .axi_ar_valid_o  ( master_ar_valid  ),
    .axi_ar_addr_o   ( master_ar_addr   ),
    .axi_ar_prot_o   ( master_ar_prot   ),
    .axi_ar_id_o     ( master_ar_id     ),
    .axi_ar_user_o   ( master_ar_user   ),
    .axi_ar_len_o    ( master_ar_len    ),
    .axi_ar_size_o   ( master_ar_size   ),
    .axi_ar_burst_o  ( master_ar_burst  ),
    .axi_ar_lock_o   ( master_ar_lock   ),
    .axi_ar_cache_o  ( master_ar_cache  ),
    .axi_ar_qos_o    ( master_ar_qos    ),
    .axi_ar_region_o ( master_ar_region ),
    .axi_r_ready_o   ( master_r_ready   ),
    .axi_r_valid_i   ( master_r_valid   ),
    .axi_r_resp_i    ( master_r_resp    ),
    .axi_r_data_i    ( master_r_data    ),
    .axi_r_last_i    ( master_r_last    ),
    .axi_r_id_i      ( master_r_id      ),
    .axi_r_user_i    ( master_r_user    )
);

axi_to_mem#(
    .DATA_WIDTH         ( DataWidth ),
    .ADDR_WIDTH         ( AddrWidth ),
    .STRB_WIDTH         ( StrbWidth ),
    .ID_WIDTH           ( IdWidth ),
    .INPUT_PIPE_STAGES  ( INPUT_PIPE_STAGES ),
    .OUTPUT_PIPE_STAGES ( OUTPUT_PIPE_STAGES ),
    .MEM_LATENCY        ( MEM_LATENCY ),
    .MEM_ADDR_WIDTH     ( MEM_ADDR_WIDTH )
)u_axi_ram(
    .clk                ( clk                ),
    .rst_n              ( rst_n              ),
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
    .mem_cen            ( s_mem_cen          ),
    .mem_last           ( s_mem_last         ),
    .mem_addr           ( s_mem_addr         ),
    .mem_ready          ( s_mem_ready        ),
    .mem_wen            ( s_mem_wen          ),
    .mem_wdata          ( s_mem_wdata        ),
    .mem_wstrb          ( s_mem_wstrb        ),
    .mem_rvalid         ( s_mem_rvalid       ),
    .mem_rlast          ( s_mem_rlast        ),
    .mem_rready         ( s_mem_rready       ),
    .mem_rdata          ( s_mem_rdata        )
);

// ========================= ibuffer ======================
ibuffer u_ibuffer(
    .clk      ( clk      ),
    .rst_n    ( rst_n    ),
    .cen_a    ( s_mem_cen    ),
    .last_a   ( s_mem_last   ),
    .ready_a  ( s_mem_ready  ),
    .wen_a    ( s_mem_wen    ),
    .addr_a   ( s_mem_addr[14:0]),
    .wdata_a  ( s_mem_wdata  ),
    .wstrb_a  ( s_mem_wstrb  ),
    .rdata_a  ( s_mem_rdata  ),
    .rvalid_a ( s_mem_rvalid ),
    .rlast_a  ( s_mem_rlast   ),
    .rready_a ( s_mem_rready ),
    .cen_b    ( ictrl_cen    ),
    .wen_b    ( ictrl_wen    ),
    .ready_b  ( ictrl_ready  ),
    .addr_b   ( ictrl_addr   ),
    .wdata_b  ( ictrl_wdata  ),
    .rdata_b  ( ictrl_rdata  ),
    .rvalid_b ( ictrl_rvalid ),
    .rready_b ( ictrl_rready )
);
// always @(posedge clk) begin
//     if(s_mem_cen && s_mem_ready && ~s_mem_wen) begin
//         $display("read data from addr: %h", s_mem_addr[15:0]);
//     end
// end
always @(posedge clk) begin
    if(s_mem_rvalid && s_mem_rready) begin
        $display("slave read data : %h", s_mem_rdata);
    end
end
always @(posedge clk) begin
    if(ictrl_rvalid && ictrl_rready) begin
        $display("ictrl read data : %h", ictrl_rdata);
    end
end
always @(posedge clk) begin
    if(s_mem_cen && s_mem_ready && s_mem_wen) begin
        $display("write data: %h, to addr: %h", s_mem_wdata, s_mem_addr[15:0]);
    end
end

assign s_axi_awid = master_aw_id     ; 
assign s_axi_awaddr = master_aw_addr   ; 
assign s_axi_awlen = master_aw_len    ; 
assign s_axi_awsize = master_aw_size   ; 
assign s_axi_awburst = master_aw_burst  ; 
assign s_axi_awlock = master_aw_lock   ; 
assign s_axi_awcache = master_aw_cache  ; 
assign s_axi_awprot = master_aw_prot   ;  
assign s_axi_awvalid = master_aw_valid  ; 
assign master_aw_ready = s_axi_awready; 
assign  master_w_ready  = s_axi_wready ; 
assign s_axi_wvalid = master_w_valid   ; 
assign s_axi_wdata = master_w_data    ; 
assign s_axi_wstrb = master_w_strb    ; 
assign s_axi_wlast = master_w_last    ; 
assign s_axi_bready = master_b_ready   ; 
assign  master_b_valid  = s_axi_bvalid ; 
assign  master_b_resp = s_axi_bresp   ; 
assign  master_b_id  =  s_axi_bid   ; 
assign  master_b_user = 1'b0   ; 
assign  master_ar_ready = s_axi_arready ; 
assign  s_axi_arvalid =master_ar_valid  ; 
assign  s_axi_araddr = master_ar_addr   ; 
assign  s_axi_arprot = master_ar_prot   ; 
assign  s_axi_arid = master_ar_id     ; 
assign  s_axi_arlen = master_ar_len    ; 
assign  s_axi_arsize = master_ar_size   ; 
assign  s_axi_arburst = master_ar_burst  ; 
assign  s_axi_arlock = master_ar_lock   ; 
assign  s_axi_arcache = master_ar_cache  ; 
// assign  s_axi_rready = master_r_ready   ; 
assign s_axi_rready = r_ready;
assign  master_r_valid = s_axi_rvalid  ; 
assign  master_r_resp = s_axi_rresp   ; 
assign  master_r_data = s_axi_rdata   ; 
assign  master_r_last = s_axi_rlast   ; 
assign  master_r_id = s_axi_rid     ; 
assign  master_r_user = 1'b0   ; 


task writeMem(input [AddrWidth-1:0] addr, [DataWidth-1:0] wdata, [DataWidth/8-1:0] be, [7:0] len, [IdWidth-1:0] id);

//   $display("time: %d, write addr: %h, wdata: %h", $time, addr, wdata);
  @(posedge clk);
  mem_addr <= addr;
  mem_wdata <= wdata;
  mem_be <= be;
  mem_req <= 1'b1;
  mem_we <= 1'b1;
  mem_size <= $clog2(StrbWidth);
  mem_len <= len;
  mem_id <= id;

  forever begin
    @(posedge clk);
    mem_wdata <= mem_wdata + 1;
    if (mem_gnt==1'b1) begin
      mem_req <= 1'b0;
      return;
    end
    else
      mem_req <= 1'b1;
  end

endtask


task readMem(input [AddrWidth-1:0] addr, [7:0] len, [IdWidth-1:0] id);

//   $display("time: %d, read addr: %h", $time, addr);
  @(posedge clk);
  mem_addr <= addr;
  mem_req <= 1'b1;
  mem_we <= 1'b0;
  mem_size <= $clog2(StrbWidth);
  mem_len <= len;
  mem_id <= id;

  forever begin
    @(posedge clk);
    if (mem_gnt==1'b1) begin
      mem_req <= 1'b0;
      return;
    end
    else
      mem_req <= 1'b1;
  end

endtask

endmodule