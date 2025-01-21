module riscv_alu_div
#(
    parameter C_WIDTH = 33
)
(
    input                           clk,
    input                           rst_n,
    //input
    input        [C_WIDTH-1:0]      opa_i,
    input        [C_WIDTH-1:0]      opb_i,
    input        [1:0]              opcode_i, //0:udiv, 1:div, 2:urem, 3:rem
    //handshake
    input                           valid_i,
    input                           ready_i,
    output logic                    valid_o,
    //output
    output logic [C_WIDTH-1:0]      result_div_o
);

    `include "decode_param.v"
    
    localparam  PIPE_STAGE = 3;

    enum logic [1:0] {IDLE, DIVIDE, FINISH} ns, cs;
    logic [C_WIDTH-1:0] div_res,rem_res;
    logic               divide_by_0;
    logic               cnt_zero;
    logic [6-1:0]       cnt_n,cnt_p;
    logic               load_en;

    assign cnt_n = load_en ? PIPE_STAGE-1 : (~cnt_zero) ? cnt_p-1 : cnt_p;
    assign cnt_zero = ~(|cnt_p);

    always_ff@(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            cs <= IDLE;
            cnt_p <= 'b0;
        end
        else begin
            cs <= ns;
            cnt_p <= cnt_n;
        end
    end

    DW_div_pipe#(
       .a_width     ( 33 ),
       .b_width     ( 33 ),
       .tc_mode     ( 1 ),
       .rem_mode    ( 1 ),
       .num_stages  ( PIPE_STAGE+1 ), //2 stage pipe
       .stall_mode  ( 1 ),
       .rst_mode    ( 1 )
    )
    U_div
    (
       .clk(clk),
       .rst_n(rst_n),
       .a(opa_i),
       .b(opb_i),
       .en(cs==DIVIDE),
       .quotient(div_res),
       .remainder(rem_res),
       .divide_by_0(divide_by_0)
    );

    always_comb begin
        ns = cs;
        valid_o = 1'b0;
        load_en = 1'b0;

        case(cs)
            IDLE: begin
                valid_o = 1'b1;

                if(valid_i) begin
                    valid_o = 1'b0;
                    load_en = 1'b1;
                    ns = DIVIDE;
                end
            end
            DIVIDE: begin
                if(cnt_zero) begin
                    ns = IDLE;
                    valid_o = 1'b1;
                end
            end
            //FINISH: begin
            //    valid_o = 1'b1;
            //    
            //    if(ready_i) begin
            //        ns = IDLE;
            //    end
            //end
        endcase
    end

    always_comb begin
        result_div_o = 'b0;
        if(valid_o) begin
            if((opcode_i == 2'b01) || (opcode_i == 2'b00)) //0:udiv, 1:div
                result_div_o = div_res;
            else if((opcode_i == 2'b11) || (opcode_i == 2'b10)) //2:urem, 3:rem
                result_div_o = rem_res;
        end
    end

endmodule
