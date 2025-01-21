module multi_ctrl_bwd_pipe
#(
parameter   DATA_W = 256
)(
input                   clk,rst_n,
//from/to master
input   [1:0]           f_valid_in,
input   [DATA_W-1:0]    f_data_in,
output  [1:0]           f_ready_out,
//from/to slave
output  [1:0]           b_valid_out,
output  [DATA_W-1:0]    b_data_out,
input   [1:0]           b_ready_in
);

reg              full;
reg [DATA_W-1:0] data_r;

always@(posedge clk or negedge rst_n) begin
    if(~rst_n)
        data_r <= {DATA_W{1'b0}};
    else if(|(f_valid_in & f_ready_out & ~b_ready_in))
        data_r <= f_data_in;
end

always@(posedge clk or negedge rst_n) begin
    if(~rst_n)
        full <= 1'b0;
    else
        full <= |(b_valid_out & ~b_ready_in);
end

assign b_valid_out[0]    = full | (f_valid_in[0] & f_ready_out[0]);
assign b_valid_out[1]    = full | (f_valid_in[1] & f_ready_out[1]);
assign b_data_out     = full ? data_r : f_data_in;
assign f_ready_out    = {2{~full}};

endmodule
