module multi_ctrl_fwd_pipe
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

reg [1:0]       valid_r;
reg[DATA_W-1:0] data_r;

always@(posedge clk or negedge rst_n) begin
    if(~rst_n)
        valid_r <= 2'b0;
    else if(~(|f_valid_in) & (|(b_ready_in & valid_r)))
        valid_r <= 2'b0;
    else if(|f_valid_in)
        valid_r <= f_valid_in;
end

always@(posedge clk or negedge rst_n) begin
    if(~rst_n)
        data_r <= {DATA_W{1'b0}};
    else if(f_valid_in & f_ready_out)
        data_r <= f_data_in;
end

assign b_valid_out    = valid_r;
assign b_data_out     = data_r;
assign f_ready_out    = (|(b_ready_in & valid_r)) | ~(|b_valid_out);

endmodule
