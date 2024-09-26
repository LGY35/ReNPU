module sram128x32(
    input                   CLK,
    input                   ME,
    input                   WE,
    input   [6:0]           A,
    input   [31:0]          D,
    output  logic   [31:0]  Q,
    input   [31:0]          WEM
);

reg [127:0][31:0] data_ram = 'b0;

always @(posedge CLK) begin
    if(ME & WE)
        data_ram[A] <= D;
end

always @(posedge CLK) begin
    if(ME & ~WE)
        Q <= data_ram[A];
end

endmodule
