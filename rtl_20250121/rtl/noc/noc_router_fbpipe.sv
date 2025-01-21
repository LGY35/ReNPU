/* 
 * =============================================================================
 * forward-backward pipeline
 */

module noc_router_fbpipe #(
    parameter DATA_WIDTH = 256,
    parameter OUTPUTS = 5
)
(
    input                               clk,
    input                               rst_n,
    input   [DATA_WIDTH-1:0]            in_data,
    input   [OUTPUTS-1:0]               in_valid,
    output                              in_ready,
    
    output  reg     [OUTPUTS-1:0]       out_valid,
    output  reg     [DATA_WIDTH-1:0]    out_data,
    input           [OUTPUTS-1:0]       out_ready
);

    // This is an intermediate register that we use to avoid
    // stop-and-go behavior
    reg [DATA_WIDTH-1:0]                reg_data;
    reg [OUTPUTS-1:0]                   reg_valid;
    // This signal selects where to store the next incoming flit
    reg                                 pressure;

    // A backpressure in the output port leads to backpressure on the
    // input with one cycle delay
    assign in_ready = !pressure;

    //control signals with async rstn
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pressure <= 'b0;
            out_valid <= 'b0;
        end 
        else begin
            if (!pressure) begin
                // We are accepting the input in this cycle, determine
                // where to store it..
                if (// There is no flit waiting in the register, or
                    (~|out_valid)
                    // The current flit is transfered this cycle
                    | (out_ready == out_valid)) begin
                    out_valid <= in_valid;
                end else if (out_valid != out_ready) begin
                    // Otherwise if there is a flit waiting and upstream
                    // not ready, push it to the second register. Enter the
                    // backpressure mode.
                    if(|in_valid)begin
                        reg_valid <= in_valid;
                        pressure <= 1'b1;
                    end
                end
            end 
            else begin // if (!pressure)
                // We can be sure that a flit is waiting now (don't need
                // to check)
                if (out_ready == out_valid) begin
                    // If the output accepted this flit, go back to
                    // accepting input flits.
                    out_valid <= reg_valid;
                    pressure <= 1'b0;
                end
            end
        end
    end

    always_ff @(posedge clk) begin
        if (!pressure) begin
            // We are accepting the input in this cycle, determine
            // where to store it..
            if (// There is no flit waiting in the register, or
                (~|out_valid)
                // The current flit is transfered this cycle
                | (out_ready == out_valid)) begin
                out_data <= in_data;
            end 
            else if (out_valid != out_ready) begin
                // Otherwise if there is a flit waiting and upstream
                // not ready, push it to the second register. Enter the
                // backpressure mode.
                if(|in_valid)begin
                    reg_data <= in_data;
                end
            end
        end 
        else begin // if (!pressure)
            // We can be sure that a flit is waiting now (don't need
            // to check)
            if (out_ready == out_valid) begin
                // If the output accepted this flit, go back to
                // accepting input flits.
                out_data <= reg_data;
            end
        end
    end



endmodule // noc_router_fbpipe
