module cub_decoder(
    input  [31:0]                       Cub_instr_i,
    output logic                        Cub_illegal_insn_o,

    //ALU signals
    output logic                        alu_en_o,           //ALU enable
    output logic [7-1:0]                alu_operator_o,     //ALU operation selection
    output logic [2:0]                  alu_op_a_mux_sel_o, //operand a selection: reg value, PC, immediate or zero
    output logic [2:0]                  alu_op_b_mux_sel_o, //operand b selection: reg value or immediate
    //output logic [1:0]                  alu_op_c_mux_sel_o, //operand c selection: reg value or jump target
    output logic [1:0]                  alu_vec_mode_o,     // selects between 32 bit, 16 bit and 8 bit vectorial modes
    output logic [1:0]                  imm_a_mux_sel_o,    //immediate selection for operand a
    output logic [3:0]                  imm_b_mux_sel_o,    //immediate selection for operand b
    output logic                        alu_trun_prec_o,    //0:int8 1:int16
    output logic [4:0]                  alu_trun_Q_o,    
    //output logic [1:0]                  regc_mux_o,         //register c selection: S3, RD or 0

    //MUL signals
    output logic                        mult_int_en_o,      // perform integer multiplication
    output logic [2:0]                  mult_operator_o,    // Multiplication operation selection
    output logic [1:0]                  mult_signed_mode_o, // Multiplication in signed mode
    output logic                        mult_sel_subword_o, // Select subwords for 16x16 bit of multiplier

    output logic                        rega_used_o, // rs1 is used by current instruction
    output logic                        regb_used_o, // rs2 is used by current instruction
    //output logic                        regc_used_o, // rs3 is used by current instruction

    //register file related signals
    output logic                        regfile_mem_we_o,       //write enable for regfile
    output logic                        regfile_alu_we_o,       //write enable for 2nd regfile port
    output logic                        regfile_alu_waddr_sel_o,//Select register write address for ALU/MUL operations

    //LD/ST unit signals
    output logic                        data_req_o,  //start transaction to data memory
    output logic                        data_we_o,   //data memory write enable
    output logic [1:0]                  data_type_o, //00:byte 01:halfword 10:word          
    output logic [1:0]                  data_ram_sel_o, //00:l1b 01:cram 10:scache
    output logic                        data_sign_extension_o, //0:signed ext 1:zero
    //output  logic                       prepost_useincr_o, //when not active bypass the alu result for address calculation

    output logic                        scache_en_o,
    output logic                        scache_we_o,
    output logic [1:0]                  scache_size_o,
    output logic                        scache_sign_ext_o,
    //output logic                        l1b_en_o,
    //output logic                        l1b_we_o,
    //output logic [1:0]                  l1b_size_o,
    //output logic                        l1b_sign_ext_o,

    output logic                        acti_en_o,
    output logic [7:0]                  acti_operator_o,
    output logic                        pool_en_o,
    output logic [1:0]                  pool_operator_o,
    output logic                        pool_comp_sign_o, 
    output logic [1:0]                  pool_comp_vect_o,
    output logic [1:0]                  pool_comp_mode_o,      

    //CSR manipulation
    output logic                        csr_access_o, // access to CSR

    input                               deassert_we_i,

    output logic                        cflow_nop_en_o,
    output logic [7:0]                  cflow_nop_cycle_num_o    
);

    `include "npu_decode_param.v"
    `include "decode_param.v"

    logic                               alu_en;
    logic                               mult_int_en;
    logic                               regfile_mem_we;
    logic                               regfile_alu_we;
    logic                               data_req;
    logic                               csr_access;
    logic                               scache_en;
    logic                               acti_en;
    logic                               pool_en;


    always_comb begin
        alu_en                      = 1'b1;
        alu_operator_o              = ALU_SLTU;
        alu_trun_prec_o             = 1'b0;
        alu_trun_Q_o                = 5'b0;
        alu_op_a_mux_sel_o          = OP_A_REGA_OR_FWD;
        alu_op_b_mux_sel_o          = OP_B_REGB_OR_FWD;
        //alu_op_c_mux_sel_o          = OP_C_REGC_OR_FWD;
        alu_vec_mode_o              = VEC_MODE32;
        imm_a_mux_sel_o             = IMMA_ZERO;
        imm_b_mux_sel_o             = IMMB_I;
        //regc_mux_o                  = REGC_ZERO;

        mult_int_en                 = 1'b0;
        mult_operator_o             = MUL_I;
        mult_signed_mode_o          = 2'b00;
        mult_sel_subword_o          = 1'b0;

        rega_used_o                 = 1'b0;
        regb_used_o                 = 1'b0;
        //regc_used_o                 = 1'b0;

        regfile_mem_we              = 1'b0;
        regfile_alu_we              = 1'b0;
        regfile_alu_waddr_sel_o     = 1'b1;

        data_req                    = 1'b0;
        data_ram_sel_o              = 2'b0;
        data_we_o                   = 1'b0;
        data_type_o                 = 2'b0;
        data_sign_extension_o       = 1'b0;
        //prepost_useincr_o = 1'b1;

        csr_access                  = 1'b0;

        scache_en                   = 1'b0;
        scache_we_o                 = 1'b0;
        scache_size_o               = 2'b0;
        scache_sign_ext_o           = 1'b0;
        //l1b_en_o                    = 1'b0;
        //l1b_we_o                    = 1'b0;
        //l1b_size_o                  = 2'b0;
        //l1b_sign_ext_o              = 1'b0;
        
        acti_en                     = 1'b0;
        acti_operator_o             = 8'b0;
        pool_en                     = 1'b0;
        pool_operator_o             = 2'b0;
        pool_comp_sign_o            = 1'b0; 
        pool_comp_vect_o            = 2'b0;
        pool_comp_mode_o            = 2'b0;       

        Cub_illegal_insn_o          = 1'b0;

        cflow_nop_en_o              = 1'b0;
        cflow_nop_cycle_num_o       = 8'b0;  

        case(Cub_instr_i[6:0])
            OPCODE_CUB_ALU_LUI: begin //Load Upper Immediate, lui rd, imm, x[rd]=sext(imm[31:12]<<12])
                alu_op_a_mux_sel_o  = OP_A_IMM;
                alu_op_b_mux_sel_o  = OP_B_IMM;
                imm_a_mux_sel_o     = IMMA_ZERO;
                imm_b_mux_sel_o     = IMMB_U;
                alu_operator_o      = ALU_ADD;
                regfile_alu_we      = 1'b1;
            end

            OPCODE_CUB_ALU_REG: begin //Reg-Reg ALU Operations
                //add,sub; slt,sltu,slet,sletu; min,minu,max,maxu; and,or,xor;
                //sll,srl,sra; abs,exths,exthz,extbs,extbz;
                //mul,mulh,mulsu,mulhu,muls,mulhhs,mulu,mulhhu(29)
                if(Cub_instr_i[31] == 1'b0) begin
                    rega_used_o      = 1'b1;
                    regb_used_o      = 1'b1;
                    regfile_alu_we   = 1'b1;

                    case({Cub_instr_i[30:25], Cub_instr_i[14:12]})
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
                          //regc_mux_o      = REGC_ZERO;
                        end
                        {6'b00_0001, 3'b001}: begin //mulh rd,rs1,rs2; x[rd]=(x[rs1](s)*x[rs2](s))>>(s)XLEN (XLEN=32)
                          alu_en             = 1'b0;
                          mult_int_en        = 1'b1;
                          mult_operator_o    = MUL_H;
                          mult_signed_mode_o = 2'b11;
                          //regc_used_o        = 1'b1;
                          //regc_mux_o         = REGC_ZERO;
                        end
                        {6'b00_0001, 3'b010}: begin //mulhsu
                          alu_en             = 1'b0;
                          mult_int_en        = 1'b1;
                          mult_operator_o    = MUL_H;
                          mult_signed_mode_o = 2'b01;
                          //regc_used_o        = 1'b1;
                          //regc_mux_o         = REGC_ZERO;
                        end
                        {6'b00_0001, 3'b011}: begin //mulhu
                          alu_en             = 1'b0;
                          mult_int_en        = 1'b1;
                          mult_operator_o    = MUL_H;
                          mult_signed_mode_o = 2'b00;
                          //regc_used_o        = 1'b1;
                          //regc_mux_o         = REGC_ZERO;
                        end
                        {6'b00_0001, 3'b100}: begin //ncni16
                          alu_en             = 1'b0;
                          mult_int_en        = 1'b1;
                          mult_operator_o    = MUL_NCNI16;
                          //regc_used_o        = 1'b1;
                          //regc_mux_o         = REGC_ZERO;
                        end
                        {6'b00_0001, 3'b101}: begin //ccni16
                          alu_en             = 1'b0;
                          mult_int_en        = 1'b1;
                          mult_operator_o    = MUL_CCNI16;
                          //regc_used_o        = 1'b1;
                          //regc_mux_o         = REGC_ZERO;
                        end
                        /*
                        {6'b00_0001, 3'b100}: begin //div
                          alu_operator_o     = ALU_DIV;
                          rega_used_o        = 1'b1;
                          regb_used_o        = 1'b1;
                          //regc_used_o        = 1'b1;
                          //regc_mux_o         = REGC_S1;
                          alu_op_a_mux_sel_o = OP_A_REGB_OR_FWD;
                          alu_op_b_mux_sel_o = OP_B_REGA_OR_FWD;
                          //instr_multicycle_o = 1'b1;
                        end
                        {6'b00_0001, 3'b101}: begin //divu
                          alu_operator_o     = ALU_DIVU;
                          rega_used_o        = 1'b1;
                          regb_used_o        = 1'b1;
                          //regc_used_o        = 1'b1;
                          //regc_mux_o         = REGC_S1;
                          alu_op_a_mux_sel_o = OP_A_REGB_OR_FWD;
                          alu_op_b_mux_sel_o = OP_B_REGA_OR_FWD;
                          //instr_multicycle_o = 1'b1;
                        end
                        {6'b00_0001, 3'b110}: begin //rem
                          alu_operator_o     = ALU_REM;
                          rega_used_o        = 1'b1;
                          regb_used_o        = 1'b1;
                          //regc_used_o        = 1'b1;
                          //regc_mux_o         = REGC_S1;
                          alu_op_a_mux_sel_o = OP_A_REGB_OR_FWD;
                          alu_op_b_mux_sel_o = OP_B_REGA_OR_FWD;
                          //instr_multicycle_o = 1'b1;
                        end
                        {6'b00_0001, 3'b111}: begin //remu
                          alu_operator_o     = ALU_REMU;
                          rega_used_o        = 1'b1;
                          regb_used_o        = 1'b1;
                          //regc_used_o        = 1'b1;
                          //regc_mux_o         = REGC_S1;
                          alu_op_a_mux_sel_o = OP_A_REGB_OR_FWD;
                          alu_op_b_mux_sel_o = OP_B_REGA_OR_FWD;
                          //instr_multicycle_o = 1'b1;
                        end
                        */

/*
                        //PULP specific instructions
                        {6'b00_0001, 3'b100}: begin //muls
                          alu_en             = 1'b0;
                          mult_int_en        = 1'b1;
                          mult_operator_o    = MUL_I;
                          //regc_mux_o         = REGC_ZERO;
                          mult_sel_subword_o = 1'b0;
                          mult_signed_mode_o = 2'b11;
                        end
                        {6'b00_0001, 3'b101}: begin //mulhhs
                          alu_en             = 1'b0;
                          mult_int_en        = 1'b1;
                          mult_operator_o    = MUL_I;
                          //regc_mux_o         = REGC_ZERO;
                          mult_sel_subword_o = 1'b1;
                          mult_signed_mode_o = 2'b11;
                        end
                        {6'b00_0001, 3'b110}: begin //mulu
                          alu_en             = 1'b0;
                          mult_int_en        = 1'b1;
                          mult_operator_o    = MUL_I;
                          //regc_mux_o         = REGC_ZERO;
                          mult_sel_subword_o = 1'b0;
                          mult_signed_mode_o = 2'b00;
                        end
                        {6'b00_0001, 3'b111}: begin //mulhhu
                          alu_en             = 1'b0;
                          mult_int_en        = 1'b1;
                          mult_operator_o    = MUL_I;
                          //regc_mux_o         = REGC_ZERO;
                          mult_sel_subword_o = 1'b1;
                          mult_signed_mode_o = 2'b00;
                        end                    
*/                        
                        {6'b00_0010, 3'b000}: begin alu_operator_o = ALU_ABS;  end // p.abs
                        {6'b00_0010, 3'b001}: begin alu_operator_o = ALU_EQ;  end // p.eq
                        {6'b00_0010, 3'b010}: alu_operator_o = ALU_SLETS; // Set Lower Equal Than           p.slet
                        {6'b00_0010, 3'b011}: alu_operator_o = ALU_SLETU; // Set Lower Equal Than Unsigned  p.sletu
                        {6'b00_0010, 3'b100}: begin // p.sgtb
                            alu_operator_o = ALU_SGTS; 
                            alu_vec_mode_o = VEC_MODE8;
                        end 
                        {6'b00_0010, 3'b101}: begin // p.sgth
                            alu_operator_o = ALU_SGTS; 
                            alu_vec_mode_o = VEC_MODE16;
                        end 
                        {6'b00_0010, 3'b110}: begin // p.sltb
                            alu_operator_o = ALU_SLTS; 
                            alu_vec_mode_o = VEC_MODE8;
                        end 
                        {6'b00_0010, 3'b111}: begin // p.slth
                            alu_operator_o = ALU_SLTU; 
                            alu_vec_mode_o = VEC_MODE16;
                        end 

                        {6'b00_1000, 3'b100}: begin alu_operator_o = ALU_EXTS; alu_vec_mode_o = VEC_MODE16;  end // Sign-extend Half-word
                        {6'b00_1000, 3'b101}: begin alu_operator_o = ALU_EXT;  alu_vec_mode_o = VEC_MODE16;  end // Zero-extend Half-word
                        {6'b00_1000, 3'b110}: begin alu_operator_o = ALU_EXTS; alu_vec_mode_o = VEC_MODE8;   end // Sign-extend Byte
                        {6'b00_1000, 3'b111}: begin alu_operator_o = ALU_EXT;  alu_vec_mode_o = VEC_MODE8;   end // Zero-extend Byte
                        {6'b00_1000, 3'b000}: begin // Min          p.min
                            pool_en = 1'b1;
                            pool_comp_sign_o = 1'b0;  //0:signed 1:unsigned
                            pool_comp_vect_o = 2'b00; //10:int8x4 01:int16x2 00:int32x1
                            pool_comp_mode_o = 2'b10; //00:accumulator 01:compare(max) 10:compare(min) 11:sub
                        end
                        {6'b00_1000, 3'b001}: begin // Min Unsigned p.minu
                            pool_en = 1'b1;
                            pool_comp_sign_o = 1'b1;  //0:signed 1:unsigned
                            pool_comp_vect_o = 2'b00; //10:int8x4 01:int16x2 00:int32x1
                            pool_comp_mode_o = 2'b10; //00:accumulator 01:compare(max) 10:compare(min) 11:sub
                        end
                        {6'b00_1000, 3'b010}: begin // Max          p.max 
                            pool_en = 1'b1;
                            pool_comp_sign_o = 1'b0;  //0:signed 1:unsigned
                            pool_comp_vect_o = 2'b00; //10:int8x4 01:int16x2 00:int32x1
                            pool_comp_mode_o = 2'b01; //00:accumulator 01:compare(max) 10:compare(min) 11:sub
                        end
                        {6'b00_1000, 3'b011}: begin // Max Unsigned p.maxu 
                            pool_en = 1'b1;
                            pool_comp_sign_o = 1'b1;  //0:signed 1:unsigned
                            pool_comp_vect_o = 2'b00; //10:int8x4 01:int16x2 00:int32x1
                            pool_comp_mode_o = 2'b01; //00:accumulator 01:compare(max) 10:compare(min) 11:sub
                        end

                        {6'b00_1010, 3'b000}: begin // p.vec.addh
                            pool_en = 1'b1;
                            pool_comp_sign_o = 1'b0;  //0:signed 1:unsigned
                            pool_comp_vect_o = 2'b01; //10:int8x4 01:int16x2 00:int32x1
                            pool_comp_mode_o = 2'b00; //00:accumulator 01:compare(max) 10:compare(min) 11:sub
                        end
                        {6'b00_1010, 3'b001}: begin // p.vec.addb
                            pool_en = 1'b1;
                            pool_comp_sign_o = 1'b0;  //0:signed 1:unsigned
                            pool_comp_vect_o = 2'b10; //10:int8x4 01:int16x2 00:int32x1
                            pool_comp_mode_o = 2'b00; //00:accumulator 01:compare(max) 10:compare(min) 11:sub                         
                        end
                        {6'b00_1010, 3'b010}: begin // p.vec.subh
                            pool_en = 1'b1;
                            pool_comp_sign_o = 1'b0;  //0:signed 1:unsigned
                            pool_comp_vect_o = 2'b01; //10:int8x4 01:int16x2 00:int32x1
                            pool_comp_mode_o = 2'b11; //00:accumulator 01:compare(max) 10:compare(min) 11:sub                        
                        end
                        {6'b00_1010, 3'b011}: begin // p.vec.subb
                            pool_en = 1'b1;
                            pool_comp_sign_o = 1'b0;  //0:signed 1:unsigned
                            pool_comp_vect_o = 2'b10; //10:int8x4 01:int16x2 00:int32x1
                            pool_comp_mode_o = 2'b11; //00:accumulator 01:compare(max) 10:compare(min) 11:sub    
                        end
                        {6'b00_1010, 3'b100}: begin // p.vec.maxh
                            pool_en = 1'b1;
                            pool_comp_sign_o = 1'b0;  //0:signed 1:unsigned
                            pool_comp_vect_o = 2'b01; //10:int8x4 01:int16x2 00:int32x1
                            pool_comp_mode_o = 2'b01; //00:accumulator 01:compare(max) 10:compare(min) 11:sub
                        end
                        {6'b00_1010, 3'b101}: begin // p.vec.maxb
                            pool_en = 1'b1;
                            pool_comp_sign_o = 1'b0;  //0:signed 1:unsigned
                            pool_comp_vect_o = 2'b10; //10:int8x4 01:int16x2 00:int32x1
                            pool_comp_mode_o = 2'b01; //00:accumulator 01:compare(max) 10:compare(min) 11:sub
                        end
                        {6'b00_1010, 3'b110}: begin // p.vec.minh
                            pool_en = 1'b1;
                            pool_comp_sign_o = 1'b0;  //0:signed 1:unsigned
                            pool_comp_vect_o = 2'b01; //10:int8x4 01:int16x2 00:int32x1
                            pool_comp_mode_o = 2'b10; //00:accumulator 01:compare(max) 10:compare(min) 11:sub
                        end
                        {6'b00_1010, 3'b111}: begin // p.vec.minbb
                            pool_en = 1'b1;
                            pool_comp_sign_o = 1'b0;  //0:signed 1:unsigned
                            pool_comp_vect_o = 2'b10; //10:int8x4 01:int16x2 00:int32x1
                            pool_comp_mode_o = 2'b10; //00:accumulator 01:compare(max) 10:compare(min) 11:sub
                        end

                        default: begin
                          Cub_illegal_insn_o = 1'b1;
                        end
                    endcase
                end
                else begin
                    Cub_illegal_insn_o = 1'b1;
                end
            end

            OPCODE_CUB_ALU_IMM: begin //Reg-Imm ALU Operations
                //addi; slti,sltiu; andi,ori,xori; slli,srli,srai
                rega_used_o         = 1'b1;
                alu_op_b_mux_sel_o  = OP_B_IMM;
                imm_b_mux_sel_o     = IMMB_I;
                regfile_alu_we      = 1'b1;
                case(Cub_instr_i[14:12])
                    3'b000: alu_operator_o = ALU_ADD;  //Add Immediate
                    3'b010: alu_operator_o = ALU_SLTS; //Set to one if Lower Than Immediate
                    3'b011: alu_operator_o = ALU_SLTU; //Set to one if Lower Than Immediate Unsigned
                    3'b100: alu_operator_o = ALU_XOR;  //Exclusive Or with Immediate
                    3'b110: alu_operator_o = ALU_OR;   //Or with Immediate
                    3'b111: alu_operator_o = ALU_AND;  //And with Immediate
                    3'b001: begin
                          alu_operator_o = ALU_SLL;    //Shift Left Logical by Immediate
                          if(Cub_instr_i[31:25] != 7'b0) Cub_illegal_insn_o = 1'b1;
                    end
                    3'b101: begin
                          if(Cub_instr_i[31:25] == 7'b0)
                              alu_operator_o = ALU_SRL; //Shift Right Logical by Immediate
                          else if (Cub_instr_i[31:25] == 7'b010_0000)
                              alu_operator_o = ALU_SRA; //Shift Right Arithmetically by Immediate
                          else
                              Cub_illegal_insn_o = 1'b1;
                    end
                endcase        
            end

            OPCODE_CUB_ALU_LOAD: begin
                data_req        = 1'b1;
                regfile_mem_we  = 1'b1;
                rega_used_o     = 1'b1;
                alu_operator_o      = ALU_ADD;
                alu_op_b_mux_sel_o  = OP_B_IMM;//offset from immediate
                imm_b_mux_sel_o     = IMMB_IS;
                //lb rd Imm(rs1), rd=Mem8(rs1+sext(Imm))[7:0], RV32I

                case(Cub_instr_i[13:12])
                  2'b00:    data_type_o = 2'b10; // LB
                  2'b01:    data_type_o = 2'b01; // LH
                  2'b10:    data_type_o = 2'b00; // LW
                  default:  data_type_o = 2'b00; // LW
                endcase
                
                //00:l1b 01:scache 10:cram
                if(Cub_instr_i[14]==1'b1) begin
                    if(Cub_instr_i[13:12]==2'b11)
                        data_ram_sel_o = 2'b01; 
                    else
                        data_ram_sel_o = 2'b10;
                end

                data_sign_extension_o = ~Cub_instr_i[31];
            end

            OPCODE_CUB_ALU_STORE: begin
                data_req       = 1'b1;
                data_we_o      = 1'b1;
                rega_used_o    = 1'b1;
                regb_used_o    = 1'b1;
                alu_operator_o = ALU_ADD;
                //alu_op_c_mux_sel_o = OP_C_REGB_OR_FWD; //pass write data through ALU operand c

                imm_b_mux_sel_o     = IMMB_S;
                alu_op_b_mux_sel_o  = OP_B_IMM;

                case(Cub_instr_i[13:12])
                  2'b00:    data_type_o = 2'b10; // LB
                  2'b01:    data_type_o = 2'b01; // LH
                  2'b10:    data_type_o = 2'b00; // LW
                  default:  data_type_o = 2'b00; // LW
                endcase

                //00:l1b 01:scache 10:cram
                if(Cub_instr_i[14]==1'b1) begin
                    if(Cub_instr_i[13:12]==2'b11)
                        data_ram_sel_o = 2'b01; 
                    else
                        data_ram_sel_o = 2'b10;
                end
            end

            OPCODE_CUB_ALU_CTRL: begin // lci, cflow_nop 
                case(Cub_instr_i[13:12])
                    2'b00: begin //lci:load constant imm
                        //rega_used_o         = 1'b1;
                        alu_op_a_mux_sel_o  = OP_A_ZERO;
                        alu_op_b_mux_sel_o  = OP_B_IMM;
                        imm_b_mux_sel_o     = IMMB_LCI;
                        regfile_alu_we      = 1'b1;
                        alu_operator_o      = ALU_ADD;  //Add Immediate
                    end
                    2'b11: begin //cflow_nop
                        cflow_nop_en_o = 1'b1;
                        cflow_nop_cycle_num_o = Cub_instr_i[22:15];
                    end
                    //default:;
                endcase
            end

            OPCODE_CUB_ALU_OP: begin
                case(Cub_instr_i[14:12])
                    3'b111: begin //CSRW insn
                        csr_access          = 1'b1;
                        alu_op_a_mux_sel_o  = OP_A_IMM;
                        alu_op_b_mux_sel_o  = OP_B_IMM;
                        imm_a_mux_sel_o     = IMMA_Z; // CSR wdata
                        imm_b_mux_sel_o     = IMMB_C; // CSR address is encoded in CW imm
                    end
                    3'b010: begin //addT
                        case(Cub_instr_i[31]) //0:int8 1:int16
                            0:  alu_operator_o   = ALU_ADDT8;
                            1:  alu_operator_o   = ALU_ADDT16;
                        endcase
                        alu_trun_Q_o     = Cub_instr_i[29:25];
                        rega_used_o      = 1'b1;
                        regb_used_o      = 1'b1;
                        regfile_alu_we   = 1'b1;
                    end
                    3'b011: begin //subT
                        case(Cub_instr_i[31]) //0:int8 1:int16
                            0:  alu_operator_o   = ALU_SUBT8;
                            1:  alu_operator_o   = ALU_SUBT16;
                        endcase
                        alu_trun_Q_o     = Cub_instr_i[29:25];
                        rega_used_o      = 1'b1;
                        regb_used_o      = 1'b1;
                        regfile_alu_we   = 1'b1;
                    end
                    3'b100: begin //scache_wr_rd_en
                        alu_op_a_mux_sel_o = OP_A_IMM;
                        imm_a_mux_sel_o = IMMA_SC;
                        scache_en   = 1'b1;
                        scache_we_o = ~Cub_instr_i[31];
                        scache_size_o = Cub_instr_i[29:28];
                        scache_sign_ext_o = Cub_instr_i[30];
                    end
                    //3'b101: begin //l1b_wr_rd_en
                    //    alu_op_a_mux_sel_o = OP_A_IMM;
                    //    imm_a_mux_sel_o = IMMA_LB;
                    //    l1b_en_o = 1'b1;
                    //    l1b_we_o = ~Cub_instr_i[31];
                    //    l1b_size_o = Cub_instr_i[29:28];
                    //    l1b_sign_ext_o = Cub_instr_i[30];                            
                    //end
                    default: begin
                      Cub_illegal_insn_o = 1'b1;
                    end
                endcase
            end

            OPCODE_CUB_ACTI_POOL: begin
                case(Cub_instr_i[12])
                    1'b0: begin //RELU
                        acti_en = 1'b1;
                        acti_operator_o = Cub_instr_i[27:20];
                        rega_used_o = 1'b1;
                        regfile_alu_we = 1'b1;
                    end
/*                    
                    1'b1: begin //POOL
                        pool_en = 1'b1;
                        pool_operator_o = Cub_instr_i[26:25];  //00:a(R0) comp b(R1); 01:a(R0) pipe R1; 10:a(R0) in, R0 & R1, FU pipe R1; 11:R1 to rslt;
                        pool_comp_sign_o = Cub_instr_i[27];    //0:signed 1:unsigned
                        pool_comp_vect_o = Cub_instr_i[29:28]; //10:int8x4 01:int16x2 00:int32x1
                        pool_comp_mode_o = Cub_instr_i[31:30]; //00:accumulator 01:compare(max) 10:compare(min) 11:sub
                        case(pool_operator_o)
                            2'b00: begin
                                rega_used_o     = 1'b1;
                                regb_used_o     = 1'b1;
                                regfile_alu_we  = 1'b1;
                            end
                            2'b01, 2'b10: begin
                                rega_used_o     = 1'b1;
                                regb_used_o     = 1'b0;
                                regfile_alu_we  = 1'b0;
                            end
                            2'b11: begin
                                rega_used_o     = 1'b1;
                                regb_used_o     = 1'b0;
                                regfile_alu_we  = 1'b1;
                            end                            
                        endcase
                    end
*/
                endcase
            end

        endcase
    end

    //deassert we signals (in case of stalls)
    assign alu_en_o         = (deassert_we_i) ? 1'b0        : alu_en;
    assign mult_int_en_o    = (deassert_we_i) ? 1'b0        : mult_int_en;
    //assign regfile_mem_we_o = (deassert_we_i) ? 1'b0        : regfile_mem_we;
    //assign regfile_alu_we_o = (deassert_we_i) ? 1'b0        : regfile_alu_we;
    assign regfile_mem_we_o = regfile_mem_we;
    assign regfile_alu_we_o = regfile_alu_we;
    assign data_req_o       = (deassert_we_i) ? 1'b0        : data_req;
    assign csr_access_o     = (deassert_we_i) ? 1'b0        : csr_access;
    assign scache_en_o      = (deassert_we_i) ? 1'b0        : scache_en;
    assign acti_en_o        = (deassert_we_i) ? 1'b0        : acti_en;
    assign pool_en_o        = (deassert_we_i) ? 1'b0        : pool_en;



endmodule
