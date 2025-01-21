/*
* @Author: jiangqi
* @Date:   2022-01-12 11:42:06
* @Last Modified by:   jiangqi
* @Last Modified time: 2022-01-13 19:38:14
*/
module clk_div_int #(
	parameter DIV_NUM_WD	=	4,
//	parameter DIV_BYP		=	0,
	parameter INI_DIV		=	0
	)(
	input  	wire  					i_clk_ref,
	input  	wire 					i_rst_n,
	input  	wire  					i_clk_div_en,
	input 	wire  [DIV_NUM_WD-1:0]	i_clk_div_num,
//	input  	wire  					i_occ_mode,
//	input  	wire  [DIV_NUM_WD-1:0]	i_occ_div_num,
	output  wire  					o_clk_div,
    output  wire                    clk_en
	);

localparam  	CONST_1 = {{(DIV_NUM_WD-1){1'b0}},1'b1};

reg 						clk_div_en;
reg 						clk_div_en_d;
reg 						clk_div_en_dd;
reg 	[DIV_NUM_WD-1:0]	clk_div_num_func;
reg 	[DIV_NUM_WD-1:0]	clk_div_cnt;
reg 						clk_div;
reg 						rst_n_1ff;
reg 						rst_n_2ff;
reg							div_num_upd_hold;

wire 						clk_div_en_pulse;
wire 	[DIV_NUM_WD-1:0]	clk_div_num;
wire 	[DIV_NUM_WD-1:0]	div_cnt_nxt;

wire 						clk_neg_en;
wire 						rst_sync_n;
wire 						div_num_upd_pulse;
wire 						clk_div_num_eq_0;
wire                        clk_pos_en;
reg                         clk_pos_en_r;

always @(posedge i_clk_ref)begin
    clk_pos_en_r<=clk_pos_en;
end

always @(posedge i_clk_ref or negedge i_rst_n) begin
	if (!i_rst_n) begin
		// reset
		rst_n_1ff<=1'b0;
		rst_n_2ff<=1'b0;
	end
	else  begin
		rst_n_1ff<=1'b1;
		rst_n_2ff<=rst_n_1ff;
	end
end

assign rst_sync_n = rst_n_2ff ;

always @(posedge i_clk_ref or negedge rst_sync_n) begin
	if (!rst_sync_n) begin
		// reset
		clk_div_en<=1'b0;
		clk_div_en_d<=1'b0;
		clk_div_en_dd<=1'b0;
	end
	else begin
		clk_div_en<=i_clk_div_en;
		clk_div_en_d<=clk_div_en;
		clk_div_en_dd<=clk_div_en_d;
	end
end

assign clk_div_en_pulse = clk_div_en_d && !clk_div_en_dd ;

always @(posedge i_clk_ref or negedge rst_sync_n) begin
	if (!rst_sync_n) begin
		// reset
		div_num_upd_hold<=1'b0;
	end
	else if (div_num_upd_hold && (clk_div_num_func==clk_div_cnt)) begin
		div_num_upd_hold<=1'b0;
	end
	else if(!div_num_upd_hold && clk_div_en_pulse) begin
		div_num_upd_hold<=1'b1;
	end
end

assign div_num_upd_pulse = /*~i_occ_mode &*/ div_num_upd_hold & (clk_div_num_func==clk_div_cnt);

always @(posedge i_clk_ref or negedge rst_sync_n) begin
	if (!rst_sync_n) begin
		// reset
		clk_div_num_func<=INI_DIV-1;
	end
	else if (div_num_upd_pulse) begin
		if(i_clk_div_num[DIV_NUM_WD-1:0]!=0)
			clk_div_num_func <= i_clk_div_num - CONST_1;
		else
			clk_div_num_func<=0;
	end
end

assign clk_div_num =/* i_occ_mode? (i_occ_div_num-CONST_1) :*/ clk_div_num_func;
assign clk_div_num_eq_0 =  (clk_div_num==0)? 1:0 ; //DIV_BYP ? ((clk_div_num==0)?1:0) :0;

always @(posedge i_clk_ref or negedge rst_sync_n) begin
	if (!rst_sync_n) begin
		// reset
		clk_div_cnt<={DIV_NUM_WD{1'b0}};
	end
	else if ((div_num_upd_pulse || clk_div_num_eq_0) /*&& !i_occ_mode*/) begin
		clk_div_cnt<={DIV_NUM_WD{1'b0}};
	end
	else
		clk_div_cnt<=div_cnt_nxt;
end

assign div_cnt_nxt = (clk_div_cnt == clk_div_num)? {DIV_NUM_WD{1'b0}}:(clk_div_cnt + CONST_1);
assign clk_pos_en  = (clk_div_cnt == clk_div_num)? 1:0 ;
assign clk_neg_en  = (clk_div_cnt == (clk_div_num>>1)) ;

always @(posedge i_clk_ref or negedge rst_sync_n) begin
	if (!rst_sync_n) begin
		// reset
		clk_div <= 1'b0;
	end
	else if (clk_neg_en || clk_div_num_eq_0 || div_num_upd_pulse) begin
		clk_div <= 1'b0;
	end
	else if(clk_pos_en)
		clk_div <= 1'b1;
end
`ifdef FPGA
    assign o_clk_div =i_clk_ref;
    assign clk_en=1'b1;
//if(DIV_BYP == 1) begin:gEnByp
`else
	wire ref_clk_byp;
  
    assign  clk_en = clk_div_num_eq_0 ? 1 : clk_pos_en; //org :clk_pos_en_r
	icg u_icg_byp_clk(.Q(ref_clk_byp),.E(clk_div_num_eq_0),.CP(i_clk_ref),.TE(1'b0));
	clk_or u_or_clk_out(.Z(o_clk_div),.A1(ref_clk_byp),.A2(clk_div));
//end else begin:gNoByp
//	clk_buf U_OCC_clk_div(.Z(o_clk_div),.I(clk_div));
//end
`endif
endmodule
