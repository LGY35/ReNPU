module noc_router_lookup_slice#(
    parameter FLIT_WIDTH = 32,
    parameter OUTPUTS = 1
)
(
    input                       clk,
    input                       rst_n,

    input [FLIT_WIDTH-1:0]      in_flit,
    input                       in_last,
    input [OUTPUTS-1:0]         in_valid,
    output                      in_ready,

    output reg [OUTPUTS-1:0]    out_valid,
    output reg                  out_last,
    output reg [FLIT_WIDTH-1:0] out_flit,
    input [OUTPUTS-1:0]         out_ready
);

    // This is an intermediate register that we use to avoid
    // stop-and-go behavior
    reg [FLIT_WIDTH-1:0]         reg_flit;
    reg                          reg_last;
    reg [OUTPUTS-1:0]            reg_valid;

    // This signal selects where to store the next incoming flit
    reg                          pressure;

    // A backpressure in the output port leads to backpressure on the
    // input with one cycle delay
    assign in_ready = !pressure;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pressure <= 0;
            out_valid <= 0;
        end 
        else begin
            if (!pressure) begin
                // We are accepting the input in this cycle, determine
                // where to store it..
                if (// There is no flit waiting in the register, or
                    ~|out_valid
                    // The current flit is transfered this cycle
                    | (|(out_ready & out_valid))) begin
                    out_valid <= in_valid;
                end else if (|out_valid & ~|out_ready) begin
                    // Otherwise if there is a flit waiting and upstream
                    // not ready, push it to the second register. Enter the
                    // backpressure mode.
                    reg_valid <= in_valid;
                    pressure <= 1;
                end
            end 
            else begin // if (!pressure)
                // We can be sure that a flit is waiting now (don't need
                // to check)
                if (|out_ready) begin
                    // If the output accepted this flit, go back to
                    // accepting input flits.
                    out_valid <= reg_valid;
                    pressure <= 0;
                end
            end
        end
    end

    always_ff @(posedge clk) begin
        if (!pressure) begin
            // We are accepting the input in this cycle, determine
            // where to store it..
            if (// There is no flit waiting in the register, or
                ~|out_valid
                // The current flit is transfered this cycle
                | (|(out_ready & out_valid))) begin
                out_flit <= in_flit;
                out_last <= in_last;
            end else if (|out_valid & ~|out_ready) begin
                // Otherwise if there is a flit waiting and upstream
                // not ready, push it to the second register. Enter the
                // backpressure mode.
                reg_flit <= in_flit;
                reg_last <= in_last;
            end
        end 
        else begin // if (!pressure)
            // We can be sure that a flit is waiting now (don't need
            // to check)
            if (|out_ready) begin
                // If the output accepted this flit, go back to
                // accepting input flits.
                out_flit <= reg_flit;
                out_last <= reg_last;
            end
        end
    end

endmodule // noc_router_lookup_slice
