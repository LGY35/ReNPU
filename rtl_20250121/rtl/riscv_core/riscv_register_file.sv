/*
Design Name     : RISC-V Register File
Data            : 2024/1/24          
Description     : Register file based on Flip-Flops
*/

module riscv_register_file
#(
    parameter ADDR_WIDTH = 5,
    parameter DATA_WIDTH = 32
)
(
    input		                    clk,
    input		                    rst_n,

    //input		                    test_en_i,

    //Read port R1
    input		 [ADDR_WIDTH-1:0]   raddr_a_i,
    output logic [DATA_WIDTH-1:0]   rdata_a_o,

    //Read port R2
    input		 [ADDR_WIDTH-1:0]   raddr_b_i,
    output logic [DATA_WIDTH-1:0]   rdata_b_o,

    //Read port R3
    input		 [ADDR_WIDTH-1:0]   raddr_c_i,
    output logic [DATA_WIDTH-1:0]   rdata_c_o,

    //Write port W1
    input logic [ADDR_WIDTH-1:0]    waddr_a_i,
    input logic [DATA_WIDTH-1:0]    wdata_a_i,
    input logic                     we_a_i,

    //Write port W2
    input logic [ADDR_WIDTH-1:0]    waddr_b_i,
    input logic [DATA_WIDTH-1:0]    wdata_b_i,
    input logic                     we_b_i
);

    localparam NUM_WORDS = 2**ADDR_WIDTH; //number of integer registers

    logic [NUM_WORDS-1:0][DATA_WIDTH-1:0] mem; //integer register file

    //masked write addresses
    logic [ADDR_WIDTH-1:0]                waddr_a;
    logic [ADDR_WIDTH-1:0]                waddr_b;
    //write enable signals for all registers
    logic [NUM_WORDS-1:0]                 we_a_dec;
    logic [NUM_WORDS-1:0]                 we_b_dec;


    //============================
    //  READ Addr Dec
    //============================
    assign rdata_a_o = mem[raddr_a_i[ADDR_WIDTH-1:0]]; 
    assign rdata_b_o = mem[raddr_b_i[ADDR_WIDTH-1:0]];
    assign rdata_c_o = mem[raddr_c_i[ADDR_WIDTH-1:0]];


    //============================
    //  WRITE Addr Dec
    //============================
    //Mask top bit of write address to disable fp regfile
    assign waddr_a = waddr_a_i;
    assign waddr_b = waddr_b_i;

    always_comb begin : we_a_decoder
        foreach(we_a_dec[i]) begin
            we_a_dec[i] = (waddr_a==i) ? we_a_i : 1'b0;
        end
    end

    always_comb begin : we_b_decoder
        foreach(we_b_dec[i]) begin
            we_b_dec[i] = (waddr_b==i) ? we_b_i : 1'b0;
        end
    end


    //============================
    //  Write operation
    //============================

    //R0 is nil
    always_comb  begin
        mem[0] = 32'b0;
    end

    //loop from 1 to NUM_WORDS-1
    genvar i;
    generate
    for (i = 1; i < NUM_WORDS; i++) begin : rf_gen
        always_ff @(posedge clk or negedge rst_n) begin : register_write_behavior
            if(rst_n==1'b0) begin
                mem[i] <= 32'b0;
            end 
            else begin //port b priority high?
                if(we_b_dec[i])
                    mem[i] <= wdata_b_i;
                else if(we_a_dec[i])
                    mem[i] <= wdata_a_i;
            end
        end
    end
    endgenerate

endmodule

