module std_spram1024x128b (
    input clk,
    input cen,
    input wen,
    input [9:0] addr,
    input [127:0] wdata,
    input [15:0] wstrb,
    `ifdef FPGA
        output reg [127:0] rdata
    `else
        output [127:0] rdata
    `endif
);


`ifdef FPGA
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
        if(cen && !wen)
            rdata <= sram_sim[addr];
    end

`elsif SMIC12
    wire icg_E;
    wire CLK_w;
    wire [127:0] BWEB;
    assign BWEB = 
    {
        {8{~wstrb[15]}},
        {8{~wstrb[14]}},
        {8{~wstrb[13]}},
        {8{~wstrb[12]}},
        {8{~wstrb[11]}},
        {8{~wstrb[10]}},
        {8{~wstrb[9]}},
        {8{~wstrb[8]}},
        {8{~wstrb[7]}},
        {8{~wstrb[6]}},
        {8{~wstrb[5]}},
        {8{~wstrb[4]}},
        {8{~wstrb[3]}},
        {8{~wstrb[2]}},
        {8{~wstrb[1]}},
        {8{~wstrb[0]}}
    };
    assign icg_E = cen;
    icg ram_icg(.Q(CLK_w),.TE(1'b0),.CP(clk),.E(icg_E));

    wire cen0;
    wire cen1;
    wire [127:0] rdata0;
    wire [127:0] rdata1;
    reg rdata_sel;
    
    assign cen0 = cen && (addr[9]==1'b0);
    assign cen1 = cen && (addr[9]==1'b1);

    std_spram512x128 U0_std_spram512x128(
        .clk  (CLK_w),
        .CEB  (~cen0),
        .WEB  (~wen),
        .A    (addr[8:0]),
        .D    (wdata),
        .Q    (rdata0)
    );

    std_spram512x128 U1_std_spram512x128(
        .clk  (CLK_w),
        .CEB  (~cen1),
        .WEB  (~wen),
        .A    (addr[8:0]),
        .D    (wdata),
        .Q    (rdata1)
    );

    always@(posedge clk) begin
        if(cen)
            rdata_sel <= addr[9];
    end

    assign rdata = rdata_sel ? rdata1 : rdata0;

`else
    wire icg_E;
    wire CLK_w;
    wire [127:0] BWEB;
    assign BWEB = 
    {
        {8{~wstrb[15]}},
        {8{~wstrb[14]}},
        {8{~wstrb[13]}},
        {8{~wstrb[12]}},
        {8{~wstrb[11]}},
        {8{~wstrb[10]}},
        {8{~wstrb[9]}},
        {8{~wstrb[8]}},
        {8{~wstrb[7]}},
        {8{~wstrb[6]}},
        {8{~wstrb[5]}},
        {8{~wstrb[4]}},
        {8{~wstrb[3]}},
        {8{~wstrb[2]}},
        {8{~wstrb[1]}},
        {8{~wstrb[0]}}
    };
    assign icg_E = cen;
    icg ram_icg(.Q(CLK_w),.TE(1'b0),.CP(clk),.E(icg_E));

    wire cen0;
    wire cen1;
    wire [127:0] rdata0;
    wire [127:0] rdata1;
    reg rdata_sel;
    
    assign cen0 = cen && (addr[9]==1'b0);
    assign cen1 = cen && (addr[9]==1'b1);

    tsmc_t22hpcp_hvt_uhd_s1p512x128e U0_tsmc_t22hpcp_hvt_uhd_s1p512x128e(
        .CLK  (CLK_w),
        .CEB  (~cen0),
        .WEB  (~wen),
        .A    (addr[8:0]),
        .D    (wdata),
        .BWEB (BWEB),
        .RTSEL(2'b0),
        .WTSEL(2'b0),
        .Q    (rdata0)
    );

    tsmc_t22hpcp_hvt_uhd_s1p512x128e U1_tsmc_t22hpcp_hvt_uhd_s1p512x128e(
        .CLK  (CLK_w),
        .CEB  (~cen1),
        .WEB  (~wen),
        .A    (addr[8:0]),
        .D    (wdata),
        .BWEB (BWEB),
        .RTSEL(2'b0),
        .WTSEL(2'b0),
        .Q    (rdata1)
    );

    always@(posedge clk) begin
        if(cen)
            rdata_sel <= addr[9];
    end

    assign rdata = rdata_sel ? rdata1 : rdata0;
`endif




endmodule
