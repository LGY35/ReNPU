module cub_alu_loop_controller 
#(
    parameter LOOP_NUM = 4,
    parameter IRAM_FILL_AWID = 15
)
(
    input   [IRAM_FILL_AWID-1:0]            current_pc_i, //from fetch addr always
    
    //form hwloop_regs(ID)
    input   [LOOP_NUM-1:0][31:0]            loop_start_addr_i,
    input   [LOOP_NUM-1:0][31:0]            loop_end_addr_i,
    input   [LOOP_NUM-1:0][31:0]            loop_counter_i,

    //to id_stage
    output  logic                           loop_jump_o,
    output  logic [IRAM_FILL_AWID-1:0]      loop_target_addr_o,

    //to hwloop_regs(ID)
    output  logic [LOOP_NUM-1:0]            loop_cnt_dec_o,

    //from pipeline stages
    input   [LOOP_NUM-1:0]                  loop_cnt_dec_id_i
);


    logic   [LOOP_NUM-1:0]    pc_is_end_addr;

    //check for end addr with loop counter
    genvar i;
    generate
        for(i=0; i<LOOP_NUM; i=i+1) begin
            always @(*) begin
                if(current_pc_i == loop_end_addr_i[i][IRAM_FILL_AWID-1:0]) begin
                    if(loop_counter_i[i][31:2] != 'b0) begin
                        pc_is_end_addr[i] = 1'b1;
                    end
                    else begin
                        case(loop_counter_i[i][1:0])
                          2'b11:        pc_is_end_addr[i] = 1'b1;
                          2'b10:        pc_is_end_addr[i] = ~loop_cnt_dec_id_i[i]; // only when there is nothing in flight
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


    //select corresponding start address and decrement counter
    always_comb begin
        casez(pc_is_end_addr) //[0]:inner loop [1]:outer1 loop [2]:outer2 loop [3]:outer3 loop
            4'b0000: begin
                loop_target_addr_o = 'b0;
                loop_cnt_dec_o = 4'b0;
            end
            4'b???1: begin //inner dec
                loop_target_addr_o = loop_start_addr_i[0][IRAM_FILL_AWID-1:0];
                loop_cnt_dec_o = 4'b0001;
            end
            4'b??10: begin //outer1 dec
                loop_target_addr_o = loop_start_addr_i[1][IRAM_FILL_AWID-1:0];
                loop_cnt_dec_o = 4'b0010;
            end
            4'b?100: begin //outer2 dec
                loop_target_addr_o = loop_start_addr_i[2][IRAM_FILL_AWID-1:0];
                loop_cnt_dec_o = 4'b0100;
            end
            4'b1000: begin //outer3 dec
                loop_target_addr_o = loop_start_addr_i[3][IRAM_FILL_AWID-1:0];
                loop_cnt_dec_o = 4'b1000;
            end
            default: begin
                loop_target_addr_o = 'b0;
                loop_cnt_dec_o = 4'b0;
            end
        endcase
    end
    
    //output signal for ID stage
    assign loop_jump_o = (|pc_is_end_addr);

endmodule
