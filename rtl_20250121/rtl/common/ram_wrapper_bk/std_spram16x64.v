module t22_s1pram16x64_wrapper (
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
