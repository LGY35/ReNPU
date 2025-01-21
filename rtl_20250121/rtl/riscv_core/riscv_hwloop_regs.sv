/*
Design Name     : Hardware Loop Registers
Data            : 2024/2/1          
Description     : a) store start/end address of N=4 hardware loops,
                  b) store init value of counter for each hardware loop
                  c) decrement counter if hwloop taken
*/

module riscv_hwloop_regs
#(
    parameter HWLP_NUM = 4
)
(
    input                           clk,
    input                           rst_n,

    //from ID
    input   [31:0]                  hwlp_start_data_i,
    input   [31:0]                  hwlp_end_data_i,
    input   [31:0]                  hwlp_cnt_data_i,
    input   [2:0]                   hwlp_we_i,
    input   [1:0]                   hwlp_regid_i, //selects the register index

    //from controller
    input                           valid_i,

    //from hwloop controller
    input   [HWLP_NUM-1:0]          hwlp_cnt_dec_i,

    //to hwloop controller
    output  [HWLP_NUM-1:0][31:0]    hwlp_start_addr_o,
    output  [HWLP_NUM-1:0][31:0]    hwlp_end_addr_o,
    output  [HWLP_NUM-1:0][31:0]    hwlp_counter_o
);


    logic   [HWLP_NUM-1:0][31:0]    hwlp_start_q;
    logic   [HWLP_NUM-1:0][31:0]    hwlp_end_q;
    logic   [HWLP_NUM-1:0][31:0]    hwlp_counter_q;

    assign hwlp_start_addr_o = hwlp_start_q;
    assign hwlp_end_addr_o   = hwlp_end_q;
    assign hwlp_counter_o    = hwlp_counter_q;

    //hwloop start-address register
    always_ff@(posedge clk or negedge rst_n) begin : HWLOOP_REGS_START
        if(!rst_n)
            hwlp_start_q <= 'b0;
        else if(hwlp_we_i[0])
            hwlp_start_q[hwlp_regid_i] <= hwlp_start_data_i;
    end

    //hwloop end-address register
    always_ff@(posedge clk or negedge rst_n) begin : HWLOOP_REGS_END
      if(!rst_n)
            hwlp_end_q <= 'b0;
      else if(hwlp_we_i[1])
            hwlp_end_q[hwlp_regid_i] <= hwlp_end_data_i;
    end


    //hwloop counter register with decrement logic
    genvar i;
    generate
    for(i = 0; i < HWLP_NUM; i++) begin 
        always_ff@(posedge clk or negedge rst_n) begin : HWLOOP_REGS_COUNTER
            if(!rst_n) begin
                  hwlp_counter_q[i] <= 'b0;
            end
            else begin
                if(hwlp_we_i[2] && (i==hwlp_regid_i)) begin
                    hwlp_counter_q[i] <= hwlp_cnt_data_i;
                end
                else if(hwlp_cnt_dec_i[i] && valid_i) begin
                    hwlp_counter_q[i] <= hwlp_counter_q[i] - 1;
                end
            end
        end
    end
    endgenerate

endmodule
