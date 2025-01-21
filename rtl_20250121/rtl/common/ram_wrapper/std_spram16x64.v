module std_spram16x64 (
    input clk,
    input CEB,
    input WEB,
    input [3:0] A,
    input [63:0] D,
    output [63:0] Q
);

`ifdef FPGA
    ram_sp #(
      .WIDTH(64),
      .DEPTH(16),
      .ADDR_WIDTH(4)
    )u_ram_sp(
      .clk(clk),
      .en(~CEB),
      .we(~WEB),
      .addr(A),
      .din(D),
      .dout(Q)
    );

`elsif SMIC12
    s12_s1pram16x64 U_s12_s1pram16x64(
      .CLK(clk),
      .ME(~CEB),
      .WE(~WEB),
      .ADR(A),
      .D(D),
      .Q(Q),
      .TEST1(1'b0),
      .TEST_RNM(1'b0),
      .RME(1'b0),
      .RM(4'b0),
      .LS(1'b0),
      .BC1(1'b0),
      .BC2(1'b0)
    );

`else
    tsmc_t22hpcp_hvt_uhd_s1p16x64 U_tsmc_t22hpcp_hvt_uhd_s1p16x64(
	  .CLK(clk),
	  .CEB(CEB),
	  .WEB(WEB),
	  .A(A),
	  .D(D),
	  .BWEB(64'd0),
	  .Q(Q),
	  .RTSEL(2'b10),
	  .WTSEL(2'b00)
      );
`endif
endmodule
