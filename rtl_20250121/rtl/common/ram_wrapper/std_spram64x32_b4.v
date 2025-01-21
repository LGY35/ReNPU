module std_spram64x32_b4 (
	CLK,
	CEB,
	WEB,
	A,
	D,
	Q,
	BWEB
);
 parameter MEM_DEPTH=64  ;
 parameter MAX_ADDR	= MEM_DEPTH-1;
 parameter MEM_ADDR_WIDTH = $clog2(MEM_DEPTH); 
 parameter MEM_DATA_WIDTH = 32;
 parameter BITMASK_WIDTH = 4;
 parameter BITMASK_BUS   = MEM_DATA_WIDTH/BITMASK_WIDTH ;

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
for(i=0;i<BITMASK_WIDTH;i=i+1)begin:bitmask_ins
 assign bitmask[i*BITMASK_BUS +: BITMASK_BUS] =  {BITMASK_BUS{BWEB[i]}};
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
	// fpga_bram_64x32 U_fpga_bram_64x32  (
	//     .clka     ( CLK_w	       ),
	//     .ena      ( ~CEB              ),
	//     .wea      ( fpga_wea	              ),
	//     .addra    ( A	              ),
	//     .dina     ( D	          ),
	//     .douta    ( Q	          )
	// );

	ram_sp_be #(
  	  .WIDTH_BE(32),
  	  .DEPTH_BE(64),
  	  .ADDR_WIDTH_BE(6)
  	)u_ram_sp_be(
  	  .clk(CLK),
  	  .en(~CEB),
  	  .we(~BWEB & {4{~WEB}}),
  	  .addr(A),
  	  .din(D),
  	  .dout(Q)
  	);

`elsif SMIC12
	wire icg_E;
	assign icg_E = ~CEB;
	icg ram_icg(.Q(CLK_w),.TE(1'b0),.CP(CLK),.E(icg_E));

    s12_s1pram64x32 U_s12_s1pram64x32(
      .CLK(CLK_w),
      .ME(~CEB),
      .WE(~WEB),
	  .WEM(~bitmask),
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
	tsmc_t22hpcp_hvt_uhd_s1p64x32e lb_ram_s1p64x32 (
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

