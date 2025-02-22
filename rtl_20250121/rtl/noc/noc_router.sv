module noc_router #(
    parameter FLIT_WIDTH = 32,
    parameter VCHANNELS = 2,
    parameter INPUTS = 5,
    parameter OUTPUTS = 5,
    parameter X = 2'd0,
    parameter Y = 2'd0,
    parameter BUFFER_SIZE_IN = 4,
    parameter BUFFER_SIZE_OUT = 4,
    parameter DESTS = 16,
    parameter [OUTPUTS*DESTS-1:0] ROUTES = {(DESTS*OUTPUTS){1'b0}}
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

    logic [1:0] rst_n_reg;
    logic       rst_n_sync;

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            rst_n_reg <= 2'd0;
        end
        else begin
            rst_n_reg <= {rst_n_reg[0], 1'b1};
        end
    end

    assign rst_n_sync = rst_n_reg[1];

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
                .clk       (clk),
                .rst_n     (rst_n_sync),
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
                .clk       (clk),
                .rst_n     (rst_n_sync),
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
