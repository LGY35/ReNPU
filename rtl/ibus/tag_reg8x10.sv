module tag_reg8x10(
    input                   CLK,
    input                   ME,
    input                   WE,
    input   [2:0]           A,
    input   [9:0]           D,
    output  logic   [9:0]   Q
    // input   [15:0]          WEM
);

logic [7:0][9:0] tag_ram = 'b0;

always @(posedge CLK) begin
    if(ME & WE)
        tag_ram[A] <= D;
end

always @(posedge CLK) begin
    if(ME & ~WE)
        Q <= tag_ram[A];
end

endmodule