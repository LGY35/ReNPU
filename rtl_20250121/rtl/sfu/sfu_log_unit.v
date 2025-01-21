module sfu_log_unit(
	clk,
	rst_n,
	data_in,
	data_in_Q,
	valid_in,
	data_out,
	data_out_Q,
	valid_out
);

parameter IN_W = 16;
parameter TMP1_W = 16;
parameter OUT_W = 16;

localparam addr_width = ((IN_W>65536)?((IN_W>16777216)?((IN_W>268435456)?((IN_W>536870912)?30:29):((IN_W>67108864)?((IN_W>134217728)?28:27):((IN_W>33554432)?26:25))):((IN_W>1048576)?((IN_W>4194304)?((IN_W>8388608)?24:23):((IN_W>2097152)?22:21)):((IN_W>262144)?((IN_W>524288)?20:19):((IN_W>131072)?18:17)))):((IN_W>256)?((IN_W>4096)?((IN_W>16384)?((IN_W>32768)?16:15):((IN_W>8192)?14:13)):((IN_W>1024)?((IN_W>2048)?12:11):((IN_W>512)?10:9))):((IN_W>16)?((IN_W>64)?((IN_W>128)?8:7):((IN_W>32)?6:5)):((IN_W>4)?((IN_W>8)?4:3):((IN_W>2)?2:1)))));

input 				clk;
input 				rst_n;
input  [IN_W-1:0]	data_in;
input  [4:0]		data_in_Q;
input				valid_in;
output [OUT_W-1:0]	data_out;
output [4:0]		data_out_Q;
output				valid_out;

reg  [4:0]		tmp1_Q;

reg  [TMP1_W-1:0]		tmp1;	//k-1+w
wire [addr_width:0]		w;
wire [IN_W-1:0] 		k;
wire [addr_width-1:0]	leading_zeros;

reg	[1:0] valid;
reg [OUT_W-1:0] data_out;
reg [4:0]	  data_out_Q;

always@(posedge clk or negedge rst_n) begin
	if (~rst_n) 
		valid <= 'b0;
	else
		valid <= {valid[0],valid_in};
end

assign w = IN_W - data_in_Q - 1 - leading_zeros;
assign k = w[addr_width] ? (data_in >> (~w+1)) : (data_in >> w);

always@(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		tmp1 <= 'b0;
		tmp1_Q <= 'b0;
	end else if (valid_in) begin
		tmp1 <= k - 1 + w<<(IN_W-1);
		tmp1_Q <= IN_W -1; //because k is 1.****
	end
end

always@(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		data_out <= 'b0;
		data_out_Q <= 'b0;
	end else if (valid[0]) begin
		data_out <= tmp1>>1 + tmp1>>3 + tmp1>>4; //tmp1*0.1011
		data_out_Q <= tmp1_Q;
	end
end

assign valid_out = valid[1];

DW_lzd  #(
	.a_width(IN_W)
)u_DW_lzd(
    .a	(data_in),
    .enc(leading_zeros),
    .dec()
);

endmodule

