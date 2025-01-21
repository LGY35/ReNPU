module std_tpram64x288 (
    input RCLK,
    input RCEB,
    input [5:0] RADDR,
    output reg [287:0] RDATA,
    input WCLK,
    input [5:0] WADDR,
    input WCEB,
    input [287:0] WDATA
    
);

reg [287:0] sram_sim [63:0];

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
