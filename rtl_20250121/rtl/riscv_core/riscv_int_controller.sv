/*
Design Name     : Interrupt Controller
Data            : 2024/2/1           
Description     : Interrupt Controller
*/

module riscv_int_controller(
    input                       clk,
    input                       rst_n,

    //external interrupt lines
    input                       irq_i,     //level-triggered interrupt inputs
    input                       irq_sec_i, //interrupt secure bit from EU
    input   [4:0]               irq_id_i,  //interrupt id [0,1,....31]

    //irq_req for controller
    output logic                irq_req_ctrl_o,
    output logic                irq_sec_ctrl_o,
    output logic  [4:0]         irq_id_ctrl_o,

    //handshake signals to controller
    input                       ctrl_ack_i,
    input                       ctrl_kill_i,

    input                       m_Irq_Enable_i, //interrupt enable bit from CSR (M mode)
    input                       u_Irq_Enable_i, //interrupt enable bit from CSR (U mode)

    input  [1:0]                current_priv_lvl_i
);

    enum logic [1:0] {IDLE, IRQ_PENDING, IRQ_DONE} exc_ctrl_cs;

    logic irq_enable_ext;
    logic [4:0] irq_id_q;
    logic irq_sec_q;

    assign irq_enable_ext = m_Irq_Enable_i; //M mode from CSR

    assign irq_req_ctrl_o = (exc_ctrl_cs == IRQ_PENDING);
    assign irq_sec_ctrl_o = irq_sec_q;
    assign irq_id_ctrl_o  = irq_id_q;

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            exc_ctrl_cs <= IDLE;
            irq_sec_q   <= 1'b0;
            irq_id_q    <= 'b0;
        end 
        else begin
            case(exc_ctrl_cs)
                IDLE: begin
                    if(irq_enable_ext && irq_i) begin //find a irq
                        exc_ctrl_cs <= IRQ_PENDING;
                        irq_sec_q   <= irq_sec_i;
                        irq_id_q    <= irq_id_i;
                    end
                end
                IRQ_PENDING: begin //wait for ack signals from controller
                    case(1'b1)
                        ctrl_ack_i:  exc_ctrl_cs <= IRQ_DONE;
                        ctrl_kill_i: exc_ctrl_cs <= IDLE;
                        default:     exc_ctrl_cs <= IRQ_PENDING;
                    endcase
                end
                IRQ_DONE: begin
                    exc_ctrl_cs <= IDLE;
                    irq_sec_q   <= 1'b0;
                    irq_id_q    <= irq_id_q;
                end
                default: begin
                    exc_ctrl_cs <= IDLE;
                    irq_sec_q   <= 1'b0;
                    irq_id_q    <= 'b0;
                end
            endcase
        end
    end

endmodule
