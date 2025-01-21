module cub_arithmetic #(
    parameter ALU_OP_WIDTH = 7
)(
    input                           clk                     ,
    input                           rst_n                   ,

    input                           cub_arithmetic_enable                ,
    input  [ALU_OP_WIDTH-1:0]       cub_arithmetic_operator              ,
    input  [31:0]                   cub_arithmetic_operand_a             , 
    input  [31:0]                   cub_arithmetic_operand_b             ,
    //input  [31:0]                   cub_arithmetic_bias                  ,
    
    input                           cub_arithmetic_cflow_mode            ,
  //  input                           cub_arithmetic_truncate_prec         ,
    input  [4:0]                    cub_arithmetic_truncate_Q            ,
    input  [1:0]                    cub_arithmetic_vect_mode             , //00:32bit 01:16bit 10:8bit

    output logic                    cub_arithmetic_result_valid          ,                
    output logic [31:0]             cub_arithmetic_result                ,

    output logic                    cub_arithmetic_ready_o
  //  input                           cub_arithmetic_ex_ready_i
);

`include "decode_param.v"

    wire                           cub_arithmetic_cflow_truncate_Q_en   =  cub_arithmetic_truncate_Q !=0 ? 1:0 ;
    //============================ 
    //  adder
    //============================
    logic                           adder_op_b_negate;
    logic [31:0]                    operand_b_neg;
    logic [31:0]                    adder_op_a, adder_op_b;
    logic [32:0]                    adder_in_a, adder_in_b;
    logic [33:0]                    adder_result_expanded;
    logic [31:0]                    adder_truncate_result;
    logic [31:0]                    adder_result;
    
    assign adder_op_b_negate = (cub_arithmetic_operator == ALU_SUB)||(cub_arithmetic_operator == ALU_SUBT)||(cub_arithmetic_operator == ALU_SUBT8)||(cub_arithmetic_operator == ALU_SUBT16);
    assign operand_b_neg = ~cub_arithmetic_operand_b;

    //prepare operand a
    assign adder_op_a = cub_arithmetic_operand_a;

    //prepare operand b
    assign adder_op_b = adder_op_b_negate ? operand_b_neg : cub_arithmetic_operand_b;

    //prepare carry //resnet need to add
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
    assign adder_result_expanded = $signed(adder_in_a) +  $signed(adder_in_b) ;
    assign adder_result = ((cub_arithmetic_operator == ALU_ADDT) || (cub_arithmetic_operator == ALU_SUBT)) ? ( adder_result_expanded[33]&&(~adder_result_expanded[32])     ? 32'h8000_0000 :
                                                                                                               (~adder_result_expanded[33])&&(adder_result_expanded[32]) ? 32'hEFFF_FFFF : {adder_result_expanded[32:1]} ) :
                                                                                                                                                                    {adder_result_expanded[32:1]};

    //result truncate bit
    //int8
    function [7:0]  adder_rslt_int8_truncate(input signed [32-1:0] data_in,input [4:0] truncate_Qp );
                logic signed [32-1-7:0] truncate_high;
                truncate_high = $signed(data_in[32-1:7])>>>truncate_Qp;
                 adder_rslt_int8_truncate = //datapath_mode  ? 'b0 :   //hold 0
                                           (data_in[32-1])&&(~&truncate_high)  ?  8'b1000_0000:  //negtive num
                                           (~data_in[32-1])&&(|truncate_high)  ?  8'b0111_1111:  //postive num
                                           data_in[truncate_Qp+:8];
    endfunction

    reg [31:0] adder_result_r;
    reg     adder_truncate_valid ;
    always@(posedge clk) begin
        if(cub_arithmetic_enable)
            adder_result_r <= adder_result;
    end

    always@(posedge clk or negedge rst_n) begin
        if(!rst_n)
            adder_truncate_valid <= 'b0;
        else 
            adder_truncate_valid <= /*cub_arithmetic_cflow_mode & */cub_arithmetic_enable;
    end

    wire [7:0] adder_rslt_int8_w = adder_rslt_int8_truncate(adder_result_r, cub_arithmetic_truncate_Q[4:0]);
    wire [31:0] adder_rslt_int8_ex = {{24{adder_rslt_int8_w[7]}}, adder_rslt_int8_w}; //significane in low bits


    //int16
    function [15:0] adder_rslt_int16_truncate(input signed [32-1:0] data_in, input [4:0] truncate_Qp );
                logic signed [32-1-15:0] truncate_high;
                truncate_high = $signed(data_in[32-1:15])>>>truncate_Qp;
            adder_rslt_int16_truncate = //datapath_mode? 'b0 :   //hold 0
                                           (data_in[32-1])&&(~&truncate_high)  ?  16'b1000_0000_0000_0000:  //negtive num
                                           (~data_in[32-1])&&(|truncate_high)  ?  16'b0111_1111_1111_1111:  //postive num
                                           data_in[truncate_Qp+:16];
    endfunction

    wire [15:0] adder_rslt_int16_w = adder_rslt_int16_truncate(adder_result_r, cub_arithmetic_truncate_Q[4:0]);
    wire [31:0] adder_rslt_int16_ex = {{16{adder_rslt_int16_w[15]}}, adder_rslt_int16_w}; //significane in low bits

 //   assign  adder_truncate_result = cub_arithmetic_cflow_truncate_Q_en ? ( (cub_arithmetic_operator == ALU_ADDT16) || (cub_arithmetic_operator == ALU_SUBT16) ? adder_rslt_int16_ex :  
 //                                                                          (cub_arithmetic_operator == ALU_ADDT8 ) || (cub_arithmetic_operator == ALU_SUBT8 ) ? adder_rslt_int8_ex  : adder_result ) :
 //                                   (cub_arithmetic_operator == ALU_ADDT16 ) || (cub_arithmetic_operator == ALU_SUBT16 ) ? (adder_result[16]&&adder_result[15] ? 32'h80000 : ~adder_result[16]&&adder_result[15] ? 32'heffff :adder_result) :
 //                                   (cub_arithmetic_operator == ALU_ADDT8 ) || (cub_arithmetic_operator == ALU_SUBT8 )   ? (adder_result[8]&&adder_result[7] ?   32'h80    : ~adder_result[8]&&adder_result[7]   ? 32'hef :adder_result) :
  //                                  adder_result ;

    assign  adder_truncate_result =  (cub_arithmetic_operator == ALU_ADDT16) || (cub_arithmetic_operator == ALU_SUBT16) ? adder_rslt_int16_ex :  
                                     (cub_arithmetic_operator == ALU_ADDT8 ) || (cub_arithmetic_operator == ALU_SUBT8 ) ? adder_rslt_int8_ex  : adder_result ;

    //============================
    //  compare
    //============================

    logic           is_equal;
    logic           is_greater; //handles both signed and unsigned forms
    logic           cmp_signed;

    always_comb begin
        case(cub_arithmetic_operator)
            ALU_GES,
            ALU_LTS,
            ALU_SLTS: cmp_signed = 1'b1;
            default:  cmp_signed = 1'b0;
        endcase
    end

    assign is_equal   = (cub_arithmetic_operand_a == cub_arithmetic_operand_b);
    assign is_greater = $signed({cub_arithmetic_operand_a[31] & cmp_signed, cub_arithmetic_operand_a[31:0]})
                            >
                        $signed({cub_arithmetic_operand_b[31] & cmp_signed, cub_arithmetic_operand_b[31:0]});

    //generate comparison result
    logic           cmp_result;
    logic [31:0]    comparison_cub_arithmetic_result;

    always_comb begin
        case(cub_arithmetic_operator)
            ALU_EQ:            cmp_result = is_equal;
            ALU_NE:            cmp_result = ~is_equal;
            ALU_GES, ALU_GEU:  cmp_result = is_greater | is_equal;
            ALU_LTS, ALU_SLTS,
            ALU_LTU, ALU_SLTU: cmp_result = ~(is_greater | is_equal);
            default:           cmp_result = is_equal;
        endcase
    end

    always_comb begin
        case(cub_arithmetic_operator)
            ALU_MAX:           comparison_cub_arithmetic_result =   is_greater | is_equal ? cub_arithmetic_operand_a[31:0] : cub_arithmetic_operand_b[31:0] ;
            ALU_MIN:           comparison_cub_arithmetic_result = ~(is_greater | is_equal)? cub_arithmetic_operand_b[31:0] : cub_arithmetic_operand_a[31:0] ;
            default:           comparison_cub_arithmetic_result = {31'b0 , cmp_result};
        endcase
    end



    
    //============================
    //  shift
    //============================
    logic        shift_left;         //should we shift left
    logic [31:0] shift_amt_left;     //amount of shift, if to the left
    logic [31:0] shift_amt;          //amount of shift, to the right
    logic [31:0] shift_amt_int;      //amount of shift, used for the actual shifters
    logic [31:0] shift_op_a;         //input of the shifter
    logic        shift_arithmetic;
    logic        shift_use_adder ;
    logic [31:0] shift_result;
    logic [31:0] shift_right_result;
    logic [31:0] shift_left_result;
    logic [63:0] shift_op_a_32;
    logic [31:0] operand_a_rev;

   
    //bit reverse operand_a for left shifts and bit counting
    genvar k;
    generate
        for(k=0; k<32; k++) begin
            assign operand_a_rev[k] = cub_arithmetic_operand_a[31-k];
        end
    endgenerate

 
    assign shift_left = (cub_arithmetic_operator == ALU_SLL) /*|| 
                          (cub_arithmetic_operator == ALU_DIV) || (cub_arithmetic_operator == ALU_DIVU) ||
                          (cub_arithmetic_operator == ALU_REM) || (cub_arithmetic_operator == ALU_REMU)*/;
    assign shift_arithmetic = (cub_arithmetic_operator == ALU_SRA) || (cub_arithmetic_operator == ALU_ADD) || (cub_arithmetic_operator == ALU_SUB);
    assign shift_use_adder = (cub_arithmetic_operator == ALU_ADD) || (cub_arithmetic_operator == ALU_SUB) || (cub_arithmetic_operator == ALU_ADDT)|| (cub_arithmetic_operator == ALU_SUBT);

    //shifter is also used for preparing operand for division
    assign shift_amt = cub_arithmetic_operand_b;
    assign shift_amt_int =  shift_amt;

    assign shift_op_a = shift_left ? operand_a_rev : cub_arithmetic_operand_a ; //choose the bit reversed or the normal input for shift operand a

    assign shift_op_a_32 = $signed({{32{shift_arithmetic & shift_op_a[31]}}, shift_op_a});//arithmetic or logic shift right

    assign shift_right_result = shift_op_a_32 >> shift_amt_int[4:0];


    //for left shift : bit reverse the shift_right_result for left shifts
    genvar j;
    generate
        for(j=0; j<32; j++) begin 
            assign shift_left_result[j] = shift_right_result[31-j];
        end
    endgenerate


    //result
    //assign shift_result =  shift_use_adder ? adder_truncate_result :( shift_left ? shift_left_result : shift_right_result);
    assign shift_result = shift_left ? shift_left_result : shift_right_result ;


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

    assign div_valid = cub_arithmetic_enable & ((cub_arithmetic_operator == ALU_DIV) || (cub_arithmetic_operator == ALU_DIVU) || (cub_arithmetic_operator == ALU_REM) || (cub_arithmetic_operator == ALU_REMU));

    assign div_signed = cub_arithmetic_operator[0];
    assign div_op_a_signed = cub_arithmetic_operand_a[31] & div_signed;
    assign div_op_b_signed = cub_arithmetic_operand_b[31] & div_signed;   
    assign div_a = {div_op_a_signed, cub_arithmetic_operand_a};
    assign div_b = {div_op_b_signed, cub_arithmetic_operand_b};
  
   // riscv_alu_div
   // #(
   //     .C_WIDTH(33)
   // )
   // U_alu_div(
   // .clk(clk),
   // .rst_n(rst_n),
   // 
   // .opa_i(div_b),
   // .opb_i(div_a),
   // .opcode_i(cub_arithmetic_operator[1:0]), //0:udiv, 1:div, 2:urem, 3:rem
   // 
   // .valid_i(div_valid),
   // .ready_i(cub_arithmetic_ex_ready_i),
   // .valid_o(div_ready),
   // 
   // .result_div_o(result_div)
   // );

   assign  result_div = 'b0;
    //assign cub_arithmetic_ready_o = div_ready;


    //============================
    //  result mux
    //============================
    always_comb begin
    case(cub_arithmetic_operator)
        //Standard Operations
        ALU_AND: cub_arithmetic_result = cub_arithmetic_operand_a & cub_arithmetic_operand_b;
        ALU_OR:  cub_arithmetic_result = cub_arithmetic_operand_a | cub_arithmetic_operand_b;
        ALU_XOR: cub_arithmetic_result = cub_arithmetic_operand_a ^ cub_arithmetic_operand_b;

        //Shift Operations
        ALU_ADD, ALU_SUB, ALU_ADDT, ALU_SUBT,
        ALU_ADDT16, ALU_SUBT16, ALU_SUBT8, ALU_ADDT8 : cub_arithmetic_result = adder_truncate_result ;

        ALU_SLL, ALU_SRL, ALU_SRA: cub_arithmetic_result = shift_result;
        
        //Comparison Operations
        ALU_MAX, ALU_MIN,
        ALU_EQ, ALU_NE,
        ALU_LTU,
        ALU_LTS,
        ALU_SLTS, ALU_SLTU: cub_arithmetic_result =  comparison_cub_arithmetic_result ;

        //Division Unit Commands
        ALU_DIV, ALU_DIVU,
        ALU_REM, ALU_REMU: cub_arithmetic_result = result_div[31:0];

        default: cub_arithmetic_result = adder_truncate_result; //default case to suppress unique warning
    endcase
    end

    assign cub_arithmetic_result_valid = cub_arithmetic_cflow_mode && (
                                          (cub_arithmetic_operator == ALU_ADDT16) || 
                                          (cub_arithmetic_operator == ALU_SUBT16) ||  
                                          (cub_arithmetic_operator == ALU_ADDT8 ) || 
                                          (cub_arithmetic_operator == ALU_SUBT8 )   ?  adder_truncate_valid : cub_arithmetic_enable );


    //logic  cub_adder_truncate;
    //assign cub_adder_truncate = !cub_arithmetic_cflow_mode && cub_arithmetic_enable && (
    //                            (cub_arithmetic_operator == ALU_ADDT16) || 
    //                            (cub_arithmetic_operator == ALU_SUBT16) ||  
    //                            (cub_arithmetic_operator == ALU_ADDT8 ) || 
    //                            (cub_arithmetic_operator == ALU_SUBT8 ));

    assign cub_arithmetic_ready_o = !cub_arithmetic_cflow_mode /*&& cub_arithmetic_enable*/ && (
                                          (cub_arithmetic_operator == ALU_ADDT16) || 
                                          (cub_arithmetic_operator == ALU_SUBT16) ||  
                                          (cub_arithmetic_operator == ALU_ADDT8 ) || 
                                          (cub_arithmetic_operator == ALU_SUBT8 )   ?  adder_truncate_valid : cub_arithmetic_enable );

   // enum logic {IDLE, WAIT} ns,cs;

   // always_ff @(posedge clk or negedge rst_n) begin
   //     if(!rst_n)
   //         cs <= IDLE;
   //     else
   //         cs <= ns;
   // end
   // always_comb begin
   //     ns = cs;
   //     cub_arithmetic_ready_o = 1'b1;
   //     
   //     case(cs)
   //         IDLE: begin
   //             cub_arithmetic_ready_o = 1'b1;

   //             if(cub_adder_truncate) begin
   //                 cub_arithmetic_ready_o = 1'b0;
   //                 ns = WAIT;
   //             end
   //         end
   //         WAIT: begin
   //             cub_arithmetic_ready_o = 1'b1;
   //             ns = IDLE;
   //         end
   //     endcase
   // end

endmodule
