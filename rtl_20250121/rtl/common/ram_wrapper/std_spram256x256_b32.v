module std_spram256x256_b32 (
	CLK,
	CEB0,
	CEB1,
	WEB,
	A0,
	A1,
	D,
	Q,
	BWEB
);
 parameter MAX_ADDR	= 255;
 parameter MEM_ADDR_WIDTH = 8; 
 parameter MEM_DATA_WIDTH = 256;
 parameter BITMASK_WIDTH = 32;

 input 				CLK;
 input 				CEB0;
 input 				CEB1;
 input 				WEB;
 input	[MEM_ADDR_WIDTH-1:0]	A0;
 input	[MEM_ADDR_WIDTH-1:0]	A1;
 input	[MEM_DATA_WIDTH-1:0]	D;
 output	[MEM_DATA_WIDTH-1:0]	Q;
 input	[BITMASK_WIDTH-1:0]	BWEB;
 
 std_spram256x128_b16 U_std_spram256x128_b16_bank0(
	.CLK (CLK ),
	.CEB (CEB0 ),
	.WEB (WEB ),
	.A   (A0   ),
	.D   (D[MEM_DATA_WIDTH/2-1:0]   ),
	.Q   (Q[MEM_DATA_WIDTH/2-1:0]   ),
	.BWEB(BWEB[BITMASK_WIDTH/2-1:0] )
);

std_spram256x128_b16 U_std_spram256x128_b16_bank1(
	.CLK    (CLK),
	.CEB    (CEB1),
	.WEB    (WEB),
	.A      (A1),
	.D      (D[MEM_DATA_WIDTH/2+:MEM_DATA_WIDTH/2]),
	.Q      (Q[MEM_DATA_WIDTH/2+:MEM_DATA_WIDTH/2]),
	.BWEB   (BWEB[BITMASK_WIDTH/2+:BITMASK_WIDTH/2] )
);

endmodule

