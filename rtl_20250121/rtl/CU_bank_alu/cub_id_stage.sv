// Source/Destination register instruction index
`define REG_S1 19:15
`define REG_S2 24:20
`define REG_S4 31:27
`define REG_D  11:07

module cub_id_stage #(
    parameter RF_ADDR_WIDTH = 5,
    parameter CRBR_DWID     = 32,
    parameter CRBR_CH_IN    = 5,
    parameter CRBR_CH_OUT   = 5    
    )(
    input                                       clk,
    input                                       rst_n,

    input [31:0]                                Cub_instr_i,
    input                                       Cub_instr_valid_i,
    input                                       deassert_we_i,
    output logic                                deassert_we_ex_o,
    input [4:0]                                 cub_id_i,
    //Forward Signals
    input [5-1:0]                               regfile_waddr_wb_i,
    input                                       regfile_we_wb_i,
    input [31:0]                                regfile_wdata_wb_i, //From wb_stage: selects data from data memory, ex_stage result and sp rdata

    input [5-1:0]                               regfile_alu_waddr_fw_i,
    input                                       regfile_alu_we_fw_i,
    input [31:0]                                regfile_alu_wdata_fw_i,   
    //Pipeline ED/EX
    output logic [RF_ADDR_WIDTH-1:0]            regfile_waddr_ex_o,     //write prot a
    output logic                                regfile_we_ex_o,
    output logic [RF_ADDR_WIDTH-1:0]            regfile_alu_waddr_ex_o, //write prot b
    output logic                                regfile_alu_we_ex_o,
    output logic [RF_ADDR_WIDTH-1:0]            regfile_alu_waddr_ex_fifo_o, //write prot b
    output logic                                regfile_alu_we_ex_fifo_o,
    output logic                                alu_en_fifo_o,
    output logic                                mult_int_en_fifo_o,
    output logic                                acti_en_fifo_o,
    output logic                                pool_en_fifo_o,
    //ALU signals
    output logic                                alu_en_ex_o,           //ALU enable
    output logic [7-1:0]                        alu_operator_ex_o,     //ALU operation selection
    output logic [31:0]                         alu_operand_a_ex_o,  //operand a selection: reg value, PC, immediate or zero
    output logic [31:0]                         alu_operand_b_ex_o,  //operand b selection: reg value or immediate
    output logic [31:0]                         alu_operand_c_ex_o,
    output logic [1:0]                          alu_vec_mode_ex_o,     //00:32bit 01:16bit 10:8bit
    output logic                                alu_trun_prec_ex_o,    //0:int8 1:int16
    output logic [4:0]                          alu_trun_Q_ex_o,      

    //MUL signals
    output logic                                mult_en_ex_o,          // perform integer multiplication
    output logic [2:0]                          mult_operator_ex_o,    // Multiplication operation selection
    output logic [31:0]                         mult_operand_a_ex_o,
    output logic [31:0]                         mult_operand_b_ex_o,
    output logic [1:0]                          mult_signed_mode_ex_o, // Multiplication in signed mode
    output logic                                mult_sel_subword_ex_o, // Select subwords for 16x16 bit of multiplier

    //LD/ST unit signals
    output logic                                data_req_ex_o,            //start transaction to data memory
    output logic                                data_we_ex_o,             //data memory write enable
    output logic [1:0]                          data_type_ex_o,           //00:byte 01:halfword 10:word
    output logic [1:0]                          data_ram_sel_ex_o,        //00:l1b 01:cram 10:scache
    output logic                                data_sign_extension_ex_o, //0:signed ext 1:zero
    input                                       l1b_load_to_crossbar_sel_i,

    output logic                                csr_access_ex_o,

    output logic                                scache_en_ex_o,
    output logic                                scache_we_ex_o,
    output logic [8:0]                          scache_addr_ex_o,
    output logic [1:0]                          scache_size_ex_o,
    output logic                                scache_sign_ext_ex_o,
    //output logic                                l1b_en_o,
    //output logic                                l1b_we_o,
    //output logic [1:0]                          l1b_size_o,
    //output logic                                l1b_sign_ext_o

    output logic                                acti_en_ex_o,
    output logic [7:0]                          acti_operator_ex_o,
    output logic [31:0]                         acti_operand_a_ex_o,
    output logic                                pool_en_ex_o,
    output logic [1:0]                          pool_operator_ex_o,
    output logic [31:0]                         pool_operand_a_ex_o,
    output logic [31:0]                         pool_operand_b_ex_o,
    output logic                                pool_comp_sign_ex_o, 
    output logic [1:0]                          pool_comp_vect_ex_o,
    output logic [1:0]                          pool_comp_mode_ex_o,     
    input                                       cub_pooling_cflow_reg1_act_i,
    input [31:0]                                cub_pool_rslt_i,

    //crossbar interface
    input                                       cub_cflow_mode_i,
    input [CRBR_CH_OUT-1:0][CRBR_DWID-1 : 0]    cub_crbr_cflow_data_out_i,
    input [CRBR_CH_OUT-1:0]                     cub_crbr_cflow_valid_out_i,

    //to alu reg
    input                                       cub_mult_param_sel_i,
    input                                       cub_arithmetic_param_sel_i,
    input                                       cub_activ_param_sel_i,

    output logic [15: 0]                        cub_mult_lambda_o,
    output logic [ 3: 0]                        cub_mult_truncate_Q_o,
    output logic [31: 0]                        cub_arithmetic_bias_o,
    //output logic [ 0: 0]                        cub_arithmetic_trun_en_o,
    //output logic [ 0: 0]                        cub_arithmetic_trun_prec_o,
    output logic [ 4: 0]                        cub_arithmetic_trun_Q_o,
    output logic [ 4: 0]                        cub_arithmetic_trun_elt_Q_o,
    output logic [15: 0]                        cub_activ_prelu_scaling_o,
    output logic [ 4: 0]                        cub_activ_mul_pdt_Qp_o,
    output logic [31: 0]                        cub_activ_relu6_bias_o,
    output logic [31: 0]                        cub_activ_relu6_ref_max_o,
    output logic [31: 0]                        cub_activ_relu6_ref_min_o,

    input                                       ex_ready_i,
    input                                       ex_valid_i,

    output logic                                cflow_nop_en_o,

    //cubank interconnect reg
    input   [31:0]                              cub_interconnect_top_reg_0_i,
    input   [31:0]                              cub_interconnect_top_reg_1_i,
    input   [31:0]                              cub_interconnect_top_reg_2_i,
    input   [31:0]                              cub_interconnect_top_reg_3_i,
    input   [31:0]                              cub_interconnect_bottom_reg_0_i,
    input   [31:0]                              cub_interconnect_bottom_reg_1_i,
    input   [31:0]                              cub_interconnect_bottom_reg_2_i,
    input   [31:0]                              cub_interconnect_bottom_reg_3_i,
    input   [31:0]                              cub_interconnect_side_reg_i,
    input   [31:0]                              cub_interconnect_gap_reg_i,
    output logic [31:0]                         cub_interconnect_reg_o,
    input                                       cub_interconnect_reg_valid_i,
    output logic                                cub_interconnect_reg_ready_o
);

    `include "decode_param.v"

    localparam MULT  = 3'd0;
    localparam ALU   = 3'd1;
    localparam ACTI  = 3'd2;
    localparam POOL  = 3'd3;

    logic [31:0] instr;
    assign instr = Cub_instr_i;

    logic   [1:0]           imm_a_mux_sel;
    logic   [3:0]           imm_b_mux_sel;

    //Immediate decoding and sign extension
    logic   [31:0]          imm_i_type;
    logic   [31:0]          imm_lci_type;
    logic   [31:0]          imm_s_type;
    logic   [31:0]          imm_u_type;
    logic   [31:0]          imm_z_type;
    logic   [31:0]          imm_sc_type;
    logic   [31:0]          imm_lb_type;
    logic   [31:0]          imm_c_type;
    logic   [31:0]          imm_is_type;

    logic [31:0]            imm_a;       
    logic [31:0]            imm_b;           

    //Regfile interface
    logic [RF_ADDR_WIDTH-1:0]   regfile_addr_ra_id;//raddr
    logic [RF_ADDR_WIDTH-1:0]   regfile_addr_rb_id;
    logic [RF_ADDR_WIDTH-1:0]   regfile_addr_rc_id;    
    logic [31:0]                regfile_data_ra_id;//rdata
    logic [31:0]                regfile_data_rb_id;
    logic [31:0]                regfile_data_rc_id;

    logic [RF_ADDR_WIDTH-1:0]   regfile_waddr_id;
    logic [RF_ADDR_WIDTH-1:0]   regfile_alu_waddr_id;
    logic                       regfile_alu_we_id;    

    logic reg_d_ex_is_reg_a, reg_d_ex_is_reg_b, reg_d_ex_is_reg_c;
    logic reg_d_wb_is_reg_a, reg_d_wb_is_reg_b, reg_d_wb_is_reg_c;
    logic reg_d_alu_is_reg_a, reg_d_alu_is_reg_b, reg_d_alu_is_reg_c;

    //Register Write Control
    logic                   regfile_we_id;
    logic                   regfile_alu_waddr_mux_sel;

    //ALU Control
    logic                   alu_en;
    logic [7-1:0]           alu_operator;
    logic [2:0]             alu_op_a_mux_sel;
    logic [2:0]             alu_op_b_mux_sel;
    logic [1:0]             alu_vec_mode;
    logic                   alu_trun_prec;                    
    logic [4:0]             alu_trun_Q;                    

    //Multiplier Control
    logic                   mult_int_en;      // use integer multiplier
    logic [2:0]             mult_operator;    // multiplication operation selection
    logic [1:0]             mult_signed_mode; // Signed mode multiplication at the output of the controller, and before the pipe registers
    logic                   mult_sel_subword;

    //Data Memory Control
    logic                   data_req_id;
    logic                   data_we_id;
    logic [1:0]             data_type_id;
    logic [1:0]             data_ram_sel_id;
    logic                   data_sign_ext_id;

    //CSR control
    logic                   csr_access;

    //cflow nop ctrl
    logic                   cflow_nop_en;
    logic [7:0]             cflow_nop_cycle_num;

    //Forwarding
    logic [1:0]             operand_a_fw_mux_sel;
    logic [1:0]             operand_b_fw_mux_sel;
    logic [31:0]            operand_a_fw_id;
    logic [31:0]            operand_b_fw_id;

    logic [31:0]            operand_a;
    logic [31:0]            operand_b;

    logic [31:0]            alu_operand_a;
    logic [31:0]            alu_operand_b;
    logic [31:0]            alu_operand_c;

    logic                   rega_used_dec;
    logic                   regb_used_dec;

    logic                   scache_en_id;
    logic                   scache_we_id;
    logic [1:0]             scache_size_id;
    logic                   scache_sign_ext_id;

    logic                   acti_en;
    logic [7:0]             acti_operator;
    logic                   pool_en;
    logic [1:0]             pool_operator;
    logic                   pool_comp_sign; 
    logic [1:0]             pool_comp_vect;
    logic [1:0]             pool_comp_mode;     

    logic                   id_valid;
    logic                   Cub_illegal_insn;

    //immediate extraction and sign extension
    assign imm_i_type  = {{20{instr[31]}}, instr[31:20]};
    assign imm_lci_type = {{16{instr[31]}}, instr[31:16]};
    //assign imm_iz_type = {           20'b0, instr[31:20]};
    assign imm_is_type = {{21{instr[30]}}, instr[30:20]};
    assign imm_s_type  = {{20{instr[31]}}, instr[31:25], instr[11:7]};
    //assign imm_sb_type = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
    assign imm_u_type  = {instr[31:12], 12'b0};
    //assign imm_uj_type = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};

    //immediate for CSR manipulate (zero extended)
    assign imm_z_type  = {16'b0, instr[31:16]};
    //assign imm_s2_type = {27'b0, instr[24:20]};
    //assign imm_bi_type = {{27{instr[24]}}, instr[24:20]};
    //assign imm_s3_type = {27'b0, instr[29:25]};
    //assign imm_vs_type = {{26{instr[24]}}, instr[24:20], instr[25]};
    //assign imm_vu_type = {26'b0, instr[24:20], instr[25]};
    assign imm_c_type  = {26'b0, instr[15], instr[11:7]};

    //immediate for scache/l1b/cram
    assign imm_sc_type = {23'b0, instr[23:15]};
    assign imm_lb_type = {19'b0, instr[27:15]};


    //============================
    //  Operand
    //============================
    //==========Operand A==========
    //ALU_op_a Mux
    always_comb begin : alu_operand_a_mux
      case(alu_op_a_mux_sel)
        OP_A_REGA_OR_FWD:  alu_operand_a = operand_a_fw_id;
        OP_A_REGB_OR_FWD:  alu_operand_a = operand_b_fw_id;
        //OP_A_REGC_OR_FWD:  alu_operand_a = operand_c_fw_id;
        OP_A_IMM:          alu_operand_a = imm_a;
        OP_A_ZERO:         alu_operand_a = 32'b0;
        default:           alu_operand_a = operand_a_fw_id;
      endcase
    end

    //Operand a forwarding mux
    always_comb begin : operand_a_fw_mux
      case(operand_a_fw_mux_sel)
        SEL_FW_EX:    operand_a_fw_id = regfile_alu_wdata_fw_i;
        SEL_FW_WB:    operand_a_fw_id = regfile_wdata_wb_i;
        SEL_REGFILE:  operand_a_fw_id = regfile_data_ra_id;
        default:      operand_a_fw_id = regfile_data_ra_id;
      endcase
    end

    //imm_a
    always_comb begin : immediate_a_mux
      case(imm_a_mux_sel)
        IMMA_Z:      imm_a = imm_z_type;
        IMMA_SC:     imm_a = imm_sc_type;
        IMMA_LB:     imm_a = imm_lb_type;
        IMMA_ZERO:   imm_a = '0;
        default:     imm_a = '0;
      endcase
    end

    //==========Operand B==========
    assign alu_operand_b = operand_b; //choose normal or scalar replicated version of operand b
    
    //ALU_op_b Mux
    always_comb begin : alu_operand_b_mux
      case (alu_op_b_mux_sel)
        OP_B_REGA_OR_FWD:  operand_b = operand_a_fw_id;
        OP_B_REGB_OR_FWD:  operand_b = operand_b_fw_id;
        //OP_B_REGC_OR_FWD:  operand_b = operand_c_fw_id;
        OP_B_IMM:          operand_b = imm_b;
        default:           operand_b = operand_b_fw_id;
      endcase
    end

    //Operand b forwarding mux
    always_comb begin : operand_b_fw_mux
      case (operand_b_fw_mux_sel)
        SEL_FW_EX:    operand_b_fw_id = regfile_alu_wdata_fw_i;
        SEL_FW_WB:    operand_b_fw_id = regfile_wdata_wb_i;
        SEL_REGFILE:  operand_b_fw_id = regfile_data_rb_id;
        default:      operand_b_fw_id = regfile_data_rb_id;
      endcase
    end

    //imm_b
    always_comb begin : immediate_b_mux
      case (imm_b_mux_sel)
        IMMB_I:      imm_b = imm_i_type;
        IMMB_S:      imm_b = imm_s_type;
        IMMB_U:      imm_b = imm_u_type;
        //IMMB_PCINCR: imm_b = (is_compressed_i && (~data_misaligned_i)) ? 32'h2 : 32'h4;
        //IMMB_S2:     imm_b = imm_s2_type;
        //IMMB_BI:     imm_b = imm_bi_type;
        //IMMB_S3:     imm_b = imm_s3_type;
        //IMMB_VS:     imm_b = imm_vs_type;
        //IMMB_VU:     imm_b = imm_vu_type;
        //IMMB_SHUF:   imm_b = imm_shuffle_type;
        //IMMB_CLIP:   imm_b = {1'b0, imm_clip_type[31:1]};
        IMMB_C:      imm_b = imm_c_type;
        IMMB_IS:     imm_b = imm_is_type;
        IMMB_LCI:    imm_b = imm_lci_type;
        default:     imm_b = imm_i_type;
      endcase
    end

    //==========Operand C==========
    assign alu_operand_c = operand_b_fw_id;


    //==========source register selection==========
    assign regfile_addr_ra_id = instr[`REG_S1];
    assign regfile_addr_rb_id = instr[`REG_S2];

    //==========destination register selection========== 
    //First Register Write Address 
    assign regfile_waddr_id = instr[`REG_D];

    //Second Register Write Address Selection, Used for prepost load/store and multiplier
    assign regfile_alu_waddr_id = regfile_alu_waddr_mux_sel ? regfile_waddr_id : regfile_addr_ra_id;


cub_general_regfile #(
    .ADDR_WIDTH(5),
    .DATA_WIDTH(32)
)
U_cub_general_regfile(
    .clk                        (clk),
    .rst_n                      (rst_n),
    
    .cub_greg_raddr_a           (regfile_addr_ra_id),
    .cub_greg_rdata_a           (regfile_data_ra_id),
    
    .cub_greg_raddr_b           (regfile_addr_rb_id),
    .cub_greg_rdata_b           (regfile_data_rb_id),
    
    .cub_greg_waddr_a           (regfile_waddr_wb_i),
    .cub_greg_wdata_a           (regfile_wdata_wb_i),
    .cub_greg_we_a              (regfile_we_wb_i),

    //.cub_greg_waddr_b           (regfile_alu_waddr_fw_i), //port b priority is high
    .cub_greg_waddr_b           (regfile_alu_waddr_ex_fifo_o), //port b priority is high
    .cub_greg_wdata_b           (regfile_alu_wdata_fw_i),
    //.cub_greg_we_b              (regfile_alu_we_fw_i),
    .cub_greg_we_b              (regfile_alu_we_ex_fifo_o),

    .cub_id_i                   (cub_id_i),

    //to alu reg
    .cub_mult_param_sel_i       (cub_mult_param_sel_i),
    .cub_arithmetic_param_sel_i (cub_arithmetic_param_sel_i),
    .cub_activ_param_sel_i      (cub_activ_param_sel_i),
    
    .cub_mult_lambda_o          (cub_mult_lambda_o),
    .cub_mult_truncate_Q_o      (cub_mult_truncate_Q_o),
    .cub_arithmetic_bias_o      (cub_arithmetic_bias_o),
    //.cub_arithmetic_trun_en_o   (cub_arithmetic_trun_en_o),
    //.cub_arithmetic_trun_prec_o (cub_arithmetic_trun_prec_o),
    .cub_arithmetic_trun_Q_o    (cub_arithmetic_trun_Q_o),
    .cub_arithmetic_trun_elt_Q_o(cub_arithmetic_trun_elt_Q_o),
    .cub_activ_prelu_scaling_o  (cub_activ_prelu_scaling_o),
    .cub_activ_mul_pdt_Qp_o     (cub_activ_mul_pdt_Qp_o),
    .cub_activ_relu6_bias_o     (cub_activ_relu6_bias_o),
    .cub_activ_relu6_ref_max_o  (cub_activ_relu6_ref_max_o),
    .cub_activ_relu6_ref_min_o  (cub_activ_relu6_ref_min_o),

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


    //Forwarding control signals
    assign reg_d_ex_is_reg_a  = (regfile_waddr_ex_o     == regfile_addr_ra_id) && (rega_used_dec == 1'b1) && (regfile_addr_ra_id != '0);
    assign reg_d_ex_is_reg_b  = (regfile_waddr_ex_o     == regfile_addr_rb_id) && (regb_used_dec == 1'b1) && (regfile_addr_rb_id != '0);
    //assign reg_d_ex_is_reg_c  = (regfile_waddr_ex_o     == regfile_addr_rc_id) && (regc_used_dec == 1'b1) && (regfile_addr_rc_id != '0);
    //assign reg_d_wb_is_reg_a  = (regfile_waddr_wb_i     == regfile_addr_ra_id) && (rega_used_dec == 1'b1) && (regfile_addr_ra_id != '0);
    //assign reg_d_wb_is_reg_b  = (regfile_waddr_wb_i     == regfile_addr_rb_id) && (regb_used_dec == 1'b1) && (regfile_addr_rb_id != '0);
    assign reg_d_wb_is_reg_a  = (regfile_waddr_ex_o     == regfile_addr_ra_id) && (rega_used_dec == 1'b1) && (regfile_addr_ra_id != '0);
    assign reg_d_wb_is_reg_b  = (regfile_waddr_ex_o     == regfile_addr_rb_id) && (regb_used_dec == 1'b1) && (regfile_addr_rb_id != '0);
    //assign reg_d_wb_is_reg_c  = (regfile_waddr_wb_i     == regfile_addr_rc_id) && (regc_used_dec == 1'b1) && (regfile_addr_rc_id != '0);
    //assign reg_d_alu_is_reg_a = (regfile_alu_waddr_fw_i == regfile_addr_ra_id) && (rega_used_dec == 1'b1) && (regfile_addr_ra_id != '0);
    //assign reg_d_alu_is_reg_b = (regfile_alu_waddr_fw_i == regfile_addr_rb_id) && (regb_used_dec == 1'b1) && (regfile_addr_rb_id != '0);
      assign reg_d_alu_is_reg_a = (regfile_alu_waddr_ex_o == regfile_addr_ra_id) && (rega_used_dec == 1'b1) && (regfile_addr_ra_id != '0);
      assign reg_d_alu_is_reg_b = (regfile_alu_waddr_ex_o == regfile_addr_rb_id) && (regb_used_dec == 1'b1) && (regfile_addr_rb_id != '0);
    //assign reg_d_alu_is_reg_c = (regfile_alu_waddr_fw_i == regfile_addr_rc_id) && (regc_used_dec == 1'b1) && (regfile_addr_rc_id != '0);

    //==========Forwarding Ctrl==========
    always_comb begin
        //default assignements
        operand_a_fw_mux_sel = SEL_REGFILE;
        operand_b_fw_mux_sel = SEL_REGFILE;
        //operand_c_fw_mux_sel = SEL_REGFILE;

     //   //Forwarding WB -> ID
     //   if(regfile_we_wb_i == 1'b1) begin
     //       if(reg_d_wb_is_reg_a == 1'b1)
     //           operand_a_fw_mux_sel = SEL_FW_WB;
     //       if(reg_d_wb_is_reg_b == 1'b1)
     //           operand_b_fw_mux_sel = SEL_FW_WB;
     //       //if(reg_d_wb_is_reg_c == 1'b1)
     //       //    operand_c_fw_mux_sel = SEL_FW_WB;
     //   end

     //   //Forwarding EX -> ID
     //   if(regfile_alu_we_fw_i == 1'b1) begin
     //       if(reg_d_alu_is_reg_a == 1'b1)
     //           operand_a_fw_mux_sel = SEL_FW_EX;
     //       if(reg_d_alu_is_reg_b == 1'b1)
     //           operand_b_fw_mux_sel = SEL_FW_EX;
     //       //if(reg_d_alu_is_reg_c == 1'b1)
     //       //    operand_c_fw_mux_sel = SEL_FW_EX;
     //   end
     
     //based on adjoining instr ex action
        //Forwarding WB -> ID
        if(regfile_we_wb_i/*regfile_we_ex_o*/ == 1'b1) begin
            if(reg_d_wb_is_reg_a == 1'b1)
                operand_a_fw_mux_sel = SEL_FW_WB;
            if(reg_d_wb_is_reg_b == 1'b1)
                operand_b_fw_mux_sel = SEL_FW_WB;
            //if(reg_d_wb_is_reg_c == 1'b1)
            //    operand_c_fw_mux_sel = SEL_FW_WB;
        end

        //Forwarding EX -> ID
        if(regfile_alu_we_ex_fifo_o/*regfile_alu_we_ex_o*/ == 1'b1) begin
            if(reg_d_alu_is_reg_a == 1'b1)
                operand_a_fw_mux_sel = SEL_FW_EX;
            if(reg_d_alu_is_reg_b == 1'b1)
                operand_b_fw_mux_sel = SEL_FW_EX;
            //if(reg_d_alu_is_reg_c == 1'b1)
            //    operand_c_fw_mux_sel = SEL_FW_EX;
        end
    end

    cub_decoder U_cub_decoder(
        .Cub_instr_i                (Cub_instr_i                ),
        .Cub_illegal_insn_o         (Cub_illegal_insn           ),
        .deassert_we_i              (deassert_we_i              ),
                                                                
        .alu_en_o                   (alu_en                     ), //ALU enable
        .alu_operator_o             (alu_operator               ), //ALU operation selection
        .alu_op_a_mux_sel_o         (alu_op_a_mux_sel           ), //operand a selection: reg value, PC, immediate or zero
        .alu_op_b_mux_sel_o         (alu_op_b_mux_sel           ), //operand b selection: reg value or immediate
        //.alu_op_c_mux_sel_o         (alu_op_c_mux_sel           ), //operand c selection: reg value or jump target
        .alu_vec_mode_o             (alu_vec_mode               ), // selects between 32 bit, 16 bit and 8 bit vectorial modes
        .imm_a_mux_sel_o            (imm_a_mux_sel              ), //immediate selection for operand a
        .imm_b_mux_sel_o            (imm_b_mux_sel              ), //immediate selection for operand b
        .alu_trun_prec_o            (alu_trun_prec              ), //0:int8 1:int16
        .alu_trun_Q_o               (alu_trun_Q                 ), 
                                                                
        .mult_int_en_o              (mult_int_en                ), // perform integer multiplication
        .mult_operator_o            (mult_operator              ), // Multiplication operation selection
        .mult_signed_mode_o         (mult_signed_mode           ), // Multiplication in signed mode
        .mult_sel_subword_o         (mult_sel_subword           ), // Select subwords for 16x16 bit of multiplier
                                                                
        .rega_used_o                (rega_used_dec              ), //rs1 is used by current instruction
        .regb_used_o                (regb_used_dec              ), //rs2 is used by current instruction
                                                                
        .regfile_mem_we_o           (regfile_we_id              ), //write enable for regfile
        .regfile_alu_we_o           (regfile_alu_we_id          ), //write enable for 2nd regfile port
        .regfile_alu_waddr_sel_o    (regfile_alu_waddr_mux_sel  ), //Select register write address for ALU/MUL operations
                                                                
        .data_req_o                 (data_req_id                ), //start transaction to data memory
        .data_we_o                  (data_we_id                 ), //data memory write enable
        .data_type_o                (data_type_id               ), //00:byte 01:halfword 10:word
        .data_ram_sel_o             (data_ram_sel_id            ), //00:l1b 01:cram 10:scache
        .data_sign_extension_o      (data_sign_ext_id           ), //0:signed ext 1:zero
        
        .scache_en_o                (scache_en_id               ),
        .scache_we_o                (scache_we_id               ),
        .scache_size_o              (scache_size_id             ),
        .scache_sign_ext_o          (scache_sign_ext_id         ),
        //.l1b_en_o                   (l1b_en_id                  ),
        //.l1b_we_o                   (l1b_we_id                  ),
        //.l1b_size_o                 (l1b_size_id                ),
        //.l1b_sign_ext_o             (l1b_sign_ext_id          ),

        .acti_en_o                  (acti_en                    ),
        .acti_operator_o            (acti_operator              ),
        .pool_en_o                  (pool_en                    ),
        .pool_operator_o            (pool_operator              ),
        .pool_comp_sign_o           (pool_comp_sign             ),
        .pool_comp_vect_o           (pool_comp_vect             ),
        .pool_comp_mode_o           (pool_comp_mode             ),

        .csr_access_o               (csr_access                 ), //access to CSR

        .cflow_nop_en_o             (cflow_nop_en               ),
        .cflow_nop_cycle_num_o      (cflow_nop_cycle_num        )
    );

    logic   cflow_nop_en_r;
    always_ff@(posedge clk or negedge rst_n) begin
        if(!rst_n)
            cflow_nop_en_r <= 1'b0;
        else
            cflow_nop_en_r <= cflow_nop_en;
    end
    assign cflow_nop_en_o = cflow_nop_en_r&cflow_nop_en;

    //============================
    //  ID pipeline reg 
    //============================
    always_ff@(posedge clk or negedge rst_n) begin : ID_EX_PIPE_REGISTERS
        if(!rst_n) begin
            alu_en_ex_o           <= 'b0;
            alu_operator_ex_o     <= ALU_SLTU;
            alu_operand_a_ex_o    <= 'b0;
            alu_operand_b_ex_o    <= 'b0;
            alu_operand_c_ex_o    <= 'b0;
            alu_vec_mode_ex_o      <= 'b0;
            alu_trun_prec_ex_o    <= 'b0;

            mult_en_ex_o          <= 1'b0;
            mult_operator_ex_o    <= 'b0;
            mult_operand_a_ex_o   <= 'b0;
            mult_operand_b_ex_o   <= 'b0;
            //mult_operand_c_ex_o   <= 'b0;
            mult_signed_mode_ex_o <= 2'b00;
            mult_sel_subword_ex_o <= 1'b0;

            regfile_waddr_ex_o    <= 6'b0;
            regfile_we_ex_o       <= 1'b0;
            regfile_alu_we_ex_o   <= 1'b0;
            regfile_alu_waddr_ex_o <= 6'b0;

            csr_access_ex_o     <= 1'b0;
           
            data_req_ex_o        <= 1'b0;
            data_we_ex_o         <= 1'b0;
            data_type_ex_o       <= 2'b0;
            data_ram_sel_ex_o    <= 2'b0;
            data_sign_extension_ex_o <= 1'b0; 

            scache_en_ex_o         <= 1'b0;
            scache_we_ex_o         <= 1'b0;
            scache_addr_ex_o       <= 9'b0;
            scache_size_ex_o       <= 2'b0;
            scache_sign_ext_ex_o   <= 1'b0;

            //l1b_en_o            <= 1'b0;
            //l1b_we_o            <= 1'b0;
            //l1b_size_o          <= 2'b0;
            //l1b_sign_ext_o      <= 1'b0;

            acti_en_ex_o        <= 1'b0;
            acti_operator_ex_o  <= 8'b0;
            acti_operand_a_ex_o <= 'b0;
            pool_en_ex_o        <= 1'b0;
            pool_operator_ex_o  <= 2'b0;
            pool_operand_a_ex_o <= 'b0;
            pool_operand_b_ex_o <= 'b0;
            pool_comp_sign_ex_o <= 'b0;
            pool_comp_vect_ex_o <= 'b0;
            pool_comp_mode_ex_o <= 'b0;             
        end
        else if(cub_cflow_mode_i | cflow_nop_en_o | l1b_load_to_crossbar_sel_i) begin //cflow mode
            //arith reg
            //alu_operator_ex_o <= ALU_ADD;
            if(cub_crbr_cflow_valid_out_i[ALU]) begin
                alu_operand_a_ex_o <= cub_crbr_cflow_data_out_i[ALU];
                alu_en_ex_o <= 1'b1;
            end
            else begin
                alu_en_ex_o <= 1'b0;
            end

            //mult reg
            mult_operator_ex_o <= MUL_MAC32;
            mult_signed_mode_ex_o <= 2'b00;
            if(cub_crbr_cflow_valid_out_i[MULT]) begin
                mult_operand_a_ex_o <= cub_crbr_cflow_data_out_i[MULT];
                mult_en_ex_o <= 1'b1;
            end
            else begin
                mult_en_ex_o <= 1'b0;
            end

            //acti reg
            if(cub_crbr_cflow_valid_out_i[ACTI]) begin
                acti_operand_a_ex_o <= cub_crbr_cflow_data_out_i[ACTI];
                acti_en_ex_o <= 1'b1;
            end
            else begin
                acti_en_ex_o <= 1'b0;
            end

            //pool reg
            if(cub_crbr_cflow_valid_out_i[POOL]) begin
                pool_operand_a_ex_o <= cub_crbr_cflow_data_out_i[POOL];
                pool_operand_b_ex_o <= cub_pooling_cflow_reg1_act_i ? cub_pool_rslt_i : pool_operand_a_ex_o;
                pool_en_ex_o <= 1'b1;
            end
            else begin
                pool_en_ex_o <= 1'b0;
            end

            //l1b load to crossbar
            if(id_valid) begin
                data_req_ex_o <= data_req_id;
                if(data_req_id) begin //only needed for LSU when there is an active request
                    data_we_ex_o    <= data_we_id;
                    data_type_ex_o  <= data_type_id;
                    data_ram_sel_ex_o  <= data_ram_sel_id;
                    data_sign_extension_ex_o <= data_sign_ext_id;
                end
            end
            else begin
                data_req_ex_o <= 1'b0;
            end
        end
        else begin //normal pipeline unstall case
            deassert_we_ex_o <= deassert_we_i; 
            if(id_valid) begin //unstall the whole pipeline
                alu_en_ex_o <= alu_en;
                mult_en_ex_o <= mult_int_en;
                
                if(alu_en) begin //alu
                    alu_operator_ex_o  <= alu_operator;
                    alu_operand_a_ex_o <= alu_operand_a;
                    alu_operand_b_ex_o <= alu_operand_b;
                    alu_operand_c_ex_o <= alu_operand_c;
                    alu_vec_mode_ex_o  <= alu_vec_mode;
                    alu_trun_prec_ex_o <= alu_trun_prec;
                    alu_trun_Q_ex_o    <= alu_trun_Q;
                end

                if(mult_int_en) begin //mult
                    mult_operator_ex_o    <= mult_operator;
                    mult_operand_a_ex_o   <= alu_operand_a;
                    mult_operand_b_ex_o   <= alu_operand_b;
                    //mult_operand_c_ex_o   <= alu_operand_c;
                    mult_signed_mode_ex_o <= mult_signed_mode;
                    mult_sel_subword_ex_o <= mult_sel_subword;
                end
                
                //wport a
                regfile_we_ex_o <= regfile_we_id;
                if(regfile_we_id) begin
                    regfile_waddr_ex_o <= regfile_waddr_id;
                end
                //wprot b
                regfile_alu_we_ex_o <= regfile_alu_we_id;
                if(regfile_alu_we_id) begin
                    regfile_alu_waddr_ex_o <= regfile_alu_waddr_id;
                end
                
                csr_access_ex_o     <= csr_access;

                //LSU
                data_req_ex_o <= data_req_id;
                if(data_req_id) begin //only needed for LSU when there is an active request
                    data_we_ex_o    <= data_we_id;
                    data_type_ex_o  <= data_type_id;
                    data_ram_sel_ex_o  <= data_ram_sel_id;
                    data_sign_extension_ex_o <= data_sign_ext_id;
                end
                //data_misaligned_ex_o <= 1'b0;
                
                scache_en_ex_o <= scache_en_id;
                if(scache_en_id) begin
                    scache_we_ex_o <= scache_we_id;
                    scache_size_ex_o <= scache_size_id;
                    scache_addr_ex_o <= alu_operand_a[8:0];
                    scache_sign_ext_ex_o <= scache_sign_ext_id;
                end
                //l1b_en_o <= l1b_en_id;
                //if(l1b_en_id) begin
                //    l1b_we_o <= l1b_we_id;
                //    l1b_size_o <= l1b_size_id;
                //    l1b_sign_ext_o <= l1b_sign_ext_id;
                //end

                acti_en_ex_o <= acti_en;
                if(acti_en) begin
                    acti_operator_ex_o  <= acti_operator;
                    acti_operand_a_ex_o <= alu_operand_a;
                end
                pool_en_ex_o <= pool_en;
                if(pool_en) begin
                    pool_operator_ex_o <= pool_operator;
                    pool_operand_a_ex_o <= alu_operand_a;
                    pool_operand_b_ex_o <= alu_operand_b;
                    pool_comp_sign_ex_o <= pool_comp_sign;
                    pool_comp_vect_ex_o <= pool_comp_vect;
                    pool_comp_mode_ex_o <= pool_comp_mode;                    

/*
                    case(pool_operator) 
                    //00:a->R0, b->R1, R0 comp R1, rslt->rd; 
                    //01:a->R0. R0->R1, R0 comp R1, rslt->rd; 
                    //10:a->R0, rslt'->R1, R0 comp R1, rslt->rd;
                    2'b00:  begin
                        pool_operand_a_ex_o <= alu_operand_a;
                        pool_operand_b_ex_o <= alu_operand_b;
                        end
                    2'b01: begin
                        pool_operand_a_ex_o <= alu_operand_a;
                        pool_operand_b_ex_o <= pool_operand_a_ex_o;
                        end
                    2'b10: begin
                        pool_operand_a_ex_o <= alu_operand_a;
                        pool_operand_b_ex_o <= cub_pool_rslt_i;
                        end
                    endcase
*/
                end
                
            end
            else begin
                if(ex_ready_i) begin //EX stage is ready but we don't have a new instruction for it,
                                     //so we set all write enables to 0, but unstall the pipe
                    regfile_we_ex_o      <= 1'b0;
                    //regfile_alu_we_ex_o  <= 1'b0;

                    data_req_ex_o        <= 1'b0;

                    //alu_en_ex_o          <= 1'b1;
                    //alu_operator_ex_o    <= ALU_SLTU;
                    //mult_en_ex_o         <= 1'b0;

                    scache_en_ex_o       <= 1'b0;
                    //l1b_en_o             <= 1'b0;

                    //acti_en_ex_o         <= 1'b0;
                    //pool_en_ex_o         <= 1'b0;

                    csr_access_ex_o      <= 1'b0;
                end
                else if (csr_access_ex_o) begin
                 //In the EX stage there was a CSR access, to avoid multiple
                 //writes to the RF, disable regfile_alu_we_ex_o.
                 //Not doing it can overwrite the RF file with the currennt CSR value rather than the old one
                 regfile_alu_we_ex_o         <= 1'b0;
                end
            end
        end
    end

    //stall control
    assign id_valid = Cub_instr_valid_i /*& ex_ready_i & (& ~halt_id)*/;

    // fu instr pipe flow 
    wire alu_en_fifo_o_w,mult_int_en_fifo_o_w,acti_en_fifo_o_w,pool_en_fifo_o_w,regfile_alu_we_ex_fifo_o_w ;
    wire [RF_ADDR_WIDTH-1:0] regfile_alu_waddr_ex_fifo_o_w ;

    wire ctrl_fifo_full,ctrl_fifo_empty;

    wire  regfile_alu_we_ex_fifo_vld = ex_valid_i && regfile_alu_we_ex_fifo_o_w;

    assign  alu_en_fifo_o                                     = ctrl_fifo_empty ? alu_en_ex_o           : alu_en_fifo_o_w             ;
    assign  mult_int_en_fifo_o                                = ctrl_fifo_empty ? mult_en_ex_o          : mult_int_en_fifo_o_w        ;
    assign  acti_en_fifo_o                                    = ctrl_fifo_empty ? acti_en_ex_o          : acti_en_fifo_o_w            ;
    assign  pool_en_fifo_o                                    = ctrl_fifo_empty ? pool_en_ex_o          : pool_en_fifo_o_w            ; 
    assign  regfile_alu_we_ex_fifo_o                          = regfile_alu_we_ex_fifo_vld  ;
    assign  regfile_alu_waddr_ex_fifo_o                       = ctrl_fifo_empty ? regfile_alu_waddr_ex_o: regfile_alu_waddr_ex_fifo_o_w;




    wire id_ctrl_fifo_push_req = (!cub_cflow_mode_i)&&regfile_alu_we_id&&(alu_en||mult_int_en||acti_en||pool_en);
    wire id_ctrl_fifo_pop_req = ex_valid_i ;

    DW_fifo_s1_sf #(.width(10),  .depth(3),   .err_mode(0),  .rst_mode(0)) //depth need to be redefined   according to read_pipe_delay cycle
    U_cub_id_ctrl_fifo (
        .clk                (clk                        ),   
        .rst_n              (rst_n                      ),   
        .push_req_n         (!(id_ctrl_fifo_push_req&&!ctrl_fifo_full)), //only read operate can push 
        .pop_req_n          (!(id_ctrl_fifo_pop_req&&!ctrl_fifo_empty)), 
        .diag_n             (1'b1   ),
        .empty              (ctrl_fifo_empty),
        .almost_empty       (),   
        .half_full          (),
        .almost_full        (),   
        .full               (ctrl_fifo_full),
        .error              (),   
        .data_in            ({alu_en,mult_int_en,acti_en,pool_en,regfile_alu_we_id, regfile_alu_waddr_id } ),   
        .data_out           ({alu_en_fifo_o_w,mult_int_en_fifo_o_w,acti_en_fifo_o_w,pool_en_fifo_o_w,regfile_alu_we_ex_fifo_o_w, regfile_alu_waddr_ex_fifo_o_w  } )
        );

endmodule
