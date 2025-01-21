module noc_router_input #(
    parameter FLIT_WIDTH = 256,
    parameter DESTS = 1,
    parameter OUTPUTS = 1,
    parameter X = 2'd0,
    parameter Y = 2'd0,
    parameter [OUTPUTS*DESTS-1:0] ROUTES = {DESTS*OUTPUTS{1'b0}},
    parameter BUFFER_DEPTH = 4
)
(
    input                               clk,
    input                               rst_n,

    input   [FLIT_WIDTH-1:0]            in_flit,
    input                               in_last,
    input   [1:0]                       in_valid,
    output  [1:0]                       in_ready,

    output  [1:0][OUTPUTS-1:0]          out_valid,
    output  [1:0]                       out_last,
    output  [1:0][FLIT_WIDTH-1:0]       out_flit,
    input   [1:0][OUTPUTS-1:0]          out_ready
);

wire [1:0][FLIT_WIDTH-1:0]    buffer_flit;
wire [1:0]                    buffer_last;
wire [1:0]                    buffer_valid;
wire [1:0]                    buffer_ready;

logic        [256-1:0]  in_flit_pipe;
logic                   in_last_pipe;
logic   [1:0]           in_valid_pipe;
logic   [1:0]           in_ready_pipe;

noc_pchannel_fbpipe 
#(
    .DATA_WIDTH(256),
    .VCHANNEL_NUM(2)
)
U_input_pchannel_pipe(
    .clk        (clk),
    .rst_n      (rst_n),

    .in_valid   (in_valid),
    .in_flit    (in_flit),
    .in_last    (in_last),
    .in_ready   (in_ready),

    .out_valid  (in_valid_pipe),
    .out_flit   (in_flit_pipe),
    .out_last   (in_last_pipe),
    .out_ready  (in_ready_pipe)
);


noc_buffer
#(
    .FLIT_WIDTH (FLIT_WIDTH),
    .DEPTH  (BUFFER_DEPTH)
)
U_buffer_channel1
(
    .clk        (clk),
    .rst_n      (rst_n),
    .in_flit    (in_flit_pipe),
    .in_last    (in_last_pipe),
    .in_valid   (in_valid_pipe[1]),
    .in_ready   (in_ready_pipe[1]),
    .out_flit   (buffer_flit[1]),
    .out_last   (buffer_last[1]),
    .out_valid  (buffer_valid[1]),
    .out_ready  (buffer_ready[1])
);

noc_router_lookup
#(
    .FLIT_WIDTH (FLIT_WIDTH), 
    .DESTS (DESTS),
    .OUTPUTS (OUTPUTS), 
    .ROUTES (ROUTES)
)
U_lookup
(
    .clk        (clk),
    .rst_n      (rst_n),
    .in_flit    (buffer_flit[1]),
    .in_last    (buffer_last[1]),
    .in_valid   (buffer_valid[1]),
    .in_ready   (buffer_ready[1]),
    .out_flit   (out_flit[1]),
    .out_last   (out_last[1]),
    .out_valid  (out_valid[1]),
    .out_ready  (out_ready[1])
);

wire [FLIT_WIDTH-1:0]                   lookup_flit;
wire                                    lookup_last;
wire [OUTPUTS-1:0]                      lookup_valid;
wire                                    lookup_ready;

noc_buffer
#(    
    .FLIT_WIDTH (FLIT_WIDTH),
    .DEPTH  (BUFFER_DEPTH)
)
U_buffer_channel0
(    
    .clk        (clk),
    .rst_n      (rst_n),
    .in_flit    (in_flit_pipe),
    .in_last    (in_last_pipe),
    .in_valid   (in_valid_pipe[0]),
    .in_ready   (in_ready_pipe[0]),
    .out_flit   (buffer_flit[0]),
    .out_last   (buffer_last[0]),
    .out_valid  (buffer_valid[0]),
    .out_ready  (buffer_ready[0])
);

noc_router_lookup_m
#(    
    .FLIT_WIDTH (FLIT_WIDTH), 
    .DESTS      (DESTS), 
    .ID_WIDTH   (4),
    .X          (X), 
    .Y          (Y),
    .OUTPUTS    (OUTPUTS), 
    .ROUTES     (ROUTES)
)
U_lookup_channel0
(    
    .clk        (clk),
    .rst_n      (rst_n),
    .in_flit    (buffer_flit[0]),
    .in_last    (buffer_last[0]),
    .in_valid   (buffer_valid[0]),
    .in_ready   (buffer_ready[0]),
    .out_flit   (lookup_flit),
    .out_last   (lookup_last),
    .out_valid  (lookup_valid),
    .out_ready  (lookup_ready)
);

noc_router_fbpipe
#(
    .DATA_WIDTH(FLIT_WIDTH+1)
)
U_router_fbpipe
(
    .clk        (clk),
    .rst_n      (rst_n),
    .in_data    ({lookup_last, lookup_flit}),
    .in_valid   (lookup_valid),
    .in_ready   (lookup_ready),

    .out_data   ({out_last[0], out_flit[0]}),
    .out_valid  (out_valid[0]),
    .out_ready  (out_ready[0])
);



endmodule // noc_router_input
