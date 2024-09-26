module sram8x16(
    input                   CLK,
    input                   ME,
    input                   WE,
    input   [2:0]           A,
    input   [15:0]          D,
    output  logic   [15:0]  Q,
    input   [15:0]          WEM
);

reg [7:0][15:0] tag_ram = 'b0;

always @(posedge CLK) begin
    if(ME & WE)
        tag_ram[A] <= D;
end

always @(posedge CLK) begin
    if(ME & ~WE)
        Q <= tag_ram[A];
end

endmodule