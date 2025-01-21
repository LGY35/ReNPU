module std_tpram32x32 (
    input RCLK,
    input RCEB,
    input [4:0] RADDR,
    output reg [31:0] RDATA,
    input WCLK,
    input [4:0] WADDR,
    input WCEB,
    input [31:0] WDATA
    
);

reg [31:0] sram_sim [31:0];

always @(posedge WCLK) begin
    if(!WCEB) begin
        sram_sim[WADDR] <= WDATA;
    end
end

always @(posedge RCLK) begin
    if(!RCEB)
      RDATA <= sram_sim[RADDR];
end

endmodule