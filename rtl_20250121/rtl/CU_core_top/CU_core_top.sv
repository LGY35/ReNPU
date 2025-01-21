module CU_core_top #(
    parameter   N_EXT_PERF_COUNTERS = 1
)(
    input                           clk,
    input                           rst_n,
    
    //riscv core
    input                               clock_en_i, //enable clock, otherwise it is gated
    input                               test_en_i, //enable all clock gates for testing

    input  [31:0]                       boot_addr_i,
    input  [ 3:0]                       core_id_i,
    input  [ 5:0]                       cluster_id_i,    

    input                               fetch_enable_i,
    output logic                        core_busy_o,

    //Instruction memory interface
    output logic                        riscv_instr_req_o,
    input                               riscv_instr_gnt_i,
    output logic [31:0]                 riscv_instr_addr_o,
    input                               riscv_instr_rvalid_i,
    input   [31:0]                      riscv_instr_rdata_i,

    //Data memory interface
    output logic                        riscv_data_req_o,
    input                               riscv_data_gnt_i,
    output                              riscv_data_we_o,
    output logic [3:0]                  riscv_data_be_o,
    output logic [31:0]                 riscv_data_addr_o,
    output logic [31:0]                 riscv_data_wdata_o,
    input                               riscv_data_rvalid_i,
    input   [31:0]                      riscv_data_rdata_i,

    //Interrupt inputs
    input                               irq_i, //level sensitive IR lines
    input   [4:0]                       irq_id_i,
    output logic                        irq_ack_o,
    input                               irq_sec_i,
    output logic [4:0]                  irq_id_o,
    output logic                        sec_lvl_o, //csr out
      
    //Debug Interface
    input                               debug_req_i, //to id
    input  [N_EXT_PERF_COUNTERS-1:0]    ext_perf_counters_i,

    //to NOC
    output logic                        Noc_cmd_req_o,
    output logic [2:0]                  Noc_cmd_addr_o,
    input                               Noc_cmd_gnt_i,
    input                               Noc_cmd_ok_i,
    
    output logic                        Noc_cfg_vld_o,
    output logic [6:0]                  Noc_cfg_addr_o,
    output logic [12:0]                 Noc_cfg_data_o,

    output logic                        core_sleep_en_o, //pulse to Noc

    //from l2 noc
    input                               l2c_datain_vld   ,
    input                               l2c_datain_last  ,
    output logic                        l2c_datain_rdy   ,
    input [256-1:0]                     l2c_datain_data  ,
    //to l2 noc
    output                              l2c_dataout_vld  ,
    output                              l2c_dataout_last ,
    input logic                         l2c_dataout_rdy  ,
    output [256-1:0]                    l2c_dataout_data      

);

    localparam   CUBANK_NUM      = 32;
    localparam   L1B_RAM_DBANK   = 16;
    localparam   L1B_RAM_DEPTH   = 256;
    localparam   L1B_RAM_ADDR_WID= $clog2(L1B_RAM_DEPTH)+$clog2(L1B_RAM_DBANK);  // 8+4
    localparam   L1B_NUM_WORDS   = L1B_RAM_DEPTH*4;
    localparam   MQ_CFIFO_DEPTH  = 8;
    localparam   VQ_CFIFO_DEPTH  = 8;
    localparam   SQ_CFIFO_DEPTH  = 4;
    localparam   ALU_CFIFO_DEPTH = 8;

    //to share cache
    logic [32-1:0][32-1:0]       CU_bank_data_out        ;
    logic [32-1:0]               CU_bank_data_out_vld    ;
    logic [32-1:0]               CU_bank_data_out_ready  ;
    logic [32-1:0]               CU_bank_data_out_last   ;
    //to SFU
    //temp define
    logic                        Sfu_req;
    logic                        Sfu_gnt;
    logic [5:0]                  Sfu_len;
    logic [3:0]                  Sfu_mode;

    //MU related
    logic                       npu_en;
    logic [31:0]                instr_npu;

    logic                       MQ_Cfifo_req,MQ_Cfifo_push,MQ_Cfifo_pop;
    logic                       VQ_Cfifo_req,VQ_Cfifo_push,VQ_Cfifo_pop;
    logic                       SQ_Cfifo_req,SQ_Cfifo_push,SQ_Cfifo_pop;
    logic                       ALU_Cfifo_req,ALU_Cfifo_push,ALU_Cfifo_pop;
    logic [31:0]                Cfifo_data_in;
    logic [31:0]                MQ_Cfifo_data_out,VQ_Cfifo_data_out,SQ_Cfifo_data_out;
    logic [15:0]                ALU_Cfifo_data_out;
    logic                       MQ_Cfifo_afull,MQ_Cfifo_full,MQ_Cfifo_empty;
    logic                       VQ_Cfifo_afull,VQ_Cfifo_full,VQ_Cfifo_empty;
    logic                       SQ_Cfifo_afull,SQ_Cfifo_full,SQ_Cfifo_empty;
    logic                       ALU_Cfifo_afull,ALU_Cfifo_full,ALU_Cfifo_empty;
    logic                       MQ_Cfifo_clear;
    logic                       VQ_Cfifo_clear;
    logic                       SQ_Cfifo_clear;
    logic                       ALU_Cfifo_clear;

    logic                       MQ_clear;
    logic                       VQ_clear;
    logic                       SQ_clear;

    logic                       is_VQ_insn;
    logic                       is_MQ_insn;
    logic                       is_SQ_insn;
    logic                       is_Cub_alu_insn;

    logic                       mu_VQ_ready;
    logic                       mu_MQ_ready;
    logic                       mu_SQ_ready;
    logic                       mu_Cub_alu_ready;
 
    logic                       MQ_Cfifo_err ;
    logic                       VQ_Cfifo_err ;
    logic                       SQ_Cfifo_err ;
    logic                       ALU_Cfifo_err;

    logic                       Slsu_data_req ;
    logic                       Slsu_data_gnt ;
    logic                       Slsu_data_ok  ;

    logic                       Hlsu_data_req ;
    logic                       Hlsu_data_gnt ;

    logic                       Hlsu_chk_done_req;
    logic                       Hlsu_chk_done_gnt;


	logic [31 : 0]                         sfu_data_out ;
	logic [31 : 0]                         sfu_data_in  ;
	logic [7 : 0]                         sfu_q_in  ;
	assign sfu_q_in = 8'b0;
    logic                                  sfu_data_valid;

    logic [CUBANK_NUM/2+3 : -4][31 : 0]                         cub_interconnect_reg0;
    logic [CUBANK_NUM/2+3 : -4][31 : 0]                         cub_interconnect_reg1;
    logic [CUBANK_NUM-1:0]                                      cub_interconnect_reg_valid;
    logic [CUBANK_NUM-1:0]                                      cub_interconnect_reg_ready;
    assign cub_interconnect_reg0[-1]                = 32'b0;
    assign cub_interconnect_reg0[-2]                = 32'b0;
    assign cub_interconnect_reg0[-3]                = 32'b0;
    assign cub_interconnect_reg0[-4]                = 32'b0;
    assign cub_interconnect_reg0[CUBANK_NUM/2]      = sfu_data_out; //sfu dataout to  cubank15 datain, 15+1
    assign cub_interconnect_reg0[CUBANK_NUM/2+1]    = 32'b0;
    assign cub_interconnect_reg0[CUBANK_NUM/2+2]    = 32'b0;
    assign cub_interconnect_reg0[CUBANK_NUM/2+3]    = 32'b0; 
    assign cub_interconnect_reg1[-1]                = 32'b0;
    assign cub_interconnect_reg1[-2]                = 32'b0;
    assign cub_interconnect_reg1[-3]                = 32'b0;
    assign cub_interconnect_reg1[-4]                = 32'b0;
    assign cub_interconnect_reg1[CUBANK_NUM/2]      = 32'b0;
    assign cub_interconnect_reg1[CUBANK_NUM/2+1]    = 32'b0;    
    assign cub_interconnect_reg1[CUBANK_NUM/2+2]    = 32'b0;
    assign cub_interconnect_reg1[CUBANK_NUM/2+3]    = 32'b0;

	assign sfu_data_in 	= cub_interconnect_reg0[0] ;//cubank0 dataout to sfu datain

    assign MQ_Cfifo_push = MQ_Cfifo_req & ~MQ_Cfifo_full;
    assign VQ_Cfifo_push = VQ_Cfifo_req & ~VQ_Cfifo_full;
    assign SQ_Cfifo_push = SQ_Cfifo_req & ~SQ_Cfifo_full;
    assign ALU_Cfifo_push = ALU_Cfifo_req & ~ALU_Cfifo_full;

    //--------------------------------------------------------
    //  Constant fifo (MQ/VQ/SQ) 
    //--------------------------------------------------------
    DW_fifo_s1_sf #(.width(32), .depth(MQ_CFIFO_DEPTH), .af_level(1), .err_mode(0), .rst_mode(0))
    U_MQ_Constant_fifo(
        .clk            (clk),   
        .rst_n          (rst_n),
        .push_req_n     (!MQ_Cfifo_push),
        .pop_req_n      (!MQ_Cfifo_pop),
        .diag_n         (!MQ_Cfifo_clear),
        .empty          (MQ_Cfifo_empty),
        .almost_empty   (),
        .half_full      (),
        .almost_full    (MQ_Cfifo_afull),
        .full           (MQ_Cfifo_full),
        .error          (MQ_Cfifo_err),
        .data_in        (Cfifo_data_in),
        .data_out       (MQ_Cfifo_data_out)
    );

    DW_fifo_s1_sf #(.width(32), .depth(VQ_CFIFO_DEPTH), .af_level(1), .err_mode(0), .rst_mode(0))
    U_VQ_Constant_fifo(
        .clk            (clk),
        .rst_n          (rst_n),
        .push_req_n     (!VQ_Cfifo_push),
        .pop_req_n      (!VQ_Cfifo_pop),
        .diag_n         (!VQ_Cfifo_clear),
        .empty          (VQ_Cfifo_empty),
        .almost_empty   (),
        .half_full      (),
        .almost_full    (VQ_Cfifo_afull),
        .full           (VQ_Cfifo_full),
        .error          (VQ_Cfifo_err),
        .data_in        (Cfifo_data_in),
        .data_out       (VQ_Cfifo_data_out)
    );

    DW_fifo_s1_sf #(.width(32), .depth(SQ_CFIFO_DEPTH), .af_level(1), .err_mode(0), .rst_mode(0))
    U_SQ_Constant_fifo(
        .clk            (clk),
        .rst_n          (rst_n),
        .push_req_n     (!SQ_Cfifo_push),
        .pop_req_n      (!SQ_Cfifo_pop),
        .diag_n         (!SQ_Cfifo_clear),
        .empty          (SQ_Cfifo_empty),
        .almost_empty   (),
        .half_full      (),
        .almost_full    (SQ_Cfifo_afull),
        .full           (SQ_Cfifo_full),
        .error          (SQ_Cfifo_err),
        .data_in        (Cfifo_data_in),
        .data_out       (SQ_Cfifo_data_out)
    );

    DW_fifo_s1_sf #(.width(16), .depth(ALU_CFIFO_DEPTH), .af_level(1), .err_mode(0), .rst_mode(0))
    U_ALU_Constant_fifo(
        .clk            (clk),
        .rst_n          (rst_n),
        .push_req_n     (!ALU_Cfifo_push),
        .pop_req_n      (!ALU_Cfifo_pop),
        .diag_n         (!ALU_Cfifo_clear),
        .empty          (ALU_Cfifo_empty),
        .almost_empty   (),
        .half_full      (),
        .almost_full    (ALU_Cfifo_afull),
        .full           (ALU_Cfifo_full),
        .error          (ALU_Cfifo_err),
        .data_in        (Cfifo_data_in[15:0]),
        .data_out       (ALU_Cfifo_data_out)
    );



    //--------------------------------------------------------
    //  riscv core
    //--------------------------------------------------------
    riscv_core #(
        .PULP_SECURE         (0),
        .PULP_CLUSTER        (1),
        .DW_HaltAddress      (32'h1A110800),
        .N_EXT_PERF_COUNTERS (1)
    )
    U_riscv_core(    
        .clk_i(clk),
        .rst_n(rst_n),

        .clock_en_i(clock_en_i), //enable clock, otherwise it is gated
        .test_en_i(test_en_i), //enable all clock gates for testing
        
        .boot_addr_i(boot_addr_i),
        .core_id_i(core_id_i),
        .cluster_id_i(cluster_id_i),
        
        .fetch_enable_i(fetch_enable_i),
        .core_busy_o(core_busy_o),
        .core_sleep_en_o(core_sleep_en_o),
        
        .riscv_instr_req_o(riscv_instr_req_o),
        .riscv_instr_gnt_i(riscv_instr_gnt_i),
        .riscv_instr_addr_o(riscv_instr_addr_o),
        .riscv_instr_rvalid_i(riscv_instr_rvalid_i),
        .riscv_instr_rdata_i(riscv_instr_rdata_i),
        
        .riscv_data_req_o(riscv_data_req_o),
        .riscv_data_gnt_i(riscv_data_gnt_i),
        .riscv_data_we_o(riscv_data_we_o),
        .riscv_data_be_o(riscv_data_be_o),
        .riscv_data_addr_o(riscv_data_addr_o),
        .riscv_data_wdata_o(riscv_data_wdata_o),
        .riscv_data_rvalid_i(riscv_data_rvalid_i),
        .riscv_data_rdata_i(riscv_data_rdata_i),
        
        .irq_i(irq_i), //level sensitive IR lines
        .irq_id_i(irq_id_i),
        .irq_ack_o(irq_ack_o),
        .irq_sec_i(irq_sec_i),
        .irq_id_o(irq_id_o),
        .sec_lvl_o(sec_lvl_o), //csr out
        
        .debug_req_i(debug_req_i), //to id
        
        .ext_perf_counters_i(ext_perf_counters_i),

        .npu_en_mu_o(npu_en),
        .instr_npu_mu_o(instr_npu),

        .MQ_Cfifo_req_o(MQ_Cfifo_req),
        .VQ_Cfifo_req_o(VQ_Cfifo_req),
        .SQ_Cfifo_req_o(SQ_Cfifo_req),
        .ALU_Cfifo_req_o(ALU_Cfifo_req),
        .Cfifo_data_in_o(Cfifo_data_in),
        .MQ_Cfifo_full_i(MQ_Cfifo_full),//MQ_Cfifo_afull
        .VQ_Cfifo_full_i(VQ_Cfifo_full),//VQ_Cfifo_afull
        .SQ_Cfifo_full_i(SQ_Cfifo_full),//SQ_Cfifo_afull
        .ALU_Cfifo_full_i(ALU_Cfifo_full),//ALU_Cfifo_afull

        .is_VQ_insn_mu_o(is_VQ_insn),
        .is_MQ_insn_mu_o(is_MQ_insn),
        .is_SQ_insn_mu_o(is_SQ_insn),
        .is_Cub_alu_insn_mu_o(is_Cub_alu_insn),

        .mu_VQ_ready_i(mu_VQ_ready),
        .mu_MQ_ready_i(mu_MQ_ready),
        .mu_SQ_ready_i(mu_SQ_ready),
        .mu_Cub_alu_ready_i(mu_Cub_alu_ready),

        .MQ_clear_o(MQ_clear),
        .VQ_clear_o(VQ_clear),
        .SQ_clear_o(SQ_clear),
        .MQ_Cfifo_clear_o(MQ_Cfifo_clear),
        .VQ_Cfifo_clear_o(VQ_Cfifo_clear),
        .SQ_Cfifo_clear_o(SQ_Cfifo_clear),       
        .ALU_Cfifo_clear_o(ALU_Cfifo_clear),

        .cub_interconnect_reg_i({cub_interconnect_reg1[CUBANK_NUM/2-1:0],cub_interconnect_reg0[CUBANK_NUM/2-1:0]})
    );


    logic [3:0]                     tcache_conv3d_bcfmap_valid;
    logic [3:0]                     tcache_conv3d_bcfmap_vector_data_mask;
    logic [128-1:0]                 tcache_conv3d_bcfmap_dataout_bank0  [1:0]; //to 16 cubank bank0 (right)
    logic [128-1:0]                 tcache_conv3d_bcfmap_dataout_bank1  [1:0]; //to 16 cubank bank1 (left )

    logic [CUBANK_NUM-1:0][128-1:0]                 cubank_weight;
    logic [CUBANK_NUM-1:0]                          cubank_weight_valid;
    logic [CUBANK_NUM-1:0][1:0]                     cubank_LB_mv_cub_dst_sel;
    logic [1:0]                                     cubank_LB_mv_cub_dst_sel_mu; //mu use

    logic [CUBANK_NUM-1:0]                          conv_req;
    logic [CUBANK_NUM-1:0][1:0]                     conv_mode; //00:norm conv 01:dw conv 10:rgba
    logic [CUBANK_NUM-1:0]                          conv_cfg_vld;
    logic [CUBANK_NUM-1:0][1:0]                     conv_cfg_addr;
    logic [CUBANK_NUM-1:0][22-1:0]                  conv_cfg_data;
  
    logic [CUBANK_NUM-1:0]                          dwconv_cross_ram_from_left; 
    logic [CUBANK_NUM-1:0]                          dwconv_cross_ram_from_right;    
    logic [CUBANK_NUM-1:0]                          dwconv_right_padding;
    logic [CUBANK_NUM-1:0]                          dwconv_left_padding;
    logic [CUBANK_NUM-1:0]                          dwconv_bottom_padding;
    logic [CUBANK_NUM-1:0]                          dwconv_top_padding;
    logic [CUBANK_NUM-1:0][3:0]                     dwconv_trans_num;

    logic [CUBANK_NUM-1:0][4:0]                     conv3d_psum_end_index;
    logic [CUBANK_NUM-1:0][4:0]                     conv3d_psum_start_index;
    logic [CUBANK_NUM-1:0]                          conv3d_first_subch_flag;
    logic [CUBANK_NUM-1:0]                          conv3d_result_output_flag;
    logic [CUBANK_NUM-1:0][1:0]                     conv3d_weight_16ch_sel;

    logic [CUBANK_NUM-1:0]                          Y_mode_pre_en;
    logic [CUBANK_NUM-1:0]                          Y_mode_cram_sel;

    logic [CUBANK_NUM-1:0]                          conv_psum_rd_req;
    logic [CUBANK_NUM-1:0]                          conv_psum_rd_cs;
    logic [CUBANK_NUM-1:0][4:0]                     conv_psum_rd_num;
    logic [CUBANK_NUM-1:0]                          conv_psum_rd_ch_sel;
    logic [CUBANK_NUM-1:0]                          conv_psum_rd_rgb_sel;
    logic [CUBANK_NUM-1:0][4:0]                     conv_psum_rd_offset;
    logic [CUBANK_NUM-1:0][31:0]                    cubank_weight_update_req;

    logic [CUBANK_NUM-1:0]                          VQ_scache_wr_en;
    logic [CUBANK_NUM-1:0][8:0]                     VQ_scache_wr_addr;
    logic [CUBANK_NUM-1:0][1:0]                     VQ_scache_wr_size;

    logic [CUBANK_NUM-1:0]                          VQ_scache_rd_en;
    logic [CUBANK_NUM-1:0][8:0]                     VQ_scache_rd_addr;
    logic [CUBANK_NUM-1:0][1:0]                     VQ_scache_rd_size;
    logic [CUBANK_NUM-1:0]                          VQ_scache_rd_sign_ext;

    logic [CUBANK_NUM-1:0]                          VQ_cub_csr_access;
    logic [CUBANK_NUM-1:0][5:0]                     VQ_cub_csr_addr;
    logic [CUBANK_NUM-1:0][15:0]                    VQ_cub_csr_wdata;

    logic                           conv3d_bcfmap_req;
    logic                           conv3d_bcfmap_gnt;
    logic                           conv3d_bcfmap_ok;

    logic                           conv3d_bcfmap_mode;  
    logic [5:0]                     conv3d_bcfmap_len;  
    logic                           conv3d_bcfmap_rgba_mode;   
    logic                           conv3d_bcfmap_rgba_stride;     
    logic [4:0]                     conv3d_bcfmap_rgba_shift;     
    logic                           conv3d_bcfmap_hl_op;
    logic                           conv3d_bcfmap_keep_2cycle_en;
    logic                           conv3d_bcfmap_group;
    logic                           conv3d_bcfmap_pad0_he_sel;
    logic [3:0]                     conv3d_bcfmap_pad0_len;
    logic                           conv3d_bcfmap_tcache_stride;
    logic [4:0]                     conv3d_bcfmap_tcache_offset;

    logic                           conv3d_bcfmap_elt_mode;
    logic                           conv3d_bcfmap_elt_pric;
    logic                           conv3d_bcfmap_elt_bsel;
    logic                           conv3d_bcfmap_elt_32ch_i16;

    logic                           Slsu_data_we;
    logic                           Slsu_l1b_mode; 
    logic                           Slsu_tcache_core_load_bank_num;
    logic [8:0]                     Slsu_data_sys_gap;
    logic [8:0]                     Slsu_data_sub_len;
    logic [12:0]                    Slsu_data_addr;
    logic [8:0]                     Slsu_data_sys_len;
    logic                           Slsu_data_mv_last_dis;

    logic                           Slsu_cfg_vld ;
    logic [1:0]                     Slsu_cfg_type;
    logic [2:0]                     Slsu_tcache_mode; 
    logic                           Slsu_l1b_gpu_mode; 
    logic [1:0]                     Slsu_l1b_op_wr_hl_mask;
    logic [1:0]                     Slsu_mv_cub_dst_sel;
    logic                           Slsu_tcache_trans_prici;
    logic                           Slsu_tcache_trans_swbank;
    logic                           Slsu_l1b_norm_paral_mode;
    logic [8:0]                     Slsu_cache_one_ram_qw_base_addr;
    logic [8:0]                     Slsu_data_sub_gap;
    logic [4:0]                     Slsu_data_sys_gap_ext;
    logic                           Slsu_iob_pric;//1: int16  0: int8
    logic                           Slsu_iob_l2c_in_cfg;
    logic                           Slsu_tcache_mvfmap_stride;
    logic [4:0]                     Slsu_tcache_mvfmap_offset;
    

    logic                           Hlsu_data_we;
    logic                           Hlsu_l1b_mode; 
    logic [8:0]                     Hlsu_data_sys_gap;
    logic [8:0]                     Hlsu_data_sub_len;
    logic [12:0]                    Hlsu_data_addr;
    logic [8:0]                     Hlsu_data_sys_len;

    logic [8:0]                     Hlsu_data_sub_gap;
    logic [4:0]                     Hlsu_data_sys_gap_ext;
    logic                           Hlsu_l1b_norm_paral_mode;

    logic [CUBANK_NUM-1:0][31:0]    Cub_alu_instr;
    logic [CUBANK_NUM-1:0]          Cub_alu_instr_valid;
    logic [CUBANK_NUM-1:0]          deassert_we;

    logic [CUBANK_NUM-1 : 0]        scache_cflow_data_rd_st_rdy;
    logic [CUBANK_NUM-1 : 0]        CU_bank_scache_dout_en;

    //--------------------------------------------------------
    //  MU
    //--------------------------------------------------------
    mu_top #(
        .BANK_NUM(CUBANK_NUM)
    )
    U_mu_top 
    (
    .clk                    (clk),
    .rst_n                  (rst_n),

    .npu_req_i              (npu_en),
    .instr_npu_i            (instr_npu),
    //.mu_ready_o(),

    .MQ_cons_fifo_pop_o     (MQ_Cfifo_pop),
    .MQ_cons_fifo_data_i    (MQ_Cfifo_data_out),
    .MQ_cons_fifo_empty_i   (MQ_Cfifo_empty),

    .VQ_cons_fifo_pop_o     (VQ_Cfifo_pop),
    .VQ_cons_fifo_data_i    (VQ_Cfifo_data_out),
    .VQ_cons_fifo_empty_i   (VQ_Cfifo_empty),
    
    .SQ_cons_fifo_pop_o     (SQ_Cfifo_pop),
    .SQ_cons_fifo_data_i    (SQ_Cfifo_data_out),
    .SQ_cons_fifo_empty_i   (SQ_Cfifo_empty),

    .is_MQ_insn_i           (is_MQ_insn),
    .MQ_ready_o             (mu_MQ_ready),
    .is_VQ_insn_i           (is_VQ_insn),
    .VQ_ready_o             (mu_VQ_ready),
    .is_SQ_insn_i           (is_SQ_insn),
    .SQ_ready_o             (mu_SQ_ready),
    .is_Cub_alu_insn_i      (is_Cub_alu_insn),
    .Cub_alu_ready_o        (mu_Cub_alu_ready),

    .MQ_clear_i             (MQ_clear),
    .VQ_clear_i             (VQ_clear),
    .SQ_clear_i             (SQ_clear),
    
    //to Slsu
    .Slsu_data_req_o                        (Slsu_data_req                      ),
    .Slsu_data_gnt_i                        (Slsu_data_gnt                      ),
    .Slsu_data_ok_i                         (Slsu_data_ok                       ), //system lsu excute done

    .Slsu_data_we_o                         (Slsu_data_we                       ),
    .Slsu_l1b_mode_o                        (Slsu_l1b_mode                      ), //1:norm 0:cache
    .Slsu_tcache_core_load_bank_num_o       (Slsu_tcache_core_load_bank_num     ),
    .Slsu_data_sys_gap_o                    (Slsu_data_sys_gap                  ),
    .Slsu_data_sub_len_o                    (Slsu_data_sub_len                  ),
    .Slsu_data_addr_o                       (Slsu_data_addr                     ),
    .Slsu_data_sys_len_o                    (Slsu_data_sys_len                  ),
    .Slsu_data_mv_last_dis_o                (Slsu_data_mv_last_dis              ),

    .Slsu_cfg_vld_o                         (Slsu_cfg_vld                       ),
    .Slsu_cfg_addr_o                        (Slsu_cfg_type                      ),
    .Slsu_l1b_gpu_mode_o                    (Slsu_l1b_gpu_mode                  ), //MQ CFG0
    .Slsu_l1b_op_wr_hl_mask_o               (Slsu_l1b_op_wr_hl_mask             ),
    .Slsu_mv_cub_dst_sel_o                  (Slsu_mv_cub_dst_sel                ),
    .Slsu_tcache_trans_prici_o              (Slsu_tcache_trans_prici            ),
    .Slsu_tcache_trans_swbank_o             (Slsu_tcache_trans_swbank           ),
    .Slsu_l1b_norm_paral_mode_o             (Slsu_l1b_norm_paral_mode           ),
    .Slsu_tcache_mode_o                     (Slsu_tcache_mode                   ), 
    .Slsu_cache_one_ram_qw_base_addr_o      (Slsu_cache_one_ram_qw_base_addr    ),
    .Slsu_data_sub_gap_o                    (Slsu_data_sub_gap                  ), //MQ CFG1
    .Slsu_data_sys_gap_ext_o                (Slsu_data_sys_gap_ext              ),
    .Slsu_iob_pric_o                        (Slsu_iob_pric                      ),
    .Slsu_iob_l2c_in_cfg_o                  (Slsu_iob_l2c_in_cfg                ),
    .Slsu_tcache_mvfmap_stride_o            (Slsu_tcache_mvfmap_stride          ),
    .Slsu_tcache_mvfmap_offset_o            (Slsu_tcache_mvfmap_offset          ),    
    .cubank_LB_mv_cub_dst_sel_i             (cubank_LB_mv_cub_dst_sel_mu        ),

    .Hlsu_data_req_o                        (Hlsu_data_req                      ),
    .Hlsu_data_gnt_i                        (Hlsu_data_gnt                      ),
    .Hlsu_data_we_o                         (Hlsu_data_we                       ),
    .Hlsu_l1b_mode_o                        (Hlsu_l1b_mode                      ),
    .Hlsu_data_sys_gap_o                    (Hlsu_data_sys_gap                  ),
    .Hlsu_data_sub_len_o                    (Hlsu_data_sub_len                  ),
    .Hlsu_data_addr_o                       (Hlsu_data_addr                     ),
    .Hlsu_data_sys_len_o                    (Hlsu_data_sys_len                  ),

    .Hlsu_data_sub_gap_o                    (Hlsu_data_sub_gap                  ), //MQ CFG2
    .Hlsu_data_sys_gap_ext_o                (Hlsu_data_sys_gap_ext              ),
    .Hlsu_l1b_norm_paral_mode_o             (Hlsu_l1b_norm_paral_mode           ),

    .Hlsu_chk_done_req_o                    (Hlsu_chk_done_req                  ),
    .Hlsu_chk_done_gnt_i                    (Hlsu_chk_done_gnt                  ),

    .conv3d_bcfmap_req_o            (conv3d_bcfmap_req),
    .conv3d_bcfmap_gnt_i            (conv3d_bcfmap_gnt),
    .conv3d_bcfmap_ok_i             (conv3d_bcfmap_ok),
    
    .conv3d_bcfmap_mode_o           (conv3d_bcfmap_mode), 
    .conv3d_bcfmap_len_o            (conv3d_bcfmap_len), 
    .conv3d_bcfmap_rgba_mode_o      (conv3d_bcfmap_rgba_mode), 
    .conv3d_bcfmap_rgba_stride_o    (conv3d_bcfmap_rgba_stride), 
    .conv3d_bcfmap_rgba_shift_o     (conv3d_bcfmap_rgba_shift), 
    .conv3d_bcfmap_hl_op_o          (conv3d_bcfmap_hl_op),
    .conv3d_bcfmap_keep_2cycle_en_o (conv3d_bcfmap_keep_2cycle_en),
    .conv3d_bcfmap_group_o          (conv3d_bcfmap_group),
    .conv3d_bcfmap_pad0_he_sel_o    (conv3d_bcfmap_pad0_he_sel),
    .conv3d_bcfmap_pad0_len_o       (conv3d_bcfmap_pad0_len),
    .conv3d_bcfmap_tcache_stride_o  (conv3d_bcfmap_tcache_stride),
    .conv3d_bcfmap_tcache_offset_o  (conv3d_bcfmap_tcache_offset),    

    .conv3d_bcfmap_elt_mode_o       (conv3d_bcfmap_elt_mode),
    .conv3d_bcfmap_elt_pric_o       (conv3d_bcfmap_elt_pric),
    .conv3d_bcfmap_elt_bsel_o       (conv3d_bcfmap_elt_bsel),
    .conv3d_bcfmap_elt_32ch_i16_o   (conv3d_bcfmap_elt_32ch_i16),

    //to cubank vector
    .conv_req_o                     (conv_req),
    .conv_gnt_i                     ({CUBANK_NUM{1'b1}}),
    .conv_done_i                    ({CUBANK_NUM{1'b0}}),
    .conv_mode_o                    (conv_mode), //00:norm conv 01:dw conv 10:rgba
    .conv_cfg_vld_o                 (conv_cfg_vld),
    .conv_cfg_addr_o                (conv_cfg_addr),
    .conv_cfg_data_o                (conv_cfg_data),
    
    .dwconv_cross_ram_from_left_o   (dwconv_cross_ram_from_left),
    .dwconv_cross_ram_from_right_o  (dwconv_cross_ram_from_right),
    .dwconv_right_padding_o         (dwconv_right_padding),
    .dwconv_left_padding_o          (dwconv_left_padding),
    .dwconv_bottom_padding_o        (dwconv_bottom_padding),
    .dwconv_top_padding_o           (dwconv_top_padding),
    .dwconv_trans_num_o             (dwconv_trans_num),
    
    .conv3d_psum_end_index_o        (conv3d_psum_end_index),
    .conv3d_psum_start_index_o      (conv3d_psum_start_index),
    .conv3d_first_subch_flag_o      (conv3d_first_subch_flag),
    .conv3d_result_output_flag_o    (conv3d_result_output_flag),
    .conv3d_weight_16ch_sel_o       (conv3d_weight_16ch_sel),

    .Y_mode_pre_en_o                (Y_mode_pre_en),
    .Y_mode_cram_sel_o              (Y_mode_cram_sel),

    .conv_psum_rd_req_o             (conv_psum_rd_req),
    .conv_psum_rd_num_o             (conv_psum_rd_num),    
    .conv_psum_rd_ch_sel_o          (conv_psum_rd_ch_sel),    
    .conv_psum_rd_rgb_sel_o         (conv_psum_rd_rgb_sel),
    .conv_psum_rd_offset_o          (conv_psum_rd_offset),

    //to cubank alu
    .VQ_scache_wr_en_o              (VQ_scache_wr_en),
    .VQ_scache_wr_addr_o            (VQ_scache_wr_addr),    
    .VQ_scache_wr_size_o            (VQ_scache_wr_size),  
    
    .VQ_scache_rd_en_o              (VQ_scache_rd_en),
    .VQ_scache_rd_addr_o            (VQ_scache_rd_addr),
    .VQ_scache_rd_size_o            (VQ_scache_rd_size),
    .VQ_scache_rd_sign_ext_o        (VQ_scache_rd_sign_ext),

    .VQ_cub_csr_access_o            (VQ_cub_csr_access),
    .VQ_cub_csr_addr_o              (VQ_cub_csr_addr),
    .VQ_cub_csr_wdata_o             (VQ_cub_csr_wdata),

    .Cub_alu_instr_o                (Cub_alu_instr),
    .Cub_alu_instr_valid_o          (Cub_alu_instr_valid),
    .deassert_we_o                  (deassert_we),

    .ALU_Cfifo_pop_o                (ALU_Cfifo_pop),
    .ALU_Cfifo_data_i               (ALU_Cfifo_data_out),
    .ALU_Cfifo_empty_i              (ALU_Cfifo_empty),

    //to Noc
    .Noc_cmd_req_o                  (Noc_cmd_req_o),
    .Noc_cmd_addr_o                 (Noc_cmd_addr_o),
    .Noc_cmd_gnt_i                  (Noc_cmd_gnt_i),
    .Noc_cmd_ok_i                   (Noc_cmd_ok_i),
    
    .Noc_cfg_vld_o                  (Noc_cfg_vld_o),
    .Noc_cfg_addr_o                 (Noc_cfg_addr_o),
    .Noc_cfg_data_o                 (Noc_cfg_data_o),

    .scache_cflow_data_rd_st_rdy_i  (scache_cflow_data_rd_st_rdy),
    .CU_bank_scache_dout_en_i       (CU_bank_scache_dout_en[0]),
    .CU_bank_data_out_ready_i       (CU_bank_data_out_ready[0]),

    //to SFU
    .Sfu_req_o                      (Sfu_req),
    .Sfu_gnt_i                      (Sfu_gnt),
    .Sfu_len_o                      (Sfu_len),
    .Sfu_mode_o                     (Sfu_mode)
    );

    
    logic [CUBANK_NUM-1 : 0]                                    lb_bank_data_req   ;
    logic [CUBANK_NUM-1 : 0]                                    lb_bank_data_we    ;
    logic [CUBANK_NUM-1 : 0][3 : 0]                             lb_bank_data_be    ;
    logic [CUBANK_NUM-1 : 0][31: 0]                             lb_bank_data_wdata ;
    logic [CUBANK_NUM-1 : 0][$clog2(L1B_NUM_WORDS)-1 : 0]       lb_bank_data_addr  ;
    logic [CUBANK_NUM-1 : 0]                                    lb_bank_data_gnt   ;
    logic [CUBANK_NUM-1 : 0]                                    lb_bank_data_rvalid;
    logic [CUBANK_NUM-1 : 0][31 : 0]                            lb_bank_data_rdata ;


    logic [CUBANK_NUM-1 : 0][31 : 0]                            Vec_core_cal_16ch_part_data;
    logic [CUBANK_NUM-1 : 0][31 : 0]                            scache_rd_16ch_part_data;


    //--------------------------------------------------------
    //  CU BANK
    //--------------------------------------------------------
    genvar j;
    generate
    for(j=0;j<8;j=j+1) begin: cu_bank_0_7
    wire [4:0] cub_id_i  = j;
    CU_bank_top U_CU_bank_top(
        .clk                        (clk),
        .rst_n                      (rst_n),
        
        //Broadcast 
        .BC_data_in                 (tcache_conv3d_bcfmap_dataout_bank0[0][127:0]),
        .BC_data_vld                (tcache_conv3d_bcfmap_valid[0]),
        .tcache_conv3d_bcfmap_vector_data_mask(tcache_conv3d_bcfmap_vector_data_mask[0]),
        
        //LB
        .LB_data_in                 (cubank_weight[j]),
        .LB_data_vld                (cubank_weight_valid[j]),
        .LB_mv_cub_dst_sel          (cubank_LB_mv_cub_dst_sel[j]),
        
        //share cache out
        .CU_bank_data_out           (CU_bank_data_out[j]),
        .CU_bank_data_out_vld       (CU_bank_data_out_vld[j]),
        .CU_bank_data_out_ready     (CU_bank_data_out_ready[j]),
        .CU_bank_data_out_last      (CU_bank_data_out_last[j]),

        .CU_bank_scache_dout_en     (CU_bank_scache_dout_en[j]),

        //MCU
        .dwconv_start               (conv_req[j]&(conv_mode[j]==2'b01)),
        .dw_cross_ram_from_left     (dwconv_cross_ram_from_left[j]), //向左借数
        .dw_cross_ram_from_right    (dwconv_cross_ram_from_right[j]), //向右借数
        .dw_trans_num               (dwconv_trans_num[j]), //dwconv一次填几行cram
        .dwconv_right_padding       (dwconv_right_padding[j]),
        .dwconv_left_padding        (dwconv_left_padding[j]),
        .dwconv_bottom_padding      (dwconv_bottom_padding[j]),
        .dwconv_top_padding         (dwconv_top_padding[j]),
       
        .conv3d_start               (conv_req[j]&(conv_mode[j]==2'b00)),
        .conv3d_psum_end_index      (conv3d_psum_end_index[j]),
        .conv3d_psum_start_index    (conv3d_psum_start_index[j]),   
        .conv3d_first_subch_flag    (conv3d_first_subch_flag[j]),
        .conv3d_result_output_flag  (conv3d_result_output_flag[j]),
        .conv3d_weight_16ch_sel     (conv3d_weight_16ch_sel[j]),
       
        .Y_mode_pre_en              (Y_mode_pre_en[j]),
        .Y_mode_cram_sel            (Y_mode_cram_sel[j]),

        .conv3d_psum_data_trans_start   (conv_psum_rd_req[j]),
        .conv3d_psum_rd_num             (conv_psum_rd_num[j]),
        .conv3d_psum_rd_ch_sel          (conv_psum_rd_ch_sel[j]),
        .conv3d_psum_rd_rgb_sel         (conv_psum_rd_rgb_sel[j]),
        .conv3d_psum_rd_offset          (conv_psum_rd_offset[j]),

        //.weight_wr_start        (cubank_weight_valid[j]), //same from LB_data_vld
        //.weight_wr_req          (), //?
        
        .vector_cfg_addr        (conv_cfg_addr[j]), //00:dw相关 01:Routing_code 10:other
        .vector_cfg_data        (conv_cfg_data[j]),
        .vector_cfg_vld         (conv_cfg_vld[j]),

        .cram_fill_done         (),
        .psum_full              (),

        .Vec_core_cal_16ch_part_data_i (Vec_core_cal_16ch_part_data[j+16]),
        .Vec_core_cal_16ch_part_data_o (Vec_core_cal_16ch_part_data[j]),
        .scache_rd_16ch_part_data_i    (scache_rd_16ch_part_data[j+16]),
        .scache_rd_16ch_part_data_o    (scache_rd_16ch_part_data[j]),        

        //cu_bank <-> lb access
        .lb_bank_data_req_o         (lb_bank_data_req[j]         ),
        .lb_bank_data_we_o          (lb_bank_data_we[j]          ),
        .lb_bank_data_be_o          (lb_bank_data_be[j]          ),
        .lb_bank_data_wdata_o       (lb_bank_data_wdata[j]       ),
        .lb_bank_data_addr_o        (lb_bank_data_addr[j]        ),
        .lb_bank_data_gnt_i         (lb_bank_data_gnt[j]         ),
        .lb_bank_data_rvalid_i      (lb_bank_data_rvalid[j]      ),
        .lb_bank_data_rdata_i       (lb_bank_data_rdata[j]       ),

        //to cubank alu
        .Cub_alu_instr_i          (Cub_alu_instr[j][31:0]),
        .Cub_alu_instr_valid_i    (Cub_alu_instr_valid[j]),
        .deassert_we_i            (deassert_we[j]),
        .cub_id_i                 (cub_id_i),

        .VQ_cub_csr_access_i      (VQ_cub_csr_access[j]),
        .VQ_cub_csr_addr_i        (VQ_cub_csr_addr[j]),
        .VQ_cub_csr_wdata_i       (VQ_cub_csr_wdata[j]),

        .VQ_scache_wr_en_i        (VQ_scache_wr_en[j]),
        .VQ_scache_wr_addr_i      (VQ_scache_wr_addr[j]),
        .VQ_scache_wr_size_i      (VQ_scache_wr_size[j]),

        .VQ_scache_rd_en_i        (VQ_scache_rd_en[j]),
        .VQ_scache_rd_addr_i      (VQ_scache_rd_addr[j]),
        .VQ_scache_rd_size_i      (VQ_scache_rd_size[j]),
        .VQ_scache_rd_sign_ext_i  (VQ_scache_rd_sign_ext[j]),

        //cubank interconnect reg
        .cub_interconnect_top_reg_0_i   (cub_interconnect_reg0[j-1]),
        .cub_interconnect_top_reg_1_i   (cub_interconnect_reg0[j-2]),
        .cub_interconnect_top_reg_2_i   (cub_interconnect_reg0[j-3]),
        .cub_interconnect_top_reg_3_i   (cub_interconnect_reg0[j-4]),
        .cub_interconnect_bottom_reg_0_i(cub_interconnect_reg0[j+1]),
        .cub_interconnect_bottom_reg_1_i(cub_interconnect_reg0[j+2]),
        .cub_interconnect_bottom_reg_2_i(cub_interconnect_reg0[j+1]),
        .cub_interconnect_bottom_reg_3_i(cub_interconnect_reg0[j+4]),
        .cub_interconnect_side_reg_i    (cub_interconnect_reg1[j]),
        .cub_interconnect_gap_reg_i     (cub_interconnect_reg0[j+8]),

        .cub_interconnect_reg_o         (cub_interconnect_reg0[j]),
        .cub_interconnect_reg_valid_i   (sfu_data_valid			 ),//(cub_interconnect_reg_valid[j]), 
        .cub_interconnect_reg_ready_o   (cub_interconnect_reg_ready[j]),

        .scache_cflow_data_rd_st_rdy_o(scache_cflow_data_rd_st_rdy[j])
    );
    end
    for(j=8;j<16;j=j+1) begin: cu_bank_8_15
    wire [4:0] cub_id_i  = j;
    CU_bank_top U_CU_bank_top(
        .clk                        (clk),
        .rst_n                      (rst_n),
        
        //Broadcast 
        .BC_data_in                 (tcache_conv3d_bcfmap_dataout_bank0[1][127:0]),
        .BC_data_vld                (tcache_conv3d_bcfmap_valid[1]),
        .tcache_conv3d_bcfmap_vector_data_mask(tcache_conv3d_bcfmap_vector_data_mask[1]),
        
        //LB
        .LB_data_in                 (cubank_weight[j]),
        .LB_data_vld                (cubank_weight_valid[j]),
        .LB_mv_cub_dst_sel          (cubank_LB_mv_cub_dst_sel[j]),
        
        //share cache out
        .CU_bank_data_out           (CU_bank_data_out[j]),
        .CU_bank_data_out_vld       (CU_bank_data_out_vld[j]),
        .CU_bank_data_out_ready     (CU_bank_data_out_ready[j]),
        .CU_bank_data_out_last      (CU_bank_data_out_last[j]),
       
        .CU_bank_scache_dout_en     (CU_bank_scache_dout_en[j]),

        //MCU
        .dwconv_start               (conv_req[j]&(conv_mode[j]==2'b01)),
        .dw_cross_ram_from_left     (dwconv_cross_ram_from_left[j]), //向左借数
        .dw_cross_ram_from_right    (dwconv_cross_ram_from_right[j]), //向右借数
        .dw_trans_num               (dwconv_trans_num[j]), //dwconv一次填几行cram
        .dwconv_right_padding       (dwconv_right_padding[j]),
        .dwconv_left_padding        (dwconv_left_padding[j]),
        .dwconv_bottom_padding      (dwconv_bottom_padding[j]),
        .dwconv_top_padding         (dwconv_top_padding[j]),
       
        .conv3d_start               (conv_req[j]&(conv_mode[j]==2'b00)),
        .conv3d_psum_end_index      (conv3d_psum_end_index[j]),
        .conv3d_psum_start_index    (conv3d_psum_start_index[j]),   
        .conv3d_first_subch_flag    (conv3d_first_subch_flag[j]),
        .conv3d_result_output_flag  (conv3d_result_output_flag[j]),
        .conv3d_weight_16ch_sel     (conv3d_weight_16ch_sel[j]),
        
        .Y_mode_pre_en              (Y_mode_pre_en[j]),
        .Y_mode_cram_sel            (Y_mode_cram_sel[j]),
        
        .conv3d_psum_data_trans_start   (conv_psum_rd_req[j]),
        .conv3d_psum_rd_num             (conv_psum_rd_num[j]),
        .conv3d_psum_rd_ch_sel          (conv_psum_rd_ch_sel[j]),
        .conv3d_psum_rd_rgb_sel         (conv_psum_rd_rgb_sel[j]),
        .conv3d_psum_rd_offset          (conv_psum_rd_offset[j]),

        //.weight_wr_start        (cubank_weight_valid[j]), //same from LB_data_vld
        //.weight_wr_req          (), //?
        
        .vector_cfg_addr        (conv_cfg_addr[j]), //00:dw相关 01:Routing_code 10:other
        .vector_cfg_data        (conv_cfg_data[j]),
        .vector_cfg_vld         (conv_cfg_vld[j]),

        .cram_fill_done         (),
        .psum_full              (),

        .Vec_core_cal_16ch_part_data_i (Vec_core_cal_16ch_part_data[j+16]),
        .Vec_core_cal_16ch_part_data_o (Vec_core_cal_16ch_part_data[j]),
        .scache_rd_16ch_part_data_i    (scache_rd_16ch_part_data[j+16]),
        .scache_rd_16ch_part_data_o    (scache_rd_16ch_part_data[j]),        

        //cu_bank <-> lb access
        .lb_bank_data_req_o         (lb_bank_data_req[j]         ),
        .lb_bank_data_we_o          (lb_bank_data_we[j]          ),
        .lb_bank_data_be_o          (lb_bank_data_be[j]          ),
        .lb_bank_data_wdata_o       (lb_bank_data_wdata[j]       ),
        .lb_bank_data_addr_o        (lb_bank_data_addr[j]        ),
        .lb_bank_data_gnt_i         (lb_bank_data_gnt[j]         ),
        .lb_bank_data_rvalid_i      (lb_bank_data_rvalid[j]      ),
        .lb_bank_data_rdata_i       (lb_bank_data_rdata[j]       ),

        //to cubank alu
        .Cub_alu_instr_i          (Cub_alu_instr[j][31:0]),
        .Cub_alu_instr_valid_i    (Cub_alu_instr_valid[j]),
        .deassert_we_i            (deassert_we[j]),
        .cub_id_i                 (cub_id_i),

        .VQ_cub_csr_access_i      (VQ_cub_csr_access[j]),
        .VQ_cub_csr_addr_i        (VQ_cub_csr_addr[j]),
        .VQ_cub_csr_wdata_i       (VQ_cub_csr_wdata[j]),

        .VQ_scache_wr_en_i        (VQ_scache_wr_en[j]),
        .VQ_scache_wr_addr_i      (VQ_scache_wr_addr[j]),
        .VQ_scache_wr_size_i      (VQ_scache_wr_size[j]),

        .VQ_scache_rd_en_i        (VQ_scache_rd_en[j]),
        .VQ_scache_rd_addr_i      (VQ_scache_rd_addr[j]),
        .VQ_scache_rd_size_i      (VQ_scache_rd_size[j]),
        .VQ_scache_rd_sign_ext_i  (VQ_scache_rd_sign_ext[j]),

        //cubank interconnect reg
        .cub_interconnect_top_reg_0_i   (cub_interconnect_reg0[j-1]),
        .cub_interconnect_top_reg_1_i   (cub_interconnect_reg0[j-2]),
        .cub_interconnect_top_reg_2_i   (cub_interconnect_reg0[j-3]),
        .cub_interconnect_top_reg_3_i   (cub_interconnect_reg0[j-4]),
        .cub_interconnect_bottom_reg_0_i(cub_interconnect_reg0[j+1]),
        .cub_interconnect_bottom_reg_1_i(cub_interconnect_reg0[j+2]),
        .cub_interconnect_bottom_reg_2_i(cub_interconnect_reg0[j+1]),
        .cub_interconnect_bottom_reg_3_i(cub_interconnect_reg0[j+4]),
        .cub_interconnect_side_reg_i    (cub_interconnect_reg1[j]),
        .cub_interconnect_gap_reg_i     (cub_interconnect_reg0[j-8]),

        .cub_interconnect_reg_o         (cub_interconnect_reg0[j]),
        .cub_interconnect_reg_valid_i   (sfu_data_valid          ),
        .cub_interconnect_reg_ready_o   (cub_interconnect_reg_ready[j]),

        .scache_cflow_data_rd_st_rdy_o(scache_cflow_data_rd_st_rdy[j])
    );
    end

    for(j=0;j<8;j=j+1) begin: cu_bank_16_23
    wire [4:0] cub_id_i  = j+16;
    CU_bank_top U_CU_bank_top(
        .clk                        (clk),
        .rst_n                      (rst_n),
        
        //Broadcast 
        .BC_data_in                 (tcache_conv3d_bcfmap_dataout_bank1[0][127:0]),
        .BC_data_vld                (tcache_conv3d_bcfmap_valid[2]),
        .tcache_conv3d_bcfmap_vector_data_mask(tcache_conv3d_bcfmap_vector_data_mask[2]),
        
        //LB
        .LB_data_in                 (cubank_weight[j+16]),
        .LB_data_vld                (cubank_weight_valid[j+16]),
        .LB_mv_cub_dst_sel          (cubank_LB_mv_cub_dst_sel[j+16]),
        
        //share cache out
        .CU_bank_data_out           (CU_bank_data_out[j+16]),
        .CU_bank_data_out_vld       (CU_bank_data_out_vld[j+16]),
        .CU_bank_data_out_ready     (CU_bank_data_out_ready[j+16]),
        .CU_bank_data_out_last      (CU_bank_data_out_last[j+16]),

        .CU_bank_scache_dout_en     (CU_bank_scache_dout_en[j+16]),

        //MCU
        .dwconv_start               (conv_req[j+16]&(conv_mode[j]==2'b01)),
        .dw_cross_ram_from_left     (dwconv_cross_ram_from_left[j+16]), //向左借数
        .dw_cross_ram_from_right    (dwconv_cross_ram_from_right[j+16]), //向右借数
        .dw_trans_num               (dwconv_trans_num[j+16]), //dwconv一次填几行cram
        .dwconv_right_padding       (dwconv_right_padding[j+16]),
        .dwconv_left_padding        (dwconv_left_padding[j+16]),
        .dwconv_bottom_padding      (dwconv_bottom_padding[j+16]),
        .dwconv_top_padding         (dwconv_top_padding[j+16]),
       
        .conv3d_start               (conv_req[j+16]&(conv_mode[j]==2'b00)),
        .conv3d_psum_end_index      (conv3d_psum_end_index[j+16]),
        .conv3d_psum_start_index    (conv3d_psum_start_index[j+16]),        
        .conv3d_first_subch_flag    (conv3d_first_subch_flag[j+16]),
        .conv3d_result_output_flag  (conv3d_result_output_flag[j+16]),
        .conv3d_weight_16ch_sel     (conv3d_weight_16ch_sel[j+16]),
        
        .Y_mode_pre_en              (Y_mode_pre_en[j+16]),
        .Y_mode_cram_sel            (Y_mode_cram_sel[j+16]),
        
        .conv3d_psum_data_trans_start   (conv_psum_rd_req[j+16]),
        .conv3d_psum_rd_num             (conv_psum_rd_num[j+16]),        
        .conv3d_psum_rd_ch_sel          (conv_psum_rd_ch_sel[j+16]),    
        .conv3d_psum_rd_rgb_sel         (conv_psum_rd_rgb_sel[j+16]),    
        .conv3d_psum_rd_offset          (conv_psum_rd_offset[j+16]),

        //.weight_wr_start        (cubank_weight_valid[j+16]), //same from LB_data_vld
        //.weight_wr_req          (),
        
        .vector_cfg_addr        (conv_cfg_addr[j+16]), //00:dw相关 01:Routing_code 10:other
        .vector_cfg_data        (conv_cfg_data[j+16]),
        .vector_cfg_vld         (conv_cfg_vld[j+16]),

        .cram_fill_done         (),
        .psum_full              (),

        .Vec_core_cal_16ch_part_data_i (Vec_core_cal_16ch_part_data[j]),
        .Vec_core_cal_16ch_part_data_o (Vec_core_cal_16ch_part_data[j+16]),
        .scache_rd_16ch_part_data_i    (scache_rd_16ch_part_data[j]),
        .scache_rd_16ch_part_data_o    (scache_rd_16ch_part_data[j+16]),

        //cu_bank <-> lb access
        .lb_bank_data_req_o         (lb_bank_data_req[j+16]         ),
        .lb_bank_data_we_o          (lb_bank_data_we[j+16]          ),
        .lb_bank_data_be_o          (lb_bank_data_be[j+16]          ),
        .lb_bank_data_wdata_o       (lb_bank_data_wdata[j+16]       ),
        .lb_bank_data_addr_o        (lb_bank_data_addr[j+16]        ),
        .lb_bank_data_gnt_i         (lb_bank_data_gnt[j+16]         ),
        .lb_bank_data_rvalid_i      (lb_bank_data_rvalid[j+16]      ),
        .lb_bank_data_rdata_i       (lb_bank_data_rdata[j+16]       ),

        //to cubank alu
        .Cub_alu_instr_i          (Cub_alu_instr[j+16][31:0]),
        .Cub_alu_instr_valid_i    (Cub_alu_instr_valid[j+16]),
        .deassert_we_i            (deassert_we[j+16]),
        .cub_id_i                 (cub_id_i),

        .VQ_cub_csr_access_i      (VQ_cub_csr_access[j+16]),
        .VQ_cub_csr_addr_i        (VQ_cub_csr_addr[j+16]),
        .VQ_cub_csr_wdata_i       (VQ_cub_csr_wdata[j+16]),

        .VQ_scache_wr_en_i        (VQ_scache_wr_en[j+16]),
        .VQ_scache_wr_addr_i      (VQ_scache_wr_addr[j+16]),
        .VQ_scache_wr_size_i      (VQ_scache_wr_size[j+16]),

        .VQ_scache_rd_en_i        (VQ_scache_rd_en[j+16]),
        .VQ_scache_rd_addr_i      (VQ_scache_rd_addr[j+16]),
        .VQ_scache_rd_size_i      (VQ_scache_rd_size[j+16]),
        .VQ_scache_rd_sign_ext_i  (VQ_scache_rd_sign_ext[j+16]),

        //cubank interconnect reg
        .cub_interconnect_top_reg_0_i   (cub_interconnect_reg1[j-1]),
        .cub_interconnect_top_reg_1_i   (cub_interconnect_reg1[j-2]),
        .cub_interconnect_top_reg_2_i   (cub_interconnect_reg1[j-3]),
        .cub_interconnect_top_reg_3_i   (cub_interconnect_reg1[j-4]),
        .cub_interconnect_bottom_reg_0_i(cub_interconnect_reg1[j+1]),
        .cub_interconnect_bottom_reg_1_i(cub_interconnect_reg1[j+2]),
        .cub_interconnect_bottom_reg_2_i(cub_interconnect_reg1[j+1]),
        .cub_interconnect_bottom_reg_3_i(cub_interconnect_reg1[j+4]),
        .cub_interconnect_side_reg_i    (cub_interconnect_reg0[j]),
        .cub_interconnect_gap_reg_i     (cub_interconnect_reg1[j+8]),
        
        .cub_interconnect_reg_o         (cub_interconnect_reg1[j]),
        .cub_interconnect_reg_valid_i   (sfu_data_valid          ),
        .cub_interconnect_reg_ready_o   (cub_interconnect_reg_ready[j+16]),

        .scache_cflow_data_rd_st_rdy_o(scache_cflow_data_rd_st_rdy[j+16])
    );
    end

    for(j=8;j<16;j=j+1) begin: cu_bank_24_31
    wire [4:0] cub_id_i = j+16;
    CU_bank_top U_CU_bank_top(
        .clk                        (clk),
        .rst_n                      (rst_n),
        
        //Broadcast 
        .BC_data_in                 (tcache_conv3d_bcfmap_dataout_bank1[1][127:0]),
        .BC_data_vld                (tcache_conv3d_bcfmap_valid[3]),
        .tcache_conv3d_bcfmap_vector_data_mask(tcache_conv3d_bcfmap_vector_data_mask[3]),
        
        //LB
        .LB_data_in                 (cubank_weight[j+16]),
        .LB_data_vld                (cubank_weight_valid[j+16]),
        .LB_mv_cub_dst_sel          (cubank_LB_mv_cub_dst_sel[j+16]),

        //share cache out
        .CU_bank_data_out           (CU_bank_data_out[j+16]),
        .CU_bank_data_out_vld       (CU_bank_data_out_vld[j+16]),
        .CU_bank_data_out_ready     (CU_bank_data_out_ready[j+16]),
        .CU_bank_data_out_last      (CU_bank_data_out_last[j+16]),

        .CU_bank_scache_dout_en     (CU_bank_scache_dout_en[j+16]),
 
        //MCU
        .dwconv_start               (conv_req[j+16]&(conv_mode[j]==2'b01)),
        .dw_cross_ram_from_left     (dwconv_cross_ram_from_left[j+16]), //向左借数
        .dw_cross_ram_from_right    (dwconv_cross_ram_from_right[j+16]), //向右借数
        .dw_trans_num               (dwconv_trans_num[j+16]), //dwconv一次填几行cram
        .dwconv_right_padding       (dwconv_right_padding[j+16]),
        .dwconv_left_padding        (dwconv_left_padding[j+16]),
        .dwconv_bottom_padding      (dwconv_bottom_padding[j+16]),
        .dwconv_top_padding         (dwconv_top_padding[j+16]),
       
        .conv3d_start               (conv_req[j+16]&(conv_mode[j]==2'b00)),
        .conv3d_psum_end_index      (conv3d_psum_end_index[j+16]),
        .conv3d_psum_start_index    (conv3d_psum_start_index[j+16]),        
        .conv3d_first_subch_flag    (conv3d_first_subch_flag[j+16]),
        .conv3d_result_output_flag  (conv3d_result_output_flag[j+16]),
        .conv3d_weight_16ch_sel     (conv3d_weight_16ch_sel[j+16]),
        
        .Y_mode_pre_en              (Y_mode_pre_en[j+16]),
        .Y_mode_cram_sel            (Y_mode_cram_sel[j+16]),
        
        .conv3d_psum_data_trans_start   (conv_psum_rd_req[j+16]),
        .conv3d_psum_rd_num             (conv_psum_rd_num[j+16]),        
        .conv3d_psum_rd_ch_sel          (conv_psum_rd_ch_sel[j+16]),    
        .conv3d_psum_rd_rgb_sel         (conv_psum_rd_rgb_sel[j+16]),
        .conv3d_psum_rd_offset          (conv_psum_rd_offset[j+16]),

        //.weight_wr_start        (cubank_weight_valid[j+16]), //same from LB_data_vld
        //.weight_wr_req          (),
        
        .vector_cfg_addr        (conv_cfg_addr[j+16]), //00:dw相关 01:Routing_code 10:other
        .vector_cfg_data        (conv_cfg_data[j+16]),
        .vector_cfg_vld         (conv_cfg_vld[j+16]),

        .cram_fill_done         (),
        .psum_full              (),

        .Vec_core_cal_16ch_part_data_i (Vec_core_cal_16ch_part_data[j]),
        .Vec_core_cal_16ch_part_data_o (Vec_core_cal_16ch_part_data[j+16]),
        .scache_rd_16ch_part_data_i    (scache_rd_16ch_part_data[j]),
        .scache_rd_16ch_part_data_o    (scache_rd_16ch_part_data[j+16]),

        //cu_bank <-> lb access
        .lb_bank_data_req_o         (lb_bank_data_req[j+16]         ),
        .lb_bank_data_we_o          (lb_bank_data_we[j+16]          ),
        .lb_bank_data_be_o          (lb_bank_data_be[j+16]          ),
        .lb_bank_data_wdata_o       (lb_bank_data_wdata[j+16]       ),
        .lb_bank_data_addr_o        (lb_bank_data_addr[j+16]        ),
        .lb_bank_data_gnt_i         (lb_bank_data_gnt[j+16]         ),
        .lb_bank_data_rvalid_i      (lb_bank_data_rvalid[j+16]      ),
        .lb_bank_data_rdata_i       (lb_bank_data_rdata[j+16]       ),

        //to cubank alu
        .Cub_alu_instr_i          (Cub_alu_instr[j+16][31:0]),
        .Cub_alu_instr_valid_i    (Cub_alu_instr_valid[j+16]),
        .deassert_we_i            (deassert_we[j+16]),
        .cub_id_i                 (cub_id_i),

        .VQ_cub_csr_access_i      (VQ_cub_csr_access[j+16]),
        .VQ_cub_csr_addr_i        (VQ_cub_csr_addr[j+16]),
        .VQ_cub_csr_wdata_i       (VQ_cub_csr_wdata[j+16]),

        .VQ_scache_wr_en_i        (VQ_scache_wr_en[j+16]),
        .VQ_scache_wr_addr_i      (VQ_scache_wr_addr[j+16]),
        .VQ_scache_wr_size_i      (VQ_scache_wr_size[j+16]),

        .VQ_scache_rd_en_i        (VQ_scache_rd_en[j+16]),
        .VQ_scache_rd_addr_i      (VQ_scache_rd_addr[j+16]),
        .VQ_scache_rd_size_i      (VQ_scache_rd_size[j+16]),
        .VQ_scache_rd_sign_ext_i  (VQ_scache_rd_sign_ext[j+16]),

        //cubank interconnect reg
        .cub_interconnect_top_reg_0_i   (cub_interconnect_reg1[j-1]),
        .cub_interconnect_top_reg_1_i   (cub_interconnect_reg1[j-2]),
        .cub_interconnect_top_reg_2_i   (cub_interconnect_reg1[j-3]),
        .cub_interconnect_top_reg_3_i   (cub_interconnect_reg1[j-4]),
        .cub_interconnect_bottom_reg_0_i(cub_interconnect_reg1[j+1]),
        .cub_interconnect_bottom_reg_1_i(cub_interconnect_reg1[j+2]),
        .cub_interconnect_bottom_reg_2_i(cub_interconnect_reg1[j+1]),
        .cub_interconnect_bottom_reg_3_i(cub_interconnect_reg1[j+4]),
        .cub_interconnect_side_reg_i    (cub_interconnect_reg0[j]),
        .cub_interconnect_gap_reg_i     (cub_interconnect_reg1[j-8]),
        
        .cub_interconnect_reg_o         (cub_interconnect_reg1[j]),
        .cub_interconnect_reg_valid_i   (sfu_data_valid         ),
        .cub_interconnect_reg_ready_o   (cub_interconnect_reg_ready[j+16]),

        .scache_cflow_data_rd_st_rdy_o(scache_cflow_data_rd_st_rdy[j+16])
    );
    end    
    endgenerate



    //--------------------------------------------------------
    //  L1B sys
    //--------------------------------------------------------

    l1b_sys U_l1b_sys(
        .clk(clk),
        .rst_n(rst_n),
        //system lsu
        .slsu_data_req                      (Slsu_data_req                                              ),
        .slsu_data_gnt                      (Slsu_data_gnt                                              ),
        .slsu_data_ok                       (Slsu_data_ok                                               ),

        .slsu_data_we                       (Slsu_data_we                                               ),
        .slsu_l1b_mode                      (Slsu_l1b_mode                                              ),  
        .slsu_tcache_core_load_bank_num     (Slsu_tcache_core_load_bank_num                             ),
        .slsu_data_addr                     (Slsu_data_addr[L1B_RAM_ADDR_WID-1 : 0]                     ),
        .slsu_data_sys_len                  (Slsu_data_sys_len[$clog2(L1B_RAM_DEPTH)-1: 0]              ),
        .slsu_data_sub_len                  (Slsu_data_sub_len[$clog2(L1B_RAM_DEPTH)-1: 0]              ),
        .slsu_data_sys_gap                  (Slsu_data_sys_gap[$clog2(L1B_RAM_DEPTH)-1: 0]              ),
        .slsu_data_mv_last_dis              (Slsu_data_mv_last_dis                                      ),

        .slsu_cfg_vld                       (Slsu_cfg_vld                                               ),
        .slsu_cfg_type                      (Slsu_cfg_type                                              ),
        .slsu_tcache_mode                   (Slsu_tcache_mode                                           ), 
        .slsu_l1b_gpu_mode                  (Slsu_l1b_gpu_mode                                          ),
        .slsu_l1b_norm_paral_mode           (Slsu_l1b_norm_paral_mode                                   ),
        .slsu_l1b_op_wr_hl_mask             (Slsu_l1b_op_wr_hl_mask                                     ),
        .slsu_mv_cub_dst_sel                (Slsu_mv_cub_dst_sel                                        ),
        .slsu_tcache_trans_prici            (Slsu_tcache_trans_prici                                    ),
        .slsu_tcache_trans_swbank           (Slsu_tcache_trans_swbank                                   ),
        .slsu_cache_one_ram_qw_base_addr    (Slsu_cache_one_ram_qw_base_addr[$clog2(L1B_RAM_DEPTH)-1:0] ),
        .slsu_data_sub_gap                  (Slsu_data_sub_gap[$clog2(L1B_RAM_DEPTH)-1:0]               ),
        .slsu_data_sys_gap_ext              (Slsu_data_sys_gap_ext[$clog2(L1B_RAM_DBANK):0]             ),
        .slsu_iob_pric                      (Slsu_iob_pric                                              ),
        .slsu_iob_l2c_in_cfg                (Slsu_iob_l2c_in_cfg                                        ),
        .slsu_tcache_mvfmap_stride          (Slsu_tcache_mvfmap_stride                                  ),
        .slsu_tcache_mvfmap_offset          (Slsu_tcache_mvfmap_offset                                  ),
        .slsu_state_clr                     (1'b0                                                       ),
        .cubank_lb_mv_cub_dst_sel           (cubank_LB_mv_cub_dst_sel_mu                                ),
        
        //Hide load
        .hlsu_data_req                      (Hlsu_data_req),
        .hlsu_data_gnt                      (Hlsu_data_gnt),
        .hlsu_data_ok                       (),
        .hlsu_data_we                       (Hlsu_data_we),
        .hlsu_l1b_mode                      (Hlsu_l1b_mode),
        .hlsu_data_sys_gap                  (Hlsu_data_sys_gap[$clog2(L1B_RAM_DEPTH)-1: 0]              ),
        .hlsu_data_sub_len                  (Hlsu_data_sub_len[$clog2(L1B_RAM_DEPTH)-1: 0]              ),
        .hlsu_data_addr                     (Hlsu_data_addr[L1B_RAM_ADDR_WID-1 : 0]                     ),
        .hlsu_data_sys_len                  (Hlsu_data_sys_len[$clog2(L1B_RAM_DEPTH)-1: 0]              ),

        .hlsu_chk_done_req                  (Hlsu_chk_done_req                                          ),
        .hlsu_chk_done_gnt                  (Hlsu_chk_done_gnt                                          ),

        .hlsu_cfg_vld                       (Slsu_cfg_vld                                               ),
        .hlsu_cfg_type                      (Slsu_cfg_type                                              ),
        .hlsu_data_sub_gap                  (Hlsu_data_sub_gap[$clog2(L1B_RAM_DEPTH)-1:0]               ),
        .hlsu_data_sys_gap_ext              (Hlsu_data_sys_gap_ext[$clog2(L1B_RAM_DBANK):0]             ),
        .hlsu_l1b_norm_paral_mode           (Hlsu_l1b_norm_paral_mode                                   ),

        //fmap broadcast
        .conv3d_bcfmap_req                  (conv3d_bcfmap_req                                          ),
        .conv3d_bcfmap_gnt                  (conv3d_bcfmap_gnt                                          ),
        .conv3d_bcfmap_ok                   (conv3d_bcfmap_ok                                           ),
        .conv3d_bcfmap_mode                 (conv3d_bcfmap_mode                                         ),
        .conv3d_bcfmap_len                  (conv3d_bcfmap_len                                          ),
        .conv3d_bcfmap_rgba_mode            (conv3d_bcfmap_rgba_mode                                    ),
        .conv3d_bcfmap_rgba_stride          (conv3d_bcfmap_rgba_stride                                  ),
        .conv3d_bcfmap_rgba_shift           (conv3d_bcfmap_rgba_shift                                   ),
        .conv3d_bcfmap_hl_op                (conv3d_bcfmap_hl_op                                        ),
        .conv3d_bcfmap_keep_2cycle_en       (conv3d_bcfmap_keep_2cycle_en                               ),
        .conv3d_bcfmap_group                (conv3d_bcfmap_group                                        ),
        .conv3d_bcfmap_pad0_he_sel          (conv3d_bcfmap_pad0_he_sel                                  ),
        .conv3d_bcfmap_pad0_len             (conv3d_bcfmap_pad0_len                                     ),
        .conv3d_bcfmap_tcache_stride        (conv3d_bcfmap_tcache_stride                                ),
        .conv3d_bcfmap_tcache_offset        (conv3d_bcfmap_tcache_offset                                ),

        .conv3d_bcfmap_elt_mode             (conv3d_bcfmap_elt_mode                                     ),
        .conv3d_bcfmap_elt_pric             (conv3d_bcfmap_elt_pric                                     ),
        .conv3d_bcfmap_elt_bsel             (conv3d_bcfmap_elt_bsel                                     ),
        .conv3d_bcfmap_elt_32ch_i16         (conv3d_bcfmap_elt_32ch_i16                                 ),

        //fmap broadcast inf
        .tcache_conv3d_bcfmap_valid         (tcache_conv3d_bcfmap_valid                                 ),
        .tcache_conv3d_bcfmap_vector_data_mask(tcache_conv3d_bcfmap_vector_data_mask                    ),
        .tcache_conv3d_bcfmap_dataout_bank0 (tcache_conv3d_bcfmap_dataout_bank0                         ),
        .tcache_conv3d_bcfmap_dataout_bank1 (tcache_conv3d_bcfmap_dataout_bank1                         ),
        //weight to cubank inf
        .cubank_weight                      (cubank_weight                                              ),
        .cubank_weight_valid                (cubank_weight_valid                                        ),
        .cubank_weight_mv_cub_dst_sel       (cubank_LB_mv_cub_dst_sel                                   ),
        //from l2 noc
        .l2c_datain_vld                     (l2c_datain_vld                                             ),
        .l2c_datain_last                    (l2c_datain_last                                            ),
        .l2c_datain_rdy                     (l2c_datain_rdy                                             ),
        .l2c_datain_data                    (l2c_datain_data                                            ),
        //to l2 noc
        .l2c_dataout_vld                    (l2c_dataout_vld                                            ),
        .l2c_dataout_last                   (l2c_dataout_last                                           ),
        .l2c_dataout_rdy                    (l2c_dataout_rdy                                            ),
        .l2c_dataout_data                   (l2c_dataout_data                                           ),
        //from scache
        .CU_bank_data_out                   (CU_bank_data_out                                           ),
        .CU_bank_data_out_vld               (CU_bank_data_out_vld                                       ),
        .CU_bank_data_out_ready             (CU_bank_data_out_ready                                     ),
        .CU_bank_data_out_last              (CU_bank_data_out_last                                      ),
        //cubank lsu inf
        .cubank_data_req                    (lb_bank_data_req                                           ),
        .cubank_data_we                     (lb_bank_data_we                                            ),
        .cubank_data_be                     (lb_bank_data_be                                            ),
        .cubank_data_wdata                  (lb_bank_data_wdata                                         ),
        .cubank_data_addr                   (lb_bank_data_addr                                          ),
        .cubank_data_gnt                    (lb_bank_data_gnt                                           ),
        .cubank_data_rvalid                 (lb_bank_data_rvalid                                        ),
        .cubank_data_rdata                  (lb_bank_data_rdata                                         )
    );

    //--------------------------------------------------------
    //  sfu
    //--------------------------------------------------------

	sfu u_sfu(
		.clk(clk),
		.rst_n(rst_n),
		.Q_in(sfu_q_in),
		.data_in(sfu_data_in),	
		//.valid_in(sfu_data_valid),
		//.ready_out(),
		.data_out(sfu_data_out),	
		.valid_out(sfu_data_valid),
		//.ready_in(1'b1),
		.sfu_req(Sfu_req),	
		.sfu_cfg_len(Sfu_len),
		.sfu_cfg_mode(Sfu_mode),
		.sfu_calc_ok(Sfu_gnt)
		//instr_data_in_a,
		//instr_data_in_b,
		//instr_valid_in,
		//instr_data_out,
		//instr_valid_out
	);

endmodule
