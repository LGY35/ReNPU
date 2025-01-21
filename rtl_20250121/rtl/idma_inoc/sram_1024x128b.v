module sram_1024x128b (
    input clk,
    input cen,
    input wen,
    input [9:0] addr,
    input [127:0] wdata,
    input [15:0] wstrb,
    output reg [127:0] rdata
);

reg [127:0] sram_sim [1023:0];
wire [127:0] bits_to_write;

assign bits_to_write = 
    {
        {8{wstrb[15]}},
        {8{wstrb[14]}},
        {8{wstrb[13]}},
        {8{wstrb[12]}},
        {8{wstrb[11]}},
        {8{wstrb[10]}},
        {8{wstrb[9]}},
        {8{wstrb[8]}},
        {8{wstrb[7]}},
        {8{wstrb[6]}},
        {8{wstrb[5]}},
        {8{wstrb[4]}},
        {8{wstrb[3]}},
        {8{wstrb[2]}},
        {8{wstrb[1]}},
        {8{wstrb[0]}}
    };

always @(posedge clk) begin
    if(cen && wen) begin
        sram_sim[addr] <= (wdata & bits_to_write) | (sram_sim[addr] & ~bits_to_write);
    end
end

always @(posedge clk) begin
    rdata <= sram_sim[addr];
end

endmodule
