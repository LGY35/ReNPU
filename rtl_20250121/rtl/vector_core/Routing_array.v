module Routing_array (
    input clk,
    input rstn,

    input [1:0] stride,   //0:步长为1，1:步长为2 
    input [2:0] calculation_mode,
    //input routing_mode, //0:dwconv模式，1:稀疏conv模式
    input double_byte_mode, //0为单字节模式，连续解压两通道；1为双字节模式，只解压一路

    input bitmask_reload,
    input bitmask_shift,

    output bitmask_sel,

    input [100-1:0] routing_code, //压缩后的routing_bitmask
    //output reg [20*16-1:0] routing_bitmask
    input [16*8-1:0] routing_in,
    input routing_in_vld,
    output reg [20*8-1:0] routing_out_r,
    output reg routing_out_vld,

    //input [13:0] conv3d_psum_add_num,
    input uncompress_update, //稀疏conv模式下，更新一次routing_bitmask
    input sparse_start,
    input [15:0] sparse_bitmask,
    input [15:0] sparse_bitmask_r,
    output weight_uncompress_done
    //output conv_mac_first
    //output conv_mac_last
);
    
    reg [20*16-1:0] routing_bitmask;
    reg [20*16-1:0] routing_bitmask_update;
    wire [20*8-1:0] routing_out;
    wire uncompress_grp_valid; //稀疏conv模式下，一组解压valid
    wire [2:0] uncompress_sequence;
    wire [40-1:0] routing_bitmask_reg_echelon;

    integer i;
    always @(posedge clk) begin
        if (bitmask_reload) begin
            for (i = 0; i < 20; i = i + 1) begin
                routing_bitmask[16*i] <= ~routing_code[5*i+4] & ~routing_code[5*i+3] & ~routing_code[5*i+2] & ~routing_code[5*i+1] & ~routing_code[5*i];
                routing_bitmask[16*i+1] <= ~routing_code[5*i+4] & ~routing_code[5*i+3] & ~routing_code[5*i+2] & ~routing_code[5*i+1] & routing_code[5*i];
                routing_bitmask[16*i+2] <= ~routing_code[5*i+4] & ~routing_code[5*i+3] & ~routing_code[5*i+2] & routing_code[5*i+1] & ~routing_code[5*i];
                routing_bitmask[16*i+3] <= ~routing_code[5*i+4] & ~routing_code[5*i+3] & ~routing_code[5*i+2] & routing_code[5*i+1] & routing_code[5*i];
                routing_bitmask[16*i+4] <= ~routing_code[5*i+4] & ~routing_code[5*i+3] & routing_code[5*i+2] & ~routing_code[5*i+1] & ~routing_code[5*i];
                routing_bitmask[16*i+5] <= ~routing_code[5*i+4] & ~routing_code[5*i+3] & routing_code[5*i+2] & ~routing_code[5*i+1] & routing_code[5*i];
                routing_bitmask[16*i+6] <= ~routing_code[5*i+4] & ~routing_code[5*i+3] & routing_code[5*i+2] & routing_code[5*i+1] & ~routing_code[5*i];
                routing_bitmask[16*i+7] <= ~routing_code[5*i+4] & ~routing_code[5*i+3] & routing_code[5*i+2] & routing_code[5*i+1] & routing_code[5*i];
                routing_bitmask[16*i+8] <= ~routing_code[5*i+4] & routing_code[5*i+3] & ~routing_code[5*i+2] & ~routing_code[5*i+1] & ~routing_code[5*i];
                routing_bitmask[16*i+9] <= ~routing_code[5*i+4] & routing_code[5*i+3] & ~routing_code[5*i+2] & ~routing_code[5*i+1] & routing_code[5*i];
                routing_bitmask[16*i+10] <= ~routing_code[5*i+4] & routing_code[5*i+3] & ~routing_code[5*i+2] & routing_code[5*i+1] & ~routing_code[5*i];
                routing_bitmask[16*i+11] <= ~routing_code[5*i+4] & routing_code[5*i+3] & ~routing_code[5*i+2] & routing_code[5*i+1] & routing_code[5*i];
                routing_bitmask[16*i+12] <= ~routing_code[5*i+4] & routing_code[5*i+3] & routing_code[5*i+2] & ~routing_code[5*i+1] & ~routing_code[5*i];
                routing_bitmask[16*i+13] <= ~routing_code[5*i+4] & routing_code[5*i+3] & routing_code[5*i+2] & ~routing_code[5*i+1] & routing_code[5*i];
                routing_bitmask[16*i+14] <= ~routing_code[5*i+4] & routing_code[5*i+3] & routing_code[5*i+2] & routing_code[5*i+1] & ~routing_code[5*i];
                routing_bitmask[16*i+15] <= ~routing_code[5*i+4] & routing_code[5*i+3] & routing_code[5*i+2] & routing_code[5*i+1] & routing_code[5*i];
            end
        end
        else if (((calculation_mode == 3'b010) | (calculation_mode == 3'b101)) & bitmask_shift) begin
            for (i = 0; i < 20; i = i + 1) begin
		if(routing_bitmask[16*i +: 16] == 16'd0) begin
		    routing_bitmask[16*i +: 16] <= 16'd0;
		end
                else if (stride == 2'b00) begin
                    routing_bitmask[16*i +: 16] <= {routing_bitmask[16*i +: 12], routing_bitmask[16*i+12 +: 4]};
                end
                else begin
                    routing_bitmask[16*i +: 16] <= {routing_bitmask[16*i +: 8], routing_bitmask[16*i+8 +: 8]};
                end            
            end
        end
        else if ((calculation_mode == 3'b001) && uncompress_update) begin
            routing_bitmask <= routing_bitmask_update;
        end
        else begin
            routing_bitmask <= routing_bitmask;
        end
    end

    always @(posedge clk) begin
        if ((calculation_mode == 3'b001) & uncompress_grp_valid) begin
            case (uncompress_sequence)
                3'd0: begin
                    for (i = 0; i < 10; i = i + 1) begin
                        routing_bitmask_update[16*i] <= sparse_bitmask_r[0] ? routing_bitmask_reg_echelon[i] : 10'd0;
                        routing_bitmask_update[16*i+1] <= sparse_bitmask_r[1] ? routing_bitmask_reg_echelon[10+i] : 10'd0;
                        routing_bitmask_update[16*i+2] <= sparse_bitmask_r[2] ? routing_bitmask_reg_echelon[20+i] : 10'd0;
                        routing_bitmask_update[16*i+3] <= sparse_bitmask_r[3] ? routing_bitmask_reg_echelon[30+i] : 10'd0;
                    end
                end
                3'd1: begin
                    for (i = 0; i < 10; i = i + 1) begin
                        routing_bitmask_update[16*i+4] <= sparse_bitmask_r[4] ? routing_bitmask_reg_echelon[i] : 10'd0;
                        routing_bitmask_update[16*i+5] <= sparse_bitmask_r[5] ? routing_bitmask_reg_echelon[10+i] : 10'd0;
                        routing_bitmask_update[16*i+6] <= sparse_bitmask_r[6] ? routing_bitmask_reg_echelon[20+i] : 10'd0;
                        routing_bitmask_update[16*i+7] <= sparse_bitmask_r[7] ? routing_bitmask_reg_echelon[30+i] : 10'd0;
                    end
                end
                3'd2: begin
                    for (i = 0; i < 10; i = i + 1) begin
                        routing_bitmask_update[16*i+8] <= sparse_bitmask_r[8] ? routing_bitmask_reg_echelon[i] : 10'd0;
                        routing_bitmask_update[16*i+9] <= sparse_bitmask_r[9] ? routing_bitmask_reg_echelon[10+i] : 10'd0;
                        routing_bitmask_update[16*i+10] <= sparse_bitmask_r[10] ? routing_bitmask_reg_echelon[20+i] : 10'd0;
                        routing_bitmask_update[16*i+11] <= sparse_bitmask_r[11] ? routing_bitmask_reg_echelon[30+i] : 10'd0;
                    end
                end
                3'd3: begin
                    for (i = 0; i < 10; i = i + 1) begin
                        routing_bitmask_update[16*i+12] <= sparse_bitmask_r[12] ? routing_bitmask_reg_echelon[i] : 10'd0;
                        routing_bitmask_update[16*i+13] <= sparse_bitmask_r[13] ? routing_bitmask_reg_echelon[10+i] : 10'd0;
                        routing_bitmask_update[16*i+14] <= sparse_bitmask_r[14] ? routing_bitmask_reg_echelon[20+i] : 10'd0;
                        routing_bitmask_update[16*i+15] <= sparse_bitmask_r[15] ? routing_bitmask_reg_echelon[30+i] : 10'd0;
                    end
                end
                3'd4: begin
                    for (i = 10; i < 20; i = i + 1) begin
                        routing_bitmask_update[16*i] <= sparse_bitmask_r[0] ? routing_bitmask_reg_echelon[i-10] : 10'd0;
                        routing_bitmask_update[16*i+1] <= sparse_bitmask_r[1] ? routing_bitmask_reg_echelon[i] : 10'd0;
                        routing_bitmask_update[16*i+2] <= sparse_bitmask_r[2] ? routing_bitmask_reg_echelon[10+i] : 10'd0;
                        routing_bitmask_update[16*i+3] <= sparse_bitmask_r[3] ? routing_bitmask_reg_echelon[20+i] : 10'd0;
                    end
                end
                3'd5: begin
                    for (i = 10; i < 20; i = i + 1) begin
                        routing_bitmask_update[16*i+4] <= sparse_bitmask_r[4] ? routing_bitmask_reg_echelon[i-10] : 10'd0;
                        routing_bitmask_update[16*i+5] <= sparse_bitmask_r[5] ? routing_bitmask_reg_echelon[i] : 10'd0;
                        routing_bitmask_update[16*i+6] <= sparse_bitmask_r[6] ? routing_bitmask_reg_echelon[10+i] : 10'd0;
                        routing_bitmask_update[16*i+7] <= sparse_bitmask_r[7] ? routing_bitmask_reg_echelon[20+i] : 10'd0;
                    end
                end
                3'd6: begin
                    for (i = 10; i < 20; i = i + 1) begin
                        routing_bitmask_update[16*i+8] <= sparse_bitmask_r[8] ? routing_bitmask_reg_echelon[i-10] : 10'd0;
                        routing_bitmask_update[16*i+9] <= sparse_bitmask_r[9] ? routing_bitmask_reg_echelon[i] : 10'd0;
                        routing_bitmask_update[16*i+10] <= sparse_bitmask_r[10] ? routing_bitmask_reg_echelon[10+i] : 10'd0;
                        routing_bitmask_update[16*i+11] <= sparse_bitmask_r[11] ? routing_bitmask_reg_echelon[20+i] : 10'd0;
                    end
                end
                3'd7: begin
                    for (i = 10; i < 20; i = i + 1) begin
                        routing_bitmask_update[16*i+12] <= sparse_bitmask_r[12] ? routing_bitmask_reg_echelon[i-10] : 10'd0;
                        routing_bitmask_update[16*i+13] <= sparse_bitmask_r[13] ? routing_bitmask_reg_echelon[i] : 10'd0;
                        routing_bitmask_update[16*i+14] <= sparse_bitmask_r[14] ? routing_bitmask_reg_echelon[10+i] : 10'd0;
                        routing_bitmask_update[16*i+15] <= sparse_bitmask_r[15] ? routing_bitmask_reg_echelon[20+i] : 10'd0;
                    end
                end
                default: routing_bitmask_update <= routing_bitmask_update;
            endcase
        end
    end

    reg [16*8-1:0] routing_in_recom;
    always @(*) begin
        if ((!double_byte_mode) | (calculation_mode == 3'b010) | (calculation_mode == 3'b101)) begin
            routing_in_recom = routing_in;
        end
        else begin
            for (i = 0; i < 8; i = i + 1) begin
                routing_in_recom[8*i+:8] = routing_in[(16*i+8)+:8];
                routing_in_recom[8*(i+8)+:8] = routing_in[16*i+:8];
            end
        end
    end

    Sparse_detect sparse_detect_U0 (
        .clk(clk),
        .rstn(rstn),
        .sparse_start(sparse_start),
        .sparse_bitmask(sparse_bitmask),
        .sparse_bitmask_r(sparse_bitmask_r),
        .double_byte_mode(double_byte_mode),
        .bitmask_sel(bitmask_sel),
        .uncompress_sequence(uncompress_sequence),
        .uncompress_grp_valid(uncompress_grp_valid),
        .weight_uncompress_done(weight_uncompress_done),
        .routing_bitmask_reg_echelon(routing_bitmask_reg_echelon)
    );

    Vector_crossbar vector_crossbar_U0 (
        .routing_bitmask(routing_bitmask),
        .routing_in(routing_in_recom),
        .routing_out(routing_out)
    );

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            routing_out_vld <= 1'b0;
        end
        else begin
            routing_out_vld <= routing_in_vld;
        end
    end

    always @(posedge clk) begin
        if (((calculation_mode == 3'b010) | (calculation_mode == 3'b101)) & double_byte_mode) begin 
            for (i = 0; i < 5; i = i + 1) begin
                routing_out_r[8*i+:8] <= routing_out[(16*i+8)+:8];
                routing_out_r[8*(i+5)+:8] <= routing_out[16*i+:8];
                routing_out_r[8*(i+10)+:8] <= routing_out[(16*(i+5)+8)+:8];
                routing_out_r[8*(i+15)+:8] <= routing_out[16*(i+5)+:8];

            end
        end
        else begin
            routing_out_r <= routing_out;
        end
    end

endmodule
