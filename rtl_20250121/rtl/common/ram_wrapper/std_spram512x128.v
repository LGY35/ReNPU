module std_spram512x128 (
    input clk,
    input CEB,
    input WEB,
    input [8:0] A,
    input [127:0] D,
	`ifdef FPGA
    	output reg [127:0] Q
	`else
		output [127:0] Q
	`endif
);

wire CLK_w;

`ifdef FPGA
	assign CLK_w=clk;
	reg [128-1:0] sram_sim [511:0];

	always @(posedge CLK_w) begin
	    if(!CEB && !WEB) begin
	        sram_sim[A] <= D;
	    end
	end

	always @(posedge clk) begin
		if(!CEB && WEB)
	    	Q <= sram_sim[A];
	end

`elsif SMIC12
	wire icg_E;
	assign icg_E = ~CEB;
	icg ram_icg(.Q(CLK_w),.TE(1'b0),.CP(clk),.E(icg_E));

    s12_s1pram512x128 U_s12_s1pram512x128(
      .CLK(CLK_w),
      .ME(~CEB),
      .WE(~WEB),
<<<<<<< .mine
      //.WEM({128{1'b1}}),
=======
>>>>>>> .r1042
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
	wire icg_E;
	assign icg_E = ~CEB;
	icg ram_icg(.Q(CLK_w),.TE(1'b0),.CP(clk),.E(icg_E));

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
`endif
endmodule
