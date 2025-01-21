module datapath_src_mux51 #(
    parameter DWID    = 24,
    parameter CH_NUM  = 8
    )
    (
      input  [2:0]       S,     //000: A 001: B 010: C 011: D 100: E
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
      output        E_ready,
      input         E_valid,
      input [CH_NUM-1:0][DWID-1:0]    E_data,
      
      

      output [CH_NUM-1:0][DWID-1:0]    Z_data,
      output                           Z_valid,
      input                            Z_ready
    );


//2'b 0 0  ||   0 1   || 1 0  || 1 1
//    B A       C A      C B     A A

assign A_ready = (S ==  3'b000)&&Z_ready;
assign B_ready = (S ==  3'b001)&&Z_ready;
assign C_ready = (S ==  3'b010)&&Z_ready;
assign D_ready = (S ==  3'b011)&&Z_ready;
assign E_ready = (S ==  3'b100)&&Z_ready;

assign  Z_valid = (S == 3'b000)? A_valid : 
                  (S == 3'b001)? B_valid : 
                  (S == 3'b010)? C_valid : 
                  (S == 3'b011)? D_valid : E_valid;

assign  Z_data = (S == 3'b000)?  {A_data} : 
                 (S == 3'b001)?  {B_data} :  
                 (S == 3'b010)?  {C_data} :  
                 (S == 3'b011)?  {D_data} : E_data;
                           
endmodule

