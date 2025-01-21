module sram512x32
 #(
parameter   MEM_DATA_WIDTH = 32,
parameter   MEM_ADDR_WIDTH = 9,
parameter   MEM_DATA_MASKB = 4
)(
input                       clk,           //CLK
input                       rst_n,
input                       we,            //WEB
input                       ce,            //CEB
input   [MEM_DATA_MASKB-1:0]bit_mask_in,   //BWEB
input   [MEM_ADDR_WIDTH-1:0]addr,          //A
input   [MEM_DATA_WIDTH-1:0]data_in,       //D
output  [MEM_DATA_WIDTH-1:0]data_out       //Q
);

//    wire clk_w;
    wire[MEM_DATA_WIDTH-1:0]    sram_bit_mask;
	
//    wire icg_E;
//	assign icg_E = ce;
//	icg ram_icg(.Q(clk_w),.TE(1'b0),.CP(clk),.E(icg_E));

    genvar i;

    generate
        for(i=0 ; i<MEM_DATA_WIDTH/4 ; i=i+1) begin
            assign #1 sram_bit_mask[i*4 +: 4] = {4{bit_mask_in[i]}};
        end
    endgenerate

tsmc_t28hpcp_hvt_uhd_s1p512x32e
instr_mem_tsmc_t28hpcp_hvt_uhd_s1p512x32e //TODO
(
.CLK    (clk            ),
.CEB    (~ce            ),
.WEB    (~we            ),
.A      (addr           ),
.D      (data_in        ),
.BWEB   (~sram_bit_mask ),
.RTSEL  (2'b10          ),
.WTSEL  (2'b00          ),
.Q      (data_out       )
);

endmodule
