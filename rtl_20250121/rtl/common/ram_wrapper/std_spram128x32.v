module std_spram128x32 (
    input CLK,
    input CE,
    input WE,
    input [6:0] A,
    input [31:0] D,
    output [31:0] Q
);

wire CLK_w;

`ifdef FPGA
	assign CLK_w=CLK;
	ram_sp #(
  	  .WIDTH(32),
  	  .DEPTH(128),
  	  .ADDR_WIDTH(7)
  	)u_ram_sp(
  	  .clk(CLK_w),
  	  .en(CE),
  	  .we(WE),
  	  .addr(A),
  	  .din(D),
  	  .dout(Q)
  	);

`elsif SMIC12
	wire icg_E;
	assign icg_E = CE;
	icg ram_icg(.Q(CLK_w),.TE(1'b0),.CP(CLK),.E(icg_E));

    s12_s1pram128x32 U_s12_s1pram128x32(
      .CLK(CLK_w),
      .ME(CE),
      .WE(WE),
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
	assign icg_E = CE;
	icg ram_icg(.Q(CLK_w),.TE(1'b0),.CP(CLK),.E(icg_E));
    
    tsmc_t22hpcp_hvt_uhd_s1p128x32 U_tsmc_t22hpcp_hvt_uhd_s1p128x32(
	.CLK(CLK_w),
	.CEB(~CE),
	.WEB(~WE),
	//.BWEB(32'd0),
	.A(A),
	.D(D),
	.Q(Q),
	.RTSEL(2'b10),
	.WTSEL(2'b00)
    );
`endif
endmodule
