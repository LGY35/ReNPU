module ram_req_fifo(
    input                   clk,    // Clock input
    input                   rst_n,   // Active low reset

    input                   push,
    input           [1:0]   in_data,
    output  logic           full,

    input                   pop,
    output  logic   [1:0]   out_data,
    output  logic           empty
);

// Add your logic here

logic [15:0][1:0] ram;
logic [4:0] wr_ptr, rd_ptr;

assign full = (wr_ptr[3:0] == rd_ptr[3:0]) & (wr_ptr[4] ^ rd_ptr[4]);
assign empty = (wr_ptr == rd_ptr);

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        rd_ptr <= 'd0;
    end
    else if(~empty & pop) begin
        rd_ptr <= rd_ptr + 5'd1;
    end
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        wr_ptr <= 'd0;
    end
    else if(~full & push) begin
        wr_ptr <= wr_ptr + 5'd1;
    end
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        ram <= 'd0;
    end
    else if(~full & push) begin
        ram[wr_ptr[3:0]] <= in_data;
    end
end

assign out_data = ram[rd_ptr[3:0]];

endmodule