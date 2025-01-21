module t22_s1pram64x32_wrapper (
    CLK,
    CEB,
    WEB,
    A,
    D,
    Q
);

parameter	MEM_ADDR_WIDTH =  6;
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
	reg [31:0] sram_sim [63:0];

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
	icg ram_icg(.Q(CLK_w),.TE(1'b0),.CP(CLK),.E(icg_E));

	tsmc_t22hpcp_hvt_uhd_s1p64x32 U_tsmc_t22hpcp_hvt_uhd_s1p64x32(
	.CLK(CLK_w),
	.CEB(CEB),
	.WEB(WEB),
	.A(A),
	.D(D),
	.Q(Q),
	.RTSEL(2'b10),
	.WTSEL(2'b00)
    );
`endif


endmodule
