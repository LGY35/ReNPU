module noc_router_output #(
    parameter FLIT_WIDTH = 256,
    parameter INPUTS = 5,
    parameter BUFFER_DEPTH = 4
)
(
    input                                           clk,
    input                                           rst_n,

    input   [1:0][INPUTS-1:0][FLIT_WIDTH-1:0]       in_flit,
    input   [1:0][INPUTS-1:0]                       in_last,
    input   [1:0][INPUTS-1:0]                       in_valid,
    output  [1:0][INPUTS-1:0]                       in_ready,

    output  [FLIT_WIDTH-1:0]                        out_flit,
    output                                          out_last,
    output  [1:0]                                   out_valid,
    input   [1:0]                                   out_ready
);

   genvar                                             v;

   wire [1:0][FLIT_WIDTH-1:0]               channel_flit;
   wire [1:0]                               channel_last;
   wire [1:0]                               channel_valid;
   wire [1:0]                               channel_ready;

    generate
        for (v = 0; v < 2; v = v+1) begin:ROUTER_OUTPUT_BANK
            wire [FLIT_WIDTH-1:0] buffer_flit;
            wire                  buffer_last;
            wire                  buffer_valid;
            wire                  buffer_ready;

            noc_mux
            #(
                .FLIT_WIDTH (FLIT_WIDTH), 
                .CHANNELS (INPUTS)
            )
            U_mux
            (.*,
                .in_flit   (in_flit[v]),
                .in_last   (in_last[v]),
                .in_valid  (in_valid[v]),
                .in_ready  (in_ready[v]),
                .out_flit  (buffer_flit),
                .out_last  (buffer_last),
                .out_valid (buffer_valid),
                .out_ready (buffer_ready)
            );

            noc_buffer
            #(
                .FLIT_WIDTH (FLIT_WIDTH), 
                .DEPTH(BUFFER_DEPTH)
            )
            U_buffer
            (
                .*,
                .in_flit     (buffer_flit),
                .in_last     (buffer_last),
                .in_valid    (buffer_valid),
                .in_ready    (buffer_ready),
                .out_flit    (channel_flit[v]),
                .out_last    (channel_last[v]),
                .out_valid   (channel_valid[v]),
                .out_ready   (channel_ready[v])
            );
        end // for (v = 0; v < 2; v++)

        noc_vchannel_mux
        #(
            .FLIT_WIDTH (FLIT_WIDTH)
        )
        U_vmux
        (
            .*,
            .in_flit  (channel_flit),
            .in_last  (channel_last),
            .in_valid (channel_valid),
            .in_ready (channel_ready)
        );
    endgenerate

endmodule // noc_router_output
