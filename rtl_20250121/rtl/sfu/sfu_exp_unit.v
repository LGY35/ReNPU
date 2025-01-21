module sfu_exp_unit(
	clk,
	rst_n,
	lnF_en,
	lnF_in,
	lnF_in_Q,
	d_in,
	d_in_Q,
	data_in,
	data_in_Q,
	valid_in,
	data_out,
	data_out_Q,
	valid_out
);

parameter IN_W = 16;
parameter LNF_W = 16;
parameter TMP1_W = 16;
parameter TMP2_W = 16;
parameter TMP3_W = 16;
parameter D_W = 16;
parameter OUT_W = 16;

input 				clk;
input 				rst_n;
input				lnF_en;	//second time need -lnF
input  [LNF_W-1:0]	lnF_in;
input  [4:0]		lnF_in_Q;
input  [D_W-1:0]	d_in;  //first time use d1, second time use d2
input  [4:0]		d_in_Q;
input  [IN_W-1:0]	data_in;
input  [4:0]		data_in_Q;
input				valid_in;
output [OUT_W-1:0]	data_out;
output [4:0]		data_out_Q;
output				valid_out;

reg  [4:0]		tmp1_Q;
reg  [4:0]		tmp2_Q;
reg  [4:0]		tmp3_Q;

reg  [TMP1_W-1:0]	tmp1;	//data_in + lnF
reg  [TMP2_W-1:0]	tmp2;	//tmp1 * log2e
wire [TMP2_W-1:0]	tmp2_u;	//int part
wire [TMP2_W-1:0]	tmp2_v;	//mantissa part
reg  [TMP3_W-1:0]	tmp3;	//v+d
wire [TMP1_W-1:0]	tmp1_lnF;
wire [4:0]			tmp1_lnF_Q;
reg  [TMP2_W-1:0]	tmp2_u_d;

reg	[2:0] valid;

always@(posedge clk or negedge rst_n) begin
	if (~rst_n) 
		valid <= 'b0;
	else
		valid <= {valid[1:0],valid_in};
end

assign tmp1_lnF = (data_in_Q > lnF_in_Q) ? (data_in + ~(lnF_in<<(data_in_Q - lnF_in_Q)) + 1) : (data_in<<(lnF_in_Q - data_in_Q) + ~lnF_in + 1);
assign tmp1_lnF_Q = (data_in_Q > lnF_in_Q) ? data_in_Q : lnF_in_Q;

always@(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		tmp1 <= 'b0;
		tmp1_Q <= 'b0;
	end else if (valid_in) begin
		tmp1 <= lnF_en ? tmp1_lnF : {{(TMP1_W-IN_W){data_in[IN_W-1]}},data_in};
		tmp1_Q <= lnF_en ? tmp1_lnF_Q : data_in_Q;
	end
end

always@(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		tmp2 <= 'b0;
		tmp2_Q <= 'b0;
	end
	else if (valid[0]) begin
		tmp2 <= tmp1 + tmp1>>1 + ~(tmp1>>4) + 1; //tmp1*1.0111
		tmp2_Q <= tmp1_Q;
	end
end

assign tmp2_u = tmp2 >>> tmp2_Q; //int part
assign tmp2_v = (tmp2 << (TMP2_W - tmp2_Q)) >> (TMP2_W - tmp2_Q); //mantissa


always@(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		tmp3 <= 'b0;
		tmp3_Q <= 'b0;
		tmp2_u_d <= 'b0;
	end
	else if (valid[1]) begin
		tmp3 <= (d_in_Q > tmp2_Q) ? (d_in + tmp2_v<<(d_in_Q - tmp2_Q)) : (d_in<<(tmp2_Q - d_in_Q) + tmp2_v);
		tmp3_Q <= (d_in_Q > tmp2_Q) ? d_in_Q : tmp2_Q;
		tmp2_u_d <= tmp2_u;
	end
end

assign data_out = tmp3;
assign data_out_Q = tmp3_Q + tmp2_u_d;
assign valid_out = valid[2];

endmodule

