/*

    8 banks

*/

module L2_dmem(

    input                           clk,

    input                           rst_n,



    input                           L2_dmem_core_rd_en,

    input           [12:0]          L2_dmem_core_rd_addr,

    output  logic   [255:0]         L2_dmem_core_rd_data,



    input                           L2_dmem_core_wr_en,

    input           [12:0]          L2_dmem_core_wr_addr,

    input           [255:0]         L2_dmem_core_wr_data,



    input                           L2_dmem_dma_rd_en,

    input           [12:0]          L2_dmem_dma_rd_addr,

    output  logic   [255:0]         L2_dmem_dma_rd_data,



    input                           L2_dmem_dma_wr_en,

    input           [12:0]          L2_dmem_dma_wr_addr,

    input           [255:0]         L2_dmem_dma_wr_data

);



logic [3:0][7:0] in_ce;

logic [7:0][3:0] in_ce_t; //transpose

logic [1:0][7:0] in_we;

logic [7:0][2:0] in_we_t; //transpose

logic [1:0][7:0][255:0] in_wr_data;

logic [7:0][1:0][255:0] in_wr_data_t;

logic [3:0][7:0][9:0] in_addr;

logic [7:0][3:0][9:0] in_addr_t;



logic [1:0][7:0] in_ce_rd_reg;



logic [7:0] ce, we;

logic [7:0][255:0] wr_data, rd_data;

logic [7:0][9:0] addr;



assign in_ce[0] = L2_dmem_core_rd_en << L2_dmem_core_rd_addr[12:10];

assign in_ce[1] = L2_dmem_core_wr_en << L2_dmem_core_wr_addr[12:10];

assign in_ce[2] = L2_dmem_dma_rd_en << L2_dmem_dma_rd_addr[12:10];

assign in_ce[3] = L2_dmem_dma_wr_en << L2_dmem_dma_wr_addr[12:10];



assign in_we[0] = in_ce[1];

assign in_we[1] = in_ce[3];



integer h;

always_comb begin

    in_addr = 'b0;

    for(h = 0; h < 8; h = h + 1) begin

        if(in_ce[0][h]) begin

            in_addr[0][h] = L2_dmem_core_rd_addr[9:0];

        end

        if(in_ce[1][h]) begin

            in_addr[1][h] = L2_dmem_core_wr_addr[9:0];

        end

        if(in_ce[2][h]) begin

            in_addr[2][h] = L2_dmem_dma_rd_addr[9:0];

        end

        if(in_ce[3][h]) begin

            in_addr[3][h] = L2_dmem_dma_wr_addr[9:0];

        end

    end

end



integer k;

always_comb begin

    in_wr_data = 'b0;

    for(k = 0; k < 8; k = k + 1) begin

        if(in_ce[1][k]) begin

            in_wr_data[0][k] = L2_dmem_core_wr_data;

        end

        if(in_ce[3][k]) begin

            in_wr_data[1][k] = L2_dmem_dma_wr_data;

        end

    end

end



integer i,j;

always_comb begin

    for(i = 0; i < 4; i = i + 1) begin

        for(j = 0; j < 8; j = j + 1) begin

            in_ce_t[j][i] = in_ce[i][j];

        end

    end



    for(j = 0; j < 8; j = j + 1) begin

        ce[j] = | in_ce_t[j];

    end



    for(i = 0; i < 2; i = i + 1) begin

        for(j = 0; j < 8; j = j + 1) begin

            in_we_t[j][i] = in_we[i][j];

        end

    end



    for(j = 0; j < 8; j = j + 1) begin

        we[j] = | in_we_t[j];

    end



    for(i = 0; i < 2; i = i + 1) begin

        for(j = 0; j < 8; j = j + 1) begin

            in_wr_data_t[j][i] = in_wr_data[i][j];

        end

    end



    for(j = 0; j < 8; j = j + 1) begin

        wr_data[j] = in_wr_data_t[j][0] | in_wr_data_t[j][1];

    end



    for(i = 0; i < 4; i = i + 1) begin

        for(j = 0; j < 8; j = j + 1) begin

            in_addr_t[j][i] = in_addr[i][j];

        end

    end



    for(j = 0; j < 8; j = j + 1) begin

        addr[j] = in_addr_t[j][0] | in_addr_t[j][1] | in_addr_t[j][2] | in_addr_t[j][3];

    end

end



always_ff @(posedge clk or negedge rst_n) begin

    if(!rst_n) begin

        in_ce_rd_reg[0] <= 'b0;

    end

    else if(L2_dmem_core_rd_en) begin

        in_ce_rd_reg[0] <= in_ce[0];

    end

end



always_ff @(posedge clk or negedge rst_n) begin

    if(!rst_n) begin

        in_ce_rd_reg[1] <= 'b0;

    end

    else if(L2_dmem_dma_rd_en) begin

        in_ce_rd_reg[1] <= in_ce[2];

    end

end



integer x;

always_comb begin

    L2_dmem_core_rd_data = 'b0;

    L2_dmem_dma_rd_data = 'b0;

    for(x = 0; x < 8; x = x + 1) begin

        if(in_ce_rd_reg[0][x]) begin

            L2_dmem_core_rd_data = rd_data[x];

        end

        if(in_ce_rd_reg[1][x]) begin

            L2_dmem_dma_rd_data = rd_data[x];

        end

    end

end



genvar gen_i;

generate

    for(gen_i = 0; gen_i < 8; gen_i = gen_i + 1) begin: L2_dmem_banks

        L2_dmem_bank U_L2_dmem_bank(

            .CLK(clk),

            .CE(ce[gen_i]),

            .WE(we[gen_i]),

            .ADDR(addr[gen_i]),

            .WR_DATA(wr_data[gen_i]),

            .RD_DATA(rd_data[gen_i])

        );

    end

endgenerate

    

endmodule

