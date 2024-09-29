/*

    assume 32KB

*/



module L2_dmem_bank(

    input                           CLK,

    // input                           rst_n,



    input                           CE,

    input                           WE,

    input               [9:0]       ADDR,

    input               [255:0]     WR_DATA,

    output  logic       [255:0]     RD_DATA

);



logic [7:0][31:0] wr_data, rd_data;



assign wr_data = WR_DATA;

assign RD_DATA = rd_data;



genvar gen_i;

generate

    for(gen_i = 0; gen_i < 8; gen_i = gen_i + 1) begin: SRAM_BANK

         t22_s1pram1024x32_wrapper U_sram1024x32(

            .clk(CLK),

            .CEB(~CE),

            .WEB(~WE),

            .A(ADDR),

            .D(wr_data[gen_i]),

            .Q(rd_data[gen_i])

        );

    end

endgenerate



endmodule

