module t22_s1pram512x32_wrapper (
    CLK,
    CEB,
    WEB,
    A,
    D,
    Q,
    BE
);

parameter	MEM_ADDR_WIDTH =  9;
parameter	MEM_DATA_WIDTH =  32;

input  			            CLK;
input  			            CEB;
input  			            WEB;
input  [MEM_ADDR_WIDTH-1:0]	A;
input  [MEM_DATA_WIDTH-1:0]	D;
output [MEM_DATA_WIDTH-1:0]	Q;
input  [3:0]  BE;

wire CLK_w;

`ifdef FPGA
	assign CLK_w=CLK;
	// fpga_bram_32x32 U_fpga_bram_32x32 (
	//     .clka     ( CLK_w	       ),
	//     .ena      ( ~CEB           ),
	//     .wea      ( ~WEB	       ),
	//     .addra    ( A	           ),
	//     .dina     ( D	           ),
	//     .douta    ( Q	           )
	// );
	ram_sp_be #(
  	  .WIDTH_BE(32),
  	  .DEPTH_BE(512),
  	  .ADDR_WIDTH_BE(9)
  	)u_ram_sp_be(
  	  .clk(CLK_w),
  	  .en(~CEB),
  	  .we(~BE & {4{~WEB}}),
  	  .addr(A),
  	  .din(D),
  	  .dout(Q)
  	);
`else
	reg [31:0] BWEB;
    assign BWEB[7:0]   = {8{BE[0]}};
    assign BWEB[15:8]  = {8{BE[1]}};
    assign BWEB[23:16] = {8{BE[2]}};
    assign BWEB[31:24] = {8{BE[3]}};
    wire icg_E;
	assign icg_E = ~CEB;
	icg ram_icg(.Q(CLK_w),.TE(1'b0),.CP(CLK),.E(icg_E));

	tsmc_t22hpcp_hvt_uhd_s1p512x32 U_tsmc_t22hpcp_hvt_uhd_s1p512x32(
	.CLK(CLK_w),
	.CEB(CEB),
	.WEB(WEB),
	.A(A),
	.D(D),
	.BWEB(BWEB),
	.Q(Q),
	.RTSEL(2'b0),
	.WTSEL(2'b0)
    );
`endif


endmodule
