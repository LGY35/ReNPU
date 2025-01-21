module fwd_clr_pipe
#(
parameter   DATA_W = 256
)(
input                   clk,rst_n,clr,
//from/to master
input                   f_valid_in,
input   [DATA_W-1:0]    f_data_in,
output                  f_ready_out,
//from/to slave
output                  b_valid_out,
output  [DATA_W-1:0]    b_data_out,
input                   b_ready_in
);

reg             valid_r;
reg[DATA_W-1:0] data_r;

always@(posedge clk or negedge rst_n) begin
    if(~rst_n)
        valid_r <= 1'b0;
    else if(clr)
        valid_r <= 1'b0;
    else if(~f_valid_in & b_ready_in)
        valid_r <= 1'b0;
    else if(f_valid_in)
        valid_r <= 1'b1;
end

always@(posedge clk or negedge rst_n) begin
    if(~rst_n)
        data_r <= {DATA_W{1'b0}};
    else if(clr)
        data_r <= {DATA_W{1'b0}};
    else if(f_valid_in & f_ready_out)
        data_r <= f_data_in;
end

assign b_valid_out    = valid_r;
assign b_data_out     = data_r;
assign f_ready_out    = b_ready_in | ~b_valid_out;

endmodule
