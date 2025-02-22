module cluster_clock_gating
(
    input        clk_i,
    input        en_i,
    input        test_en_i,
    output logic clk_o
);

`ifdef CORE_FPGA
    // no clock gates in FPGA flow
    assign clk_o = clk_i;
`else
    logic clk_en;

    always_latch begin
        if (clk_i == 1'b0)
            clk_en <= en_i | test_en_i;
    end

    assign clk_o = clk_i & clk_en;
`endif

endmodule
