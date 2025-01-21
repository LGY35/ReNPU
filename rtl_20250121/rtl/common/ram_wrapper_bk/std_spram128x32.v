module t22_s1pram128x32_wrapper (
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
