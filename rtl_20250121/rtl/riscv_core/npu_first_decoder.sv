module npu_first_decoder(
    input  [31:0]               instr_i,
    input                       instr_valid_i,
    output logic                illegal_instr_npu_o,
    output logic                next_fetch_is_cpu_o,
    output logic                VQ_insn_o,
    output logic                MQ_insn_o,
    output logic                SQ_insn_o,
    output logic                Cub_alu_insn_o,

    output logic                MQ_clear_o,
    output logic                VQ_clear_o,
    output logic                SQ_clear_o,

    output logic                MQ_Cfifo_clear_o,
    output logic                VQ_Cfifo_clear_o,
    output logic                SQ_Cfifo_clear_o,
    output logic                ALU_Cfifo_clear_o,

    input                       deassert_we_i
);

//`include "npu_decode_param.v"
    parameter   OP_NPU_SYS = 3'b111;
    parameter   OP_NPU_VQ  = 3'b010;
    parameter   OP_NPU_MQ  = 3'b001;
    parameter   OP_NPU_SQ  = 3'b011;
    parameter   OP_CUB_ALU = 3'b100;

    logic                illegal_instr_npu;
    logic                next_fetch_is_cpu;
    logic                VQ_insn;
    logic                MQ_insn;
    logic                SQ_insn;
    logic                Cub_alu_insn;

    logic                MQ_clear;
    logic                VQ_clear;
    logic                SQ_clear;

    logic                MQ_Cfifo_clear;
    logic                VQ_Cfifo_clear;
    logic                SQ_Cfifo_clear;
    logic                ALU_Cfifo_clear;

    always_comb begin
        illegal_instr_npu = 1'b0;
        next_fetch_is_cpu = 1'b0;
        MQ_insn = 1'b0;
        VQ_insn = 1'b0;
        SQ_insn = 1'b0;
        Cub_alu_insn = 1'b0;
        
        MQ_clear = 1'b0;
        VQ_clear = 1'b0;
        SQ_clear = 1'b0;

        MQ_Cfifo_clear = 1'b0;
        VQ_Cfifo_clear = 1'b0;
        SQ_Cfifo_clear = 1'b0;
        ALU_Cfifo_clear = 1'b0;
        
        if(instr_valid_i) begin
            case(instr_i[6:4])
                OP_NPU_SYS: begin
                    case(instr_i[12])
                        1'b0:begin
                            next_fetch_is_cpu = 1'b1;
                        end                    
                        1'b1:begin
                            case(instr_i[9:7])
                                3'b000: MQ_clear = 1'b1;
                                3'b001: VQ_clear = 1'b1;
                                3'b010: SQ_clear = 1'b1;

                                3'b100: MQ_Cfifo_clear = 1'b1;
                                3'b101: VQ_Cfifo_clear = 1'b1;
                                3'b110: SQ_Cfifo_clear = 1'b1;
                                3'b111: ALU_Cfifo_clear = 1'b1;
                                //default:;
                            endcase
                        end
                    endcase
                end
                
                OP_NPU_VQ: begin
                    VQ_insn = 1'b1;
                end

                OP_NPU_MQ: begin
                    MQ_insn = 1'b1;
                end

                OP_NPU_SQ: begin
                    SQ_insn = 1'b1;
                end

                OP_CUB_ALU: begin
                    Cub_alu_insn = 1'b1;
                end                

                default: illegal_instr_npu = 1'b1;
            endcase
        end 
    end

    assign illegal_instr_npu_o  = illegal_instr_npu  ;
                                                       
    assign next_fetch_is_cpu_o  = deassert_we_i ? 1'b0 : next_fetch_is_cpu  ;
    assign VQ_insn_o            = deassert_we_i ? 1'b0 : VQ_insn            ;
    assign MQ_insn_o            = deassert_we_i ? 1'b0 : MQ_insn            ;
    assign SQ_insn_o            = deassert_we_i ? 1'b0 : SQ_insn            ;
    assign Cub_alu_insn_o       = deassert_we_i ? 1'b0 : Cub_alu_insn       ;
    assign MQ_clear_o           = deassert_we_i ? 1'b0 : MQ_clear           ;
    assign VQ_clear_o           = deassert_we_i ? 1'b0 : VQ_clear           ;
    assign SQ_clear_o           = deassert_we_i ? 1'b0 : SQ_clear           ;
    assign MQ_Cfifo_clear_o     = deassert_we_i ? 1'b0 : MQ_Cfifo_clear     ;
    assign VQ_Cfifo_clear_o     = deassert_we_i ? 1'b0 : VQ_Cfifo_clear     ;
    assign SQ_Cfifo_clear_o     = deassert_we_i ? 1'b0 : SQ_Cfifo_clear     ;
    assign ALU_Cfifo_clear_o    = deassert_we_i ? 1'b0 : ALU_Cfifo_clear    ;

endmodule
