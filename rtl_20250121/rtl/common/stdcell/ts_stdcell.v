module icg(output Q, input TE, CP, E);

`ifdef FPGA
    assign Q = CP;
`elsif SMIC12
    // CLKLANQV4_96S7P5T16R stdcell_icg_d0nt(.Q(Q),.TE(TE),.CK(CP),.E(E));
    CLKLANQV4_96S7P5T24R stdcell_icg_d0nt(.Q(Q),.TE(TE),.CK(CP),.E(E));
`else
    CKLNQD2BWP7T30P140 stdcell_icg_d0nt(.Q(Q),.TE(TE),.CP(CP),.E(E));
`endif

endmodule


module clk_mux(output Z ,input I1,I0,S );
`ifdef FPGA
    assign Z = S ? I1 : I0;
`elsif SMIC12
//  CLKMUX2V2_96S7P5T16R stdcell_clk_mux_d0nt(.Z(Z), .I1(I1), .I0(I0), .S(S));
 CLKMUX2V2_96S7P5T24R stdcell_clk_mux_d0nt(.Z(Z), .I1(I1), .I0(I0), .S(S));

`else

 CKMUX2D2BWP7T30P140 stdcell_clk_mux_d0nt(.Z(Z), .I1(I1), .I0(I0), .S(S));

`endif

endmodule


module clk_buf(output Z ,input I );

`ifdef FPGA
    assign Z = I;
`elsif SMIC12

//  CLKBUFV4_96S7P5T16R stdcell_clk_buf_d0nt(.Z(Z), .I(I));
 CLKBUFV4_96S7P5T24R stdcell_clk_buf_d0nt(.Z(Z), .I(I));
`else

 CKBD2BWP7T30P140 stdcell_clk_buf_d0nt(.Z(Z), .I(I));
`endif

endmodule

module clk_inv(output ZN ,input I );

`ifdef FPGA
    assign ZN = ~I;
`elsif SMIC12
//  CLKINV4_96S7P5T16R stdcell_clk_inv_d0nt(.ZN(ZN), .I(I));
 CLKINV4_96S7P5T24R stdcell_clk_inv_d0nt(.ZN(ZN), .I(I));

`else

 CKND2BWP7T30P140 stdcell_clk_inv_d0nt(.ZN(ZN), .I(I));

`endif

endmodule

module logic_buf(output Z ,input I );

`ifdef FPGA
    assign Z = I;
`elsif SMIC12
//  BUFV4_96S7P5T16R stdcell_logic_buf_d0nt(.Z(Z), .I(I));
 BUFV4_96S7P5T24R stdcell_logic_buf_d0nt(.Z(Z), .I(I));
`else
 BUFFD2BWP7T30P140 stdcell_logic_buf_d0nt(.Z(Z), .I(I));
`endif

endmodule


module cmn_buf(output Z ,input I);

`ifdef FPGA
    assign Z = I;
`elsif SMIC12
//  BUFV4_96S7P5T16R stdcell_cmn_buf_d0nt(.Z(Z), .I(I));
 BUFV4_96S7P5T24R stdcell_cmn_buf_d0nt(.Z(Z), .I(I));
`else
 BUFFD2BWP7T30P140 stdcell_cmn_buf_d0nt(.Z(Z), .I(I));
`endif
endmodule

module clk_or(output Z , input A1, input A2);

`ifdef FPGA
    assign Z = A1 | A2;
`elsif SMIC12
//  CLKOR2V2_96S7P5T16R stdcell_clk_or_d0nt(.Z(Z),.A1(A1),.A2(A2));
 CLKOR2V2_96S7P5T24R stdcell_clk_or_d0nt(.Z(Z),.A1(A1),.A2(A2));
`else
 OR2D2BWP7T30P140 stdcell_clk_or_d0nt(.Z(Z),.A1(A1),.A2(A2));
`endif
endmodule


