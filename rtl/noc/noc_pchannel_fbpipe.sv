/* 
 * =============================================================================
 * forward-backward pipeline
 */

module noc_pchannel_fbpipe #(
    parameter DATA_WIDTH = 256,
    parameter VCHANNEL_NUM = 2
)
(
    input                               clk,
    input                               rst_n,
    input   [DATA_WIDTH-1:0]            in_flit,
    input                               in_last,
    input   [VCHANNEL_NUM-1:0]          in_valid,
    output  logic   [VCHANNEL_NUM-1:0]  in_ready,
    
    output  logic   [VCHANNEL_NUM-1:0]  out_valid,
    output  logic   [DATA_WIDTH-1:0]    out_flit,
    output  logic                       out_last,
    input           [VCHANNEL_NUM-1:0]  out_ready
);

logic   [1:0][256-1:0]  in_flit_pipe;
logic   [1:0]           in_last_pipe;
logic   [1:0]           in_valid_pipe;
logic   [1:0]           in_ready_pipe;

noc_vchannel_mux
#(
    .FLIT_WIDTH (256)
)
u_vc_mux
(
    // .clk        (clk),
    .in_flit    (in_flit_pipe),
    .in_last    (in_last_pipe),
    .in_valid   (in_valid_pipe),
    .in_ready   (in_ready_pipe),
    .out_flit   (out_flit),
    .out_last   (out_last),
    .out_valid  (out_valid),
    .out_ready  (out_ready)
);

fwdbwd_pipe 
#( 
    .DATA_W(256+1)
)
U_pchannel_pipe_0
(
    .clk            (clk),
    .rst_n          (rst_n),
//from/to master
    .f_valid_in     (in_valid[0]),
    .f_data_in      ({in_last, in_flit}),
    .f_ready_out    (in_ready[0]),
//from/to slave
    .b_valid_out    (in_valid_pipe[0]),
    .b_data_out     ({in_last_pipe[0], in_flit_pipe[0]}),
    .b_ready_in     (in_ready_pipe[0])

);

fwdbwd_pipe 
#( 
    .DATA_W(256+1)
)
U_pchannel_pipe_1
(
    .clk            (clk),
    .rst_n          (rst_n),
//from/to master
    .f_valid_in     (in_valid[1]),
    .f_data_in      ({in_last, in_flit}),
    .f_ready_out    (in_ready[1]),
//from/to slave
    .b_valid_out    (in_valid_pipe[1]),
    .b_data_out     ({in_last_pipe[1], in_flit_pipe[1]}),
    .b_ready_in     (in_ready_pipe[1])

);



endmodule // noc_router_fbpipe
