module accel_decode #(
    parameter   IRAM_AWID = 8
)
(
    input                                   clk,
    input                                   rst_n,

    input  [31:7]                           instr_MQ_i,
    input  [3:0][31:7]                      instr_VQ_i,
    input  [31:7]                           instr_SQ_i,
    output logic                            illegal_instr_o,

    input  [2:0]                            MQ_disp_func_i,
    input  [3:0][1:0]                       VQ_disp_func_i,
    input                                   SQ_disp_func_i,

    //MQ info
    input                                   MQ_req_i,
    output logic                            MQ_cfg_en_o,
    output logic [1:0]                      MQ_cfg_addr_o,
    input                                   MQ_cfifo_en_i,
    input  [31:0]                           MQ_cfifo_data_i,

    output logic                            Slsu_data_we_o,
    output logic                            Slsu_l1b_mode_o, //1:norm 0:cache
    output logic                            Slsu_tcache_core_load_bank_num_o,
    output logic                            Slsu_l1b_from_sc_or_noc_o,
    output logic [8:0]                      Slsu_data_sys_gap_o,
    output logic [8:0]                      Slsu_data_sub_len_o,
    output logic [12:0]                     Slsu_data_addr_o,
    output logic [8:0]                      Slsu_data_sys_len_o,
    output logic                            Slsu_data_mv_last_dis_o,
    output logic                            weight_update_req_o,
    input  [1:0]                            cubank_LB_mv_cub_dst_sel_i,                             

    output logic                            Slsu_l1b_gpu_mode_o, //MQ CFG0
    output logic [1:0]                      Slsu_l1b_op_wr_hl_mask_o,
    output logic [1:0]                      Slsu_mv_cub_dst_sel_o,
    output logic                            Slsu_tcache_trans_prici_o, //0:int8 1:int16
    output logic                            Slsu_tcache_trans_swbank_o,
    output logic                            Slsu_l1b_norm_paral_mode_o,
    output logic [2:0]                      Slsu_tcache_mode_o,
    output logic [8:0]                      Slsu_cache_one_ram_qw_base_addr_o,
    output logic [8:0]                      Slsu_data_sub_gap_o, //MQ CFG1
    output logic [4:0]                      Slsu_data_sys_gap_ext_o,
    output logic                            Slsu_iob_pric_o,
    output logic                            Slsu_iob_l2c_in_cfg_o,
    output logic                            Slsu_tcache_mvfmap_stride_o,
    output logic [4:0]                      Slsu_tcache_mvfmap_offset_o,

    output logic                            Hlsu_data_we_o,
    output logic                            Hlsu_l1b_mode_o,
    output logic [8:0]                      Hlsu_data_sys_gap_o,
    output logic [8:0]                      Hlsu_data_sub_len_o,
    output logic [12:0]                     Hlsu_data_addr_o,
    output logic [8:0]                      Hlsu_data_sys_len_o,

    output logic [8:0]                      Hlsu_data_sub_gap_o, //MQ CFG2
    output logic [4:0]                      Hlsu_data_sys_gap_ext_o,
    output logic                            Hlsu_l1b_norm_paral_mode_o,

    output logic                            MQ_noc_cfg_en_o,
    output logic [6:0]                      Noc_cfg_addr_o,
    output logic [12:0]                     Noc_cfg_data_o,
    
    output logic [1:0]                      MQ_req_type_o,
    output logic                            Noc_core_rd_req_o,
    output logic                            Noc_core_wr_req_o,
    output logic [2:0]                      MQ_noc_cmd_addr_o,

    output logic                            MQ_nop_en_o,
    output logic [4:0]                      MQ_nop_cycle_num_o,

    //VQ info
    input  [3:0]                            VQ_req_i,
    output logic [3:0]                      VQ_cfg_en_o,
    input  [3:0]                            VQ_cfifo_en_i,
    input  [3:0][31:0]                      VQ_cfifo_data_i,

    output logic [3:0][1:0]                 conv_mode_o, //00:norm conv 01:dw conv 10:rgba
    output logic [3:0]                      conv_cfg_en_o,
    output logic [3:0][1:0]                 conv_cfg_addr_o,
    output logic [3:0][22-1:0]              conv_cfg_data_o,

    output logic [3:0]                      dwconv_cross_ram_from_left_o,
    output logic [3:0]                      dwconv_cross_ram_from_right_o,
    output logic [3:0]                      dwconv_right_padding_o,
    output logic [3:0]                      dwconv_left_padding_o,
    output logic [3:0]                      dwconv_bottom_padding_o,
    output logic [3:0]                      dwconv_top_padding_o,
    output logic [3:0][3:0]                 dwconv_trans_num_o,
    output logic [3:0][6:0]                 dwconv_run_cycle_num_o,

    output logic [3:0][4:0]                 conv3d_psum_end_index_o,
    output logic [3:0][4:0]                 conv3d_psum_start_index_o,
    output logic [3:0]                      conv3d_first_subch_flag_o,
    output logic [3:0]                      conv3d_result_output_flag_o,
    output logic [3:0][1:0]                 conv3d_weight_16ch_sel_o,
    output logic [3:0][7:0]                 conv3d_run_cycle_num_o,

    output logic [3:0]                      conv3d_bcfmap_en_o,
    output logic [3:0]                      conv3d_bcfmap_mode_o,
    output logic [3:0][5:0]                 conv3d_bcfmap_len_o,
    output logic [3:0]                      conv3d_bcfmap_rgba_mode_o,
    output logic [3:0]                      conv3d_bcfmap_rgba_stride_o,
    output logic [3:0][4:0]                 conv3d_bcfmap_rgba_shift_o,
    output logic [3:0]                      conv3d_bcfmap_hl_op_o,
    output logic [3:0]                      conv3d_bcfmap_keep_2cycle_en_o,
    output logic [3:0]                      conv3d_bcfmap_group_o,
    output logic [3:0]                      conv3d_bcfmap_pad0_he_sel_o,
    output logic [3:0][3:0]                 conv3d_bcfmap_pad0_len_o,
    output logic [3:0]                      conv3d_bcfmap_tcache_stride_o,
    output logic [3:0][4:0]                 conv3d_bcfmap_tcache_offset_o,
   
    output logic [3:0]                      conv3d_bcfmap_elt_en_o,
    output logic [3:0]                      conv3d_bcfmap_elt_mode_o,
    output logic [3:0]                      conv3d_bcfmap_elt_pric_o,
    output logic [3:0]                      conv3d_bcfmap_elt_bsel_o,
    output logic [3:0]                      conv3d_bcfmap_elt_32ch_i16_o,

    output logic [3:0]                      Y_mode_pre_en_o,
    output logic [3:0]                      Y_mode_cram_sel_o, //to Vector
    output logic [3:0][4:0]                 Y_mode_pre_run_cycle_num_o,

    output logic [3:0]                      conv_psum_rd_en_o,
    output logic [3:0][4:0]                 conv_psum_rd_num_o,
    output logic [3:0]                      conv_psum_rd_ch_sel_o,
    output logic [3:0]                      conv_psum_rd_rgb_sel_o,
    output logic [3:0][5:0]                 conv_psum_rd_run_cycle_num_o,
    output logic [3:0][4:0]                 conv_psum_rd_offset_o,

    output logic [3:0]                      VQ_scache_wr_rd_type_o,
    output logic [3:0]                      VQ_scache_we_o,

    output logic [3:0]                      VQ_scache_wr_en_o,
    output logic [3:0][8:0]                 VQ_scache_wr_addr_o,
    output logic [3:0][1:0]                 VQ_scache_wr_size_o,
    output logic [3:0]                      VQ_scache_wr_run_wait_type_o,
    output logic [3:0][9:0]                 VQ_scache_wr_run_cycle_num_o,

    output logic [3:0]                      VQ_scache_rd_en_o,
    output logic [3:0][8:0]                 VQ_scache_rd_addr_o,
    output logic [3:0][1:0]                 VQ_scache_rd_size_o,
    output logic [3:0]                      VQ_scache_rd_sign_ext_o,
    output logic [3:0]                      VQ_scache_rd_run_wait_type_o,
    output logic [3:0][9:0]                 VQ_scache_rd_run_cycle_num_o,

    output logic [3:0]                      VQ_cub_csr_access_o,
    output logic [3:0][5:0]                 VQ_cub_csr_addr_o,
    output logic [3:0][15:0]                VQ_cub_csr_wdata_o,

    output logic [3:0]                      VQ_alu_event_call_o,
    output logic [3:0][IRAM_AWID-1:0]       VQ_alu_event_addr_o,

    output logic [3:0]                      VQ_nop_en_o,
    output logic [3:0][4:0]                 VQ_nop_cycle_num_o,

    //SQ info
    input                                   SQ_req_i,
    input                                   SQ_cfifo_en_i,
    input  [31:0]                           SQ_cfifo_data_i,

    output logic [5:0]                      Sfu_len_o,
    output logic [3:0]                      Sfu_mode_o
);

    `include "npu_decode_param.v"

    localparam  MQ_CFG          = 2'b00;
    localparam  MQ_LOAD         = 2'b01;
    localparam  MQ_STORE        = 2'b10;
    localparam  MQ_MV           = 2'b11;

    localparam  MQ_NOC_CFG      = 2'b00;
    localparam  MQ_NOC          = 2'b01;
    localparam  MQ_NOP          = 2'b10;
    localparam  MQ_HLOAD        = 2'b11;
   
    localparam  SLSU_REQ        = 2'b00;
    localparam  HLSU_REQ        = 2'b01;
    localparam  NOC_REQ         = 2'b10;
    localparam  HLSU_CHK_REQ    = 2'b11;

    logic [12:0]              Slsu_data_addr_q;
    logic [8:0]               Slsu_data_sub_len_q;
    logic                     Slsu_data_mv_last_dis_q;

    logic [12:0]              Hlsu_data_addr_q;
    logic [8:0]               Hlsu_data_sub_len_q;
    
    logic [3:0]               conv3d_bcfmap_mode_q;
    logic [3:0][5:0]          conv3d_bcfmap_32ch_len_q;
    logic [3:0][4:0]          conv3d_bcfmap_rgba_shift_q;
    logic [3:0]               conv3d_bcfmap_hl_op_q;
    logic [3:0]               conv3d_bcfmap_pad0_he_sel_q; 
    logic [3:0][3:0]          conv3d_bcfmap_pad0_len_q;
    logic [3:0][4:0]          conv3d_bcfmap_tcache_offset_q;
    logic [3:0]               conv3d_first_subch_flag_q;

    logic [3:0][7:0]          conv3d_run_cycle_num_q;
    logic [3:0][6:0]          dwconv_run_cycle_num_q;
    logic [3:0][8:0]          VQ_scache_wr_addr_q;
    logic [3:0][8:0]          VQ_scache_rd_addr_q;
    logic [3:0][4:0]          conv_psum_rd_offset_q;

    always_comb begin
        MQ_cfg_en_o = 1'b0;
        MQ_cfg_addr_o = 2'b1;
        Slsu_data_we_o = 'b0;
        Slsu_l1b_mode_o = 'b0;
        Slsu_tcache_core_load_bank_num_o = 'b0;
        Slsu_l1b_from_sc_or_noc_o = 'b0;
        Slsu_data_sys_gap_o = 'b0;
        Slsu_data_sub_len_o = Slsu_data_sub_len_q;
        Slsu_data_addr_o = Slsu_data_addr_q;
        Slsu_data_sys_len_o = 'b0;
        Slsu_data_mv_last_dis_o = Slsu_data_mv_last_dis_q;
        weight_update_req_o = 'b0;

        Slsu_l1b_gpu_mode_o = 'b0;
        Slsu_l1b_norm_paral_mode_o = 'b0;
        Slsu_tcache_mode_o = 'b0;
        Slsu_cache_one_ram_qw_base_addr_o = 'b0;
        Slsu_l1b_op_wr_hl_mask_o = 1'b0;
        Slsu_mv_cub_dst_sel_o = 'b0;
        Slsu_tcache_trans_prici_o = 1'b0;
        Slsu_tcache_trans_swbank_o = 1'b0;
        Slsu_data_sub_gap_o = 'b0;
        Slsu_data_sys_gap_ext_o = 'b0;
        Slsu_iob_pric_o = 1'b0;
        Slsu_iob_l2c_in_cfg_o = 1'b0;
        Slsu_tcache_mvfmap_stride_o = 'b0;
        Slsu_tcache_mvfmap_offset_o = 'b0;

        Hlsu_data_we_o = 'b0;
        Hlsu_l1b_mode_o = 'b0;
        Hlsu_data_sys_gap_o = 'b0;
        Hlsu_data_sub_len_o = Hlsu_data_sub_len_q;
        Hlsu_data_addr_o = Hlsu_data_addr_q;
        Hlsu_data_sys_len_o = 'b0;

        Hlsu_data_sub_gap_o = 'b0;
        Hlsu_data_sys_gap_ext_o = 'b0;
        Hlsu_l1b_norm_paral_mode_o = 'b0;

        MQ_noc_cfg_en_o = 1'b0;
        Noc_cfg_addr_o = 'b0;
        Noc_cfg_data_o = 'b0;
    
        MQ_req_type_o = SLSU_REQ;
        Noc_core_rd_req_o = 1'b0;
        Noc_core_wr_req_o = 1'b0;
        MQ_noc_cmd_addr_o = 'b0;

        MQ_nop_en_o = 1'b0;
        MQ_nop_cycle_num_o = 5'b0;

        if(MQ_req_i) begin
            if(MQ_disp_func_i[2]==1'b0) begin //Slsu
                case(MQ_disp_func_i[1:0])
                    MQ_CFG: begin 
                        //MQ_cfg0
                        if(instr_MQ_i[31:30]==2'b00) begin
                            MQ_cfg_en_o = 1'b1;
                            MQ_cfg_addr_o = 2'b00;
                            Slsu_l1b_gpu_mode_o = instr_MQ_i[7];
                            Slsu_l1b_norm_paral_mode_o = instr_MQ_i[8];
                            Slsu_tcache_mode_o = instr_MQ_i[11:9];
                            Slsu_cache_one_ram_qw_base_addr_o = instr_MQ_i[20:12];
                            Slsu_l1b_op_wr_hl_mask_o = instr_MQ_i[29:28];
                            Slsu_mv_cub_dst_sel_o = instr_MQ_i[27:26];
                            Slsu_tcache_trans_prici_o = instr_MQ_i[25];
                            Slsu_tcache_trans_swbank_o = instr_MQ_i[24];
                        end
                        //MQ_cfg1
                        else if(instr_MQ_i[31:30]==2'b01) begin
                            MQ_cfg_en_o = 1'b1;
                            MQ_cfg_addr_o = 2'b01;
                            Slsu_data_sub_gap_o = instr_MQ_i[15:7];
                            Slsu_data_sys_gap_ext_o = instr_MQ_i[20:16];
                            Slsu_iob_pric_o = instr_MQ_i[21];
                            Slsu_iob_l2c_in_cfg_o = instr_MQ_i[22];
                            Slsu_tcache_mvfmap_stride_o = instr_MQ_i[23];
                            Slsu_tcache_mvfmap_offset_o = instr_MQ_i[28:24];
                        end
                        //MQ_cfg2
                        else if(instr_MQ_i[31:30]==2'b10) begin
                            MQ_cfg_en_o = 1'b1;
                            MQ_cfg_addr_o = 2'b10;
                            Hlsu_data_sub_gap_o = instr_MQ_i[15:7];
                            Hlsu_data_sys_gap_ext_o = instr_MQ_i[20:16];
                            Hlsu_l1b_norm_paral_mode_o = instr_MQ_i[21];
                        end
                    end

                    MQ_LOAD,MQ_STORE,MQ_MV: begin
                        Slsu_data_we_o = instr_MQ_i[7];
                        Slsu_l1b_mode_o = instr_MQ_i[8];
                        //Slsu_tcache_core_load_bank_num_o = instr_MQ_i[9];
                        Slsu_l1b_from_sc_or_noc_o = instr_MQ_i[9];
                        Slsu_data_sys_gap_o = instr_MQ_i[18:10];
                        Slsu_data_sub_len_o = MQ_cfifo_en_i ? MQ_cfifo_data_i[21:13] : Slsu_data_sub_len_q;
                        Slsu_data_addr_o = MQ_cfifo_en_i ? MQ_cfifo_data_i[12:0] : Slsu_data_addr_q;
                        Slsu_data_sys_len_o = instr_MQ_i[27:19];
                        Slsu_data_mv_last_dis_o = MQ_cfifo_en_i ? MQ_cfifo_data_i[22] : Slsu_data_mv_last_dis_q;
                        weight_update_req_o = MQ_disp_func_i[1:0]==2'b11 && Slsu_data_we_o==1'b0 && Slsu_l1b_mode_o==1'b1 && cubank_LB_mv_cub_dst_sel_i==2'b0; //mv_weight
                        Noc_core_rd_req_o = (MQ_disp_func_i[1:0]==2'b01);//load
                        Noc_core_wr_req_o = (MQ_disp_func_i[1:0]==2'b10);//store
                        MQ_noc_cmd_addr_o = Noc_core_wr_req_o ? 3'b1 : 3'b0;

                        MQ_req_type_o = Noc_core_wr_req_o ? NOC_REQ : SLSU_REQ;
                    end

                    //default:;
                endcase
            end
            else begin //noc or MQ_nop or Hid_load
                MQ_req_type_o = NOC_REQ;
                case(MQ_disp_func_i[1:0])
                    MQ_NOC_CFG: begin
                        MQ_noc_cfg_en_o = 1'b1;
                        Noc_cfg_addr_o = instr_MQ_i[30:24];
                        Noc_cfg_data_o = MQ_cfifo_en_i ? MQ_cfifo_data_i[12:0] : instr_MQ_i[20:8];
                    end
                    MQ_NOC: begin
                        MQ_noc_cmd_addr_o = instr_MQ_i[27:25];
                    end
                    MQ_NOP: begin
                        MQ_nop_en_o = 1'b1;
                        MQ_nop_cycle_num_o = instr_MQ_i[12:8];
                    end
                    MQ_HLOAD: begin
                        if(instr_MQ_i[9]) begin
                            MQ_req_type_o = HLSU_CHK_REQ;
                        end
                        else begin
                            MQ_req_type_o = HLSU_REQ;

                            Hlsu_data_we_o = instr_MQ_i[7];
                            Hlsu_l1b_mode_o = instr_MQ_i[8];
                            Hlsu_data_sys_gap_o = instr_MQ_i[18:10];
                            Hlsu_data_sub_len_o = MQ_cfifo_en_i ? MQ_cfifo_data_i[21:13] : Hlsu_data_sub_len_q;
                            Hlsu_data_addr_o = MQ_cfifo_en_i ? MQ_cfifo_data_i[12:0] : Hlsu_data_addr_q;
                            Hlsu_data_sys_len_o = instr_MQ_i[27:19];
                            
                            MQ_noc_cmd_addr_o = 3'b0;
                        end
                    end
                endcase
            end
        end
    end

    //MQ fifo info register
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            Slsu_data_addr_q <= 'b0;
            Slsu_data_sub_len_q <= 'b0;
            Slsu_data_mv_last_dis_q <= 1'b0;

            Hlsu_data_addr_q <= 'b0;
            Hlsu_data_sub_len_q <= 'b0;
        end
        else if(MQ_req_i & MQ_cfifo_en_i) begin
            if(MQ_disp_func_i[2]==1'b0 && MQ_disp_func_i[0]==1'b1) begin //load,mv
                    Slsu_data_addr_q <= MQ_cfifo_data_i[12:0];
                    Slsu_data_sub_len_q <= MQ_cfifo_data_i[21:13];
                    Slsu_data_mv_last_dis_q <= MQ_cfifo_data_i[22];
            end
            else if(MQ_disp_func_i[2:0]==3'b111) begin
                    Hlsu_data_addr_q <= MQ_cfifo_data_i[12:0];
                    Hlsu_data_sub_len_q <= MQ_cfifo_data_i[21:13];
            end
        end
    end




    genvar i;
    generate
    for(i=0;i<4;i=i+1) begin: VQ_DECODE
    always_comb begin
        VQ_cfg_en_o[i] = 1'b0;
        conv_mode_o[i] = 'b0; //00:norm conv 01:dw conv 10:rgba

        dwconv_cross_ram_from_left_o[i] = 'b0;
        dwconv_cross_ram_from_right_o[i] = 'b0;
        dwconv_right_padding_o[i] = 'b0;
        dwconv_left_padding_o[i] = 'b0;
        dwconv_bottom_padding_o[i] = 'b0;
        dwconv_top_padding_o[i] = 'b0;
        dwconv_trans_num_o[i] = 'b0;
        dwconv_run_cycle_num_o[i] = dwconv_run_cycle_num_q[i];
     
        conv3d_psum_end_index_o[i] = 'b0;
        conv3d_psum_start_index_o[i] = 'b0;
        conv3d_first_subch_flag_o[i] = conv3d_first_subch_flag_q[i];
        conv3d_result_output_flag_o[i] = 1'b0;
        conv3d_weight_16ch_sel_o[i] = 2'b0;
        //conv3d_run_cycle_num_sel[i] = 'b0;
        //conv3d_MQ_yield_flag_o[i] = 1'b0;

        Y_mode_cram_sel_o[i] = 'b0;

        conv3d_bcfmap_en_o[i] = 1'b0;
        conv3d_bcfmap_mode_o[i] = conv3d_bcfmap_mode_q[i];
        conv3d_bcfmap_len_o[i] = conv3d_bcfmap_32ch_len_q[i];
        conv3d_bcfmap_rgba_mode_o[i] = 1'b0;
        conv3d_bcfmap_rgba_stride_o[i] = 1'b0;
        conv3d_bcfmap_rgba_shift_o[i] = conv3d_bcfmap_rgba_shift_q[i];
        conv3d_bcfmap_hl_op_o[i] = conv3d_bcfmap_hl_op_q[i];
        conv3d_bcfmap_keep_2cycle_en_o[i] = 1'b0;
        conv3d_bcfmap_group_o[i] = 1'b0;
        conv3d_run_cycle_num_o[i] = conv3d_run_cycle_num_q[i];
        conv3d_bcfmap_pad0_he_sel_o[i] = conv3d_bcfmap_pad0_he_sel_q[i];
        conv3d_bcfmap_pad0_len_o[i] = conv3d_bcfmap_pad0_len_q[i];
        conv3d_bcfmap_tcache_stride_o[i] = 1'b0;
        conv3d_bcfmap_tcache_offset_o[i] = conv3d_bcfmap_tcache_offset_q[i];

        conv3d_bcfmap_elt_en_o[i] = 1'b0;
        conv3d_bcfmap_elt_mode_o[i] = 1'b0;
        conv3d_bcfmap_elt_pric_o[i] = 1'b0;
        conv3d_bcfmap_elt_bsel_o[i] = 1'b0;
        conv3d_bcfmap_elt_32ch_i16_o[i] = 1'b0;

        conv_psum_rd_en_o[i] = 'b0;
        //conv_psum_rd_mode_o[i] = 'b0;
        conv_psum_rd_num_o[i] = 'b0;
        conv_psum_rd_ch_sel_o[i] = 1'b0;
        conv_psum_rd_rgb_sel_o[i] = 1'b0;
        conv_psum_rd_run_cycle_num_o[i] = 'b0;
        conv_psum_rd_offset_o[i] = conv_psum_rd_offset_q[i];

        VQ_scache_wr_rd_type_o[i] = 1'b0;
        VQ_scache_we_o[i] = 1'b0;

        VQ_scache_wr_en_o[i] = 1'b0;
        VQ_scache_wr_addr_o[i] = VQ_scache_wr_addr_q[i];
        VQ_scache_wr_size_o[i] = 'b0;
        VQ_scache_wr_run_wait_type_o[i] = 'b0;
        VQ_scache_wr_run_cycle_num_o[i] = 'b0;                            

        VQ_scache_rd_en_o[i] = 1'b0;
        VQ_scache_rd_addr_o[i] = VQ_scache_rd_addr_q[i];
        VQ_scache_rd_size_o[i] = 'b0;
        VQ_scache_rd_sign_ext_o[i] = 1'b0;
        VQ_scache_rd_run_wait_type_o[i] = 'b0;
        VQ_scache_rd_run_cycle_num_o[i] = 'b0;

        conv_cfg_en_o[i] = 1'b0;
        conv_cfg_addr_o[i] = 'b0;
        conv_cfg_data_o[i] = 'b0;
        //alu_cfg_en_o =1'b0;
        
        VQ_cub_csr_access_o[i] = 1'b0;
        VQ_cub_csr_addr_o  [i] = 'b0;
        VQ_cub_csr_wdata_o [i] = 'b0;
        
        VQ_alu_event_call_o[i] =1'b0;
        VQ_alu_event_addr_o[i] = 'b0;

        VQ_nop_en_o[i] = 1'b0;
        VQ_nop_cycle_num_o[i] = 5'b0;

        Y_mode_pre_en_o[i] = 1'b0;
        Y_mode_pre_run_cycle_num_o[i] = 'b0;
        Y_mode_cram_sel_o[i] = 'b0;

        if(VQ_req_i[i]) begin
            case(VQ_disp_func_i[i][1:0])
                2'b00: begin //ALU CFG
                    case(instr_VQ_i[i][31:30])
                        2'b00: begin //VQ_cub_csrw
                            VQ_cub_csr_access_o[i] = 1'b1;
                            VQ_cub_csr_addr_o  [i] = instr_VQ_i[i][12:7];
                            VQ_cub_csr_wdata_o [i] = VQ_cfifo_en_i[i] ? VQ_cfifo_data_i[i][15:0] : instr_VQ_i[i][28:13];
                        end
                        //2'b01: begin //alu_event_call
                        //    VQ_alu_event_call_o[i] = 1'b1;
                        //    VQ_alu_event_addr_o[i] = instr_VQ_i[i][11:7];
                        //end
                        //default:;
                    endcase
                end

                2'b11: begin//ALU
                    case(instr_VQ_i[i][27:26])
                        2'b00: begin //alu_event_call
                            VQ_alu_event_call_o[i] = 1'b1; 
                            VQ_alu_event_addr_o[i] = instr_VQ_i[i][7+:IRAM_AWID];
                        end
                        2'b01: begin //VQ_scache_wr_en
                            VQ_scache_wr_en_o[i] = 1'b1;
                            VQ_scache_wr_addr_o[i] = VQ_cfifo_en_i[i] ? VQ_cfifo_data_i[i][8:0] : VQ_scache_wr_addr_q[i];
                            VQ_scache_wr_size_o[i] = instr_VQ_i[i][18:17];
                            VQ_scache_wr_run_wait_type_o[i] = instr_VQ_i[i][19];
                            VQ_scache_wr_run_cycle_num_o[i] = instr_VQ_i[i][16:7];
                            VQ_scache_wr_rd_type_o[i] = 1'b1;
                            VQ_scache_we_o[i] = 1'b1;
                        end
                        2'b10: begin //VQ_scache_rd_en
                            VQ_scache_rd_en_o[i] = 1'b1;
                            VQ_scache_rd_addr_o[i] = VQ_cfifo_en_i[i] ? VQ_cfifo_data_i[i][8:0] : VQ_scache_rd_addr_q[i];
                            VQ_scache_rd_size_o[i] = instr_VQ_i[i][18:17];
                            VQ_scache_rd_run_wait_type_o[i] = instr_VQ_i[i][19];
                            VQ_scache_rd_sign_ext_o[i] = instr_VQ_i[i][19];
                            VQ_scache_rd_run_cycle_num_o[i] = instr_VQ_i[i][16:7];
                            VQ_scache_wr_rd_type_o[i] = 1'b1;
                        end
                    endcase
                end
                2'b01: begin //VEC CFG
                    VQ_cfg_en_o[i] = 1'b1;
                    conv_cfg_en_o[i] = 1'b1;
                    conv_cfg_addr_o[i] = instr_VQ_i[i][30:29];
                    conv_cfg_data_o[i] = instr_VQ_i[i][28:7];
                end

                2'b10: begin //MAC
                    if(instr_VQ_i[i][27:25]==3'b000) begin //norm conv, need send fmap broadcast req to Slsu at the same time
                        conv_mode_o[i] = 2'b00;
                        conv3d_psum_end_index_o[i] = instr_VQ_i[i][11:7];
                        conv3d_psum_start_index_o[i] = instr_VQ_i[i][16:12];
                        conv3d_result_output_flag_o[i] = instr_VQ_i[i][22];
                        conv3d_weight_16ch_sel_o[i] = instr_VQ_i[i][24:23];
                        conv3d_bcfmap_rgba_mode_o[i] = instr_VQ_i[i][17];
                        conv3d_bcfmap_rgba_stride_o[i] = instr_VQ_i[i][18];
                        conv3d_bcfmap_tcache_stride_o[i] = instr_VQ_i[i][19];
                        conv3d_bcfmap_keep_2cycle_en_o[i] = instr_VQ_i[i][20];
                        conv3d_bcfmap_group_o[i] = instr_VQ_i[i][21];
                        conv3d_bcfmap_en_o[i] = 1'b1;
                        conv3d_bcfmap_mode_o[i] = VQ_cfifo_en_i[i] ? VQ_cfifo_data_i[i][0] : conv3d_bcfmap_mode_q[i];
                        conv3d_bcfmap_len_o[i] = VQ_cfifo_en_i[i] ? VQ_cfifo_data_i[i][6:1] : conv3d_bcfmap_32ch_len_q[i];
                        conv3d_bcfmap_hl_op_o[i] = VQ_cfifo_en_i[i] ? VQ_cfifo_data_i[i][22] : conv3d_bcfmap_hl_op_q[i];
                        conv3d_bcfmap_tcache_offset_o[i] = VQ_cfifo_en_i[i] ? VQ_cfifo_data_i[i][11:7] : conv3d_bcfmap_tcache_offset_q[i];
                        conv3d_bcfmap_pad0_len_o[i] = VQ_cfifo_en_i[i] ? VQ_cfifo_data_i[i][15:12] : conv3d_bcfmap_pad0_len_q[i];
                        conv3d_bcfmap_pad0_he_sel_o[i] = VQ_cfifo_en_i[i] ? VQ_cfifo_data_i[i][16] : conv3d_bcfmap_pad0_he_sel_q[i];
                        conv3d_bcfmap_rgba_shift_o[i] = VQ_cfifo_en_i[i] ? VQ_cfifo_data_i[i][21:17] : conv3d_bcfmap_rgba_shift_q[i];
                        conv3d_first_subch_flag_o[i] = VQ_cfifo_en_i[i] ? VQ_cfifo_data_i[i][23] : conv3d_first_subch_flag_q[i];
                        conv3d_run_cycle_num_o[i] = VQ_cfifo_en_i[i] ? VQ_cfifo_data_i[i][31:24] : conv3d_run_cycle_num_q[i];
                        //conv3d_MQ_yield_flag_o[i] = 1'b1;
                    end
                    else if(instr_VQ_i[i][27:25]==3'b001) begin //dw conv
                        conv_mode_o[i] = 2'b01; 
                        dwconv_cross_ram_from_left_o[i] = instr_VQ_i[i][8];
                        dwconv_cross_ram_from_right_o[i] = instr_VQ_i[i][7];
                        dwconv_right_padding_o[i] = instr_VQ_i[i][9];
                        dwconv_left_padding_o[i] = instr_VQ_i[i][10];
                        dwconv_bottom_padding_o[i] = instr_VQ_i[i][11];
                        dwconv_top_padding_o[i] = instr_VQ_i[i][12];
                        dwconv_trans_num_o[i] = instr_VQ_i[i][16:13];
                        dwconv_run_cycle_num_o[i] = VQ_cfifo_en_i[i] ? VQ_cfifo_data_i[i][6:0] : dwconv_run_cycle_num_q[i];
                        VQ_scache_wr_en_o[i] = 1'b1;
                        VQ_scache_wr_addr_o[i] = VQ_cfifo_en_i[i] ? VQ_cfifo_data_i[i][15:7] : VQ_scache_wr_addr_q[i];
                        VQ_scache_wr_size_o[i] = instr_VQ_i[i][18:17];
                    end
                    else if(instr_VQ_i[i][27:25]==3'b010) begin //eltwise
                        conv_mode_o[i] = 2'b10;
                        VQ_scache_rd_en_o[i] = instr_VQ_i[i][24];
                        VQ_scache_rd_addr_o[i] = VQ_cfifo_en_i[i] ? VQ_cfifo_data_i[i][31:23] : VQ_scache_rd_addr_q[i];
                        VQ_scache_rd_size_o[i] = instr_VQ_i[i][14:13];
                        VQ_scache_rd_sign_ext_o[i] = instr_VQ_i[i][15];
                        VQ_scache_rd_run_cycle_num_o[i] = {{4'b0},instr_VQ_i[i][12:7]};

                        conv3d_bcfmap_en_o[i] = 1'b1;
                        conv3d_bcfmap_rgba_mode_o[i] = instr_VQ_i[i][16];
                        conv3d_bcfmap_rgba_stride_o[i] = instr_VQ_i[i][17];
                        conv3d_bcfmap_tcache_stride_o[i] = instr_VQ_i[i][18];
                        conv3d_bcfmap_keep_2cycle_en_o[i] = instr_VQ_i[i][19];
                        conv3d_bcfmap_mode_o[i] = VQ_cfifo_en_i[i] ? VQ_cfifo_data_i[i][0] : conv3d_bcfmap_mode_q[i];
                        conv3d_bcfmap_len_o[i] = VQ_cfifo_en_i[i] ? VQ_cfifo_data_i[i][6:1] : conv3d_bcfmap_32ch_len_q[i];
                        conv3d_bcfmap_hl_op_o[i] = VQ_cfifo_en_i[i] ? VQ_cfifo_data_i[i][22] : conv3d_bcfmap_hl_op_q[i];
                        conv3d_bcfmap_tcache_offset_o[i] = VQ_cfifo_en_i[i] ? VQ_cfifo_data_i[i][11:7] : conv3d_bcfmap_tcache_offset_q[i];
                        conv3d_bcfmap_pad0_len_o[i] = VQ_cfifo_en_i[i] ? VQ_cfifo_data_i[i][15:12] : conv3d_bcfmap_pad0_len_q[i];
                        conv3d_bcfmap_pad0_he_sel_o[i] = VQ_cfifo_en_i[i] ? VQ_cfifo_data_i[i][16] : conv3d_bcfmap_pad0_he_sel_q[i];
                        conv3d_bcfmap_rgba_shift_o[i] = VQ_cfifo_en_i[i] ? VQ_cfifo_data_i[i][21:17] : conv3d_bcfmap_rgba_shift_q[i];

                        conv3d_bcfmap_elt_en_o[i] = 1'b1;
                        conv3d_bcfmap_elt_mode_o[i] = instr_VQ_i[i][20];
                        conv3d_bcfmap_elt_pric_o[i] = instr_VQ_i[i][21];
                        conv3d_bcfmap_elt_bsel_o[i] = instr_VQ_i[i][22];
                        conv3d_bcfmap_elt_32ch_i16_o[i] = instr_VQ_i[i][23];
                    end
                    else if(instr_VQ_i[i][27:25]==3'b011) begin //psum_rd
                        conv_psum_rd_en_o[i] = 1'b1;
                        //conv_psum_rd_mode_o[i] = instr_VQ_i[i][13:12]; //0:dwconv 1:conv3d 2:alu
                        conv_psum_rd_num_o[i] = instr_VQ_i[i][11:7];
                        conv_psum_rd_offset_o[i] = VQ_cfifo_en_i[i] ? VQ_cfifo_data_i[i][13:9] : conv_psum_rd_offset_q[i];
                        conv_psum_rd_ch_sel_o[i] = instr_VQ_i[i][21];
                        conv_psum_rd_rgb_sel_o[i] = instr_VQ_i[i][20];
                        conv_psum_rd_run_cycle_num_o[i] = instr_VQ_i[i][17:12];
                        VQ_scache_wr_en_o[i] = ~instr_VQ_i[i][24];
                        VQ_scache_wr_addr_o[i] = VQ_cfifo_en_i[i] ? VQ_cfifo_data_i[i][8:0] : VQ_scache_wr_addr_q[i];
                        VQ_scache_wr_size_o[i] = instr_VQ_i[i][23:22];
                    end
                    else if(instr_VQ_i[i][27:25]==3'b100) begin //NOP
                        VQ_nop_en_o[i] = 1'b1;
                        VQ_nop_cycle_num_o[i] = instr_VQ_i[i][12:8];
                    end
                    else if(instr_VQ_i[i][27:25]==3'b101) begin //Y_mode_pre
                        Y_mode_cram_sel_o[i] = instr_VQ_i[i][7];
                        Y_mode_pre_en_o[i] = 1'b1;
                        Y_mode_pre_run_cycle_num_o[i] = instr_VQ_i[i][16:12];
                        conv3d_bcfmap_en_o[i] = 1'b1;
                        conv3d_bcfmap_rgba_mode_o[i] = instr_VQ_i[i][8];
                        conv3d_bcfmap_rgba_stride_o[i] = instr_VQ_i[i][9];
                        conv3d_bcfmap_tcache_stride_o[i] = instr_VQ_i[i][10];
                        conv3d_bcfmap_keep_2cycle_en_o[i] = instr_VQ_i[i][11];
                        conv3d_bcfmap_group_o[i] = instr_VQ_i[i][17];
                        conv3d_bcfmap_mode_o[i] = VQ_cfifo_en_i[i] ? VQ_cfifo_data_i[i][0] : conv3d_bcfmap_mode_q[i];
                        conv3d_bcfmap_len_o[i] = VQ_cfifo_en_i[i] ? VQ_cfifo_data_i[i][6:1] : conv3d_bcfmap_32ch_len_q[i];
                        conv3d_bcfmap_hl_op_o[i] = VQ_cfifo_en_i[i] ? VQ_cfifo_data_i[i][22] : conv3d_bcfmap_hl_op_q[i];
                        conv3d_bcfmap_tcache_offset_o[i] = VQ_cfifo_en_i[i] ? VQ_cfifo_data_i[i][11:7] : conv3d_bcfmap_tcache_offset_q[i];
                        conv3d_bcfmap_pad0_len_o[i] = VQ_cfifo_en_i[i] ? VQ_cfifo_data_i[i][15:12] : conv3d_bcfmap_pad0_len_q[i];
                        conv3d_bcfmap_pad0_he_sel_o[i] = VQ_cfifo_en_i[i] ? VQ_cfifo_data_i[i][16] : conv3d_bcfmap_pad0_he_sel_q[i];
                        conv3d_bcfmap_rgba_shift_o[i] = VQ_cfifo_en_i[i] ? VQ_cfifo_data_i[i][21:17] : conv3d_bcfmap_rgba_shift_q[i];
                        end
                end
 
                //default:;
            endcase
        end
    end


    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            conv3d_bcfmap_mode_q[i] <='b0;
            conv3d_bcfmap_32ch_len_q[i] <='b0;
            conv3d_bcfmap_rgba_shift_q[i] <='b0;
            conv3d_bcfmap_hl_op_q[i] <='b0;
            conv3d_bcfmap_pad0_he_sel_q[i] <= 'b0;
            conv3d_bcfmap_pad0_len_q[i] <= 'b0;
            conv3d_bcfmap_tcache_offset_q[i] <= 'b0;
            conv3d_first_subch_flag_q[i] <= 'b0;

            conv3d_run_cycle_num_q[i] <='b0;
            dwconv_run_cycle_num_q[i] <='b0;
            VQ_scache_wr_addr_q[i] <='b0;
            VQ_scache_rd_addr_q[i] <='b0;
            conv_psum_rd_offset_q[i] <='b0;
        end
        else if(VQ_req_i[i] & VQ_cfifo_en_i[i]) begin
            case(VQ_disp_func_i[i][1:0])
                2'b10: begin
                    if(conv_psum_rd_en_o[i]) begin //psum rd
                        VQ_scache_wr_addr_q[i] <= VQ_scache_wr_en_o[i] ? VQ_cfifo_data_i[i][8:0] : VQ_scache_wr_addr_q[i];
                        conv_psum_rd_offset_q[i] <= VQ_cfifo_data_i[i][13:9];

                    end
                    else if(Y_mode_pre_en_o[i]) begin
                        conv3d_bcfmap_mode_q[i] <= VQ_cfifo_data_i[i][0];
                        conv3d_bcfmap_32ch_len_q[i] <= VQ_cfifo_data_i[i][6:1];
                        conv3d_bcfmap_hl_op_q[i] <= VQ_cfifo_data_i[i][22];
                        conv3d_bcfmap_tcache_offset_q[i] <= VQ_cfifo_data_i[i][11:7];
                        conv3d_bcfmap_pad0_len_q[i] <= VQ_cfifo_data_i[i][15:12];
                        conv3d_bcfmap_pad0_he_sel_q[i] <= VQ_cfifo_data_i[i][16];
                        conv3d_bcfmap_rgba_shift_q[i] <= VQ_cfifo_data_i[i][21:17];
                    end
                    else if(conv_mode_o[i]==2'b00) begin //norm conv
                        conv3d_bcfmap_mode_q[i] <= VQ_cfifo_data_i[i][0];
                        conv3d_bcfmap_32ch_len_q[i] <= VQ_cfifo_data_i[i][6:1];
                        conv3d_bcfmap_hl_op_q[i] <= VQ_cfifo_data_i[i][22];
                        conv3d_bcfmap_tcache_offset_q[i] <= VQ_cfifo_data_i[i][11:7];
                        conv3d_bcfmap_pad0_len_q[i] <= VQ_cfifo_data_i[i][15:12];
                        conv3d_bcfmap_pad0_he_sel_q[i] <= VQ_cfifo_data_i[i][16];
                        conv3d_bcfmap_rgba_shift_q[i] <= VQ_cfifo_data_i[i][21:17];
                        conv3d_first_subch_flag_q[i] <= VQ_cfifo_data_i[i][23];

                        conv3d_run_cycle_num_q[i] <= VQ_cfifo_data_i[i][31:24];
                    end
                    else if(conv_mode_o[i]==2'b01) begin //dwconv
                        dwconv_run_cycle_num_q[i] <= VQ_cfifo_data_i[i][6:0];
                        VQ_scache_wr_addr_q[i] <= VQ_cfifo_data_i[i][15:7];
                    end
                    else if(conv_mode_o[i]==2'b10) begin //eltwise
                        VQ_scache_rd_addr_q[i] <= VQ_cfifo_data_i[i][31:23];

                        conv3d_bcfmap_mode_q[i] <= VQ_cfifo_data_i[i][0];
                        conv3d_bcfmap_32ch_len_q[i] <= VQ_cfifo_data_i[i][6:1];
                        conv3d_bcfmap_hl_op_q[i] <= VQ_cfifo_data_i[i][22];
                        conv3d_bcfmap_tcache_offset_q[i] <= VQ_cfifo_data_i[i][11:7];
                        conv3d_bcfmap_pad0_len_q[i] <= VQ_cfifo_data_i[i][15:12];
                        conv3d_bcfmap_pad0_he_sel_q[i] <= VQ_cfifo_data_i[i][16];
                        conv3d_bcfmap_rgba_shift_q[i] <= VQ_cfifo_data_i[i][21:17];
                    end
                end
                2'b11: begin //scache_wr/scache_rd
                    if(instr_VQ_i[i][27]==1'b0)
                        VQ_scache_wr_addr_q[i] <= VQ_cfifo_data_i[i][8:0];
                    else
                        VQ_scache_rd_addr_q[i] <= VQ_cfifo_data_i[i][8:0];
                end
            endcase
        end
    end

    end
    endgenerate


    always_comb begin
        Sfu_len_o = 6'b0;
        Sfu_mode_o = 4'b0;

        if(SQ_req_i) begin
            if(SQ_disp_func_i==1'b0) begin //sfu req
                Sfu_len_o = instr_SQ_i[12:7];
                Sfu_mode_o = instr_SQ_i[16:13];
            end
        end
    end
endmodule
