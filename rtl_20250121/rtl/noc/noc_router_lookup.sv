module noc_router_lookup #(
    parameter FLIT_WIDTH = 32,
    parameter DEST_WIDTH = 4,
    parameter DESTS = 1,
    parameter OUTPUTS = 1,
    parameter [DESTS*OUTPUTS-1:0] ROUTES = {DESTS*OUTPUTS{1'b0}}
)
(
    input                   clk,
    input                   rst_n,

    input [FLIT_WIDTH-1:0]  in_flit,
    input                   in_last,
    input                   in_valid,
    output                  in_ready,

    output [OUTPUTS-1:0]    out_valid,
    output                  out_last,
    output [FLIT_WIDTH-1:0] out_flit,
    input [OUTPUTS-1:0]     out_ready
);

    // We need to track worms and directly encode the output of the
    // current worm.
    reg [OUTPUTS-1:0]        worm;
    logic [OUTPUTS-1:0]      nxt_worm;
    // This is high if we are in a worm
    logic                    wormhole;
    assign wormhole = |worm;

    // Extract destination from flit
    logic [DEST_WIDTH-1:0]   dest;
    assign dest = in_flit[0 +: DEST_WIDTH];

    // This is the selection signal of the slave, one hot so that it
    // directly serves as flow control valid
    logic [OUTPUTS-1:0]      valid;

    // Register slice at the output.
    noc_router_lookup_slice
    #(
        .FLIT_WIDTH (FLIT_WIDTH),
        .OUTPUTS    (OUTPUTS)
    )
    U_slice
    (
        .*,
        .in_valid (valid)
    );

    always_comb begin
        nxt_worm = worm;
        valid = 0;

        if (!wormhole) begin
            // We are waiting for a flit
            if (in_valid) begin
                // This is a header. Lookup output
                valid = ROUTES[dest*OUTPUTS +: OUTPUTS];
                if (in_ready & !in_last) begin
                    // If we can push it further and it is not the only
                    // flit, enter a worm and store the output
                    nxt_worm = ROUTES[dest*OUTPUTS +: OUTPUTS];
                end
            end
        end 
        else begin // if (!wormhole)
            // We are in a worm
            // The valid is set on the currently select output
            valid = worm & {OUTPUTS{in_valid}};
            if (in_ready & in_last) begin
                // End of worm
                nxt_worm = 0;
            end
        end
    end

   always_ff @(posedge clk) begin
        if (rst_n) begin
            worm <= 'b0;
        end 
        else begin
            worm <= nxt_worm;
        end
   end

endmodule
