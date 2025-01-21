//=========================================================
// module: fp_E_align_op_minmax
//=========================================================
module fp_E_align_op_minmax(
	clk,
	rst_n,
	min_or_max,
	cfg_mode,
	cflow_valid,
	instr_valid,
	minmax_data_in,
	minmax_data_out,
	minmax_index_out,
	minmax_data_out_valid
);

parameter width = 5;
parameter num_inputs = 5;
localparam index_width = ((num_inputs>8)?((num_inputs>32)? 6:((num_inputs>16)? 5:4)):((num_inputs>4)? 3:((num_inputs>2)? 2:1)));

input							clk;
input							rst_n;
input							min_or_max;		//0:min 1:max
input							cfg_mode;		//0:cflow 1:instr
input							cflow_valid;
input							instr_valid;
input  [num_inputs*width-1:0]	minmax_data_in;
output [width-1:0]				minmax_data_out;
output [index_width-1:0]		minmax_index_out;
output							minmax_data_out_valid;

reg							valid_reg;
reg [num_inputs*width-1:0]	minmax_data_in_reg;

function [width-1 : 0] max_unsigned_value;
  input [num_inputs*width-1 : 0] a;
  reg [width-1 : 0] a_v;
  reg [width-1 : 0] value_v;
  reg [index_width : 0] k;
  begin
  value_v = {width{1'b0}};
  for (k = 0; k < num_inputs; k = k+1) begin 
      a_v = a[width-1 : 0];
      a = a >> width;
      if (a_v >= value_v) begin 
          value_v = a_v;
      end 
  end
  max_unsigned_value = value_v;
  end
endfunction

function  [index_width-1 : 0] max_unsigned_index;
  input [num_inputs*width-1 : 0] a;
  reg [width-1 : 0] a_v;
  reg [index_width-1 : 0] index_v;
  reg [width-1 : 0] value_v;
  reg [index_width : 0] k;
  begin
  value_v = {width{1'b0}};
  index_v = {index_width{1'b0}};
  for (k = 0; k < num_inputs; k = k+1) begin 
      a_v = a[width-1 : 0];
      a = a >> width;
      if (a_v >= value_v) begin 
          value_v = a_v;
          index_v = k[index_width-1 : 0];
      end 
  end
  max_unsigned_index = index_v;
  end
endfunction

function [width-1 : 0] min_unsigned_value;
  input [num_inputs*width-1 : 0] a;
  reg [width-1 : 0] a_v;
  reg [width-1 : 0] value_v;
  reg [index_width : 0] k;
  begin
  value_v = {width{1'b1}};
  for (k = 0; k < num_inputs; k = k+1) begin 
      a_v = a[width-1 : 0];
      a = a >> width;
      if (a_v < value_v) begin 
          value_v = a_v;
      end 
  end
  min_unsigned_value = value_v;
  end
endfunction

function [index_width-1 : 0] min_unsigned_index;
  input [num_inputs*width-1 : 0] a;
  reg [width-1 : 0] a_v;
  reg [width-1 : 0] value_v;
  reg [index_width-1 : 0] index_v;
  reg [index_width : 0] k;
  begin
  value_v = {width{1'b1}};
  index_v = {index_width{1'b0}};
  for (k = 0; k < num_inputs; k = k+1) begin 
      a_v = a[width-1 : 0];
      a = a >> width;
      if (a_v < value_v) begin 
          value_v = a_v;
          index_v = k[index_width-1 : 0];
      end 
  end
  min_unsigned_index = index_v;
  end
endfunction

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
		valid_reg <= 'b0;
		minmax_data_in_reg <= 'b0;
	end
	else if (((~cfg_mode)&&cflow_valid) || (cfg_mode&&instr_valid)) begin
		valid_reg <= cfg_mode ? instr_valid : cflow_valid; //=1?
		minmax_data_in_reg <= minmax_data_in;
	end
	else begin
		valid_reg <= 'b0;
		minmax_data_in_reg <= minmax_data_in_reg;
	end
end

always @(minmax_data_in_reg or min_max) begin
    if (min_max == 1'b0) begin
        minmax_data_out = min_unsigned_value (minmax_data_in_reg);
        minmax_index_out = min_unsigned_index (minmax_data_in_reg);
    end
    else begin 
        minmax_data_out = max_unsigned_value (minmax_data_in_reg);
        minmax_index_out = max_unsigned_index (minmax_data_in_reg);
    end
end

assign minmax_data_out_valid = valid_reg;

endmodule


//=========================================================
// module: fp_E_align_op_sub
//=========================================================
module fp_E_align_op_sub(
	clk,
	rst_n,
	cfg_mode,
	cflow_valid,
	instr_valid,
	sub_data_in_emax,
	sub_data_in_exp1,
	sub_data_in_exp2,
	sub_data_in_exp3,
	sub_data_in_exp4,
	sub_data_in_exp5,
	sub_data_out1,
	sub_data_out2,
	sub_data_out3,
	sub_data_out4,
	sub_data_out5,
	sub_data_out_valid
);

parameter width = 5;

input				clk;
input				rst_n;
input				cfg_mode;		//0:cflow 1:instr
input				cflow_valid;
input				instr_valid;
input  [width-1:0]	sub_data_in_emax;
input  [width-1:0]	sub_data_in_exp1;
input  [width-1:0]	sub_data_in_exp2;
input  [width-1:0]	sub_data_in_exp3;
input  [width-1:0]	sub_data_in_exp4;
input  [width-1:0]	sub_data_in_exp5;
output [width-1:0]	sub_data_out1;
output [width-1:0]	sub_data_out2;
output [width-1:0]	sub_data_out3;
output [width-1:0]	sub_data_out4;
output [width-1:0]	sub_data_out5;
output				sub_data_out_valid;

reg					valid_reg;
reg 	[width-1:0]	sub_data_in_emax_reg;
reg 	[width-1:0]	sub_data_in_exp1_reg;
reg 	[width-1:0]	sub_data_in_exp2_reg;
reg 	[width-1:0]	sub_data_in_exp3_reg;
reg 	[width-1:0]	sub_data_in_exp4_reg;
reg 	[width-1:0]	sub_data_in_exp5_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
		valid_reg <= 'b0;
		sub_data_in_emax_reg <= 'b0;
		sub_data_in_exp1_reg <= 'b0;
		sub_data_in_exp2_reg <= 'b0;
		sub_data_in_exp3_reg <= 'b0;
		sub_data_in_exp4_reg <= 'b0;
		sub_data_in_exp5_reg <= 'b0;
	end
	else if (((~cfg_mode)&&cflow_valid) || (cfg_mode&&instr_valid)) begin
		valid_reg <= cfg_mode ? instr_valid : cflow_valid; //=1?
		sub_data_in_emax_reg <= sub_data_in_emax;
		sub_data_in_exp1_reg <= sub_data_in_exp1;
		sub_data_in_exp2_reg <= sub_data_in_exp2;
		sub_data_in_exp3_reg <= sub_data_in_exp3;
		sub_data_in_exp4_reg <= sub_data_in_exp4;
		sub_data_in_exp5_reg <= sub_data_in_exp5;
	end
	else begin
		valid_reg <= 'b0;
		sub_data_in_emax_reg <= sub_data_in_emax_reg;
		sub_data_in_exp1_reg <= sub_data_in_exp1_reg;
		sub_data_in_exp2_reg <= sub_data_in_exp2_reg;
		sub_data_in_exp3_reg <= sub_data_in_exp3_reg;
		sub_data_in_exp4_reg <= sub_data_in_exp4_reg;
		sub_data_in_exp5_reg <= sub_data_in_exp5_reg;
	end
end

assign sub_data_out1 = sub_data_in_emax_reg - sub_data_in_exp1_reg;
assign sub_data_out2 = sub_data_in_emax_reg - sub_data_in_exp2_reg;
assign sub_data_out3 = sub_data_in_emax_reg - sub_data_in_exp3_reg;
assign sub_data_out4 = sub_data_in_emax_reg - sub_data_in_exp4_reg;
assign sub_data_out5 = sub_data_in_emax_reg - sub_data_in_exp5_reg;
assign sub_data_out_valid = valid_reg;

endmodule


//=========================================================
// module: fp_E_align_op_shift
//=========================================================
module fp_E_align_op_shift(
	clk,
	rst_n,
	cfg_mode,
	cflow_valid,
	instr_valid,
	shift_data_in_amount1,
	shift_data_in_amount2,
	shift_data_in_amount3,
	shift_data_in_amount4,
	shift_data_in_amount5,
	shift_data_in_m1,
	shift_data_in_m2,
	shift_data_in_m3,
	shift_data_in_m4,
	shift_data_in_m5,
	shift_data_out1,
	shift_data_out2,
	shift_data_out3,
	shift_data_out4,
	shift_data_out5,
	shift_data_out_valid
);

parameter dwidth = 16;		//data_width
parameter awidth = 5;		//amount_width

input				clk;
input				rst_n;
input				cfg_mode;		//0:cflow 1:instr
input				cflow_valid;
input				instr_valid;
input  [awidth-1:0]	shift_data_in_amount1;
input  [awidth-1:0]	shift_data_in_amount2;
input  [awidth-1:0]	shift_data_in_amount3;
input  [awidth-1:0]	shift_data_in_amount4;
input  [awidth-1:0]	shift_data_in_amount5;
input  [dwidth-1:0]	shift_data_in_m1;
input  [dwidth-1:0]	shift_data_in_m2;
input  [dwidth-1:0]	shift_data_in_m3;
input  [dwidth-1:0]	shift_data_in_m4;
input  [dwidth-1:0]	shift_data_in_m5;
output [dwidth-1:0]	shift_data_out1;
output [dwidth-1:0]	shift_data_out2;
output [dwidth-1:0]	shift_data_out3;
output [dwidth-1:0]	shift_data_out4;
output [dwidth-1:0]	shift_data_out5;
output				shift_data_out_valid;

reg					valid_reg;
reg [awidth-1:0]	shift_data_in_amount1_reg;
reg [awidth-1:0]	shift_data_in_amount2_reg;
reg [awidth-1:0]	shift_data_in_amount3_reg;
reg [awidth-1:0]	shift_data_in_amount4_reg;
reg [awidth-1:0]	shift_data_in_amount5_reg;
reg [dwidth-1:0]	shift_data_in_m1_reg;
reg [dwidth-1:0]	shift_data_in_m2_reg;
reg [dwidth-1:0]	shift_data_in_m3_reg;
reg [dwidth-1:0]	shift_data_in_m4_reg;
reg [dwidth-1:0]	shift_data_in_m5_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
		valid_reg <= 'b0;
		shift_data_in_amount1_reg <= 'b0;
		shift_data_in_amount2_reg <= 'b0;
		shift_data_in_amount3_reg <= 'b0;
		shift_data_in_amount4_reg <= 'b0;
		shift_data_in_amount5_reg <= 'b0;
		shift_data_in_m1_reg <= 'b0;
		shift_data_in_m2_reg <= 'b0;
		shift_data_in_m3_reg <= 'b0;
		shift_data_in_m4_reg <= 'b0;
		shift_data_in_m5_reg <= 'b0;
	end
	else if (((~cfg_mode)&&cflow_valid) || (cfg_mode&&instr_valid)) begin
		valid_reg <= cfg_mode ? instr_valid : cflow_valid; //=1?
		shift_data_in_amount1_reg <= shift_data_in_amount1;
		shift_data_in_amount2_reg <= shift_data_in_amount2;
		shift_data_in_amount3_reg <= shift_data_in_amount3;
		shift_data_in_amount4_reg <= shift_data_in_amount4;
		shift_data_in_amount5_reg <= shift_data_in_amount5;
		shift_data_in_m1_reg <= shift_data_in_m1;
		shift_data_in_m2_reg <= shift_data_in_m2;
		shift_data_in_m3_reg <= shift_data_in_m3;
		shift_data_in_m4_reg <= shift_data_in_m4;
		shift_data_in_m5_reg <= shift_data_in_m5;
	end
	else begin
		valid_reg <= 'b0;
		shift_data_in_amount1_reg <= shift_data_in_amount1_reg;
		shift_data_in_amount2_reg <= shift_data_in_amount2_reg;
		shift_data_in_amount3_reg <= shift_data_in_amount3_reg;
		shift_data_in_amount4_reg <= shift_data_in_amount4_reg;
		shift_data_in_amount5_reg <= shift_data_in_amount5_reg;
		shift_data_in_m1_reg <= shift_data_in_m1_reg;
		shift_data_in_m2_reg <= shift_data_in_m2_reg;
		shift_data_in_m3_reg <= shift_data_in_m3_reg;
		shift_data_in_m4_reg <= shift_data_in_m4_reg;
		shift_data_in_m5_reg <= shift_data_in_m5_reg;
	end
end

assign shift_data_out1 = shift_data_in_m1_reg >> shift_data_in_amount1_reg;
assign shift_data_out2 = shift_data_in_m2_reg >> shift_data_in_amount2_reg;
assign shift_data_out3 = shift_data_in_m3_reg >> shift_data_in_amount3_reg;
assign shift_data_out4 = shift_data_in_m4_reg >> shift_data_in_amount4_reg;
assign shift_data_out5 = shift_data_in_m5_reg >> shift_data_in_amount5_reg;
assign shift_data_out_valid = valid_reg;

endmodule


//=========================================================
// module: fp_E_align_op_uint2int
//=========================================================
module fp_E_align_op_uint2int(
	clk,
	rst_n,
	cfg_mode,
	cflow_valid,
	instr_valid,
	u2i_data_in_uint1,
	u2i_data_in_uint2,
	u2i_data_in_uint3,
	u2i_data_in_uint4,
	u2i_data_in_uint5,
	u2i_data_in_sign1,
	u2i_data_in_sign2,
	u2i_data_in_sign3,
	u2i_data_in_sign4,
	u2i_data_in_sign5,
	u2i_data_out_int1,
	u2i_data_out_int2,
	u2i_data_out_int3,
	u2i_data_out_int4,
	u2i_data_out_int5,
	u2i_data_out_valid
);

parameter width = 16;

input				clk;
input				rst_n;
input				cfg_mode;		//0:cflow 1:instr
input				cflow_valid;
input				instr_valid;
input  [width-1:0]	u2i_data_in_uint1;
input  [width-1:0]	u2i_data_in_uint2;
input  [width-1:0]	u2i_data_in_uint3;
input  [width-1:0]	u2i_data_in_uint4;
input  [width-1:0]	u2i_data_in_uint5;
input  				u2i_data_in_sign1;
input  				u2i_data_in_sign2;
input  				u2i_data_in_sign3;
input  				u2i_data_in_sign4;
input  				u2i_data_in_sign5;
output [width-1:0]	u2i_data_out_int1;
output [width-1:0]	u2i_data_out_int2;
output [width-1:0]	u2i_data_out_int3;
output [width-1:0]	u2i_data_out_int4;
output [width-1:0]	u2i_data_out_int5;
output				u2i_data_out_valid;

reg					valid_reg;
reg  [width-1:0]	u2i_data_in_uint1_reg;
reg  [width-1:0]	u2i_data_in_uint2_reg;
reg  [width-1:0]	u2i_data_in_uint3_reg;
reg  [width-1:0]	u2i_data_in_uint4_reg;
reg  [width-1:0]	u2i_data_in_uint5_reg;
reg  				u2i_data_in_sign1_reg;
reg  				u2i_data_in_sign2_reg;
reg  				u2i_data_in_sign3_reg;
reg  				u2i_data_in_sign4_reg;
reg  				u2i_data_in_sign5_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
		valid_reg <= 'b0;
		u2i_data_in_uint1_reg <= 'b0;
		u2i_data_in_uint2_reg <= 'b0;
		u2i_data_in_uint3_reg <= 'b0;
		u2i_data_in_uint4_reg <= 'b0;
		u2i_data_in_uint5_reg <= 'b0;
		u2i_data_in_sign1_reg <= 'b0;
		u2i_data_in_sign2_reg <= 'b0;
		u2i_data_in_sign3_reg <= 'b0;
		u2i_data_in_sign4_reg <= 'b0;
		u2i_data_in_sign5_reg <= 'b0;
	end
	else if (((~cfg_mode)&&cflow_valid) || (cfg_mode&&instr_valid)) begin
		valid_reg <= cfg_mode ? instr_valid : cflow_valid; //=1?
		u2i_data_in_uint1_reg <= u2i_data_in_uint1;
		u2i_data_in_uint2_reg <= u2i_data_in_uint2;
		u2i_data_in_uint3_reg <= u2i_data_in_uint3;
		u2i_data_in_uint4_reg <= u2i_data_in_uint4;
		u2i_data_in_uint5_reg <= u2i_data_in_uint5;
		u2i_data_in_sign1_reg <= u2i_data_in_sign1;
		u2i_data_in_sign2_reg <= u2i_data_in_sign2;
		u2i_data_in_sign3_reg <= u2i_data_in_sign3;
		u2i_data_in_sign4_reg <= u2i_data_in_sign4;
		u2i_data_in_sign5_reg <= u2i_data_in_sign5;
	end
	else begin
		valid_reg <= 'b0;
		u2i_data_in_uint1_reg <= u2i_data_in_uint1_reg;
		u2i_data_in_uint2_reg <= u2i_data_in_uint2_reg;
		u2i_data_in_uint3_reg <= u2i_data_in_uint3_reg;
		u2i_data_in_uint4_reg <= u2i_data_in_uint4_reg;
		u2i_data_in_uint5_reg <= u2i_data_in_uint5_reg;
		u2i_data_in_sign1_reg <= u2i_data_in_sign1_reg;
		u2i_data_in_sign2_reg <= u2i_data_in_sign2_reg;
		u2i_data_in_sign3_reg <= u2i_data_in_sign3_reg;
		u2i_data_in_sign4_reg <= u2i_data_in_sign4_reg;
		u2i_data_in_sign5_reg <= u2i_data_in_sign5_reg;
	end
end

assign u2i_data_out_int1 = u2i_data_in_sign1_reg ? (~u2i_data_in_uint1_reg + 'b1) : u2i_data_in_uint1_reg;
assign u2i_data_out_int2 = u2i_data_in_sign2_reg ? (~u2i_data_in_uint2_reg + 'b1) : u2i_data_in_uint2_reg;
assign u2i_data_out_int3 = u2i_data_in_sign3_reg ? (~u2i_data_in_uint3_reg + 'b1) : u2i_data_in_uint3_reg;
assign u2i_data_out_int4 = u2i_data_in_sign4_reg ? (~u2i_data_in_uint4_reg + 'b1) : u2i_data_in_uint4_reg;
assign u2i_data_out_int5 = u2i_data_in_sign5_reg ? (~u2i_data_in_uint5_reg + 'b1) : u2i_data_in_uint5_reg;
assign add_data_out_valid = valid_reg;

endmodule


