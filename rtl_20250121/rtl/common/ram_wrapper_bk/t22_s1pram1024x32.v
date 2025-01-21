module t22_s1pram1024x32_wrapper (
    input clk,
    input CEB,
    input WEB,
    input [9:0] A,
    input [31:0] D,
    output [31:0] Q
);

    tsmc_t22hpcp_hvt_uhd_s1p1024x32 U_tsmc_t22hpcp_hvt_uhd_s1p1024x32(
	.CLK(clk),
	.CEB(CEB),
	.WEB(WEB),
	.A(A),
	.D(D),
	.BWEB(32'd0),
	.Q(Q),
	.RTSEL(2'b00),
	.WTSEL(2'b00)
    );
endmodule
