module t22_s1pram64x32_wrapper (
    input clk,
    input CEB,
    input WEB,
    input [31:0] BWEB,
    input [5:0] A,
    input [31:0] D,
    output [31:0] Q
);

    tsmc_t22hpcp_hvt_uhd_s1p64x32 U_tsmc_t22hpcp_hvt_uhd_s1p64x32(
	.CLK(clk),
	.CEB(CEB),
	.WEB(WEB),
	.BWEB(BWEB),
	.A(A),
	.D(D),
	.Q(Q),
	.RTSEL(2'b10),
	.WTSEL(2'b00)
    );
endmodule
