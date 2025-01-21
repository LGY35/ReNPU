module sfu_wrapper(
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
);

//------------------ ports define -------------------
//clk and rst
input		  clk;
input		  rst_n;
//data ports
input  [31:0] data_in;		//int16 ext
input  [7:0]  Q_in;		//8
//input		  valid_in;
//output	reg	  ready_out;
output reg [31:0] data_out;		//int16 ext
output	reg      valid_out;
//input	      ready_in;
//ctrl ports
input		  sfu_req;		//pulse
input  [5:0]  sfu_cfg_len;	//actual len - 1
input  [3:0]  sfu_cfg_mode;	//000:softmax  001:i2flt  010:flt2i  011:fp_add  100:fp_exp  101:fp_div
output	reg	  sfu_calc_ok;

reg [31:0] data_in_r;
reg [7:0]  Q_in_r;
//reg        valid_in_r;
//reg        ready_in_r;
reg        sfu_req_r;
reg [5:0]  sfu_cfg_len_r;
reg [3:0]  sfu_cfg_mode_r;

always@(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		data_in_r <= 'b0;
		Q_in_r <= 'b0;
//		valid_in_r <= 'b0;
//		ready_in_r     <= 'b0;
		sfu_req_r      <= 'b0;
		sfu_cfg_len_r  <= 'b0;
		sfu_cfg_mode_r <= 'b0;
	end else begin
		data_in_r <= data_in;
		Q_in_r <= Q_in;
//		valid_in_r <= valid_in;
//		ready_in_r     <= ready_in  ;
		sfu_req_r      <= sfu_req   ;
		sfu_cfg_len_r  <= sfu_cfg_len;
		sfu_cfg_mode_r <= sfu_cfg_mode;
	end
end


//wire 	    ready_out_w;
wire [31:0] data_out_w;		//int16 ext
wire        valid_out_w;
wire 	    sfu_calc_ok_w;

always@(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
//		ready_out 		<= 'b0;
		sfu_calc_ok  	<= 'b0;
		data_out	  	<= 'b0;
		valid_out 		<= 'b0;
	end else begin
//		ready_out <= ready_out_w;
		sfu_calc_ok  <= sfu_calc_ok_w;
		data_out	  <= data_out_w; 
		valid_out <= valid_out_w;
	end
end

sfu U_sfu(
	.clk			(clk),
	.rst_n			(rst_n),
	.data_in		(data_in_r		),	
	.Q_in			(Q_in_r),
//	.valid_in		(valid_in_r		),
//	.ready_out		(ready_out_w		),
	.data_out		(data_out_w		),	
	.valid_out		(valid_out_w		),
//	.ready_in		(ready_in_r		),
	.sfu_req		(sfu_req_r		),	
	.sfu_cfg_len	(sfu_cfg_len_r	),
	.sfu_cfg_mode	(sfu_cfg_mode_r	),
	.sfu_calc_ok	(sfu_calc_ok_w	)
);


endmodule
