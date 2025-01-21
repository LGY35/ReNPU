module datapath_src_mux2 #(
    parameter DWID    = 24,
    parameter CH_NUM  = 32
    )
    (
      input         S,
      output        A_ready,
      input         A_valid,
      input         A_last,
      input [CH_NUM-1:0][DWID-1:0]    A_data,
      output        B_ready,
      input         B_valid,
      input         B_last,
      input [CH_NUM-1:0][DWID-1:0]    B_data,

      input        Z_ready,
      output         Z_valid,
      output         Z_last,
      output [CH_NUM-1:0][DWID-1:0]    Z_data
    );



assign A_ready =  ( !S )&& Z_ready;
assign B_ready =  S&&Z_ready;


assign Z_valid = S? B_valid : A_valid;
assign Z_data  = S? B_data : A_data;


assign Z_last = S? B_last : A_last;
endmodule
