module cu_node #(
    parameter NODE_ID       = 4'd0,
    parameter CLUSTER_ID    = 6'd0,
    parameter DMA_ID        = 4'b1101
)
(
    input                           clk,
    input                           rst_n,

    output  logic                   pc_serial_out,

    //noc interface

    input           [256-1:0]       node_out_flit_local,
    input                           node_out_last_local,
    input           [1:0]           node_out_valid_local,
    output  logic   [1:0]           node_out_ready_local,

    output  logic   [256-1:0]       node_in_flit_local,
    output  logic                   node_in_last_local,
    output  logic   [1:0]           node_in_valid_local,
    input           [1:0]           node_in_ready_local,

    //instruction interface
    output  logic   [31:0]          fetch_L2cache_info,
    output  logic                   fetch_L2cache_req,
    input                           fetch_L2cache_gnt,
    input   [31:0]                  fetch_L2cache_r_data,
    input                           fetch_L2cache_r_valid,
    output  logic                   fetch_L2cache_r_ready
);

assign pc_serial_out = 'd0;
assign node_out_ready_local = 'd0;
assign node_in_flit_local = 'd0;
assign node_in_last_local = 'd0;
assign node_in_valid_local = 'd0;

assign fetch_L2cache_info = 'd0;
assign fetch_L2cache_req = 'd0;
assign fetch_L2cache_r_ready = 'd0;

endmodule
