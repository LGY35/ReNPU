module noc_router_input #(
    parameter FLIT_WIDTH = 'x,
    parameter DESTS = 1,
    parameter OUTPUTS = 1,
    parameter X = 2'd0,
    parameter Y = 2'd0,
    //几个输出方向，以及每个方向有几个DEST节点
    parameter [OUTPUTS*DESTS-1:0] ROUTES = {DESTS*OUTPUTS{1'b0}},
    parameter BUFFER_DEPTH = 4
)
(
    input                               clk,
    input                               rst_n,

    //输入是一个物理通道，所以只有一个in_flit，但是两个虚拟通道，所以需要两个握手信号
    input   [FLIT_WIDTH-1:0]            in_flit,
    input                               in_last,
    input   [1:0]                       in_valid,
    output  [1:0]                       in_ready,
    //输出是两个虚拟通道，所以两个out_flit
    output  [1:0][OUTPUTS-1:0]          out_valid,
    output  [1:0]                       out_last,
    output  [1:0][FLIT_WIDTH-1:0]       out_flit,
    input   [1:0][OUTPUTS-1:0]          out_ready
);

//两个虚拟通道的寄存器
wire [1:0][FLIT_WIDTH-1:0]    buffer_flit;
wire [1:0]                    buffer_last;
wire [1:0]                    buffer_valid;
wire [1:0]                    buffer_ready;

noc_buffer
#(
    .FLIT_WIDTH (FLIT_WIDTH),
    .DEPTH  (BUFFER_DEPTH)
)
U_buffer_channel1
(
    .clk        (clk),
    .rst_n      (rst_n),
    .in_flit    (in_flit),
    .in_last    (in_last),
    .in_valid   (in_valid[1]),
    .in_ready   (in_ready[1]),
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
    .in_flit    (in_flit),
    .in_last    (in_last),
    .in_valid   (in_valid[0]),
    .in_ready   (in_ready[0]),
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
