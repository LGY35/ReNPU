module std_spram256x128_b16 (
	CLK,
	CEB,
	WEB,
	A,
	D,
	Q,
	BWEB
);
 parameter MAX_ADDR	= 255;
 parameter MEM_ADDR_WIDTH = 8; 
 parameter MEM_DATA_WIDTH = 128;
 parameter BITMASK_WIDTH = 16;

 input 				CLK;
 input 				CEB;
 input 				WEB;
 input	[MEM_ADDR_WIDTH-1:0]	A;
 input	[MEM_DATA_WIDTH-1:0]	D;
 output	[MEM_DATA_WIDTH-1:0]	Q;
 input	[BITMASK_WIDTH-1:0]	BWEB;
 
 wire 	[MEM_DATA_WIDTH-1:0]	bitmask;
genvar i;
generate
for(i=0;i<16;i=i+1)begin:bitmask_ins
 assign bitmask[i*8 +:8] =  {8{BWEB[i]}};
end
endgenerate
//----------------------------------------
wire CLK_w;

`ifdef FPGA 
	assign CLK_w=CLK;
	// wire [7:0] fpga_wea_pre;
	// wire [7:0] fpga_wea;
    //     genvar i;
    //     generate
    //     for(i=0;i<8;i=i+1)begin:bitmask_ins
    //      assign fpga_wea_pre[i] = ~BWEB[i*2];
    //     end
    //     endgenerate
	// assign fpga_wea = ~WEB ? fpga_wea_pre : 8'b0;

	// //inst FPGA sram
	// fpga_bram_256x128 U_fpga_bram_256x128  (
	//     .clka     ( CLK_w	       ),
	//     .ena      ( ~CEB              ),
	//     .wea      ( fpga_wea	              ),
	//     .addra    ( A	              ),
	//     .dina     ( D	          ),
	//     .douta    ( Q	          )
	// );
	ram_sp_be #(
  	  .WIDTH_BE(128),
  	  .DEPTH_BE(256),
  	  .ADDR_WIDTH_BE(8)
  	)u_ram_sp_be(
  	  .clk(CLK_w),
  	  .en(~CEB),
  	  .we(~BWEB & {16{~WEB}}),
  	  .addr(A),
  	  .din(D),
  	  .dout(Q)
  	);
`else 
	wire icg_E;
	assign icg_E = ~CEB;
	//icg ram_icg(.Q(CLK_w),.TE(1'b0),.CP(CLK),.E(icg_E));
    assign CLK_w = CLK;
	tsmc_t22hpcp_hvt_uhd_s1p256x128e lb_ram_s1p256x128 (
		.CLK(CLK_w),
		.CEB(CEB),
		.WEB(WEB),
		.A(A),
		.D(D),
		.Q(Q),
		.BWEB(bitmask),
		.RTSEL(2'b10),
		.WTSEL(2'b00)
	);
`endif

endmodule

