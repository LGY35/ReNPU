module noc_mux
#(
    parameter FLIT_WIDTH        = 32,
    parameter CHANNELS          = 2
)
(
    input                                   clk, 
    input                                   rst_n,

    input [CHANNELS-1:0][FLIT_WIDTH-1:0]    in_flit,
    input [CHANNELS-1:0]                    in_last,
    input [CHANNELS-1:0]                    in_valid,
    output reg [CHANNELS-1:0]               in_ready,

    output reg [FLIT_WIDTH-1:0]             out_flit,
    output reg                              out_last,
    output reg                              out_valid,
    input                                   out_ready
);

    wire [CHANNELS-1:0]                     select;
    reg [CHANNELS-1:0]                      active;

    reg                                     activeroute, nxt_activeroute;

    wire [CHANNELS-1:0]                     req_masked;
    assign req_masked = {CHANNELS{~activeroute & out_ready}} & in_valid;

    always @(*) begin
        out_flit = {FLIT_WIDTH{1'b0}};
        out_last = 1'b0;
        for (int c = 0; c < CHANNELS; c = c + 1) begin
            if (select[c]) begin
                out_flit = in_flit[c];
                out_last = in_last[c];
            end
        end
    end

    always @(*) begin
        nxt_activeroute = activeroute;
        in_ready = {CHANNELS{1'b0}};

        if (activeroute) begin
            if (|(in_valid & active) && out_ready) begin
                in_ready = active;
                out_valid = 1;
                if (out_last)
                    nxt_activeroute = 0;
            end 
            else begin
                out_valid = 1'b0;
                in_ready = 0;
            end
        end 
        else begin
            out_valid = 0;
            if (|in_valid && out_ready) begin
                out_valid = 1'b1;
                nxt_activeroute = ~out_last;
                in_ready = select;
            end
        end
    end // always @ (*)

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            activeroute <= 0;
            active <= {{CHANNELS-1{1'b0}},1'b1};
        end 
        else begin
            activeroute <= nxt_activeroute;
            active <= select;
        end
    end

    arb_rr
    #(
        .N(CHANNELS)
    )
    U_arb
    (    
        .nxt_gnt    (select),
        .req        (req_masked),
        .gnt        (active),
        .en         (1'b1)
    );

endmodule // noc_mux
