module clk_mode_sw(
input   rstn,
input   i_clk_ref,
input   intcore_clk_sw_enable,
input   intcore_clk_mode,
output  o_clk_sw
);

wire    intcore_sw_icg_clk;
wire    intcore_sw_icg_clk_inv;

reg [1:0] clk_en_sync;
wire    intcore_clk_sw_enable_w;


always@(posedge i_clk_ref or negedge rstn) begin
    if(!rstn)
        clk_en_sync <= 2'b11;
    else begin
        clk_en_sync[0] <= intcore_clk_sw_enable;
        clk_en_sync[1] <= clk_en_sync[0];
    end
end

assign intcore_clk_sw_enable_w = clk_en_sync[1];


`ifdef FPGA
	assign o_clk_sw=i_clk_ref;
`elsif SIM_CLK
    assign intcore_sw_icg_clk = intcore_clk_sw_enable_w ? i_clk_ref : 1'b0;

    assign intcore_sw_icg_clk_inv = ~intcore_sw_icg_clk;
    assign o_clk_sw = intcore_clk_mode ? intcore_sw_icg_clk_inv : intcore_sw_icg_clk;
`else 
    icg U_INTCORE_SW_ICG(.TE(1'b0),.E(intcore_clk_sw_enable_w),.CP(i_clk_ref),.Q(intcore_sw_icg_clk));
    clk_inv U_intcore_sw_clk_inv(.ZN(intcore_sw_icg_clk_inv) , .I(intcore_sw_icg_clk));
    clk_mux U_intcore_sw_clk_mux(.Z(o_clk_sw), .I1(intcore_sw_icg_clk_inv), .I0(intcore_sw_icg_clk), .S(intcore_clk_mode));
`endif



endmodule
