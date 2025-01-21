/*
Design Name     : Instruction Decode Stage
Data            : 2024/1/24          
Description     : It decodes the instructions and hosts the register file.
*/

// Source/Destination register instruction index
`define REG_S1 19:15
`define REG_S2 24:20
`define REG_S4 31:27
`define REG_D  11:07

module riscv_id_stage
#(
    parameter RF_ADDR_WIDTH = 5,
    parameter HWLP_NUM = 4
)
(
    input                               clk,
    input                               rst_n,

    input                               test_en_i,
    input                               fetch_enable_i,
    output logic                        ctrl_busy_o,
    output logic                        core_ctrl_firstfetch_o,
    output logic                        is_decoding_o,
    output logic                        core_sleep_en_o, //to Noc


    //NPU
    output logic                        npu_en_mu_o,
    output logic [31:0]                 instr_npu_mu_o,

    output logic                        MQ_Cfifo_req_o,
    output logic                        VQ_Cfifo_req_o,
    output logic                        SQ_Cfifo_req_o,
    output logic                        ALU_Cfifo_req_o,
    output logic [31:0]                 Cfifo_data_in_o,
    input                               MQ_Cfifo_full_i,
    input                               VQ_Cfifo_full_i,
    input                               SQ_Cfifo_full_i,
    input                               ALU_Cfifo_full_i,

    output logic                        is_VQ_insn_o,
    output logic                        is_MQ_insn_o,
    output logic                        is_SQ_insn_o,
    output logic                        is_Cub_alu_insn_o,

    input                               mu_VQ_ready_i,
    input                               mu_MQ_ready_i,
    input                               mu_SQ_ready_i,
    input                               mu_Cub_alu_ready_i,

    output logic                        MQ_clear_o,
    output logic                        VQ_clear_o,
    output logic                        SQ_clear_o,
    output logic                        MQ_Cfifo_clear_o,
    output logic                        VQ_Cfifo_clear_o,
    output logic                        SQ_Cfifo_clear_o,
    output logic                        ALU_Cfifo_clear_o,

    //from/to IF stage
    output                              instr_req_o,  //ID want to start to fetch instr, to IF
    input   [31:0]                      instr_rdata_i,//from IF
    input                               instr_valid_i,
    input                               is_hwlp_i,
    input   [HWLP_NUM-1:0]              hwlp_cnt_dec_i,
    
    input                               is_compressed_i,
    input                               illegal_c_instr_i,
    input                               is_fetch_failed_i,
    input   [31:0]                      pc_if_i,
    input   [31:0]                      pc_id_i,
    output  logic                       is_npu_insn_if_o, //to IF stage

    output                              pc_set_o,
    output  logic [2+1:0]               pc_mux_o,
    output  logic [2:0]                 exc_pc_mux_o,
    output  logic                       trap_addr_mux_o,
    output  logic                       clear_instr_valid_o,

    //Jumps and branches
    output logic                        branch_in_ex_o,
    input                               branch_decision_i, //alu_cmp_result
    output logic [31:0]                 jump_target_o,

    //stall
    output logic                        halt_if_o,  //controller requests a halt of the IF stage

    output logic                        id_ready_o, //ID stage is ready for the next instruction
    input                               ex_ready_i, //EX stage is ready for the next instruction
    input                               wb_ready_i, //WB stage is ready for the next instruction

    output logic                        id_valid_o, //ID stage is done
    input                               ex_valid_i, //EX stage is done

    //Pipeline ED/EX
    output logic [31:0]                 pc_ex_o,

    output logic [RF_ADDR_WIDTH-1:0]    regfile_waddr_ex_o,     //write prot a
    output logic                        regfile_we_ex_o,
    output logic [RF_ADDR_WIDTH-1:0]    regfile_alu_waddr_ex_o, //write prot b
    output logic                        regfile_alu_we_ex_o,

    //ALU
    output  logic                       alu_en_ex_o,
    output  logic [7-1:0]               alu_operator_ex_o,
    output  logic [31:0]                alu_operand_a_ex_o,
    output  logic [31:0]                alu_operand_b_ex_o,
    output  logic [31:0]                alu_operand_c_ex_o,

    //MUL
    output logic                        mult_en_ex_o,
    output logic [ 2:0]                 mult_operator_ex_o,
    output logic [31:0]                 mult_operand_a_ex_o, //mul
    output logic [31:0]                 mult_operand_b_ex_o,
    //output logic [31:0]                 mult_operand_c_ex_o,
    output logic [ 1:0]                 mult_signed_mode_ex_o,

    //output logic [31:0]                 mult_dot_op_a_ex_o,  //dot
    //output logic [31:0]                 mult_dot_op_b_ex_o,
    //output logic [31:0]                 mult_dot_op_c_ex_o,
    //output logic [ 1:0]                 mult_dot_signed_ex_o,    
    

    //hwloop signals
    output logic [HWLP_NUM-1:0][31:0]   hwlp_start_o,
    output logic [HWLP_NUM-1:0][31:0]   hwlp_end_o,
    output logic [HWLP_NUM-1:0][31:0]   hwlp_cnt_o,
    //hwloop signals from CS register
    input  [1:0]                        csr_hwlp_regid_i,
    input  [2:0]                        csr_hwlp_we_i,
    input  [31:0]                       csr_hwlp_data_i,

    //Interface to Load Store unit
    output logic                        data_req_ex_o,
    output logic                        data_we_ex_o,
    output logic [1:0]                  data_type_ex_o,
    output logic [1:0]                  data_sign_ext_ex_o,
    output logic [1:0]                  data_reg_offset_ex_o,
    output logic                        data_load_event_ex_o,

    output logic                        data_misaligned_ex_o,
    input                               data_misaligned_i,
    output logic                        prepost_useincr_ex_o,
    input                               data_err_i,
    //output logic                        data_err_ack_o,

    //Interrupt signals
    input                   irq_i,
    input   [4:0]           irq_id_i,
    input                   irq_sec_i,
    input                   m_irq_enable_i,
    input                   u_irq_enable_i,
    output  logic           irq_ack_o,
    output  logic [4:0]     irq_id_o,
    output  logic [5:0]     exc_cause_o,

    //Debug Signal
    output logic        debug_mode_o,
    output logic [2:0]  debug_cause_o,
    output logic        debug_csr_save_o,
    input  logic        debug_req_i,
    input  logic        debug_single_step_i,
    input  logic        debug_ebreakm_i,
    input  logic        debug_ebreaku_i,

    // CSR ID/EX
    output logic        csr_access_ex_o,
    output logic [1:0]  csr_op_ex_o,
    input  [1:0]        current_priv_lvl_i,
    output logic        csr_irq_sec_o,
    output logic [5:0]  csr_cause_o,
    output logic        csr_save_if_o,
    output logic        csr_save_id_o,
    output logic        csr_save_ex_o,
    output logic        csr_restore_mret_id_o,
    output logic        csr_restore_uret_id_o,
    output logic        csr_restore_dret_id_o,
    output logic        csr_save_cause_o,

    //Forward Signals
    input   [RF_ADDR_WIDTH-1:0]         regfile_waddr_wb_i,
    input                               regfile_we_wb_i,
    input   [31:0]                      regfile_wdata_wb_i, //From wb_stage: selects data from data memory, ex_stage result and sp rdata

    input   [RF_ADDR_WIDTH-1:0]         regfile_alu_waddr_fw_i,
    input                               regfile_alu_we_fw_i,
    input   [31:0]                      regfile_alu_wdata_fw_i,   

    //from ALU
    //input                               mult_multicycle_i, //when we need multiple cycles in the multiplier and use op c as storage

    //Performance Counters
    output logic        perf_jump_o,          // we are executing a jump instruction
    output logic        perf_jr_stall_o,      // jump-register-hazard
    output logic        perf_ld_stall_o,      // load-use-hazard
    output logic        perf_pipeline_stall_o //extra cycles from elw
);

`include "decode_param.v"
    
      

    logic   [1:0]           imm_a_mux_sel;
    logic   [3:0]           imm_b_mux_sel;
    logic   [1:0]           jump_target_mux_sel;
    logic   [31:0]          jump_target; // calculated jump target (-> EX -> IF)

    //Immediate decoding and sign extension
    logic   [31:0]          imm_i_type;
    logic   [31:0]          imm_iz_type;
    logic   [31:0]          imm_s_type;
    logic   [31:0]          imm_sb_type;
    logic   [31:0]          imm_u_type;
    logic   [31:0]          imm_uj_type;
    logic   [31:0]          imm_z_type;
    logic   [31:0]          imm_s2_type;
    logic   [31:0]          imm_bi_type;
    logic   [31:0]          imm_s3_type;
    logic   [31:0]          imm_vs_type;
    logic   [31:0]          imm_vu_type;
    logic   [31:0]          imm_shuffleb_type;
    logic   [31:0]          imm_shuffleh_type;
    logic   [31:0]          imm_shuffle_type;
    logic   [31:0]          imm_clip_type;

    logic [31:0]            imm_a;       
    logic [31:0]            imm_b;           

    //Signals running between controller and exception controller
    logic       irq_req_ctrl, irq_sec_ctrl;
    logic [4:0] irq_id_ctrl;
    logic       exc_ack, exc_kill;// handshake

    //Regfile interface
    logic [RF_ADDR_WIDTH-1:0]   regfile_addr_ra_id;//raddr
    logic [RF_ADDR_WIDTH-1:0]   regfile_addr_rb_id;
    logic [RF_ADDR_WIDTH-1:0]   regfile_addr_rc_id;    
    logic [31:0]                regfile_data_ra_id;//rdata
    logic [31:0]                regfile_data_rb_id;
    logic [31:0]                regfile_data_rc_id;

    logic [RF_ADDR_WIDTH-1:0]   regfile_waddr_id;
    logic [RF_ADDR_WIDTH-1:0]   regfile_alu_waddr_id;
    logic                       regfile_alu_we_id, regfile_alu_we_dec_id;    

    logic reg_d_ex_is_reg_a_id, reg_d_ex_is_reg_b_id, reg_d_ex_is_reg_c_id;
    logic reg_d_wb_is_reg_a_id, reg_d_wb_is_reg_b_id, reg_d_wb_is_reg_c_id;
    logic reg_d_alu_is_reg_a_id, reg_d_alu_is_reg_b_id, reg_d_alu_is_reg_c_id;

    //Register Write Control
    logic                   regfile_we_id;
    logic                   regfile_alu_waddr_mux_sel;

    //ALU Control
    logic                   alu_en;
    logic [7-1:0]           alu_operator;
    logic [2:0]             alu_op_a_mux_sel;
    logic [2:0]             alu_op_b_mux_sel;
    logic [1:0]             alu_op_c_mux_sel;
    logic [1:0]             regc_mux;

    //Multiplier Control
    logic [2:0]             mult_operator;    // multiplication operation selection
    logic                   mult_en;          // multiplication is used instead of ALU
    logic                   mult_int_en;      // use integer multiplier
    logic [1:0]             mult_signed_mode; // Signed mode multiplication at the output of the controller, and before the pipe registers
    //logic                   mult_dot_en;      // use dot product
    logic [1:0]             mult_dot_signed;  // Signed mode dot products (can be mixed types)

    //Data Memory Control
    logic        data_we_id;
    logic [1:0]  data_type_id;
    logic [1:0]  data_sign_ext_id;
    logic [1:0]  data_reg_offset_id;
    logic        data_req_id;
    logic        data_load_event_id;

    //hwloop signals
    logic [1:0] hwloop_regid, hwloop_regid_int;
    logic [2:0] hwloop_we, hwloop_we_int, hwloop_we_masked;
    logic       hwloop_target_mux_sel;
    logic       hwloop_start_mux_sel;
    logic       hwloop_cnt_mux_sel;

    logic[31:0] hwloop_target;
    logic[31:0] hwloop_start, hwloop_start_int;
    logic[31:0] hwloop_end;
    logic[31:0] hwloop_cnt, hwloop_cnt_int;

    logic       hwloop_valid;

    //CSR control
    logic        csr_access;
    logic [1:0]  csr_op;
    logic        csr_status;    

    //Forwarding
    logic [1:0]             operand_a_fw_mux_sel;
    logic [1:0]             operand_b_fw_mux_sel;
    logic [1:0]             operand_c_fw_mux_sel;
    logic [31:0]            operand_a_fw_id;
    logic [31:0]            operand_b_fw_id;
    logic [31:0]            operand_c_fw_id;

    logic [31:0]            operand_b;
    logic [31:0]            operand_c;

    logic [31:0]            alu_operand_a;
    logic [31:0]            alu_operand_b;
    logic [31:0]            alu_operand_c;







    //NPU related signal
    logic        npu_insn;
    logic        npu_insn_if;
    logic        is_npu_insn;
    logic        MQ_Cfifo_req;
    logic        VQ_Cfifo_req;
    logic        SQ_Cfifo_req;
    logic        ALU_Cfifo_req;
    logic        Cfifo_stall;
    logic        mu_stall;
    logic        VQ_insn;
    logic        MQ_insn;
    logic        SQ_insn;
    logic        Cub_alu_insn;
    logic        MQ_clear;
    logic        VQ_clear;
    logic        SQ_clear;
    logic        MQ_Cfifo_clear;
    logic        VQ_Cfifo_clear;
    logic        SQ_Cfifo_clear;
    logic        ALU_Cfifo_clear;

    //Decoder/Controller, ID stage internal signals
    logic        deassert_we;
    logic        illegal_instr_dec;

    logic        ebrk_insn;
    logic        ecall_insn_dec;
    logic        pipe_flush_dec;
    logic        fencei_insn_dec;

    logic       mret_dec;
    logic       uret_dec;
    logic       dret_dec;
    logic       prepost_useincr;


    logic        mret_instr_dec;
    logic        uret_instr_dec;
    logic        dret_instr_dec;

    logic        rega_used_dec;
    logic        regb_used_dec;
    logic        regc_used_dec;

    logic        branch_taken_ex;
    logic [1:0]  jump_in_id;
    logic [1:0]  jump_in_dec;

    logic        misaligned_stall;
    logic        jr_stall;
    logic        load_stall;
    //logic        instr_multicycle;
    logic        hwloop_mask;
    logic        halt_id;


    logic   [31:0]                      instr;
    assign instr = instr_rdata_i;
    assign is_npu_insn_if_o = npu_insn_if;

    //immediate extraction and sign extension
    assign imm_i_type  = {{20{instr[31]}}, instr[31:20]};
    assign imm_iz_type = {           20'b0, instr[31:20]};
    assign imm_s_type  = {{20{instr[31]}}, instr[31:25], instr[11:7]};
    assign imm_sb_type = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
    assign imm_u_type  = {instr[31:12], 12'b0};
    assign imm_uj_type = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};

    //immediate for CSR manipulate (zero extended)
    assign imm_z_type  = {27'b0, instr[`REG_S1]};
    assign imm_s2_type = {27'b0, instr[24:20]};
    assign imm_bi_type = {{27{instr[24]}}, instr[24:20]};
    assign imm_s3_type = {27'b0, instr[29:25]};
    assign imm_vs_type = {{26{instr[24]}}, instr[24:20], instr[25]};
    assign imm_vu_type = {26'b0, instr[24:20], instr[25]};    


    //============================
    //  Operand
    //============================

    //==========Operand A==========
    //ALU_op_a Mux
    always_comb begin : alu_operand_a_mux
      case(alu_op_a_mux_sel)
        OP_A_REGA_OR_FWD:  alu_operand_a = operand_a_fw_id;
        OP_A_REGB_OR_FWD:  alu_operand_a = operand_b_fw_id;
        OP_A_REGC_OR_FWD:  alu_operand_a = operand_c_fw_id;
        OP_A_CURRPC:       alu_operand_a = pc_id_i;
        OP_A_IMM:          alu_operand_a = imm_a;
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
        OP_B_REGC_OR_FWD:  operand_b = operand_c_fw_id;
        OP_B_IMM:          operand_b = imm_b;
        OP_B_BMASK:        operand_b = $unsigned(operand_b_fw_id[4:0]);
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
        IMMB_PCINCR: imm_b = (is_compressed_i && (~data_misaligned_i)) ? 32'h2 : 32'h4;
        IMMB_S2:     imm_b = imm_s2_type;
        IMMB_BI:     imm_b = imm_bi_type;
        IMMB_S3:     imm_b = imm_s3_type;
        IMMB_VS:     imm_b = imm_vs_type;
        IMMB_VU:     imm_b = imm_vu_type;
        //IMMB_SHUF:   imm_b = imm_shuffle_type;
        //IMMB_CLIP:   imm_b = {1'b0, imm_clip_type[31:1]};
        default:     imm_b = imm_i_type;
      endcase
    end

    //==========Operand C==========
  
    assign alu_operand_c = operand_c; //choose normal or scalar replicated version of operand c

    //ALU_op_c Mux
    always_comb begin : alu_operand_c_mux
      case (alu_op_c_mux_sel)
        OP_C_REGC_OR_FWD:  operand_c = operand_c_fw_id;
        OP_C_REGB_OR_FWD:  operand_c = operand_b_fw_id;
        OP_C_JT:           operand_c = jump_target;
        default:           operand_c = operand_c_fw_id;
      endcase
    end    

    //Operand c forwarding mux
    always_comb begin : operand_c_fw_mux
      case (operand_c_fw_mux_sel)
        SEL_FW_EX:    operand_c_fw_id = regfile_alu_wdata_fw_i;
        SEL_FW_WB:    operand_c_fw_id = regfile_wdata_wb_i;
        SEL_REGFILE:  operand_c_fw_id = regfile_data_rc_id;
        default:      operand_c_fw_id = regfile_data_rc_id;
      endcase;
    end

    




    //==========Jump Target==========
    always_comb begin : jump_target_mux
      case(jump_target_mux_sel)
        JT_JAL:  jump_target = pc_id_i + imm_uj_type;
        JT_COND: jump_target = pc_id_i + imm_sb_type;
        JT_JALR: jump_target = regfile_data_ra_id + imm_i_type; //JALR: Cannot forward RS1, since the path is too long
        default: jump_target = regfile_data_ra_id + imm_i_type;
      endcase
    end    

    assign jump_target_o = jump_target;

    //============================
    //  Regfiles
    //============================
    riscv_register_file
    #(
        .ADDR_WIDTH(RF_ADDR_WIDTH),
        .DATA_WIDTH(32)
    )
    U_register_file
    (
        .clk                ( clk                ),
        .rst_n              ( rst_n              ),

        //.test_en_i          ( test_en_i          ),

        // Read port a
        .raddr_a_i          ( regfile_addr_ra_id ),
        .rdata_a_o          ( regfile_data_ra_id ),

        // Read port b
        .raddr_b_i          ( regfile_addr_rb_id ),
        .rdata_b_o          ( regfile_data_rb_id ),

        // Read port c
        .raddr_c_i          ( regfile_addr_rc_id ),
        .rdata_c_o          ( regfile_data_rc_id ),

        // Write port a
        .waddr_a_i          ( regfile_waddr_wb_i ),
        .wdata_a_i          ( regfile_wdata_wb_i ),
        .we_a_i             ( regfile_we_wb_i    ),

        // Write port b
        .waddr_b_i          ( regfile_alu_waddr_fw_i ),
        .wdata_b_i          ( regfile_alu_wdata_fw_i ),
        .we_b_i             ( regfile_alu_we_fw_i    )
    );

    //==========source register selection==========
    //assign regfile_addr_ra_id = {1'b0, instr[`REG_S1]};
    //assign regfile_addr_rb_id = {1'b0, instr[`REG_S2]};
    assign regfile_addr_ra_id = instr[`REG_S1];
    assign regfile_addr_rb_id = instr[`REG_S2];

    //register C mux
    always_comb begin
      case(regc_mux)
        REGC_ZERO:  regfile_addr_rc_id = 'b0;
        REGC_RD:    regfile_addr_rc_id = {1'b0, instr[`REG_D]};
        REGC_S1:    regfile_addr_rc_id = {1'b0, instr[`REG_S1]};
        REGC_S4:    regfile_addr_rc_id = {1'b0, instr[`REG_S4]};
        default:    regfile_addr_rc_id = 'b0;
      endcase
    end

    //==========destination register selection========== 
    //First Register Write Address 
    //assign regfile_waddr_id = {1'b0, instr[`REG_D]};
    assign regfile_waddr_id = instr[`REG_D];

    //Second Register Write Address Selection, Used for prepost load/store and multiplier
    assign regfile_alu_waddr_id = regfile_alu_waddr_mux_sel ? regfile_waddr_id : regfile_addr_ra_id;

    //Forwarding control signals
    assign reg_d_ex_is_reg_a_id  = (regfile_waddr_ex_o     == regfile_addr_ra_id) && (rega_used_dec == 1'b1) && (regfile_addr_ra_id != '0);
    assign reg_d_ex_is_reg_b_id  = (regfile_waddr_ex_o     == regfile_addr_rb_id) && (regb_used_dec == 1'b1) && (regfile_addr_rb_id != '0);
    assign reg_d_ex_is_reg_c_id  = (regfile_waddr_ex_o     == regfile_addr_rc_id) && (regc_used_dec == 1'b1) && (regfile_addr_rc_id != '0);
    assign reg_d_wb_is_reg_a_id  = (regfile_waddr_wb_i     == regfile_addr_ra_id) && (rega_used_dec == 1'b1) && (regfile_addr_ra_id != '0);
    assign reg_d_wb_is_reg_b_id  = (regfile_waddr_wb_i     == regfile_addr_rb_id) && (regb_used_dec == 1'b1) && (regfile_addr_rb_id != '0);
    assign reg_d_wb_is_reg_c_id  = (regfile_waddr_wb_i     == regfile_addr_rc_id) && (regc_used_dec == 1'b1) && (regfile_addr_rc_id != '0);
    assign reg_d_alu_is_reg_a_id = (regfile_alu_waddr_fw_i == regfile_addr_ra_id) && (rega_used_dec == 1'b1) && (regfile_addr_ra_id != '0);
    assign reg_d_alu_is_reg_b_id = (regfile_alu_waddr_fw_i == regfile_addr_rb_id) && (regb_used_dec == 1'b1) && (regfile_addr_rb_id != '0);
    assign reg_d_alu_is_reg_c_id = (regfile_alu_waddr_fw_i == regfile_addr_rc_id) && (regc_used_dec == 1'b1) && (regfile_addr_rc_id != '0);



    //============================
    //  Decoder
    //============================
    riscv_decoder 
    #(
        .ALU_OP_WIDTH(7),
        .PULP_SECURE(0)
    )
    U_decoder
    (
    .clk(clk),
    .rst_n(rst_n),
    
    .instr_rdata_i(instr),     
    .illegal_c_instr_i(illegal_c_instr_i), 
    
    .deassert_we_i(deassert_we), 
    .data_misaligned_i(data_misaligned_i),
    //.mult_multicycle_i(mult_multicycle_i),    
    //.instr_multicycle_o(instr_multicycle),

    .npu_insn_o(npu_insn),
    .npu_insn_if_o(npu_insn_if), //no reg to IF stage
    .MQ_Cfifo_req_o(MQ_Cfifo_req),
    .VQ_Cfifo_req_o(VQ_Cfifo_req),
    .SQ_Cfifo_req_o(SQ_Cfifo_req),
    .ALU_Cfifo_req_o(ALU_Cfifo_req),

    .VQ_insn_o(VQ_insn),
    .MQ_insn_o(MQ_insn),
    .SQ_insn_o(SQ_insn),
    .Cub_alu_insn_o(Cub_alu_insn),

    .MQ_clear_o(MQ_clear),
    .VQ_clear_o(VQ_clear),
    .SQ_clear_o(SQ_clear),
    .MQ_Cfifo_clear_o(MQ_Cfifo_clear),
    .VQ_Cfifo_clear_o(VQ_Cfifo_clear),
    .SQ_Cfifo_clear_o(SQ_Cfifo_clear),
    .ALU_Cfifo_clear_o(ALU_Cfifo_clear),

    .illegal_instr_o(illegal_instr_dec),
    .ebrk_insn_o(ebrk_insn),
    .ecall_insn_o(ecall_insn_dec),
    .pipe_flush_o(pipe_flush_dec),
    .fencei_insn_o(fencei_insn_dec),
    
    .mret_dec_o(mret_dec), 
    .uret_dec_o(uret_dec), 
    .dret_dec_o(dret_dec), 
    .mret_instr_o(mret_instr_dec),
    .uret_instr_o(uret_instr_dec),
    .dret_instr_o(dret_instr_dec),

    .rega_used_o(rega_used_dec),
    .regb_used_o(regb_used_dec),
    .regc_used_o(regc_used_dec),

    .alu_en_o(alu_en),
    .alu_operator_o(alu_operator),
    .alu_op_a_mux_sel_o(alu_op_a_mux_sel),
    .alu_op_b_mux_sel_o(alu_op_b_mux_sel),
    .alu_op_c_mux_sel_o(alu_op_c_mux_sel),
    .imm_a_mux_sel_o(imm_a_mux_sel),
    .imm_b_mux_sel_o(imm_b_mux_sel),
    .regc_mux_o(regc_mux),
    
    .mult_operator_o(mult_operator),
    .mult_int_en_o(mult_int_en),
    //.mult_dot_en_o(mult_dot_en),
    .mult_signed_mode_o(mult_signed_mode), 
    .mult_dot_signed_o(mult_dot_signed),  
   
    .regfile_mem_we_o(regfile_we_id),       
    .regfile_alu_we_o(regfile_alu_we_id),       
    .regfile_alu_we_dec_o(regfile_alu_we_dec_id),   
    .regfile_alu_waddr_sel_o(regfile_alu_waddr_mux_sel),

    .jump_target_mux_sel_o(jump_target_mux_sel), 
    .jump_in_dec_o(jump_in_dec),         
    .jump_in_id_o(jump_in_id),          
    
    .hwloop_we_o(hwloop_we_int),             
    .hwloop_target_mux_sel_o(hwloop_target_mux_sel), 
    .hwloop_start_mux_sel_o(hwloop_start_mux_sel),  
    .hwloop_cnt_mux_sel_o(hwloop_cnt_mux_sel),    
    
    .data_req_o(data_req_id),  
    .data_we_o(data_we_id),   
    .data_type_o(data_type_id), 
    .data_sign_extension_o(data_sign_ext_id),
    .data_reg_offset_o(data_reg_offset_id),
    .prepost_useincr_o(prepost_useincr),
    .data_load_event_o(data_load_event_id),

    .csr_access_o(csr_access),
    .csr_status_o(csr_status),
    .csr_op_o(csr_op),
    .current_priv_lvl_i(current_priv_lvl_i)
    ); //decoder





    //============================
    //  Controller
    //============================
    riscv_controller
    #(
        //.PULP_SECURE(0)
        .RF_ADDR_WIDTH(RF_ADDR_WIDTH)
    )
    U_controller
    (
      .clk                            ( clk                    ),
      .rst_n                          ( rst_n                  ),

      .fetch_enable_i                 ( fetch_enable_i         ),
      .ctrl_busy_o                    ( ctrl_busy_o            ),
      .first_fetch_o                  ( core_ctrl_firstfetch_o ),
      .is_decoding_o                  ( is_decoding_o          ),
      .is_fetch_failed_i              ( is_fetch_failed_i      ),
      .core_sleep_en_o                ( core_sleep_en_o        ),

      .npu_insn_i                     ( npu_insn               ),
      .is_npu_insn_o                  ( is_npu_insn            ),
      .is_npu_insn_i                  ( npu_en_mu_o            ),
      .MQ_Cfifo_req_i                 ( MQ_Cfifo_req_o         ),//( MQ_Cfifo_req           ),
      .VQ_Cfifo_req_i                 ( VQ_Cfifo_req_o         ),//( VQ_Cfifo_req           ),
      .SQ_Cfifo_req_i                 ( SQ_Cfifo_req_o         ),//( SQ_Cfifo_req           ),
      .ALU_Cfifo_req_i                ( ALU_Cfifo_req_o        ),//( ALU_Cfifo_req          ),
      .MQ_Cfifo_full_i                ( MQ_Cfifo_full_i        ),
      .VQ_Cfifo_full_i                ( VQ_Cfifo_full_i        ),
      .SQ_Cfifo_full_i                ( SQ_Cfifo_full_i        ),
      .ALU_Cfifo_full_i               ( ALU_Cfifo_full_i       ),
      .Cfifo_stall_o                  ( Cfifo_stall            ),
      .VQ_insn_i                    (is_VQ_insn_o),     //(VQ_insn),
      .MQ_insn_i                    (is_MQ_insn_o),     //(MQ_insn),
      .SQ_insn_i                    (is_SQ_insn_o),     //(SQ_insn),
      .Cub_alu_insn_i               (is_Cub_alu_insn_o),//(Cub_alu_insn),
      .mu_VQ_ready_i                (mu_VQ_ready_i),
      .mu_MQ_ready_i                (mu_MQ_ready_i),
      .mu_SQ_ready_i                (mu_SQ_ready_i),
      .mu_Cub_alu_ready_i           (mu_Cub_alu_ready_i),
      .mu_stall_o                   (mu_stall),

      // decoder related signals
      .deassert_we_o                  ( deassert_we            ),

      .illegal_instr_i                ( illegal_instr_dec      ),
      .ecall_insn_i                   ( ecall_insn_dec         ),
      .mret_insn_i                    ( mret_instr_dec          ),
      .uret_insn_i                    ( uret_instr_dec          ),
      .dret_insn_i                    ( dret_instr_dec          ),

      .mret_dec_i                     ( mret_dec               ),
      .uret_dec_i                     ( uret_dec               ),
      .dret_dec_i                     ( dret_dec               ),


      .pipe_flush_i                   ( pipe_flush_dec         ),
      .ebrk_insn_i                    ( ebrk_insn              ),
      .fencei_insn_i                  ( fencei_insn_dec        ),
      .csr_status_i                   ( csr_status             ),
      //.instr_multicycle_i             ( instr_multicycle       ),

      .hwloop_mask_o                  ( hwloop_mask            ),

      // from IF/ID pipeline
      .instr_valid_i                  ( instr_valid_i          ),

      // from prefetcher
      .instr_req_o                    ( instr_req_o            ),

      // to prefetcher
      .pc_set_o                       ( pc_set_o               ),
      .pc_mux_o                       ( pc_mux_o               ),
      .exc_pc_mux_o                   ( exc_pc_mux_o           ),
      .exc_cause_o                    ( exc_cause_o            ),
      .trap_addr_mux_o                ( trap_addr_mux_o        ),

      // LSU
      .data_req_ex_i                  ( data_req_ex_o          ),
      .data_we_ex_i                   ( data_we_ex_o           ),
      .data_misaligned_i              ( data_misaligned_i      ),
      .data_load_event_i              ( data_load_event_id     ),
      .data_err_i                     ( data_err_i             ),
      //.data_err_ack_o                 ( data_err_ack_o         ),

      // ALU
      //.mult_multicycle_i              ( mult_multicycle_i      ),

      // jump/branch control
      .branch_taken_ex_i              ( branch_taken_ex        ),
      .jump_in_id_i                   ( jump_in_id             ),
      .jump_in_dec_i                  ( jump_in_dec            ),

      // Interrupt Controller Signals
      .irq_i                          ( irq_i                  ),
      .irq_req_ctrl_i                 ( irq_req_ctrl           ),
      .irq_sec_ctrl_i                 ( irq_sec_ctrl           ),
      .irq_id_ctrl_i                  ( irq_id_ctrl            ),
      .m_Irq_Enable_i                 ( m_irq_enable_i         ),
      .u_Irq_Enable_i                 ( u_irq_enable_i         ),
      .current_priv_lvl_i             ( current_priv_lvl_i     ),

      .irq_ack_o                      ( irq_ack_o              ),
      .irq_id_o                       ( irq_id_o               ),

      .exc_ack_o                      ( exc_ack                ),
      .exc_kill_o                     ( exc_kill               ),

      // Debug Signal
      .debug_mode_o                   ( debug_mode_o           ),
      .debug_cause_o                  ( debug_cause_o          ),
      .debug_csr_save_o               ( debug_csr_save_o       ),
      .debug_req_i                    ( debug_req_i            ),
      .debug_single_step_i            ( debug_single_step_i    ),
      .debug_ebreakm_i                ( debug_ebreakm_i        ),
      .debug_ebreaku_i                ( debug_ebreaku_i        ),

      // CSR Controller Signals
      .csr_save_cause_o               ( csr_save_cause_o       ),
      .csr_cause_o                    ( csr_cause_o            ),
      .csr_save_if_o                  ( csr_save_if_o          ),
      .csr_save_id_o                  ( csr_save_id_o          ),
      .csr_save_ex_o                  ( csr_save_ex_o          ),
      .csr_restore_mret_id_o          ( csr_restore_mret_id_o  ),
      .csr_restore_uret_id_o          ( csr_restore_uret_id_o  ),
      .csr_restore_dret_id_o          ( csr_restore_dret_id_o  ),
      .csr_irq_sec_o                  ( csr_irq_sec_o          ),

      // Write targets from ID
      .regfile_we_id_i                ( regfile_alu_we_dec_id  ),
      .regfile_alu_waddr_id_i         ( regfile_alu_waddr_id   ),

      // Forwarding signals from regfile
      .regfile_we_ex_i                ( regfile_we_ex_o        ),
      .regfile_waddr_ex_i             ( regfile_waddr_ex_o     ),
      .regfile_we_wb_i                ( regfile_we_wb_i        ),

      // regfile port 2
      .regfile_alu_we_fw_i            ( regfile_alu_we_fw_i    ),

      // Forwarding detection signals
      .reg_d_ex_is_reg_a_i            ( reg_d_ex_is_reg_a_id   ),
      .reg_d_ex_is_reg_b_i            ( reg_d_ex_is_reg_b_id   ),
      .reg_d_ex_is_reg_c_i            ( reg_d_ex_is_reg_c_id   ),
      .reg_d_wb_is_reg_a_i            ( reg_d_wb_is_reg_a_id   ),
      .reg_d_wb_is_reg_b_i            ( reg_d_wb_is_reg_b_id   ),
      .reg_d_wb_is_reg_c_i            ( reg_d_wb_is_reg_c_id   ),
      .reg_d_alu_is_reg_a_i           ( reg_d_alu_is_reg_a_id  ),
      .reg_d_alu_is_reg_b_i           ( reg_d_alu_is_reg_b_id  ),
      .reg_d_alu_is_reg_c_i           ( reg_d_alu_is_reg_c_id  ),

      // Forwarding signals
      .operand_a_fw_mux_sel_o         ( operand_a_fw_mux_sel   ),
      .operand_b_fw_mux_sel_o         ( operand_b_fw_mux_sel   ),
      .operand_c_fw_mux_sel_o         ( operand_c_fw_mux_sel   ),

      // Stall signals
      .halt_if_o                      ( halt_if_o              ),
      .halt_id_o                      ( halt_id                ),

      .misaligned_stall_o             ( misaligned_stall       ),
      .jr_stall_o                     ( jr_stall               ),
      .load_stall_o                   ( load_stall             ),

      .id_ready_i                     ( id_ready_o             ),
      .ex_valid_i                     ( ex_valid_i             ),
      .wb_ready_i                     ( wb_ready_i             ),

      //Performance Counters
      .perf_jump_o                    ( perf_jump_o            ),
      .perf_jr_stall_o                ( perf_jr_stall_o        ),
      .perf_ld_stall_o                ( perf_ld_stall_o        ),
      .perf_pipeline_stall_o          ( perf_pipeline_stall_o  )
    ); //controller



    //============================
    //  Irq Controller
    //============================
    riscv_int_controller  U_int_controller
    (
      .clk                  ( clk                ),
      .rst_n                ( rst_n              ),

      //External Interrupt lines
      .irq_i                ( irq_i              ),
      .irq_sec_i            ( irq_sec_i          ),
      .irq_id_i             ( irq_id_i           ),

      //to controller
      .irq_req_ctrl_o       ( irq_req_ctrl       ),
      .irq_sec_ctrl_o       ( irq_sec_ctrl       ),
      .irq_id_ctrl_o        ( irq_id_ctrl        ),

      //handshake signals to controller
      .ctrl_ack_i           ( exc_ack            ),
      .ctrl_kill_i          ( exc_kill           ),

      .m_Irq_Enable_i       ( m_irq_enable_i     ),
      .u_Irq_Enable_i       ( u_irq_enable_i     ),
      //.current_priv_lvl_i   ( 1'b0 )
      .current_priv_lvl_i   ( current_priv_lvl_i )
    );



    //============================
    //  Hwloop regs
    //============================
    //hwloop register id
    assign hwloop_regid_int = instr[8:7];   //rd contains hwloop register id

    // hwloop target mux
    always_comb begin
      case (hwloop_target_mux_sel)
        1'b0: hwloop_target = pc_id_i + {imm_iz_type[30:0], 1'b0};
        1'b1: hwloop_target = pc_id_i + {imm_z_type[30:0], 1'b0};
      endcase
    end

    // hwloop start mux
    always_comb begin
      case (hwloop_start_mux_sel)
        1'b0: hwloop_start_int = hwloop_target;   //for PC + I imm
        1'b1: hwloop_start_int = pc_if_i;         //for next PC
      endcase
    end


    // hwloop cnt mux
    always_comb begin : hwloop_cnt_mux
      case (hwloop_cnt_mux_sel)
        1'b0: hwloop_cnt_int = imm_iz_type;
        1'b1: hwloop_cnt_int = operand_a_fw_id;
      endcase
    end

    /*
      when hwloop_mask is 1, the controller is about to take an interrupt
      the xEPC is going to have the hwloop instruction PC, therefore, do not update the
      hwloop registers to make clear that the instruction hasn't been executed.
      Although it may not be a HW bugs causing uninteded behaviours,
      it helps verifications processes when checking the hwloop regs
    */
    assign hwloop_we_masked = hwloop_we_int & ~{3{hwloop_mask}} & {3{id_ready_o}};

    //multiplex between access from instructions and access via CSR registers
    assign hwloop_start = hwloop_we_masked[0] ? hwloop_start_int : csr_hwlp_data_i;
    assign hwloop_end   = hwloop_we_masked[1] ? hwloop_target    : csr_hwlp_data_i;
    assign hwloop_cnt   = hwloop_we_masked[2] ? hwloop_cnt_int   : csr_hwlp_data_i;
    assign hwloop_regid = (|hwloop_we_masked) ? hwloop_regid_int : csr_hwlp_regid_i;
    assign hwloop_we    = (|hwloop_we_masked) ? hwloop_we_masked : csr_hwlp_we_i; 


    riscv_hwloop_regs
    #(
        .HWLP_NUM(HWLP_NUM)
    )
    U_hwloop_regs
    (
        .clk                   ( clk                       ),
        .rst_n                 ( rst_n                     ),
        //from ID
        .hwlp_start_data_i     ( hwloop_start              ),
        .hwlp_end_data_i       ( hwloop_end                ),
        .hwlp_cnt_data_i       ( hwloop_cnt                ),
        .hwlp_we_i             ( hwloop_we                 ),
        .hwlp_regid_i          ( hwloop_regid              ),
        //from controller
        .valid_i               ( hwloop_valid              ),
        //from hwloop controller
        .hwlp_cnt_dec_i        ( hwlp_cnt_dec_i            ),
        //to hwloop controller
        .hwlp_start_addr_o     ( hwlp_start_o              ),
        .hwlp_end_addr_o       ( hwlp_end_o                ),
        .hwlp_counter_o        ( hwlp_cnt_o                )
    );    

    assign hwloop_valid = instr_valid_i & clear_instr_valid_o & is_hwlp_i;
    //kill instruction in the IF/ID stage by setting the instr_valid_id control signal to 0 for instructions that are done
    assign clear_instr_valid_o = id_ready_o | halt_id | branch_taken_ex;
    assign branch_taken_ex = branch_in_ex_o && branch_decision_i; //decode branch instr && alu_cmp_rslt
    assign mult_en = mult_int_en/* | mult_dot_en*/;



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

            mult_en_ex_o          <= 1'b0;
            mult_operator_ex_o    <= 'b0;
            mult_operand_a_ex_o   <= 'b0;
            mult_operand_b_ex_o   <= 'b0;
            //mult_operand_c_ex_o   <= 'b0;
            mult_signed_mode_ex_o <= 2'b00;
            
            //mult_dot_op_a_ex_o    <= 'b0;
            //mult_dot_op_b_ex_o    <= 'b0;
            //mult_dot_op_c_ex_o    <= 'b0;
            //mult_dot_signed_ex_o  <= 'b0;

            regfile_waddr_ex_o <= 6'b0;
            regfile_we_ex_o <= 1'b0;
            regfile_alu_we_ex_o <= 1'b0;
            regfile_alu_waddr_ex_o <= 6'b0;
            prepost_useincr_ex_o <= 1'b0;
           
            data_req_ex_o        <= 1'b0;
            data_we_ex_o         <= 1'b0;
            data_type_ex_o       <= 2'b0;
            data_sign_ext_ex_o   <= 2'b0;
            data_reg_offset_ex_o <= 2'b0;
            data_load_event_ex_o <= 1'b0;
            data_misaligned_ex_o <= 1'b0;

            branch_in_ex_o <= 1'b0;

            npu_en_mu_o <= 'b0;
            instr_npu_mu_o <= 'b0;
            is_VQ_insn_o <= 'b0;
            is_MQ_insn_o <= 'b0;
            is_SQ_insn_o <= 'b0;
            is_Cub_alu_insn_o <= 'b0;
            MQ_Cfifo_req_o <= 'b0;
            VQ_Cfifo_req_o <= 'b0;
            SQ_Cfifo_req_o <= 'b0;
            ALU_Cfifo_req_o <= 'b0;
            Cfifo_data_in_o  <= 'b0;
            MQ_clear_o <= 1'b0;
            VQ_clear_o <= 1'b0;
            SQ_clear_o <= 1'b0;
            MQ_Cfifo_clear_o <= 1'b0;
            VQ_Cfifo_clear_o <= 1'b0;
            SQ_Cfifo_clear_o <= 1'b0;             
            ALU_Cfifo_clear_o <= 1'b0;             
        end
        else if(data_misaligned_i) begin //misaligned data access case
            if(ex_ready_i) begin //misaligned access case, only unstall alu operands

              // if we are using post increments, then we have to use the
              // original value of the register for the second memory access
              // => keep it stalled
              if(prepost_useincr_ex_o == 1'b1)
              begin
                alu_operand_a_ex_o <= alu_operand_a;
              end

              alu_operand_b_ex_o   <= alu_operand_b;
              regfile_alu_we_ex_o  <= regfile_alu_we_id;
              prepost_useincr_ex_o <= prepost_useincr;

              data_misaligned_ex_o <= 1'b1;
            end        
        end
        //else if(mult_multicycle_i) begin
        //    mult_operand_c_ex_o <= alu_operand_c; 
        //end        
        else begin //normal pipeline unstall case
            if(id_valid_o) begin //unstall the whole pipeline
                alu_en_ex_o <= alu_en;
                mult_en_ex_o <= mult_en;
                
                if(alu_en) begin //alu
                    alu_operator_ex_o  <= alu_operator;
                    alu_operand_a_ex_o <= alu_operand_a;
                    alu_operand_b_ex_o <= alu_operand_b;
                    alu_operand_c_ex_o <= alu_operand_c;
                end

                if(mult_int_en) begin //mult
                    mult_operator_ex_o    <= mult_operator;
                    mult_operand_a_ex_o   <= alu_operand_a;
                    mult_operand_b_ex_o   <= alu_operand_b;
                    //mult_operand_c_ex_o   <= alu_operand_c;
                    mult_signed_mode_ex_o <= mult_signed_mode;
                end
                //if(mult_dot_en) begin
                //    mult_operator_ex_o   <= mult_operator;
                //    mult_dot_op_a_ex_o   <= alu_operand_a;
                //    mult_dot_op_b_ex_o   <= alu_operand_b;
                //    mult_dot_op_c_ex_o   <= alu_operand_c;
                //    mult_dot_signed_ex_o <= mult_dot_signed;
                //end
                
                npu_en_mu_o <= is_npu_insn;
                if(is_npu_insn) begin
                    instr_npu_mu_o <= instr_rdata_i;
                    is_VQ_insn_o <= VQ_insn;
                    is_MQ_insn_o <= MQ_insn;
                    is_SQ_insn_o <= SQ_insn;
                    is_Cub_alu_insn_o <= Cub_alu_insn;

                    MQ_clear_o <= MQ_clear;
                    VQ_clear_o <= VQ_clear;
                    SQ_clear_o <= SQ_clear;
                    MQ_Cfifo_clear_o <= MQ_Cfifo_clear;
                    VQ_Cfifo_clear_o <= VQ_Cfifo_clear;
                    SQ_Cfifo_clear_o <= SQ_Cfifo_clear;
                    ALU_Cfifo_clear_o <= ALU_Cfifo_clear;
                end
                else begin
                    is_MQ_insn_o <= 'b0;
                    is_VQ_insn_o <= 'b0;
                    is_SQ_insn_o <= 'b0;
                    is_Cub_alu_insn_o <= 'b0;
                end
                //MQ_Cfifo_push_o <= MQ_Cfifo_req;
                //VQ_Cfifo_push_o <= VQ_Cfifo_req;
                //SQ_Cfifo_push_o <= SQ_Cfifo_req;
                //ALU_Cfifo_push_o <= ALU_Cfifo_req;
                MQ_Cfifo_req_o <= MQ_Cfifo_req;
                VQ_Cfifo_req_o <= VQ_Cfifo_req;
                SQ_Cfifo_req_o <= SQ_Cfifo_req;
                ALU_Cfifo_req_o <= ALU_Cfifo_req;                
                if(MQ_Cfifo_req | VQ_Cfifo_req | SQ_Cfifo_req | ALU_Cfifo_req) begin
                    Cfifo_data_in_o  <= alu_operand_c;
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
                
                prepost_useincr_ex_o <= prepost_useincr;

                csr_access_ex_o <= csr_access;
                csr_op_ex_o <= csr_op;

                //LSU
                data_req_ex_o <= data_req_id;
                if(data_req_id) begin //only needed for LSU when there is an active request
                    data_we_ex_o         <= data_we_id;
                    data_type_ex_o       <= data_type_id;
                    data_sign_ext_ex_o   <= data_sign_ext_id;
                    data_reg_offset_ex_o <= data_reg_offset_id;
                    data_load_event_ex_o <= data_load_event_id;
                end else begin
                    data_load_event_ex_o <= 1'b0;
                end                

                data_misaligned_ex_o <= 1'b0;

                if ((jump_in_id == BRANCH_COND) || data_req_id) begin
                  pc_ex_o <= pc_id_i;
                end

                //branch
                branch_in_ex_o <= (jump_in_id == BRANCH_COND);

            end
            else begin
                if(ex_ready_i) begin //EX stage is ready but we don't have a new instruction for it,
                                          //so we set all write enables to 0, but unstall the pipe
                    regfile_we_ex_o      <= 1'b0;
                    regfile_alu_we_ex_o  <= 1'b0;

                    data_req_ex_o        <= 1'b0;
                    data_load_event_ex_o <= 1'b0;
                    data_misaligned_ex_o <= 1'b0;

                    branch_in_ex_o       <= 1'b0;
                    
                    alu_en_ex_o          <= 1'b1;
                    alu_operator_ex_o    <= ALU_SLTU;
                    mult_en_ex_o         <= 1'b0;
    
                    csr_op_ex_o          <= CSR_OP_NONE;
                end
                else if (csr_access_ex_o) begin
                 //In the EX stage there was a CSR access, to avoid multiple
                 //writes to the RF, disable regfile_alu_we_ex_o.
                 //Not doing it can overwrite the RF file with the currennt CSR value rather than the old one
                 regfile_alu_we_ex_o         <= 1'b0;
                end
                
                //if(mu_MQ_ready_i || mu_VQ_ready_i || mu_SQ_ready_i || mu_Cub_alu_ready_i) begin
                //    npu_en_mu_o <= 1'b0;
                //    instr_npu_mu_o <= 'b0;

                //    MQ_clear_o <= 1'b0;
                //    VQ_clear_o <= 1'b0;
                //    SQ_clear_o <= 1'b0;
                //    MQ_Cfifo_clear_o <= 1'b0;
                //    VQ_Cfifo_clear_o <= 1'b0;
                //    SQ_Cfifo_clear_o <= 1'b0;                    
                //    ALU_Cfifo_clear_o <= 1'b0;                    

                //    if(mu_MQ_ready_i)
                //        is_MQ_insn_o <= 'b0;
                //    if(mu_VQ_ready_i)
                //        is_VQ_insn_o <= 'b0;
                //    if(mu_SQ_ready_i)
                //        is_SQ_insn_o <= 'b0;
                //    if(mu_Cub_alu_ready_i)
                //        is_Cub_alu_insn_o <= 'b0;
                //end

                if(mu_MQ_ready_i&&is_MQ_insn_o || mu_VQ_ready_i&&is_VQ_insn_o || mu_SQ_ready_i&&is_SQ_insn_o || mu_Cub_alu_ready_i&&is_Cub_alu_insn_o) begin
                    npu_en_mu_o <= 1'b0;
                    instr_npu_mu_o <= 'b0;

                    if(mu_MQ_ready_i)
                        is_MQ_insn_o <= 'b0;
                    if(mu_VQ_ready_i)
                        is_VQ_insn_o <= 'b0;
                    if(mu_SQ_ready_i)
                        is_SQ_insn_o <= 'b0;
                    if(mu_Cub_alu_ready_i)
                        is_Cub_alu_insn_o <= 'b0;
                end

                MQ_clear_o <= 1'b0;
                VQ_clear_o <= 1'b0;
                SQ_clear_o <= 1'b0;
                MQ_Cfifo_clear_o <= 1'b0;
                VQ_Cfifo_clear_o <= 1'b0;
                SQ_Cfifo_clear_o <= 1'b0;                    
                ALU_Cfifo_clear_o <= 1'b0;
               
               if(MQ_Cfifo_req_o&&~MQ_Cfifo_full_i || VQ_Cfifo_req_o&&~VQ_Cfifo_full_i || SQ_Cfifo_req_o&&~SQ_Cfifo_full_i || ALU_Cfifo_req_o&&~ALU_Cfifo_full_i) begin
                    Cfifo_data_in_o  <= 'b0;
                    if(~MQ_Cfifo_full_i)
                        MQ_Cfifo_req_o <= 'b0;
                    if(~VQ_Cfifo_full_i)
                        VQ_Cfifo_req_o <= 'b0;
                    if(~SQ_Cfifo_full_i)
                        SQ_Cfifo_req_o <= 'b0;
                    if(~ALU_Cfifo_full_i)
                        ALU_Cfifo_req_o <= 'b0;
               end
                //MQ_Cfifo_push_o <= 'b0;
                //VQ_Cfifo_push_o <= 'b0;
                //SQ_Cfifo_push_o <= 'b0;
                //ALU_Cfifo_push_o <= 'b0;
/*
                if(MQ_Cfifo_full_i)
                    MQ_Cfifo_push_o <= 'b0;
                if(VQ_Cfifo_full_i)
                    VQ_Cfifo_push_o <= 'b0;
                if(SQ_Cfifo_full_i)
                    SQ_Cfifo_push_o <= 'b0;
*/
            end
        end
    end


    //stall control
    assign id_ready_o = ((~misaligned_stall) & (~jr_stall) & (~load_stall) & (~Cfifo_stall) & (~mu_stall) & ex_ready_i);
    assign id_valid_o = id_ready_o & (~halt_id);        
endmodule
