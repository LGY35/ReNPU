module cub_alu_top(
    input                       clk,
    input                       rst_n,
 
    //conv flow data in
    input [32-1:0]              cub_alu_data_i,
    input                       cub_alu_data_valid_i,

    //alu rslt data
    output logic [32-1:0]       cub_alu_data_o,
    output logic                cub_alu_data_valid_o,

    //alu insn in
    input [31:0]                Cub_alu_instr_i,
    input                       Cub_alu_instr_valid_i,
    input                       deassert_we_i,
    input [4:0]                 cub_id_i,
  
    //VQ csr cfg in
    input                       VQ_cub_csr_access_i,
    input [5:0]                 VQ_cub_csr_addr_i,
    input [15:0]                VQ_cub_csr_wdata_i,

    //scache cfg
    output logic [ 7: 0]        scache_wr_sub_len_o,
    output logic [ 7: 0]        scache_wr_sys_len_o,
    output logic [ 8: 0]        scache_wr_sub_gap_o,
    output logic [ 9: 0]        scache_wr_sys_gap_o,
    output logic [ 7: 0]        scache_rd_sub_len_o,
    output logic [ 7: 0]        scache_rd_sys_len_o,
    output logic [ 8: 0]        scache_rd_sub_gap_o,
    output logic [ 9: 0]        scache_rd_sys_gap_o,
    output logic                scache_lut_mode_o,
    output logic                scache_lut_ram_sel_o,
    
    //alu flow cfg
    output logic [ 2: 0]        cub_alu_din_cflow_sel_o ,
    output logic [ 0: 0]        cub_scache_dout_cflow_sel_o,
    output logic [ 0: 0]        cub_alu_dout_cflow_sel_o ,
    output logic [ 0: 0]        cub_alu_din_sc_cross_rd_en_o,

    output logic                cub_alu_scache_en_o,
    output logic                cub_alu_scache_we_o,
    output logic [8:0]          cub_alu_scache_addr_o,
    output logic [1:0]          cub_alu_scache_size_o,
    output logic                cub_alu_scache_sign_ext_o,    

    output logic                cub_mif_data_l1b_req_o      ,
    output logic                cub_mif_data_cram_req_o     ,
    output logic                cub_mif_data_scache_req_o   ,
    output logic                cub_mif_data_we_o           ,
    output logic [3 : 0]        cub_mif_data_be_o           ,
    output logic [31: 0]        cub_mif_data_wdata_o        ,
    output logic [13 : 0]       cub_mif_data_addr_o         , //word addr
    input                       cub_mif_data_l1b_gnt_i      ,
    input                       cub_mif_data_l1b_rvalid_i   ,
    input        [31 : 0]       cub_mif_data_l1b_rdata_i    ,
    input                       cub_mif_data_cram_gnt_i     ,
    input                       cub_mif_data_cram_rvalid_i  ,
    input        [31 : 0]       cub_mif_data_cram_rdata_i   ,
    input                       cub_mif_data_scache_gnt_i   ,
    input                       cub_mif_data_scache_rvalid_i,
    input        [31 : 0]       cub_mif_data_scache_rdata_i ,

    output logic [31:0]         cub_mem_rdata_to_crossbar_o,
    output logic                cub_mem_rvalid_to_crossbar_o,

    //cubank interconnect reg
    input   [31:0]              cub_interconnect_top_reg_0_i,
    input   [31:0]              cub_interconnect_top_reg_1_i,
    input   [31:0]              cub_interconnect_top_reg_2_i,
    input   [31:0]              cub_interconnect_top_reg_3_i,
    input   [31:0]              cub_interconnect_bottom_reg_0_i,
    input   [31:0]              cub_interconnect_bottom_reg_1_i,
    input   [31:0]              cub_interconnect_bottom_reg_2_i,
    input   [31:0]              cub_interconnect_bottom_reg_3_i,
    input   [31:0]              cub_interconnect_side_reg_i,
    input   [31:0]              cub_interconnect_gap_reg_i,    
    output logic [31:0]         cub_interconnect_reg_o,
    input  logic                cub_interconnect_reg_valid_i,
    output logic                cub_interconnect_reg_ready_o,

    input   [31:0]              tcache_bcfmap_data_alu_i
);

    parameter RF_ADDR_WIDTH = 5;
    parameter CRBR_DWID     = 32;
    parameter CRBR_CH_IN    = 5;
    parameter CRBR_CH_OUT   = 5;
    parameter CRBR_OUT_WR   = 4;

    //Forward Signals
    logic [5-1:0]               regfile_waddr_wb;
    logic                       regfile_we_wb;
    logic [31:0]                regfile_wdata_wb;      //From wb_stage: selects data from data memory, ex_stage result and sp rdata

    logic [5-1:0]               regfile_alu_waddr_fw;
    logic                       regfile_alu_we_fw;
    logic [31:0]                regfile_alu_wdata_fw;   
    //Pipeline ED/EX
    logic [RF_ADDR_WIDTH-1:0]   regfile_waddr_ex;      //write prot a
    logic                       regfile_we_ex;
    logic [RF_ADDR_WIDTH-1:0]   regfile_alu_waddr_ex;  //write prot b
    logic                       regfile_alu_we_ex;
    logic                       deassert_we_ex; 
    //ALU signals
    logic                       alu_en_ex;             //ALU enable
    logic [7-1:0]               alu_operator_ex;       //ALU operation selection
    logic [31:0]                alu_operand_a_ex;      //operand a selection: reg value, PC, immediate or zero
    logic [31:0]                alu_operand_b_ex;      //operand b selection: reg value or immediate
    logic [31:0]                alu_operand_c_ex;
    logic [1:0]                 alu_vec_mode_ex;       //selects between 32 bit, 16 bit and 8 bit vectorial modes
    logic                       alu_trun_prec_ex;      //0:int8 1:int16
    logic [4:0]                 alu_trun_Q_ex;      

    //MUL signals
    logic                       mult_en_ex;            //perform integer multiplication
    logic [2:0]                 mult_operator_ex;      //Multiplication operation selection
    logic [31:0]                mult_operand_a_ex;
    logic [31:0]                mult_operand_b_ex;
    logic [1:0]                 mult_signed_mode_ex;   //Multiplication in signed mode
    logic                       mult_sel_subword_ex;   //Select subwords for 16x16 bit of multiplier

    //LD/ST unit signals
    logic                       data_req_ex;           //start transaction to data memory
    logic                       data_we_ex;            //data memory write enable
    logic [1:0]                 data_type_ex;          //00:byte 01:halfword 10:word
    logic [1:0]                 data_ram_sel_ex;       //00:scache 01:l1b 10:cram
    logic                       data_sign_extension_ex;//0:signed ext 1:zero

    logic                       csr_access;
    logic                       csr_access_ex;
    logic [ 5: 0]               csr_addr;
    logic [15: 0]               csr_wdata;    

    logic                       acti_en_ex;
    logic [7:0]                 acti_operator_ex;
    logic [31:0]                acti_operand_a_ex;
    logic                       pool_en_ex;
    logic [1:0]                 pool_operator_ex;
    logic [31:0]                pool_operand_a_ex;
    logic [31:0]                pool_operand_b_ex;
    logic                       pool_comp_sign_ex; 
    logic [1:0]                 pool_comp_vect_ex;
    logic [1:0]                 pool_comp_mode_ex;     
    
    logic                       alu_en_deassert;
    logic                       mult_en_deassert;
    logic                       acti_en_deassert;
    logic                       pool_en_deassert;
    
    logic [31:0]                cub_arithmetic_rslt;
    logic [31:0]                cub_mult_rslt;

    logic [15: 0]               cub_mult_lambda;
    logic [ 3: 0]               cub_mult_truncate_Q;
    logic [31: 0]               cub_arithmetic_bias;
    //logic                       cub_arithmetic_trun_en;    
    //logic                       cub_arithmetic_trun_prec;
    logic [ 4: 0]               cub_arithmetic_trun_Q;
    logic [ 4: 0]               cub_arithmetic_trun_elt_Q;
    logic [15: 0]               cub_activ_prelu_scaling;
    logic [ 4: 0]               cub_activ_mul_pdt_Qp;
    logic [31: 0]               cub_activ_relu6_bias;
    logic [31: 0]               cub_activ_relu6_ref_max;
    logic [31: 0]               cub_activ_relu6_ref_min;

    //csr signal
    logic [ 7: 0]               acti_work_mode      ;
    logic [ 0: 0]               pool_comp_sign      ;
    logic [ 1: 0]               pool_comp_vect      ;
    logic [ 1: 0]               pool_comp_mode      ;
    logic [ 0: 0]               pool_cflow_wind_step;
    logic [ 7: 0]               pool_cflow_wind_size;
    logic [ 1: 0]               pool_cflow_lab_mode ;
    logic [ 7: 0]               pool_cflow_data_len ;
    logic [14: 0]               cub_crbr_bitmask_cfg0;
    logic [ 9: 0]               cub_crbr_bitmask_cfg1;
    logic [ 0: 0]               cub_cflow_mode,cub_cflow_mode_fu;
    logic [ 0: 0]               cub_alu_elt_mode,cub_alu_elt_mode_fu;
    logic [ 0: 0]               cub_alu_elt_arith_or_mult;
    logic                       cub_mult_param_sel;
    logic                       cub_arithmetic_param_sel;
    logic                       cub_activ_param_sel;
    logic                       cub_mem_op_sta_clr;
    logic [ 6: 0]               arithmetic_cflow_operator;
    logic [ 2: 0]               cub_alu_din_cflow_sel;

    logic                       l1b_load_to_crossbar_sel;
    logic                       cub_pooling_cflow_reg1_act;

    logic [CRBR_CH_IN-1:0][CRBR_DWID-1 : 0]     cub_crbr_cflow_data_in  ;
    logic [CRBR_CH_IN-1:0]                      cub_crbr_cflow_valid_in ;
    logic [CRBR_CH_OUT-1:0][CRBR_DWID-1 : 0]    cub_crbr_cflow_data_out ;
    logic [CRBR_CH_OUT-1:0]                     cub_crbr_cflow_valid_out;

    logic [31:0]                                cub_mult_cflow_rslt;
    logic                                       cub_mult_cflow_rslt_valid;
    logic                                       cub_arithmetic_rslt_valid;
    logic [31:0]                                cub_activ_rslt;
    logic                                       cub_activ_rslt_valid;
    
    logic [31:0]                                cub_pool_vect_rslt;
    logic [31:0]                                cub_pool_cflow_rslt;
    logic                                       cub_pool_cflow_rslt_valid;
    logic                                       cub_pool_done;

    logic                                       prelu_mult_en;
    logic [32:0]                                prelu_mult_multiplicand;
    logic [16:0]                                prelu_mult_multiplier;
    logic [49:0]                                prelu_mult_product;

    logic                                       cflow_nop_en;
    logic                                       ex_ready;
    logic                                       ex_valid;
    logic                                       alu_ready,mult_ready,pool_ready,acti_ready;

    logic                                       alu_en_sel           ;
    logic                                       mult_en_sel          ;
    logic                                       acti_en_sel          ;
    logic                                       pool_en_sel          ;


    //==================================
    //cub_id_stage
    //==================================
    cub_id_stage #(
        .RF_ADDR_WIDTH(RF_ADDR_WIDTH),
        .CRBR_DWID    (CRBR_DWID),
        .CRBR_CH_IN   (CRBR_CH_IN),
        .CRBR_CH_OUT  (CRBR_CH_OUT)        
    )
    U_cub_id_stage(
        .clk                            (clk                       ),
        .rst_n                          (rst_n                     ),
        
        //cub instr in
        .Cub_instr_i                    (Cub_alu_instr_i           ),
        .Cub_instr_valid_i              (Cub_alu_instr_valid_i     ),
        .deassert_we_i                  (deassert_we_i             ),
        .deassert_we_ex_o               (deassert_we_ex            ),
        .cub_id_i                       (cub_id_i                  ),
        
        //Forward Signals
        .regfile_waddr_wb_i             (regfile_waddr_wb          ),
        .regfile_we_wb_i                (regfile_we_wb             ),
        .regfile_wdata_wb_i             (regfile_wdata_wb          ),
        
        .regfile_alu_waddr_fw_i         (regfile_alu_waddr_fw      ),
        .regfile_alu_we_fw_i            (regfile_alu_we_fw         ),
        .regfile_alu_wdata_fw_i         (regfile_alu_wdata_fw      ),   
        
        //Pipeline ED/EX
        .regfile_waddr_ex_o             (regfile_waddr_ex          ),
        .regfile_we_ex_o                (regfile_we_ex             ),
        .regfile_alu_waddr_ex_o         (/*regfile_alu_waddr_ex */ ),
        .regfile_alu_we_ex_o            (/*regfile_alu_we_ex    */ ),
        .regfile_alu_waddr_ex_fifo_o    (regfile_alu_waddr_ex      ),
        .regfile_alu_we_ex_fifo_o       (regfile_alu_we_ex         ),
        .alu_en_fifo_o                  (alu_en_sel                ),
        .mult_int_en_fifo_o             (mult_en_sel               ),
        .acti_en_fifo_o                 (acti_en_sel               ),
        .pool_en_fifo_o                 (pool_en_sel               ),

        
        //ALU signals
        .alu_en_ex_o                    (alu_en_ex                 ),
        .alu_operator_ex_o              (alu_operator_ex           ),
        .alu_operand_a_ex_o             (alu_operand_a_ex          ),
        .alu_operand_b_ex_o             (alu_operand_b_ex          ),
        .alu_operand_c_ex_o             (alu_operand_c_ex          ),
        .alu_vec_mode_ex_o              (alu_vec_mode_ex           ), //TODO
        .alu_trun_prec_ex_o             (alu_trun_prec_ex          ),
        .alu_trun_Q_ex_o                (alu_trun_Q_ex             ),
        
        //MUL signals
        .mult_en_ex_o                   (mult_en_ex                ),
        .mult_operator_ex_o             (mult_operator_ex          ),
        .mult_operand_a_ex_o            (mult_operand_a_ex         ),
        .mult_operand_b_ex_o            (mult_operand_b_ex         ),
        .mult_signed_mode_ex_o          (mult_signed_mode_ex       ),
        .mult_sel_subword_ex_o          (mult_sel_subword_ex       ), //TODO
        
        //LD/ST unit signals
        .data_req_ex_o                  (data_req_ex               ),
        .data_we_ex_o                   (data_we_ex                ),
        .data_type_ex_o                 (data_type_ex              ),
        .data_ram_sel_ex_o              (data_ram_sel_ex           ),
        .data_sign_extension_ex_o       (data_sign_extension_ex    ),
        .l1b_load_to_crossbar_sel_i     (l1b_load_to_crossbar_sel  ),
        
        //cub_csr
        .csr_access_ex_o                (csr_access_ex             ),
        
        //Scache
        .scache_en_ex_o                 (cub_alu_scache_en_o       ),
        .scache_we_ex_o                 (cub_alu_scache_we_o       ),
        .scache_addr_ex_o               (cub_alu_scache_addr_o     ),
        .scache_size_ex_o               (cub_alu_scache_size_o     ),
        .scache_sign_ext_ex_o           (cub_alu_scache_sign_ext_o ),
        //00:32bit 01:16bit 10:8bit
        //acti/pool
        .acti_en_ex_o                   (acti_en_ex                ),
        .acti_operator_ex_o             (acti_operator_ex          ),
        .acti_operand_a_ex_o            (acti_operand_a_ex         ),
        .pool_en_ex_o                   (pool_en_ex                ),
        .pool_operator_ex_o             (pool_operator_ex          ),
        .pool_operand_a_ex_o            (pool_operand_a_ex         ),
        .pool_operand_b_ex_o            (pool_operand_b_ex         ),
        .pool_comp_sign_ex_o            (pool_comp_sign_ex         ), 
        .pool_comp_vect_ex_o            (pool_comp_vect_ex         ),
        .pool_comp_mode_ex_o            (pool_comp_mode_ex         ),     
        .cub_pooling_cflow_reg1_act_i   (cub_pooling_cflow_reg1_act),
        .cub_pool_rslt_i                (cub_pool_vect_rslt        ),
        
        //crossbar interface
        .cub_cflow_mode_i               (cub_cflow_mode            ),
        .cub_crbr_cflow_data_out_i      (cub_crbr_cflow_data_out   ),
        .cub_crbr_cflow_valid_out_i     (cub_crbr_cflow_valid_out  ),

        .cub_mult_param_sel_i           (cub_mult_param_sel        ),
        .cub_arithmetic_param_sel_i     (cub_arithmetic_param_sel  ),
        .cub_activ_param_sel_i          (cub_activ_param_sel       ),
        
        .cub_mult_lambda_o              (cub_mult_lambda           ),
        .cub_mult_truncate_Q_o          (cub_mult_truncate_Q       ),
        .cub_arithmetic_bias_o          (cub_arithmetic_bias       ),
        //.cub_arithmetic_trun_en_o       (cub_arithmetic_trun_en    ),
        //.cub_arithmetic_trun_prec_o     (cub_arithmetic_trun_prec  ),
        .cub_arithmetic_trun_Q_o        (cub_arithmetic_trun_Q     ),
        .cub_arithmetic_trun_elt_Q_o    (cub_arithmetic_trun_elt_Q ),
        .cub_activ_prelu_scaling_o      (cub_activ_prelu_scaling   ),
        .cub_activ_mul_pdt_Qp_o         (cub_activ_mul_pdt_Qp      ),
        .cub_activ_relu6_bias_o         (cub_activ_relu6_bias      ),
        .cub_activ_relu6_ref_max_o      (cub_activ_relu6_ref_max   ),
        .cub_activ_relu6_ref_min_o      (cub_activ_relu6_ref_min   ),        

        .ex_ready_i                     (1'b1),
        .ex_valid_i                     (ex_valid                  ),

        .cflow_nop_en_o                 (cflow_nop_en              ),

        //cubank interconnect reg
        .cub_interconnect_top_reg_0_i   (cub_interconnect_top_reg_0_i),
        .cub_interconnect_top_reg_1_i   (cub_interconnect_top_reg_1_i),
        .cub_interconnect_top_reg_2_i   (cub_interconnect_top_reg_2_i),
        .cub_interconnect_top_reg_3_i   (cub_interconnect_top_reg_3_i),
        .cub_interconnect_bottom_reg_0_i(cub_interconnect_bottom_reg_0_i),
        .cub_interconnect_bottom_reg_1_i(cub_interconnect_bottom_reg_1_i),
        .cub_interconnect_bottom_reg_2_i(cub_interconnect_bottom_reg_2_i),
        .cub_interconnect_bottom_reg_3_i(cub_interconnect_bottom_reg_3_i),
        .cub_interconnect_side_reg_i    (cub_interconnect_side_reg_i),
        .cub_interconnect_gap_reg_i     (cub_interconnect_gap_reg_i),
        .cub_interconnect_reg_o         (cub_interconnect_reg_o),
        .cub_interconnect_reg_valid_i   (cub_interconnect_reg_valid_i),
        .cub_interconnect_reg_ready_o   (cub_interconnect_reg_ready_o)
    );




    //===========================================
    //cub_ex+crossbar: include alu,mult,relu,pool
    //===========================================
    cub_crossbar #(
        .DWID    (CRBR_DWID),
        .CH_IN   (CRBR_CH_IN),
        .CH_OUT  (CRBR_CH_OUT)
    )U_cub_crossbar(
         .cub_crbr_cfg_bitmask           ({cub_crbr_bitmask_cfg1,cub_crbr_bitmask_cfg0}),
         .cub_crbr_cflow_data_in         ({cub_alu_data_i,
                                           cub_mult_cflow_rslt,
                                           cub_arithmetic_rslt,
                                           cub_activ_rslt,
                                           cub_pool_cflow_rslt
                                           }),
         .cub_crbr_cflow_valid_in        ({cub_alu_data_valid_i,
                                           cub_mult_cflow_rslt_valid,
                                           cub_arithmetic_rslt_valid,
                                           cub_activ_rslt_valid,
                                           cub_pool_cflow_rslt_valid
                                           }),
         .cub_crbr_cflow_data_out        (cub_crbr_cflow_data_out),
         .cub_crbr_cflow_valid_out       (cub_crbr_cflow_valid_out)
    );
   

    //alu out
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            cub_alu_data_valid_o <= 1'b0;
        end
        else if(cub_crbr_cflow_valid_out[CRBR_OUT_WR]) begin
            cub_alu_data_o <= cub_crbr_cflow_data_out[CRBR_OUT_WR];
            cub_alu_data_valid_o <= 1'b1;
        end
        else begin
            cub_alu_data_valid_o <= 1'b0;
        end
    end
        
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            cub_cflow_mode_fu <= 1'b0;
            cub_alu_elt_mode_fu <= 'b0;
        end
        else begin
            cub_cflow_mode_fu <= cub_cflow_mode | cflow_nop_en;
            cub_alu_elt_mode_fu <= cub_alu_elt_mode;
        end
    end
 
    assign mult_en_deassert = mult_en_ex & (cub_cflow_mode_fu ? 1'b1 : ~deassert_we_ex);
    assign alu_en_deassert  = alu_en_ex & (cub_cflow_mode_fu ? 1'b1 : (~deassert_we_ex)&&(~data_req_ex));
    assign acti_en_deassert = acti_en_ex & (cub_cflow_mode_fu ? 1'b1 : ~deassert_we_ex);
    assign pool_en_deassert = pool_en_ex & (cub_cflow_mode_fu ? 1'b1 : ~deassert_we_ex);
    
    //MULT
    cub_mult U_cub_mult(
        .clk                             (clk                             ),
        .rst_n                           (rst_n                           ),
        
        .cub_mult_enable                 (mult_en_deassert                ),
        .cub_mult_operator               (mult_operator_ex                ),
        .cub_mult_cflow_mode             (cub_cflow_mode_fu               ),
        
        .cub_mult_operand_a              (mult_operand_a_ex               ),
        .cub_mult_operand_b              (mult_operand_b_ex               ),
        .cub_mult_lambda                 (cub_alu_elt_mode_fu & cub_alu_elt_arith_or_mult ? tcache_bcfmap_data_alu_i[15:0] : cub_mult_lambda), //16bit
        
        .cub_mult_cflow_truncate_Q       (cub_mult_truncate_Q             ), //4bit
        .cub_mult_op_data_signed         (mult_signed_mode_ex             ), //00:mulhu,mul 01:mulhsu 11:mulh
        
        .cub_mult_instr_rslt             (cub_mult_rslt                   ),
        
        .cub_mult_cflow_rslt             (cub_mult_cflow_rslt             ),
        .cub_mult_cflow_rslt_valid       (cub_mult_cflow_rslt_valid       ),
        
        
        .cub_mult_multicycle_o           (),
        .cub_mult_ready_o                (mult_ready),
        //.cub_mult_ready_i                (),
        
        //reused by prelu module
        .prelu_mult_en                   (prelu_mult_en                   ),
        .prelu_mult_multiplicand         (prelu_mult_multiplicand         ),
        .prelu_mult_multiplier           (prelu_mult_multiplier           ),
        .prelu_mult_product              (prelu_mult_product              )              
    );


    //ALU
    cub_arithmetic U_cub_arithmetic(
        .clk                             (clk                             ),
        .rst_n                           (rst_n                           ),
        
        .cub_arithmetic_enable           (alu_en_deassert                 ),
        .cub_arithmetic_operator         ((cub_cflow_mode_fu || cub_alu_elt_mode_fu) ? arithmetic_cflow_operator : alu_operator_ex),
        .cub_arithmetic_operand_a        (alu_operand_a_ex                ), 
        .cub_arithmetic_operand_b        (cub_alu_elt_mode_fu & !cub_alu_elt_arith_or_mult ? tcache_bcfmap_data_alu_i[31:0] : (cub_cflow_mode_fu ? cub_arithmetic_bias : alu_operand_b_ex)),
        //.cub_arithmetic_bias             (cub_alu_elt_mode_fu & !cub_alu_elt_arith_or_mult ? tcache_bcfmap_data_alu_i[31:0] : cub_arithmetic_bias), //32bit

        .cub_arithmetic_cflow_mode       (cub_cflow_mode_fu               ),
        //.cub_arithmetic_cflow_truncate_en(cub_arithmetic_trun_en          ),
        //.cub_arithmetic_truncate_prec    (cub_cflow_mode_fu ? cub_arithmetic_trun_prec : alu_trun_prec_ex), //0:int8 1:int16
        .cub_arithmetic_truncate_Q       (cub_alu_elt_mode_fu ? cub_arithmetic_trun_elt_Q : (cub_cflow_mode_fu ? cub_arithmetic_trun_Q : alu_trun_Q_ex)), //5bit
        .cub_arithmetic_vect_mode        (alu_vec_mode_ex                 ), //00:32bit 01:16bit 10:8bit
        
        .cub_arithmetic_result_valid     (cub_arithmetic_rslt_valid       ),
        .cub_arithmetic_result           (cub_arithmetic_rslt             ),

        .cub_arithmetic_ready_o          (alu_ready                       )
    );


    //ACTI
    cub_activ U_cub_activ(  
        .clk                             (clk                             ),
        .rst_n                           (rst_n                           ),
        
        .cub_activ_cflow_mode            (cub_cflow_mode_fu               ),
        .cub_activ_valid                 (acti_en_deassert                ), //op_enable
        .cub_activ_work_op               (cub_cflow_mode_fu ? acti_work_mode : acti_operator_ex),
        .cub_activ_operand               (acti_operand_a_ex               ),
        
        .cub_activ_rslt_data             (cub_activ_rslt                  ),
        .cub_activ_rslt_valid            (cub_activ_rslt_valid            ),
        
        .cub_activ_relu6_bias            (cub_activ_relu6_bias            ), //32bit
        .cub_activ_relu6_ref_min         (cub_activ_relu6_ref_min         ), //32bit
        .cub_activ_relu6_ref_max         (cub_activ_relu6_ref_max         ), //32bit
        .cub_activ_prelu_scaling         (cub_activ_prelu_scaling         ), //16bit
        .cub_activ_mul_pdt_Qp            (cub_activ_mul_pdt_Qp            ), //5bit
        
        //reused by prelu module
        .prelu_mult_en                   (prelu_mult_en                   ),
        .prelu_mult_multiplier           (prelu_mult_multiplier           ),
        .prelu_mult_multiplicand         (prelu_mult_multiplicand         ),
        .prelu_mult_product              (prelu_mult_product              ),

        .cub_activ_ready                 (acti_ready                      )
    );




    //POOL
    cub_pooling U_cub_pooling(
        .clk                             (clk                           ),
        .rst_n                           (rst_n                         ),
        
        .cub_pooling_en                  (pool_en_ex                        ),
        .cub_pooling_cflow_mode          (cub_cflow_mode_fu                ),
        //only for instr
        //.cub_pooling_operator            (),  
        .cub_pooling_op_a                (pool_operand_a_ex             ),
        .cub_pooling_op_b                (pool_operand_b_ex             ),
        
        //comparator cflow & instr use
        .cub_pooling_comp_sign           (cub_cflow_mode_fu ? pool_comp_sign : pool_comp_sign_ex),
        .cub_pooling_comp_vect           (cub_cflow_mode_fu ? pool_comp_vect : pool_comp_vect_ex),
        .cub_pooling_comp_mode           (cub_cflow_mode_fu ? pool_comp_mode : pool_comp_mode_ex),
        
        //only for cflow
        .cub_pooling_cflow_wind_step     (pool_cflow_wind_step          ),
        .cub_pooling_cflow_wind_size     (pool_cflow_wind_size          ),
        .cub_pooling_cflow_data_len      (pool_cflow_data_len           ),
        .cub_pooling_cflow_lab_mode      (pool_cflow_lab_mode           ),
        
        //cflow data in port
        //.cub_pooling_cflow_data          (cub_pooling_cflow_data),
        .cub_pooling_cflow_data_valid    (/*pool_en_ex*/cub_crbr_cflow_valid_out[3]),    
        
        .cub_pooling_cflow_reg1_act      (cub_pooling_cflow_reg1_act    ),                                    
       
        .cub_pooling_vect_rslt           (cub_pool_vect_rslt            ),
        .cub_pooling_cflow_rslt          (cub_pool_cflow_rslt           ),
        .cub_pooling_cflow_rslt_valid    (cub_pool_cflow_rslt_valid     ),
        .cub_pooling_ready               (pool_ready                    ),
        .cub_pooling_done                ()
    );





    always_comb begin
        regfile_alu_we_fw    = regfile_alu_we_ex; 
        regfile_alu_waddr_fw = regfile_alu_waddr_ex;
        regfile_alu_wdata_fw = 'b0;
        if(alu_en_sel)
            regfile_alu_wdata_fw = cub_arithmetic_rslt;
        else if(mult_en_sel)
            regfile_alu_wdata_fw = cub_mult_rslt;
        else if(acti_en_sel)
            regfile_alu_wdata_fw = cub_activ_rslt;
        else if(pool_en_sel)
            regfile_alu_wdata_fw = cub_pool_vect_rslt;
    end

    //assign ex_ready = alu_ready & mult_ready & acti_ready & pool_ready;/*& lsu_ready_ex_i*/ ; //EX stage ready for new data
    assign ex_valid = alu_ready || mult_ready || acti_ready || pool_ready;/*& lsu_ready_ex_i*/ ; //EX stage ready for new data
    //===========================================
    // ex stage end
    //===========================================





    //==================================
    //cub_csr
    //==================================
    cub_cs_registers U_cub_cs_registers(
        .clk                            (clk                            ),
        .rst_n                          (rst_n                          ),
        
        .csr_access_en_i                (csr_access                     ),
        .csr_addr_i                     (csr_addr                       ),
        .csr_wdata_i                    (csr_wdata                      ),

        //cub csr output
        .scache_wr_sub_len_o            (scache_wr_sub_len_o            ),
        .scache_wr_sys_len_o            (scache_wr_sys_len_o            ),
        .scache_wr_sub_gap_o            (scache_wr_sub_gap_o            ),
        .scache_wr_sys_gap_o            (scache_wr_sys_gap_o            ),
        .scache_rd_sub_len_o            (scache_rd_sub_len_o            ),
        .scache_rd_sys_len_o            (scache_rd_sys_len_o            ),
        .scache_rd_sub_gap_o            (scache_rd_sub_gap_o            ),
        .scache_rd_sys_gap_o            (scache_rd_sys_gap_o            ),
        .acti_work_mode_o               (acti_work_mode                 ),
        .pool_comp_sign_o               (pool_comp_sign                 ),
        .pool_comp_vect_o               (pool_comp_vect                 ),
        .pool_comp_mode_o               (pool_comp_mode                 ),
        .pool_cflow_wind_step_o         (pool_cflow_wind_step           ),
        .pool_cflow_wind_size_o         (pool_cflow_wind_size           ),
        .pool_cflow_lab_mode_o          (pool_cflow_lab_mode            ),
        .pool_cflow_data_len_o          (pool_cflow_data_len            ),
        .cub_alu_din_cflow_sel_o        (cub_alu_din_cflow_sel          ),
        .cub_scache_dout_cflow_sel_o    (cub_scache_dout_cflow_sel_o    ),
        .cub_cflow_mode_o               (cub_cflow_mode                 ),
        .cub_alu_dout_cflow_sel_o       (cub_alu_dout_cflow_sel_o       ),
        .cub_alu_elt_mode_o             (cub_alu_elt_mode               ),
        .cub_alu_elt_arith_or_mult_o    (cub_alu_elt_arith_or_mult      ),
        .cub_crbr_bitmask_cfg0_o        (cub_crbr_bitmask_cfg0          ),
        .cub_crbr_bitmask_cfg1_o        (cub_crbr_bitmask_cfg1          ),
        .cub_mult_param_sel_o           (cub_mult_param_sel             ),
        .cub_arithmetic_param_sel_o     (cub_arithmetic_param_sel       ),
        .cub_activ_param_sel_o          (cub_activ_param_sel            ),
        .cub_mem_op_sta_clr_o           (cub_mem_op_sta_clr             ),
        .scache_lut_mode_o              (scache_lut_mode_o              ),
        .scache_lut_ram_sel_o           (scache_lut_ram_sel_o           ),
        .arithmetic_cflow_operator_o    (arithmetic_cflow_operator      )
        //.arithmetic_trun_prec_o     (arithmetic_trun_prec       ),
        //.arithmetic_trun_Q_o        (arithmetic_trun_Q          )
    );

    assign cub_alu_din_cflow_sel_o = cub_alu_din_cflow_sel;
    assign l1b_load_to_crossbar_sel =  (cub_alu_din_cflow_sel == 3'b010);

    //CSR access
    assign csr_access   =  VQ_cub_csr_access_i | csr_access_ex;
    assign csr_addr     =  VQ_cub_csr_access_i ? VQ_cub_csr_addr_i : csr_access_ex ? alu_operand_b_ex[5:0] : 6'b0;
    assign csr_wdata    =  VQ_cub_csr_access_i ? VQ_cub_csr_wdata_i : csr_access_ex ? alu_operand_a_ex[15:0] : 16'b0;


    logic [31:0]    cub_mem_rdata;
    logic           cub_mem_rvalid;
    logic [4:0]     cub_mem_rdst_greg_out;
    logic           cub_mem_l1b_rdst_crossbar_en;

    assign regfile_we_wb    = cub_mem_rvalid & !cub_mem_l1b_rdst_crossbar_en;
    assign regfile_wdata_wb = cub_mem_rdata;
    assign regfile_waddr_wb = cub_mem_rdst_greg_out;

    assign cub_mem_rdata_to_crossbar_o = cub_mem_rdata;
    assign cub_mem_rvalid_to_crossbar_o = cub_mem_rvalid & cub_mem_l1b_rdst_crossbar_en;

    //==================================
    //cub_load_store_unit
    //==================================
    cub_mem_addr_ctrl U_cub_mem_addr_ctrl(
        .clk                         (clk                         ),
        .rst_n                       (rst_n                       ),

        //signals from id stage
        .cub_mem_op_sta_clr          (cub_mem_op_sta_clr            ),
        .cub_mem_op_enable           (data_req_ex                   ),
        .cub_mem_sel                 (data_ram_sel_ex               ), //00:l1b 01:cram 10:sharecache
        .cub_mem_rdst_greg_in        (regfile_waddr_ex              ), // dst general regs
        .cub_mem_we                  (data_we_ex                    ), // 1: write 0: read
        .cub_mem_data_type           (data_type_ex                  ), //00:word, 01:halfword, ,10:byte         -> from ex stage
        .cub_mem_wr_data             (alu_operand_c_ex              ),
        .cub_mem_rdata_sign_ext      (data_sign_extension_ex        ), //sign extension                         -> from ex stage
        .cub_mem_operand_a           (alu_operand_a_ex              ), //operand a from RF for address 16bit    -> from ex stage
        .cub_mem_operand_b           (alu_operand_b_ex              ), //operand b from RF for address 16bit    -> from ex stage 
        .cub_mem_rvalid              (/*regfile_we_wb*/cub_mem_rvalid),
        .cub_mem_rdata               (/*regfile_wdata_wb*/cub_mem_rdata),
        .cub_mem_rdst_greg_out       (/*regfile_waddr_wb*/cub_mem_rdst_greg_out),
        .cub_mem_l1b_rdst_crossbar_en(cub_mem_l1b_rdst_crossbar_en  ),
        
        //l1b,scache,cram
        .cub_mif_data_l1b_req        (cub_mif_data_l1b_req_o        ),
        .cub_mif_data_cram_req       (cub_mif_data_cram_req_o       ),
        .cub_mif_data_scache_req     (cub_mif_data_scache_req_o     ),
        .cub_mif_data_we             (cub_mif_data_we_o             ),
        .cub_mif_data_be             (cub_mif_data_be_o             ),
        .cub_mif_data_wdata          (cub_mif_data_wdata_o          ),
        .cub_mif_data_addr           (cub_mif_data_addr_o           ), //word addr
        .cub_mif_data_l1b_gnt        (cub_mif_data_l1b_gnt_i        ),
        .cub_mif_data_l1b_rvalid     (cub_mif_data_l1b_rvalid_i     ),
        .cub_mif_data_l1b_rdata      (cub_mif_data_l1b_rdata_i      ),
        .cub_mif_data_cram_gnt       (cub_mif_data_cram_gnt_i       ),
        .cub_mif_data_cram_rvalid    (cub_mif_data_cram_rvalid_i    ),
        .cub_mif_data_cram_rdata     (cub_mif_data_cram_rdata_i     ),
        .cub_mif_data_scache_gnt     (cub_mif_data_scache_gnt_i     ),
        .cub_mif_data_scache_rvalid  (cub_mif_data_scache_rvalid_i  ),
        .cub_mif_data_scache_rdata   (cub_mif_data_scache_rdata_i   )
        );

endmodule
