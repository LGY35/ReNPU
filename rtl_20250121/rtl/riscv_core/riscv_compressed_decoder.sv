/*
Design Name     : Compressed Instruction Decoder
Data            : 2023/12/22           
Description     : Decodes RISC-V compressed instr into their RV32 equivalent, fully combinatorial.
*/

module riscv_compressed_decoder
(
    input   [31:0]              instr_i,
    output  logic [31:0]        instr_o,
    output  logic               is_compressed_o,
    output  logic               illegal_instr_o,
    input                       is_npu_insn_i
);
`include "opcode_param.v"

    assign  is_compressed_o = ~is_npu_insn_i & (instr_i[1:0] != 2'b11);

    always_comb begin
        instr_o = instr_i;
        illegal_instr_o = 1'b0;

        if(~is_npu_insn_i) begin
        case(instr_i[1:0])
            //========
            //  C0
            //========
            2'b00: begin
                case(instr_i[15:13])
                    3'b000: begin //c.addi4spn > addi rd'+8, x2, uimm; uimm=0 is illegal
                        instr_o = {2'b00, instr_i[10:7], instr_i[12:11], instr_i[5], instr_i[6], 2'b00, 5'h02, 3'b000, 2'b01, instr_i[4:2], OPCODE_OPIMM};
                        if(instr_i[12:5]==8'b0) illegal_instr_o = 1'b1;
                    end
                    3'b001: begin //c.fld(FPU)
                        illegal_instr_o = 1'b1;
                    end
                    3'b010: begin //c.lw > lw rd'+8, uimm(rs1'+8)
                        instr_o = {5'b0, instr_i[5], instr_i[12:10], instr_i[6], 2'b00, 2'b01, instr_i[9:7], 3'b010, 2'b01, instr_i[4:2], OPCODE_LOAD}; 
                    end
                    3'b011: begin //c.flw(FPU)
                        illegal_instr_o = 1'b1;
                    end
                    3'b101: begin //c.fsd(FPU)
                        illegal_instr_o = 1'b1;
                    end
                    3'b110: begin //c.sw > sw rs2'+8, imm(rs1'+8)
                        instr_o = {5'b0, instr_i[5], instr_i[12], 2'b01, instr_i[4:2], 2'b01, instr_i[9:7], 3'b010, instr_i[11:10], instr_i[6], 2'b00, OPCODE_STORE};
                    end
                    3'b111: begin //c.fsw(FPU)
                        illegal_instr_o = 1'b1;
                    end
                    default: illegal_instr_o = 1'b1;
                endcase
            end

            //========
            //  C1
            //========
            2'b01: begin
                case(instr_i[15:13])
                    3'b000: begin //c.addi > addi rd, rd, nzimm
                        instr_o = {{6{instr_i[12]}}, instr_i[12], instr_i[6:2], instr_i[11:7], 3'b0, instr_i[11:7], OPCODE_OPIMM};
                    end
                    3'b001, 3'b101: begin
                        //001: c.jal > jal x1, imm
                        //101: c.j   > jal x0, imm
                        instr_o = {instr_i[12], instr_i[8], instr_i[10:9], instr_i[6], instr_i[7], instr_i[2], instr_i[11], instr_i[5:3], {9{instr_i[12]}}, 4'b0, ~instr_i[15], OPCODE_JAL};
                    end
                    3'b010: begin //c.li > addi rd, x0, nzimm
                        instr_o = {{6{instr_i[12]}}, instr_i[12], instr_i[6:2], 5'b0, 3'b0, instr_i[11:7], OPCODE_OPIMM};
                        if(instr_i[11:7]==5'b0)  illegal_instr_o = 1'b1; //rd==0
                    end
                    3'b011: begin //c.lui > lui rd, imm; rd=x2 or imm=0 is illegal
                        instr_o = {{15{instr_i[12]}}, instr_i[6:2], instr_i[11:7], OPCODE_LUI};
                        if(instr_i[11:7]==5'h02) begin //c.addi16sp -> addi x2, x2, nzimm
                            instr_o = {{3{instr_i[12]}}, instr_i[4:3], instr_i[5], instr_i[2], instr_i[6], 4'b0, 5'h02, 3'b000, 5'h02, OPCODE_OPIMM};
                        end
                        else if(instr_i[11:7] == 5'b0) begin
                            illegal_instr_o = 1'b1;
                        end

                        if({instr_i[12], instr_i[6:2]}==6'b0) illegal_instr_o = 1'b1;
                    end
                    3'b100: begin
                        case (instr_i[11:10])
                            2'b00,2'b01: begin
                                //00: c.srli > srli rd'+8, rd'+8, shamt;(uimm)
                                //01: c.srai > srai rd'+8, rd'+8, shamt;(uimm)
                                instr_o = {1'b0, instr_i[10], 5'b0, instr_i[6:2], 2'b01, instr_i[9:7], 3'b101, 2'b01, instr_i[9:7], OPCODE_OPIMM};
                                if (instr_i[12] == 1'b1)  illegal_instr_o = 1'b1;
                                if (instr_i[6:2] == 5'b0) illegal_instr_o = 1'b1;
                            end
                            2'b10: begin
                                // c.andi > andi rd'+8, rd'+8, imm
                                instr_o = {{6{instr_i[12]}}, instr_i[12], instr_i[6:2], 2'b01, instr_i[9:7], 3'b111, 2'b01, instr_i[9:7], OPCODE_OPIMM};
                            end
                            2'b11: begin
                                case ({instr_i[12], instr_i[6:5]})
                                    3'b000: begin //c.sub > sub rd'+8, rd'+8, rs2'+8
                                        instr_o = {2'b01, 5'b0, 2'b01, instr_i[4:2], 2'b01, instr_i[9:7], 3'b000, 2'b01, instr_i[9:7], OPCODE_OP};
                                    end
                                    3'b001: begin //c.xor > xor rd'+8, rd'+8, rs2'+8
                                        instr_o = {7'b0, 2'b01, instr_i[4:2], 2'b01, instr_i[9:7], 3'b100, 2'b01, instr_i[9:7], OPCODE_OP};
                                    end
                                    3'b010: begin //c.or  > or  rd'+8, rd'+8, rs2'+8
                                        instr_o = {7'b0, 2'b01, instr_i[4:2], 2'b01, instr_i[9:7], 3'b110, 2'b01, instr_i[9:7], OPCODE_OP};
                                    end
                                    3'b011: begin //c.and > and rd'+8, rd'+8, rs2'+8
                                        instr_o = {7'b0, 2'b01, instr_i[4:2], 2'b01, instr_i[9:7], 3'b111, 2'b01, instr_i[9:7], OPCODE_OP};
                                    end
                                    3'b100, 3'b101, 3'b110, 3'b111: begin
                                        //100: c.subw (RV64I, not support)
                                        //101: c.addw (RV64I, not support)
                                        illegal_instr_o = 1'b1;
                                    end
                                endcase
                            end
                        endcase        
                    end
                    3'b110, 3'b111: begin
                        //110: c.beqz > beq rs1'+8, x0, imm
                        //111: c.bnez > bne rs1'+8, x0, imm
                        instr_o = {{4{instr_i[12]}}, instr_i[6:5], instr_i[2], 5'b0, 2'b01, instr_i[9:7], 2'b00, instr_i[13], instr_i[11:10], instr_i[4:3], instr_i[12], OPCODE_BRANCH};
                    end
                endcase
            end

            //========
            //  C2
            //========            
            2'b10: begin
                case(instr_i[15:13])
                    3'b000: begin //c.slli > slli rd, rd, shamt;(uimm)
                        instr_o = {7'b0, instr_i[6:2], instr_i[11:7], 3'b001, instr_i[11:7], OPCODE_OPIMM};
                        if (instr_i[11:7] == 5'b0)  illegal_instr_o = 1'b1;
                        if (instr_i[12] == 1'b1 || instr_i[6:2] == 5'b0)  illegal_instr_o = 1'b1;                        
                    end
                    3'b001: begin //c.fldsp(FPU)
                        illegal_instr_o = 1'b1;
                    end
                    3'b010: begin //c.lwsp > lw rd, uimm(x2); rd=0([11:7]) is illegal
                        instr_o = {4'b0, instr_i[3:2], instr_i[12], instr_i[6:4], 2'b00, 5'h02, 3'b010, instr_i[11:7], OPCODE_LOAD};
                        if (instr_i[11:7] == 5'b0)  illegal_instr_o = 1'b1;
                    end
                    3'b011: begin //c.flwsp(FPU)
                        illegal_instr_o = 1'b1;
                    end
                    3'b100: begin
                        if(instr_i[12] == 1'b0) begin //c.mv > add rd, x0, rs2; rs2=0([6:2]) is illegal
                            instr_o = {7'b0, instr_i[6:2], 5'b0, 3'b0, instr_i[11:7], OPCODE_OP};
                            if (instr_i[6:2] == 5'b0) //c.jr > jalr x0, 0(rs1); rs1=0 is illegal
                                instr_o = {12'b0, instr_i[11:7], 3'b0, 5'b0, OPCODE_JALR};
                        end 
                        else begin //c.add > add rd, rd, rs2; rd=0([11:7]) or rs2=0([6:2]) is illegal
                            instr_o = {7'b0, instr_i[6:2], instr_i[11:7], 3'b0, instr_i[11:7], OPCODE_OP};
                            if (instr_i[11:7] == 5'b0) begin //c.ebreak > ebreak
                                if (instr_i[6:2] != 5'b0)
                                    illegal_instr_o = 1'b1;
                                else
                                    instr_o = {32'h00_10_00_73};
                            end 
                            else if (instr_i[6:2] == 5'b0) begin //c.jalr > jalr x1, 0(rs1); rs1=0([11:7]) is illegal
                                instr_o = {12'b0, instr_i[11:7], 3'b000, 5'b00001, OPCODE_JALR};
                            end
                        end
                    end
                    3'b101: begin //c.fsdsp(FPU)
                        illegal_instr_o = 1'b1;
                    end
                    3'b110: begin //c.swsp > sw rs2, uimm(x2)
                        instr_o = {4'b0, instr_i[8:7], instr_i[12], instr_i[6:2], 5'h02, 3'b010, instr_i[11:9], 2'b00, OPCODE_STORE};
                    end
                    3'b111: begin //c.fswsp(FPU)
                        illegal_instr_o = 1'b1;
                    end
                endcase
            end
            default: instr_o = instr_i;
        endcase
        end
    end

endmodule
