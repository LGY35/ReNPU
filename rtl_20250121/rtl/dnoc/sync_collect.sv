module sync_collect(
    input                           clk,
    input                           rst_n,

    input                           sync_req,
    input           [3:0]           sync_node_id,
    output  logic                   sync_gnt,

    output  logic                   sync_hit,
    input                           sync_init,
    input           [11:0]          sync_target
);

localparam IDLE = 2'b0;
localparam WAIT = 2'd1;
localparam HIT  = 2'd2;

logic [1:0] cs, ns;

logic [11:0] sync_target_reg, sync_target_reg_ns;
logic [11:0] sync_buffer, sync_buffer_ns;

always_comb begin
    ns = cs;
    sync_target_reg_ns = sync_target_reg;
    sync_buffer_ns = sync_buffer;

    sync_hit = 'b0;
    sync_gnt = 1'b0;

    case(cs)
    IDLE: begin
        if(sync_init) begin
            ns = WAIT;
            sync_target_reg_ns = sync_target;
        end
    end
    WAIT: begin
        sync_gnt = 1'b1;
        if(sync_req) begin
            sync_buffer_ns = sync_buffer | (11'd1 << (sync_node_id));
        end
        if(sync_buffer == sync_target_reg) begin
            ns = HIT;
        end
    end
    HIT: begin
        ns = IDLE;
        sync_hit = 1'b1;
        sync_buffer_ns = 'b0;
    end
    endcase
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cs <= IDLE;
        sync_target_reg <= 'b0;
        sync_buffer <= 'b0;
    end
    else begin
        cs <= ns;
        sync_target_reg <= sync_target_reg_ns;
        sync_buffer <= sync_buffer_ns;
    end
end

endmodule