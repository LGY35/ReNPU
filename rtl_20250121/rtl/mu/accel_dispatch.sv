module accel_dispatch #(
    parameter   IRAM_AWID = 8
)
(
    input                                   clk,
    input                                   rst_n,

    input                                   MQ_disp_req_i, //MQ instr can disp and fifo data valid if need imm
    input [31:7]                            MQ_disp_instr_i,
    output logic                            MQ_disp_ready_o, //to accel_sequence
    input                                   MQ_cfifo_en_i,
    input [31:0]                            MQ_cfifo_data_i,

    input [3:0]                             VQ_disp_req_i,
    input [3:0][31:7]                       VQ_disp_instr_i,
    output logic                            VQ_disp_ready_o,
    input [3:0]                             VQ_cfifo_en_i,
    input [3:0][31:0]                       VQ_cfifo_data_i,

    input                                   SQ_disp_req_i,
    input [31:7]                            SQ_disp_instr_i,
    output logic                            SQ_disp_ready_o,
    input                                   SQ_cfifo_en_i,
    input [31:0]                            SQ_cfifo_data_i,

    input [2:0]                             MQ_disp_func_i,
    input [3:0][1:0]                        VQ_disp_func_i,
    input                                   SQ_disp_func_i,

    //to Sys LSU
    output logic                            Slsu_data_req_o,
    input                                   Slsu_data_gnt_i,
    input                                   Slsu_data_ok_i, //system lsu excute done

    output logic                            Slsu_data_we_o,
    output logic                            Slsu_l1b_mode_o, //1:norm 0:cache
    output logic                            Slsu_tcache_core_load_bank_num_o,
    output logic [8:0]                      Slsu_data_sys_gap_o,
    output logic [8:0]                      Slsu_data_sub_len_o,
    output logic [12:0]                     Slsu_data_addr_o,
    output logic [8:0]                      Slsu_data_sys_len_o,
    output logic                            Slsu_data_mv_last_dis_o,

    output logic                            Slsu_cfg_vld_o,
    output logic [1:0]                      Slsu_cfg_addr_o,
    output logic                            Slsu_l1b_gpu_mode_o, //MQ CFG0
    output logic [1:0]                      Slsu_l1b_op_wr_hl_mask_o,
    output logic [1:0]                      Slsu_mv_cub_dst_sel_o,
    output logic                            Slsu_tcache_trans_prici_o, //0:int8 1:int16
    output logic                            Slsu_tcache_trans_swbank_o,
    output logic                            Slsu_l1b_norm_paral_mode_o,
    output logic [2:0]                      Slsu_tcache_mode_o, //00:DFIFO_MODE 01:SFIFO_MODE 10:TRANS_MODE 11:DWCONV_MODE
    output logic [8:0]                      Slsu_cache_one_ram_qw_base_addr_o,
    output logic [8:0]                      Slsu_data_sub_gap_o,
    output logic [4:0]                      Slsu_data_sys_gap_ext_o,
    output logic                            Slsu_iob_pric_o,
    output logic                            Slsu_iob_l2c_in_cfg_o,
    output logic                            Slsu_tcache_mvfmap_stride_o,
    output logic [4:0]                      Slsu_tcache_mvfmap_offset_o,
    input  [1:0]                            cubank_LB_mv_cub_dst_sel_i,

    //Hide load
    output logic                            Hlsu_data_req_o,
    input                                   Hlsu_data_gnt_i,
    
    output logic                            Hlsu_data_we_o,
    output logic                            Hlsu_l1b_mode_o,
    output logic [8:0]                      Hlsu_data_sys_gap_o,
    output logic [8:0]                      Hlsu_data_sub_len_o,
    output logic [12:0]                     Hlsu_data_addr_o,
    output logic [8:0]                      Hlsu_data_sys_len_o,

    output logic [8:0]                      Hlsu_data_sub_gap_o, //MQ CFG2
    output logic [4:0]                      Hlsu_data_sys_gap_ext_o,
    output logic                            Hlsu_l1b_norm_paral_mode_o,

    output logic                            Hlsu_chk_done_req_o,
    input                                   Hlsu_chk_done_gnt_i,

    //to CU bank
    output logic [3:0]                      conv_req_o,
    input        [3:0]                      conv_gnt_i,
    input        [3:0]                      conv_done_i,
    output logic [3:0][1:0]                 conv_mode_o, //00:norm conv 01:dw conv 10:rgba
    output logic [3:0]                      conv_cfg_vld_o,
    output logic [3:0][1:0]                 conv_cfg_addr_o,
    output logic [3:0][22-1:0]              conv_cfg_data_o,
    
    output logic [3:0]                      dwconv_cross_ram_from_left_o, 
    output logic [3:0]                      dwconv_cross_ram_from_right_o,    
    output logic [3:0]                      dwconv_right_padding_o,
    output logic [3:0]                      dwconv_left_padding_o,
    output logic [3:0]                      dwconv_bottom_padding_o,
    output logic [3:0]                      dwconv_top_padding_o,
    output logic [3:0][3:0]                 dwconv_trans_num_o,

    output logic [3:0][4:0]                 conv3d_psum_end_index_o,
    output logic [3:0][4:0]                 conv3d_psum_start_index_o,
    output logic [3:0]                      conv3d_first_subch_flag_o,
    output logic [3:0]                      conv3d_result_output_flag_o,
    output logic [3:0][1:0]                 conv3d_weight_16ch_sel_o,

    output logic                            conv3d_bcfmap_req_o,
    input                                   conv3d_bcfmap_gnt_i,
    input                                   conv3d_bcfmap_ok_i,

    output logic                            conv3d_bcfmap_mode_o, //1:double bank diff fmap 0:single bank same fmap 
    output logic [5:0]                      conv3d_bcfmap_len_o, //32ch data len <= 8 
    output logic                            conv3d_bcfmap_rgba_mode_o, //even start 16ch mask  
    output logic                            conv3d_bcfmap_rgba_stride_o, //odd last 16ch mask    
    output logic [4:0]                      conv3d_bcfmap_rgba_shift_o,     
    output logic                            conv3d_bcfmap_hl_op_o, //1:high 16ch 0:low 16ch
    output logic                            conv3d_bcfmap_keep_2cycle_en_o, //1:high 16ch 0:low 16ch
    output logic                            conv3d_bcfmap_group_o,
    output logic                            conv3d_bcfmap_pad0_he_sel_o,
    output logic [3:0]                      conv3d_bcfmap_pad0_len_o,
    output logic                            conv3d_bcfmap_tcache_stride_o,
    output logic [4:0]                      conv3d_bcfmap_tcache_offset_o,
    output logic                            conv3d_bcfmap_elt_32ch_i16_o,

    output logic                            conv3d_bcfmap_elt_mode_o,
    output logic                            conv3d_bcfmap_elt_pric_o,
    output logic                            conv3d_bcfmap_elt_bsel_o,

    output logic [3:0]                      Y_mode_pre_en_o,
    output logic [3:0]                      Y_mode_cram_sel_o,

    output logic [3:0]                      conv_psum_rd_req_o,
    output logic [3:0][4:0]                 conv_psum_rd_num_o,
    output logic [3:0]                      conv_psum_rd_ch_sel_o,
    output logic [3:0]                      conv_psum_rd_rgb_sel_o,
    output logic [3:0][4:0]                 conv_psum_rd_offset_o,

    output logic [3:0]                      VQ_scache_wr_en_o,
    output logic [3:0][8:0]                 VQ_scache_wr_addr_o,
    output logic [3:0][1:0]                 VQ_scache_wr_size_o, //00: byte 01: half word 10: word
    
    output logic [3:0]                      VQ_scache_rd_en_o,
    output logic [3:0][8:0]                 VQ_scache_rd_addr_o,
    output logic [3:0][1:0]                 VQ_scache_rd_size_o,
    output logic [3:0]                      VQ_scache_rd_sign_ext_o,

    output logic                            VQ_alu_event_call_o,
    output logic [IRAM_AWID-1:0]            VQ_alu_event_addr_o,
    input        [3:0]                      VQ_alu_event_finish_i,

    output logic [3:0]                      VQ_cub_csr_access_o,
    output logic [3:0][5:0]                 VQ_cub_csr_addr_o,
    output logic [3:0][15:0]                VQ_cub_csr_wdata_o,
    
    //input                                   cubank_weight_update_gnt_i,

    //to NOC
    output logic                            Noc_cmd_req_o,
    output logic [2:0]                      Noc_cmd_addr_o,
    input                                   Noc_cmd_gnt_i,
    input                                   Noc_cmd_ok_i,
    
    output logic                            Noc_cfg_vld_o,
    output logic [6:0]                      Noc_cfg_addr_o,
    output logic [12:0]                     Noc_cfg_data_o,

    input                                   scache_cflow_data_rd_st_rdy_i,
    input                                   CU_bank_scache_dout_en_i,
    input                                   CU_bank_data_out_ready_i,

    //to SFU
    output logic                            Sfu_req_o,
    input                                   Sfu_gnt_i,
    output logic [5:0]                      Sfu_len_o,
    output logic [3:0]                      Sfu_mode_o    
);

    localparam  SLSU_REQ        = 2'b00;
    localparam  HLSU_REQ        = 2'b01;
    localparam  NOC_REQ         = 2'b10;
    localparam  HLSU_CHK_REQ    = 2'b11;

    logic                           MQ_cfg_en, MQ_noc_cfg_en; //Cfg type
    logic [1:0]                     MQ_cfg_addr;
    logic [1:0]                     MQ_req_type;
    logic                           illegal_instr;
    logic                           MQ_busy;
    logic                           MQ_nop_en;
    logic                           MQ_nop_done;
    logic                           MQ_nop_multi_cycle;
    logic [4:0]                     MQ_nop_cycle_num,MQ_nop_cycle_cnt;    

    logic [3:0]                     VQ_cfg_en; //Cfg type
    logic [3:0][7:0]                conv3d_run_cycle_num,conv3d_run_cycle_cnt;
    logic [3:0][6:0]                dwconv_run_cycle_num,dwconv_run_cycle_cnt;
    logic [3:0][5:0]                conv_psum_rd_run_cycle_num,conv3d_psum_rd_cycle_cnt;
    logic [3:0]                     conv3d_done,dwconv_done,conv3d_psum_rd_done,Y_mode_pre_done;
    logic [3:0][9:0]                VQ_scache_wr_run_cycle_num,VQ_scache_rd_run_cycle_num;
    logic [3:0]                     VQ_scache_wr_run_wait_type,VQ_scache_rd_run_wait_type;
    logic [3:0][9:0]                scache_wr_rd_cycle_cnt;
    logic [3:0]                     scache_wr_rd_done;

    logic [3:0]                     VQ_scache_wr_rd_type;
    logic [3:0]                     VQ_scache_we;

    logic [3:0]                     conv3d_psum_rd_en;
    logic [3:0]                     VQ_scache_wr_en,VQ_scache_rd_en;
    logic [3:0]                     conv3d_bcfmap_en;
    logic [3:0]                     conv3d_bcfmap_elt_en;
    logic [3:0]                     conv_cfg_en;
    logic [3:0]                     VQ_alu_event_call,VQ_alu_event_call_w;
    logic [3:0][IRAM_AWID-1:0]      VQ_alu_event_addr;
    logic [3:0]                     VQ_cub_csr_access;
    logic [3:0]                     VQ_nop_en;
    logic [3:0]                     VQ_nop_done;
    logic [3:0]                     VQ_nop_multi_cycle;
    logic [3:0][4:0]                VQ_nop_cycle_num,VQ_nop_cycle_cnt;
    logic [3:0][4:0]                Y_mode_pre_cycle_cnt,Y_mode_pre_run_cycle_num;

    logic [3:0]                     conv3d_bcfmap_req;
    logic [3:0]                     conv3d_bcfmap_mode;
    logic [3:0][5:0]                conv3d_bcfmap_len;
    logic [3:0]                     conv3d_bcfmap_rgba_mode;
    logic [3:0]                     conv3d_bcfmap_rgba_stride;
    logic [3:0][4:0]                conv3d_bcfmap_rgba_shift;
    logic [3:0]                     conv3d_bcfmap_hl_op;
    logic [3:0]                     conv3d_bcfmap_keep_2cycle_en;
    logic [3:0]                     conv3d_bcfmap_group;
    logic [3:0]                     conv3d_bcfmap_pad0_he_sel;
    logic [3:0][3:0]                conv3d_bcfmap_pad0_len;
    logic [3:0]                     conv3d_bcfmap_tcache_stride;
    logic [3:0][4:0]                conv3d_bcfmap_tcache_offset;

    logic [3:0]                     conv3d_bcfmap_elt_mode;
    logic [3:0]                     conv3d_bcfmap_elt_pric;
    logic [3:0]                     conv3d_bcfmap_elt_bsel;
    logic [3:0]                     conv3d_bcfmap_elt_32ch_i16;

    logic                           weight_update_req, cubank_weight_update_gnt;
    logic                           Noc_core_rd_req, Noc_core_wr_req;
    logic                           Slsu_l1b_from_sc_or_noc;


    enum logic [2:0] {MQ_IDLE, MQ_WAIT_SLSU_GNT, MQ_WAIT_SLSU_OK, MQ_WAIT_HLSU_GNT, MQ_WAIT_NOC_GNT, MQ_WAIT_NOC_OK, MQ_WAIT_WGT_UP_GNT, MQ_WAIT_NOP_DONE} MQ_CS, MQ_NS;
    enum logic [3:0] {VQ_IDLE, VQ_WAIT_GNT, VQ_WAIT_OK, VQ_WAIT_SCACHE_WR_RD_DONE, VQ_WAIT_PSUM_RD_DONE, VQ_WAIT_EVENT_DONE, VQ_WAIT_NOP_DONE, VQ_WAIT_Y_MODE_PRE_DONE, VQ_WAIT_SCACHE_RD_RDY} VQ_CS[3:0], VQ_NS[3:0];
    enum logic {SQ_IDLE, SQ_WAIT_GNT} SQ_CS, SQ_NS;


    assign conv3d_bcfmap_req_o = conv3d_bcfmap_req[0];
    assign conv3d_bcfmap_mode_o = conv3d_bcfmap_mode[0];
    assign conv3d_bcfmap_len_o = conv3d_bcfmap_len[0];
    assign conv3d_bcfmap_rgba_mode_o = conv3d_bcfmap_rgba_mode[0];
    assign conv3d_bcfmap_rgba_stride_o = conv3d_bcfmap_rgba_stride[0];
    assign conv3d_bcfmap_rgba_shift_o = conv3d_bcfmap_rgba_shift[0];
    assign conv3d_bcfmap_hl_op_o = conv3d_bcfmap_hl_op[0];
    assign conv3d_bcfmap_keep_2cycle_en_o = conv3d_bcfmap_keep_2cycle_en[0];
    assign conv3d_bcfmap_group_o = conv3d_bcfmap_group[0];
    assign conv3d_bcfmap_pad0_he_sel_o = conv3d_bcfmap_pad0_he_sel[0];
    assign conv3d_bcfmap_pad0_len_o = conv3d_bcfmap_pad0_len[0];
    assign conv3d_bcfmap_tcache_stride_o = conv3d_bcfmap_tcache_stride[0];
    assign conv3d_bcfmap_tcache_offset_o = conv3d_bcfmap_tcache_offset[0];

    assign conv3d_bcfmap_elt_mode_o = conv3d_bcfmap_elt_mode[0];
    assign conv3d_bcfmap_elt_pric_o = conv3d_bcfmap_elt_pric[0];
    assign conv3d_bcfmap_elt_bsel_o = conv3d_bcfmap_elt_bsel[0];
    assign conv3d_bcfmap_elt_32ch_i16_o = conv3d_bcfmap_elt_32ch_i16[0];

    accel_decode #(
        .IRAM_AWID  (IRAM_AWID)
    )
    U_accel_decode(
        .clk(clk),
        .rst_n(rst_n),

        .instr_MQ_i(MQ_disp_instr_i),
        .instr_VQ_i(VQ_disp_instr_i),
        .instr_SQ_i(SQ_disp_instr_i),
        .illegal_instr_o(illegal_instr),

        .MQ_disp_func_i(MQ_disp_func_i),
        .VQ_disp_func_i(VQ_disp_func_i),
        .SQ_disp_func_i(SQ_disp_func_i),

        //MQ
        .MQ_req_i(MQ_disp_req_i),
        .MQ_cfifo_en_i(MQ_cfifo_en_i),
        .MQ_cfifo_data_i(MQ_cfifo_data_i),

        .MQ_cfg_en_o(MQ_cfg_en),
        .MQ_cfg_addr_o(MQ_cfg_addr),
		.Slsu_data_we_o(Slsu_data_we_o),
		.Slsu_l1b_mode_o(Slsu_l1b_mode_o), //1:norm 0:cache
		.Slsu_tcache_core_load_bank_num_o(Slsu_tcache_core_load_bank_num_o),
        .Slsu_l1b_from_sc_or_noc_o(Slsu_l1b_from_sc_or_noc),
		.Slsu_data_sys_gap_o(Slsu_data_sys_gap_o),
		.Slsu_data_sub_len_o(Slsu_data_sub_len_o),
		.Slsu_data_addr_o(Slsu_data_addr_o),
		.Slsu_data_sys_len_o(Slsu_data_sys_len_o),
		.Slsu_data_mv_last_dis_o(Slsu_data_mv_last_dis_o),
        .weight_update_req_o(weight_update_req),
        .cubank_LB_mv_cub_dst_sel_i(cubank_LB_mv_cub_dst_sel_i),

		.Slsu_l1b_gpu_mode_o(Slsu_l1b_gpu_mode_o), //MQ CFG0
        .Slsu_l1b_op_wr_hl_mask_o(Slsu_l1b_op_wr_hl_mask_o),
        .Slsu_mv_cub_dst_sel_o(Slsu_mv_cub_dst_sel_o),
        .Slsu_tcache_trans_prici_o(Slsu_tcache_trans_prici_o),
        .Slsu_tcache_trans_swbank_o(Slsu_tcache_trans_swbank_o),
		.Slsu_l1b_norm_paral_mode_o(Slsu_l1b_norm_paral_mode_o),
		.Slsu_tcache_mode_o(Slsu_tcache_mode_o), 
		.Slsu_cache_one_ram_qw_base_addr_o(Slsu_cache_one_ram_qw_base_addr_o),
        .Slsu_data_sub_gap_o(Slsu_data_sub_gap_o), //MQ CFG1
        .Slsu_data_sys_gap_ext_o(Slsu_data_sys_gap_ext_o),
        .Slsu_iob_pric_o(Slsu_iob_pric_o),
        .Slsu_iob_l2c_in_cfg_o(Slsu_iob_l2c_in_cfg_o),
        .Slsu_tcache_mvfmap_stride_o(Slsu_tcache_mvfmap_stride_o),
        .Slsu_tcache_mvfmap_offset_o(Slsu_tcache_mvfmap_offset_o),
        
        .Hlsu_data_we_o(Hlsu_data_we_o),
        .Hlsu_l1b_mode_o(Hlsu_l1b_mode_o),
        .Hlsu_data_sys_gap_o(Hlsu_data_sys_gap_o),
        .Hlsu_data_sub_len_o(Hlsu_data_sub_len_o),
        .Hlsu_data_addr_o(Hlsu_data_addr_o),
        .Hlsu_data_sys_len_o(Hlsu_data_sys_len_o),

        .Hlsu_data_sub_gap_o(Hlsu_data_sub_gap_o), //MQ CFG2
        .Hlsu_data_sys_gap_ext_o(Hlsu_data_sys_gap_ext_o),
        .Hlsu_l1b_norm_paral_mode_o(Hlsu_l1b_norm_paral_mode_o),

        .MQ_noc_cfg_en_o(MQ_noc_cfg_en),
        .Noc_cfg_addr_o(Noc_cfg_addr_o),
        .Noc_cfg_data_o(Noc_cfg_data_o),
        
        .MQ_req_type_o(MQ_req_type),
        .Noc_core_rd_req_o(Noc_core_rd_req),
        .Noc_core_wr_req_o(Noc_core_wr_req),
        .MQ_noc_cmd_addr_o(Noc_cmd_addr_o),
        .MQ_nop_en_o(MQ_nop_en),
        .MQ_nop_cycle_num_o(MQ_nop_cycle_num),

        //VQ
        .VQ_req_i(VQ_disp_req_i),
        .VQ_cfifo_en_i(VQ_cfifo_en_i),
        .VQ_cfifo_data_i(VQ_cfifo_data_i),

        .VQ_cfg_en_o(VQ_cfg_en),
        .conv_mode_o(conv_mode_o),

        .conv_cfg_en_o(conv_cfg_en),
        .conv_cfg_addr_o(conv_cfg_addr_o),
        .conv_cfg_data_o(conv_cfg_data_o),

        .dwconv_cross_ram_from_left_o(dwconv_cross_ram_from_left_o), 
        .dwconv_cross_ram_from_right_o(dwconv_cross_ram_from_right_o),
        .dwconv_right_padding_o(dwconv_right_padding_o),
        .dwconv_left_padding_o(dwconv_left_padding_o),
        .dwconv_bottom_padding_o(dwconv_bottom_padding_o),
        .dwconv_top_padding_o(dwconv_top_padding_o),
        .dwconv_trans_num_o(dwconv_trans_num_o),
        .dwconv_run_cycle_num_o(dwconv_run_cycle_num),

        .conv3d_psum_end_index_o(conv3d_psum_end_index_o),
        .conv3d_psum_start_index_o(conv3d_psum_start_index_o),
        .conv3d_first_subch_flag_o(conv3d_first_subch_flag_o),
        .conv3d_result_output_flag_o(conv3d_result_output_flag_o),
        .conv3d_weight_16ch_sel_o(conv3d_weight_16ch_sel_o),
        .conv3d_run_cycle_num_o(conv3d_run_cycle_num),

        .conv3d_bcfmap_en_o(conv3d_bcfmap_en),
        .conv3d_bcfmap_mode_o(conv3d_bcfmap_mode),
        .conv3d_bcfmap_len_o(conv3d_bcfmap_len),
        .conv3d_bcfmap_rgba_mode_o(conv3d_bcfmap_rgba_mode),
        .conv3d_bcfmap_rgba_stride_o(conv3d_bcfmap_rgba_stride),
        .conv3d_bcfmap_rgba_shift_o(conv3d_bcfmap_rgba_shift),
        .conv3d_bcfmap_hl_op_o(conv3d_bcfmap_hl_op),
        .conv3d_bcfmap_keep_2cycle_en_o(conv3d_bcfmap_keep_2cycle_en),
        .conv3d_bcfmap_group_o(conv3d_bcfmap_group),
        .conv3d_bcfmap_pad0_he_sel_o(conv3d_bcfmap_pad0_he_sel),
        .conv3d_bcfmap_pad0_len_o(conv3d_bcfmap_pad0_len),
        .conv3d_bcfmap_tcache_stride_o(conv3d_bcfmap_tcache_stride),
        .conv3d_bcfmap_tcache_offset_o(conv3d_bcfmap_tcache_offset),

        .conv3d_bcfmap_elt_en_o(conv3d_bcfmap_elt_en),
        .conv3d_bcfmap_elt_mode_o(conv3d_bcfmap_elt_mode),
        .conv3d_bcfmap_elt_pric_o(conv3d_bcfmap_elt_pric),
        .conv3d_bcfmap_elt_bsel_o(conv3d_bcfmap_elt_bsel),
        .conv3d_bcfmap_elt_32ch_i16_o(conv3d_bcfmap_elt_32ch_i16),

        .Y_mode_pre_en_o(Y_mode_pre_en_o),
        .Y_mode_cram_sel_o(Y_mode_cram_sel_o),
        .Y_mode_pre_run_cycle_num_o(Y_mode_pre_run_cycle_num),

        .conv_psum_rd_en_o(conv3d_psum_rd_en), 
        .conv_psum_rd_num_o(conv_psum_rd_num_o),
        .conv_psum_rd_ch_sel_o(conv_psum_rd_ch_sel_o),
        .conv_psum_rd_rgb_sel_o(conv_psum_rd_rgb_sel_o),
        .conv_psum_rd_run_cycle_num_o(conv_psum_rd_run_cycle_num),
        .conv_psum_rd_offset_o(conv_psum_rd_offset_o),

        .VQ_scache_wr_en_o(VQ_scache_wr_en),
        .VQ_scache_wr_addr_o(VQ_scache_wr_addr_o),
        .VQ_scache_wr_size_o(VQ_scache_wr_size_o),
        .VQ_scache_wr_run_wait_type_o(VQ_scache_wr_run_wait_type),
        .VQ_scache_wr_run_cycle_num_o(VQ_scache_wr_run_cycle_num),
        .VQ_scache_rd_en_o(VQ_scache_rd_en),
        .VQ_scache_rd_addr_o(VQ_scache_rd_addr_o),
        .VQ_scache_rd_size_o(VQ_scache_rd_size_o),
        .VQ_scache_rd_sign_ext_o(VQ_scache_rd_sign_ext_o),
        .VQ_scache_rd_run_wait_type_o(VQ_scache_rd_run_wait_type),
        .VQ_scache_rd_run_cycle_num_o(VQ_scache_rd_run_cycle_num),
        .VQ_scache_wr_rd_type_o(VQ_scache_wr_rd_type),
        .VQ_scache_we_o(VQ_scache_we),

        .VQ_cub_csr_access_o(VQ_cub_csr_access),
        .VQ_cub_csr_addr_o(VQ_cub_csr_addr_o),
        .VQ_cub_csr_wdata_o(VQ_cub_csr_wdata_o),

        .VQ_alu_event_call_o(VQ_alu_event_call),
        .VQ_alu_event_addr_o(VQ_alu_event_addr),
        .VQ_nop_en_o(VQ_nop_en),
        .VQ_nop_cycle_num_o(VQ_nop_cycle_num),

        //SQ
        .SQ_req_i(SQ_disp_req_i),
        .SQ_cfifo_en_i(SQ_cfifo_en_i),
        .SQ_cfifo_data_i(SQ_cfifo_data_i),

        .Sfu_len_o(Sfu_len_o),
        .Sfu_mode_o(Sfu_mode_o)

        //SQ
    );

    assign VQ_alu_event_call_o = VQ_alu_event_call_w[0];
    assign VQ_alu_event_addr_o = VQ_alu_event_addr[0];

    always_comb begin
        foreach(VQ_nop_multi_cycle[i])
            VQ_nop_multi_cycle[i] = (VQ_nop_cycle_num[i] != 5'b0);
    end
    assign MQ_nop_multi_cycle = (MQ_nop_cycle_num != 5'b0);

    //-----------------------------------
    //  MQ dispatch
    //-----------------------------------

    always_ff @(posedge clk or negedge rst_n) begin
      if(!rst_n)
        MQ_CS <= MQ_IDLE;
      else
        MQ_CS <= MQ_NS;
    end

    always_comb begin
        MQ_NS = MQ_CS;
        Slsu_data_req_o = 1'b0;
        Slsu_cfg_vld_o = 1'b0;
        Slsu_cfg_addr_o = 2'b0;
        Noc_cmd_req_o = 1'b0;
        Noc_cfg_vld_o = 1'b0;
        Hlsu_data_req_o = 1'b0;
        Hlsu_chk_done_req_o = 1'b0;
        
        case(MQ_CS)
            MQ_IDLE: begin //wait for MQ_req
                if(MQ_disp_req_i) begin

                    if(MQ_req_type==SLSU_REQ) begin //Slsu req
                        Slsu_data_req_o = 1'b1;

                        if(MQ_cfg_en) begin //TODO:if need wait for ready?
                            Slsu_cfg_vld_o = 1'b1;
                            Slsu_cfg_addr_o = MQ_cfg_addr;
                            Slsu_data_req_o = 1'b0;
                        end
                        else if(weight_update_req && ~cubank_weight_update_gnt) begin
                            Slsu_data_req_o = 1'b0;
                            MQ_NS = MQ_WAIT_WGT_UP_GNT;
                        end
                        else if(Slsu_data_gnt_i) begin
                            Noc_cmd_req_o = Noc_core_rd_req & ~Slsu_l1b_from_sc_or_noc;
                            if(Noc_cmd_req_o) begin
                                if(Noc_cmd_gnt_i)
                                    MQ_NS = MQ_WAIT_SLSU_OK;
                                else
                                    MQ_NS = MQ_WAIT_NOC_GNT;
                            end
                            else
                                MQ_NS = MQ_WAIT_SLSU_OK;
                        end
                        else
                            MQ_NS = MQ_WAIT_SLSU_GNT;
                    end
                    else if(MQ_req_type==HLSU_REQ) begin //hlsu req
                        Hlsu_data_req_o = 1'b1;

                        if(Hlsu_data_gnt_i) begin
                            Noc_cmd_req_o = 1'b1;
                                if(~Noc_cmd_gnt_i)
                                    MQ_NS = MQ_WAIT_NOC_GNT;
                        end
                        else begin
                            MQ_NS = MQ_WAIT_HLSU_GNT;
                        end
                    end
                    else if(MQ_req_type==HLSU_CHK_REQ) begin //hlsu chk done req
                        Hlsu_chk_done_req_o = 1'b1;
                        if(~Hlsu_chk_done_gnt_i)
                            MQ_NS = MQ_WAIT_HLSU_GNT;
                    end
                    else begin //NOC req or NOP or npu_store
                        if(MQ_nop_en) begin
                            if(MQ_nop_multi_cycle)
                                MQ_NS = MQ_WAIT_NOP_DONE;
                            else
                                MQ_NS = MQ_CS;
                        end
                        else begin
                            Noc_cmd_req_o = 1'b1;

                            if(MQ_noc_cfg_en) begin
                                Noc_cfg_vld_o = 1'b1;
                                Noc_cmd_req_o = 1'b0;
                            end
                            else if(Noc_cmd_gnt_i)
                                MQ_NS = MQ_WAIT_NOC_OK;
                            else
                                MQ_NS = MQ_WAIT_NOC_GNT;
                        end
                    end
                end
            end
            MQ_WAIT_SLSU_GNT: begin
                Slsu_data_req_o = 1'b1;
                if(Slsu_data_gnt_i) begin
                    Noc_cmd_req_o = Noc_core_rd_req & ~Slsu_l1b_from_sc_or_noc;
                    if(Noc_cmd_req_o) begin
                        if(Noc_cmd_gnt_i)
                            MQ_NS = MQ_WAIT_SLSU_OK;
                        else
                            MQ_NS = MQ_WAIT_NOC_GNT;
                    end
                    else
                        MQ_NS = MQ_WAIT_SLSU_OK;
                end
            end
            MQ_WAIT_NOC_GNT: begin
                Noc_cmd_req_o = 1'b1;
                if(Noc_cmd_gnt_i) begin
                    if(MQ_req_type==SLSU_REQ) //SLSU req
                        MQ_NS = MQ_WAIT_SLSU_OK;
                    else if(MQ_req_type==HLSU_REQ) //HLSU req
                        MQ_NS = MQ_IDLE;
                    else //NOC req
                        MQ_NS = MQ_WAIT_NOC_OK;
                end
            end
            MQ_WAIT_HLSU_GNT: begin
                if(MQ_req_type==HLSU_REQ) begin
                    Hlsu_data_req_o = 1'b1;
                    if(Hlsu_data_gnt_i) begin
                        Noc_cmd_req_o = 1'b1;
                            if(Noc_cmd_gnt_i)
                                MQ_NS = MQ_IDLE;
                            else
                                MQ_NS = MQ_WAIT_NOC_GNT;
                    end
                end
                else begin //wait hlsu chk done gnt
                    Hlsu_chk_done_req_o = 1'b1;
                    if(Hlsu_chk_done_gnt_i)
                        MQ_NS = MQ_IDLE;
                end
            end            
            MQ_WAIT_SLSU_OK: begin
                if(Slsu_data_ok_i) begin
                    MQ_NS = MQ_IDLE;
                end
            end
            MQ_WAIT_NOC_OK: begin
                if(Noc_cmd_ok_i) begin
                    MQ_NS = MQ_IDLE;
                end                
            end
            MQ_WAIT_WGT_UP_GNT: begin
                if(cubank_weight_update_gnt) begin
                    Slsu_data_req_o = 1'b1;
                    if(Slsu_data_gnt_i)
                        MQ_NS = MQ_WAIT_SLSU_OK;
                    else
                        MQ_NS = MQ_WAIT_SLSU_GNT;
                end
            end
            MQ_WAIT_NOP_DONE: begin
                if(MQ_nop_done)
                    MQ_NS = MQ_IDLE;
            end            
            //default:;
        endcase
    end

    //assign MQ_busy = (MQ_CS==MQ_WAIT_SLSU_GNT) || (MQ_CS==MQ_WAIT_SLSU_OK) || (MQ_CS==MQ_WAIT_NOC_GNT) || (MQ_CS==MQ_WAIT_NOC_OK);
    //assign MQ_disp_ready_o = ((MQ_CS==MQ_IDLE) && (MQ_NS!=MQ_WAIT_YIELD)) || (MQ_NS==MQ_IDLE);
    assign MQ_disp_ready_o = MQ_NS==MQ_IDLE;
    //assign MQ_disp_done_o = MQ_NS==MQ_IDLE && MQ_CS!=MQ_IDLE;


    //replace cubank_weight_update_gnt_i
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            cubank_weight_update_gnt <= 1'b0;
	    end
        else if((cubank_weight_update_gnt == 1'b0) && (conv_cfg_vld_o[0] || conv_req_o[0]&&conv_mode_o[0]==2'b00)) begin //conv3d_start
            cubank_weight_update_gnt <= 1'b1;
        end
        else if((cubank_weight_update_gnt == 1'b1) && Slsu_data_req_o && weight_update_req) begin //mv_weight
            cubank_weight_update_gnt <= 1'b0;
        end
        else begin
            cubank_weight_update_gnt <= cubank_weight_update_gnt;
        end
    end    

    //MQ_nop cycle cnt
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            MQ_nop_cycle_cnt <= 5'b0;
            MQ_nop_done <= 1'b0;
        end
        else if(MQ_nop_cycle_cnt == MQ_nop_cycle_num-1) begin
            MQ_nop_cycle_cnt <= 5'b0;
            MQ_nop_done <= 1'b1;
        end
        else if(MQ_NS==MQ_WAIT_NOP_DONE) begin
            MQ_nop_cycle_cnt <= MQ_nop_cycle_cnt + 1;
            MQ_nop_done <= 1'b0;
        end
        else begin
            MQ_nop_done <= 1'b0;
        end
    end


    //-----------------------------------
    //  VQ dispatch
    //-----------------------------------
    
    genvar i;
    generate
    for(i=0;i<4;i=i+1) begin: VQ_DISPATCH

    always_ff @(posedge clk or negedge rst_n) begin
      if(!rst_n)
        VQ_CS[i] <= VQ_IDLE;
      else
        VQ_CS[i] <= VQ_NS[i];
    end


    always_comb begin
        VQ_NS[i] = VQ_CS[i];
        conv_req_o[i] = 1'b0;
        conv_cfg_vld_o[i] = 1'b0;
        conv3d_bcfmap_req[i] = 1'b0;
        conv_psum_rd_req_o[i] = 1'b0;
        VQ_scache_wr_en_o[i] = 1'b0;
        VQ_scache_rd_en_o[i] = 1'b0;
        VQ_cub_csr_access_o[i] = 1'b0;
        VQ_alu_event_call_w[i] = 1'b0;

        case(VQ_CS[i])
            VQ_IDLE: begin //wait for VQ_req
        
                if(VQ_disp_req_i[i]) begin
                    VQ_scache_wr_en_o[i] = VQ_scache_wr_en[i];
                    VQ_scache_rd_en_o[i] = VQ_scache_rd_en[i] & scache_cflow_data_rd_st_rdy_i;

                    if(VQ_nop_en[i]) begin
                        if(VQ_nop_multi_cycle[i])
                            VQ_NS[i] = VQ_WAIT_NOP_DONE;
                        else
                            VQ_NS[i] = VQ_CS[i];
                    end
                    else if(conv_mode_o[i]==2'b10) begin //eltwise req+scache rd
                        conv3d_bcfmap_req[i] = conv3d_bcfmap_elt_en[i];
                        VQ_NS[i] = VQ_WAIT_SCACHE_WR_RD_DONE;
                    end
                    else if(VQ_scache_wr_en[i] && VQ_scache_wr_rd_type[i]==1'b1) begin//wr self
                        if(VQ_scache_wr_run_wait_type[i]) //need to wait done
                            VQ_NS[i] = VQ_WAIT_SCACHE_WR_RD_DONE;
                        else
                            VQ_NS[i] = VQ_CS[i];
                    end
                    else if(VQ_scache_rd_en[i]) begin
                        if(~scache_cflow_data_rd_st_rdy_i) begin
                            VQ_NS[i] = VQ_WAIT_SCACHE_RD_RDY;
                        end
                        else if(VQ_scache_wr_rd_type[i]==1'b1) begin//rd self
                            if(VQ_scache_rd_run_wait_type[i]) //need to wait done
                                VQ_NS[i] = VQ_WAIT_SCACHE_WR_RD_DONE;
                            else
                                VQ_NS[i] = VQ_CS[i];
                        end
                    end
                    //else if(VQ_scache_rd_en[i] && VQ_scache_wr_rd_type[i]==1'b1) begin//rd self
                    //    if(VQ_scache_rd_run_wait_type[i]) //need to wait done
                    //        VQ_NS[i] = VQ_WAIT_SCACHE_WR_RD_DONE;
                    //    else
                    //        VQ_NS[i] = VQ_CS[i];                            
                    //end                    
                    else if(VQ_cfg_en[i]) begin 
                        conv_cfg_vld_o[i] = 1'b1;
                    end
                    else begin
                        conv3d_bcfmap_req[i] = conv3d_bcfmap_en[i];

                        if(conv3d_psum_rd_en[i]) begin
                            if(VQ_alu_event_finish_i[i]) begin
                                conv_psum_rd_req_o[i] = 1'b1;
                                VQ_NS[i] = VQ_WAIT_PSUM_RD_DONE;
                            end
                            else
                                VQ_NS[i] = VQ_WAIT_EVENT_DONE;
                        end
                        else if(Y_mode_pre_en_o[i]) begin
                             VQ_NS[i] = VQ_WAIT_Y_MODE_PRE_DONE;
                        end
                        else if(/*dwconv_psum_rd_en || */VQ_alu_event_call[i]) begin
                            if(VQ_alu_event_finish_i[i]) begin
                                VQ_alu_event_call_w[i] = 1'b1;
                            end
                            else
                                VQ_NS[i] = VQ_WAIT_EVENT_DONE;                        
                            //VQ_NS[i] = VQ_CS[i];
                        end
                        else if(VQ_cub_csr_access[i]) begin
                            if(VQ_alu_event_finish_i[i]) begin
                                VQ_cub_csr_access_o[i] = 1'b1;
                            end
                            else
                                VQ_NS[i] = VQ_WAIT_EVENT_DONE;
                        end
                        else begin
                            if(conv_mode_o[i]==2'b01 && ~VQ_alu_event_finish_i[i]) //dwconv
                                VQ_NS[i] = VQ_WAIT_EVENT_DONE;
                            else begin
                                conv_req_o[i] = 1'b1;
                                if(conv_gnt_i[i])
                                    VQ_NS[i] = VQ_WAIT_OK;
                                else
                                    VQ_NS[i] = VQ_WAIT_GNT;
                            end
                        end
                    end
                end
            end
            VQ_WAIT_GNT: begin
                conv_req_o[i] = 1'b1;
                conv3d_bcfmap_req[i] = conv3d_bcfmap_en[i];
 
                if(conv_gnt_i[i]) 
                    VQ_NS[i] = VQ_WAIT_OK;
            end
            VQ_WAIT_SCACHE_RD_RDY: begin
                if(scache_cflow_data_rd_st_rdy_i) begin
                    VQ_scache_rd_en_o[i] = 1'b1;
                    if(VQ_scache_wr_rd_type[i]==1'b1 && VQ_scache_rd_run_wait_type[i]) //rd self && need to wait done
                        VQ_NS[i] = VQ_WAIT_SCACHE_WR_RD_DONE;
                    else
                        VQ_NS[i] = VQ_IDLE;
                end
            end
            VQ_WAIT_SCACHE_WR_RD_DONE: begin
                if(scache_wr_rd_done[i])
                    VQ_NS[i] = VQ_IDLE;
            end
            VQ_WAIT_PSUM_RD_DONE: begin
                if(conv3d_psum_rd_done[i])
                    VQ_NS[i] = VQ_IDLE;
            end
            VQ_WAIT_Y_MODE_PRE_DONE: begin
                if(Y_mode_pre_done[i])
                    VQ_NS[i] = VQ_IDLE;
            end            
            VQ_WAIT_EVENT_DONE: begin
                if(VQ_alu_event_finish_i[i]) begin
                    if(conv3d_psum_rd_en[i]) begin
                        conv_psum_rd_req_o[i] = 1'b1;
                        VQ_NS[i] = VQ_WAIT_PSUM_RD_DONE;
                    end
                    else if(VQ_alu_event_call[i]) begin
                        VQ_alu_event_call_w[i] = 1'b1;
                        VQ_NS[i] = VQ_IDLE;
                    end
                    else if(VQ_cub_csr_access[i]) begin
                        VQ_cub_csr_access_o[i] = 1'b1;
                        VQ_NS[i] = VQ_IDLE;
                    end
                    else begin  //dwconv
                        conv_req_o[i] = 1'b1;
                        if(conv_gnt_i[i])
                            VQ_NS[i] = VQ_WAIT_OK;
                        else
                            VQ_NS[i] = VQ_WAIT_GNT;
                    end
                end 
            end
            VQ_WAIT_NOP_DONE: begin
                if(VQ_nop_done[i])
                    VQ_NS[i] = VQ_IDLE;
            end
            VQ_WAIT_OK: begin
                if((conv_mode_o[i]==2'b00) && conv3d_done[i]) //conv3d done gen by conv3d cnt 
                    VQ_NS[i] = VQ_IDLE;
                else if((conv_mode_o[i]==2'b01) && dwconv_done[i]) //dwconv done gen by conv+alu+scache cnt
                    VQ_NS[i] = VQ_IDLE;
            end
            //default:;
            default: VQ_NS[i] = VQ_IDLE;
        endcase
    end

    //-----------------------------------
    //  run cycle scoreboard
    //-----------------------------------

    //cycle define
    //assign conv3d_psum_rd_cycle_num[i] = conv_psum_rd_num_o[i];

    //conv3d cycle cnt
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            conv3d_run_cycle_cnt[i] <= 8'b0;
            conv3d_done[i] <= 1'b0;
        end
        else if(conv3d_run_cycle_cnt[i]==conv3d_run_cycle_num[i]-1) begin
            conv3d_run_cycle_cnt[i] <= 8'b0;
            conv3d_done[i] <= 1'b1;
        end
        else if(conv_mode_o[i]==2'b00 && VQ_NS[i]==VQ_WAIT_OK /*|| VQ_CS==VQ_WAIT_OK*/) begin
            conv3d_run_cycle_cnt[i] <= conv3d_run_cycle_cnt[i] + 1;
            conv3d_done[i] <= 1'b0;
        end
        else begin
            conv3d_done[i] <= 1'b0;
        end
    end

    //dwconv cycle cnt
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            dwconv_run_cycle_cnt[i] <= 7'b0;
            dwconv_done[i] <= 1'b0;
        end
        else if(dwconv_run_cycle_cnt[i]==dwconv_run_cycle_num[i]-1) begin
            dwconv_run_cycle_cnt[i] <= 7'b0;
            dwconv_done[i] <= 1'b1;
        end
        else if(conv_mode_o[i]==2'b01 && VQ_NS[i]==VQ_WAIT_OK /*|| VQ_CS==VQ_WAIT_OK*/) begin
            dwconv_run_cycle_cnt[i] <= dwconv_run_cycle_cnt[i] + 1;
            dwconv_done[i] <= 1'b0;
        end
        else begin
            dwconv_done[i] <= 1'b0;
        end
    end

    //psum cycle cnt
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            conv3d_psum_rd_cycle_cnt[i] <= 6'b0;
            conv3d_psum_rd_done[i] <= 1'b0;
        end
        else if(conv3d_psum_rd_cycle_cnt[i]==conv_psum_rd_run_cycle_num[i]-1) begin
            conv3d_psum_rd_cycle_cnt[i] <= 6'b0;
            conv3d_psum_rd_done[i] <= 1'b1;
        end
        else if(VQ_NS[i]==VQ_WAIT_PSUM_RD_DONE /*|| VQ_CS==VQ_WAIT_OK*/) begin
            conv3d_psum_rd_cycle_cnt[i] <= conv3d_psum_rd_cycle_cnt[i] + 1;
            conv3d_psum_rd_done[i] <= 1'b0;
        end
        else begin
            conv3d_psum_rd_done[i] <= 1'b0;
        end
    end

    //Y_mode_PRE cycle cnt
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            Y_mode_pre_cycle_cnt[i] <= 6'b0;
            Y_mode_pre_done[i] <= 1'b0;
        end
        else if(Y_mode_pre_cycle_cnt[i]==Y_mode_pre_run_cycle_num[i]-1) begin
            Y_mode_pre_cycle_cnt[i] <= 6'b0;
            Y_mode_pre_done[i] <= 1'b1;
        end
        else if(VQ_NS[i]==VQ_WAIT_Y_MODE_PRE_DONE) begin
            Y_mode_pre_cycle_cnt[i] <= Y_mode_pre_cycle_cnt[i] + 1;
            Y_mode_pre_done[i] <= 1'b0;
        end
        else begin
            Y_mode_pre_done[i] <= 1'b0;
        end
    end

    //scache wr rd cycle cnt
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            scache_wr_rd_cycle_cnt[i] <= 10'b0;
            scache_wr_rd_done[i] <= 1'b0;
        end
        else if(scache_wr_rd_cycle_cnt[i] == ((VQ_scache_we[i] ? VQ_scache_wr_run_cycle_num[i] : VQ_scache_rd_run_cycle_num[i]) -1)) begin
            scache_wr_rd_cycle_cnt[i] <= 10'b0;
            scache_wr_rd_done[i] <= 1'b1;
        end
        else if((VQ_NS[i]==VQ_WAIT_SCACHE_WR_RD_DONE) && (CU_bank_scache_dout_en_i ? CU_bank_data_out_ready_i : 1'b1)) begin
            scache_wr_rd_cycle_cnt[i] <= scache_wr_rd_cycle_cnt[i] + 1;
            scache_wr_rd_done[i] <= 1'b0;
        end
        else begin
            scache_wr_rd_done[i] <= 1'b0;
        end
    end


    //VQ_nop cycle cnt
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            VQ_nop_cycle_cnt[i] <= 5'b0;
            VQ_nop_done[i] <= 1'b0;
        end
        else if(VQ_nop_cycle_cnt[i] == VQ_nop_cycle_num[i]-1) begin
            VQ_nop_cycle_cnt[i] <= 5'b0;
            VQ_nop_done[i] <= 1'b1;
        end
        else if(VQ_NS[i]==VQ_WAIT_NOP_DONE) begin
            VQ_nop_cycle_cnt[i] <= VQ_nop_cycle_cnt[i] + 1;
            VQ_nop_done[i] <= 1'b0;
        end
        else begin
            VQ_nop_done[i] <= 1'b0;
        end
    end

    end
    endgenerate
    
    assign VQ_disp_ready_o = (VQ_NS[0]==VQ_IDLE);
    //assign VQ_disp_done_o = (VQ_NS[0]==VQ_IDLE) && (VQ_CS[0]!=VQ_IDLE);
    //assign conv3d_psum_rd_en = conv_psum_rd_en;
   


    //-----------------------------------
    //  SQ dispatch
    //-----------------------------------

    always_ff @(posedge clk or negedge rst_n) begin
      if(!rst_n)
        SQ_CS <= SQ_IDLE;
      else
        SQ_CS <= SQ_NS;
    end

    always_comb begin
        SQ_NS = SQ_CS;
        Sfu_req_o = 1'b0;
        
        case(SQ_CS)
            SQ_IDLE: begin //wait for SQ_req
                if(SQ_disp_req_i) begin

                    Sfu_req_o = 1'b1;
                    if (~Sfu_gnt_i) begin
                        SQ_NS = SQ_WAIT_GNT;
                    end
                end
            end
            SQ_WAIT_GNT: begin
                Sfu_req_o = 1'b1;
                if(Sfu_gnt_i) begin
                    SQ_NS = SQ_IDLE;
                end
            end
            //default:;
        endcase
    end

    assign SQ_disp_ready_o = SQ_NS==SQ_IDLE;
endmodule
