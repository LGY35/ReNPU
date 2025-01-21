module datapath_src_mux42 #(
    parameter DWID    = 24,
    parameter CH_NUM  = 8
    )
    (
      input  [1:0]       S,     //00: B,A 01:C,A 10: C,B  11:D,A
      output        A_ready,
      input         A_valid,
      input [CH_NUM-1:0][DWID-1:0]    A_data,
      output        B_ready,
      input         B_valid,
      input [CH_NUM-1:0][DWID-1:0]    B_data,
      output        C_ready,
      input         C_valid,
      input [CH_NUM-1:0][DWID-1:0]    C_data,
      output        D_ready,
      input         D_valid,
      input [CH_NUM-1:0][DWID-1:0]    D_data,

      output [CH_NUM-1:0][DWID-1:0]    Z0_data,
      output [CH_NUM-1:0][DWID-1:0]    Z1_data,
      output                           Z_valid,
      input                            Z_ready
    );


//2'b 0 0  ||   0 1   || 1 0  || 1 1
//    B A       C A      C B     D A

assign A_ready = (S == 2'b00 )?  Z_ready && B_valid:
                 (S == 2'b01 )?  Z_ready && C_valid:
                 (S == 2'b11 )?  Z_ready && D_valid: 1'b1;

assign B_ready = (S == 2'b00 )?  Z_ready && A_valid:
                 (S == 2'b10 )?  Z_ready && C_valid: 1'b1;

assign C_ready = (S == 2'b01 )?  Z_ready && A_valid:
                 (S == 2'b10 )?  Z_ready && B_valid: 1'b1;

assign D_ready = (S    == 2'b11)? Z_ready && A_valid : 1'b1;


assign Z_valid = (S == 2'b00)? A_valid&&B_valid : 
                 (S == 2'b01)? A_valid&&C_valid : 
                 (S == 2'b10)? B_valid&&C_valid : 
                 A_valid&&D_valid ; 

assign {Z1_data, Z0_data} = (S == 2'b00)?  {B_data, A_data} : 
                            (S == 2'b01)?  {C_data, A_data} :  
                            (S == 2'b10)?  {C_data, B_data} :
                            {D_data,A_data} ; 
endmodule
