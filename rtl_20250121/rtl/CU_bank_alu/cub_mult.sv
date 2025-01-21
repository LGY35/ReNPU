
module cub_mult(
  input                                         clk                             ,
  input                                         rst_n                           ,
  //------------------------------------------------------------------//
  input                                         cub_mult_enable                 ,
  input         [ 2:0]                          cub_mult_operator               ,
  input                                         cub_mult_cflow_mode             ,

  input         [31:0]                          cub_mult_operand_a              ,
  input         [31:0]                          cub_mult_operand_b              ,
  input         [15:0]                          cub_mult_lambda                 ,

  //input                                         cub_mult_op_data_signed_dis     ,
  input         [ 1:0]                          cub_mult_op_data_signed         , // 00:mulhu, mul  01:mulhsu  11:mulh
  input         [ 3:0]                          cub_mult_cflow_truncate_Q       ,

  output logic  [31:0]                          cub_mult_instr_rslt             ,

  output logic  [31:0]                          cub_mult_cflow_rslt             ,
  output logic                                  cub_mult_cflow_rslt_valid       ,
  

  output logic                                  cub_mult_multicycle_o           ,
  output logic                                  cub_mult_ready_o                ,
  //input                                         cub_mult_ready_i                ,
  //---------------------------------reused by prelu module-------------------------------------------//
  input                                         prelu_mult_en                   ,
  input        [32:0]                           prelu_mult_multiplicand         ,
  input        [16:0]                           prelu_mult_multiplier           ,
  output logic [49:0]                           prelu_mult_product              
);



    `include "decode_param.v"

    localparam  INSTR_PIPE_STAGE = 2;
    localparam  CFLOW_PIPE_STAGE = INSTR_PIPE_STAGE-1;

    //============================
    //  int mult
    //============================

    //32x32 = 32-bit multiplier
    logic signed [65:0]        mult_int_rslt       ;
    logic [32:0]        mult_signed_ext_a     ,  mult_signed_ext_b  ;
    logic               mult_signed_bit_a     ,  mult_signed_bit_b  ;               

    logic           load_en;
    logic           cnt_zero;
    logic [2-1:0]   cnt_n,cnt_p;    

    assign mult_signed_bit_a  = ~((cub_mult_operator==MUL_H) & (cub_mult_op_data_signed     ==  2'b00));   //mulhu u*u excep mul because mul: mult_operator_o = MUL_MAC32;
    assign mult_signed_bit_b  = ~((cub_mult_operator==MUL_H) & (cub_mult_op_data_signed[1]  ==  1'b0 )); //mulhu, mulhsu
    assign mult_signed_ext_a  = {{(mult_signed_bit_a | cub_mult_cflow_mode ) & cub_mult_operand_a[31]}, cub_mult_operand_a};
    assign mult_signed_ext_b  = {{(mult_signed_bit_b | cub_mult_cflow_mode )& cub_mult_operand_b[31]}, {cub_mult_cflow_mode ? {16'b0,cub_mult_lambda} : cub_mult_operand_b}};


    //
    //signed(33bit) * signed(33bit) =  signed(33bit)*(+17bit(low16bit of 33bit)) + signed(33bit)*signed(high 17bit)<<16
    //
    wire [16:0]  mult_signed_ext_a_low_hw  = {1'b0, mult_signed_ext_a[15:0] } ; //+ low bits 17bit ,posi number
    wire [16:0]  mult_signed_ext_a_high_hw = { mult_signed_ext_a[32:16] } ; //signed high 17bit

    wire [16:0]  mult_signed_ext_b_low_hw  = {1'b0, mult_signed_ext_b[15:0] } ; //+ low bits 17bit ,posi number
    wire [16:0]  mult_signed_ext_b_high_hw = { mult_signed_ext_b[32:16] } ; //signed high 17bit


    wire [16:0]  prelu_mult_multiplicand_low_hw  = {1'b0, prelu_mult_multiplicand[15:0] } ; //+ low bits 17bit ,posi number
    wire [16:0]  prelu_mult_multiplicand_high_hw = { prelu_mult_multiplicand[32:16] } ; //signed high 17bit

    logic signed [33+17-1:0]   mult_low_hw_int_rslt, mult_high_hw_int_rslt, cub_mult_high_product;
    logic signed [17+17-1:0]   mult_low_hw_int_rslt_lw, mult_low_hw_int_rslt_hi; 
    logic signed [17+17-1:0]   mult_high_hw_int_rslt_lw, mult_high_hw_int_rslt_hi;

    reg [CFLOW_PIPE_STAGE-1:0]  mult_cflow_pipe_valid;

    //always@(posedge clk or negedge rst_n) begin
    //    if(!rst_n)
    //        mult_cflow_pipe_valid <= 'b0;
    //    else
    //        mult_cflow_pipe_valid <=  {mult_cflow_pipe_valid[INSTR_PIPE_STAGE-2:0], cub_mult_enable}
    //end

    always@(posedge clk or negedge rst_n) begin
        if(!rst_n)
            mult_cflow_pipe_valid <= 'b0;
        else 
            mult_cflow_pipe_valid <=  cub_mult_enable;//one stage
    end


    assign cub_mult_cflow_rslt_valid = cub_mult_cflow_mode&&mult_cflow_pipe_valid[CFLOW_PIPE_STAGE-1];

    ////low +17bit,signed(33bit)*(+17bit(low16bit of 33bit))
    //DW_mult_pipe #(
    //.a_width(17),
    //.b_width(17),
    //.num_stages(INSTR_PIPE_STAGE+1-1),
    //.stall_mode(1),
    //.rst_mode(1)
    //)
    //U_cub_mult_low33x16_hw_lw 
    //(
    //.clk(clk),
    //.rst_n(rst_n),
    //.en(cub_mult_enable), // enable == flow ready,but no ready in cflow
    //.tc(1'b1),
    //.a(mult_signed_ext_a_low_hw),
    //.b(mult_signed_ext_b_low_hw),
    //.product(mult_low_hw_int_rslt_lw)
    //);
    //
    always@(posedge clk ) begin
        if(cub_mult_enable)
            mult_low_hw_int_rslt_lw <= mult_signed_ext_a_low_hw * mult_signed_ext_b_low_hw ;
    end
    

    //DW_mult_pipe #(
    //.a_width(17),
    //.b_width(17),
    //.num_stages(INSTR_PIPE_STAGE+1-1),
    //.stall_mode(1),
    //.rst_mode(1)
    //)
    //U_cub_mult_low33x16_hw_hi 
    //(
    //.clk(clk),
    //.rst_n(rst_n),
    //.en(cub_mult_enable), // enable == flow ready,but no ready in cflow
    //.tc(1'b1),
    //.a(mult_signed_ext_a_high_hw),
    //.b(mult_signed_ext_b_low_hw),
    //.product(mult_low_hw_int_rslt_hi)
    //);

    always@(posedge clk ) begin
        if(cub_mult_enable)
            mult_low_hw_int_rslt_hi <= mult_signed_ext_a_high_hw * mult_signed_ext_b_low_hw ;
    end
    

    assign mult_low_hw_int_rslt = $signed({mult_low_hw_int_rslt_hi,16'b0}) + $signed(mult_low_hw_int_rslt_lw) ;

    //high +17bit, signed(33bit)*signed(high 17bit)<<16
   // DW_mult_pipe #(
   // .a_width(17),
   // .b_width(17),
   // .num_stages(INSTR_PIPE_STAGE+1-1),
   // .stall_mode(1),
   // .rst_mode(1)
   // )
   // U_cub_mult_high33x16_hw_lw 
   // (
   // .clk(clk),
   // .rst_n(rst_n),
   // .en(cub_mult_cflow_mode ? prelu_mult_en           :  cub_mult_enable             ),// enable == flow ready,but no ready in cflow
   // .tc(1'b1),
   // .a(cub_mult_cflow_mode ?  prelu_mult_multiplicand_low_hw :  mult_signed_ext_a_low_hw    ),
   // .b(cub_mult_cflow_mode ?  prelu_mult_multiplier   :  mult_signed_ext_b_high_hw   ),
   // .product(mult_high_hw_int_rslt_lw)
   // );


    wire signed [16:0] mult_hl_reuse_op_a    =   cub_mult_cflow_mode ?  prelu_mult_multiplicand_low_hw :  mult_signed_ext_a_low_hw  ;
    wire signed [16:0] mult_hl_reuse_op_b    =   cub_mult_cflow_mode ?  prelu_mult_multiplier   :  mult_signed_ext_b_high_hw ;

    wire mult_hl_resue_vld = cub_mult_cflow_mode ? prelu_mult_en   :  cub_mult_enable ;
    
    always@(posedge clk ) begin
        if(mult_hl_resue_vld)
            mult_high_hw_int_rslt_lw <= mult_hl_reuse_op_a * mult_hl_reuse_op_b ;
    end


    //high +17bit, signed(33bit)*signed(high 17bit)<<16
   // DW_mult_pipe #(
   // .a_width(17),
   // .b_width(17),
   // .num_stages(INSTR_PIPE_STAGE+1-1),
   // .stall_mode(1),
   // .rst_mode(1)
   // )
   // U_cub_mult_high33x16_hw_hi 
   // (
   // .clk(clk),
   // .rst_n(rst_n),
   // .en(cub_mult_cflow_mode ? prelu_mult_en           :  cub_mult_enable             ),// enable == flow ready,but no ready in cflow
   // .tc(1'b1),
   // .a(cub_mult_cflow_mode ?  prelu_mult_multiplicand_high_hw :  mult_signed_ext_a_high_hw   ),
   // .b(cub_mult_cflow_mode ?  prelu_mult_multiplier           :  mult_signed_ext_b_high_hw   ),
   // .product(mult_high_hw_int_rslt_hi)
   // );
   

    wire signed [16:0] mult_hh_reuse_op_a    =   cub_mult_cflow_mode ?  prelu_mult_multiplicand_high_hw :  mult_signed_ext_a_high_hw  ;
    wire signed [16:0] mult_hh_reuse_op_b    =   cub_mult_cflow_mode ?  prelu_mult_multiplier           :  mult_signed_ext_b_high_hw ;

    wire mult_hh_resue_vld = cub_mult_cflow_mode ? prelu_mult_en  :  cub_mult_enable ;
    
    always@(posedge clk ) begin
        if(mult_hh_resue_vld)
            mult_high_hw_int_rslt_hi <= mult_hh_reuse_op_a * mult_hh_reuse_op_b ;
    end




    wire [33+17-1:0]   cub_mult_high_product_w = $signed(mult_high_hw_int_rslt_lw) ;

    assign cub_mult_high_product =  $signed({ mult_high_hw_int_rslt_hi,16'b0}) +  $signed(mult_high_hw_int_rslt_lw);

    assign prelu_mult_product = cub_mult_cflow_mode ? cub_mult_high_product : 'b0;
    assign mult_high_hw_int_rslt = cub_mult_cflow_mode ? 'b0 : cub_mult_high_product;



    wire [16:0]   mult_complexnum_real =  cub_mult_operator == MUL_CCNI16 ? mult_high_hw_int_rslt_hi + mult_low_hw_int_rslt_lw  : mult_high_hw_int_rslt_hi - mult_low_hw_int_rslt_lw ;
    wire [16:0]   mult_complexnum_im   = mult_low_hw_int_rslt_hi + mult_high_hw_int_rslt_lw ;
    wire [15:0]   mult_complexnum_real_trunc =  (mult_complexnum_real[16]) & !mult_complexnum_real[15] ?  16'h8000 : (!mult_complexnum_real[16]) & mult_complexnum_real[15]  ?  16'h7fff: mult_complexnum_real[15:0] ;
    wire [15:0]   mult_complexnum_im_trunc   =  (mult_complexnum_im  [16]) & !mult_complexnum_im  [15] ?  16'h8000 : (!mult_complexnum_im  [16]) & mult_complexnum_im  [15]  ?  16'h7fff: mult_complexnum_im  [15:0] ;

    wire [31:0]   mult_complexnum_rslt = { mult_complexnum_im_trunc, mult_complexnum_real_trunc};

    logic cub_mult_enable_r;
    assign mult_int_rslt = $signed({mult_high_hw_int_rslt,16'b0}) + $signed(mult_low_hw_int_rslt );
    //mult_int_rslt <= cub_mult_operator == MUL_NCNI16 || cub_mult_operator == MUL_CCNI16  ?  mult_complexnum_rslt : mult_int_rslt_w;

    always@(posedge clk ) begin
        cub_mult_enable_r <= mult_cflow_pipe_valid;
        if(mult_cflow_pipe_valid) begin
           case(cub_mult_operator)
            MUL_MAC32:   cub_mult_instr_rslt <= mult_int_rslt[31:0];
            MUL_H:       cub_mult_instr_rslt <= mult_int_rslt[63:32];
            MUL_NCNI16:  cub_mult_instr_rslt <= mult_complexnum_rslt;
            MUL_CCNI16:  cub_mult_instr_rslt <= mult_complexnum_rslt;
            default:     cub_mult_instr_rslt <= mult_int_rslt[31:0];//default case to suppress unique warning
        endcase
        end
                
    end


    //============================
    //  result mux
    //============================
   // always_comb begin
   //     case(cub_mult_operator)
   //         MUL_MAC32:  cub_mult_instr_rslt = mult_int_rslt[31:0];
   //         MUL_H:      cub_mult_instr_rslt = mult_int_rslt[63:32];
   //         MUL_NCNI16:  cub_mult_instr_rslt = mult_int_rslt[31:0];
   //         MUL_CCNI16:  cub_mult_instr_rslt = mult_int_rslt[31:0];
   //         default:    cub_mult_instr_rslt = 'b0; //default case to suppress unique warning
   //     endcase
   // end
    

    //===============================
    //
    //================================
    function [31:0] bn_int48_to_int32_truncate(input signed [47:0] data_in,input [3:0] truncate_Qp );

        logic [16:0] truncate_int32_high;
        
                truncate_int32_high = $signed(data_in[47:31])>>>truncate_Qp;
                bn_int48_to_int32_truncate =   //int32
                                           ( data_in[47])&&(~&truncate_int32_high)  ?  32'h8000_0000:  //negtive num
                                           (~data_in[47])&&(|truncate_int32_high)  ?  32'h7fff_ffff:  //postive num
                                           { data_in[truncate_Qp+:32]}; //recopy signed bit
    endfunction



  assign cub_mult_cflow_rslt =   bn_int48_to_int32_truncate(mult_low_hw_int_rslt[47:0], cub_mult_cflow_truncate_Q);


 //   //=============================================================

 //   enum logic [1:0] {IDLE, MULT, FINISH} cub_mult_ns, cub_mult_cs;

 //   assign cnt_n = load_en ? INSTR_PIPE_STAGE-1 : (~cnt_zero) ? cnt_p-1 : cnt_p;
 //   assign cnt_zero = ~(|cnt_p); // cnt_zero is 1 when cnt_p == 0

 //   always_ff@(posedge clk or negedge rst_n) begin
 //       if(~rst_n) begin
 //           cub_mult_cs <= IDLE;
 //           cnt_p <= 'b0;
 //       end
 //       else begin
 //           cub_mult_cs <= cub_mult_ns;
 //           cnt_p <= cnt_n;
 //       end
 //   end

 // 
 //    always_comb begin
 //       cub_mult_ns = cub_mult_cs;
 //       cub_mult_ready_o = 1'b0;
 //       load_en = 1'b0;
 //       cub_mult_multicycle_o = 1'b0;

 //       case(cub_mult_cs)
 //           IDLE: begin
 //               cub_mult_ready_o = 1'b1;

 //               if(cub_mult_enable) begin
 //                   cub_mult_ready_o = 1'b0;
 //                   load_en = 1'b1;
 //                   cub_mult_ns = MULT;
 //               end
 //           end
 //           MULT: begin
 //               //cub_mult_multicycle_o = 1'b1;
 //               if(cnt_zero) begin
 //                   cub_mult_ready_o = 1'b1;
 //                   cub_mult_ns = IDLE;
 //               end
 //           end
 //               //end
 //       endcase
 //   end

  assign cub_mult_ready_o = (!cub_mult_cflow_mode) && cub_mult_enable_r;

endmodule
