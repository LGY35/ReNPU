module noc_router #(
    parameter FLIT_WIDTH = 32,
    parameter VCHANNELS = 2,
    parameter INPUTS = 'x,      //参数默认是x，就需要在例化的时候明确指定
    parameter OUTPUTS = 'x, //输入和输出的方向数，即东西南北local 5个
    parameter X = 2'd0,     
    parameter Y = 2'd0,     //东西南北四个方向的x和y的节点
    parameter BUFFER_SIZE_IN = 4,
    parameter BUFFER_SIZE_OUT = 4,
    parameter DESTS = 'x,   //目的节点数
    parameter [OUTPUTS*DESTS-1:0] ROUTES = {DESTS*OUTPUTS{1'b0}}    //输出端口与目的节点之间关系的路由表
)
(
    input                                   clk, 
    input                                   rst_n,

    output [OUTPUTS-1:0][FLIT_WIDTH-1:0]    out_flit,
    output [OUTPUTS-1:0]                    out_last,
    output [OUTPUTS-1:0][VCHANNELS-1:0]     out_valid,
    input [OUTPUTS-1:0][VCHANNELS-1:0]      out_ready,

    input [INPUTS-1:0][FLIT_WIDTH-1:0]      in_flit,
    input [INPUTS-1:0]                      in_last,
    input [INPUTS-1:0][VCHANNELS-1:0]       in_valid,
    output [INPUTS-1:0][VCHANNELS-1:0]      in_ready
);

    // The "switch" is just wiring (all logic is in input and
    // output). All inputs generate their requests for the outputs and
    // the output arbitrate between the input requests.

    // The input valid signals are one (or zero) hot and hence share
    // the flit signal.
    wire [INPUTS-1:0][VCHANNELS-1:0][FLIT_WIDTH-1:0] switch_in_flit;
    wire [INPUTS-1:0][VCHANNELS-1:0]                 switch_in_last;
    wire [INPUTS-1:0][VCHANNELS-1:0][OUTPUTS-1:0]    switch_in_valid;
    wire [INPUTS-1:0][VCHANNELS-1:0][OUTPUTS-1:0]    switch_in_ready;

    // Outputs are fully wired to receive all input requests.
    wire [OUTPUTS-1:0][VCHANNELS-1:0][INPUTS-1:0][FLIT_WIDTH-1:0] switch_out_flit;
    wire [OUTPUTS-1:0][VCHANNELS-1:0][INPUTS-1:0]                 switch_out_last;
    wire [OUTPUTS-1:0][VCHANNELS-1:0][INPUTS-1:0]                 switch_out_valid;
    wire [OUTPUTS-1:0][VCHANNELS-1:0][INPUTS-1:0]                 switch_out_ready;

    genvar                                                        i, v, o;
    generate
        for (i = 0; i < INPUTS; i++) begin : inputs
         // The input stages
         //处理入站数据，根据路由策略（由 ROUTES 参数指定）决定将数据发送到哪个输出端口。
            noc_router_input 
            #(
                .FLIT_WIDTH(FLIT_WIDTH), 
                .DESTS(DESTS),
                .X(X),
                .Y(Y),
                .OUTPUTS(OUTPUTS), 
                .ROUTES(ROUTES),    
                .BUFFER_DEPTH (BUFFER_SIZE_IN)
            )
            U_input
            (   
                .*,
                .in_flit   (in_flit[i]),
                .in_last   (in_last[i]),
                .in_valid  (in_valid[i]),
                .in_ready  (in_ready[i]),
                .out_flit  (switch_in_flit[i]),
                .out_last  (switch_in_last[i]),
                .out_valid (switch_in_valid[i]),
                .out_ready (switch_in_ready[i])
            );
        end // block: inputs

        // The switching logic
        //数据在输入到输出的转换过程中通过交换逻辑。将输入端的数据分配到正确的输出端，基于输入端提供的有效信号和输出端的就绪信号。
        for (o = 0; o < OUTPUTS; o++) begin
            for (v = 0; v < VCHANNELS; v++) begin
                for (i = 0; i < INPUTS; i++) begin
                    assign switch_out_flit[o][v][i] = switch_in_flit[i][v];
                    assign switch_out_last[o][v][i] = switch_in_last[i][v];
                    assign switch_out_valid[o][v][i] = switch_in_valid[i][v][o];
                    assign switch_in_ready[i][v][o] = switch_out_ready[o][v][i];
                end
            end
        end

        //输出阶段：从交换逻辑接收数据，并将其发送到目标输出端口。
        for (o = 0; o < OUTPUTS; o++) begin :  outputs
            // The output stages
            noc_router_output
            #(
                .FLIT_WIDTH(FLIT_WIDTH), 
                .INPUTS(INPUTS), 
                .BUFFER_DEPTH(BUFFER_SIZE_OUT)
            )
            U_output
            (   
                .*,
                .in_flit   (switch_out_flit[o]),
                .in_last   (switch_out_last[o]),
                .in_valid  (switch_out_valid[o]),
                .in_ready  (switch_out_ready[o]),
                .out_flit  (out_flit[o]),
                .out_last  (out_last[o]),
                .out_valid (out_valid[o]),
                .out_ready (out_ready[o])
            );
        end
    endgenerate
endmodule // noc_router
