module datapath_dst_mux2 #(
    parameter DWID    = 24,
    parameter CH_NUM  = 32
    )
    (
      input         S,
      input        Z0_ready,
      output         Z0_valid,
      output         Z0_last,
      output [CH_NUM-1:0][DWID-1:0]    Z0_data,
      input        Z1_ready,
      output         Z1_valid,
      output         Z1_last,
      output [CH_NUM-1:0][DWID-1:0]    Z1_data,

      output        A_ready,
      input         A_valid,
      input         A_last,
      input [CH_NUM-1:0][DWID-1:0]    A_data
    );



assign A_ready = S? Z1_ready: Z0_ready;


assign Z0_valid = (~S)&A_valid;
assign Z1_valid = S&A_valid;


assign Z0_last = (~S)&A_last;
assign Z1_last = S&A_last;

assign Z0_data  = A_data;
assign Z1_data  = A_data;


endmodule
