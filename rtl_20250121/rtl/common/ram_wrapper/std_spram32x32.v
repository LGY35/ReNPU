module std_spram32x32 (
    CLK,
    CEB,
    WEB,
    A,
    D,
    Q
);

parameter	MEM_ADDR_WIDTH =  5;
parameter	MEM_DATA_WIDTH =  32;

input  			            CLK;
input  			            CEB;
input  			            WEB;
input  [MEM_ADDR_WIDTH-1:0]	A;
input  [MEM_DATA_WIDTH-1:0]	D;
output [MEM_DATA_WIDTH-1:0]	Q;

wire CLK_w;

`ifdef FPGA
	  assign CLK_w=CLK;

	  ram_sp #(
      .WIDTH(32),
      .DEPTH(32),
      .ADDR_WIDTH(5)
    )u_ram_sp(
      .clk(CLK),
      .en(~CEB),
      .we(~WEB),
      .addr(A),
      .din(D),
      .dout(Q)
    );

`elsif SMIC12
    wire icg_E;
	  assign icg_E = ~CEB;
	  icg ram_icg(.Q(CLK_w),.TE(1'b0),.CP(CLK),.E(icg_E));

    s12_s1pram32x32 U_s12_s1pram32x32(
      .CLK(CLK_w),
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
	  wire icg_E;
	  assign icg_E = ~CEB;
	  icg ram_icg(.Q(CLK_w),.TE(1'b0),.CP(CLK),.E(icg_E));

    tsmc_t22hpcp_hvt_uhd_s1p32x32 U_tsmc_t22hpcp_hvt_uhd_s1p32x32(
	  .CLK(CLK_w),
	  .CEB(CEB),
	  .WEB(WEB),
	  .A(A),
	  .D(D),
	  .BWEB(32'b0),
	  .Q(Q),
	  .RTSEL(2'b00),
	  .WTSEL(2'b00)
    );
`endif

endmodule
