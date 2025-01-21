//pseudo_least_recently_used

module plru(
    input                   clk,
    input                   rst_n,

    input                   plru_hit,
    input           [2:0]   hit_cache_line_addr,
    input           [3:0]   plru_hit_index,

    input           [2:0]   miss_cache_line_addr,
    output  logic   [3:0]   choose_old_onehot

);

reg [2:0][2:0] plru_tree, plru_tree_next;

always_comb begin
    plru_tree_next = plru_tree;
    case(plru_hit_index)
    4'b1000: plru_tree_next[hit_cache_line_addr][2:1] = 2'b00;
    4'b0100: plru_tree_next[hit_cache_line_addr][2:1] = 2'b01;
    4'b0010: begin
        plru_tree_next[hit_cache_line_addr][2] = 1'b1;
        plru_tree_next[hit_cache_line_addr][0] = 1'b0;
    end
    4'b0001: begin
        plru_tree_next[hit_cache_line_addr][2] = 1'b1;
        plru_tree_next[hit_cache_line_addr][0] = 1'b1;
    end
    endcase
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        plru_tree <= 'b0;
    end
    else if(plru_hit) begin
        plru_tree <= plru_tree_next;
    end
end

always_comb begin
    case(plru_tree[miss_cache_line_addr])
    3'b000: choose_old_onehot = 4'b0001;
    3'b001: choose_old_onehot = 4'b0010;
    3'b010: choose_old_onehot = 4'b0001;
    3'b011: choose_old_onehot = 4'b0010;
    3'b100: choose_old_onehot = 4'b0100;
    3'b101: choose_old_onehot = 4'b0100;
    3'b110: choose_old_onehot = 4'b1000;
    3'b111: choose_old_onehot = 4'b1000;
    endcase
end



endmodule