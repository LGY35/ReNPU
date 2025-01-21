module pe_accu(
    clk,
    rst_n,
    accu_in_data,
    accu_in_valid,
    //accu_in_fixed_Q,
	accu_out_data_0,
	accu_out_data_1,
	accu_out_data_2,
	accu_out_data_3,
	accu_out_valid,
	//accu_ram_in_0;
	//accu_ram_in_1;
	//accu_ram_out_0;
	//accu_ram_out_1;
	mac_cfg_conv_mode,
	mac_cfg_preci,
	mac_cfg_is_sparse,
	mac_cfg_is_fp,
	mac_ctrl_accu_ori,
	mac_ctrl_first_ori,
	mac_ctrl_last_ori,
	mac_ctrl_read
);

input				clk;
input				rst_n;
input	[128-1:0]	accu_in_data;		//8taps,8*16bit
//input   [6-1:0]     accu_in_fixed_Q;	//E_fmap+E_weight
input				accu_in_valid;
output	[32-1:0]	accu_out_data_0;		//output to cram, DW and conv share
output	[32-1:0]	accu_out_data_1;		//output to cram, only conv use
output	[32-1:0]	accu_out_data_2;		//output to cram, only RGB use
output	[32-1:0]	accu_out_data_3;		//output to cram, only RGB use
output				accu_out_valid;
//input	[40-1:0]	accu_ram_in_0,accu_ram_in_1;
//output	[40-1:0]	accu_ram_out_0,accu_ram_out_1;
input	[1:0]		mac_cfg_conv_mode;	//| 00:fc        | 01:conv       | 10:DWconv      | 11:RGB         |
input	[1:0]		mac_cfg_preci;		//| 00:int8xint4 | 01:int8xint8  | 10:int16xint8  | 11:int16xint16 |
input				mac_cfg_is_sparse;	//| 00:dense     | 01:sparse     |                |                |
input				mac_cfg_is_fp;		//| 00:int       | 01:fp         |                |                |
input				mac_ctrl_accu_ori;
input				mac_ctrl_first_ori;
input				mac_ctrl_last_ori;
input				mac_ctrl_read;

reg		[32-1:0]	accu_out_data_0;
reg		[32-1:0]	accu_out_data_1;
reg		[32-1:0]	accu_out_data_2;
reg		[32-1:0]	accu_out_data_3;
reg					accu_out_valid;

wire    [20-1:0]    accu_partial_sum0A,accu_partial_sum1A,accu_partial_sum2A,accu_partial_sum3A;
wire    [16-1:0]    accu_partial_sum0B,accu_partial_sum1B,accu_partial_sum2B,accu_partial_sum3B;
wire	[3-1:0]		accu_mode;
wire	[32-1:0]	adder1_h,adder1_l,adder2_h,adder2_l;
wire	[32-1:0]	adder1_dst,adder2_dst,adder3_h,adder3_l;
//wire	[48-1:0]	adder3_dst;
wire				is_shift1,is_shift2;

reg     [128-1:0]   accu_in_reg_d1;
reg                 accu_in_valid_d1;
//reg     [6-1:0]     accu_in_fixed_Q_d1;
reg     [20-1:0]    accu_partial_sum0,accu_partial_sum1,accu_partial_sum2,accu_partial_sum3;  //d2
reg                 accu_partial_sum_valid;  //d2
//reg     [6-1:0]     accu_in_fixed_Q_d2;
reg		[32-1:0]	accu_reg0,accu_reg1,accu_reg2,accu_reg3;
//reg		[32-1:0]	accu_adder1_lvl1_reg;	//d3
//reg		[32-1:0]	accu_adder2_lvl1_reg;	//d3
//reg					accu_adder_lvl1_valid;	//d3
//reg		[48-1:0]	accu_adder3_lvl2_reg;	//d4
//reg					accu_adder_lvl2_valid;	//d4

reg					mac_ctrl_accu_ori_d1;
reg					mac_ctrl_first_ori_d1;
reg					mac_ctrl_last_ori_d1;
reg					mac_ctrl_accu_ori_d2;
reg					mac_ctrl_first_ori_d2;
reg					mac_ctrl_last_ori_d2;
reg					mac_ctrl_accu_ori_d3;
reg					mac_ctrl_first_ori_d3;
reg					mac_ctrl_last_ori_d3;
reg					mac_ctrl_accu;
reg					mac_ctrl_first;
reg					mac_ctrl_last;

reg					mac_ctrl_last_r1;
reg					mac_ctrl_last_r2;
reg					mac_ctrl_last_r3;
reg					mac_ctrl_last_r4;
reg					mac_ctrl_read_r1;
reg		[32-1:0]	out1_r1; //output pipe regs for DW
reg		[32-1:0]	out2_r1;
reg		[32-1:0]	out2_r2;
reg		[32-1:0]	out3_r1;
reg		[32-1:0]	out3_r2;
reg		[32-1:0]	out3_r3;

//=========================================================
// input reg d1
//=========================================================
always@(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		accu_in_reg_d1 <= 128'b0;
		accu_in_valid_d1 <= 1'b0;
	end
	else if (accu_in_valid) begin //accu_in valid
		accu_in_reg_d1 <= accu_in_data;
		accu_in_valid_d1 <= 1'b1;
	end
	else begin
		accu_in_reg_d1 <= accu_in_reg_d1;
		accu_in_valid_d1 <= 1'b0;
	end
end
/*
always@(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		accu_in_fixed_Q_d1 <= 6'b0;
	end
	else if (accu_in_valid) begin
		accu_in_fixed_Q_d1 <= accu_in_fixed_Q;
	end
	else begin
		accu_in_fixed_Q_d1 <= accu_in_fixed_Q_d1;
	end
end
*/

//=========================================================
// int8x4 to int8x8 d2
//=========================================================
assign accu_partial_sum0A = (mac_cfg_preci==2'b00) ? {{4{accu_in_reg_d1[79]}},accu_in_reg_d1[79:64]} 
                            : accu_in_reg_d1[79:64]<<4;
assign accu_partial_sum1A = (mac_cfg_preci==2'b00) ? {{4{accu_in_reg_d1[95]}},accu_in_reg_d1[95:80]} 
                            : accu_in_reg_d1[95:80]<<4;
assign accu_partial_sum2A = (mac_cfg_preci==2'b00) ? {{4{accu_in_reg_d1[111]}},accu_in_reg_d1[111:96]} 
                            : accu_in_reg_d1[111:96]<<4;
assign accu_partial_sum3A = (mac_cfg_preci==2'b00) ? {{4{accu_in_reg_d1[127]}},accu_in_reg_d1[127:112]} 
                            : accu_in_reg_d1[127:112]<<4;
assign accu_partial_sum0B = accu_in_reg_d1[15:0];
assign accu_partial_sum1B = accu_in_reg_d1[31:16];
assign accu_partial_sum2B = accu_in_reg_d1[47:32];
assign accu_partial_sum3B = accu_in_reg_d1[63:48];

always@(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		accu_partial_sum0 <= 20'b0;
		accu_partial_sum1 <= 20'b0;
		accu_partial_sum2 <= 20'b0;
		accu_partial_sum3 <= 20'b0;
		accu_partial_sum_valid <= 1'b0;
    end
    else if (accu_in_valid_d1) begin
		accu_partial_sum0 <= $signed(accu_partial_sum0A) + $signed(accu_partial_sum0B);
		accu_partial_sum1 <= $signed(accu_partial_sum1A) + $signed(accu_partial_sum1B);
		accu_partial_sum2 <= $signed(accu_partial_sum2A) + $signed(accu_partial_sum2B);
		accu_partial_sum3 <= $signed(accu_partial_sum3A) + $signed(accu_partial_sum3B);
		accu_partial_sum_valid <= 1'b1;
    end
    else begin
        accu_partial_sum0 <= accu_partial_sum0;
        accu_partial_sum1 <= accu_partial_sum1;
        accu_partial_sum2 <= accu_partial_sum2;
        accu_partial_sum3 <= accu_partial_sum3;
		accu_partial_sum_valid <= 1'b0;
    end
end
/*
always@(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		accu_in_fixed_Q_d2 <= 6'b0;
	end
	else if (accu_in_valid_d1) begin
		accu_in_fixed_Q_d2 <= accu_in_fixed_Q_d1;
	end
	else begin
		accu_in_fixed_Q_d2 <= accu_in_fixed_Q_d2;
	end
end
*/

//=========================================================
// pipe regs for mac_ctrl signals
//=========================================================
always@(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		mac_ctrl_accu_ori_d1 <= 1'b0;
		mac_ctrl_accu_ori_d2 <= 1'b0;
		mac_ctrl_accu_ori_d3 <= 1'b0;
		mac_ctrl_accu <= 1'b0;
	end
	else begin
		mac_ctrl_accu_ori_d1 <= mac_ctrl_accu_ori;
		mac_ctrl_accu_ori_d2 <= mac_ctrl_accu_ori_d1;
		mac_ctrl_accu_ori_d3 <= mac_ctrl_accu_ori_d2;
		mac_ctrl_accu <= mac_ctrl_accu_ori_d3;
	end
end
always@(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		mac_ctrl_first_ori_d1 <= 1'b0;
		mac_ctrl_first_ori_d2 <= 1'b0;
		mac_ctrl_first_ori_d3 <= 1'b0;
		mac_ctrl_first <= 1'b0;
	end
	else begin
		mac_ctrl_first_ori_d1 <= mac_ctrl_first_ori;
		mac_ctrl_first_ori_d2 <= mac_ctrl_first_ori_d1;
		mac_ctrl_first_ori_d3 <= mac_ctrl_first_ori_d2;
		mac_ctrl_first <= mac_ctrl_first_ori_d3;
	end
end
always@(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		mac_ctrl_last_ori_d1 <= 1'b0;
		mac_ctrl_last_ori_d2 <= 1'b0;
		mac_ctrl_last_ori_d3 <= 1'b0;
		mac_ctrl_last <= 1'b0;
	end
	else begin
		mac_ctrl_last_ori_d1 <= mac_ctrl_last_ori;
		mac_ctrl_last_ori_d2 <= mac_ctrl_last_ori_d1;
		mac_ctrl_last_ori_d3 <= mac_ctrl_last_ori_d2;
		mac_ctrl_last <= mac_ctrl_last_ori_d3;
	end
end

//=========================================================
// accu mode
//=========================================================
assign accu_mode[0] = ((mac_cfg_conv_mode==2'b00)||(mac_cfg_conv_mode==2'b10))&&(!mac_cfg_is_fp); //DW/fc and INT, using accu regs
assign accu_mode[1] = (mac_cfg_conv_mode==2'b01)&&(!mac_cfg_is_fp); //normal conv and INT, using accu RAM
assign accu_mode[2] = mac_cfg_is_fp; //t22 not use

//=========================================================
// register accumulator
//=========================================================
always@(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		accu_reg0 <= 32'b0;
		accu_reg1 <= 32'b0;
		accu_reg2 <= 32'b0;
		accu_reg3 <= 32'b0;
	end
	else if (mac_ctrl_first&&accu_mode[0]&&accu_partial_sum_valid) begin
		accu_reg0 <= {{12{accu_partial_sum0[19]}},accu_partial_sum0};
		accu_reg1 <= {{12{accu_partial_sum1[19]}},accu_partial_sum1};
		accu_reg2 <= {{12{accu_partial_sum2[19]}},accu_partial_sum2};
		accu_reg3 <= {{12{accu_partial_sum3[19]}},accu_partial_sum3};
	end
	else if (mac_ctrl_accu&&accu_mode[0]&&accu_partial_sum_valid) begin
		accu_reg0 <= $signed(accu_reg0) + $signed(accu_partial_sum0);
		accu_reg1 <= $signed(accu_reg1) + $signed(accu_partial_sum1);
		accu_reg2 <= $signed(accu_reg2) + $signed(accu_partial_sum2);
		accu_reg3 <= $signed(accu_reg3) + $signed(accu_partial_sum3);
	end
	else begin
		accu_reg0 <= accu_reg0;
		accu_reg1 <= accu_reg1;
		accu_reg2 <= accu_reg2;
		accu_reg3 <= accu_reg3;
	end
end

//=========================================================
// conbination adder
//=========================================================
assign adder1_h = accu_mode[0]?accu_reg0:((accu_mode[1]||accu_mode[2]) ? {{12{accu_partial_sum0[19]}},accu_partial_sum0} : 32'd0);
assign adder1_l = accu_mode[0]?accu_reg1:((accu_mode[1]||accu_mode[2]) ? {{12{accu_partial_sum1[19]}},accu_partial_sum1} : 32'd0);
assign adder2_h = accu_mode[0]?accu_reg2:((accu_mode[1]||accu_mode[2]) ? {{12{accu_partial_sum2[19]}},accu_partial_sum2} : 32'd0);
assign adder2_l = accu_mode[0]?accu_reg3:((accu_mode[1]||accu_mode[2]) ? {{12{accu_partial_sum3[19]}},accu_partial_sum3} : 32'd0);
//assign adder3_h = accu_mode[0]?accu_adder2_lvl1_reg : 40'b0; //adder2 is high mul
//assign adder3_l = accu_mode[0]?accu_adder1_lvl1_reg : 40'b0;
assign is_shift1 = mac_cfg_preci[1]; //int16x8 or int16x16
assign is_shift2 = mac_cfg_preci == 2'b11; //only int16x16

//lvl 1
pe_adder_shift #(
	.DATA_WIDTH(32),
	.RSLT_WIDTH(32),
	.SHIFT_AMOUNT(8)
) U_accu_adder1(
	.src_h(adder1_h),
	.src_l(adder1_l),
	.dst(adder1_dst),
	.is_shift(is_shift1)
);

pe_adder_shift #(
	.DATA_WIDTH(32),
	.RSLT_WIDTH(32),
	.SHIFT_AMOUNT(8)
) U_accu_adder2(
	.src_h(adder2_h),
	.src_l(adder2_l),
	.dst(adder2_dst),
	.is_shift(is_shift1)
);
/*
//d3 reg
always@(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		accu_adder1_lvl1_reg <= 40'b0;
		accu_adder2_lvl1_reg <= 40'b0;
		accu_adder_lvl1_valid <= 1'b0;
	end
	else if (accu_mode[0] ? mac_ctrl_last : ((accu_mode[1]||accu_mode[2]) ? accu_partial_sum_valid : 0)) begin
		accu_adder1_lvl1_reg <= adder1_dst;
		accu_adder2_lvl1_reg <= adder2_dst;
		accu_adder_lvl1_valid <= 1'b1;
	end
	else begin
		accu_adder1_lvl1_reg <= accu_adder1_lvl1_reg;
		accu_adder2_lvl1_reg <= accu_adder2_lvl1_reg;
		accu_adder_lvl1_valid <= accu_adder_lvl1_valid;
	end
end


//lvl 2
pe_adder_shift #(
	.DATA_WIDTH(40),
	.RSTL_WIDTH(48),
	.SHIFT_AMOUNT(8)
) U_accu_adder3(
	.src_h(adder3_h),
	.src_l(adder3_l),
	.dst(adder3_dst),
	.is_shift(is_shift2)
);

//d4 reg
always@(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		accu_adder3_lvl2_reg <= 40'b0;
		accu_adder_lvl2_valid <= 1'b0;
	end
	else if (accu_adder_lvl1_valid) begin
		accu_adder3_lvl2_reg <= adder3_dst;
		accu_adder_lvl2_valid <= 1'b1;
	end
	else begin
		accu_adder3_lvl2_reg <= accu_adder3_lvl2_reg;
		accu_adder_lvl2_valid <= accu_adder_lvl2_valid;
	end
end
*/

//=========================================================
// output data pipe
//=========================================================
//ctrl
always@(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		mac_ctrl_last_r1 <= 0;
		mac_ctrl_last_r2 <= 0;
		mac_ctrl_last_r3 <= 0;
		mac_ctrl_last_r4 <= 0;
		mac_ctrl_read_r1 <= 0;
	end
	else begin
		mac_ctrl_last_r1 <= mac_ctrl_last;
		mac_ctrl_last_r2 <= mac_ctrl_last_r1;
		mac_ctrl_last_r3 <= mac_ctrl_last_r2;
		mac_ctrl_last_r4 <= mac_ctrl_last_r3;
		mac_ctrl_read_r1 <= mac_ctrl_read;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		out1_r1 <= 32'b0;
		out2_r1 <= 32'b0;
		out2_r2 <= 32'b0;
		out3_r1 <= 32'b0;
		out3_r2 <= 32'b0;
		out3_r3 <= 32'b0;
	end
	else begin
		out1_r1 <= (mac_cfg_preci == 2'b01) ? accu_reg1 : ((mac_cfg_preci == 2'b10) ? adder2_dst : 'b0);
		out2_r1 <= (mac_cfg_preci == 2'b01) ? accu_reg2 : 'b0;
		out2_r2 <= out2_r1;
		out3_r1 <= (mac_cfg_preci == 2'b01) ? accu_reg3 : 'b0;
		out3_r2 <= out3_r1;
		out3_r3 <= out3_r2;
	end
end

//=========================================================
// output select
//=========================================================
always@(*) begin
	// DW 8x8
	if (accu_mode[0]&&(mac_cfg_preci == 2'b01)) begin
		accu_out_data_0 = mac_ctrl_last_r1 ? accu_reg0 : (mac_ctrl_last_r2 ? out1_r1 : (mac_ctrl_last_r3 ? out2_r2 : (mac_ctrl_last_r4 ? out3_r3 : 32'b0)));
		accu_out_valid = mac_ctrl_last_r4 || mac_ctrl_last_r1 || mac_ctrl_last_r2 || mac_ctrl_last_r3;
	end
	// DW 16x8 or 16x16
	else if (accu_mode[0]&&mac_cfg_preci[1]) begin
		accu_out_data_0 = mac_ctrl_last ? adder1_dst : (mac_ctrl_last_r1 ? out1_r1 : 32'b0);
		accu_out_valid = mac_ctrl_last || mac_ctrl_last_r1;
		//accu_out_data = mac_ctrl_last_r1?adder1_dst:(mac_ctrl_last_r2?adder2_dst:48'b0);
	end
	/*
	// DW 16x16
	else if (accu_mode[0]&&(mac_cfg_preci == 2'b11)) begin
		accu_out_data = mac_ctrl_last_r1?adder3_dst:48'b0);
	end
	*/
	// fc 8x4 dense
	else if (accu_mode[0]&&(mac_cfg_preci == 2'b00)) begin
		accu_out_data_0 = mac_ctrl_read ? adder1_dst : (mac_ctrl_read_r1 ? out1_r1 : 32'b0);
		accu_out_valid = mac_ctrl_read || mac_ctrl_read_r1;
	end
	// conv mode (all preci same)
	else if (accu_mode[1]) begin
		accu_out_data_0 = adder1_dst;
		accu_out_valid = accu_partial_sum_valid;
	end
	// RGB mode
	else if (mac_cfg_conv_mode==2'b11) begin
		accu_out_data_0 = {{12{accu_partial_sum0[19]}},accu_partial_sum0};
		accu_out_valid = accu_partial_sum_valid;
	end
	else begin
		accu_out_data_0 = 32'b0;
		accu_out_valid = 1'b0;
	end
end

always@(*) begin
	if (accu_mode[1]) begin
		accu_out_data_1 = adder2_dst;
	end
	else if (mac_cfg_conv_mode==2'b11) begin
		accu_out_data_1 = {{12{accu_partial_sum1[19]}},accu_partial_sum1};
	end 
	else begin
		accu_out_data_1 = 32'b0;
	end
end

always@(*) begin
	if (mac_cfg_conv_mode==2'b11) begin
		accu_out_data_2 = {{12{accu_partial_sum2[19]}},accu_partial_sum2};
		accu_out_data_3 = {{12{accu_partial_sum3[19]}},accu_partial_sum3};
	end 
	else begin
		accu_out_data_2 = 32'b0;
		accu_out_data_3 = 32'b0;
	end
end
endmodule



