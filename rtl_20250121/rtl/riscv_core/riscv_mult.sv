/*
Design Name     : Multiplier
Data            : 2024/2/19      
Description     :  
*/

module riscv_mult(
  input                 clk,
  input                 rst_n,

  input                 enable_i,
  input [ 2:0]          operator_i,

  input [31:0]          op_a_i,
  input [31:0]          op_b_i,
  //input [31:0]          op_c_i,
  //input [ 4:0]          imm_i,
  input [ 1:0]          short_signed_i,

  output logic [31:0]   result_o,

  //output logic          multicycle_o,
  output logic          ready_o,
  input                 ready_i
);

    `include "decode_param.v"

    localparam  PIPE_STAGE = 1;

    //============================
    //  int mult
    //============================

    //32x32 = 32-bit multiplier
    logic signed [65:0]    int_result;
    logic signed [32:0]    mult_a,mult_b;
    logic           mult_signed_a,mult_signed_b;
    logic           load_en;
    logic           cnt_zero;
    logic [2:0]     cnt_n,cnt_p;

    assign mult_signed_a = ~((operator_i==MUL_H) & (short_signed_i==2'b00)); //mulhu
    assign mult_signed_b = ~((operator_i==MUL_H) & (short_signed_i[1]==1'b0)); //mulhu, mulhsu
    assign mult_a = {{mult_signed_a & op_a_i[31]}, op_a_i};
    assign mult_b = {{mult_signed_b & op_b_i[31]}, op_b_i};

    logic signed [33+17-1:0] int_result_high ;
    logic signed [33+17-1:0] int_result_low ;

    wire signed  [16:0] a_high_i16 = mult_a[32:16];
    wire signed  [16:0] a_low_i16 = {1'b0,  mult_a[15:0]};

    wire signed  [16:0] b_high_i16 = mult_b[32:16];
    wire signed  [16:0] b_low_i16 = {1'b0,  mult_b[15:0]};

  //  always@(posedge clk)
  //      if(enable_i) 
  //          int_result_high <= $signed(mult_a)*$signed(b_high_i16); 

  //  always@(posedge clk)
  //      if(enable_i) 
  //          int_result_low  <= $signed(mult_a)*$signed(b_low_i16); 

  //  always@(posedge clk)
  //      if(enable_i)
  //          int_result <= {int_result_high,16'b0} + {{16{int_result_low[49]}},int_result_low} ;
   // DW_mult_pipe #(
   // .a_width(33),
   // .b_width(33),
   // .num_stages(PIPE_STAGE+1),
   // .stall_mode(1),
   // .rst_mode(1)
   // )
   // U_mult
   // (
   // .clk(clk),
   // .rst_n(rst_n),
   // .en(enable_i),
   // .tc(1'b1),
   // .a(mult_a),
   // .b(mult_b),
   // .product(int_result)
   // );
    logic start_valid,start;
    always_ff@(posedge clk or negedge rst_n) 
        if(!rst_n) 
            start_valid <= 'b0;
        else
            start_valid <= enable_i;

    assign start = enable_i && !start_valid ;

  logic complete ;
    DW_mult_seq #(
    .a_width(33),
    .b_width(33),
    .tc_mode(1),
    .num_cyc(3),
    .rst_mode(0),
    .input_mode(0),
    .output_mode(1),
    .early_start(0)
    )
    U_riscv_mult (
    .clk(clk),   
    .rst_n(rst_n),   
    .hold(1'b0), 
    .start(start ),   
    .a(mult_a),   
    .b(mult_b), 
    .complete(complete),   
    .product(int_result) );


assign ready_o = complete && !start;
    //============================
    //  result mux
    //============================
    always_comb begin
        case(operator_i)
            MUL_MAC32:  result_o = int_result[31:0];
            MUL_H:      result_o = int_result[63:32];
            default:    result_o = 'b0; //default case to suppress unique warning
        endcase
    end
/*    
    enum logic [1:0] {IDLE, MULT, FINISH} ns, cs;

    assign cnt_n = load_en ? PIPE_STAGE-1 : (~cnt_zero) ? cnt_p-1 : cnt_p;
    assign cnt_zero = ~(|cnt_p);

    always_ff@(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            cs <= IDLE;
            cnt_p <= 'b0;
        end
        else begin
            cs <= ns;
            cnt_p <= cnt_n;
        end
    end

    always_comb begin
        ns = cs;
        ready_o = 1'b0;
        load_en = 1'b0;
        multicycle_o = 1'b0;

        case(cs)
            IDLE: begin
                ready_o = 1'b1;

                if(enable_i) begin
                    ready_o = 1'b0;
                    load_en = 1'b1;
                    ns = MULT;
                end
            end
            MULT: begin
                //multicycle_o = 1'b1;
                if(cnt_zero) begin
                    ready_o = 1'b1;
                    ns = IDLE;
                    //ns = FINISH;
                end
            end
            //FINISH: begin
            //    ready_o = 1'b1;
            //    
            //    if(ready_i) begin
            //        ns = IDLE;
            //    end
            //end
        endcase
    end
    */
endmodule
