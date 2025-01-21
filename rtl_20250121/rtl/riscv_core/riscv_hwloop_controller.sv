/*
Design Name     : hwloop controller
Data            : 2024/1/10           
Description     : Tasks are:
                  a) compare PC with all stored end addr
                  b) jump to the right start addr if conunter=0
*/

module riscv_hwloop_controller
#(
    parameter HWLP_NUM = 4 //two loops
)
(
    input   [31:0]                          current_pc_i, //from fetch fifo addr out
    
    //form hwloop_regs(ID)
    input   [HWLP_NUM-1:0][31:0]            hwlp_start_addr_i,
    input   [HWLP_NUM-1:0][31:0]            hwlp_end_addr_i,
    input   [HWLP_NUM-1:0][31:0]            hwlp_counter_i,

    //to hwloop_regs(ID)
    output  logic [HWLP_NUM-1:0]            hwlp_cnt_dec_o,
    //from pipeline stages
    input   [HWLP_NUM-1:0]                  hwlp_cnt_dec_id_i,
    //to id_stage
    output  logic                           hwlp_jump_o,
    output  logic [31:0]                    hwlp_target_addr_o
);

    logic   [HWLP_NUM-1:0]    pc_is_end_addr;

    //check for end addr with loop counter
    genvar i;
    generate
        for(i=0; i<HWLP_NUM; i=i+1) begin
            always @(*) begin
                if(current_pc_i == hwlp_end_addr_i[i]) begin
                    if(hwlp_counter_i[i][31:2] != 'b0) begin
                        pc_is_end_addr[i] = 1'b1;
                    end
                    else begin
                        //hwlp_counter_i[i][31:2] == 32'h0
                        case(hwlp_counter_i[i][1:0])
                          2'b11:        pc_is_end_addr[i] = 1'b1;
                          2'b10:        pc_is_end_addr[i] = ~hwlp_cnt_dec_id_i[i]; // only when there is nothing in flight
                          2'b01, 2'b00: pc_is_end_addr[i] = 1'b0;
                        endcase                        
                    end
                end
                else begin
                    pc_is_end_addr[i] = 1'b0;
                end
            end
        end
    endgenerate
/*    
    //select corresponding start address and decrement counter
    always_comb begin
        case(pc_is_end_addr) //[0]:inner loop [1]:outer loop
            2'b00: begin
                hwlp_target_addr_o = 'b0;
                hwlp_cnt_dec_o = 2'b0;
            end
            2'b01, 2'b11: begin //inner dec
                hwlp_target_addr_o = hwlp_start_addr_i[0];
                hwlp_cnt_dec_o = 2'b01;                
            end
            2'b10: begin //outer dec
                hwlp_target_addr_o = hwlp_start_addr_i[1];
                hwlp_cnt_dec_o = 2'b10;   
            end
        endcase
    end
*/
    always_comb begin
        casez(pc_is_end_addr) //[0]:inner loop [1]:outer1 loop [2]:outer2 loop [3]:outer3 loop
            4'b0000: begin
                hwlp_target_addr_o = 'b0;
                hwlp_cnt_dec_o = 4'b0;
            end
            4'b???1: begin //inner dec
                hwlp_target_addr_o = hwlp_start_addr_i[0];
                hwlp_cnt_dec_o = 4'b0001;
            end
            4'b??10: begin //outer1 dec
                hwlp_target_addr_o = hwlp_start_addr_i[1];
                hwlp_cnt_dec_o = 4'b0010;
            end
            4'b?100: begin //outer2 dec
                hwlp_target_addr_o = hwlp_start_addr_i[2];
                hwlp_cnt_dec_o = 4'b0100;
            end
            4'b1000: begin //outer3 dec
                hwlp_target_addr_o = hwlp_start_addr_i[3];
                hwlp_cnt_dec_o = 4'b1000;
            end
            default: begin
                hwlp_target_addr_o = 'b0;
                hwlp_cnt_dec_o = 4'b0;
            end
        endcase
    end

    //output signal for ID stage
    assign hwlp_jump_o = (|pc_is_end_addr);

endmodule
