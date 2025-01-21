module pe_mul (
	src_a,
	src_b,
	dst
);
    parameter DATA_A_WIDTH = 16;
    parameter DATA_B_WIDTH = 16;
    parameter RSLT_WIDTH = 16;
    input signed   [DATA_A_WIDTH-1:0] src_a;
    input signed   [DATA_B_WIDTH-1:0] src_b;
    output signed  [RSLT_WIDTH-1:0] dst;
	assign dst = src_a * src_b;

endmodule

module pe_adder (
	src_a,
    src_b,
    src_c,
    src_d,
	src_e,
    dst
);
    parameter DATA_WIDTH = 16;
    parameter RSLT_WIDTH = 16;
    input signed   [DATA_WIDTH-1:0]    src_a;
    input signed   [DATA_WIDTH-1:0]    src_b;
    input signed   [DATA_WIDTH-1:0]    src_c;
    input signed   [DATA_WIDTH-1:0]    src_d;    
    input signed   [DATA_WIDTH-1:0]    src_e;    
    output signed  [RSLT_WIDTH-1:0]      dst;

    assign dst = src_a + src_b + src_c + src_d + src_e;

endmodule

module pe_adder_shift (
	src_h,
    src_l,
    dst,
	is_shift
);
    parameter DATA_WIDTH = 16;
    parameter RSLT_WIDTH = 16;
	parameter SHIFT_AMOUNT = 8;
	input							is_shift;
    input signed   [DATA_WIDTH-1:0]    src_h;
    input signed   [DATA_WIDTH-1:0]    src_l;
    output signed  [RSLT_WIDTH-1:0]      dst;
	wire  signed   [RSLT_WIDTH-1:0]     temp;

	assign temp = src_h << SHIFT_AMOUNT;
    assign dst = is_shift ? (temp + src_l) : (src_h + src_l);

endmodule

