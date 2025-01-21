module riscv_decoder
#(
    parameter ALU_OP_WIDTH = 7,
    parameter PULP_SECURE  = 0
)
(
    input                               clk, //just for npu insn
    input                               rst_n,

    //instr from IF pipeline
    input   [31:0]                      instr_rdata_i,     //instruction read from instr memory/cache
    input                               illegal_c_instr_i, //compressed instruction decode failed

    //singals running to/from controller
    input                               deassert_we_i, //deassert we, we are stalled or not active
    input                               data_misaligned_i, // misaligned data load/store in progress
    //input                               mult_multicycle_i, // multiplier taking multiple cycles, using op c as storage
    //output logic                        instr_multicycle_o, // true when multiple cycles are decoded

    output logic                        npu_insn_o,
    output logic                        npu_insn_if_o, //no reg
    output logic                        MQ_Cfifo_req_o, //push rs2[31:0] to Cfifo
    output logic                        VQ_Cfifo_req_o, //push rs2[31:0] to Cfifo
    output logic                        SQ_Cfifo_req_o, //push rs2[31:0] to Cfifo
    output logic                        ALU_Cfifo_req_o,//push rs2[31:0] to Cfifo
    output logic                        VQ_insn_o,
    output logic                        MQ_insn_o,
    output logic                        SQ_insn_o,
    output logic                        Cub_alu_insn_o,
    output logic                        MQ_clear_o,
    output logic                        VQ_clear_o,
    output logic                        SQ_clear_o,
    output logic                        MQ_Cfifo_clear_o,
    output logic                        VQ_Cfifo_clear_o,
    output logic                        SQ_Cfifo_clear_o,
    output logic                        ALU_Cfifo_clear_o,

    output logic                        illegal_instr_o,   //illegal instruction encountered
    output logic                        ebrk_insn_o,       //trap instruction encountered
    output logic                        ecall_insn_o,      //environment call (syscall) instruction encountered
    output logic                        pipe_flush_o,      //pipeline flush is requested
    output logic                        fencei_insn_o,     //fence.i instruction

    output logic                        mret_dec_o, //return from exception instruction encountered (M) without deassert
    output logic                        uret_dec_o, //return from exception instruction encountered (S) without deassert
    output logic                        dret_dec_o, //return from debug (M) without deassert
    output logic                        mret_instr_o, // return from exception instruction encountered (M)
    output logic                        uret_instr_o, // return from exception instruction encountered (S)
    output logic                        dret_instr_o, // return from debug (M)

    output logic                        rega_used_o, // rs1 is used by current instruction
    output logic                        regb_used_o, // rs2 is used by current instruction
    output logic                        regc_used_o, // rs3 is used by current instruction

    //ALU signals
    output logic                        alu_en_o,           //ALU enable
    output logic [ALU_OP_WIDTH-1:0]     alu_operator_o,     //ALU operation selection
    output logic [2:0]                  alu_op_a_mux_sel_o, //operand a selection: reg value, PC, immediate or zero
    output logic [2:0]                  alu_op_b_mux_sel_o, //operand b selection: reg value or immediate
    output logic [1:0]                  alu_op_c_mux_sel_o, //operand c selection: reg value or jump target
    output logic [1:0]                  imm_a_mux_sel_o,    //immediate selection for operand a
    output logic [3:0]                  imm_b_mux_sel_o,    //immediate selection for operand b    
    output logic [1:0]                  regc_mux_o,         //register c selection: S3, RD or 0

    //MUL related control signals
    output logic [2:0]                  mult_operator_o,    // Multiplication operation selection
    output logic                        mult_int_en_o,      // perform integer multiplication
    //output logic                        mult_dot_en_o,      // perform dot multiplication
    output logic [1:0]                  mult_signed_mode_o, // Multiplication in signed mode
    output logic [1:0]                  mult_dot_signed_o,  // Dot product in signed mode

    //jump/branches
    output  logic [1:0]                 jump_target_mux_sel_o, //jump target selection
    output  logic [1:0]                 jump_in_dec_o,         //jump_in_id without deassert
    output  logic [1:0]                 jump_in_id_o,          //jump is being calculated in ALU

    //hwloop signals
    output logic [2:0]                  hwloop_we_o,             // write enable for hwloop regs
    output logic                        hwloop_target_mux_sel_o, // selects immediate for hwloop target
    output logic                        hwloop_start_mux_sel_o,  // selects hwloop start address input
    output logic                        hwloop_cnt_mux_sel_o,    // selects hwloop counter input

    //register file related signals
    output logic                        regfile_mem_we_o,       //write enable for regfile
    output logic                        regfile_alu_we_o,       //write enable for 2nd regfile port
    output logic                        regfile_alu_we_dec_o,   //write enable for 2nd regfile port without deassert
    output logic                        regfile_alu_waddr_sel_o,//Select register write address for ALU/MUL operations
    
    //LD/ST unit signals
    output  logic                       data_req_o,  //start transaction to data memory
    output  logic                       data_we_o,   //data memory write enable
    output  logic [1:0]                 data_type_o, //data type on data memory: byte, half word or word
    output  logic [1:0]                 data_sign_extension_o, //sign extension on read data from data memory / NaN boxing
    output  logic [1:0]                 data_reg_offset_o, //0; offset in byte inside register for stores
    output  logic                       prepost_useincr_o, //when not active bypass the alu result for address calculation
    output  logic                       data_load_event_o, //0; data request is in the special event range
    //CSR manipulation
    output logic                        csr_access_o, // access to CSR
    output logic                        csr_status_o, // access to xstatus CSR
    output logic [1:0]                  csr_op_o,     // operation to perform on CSR   
    input   [1:0]                       current_priv_lvl_i
);

`include "opcode_param.v"
`include "decode_param.v"

    //write enable/request control
    logic           regfile_alu_we;
    logic           regfile_mem_we;
    logic           data_req;
    logic   [2:0]   hwloop_we;
    logic   [1:0]   jump_in_id;
    logic           csr_illegal;

    logic   [1:0]   csr_op;

    logic       alu_en;
    logic       mult_int_en;
    //logic       mult_dot_en;
    logic       apu_en;

    //npu related signal
    logic       next_fetch_is_npu, next_fetch_is_npu_w;
    logic       next_fetch_is_cpu;
    logic       npu_insn;
    //logic       Cfifo_req;
    logic       MQ_Cfifo_req;
    logic       VQ_Cfifo_req;
    logic       SQ_Cfifo_req;
    logic       ALU_Cfifo_req;
    logic       MQ_sync_req;
    logic       VQ_sync_req;
    logic       SQ_sync_req;
    logic       illegal_instr_npu;

    always_comb begin
        jump_target_mux_sel_o = JT_JAL;
        jump_in_id = BRANCH_NONE;

        alu_en = 1'b1;
        alu_operator_o = ALU_SLTU;
        alu_op_a_mux_sel_o = OP_A_REGA_OR_FWD;
        alu_op_b_mux_sel_o = OP_B_REGB_OR_FWD;
        alu_op_c_mux_sel_o = OP_C_REGC_OR_FWD;
        imm_a_mux_sel_o = IMMA_ZERO;
        imm_b_mux_sel_o = IMMB_I;
        regc_mux_o = REGC_ZERO;

        mult_int_en        = 1'b0;
        //mult_dot_en        = 1'b0;
        mult_operator_o    = MUL_MAC32;
        mult_signed_mode_o = 2'b00;
        mult_dot_signed_o  = 2'b00;

        rega_used_o = 1'b0;
        regb_used_o = 1'b0;
        regc_used_o = 1'b0;        

        data_req  = 1'b0;
        data_we_o = 1'b0;
        data_type_o = 2'b00;
        data_sign_extension_o = 2'b00;
        prepost_useincr_o = 1'b1;
        data_reg_offset_o = 2'b00;
        data_load_event_o = 1'b0;

        regfile_mem_we          = 1'b0;
        regfile_alu_we          = 1'b0;
        regfile_alu_waddr_sel_o = 1'b1;

        illegal_instr_o = 1'b0;
        ebrk_insn_o     = 1'b0;
        ecall_insn_o    = 1'b0;
        pipe_flush_o    = 1'b0;
        fencei_insn_o   = 1'b0;

        mret_dec_o = 1'b0; //without deassert
        uret_dec_o = 1'b0;
        dret_dec_o = 1'b0;
        mret_instr_o = 1'b0; //with deassert
        uret_instr_o = 1'b0;
        dret_instr_o = 1'b0;        

        //instr_multicycle_o = 1'b0;

        next_fetch_is_npu = 1'b0;
        
        MQ_Cfifo_req = 1'b0;
        VQ_Cfifo_req = 1'b0;
        SQ_Cfifo_req = 1'b0;
        ALU_Cfifo_req = 1'b0;

        MQ_sync_req = 1'b0;
        VQ_sync_req = 1'b0;
        SQ_sync_req = 1'b0;

        hwloop_we               = 3'b0;
        hwloop_target_mux_sel_o = 1'b0;
        hwloop_start_mux_sel_o  = 1'b0;
        hwloop_cnt_mux_sel_o    = 1'b0;

        csr_access_o = 1'b0;
        csr_status_o = 1'b0;
        csr_illegal  = 1'b0;
        csr_op       = CSR_OP_NONE;        

        if(~npu_insn) begin //cpu instr decode
        case (instr_rdata_i[6:0])
            //======JUMPS======
            OPCODE_JAL: begin //Jump and Link, jal rd,offset, x[rd] = pc+4; pc += sext(offset)
                jump_target_mux_sel_o = JT_JAL;
                jump_in_id = BRANCH_JAL;
                //Calculate and store PC+4
                alu_op_a_mux_sel_o = OP_A_CURRPC;
                alu_op_b_mux_sel_o = OP_B_IMM;
                imm_b_mux_sel_o = IMMB_PCINCR;
                alu_operator_o = ALU_ADD;
                regfile_alu_we = 1'b1;
            end
            OPCODE_JALR: begin //Jump and Link register, jalr rd,offset(rs1), x[rd]=pc+4; pc=(x[rs1]+sext(offset))&~1
                jump_target_mux_sel_o = JT_JALR;
                jump_in_id = BRANCH_JALR;
                //Calculate and store PC+4
                alu_op_a_mux_sel_o = OP_A_CURRPC;
                alu_op_b_mux_sel_o = OP_B_IMM;
                imm_b_mux_sel_o = IMMB_PCINCR;
                alu_operator_o = ALU_ADD;
                regfile_alu_we = 1'b1;
                //Calculate jump target (= RS1 + I imm)
                rega_used_o = 1'b1;

                if(instr_rdata_i[14:12] != 3'b0) begin
                    jump_in_id       = BRANCH_NONE;
                    regfile_alu_we   = 1'b0;
                    illegal_instr_o  = 1'b1;
                end                
            end
            OPCODE_BRANCH: begin //Branch
                jump_target_mux_sel_o = JT_COND;
                jump_in_id            = BRANCH_COND;
                alu_op_c_mux_sel_o    = OP_C_JT;
                rega_used_o           = 1'b1;
                regb_used_o           = 1'b1;
                case(instr_rdata_i[14:12])
                  3'b000: alu_operator_o = ALU_EQ; //beq if(rs1==rs2) pc+=sext(offset)
                  3'b001: alu_operator_o = ALU_NE; //bne
                  3'b100: alu_operator_o = ALU_LTS;//blt if(rs1<(s)rs2) pc+=sext(offset)
                  3'b101: alu_operator_o = ALU_GES;//bge
                  3'b110: alu_operator_o = ALU_LTU;//bltu if(rs1<(u)rs2) pc+=sext(offset)
                  3'b111: alu_operator_o = ALU_GEU;//bgeu
                  default: alu_operator_o = ALU_EQ;//careful!
                endcase
            end

            //======LD/ST======
            OPCODE_STORE, OPCODE_STORE_POST: begin //sb,sh,sw, p.sb,p.sh,p.sw(imm and reg(post or not))
                data_req       = 1'b1;
                data_we_o      = 1'b1;
                rega_used_o    = 1'b1;
                regb_used_o    = 1'b1;
                alu_operator_o = ALU_ADD;
                //instr_multicycle_o = 1'b1;
                alu_op_c_mux_sel_o = OP_C_REGB_OR_FWD; //pass write data through ALU operand c

                //post-increment setup
                if(instr_rdata_i[6:0] == OPCODE_STORE_POST) begin
                    prepost_useincr_o       = 1'b0; //when not active bypass the alu result for address calculation
                    regfile_alu_waddr_sel_o = 1'b0;
                    regfile_alu_we          = 1'b1;
                end

                if(instr_rdata_i[14] == 1'b0) begin //offset from immediate
                  //sb rs2, Imm(rs1), Mem8(rs1+sext(Imm))=rs2[7:0], RV32I
                  //p.sb rs2, Imm(rs1!), Mem8(rs1)=rs2[7:0] rs1+=Imm[11:0]
                  imm_b_mux_sel_o     = IMMB_S;
                  alu_op_b_mux_sel_o  = OP_B_IMM;
                end else begin //offset from register(post or not)
                  //p.sb rs2, rs3(rs1!), Mem8(rs1)=rs2 rs1+=rs3
                  //p.sb rs2, rs3(rs1),  Mem8(rs1+rs3)=rs2
                  regc_used_o        = 1'b1;
                  alu_op_b_mux_sel_o = OP_B_REGC_OR_FWD;
                  regc_mux_o         = REGC_RD;
                end

                //store size
                case(instr_rdata_i[13:12])//byte,halfword,word
                  2'b00: data_type_o = 2'b10; //SB
                  2'b01: data_type_o = 2'b01; //SH
                  2'b10: data_type_o = 2'b00; //SW
                  default: begin
                    data_req       = 1'b0;
                    data_we_o      = 1'b0;
                    illegal_instr_o = 1'b1;
                  end
                endcase            
            end
            OPCODE_LOAD, OPCODE_LOAD_POST: begin //lb,lh,lw,lbu,lhu
                data_req        = 1'b1;
                regfile_mem_we  = 1'b1;
                rega_used_o     = 1'b1;
                alu_operator_o      = ALU_ADD;
                //instr_multicycle_o  = 1'b1;
                alu_op_b_mux_sel_o  = OP_B_IMM;//offset from immediate
                imm_b_mux_sel_o     = IMMB_I;
                //lb rd Imm(rs1), rd=Mem8(rs1+sext(Imm))[7:0], RV32I

                //post-increment setup
                if(instr_rdata_i[6:0] == OPCODE_LOAD_POST) begin
                    prepost_useincr_o       = 1'b0;
                    regfile_alu_waddr_sel_o = 1'b0;
                    regfile_alu_we          = 1'b1;
                end         

                //sign/zero extension
                data_sign_extension_o = {1'b0,~instr_rdata_i[14]};

                //load size
                case (instr_rdata_i[13:12]) //byte,halfword,word
                  2'b00:   data_type_o = 2'b10; // LB
                  2'b01:   data_type_o = 2'b01; // LH
                  2'b10:   data_type_o = 2'b00; // LW
                  default: data_type_o = 2'b00; // illegal or reg-reg
                endcase      

                //reg-reg load (different encoding)
                if(instr_rdata_i[14:12] == 3'b111) begin //offset from RS2
                    //p.lb rD, rs2(rs1!), rd=sext(Mem8(rs1)) rs1+=rs2
                    //p.lb rD, rs2(rs1),  rd=sext(Mem8(rs1+rs2))
                    regb_used_o        = 1'b1;
                    alu_op_b_mux_sel_o = OP_B_REGB_OR_FWD;

                    //sign/zero extension
                    data_sign_extension_o = {1'b0, ~instr_rdata_i[30]};

                    //load size
                    case(instr_rdata_i[31:25]) //func7
                      7'b0000_000, 7'b0100_000: data_type_o = 2'b10; // LB, LBU
                      7'b0001_000, 7'b0101_000: data_type_o = 2'b01; // LH, LHU
                      7'b0010_000:              data_type_o = 2'b00; // LW
                      default: illegal_instr_o = 1'b1;
                    endcase
                end

                if(instr_rdata_i[14:12] == 3'b011) begin //LD -> RV64 only
                    illegal_instr_o = 1'b1;
                end                    
            end

            //======ALU======
            OPCODE_LUI: begin //Load Upper Immediate, lui rd, imm, x[rd]=sext(imm[31:12]<<12])
                alu_op_a_mux_sel_o  = OP_A_IMM;
                alu_op_b_mux_sel_o  = OP_B_IMM;
                imm_a_mux_sel_o     = IMMA_ZERO;
                imm_b_mux_sel_o     = IMMB_U;
                alu_operator_o      = ALU_ADD;
                regfile_alu_we      = 1'b1;
            end
            OPCODE_AUIPC: begin //Add Upper Immediate to PC, auipc rd imm, x[rd]=pc+sext(imm[31:12]<<12])
                alu_op_a_mux_sel_o  = OP_A_CURRPC;
                alu_op_b_mux_sel_o  = OP_B_IMM;
                imm_b_mux_sel_o     = IMMB_U;
                alu_operator_o      = ALU_ADD;
                regfile_alu_we      = 1'b1;
            end
            OPCODE_OPIMM: begin //Reg-Imm ALU Operations
                //addi,slti,sltiu,xori,ori,andi,slli,srli,srai(9)
                //etc: addi rd,rs1,imm; x[rd] = x[rs1] & sext(imm)
                rega_used_o         = 1'b1;
                alu_op_b_mux_sel_o  = OP_B_IMM;
                imm_b_mux_sel_o     = IMMB_I;
                regfile_alu_we      = 1'b1;
                case(instr_rdata_i[14:12])
                  3'b000: alu_operator_o = ALU_ADD;  //Add Immediate
                  3'b010: alu_operator_o = ALU_SLTS; //Set to one if Lower Than Immediate
                  3'b011: alu_operator_o = ALU_SLTU; //Set to one if Lower Than Immediate Unsigned
                  3'b100: alu_operator_o = ALU_XOR;  //Exclusive Or with Immediate
                  3'b110: alu_operator_o = ALU_OR;   //Or with Immediate
                  3'b111: alu_operator_o = ALU_AND;  //And with Immediate
                  3'b001: begin
                        alu_operator_o = ALU_SLL;    //Shift Left Logical by Immediate
                        if(instr_rdata_i[31:25] != 7'b0) illegal_instr_o = 1'b1;
                  end
                  3'b101: begin
                        if(instr_rdata_i[31:25] == 7'b0)
                            alu_operator_o = ALU_SRL; //Shift Right Logical by Immediate
                        else if (instr_rdata_i[31:25] == 7'b010_0000)
                            alu_operator_o = ALU_SRA; //Shift Right Arithmetically by Immediate
                        else
                            illegal_instr_o = 1'b1;
                  end
                endcase
            end
            OPCODE_OP: begin //Reg-Reg ALU Operations
                //RV32I: add,sub,sll,slt,sltu,xor,srl,sra,or,and(10)
                //RV32M: mul,mulh,mulhsu,mulhu,div,divu,rem,remu(8)
                //etc: add rd,rs1,rs2; x[rd]=x[rs1]+x[rs2]
                if(instr_rdata_i[31:30] == 2'b11) begin //Imm Bit-Manipulation
                    illegal_instr_o = 1'b1; //delete,careful!
                end
                else if(instr_rdata_i[31:30] == 2'b10) begin //Reg Bit-Manipulation
                    illegal_instr_o = 1'b1; //delete,careful!
                end
                else begin
                    //non bit-manipulation instructions
                    rega_used_o    = 1'b1;
                    regfile_alu_we = 1'b1;
                    
                    if (~instr_rdata_i[28]) regb_used_o = 1'b1;      
                    case({instr_rdata_i[30:25], instr_rdata_i[14:12]})
                        //RV32I ALU operations
                        {6'b00_0000, 3'b000}: alu_operator_o = ALU_ADD;   // Add
                        {6'b10_0000, 3'b000}: alu_operator_o = ALU_SUB;   // Sub
                        {6'b00_0000, 3'b010}: alu_operator_o = ALU_SLTS;  // Set Lower Than
                        {6'b00_0000, 3'b011}: alu_operator_o = ALU_SLTU;  // Set Lower Than Unsigned
                        {6'b00_0000, 3'b100}: alu_operator_o = ALU_XOR;   // Xor
                        {6'b00_0000, 3'b110}: alu_operator_o = ALU_OR;    // Or
                        {6'b00_0000, 3'b111}: alu_operator_o = ALU_AND;   // And
                        {6'b00_0000, 3'b001}: alu_operator_o = ALU_SLL;   // Shift Left Logical
                        {6'b00_0000, 3'b101}: alu_operator_o = ALU_SRL;   // Shift Right Logical
                        {6'b10_0000, 3'b101}: alu_operator_o = ALU_SRA;   // Shift Right Arithmetic

                        //RV32M instructions
                        {6'b00_0001, 3'b000}: begin //mul rd,rs1,rs2; x[rd]=x[rs1]*x[rs2]
                          alu_en          = 1'b0;
                          mult_int_en     = 1'b1;
                          mult_operator_o = MUL_MAC32;
                          regc_mux_o      = REGC_ZERO;
                          //instr_multicycle_o = 1'b1;
                        end
                        {6'b00_0001, 3'b001}: begin //mulh rd,rs1,rs2; x[rd]=(x[rs1](s)*x[rs2](s))>>(s)XLEN (XLEN=32)
                          alu_en             = 1'b0;
                          mult_int_en        = 1'b1;
                          mult_operator_o    = MUL_H;
                          mult_signed_mode_o = 2'b11;
                          regc_used_o        = 1'b1;
                          regc_mux_o         = REGC_ZERO;
                          //instr_multicycle_o = 1'b1;
                        end
                        {6'b00_0001, 3'b010}: begin //mulhsu
                          alu_en             = 1'b0;
                          mult_int_en        = 1'b1;
                          mult_operator_o    = MUL_H;
                          mult_signed_mode_o = 2'b01;
                          regc_used_o        = 1'b1;
                          regc_mux_o         = REGC_ZERO;
                          //instr_multicycle_o = 1'b1;
                        end
                        {6'b00_0001, 3'b011}: begin //mulhu
                          alu_en             = 1'b0;
                          mult_int_en        = 1'b1;
                          mult_operator_o    = MUL_H;
                          mult_signed_mode_o = 2'b00;
                          regc_used_o        = 1'b1;
                          regc_mux_o         = REGC_ZERO;
                          //instr_multicycle_o = 1'b1;
                        end
                        {6'b00_0001, 3'b100}: begin //div
                          alu_operator_o     = ALU_DIV;
                          rega_used_o        = 1'b0;
                          regb_used_o        = 1'b1;
                          regc_used_o        = 1'b1;
                          regc_mux_o         = REGC_S1;
                          alu_op_a_mux_sel_o = OP_A_REGB_OR_FWD;
                          alu_op_b_mux_sel_o = OP_B_REGC_OR_FWD;
                          //instr_multicycle_o = 1'b1;
                        end
                        {6'b00_0001, 3'b101}: begin //divu
                          alu_operator_o     = ALU_DIVU;
                          rega_used_o        = 1'b0;
                          regb_used_o        = 1'b1;
                          regc_used_o        = 1'b1;
                          regc_mux_o         = REGC_S1;
                          alu_op_a_mux_sel_o = OP_A_REGB_OR_FWD;
                          alu_op_b_mux_sel_o = OP_B_REGC_OR_FWD;
                          //instr_multicycle_o = 1'b1;
                        end
                        {6'b00_0001, 3'b110}: begin //rem
                          alu_operator_o     = ALU_REM;
                          rega_used_o        = 1'b0;
                          regb_used_o        = 1'b1;
                          regc_used_o        = 1'b1;
                          regc_mux_o         = REGC_S1;
                          alu_op_a_mux_sel_o = OP_A_REGB_OR_FWD;
                          alu_op_b_mux_sel_o = OP_B_REGC_OR_FWD;
                          //instr_multicycle_o = 1'b1;
                        end
                        {6'b00_0001, 3'b111}: begin //remu
                          alu_operator_o     = ALU_REMU;
                          rega_used_o        = 1'b0;
                          regb_used_o        = 1'b1;
                          regc_used_o        = 1'b1;
                          regc_mux_o         = REGC_S1;
                          alu_op_a_mux_sel_o = OP_A_REGB_OR_FWD;
                          alu_op_b_mux_sel_o = OP_B_REGC_OR_FWD;
                          //instr_multicycle_o = 1'b1;
                        end
/*
                        //PULP specific instructions
                        {6'b10_0001, 3'b000}: begin // p.mac
                          alu_en          = 1'b0;
                          regc_used_o     = 1'b1;
                          regc_mux_o      = REGC_RD;
                          mult_int_en     = 1'b1;
                          mult_operator_o = MUL_MAC32;
                        end
                        {6'b10_0001, 3'b001}: begin // p.msu
                          alu_en          = 1'b0;
                          regc_used_o     = 1'b1;
                          regc_mux_o      = REGC_RD;
                          mult_int_en     = 1'b1;
                          mult_operator_o = MUL_MSU32;
                        end
                        {6'b00_0010, 3'b010}: alu_operator_o = ALU_SLETS; // Set Lower Equal Than    p.slet
                        {6'b00_0010, 3'b011}: alu_operator_o = ALU_SLETU; // Set Lower Equal Than Unsigned   p.sletu
                        {6'b00_0010, 3'b100}: begin alu_operator_o = ALU_MIN;   end // Min   p.min
                        {6'b00_0010, 3'b101}: begin alu_operator_o = ALU_MINU;  end // Min Unsigned
                        {6'b00_0010, 3'b110}: begin alu_operator_o = ALU_MAX;   end // Max
                        {6'b00_0010, 3'b111}: begin alu_operator_o = ALU_MAXU;  end // Max Unsigned
                        {6'b00_0100, 3'b101}: begin alu_operator_o = ALU_ROR;   end // Rotate Right

                        // PULP specific instructions using only one source register
                        {6'b00_1000, 3'b000}: begin alu_operator_o = ALU_FF1;  end // Find First 1
                        {6'b00_1000, 3'b001}: begin alu_operator_o = ALU_FL1;  end // Find Last 1
                        {6'b00_1000, 3'b010}: begin alu_operator_o = ALU_CLB;  end // Count Leading Bits
                        {6'b00_1000, 3'b011}: begin alu_operator_o = ALU_CNT;  end // Count set bits (popcount)
                        {6'b00_1000, 3'b100}: begin alu_operator_o = ALU_EXTS; alu_vec_mode_o = VEC_MODE16;  end // Sign-extend Half-word
                        {6'b00_1000, 3'b101}: begin alu_operator_o = ALU_EXT;  alu_vec_mode_o = VEC_MODE16;  end // Zero-extend Half-word
                        {6'b00_1000, 3'b110}: begin alu_operator_o = ALU_EXTS; alu_vec_mode_o = VEC_MODE8;   end // Sign-extend Byte
                        {6'b00_1000, 3'b111}: begin alu_operator_o = ALU_EXT;  alu_vec_mode_o = VEC_MODE8;   end // Zero-extend Byte

                        {6'b00_0010, 3'b000}: begin alu_operator_o = ALU_ABS;  end // p.abs

                        {6'b00_1010, 3'b001}: begin // p.clip
                          alu_operator_o     = ALU_CLIP;
                          alu_op_b_mux_sel_o = OP_B_IMM;
                          imm_b_mux_sel_o    = IMMB_CLIP;
                        end

                        {6'b00_1010, 3'b010}: begin // p.clipu
                          alu_operator_o     = ALU_CLIPU;
                          alu_op_b_mux_sel_o = OP_B_IMM;
                          imm_b_mux_sel_o    = IMMB_CLIP;
                        end

                        {6'b00_1010, 3'b101}: begin // p.clipr
                          alu_operator_o     = ALU_CLIP;
                          regb_used_o        = 1'b1;
                        end

                        {6'b00_1010, 3'b110}: begin // p.clipur
                          alu_operator_o     = ALU_CLIPU;
                          regb_used_o        = 1'b1;
                        end
*/
                        default: begin
                          illegal_instr_o = 1'b1;
                        end
                    endcase
                end
            end

            //======Special======
            OPCODE_FENCE:
                case(instr_rdata_i[14:12])
                  3'b000: begin // FENCE (FENCE.I instead, a bit more conservative)
                    // flush pipeline
                    fencei_insn_o = 1'b1;
                  end

                  3'b001: begin // FENCE.I
                    // flush prefetch buffer, flush pipeline
                    fencei_insn_o = 1'b1;
                  end

                  default: begin
                    illegal_instr_o =  1'b1;
                  end
                endcase   
                
            OPCODE_SYSTEM: begin
                if(instr_rdata_i[14:12] == 3'b000) begin //non CSR related SYSTEM instructions
                    if({instr_rdata_i[19:15], instr_rdata_i[11:7]} == 'b0) begin
                        case (instr_rdata_i[31:20])
                          12'h000:// ECALL
                          begin
                            //environment (system) call
                            ecall_insn_o  = 1'b1;
                          end

                          12'h001:// EBREAK
                          begin
                            //debugger trap
                            ebrk_insn_o = 1'b1;
                          end

                          12'h302:// mret
                          begin
                            illegal_instr_o = (PULP_SECURE) ? current_priv_lvl_i != PRIV_LVL_M : 1'b0;
                            mret_instr_o    = ~illegal_instr_o;
                            mret_dec_o     = 1'b1;
                          end

                          12'h002:// uret
                          begin
                            uret_instr_o   = (PULP_SECURE) ? 1'b1 : 1'b0;
                            uret_dec_o     = 1'b1;
                          end

                          12'h7b2:// dret
                          begin
                            illegal_instr_o = (PULP_SECURE) ? current_priv_lvl_i != PRIV_LVL_M : 1'b0;
                            dret_instr_o    = ~illegal_instr_o;
                            dret_dec_o     = 1'b1;
                          end

                          12'h105:// wfi : wait for interrupt, while(no_Interrupt_Pending) idle
                          begin
                            // flush pipeline
                            pipe_flush_o = 1'b1;
                          end

                          default: begin
                            illegal_instr_o = 1'b1;
                          end
                        endcase
                    end 
                    else begin
                        illegal_instr_o = 1'b1;
                    end
                end
                else begin //instruction to read/modify CSR
                    csr_access_o        = 1'b1;
                    regfile_alu_we      = 1'b1;
                    alu_op_b_mux_sel_o  = OP_B_IMM;
                    imm_a_mux_sel_o     = IMMA_Z;
                    imm_b_mux_sel_o     = IMMB_I; // CSR address is encoded in I imm
                    //instr_multicycle_o  = 1'b1;

                    if (instr_rdata_i[14] == 1'b1) begin 
                      // rs1 field is used as immediate
                      // csrrwi, csrrsi, csrrci
                      alu_op_a_mux_sel_o = OP_A_IMM;
                    end 
                    else begin
                      rega_used_o        = 1'b1;
                      alu_op_a_mux_sel_o = OP_A_REGA_OR_FWD;
                    end

                    unique case (instr_rdata_i[13:12])
                      2'b01:   csr_op   = CSR_OP_WRITE;
                      2'b10:   csr_op   = CSR_OP_SET;
                      2'b11:   csr_op   = CSR_OP_CLEAR;
                      default: csr_illegal = 1'b1;
                    endcase

                    if (instr_rdata_i[29:28] > current_priv_lvl_i) begin
                      // No access to higher privilege CSR
                      csr_illegal = 1'b1;
                    end

                    if(~csr_illegal)
                      if(instr_rdata_i[31:20] == 12'h300 || instr_rdata_i[31:20] == 12'h000  || instr_rdata_i[31:20] == 12'h041 ||
                         instr_rdata_i[31:20] == 12'h7b0 || instr_rdata_i[31:20] == 12'h7b1 || instr_rdata_i[31:20] == 12'h7b2 || 
                         instr_rdata_i[31:20] == 12'h7b3) //debug registers

                            csr_status_o = 1'b1; //access to xstatus

                    illegal_instr_o = csr_illegal;
                end
            end // OPCODE_SYSTEM end

            //======Custom======
            //OPCODE_PULP_OP:
            //OPCODE_VECOP:            
            OPCODE_HWLOOP: begin//must!
                hwloop_target_mux_sel_o = 1'b0;

                case (instr_rdata_i[14:12])
                  3'b000: begin
                    // lp.starti L,uimmL, lpstart[L] = PC + (uimmL << 1) : set start address to PC + I-type immediate
                    hwloop_we[0]           = 1'b1;
                    hwloop_start_mux_sel_o = 1'b0;
                  end

                  3'b001: begin
                    // lp.endi L,uimmL, lpend[L] = PC + (uimmL << 1) : set end address to PC + I-type immediate
                    hwloop_we[1]         = 1'b1;
                  end

                  3'b010: begin
                    // lp.count L,rs1, lpcount[L] = rs1 : initialize counter from rs1
                    hwloop_we[2]         = 1'b1;
                    hwloop_cnt_mux_sel_o = 1'b1;
                    rega_used_o          = 1'b1;
                  end

                  3'b011: begin
                    // lp.counti L,uimmL, lpcount[L] = uimmL : initialize counter from I-type immediate
                    hwloop_we[2]         = 1'b1;
                    hwloop_cnt_mux_sel_o = 1'b0;
                  end

                  3'b100: begin
                    // lp.setup L,rs1,uimmL : initialize counter from rs1, set start address to next instruction and end address to PC + I-type immediate
                        /* lpstart[L] = pc + 4
                           lpend[L] = pc + (uimmL << 1)
                           lpcount[L] = rs1 */
                    hwloop_we              = 3'b111;
                    hwloop_start_mux_sel_o = 1'b1;
                    hwloop_cnt_mux_sel_o   = 1'b1;
                    rega_used_o            = 1'b1;
                  end

                  3'b101: begin
                    // lp.setupi: initialize counter from immediate, set start address to next instruction and end address to PC + I-type immediate
                        /* lpstart[L] = pc + 4
                           lpend[L] = pc + (uimmS << 1)
                           lpcount[L] = uimmL */
                    hwloop_we               = 3'b111;
                    hwloop_target_mux_sel_o = 1'b1;
                    hwloop_start_mux_sel_o  = 1'b1;
                    hwloop_cnt_mux_sel_o    = 1'b0;
                  end

                  default: begin
                    illegal_instr_o = 1'b1;
                  end
                endcase
            end //OPCODE_HWLOOP end

            OPCODE_ACCEL: begin
                if(instr_rdata_i[14:12]==3'b0) //next_fetch_is_npu
                    next_fetch_is_npu = 1'b1;
                else if(instr_rdata_i[14:12]==3'b1) begin //storec: store data to Cons FIFO
                    alu_en = 1'b0;
                    alu_op_c_mux_sel_o = OP_C_REGB_OR_FWD; //pass write data through ALU operand c
                    regb_used_o = 1'b1;
                    //sb rs2, Imm(rs1), Mem8(rs1+sext(Imm))=rs2[7:0], RV32I
                    //sc rs2, Cfifo, fifo(push)=rs2[31:0]

                    case(instr_rdata_i[31:30])
                        2'b00: MQ_Cfifo_req = 1'b1;
                        2'b01: VQ_Cfifo_req = 1'b1;
                        2'b10: SQ_Cfifo_req = 1'b1;
                        2'b11: ALU_Cfifo_req = 1'b1;
                    endcase
                end
                else if(instr_rdata_i[14:12]==3'b010) begin //MQ/VQ/SQ sync
                    case(instr_rdata_i[31:30])
                        2'b00: MQ_sync_req = 1'b1;
                        2'b01: VQ_sync_req = 1'b1;
                        2'b10: SQ_sync_req = 1'b1;
                        default:;
                    endcase                    
                end
                else illegal_instr_o = 1'b1;
            end
            
            default: illegal_instr_o = 1'b1;
        endcase

        if(illegal_c_instr_i || illegal_instr_npu)   illegal_instr_o = 1'b1; //make sure invalid compressed instruction causes an exception

        //==========misaligned==========
        // misaligned access was detected by the LSU
        // TODO: this section should eventually be moved out of the decoder
        if(data_misaligned_i == 1'b1) begin
            // only part of the pipeline is unstalled, make sure that the
            // correct operands are sent to the AGU
            alu_op_a_mux_sel_o  = OP_A_REGA_OR_FWD;
            alu_op_b_mux_sel_o  = OP_B_IMM;
            imm_b_mux_sel_o     = IMMB_PCINCR;

            // if prepost increments are used, we do not write back the
            // second address since the first calculated address was
            // the correct one
            regfile_alu_we = 1'b0;

            // if post increments are used, we must make sure that for
            // the second memory access we do use the adder
            prepost_useincr_o = 1'b1;
        end 
        //==========multicycle==========
        //else if(mult_multicycle_i) begin
        //  alu_op_c_mux_sel_o = OP_C_REGC_OR_FWD;
        //end
        
        end //~npu_insn end
    end


    //deassert we signals (in case of stalls
    assign alu_en_o         = (deassert_we_i) ? 1'b0        : alu_en;
    assign mult_int_en_o    = (deassert_we_i) ? 1'b0        : mult_int_en;
    //assign mult_dot_en_o    = (deassert_we_i) ? 1'b0        : mult_dot_en;
    assign regfile_mem_we_o = (deassert_we_i) ? 1'b0        : regfile_mem_we;
    assign regfile_alu_we_o = (deassert_we_i) ? 1'b0        : regfile_alu_we;
    assign data_req_o       = (deassert_we_i) ? 1'b0        : data_req;
    assign hwloop_we_o      = (deassert_we_i) ? 3'b0        : hwloop_we;
    assign csr_op_o         = (deassert_we_i) ? CSR_OP_NONE : csr_op;
    assign jump_in_id_o     = (deassert_we_i) ? BRANCH_NONE : jump_in_id;

    assign jump_in_dec_o        = jump_in_id;
    assign regfile_alu_we_dec_o = regfile_alu_we;


    //==========gen npu_insn flag signal==========
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            npu_insn <= 1'b0;
        else if(next_fetch_is_npu_w)
            npu_insn <= 1'b1;
        else if(next_fetch_is_cpu)
            npu_insn <= 1'b0;
    end
    assign npu_insn_if_o = (next_fetch_is_npu_w | npu_insn) & ~next_fetch_is_cpu;

    assign npu_insn_o = (deassert_we_i) ? 1'b0 : npu_insn & ~next_fetch_is_cpu;
    assign MQ_Cfifo_req_o = (deassert_we_i) ? 1'b0 : MQ_Cfifo_req;
    assign VQ_Cfifo_req_o = (deassert_we_i) ? 1'b0 : VQ_Cfifo_req;
    assign SQ_Cfifo_req_o = (deassert_we_i) ? 1'b0 : SQ_Cfifo_req;
    assign ALU_Cfifo_req_o = (deassert_we_i) ? 1'b0 : ALU_Cfifo_req;
    assign next_fetch_is_npu_w = (deassert_we_i) ? 1'b0 : next_fetch_is_npu;

    npu_first_decoder U_npu_first_decoder(
        .instr_i(instr_rdata_i),
        .instr_valid_i(npu_insn),
        .illegal_instr_npu_o(illegal_instr_npu),
        .next_fetch_is_cpu_o(next_fetch_is_cpu),
        .VQ_insn_o(VQ_insn_o),
        .MQ_insn_o(MQ_insn_o),
        .SQ_insn_o(SQ_insn_o),
        .Cub_alu_insn_o(Cub_alu_insn_o),

        .MQ_clear_o(MQ_clear_o),
        .VQ_clear_o(VQ_clear_o),
        .SQ_clear_o(SQ_clear_o),
        .MQ_Cfifo_clear_o(MQ_Cfifo_clear_o),
        .VQ_Cfifo_clear_o(VQ_Cfifo_clear_o),
        .SQ_Cfifo_clear_o(SQ_Cfifo_clear_o),       
        .ALU_Cfifo_clear_o(ALU_Cfifo_clear_o),

        .deassert_we_i(deassert_we_i)
    );
endmodule

