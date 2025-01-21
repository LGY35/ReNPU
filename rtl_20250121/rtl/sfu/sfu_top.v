module sfu_top(
	clk,
	rst_n,
	cub_sfu_req,  //same to all
	cub_sfu_we,   //same to all
	cub_sfu_addr, //same to all
	cub_sfu_gnt,
	cub_sfu_wdata,
	cub_sfu_be,
	cub_sfu_rdata,
	cub_sfu_rvalid,
	cfg_qkv_len,  //qkv matrix len
	cfg_d1,  //1st time use
	cfg_d1_Q,
	cfg_d2,  //2nd time use
	cfg_d2_Q,
	sfu_start,  //pulse, enable
	sfu_rw_scache_addr,
	sfu_done
);

parameter PORT_NUM = 8;  //1 sfu connect to several scaches

parameter IDLE = 3'b0;
parameter RD_SCACHE = 3'd1;
parameter SEQ_1 = 3'd2;
parameter SEQ_2 = 3'd3;
parameter WR_SCACHE = 3'd4;

//clk and rst
input		  clk;
input		  rst_n;
//port to scaches
output		  cub_sfu_req;  //same to all scache
output		  cub_sfu_we;   //same to all scache
output [6:0]  cub_sfu_addr; //same to all scache
input		  cub_sfu_gnt;  //&cub_sfu_gnt
output [8*32-1:0] cub_sfu_wdata;
output [8*4-1:0]  cub_sfu_be;
input  [8*32-1:0] cub_sfu_rdata;
input  [8*1-1:0]  cub_sfu_rvalid;
//static cfg port
input  [7:0]  cfg_qkv_len;  //qkv matrix length for softmax
input  [15:0] cfg_d1;  //1st time use
input  [4:0]  cfg_d1_Q;
input  [15:0] cfg_d2;  //2nd time use
input  [4:0]  cfg_d2_Q;
//ctrl port
input	sfu_start;  //pulse, enable to start compute
input [6:0] sfu_rw_scache_addr;
output	sfu_done;  //write out done signal

genvar i;
reg [2:0] cs;
reg [2:0] ns;
wire [15:0] exp_out;
wire [4:0]  exp_out_Q;
wire		exp_out_valid;

//--------------- scache itf -----------------
reg        cub_sfu_req;
reg        cub_sfu_we;
reg [6:0]  cub_sfu_addr;
reg [7:0]  seq_cnt;

reg [15:0] exp_in_data;
reg  exp_in_valid;

wire rd_scache_done;
wire wr_scache_done;
reg [7:0] rd_scache;
reg [7:0] wr_scache;
reg [31:0] rw_reg[7:0];

//common
always@(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		cub_sfu_req <= 'b0;
		cub_sfu_we <= 'b0;
		cub_sfu_addr <= 'b0;
	end else if ((cs == RD_SCACHE)) begin
		cub_sfu_req <= 'b1;
		cub_sfu_we <= 'b0;
		cub_sfu_addr <= sfu_rw_scache_addr;
	end else if ((cs == WR_SCACHE)) begin
		cub_sfu_req <= 'b1;
		cub_sfu_we <= 'b1;
		cub_sfu_addr <= sfu_rw_scache_addr;
	end else begin
		cub_sfu_req <= 'b0;
		cub_sfu_we <= 'b0;
		cub_sfu_addr <= 'b0;
	end
end

//rd and wr
generate
for (i=0; i<8; i=i+1) begin: scache_ctrl
	always@(posedge clk or negedge rst_n) begin
		if (~rst_n) begin
			rw_reg[i] <= 'b0;
			rd_scache[i] <= 'b0;
			wr_scache[i] <= 'b0;
		end else if ((cs == RD_SCACHE)&&cub_sfu_rvalid[i]) begin
			rw_reg[i] <= cub_sfu_rdata[32*i+:32];
			rd_scache[i] <= 'b1;
			wr_scache[i] <= wr_scache[i];
		end else if ((cs == SEQ_2)&&(seq_cnt == i)) begin
			rw_reg[i] <= {exp_out_Q,exp_out};
			rd_scache[i] <= rd_scache[i];
			wr_scache[i] <= 'b1;
		end else begin
			rw_reg[i] <= rw_reg[i];
			rd_scache[i] <= rd_scache[i];
			wr_scache[i] <= wr_scache[i];
		end
	end

	assign cub_sfu_wdata[32*i+:32] = rw_reg[i];
	assign cub_sfu_be[4*i+:4] = 'hf;
end
endgenerate

assign rd_scache_done = &rd_scache;
assign wr_scache_done = &wr_scache;

//--------------- softmax fsm -----------------

always@(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		seq_cnt <= 'b0;
		exp_in_data <= 'b0;
		exp_in_valid <= 'b0;
	end else if ((cs == SEQ_1)||((cs == SEQ_2)&&exp_out_valid)) begin
		seq_cnt <= seq_cnt + 'b1;
		exp_in_data <= rw_reg[seq_cnt];
		exp_in_valid <= 'b1;
	end else if ((ns == SEQ_2)||(ns == WR_SCACHE)) begin
		seq_cnt <= 'b0;
		exp_in_data <= 'b0;
		exp_in_valid <= 'b0;
	end else begin
		seq_cnt <= seq_cnt;
		exp_in_data <= exp_in_data;
		exp_in_valid <= exp_in_valid;
	end
end

always@(posedge clk or negedge rst_n) begin
	if (~rst_n)
		cs <= 'b0;
	else
		cs <= ns;
end

always@(*) begin
	case(cs)
		IDLE: begin  //idle, wait sfu start
			if (sfu_start) ns = RD_SCACHE;
			else ns = IDLE;
		end
		RD_SCACHE: begin  //read 8 scache
			if (rd_scache_done) ns = SEQ_1;
			else ns = RD_SCACHE;
		end
		SEQ_1: begin  //1st time, calculate e^x
			if (seq_cnt == cfg_qkv_len) ns = SEQ_2;
			else ns = SEQ_1;
		end
		SEQ_2: begin  //2nd time, calculate e^(x-lnF)
			if (seq_cnt == cfg_qkv_len) ns = WR_SCACHE;
			else ns = SEQ_2;
		end
		WR_SCACHE: begin  //write out
			if (wr_scache_done) ns = IDLE;
			else ns = WR_SCACHE;
		end

		default:
			ns = IDLE;
	endcase
end

//--------------- 1st/2nd ctrl -----------------
wire [15:0] d_in;
wire [4:0]  d_in_Q;
wire		lnF_en;
wire [15:0] lnF;
wire [4:0]  lnF_Q;
wire		lnF_valid;

assign lnF_en = (cs == SEQ_2) ? 1'b1 : 1'b0;
assign d_in = (cs == SEQ_1) ? cfg_d1 : ((cs == SEQ_2) ? cfg_d2 : 'b0);
assign d_in_Q = (cs == SEQ_1) ? cfg_d1_Q : ((cs == SEQ_2) ? cfg_d2_Q : 'b0);

//--------------- serial adder -----------------
reg [15:0] fsum; //exp sum F
wire	   fsum_valid;

always@(posedge clk or negedge rst_n) begin
	if (~rst_n)
		fsum <= 'b0;
	else if (exp_out_valid&&(cs==SEQ_1))
		fsum <= fsum + exp_out;
	else if (ns == IDLE)
		fsum <= 'b0;
	else 
		fsum <= fsum;
end

assign fsum_valid = ns == SEQ_2;

//--------------- exp ln units -----------------
sfu_exp_unit  #(
	.IN_W  (16),
	.LNF_W (16),
	.TMP1_W(16),
	.TMP2_W(16),
	.TMP3_W(16),
	.D_W   (16),
	.OUT_W (16)
)u_sfu_exp_unit(
	.clk		(clk			),
	.rst_n		(rst_n			),
	.lnF_en		(lnF_en			),
	.lnF_in		(lnF			),
	.lnF_in_Q	(lnF_Q			),
	.d_in		(d_in			),
	.d_in_Q		(d_in_Q			),
	.data_in	(exp_in_data	),
	.data_in_Q	(0		),
	.valid_in	(exp_in_valid	),
	.data_out	(exp_out		),
	.data_out_Q	(exp_out_Q		),
	.valid_out	(exp_out_valid	)
);

sfu_log_unit  #(
	.IN_W  (16),
	.TMP1_W(16),
	.OUT_W (16)
)u_sfu_log_unit(
	.clk		(clk			),
	.rst_n		(rst_n			),
	.data_in	(fsum			),
	.data_in_Q	(exp_out_Q		),
	.valid_in	(fsum_valid		),
	.data_out	(lnF			),
	.data_out_Q	(lnF_Q			),
	.valid_out	(lnF_valid		)
);

endmodule

