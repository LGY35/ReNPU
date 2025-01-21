/*
Design Name     : Accelerator Manage Unit
Data            : 2024/3/2           
Description     : 
*/

module mu_top #(
    parameter BANK_NUM = 32
)(
    input                               clk,
    input                               rst_n,
   
    //from riscv_core decoder
    input                               npu_req_i,
    input [31:0]                        instr_npu_i,

    //output                              mu_ready_o,

    //from/to Cons FIFO
    output                              MQ_cons_fifo_pop_o,
    input [31:0]                        MQ_cons_fifo_data_i,
    input                               MQ_cons_fifo_empty_i,

    output                              VQ_cons_fifo_pop_o,
    input [31:0]                        VQ_cons_fifo_data_i,
    input                               VQ_cons_fifo_empty_i,

    output                              SQ_cons_fifo_pop_o,
    input [31:0]                        SQ_cons_fifo_data_i,
    input                               SQ_cons_fifo_empty_i,
    
    //Mem Queue
    input                               is_MQ_insn_i,
    output                              MQ_ready_o,
    //VU Queue
    input                               is_VQ_insn_i,
    output                              VQ_ready_o,
    //SU Queue
    input                               is_SQ_insn_i,
    output                              SQ_ready_o,

    input                               is_Cub_alu_insn_i,
    output                              Cub_alu_ready_o,

    input                               MQ_clear_i,
    input                               VQ_clear_i,
    input                               SQ_clear_i,    

    //to Sys LSU
    output logic                        Slsu_data_req_o,
    input                               Slsu_data_gnt_i,
    input                               Slsu_data_ok_i, //system lsu excute done

    output logic                        Slsu_data_we_o,
    output logic                        Slsu_l1b_mode_o, //1:norm 0:cache
    output logic                        Slsu_tcache_core_load_bank_num_o,
    output logic [8:0]                  Slsu_data_sys_gap_o,
    output logic [8:0]                  Slsu_data_sub_len_o,
    output logic [12:0]                 Slsu_data_addr_o,
    output logic [8:0]                  Slsu_data_sys_len_o,
    output logic                        Slsu_data_mv_last_dis_o,

    output logic                        Slsu_cfg_vld_o,
    output logic [1:0]                  Slsu_cfg_addr_o,
    output logic                        Slsu_l1b_gpu_mode_o, //MQ CFG0
    output logic [1:0]                  Slsu_l1b_op_wr_hl_mask_o,
    output logic [1:0]                  Slsu_mv_cub_dst_sel_o,
    output logic                        Slsu_tcache_trans_prici_o, //0:int8 1:int16
    output logic                        Slsu_tcache_trans_swbank_o,
    output logic                        Slsu_l1b_norm_paral_mode_o,
    output logic [2:0]                  Slsu_tcache_mode_o, //00:DFIFO_MODE 01:SFIFO_MODE 10:TRANS_MODE 11:DWCONV_MODE
    output logic [8:0]                  Slsu_cache_one_ram_qw_base_addr_o,
    output logic [8:0]                  Slsu_data_sub_gap_o,
    output logic [4:0]                  Slsu_data_sys_gap_ext_o,
    output logic                        Slsu_iob_pric_o,
    output logic                        Slsu_iob_l2c_in_cfg_o,
    output logic                        Slsu_tcache_mvfmap_stride_o,
    output logic [4:0]                  Slsu_tcache_mvfmap_offset_o,
    input  [1:0]                        cubank_LB_mv_cub_dst_sel_i,

    //Hide load
    output logic                        Hlsu_data_req_o,
    input                               Hlsu_data_gnt_i,
    
    output logic                        Hlsu_data_we_o,
    output logic                        Hlsu_l1b_mode_o,
    output logic [8:0]                  Hlsu_data_sys_gap_o,
    output logic [8:0]                  Hlsu_data_sub_len_o,
    output logic [12:0]                 Hlsu_data_addr_o,
    output logic [8:0]                  Hlsu_data_sys_len_o,

    output logic [8:0]                  Hlsu_data_sub_gap_o, //MQ CFG2
    output logic [4:0]                  Hlsu_data_sys_gap_ext_o,
    output logic                        Hlsu_l1b_norm_paral_mode_o,

    output logic                        Hlsu_chk_done_req_o,
    input                               Hlsu_chk_done_gnt_i,

    //to CU bank
    output logic [BANK_NUM-1:0]                     conv_req_o,
    input        [BANK_NUM-1:0]                     conv_gnt_i,
    input        [BANK_NUM-1:0]                     conv_done_i,
    output logic [BANK_NUM-1:0][1:0]                conv_mode_o, //00:norm conv 01:dw conv 10:rgba
    output logic [BANK_NUM-1:0]                     conv_cfg_vld_o,
    output logic [BANK_NUM-1:0][1:0]                conv_cfg_addr_o,
    output logic [BANK_NUM-1:0][22-1:0]             conv_cfg_data_o,    
    
    output logic [BANK_NUM-1:0]                     dwconv_cross_ram_from_left_o, 
    output logic [BANK_NUM-1:0]                     dwconv_cross_ram_from_right_o,    
    output logic [BANK_NUM-1:0]                     dwconv_right_padding_o,
    output logic [BANK_NUM-1:0]                     dwconv_left_padding_o,
    output logic [BANK_NUM-1:0]                     dwconv_bottom_padding_o,
    output logic [BANK_NUM-1:0]                     dwconv_top_padding_o,
    output logic [BANK_NUM-1:0][3:0]                dwconv_trans_num_o,

    output logic [BANK_NUM-1:0][4:0]                conv3d_psum_end_index_o,
    output logic [BANK_NUM-1:0][4:0]                conv3d_psum_start_index_o,
    output logic [BANK_NUM-1:0]                     conv3d_first_subch_flag_o,
    output logic [BANK_NUM-1:0]                     conv3d_result_output_flag_o,
    output logic [BANK_NUM-1:0][1:0]                conv3d_weight_16ch_sel_o,

    output logic [BANK_NUM-1:0]                     Y_mode_pre_en_o,
    output logic [BANK_NUM-1:0]                     Y_mode_cram_sel_o,

    output logic [BANK_NUM-1:0]                     conv_psum_rd_req_o,
    output logic [BANK_NUM-1:0][4:0]                conv_psum_rd_num_o,
    output logic [BANK_NUM-1:0]                     conv_psum_rd_ch_sel_o,
    output logic [BANK_NUM-1:0]                     conv_psum_rd_rgb_sel_o,
    output logic [BANK_NUM-1:0][4:0]                 conv_psum_rd_offset_o,

    output logic [BANK_NUM-1:0]                     VQ_scache_wr_en_o,
    output logic [BANK_NUM-1:0][8:0]                VQ_scache_wr_addr_o,
    output logic [BANK_NUM-1:0][1:0]                VQ_scache_wr_size_o,

    output logic [BANK_NUM-1:0]                     VQ_scache_rd_en_o,
    output logic [BANK_NUM-1:0][8:0]                VQ_scache_rd_addr_o,
    output logic [BANK_NUM-1:0][1:0]                VQ_scache_rd_size_o,
    output logic [BANK_NUM-1:0]                     VQ_scache_rd_sign_ext_o,

    output logic [BANK_NUM-1:0]                     VQ_cub_csr_access_o,
    output logic [BANK_NUM-1:0][5:0]                VQ_cub_csr_addr_o,
    output logic [BANK_NUM-1:0][15:0]               VQ_cub_csr_wdata_o,

    output logic [BANK_NUM-1:0][31:0]               Cub_alu_instr_o,
    output logic [BANK_NUM-1:0]                     Cub_alu_instr_valid_o,
    output logic [BANK_NUM-1:0]                     deassert_we_o,

    output logic                                    ALU_Cfifo_pop_o,
    input [15:0]                                    ALU_Cfifo_data_i,
    input                                           ALU_Cfifo_empty_i,

    //to Sys LSU
    output logic                        conv3d_bcfmap_req_o,
    input                               conv3d_bcfmap_gnt_i,
    input                               conv3d_bcfmap_ok_i,

    output logic                        conv3d_bcfmap_mode_o, //1:double bank diff fmap 0:single bank same fmap 
    output logic [5:0]                  conv3d_bcfmap_len_o, //32ch data len <= 8 
    output logic                        conv3d_bcfmap_rgba_mode_o, //even start 16ch mask  
    output logic                        conv3d_bcfmap_rgba_stride_o, //odd last 16ch mask    
    output logic [4:0]                  conv3d_bcfmap_rgba_shift_o,     
    output logic                        conv3d_bcfmap_hl_op_o, //1:high 16ch 0:low 16ch
    output logic                        conv3d_bcfmap_keep_2cycle_en_o, //1:high 16ch 0:low 16ch
    output logic                        conv3d_bcfmap_group_o,
    output logic                        conv3d_bcfmap_pad0_he_sel_o,
    output logic [3:0]                  conv3d_bcfmap_pad0_len_o,
    output logic                        conv3d_bcfmap_tcache_stride_o,
    output logic [4:0]                  conv3d_bcfmap_tcache_offset_o,

    output logic                        conv3d_bcfmap_elt_mode_o,
    output logic                        conv3d_bcfmap_elt_pric_o,
    output logic                        conv3d_bcfmap_elt_bsel_o, //0: 0-15, 1: 16-31
    output logic                        conv3d_bcfmap_elt_32ch_i16_o,

    //to NOC
    output logic                        Noc_cmd_req_o,
    output logic [2:0]                  Noc_cmd_addr_o,
    input                               Noc_cmd_gnt_i,
    input                               Noc_cmd_ok_i,
    
    output logic                        Noc_cfg_vld_o,
    output logic [6:0]                  Noc_cfg_addr_o,
    output logic [12:0]                 Noc_cfg_data_o,

    input  [BANK_NUM-1:0]               scache_cflow_data_rd_st_rdy_i,
    input                               CU_bank_scache_dout_en_i,
    input                               CU_bank_data_out_ready_i,
   
    //to SFU
    output logic                        Sfu_req_o,
    input                               Sfu_gnt_i,
    output logic [5:0]                  Sfu_len_o,
    output logic [3:0]                  Sfu_mode_o
);

    localparam   MQ_DEPTH = 8;
    localparam   VQ_DEPTH = 8;
    localparam   SQ_DEPTH = 4;

    localparam   INSN_WIDTH = 32;
    localparam   IRAM_AWID = 8; //32 -> 64 -> 128 -> 256
    localparam   IRAM_FILL_AWID = 15;
    localparam   LOOP_NUM = 4;
    
    //npu insn
    logic               MQ_disp_ready,VQ_disp_ready,SQ_disp_ready;
    logic               MQ_disp_req;
    logic [3:0]         VQ_disp_req;
    logic               SQ_disp_req;
    logic               MQ_disp_cfifo_en;
    logic [3:0]         VQ_disp_cfifo_en;
    logic               SQ_disp_cfifo_en;
    logic [31:0]        MQ_disp_cfifo_data;
    logic [3:0][31:0]   VQ_disp_cfifo_data;
    logic [31:0]        SQ_disp_cfifo_data;
    logic [31:7]        MQ_disp_instr_dec;
    logic [3:0][31:7]   VQ_disp_instr_dec;
    logic [31:7]        SQ_disp_instr_dec;
    logic [2:0]         MQ_disp_func;
    logic [3:0][1:0]    VQ_disp_func;
    logic               SQ_disp_func;

    //gpu insn (Cub alu)
    logic [IRAM_AWID-1:0]           Cub_alu_insn_fill_addr;
    logic [31:0]                    Cub_alu_insn;
    logic                           Cub_alu_insn_fill_state;
    logic                           Cub_alu_insn_fill_stall;
    logic                           Cub_alu_fetch_req;
    logic [IRAM_AWID-1:0]           Cub_alu_boot_addr;
    logic                           Cub_alu_fetch_end;

    logic                           cub_nop_state;
    
    logic [BANK_NUM/2-1:0]          Cub_alu_mask;
    logic                           Cub_alu_mask_update;
    logic                           Cub_alu_mask_sel;

    logic [BANK_NUM-1:0]            VQ_disp_cubank_mask;

    logic                           fetch_req;
    logic [0:0]                     pc_mux;
    logic                           pc_set;
    logic [31:0]                    fetch_instr;
    logic                           fetch_valid;
    logic [IRAM_FILL_AWID-1:0]      pc_if;
    logic [IRAM_FILL_AWID-1:0]      pc_id;
    logic                           id_ready;
    
    logic [LOOP_NUM-1:0][31:0]      loop_start;
    logic [LOOP_NUM-1:0][31:0]      loop_end;
    logic [LOOP_NUM-1:0][31:0]      loop_cnt;
    logic [LOOP_NUM-1:0]            loop_cnt_dec;
    logic                           is_loop_id;

    logic                           VQ_alu_event_call;
    logic [IRAM_AWID-1:0]           VQ_alu_event_addr;
    logic                           VQ_alu_event_finish;

    //pipe
    logic               MQ_disp_req_pipe,SQ_disp_req_pipe;
    logic [3:0]         VQ_disp_req_pipe;
    logic               MQ_disp_cfifo_en_pipe,SQ_disp_cfifo_en_pipe;
    logic [3:0]         VQ_disp_cfifo_en_pipe;
    logic [31:0]        MQ_disp_cfifo_data_pipe,SQ_disp_cfifo_data_pipe;
    logic [3:0][31:0]   VQ_disp_cfifo_data_pipe;
    logic [31:7]        MQ_disp_instr_dec_pipe,SQ_disp_instr_dec_pipe;
    logic [3:0][31:7]   VQ_disp_instr_dec_pipe;
    logic [2:0]         MQ_disp_func_pipe;
    logic [3:0][1:0]    VQ_disp_func_pipe;
    logic [1:0]         SQ_disp_func_pipe;


    logic                       Cub_alu_instr_req;
    logic                       Cub_alu_instr_gnt;
    logic [IRAM_AWID-1:0]       Cub_alu_instr_addr;
    logic [INSN_WIDTH-1:0]      Cub_alu_instr_rdata;
    logic                       Cub_alu_instr_rvalid;    

    logic [IRAM_AWID-1:0]       Cub_alu_fetch_req_addr; //to sequence ctrl for fetch_ready
    //--------------------------------------------------------
    //  MU sequence ctrl
    //--------------------------------------------------------
    accel_sequence_ctrl #(
        .MQ_DEPTH       (MQ_DEPTH),
        .VQ_DEPTH       (VQ_DEPTH),
        .SQ_DEPTH       (SQ_DEPTH),
        .IRAM_AWID      (IRAM_AWID),
        .IRAM_FILL_AWID (IRAM_FILL_AWID),
        .BANK_NUM       (BANK_NUM)
    )
    U_accel_sequence_ctrl
    (
        .clk(clk),
        .rst_n(rst_n),
        
        .npu_req_i(npu_req_i),
        .instr_npu_i(instr_npu_i),
        
        //.Cub_alu_insn_fill_en_o(Cub_alu_insn_fill_en),
        //.Cub_alu_insn_fill_num_o(Cub_alu_insn_fill_num),
        .Cub_alu_insn_fill_state_o(Cub_alu_insn_fill_state),
        .Cub_alu_insn_fill_stall_o(Cub_alu_insn_fill_stall),
        .Cub_alu_insn_fill_addr_o(Cub_alu_insn_fill_addr),
        .Cub_alu_insn_o(Cub_alu_insn),

        .VQ_alu_event_call_i(VQ_alu_event_call),
        .VQ_alu_event_addr_i(VQ_alu_event_addr),
        .VQ_alu_event_finish_o(VQ_alu_event_finish),

        .Cub_alu_fetch_req_o(Cub_alu_fetch_req),
        .Cub_alu_boot_addr_o(Cub_alu_boot_addr),
        .Cub_alu_fetch_end_i(Cub_alu_fetch_end),
        .Cub_alu_fetch_req_addr_i(Cub_alu_fetch_req_addr),  //for fetch_ready
        

        .Cub_alu_mask_o(Cub_alu_mask),
        .Cub_alu_mask_update_o(Cub_alu_mask_update),
        .Cub_alu_mask_sel_o(Cub_alu_mask_sel),

        .VQ_disp_cubank_mask_o(VQ_disp_cubank_mask),

        .is_MQ_insn_i(is_MQ_insn_i),
        .is_VQ_insn_i(is_VQ_insn_i),
        .is_SQ_insn_i(is_SQ_insn_i),
        .is_Cub_alu_insn_i(is_Cub_alu_insn_i),
        
        .MQ_ready_o(MQ_ready_o),
        .VQ_ready_o(VQ_ready_o),
        .SQ_ready_o(SQ_ready_o),
        .Cub_alu_ready_o(Cub_alu_ready_o),
        
        .MQ_Cfifo_pop_o(MQ_cons_fifo_pop_o),
        .MQ_Cfifo_data_i(MQ_cons_fifo_data_i),
        .MQ_Cfifo_empty_i(MQ_cons_fifo_empty_i),
        
        .VQ_Cfifo_pop_o(VQ_cons_fifo_pop_o),
        .VQ_Cfifo_data_i(VQ_cons_fifo_data_i),
        .VQ_Cfifo_empty_i(VQ_cons_fifo_empty_i),
        
        .SQ_Cfifo_pop_o(SQ_cons_fifo_pop_o),
        .SQ_Cfifo_data_i(SQ_cons_fifo_data_i),
        .SQ_Cfifo_empty_i(SQ_cons_fifo_empty_i),
        
        .MQ_disp_ready_i(MQ_disp_ready),
        .VQ_disp_ready_i(VQ_disp_ready),
        .SQ_disp_ready_i(SQ_disp_ready),
       
        //.MQ_disp_done_i(MQ_disp_done),
        //.MQ_disp_cfg_done_i(MQ_disp_cfg_done),
        //.VQ_disp_done_i(VQ_disp_done),
        //.VQ_disp_cfg_done_i(VQ_disp_cfg_done[0]),

        .MQ_disp_req_o(MQ_disp_req),
        .MQ_disp_cfifo_en_o(MQ_disp_cfifo_en),
        .MQ_disp_cfifo_data_o(MQ_disp_cfifo_data),
        
        .VQ_disp_req_o(VQ_disp_req),
        .VQ_disp_cfifo_en_o(VQ_disp_cfifo_en),
        .VQ_disp_cfifo_data_o(VQ_disp_cfifo_data),
        
        .SQ_disp_req_o(SQ_disp_req),
        .SQ_disp_cfifo_en_o(SQ_disp_cfifo_en),
        .SQ_disp_cfifo_data_o(SQ_disp_cfifo_data),
        
        .MQ_disp_instr_dec_o(MQ_disp_instr_dec),
        .VQ_disp_instr_dec_o(VQ_disp_instr_dec),
        .SQ_disp_instr_dec_o(SQ_disp_instr_dec),
        
        .MQ_disp_func_o(MQ_disp_func),
        .VQ_disp_func_o(VQ_disp_func),
        .SQ_disp_func_o(SQ_disp_func),

        .MQ_clear_i(MQ_clear_i),
        .VQ_clear_i(VQ_clear_i),
        .SQ_clear_i(SQ_clear_i)     
    );

/*
    accel_dispatch_pipe4_unit U_accel_dispatch_pipe4_unit(
        .clk(clk),
        .rst_n(rst_n),
        
        .MQ_disp_req_i(MQ_disp_req),
        .MQ_disp_instr_i(MQ_disp_instr_dec),
        .MQ_cfifo_en_i(MQ_disp_cfifo_en),
        .MQ_cfifo_data_i(MQ_disp_cfifo_data),
        .MQ_disp_func_i(MQ_disp_func),

        .VQ_disp_req_i(VQ_disp_req),
        .VQ_disp_instr_i(VQ_disp_instr_dec),
        .VQ_cfifo_en_i(VQ_disp_cfifo_en),
        .VQ_cfifo_data_i(VQ_disp_cfifo_data),
        .VQ_disp_func_i(VQ_disp_func),

        .SQ_disp_req_i(SQ_disp_req),
        .SQ_disp_func_i(SQ_disp_func),

        .MQ_disp_req_o(MQ_disp_req_pipe),
        .MQ_disp_instr_o(MQ_disp_instr_dec_pipe),
        .MQ_cfifo_en_o(MQ_disp_cfifo_en_pipe),
        .MQ_cfifo_data_o(MQ_disp_cfifo_data_pipe),
        .MQ_disp_func_o(MQ_disp_func_pipe),

        .VQ_disp_req_o(VQ_disp_req_pipe),
        .VQ_disp_instr_o(VQ_disp_instr_dec_pipe),
        .VQ_cfifo_en_o(VQ_disp_cfifo_en_pipe),
        .VQ_cfifo_data_o(VQ_disp_cfifo_data_pipe),
        .VQ_disp_func_o(VQ_disp_func_pipe),

        .SQ_disp_req_o(SQ_disp_req_pipe),
        .SQ_disp_func_o(SQ_disp_func_pipe)
    );
*/

    //dispatch to cu_bank
    logic [3:0]                         conv_req;
    logic [3:0][1:0]                    conv_mode; 
    logic [3:0]                         conv_cfg_vld;
    logic [3:0][1:0]                    conv_cfg_addr;
    logic [3:0][22-1:0]                 conv_cfg_data;    
    
    logic [3:0]                         dwconv_cross_ram_from_left; 
    logic [3:0]                         dwconv_cross_ram_from_right;    
    logic [3:0]                         dwconv_right_padding;
    logic [3:0]                         dwconv_left_padding;
    logic [3:0]                         dwconv_bottom_padding;
    logic [3:0]                         dwconv_top_padding;
    logic [3:0][3:0]                    dwconv_trans_num;

    logic [3:0][4:0]                    conv3d_psum_end_index;
    logic [3:0][4:0]                    conv3d_psum_start_index;
    logic [3:0]                         conv3d_first_subch_flag;
    logic [3:0]                         conv3d_result_output_flag;
    logic [3:0][1:0]                    conv3d_weight_16ch_sel;

    logic [3:0]                         conv_psum_rd_req;
    logic [3:0][4:0]                    conv_psum_rd_num;
    logic [3:0]                         conv_psum_rd_ch_sel;
    logic [3:0]                         conv_psum_rd_rgb_sel;
    logic [3:0][4:0]                    conv_psum_rd_offset;

    logic [3:0]                         VQ_scache_wr_en;
    logic [3:0][8:0]                    VQ_scache_wr_addr;
    logic [3:0][1:0]                    VQ_scache_wr_size;
    
    logic [3:0]                         VQ_scache_rd_en;
    logic [3:0][8:0]                    VQ_scache_rd_addr;
    logic [3:0][1:0]                    VQ_scache_rd_size;
    logic [3:0]                         VQ_scache_rd_sign_ext;

    logic [3:0]                         VQ_cub_csr_access;
    logic [3:0][5:0]                    VQ_cub_csr_addr;
    logic [3:0][15:0]                   VQ_cub_csr_wdata;

    logic [3:0]                         Y_mode_pre_en;
    logic [3:0]                         Y_mode_cram_sel;

    logic                               eltwise_bcfmap_bsel_en;
    assign eltwise_bcfmap_bsel_en = conv3d_bcfmap_elt_mode_o &  conv3d_bcfmap_elt_pric_o; //eltwise int16

    logic scache_cflow_data_rd_st_rdy;
    logic [BANK_NUM-1:0]scache_cflow_data_rd_st_rdy_w;
    always_comb begin
        foreach(scache_cflow_data_rd_st_rdy_w[i])
            scache_cflow_data_rd_st_rdy_w[i] = VQ_disp_cubank_mask[i] ? 1'b1 : scache_cflow_data_rd_st_rdy_i[i];
    end
    assign scache_cflow_data_rd_st_rdy = &scache_cflow_data_rd_st_rdy_w;

    genvar i;
    generate
    for(i=0;i<16;i=i+1) begin: DISPATCH_TO_CU_BANK_0_15
        assign conv_req_o[i] = /*VQ_disp_cubank_mask[i] ? 1'b0 : */conv_req[i/8];
        assign conv_mode_o[i] = conv_mode[i/8]; 
        assign conv_cfg_vld_o[i] = /*VQ_disp_cubank_mask[i] ? 1'b0 : */conv_cfg_vld[i/8];
        assign conv_cfg_addr_o[i] = conv_cfg_addr[i/8];
        assign conv_cfg_data_o[i] = conv_cfg_data[i/8];    
         
        assign dwconv_cross_ram_from_left_o[i] = dwconv_cross_ram_from_left[i/8]; 
        assign dwconv_cross_ram_from_right_o[i] = dwconv_cross_ram_from_right[i/8];    
        assign dwconv_right_padding_o[i] = dwconv_right_padding[i/8];
        assign dwconv_left_padding_o[i] = dwconv_left_padding[i/8];
        assign dwconv_bottom_padding_o[i] = dwconv_bottom_padding[i/8];
        assign dwconv_top_padding_o[i] = dwconv_top_padding[i/8];
        assign dwconv_trans_num_o[i] = dwconv_trans_num[i/8];

        assign conv3d_psum_end_index_o[i] = conv3d_psum_end_index[i/8];
        assign conv3d_psum_start_index_o[i] = conv3d_psum_start_index[i/8];
        assign conv3d_first_subch_flag_o[i] = conv3d_first_subch_flag[i/8];
        assign conv3d_result_output_flag_o[i] = conv3d_result_output_flag[i/8];
        assign conv3d_weight_16ch_sel_o[i] = conv3d_weight_16ch_sel[i/8];

        assign conv_psum_rd_req_o[i] = VQ_disp_cubank_mask[i] ? 1'b0 : conv_psum_rd_req[i/8];
        assign conv_psum_rd_num_o[i] = conv_psum_rd_num[i/8];
        assign conv_psum_rd_ch_sel_o[i] = conv_psum_rd_ch_sel[i/8];
        assign conv_psum_rd_rgb_sel_o[i] = conv_psum_rd_rgb_sel[i/8];
        assign conv_psum_rd_offset_o[i] = conv_psum_rd_offset[i/8];

        assign VQ_scache_wr_en_o[i] = VQ_disp_cubank_mask[i] ? 1'b0 : VQ_scache_wr_en[i/8];
        assign VQ_scache_wr_addr_o[i] = VQ_scache_wr_addr[i/8];
        assign VQ_scache_wr_size_o[i] = VQ_scache_wr_size[i/8];

        assign VQ_scache_rd_en_o[i] = (eltwise_bcfmap_bsel_en&conv3d_bcfmap_elt_bsel_o | VQ_disp_cubank_mask[i]) ? 1'b0 : VQ_scache_rd_en[i/8];
        assign VQ_scache_rd_addr_o[i] = VQ_scache_rd_addr[i/8];
        assign VQ_scache_rd_size_o[i] = VQ_scache_rd_size[i/8];
        assign VQ_scache_rd_sign_ext_o[i] = VQ_scache_rd_sign_ext[i/8];

        assign VQ_cub_csr_access_o[i] = VQ_disp_cubank_mask[i] ? 1'b0 : VQ_cub_csr_access[i/8];
        assign VQ_cub_csr_addr_o[i] = VQ_cub_csr_addr[i/8];
        assign VQ_cub_csr_wdata_o[i] = VQ_cub_csr_wdata[i/8];

        assign Y_mode_pre_en_o[i] = VQ_disp_cubank_mask[i] ? 1'b0 : Y_mode_pre_en[i/8];
        assign Y_mode_cram_sel_o[i] = VQ_disp_cubank_mask[i] ? 1'b0 : Y_mode_cram_sel[i/8];
    end

    for(i=16;i<32;i=i+1) begin: DISPATCH_TO_CU_BANK_16_31
        assign conv_req_o[i] = /*VQ_disp_cubank_mask[i] ? 1'b0 : */conv_req[i/8];
        assign conv_mode_o[i] = conv_mode[i/8]; 
        assign conv_cfg_vld_o[i] = /*VQ_disp_cubank_mask[i] ? 1'b0 : */conv_cfg_vld[i/8];
        assign conv_cfg_addr_o[i] = conv_cfg_addr[i/8];
        assign conv_cfg_data_o[i] = conv_cfg_data[i/8];    
         
        assign dwconv_cross_ram_from_left_o[i] = dwconv_cross_ram_from_left[i/8]; 
        assign dwconv_cross_ram_from_right_o[i] = dwconv_cross_ram_from_right[i/8];    
        assign dwconv_right_padding_o[i] = dwconv_right_padding[i/8];
        assign dwconv_left_padding_o[i] = dwconv_left_padding[i/8];
        assign dwconv_bottom_padding_o[i] = dwconv_bottom_padding[i/8];
        assign dwconv_top_padding_o[i] = dwconv_top_padding[i/8];
        assign dwconv_trans_num_o[i] = dwconv_trans_num[i/8];

        assign conv3d_psum_end_index_o[i] = conv3d_psum_end_index[i/8];
        assign conv3d_psum_start_index_o[i] = conv3d_psum_start_index[i/8];
        assign conv3d_first_subch_flag_o[i] = conv3d_first_subch_flag[i/8];
        assign conv3d_result_output_flag_o[i] = conv3d_result_output_flag[i/8];
        assign conv3d_weight_16ch_sel_o[i] = conv3d_weight_16ch_sel[i/8];

        assign conv_psum_rd_req_o[i] = VQ_disp_cubank_mask[i] ? 1'b0 : conv_psum_rd_req[i/8];
        assign conv_psum_rd_num_o[i] = conv_psum_rd_num[i/8];
        assign conv_psum_rd_ch_sel_o[i] = conv_psum_rd_ch_sel[i/8];
        assign conv_psum_rd_rgb_sel_o[i] = conv_psum_rd_rgb_sel[i/8];
        assign conv_psum_rd_offset_o[i] = conv_psum_rd_offset[i/8];

        assign VQ_scache_wr_en_o[i] = VQ_disp_cubank_mask[i] ? 1'b0 : VQ_scache_wr_en[i/8];
        assign VQ_scache_wr_addr_o[i] = VQ_scache_wr_addr[i/8];
        assign VQ_scache_wr_size_o[i] = VQ_scache_wr_size[i/8];

        assign VQ_scache_rd_en_o[i] = (eltwise_bcfmap_bsel_en&!conv3d_bcfmap_elt_bsel_o | VQ_disp_cubank_mask[i]) ? 1'b0 : VQ_scache_rd_en[i/8];
        assign VQ_scache_rd_addr_o[i] = VQ_scache_rd_addr[i/8];
        assign VQ_scache_rd_size_o[i] = VQ_scache_rd_size[i/8];
        assign VQ_scache_rd_sign_ext_o[i] = VQ_scache_rd_sign_ext[i/8];

        assign VQ_cub_csr_access_o[i] = VQ_disp_cubank_mask[i] ? 1'b0 : VQ_cub_csr_access[i/8];
        assign VQ_cub_csr_addr_o[i] = VQ_cub_csr_addr[i/8];
        assign VQ_cub_csr_wdata_o[i] = VQ_cub_csr_wdata[i/8];

        assign Y_mode_pre_en_o[i] = VQ_disp_cubank_mask[i] ? 1'b0 : Y_mode_pre_en[i/8];
        assign Y_mode_cram_sel_o[i] = VQ_disp_cubank_mask[i] ? 1'b0 : Y_mode_cram_sel[i/8];        
    end
    endgenerate

    //--------------------------------------------------------
    //  Dispatch+Decode
    //--------------------------------------------------------
    accel_dispatch #(
        .IRAM_AWID      (IRAM_AWID)
    )
    U_accel_dispatch
    (
        .clk(clk),
        .rst_n(rst_n),
        
        .MQ_disp_req_i(MQ_disp_req),
        .MQ_disp_instr_i(MQ_disp_instr_dec),
        .MQ_disp_ready_o(MQ_disp_ready), 
        .MQ_cfifo_en_i(MQ_disp_cfifo_en),
        .MQ_cfifo_data_i(MQ_disp_cfifo_data),
        
        .VQ_disp_req_i(VQ_disp_req),
        .VQ_disp_instr_i(VQ_disp_instr_dec),
        .VQ_disp_ready_o(VQ_disp_ready),
        .VQ_cfifo_en_i(VQ_disp_cfifo_en),
        .VQ_cfifo_data_i(VQ_disp_cfifo_data),
        
        .MQ_disp_func_i(MQ_disp_func),
        .VQ_disp_func_i(VQ_disp_func),
        .SQ_disp_func_i(SQ_disp_func),
        
        .SQ_disp_req_i(SQ_disp_req),
        .SQ_disp_instr_i(SQ_disp_instr_dec),
        .SQ_disp_ready_o(SQ_disp_ready),
        .SQ_cfifo_en_i(SQ_disp_cfifo_en),
        .SQ_cfifo_data_i(SQ_disp_cfifo_data),        
        
        .Slsu_data_req_o(Slsu_data_req_o),
        .Slsu_data_gnt_i(Slsu_data_gnt_i),
        .Slsu_data_ok_i(Slsu_data_ok_i),  

		.Slsu_data_we_o(Slsu_data_we_o),
		.Slsu_l1b_mode_o(Slsu_l1b_mode_o), //1:norm 0:cache
		.Slsu_tcache_core_load_bank_num_o(Slsu_tcache_core_load_bank_num_o),
		.Slsu_data_sub_len_o(Slsu_data_sub_len_o),
		.Slsu_data_sys_gap_o(Slsu_data_sys_gap_o),
		.Slsu_data_addr_o(Slsu_data_addr_o),
		.Slsu_data_sys_len_o(Slsu_data_sys_len_o),
        .Slsu_data_mv_last_dis_o(Slsu_data_mv_last_dis_o),

        .Slsu_cfg_vld_o(Slsu_cfg_vld_o),
        .Slsu_cfg_addr_o(Slsu_cfg_addr_o),
		.Slsu_l1b_gpu_mode_o(Slsu_l1b_gpu_mode_o), //MQ CFG0
        .Slsu_l1b_op_wr_hl_mask_o(Slsu_l1b_op_wr_hl_mask_o),
		.Slsu_mv_cub_dst_sel_o(Slsu_mv_cub_dst_sel_o),
        .Slsu_tcache_trans_prici_o(Slsu_tcache_trans_prici_o),
        .Slsu_tcache_trans_swbank_o(Slsu_tcache_trans_swbank_o),
		.Slsu_l1b_norm_paral_mode_o(Slsu_l1b_norm_paral_mode_o),
		.Slsu_tcache_mode_o(Slsu_tcache_mode_o), //00:DFIFO_MODE 01:SFIFO_MODE 10:TRANS_MODE 11:DWCONV_MODE
		.Slsu_cache_one_ram_qw_base_addr_o(Slsu_cache_one_ram_qw_base_addr_o),
        .Slsu_data_sub_gap_o(Slsu_data_sub_gap_o),
        .Slsu_data_sys_gap_ext_o(Slsu_data_sys_gap_ext_o),
        .Slsu_iob_pric_o(Slsu_iob_pric_o),
        .Slsu_iob_l2c_in_cfg_o(Slsu_iob_l2c_in_cfg_o),
        .Slsu_tcache_mvfmap_stride_o(Slsu_tcache_mvfmap_stride_o),
        .Slsu_tcache_mvfmap_offset_o(Slsu_tcache_mvfmap_offset_o),        
        
        .cubank_LB_mv_cub_dst_sel_i(cubank_LB_mv_cub_dst_sel_i),

        .Hlsu_data_req_o(Hlsu_data_req_o),
        .Hlsu_data_gnt_i(Hlsu_data_gnt_i),
        .Hlsu_data_we_o(Hlsu_data_we_o),
        .Hlsu_l1b_mode_o(Hlsu_l1b_mode_o),
        .Hlsu_data_sys_gap_o(Hlsu_data_sys_gap_o),
        .Hlsu_data_sub_len_o(Hlsu_data_sub_len_o),
        .Hlsu_data_addr_o(Hlsu_data_addr_o),
        .Hlsu_data_sys_len_o(Hlsu_data_sys_len_o),

        .Hlsu_data_sub_gap_o(Hlsu_data_sub_gap_o), //MQ CFG2
        .Hlsu_data_sys_gap_ext_o(Hlsu_data_sys_gap_ext_o),
        .Hlsu_l1b_norm_paral_mode_o(Hlsu_l1b_norm_paral_mode_o),

        .Hlsu_chk_done_req_o(Hlsu_chk_done_req_o),
        .Hlsu_chk_done_gnt_i(Hlsu_chk_done_gnt_i),

        //to cu_bank
        .conv_req_o(conv_req),
        .conv_gnt_i({conv_gnt_i[24],conv_gnt_i[16],conv_gnt_i[8],conv_gnt_i[0]}),
        .conv_done_i({conv_done_i[24],conv_done_i[16],conv_done_i[8],conv_done_i[0]}),
        .conv_mode_o(conv_mode), 
        .conv_cfg_vld_o(conv_cfg_vld),
        .conv_cfg_addr_o(conv_cfg_addr),
        .conv_cfg_data_o(conv_cfg_data),
        
        .dwconv_cross_ram_from_left_o(dwconv_cross_ram_from_left), 
        .dwconv_cross_ram_from_right_o(dwconv_cross_ram_from_right),        
        .dwconv_right_padding_o(dwconv_right_padding),
        .dwconv_left_padding_o(dwconv_left_padding),
        .dwconv_bottom_padding_o(dwconv_bottom_padding),
        .dwconv_top_padding_o(dwconv_top_padding),
        .dwconv_trans_num_o(dwconv_trans_num),
        
        .conv3d_psum_end_index_o(conv3d_psum_end_index),
        .conv3d_psum_start_index_o(conv3d_psum_start_index),
        .conv3d_first_subch_flag_o(conv3d_first_subch_flag),
        .conv3d_result_output_flag_o(conv3d_result_output_flag),
        .conv3d_weight_16ch_sel_o(conv3d_weight_16ch_sel),

        .conv_psum_rd_req_o(conv_psum_rd_req),
        .conv_psum_rd_num_o(conv_psum_rd_num),
        .conv_psum_rd_ch_sel_o(conv_psum_rd_ch_sel),
        .conv_psum_rd_rgb_sel_o(conv_psum_rd_rgb_sel),
        .conv_psum_rd_offset_o(conv_psum_rd_offset),

        .VQ_scache_wr_en_o(VQ_scache_wr_en),
        .VQ_scache_wr_addr_o(VQ_scache_wr_addr),
        .VQ_scache_wr_size_o(VQ_scache_wr_size),
        .VQ_scache_rd_en_o(VQ_scache_rd_en),
        .VQ_scache_rd_addr_o(VQ_scache_rd_addr),
        .VQ_scache_rd_size_o(VQ_scache_rd_size),
        .VQ_scache_rd_sign_ext_o(VQ_scache_rd_sign_ext),
        
        .VQ_cub_csr_access_o(VQ_cub_csr_access),
        .VQ_cub_csr_addr_o(VQ_cub_csr_addr),
        .VQ_cub_csr_wdata_o(VQ_cub_csr_wdata),

        .VQ_alu_event_call_o(VQ_alu_event_call),
        .VQ_alu_event_addr_o(VQ_alu_event_addr),
        .VQ_alu_event_finish_i({4{VQ_alu_event_finish}}),

        //to SLSU
        .conv3d_bcfmap_req_o(conv3d_bcfmap_req_o),
        .conv3d_bcfmap_gnt_i(conv3d_bcfmap_gnt_i),
        .conv3d_bcfmap_ok_i(conv3d_bcfmap_ok_i),
        
        .conv3d_bcfmap_mode_o(conv3d_bcfmap_mode_o), 
        .conv3d_bcfmap_len_o(conv3d_bcfmap_len_o), 
        .conv3d_bcfmap_rgba_mode_o(conv3d_bcfmap_rgba_mode_o), 
        .conv3d_bcfmap_rgba_stride_o(conv3d_bcfmap_rgba_stride_o), 
        .conv3d_bcfmap_rgba_shift_o(conv3d_bcfmap_rgba_shift_o), 
        .conv3d_bcfmap_hl_op_o(conv3d_bcfmap_hl_op_o),
        .conv3d_bcfmap_keep_2cycle_en_o(conv3d_bcfmap_keep_2cycle_en_o),
        .conv3d_bcfmap_group_o(conv3d_bcfmap_group_o),
        .conv3d_bcfmap_pad0_he_sel_o(conv3d_bcfmap_pad0_he_sel_o),
        .conv3d_bcfmap_pad0_len_o(conv3d_bcfmap_pad0_len_o),
        .conv3d_bcfmap_tcache_stride_o(conv3d_bcfmap_tcache_stride_o),
        .conv3d_bcfmap_tcache_offset_o(conv3d_bcfmap_tcache_offset_o),

        .conv3d_bcfmap_elt_mode_o(conv3d_bcfmap_elt_mode_o),
        .conv3d_bcfmap_elt_pric_o(conv3d_bcfmap_elt_pric_o),
        .conv3d_bcfmap_elt_bsel_o(conv3d_bcfmap_elt_bsel_o),
        .conv3d_bcfmap_elt_32ch_i16_o(conv3d_bcfmap_elt_32ch_i16_o),

        .Y_mode_pre_en_o(Y_mode_pre_en),
        .Y_mode_cram_sel_o(Y_mode_cram_sel),

        //to NOC
        .Noc_cmd_req_o(Noc_cmd_req_o),
        .Noc_cmd_addr_o(Noc_cmd_addr_o),
        .Noc_cmd_gnt_i(Noc_cmd_gnt_i),
        .Noc_cmd_ok_i(Noc_cmd_ok_i),
        
        .Noc_cfg_vld_o(Noc_cfg_vld_o),
        .Noc_cfg_addr_o(Noc_cfg_addr_o),
        .Noc_cfg_data_o(Noc_cfg_data_o),

        .scache_cflow_data_rd_st_rdy_i(scache_cflow_data_rd_st_rdy),
        .CU_bank_scache_dout_en_i(CU_bank_scache_dout_en_i),
        .CU_bank_data_out_ready_i(CU_bank_data_out_ready_i),

        .Sfu_req_o(Sfu_req_o),
        .Sfu_gnt_i(Sfu_gnt_i),
        .Sfu_len_o(Sfu_len_o),
        .Sfu_mode_o(Sfu_mode_o)
    );



    //--------------------------------------------------------
    //  CUB Alu insn in
    //--------------------------------------------------------


    cub_alu_instr_ram #(
        .INSN_WIDTH     (INSN_WIDTH),
        .IRAM_AWID      (IRAM_AWID)
    )
    U_cub_alu_instr_ram(
        .clk                     (clk                       ),
        .rst_n                   (rst_n                     ),

        //.alu_instr_fill_en_i     (Cub_alu_insn_fill_en      ),
        //.alu_instr_fill_addr_i   (Cub_alu_insn_fill_addr    ),
        //.alu_instr_fill_num_i    (Cub_alu_insn_fill_num     ),
        .alu_instr_fill_state_i  (Cub_alu_insn_fill_state   ),
        .alu_instr_fill_stall_i  (Cub_alu_insn_fill_stall   ),
        .alu_instr_fill_addr_i   (Cub_alu_insn_fill_addr    ),
        .alu_instr_in_i          (Cub_alu_insn              ),

        .alu_instr_req_i         (Cub_alu_instr_req         ),
        .alu_instr_gnt_o         (Cub_alu_instr_gnt         ),
        .alu_instr_addr_i        (Cub_alu_instr_addr        ),
        .alu_instr_rdata_o       (Cub_alu_instr_rdata       ),
        .alu_instr_rvalid_o      (Cub_alu_instr_rvalid      )
    );


    cub_alu_fetch #(
        .IRAM_AWID      (IRAM_AWID),
        .IRAM_FILL_AWID (IRAM_FILL_AWID),
        .LOOP_NUM       (LOOP_NUM)
    )
    U_cub_alu_fetch(
        .clk                     (clk                     ),
        .rst_n                   (rst_n                   ),

        .alu_boot_addr_i         (Cub_alu_boot_addr       ),

        .instr_req_o             (Cub_alu_instr_req       ),
        .instr_gnt_i             (Cub_alu_instr_gnt       ),
        .instr_addr_o            (Cub_alu_instr_addr      ),
        .instr_rdata_i           (Cub_alu_instr_rdata     ),
        .instr_rvalid_i          (Cub_alu_instr_rvalid    ),

        .req_i                   (fetch_req               ),
        .pc_mux_i                (pc_mux                  ),
        .pc_set_i                (pc_set                  ),

        .pc_if_o                 (pc_if                   ),
        .pc_id_o                 (pc_id                   ),
        .fetch_instr_o           (fetch_instr             ),
        .fetch_valid_o           (fetch_valid             ),
        .id_ready_i              (id_ready                ),
        .cub_alu_fetch_end_i     (Cub_alu_fetch_end       ),

        .loop_start_i            (loop_start              ),
        .loop_end_i              (loop_end                ),
        .loop_cnt_i              (loop_cnt                ),

        .loop_cnt_dec_o          (loop_cnt_dec            ),
        .is_loop_id_o            (is_loop_id              ),

        .cub_nop_state_i         (cub_nop_state           )        
    );



    cub_alu_pre_decode #(
        .IRAM_AWID      (IRAM_AWID),
        .IRAM_FILL_AWID (IRAM_FILL_AWID),
        .LOOP_NUM       (LOOP_NUM),
        .BANK_NUM       (BANK_NUM)
    )
    U_cub_alu_pre_decode(
        .clk                     (clk                   ),
        .rst_n                   (rst_n                 ),

        .instr_rdata_i           (fetch_instr           ),
        .instr_valid_i           (fetch_valid           ),

        .cub_alu_boot_addr_i     (Cub_alu_boot_addr     ),
        .alu_instr_addr_i        (Cub_alu_instr_addr    ),
        .Cub_alu_fetch_req_addr_o(Cub_alu_fetch_req_addr), //to sequence ctrl for fetch_ready


        .fetch_enable_i          (Cub_alu_fetch_req     ),
        .fetch_req_o             (fetch_req             ),
        .pc_mux_o                (pc_mux                ),
        .pc_set_o                (pc_set                ),
        .pc_if_i                 (pc_if                 ),
        .pc_id_i                 (pc_id                 ),
        .id_ready_o              (id_ready              ),

        .loop_start_o            (loop_start            ),
        .loop_end_o              (loop_end              ),
        .loop_cnt_o              (loop_cnt              ),
        .loop_cnt_dec_i          (loop_cnt_dec          ),
        .is_loop_i               (is_loop_id            ),

        .Cub_alu_mask_i          (Cub_alu_mask          ),
        .Cub_alu_mask_update_i   (Cub_alu_mask_update   ),
        .Cub_alu_mask_sel_i      (Cub_alu_mask_sel      ),

        .cub_alu_fetch_end_o     (Cub_alu_fetch_end     ),
        .deassert_we_o           (deassert_we_o         ),
        .cub_nop_state_o         (cub_nop_state         ),
        .first_fetch_o           (),

        .Cub_alu_instr_o         (Cub_alu_instr_o       ),
        .Cub_alu_instr_valid_o   (Cub_alu_instr_valid_o ),

        .ALU_Cfifo_pop_o         (ALU_Cfifo_pop_o       ),
        .ALU_Cfifo_data_i        (ALU_Cfifo_data_i      ),
        .ALU_Cfifo_empty_i       (ALU_Cfifo_empty_i     )
    );



endmodule


