module Cram_ctrl #(
    parameter PSUM_DATA_WIDTH = 32
)
(
    input clk,
    input rstn,
    //BC
    input [128-1:0] BC_data_in,
    input BC_data_vld,
    //LB
    input [128-1:0] lb_data_in,
    input lb_data_in_vld,
    input [1:0] LB_mv_cub_dst_sel,
    //MAC Array
    input [4*PSUM_DATA_WIDTH-1:0] mac_data_in,
    input mac_data_in_vld,
    input mac_data_vld_2cycle_bf, //\u65e9\u4e09\u4e2a\u5468\u671f\u7684vld\u4fe1\u53f7
    output reg dw_mac_first,
    output reg dw_mac_last,

    //Routing Array
    output reg [128-1:0] cram_data_out,
    output cram_data_out_vld,
    //share cache
    output reg [2*PSUM_DATA_WIDTH-1:0] psum_data_out,
    output psum_data_out_vld,

    // ctr
    input [2:0] cram_mode, //000:norm conv 001:sparse_mode 010:dw conv 011:fc 100:rgb
    input [2:0] weight_precision,
    input dwconv_start,
    input [1:0] dw_stride,   //0:\u6b65\u957f\u4e3a1\uff0c1:\u6b65\u957f\u4e3a2 
    input [3:0] dw_kernel_size, //\u5377\u79ef\u6838\u5927\u5c0f
    input cross_ram_from_left, //\u5411\u5de6\u501f\u6570
    input cross_ram_from_right, //\u5411\u53f3\u501f\u6570
    input dw_top_pad,
    input dw_bottom_pad,
    input dw_left_pad,
    input dw_right_pad,
    input [3:0] dw_trans_num, //dwconv\u4e00\u6b21\u586b\u51e0\u884ccram
    input [7:0] dw_inst_num, //feature map size
    input [7:0] dw_fmap_bank_size, //\u6bcf\u6761\u6307\u4ee4\u8ba1\u7b97\u4e00\u4e2abank\u7684feature map(dwconv int8\u4e0b\u6bcf\u56db\u4e2a\u7a97\u53e3\u4e3a\u4e00\u4e2a\u6307\u4ee4bank,\u4e00\u884c\u5206\u6210\u51e0\u6b21bank\u8ba1\u7b97)
    output bitmask_reload,
    output bitmask_shift,
    input conv3d_start,
    input conv3d_first_subch_flag,
    input [4:0] conv3d_psum_start_index,
    input [4:0] conv3d_psum_end_index,
    input psum_data_trans_start,
    //input [5:0] subch_num, //\u5b50\u901a\u9053\u4e2a\u6570
    input [4:0] psum_rd_num, //psum\u5b9e\u9645\u6df1\u5ea6-1\uff0c\u4f7f\u7528\u8303\u56f4\u4e3a1\u523031;0\u65f6\u76f4\u63a5\u7528\u5bc4\u5b58\u5668\u7d2f\u52a0
    input psum_rd_ch_sel,
    input [13:0] psum_add_num, //H*W*subch_num - 1
    output reg [2:0] dw_weight_out_sequence,
    input Y_mode_pre_en,
    input Y_mode_cram_sel, 

    input cram_access_wr_req,
    input cram_access_rd_req,
    input [6:0] cram_access_addr,
    input [31:0] cram_access_wr_data,
    output cram_access_gnt,
    output reg [31:0] cram_access_rd_data,
    output reg cram_access_rd_data_vld,

    output cram_fill_done,
    output psum_full
);

    //cram
    wire CE0_a, CE0_b, CE1_a, CE1_b;
    wire WE0_a, WE0_b, WE1_a, WE1_b;
    wire RE0_a, RE0_b, RE1_a, RE1_b;
    wire [3:0] wr_addr0, wr_addr1;
    wire [3:0] rd_addr0, rd_addr1;
    reg [128-1:0] D;
    reg [128-1:0] Q0, Q1;


//DW_cram_ctrl
    reg dw_conv_state;
    wire dw_conv_end;
    reg [3:0] row_cnt;
    reg [7:0] dw_inst_cnt;
    reg [3:0] dw_kernel_size_cnt;
    wire [3:0] dw_kernel_cycle;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            dw_conv_state <= 1'b0;
        end
        else if (dwconv_start) begin
            dw_conv_state <= 1'b1;
        end
        else if (dw_conv_end) begin
            dw_conv_state <= 1'b0;
        end
        else begin
            dw_conv_state <= dw_conv_state;
        end
    end

    assign dw_conv_end =(dw_kernel_size_cnt == dw_kernel_cycle) & (dw_bottom_pad ? (row_cnt == dw_trans_num) : (row_cnt == (dw_trans_num - (dw_kernel_size >> 1))));

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            dw_inst_cnt <= 8'd0;
        end
        else if (dw_conv_state & dw_conv_end) begin
            dw_inst_cnt <= (dw_inst_cnt == dw_fmap_bank_size) ? 8'd0 : dw_inst_cnt + 1;
        end
        else begin
            dw_inst_cnt <= dw_inst_cnt;
        end
    end

    assign bitmask_reload = dwconv_start & (dw_inst_cnt == 0);
    assign bitmask_shift = dwconv_start & (dw_inst_cnt != 0);
    
    assign dw_kernel_cycle = (dw_kernel_size == 3) ? 4'd3 : dw_kernel_size - 1;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            row_cnt <= 4'd0;
        end
        else if (dwconv_start) begin
	    row_cnt <= dw_top_pad ? 4'd0 : (dw_kernel_size >> 1);
        end
        else if (dw_kernel_size_cnt == dw_kernel_cycle) begin
            row_cnt <= row_cnt + dw_stride + 1;
        end
        else begin
            row_cnt <= row_cnt;
        end
    end

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            dw_kernel_size_cnt <= 4'd0;
        end
        else if (dwconv_start | (dw_kernel_size_cnt == dw_kernel_cycle)) begin
            dw_kernel_size_cnt <= 4'd0;
        end
        else if (dw_conv_state) begin
            dw_kernel_size_cnt <= dw_kernel_size_cnt + 1;
        end
        else begin
            dw_kernel_size_cnt <= dw_kernel_size_cnt;
        end
    end

    //dw_wr_logic
    wire dw_WE0, dw_WE1;
    reg [3:0] dw_cram_wr_addr;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            dw_cram_wr_addr <= 4'd0;
        end
        else if (dw_WE0 | dw_WE1) begin
            dw_cram_wr_addr <= (dw_cram_wr_addr == dw_inst_num[3:0]) ? 4'd0 : (dw_cram_wr_addr + 1);
        end
        else begin
            dw_cram_wr_addr <= 4'd0;
        end
    end

    assign dw_WE0 = ((cram_mode == 3'b010) & lb_data_in_vld & (LB_mv_cub_dst_sel == 2'b01)) | ((cram_mode == 3'b101) & Y_mode_pre_en & ~Y_mode_cram_sel & BC_data_vld);
    assign dw_WE1 = ((cram_mode == 3'b010) & lb_data_in_vld & (LB_mv_cub_dst_sel == 2'b10)) | ((cram_mode == 3'b101) & Y_mode_pre_en & Y_mode_cram_sel & BC_data_vld);

    //dw_rd_logic
    wire [4:0] dw_cram_rd_addr;
    reg dw_RE0, dw_RE1;
    reg dw_RE0_r, dw_RE1_r;
    reg dw_RE0_rr, dw_RE1_rr;
    wire cram_left_flag;

    assign dw_cram_rd_addr = row_cnt - (dw_kernel_size >> 1) + dw_kernel_size_cnt;
    assign cram_left_flag = ((dw_stride == 0) & (dw_inst_cnt[2:0] < 4)) | ((dw_stride == 1) & (dw_inst_cnt[1:0] < 2)); //dw_stride support : 1,2
    always @(*) begin
        if (dw_conv_state) begin
            if (cram_left_flag) begin
                dw_RE0 = ((dw_kernel_size == 3) & (dw_kernel_size_cnt == 3)) ? 1'b0 : 1'b1;
		        dw_RE1 = (cross_ram_from_right & ~dw_right_pad) | (cross_ram_from_left & ~dw_left_pad);
            end
            else begin
                dw_RE1 = ((dw_kernel_size == 3) & (dw_kernel_size_cnt == 3)) ? 1'b0 : 1'b1;
		        dw_RE0 = cross_ram_from_left | (cross_ram_from_right & ~dw_right_pad);
	        end
	    end
        else begin
            dw_RE0 = 1'b0;
            dw_RE1 = 1'b0;
        end
    end

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            dw_RE0_r <= 1'b0;
            dw_RE1_r <= 1'b0;
            dw_RE0_rr <= 1'b0;
            dw_RE1_rr <= 1'b0;
        end
        else begin
            dw_RE0_r <= dw_RE0;
            dw_RE1_r <= dw_RE1;
            dw_RE0_rr <= dw_RE0_r;
            dw_RE1_rr <= dw_RE1_r;
        end
    end

    reg dw_row_pading_flag;
    reg dw_row_pading_flag_r;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            dw_row_pading_flag <= 1'b0;
            dw_row_pading_flag_r <= 1'b0;
        end
        else begin
            dw_row_pading_flag <= dw_conv_state & (dw_cram_rd_addr[4] | (dw_cram_rd_addr > dw_trans_num));
            dw_row_pading_flag_r <= dw_row_pading_flag;
        end
    end

    always @(*) begin
        if (cram_data_out_vld & ~dw_row_pading_flag_r) begin
            if (cram_left_flag) begin
                cram_data_out[96-1:32] = Q0[96-1:32];
                cram_data_out[128-1:96] = dw_left_pad ? 32'd0 : (cross_ram_from_left ? Q1[128-1:96] : Q0[128-1:96]);
                cram_data_out[32-1:0] = (dw_right_pad & cross_ram_from_right) ? 32'd0 : (cross_ram_from_right ? Q1[32-1:0] : Q0[32-1:0]);
            end
            else begin
                cram_data_out[96-1:32] = Q1[96-1:32];
                cram_data_out[128-1:96] = cross_ram_from_left ? Q0[128-1:96] : Q1[128-1:96];
                cram_data_out[32-1:0] = (dw_right_pad & cross_ram_from_right) ? 32'd0 : (cross_ram_from_right ? Q0[32-1:0] : Q1[32-1:0]);
            end
        end
        else begin
            cram_data_out = 128'd0;
        end
    end

    reg [3:0] dw_kernel_size_cnt_r;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            dw_kernel_size_cnt_r <= 4'd0;
            dw_weight_out_sequence <= 4'd0;
        end
        else begin
            dw_kernel_size_cnt_r <= dw_kernel_size_cnt;
            dw_weight_out_sequence <= dw_kernel_size_cnt_r;
        end
    end

    assign cram_data_out_vld = (dw_RE0_rr | dw_RE1_rr) & (dw_weight_out_sequence < dw_kernel_size);
    reg cram_data_out_vld_r;
    reg [3:0] dw_weight_out_sequence_r;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            cram_data_out_vld_r <= 1'b0;
            dw_weight_out_sequence_r <= 4'd0;
        end
        else begin
            cram_data_out_vld_r <= cram_data_out_vld;
            dw_weight_out_sequence_r <= dw_weight_out_sequence;
        end
    end
    assign dw_mac_first = cram_data_out_vld_r & (dw_weight_out_sequence_r == 0);
    
    assign dw_mac_last = cram_data_out_vld_r & (dw_weight_out_sequence_r == dw_kernel_size - 1);
    //conv_psum_ctrl
    reg conv3d_state;
    wire conv3d_end;
    reg [8:0] conv3d_start_r;
    wire conv3d_start_psum_wr;
    wire conv3d_start_psum_rd;
    wire conv3d_start_psum_wr_index;
    wire conv3d_start_psum_rd_index;
    reg [4:0] psum_rd_num_r;
    reg [4:0] conv3d_psum_start_index_wr;
    reg [4:0] conv3d_psum_end_index_wr;
    reg [4:0] conv3d_psum_start_index_rd;
    reg [4:0] conv3d_psum_end_index_rd;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            conv3d_start_r <= 9'b0;
        end
        else begin
            conv3d_start_r <= {conv3d_start_r[7:0], conv3d_start};
        end
    end
    assign conv3d_start_psum_wr = (cram_mode == 3'b001) ? conv3d_start_r[8] : conv3d_start_r[7];
    assign conv3d_start_psum_rd = ((cram_mode == 3'b001) ? conv3d_start_r[5] : conv3d_start_r[4]) & ~conv3d_first_subch_flag;
    assign conv3d_start_psum_wr_index =(cram_mode == 3'b001) ? conv3d_start_r[6] : conv3d_start_r[5];
    assign conv3d_start_psum_rd_index = (cram_mode == 3'b001) ? conv3d_start_r[3] : conv3d_start_r[2];


    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            psum_rd_num_r <= 5'd0;
        end
        else if (psum_data_trans_start) begin
            psum_rd_num_r <= psum_rd_num;
        end
        else begin
            psum_rd_num_r <= psum_rd_num_r;
        end
    end

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            conv3d_psum_start_index_wr <= 5'b0;
            conv3d_psum_end_index_wr <= 5'b0;
        end
        else if (psum_data_trans_start) begin
            conv3d_psum_start_index_wr <= 5'd0;
            conv3d_psum_end_index_wr <= psum_rd_num;            
        end
        else if (conv3d_start_psum_wr_index) begin
            conv3d_psum_start_index_wr <= conv3d_psum_start_index;
            conv3d_psum_end_index_wr <= conv3d_psum_end_index;
        end
        else begin
            conv3d_psum_start_index_wr <= conv3d_psum_start_index_wr;
            conv3d_psum_end_index_wr <= conv3d_psum_end_index_wr;
        end
    end

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            conv3d_psum_start_index_rd <= 5'b0;
            conv3d_psum_end_index_rd <= 5'b0;
        end
        else if (psum_data_trans_start) begin
            conv3d_psum_start_index_rd <= 5'd0;
            conv3d_psum_end_index_rd <= psum_rd_num;            
        end
        else if (conv3d_start_psum_rd_index) begin
            conv3d_psum_start_index_rd <= conv3d_psum_start_index;
            conv3d_psum_end_index_rd <= conv3d_psum_end_index;
        end
        else begin
            conv3d_psum_start_index_rd <= conv3d_psum_start_index_rd;
            conv3d_psum_end_index_rd <= conv3d_psum_end_index_rd;
        end
    end


    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            conv3d_state <= 1'b0;
        end
        else if (conv3d_start_psum_wr) begin
            conv3d_state <= 1'b1;
        end
        else if (conv3d_end) begin
            conv3d_state <= 1'b0;
        end
        else begin
            conv3d_state <= conv3d_state;
        end
    end

    reg conv3d_psum_rd_state;
    reg [4:0] psum_rd_addr;
    reg [13:0] psum_add_cnt;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            psum_add_cnt <= 14'd0;
        end
	//else if ((conv3d_psum_rd_state & (psum_rd_addr == psum_rd_num_r)) | (conv3d_start & conv3d_first_subch_flag)) begin	
        else if (conv3d_start & conv3d_first_subch_flag) begin
	    psum_add_cnt <= 14'd0;
	end
        else if(conv3d_end) begin
            psum_add_cnt <= psum_add_cnt + 1;
        end
        else begin
            psum_add_cnt <= psum_add_cnt;
        end
    end

    reg [4:0] psum_wr_addr;
    reg psum_data_in_vld;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            psum_data_in_vld <= 1'b0;
        end
        else begin
            psum_data_in_vld <= mac_data_in_vld & ((cram_mode == 3'b000) | (cram_mode == 3'b001) | (cram_mode == 3'b100));
        end
    end

/*
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            psum_pad_in_vld <= 1'b0;
        end
        else if (conv3d_state & (conv3d_psum_start_index_wr != 5'd0) & (psum_add_cnt < 2)) begin
            if (psum_wr_addr == conv3d_psum_end_index_wr) begin
                psum_pad_in_vld <= 1;                
            end
            else if(psum_wr_addr == (conv3d_psum_start_index_wr - 1)) begin
                psum_pad_in_vld <= 0;
            end
            else begin
                psum_pad_in_vld <= psum_pad_in_vld;
            end
        end
        else begin
            psum_pad_in_vld <= 0;
        end
    end
*/
/*
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            conv3d_end <= 1'b0;
        end
        else if (conv3d_state) begin 
            //if((conv3d_psum_start_index_wr != 5'd0) & ((psum_add_cnt < 2))) begin
                //conv3d_end <= (psum_wr_addr == (conv3d_psum_start_index_wr - 1)) ? 1 : 0;
            //end
            begin
                conv3d_end <= (psum_wr_addr == conv3d_psum_end_index_wr) ? 1 : 0;
            end
        end
        else begin
            conv3d_end <= 0;
        end
    end
*/
    reg psum_rd_flag;
    always @ (posedge clk or negedge rstn) begin
        if (!rstn) begin
            psum_rd_flag <= 1'b0;
        end
        else if (psum_data_trans_start) begin
            psum_rd_flag <= 1'b0;
        end
        else begin 
            psum_rd_flag <= conv3d_start_psum_rd ? ~psum_rd_flag : psum_rd_flag;
        end
    end

    assign conv3d_end = conv3d_state && (psum_wr_addr == conv3d_psum_end_index_wr);

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            conv3d_psum_rd_state <= 1'b0;
        end
        else if (psum_data_trans_start) begin
            conv3d_psum_rd_state <= 1'b1;
        end
        else if (conv3d_psum_rd_state & (psum_rd_addr == psum_rd_num_r)) begin
            conv3d_psum_rd_state <= 1'b0;
        end
        else begin
            conv3d_psum_rd_state <= conv3d_psum_rd_state;
        end
    end


    // psum_wr_logic

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            psum_wr_addr <= 4'd0;
        end
        else if (conv3d_start_psum_wr) begin
            psum_wr_addr <= conv3d_psum_start_index_wr;
        end 
        else if (psum_data_in_vld) begin
            psum_wr_addr <= (psum_wr_addr == conv3d_psum_end_index_wr) ? 5'd0 : psum_wr_addr + 1;
        end
        else begin
            psum_wr_addr <= psum_wr_addr;
        end
    end

    reg [127:0] mac_data_in_r;
    always @ (posedge clk or negedge rstn) begin
        if (!rstn) begin
            mac_data_in_r <= 128'd0;
        end
        else if (mac_data_in_vld) begin
            mac_data_in_r <= mac_data_in;
        end
        else begin 
            mac_data_in_r <= mac_data_in_r;
        end
    end


    wire [64-1:0] psum_wr_data;
    wire [64-1:0] psum_adder_in;
    reg [64-1:0] psum_adder_out;
    always @ (posedge clk or negedge rstn) begin
        if (!rstn) begin
            psum_adder_out <= 64'd0;
        end
        else if (mac_data_in_vld & (cram_mode[2:1] == 2'b00)) begin
            psum_adder_out <= {psum_adder_in[63:32] + mac_data_in[63:32], psum_adder_in[31:0] + mac_data_in[31:0]};
        end
        else begin 
            psum_adder_out <= psum_adder_out;
        end
    end

    assign psum_wr_data = ((psum_add_cnt == 0) ? mac_data_in_r[63:0] : psum_adder_out);

    wire [128-1:0] psum_wr_data_4ch;
    wire [128-1:0] psum_adder_in_4ch;
    reg [128-1:0] psum_adder_out_4ch;
    always @ (posedge clk or negedge rstn) begin
        if (!rstn) begin
            psum_adder_out_4ch <= 64'd0;
        end
        else if (mac_data_in_vld & (cram_mode == 3'b100)) begin
            psum_adder_out_4ch <= {psum_adder_in_4ch[127:96] + mac_data_in[127:96], psum_adder_in_4ch[95:64] + mac_data_in[95:64], psum_adder_in_4ch[63:32] + mac_data_in[63:32], psum_adder_in_4ch[31:0] + mac_data_in[31:0]};
        end
        else begin 
            psum_adder_out_4ch <= psum_adder_out_4ch;
        end
    end

    assign psum_wr_data_4ch = (psum_add_cnt == 0) ? mac_data_in_r : psum_adder_out_4ch;



    wire conv3d_WE0_a;
    wire conv3d_WE0_b;
    wire conv3d_WE1_a;
    wire conv3d_WE1_b;
    assign conv3d_WE0_a = (psum_data_in_vld) & ~psum_add_cnt[0] & ((cram_mode == 3'b100) ? 1'b1 : ~psum_wr_addr[4]);
    assign conv3d_WE0_b = (psum_data_in_vld) & ~psum_add_cnt[0] & ((cram_mode == 3'b100) ? 1'b1 : psum_wr_addr[4]);
    assign conv3d_WE1_a = (psum_data_in_vld) & psum_add_cnt[0] & ((cram_mode == 3'b100) ? 1'b1 : ~psum_wr_addr[4]);
    assign conv3d_WE1_b = (psum_data_in_vld) & psum_add_cnt[0] & ((cram_mode == 3'b100) ? 1'b1 : psum_wr_addr[4]);
    
    //psum_rd_logic
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            psum_rd_addr <= 5'd0;
        end
        else if (conv3d_start_psum_rd) begin
            psum_rd_addr <= conv3d_psum_start_index_rd;
        end
        else if (psum_data_trans_start) begin
            psum_rd_addr <= 5'd0;
        end

        //else if ((mac_data_vld_2cycle_bf & (psum_add_cnt > 0)) | conv3d_psum_rd_state) begin
        else if ((mac_data_vld_2cycle_bf) | conv3d_psum_rd_state) begin
            psum_rd_addr <= (psum_rd_addr == conv3d_psum_end_index_rd) ? 5'd0 : psum_rd_addr + 1;
        end
        else begin
            psum_rd_addr <= psum_rd_addr;
        end
    end

    wire conv3d_RE0_a_add;
    wire conv3d_RE0_b_add;
    wire conv3d_RE1_a_add;
    wire conv3d_RE1_b_add;
    wire conv3d_RE0_a_rd;
    wire conv3d_RE0_b_rd;
    wire conv3d_RE1_a_rd;
    wire conv3d_RE1_b_rd;

/*
    assign conv3d_RE0_a_add = mac_data_vld_2cycle_bf & psum_add_cnt[0] & (psum_add_cnt > 0) & ((cram_mode == 3'b100) ? 1'b1 : ~psum_rd_addr[4]);
    assign conv3d_RE0_b_add = mac_data_vld_2cycle_bf & psum_add_cnt[0] & (psum_add_cnt > 0) & ((cram_mode == 3'b100) ? 1'b1 : psum_rd_addr[4]);
    assign conv3d_RE1_a_add = mac_data_vld_2cycle_bf & ~psum_add_cnt[0] & (psum_add_cnt > 0) & ((cram_mode == 3'b100) ? 1'b1 : ~psum_rd_addr[4]); 
    assign conv3d_RE1_b_add = mac_data_vld_2cycle_bf & ~psum_add_cnt[0] & (psum_add_cnt > 0) & ((cram_mode == 3'b100) ? 1'b1 : psum_rd_addr[4]); 
*/
    assign conv3d_RE0_a_add = mac_data_vld_2cycle_bf & psum_rd_flag & ((cram_mode == 3'b100) ? 1'b1 : ~psum_rd_addr[4]);
    assign conv3d_RE0_b_add = mac_data_vld_2cycle_bf & psum_rd_flag & ((cram_mode == 3'b100) ? 1'b1 : psum_rd_addr[4]);
    assign conv3d_RE1_a_add = mac_data_vld_2cycle_bf & ~psum_rd_flag & ((cram_mode == 3'b100) ? 1'b1 : ~psum_rd_addr[4]); 
    assign conv3d_RE1_b_add = mac_data_vld_2cycle_bf & ~psum_rd_flag & ((cram_mode == 3'b100) ? 1'b1 : psum_rd_addr[4]); 

    reg conv3d_RE0_a_add_r;
    reg conv3d_RE0_b_add_r;
    reg conv3d_RE1_a_add_r;
    reg conv3d_RE1_b_add_r;     
    reg conv3d_RE0_a_add_rr;
    reg conv3d_RE0_b_add_rr;
    reg conv3d_RE1_a_add_rr;
    reg conv3d_RE1_b_add_rr;              

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            conv3d_RE0_a_add_r <= 1'b0;
            conv3d_RE0_b_add_r <= 1'b0;
            conv3d_RE1_a_add_r <= 1'b0;
            conv3d_RE1_b_add_r <= 1'b0;
            conv3d_RE0_a_add_rr <= 1'b0;
            conv3d_RE0_b_add_rr <= 1'b0;
            conv3d_RE1_a_add_rr <= 1'b0;
            conv3d_RE1_b_add_rr <= 1'b0;
        end
        else begin
            conv3d_RE0_a_add_r <= conv3d_RE0_a_add;
            conv3d_RE0_b_add_r <= conv3d_RE0_b_add;
            conv3d_RE1_a_add_r <= conv3d_RE1_a_add;
            conv3d_RE1_b_add_r <= conv3d_RE1_b_add;
            conv3d_RE0_a_add_rr <= conv3d_RE0_a_add_r;
            conv3d_RE0_b_add_rr <= conv3d_RE0_b_add_r;
            conv3d_RE1_a_add_rr <= conv3d_RE1_a_add_r;
            conv3d_RE1_b_add_rr <= conv3d_RE1_b_add_r;
        end
    end

    assign psum_adder_in = ({64{conv3d_RE0_a_add_rr}} & Q0[63:0]) | ({64{conv3d_RE0_b_add_rr}} & Q0[127:64]) | ({64{conv3d_RE1_a_add_rr}} & Q1[63:0]) | ({64{conv3d_RE1_b_add_rr}} & Q1[127:64]);
    assign psum_adder_in_4ch = conv3d_RE0_a_add_rr ? Q0 : Q1;


    assign conv3d_RE0_a_rd = conv3d_psum_rd_state & psum_add_cnt[0] & ((cram_mode == 3'b100) ? 1'b1 : ~psum_rd_addr[4]);
    assign conv3d_RE0_b_rd = conv3d_psum_rd_state & psum_add_cnt[0] & ((cram_mode == 3'b100) ? 1'b1 : psum_rd_addr[4]);
    assign conv3d_RE1_a_rd = conv3d_psum_rd_state & ~psum_add_cnt[0] & ((cram_mode == 3'b100) ? 1'b1 : ~psum_rd_addr[4]);
    assign conv3d_RE1_b_rd = conv3d_psum_rd_state & ~psum_add_cnt[0] & ((cram_mode == 3'b100) ? 1'b1 : psum_rd_addr[4]);
                              
    reg conv3d_RE0_a_rd_r;
    reg conv3d_RE0_b_rd_r;
    reg conv3d_RE1_a_rd_r;
    reg conv3d_RE1_b_rd_r;     
    reg conv3d_RE0_a_rd_rr;
    reg conv3d_RE0_b_rd_rr;
    reg conv3d_RE1_a_rd_rr;
    reg conv3d_RE1_b_rd_rr;              

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            conv3d_RE0_a_rd_r <= 1'b0;
            conv3d_RE0_b_rd_r <= 1'b0;
            conv3d_RE1_a_rd_r <= 1'b0;
            conv3d_RE1_b_rd_r <= 1'b0;
            conv3d_RE0_a_rd_rr <= 1'b0;
            conv3d_RE0_b_rd_rr <= 1'b0;
            conv3d_RE1_a_rd_rr <= 1'b0;
            conv3d_RE1_b_rd_rr <= 1'b0;
        end
        else begin
            conv3d_RE0_a_rd_r <= conv3d_RE0_a_rd;
            conv3d_RE0_b_rd_r <= conv3d_RE0_b_rd;
            conv3d_RE1_a_rd_r <= conv3d_RE1_a_rd;
            conv3d_RE1_b_rd_r <= conv3d_RE1_b_rd;
            conv3d_RE0_a_rd_rr <= conv3d_RE0_a_rd_r;
            conv3d_RE0_b_rd_rr <= conv3d_RE0_b_rd_r;
            conv3d_RE1_a_rd_rr <= conv3d_RE1_a_rd_r;
            conv3d_RE1_b_rd_rr <= conv3d_RE1_b_rd_r;
        end
    end

    wire [63:0] psum_data_out_ori;

    assign psum_data_out_ori = ({64{conv3d_RE0_a_rd_rr}} & Q0[63:0]) | ({64{conv3d_RE0_b_rd_rr}} & Q0[127:64])
                             | ({64{conv3d_RE1_a_rd_rr}} & Q1[63:0]) | ({64{conv3d_RE1_b_rd_rr}} & Q1[127:64]);
    always @(*) begin
        if(cram_mode == 3'b001 & (weight_precision != 3'b010)) begin
            psum_data_out = psum_data_out_ori & {{32{psum_rd_ch_sel}}, {32{~psum_rd_ch_sel}}};
        end
        else if(cram_mode == 3'b100) begin
            psum_data_out = psum_rd_ch_sel ? (({64{conv3d_RE0_b_rd_rr}} & Q0[127:64]) | ({64{conv3d_RE1_b_rd_rr}} & Q1[127:64])) : (({64{conv3d_RE1_a_rd_rr}} & Q1[63:0]) | ({64{conv3d_RE0_a_rd_rr}} & Q0[63:0]));
        end
	else begin
            psum_data_out = psum_data_out_ori;
        end
    end

    assign psum_data_out_vld = conv3d_RE0_a_rd_rr | conv3d_RE0_b_rd_rr | conv3d_RE1_a_rd_rr | conv3d_RE1_b_rd_rr;

    //alu_ctr

    reg cram_access_rd_req_r;
    reg [1:0] cram_access_sel_r;
    reg [1:0] cram_access_sel_rr;    
    always@(posedge clk or negedge rstn) begin
        if(!rstn) begin
            cram_access_rd_req_r <= 1'b0;
            cram_access_rd_data_vld <= 1'b0;
            cram_access_sel_r <= 2'b0;
            cram_access_sel_rr <= 2'b0;
        end
        else begin
            cram_access_rd_req_r <= cram_access_rd_req;
            cram_access_rd_data_vld <= cram_access_rd_req_r;
            cram_access_sel_r <= {cram_access_addr[6:5]};
            cram_access_sel_rr <= cram_access_sel_r;
        end
    end
    
    always @(*) begin
        case (cram_access_sel_rr)
            2'b00: cram_access_rd_data = Q0[31:0];
            2'b01: cram_access_rd_data = Q0[63:32];
            2'b10: cram_access_rd_data = Q1[31:0];
            2'b11: cram_access_rd_data = Q1[63:32];
            default: cram_access_rd_data = 32'd0;
        endcase
    end
    
    assign cram_access_gnt = ~(CE0_a | CE0_b | CE1_a | CE1_b);

    //cram

    wire conv3d_RE0_a;
    wire conv3d_RE0_b;
    wire conv3d_RE1_a;
    wire conv3d_RE1_b;

    assign conv3d_RE0_a = conv3d_RE0_a_add | conv3d_RE0_a_rd;
    assign conv3d_RE0_b = conv3d_RE0_b_add | conv3d_RE0_b_rd;
    assign conv3d_RE1_a = conv3d_RE1_a_add | conv3d_RE1_a_rd;
    assign conv3d_RE1_b = conv3d_RE1_b_add | conv3d_RE1_b_rd;

    wire alu_WE0_a;
    wire alu_WE0_b;
    wire alu_WE1_a;
    wire alu_WE1_b;
    wire alu_RE0_a;
    wire alu_RE0_b;
    wire alu_RE1_a;
    wire alu_RE1_b;
 

    assign alu_WE0_a = cram_access_wr_req & ({cram_access_addr[6], cram_access_addr[4]} == 2'b00);
    assign alu_WE0_b = cram_access_wr_req & ({cram_access_addr[6], cram_access_addr[4]} == 2'b01);
    assign alu_WE1_a = cram_access_wr_req & ({cram_access_addr[6], cram_access_addr[4]} == 2'b10);
    assign alu_WE1_b = cram_access_wr_req & ({cram_access_addr[6], cram_access_addr[4]} == 2'b11);
    assign alu_RE0_a = cram_access_rd_req & ({cram_access_addr[6], cram_access_addr[4]} == 2'b00);
    assign alu_RE0_b = cram_access_rd_req & ({cram_access_addr[6], cram_access_addr[4]} == 2'b01);
    assign alu_RE1_a = cram_access_rd_req & ({cram_access_addr[6], cram_access_addr[4]} == 2'b10);
    assign alu_RE1_b = cram_access_rd_req & ({cram_access_addr[6], cram_access_addr[4]} == 2'b11);

    assign WE0_a = dw_WE0 | conv3d_WE0_a | alu_WE0_a;
    assign WE0_b = dw_WE0 | conv3d_WE0_b | alu_WE0_b;
    assign WE1_a = dw_WE1 | conv3d_WE1_a | alu_WE1_a;
    assign WE1_b = dw_WE1 | conv3d_WE1_b | alu_WE1_b;
    assign RE0_a = dw_RE0 | conv3d_RE0_a | alu_RE0_a;
    assign RE0_b = dw_RE0 | conv3d_RE0_b | alu_RE0_b;
    assign RE1_a = dw_RE1 | conv3d_RE1_a | alu_RE1_a;
    assign RE1_b = dw_RE1 | conv3d_RE1_b | alu_RE1_b;

    assign CE0_a = WE0_a | RE0_a;
    assign CE0_b = WE0_b | RE0_b;
    assign CE1_a = WE1_a | RE1_a;
    assign CE1_b = WE1_b | RE1_b;

    assign rd_addr0 = ({4{dw_RE0}} & dw_cram_rd_addr[3:0]) | ({4{conv3d_RE0_a | conv3d_RE0_b}} & psum_rd_addr[3:0]) | ({4{alu_RE0_a | alu_RE0_b}} & cram_access_addr[3:0]);
    assign rd_addr1 = ({4{dw_RE1}} & dw_cram_rd_addr[3:0]) | ({4{conv3d_RE1_a | conv3d_RE1_b}} & psum_rd_addr[3:0]) | ({4{alu_RE1_a | alu_RE1_b}} & cram_access_addr[3:0]);
    assign wr_addr0 = ({4{dw_WE0}} & dw_cram_wr_addr) | ({4{conv3d_WE0_a | conv3d_WE0_b}} & psum_wr_addr[3:0]) | ({4{alu_WE0_a | alu_WE0_b}} & cram_access_addr[3:0]);
    assign wr_addr1 = ({4{dw_WE1}} & dw_cram_wr_addr) | ({4{conv3d_WE1_a | conv3d_WE1_b}} & psum_wr_addr[3:0]) | ({4{alu_WE1_a | alu_WE1_b}} & cram_access_addr[3:0]);
    
    always @(*) begin
        if (~cram_access_wr_req & (cram_mode == 3'b010)) begin
            D = lb_data_in;
        end
        else if(~cram_access_wr_req & (cram_mode[2:1] == 2'b00)) begin
            D = psum_wr_addr[4] ? {psum_wr_data, 64'd0} : {64'd0, psum_wr_data};
        end
        else if(~cram_access_wr_req & (cram_mode == 3'b100)) begin
            D = psum_wr_data_4ch;
        end
        else if (~cram_access_wr_req & (cram_mode == 3'b101)) begin
            D = BC_data_in;
        end 
        else begin
            case (cram_access_addr[5:4])
                2'b00: D = {96'd0, cram_access_wr_data};
                2'b01: D = {64'd0, cram_access_wr_data, 32'd0}; 
                2'b10: D = {32'd0, cram_access_wr_data, 64'd0};
                2'b11: D = {cram_access_wr_data, 96'd0};
                default: D = 128'd0;
            endcase
        end
    end

    Cram_16x128 Cram_16x128_U0 (
        .clk(clk),
        .CE_a(CE0_a),
        .CE_b(CE0_b),
        .WE_a(WE0_a),
        .WE_b(WE0_b),
        .D(D),
        .wr_addr(wr_addr0),
        .rd_addr(rd_addr0),
        .Q(Q0)
    );

    Cram_16x128 Cram_16x128_U1 (
        .clk(clk),
        .CE_a(CE1_a),
        .CE_b(CE1_b),
        .WE_a(WE1_a),
        .WE_b(WE1_b),
        .D(D),
        .wr_addr(wr_addr1),
        .rd_addr(rd_addr1),
        .Q(Q1)
    );
endmodule


