module irq_ctr #(
    parameter IRQ_NUM = 2
)
(
    input                               clk,
    input                               rst_n,

    input                               core_wakeup_irq,

    output  logic                       irq_i,
    output  logic   [4:0]               irq_id_i,
    input                               irq_ack_o,
    input           [4:0]               irq_id_o
);

reg [IRQ_NUM-1:0] irq_reg;
wire [IRQ_NUM-1:0] irq_reg_nxt;
wire [IRQ_NUM-1:0] irq_ack_bit_mask;
wire [IRQ_NUM-1:0] irq_set_bit_mask;

assign irq_ack_bit_mask = irq_ack_o << irq_id_o;
assign irq_set_bit_mask = {{(IRQ_NUM-1){1'b0}},core_wakeup_irq};
assign irq_reg_nxt = (irq_reg & (~irq_ack_bit_mask)) | irq_set_bit_mask;



always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        irq_reg <= 'b0;
    end
    else begin
        irq_reg <= irq_reg_nxt;
    end
end

assign irq_i = | irq_reg;

integer i;
always_comb begin
    irq_id_i = 'b0;
    for(i = 0; i < IRQ_NUM; i = i + 1) begin
        if(irq_reg[i])
            // irq_id_i = i[4:0];
            irq_id_i = i;
    end
end


endmodule