module Weight_reg (
    input clk,
    input rstn,

    //ctr
    //input [1:0] calculation_mode,  //0:dwconv模式，1:稀疏conv模式，2:普通conv模式
    input [2:0] calculation_mode, //000:普通conv模式，001:稀疏conv模式 010:dwconv模式 011:fc模式
    input [1:0] weight_reg_wr_cnt, //weight_reg_ptr写次数-1, dwconv下，5x5int16需要400b，128b写4次；稀疏conv下，需要128b写3次；普通conv下，直接写128b
    input weight_wr_vld,
    output weight_wr_done,
    input conv3d_start,
    //LB
    input [128-1:0] LB_data_in,
    //input LB_data_vld,

    //Routing_array
    input [2:0] weight_out_sequence, //给出哪组权重
    input weight_uncompress_done,
    input bitmask_sel,
    input double_byte_mode,
    input int16_dense_mode,
    input int16_dense_weight_shift,
    input [2:0] weight_precision,
    output reg [15:0] sparse_bitmask,
    output reg [15:0] sparse_bitmask_r,
    output reg [160-1:0] weight_data
);

    reg [400-1:0] weight_reg;
    reg [1:0] weight_reg_ptr; 
    reg [1:0] sparse_bitmask_out_sequence;

    reg [2:0] conv3d_start_r;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            conv3d_start_r <= 3'b0;
        end
        else begin
            conv3d_start_r <= {conv3d_start_r[1:0], conv3d_start};
        end
    end


    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            weight_reg_ptr <= 2'd0;
        end
        else if (weight_wr_vld) begin
            weight_reg_ptr <= (weight_reg_ptr == weight_reg_wr_cnt) ? 2'b00 : weight_reg_ptr + 1;
        end
        else begin
            weight_reg_ptr <= weight_reg_ptr;
        end
    end

    assign weight_wr_done = (weight_reg_ptr == weight_reg_wr_cnt) & weight_wr_vld;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            sparse_bitmask_out_sequence <= 2'b0;
        end
        else if (weight_wr_vld) begin
            sparse_bitmask_out_sequence <= 2'b0;
        end
        else if (weight_uncompress_done) begin
            if(double_byte_mode) begin
                sparse_bitmask_out_sequence <= (sparse_bitmask_out_sequence == 3'd3) ? 3'd0 : sparse_bitmask_out_sequence + 1;
            end
            else begin
                sparse_bitmask_out_sequence <= (sparse_bitmask_out_sequence == 3'd1) ? 3'd0 : sparse_bitmask_out_sequence + 1;
            end        
        end
        else begin
            sparse_bitmask_out_sequence <= sparse_bitmask_out_sequence; 
        end
    end


    always @(posedge clk or negedge rstn) begin
	if(!rstn) begin
	    weight_reg <= 400'd0;
	end
        else if (weight_wr_vld) begin
            if ((calculation_mode[1:0] == 2'b00) | (calculation_mode == 3'b010) | (calculation_mode == 3'b101)) begin
                case (weight_reg_ptr)
                    2'b00: weight_reg[127:0] <= LB_data_in;
                    2'b01: weight_reg[255:128] <= LB_data_in;
                    2'b10: weight_reg[383:256] <= LB_data_in;
                    2'b11: weight_reg[400-1:384] <= LB_data_in[15:0];
                    default: weight_reg <= weight_reg;
                endcase
            end
            else if (calculation_mode == 3'b001) begin
                case (weight_reg_ptr)
                    2'b00: {weight_reg[112-1:80], weight_reg[336-1:320], weight_reg[80-1:0]} <= LB_data_in;
                    2'b01: {weight_reg[224-1:160], weight_reg[352-1:336], weight_reg[160-1:112]} <= LB_data_in;
                    2'b10: {weight_reg[384-1:368], weight_reg[320-1:240], weight_reg[368-1:352], weight_reg[240-1:224]} <= LB_data_in;
                    default: weight_reg <= weight_reg;
                endcase
            end
            else begin
                weight_reg <= weight_reg;
            end
        end
    end

    always @(*) begin
        if (calculation_mode == 3'b001) begin
            if (!double_byte_mode) begin
                case (sparse_bitmask_out_sequence)
                    3'd0: sparse_bitmask = bitmask_sel ? {weight_reg[344-1:336],weight_reg[352-1:344]} : {weight_reg[328-1:320],weight_reg[336-1:328]};
                    3'd1: sparse_bitmask = bitmask_sel ? {weight_reg[376-1:368],weight_reg[384-1:376]} : {weight_reg[360-1:352],weight_reg[368-1:360]};
                    default: sparse_bitmask = 16'd0;
                endcase
            end
            else begin
                case (sparse_bitmask_out_sequence)
                    3'd0: sparse_bitmask = bitmask_sel ? {weight_reg[328-1:320],weight_reg[328-1:320]} : {weight_reg[336-1:328],weight_reg[336-1:328]};
                    3'd1: sparse_bitmask = bitmask_sel ? {weight_reg[344-1:336],weight_reg[344-1:336]} : {weight_reg[352-1:344],weight_reg[352-1:344]};
                    3'd2: sparse_bitmask = bitmask_sel ? {weight_reg[360-1:352],weight_reg[360-1:352]} : {weight_reg[368-1:360],weight_reg[368-1:360]};
                    3'd3: sparse_bitmask = bitmask_sel ? {weight_reg[376-1:368],weight_reg[376-1:368]} : {weight_reg[384-1:376],weight_reg[384-1:376]};
                    default: sparse_bitmask = 16'd0;
                endcase
            end
        end
        else begin
            sparse_bitmask = 16'd0;
        end
    end

    always@(posedge clk or negedge rstn) begin
        if (!rstn) begin
            sparse_bitmask_r <= 16'd0;
        end
        else begin
            sparse_bitmask_r <= sparse_bitmask;
        end
    end

    always @(posedge clk) begin
        if ((calculation_mode == 3'b001 ? conv3d_start_r[2] : conv3d_start_r[1]) | int16_dense_weight_shift) begin
            if ((calculation_mode == 3'b000) & ~int16_dense_mode) begin
                weight_data <= {32'd0, weight_reg[128-1:0]};
            end
            else if (int16_dense_mode) begin
                case (weight_out_sequence)
                    3'd0: weight_data <= {{2{8'd0, weight_reg[55:48], weight_reg[39:32], weight_reg[23:16], weight_reg[7:0]}},
 					  {2{8'd0, weight_reg[63:56], weight_reg[47:40], weight_reg[31:24], weight_reg[15:8]}}};
                    3'd1: weight_data <= {{2{8'd0, weight_reg[119:112], weight_reg[103:96], weight_reg[87:80], weight_reg[71:64]}},
 					  {2{8'd0, weight_reg[127:120], weight_reg[111:104], weight_reg[95:88], weight_reg[79:72]}}};
                    default: weight_data <= 160'd0;
                endcase
            end
            else if (calculation_mode == 3'b100) begin
                weight_data <= {8'd0, weight_reg[127:96], 8'd0, weight_reg[95:64], 8'd0, weight_reg[63:32], 8'd0, weight_reg[31:0]};
            end
            else if (!double_byte_mode) begin
                case (weight_out_sequence)
                    3'd0: weight_data <= weight_reg[160-1:0];
                    3'd1: weight_data <= weight_reg[320-1:160];
                    default: weight_data <= 160'd0;
                endcase
            end
            else if (weight_precision == 3'b001) begin
                case (weight_out_sequence)
                    3'd0: weight_data <= {{2{weight_reg[80-1:40]}}, {2{weight_reg[40-1:0]}}};
                    3'd1: weight_data <= {{2{weight_reg[160-1:120]}}, {2{weight_reg[120-1:80]}}};
                    3'd2: weight_data <= {{2{weight_reg[240-1:200]}}, {2{weight_reg[200-1:160]}}};
                    3'd3: weight_data <= {{2{weight_reg[320-1:280]}}, {2{weight_reg[280-1:240]}}};
                    default: weight_data <= 160'd0;
                endcase
            end
            else begin
                case (weight_out_sequence)
                    3'd0: weight_data <= {{2{weight_reg[71:64], weight_reg[55:48], weight_reg[39:32], weight_reg[23:16], weight_reg[7:0]}},
 					  {2{weight_reg[79:72], weight_reg[63:56], weight_reg[47:40], weight_reg[31:24], weight_reg[15:8]}}};
                    3'd1: weight_data <= {{2{weight_reg[151:144], weight_reg[135:128], weight_reg[119:112], weight_reg[103:96], weight_reg[87:80]}},
 					  {2{weight_reg[159:152], weight_reg[143:136], weight_reg[127:120], weight_reg[111:104], weight_reg[95:88]}}};
                    3'd2: weight_data <= {{2{weight_reg[231:224], weight_reg[215:208], weight_reg[199:192], weight_reg[183:176], weight_reg[167:160]}},
 					  {2{weight_reg[239:232], weight_reg[223:216], weight_reg[207:200], weight_reg[191:184], weight_reg[175:168]}}};
                    3'd3: weight_data <= {{2{weight_reg[311:304], weight_reg[295:288], weight_reg[279:272], weight_reg[263:256], weight_reg[247:240]}},
 					  {2{weight_reg[319:312], weight_reg[303:296], weight_reg[287:280], weight_reg[271:264], weight_reg[255:248]}}};
                    default: weight_data <= 160'd0;
                endcase
            end
        end
        else if ((calculation_mode == 3'b010) | (calculation_mode == 3'b101)) begin
            if (!double_byte_mode) begin
                case (weight_out_sequence)
                    3'd0: weight_data <= {4{weight_reg[40-1:0]}};
                    3'd1: weight_data <= {4{weight_reg[80-1:40]}};
                    3'd2: weight_data <= {4{weight_reg[120-1:80]}};
                    3'd3: weight_data <= {4{weight_reg[160-1:120]}};
                    3'd4: weight_data <= {4{weight_reg[200-1:160]}};
                    default: weight_data <= 160'd0;
                endcase
            end
            else begin
                case (weight_out_sequence)
                    3'd0: weight_data <= {{2{weight_reg[80-1:40]}}, {2{weight_reg[40-1:0]}}};
                    3'd1: weight_data <= {{2{weight_reg[160-1:120]}}, {2{weight_reg[120-1:80]}}};
                    3'd2: weight_data <= {{2{weight_reg[240-1:200]}}, {2{weight_reg[200-1:160]}}};
                    3'd3: weight_data <= {{2{weight_reg[320-1:280]}}, {2{weight_reg[280-1:240]}}};
                    3'd4: weight_data <= {{2{weight_reg[400-1:360]}}, {2{weight_reg[360-1:320]}}};
                    default: weight_data <= 160'd0;
                endcase
            end
        end
        else begin
            weight_data <= weight_data;
        end
    end
endmodule
