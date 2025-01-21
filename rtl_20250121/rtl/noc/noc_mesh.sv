module noc_mesh #(
    parameter FLIT_WIDTH = 32,
    parameter CHANNELS = 2,
    parameter X = 4,
    parameter Y = 4,
    parameter BUFFER_SIZE_IN = 4,
    parameter BUFFER_SIZE_OUT = 4,
    localparam NODES = X*Y
)
(
    input                                               clk, 
    input                                               rst_n,

    input   [NODES-1:0][FLIT_WIDTH-1:0]                 node_in_flit_local,
    input   [NODES-1:0]                                 node_in_last_local,
    input   [NODES-1:0][CHANNELS-1:0]                   node_in_valid_local,
    output  [NODES-1:0][CHANNELS-1:0]                   node_in_ready_local,

    output  [NODES-1:0][FLIT_WIDTH-1:0]                 node_out_flit_local,
    output  [NODES-1:0]                                 node_out_last_local,
    output  [NODES-1:0][CHANNELS-1:0]                   node_out_valid_local,
    input   [NODES-1:0][CHANNELS-1:0]                   node_out_ready_local
);
    
    // Those are indexes into the wiring arrays
    localparam LOCAL = 0;
    localparam NORTH = 1;
    localparam EAST  = 2;
    localparam SOUTH = 3;
    localparam WEST  = 4;

    // Those are direction codings that match the wiring indices
    // above. The router is configured to use those to select the
    // proper output port.
    localparam DIR_LOCAL = 5'b00001;
    localparam DIR_NORTH = 5'b00010;
    localparam DIR_EAST  = 5'b00100;
    localparam DIR_SOUTH = 5'b01000;
    localparam DIR_WEST  = 5'b10000;

    // Number of physical channels between routers. This is essentially
    // the number of flits (and last) between the routers.
    localparam PCHANNELS = 1;

    genvar                                           c, p, x, y;

    generate
        // With virtual channels, we generate one router per node and
        // then add a virtual channel muxer between the tiles and the
        // local router input. On the output the "demux" is plain
        // wiring.

        // Arrays of wires between the routers. Each router has a
        // pair of NoC wires per direction and below those are hooked
        // up.
        wire [4:0][PCHANNELS-1:0][FLIT_WIDTH-1:0]     node_in_flit [0:NODES-1];
        wire [4:0][PCHANNELS-1:0]                     node_in_last [0:NODES-1];
        wire [4:0][CHANNELS-1:0]                      node_in_valid [0:NODES-1];
        wire [4:0][CHANNELS-1:0]                      node_in_ready [0:NODES-1];
        wire [4:0][PCHANNELS-1:0][FLIT_WIDTH-1:0]     node_out_flit [0:NODES-1];
        wire [4:0][PCHANNELS-1:0]                     node_out_last [0:NODES-1];
        wire [4:0][CHANNELS-1:0]                      node_out_valid [0:NODES-1];
        wire [4:0][CHANNELS-1:0]                      node_out_ready [0:NODES-1];

        for (y = 0; y < Y; y++) begin : ydir
            for (x = 0; x < X; x++) begin : xdir
                // noc_vchannel_mux
                // #(
                //     //.CHANNELS   (CHANNELS),
                //     .FLIT_WIDTH (FLIT_WIDTH)
                // )
                // u_vc_mux
                // (
                //     .*,
                //     .in_flit   (in_flit[nodenum(x,y)]),
                //     .in_last   (in_last[nodenum(x,y)]),
                //     .in_valid  (in_valid[nodenum(x,y)]),
                //     .in_ready  (in_ready[nodenum(x,y)]),
                //     .out_flit  (node_in_flit[nodenum(x,y)][LOCAL][0]),
                //     .out_last  (node_in_last[nodenum(x,y)][LOCAL][0]),
                //     .out_valid (node_in_valid[nodenum(x,y)][LOCAL]),
                //     .out_ready (node_in_ready[nodenum(x,y)][LOCAL])
                // );

                // // Replicate the flit to all output channels and the
                // // rest is just wiring
                // for (c = 0; c < CHANNELS; c++) begin : flit_demux
                //     assign out_flit[nodenum(x,y)][c] = node_out_flit[nodenum(x,y)][LOCAL][0];
                //     assign out_last[nodenum(x,y)][c] = node_out_last[nodenum(x,y)][LOCAL][0];
                // end
                // assign out_valid[nodenum(x,y)] = node_out_valid[nodenum(x,y)][LOCAL];
                // assign node_out_ready[nodenum(x,y)][LOCAL] = out_ready[nodenum(x,y)];

                // Instantiate the router. We call a function to
                // generate the routing table
                assign node_in_flit[nodenum(x,y)][LOCAL][0] = node_in_flit_local[nodenum(x,y)];
                assign node_in_last[nodenum(x,y)][LOCAL][0] = node_in_last_local[nodenum(x,y)];
                assign node_in_valid[nodenum(x,y)][LOCAL] = node_in_valid_local[nodenum(x,y)];
                assign node_in_ready_local[nodenum(x,y)] = node_in_ready[nodenum(x,y)][LOCAL];

                assign node_out_flit_local[nodenum(x,y)] = node_out_flit[nodenum(x,y)][LOCAL][0];
                assign node_out_last_local[nodenum(x,y)] = node_out_last[nodenum(x,y)][LOCAL][0];
                assign node_out_valid_local[nodenum(x,y)] = node_out_valid[nodenum(x,y)][LOCAL];
                assign node_out_ready[nodenum(x,y)][LOCAL] = node_out_ready_local[nodenum(x,y)];

                noc_router
                #(
                    .FLIT_WIDTH (FLIT_WIDTH),
                    .VCHANNELS  (CHANNELS),
                    .INPUTS     (5),
                    .OUTPUTS    (5),
                    .X          (x[1:0]),
                    .Y          (y[1:0]),
                    .BUFFER_SIZE_IN (BUFFER_SIZE_IN),
                    .BUFFER_SIZE_OUT (BUFFER_SIZE_OUT),
                    .DESTS      (NODES),
                    .ROUTES     (genroutes(x,y))
                )
                u_router
                (
                    .*,
                    .in_flit   (node_in_flit[nodenum(x,y)]),
                    .in_last   (node_in_last[nodenum(x,y)]),
                    .in_valid  (node_in_valid[nodenum(x,y)]),
                    .in_ready  (node_in_ready[nodenum(x,y)]),
                    .out_flit  (node_out_flit[nodenum(x,y)]),
                    .out_last  (node_out_last[nodenum(x,y)]),
                    .out_valid (node_out_valid[nodenum(x,y)]),
                    .out_ready (node_out_ready[nodenum(x,y)])
                );

                // The following are all the connections of the routers
                // in the four directions. If the router is on an outer
                // border, tie off.
                if (y > 0) begin
                    assign node_in_flit[nodenum(x,y)][SOUTH] = node_out_flit[southof(x,y)][NORTH];
                    assign node_in_last[nodenum(x,y)][SOUTH] = node_out_last[southof(x,y)][NORTH];
                    assign node_in_valid[nodenum(x,y)][SOUTH] = node_out_valid[southof(x,y)][NORTH];
                    assign node_out_ready[nodenum(x,y)][SOUTH] = node_in_ready[southof(x,y)][NORTH];
                    end else begin
                    assign node_in_flit[nodenum(x,y)][SOUTH] = '0;
                    assign node_in_last[nodenum(x,y)][SOUTH] = '0;
                    assign node_in_valid[nodenum(x,y)][SOUTH] = 0;
                    assign node_out_ready[nodenum(x,y)][SOUTH] = 0;
                end

                if (y < Y-1) begin
                    assign node_in_flit[nodenum(x,y)][NORTH] = node_out_flit[northof(x,y)][SOUTH];
                    assign node_in_last[nodenum(x,y)][NORTH] = node_out_last[northof(x,y)][SOUTH];
                    assign node_in_valid[nodenum(x,y)][NORTH] = node_out_valid[northof(x,y)][SOUTH];
                    assign node_out_ready[nodenum(x,y)][NORTH] = node_in_ready[northof(x,y)][SOUTH];
                    end else begin
                    assign node_in_flit[nodenum(x,y)][NORTH] = '0;
                    assign node_in_last[nodenum(x,y)][NORTH] = '0;
                    assign node_in_valid[nodenum(x,y)][NORTH] = 0;
                    assign node_out_ready[nodenum(x,y)][NORTH] = 0;
                end

                if (x > 0) begin
                    assign node_in_flit[nodenum(x,y)][WEST] = node_out_flit[westof(x,y)][EAST];
                    assign node_in_last[nodenum(x,y)][WEST] = node_out_last[westof(x,y)][EAST];
                    assign node_in_valid[nodenum(x,y)][WEST] = node_out_valid[westof(x,y)][EAST];
                    assign node_out_ready[nodenum(x,y)][WEST] = node_in_ready[westof(x,y)][EAST];
                    end else begin
                    assign node_in_flit[nodenum(x,y)][WEST] = '0;
                    assign node_in_last[nodenum(x,y)][WEST] = '0;
                    assign node_in_valid[nodenum(x,y)][WEST] = 0;
                    assign node_out_ready[nodenum(x,y)][WEST] = 0;
                end

                if (x < X-1) begin
                    assign node_in_flit[nodenum(x,y)][EAST] = node_out_flit[eastof(x,y)][WEST];
                    assign node_in_last[nodenum(x,y)][EAST] = node_out_last[eastof(x,y)][WEST];
                    assign node_in_valid[nodenum(x,y)][EAST] = node_out_valid[eastof(x,y)][WEST];
                    assign node_out_ready[nodenum(x,y)][EAST] = node_in_ready[eastof(x,y)][WEST];
                    end else begin
                    assign node_in_flit[nodenum(x,y)][EAST] = '0;
                    assign node_in_last[nodenum(x,y)][EAST] = '0;
                    assign node_in_valid[nodenum(x,y)][EAST] = 0;
                    assign node_out_ready[nodenum(x,y)][EAST] = 0;
                end
            end
        end
    endgenerate

    // Get the node number
    function integer nodenum(input integer x,input integer y);
        nodenum = x+y*X;
    endfunction // nodenum

    // Get the node north of position
    function integer northof(input integer x,input integer y);
        northof = x+(y+1)*X;
    endfunction // northof

    // Get the node east of position
    function integer eastof(input integer x,input integer y);
        eastof  = (x+1)+y*X;
    endfunction // eastof

    // Get the node south of position
    function integer southof(input integer x,input integer y);
        southof = x+(y-1)*X;
    endfunction // southof

    // Get the node west of position
    function integer westof(input integer x,input integer y);
        westof = (x-1)+y*X;
    endfunction // westof

    // This generates the lookup table for each individual node
    function [NODES-1:0][4:0] genroutes(input integer x, input integer y);
        integer yd,xd;
        integer nd;
        reg [4:0] d;

        genroutes = {NODES{5'b00000}};

        for (yd = 0; yd < Y; yd++) begin
            for (xd = 0; xd < X; xd++) begin : inner_loop
                nd = nodenum(xd,yd);
                d = 5'b00000;
                if ((xd==x) && (yd==y)) begin
                    d = DIR_LOCAL;
                end 
                else if (xd==x) begin
                    if (yd<y) begin
                        d = DIR_SOUTH;
                    end else begin
                        d = DIR_NORTH;
                    end
                end 
                else begin
                    if (xd<x) begin
                        d = DIR_WEST;
                    end else begin
                        d = DIR_EAST;
                    end
                end // else: !if(xd==x)
                genroutes[nd] = d;
            end
        end
    endfunction


endmodule // mesh
