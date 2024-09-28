module noc_router_lookup_m
#(    
    parameter FLIT_WIDTH                    = 32,
    parameter ID_WIDTH                      = 4,
    parameter DESTS                         = 16,
    parameter OUTPUTS                       = 5,
    parameter X                             = 2'd0,
    parameter Y                             = 2'd0,
    parameter [DESTS*OUTPUTS-1:0] ROUTES    = {DESTS*OUTPUTS{1'b0}}
)
(
    input                           clk,
    input                           rst_n,

    input       [FLIT_WIDTH-1:0]    in_flit,
    input                           in_last,
    input                           in_valid,
    output                          in_ready,

    output      [OUTPUTS-1:0]       out_valid,
    output                          out_last,
    output  reg [FLIT_WIDTH-1:0]    out_flit,
    input                           out_ready
);

    localparam IDLE = 1'b0;
    localparam WORM = 1'b1;

    localparam [3:0] NODE_ID = {Y, X};

    localparam LOCAL = 0;
    localparam NORTH = 1;
    localparam EAST  = 2;
    localparam SOUTH = 3;
    localparam WEST  = 4;
    // We need to track worms and directly encode the output of the
    // current worm.
    reg [OUTPUTS-1:0]       worm;
    logic [OUTPUTS-1:0]     nxt_worm;
    // This is high if we are in a worm
    logic                   wormhole;
    assign wormhole = |worm;

    // Extract unicast destination from flit
    logic [ID_WIDTH-1:0]    dest;
    assign dest = in_flit[0 +: ID_WIDTH];

    // Extract multicast destination from flit
    logic [ID_WIDTH-1:0] central_node;
    assign central_node = dest;
    //order is n e s w
    logic [1:0] north_id, east_id, south_id, west_id;
    assign north_id = in_flit[ID_WIDTH +: 2];
    assign east_id = in_flit[ID_WIDTH+2 +: 2];
    assign south_id = in_flit[ID_WIDTH+4 +: 2];
    assign west_id = in_flit[ID_WIDTH+6 +: 2];

    // This is the selection signal of the slave, one hot so that it
    // directly serves as flow control valid
    logic [OUTPUTS-1:0]        valid;

    assign out_valid = valid;
    assign out_last = in_last;
    assign in_ready = out_ready;

    always_comb begin
        nxt_worm = worm;
        valid = 'b0;
        out_flit = in_flit;

        if (!wormhole) begin
            // We are waiting for a flit
            if (in_valid) begin
                // This is a header. Lookup output
                if(~in_flit[FLIT_WIDTH-1])begin
                    if(NODE_ID == central_node)begin
                        valid[LOCAL] = 1'b1;
                        out_flit = {~in_flit[FLIT_WIDTH-1], in_flit[FLIT_WIDTH-2:12] ,in_flit[11:0]};
                        if(Y != north_id)
                            valid[NORTH] = 1'b1;
                        if(Y != south_id) 
                            valid[SOUTH] = 1'b1;
                        if(X != east_id) 
                            valid[EAST] = 1'b1;
                        if(X != west_id) 
                            valid[WEST] = 1'b1;
                    end
                    else begin
                        valid = ROUTES[dest*OUTPUTS +: OUTPUTS];
                    end
                end
                else begin
                    valid[LOCAL] = 1'b1;
                    if(Y != central_node[3:2])begin
                        if((Y > central_node[3:2]) & (Y < north_id))begin
                            valid[NORTH] = 1'b1;
                        end
                        else if((Y < central_node[3:2]) & (Y > south_id)) begin
                            valid[SOUTH] = 1'b1;
                        end
                    end
                    else begin
                        if(Y != north_id) 
                            valid[NORTH] = 1'b1;
                        if(Y != south_id) 
                            valid[SOUTH] = 1'b1;
                        if((X > central_node[1:0]) & (X < east_id))
                            valid[EAST] = 1'b1;
                        if((X < central_node[1:0]) & (X > west_id))
                            valid[WEST] = 1'b1;
                    end
                end
            end
                
            if (in_ready & !in_last) begin
                // If we can push it further and it is not the only
                // flit, enter a worm and store the output
                nxt_worm = valid;
            end
        end
        else begin // if (!wormhole)
            // We are in a worm
            // The valid is set on the currently select output
            valid = worm & {OUTPUTS{in_valid}};
            if (in_valid & in_ready & in_last) begin
                // End of worm
                nxt_worm = 'b0;
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            worm <= 'b0;
        end else begin
            worm <= nxt_worm;
        end
    end

    

endmodule
