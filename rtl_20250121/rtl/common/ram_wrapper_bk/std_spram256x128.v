module std_spram256x128_wrapper (
    input clk,
    input CEB,
    input WEB,
    input [7:0] A,
    input [127:0] D,
    output [127:0] Q
);
    wire CLK_w;

`ifdef FPGA
	assign CLK_w=clk;
	reg [127:0] sram_sim [255:0];

	always @(posedge CLK_w) begin
	    if(!CEB && !WEB) begin
	        sram_sim[A] <= D;
	    end
	end

	always @(posedge CLK_w) begin
	    Q <= sram_sim[A];
	end
`else
	wire icg_E;
	assign icg_E = ~CEB;
	icg ram_icg(.Q(CLK_w),.TE(1'b0),.CP(clk),.E(icg_E));
    tsmc_t22hpcp_hvt_uhd_s1p256x128 U_tsmc_t22hpcp_hvt_uhd_s1p256x128(
	.CLK(CLK_w),
	.CEB(CEB),
	.WEB(WEB),
	.A(A),
	.D(D),
	//.BWEB(32'd0),
	.Q(Q),
	.RTSEL(2'b10),
	.WTSEL(2'b00)
    );
`endif
endmodule
