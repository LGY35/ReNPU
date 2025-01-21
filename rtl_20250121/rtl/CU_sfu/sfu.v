module sfu(
	clk,
	rst_n,
	data_in,	
	Q_in,
//	valid_in,
//	ready_out,
	data_out,	
	valid_out,
//	ready_in,
	sfu_req,	
	sfu_cfg_len,
	sfu_cfg_mode,
	sfu_calc_ok
	//instr_data_in_a,
	//instr_data_in_b,
	//instr_valid_in,
	//instr_data_out,
	//instr_valid_out
);

//------------------ ports define -------------------
//clk and rst
input		  clk;
input		  rst_n;
//data ports
input  [31:0] data_in;		//int16 ext
input  [7:0]  Q_in;			//max 8
//input		  valid_in;
//output		  ready_out;
output reg [31:0] data_out;		//int16 ext
output reg	      valid_out;
//input	      ready_in;
//ctrl ports
input		  sfu_req;		//pulse
input  [5:0]  sfu_cfg_len;	//actual len - 1
input  [3:0]  sfu_cfg_mode;	//[3]:  0:fp16  1:bf16
							//[2:0]:000:softmax  001:i2flt  010:flt2i  011:fp_add  100:fp_exp  101:fp_div
output		  sfu_calc_ok;
//instr mode ports
//input  [15:0] instr_data_in_a;	//fp16
//input  [15:0] instr_data_in_b;	//fp16
//input		  instr_valid_in;
//output [15:0] instr_data_out;	//fp16
//output		  instr_valid_out;

wire [31:0]   data_out_w;		//int16 ext
wire	      valid_out_w;
wire		  valid_in;	//self-generated fake valid

//------------------- instr mode --------------------
reg [15:0] instr_data_a_d1;
reg [15:0] instr_data_b_d1;
reg        instr_valid_d1;
reg        instr_valid_d2;
reg		   sfu_req_r;

reg  [15:0] instr_data_out;	//fp16
reg 		  instr_valid_out;

always@(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		sfu_req_r <= 'b0;
	end else if (sfu_req) begin
		sfu_req_r <= sfu_req;
	end else begin
		sfu_req_r <= 'b0;
	end
end

always@(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		instr_data_a_d1 <= 'b0;
		instr_valid_d1 <= 'b0;
	end else if (((sfu_cfg_mode=='b001)||(sfu_cfg_mode=='b010)||(sfu_cfg_mode=='b100))&&valid_in&&sfu_req) begin
		instr_data_a_d1 <= (sfu_cfg_mode[3]) ? {{8{data_in[7]}},data_in[7:0]} : {{5{data_in[10]}},data_in[10:0]};
		instr_valid_d1 <= valid_in;
	end else begin
		instr_data_a_d1 <= instr_data_a_d1;
		instr_valid_d1 <= 'b0;
	end
end

always@(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		instr_data_b_d1 <= 'b0;
	end else if (((sfu_cfg_mode=='b011)||(sfu_cfg_mode=='b101))&&valid_in&&sfu_req_r) begin
		instr_data_b_d1 <= (sfu_cfg_mode[3]) ? {{8{data_in[7]}},data_in[7:0]} : {{5{data_in[10]}},data_in[10:0]};
	end else begin
		instr_data_b_d1 <= instr_data_b_d1;
	end
end

always@(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		instr_valid_d2 <= 'b0;
	end else if (instr_valid_d1) begin
		instr_valid_d2 <= instr_valid_d1;
	end else begin
		instr_valid_d2 <= 'b0;
	end
end

wire [15:0] fp_i2flt_a;
wire [15:0] fp_i2flt_z;
wire [15:0] fp_flt2i_a;
wire [15:0] fp_flt2i_z;
wire [15:0] fp_add1_a;
wire [15:0] fp_add1_b;
wire [15:0] fp_add1_z;
wire [15:0] fp_add_a;
wire [15:0] fp_add_b;
wire [15:0] fp_add_z;
wire [15:0] fp_exp_a;
wire [15:0] fp_exp_z;
wire [15:0] fp_div_a;
wire [15:0] fp_div_b;
wire [15:0] fp_div_z;

always@(*) begin
	case(sfu_cfg_mode)
		3'b000: begin
			instr_data_out = 'b0;
			instr_valid_out = 'b0;
		end
		3'b001: begin
			instr_data_out = fp_i2flt_z;
			instr_valid_out = instr_valid_d1;
		end
		3'b010: begin
			instr_data_out = fp_flt2i_z;
			instr_valid_out = instr_valid_d1;
		end
		3'b011: begin
			instr_data_out = fp_add_z;
			instr_valid_out = instr_valid_d2;	//2stage
		end
		3'b100: begin
			instr_data_out = fp_exp_z;
			instr_valid_out = instr_valid_d1;
		end
		3'b101: begin
			instr_data_out = fp_div_z;
			instr_valid_out = instr_valid_d2;	//2stage
		end
		default: begin
			instr_data_out = 'b0;
			instr_valid_out = 'b0;
		end
	endcase
end

//----------------------- fsm -----------------------
parameter IDLE = 'b000;
parameter MAX  = 'b001;
parameter SUB  = 'b010;
parameter ACCU = 'b011;
parameter DIV  = 'b100;
reg [2:0] cs;
reg [2:0] ns;
reg [5:0] cnt;
reg [5:0] cnt_valid;
reg		  cnt_one;

//valid generate
always@(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		cnt_valid <= 'b0;
	end else if (cs == MAX) begin
		cnt_valid <= cnt_valid + 'b1;
	end else if (ns == ACCU) begin 
		cnt_valid <= 'b0;
	end
end

//cnt one is used for ping-pong ram
always@(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		cnt_one <= 'b0;
	end else if (cs == ACCU) begin
		cnt_one <= ~cnt_one;
	end else if (ns == DIV) begin 
		cnt_one <= 'b0;
	end
end

assign valid_in = |cnt_valid;

always@(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		cs <= IDLE;
	end else begin
		cs <= ns;
	end
end

always@(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		cnt <= 'b0;
	end else if (valid_in&&((cs == MAX)||(cs == SUB)||(cs == ACCU)||(cs == DIV))) begin
		cnt <= cnt + 'b1;
	end else if ((ns == SUB)||(ns == ACCU)||(ns == DIV)||(ns == IDLE)) begin 
		cnt <= 'b0;
	end
end

always@(*) begin
	case(cs) 
	IDLE:
		if (sfu_req) ns = MAX;
		else ns = IDLE;
	MAX:
		if (cnt == sfu_cfg_len) ns = ACCU;
		else ns = MAX;
//	SUB:
//		if (cnt == sfu_cfg_len) ns = ACCU;
//		else ns = SUB;
	ACCU:
		if (cnt == sfu_cfg_len) ns = DIV;
		else ns = ACCU;
	DIV:
		if (cnt == sfu_cfg_len) ns = IDLE;
		else ns = DIV;
	default:
		ns = IDLE;
	endcase
end

//assign ready_out = (cs == IDLE)||(cs == MAX);

//------------------ input reg l1d1 -------------------
reg [15:0] data_l1d1;
reg        valid_l1d1;

always@(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		data_l1d1 <= 'b0;
		valid_l1d1 <= 'b0;
	end else if (valid_in) begin
		data_l1d1 <= (sfu_cfg_mode[3]) ? {{8{data_in[7]}},data_in[7:0]} : {{5{data_in[10]}},data_in[10:0]};
		valid_l1d1 <= valid_in;
	end else begin
		data_l1d1 <= data_l1d1;
		valid_l1d1 <= 'b0;
	end
end

//------------------ int to fp l1d2 -------------------
reg  [15:0] data_l1d2;
reg         valid_l1d2;

always@(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		data_l1d2 <= 'b0;
		valid_l1d2 <= 'b0;
	end else if (valid_l1d1) begin
		data_l1d2 <= fp_i2flt_z;
		valid_l1d2 <= valid_l1d1;
	end else begin
		data_l1d2 <= data_l1d2;
		valid_l1d2 <= 'b0;
	end
end

assign fp_i2flt_a = (sfu_cfg_mode == 3'b000) ? data_l1d1 : instr_data_a_d1; //sign ext to int16

DW_fp_i2flt #(
	.sig_width	(10),
	.exp_width	(5),
	.isize		(16),
	.isign		(1)
) U_DW_fp_i2flt(
	.a			(fp_i2flt_a),
	.rnd		(3'b001), 
	.z			(fp_i2flt_z),
	.status		()
);

//------------------ find max l1d3/4 -------------------
reg  [15:0] data_max;
reg  [15:0] data_l1d3;
reg         valid_l1d3;
reg         valid_l1d4;

always@(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		data_l1d3 <= 'b0;
		valid_l1d3 <= 'b0;
	end else if (valid_l1d2) begin
		data_l1d3 <= data_l1d2;
		valid_l1d3 <= valid_l1d2;
	end else begin
		data_l1d3 <= data_l1d3;
		valid_l1d3 <= 'b0;
	end
end

always@(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		data_max <= 'b0;
		valid_l1d4 <= 'b0;
	end else if (valid_l1d3) begin
		data_max <= fp_add1_z[15] ? data_l1d3 : data_max;
		valid_l1d4 <= valid_l1d3;
	end else begin
		data_max <= data_max;
		valid_l1d4 <= 'b0;
	end
end

//------------------ sub max l2d1/2 -------------------
reg  [15:0] data_l2d2;
reg         valid_l2d1;
reg         valid_l2d2;
wire [15:0] ram_out;

always@(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		valid_l2d1 <= 'b0;
	end else if (cs == ACCU) begin
		valid_l2d1 <= 'b1;
	end else begin
		valid_l2d1 <= 'b0;
	end
end

always@(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		data_l2d2 <= 'b0;
		valid_l2d2 <= 'b0;
	end else if (valid_l2d1&&cnt_one) begin
		data_l2d2 <= fp_add1_z;
		valid_l2d2 <= 'b1;
	end else begin
		data_l2d2 <= data_l2d2;
		valid_l2d2 <= 'b0;
	end
end

assign fp_add1_a = (cs == MAX) ? data_max : ~data_max +16'b1; 
assign fp_add1_b = (cs == MAX) ? ~data_l1d2+16'b1 : ram_out;

DW_lp_piped_fp_add #(
	.sig_width		(10),
	.exp_width		(5),
	.ieee_compliance(0),
	.op_iso_mode    (0), 
    .id_width       (8),
    .in_reg         (0),
    .stages         (2), //2 stage pipeline
    .out_reg        (0),
    .no_pm          (1),
    .rst_mode       (0)
) U_DW_lp_piped_fp_add_1(
	.clk			(clk),
	.rst_n			(rst_n),
	.a				(fp_add1_a),
	.b				(fp_add1_b),
	.rnd			(3'b001),
	.z				(fp_add1_z),
	.status			(),
	.launch			(1'b0),
	.launch_id		(8'b0),
	.pipe_full		(),
	.pipe_ovf		(),
	.accept_n		(1'b1),
	.arrive			(),
	.arrive_id		(),
	.push_out_n		(),
	.pipe_census	()
);

//---------------------- 64x16 ram ----------------------
wire ce;
wire we;
wire [15:0] ram_in;
reg  [15:0] data_l2d4;
reg 		valid_l2d4;

assign ce = ((cs == MAX)&&valid_l1d2) || //input data write in while doing MAX
			((cs == ACCU)&&cnt_one)   || //input data read out while doing SUB
			valid_l2d4  ||				 //exp data write in
			(cs == DIV) ||				 //exp data read out
			(((sfu_cfg_mode=='b011)||(sfu_cfg_mode=='b101))&&valid_in&&(sfu_req||sfu_req_r)); //instr mode dual operator

assign we = ((cs == MAX)&&valid_l1d2) || //input data write in while doing MAX
			(valid_l2d4&&(cs == ACCU))|| //exp data write in
			(((sfu_cfg_mode=='b011)||(sfu_cfg_mode=='b101))&&valid_in&&sfu_req); //instr mode dual operator

assign ram_in = (cs == MAX) ? data_l1d2 : data_l2d4;

std_spram64x16 u_sfu_ram(
    .clk	(clk),
    .CEB	(~ce),
    .WEB	(~we),
    .A		(cnt),
    .D		(ram_in),
    .Q		(ram_out)
);

//---------------------- exp l2d3/4 ----------------------
reg  [15:0] data_l2d3;
reg         valid_l2d3;

assign fp_exp_a = (sfu_cfg_mode == 3'b000) ? data_l2d2 : instr_data_a_d1;

always@(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		data_l2d3 <= 'b0;
		valid_l2d3 <= 'b0;
	end else if (valid_l2d2||instr_valid_d1) begin
		data_l2d3 <= fp_exp_a;
		valid_l2d3 <= valid_l2d2;
	end else begin
		data_l2d3 <= data_l2d3;
		valid_l2d3 <= 'b0;
	end
end

DW_fp_exp #(
	.sig_width		(10),
	.exp_width		(5),
	.ieee_compliance(0),
	.arch			(2)
) U_DW_fp_exp(
	.a				(data_l2d3),
	.z				(fp_exp_z),
	.status			()
);

always@(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		data_l2d4 <= 'b0;
		valid_l2d4 <= 'b0;
	end else if (valid_l2d3) begin
		data_l2d4 <= fp_exp_z;
		valid_l2d4 <= valid_l2d3;
	end else begin
		data_l2d4 <= data_l2d4;
		valid_l2d4 <= 'b0;
	end
end

//---------------------- psummer ----------------------
reg  [15:0] psum0;
reg  [15:0] psum1;
wire [15:0] a_w;
wire [15:0] b_w;
wire [15:0] z_w;
reg  [15:0] psum_all;

assign a_w = (ns == DIV) ? psum0 : data_l2d4;
assign b_w = (ns == DIV) ? psum1 : cnt[0] ? psum0 : psum1;

assign sfu_calc_ok = ns == DIV;

always@(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		psum0 <= 'b0;
	end else if ((cs == ACCU) && valid_l2d4 && cnt[0]) begin
		psum0 <= psum0 + z_w;
	end else if (ns == IDLE) begin
		psum0 <= 'b0;
	end else begin
		psum0 <= psum0;
	end
end

always@(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		psum1 <= 'b0;
	end else if ((cs == ACCU) && valid_l2d4 && ~cnt[0]) begin
		psum1 <= psum1 + z_w;
	end else if (ns == IDLE) begin
		psum1 <= 'b0;
	end else begin
		psum1 <= psum1;
	end
end

always@(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		psum_all <= 'b0;
	end else if (ns == DIV) begin
		psum_all <= z_w;
	end else if (ns == IDLE) begin
		psum_all <= 'b0;
	end else begin
		psum_all <= psum_all;
	end
end

assign fp_add_a = (sfu_cfg_mode == 3'b000) ? a_w : ram_out;
assign fp_add_b = (sfu_cfg_mode == 3'b000) ? b_w : instr_data_b_d1;
assign z_w = fp_add_z;

DW_lp_piped_fp_add #(
	.sig_width		(10),
	.exp_width		(5),
	.ieee_compliance(0),
	.op_iso_mode    (0), 
    .id_width       (8),
    .in_reg         (0),
    .stages         (2), //2 stage pipeline
    .out_reg        (0),
    .no_pm          (1),
    .rst_mode       (0)
) U_DW_lp_piped_fp_add_2(
	.clk			(clk),
	.rst_n			(rst_n),
	.a				(fp_add_a),
	.b				(fp_add_b),
	.rnd			(3'b001),
	.z				(fp_add_z),
	.status			(),
	.launch			(1'b0),
	.launch_id		(8'b0),
	.pipe_full		(),
	.pipe_ovf		(),
	.accept_n		(1'b1),
	.arrive			(),
	.arrive_id		(),
	.push_out_n		(),
	.pipe_census	()
);

//---------------------- div l3d1/2 ----------------------

reg  [15:0] data_l3d2;
reg         valid_l3d1;
reg         valid_l3d2;

always@(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		valid_l3d1 <= 'b0;
	end else if (cs == DIV) begin
		valid_l3d1 <= 'b1;
	end else begin
		valid_l3d1 <= 'b0;
	end
end

always@(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		data_l3d2 <= 'b0;
		valid_l3d2 <= 'b0;
	end else if (valid_l3d1) begin
		data_l3d2 <= fp_div_z;
		valid_l3d2 <= valid_l3d1;
	end else begin
		data_l3d2 <= data_l3d2;
		valid_l3d2 <= 'b0;
	end
end

assign fp_div_a = (sfu_cfg_mode == 3'b000) ? psum_all : ram_out;
assign fp_div_b = (sfu_cfg_mode == 3'b000) ? ram_out : instr_data_b_d1;

DW_lp_piped_fp_div #(
	.sig_width		(10),
	.exp_width		(5),
	.ieee_compliance(0),
	.faithful_round	(0),
	.op_iso_mode    (0), 
    .id_width       (8),
    .in_reg         (0),
    .stages         (2), //2 stage pipeline
    .out_reg        (0),
    .no_pm          (1),
    .rst_mode       (0)
) U_DW_lp_piped_fp_div(
	.clk			(clk),
	.rst_n			(rst_n),
	.a				(fp_div_a),
	.b				(fp_div_b),
	.rnd			(3'b001),
	.z				(fp_div_z),
	.status			(),
	.launch			(1'b0),
	.launch_id		(8'b0),
	.pipe_full		(),
	.pipe_ovf		(),
	.accept_n		(1'b1),
	.arrive			(),
	.arrive_id		(),
	.push_out_n		(),
	.pipe_census	()
);

//DW_fp_div #(
//	.sig_width		(10),
//	.exp_width		(5),
//	.ieee_compliance(0),
//	.faithful_round (0)
//) U_DW_fp_div(
//	.a				(fp_div_a),
//	.b				(fp_div_b),
//	.rnd			(3'b001),
//	.z				(fp_div_z),
//	.status			()
//);

//---------------------- flt2i l3d3 ----------------------

reg  [15:0] data_l3d3;
reg         valid_l3d3;
wire [15:0] data_l3d3_w;

always@(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		data_l3d3 <= 'b0;
		valid_l3d3 <= 'b0;
	end else if (valid_l3d2) begin
		data_l3d3 <= data_l3d2;
		valid_l3d3 <= valid_l3d2;
	end else begin
		data_l3d3 <= data_l3d3;
		valid_l3d3 <= 'b0;
	end
end
assign fp_flt2i_a = (sfu_cfg_mode == 3'b000) ? data_l3d3 : instr_data_a_d1;

DW_fp_flt2i #(
	.sig_width		(10),
	.exp_width		(5),
	.isize			(16),
	.ieee_compliance(0)
) U_DW_fp_flt2i(
	.a			(fp_flt2i_a),
	.rnd		(3'b001), 
	.z			(fp_flt2i_z),
	.status		()
);

//---------------------- pipe out l3d4 ----------------------

reg  [15:0] data_l3d4;
reg         valid_l3d4;

always@(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		data_l3d4 <= 'b0;
		valid_l3d4 <= 'b0;
	end else if (valid_l3d3) begin
		data_l3d4 <= fp_flt2i_z;
		valid_l3d4 <= valid_l3d3;
	end else begin
		data_l3d4 <= data_l3d4;
		valid_l3d4 <= 'b0;
	end
end

assign data_out_w = (sfu_cfg_mode==3'b000) ? {{16{data_l3d4[15]}},data_l3d4} : {{16{instr_data_out[15]}},instr_data_out};
assign valid_out_w = (sfu_cfg_mode==3'b000) ? valid_l3d4 : instr_valid_out;

//---------------------- pipe out final ----------------------
always@(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		data_out <= 'b0;
		valid_out <= 'b0;
	end else if (valid_out_w) begin
		data_out <= data_out_w;
		valid_out <= valid_out_w | valid_in;
	end else begin
		data_out <= data_out;
		valid_out <= 'b0;
	end
end

endmodule

