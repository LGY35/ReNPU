/*
Design Name     : ALU
Data            : 2024/2/18      
Description     : Arithmetic logic unit of the pipelined processor 
*/

module riscv_alu
#(
    parameter ALU_OP_WIDTH = 7
)(
    input                           clk,
    input                           rst_n,

    input                           enable_i,
    input  [ALU_OP_WIDTH-1:0]       operator_i,
    input  [31:0]                   operand_a_i,
    input  [31:0]                   operand_b_i,
    input  [31:0]                   operand_c_i,

    output logic [31:0]             result_o,
    output logic                    comparison_result_o,

    output logic                    ready_o,
    input                           ex_ready_i
);

`include "decode_param.v"

    //============================
    //  adder
    //============================
    logic                           adder_op_b_negate;
    logic [31:0]                    operand_b_neg;
    logic [31:0]                    adder_op_a, adder_op_b;
    logic [32:0]                    adder_in_a, adder_in_b;
    logic [33:0]                    adder_result_expanded;
    logic [31:0]                    adder_result;
    
    assign adder_op_b_negate = (operator_i == ALU_SUB);
    assign operand_b_neg = ~operand_b_i;

    //prepare operand a
    assign adder_op_a = operand_a_i;

    //prepare operand b
    assign adder_op_b = adder_op_b_negate ? operand_b_neg : operand_b_i;

    //prepare carry
    always_comb begin
        adder_in_a[    0] = 1'b1;
        adder_in_a[32: 1] = adder_op_a[31: 0];

        adder_in_b[    0] = 1'b0;
        adder_in_b[32: 1] = adder_op_b[31: 0];

        if(adder_op_b_negate) begin //special case for subtractions and absolute number calculations
            adder_in_b[0] = 1'b1;
        end 
    end

    //actual adder
    assign adder_result_expanded = $signed(adder_in_a) + $signed(adder_in_b);
    assign adder_result = {adder_result_expanded[32:1]};


    //============================
    //  compare
    //============================

    logic           is_equal;
    logic           is_greater; //handles both signed and unsigned forms
    logic           cmp_signed;

    always_comb begin
        case(operator_i)
            ALU_GES,
            ALU_LTS,
            ALU_SLTS: cmp_signed = 1'b1;
            default:  cmp_signed = 1'b0;
        endcase
    end

    assign is_equal   = (operand_a_i == operand_b_i);
    assign is_greater = $signed({operand_a_i[31] & cmp_signed, operand_a_i[31:0]})
                            >
                        $signed({operand_b_i[31] & cmp_signed, operand_b_i[31:0]});

    //generate comparison result
    logic   cmp_result;

    always_comb begin
        case(operator_i)
            ALU_EQ:            cmp_result = is_equal;
            ALU_NE:            cmp_result = ~is_equal;
            ALU_GES, ALU_GEU:  cmp_result = is_greater | is_equal;
            ALU_LTS, ALU_SLTS,
            ALU_LTU, ALU_SLTU: cmp_result = ~(is_greater | is_equal);
            default:           cmp_result = is_equal;
        endcase
    end

    assign comparison_result_o = cmp_result;

    
    //============================
    //  shift
    //============================
    logic        shift_left;         //should we shift left
    logic [31:0] shift_amt_left;     //amount of shift, if to the left
    logic [31:0] shift_amt;          //amount of shift, to the right
    logic [31:0] shift_amt_int;      //amount of shift, used for the actual shifters
    logic [31:0] shift_op_a;         //input of the shifter
    logic        shift_arithmetic;
    logic [31:0] shift_result;
    logic [31:0] shift_right_result;
    logic [31:0] shift_left_result;
    logic [63:0] shift_op_a_32;
    logic [31:0] operand_a_rev;

    //bit reverse the shift_right_result for left shifts
    genvar j;
    generate
        for(j=0; j<32; j++) begin 
            assign shift_left_result[j] = shift_right_result[31-j];
        end
    endgenerate

    //bit reverse operand_a for left shifts and bit counting
    genvar k;
    generate
        for(k=0; k<32; k++) begin
            assign operand_a_rev[k] = operand_a_i[31-k];
        end
    endgenerate


    assign shift_left = (operator_i == ALU_SLL) /*|| 
                          (operator_i == ALU_DIV) || (operator_i == ALU_DIVU) ||
                          (operator_i == ALU_REM) || (operator_i == ALU_REMU)*/;
    assign shift_arithmetic = (operator_i == ALU_SRA) || (operator_i == ALU_ADD) || (operator_i == ALU_SUB);
    assign shift_use_round = (operator_i == ALU_ADD) || (operator_i == ALU_SUB);

    //shifter is also used for preparing operand for division
    assign shift_amt = operand_b_i;
    assign shift_amt_int = shift_use_round ? 'b0 : shift_amt;

    assign shift_op_a = shift_left ? operand_a_rev : (shift_use_round ? adder_result : operand_a_i); //choose the bit reversed or the normal input for shift operand a

    assign shift_op_a_32 = $signed({{32{shift_arithmetic & shift_op_a[31]}}, shift_op_a});

    assign shift_right_result = shift_op_a_32 >> shift_amt_int[4:0];

    assign shift_result = shift_left ? shift_left_result : shift_right_result;


    //============================
    //  div/rem
    //============================
    logic [32:0] result_div;
    logic [32:0] div_a,div_b;
    logic        div_signed;
    logic        div_op_a_signed;
    logic        div_op_b_signed;
    logic        div_valid;
    logic        div_out_valid;

    assign div_valid = enable_i & ((operator_i == ALU_DIV) || (operator_i == ALU_DIVU) || (operator_i == ALU_REM) || (operator_i == ALU_REMU));

    assign div_signed = operator_i[0];
    assign div_op_a_signed = operand_a_i[31] & div_signed;
    assign div_op_b_signed = operand_b_i[31] & div_signed;   
    assign div_a = {div_op_a_signed, operand_a_i};
    assign div_b = {div_op_b_signed, operand_b_i};
    
//    riscv_alu_div
//    #(
//        .C_WIDTH(33)
//    )
//    U_alu_div(
//    .clk(clk),
//    .rst_n(rst_n),
//    
//    .opa_i(div_b),
//    .opb_i(div_a),
//    .opcode_i(operator_i[1:0]), //0:udiv, 1:div, 2:urem, 3:rem
//    
//    .valid_i(div_valid),
//    .ready_i(ex_ready_i),
//    .valid_o(div_ready),
//    
//    .result_div_o(result_div)
//    );
//
 logic start_valid,start;

    always_ff@(posedge clk or negedge rst_n) 
        if(!rst_n) 
            start_valid <= 'b0;
        else
            start_valid <= div_valid;

    assign start = div_valid && !start_valid ;

    logic [32:0] div_quotient, div_remainder ;
    logic div_by_0 ;
    
   DW_div_seq #(
                .a_width(33), 
                .b_width(33), 
                .tc_mode(1), 
                .num_cyc(8),
                .rst_mode(0), 
                .input_mode(0), 
                .output_mode(1),
                .early_start(0)) 
    U_riscv_div (
        .clk(clk),   
        .rst_n(rst_n),   
        .hold(1'b0), 
        .start(start),   
        .a(div_b),   
        .b(div_a), 
        .complete(div_ready),   
        .divide_by_0(div_by_0), 
        .quotient(div_quotient),   
        .remainder(div_remainder) );


    assign ready_o = div_ready&&!start;


    //============================
    //  result mux
    //============================
    always_comb begin
    case(operator_i)
        //Standard Operations
        ALU_AND: result_o = operand_a_i & operand_b_i;
        ALU_OR:  result_o = operand_a_i | operand_b_i;
        ALU_XOR: result_o = operand_a_i ^ operand_b_i;

        //Shift Operations
        ALU_ADD, ALU_SUB, 
        ALU_SLL, ALU_SRL, ALU_SRA: result_o = shift_result;
        
        //Comparison Operations
        ALU_EQ, ALU_NE,
        ALU_LTU,
        ALU_LTS,
        ALU_SLTS, ALU_SLTU: result_o = {31'b0, comparison_result_o};

        //Division Unit Commands
        ALU_DIV : result_o = div_by_0 ? operand_a_i[31]^operand_b_i[31] ?  32'h8000_0000:32'h7fff_ffff : div_quotient ;
        ALU_DIVU: result_o = div_by_0 ? 32'hffff_ffff : div_quotient[31:0] ;
        ALU_REM : result_o = div_by_0 ? 0 : div_remainder[31:0] ;
        ALU_REMU: result_o = div_by_0 ? 0 : div_remainder[31:0] ;

        default: result_o = 'b0; //default case to suppress unique warning
    endcase
    end

endmodule
