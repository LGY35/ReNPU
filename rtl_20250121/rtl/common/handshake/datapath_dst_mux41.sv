module datapath_dst_mux41 #(
    parameter DWID    = 24,
    parameter CH_NUM  = 8
    )
    (
      input  [1:0]       S,  // 00: Z0 01: Z1 10: Z2 11:Z3
      input        Z0_ready,
      output         Z0_valid,
      output [CH_NUM-1:0][DWID-1:0]    Z0_data,
      input        Z1_ready,
      output         Z1_valid,
      output [CH_NUM-1:0][DWID-1:0]    Z1_data,
      input        Z2_ready,
      output         Z2_valid,
      output [CH_NUM-1:0][DWID-1:0]    Z2_data,
      input        Z3_ready,
      output         Z3_valid,
      output [CH_NUM-1:0][DWID-1:0]    Z3_data,

      output        A_ready,
      input         A_valid,
      input [CH_NUM-1:0][DWID-1:0]    A_data
    );



assign A_ready = S == 2'b00 ? Z0_ready:
                 S == 2'b01 ? Z1_ready: 
                 S == 2'b10 ? Z2_ready : Z3_ready;


assign Z0_valid = (S == 2'b00)&A_valid;
assign Z1_valid = (S == 2'b01)&A_valid;
assign Z2_valid = (S == 2'b10)&A_valid;
assign Z3_valid = (S == 2'b11)&A_valid;

assign Z0_data  = A_data;
assign Z1_data  = A_data;
assign Z2_data  = A_data;
assign Z3_data  = A_data;

endmodule
