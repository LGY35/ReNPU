module Sparse_detect (
    input clk,
    input rstn,
    input sparse_start,
    input [15:0] sparse_bitmask, //8x8: 解压两组，16+16; 16x8: 解压两组，8x2+8x2; 16x16: 解压一组，8x4
    input [15:0] sparse_bitmask_r,
    input double_byte_mode, //0为单字节权重，连续解压两通道；1为双字节权重，只解压一路。常量
    output reg bitmask_sel, //配合double_byte_mode与weight_out_sequence选择输入的sparse_bitmask
    output reg [2:0] uncompress_sequence, //写哪组routing_bitmask
    output uncompress_grp_valid,
    output weight_uncompress_done,
    output reg [40-1:0] routing_bitmask_reg_echelon //出来的编码是阶梯型，向外出时在Routing_array模块中将台阶部分置零。
);
    reg [2:0] sparse_state;
    reg [2:0] sparse_state_next;
    reg bitmask_sel_r;

    parameter IDLE =3'd0, UNCOMPRESS_grp0 = 3'd1, UNCOMPRESS_grp1 = 3'd2, UNCOMPRESS_grp2 = 3'd3, UNCOMPRESS_grp3 = 3'd4;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            sparse_state <= IDLE;
        end
        else begin
            sparse_state <= sparse_state_next;
        end
    end

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            bitmask_sel <= 1'b0;
        end
        else if (sparse_start) begin
            bitmask_sel <= 1'b0;
        end
        else if (sparse_state == UNCOMPRESS_grp2) begin
            bitmask_sel <= !bitmask_sel;
        end
        else begin
            bitmask_sel <= bitmask_sel;
        end
    end


    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            bitmask_sel_r <= 1'b0;
        end
        else if (sparse_start) begin
            bitmask_sel_r <= 1'b0;
        end
        else if (sparse_state == UNCOMPRESS_grp3) begin
            bitmask_sel_r <= !bitmask_sel_r;
        end
        else begin
            bitmask_sel_r <= bitmask_sel_r;
        end
    end

    always @(*) begin
        case (sparse_state)
            IDLE: begin
                sparse_state_next = sparse_start ? UNCOMPRESS_grp0 : IDLE;
            end
            UNCOMPRESS_grp0: begin
                sparse_state_next = UNCOMPRESS_grp1;
            end
            UNCOMPRESS_grp1: begin
                sparse_state_next = UNCOMPRESS_grp2;
            end
            UNCOMPRESS_grp2: begin
                sparse_state_next = UNCOMPRESS_grp3;
            end
            UNCOMPRESS_grp3: begin
                sparse_state_next = bitmask_sel_r ? IDLE : UNCOMPRESS_grp0;
            end
            default: sparse_state_next = IDLE;
        endcase
    end
    assign weight_uncompress_done = (sparse_state == UNCOMPRESS_grp3) & bitmask_sel_r;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            uncompress_sequence <= 3'd0;
        end
        else if (uncompress_grp_valid) begin
            uncompress_sequence <= uncompress_sequence + 3'd1;
        end
        else begin
            uncompress_sequence <= uncompress_sequence;
        end
    end

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            routing_bitmask_reg_echelon[9:0] <= 10'd0;
        end
        else begin
            case (sparse_state)
                IDLE: begin
                    routing_bitmask_reg_echelon[9:0] <= sparse_bitmask[0] ? 10'b00_0000_0001 : 10'b00_0000_0000;
                end 
                UNCOMPRESS_grp0: begin
                    routing_bitmask_reg_echelon[9:0] <= sparse_bitmask[4] ? {(routing_bitmask_reg_echelon[39:30] == 10'd0) ? 10'b00_0000_0001 : {routing_bitmask_reg_echelon[38:30], 1'b0}}
									  : routing_bitmask_reg_echelon[39:30];
                end
                UNCOMPRESS_grp1: begin
                    if (!double_byte_mode) begin
                        routing_bitmask_reg_echelon[9:0] <= sparse_bitmask[8] ? {(routing_bitmask_reg_echelon[39:30] == 10'd0) ? 10'b00_0000_0001 : {routing_bitmask_reg_echelon[38:30], 1'b0}}
									  : routing_bitmask_reg_echelon[39:30];
                    end
                    else begin
                        routing_bitmask_reg_echelon[9:0] <= sparse_bitmask[8] ? 10'b00_0010_0000 : 10'b00_0001_0000;
                    end
                end
                UNCOMPRESS_grp2: begin
                    routing_bitmask_reg_echelon[9:0] <= sparse_bitmask[12] ? {(routing_bitmask_reg_echelon[39:30] == 10'd0) ? 10'b00_0010_0000 : {routing_bitmask_reg_echelon[38:30], 1'b0}}
									  : routing_bitmask_reg_echelon[39:30];
                end
                UNCOMPRESS_grp3: begin
                    routing_bitmask_reg_echelon[9:0] <= sparse_bitmask[0] ? 10'b00_0000_0001 : 10'b00_0000_0000;
                end
                default: routing_bitmask_reg_echelon[9:0] <= 10'd0;
            endcase
        end
    end

    always @(*) begin
        case (sparse_state)
            IDLE: begin
                routing_bitmask_reg_echelon[39:10] = 30'd0;
            end
            UNCOMPRESS_grp0: begin
                routing_bitmask_reg_echelon[19:10] = sparse_bitmask_r[1] ? {(routing_bitmask_reg_echelon[9:0] == 10'd0) ? 10'b00_0000_0001 : {routing_bitmask_reg_echelon[8:0], 1'b0}}
									 : routing_bitmask_reg_echelon[9:0];
                routing_bitmask_reg_echelon[29:20] = sparse_bitmask_r[2] ? {(routing_bitmask_reg_echelon[19:10] == 10'd0) ? 10'b00_0000_0001 : {routing_bitmask_reg_echelon[18:10], 1'b0}}
									 : routing_bitmask_reg_echelon[19:10];
                routing_bitmask_reg_echelon[39:30] = sparse_bitmask_r[3] ? {(routing_bitmask_reg_echelon[29:20] == 10'd0) ? 10'b00_0000_0001 : {routing_bitmask_reg_echelon[28:20], 1'b0}}
									 : routing_bitmask_reg_echelon[29:20];
            end
            UNCOMPRESS_grp1: begin
                routing_bitmask_reg_echelon[19:10] = sparse_bitmask_r[5] ? {(routing_bitmask_reg_echelon[9:0] == 10'd0) ? 10'b00_0000_0001 : {routing_bitmask_reg_echelon[8:0], 1'b0}}
									 : routing_bitmask_reg_echelon[9:0];
                routing_bitmask_reg_echelon[29:20] = sparse_bitmask_r[6] ? {(routing_bitmask_reg_echelon[19:10] == 10'd0) ? 10'b00_0000_0001 : {routing_bitmask_reg_echelon[18:10], 1'b0}}
									 : routing_bitmask_reg_echelon[19:10];
                routing_bitmask_reg_echelon[39:30] = sparse_bitmask_r[7] ? {(routing_bitmask_reg_echelon[29:20] == 10'd0) ? 10'b00_0000_0001 : {routing_bitmask_reg_echelon[28:20], 1'b0}}
									 : routing_bitmask_reg_echelon[29:20];
            end
            UNCOMPRESS_grp2: begin
                routing_bitmask_reg_echelon[19:10] = sparse_bitmask_r[9] ? {(routing_bitmask_reg_echelon[9:0] == 10'd0) ? 10'b00_0000_0001 : {routing_bitmask_reg_echelon[8:0], 1'b0}}
									 : routing_bitmask_reg_echelon[9:0];
                routing_bitmask_reg_echelon[29:20] = sparse_bitmask_r[10] ? {(routing_bitmask_reg_echelon[19:10] == 10'd0) ? 10'b00_0000_0001 : {routing_bitmask_reg_echelon[18:10], 1'b0}}
									 : routing_bitmask_reg_echelon[19:10];
                routing_bitmask_reg_echelon[39:30] = sparse_bitmask_r[11] ? {(routing_bitmask_reg_echelon[29:20] == 10'd0) ? 10'b00_0000_0001 : {routing_bitmask_reg_echelon[28:20], 1'b0}}
									 : routing_bitmask_reg_echelon[29:20];
            end
            UNCOMPRESS_grp3: begin
                routing_bitmask_reg_echelon[19:10] = sparse_bitmask_r[13] ? {(routing_bitmask_reg_echelon[9:0] == 10'd0) ? 10'b00_0000_0001 : {routing_bitmask_reg_echelon[8:0], 1'b0}}
									 : routing_bitmask_reg_echelon[9:0];
                routing_bitmask_reg_echelon[29:20] = sparse_bitmask_r[14] ? {(routing_bitmask_reg_echelon[19:10] == 10'd0) ? 10'b00_0000_0001 : {routing_bitmask_reg_echelon[18:10], 1'b0}}
									 : routing_bitmask_reg_echelon[19:10];
                routing_bitmask_reg_echelon[39:30] = sparse_bitmask_r[15] ? {(routing_bitmask_reg_echelon[29:20] == 10'd0) ? 10'b00_0000_0001 : {routing_bitmask_reg_echelon[28:20], 1'b0}}
									 : routing_bitmask_reg_echelon[29:20];
            end
            default: routing_bitmask_reg_echelon[39:10] = 30'd0;
        endcase
    end

    assign uncompress_grp_valid = (sparse_state != IDLE);
endmodule
