module Vector_core (
    input clk,
    input rstn,

    //Broadcast 
    input [128-1:0] BC_data_in,
    input BC_data_vld,

    //LB
    input [128-1:0] LB_data_in,
    input LB_data_vld,
    input [1:0] LB_mv_cub_dst_sel, 
    //share cache
    output reg [32-1:0] Vec_core_data_out,
    output reg Vec_core_data_vld,

    //MCU
    //input [2:0] calculation_mode, //000:普通conv模式，001:稀疏conv模式 010:dwconv模式 011:fc模式 100:rgb
    //input [1:0] fmap_precision, //000:INT4 001:INT8 010:INT16
    //input [1:0] weight_precision, 

    input dwconv_start,
    //input dw_stride,   //0:步长为1，1:步长为2 
    //input [3:0] dw_kernel_size, //卷积核大小
    input dw_cross_ram_from_left, //向左借数
    input dw_cross_ram_from_right, //向右借数
    input [3:0] dw_trans_num, //dwconv一次填几行cram-1,实际计算行数会少1-4行：以15为例，3x3上pading下0-14，5x5上pading下0-12，3x3无pading下1-14，5x5无pading下2-13
    input dw_top_pad,
    input dw_bottom_pad,
    input dw_left_pad,
    input dw_right_pad,
    //input [7:0] dw_inst_num, //feature map size
    //input [7:0] dw_fmap_bank_size, //每条指令计算一个bank的feature map(dwconv int8下每四个窗口为一个指令bank,一行分成几次bank计算)
    
    input conv3d_start,
    input conv3d_first_subch_flag,
    input [4:0] conv3d_psum_start_index,
    input [4:0] conv3d_psum_end_index,
    input [1:0] conv3d_weight_16ch_sel,
    input conv3d_psum_data_trans_start, //psum数据向外传输
    input conv3d_psum_rd_ch_sel,
    input conv3d_psum_rd_rgb_sel,
    input [4:0] conv3d_psum_rd_num,
    input conv3d_result_output_flag,
    input [4:0] conv3d_psum_rd_offset,
    //input [5:0] subch_num, //子通道个数
    //input [4:0] conv3d_psum_trans_num, //psum实际深度-1，使用范围为1到31;0时直接用寄存器累加
    //input conv3d_row_start_flag,
    //input conv3d_row_end_flag,
    //input [13:0] psum_add_num, //H*W*subch_num - 1

    //input [13:0] FC_add_num, //共用conv3d_psum_add_num寄存器

    //input weight_wr_start,
    //input [1:0] weight_reg_wr_cnt, //weight_reg_ptr写次数-1, dwconv下，5x5int16需要400b，128b写4次；稀疏conv下，需要128b写3次；普通conv下，直接写128b
    //output reg weight_wr_req,
    input Y_mode_pre_en,
    input Y_mode_cram_sel,

    input [1:0] vector_cfg_addr, //00:dw相关 01:Routing_code 10:other 11:conv3d
    input [22-1:0] vector_cfg_data,
    input vector_cfg_vld,

    input cram_access_req,
    input cram_access_we,
    input [6:0] cram_access_addr,
    input [31:0] cram_access_wr_data,
    output cram_access_gnt,
    output [31:0] cram_access_rd_data,
    output cram_access_rd_data_vld,


    output cram_fill_done,
    output psum_full
);

//----------------------------------------静态配置----------------------------------------
    //dw相关配置
    reg [3:0] dw_kernel_size;
    reg [7:0] dw_inst_num;
    reg [7:0] dw_fmap_bank_size;
    reg [1:0] dw_stride;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            dw_kernel_size <= 4'd0;
            dw_inst_num <= 8'd0;
            dw_fmap_bank_size <= 8'd0;
	    dw_stride <= 2'd0;
        end
        else if (vector_cfg_vld && (vector_cfg_addr == 2'b00)) begin
            dw_kernel_size <= vector_cfg_data[3:0];
            dw_inst_num <= vector_cfg_data[11:4];
            dw_fmap_bank_size <= vector_cfg_data[19:12];
	    dw_stride <= vector_cfg_data[21:20];
        end
        else begin
            dw_kernel_size <= dw_kernel_size;
            dw_inst_num <= dw_inst_num;
            dw_fmap_bank_size <= dw_fmap_bank_size;
	    dw_stride <= dw_stride;
        end
    end

    //routing_code_default_cfg
    reg [100-1:0] routing_code;
    reg [2:0] routing_code_cfg_ptr;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            routing_code_cfg_ptr <= 3'd0;
        end
        else if (vector_cfg_vld && (vector_cfg_addr == 2'b01)) begin
            routing_code_cfg_ptr <= (routing_code_cfg_ptr == 3'd4) ? 3'd0 : routing_code_cfg_ptr + 1;
        end
        else begin
            routing_code_cfg_ptr <= routing_code_cfg_ptr;
        end
    end

    always @(posedge clk) begin
        if (vector_cfg_vld && (vector_cfg_addr == 2'b01)) begin
            routing_code[routing_code_cfg_ptr*20 +: 20] <= vector_cfg_data[20-1:0];
        end
        else begin
            routing_code <= routing_code;
        end
    end

    //other
    reg [2:0] calculation_mode;
    reg [1:0] weight_reg_wr_cnt;
    //reg [1:0] LB_data_target;
    reg [2:0] fmap_precision;
    reg [2:0] weight_precision;
    reg [4:0] truncate_Qp;
    
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            calculation_mode <= 3'd0;
            weight_reg_wr_cnt <= 3'd0;
            //LB_data_target <= 2'd0;
            fmap_precision <= 3'd0;
            weight_precision <= 3'd0;
            truncate_Qp <= 5'd0;
        end
        else if (vector_cfg_vld && (vector_cfg_addr == 2'b10)) begin
            calculation_mode <= vector_cfg_data[2:0];
            weight_reg_wr_cnt <= vector_cfg_data[5:3];
            //LB_data_target <= vector_cfg_data[7:6];
            fmap_precision <= vector_cfg_data[8:6];
            weight_precision <= vector_cfg_data[11:9];
            truncate_Qp <= vector_cfg_data[16:12];
        end
        else begin
            calculation_mode <= calculation_mode;
            weight_reg_wr_cnt <= weight_reg_wr_cnt;
            //LB_data_target <= LB_data_target;
            fmap_precision <= fmap_precision;
            weight_precision <= weight_precision;
            truncate_Qp <= truncate_Qp;
        end
    end

    //conv3d
    reg [13:0] conv3d_psum_add_num;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            conv3d_psum_add_num <= 14'd0;
        end
        else if (vector_cfg_vld && (vector_cfg_addr == 2'b11)) begin
            conv3d_psum_add_num <= vector_cfg_data [13:0];
        end
        else begin
            conv3d_psum_add_num <= conv3d_psum_add_num;
        end
    end
//----------------------------------------动态配置----------------------------------------
    reg dw_cross_ram_from_left_r; //向左借数
    reg dw_cross_ram_from_right_r; //向右借数
    reg [3:0] dw_trans_num_r; //dwconv一次填几行cram-1,实际计算行数会少1-4行：以15为例，3x3上pading下0-14，5x5上pading下0-12，3x3无pading下1-14，5x5无pading下2-13
    reg dw_top_pad_r;
    reg dw_bottom_pad_r;
    reg dw_left_pad_r;
    reg dw_right_pad_r;

    
    reg [4:0] conv3d_psum_start_index_r;
    reg [4:0] conv3d_psum_end_index_r;  

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            dw_cross_ram_from_left_r <= 1'b0;
            dw_cross_ram_from_right_r <= 1'b0;
            dw_trans_num_r <= 4'd0;
            dw_top_pad_r <= 1'b0;
            dw_bottom_pad_r <= 1'b0;
            dw_left_pad_r <= 1'b0;
	    dw_right_pad_r <= 1'b0;
        end
        else if (dwconv_start) begin
            dw_cross_ram_from_left_r <= dw_cross_ram_from_left;
            dw_cross_ram_from_right_r <= dw_cross_ram_from_right;
            dw_trans_num_r <= dw_trans_num;
            dw_top_pad_r <= dw_top_pad;
            dw_bottom_pad_r <= dw_bottom_pad;
            dw_left_pad_r <= dw_left_pad;
	    dw_right_pad_r <= dw_right_pad;
        end
        else begin
            dw_cross_ram_from_left_r <= dw_cross_ram_from_left_r;
            dw_cross_ram_from_right_r <= dw_cross_ram_from_right_r;
            dw_trans_num_r <= dw_trans_num_r;
            dw_top_pad_r <= dw_top_pad_r;
            dw_bottom_pad_r <= dw_bottom_pad_r;
            dw_left_pad_r <= dw_left_pad_r;
	    dw_right_pad_r <= dw_right_pad_r;
        end
    end

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            conv3d_psum_start_index_r <= 5'b0;
            conv3d_psum_end_index_r <= 5'b0;
        end
        else if (conv3d_psum_data_trans_start) begin
            conv3d_psum_start_index_r <= 5'd0;
            conv3d_psum_end_index_r <= conv3d_psum_rd_num;            
        end
        else if (conv3d_start) begin
            conv3d_psum_start_index_r <= conv3d_psum_start_index;
            conv3d_psum_end_index_r <= conv3d_psum_end_index;
        end
        else begin
            conv3d_psum_start_index_r <= conv3d_psum_start_index_r;
            conv3d_psum_end_index_r <= conv3d_psum_end_index_r;
        end
    end


//----------------------------------------控制信号----------------------------------------
    //weight_out_sequence ctr
    wire [2:0] dw_weight_out_sequence;
    reg [2:0] conv_weight_out_sequence;
    reg [4:0] conv_BC_data_vld_cnt;
    reg [3:0] conv3d_psum_rd_ch_sel_r;
    wire [2:0] weight_out_sequence;
    wire double_byte_mode;
    wire int16_dense_mode;
    wire int16_dense_weight_shift;
    
    assign double_byte_mode = (fmap_precision[2:1] != 2'b00);
    assign int16_dense_mode = (calculation_mode == 3'b000) & (fmap_precision == 3'b010) & (weight_precision == 3'b010);

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            conv_BC_data_vld_cnt <= 5'd0;
        end
        else if (BC_data_vld) begin
            conv_BC_data_vld_cnt <= (conv_BC_data_vld_cnt == (conv3d_psum_end_index_r - conv3d_psum_start_index_r)) ? 5'd0 : conv_BC_data_vld_cnt + 1;
        end
        else begin
            conv_BC_data_vld_cnt <= conv_BC_data_vld_cnt;
        end
    end

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            conv3d_psum_rd_ch_sel_r[0] <= 4'd0;
        end
        else if (conv3d_psum_data_trans_start) begin
            conv3d_psum_rd_ch_sel_r[0] <= conv3d_psum_rd_ch_sel;
        end
        else begin
            conv3d_psum_rd_ch_sel_r[0] <= conv3d_psum_rd_ch_sel_r[0];
        end
    end
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            conv3d_psum_rd_ch_sel_r[2:1] <= 2'd0;
        end
        else begin
            conv3d_psum_rd_ch_sel_r[2:1] <= conv3d_psum_rd_ch_sel_r[1:0];
        end
    end


    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            conv_weight_out_sequence <= 3'd0;
        end
        else if ((conv_BC_data_vld_cnt == 5'd0) & BC_data_vld) begin
            if(double_byte_mode & ~int16_dense_mode) begin
                conv_weight_out_sequence <= (conv_weight_out_sequence == 3'd3) ? 3'd0 : conv_weight_out_sequence + 1;
            end
            else begin
                conv_weight_out_sequence <= (conv_weight_out_sequence == 3'd1) ? 3'd0 : conv_weight_out_sequence + 1;
            end
        end
        else begin
            conv_weight_out_sequence <= conv_weight_out_sequence;
        end
    end

    assign weight_out_sequence = ({3{(calculation_mode == 3'b001) | int16_dense_mode}} & conv_weight_out_sequence) | ({3{(calculation_mode == 3'b010) | (calculation_mode == 3'b101)}} & dw_weight_out_sequence);
    assign int16_dense_weight_shift = int16_dense_mode & (conv_weight_out_sequence == 3'b001) & (conv_BC_data_vld_cnt == 5'd0);
        //bitmask_reload/shift
    wire bitmask_reload;
    wire bitmask_shift;


    //mac_data_vld_3cycle_bf
    wire fmap_data_routing_out_vld;
    reg dw_fmap_valid_r;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            dw_fmap_valid_r <= 1'b0;
        end
        else begin
            dw_fmap_valid_r <= ((calculation_mode == 3'b010) | (calculation_mode == 3'b101)) ? fmap_data_routing_out_vld : 0;
        end
    end

    reg [1:0] LB_mv_cub_dst_sel_r0;
    reg [1:0] LB_mv_cub_dst_sel_r1;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            LB_mv_cub_dst_sel_r0 <= 1'b0;
	    LB_mv_cub_dst_sel_r1 <= 1'b0;
        end
        else begin
            LB_mv_cub_dst_sel_r0 <= LB_mv_cub_dst_sel;
	    LB_mv_cub_dst_sel_r1 <= LB_mv_cub_dst_sel_r0;
        end
    end
     

    //FC
    reg [13:0] FC_add_cnt;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            FC_add_cnt <= 14'd0;
        end
        else if (((calculation_mode == 3'b011) | (calculation_mode == 3'b001)) & BC_data_vld) begin
            FC_add_cnt <= (FC_add_cnt == conv3d_psum_add_num) ? 14'd0 : FC_add_cnt + 1;
        end
        else begin
            FC_add_cnt <= FC_add_cnt;
        end
    end
//----------------------------------------模块例化----------------------------------------

    //Cram_ctr
    wire [128-1:0] cram_data_out;
    wire cram_data_out_vld;
    wire [64-1:0] psum_data_out;
    wire psum_data_out_vld;
    wire [31:0] accu_out0;
    wire [31:0] accu_out1;
    wire [31:0] accu_out2;
    wire [31:0] accu_out3;

    wire dw_mac_first;
    wire dw_mac_last;
    wire accu_out_vld;
    wire mac_out_valid;

    reg [128-1:0] mac_data_in;
    reg mac_data_in_vld;
    reg mac_data_vld_2cycle_bf;
    wire cram_access_wr_req;
    wire cram_access_rd_req;
    assign cram_access_wr_req = cram_access_req & cram_access_we;
    assign cram_access_rd_req = cram_access_req & ~cram_access_we;
    
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            mac_data_in <= 128'b0;
            mac_data_in_vld <= 1'b0;
            mac_data_vld_2cycle_bf <= 1'b0;
        end
        else begin
            mac_data_in <= {accu_out3, accu_out2, accu_out1, accu_out0};
            mac_data_in_vld <= accu_out_vld;
            mac_data_vld_2cycle_bf <= mac_out_valid;            
        end
    end

    Cram_ctrl Cram_ctrl_U0 (
        .clk(clk),
        .rstn(rstn),
        .BC_data_in(BC_data_in),
        .BC_data_vld(BC_data_vld),
        .lb_data_in(LB_data_in),
        .lb_data_in_vld(LB_data_vld),
	.LB_mv_cub_dst_sel(LB_mv_cub_dst_sel_r1),
        .mac_data_in(mac_data_in),
        .mac_data_in_vld(mac_data_in_vld),
        .mac_data_vld_2cycle_bf(mac_data_vld_2cycle_bf),
        .dw_mac_first(dw_mac_first),
        .dw_mac_last(dw_mac_last),

        .cram_data_out(cram_data_out),
        .cram_data_out_vld(cram_data_out_vld),

        .psum_data_out(psum_data_out),
        .psum_data_out_vld(psum_data_out_vld),

        // ctr
        .cram_mode(calculation_mode), 
        .weight_precision(weight_precision),
        .dwconv_start(dwconv_start),
        .dw_stride(dw_stride),   //0:步长为1，1:步长为2 
        .dw_kernel_size(dw_kernel_size), //卷积核大小
        .cross_ram_from_left(dw_cross_ram_from_left_r), //向左借数
        .cross_ram_from_right(dw_cross_ram_from_right_r), //向右借数
        .dw_top_pad(dw_top_pad),
        .dw_bottom_pad(dw_bottom_pad_r),
        .dw_left_pad(dw_left_pad_r),
        .dw_right_pad(dw_right_pad_r),
        .dw_trans_num(dw_trans_num_r), //dwconv一次填几行cram
        .dw_inst_num(dw_inst_num), //feature map size
        .dw_fmap_bank_size(dw_fmap_bank_size), //每条指令计算一个bank的feature map(dwconv int8下每四个窗口为一个指令bank,一行分成几次ba    .
	.bitmask_reload(bitmask_reload),
	.bitmask_shift(bitmask_shift),
        .conv3d_start(conv3d_start),
        .conv3d_first_subch_flag(conv3d_first_subch_flag),
	.conv3d_psum_start_index(conv3d_psum_start_index),
	.conv3d_psum_end_index(conv3d_psum_end_index),
        .psum_data_trans_start(conv3d_psum_data_trans_start),
	.psum_rd_ch_sel(conv3d_psum_rd_ch_sel_r[2]),
        .psum_rd_num(conv3d_psum_rd_num), //psum实际深度-1，使用范围为2到15;0和1时直接用寄存器累加
        .psum_add_num(conv3d_psum_add_num), //H*W*subch_num - 1
        .dw_weight_out_sequence(dw_weight_out_sequence),
        .Y_mode_pre_en(Y_mode_pre_en),
        .Y_mode_cram_sel(Y_mode_cram_sel),
	.cram_access_wr_req(cram_access_wr_req),
        .cram_access_rd_req(cram_access_rd_req),
        .cram_access_addr(cram_access_addr),
        .cram_access_wr_data(cram_access_wr_data),
        .cram_access_gnt(cram_access_gnt),
        .cram_access_rd_data(cram_access_rd_data),
        .cram_access_rd_data_vld(cram_access_rd_data_vld),

        .cram_fill_done(cram_fill_done),
        .psum_full(psum_full)
    );

    //routing_array
    wire bitmask_sel;
    wire [20*16-1:0] routing_bitmask;
    wire [128-1:0] routing_in;
    wire routing_in_vld;
    wire [160-1:0] fmap_data_routing_out;
    wire sparse_start;
    wire [15:0] sparse_bitmask;
    wire [15:0] sparse_bitmask_r;
    wire weight_wr_done;
    wire weight_uncompress_done;
    wire weight_reg_done;
    wire weight_wr_vld;
    assign weight_reg_done = (calculation_mode == 3'b001) ? weight_uncompress_done : weight_wr_done;
    
   
    reg [1:0] uncompress_update_r;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            uncompress_update_r <= 2'd0;
        end
        else begin
            uncompress_update_r <= {uncompress_update_r[0], conv3d_start};
        end
    end
    assign sparse_start = (calculation_mode == 3'b001) & (weight_wr_done | ((weight_out_sequence != (double_byte_mode ? 2'd3 : 2'd1)) & uncompress_update_r[1]));


    Routing_array Routing_array_U0 (
        .clk(clk),
        .rstn(rstn),
        .stride(dw_stride),
        .calculation_mode(calculation_mode),
        .double_byte_mode(double_byte_mode),
        .bitmask_reload(bitmask_reload),
        .bitmask_shift(bitmask_shift),
        .bitmask_sel(bitmask_sel),
        .routing_code(routing_code),
        .routing_in(routing_in),
        .routing_in_vld(routing_in_vld),
        .routing_out_r(fmap_data_routing_out),
        .routing_out_vld(fmap_data_routing_out_vld),
        .sparse_start(sparse_start),
        .sparse_bitmask(sparse_bitmask),
        .sparse_bitmask_r(sparse_bitmask_r),
        .weight_uncompress_done(weight_uncompress_done),
        .uncompress_update(uncompress_update_r[1])
        //.conv_mac_first(conv_mac_first)
        //.conv_mac_last(conv_mac_last)
    );

    //Vector_crossbar

    assign routing_in = ({128{((calculation_mode == 3'b010) | (calculation_mode == 3'b101))}} & cram_data_out) | ({128{(calculation_mode == 3'b001)}} & BC_data_in);
    assign routing_in_vld = (((calculation_mode == 3'b010) | (calculation_mode == 3'b101)) & cram_data_out_vld) | ((calculation_mode == 3'b001) & BC_data_vld);

    //Weight_reg
    wire [160-1:0] weight_data;
    wire weight_wr_start;
    assign weight_wr_vld = LB_data_vld & (LB_mv_cub_dst_sel_r1 == 2'b00);

    Weight_reg Weight_reg_U0 (
        .clk(clk),
        .rstn(rstn),
        .calculation_mode(calculation_mode),
	.weight_reg_wr_cnt(weight_reg_wr_cnt),
        //.weight_wr_start(weight_wr_start),
        .weight_wr_done(weight_wr_done),
        .conv3d_start(conv3d_start),
        .LB_data_in(LB_data_in),
        .weight_wr_vld(weight_wr_vld),
        .weight_out_sequence(weight_out_sequence),
        .weight_uncompress_done(weight_uncompress_done),
        .bitmask_sel(bitmask_sel),
        .double_byte_mode(double_byte_mode),
        .int16_dense_mode(int16_dense_mode),
        .int16_dense_weight_shift(int16_dense_weight_shift),
        .weight_precision(weight_precision),
        .sparse_bitmask(sparse_bitmask),
        .sparse_bitmask_r(sparse_bitmask_r),
        .weight_data(weight_data)
    );

    //mac_array
    reg [160-1:0] fmap_data;
    wire fmap_data_vld;
    wire [128-1:0] mac_out_data;
    reg [1:0] mac_cfg_conv_mode;

    reg int16_dense_fmap_sel;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            int16_dense_fmap_sel <= 1'b1;
        end
        else if (conv3d_start) begin
            int16_dense_fmap_sel <= ~int16_dense_fmap_sel;
        end
        else begin
            int16_dense_fmap_sel <= int16_dense_fmap_sel;
        end
    end

    always @(*) begin
        if ((calculation_mode == 3'b001) | (calculation_mode == 3'b010) | (calculation_mode == 3'b101)) begin
            fmap_data = fmap_data_routing_out;
        end
        else if (calculation_mode == 3'b100) begin
            fmap_data = {8'b0, BC_data_in[127:96], 8'b0, BC_data_in[95:64], 8'b0, BC_data_in[63:32], 8'b0, BC_data_in[31:0]};
        end
        else if (int16_dense_mode) begin
            fmap_data = int16_dense_fmap_sel ? {2{8'd0, BC_data_in[119:112], BC_data_in[103:96], BC_data_in[87:80], BC_data_in[71:64], 8'd0, BC_data_in[127:120], BC_data_in[111:104], BC_data_in[95:88], BC_data_in[79:72]}}
                                             : {2{8'd0, BC_data_in[55:48], BC_data_in[39:32], BC_data_in[23:16], BC_data_in[7:0], 8'd0, BC_data_in[63:56], BC_data_in[47:40], BC_data_in[31:24], BC_data_in[15:8]}};
        end
        else begin
            fmap_data = {32'b0, BC_data_in};
        end
    end
    assign fmap_data_vld = ((calculation_mode == 3'b001) | (calculation_mode == 3'b010) | (calculation_mode == 3'b101)) ? fmap_data_routing_out_vld : BC_data_vld;

    reg [1:0] mac_cfg_preci;
    wire mac_cfg_is_sparse;
    wire mac_cfg_is_fp;
    wire mac_ctrl_read;
    
    always @(*) begin
        if ((calculation_mode == 3'b010) | (calculation_mode == 3'b101)) begin
            mac_cfg_conv_mode = 2'b10;
        end
        else if (calculation_mode == 3'b011) begin
            mac_cfg_conv_mode = 2'b00;
        end
        else if (calculation_mode == 3'b100) begin
            mac_cfg_conv_mode = 2'b11;
        end        
        else begin
            mac_cfg_conv_mode = 2'b01;
        end
    end

    always @(*) begin
        if ((fmap_precision == 3'b001) & (weight_precision == 3'b001)) begin
            mac_cfg_preci = 2'b01;
        end
        else if ((fmap_precision == 3'b010) & (weight_precision == 3'b001)) begin
            mac_cfg_preci = 2'b10;
        end
        else if ((fmap_precision == 3'b010) & (weight_precision == 3'b010)) begin
            mac_cfg_preci = 2'b11;
        end
        else begin
            mac_cfg_preci = 2'b00;
        end
    end

    assign mac_cfg_is_sparse = (calculation_mode == 3'b001);
    assign mac_ctrl_read = (calculation_mode == 3'b011) & (FC_add_cnt == conv3d_psum_add_num);

    pe_mac_array U_pe_mac_array(
        .clk(clk),
        .rst_n(rstn),
        .fmap_data(fmap_data),
        .fmap_data_valid(fmap_data_vld),
        .weight_data(weight_data),
        .weight_data_valid(fmap_data_vld),
        .mac_cfg_conv_mode(mac_cfg_conv_mode),
        .mac_cfg_preci(mac_cfg_preci),
        .mac_cfg_is_uint(1'b0),
        .mac_out_data(mac_out_data),
        .mac_out_valid(mac_out_valid)
    );

    pe_accu U_pe_accu(
        .clk(clk),
        .rst_n(rstn),
        .accu_in_data(mac_out_data),
        .accu_in_valid(mac_out_valid),
        .accu_out_data_0(accu_out0),
        .accu_out_data_1(accu_out1),
        .accu_out_data_2(accu_out2),
        .accu_out_data_3(accu_out3),        
        .accu_out_valid(accu_out_vld),
        .mac_cfg_conv_mode(mac_cfg_conv_mode),
        .mac_cfg_preci(mac_cfg_preci),
        .mac_cfg_is_sparse(mac_cfg_is_sparse),
        .mac_cfg_is_fp(1'b0),
        .mac_ctrl_accu_ori(fmap_data_routing_out_vld),
        .mac_ctrl_first_ori(dw_mac_first),
        .mac_ctrl_last_ori(dw_mac_last),
        .mac_ctrl_read(mac_ctrl_read)
    );



    //psum_out_adder
    wire vector_data_out_40b_vld;
    wire [40-1:0] vector_data_out_40b;
    wire [40-1-31:0] truncate_high;
    psum_out_adder psum_out_adder_U0 (
        .clk(clk),
        .rstn(rstn),
        .calculation_mode(calculation_mode),
        .fmap_precision(fmap_precision),
        .weight_precision(weight_precision),
        .accu_out0(accu_out0),
        .accu_out1(accu_out1),
        .accu_out_vld(accu_out_vld),
        .psum_data_out(psum_data_out),
        .psum_data_out_vld(psum_data_out_vld),
        .vector_data_out_40b_vld(vector_data_out_40b_vld),
        .vector_data_out_40b(vector_data_out_40b)
    );
    assign truncate_high = $signed(vector_data_out_40b[39:32]) >>> truncate_Qp;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            Vec_core_data_out <= 32'b0;
            Vec_core_data_vld <= 1'b0;
        end
        else if (calculation_mode == 3'b000 | ((calculation_mode == 3'b001) & (weight_precision == 3'b010))) begin
            
            Vec_core_data_out <= (vector_data_out_40b[39] && (~&truncate_high)) ? 32'h80000000 : 
			    (~vector_data_out_40b[39] && (|truncate_high) ? 32'h7FFFFFFF : 
			    vector_data_out_40b[truncate_Qp+:32]);
            Vec_core_data_vld <= vector_data_out_40b_vld;
        end
        else if (calculation_mode == 3'b001) begin
            Vec_core_data_out <= conv3d_psum_rd_ch_sel_r[2] ? psum_data_out[63:32] : psum_data_out[31:0];
            Vec_core_data_vld <= psum_data_out_vld;
        end
        else if (calculation_mode == 3'b100) begin
            Vec_core_data_out <= conv3d_psum_rd_rgb_sel ? psum_data_out[63:32] : psum_data_out[31:0];
            Vec_core_data_vld <= psum_data_out_vld;
        end
        else begin
            Vec_core_data_out <= accu_out0;
            Vec_core_data_vld <= accu_out_vld;
        end
    end
endmodule
