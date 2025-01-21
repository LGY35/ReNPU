module tb_idma_inoc_top();

parameter AddrWidth = 32;
parameter DataWidth = 128;
parameter IdWidth = 4;
parameter StrbWidth = DataWidth/8;
parameter MEM_ADDR_WIDTH = 15;
parameter MEM_SIM_DEPTH = 65536;
parameter INPUT_PIPE_STAGES = 1;
parameter MEM_LATENCY = 2;
parameter OUTPUT_PIPE_STAGES = 2;

parameter DATA_FIFO_DEPTH   = 64    ;
parameter DATA_FIFO_CNT_WID = 6+1   ;
parameter ADDR_FIFO_DEPTH   = 32    ;
parameter ADDR_FIFO_CNT_WID = 5+1   ;

parameter FLIT_WIDTH = 32;

parameter AXI4_ADDRESS_WIDTH = 32;
parameter AXI4_RDATA_WIDTH   = 32;
parameter AXI4_WDATA_WIDTH   = 32;
parameter AXI4_ID_WIDTH      = 8;
parameter AXI4_USER_WIDTH    = 1;
parameter AXI_NUMBYTES       = AXI4_WDATA_WIDTH/8;
parameter BUFF_DEPTH_SLAVE   = 4;
parameter APB_ADDR_WIDTH     = 12;

logic aclk, aresetn;
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

logic cfg_req       ;   
logic [AXI4_ADDRESS_WIDTH-1:0] cfg_addr      ;  
logic cfg_we        ; 
logic [AXI4_RDATA_WIDTH-1:0] cfg_data     ; 
logic [AXI4_RDATA_WIDTH/8-1:0] cfg_be        ;
logic [2:0] cfg_size;
logic [7:0] cfg_len;
logic [AXI4_ID_WIDTH-1:0] cfg_id;
logic cfg_gnt       ; 
logic cfgrsp_valid ; 
logic [AXI4_RDATA_WIDTH-1:0] cfg_rsp_rdata ;

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

logic                    m_arvalid;
logic [IdWidth-1:0]      m_arid   ;
logic [AddrWidth-1:0]    m_araddr ;
logic [8-1:0]            m_arlen  ;
logic [2:0]              m_arsize ;
logic [1:0]              m_arburst;
logic [1-1:0]            m_arlock ;
logic [3:0]              m_arcache;
logic [2:0]              m_arprot ;
logic                    m_arready;
logic                    m_rvalid ;
logic [IdWidth-1:0]      m_rid    ;
logic                    m_rlast  ;
logic [DataWidth-1:0]    m_rdata  ;
logic [1:0]              m_rresp  ;
logic                    m_rready ;

// config AXI slave port
logic  [AXI4_ID_WIDTH-1:0]       cfg_awid;
logic  [AXI4_ADDRESS_WIDTH-1:0]  cfg_awaddr;
logic  [7:0]                     cfg_awlen;
logic  [2:0]                     cfg_awsize;
logic  [1:0]                     cfg_awburst;
logic                            cfg_awlock;
logic  [3:0]                     cfg_awcache;
logic  [2:0]                     cfg_awprot;
logic                            cfg_awvalid;
logic                            cfg_awready;
logic  [AXI4_WDATA_WIDTH-1:0]    cfg_wdata;
logic  [AXI_NUMBYTES-1:0]        cfg_wstrb;
logic                            cfg_wlast;
logic                            cfg_wvalid;
logic                            cfg_wready;
logic  [AXI4_ID_WIDTH-1:0]       cfg_bid;
logic  [1:0]                     cfg_bresp;
logic                            cfg_bvalid;
logic                            cfg_bready;
logic  [AXI4_ID_WIDTH-1:0]       cfg_arid;
logic  [AXI4_ADDRESS_WIDTH-1:0]  cfg_araddr;
logic  [7:0]                     cfg_arlen;
logic  [2:0]                     cfg_arsize;
logic  [1:0]                     cfg_arburst;
logic                            cfg_arlock;
logic  [3:0]                     cfg_arcache;
logic  [2:0]                     cfg_arprot;
logic                            cfg_arvalid;
logic                            cfg_arready;
logic  [AXI4_ID_WIDTH-1:0]       cfg_rid;
logic  [AXI4_RDATA_WIDTH-1:0]    cfg_rdata;
logic  [1:0]                     cfg_rresp;
logic                            cfg_rlast;
logic                            cfg_rvalid;
logic                            cfg_rready;
// apb interface master 0
logic [11:0]                     m0_paddr            ;
logic [0:0]                      m0_psel             ;
logic                            m0_penable          ;
logic                            m0_pready           ;
logic                            m0_pwrite           ;
logic [3:0]                      m0_pstrb            ;
logic [31:0]                     m0_pwdata           ;
// apb interface master 1
logic [11:0]                     m1_paddr            ;
logic [0:0]                      m1_psel             ;
logic                            m1_penable          ;
logic                            m1_pready           ;
logic                            m1_pwrite           ;
logic [3:0]                      m1_pstrb            ;
logic [31:0]                     m1_pwdata           ;

// send to noc
logic [11:0]           send_valid ;
logic [11:0][FLIT_WIDTH-1:0] send_flit ;
logic [11:0]           send_ready ;
// receive from noc
logic [11:0]           recv_valid ;
logic [11:0][FLIT_WIDTH-1:0] recv_flit ;
logic [11:0]           recv_ready ;
logic   interrupt;

logic     [11:0]                 cfg_apb_PADDR;
logic     [0:0]                  cfg_apb_PSEL;
logic                            cfg_apb_PENABLE;
logic                            cfg_apb_PREADY;
logic                            cfg_apb_PWRITE;
logic     [3:0]                  cfg_apb_PSTRB;
logic     [2:0]                  cfg_apb_PPROT;
logic     [31:0]                 cfg_apb_PWDATA;
logic     [31:0]                 cfg_apb_PRDATA;
logic                            cfg_apb_PSLVERR;
logic     [11:0]                 nodes_pc;

initial begin
  nodes_pc = 12'b101010101010;
  #100 forever begin
    @(posedge aclk);
      nodes_pc <= ~nodes_pc;
  end
end

// ========================== clk and reset =============================	 
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

// ========================== Time out =============================
initial begin
  #500000
  $display("\n============== TimeOut ! Simulation finish ! ============\n");
  $finish;
end

// ============================== dump fsdb =============================
initial begin
	$display("\n================== Time:%d, Dump Start ================\n",$time);
	$fsdbDumpfile("tb_idma_inoc_top.fsdb");
  $fsdbDumpvars("+all");
end

initial begin
  #100
  @(posedge aclk);
  nodes_pc <= 1'b1;
  forever begin
    @(posedge aclk);
    nodes_pc <= !nodes_pc;
  end
end

// ========================= access mem ============================
initial begin

  // send_ready = 1'b1;
  for (int i = 0; i<12; i++) begin
    recv_valid[i] = 1'b0;
    recv_flit[i] = 32'b0;
  end
  
  #100

  // slave Write
  // $display("\n================== Time:%d, slave write ibuffer ================\n",$time);
  // for(int i=0;i<2;i++) begin: slave_write
  //   //             addr            wdata              strb           len   id
  //   writeMem(i*StrbWidth*16+128, i*(StrbWidth-1), {StrbWidth{1'b1}}, 15 , 1);
  // end

  // DMA read
  @(posedge aclk);
  // rd contrl
  write_cfg('hc, {1'b0, 1'b0, 1'b1, 1'b0, 4'd2}, {4{1'b1}}, 0, 2);
  // rd addr
  write_cfg('h24, 0, {4{1'b1}}, 0, 2);
  // rd num
  // write_cfg('h28, 32, {4{1'b1}}, 0, 2);
  write_cfg('h28, 128, {4{1'b1}}, 0, 2);
  // rd req
  write_cfg('h20, 1, {4{1'b1}}, 0, 2);
  // cfg rd
  write_cfg('h0, 1, {4{1'b1}}, 0, 2);
  // unmask int
  write_cfg('h3c, 32'd0, {4{1'b1}}, 0, 2);

  // cfg noc
  @(posedge aclk);

  // start FSM
  write_cfg('h30, 0, {4{1'b1}}, 0, 2);

  fork
    // slave Read
    $display("\n================== Time:%d, slave read ibuffer ================\n",$time);
    for(int i=0;i<2;i++) begin: slave_read
      //        addr          len  id
      // readMem(i*StrbWidth*16 + 32,  15, 2);
    end 

    //  ============================= case 1 =============================
    /*
    begin
      // 0, 1 sync req
      begin
        @(posedge aclk);
        recv_valid[0] <= 1'b1;
        recv_flit[0] <= {1'b0, 1'b1, 19'd128}; // len, addr
        recv_valid[1] <= 1'b1;
        recv_flit[1] <= {1'b0, 1'b1, 19'd128}; // len, addr
        wait(recv_ready[0] || recv_ready[1]);
        @(posedge aclk);
        recv_valid[0] <= 1'b0;
        recv_valid[1] <= 1'b0;
      end

      fork
        // 2 async req
        begin
          @(posedge aclk);
          recv_valid[2] <= 1'b1;
          recv_flit[2] <= {1'b1, 1'b0, 19'd128}; // len, addr
          wait(recv_ready[2]);
          @(posedge aclk);
          recv_valid[2] <= 1'b0;
          repeat(16) begin
            @(posedge aclk);
            wait(send_valid[2] && send_ready[2]);
          end
          @(posedge aclk);
          recv_valid[2] <= 1'b1;
          recv_flit[2] <= {1'b1, 31'd0}; // intr
          @(posedge aclk);
          recv_valid[2] <= 1'b0;
        end
        begin
          // 0,1 intr
          @(posedge aclk);
          recv_valid[0] <= 1'b1;
          recv_flit[0] <= {1'b1, 31'd0}; // intr
          recv_valid[1] <= 1'b1;
          recv_flit[1] <= {1'b1, 31'd0}; // intr
          @(posedge aclk);
          recv_valid[0] <= 1'b0;
          recv_valid[1] <= 1'b0;
        end
      join

      // 3 async req
      begin
        @(posedge aclk);
        recv_valid[3] <= 1'b1;
        recv_flit[3] <= {1'b1, 1'b0, 19'd128}; // len, addr
        wait(recv_ready[3]);
        @(posedge aclk);
        recv_valid[3] <= 1'b0;
        repeat(16) begin
          @(posedge aclk);
          wait(send_valid[3] && send_ready[3]);
        end
        @(posedge aclk);
        recv_valid[3] <= 1'b1;
        recv_flit[3] <= {1'b1, 31'd0}; // intr
        @(posedge aclk);
        recv_valid[3] <= 1'b0;
      end

      // 4, 5 sync req
      begin
        @(posedge aclk);
        recv_valid[4] <= 1'b1;
        recv_flit[4] <= {1'b0, 1'b1, 19'd128}; // len, addr
        recv_valid[5] <= 1'b1;
        recv_flit[5] <= {1'b0, 1'b1, 19'd128}; // len, addr
        while(!recv_ready[4] && !recv_ready[5]) begin;
          @(posedge aclk);
        end
        recv_valid[4] <= 1'b0;
        recv_valid[5] <= 1'b0;
        // 4, 5 intr
        repeat(16) begin
          @(posedge aclk);
        end
        recv_valid[4] <= 1'b1;
        recv_flit[4] <= {1'b1, 31'd0}; // intr
        recv_valid[5] <= 1'b1;
        recv_flit[5] <= {1'b1, 31'd0}; // intr
        @(posedge aclk);
        recv_valid[4] <= 1'b0;
        recv_valid[5] <= 1'b0;
      end
    end
    */


    //  ============================= case 2 =============================
    /*
    begin
      // 0, 1 sync req
      @(posedge aclk);
      recv_valid[0] <= 1'b1;
      recv_flit[0] <= {1'b0, 1'b1, 19'd120}; // len, addr
      recv_valid[1] <= 1'b1;
      recv_flit[1] <= {1'b0, 1'b1, 19'd120}; // len, addr
      while(!recv_ready[0] && !recv_ready[1]) begin;
        @(posedge aclk);
      end
      recv_valid[0] <= 1'b0;
      recv_valid[1] <= 1'b0;

      fork
        // 2 async req
        begin
          @(posedge aclk);
          recv_valid[2] <= 1'b1;
          recv_flit[2] <= {1'b1, 1'b0, 19'd128}; // len, addr
          while(!recv_ready[2]) begin;
            @(posedge aclk);
          end
          recv_valid[2] <= 1'b0;
          repeat(16) begin
            @(posedge aclk);
            // wait(send_valid[2] && send_ready[2]);
          end
          repeat(100) @(posedge aclk);
          recv_valid[2] <= 1'b1;
          recv_flit[2] <= {1'b1, 31'd0}; // intr
          @(posedge aclk);
          recv_valid[2] <= 1'b0;
        end
        begin
          // 0,1 intr
          repeat(100) @(posedge aclk);
          recv_valid[0] <= 1'b1;
          recv_flit[0] <= {1'b1, 31'd0}; // intr
          recv_valid[1] <= 1'b1;
          recv_flit[1] <= {1'b1, 31'd0}; // intr
          @(posedge aclk);
          recv_valid[0] <= 1'b0;
          recv_valid[1] <= 1'b0;
        end
      join

      // 3 async req
      begin
        @(posedge aclk);
        recv_valid[3] <= 1'b1;
        recv_flit[3] <= {1'b1, 1'b0, 19'd128}; // len, addr
        while(!recv_ready[3]) begin;
          @(posedge aclk);
        end
        recv_valid[3] <= 1'b0;
        repeat(16) begin
          @(posedge aclk);
          // wait(send_valid[3] && send_ready[3]);
        end
        repeat(100) @(posedge aclk);
        recv_valid[3] <= 1'b1;
        recv_flit[3] <= {1'b1, 31'd0}; // intr
        @(posedge aclk);
        recv_valid[3] <= 1'b0;
      end

      // 4, 5 sync req
      @(posedge aclk);
      recv_valid[4] <= 1'b1;
      recv_flit[4] <= {1'b0, 1'b1, 19'd128}; // len, addr
      recv_valid[5] <= 1'b1;
      recv_flit[5] <= {1'b0, 1'b1, 19'd128}; // len, addr
      while(!recv_ready[4] && !recv_ready[5]) begin;
        @(posedge aclk);
      end
      recv_valid[4] <= 1'b0;
      recv_valid[5] <= 1'b0;

      fork
        // 6 async req
        begin
          @(posedge aclk);
          recv_valid[6] <= 1'b1;
          recv_flit[6] <= {1'b1, 1'b0, 19'd128}; // len, addr
          wait(recv_ready[6]);
          @(posedge aclk);
          recv_valid[6] <= 1'b0;
          repeat(16) begin
            @(posedge aclk);
            // wait(send_valid[6] && send_ready[6]);
          end
          repeat(100) @(posedge aclk);
          recv_valid[6] <= 1'b1;
          recv_flit[6] <= {1'b1, 31'd0}; // intr
          @(posedge aclk);
          recv_valid[6] <= 1'b0;
        end
        begin
          // 4,5 intr
          repeat(100) @(posedge aclk);
          recv_valid[4] <= 1'b1;
          recv_flit[4] <= {1'b1, 31'd0}; // intr
          recv_valid[5] <= 1'b1;
          recv_flit[5] <= {1'b1, 31'd0}; // intr
          @(posedge aclk);
          recv_valid[4] <= 1'b0;
          recv_valid[5] <= 1'b0;
        end
      join

      // 7 async req
      begin
        @(posedge aclk);
        recv_valid[7] <= 1'b1;
        recv_flit[7] <= {1'b1, 1'b0, 19'd128}; // len, addr
        wait(recv_ready[7]);
        @(posedge aclk);
        recv_valid[7] <= 1'b0;
        repeat(16) begin
          @(posedge aclk);
          // wait(send_valid[7] && send_ready[7]);
        end
        repeat(100) @(posedge aclk);
        recv_valid[7] <= 1'b1;
        recv_flit[7] <= {1'b1, 31'd0}; // intr
        @(posedge aclk);
        recv_valid[7] <= 1'b0;
      end

      // 8, 9 sync req
      @(posedge aclk);
      recv_valid[8] <= 1'b1;
      recv_flit[8] <= {1'b0, 1'b1, 19'd128}; // len, addr
      recv_valid[9] <= 1'b1;
      recv_flit[9] <= {1'b0, 1'b1, 19'd128}; // len, addr
      wait(recv_ready[8] || recv_ready[9]);
      @(posedge aclk);
      recv_valid[8] <= 1'b0;
      recv_valid[9] <= 1'b0;

      fork
        // 10 async req
        begin
          @(posedge aclk);
          recv_valid[10] <= 1'b1;
          recv_flit[10] <= {1'b1, 1'b0, 19'd128}; // len, addr
          wait(recv_ready[10]);
          @(posedge aclk);
          recv_valid[10] <= 1'b0;
          repeat(16) begin
            @(posedge aclk);
            // wait(send_valid[10] && send_ready[10]);
          end
          repeat(100) @(posedge aclk);
          recv_valid[10] <= 1'b1;
          recv_flit[10] <= {1'b1, 31'd0}; // intr
          @(posedge aclk);
          recv_valid[10] <= 1'b0;
        end
        begin
          // 8,9 intr
          repeat(100) @(posedge aclk);
          recv_valid[8] <= 1'b1;
          recv_flit[8] <= {1'b1, 31'd0}; // intr
          recv_valid[9] <= 1'b1;
          recv_flit[9] <= {1'b1, 31'd0}; // intr
          @(posedge aclk);
          recv_valid[8] <= 1'b0;
          recv_valid[9] <= 1'b0;
        end
      join

      // 11 async req
      begin
        @(posedge aclk);
        recv_valid[11] <= 1'b1;
        recv_flit[11] <= {1'b1, 1'b0, 19'd128}; // len, addr
        wait(recv_ready[11]);
        @(posedge aclk);
        recv_valid[11] <= 1'b0;
        repeat(16) begin
          @(posedge aclk);
          // wait(send_valid[11] && send_ready[11]);
        end
        repeat(100) @(posedge aclk);
        recv_valid[11] <= 1'b1;
        recv_flit[11] <= {1'b1, 31'd0}; // intr
        @(posedge aclk);
        recv_valid[11] <= 1'b0;
      end

      // next small loop
      // wait(tb_idma_inoc_top.u_idma_inoc_top.u_idma_inoc_interface.u_idma_inoc_control.finish_flag);
      wait(tb_idma_inoc_top.u_idma_inoc_top.interrupt && tb_idma_inoc_top.u_idma_inoc_top.u_idma_inoc_regfile.small_loop_end_int_status);
      repeat(16) @(posedge aclk);
      write_cfg('h38, 32'd1, {4{1'b1}}, 0, 2); //clear int

      // 0, 1 sync req
      @(posedge aclk);
      recv_valid[0] <= 1'b1;
      recv_flit[0] <= {1'b0, 1'b1, 19'd128}; // len, addr
      recv_valid[1] <= 1'b1;
      recv_flit[1] <= {1'b0, 1'b1, 19'd128}; // len, addr
      // while(!recv_ready[0] && !recv_ready[1]) begin;
      //   @(posedge aclk);
      // end
      
      @(posedge aclk);
      wait(recv_ready[0] && recv_ready[1]);
      @(posedge aclk);
      

      recv_valid[0] <= 1'b0;
      recv_valid[1] <= 1'b0;


        // 2 async req
        begin
          @(posedge aclk);
          recv_valid[2] <= 1'b1;
          recv_flit[2] <= {1'b1, 1'b0, 19'd128}; // len, addr
          // while(!recv_ready[2]) begin;
          //   @(posedge aclk);
          // end

          @(posedge aclk);
          wait(recv_ready[2]);
          @(posedge aclk);
          
          recv_valid[2] <= 1'b0;
          repeat(48) begin
            @(posedge aclk);
            // wait(send_valid[2] && send_ready[2]);
          end
          repeat(100) @(posedge aclk);
          recv_valid[2] <= 1'b1;
          recv_flit[2] <= {1'b1, 31'd0}; // intr
          @(posedge aclk);
          recv_valid[2] <= 1'b0;
        end
        begin
          // 0,1 intr
          repeat(48) @(posedge aclk);
          recv_valid[0] <= 1'b1;
          recv_flit[0] <= {1'b1, 31'd0}; // intr
          recv_valid[1] <= 1'b1;
          recv_flit[1] <= {1'b1, 31'd0}; // intr
          @(posedge aclk);
          recv_valid[0] <= 1'b0;
          recv_valid[1] <= 1'b0;
        end


      // 3 async req
      begin
        @(posedge aclk);
        recv_valid[3] <= 1'b1;
        recv_flit[3] <= {1'b1, 1'b0, 19'd128}; // len, addr
        // while(!recv_ready[3]) begin;
        //   @(posedge aclk);
        // end
        @(posedge aclk);
        wait(recv_ready[3]);
        @(posedge aclk);
        
        recv_valid[3] <= 1'b0;
        repeat(16) begin
          @(posedge aclk);
          // wait(send_valid[3] && send_ready[3]);
        end
        repeat(100) @(posedge aclk);
        recv_valid[3] <= 1'b1;
        recv_flit[3] <= {1'b1, 31'd0}; // intr
        @(posedge aclk);
        recv_valid[3] <= 1'b0;
      end

      // 4, 5 sync req
      @(posedge aclk);
      recv_valid[4] <= 1'b1;
      recv_flit[4] <= {1'b0, 1'b1, 19'd128}; // len, addr
      recv_valid[5] <= 1'b1;
      recv_flit[5] <= {1'b0, 1'b1, 19'd128}; // len, addr
      // while(!recv_ready[4] && !recv_ready[5]) begin;
      //   @(posedge aclk);
      // end
      @(posedge aclk);
      wait(recv_ready[4] && recv_ready[5]);
      @(posedge aclk);
      
      recv_valid[4] <= 1'b0;
      recv_valid[5] <= 1'b0;

      begin
        repeat(100) begin
          @(posedge aclk);
        end
        // 4,5 intr
        repeat(100) @(posedge aclk);
        recv_valid[4] <= 1'b1;
        recv_flit[4] <= {1'b1, 31'd0}; // intr
        recv_valid[5] <= 1'b1;
        recv_flit[5] <= {1'b1, 31'd0}; // intr
        @(posedge aclk);
        recv_valid[4] <= 1'b0;
        recv_valid[5] <= 1'b0;
      end
    end
    */
    

    //  ============================= case 2 =============================
    // begin
    //   // 0, first async req
    //   @(posedge aclk);
    //   recv_valid[0] <= 1'b1;
    //   recv_flit[0] <= {1'b1, 1'b1, 19'd120}; // len, addr
    //   @(posedge aclk);
    //   wait(recv_ready[0]);
    //   @(posedge aclk);
    //   recv_valid[0] <= 1'b0;

    //   // 0, second async req
    //   @(posedge aclk);
    //   recv_valid[0] <= 1'b1;
    //   recv_flit[0] <= {1'b1, 1'b0, 19'd0}; // len, addr
    //   @(posedge aclk);
    //   wait(recv_ready[0]);
    //   @(posedge aclk);
    //   recv_valid[0] <= 1'b0;

    //   // 1, first async req
    //   @(posedge aclk);
    //   recv_valid[1] <= 1'b1;
    //   recv_flit[1] <= {1'b1, 1'b0, 19'd0}; // len, addr
    //   @(posedge aclk);
    //   wait(recv_ready[1]);
    //   @(posedge aclk);
    //   recv_valid[1] <= 1'b0;


    //   // 0 intr
    //   repeat(10) @(posedge aclk);
    //   recv_valid[0] <= 1'b1;
    //   recv_flit[0] <= {1'b1, 31'd0}; // intr
    //   @(posedge aclk);
    //   recv_valid[0] <= 1'b0;
    //   repeat(40) @(posedge aclk);
    //   recv_valid[1] <= 1'b1;
    //   recv_flit[1] <= {1'b1, 31'd0}; // intr
    //   @(posedge aclk);
    //   recv_valid[1] <= 1'b0;
    // end

    //  ============================= case 4 =============================
    /*
    begin
      // 0~7 sync req
      @(posedge aclk);
      for(int i=0;i<8;i++) begin
        recv_valid[i] <= 1'b1;
        recv_flit[i] <= {'h8_0040}; // len, addr
      end
      wait(recv_ready[0] || recv_ready[1] || recv_ready[2] || recv_ready[3]
        || recv_ready[4] || recv_ready[5] || recv_ready[6] || recv_ready[7]);
      @(posedge aclk);
      recv_valid[0] <= 1'b0;
      recv_valid[1] <= 1'b0;
      recv_valid[2] <= 1'b0;
      recv_valid[3] <= 1'b0;
      recv_valid[4] <= 1'b0;
      recv_valid[5] <= 1'b0;
      recv_valid[6] <= 1'b0;
      recv_valid[7] <= 1'b0;

      // 0~7 intr
      repeat(100) @(posedge aclk);
      recv_valid[0] <= 1'b1;
      recv_flit[0] <= {1'b1, 31'd0}; // intr
      recv_valid[1] <= 1'b1;
      recv_flit[1] <= {1'b1, 31'd0}; // intr
      recv_valid[2] <= 1'b1;
      recv_flit[2] <= {1'b1, 31'd0}; // intr
      recv_valid[3] <= 1'b1;
      recv_flit[3] <= {1'b1, 31'd0}; // intr
      recv_valid[4] <= 1'b1;
      recv_flit[4] <= {1'b1, 31'd0}; // intr
      recv_valid[5] <= 1'b1;
      recv_flit[5] <= {1'b1, 31'd0}; // intr
      recv_valid[6] <= 1'b1;
      recv_flit[6] <= {1'b1, 31'd0}; // intr
      recv_valid[7] <= 1'b1;
      recv_flit[7] <= {1'b1, 31'd0}; // intr
    end
    */

    begin
      // 0～2 async req
      repeat(500) @(posedge aclk);
      for(int i=0;i<=2;i++) begin
        recv_valid[i] <= 1'b1;
        recv_flit[i] <= {'h10_0040}; // len, addr
      end
      fork
          begin
            wait(recv_ready[0]);
            @(posedge aclk);
            recv_valid[0] <= 1'b0;
          end
          begin
            wait(recv_ready[1]);
            @(posedge aclk);
            recv_valid[1] <= 1'b0;
          end
          begin
            wait(recv_ready[2]);
            @(posedge aclk);
            recv_valid[2] <= 1'b0;
          end
      join
    end

    
  join
end


// =================== back pressure ============
initial begin
    r_ready = 1'b0;
    #700;
    // #100;
    @(posedge aclk);
    r_ready <= 1'b1;
    forever begin
        @(posedge aclk);
        r_ready <= ~r_ready;
    end
end

initial begin
    m0_pready = 1'b1;
    // #700;
    // @(posedge aclk);
    // m0_pready <= 1'b1;
    // forever begin
    //     @(posedge aclk);
    //     m0_pready <= ~m0_pready;
    // end
end

initial begin
    m1_pready = 1'b1;
    // #700;
    // @(posedge aclk);
    // m1_pready <= 1'b1;
    // forever begin
    //     @(posedge aclk);
    //     m1_pready <= ~m1_pready;
    // end
end

genvar j;
generate
  for (j = 0; j<12; j++) begin
    initial begin
      send_ready[j] = 1'b0;
      #100;
      @(posedge aclk);
      send_ready[j] <= 1'b1;
      forever begin
          @(posedge aclk);
          send_ready[j] <= ~send_ready[j];
      end
    end
  end
endgenerate


// ============== print ================
always @( posedge aclk ) begin : print
  for (int i = 0; i<12 ; i++) begin
    if(send_valid[i] && send_ready[i])
      $display("send data: %h , to noc id: %0d", send_flit[i], i);
  end
end

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
    .rw_wdata_i      ( cfg_data      ),
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
    .axi_aw_region_o (  ),
    .axi_aw_user_o   (    ),
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

axi_master_mem#(
    .RW_DATA_WIDTH   ( DataWidth ),
    .RW_ADDR_WIDTH   ( AddrWidth ),
    .AXI_DATA_WIDTH  ( DataWidth ),
    .AXI_ADDR_WIDTH  ( AddrWidth ),
    .AXI_ID_WIDTH    ( IdWidth ),
    .AXI_USER_WIDTH  ( 1 )
)u_axi_master_mem(
    .clk             ( aclk           ),
    .rst_n           ( aresetn        ),
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



// for sim
axi_ram#(
    .DATA_WIDTH         ( DataWidth ),
    .ADDR_WIDTH         ( AddrWidth ),
    .STRB_WIDTH         ( StrbWidth ),
    .ID_WIDTH           ( IdWidth ),
    .PIPELINE_OUTPUT    ( 0 )
)u_axi_ram(
    .clk                ( aclk               ),
    .rst                ( !aresetn            ),
    .s_axi_awid         ( 'b0      ),
    .s_axi_awaddr       ( 'b0      ),
    .s_axi_awlen        ( 'b0      ),
    .s_axi_awsize       ( 'b0      ),
    .s_axi_awburst      ( 'b0      ),
    .s_axi_awlock       ( 'b0      ),
    .s_axi_awcache      ( 'b0      ),
    .s_axi_awprot       ( 'b0      ),
    .s_axi_awvalid      ( 'b0      ),
    .s_axi_awready      (          ),
    .s_axi_wdata        ( 'b0      ),
    .s_axi_wstrb        ( 'b0      ),
    .s_axi_wlast        ( 'b0      ),
    .s_axi_wvalid       ( 'b0      ),
    .s_axi_wready       (          ),
    .s_axi_bid          (          ),
    .s_axi_bresp        (          ),
    .s_axi_bvalid       (          ),
    .s_axi_bready       ( 'b1      ),
    .s_axi_arid         ( m_arid         ),
    .s_axi_araddr       ( m_araddr       ),
    .s_axi_arlen        ( m_arlen        ),
    .s_axi_arsize       ( m_arsize       ),
    .s_axi_arburst      ( m_arburst      ),
    .s_axi_arlock       ( m_arlock       ),
    .s_axi_arcache      ( m_arcache      ),
    .s_axi_arprot       ( m_arprot       ),
    .s_axi_arvalid      ( m_arvalid      ),
    .s_axi_arready      ( m_arready      ),
    .s_axi_rid          ( m_rid          ),
    .s_axi_rdata        ( m_rdata        ),
    .s_axi_rresp        ( m_rresp        ),
    .s_axi_rlast        ( m_rlast        ),
    .s_axi_rvalid       ( m_rvalid       ),
    .s_axi_rready       ( m_rready       )
);

axi2apb #(
    .AXI4_ADDRESS_WIDTH ( AXI4_ADDRESS_WIDTH ),
    .AXI4_RDATA_WIDTH   ( AXI4_RDATA_WIDTH   ),
    .AXI4_WDATA_WIDTH   ( AXI4_WDATA_WIDTH   ),
    .AXI4_ID_WIDTH      ( AXI4_ID_WIDTH      ),
    .AXI4_USER_WIDTH    ( AXI4_USER_WIDTH    ),
    .AXI_NUMBYTES       ( AXI4_WDATA_WIDTH/8 ),
    .BUFF_DEPTH_SLAVE   ( BUFF_DEPTH_SLAVE),
    .APB_ADDR_WIDTH     ( APB_ADDR_WIDTH  )
) u_axi2apb
(
    .ACLK(aclk),
    .ARESETn(aresetn),
    .test_en_i(1'b0),

    .AWID_i(cfg_awid),
    .AWADDR_i(cfg_awaddr),
    .AWLEN_i(cfg_awlen),
    .AWSIZE_i(cfg_awsize),
    .AWBURST_i(cfg_awburst),
    .AWLOCK_i(cfg_awlock),
    .AWCACHE_i(cfg_awcache),
    .AWPROT_i(cfg_awprot),
    .AWREGION_i(4'b0),
    .AWUSER_i({AXI4_USER_WIDTH{1'b0}}),
    .AWQOS_i(4'b0),
    .AWVALID_i(cfg_awvalid),
    .AWREADY_o(cfg_awready),

    .WDATA_i(cfg_wdata),
    .WSTRB_i(cfg_wstrb),
    .WLAST_i(cfg_wlast),
    .WUSER_i({AXI4_USER_WIDTH{1'b0}}),
    .WVALID_i(cfg_wvalid),
    .WREADY_o(cfg_wready),

    .BID_o(cfg_bid),
    .BRESP_o(cfg_bresp),
    .BVALID_o(cfg_bvalid),
    .BUSER_o(),
    .BREADY_i(cfg_bready),

    .ARID_i(cfg_arid),
    .ARADDR_i(cfg_araddr),
    .ARLEN_i(cfg_arlen),
    .ARSIZE_i(cfg_arsize),
    .ARBURST_i(cfg_arburst),
    .ARLOCK_i(cfg_arlock),
    .ARCACHE_i(cfg_arcache),
    .ARPROT_i(cfg_arprot),
    .ARREGION_i(4'b0),
    .ARUSER_i({AXI4_USER_WIDTH{1'b0}}),
    .ARQOS_i(4'b0),
    .ARVALID_i(cfg_arvalid),
    .ARREADY_o(cfg_arready),

    .RID_o(cfg_rid),
    .RDATA_o(cfg_rdata),
    .RRESP_o(cfg_rresp),
    .RLAST_o(cfg_rlast),
    .RUSER_o(),
    .RVALID_o(cfg_rvalid),
    .RREADY_i(cfg_rready),

    .PENABLE(cfg_apb_PENABLE),
    .PWRITE(cfg_apb_PWRITE),
    .PWSTRB(cfg_apb_PSTRB),
    .PADDR(cfg_apb_PADDR),
    .PSEL(cfg_apb_PSEL),
    .PWDATA(cfg_apb_PWDATA),
    .PRDATA(cfg_apb_PRDATA),
    .PREADY(cfg_apb_PREADY),
    .PSLVERR(cfg_apb_PSLVERR)
);
    



idma_inoc_top#(
    .AXI_DW            ( DataWidth ),
    .AXI_AW            ( AddrWidth ),
    .STRB_WIDTH        ( StrbWidth ),
    .ID_WIDTH          ( IdWidth ),
    .AXI_LENW          ( 4 ),
    .AXI_LOCKW         ( 1 ),
    .MEM_AW            ( MEM_ADDR_WIDTH ),
    .FLIT_WIDTH        ( FLIT_WIDTH )
)u_idma_inoc_top(
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
    .cfg_apb_PADDR     ( cfg_apb_PADDR     ),
    .cfg_apb_PSEL      ( cfg_apb_PSEL      ),
    .cfg_apb_PENABLE   ( cfg_apb_PENABLE   ),
    .cfg_apb_PREADY    ( cfg_apb_PREADY     ),
    .cfg_apb_PWRITE    ( cfg_apb_PWRITE    ),
    .cfg_apb_PSTRB     ( cfg_apb_PSTRB     ),
    .cfg_apb_PPROT     ( cfg_apb_PPROT     ),
    .cfg_apb_PWDATA    ( cfg_apb_PWDATA    ),
    .cfg_apb_PRDATA    ( cfg_apb_PRDATA    ),
    .cfg_apb_PSLVERR   ( cfg_apb_PSLVERR   ),
    .m0_paddr          ( m0_paddr          ),
    .m0_psel           ( m0_psel           ),
    .m0_penable        ( m0_penable        ),
    .m0_pready         ( m0_pready         ),
    .m0_pwrite         ( m0_pwrite         ),
    .m0_pstrb          ( m0_pstrb          ),
    .m0_pwdata         ( m0_pwdata         ),
    .m1_paddr          ( m1_paddr          ),
    .m1_psel           ( m1_psel           ),
    .m1_penable        ( m1_penable        ),
    .m1_pready         ( m1_pready         ),
    .m1_pwrite         ( m1_pwrite         ),
    .m1_pstrb          ( m1_pstrb          ),
    .m1_pwdata         ( m1_pwdata         ),
    .send_valid        ( send_valid        ),
    .send_flit         ( send_flit         ),
    .send_ready        ( send_ready        ),
    .recv_valid        ( recv_valid        ),
    .recv_flit         ( recv_flit         ),
    .recv_ready        ( recv_ready        ),
    .interrupt         ( interrupt         ),
    .nodes_pc          ( nodes_pc          )
);


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
  @(posedge aclk);
  mem_addr <= addr;
  mem_wdata <= wdata;
  mem_be <= be;
  mem_req <= 1'b1;
  mem_we <= 1'b1;
  mem_size <= $clog2(StrbWidth);
  mem_len <= len;
  mem_id <= id;

  forever begin
    @(posedge aclk);
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
  @(posedge aclk);
  mem_addr <= addr;
  mem_wdata <= 128'b0;
  mem_be <= 16'b0;
  mem_req <= 1'b1;
  mem_we <= 1'b0;
  mem_size <= $clog2(StrbWidth);
  mem_len <= len;
  mem_id <= id;

  forever begin
    @(posedge aclk);
    if (mem_gnt==1'b1) begin
      mem_req <= 1'b0;
      return;
    end
    else
      mem_req <= 1'b1;
  end
endtask


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