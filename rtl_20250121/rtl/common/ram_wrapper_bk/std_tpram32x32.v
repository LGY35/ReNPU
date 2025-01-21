module std_tpram32x32 (
    input RCLK,
    input RCEB,
    input [4:0] RADDR,
    `ifdef FPGA
        output reg [31:0] RDATA,
    `else
        output [31:0] RDATA,
    `endif
    input WCLK,
    input [4:0] WADDR,
    input WCEB,
    input [31:0] WDATA
);


`ifdef FPGA
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
`else
    wire icg_E;
    wire CLK_w;
    wire CEB = RCEB & WCEB;
    wire [4:0] A;
    assign icg_E = ~CEB;
    assign A = (~RCEB) ? RADDR : WADDR;
    // icg ram_icg(.Q(CLK_w),.TE(1'b0),.CP(RCLK),.E(icg_E));
    tsmc_t22hpcp_hvt_uhd_s1p32x32 U_tsmc_t22hpcp_hvt_uhd_s1p32x32(
        // .CLK(CLK_w),
        .CLK(RCLK),
        .CEB(CEB),
        .WEB(WCEB),
        .A(A),
        .D(WDATA),
        .BWEB(32'b0),
        .Q(RDATA),
        .RTSEL(2'b0),
        .WTSEL(2'b0)
    );
    
`endif




endmodule
