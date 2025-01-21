module Cram_16x128 #(
    parameter CRAM_DEPTH = 16,
    parameter CRAM_WIDTH = 128
)(
    input clk,
    input CE_a,
    input CE_b,
    input WE_a,
    input WE_b,
    input [CRAM_WIDTH-1:0] D,
    input [$clog2(CRAM_DEPTH)-1:0] wr_addr,
    input [$clog2(CRAM_DEPTH)-1:0] rd_addr,
    output reg [CRAM_WIDTH-1:0] Q
);
    wire [CRAM_WIDTH/2-1:0] Qa, Qb;
    wire [$clog2(CRAM_DEPTH)-1:0] addr_a, addr_b;

    assign addr_a = WE_a ? wr_addr : rd_addr;
    assign addr_b = WE_b ? wr_addr : rd_addr;

    std_spram16x64 Cram_16x64_U0 (
        .clk(clk),
        .CEB(~CE_a),
        .WEB(~WE_a),
        .D(D[CRAM_WIDTH/2-1:0]),
        .A(addr_a),
        .Q(Qa)
    );
    std_spram16x64 Cram_16x64_U1 (
        .clk(clk),
        .CEB(~CE_b),
        .WEB(~WE_b),
        .D(D[CRAM_WIDTH-1:CRAM_WIDTH/2]),
        .A(addr_b),
        .Q(Qb)
    );

    always @(posedge clk) begin
        Q <= {Qb, Qa};
    end

endmodule
