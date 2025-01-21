module multi_ctrl_fwdbwd_pipe
#(
parameter DATA_W = 256
)(
input                   clk,rst_n,
//from/to master
input   [1:0]           f_valid_in,
input   [DATA_W-1:0]    f_data_in,
output  [1:0]          	f_ready_out,
//from/to slave
output  [1:0]           b_valid_out,
output  [DATA_W-1:0]    b_data_out,
input   [1:0]           b_ready_in
);

wire [1:0]          valid_wire;
wire [DATA_W-1:0]   data_wire;
wire [1:0]          ready_wire;

multi_ctrl_bwd_pipe
#(
.DATA_W(DATA_W)
)
U_bwd_pipe
(
.clk            (clk    ),
.rst_n          (rst_n  ),
//from/to master
.f_valid_in     (f_valid_in     ),
.f_data_in      (f_data_in      ),
.f_ready_out    (f_ready_out    ),
//from/to slave
.b_valid_out    (valid_wire     ),
.b_data_out     (data_wire      ),
.b_ready_in     (ready_wire     )
);

multi_ctrl_fwd_pipe
#(
.DATA_W(DATA_W)
)
U_fwd_pipe
(
.clk            (clk            ),
.rst_n          (rst_n          ),
//from/to master
.f_valid_in     (valid_wire     ),
.f_data_in      (data_wire      ),
.f_ready_out    (ready_wire     ),
//from/to slave
.b_valid_out    (b_valid_out    ),
.b_data_out     (b_data_out     ),
.b_ready_in     (b_ready_in     )
);

endmodule
