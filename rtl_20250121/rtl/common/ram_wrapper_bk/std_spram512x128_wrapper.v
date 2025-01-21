module std_spram512x128_wrapper (
    input clk,
    input CEB,
    input WEB,
    input [8:0] A,
    input [127:0] D,
    output [127:0] Q
);
    wire CLK_w;

    `ifdef FPGA
	assign CLK_w=clk;
    `else
	wire icg_E;
	assign icg_E = ~CEB;
	icg ram_icg(.Q(CLK_w),.TE(1'b0),.CP(clk),.E(icg_E));
    `endif

    tsmc_t22hpcp_hvt_uhd_s1p512x128 U_tsmc_t22hpcp_hvt_uhd_s1p512x128(
	.CLK(CLK_w),
	.CEB(CEB),
	.WEB(WEB),
	.A(A),
	.D(D),
	//.BWEB(32'd0),
	.Q(Q),
	.RTSEL(2'b00),
	.WTSEL(2'b00)
    );
endmodule
