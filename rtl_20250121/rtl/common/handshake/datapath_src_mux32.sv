module datapath_src_mux32 #(
    parameter DWID    = 24,
    parameter CH_NUM  = 8
    )
    (
      input  [1:0]       S,     //00: B,A 01:C,A 10: C,B  11:C,C
      output        A_ready,
      input         A_valid,
      input [CH_NUM-1:0][DWID-1:0]    A_data,
      output        B_ready,
      input         B_valid,
      input [CH_NUM-1:0][DWID-1:0]    B_data,
      output        C_ready,
      input         C_valid,
      input [CH_NUM-1:0][DWID-1:0]    C_data,

      output [CH_NUM-1:0][DWID-1:0]    Z0_data,
      output [CH_NUM-1:0][DWID-1:0]    Z1_data,
      output                           Z_valid,
      input                            Z_ready
    );


//2'b 0 0  ||   0 1   || 1 0  || 1 1
//    B A       C A      C B     A A

assign A_ready = (S[1] == 1'b0)&&Z_ready;
assign B_ready = (S[0] == 1'b0)&&Z_ready;
assign C_ready = (S != 2'b00)&&Z_ready;

assign Z_valid = (S == 2'b00)? A_valid&&B_valid : 
                 (S == 2'b01)? A_valid&&C_valid : 
                 (S == 2'b10)? B_valid&&C_valid : 
                 C_valid ; 

assign {Z1_data, Z0_data} = (S == 2'b00)?  {B_data, A_data} : 
                            (S == 2'b01)?  {C_data, A_data} :  
                            (S == 2'b10)?  {C_data, B_data} :
                            {C_data,C_data} ; 
endmodule
