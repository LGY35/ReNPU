module pe_mac_array(
	clk,
	rst_n,
	fmap_data,
	fmap_data_valid,
	weight_data,
	weight_data_valid,
	mac_out_data,
	mac_out_valid,
	mac_cfg_is_uint,
	mac_cfg_conv_mode,
	mac_cfg_preci
//	mac_cfg_de_or_sp
);

input				clk;
input				rst_n;
input	[160-1:0]	fmap_data;			//20*int8
input				fmap_data_valid;
input	[160-1:0]	weight_data;		//20*int8
input				weight_data_valid;
output	[128-1:0]	mac_out_data;		//8taps,8*16bit
output				mac_out_valid;
input	[1:0]		mac_cfg_conv_mode;	//| 00:fc        | 01:conv       | 10:DWconv      | 11:RGB         |
input	[1:0]		mac_cfg_preci;		//| 00:int8xint4 | 01:int8xint8  | 10:int16xint8  | 11:int16xint16 |
input	    		mac_cfg_is_uint;	//| 00:signed    | 01:usigned    |                |                |

wire	[320-1:0]	mul_fmap;			//40pe*int8
wire	[160-1:0]	mul_weight_ori;		//40pe*int4
wire	[200-1:0]	mul_weight_fc;		//int5(expanded)
wire	[200-1:0]	mul_weight_other;	//int5(expanded)
wire	[200-1:0]	mul_weight;			//int5(expanded)

wire	[360-1:0]	mul_fmap_s;			//int9
wire	[200-1:0]	mul_weight_s;		//int5
wire	[13-1:0]	mul_dst_out [40-1:0];
wire	[16-1:0]	adder_dst_out [8-1:0];

reg		[160-1:0]	fmap_reg_d1;
reg					fmap_valid_d1;
reg		[160-1:0]	weight_reg_d1;
reg					weight_valid_d1;
reg		[13-1:0]	mul_reg_d2 [40-1:0];
reg					mul_valid_d2;

//=========================================================
// input reg d1
//=========================================================
always@(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		fmap_reg_d1 <= 128'b0;
		fmap_valid_d1 <= 1'b0;
	end
	else if (fmap_data_valid) begin //fmap valid
		fmap_reg_d1 <= fmap_data;
		fmap_valid_d1 <= 1'b1;
	end
	else begin
		fmap_reg_d1 <= fmap_reg_d1;
		fmap_valid_d1 <= 1'b0;
	end
end

always@(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		weight_reg_d1 <= 128'b0;
		weight_valid_d1 <= 1'b0;
	end
	else if (weight_data_valid) begin //weight valid supposed to be the same as fmap
		weight_reg_d1 <= weight_data;
		weight_valid_d1 <= 1'b1;
	end
	else begin
		weight_reg_d1 <= weight_reg_d1;
		weight_valid_d1 <= 1'b0;
	end
end

//=========================================================
// 40int8xint4 muls d2
//=========================================================
assign mul_fmap = {fmap_reg_d1, fmap_reg_d1};
assign mul_weight_ori = weight_reg_d1;
genvar j;

//low0-4
generate
	for (j = 4; j >= 0; j = j-1) begin:pe_mul_8x4_low_0_4
		assign mul_weight_fc[j*5+:5] = {mul_weight_ori[j*4+3], mul_weight_ori[j*4+:4]}; //fc mode original int4, expand signal bit
		assign mul_weight_other[j*5+:5] = {1'b0, mul_weight_ori[j*8+:4]}; //otherwise, seperate int8 into 2 int4, low 4bit expand 0
		assign mul_weight[j*5+:5] = (mac_cfg_conv_mode == 2'b00) ? mul_weight_fc : mul_weight_other[j*5+:5];
		//uint expand 0 signal bit
		assign mul_fmap_s[j*9+:9] = mac_cfg_is_uint ? {1'b0,mul_fmap[j*8+:8]} : {mul_fmap[j*8+7],mul_fmap[j*8+:8]};
		assign mul_weight_s[j*5+:5] = mac_cfg_is_uint ? {1'b0,mul_weight[j*5+:4]} : mul_weight[j*5+:5];
		pe_mul #(
			.DATA_A_WIDTH(9),
			.DATA_B_WIDTH(5),
			.RSLT_WIDTH(13)
		) U_pe_mul_8x4(
			.src_a	(mul_fmap_s[j*9+:9]	),
			.src_b	(mul_weight_s[j*5+:5]	),
			.dst	(mul_dst_out[j]		)
		);
		always@(posedge clk or negedge rst_n) begin
			if(~rst_n) begin
				mul_reg_d2[j] <= 13'b0;

			end
			else if (fmap_valid_d1) begin
				mul_reg_d2[j] <= mul_dst_out[j]; //valid pass

			end
			else begin
				mul_reg_d2[j] <= mul_reg_d2[j];

			end
		end
	end
endgenerate

//low5-9
generate
	for (j = 9; j >= 5; j = j-1) begin:pe_mul_8x4_low_5_9
		assign mul_weight_fc[j*5+:5] = {mul_weight_ori[j*4+3], mul_weight_ori[j*4+:4]}; //fc mode original int4, expand signal bit
		assign mul_weight_other[j*5+:5] = {1'b0, mul_weight_ori[j*8+:4]}; //otherwise, seperate int8 into 2 int4, low 4bit expand 0
		assign mul_weight[j*5+:5] = (mac_cfg_conv_mode == 2'b00) ? mul_weight_fc : mul_weight_other[j*5+:5];
		//uint expand 0 signal bit
		assign mul_fmap_s[j*9+:9] = (mac_cfg_is_uint||mac_cfg_preci[1]) ? {1'b0,mul_fmap[j*8+:8]} : {mul_fmap[j*8+7],mul_fmap[j*8+:8]};
		assign mul_weight_s[j*5+:5] = mac_cfg_is_uint ? {1'b0,mul_weight[j*5+:4]} : mul_weight[j*5+:5];
		pe_mul #(
			.DATA_A_WIDTH(9),
			.DATA_B_WIDTH(5),
			.RSLT_WIDTH(13)
		) U_pe_mul_8x4(
			.src_a	(mul_fmap_s[j*9+:9]	),
			.src_b	(mul_weight_s[j*5+:5]	),
			.dst	(mul_dst_out[j]		)
		);
		always@(posedge clk or negedge rst_n) begin
			if(~rst_n) begin
				mul_reg_d2[j] <= 13'b0;

			end
			else if (fmap_valid_d1) begin
				mul_reg_d2[j] <= mul_dst_out[j]; //valid pass

			end
			else begin
				mul_reg_d2[j] <= mul_reg_d2[j];

			end
		end
	end
endgenerate

//low10-14
generate
	for (j = 14; j >= 10; j = j-1) begin:pe_mul_8x4_low_10_14
		assign mul_weight_fc[j*5+:5] = {mul_weight_ori[j*4+3], mul_weight_ori[j*4+:4]}; //fc mode original int4, expand signal bit
		assign mul_weight_other[j*5+:5] = {1'b0, mul_weight_ori[j*8+:4]}; //otherwise, seperate int8 into 2 int4, low 4bit expand 0
		assign mul_weight[j*5+:5] = (mac_cfg_conv_mode == 2'b00) ? mul_weight_fc : mul_weight_other[j*5+:5];
		//uint expand 0 signal bit
		assign mul_fmap_s[j*9+:9] = mac_cfg_is_uint ? {1'b0,mul_fmap[j*8+:8]} : {mul_fmap[j*8+7],mul_fmap[j*8+:8]};
		assign mul_weight_s[j*5+:5] = (mac_cfg_is_uint||(mac_cfg_preci==2'b11)) ? {1'b0,mul_weight[j*5+:4]} : mul_weight[j*5+:5];
		pe_mul #(
			.DATA_A_WIDTH(9),
			.DATA_B_WIDTH(5),
			.RSLT_WIDTH(13)
		) U_pe_mul_8x4(
			.src_a	(mul_fmap_s[j*9+:9]	),
			.src_b	(mul_weight_s[j*5+:5]	),
			.dst	(mul_dst_out[j]		)
		);
		always@(posedge clk or negedge rst_n) begin
			if(~rst_n) begin
				mul_reg_d2[j] <= 13'b0;

			end
			else if (fmap_valid_d1) begin
				mul_reg_d2[j] <= mul_dst_out[j]; //valid pass

			end
			else begin
				mul_reg_d2[j] <= mul_reg_d2[j];

			end
		end
	end
endgenerate

//low15-19
generate
	for (j = 19; j >= 15; j = j-1) begin:pe_mul_8x4_low_15_19
		assign mul_weight_fc[j*5+:5] = {mul_weight_ori[j*4+3], mul_weight_ori[j*4+:4]}; //fc mode original int4, expand signal bit
		assign mul_weight_other[j*5+:5] = {1'b0, mul_weight_ori[j*8+:4]}; //otherwise, seperate int8 into 2 int4, low 4bit expand 0
		assign mul_weight[j*5+:5] = (mac_cfg_conv_mode == 2'b00) ? mul_weight_fc : mul_weight_other[j*5+:5];
		//uint expand 0 signal bit
		assign mul_fmap_s[j*9+:9] = (mac_cfg_is_uint||mac_cfg_preci[1]) ? {1'b0,mul_fmap[j*8+:8]} : {mul_fmap[j*8+7],mul_fmap[j*8+:8]};
		assign mul_weight_s[j*5+:5] = (mac_cfg_is_uint||(mac_cfg_preci==2'b11)) ? {1'b0,mul_weight[j*5+:4]} : mul_weight[j*5+:5];
		pe_mul #(
			.DATA_A_WIDTH(9),
			.DATA_B_WIDTH(5),
			.RSLT_WIDTH(13)
		) U_pe_mul_8x4(
			.src_a	(mul_fmap_s[j*9+:9]	),
			.src_b	(mul_weight_s[j*5+:5]	),
			.dst	(mul_dst_out[j]		)
		);
		always@(posedge clk or negedge rst_n) begin
			if(~rst_n) begin
				mul_reg_d2[j] <= 13'b0;

			end
			else if (fmap_valid_d1) begin
				mul_reg_d2[j] <= mul_dst_out[j]; //valid pass

			end
			else begin
				mul_reg_d2[j] <= mul_reg_d2[j];

			end
		end
	end
endgenerate

//high0-4
generate
	for (j = 24; j >= 20; j = j-1) begin:pe_mul_8x4_high_0_4
		assign mul_weight_fc[j*5+:5] = {mul_weight_ori[j*4+3], mul_weight_ori[j*4+:4]}; //fc mode original int4, expand signal bit
		assign mul_weight_other[j*5+:5] = {mul_weight_ori[(j-20)*8+7], mul_weight_ori[((j-20)*8+4)+:4]}; //high 4bit expand signal bit
		assign mul_weight[j*5+:5] = (mac_cfg_conv_mode == 2'b00) ? mul_weight_fc : mul_weight_other[j*5+:5];
		//uint expand 0 signal bit
		assign mul_fmap_s[j*9+:9] = mac_cfg_is_uint ? {1'b0,mul_fmap[j*8+:8]} : {mul_fmap[j*8+7],mul_fmap[j*8+:8]};
		assign mul_weight_s[j*5+:5] = mac_cfg_is_uint ? {1'b0,mul_weight[j*5+:4]} : mul_weight[j*5+:5];
		pe_mul #(
			.DATA_A_WIDTH(9),
			.DATA_B_WIDTH(5),
			.RSLT_WIDTH(13)
		) U_pe_mul_8x4(
			.src_a	(mul_fmap_s[j*9+:9]	),
			.src_b	(mul_weight_s[j*5+:5]	),
			.dst	(mul_dst_out[j]		)
		);
		always@(posedge clk or negedge rst_n) begin
			if(~rst_n) begin
				mul_reg_d2[j] <= 13'b0;

			end
			else if (fmap_valid_d1) begin
				mul_reg_d2[j] <= mul_dst_out[j]; //valid pass

			end
			else begin
				mul_reg_d2[j] <= mul_reg_d2[j];

			end
		end
	end
endgenerate

//high5-9
generate
	for (j = 29; j >= 25; j = j-1) begin:pe_mul_8x4_high_5_9
		assign mul_weight_fc[j*5+:5] = {mul_weight_ori[j*4+3], mul_weight_ori[j*4+:4]}; //fc mode original int4, expand signal bit
		assign mul_weight_other[j*5+:5] = {mul_weight_ori[(j-20)*8+7], mul_weight_ori[((j-20)*8+4)+:4]}; //high 4bit expand signal bit
		assign mul_weight[j*5+:5] = (mac_cfg_conv_mode == 2'b00) ? mul_weight_fc : mul_weight_other[j*5+:5];
		//uint or 16bit low bit expand 0 signal bit
		assign mul_fmap_s[j*9+:9] = (mac_cfg_is_uint||mac_cfg_preci[1]) ? {1'b0,mul_fmap[j*8+:8]} : {mul_fmap[j*8+7],mul_fmap[j*8+:8]};
		assign mul_weight_s[j*5+:5] = mac_cfg_is_uint ? {1'b0,mul_weight[j*5+:4]} : mul_weight[j*5+:5];
		pe_mul #(
			.DATA_A_WIDTH(9),
			.DATA_B_WIDTH(5),
			.RSLT_WIDTH(13)
		) U_pe_mul_8x4(
			.src_a	(mul_fmap_s[j*9+:9]	),
			.src_b	(mul_weight_s[j*5+:5]	),
			.dst	(mul_dst_out[j]		)
		);
		always@(posedge clk or negedge rst_n) begin
			if(~rst_n) begin
				mul_reg_d2[j] <= 13'b0;

			end
			else if (fmap_valid_d1) begin
				mul_reg_d2[j] <= mul_dst_out[j]; //valid pass

			end
			else begin
				mul_reg_d2[j] <= mul_reg_d2[j];

			end
		end
	end
endgenerate

//high10-14
generate
	for (j = 34; j >= 30; j = j-1) begin:pe_mul_8x4_high_10_14
		assign mul_weight_fc[j*5+:5] = {mul_weight_ori[j*4+3], mul_weight_ori[j*4+:4]}; //fc mode original int4, expand signal bit
		assign mul_weight_other[j*5+:5] = {mul_weight_ori[(j-20)*8+7], mul_weight_ori[((j-20)*8+4)+:4]}; //high 4bit expand signal bit
		assign mul_weight[j*5+:5] = (mac_cfg_conv_mode == 2'b00) ? mul_weight_fc : mul_weight_other[j*5+:5];
		//uint expand 0 signal bit
		assign mul_fmap_s[j*9+:9] = mac_cfg_is_uint ? {1'b0,mul_fmap[j*8+:8]} : {mul_fmap[j*8+7],mul_fmap[j*8+:8]};
		assign mul_weight_s[j*5+:5] = (mac_cfg_is_uint||(mac_cfg_preci==2'b11)) ? {1'b0,mul_weight[j*5+:4]} : mul_weight[j*5+:5];
		pe_mul #(
			.DATA_A_WIDTH(9),
			.DATA_B_WIDTH(5),
			.RSLT_WIDTH(13)
		) U_pe_mul_8x4(
			.src_a	(mul_fmap_s[j*9+:9]	),
			.src_b	(mul_weight_s[j*5+:5]	),
			.dst	(mul_dst_out[j]		)
		);
		always@(posedge clk or negedge rst_n) begin
			if(~rst_n) begin
				mul_reg_d2[j] <= 13'b0;

			end
			else if (fmap_valid_d1) begin
				mul_reg_d2[j] <= mul_dst_out[j]; //valid pass

			end
			else begin
				mul_reg_d2[j] <= mul_reg_d2[j];

			end
		end
	end
endgenerate

//high15-19
generate
	for (j = 39; j >= 35; j = j-1) begin:pe_mul_8x4_high_15_19
		assign mul_weight_fc[j*5+:5] = {mul_weight_ori[j*4+3], mul_weight_ori[j*4+:4]}; //fc mode original int4, expand signal bit
		assign mul_weight_other[j*5+:5] = {mul_weight_ori[(j-20)*8+7], mul_weight_ori[((j-20)*8+4)+:4]}; //high 4bit expand signal bit
		assign mul_weight[j*5+:5] = (mac_cfg_conv_mode == 2'b00) ? mul_weight_fc : mul_weight_other[j*5+:5];
		//uint expand 0 signal bit
		assign mul_fmap_s[j*9+:9] = (mac_cfg_is_uint||mac_cfg_preci[1]) ? {1'b0,mul_fmap[j*8+:8]} : {mul_fmap[j*8+7],mul_fmap[j*8+:8]};
		assign mul_weight_s[j*5+:5] = (mac_cfg_is_uint||(mac_cfg_preci==2'b11)) ? {1'b0,mul_weight[j*5+:4]} : mul_weight[j*5+:5];
		pe_mul #(
			.DATA_A_WIDTH(9),
			.DATA_B_WIDTH(5),
			.RSLT_WIDTH(13)
		) U_pe_mul_8x4(
			.src_a	(mul_fmap_s[j*9+:9]	),
			.src_b	(mul_weight_s[j*5+:5]	),
			.dst	(mul_dst_out[j]		)
		);
		always@(posedge clk or negedge rst_n) begin
			if(~rst_n) begin
				mul_reg_d2[j] <= 13'b0;

			end
			else if (fmap_valid_d1) begin
				mul_reg_d2[j] <= mul_dst_out[j]; //valid pass

			end
			else begin
				mul_reg_d2[j] <= mul_reg_d2[j];

			end
		end
	end
endgenerate

		always@(posedge clk or negedge rst_n) begin
			if(~rst_n) begin
				mul_valid_d2 <= 1'b0;

			end
			else if (fmap_valid_d1) begin
				mul_valid_d2 <= 1'b1; //valid pass

			end
			else begin
				mul_valid_d2 <= 1'b0;

			end
		end
//=========================================================
// adder tree
//=========================================================
generate
	for (j = 7; j >= 0; j = j-1) begin:pe_adder
		pe_adder #( 
			.DATA_WIDTH(13),
			.RSLT_WIDTH(16)
		) U_pe_adder(
			.src_a	(mul_reg_d2[j*5]	),
			.src_b	(mul_reg_d2[j*5+1]	),
			.src_c	(mul_reg_d2[j*5+2]	),
			.src_d	(mul_reg_d2[j*5+3]	),
			.src_e	(mul_reg_d2[j*5+4]	),
			.dst	(adder_dst_out[j]	)
		);
	end
endgenerate

//=========================================================
// output 8 taps
//=========================================================
assign mac_out_data = {	adder_dst_out[7],	//high mul
						adder_dst_out[6],
						adder_dst_out[5],
						adder_dst_out[4],
						adder_dst_out[3],
						adder_dst_out[2],
						adder_dst_out[1],
						adder_dst_out[0] };	//low mul

assign mac_out_valid = mul_valid_d2;	//pe module total delay 2 clk

endmodule

