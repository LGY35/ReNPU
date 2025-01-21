module std_tpram64x288 (
    input RCLK,
    input RCEB,
    input [5:0] RADDR,
    `ifdef FPGA
        output reg [287:0] RDATA,
    `else
        output [287:0] RDATA,
    `endif
    input WCLK,
    input [5:0] WADDR,
    input WCEB,
    input [287:0] WDATA
);


`ifdef FPGA
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

`elsif SMIC12
    // wire icg_E;
    // wire CLK_w;
    // wire ME = ~RCEB || ~WCEB;
    // wire [5:0] A;
    // assign icg_E = ME;
    // assign A = (~RCEB) ? RADDR : WADDR;
    // icg ram_icg(.Q(CLK_w),.TE(1'b0),.CP(RCLK),.E(icg_E));
    // s12_s1pram64x288 U_s12_s1pram64x288(
    //   .CLK(CLK_w),
    //   .ME(ME),
    //   .WE(~WCEB),
    //   .ADR(A),
    //   .D(WDATA),
    //   .Q(RDATA),
    //   .TEST1(1'b0),
    //   .TEST_RNM(1'b0),
    //   .RME(1'b0),
    //   .RM(4'b0),
    //   .LS(1'b0),
    //   .BC1(1'b0),
    //   .BC2(1'b0)
    // );

    wire icg_E = ~RCEB || ~WCEB;
    wire CLK_w;
    icg ram_icg(.Q(CLK_w),.TE(1'b0),.CP(RCLK),.E(icg_E));

    s12_tpram64x144 U0_s12_tpram64x144(
        .QB(RDATA[143:0]),
        .ADRA(WADDR),
        .DA(WDATA[143:0]),
        .WEA(~WCEB),
        .MEA(~WCEB),
        .CLKA(CLK_w),
        .TEST1A(1'b0),
        .RMEA(1'b0),
        .RMA(4'b0),
        .LS(1'b0),
        .ADRB(RADDR),
        .MEB(~RCEB),
        .CLKB(CLK_w),
        .TEST1B(1'b0),
        .RMEB(1'b0),
        .RMB(4'b0)
    );

    s12_tpram64x144 U1_s12_tpram64x144(
        .QB(RDATA[287:144]),
        .ADRA(WADDR),
        .DA(WDATA[287:144]),
        .WEA(~WCEB),
        .MEA(~WCEB),
        .CLKA(CLK_w),
        .TEST1A(1'b0),
        .RMEA(1'b0),
        .RMA(4'b0),
        .LS(1'b0),
        .ADRB(RADDR),
        .MEB(~RCEB),
        .CLKB(CLK_w),
        .TEST1B(1'b0),
        .RMEB(1'b0),
        .RMB(4'b0)
    );

`else
    // wire icg_E;
    // wire CLK_w;
    // wire CEB = RCEB & WCEB;
    // wire [5:0] A;
    // assign icg_E = ~CEB;
    // assign A = (~RCEB) ? RADDR : WADDR;
    // icg ram_icg(.Q(CLK_w),.TE(1'b0),.CP(RCLK),.E(icg_E));
    // tsmc_t22hpcp_hvt_uhd_s1p64x288 U_tsmc_t22hpcp_hvt_uhd_s1p64x288(
    //     .CLK(CLK_w),
    //     //.CLK(RCLK),
    //     .CEB(CEB),
    //     .WEB(WCEB),
    //     .A(A),
    //     .D(WDATA),
    //     //.BWEB(288'b0),
    //     .Q(RDATA),
    //     .RTSEL(2'b10),
    //     .WTSEL(2'b0)
    // );

    wire icg_E = ~RCEB || ~WCEB;
    wire CLK_w;
    icg ram_icg(.Q(CLK_w),.TE(1'b0),.CP(RCLK),.E(icg_E));
    tsmc_t22hpcp_hvt_uhd_r2p64x144 U0_tsmc_t22hpcp_hvt_uhd_r2p64x144(
        .AA(WADDR),
        .D(WDATA[143:0]),
        .WEB(WCEB),
        .CLKW(CLK_w),
        .AB(RADDR),
        .REB(RCEB),
        .CLKR(CLK_w),
        .Q(RDATA[143:0])
    );
    tsmc_t22hpcp_hvt_uhd_r2p64x144 U1_tsmc_t22hpcp_hvt_uhd_r2p64x144(
        .AA(WADDR),
        .D(WDATA[287:144]),
        .WEB(WCEB),
        .CLKW(CLK_w),
        .AB(RADDR),
        .REB(RCEB),
        .CLKR(CLK_w),
        .Q(RDATA[287:144])
    );
    
`endif




endmodule
