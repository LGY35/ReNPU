module dnoc_itf_pingpong(
    input                   clk,
    input                   rst_n,

    input                   pingpong_rd_done,
    input                   pingpong_wr_done,

    output  logic   [1:0]   pingpong_state
);

logic rd_ptr, wr_ptr;

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        rd_ptr <= 'b0;
    end
    else if(pingpong_rd_done) begin
        rd_ptr <= ~rd_ptr;
    end
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        wr_ptr <= 'b0;
    end
    else if(pingpong_wr_done) begin
        wr_ptr <= ~wr_ptr;
    end
end

integer i;

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        pingpong_state <= 'b0;
    end
    else begin
        for(i = 0; i < 2; i = i + 1) begin
            if(pingpong_wr_done & (wr_ptr == i)) begin
                pingpong_state[i] <= 1'b1;
            end
            else if(pingpong_rd_done & (rd_ptr == i)) begin
                pingpong_state[i] <= 1'b0;
            end
        end
    end
end

endmodule