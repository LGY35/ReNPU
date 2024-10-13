// core先发给dnoc_itf_ctr，然后再去配置四个通道

module dnoc_itf_ctr #(
    parameter NODE_ID = 4'd0
)
(
    input                           clk,
    input                           rst_n,

    //core cfg
    input           [6:0]           core_cfg_addr,
    input           [12:0]          core_cfg_data,
    input                           core_cfg_valid,

    input                           core_cmd_req,
    input           [2:0]           core_cmd_addr,  // 0-4对应：4个通道和finish
    output  logic                   core_cmd_gnt,
    output  logic                   core_cmd_ok,
    // input           [1:0]           core_cmd_trans_mode,
    //00: core in
    //01: core out
    //10: dma rd
    //11: dma wr

    //core data
    // input   logic   [255:0]         core_out_data,
    // input   logic                   core_out_valid,

    // output  logic   [255:0]         core_in_data,
    // output  logic                   core_in_valid,


    //ctr dma read channel
    output  logic                   core_cmd_dma_rd_req,
    input                           core_cmd_dma_rd_gnt,

    input                           d_r_transaction_done,

    output  logic                   c_cfg_d_r_pingpong_en,
    output  logic   [10:0]          c_cfg_d_r_pingpong_num,
    output  logic   [12:0]          c_cfg_d_r_ping_lenth,
    output  logic   [12:0]          c_cfg_d_r_pong_lenth,
    
    output  logic   [1:0][12:0]     c_cfg_d_r_ram_base_addr,
    output  logic   [24:0]          c_cfg_d_r_noc_base_addr,
    output  logic   [3:0][12:0]     c_cfg_d_r_loop_lenth,
    output  logic   [3:0][12:0]     c_cfg_d_r_loop_gap,

    output  logic                   c_cfg_d_r_dma_transfer, // addr : DMA node ID
    // output  logic                   c_cfg_d_r_dma_access_mode,

    //ctr dma write channel
    output  logic                   core_cmd_dma_wr_req,
    input                           core_cmd_dma_wr_gnt,

    input                           d_w_transaction_done,

    output  logic                   c_cfg_d_w_pingpong_en,
    output  logic   [10:0]          c_cfg_d_w_pingpong_num,
    output  logic   [12:0]          c_cfg_d_w_ping_lenth,
    output  logic   [12:0]          c_cfg_d_w_pong_lenth,
    
    output  logic   [1:0][12:0]     c_cfg_d_w_ram_base_addr,
    output  logic   [24:0]          c_cfg_d_w_noc_base_addr,
    output  logic   [3:0][12:0]     c_cfg_d_w_loop_lenth,
    output  logic   [3:0][12:0]     c_cfg_d_w_loop_gap,

    output  logic                   c_cfg_d_w_mc,
    output  logic                   c_cfg_d_w_dma_transfer, //
    output  logic                   c_cfg_d_w_dma_access_mode,

    output  logic         [11:0]    c_cfg_d_w_noc_mc_scale, //\u77e9\u5f62\u533a\u57df

    output  logic         [11:0]    c_cfg_d_w_sync_target,  //12\u4e2a\u8282\u70b9\u540c\u6b65\u76ee\u6807

    //ctr core read channel
    output  logic                   core_cmd_core_rd_req,
    input                           core_cmd_core_rd_gnt,

    input                           c_r_transaction_done,

    output  logic                   c_cfg_c_r_pingpong_en,
    output  logic   [10:0]          c_cfg_c_r_pingpong_num,
    output  logic   [12:0]          c_cfg_c_r_ping_lenth,
    output  logic   [12:0]          c_cfg_c_r_pong_lenth,
    
    output  logic                   c_cfg_c_r_local_access, //\u8ba1\u7b97\u5f97\u5230\uff0c\u5e76\u975e\u76f4\u63a5\u914d\u7f6e

    output  logic   [1:0][12:0]     c_cfg_c_r_base_addr,
    output  logic   [3:0]           c_cfg_c_r_noc_target_id, //相当于地址的高4bit，决定节点地址
    // output  logic   [23:0]          c_cfg_c_r_noc_base_addr,
    output  logic   [3:0][12:0]     c_cfg_c_r_loop_lenth,
    output  logic   [3:0][12:0]     c_cfg_c_r_loop_gap,

    output  logic                   c_cfg_c_r_mc,
    output  logic                   c_cfg_c_r_dma_transfer, //
    output  logic                   c_cfg_c_r_dma_access_mode,

    output  logic         [11:0]    c_cfg_c_r_noc_mc_scale, //矩形区域
    output  logic         [11:0]    c_cfg_c_r_sync_target,  //12个节点同步目标

    output  logic         [3:0]     c_cfg_c_r_pad_up_len,
    output  logic         [3:0]     c_cfg_c_r_pad_right_len,
    output  logic         [3:0]     c_cfg_c_r_pad_left_len,
    output  logic         [3:0]     c_cfg_c_r_pad_bottom_len,

    output  logic         [10:0]    c_cfg_c_r_pad_row_num,
    output  logic         [10:0]    c_cfg_c_r_pad_col_num,
    output  logic                   c_cfg_c_r_pad_mode,

    //ctr core write channel
    output  logic                   core_cmd_core_wr_req,
    input                           core_cmd_core_wr_gnt,

    input                           c_w_transaction_done,

    output  logic                   c_cfg_c_w_local_access, //计算得到，并非直接配置

    output  logic                   c_cfg_c_w_pingpong_en,
    output  logic   [10:0]          c_cfg_c_w_pingpong_num,
    output  logic   [12:0]          c_cfg_c_w_ping_lenth,
    output  logic   [12:0]          c_cfg_c_w_pong_lenth,
    
    output  logic   [1:0][12:0]     c_cfg_c_w_base_addr,
    output  logic   [3:0]           c_cfg_c_w_noc_target_id,
    // output  logic   [23:0]          c_cfg_c_w_noc_base_addr,
    output  logic   [3:0][12:0]     c_cfg_c_w_loop_lenth,
    output  logic   [3:0][12:0]     c_cfg_c_w_loop_gap,

    output  logic                   c_cfg_c_w_dma_transfer, //
    // output  logic                   c_cfg_c_w_dma_access_mode,


    //----------------itf-------------------------------
    output  logic                   c_cfg_itf_irq_en,   //是否接收核的休眠中断；0：不接收；1：接收
    output  logic                   c_cfg_itf_single_fetch//是否指令同步；0：多核同步；1：单独取指

    // output  logic                   core_cmd_itf_req,
    // input                           core_cmd_itf_gnt

    // output  logic                   dmmu_L2_wr_cmd_req,
    // input                           dmmu_L2_wr_cmd_gnt,

    // output  logic                   dmmu_dma_rd_cmd_req,
    // input                           dmmu_dma_rd_cmd_gnt,

    // output  logic                   dmmu_dma_wr_cmd_req,
    // input                           dmmu_dma_wr_cmd_gnt,

    // input           [21:0]          core_cfg_L2_addr,
    // input           [21:0]          core_cfg_L2_lenth,
    // input           [21:0]          core_cfg_dma_addr,
    // input           [21:0]          core_cfg_dma_lenth,

    // //dmmu data
    // input           [255:0]         dmmu_rd_core_data,
    // input                           dmmu_rd_core_valid,

    // output  logic   [255:0]         core_dmmu_wr_data,
    // output  logic                   core_dmmu_wr_valid,

    // //ctr cmmu

    // output  logic                   cmmu_in_cmd_req,
    // input                           cmmu_in_cmd_gnt,

    // output  logic                   cmmu_out_cmd_req,
    // input                           cmmu_out_cmd_gnt,


    // //cmmu data
    // input           [255:0]         cmmu_in_core_data,
    // input                           cmmu_in_core_valid,

    // output  logic   [255:0]         core_cmmu_out_data,
    // output  logic                   core_cmmu_out_valid,

    // //core read channel cfg output
    // output  logic   [21:0]          core_cfg_core_rd_base_addr,
    // output  logic   [21:0]          core_cfg_core_rd_total_lenth,

    // //core write channel cfg output
    // output  logic   [21:0]          core_cfg_core_wr_base_addr,
    // output  logic   [21:0]          core_cfg_core_wr_total_lenth,

    //

    // output  logic   [2:0]           core_cfg_mode, //to be determined

    // // output  logic           c_cfg_c_r_mc, //broad read sel cmmu to noc output then noc input
    // output  logic                   c_cfg_c_w_mc,
    // output  logic                   c_cfg_c_r_local_access, //sel cmmu or dmmu
    

    // output  logic                   core_cfg_wr_local_access, //sel cmmu or dmmu

    // output  logic                   core_cfg_dma_rd_sync, //pingpong sync en signal

    // output  logic                   core_cfg_dma_wr_sync,


    // //core rd
    // output  logic                   c_cfg_c_r_mc,
    // output  logic   [3:0]           c_cfg_c_r_noc_target_id,
    // output  logic   [11:0]          c_cfg_c_r_noc_mc_scale,

    // output  logic   [11:0]          c_cfg_c_r_sync_target,

    // output  logic                   c_cfg_c_r_local_access,

    // // output  logic   [23:0]          c_cfg_c_r_long_base_addr,
    // // output  logic   [12:0]          c_cfg_c_r_short_base_addr,
    // output  logic   [1:0][12:0]     c_cfg_c_r_base_addr,
    // // output  logic   [12:0]          c_cfg_c_r_total_lenth,
    // output  logic   [12:0]          c_cfg_c_r_ping_lenth, //equal total lenth in none-pingpong mode
    // output  logic   [12:0]          c_cfg_c_r_pong_lenth,
    // output  logic                   c_cfg_c_r_pingpong_en,
    // output  logic   [10:0]          c_cfg_c_r_pingpong_num,


    //dma wr

    // output  logic   [1:0][12:0]     c_cfg_d_w_ram_base_addr,
    // // output  logic   [12:0]          c_cfg_d_w_ram_total_lenth,
    // output  logic   [12:0]          c_cfg_d_w_ping_lenth,
    // output  logic   [12:0]          c_cfg_d_w_pong_lenth,
    // output  logic                   c_cfg_d_w_pingpong_en,
    // output  logic   [10:0]          c_cfg_d_w_pingpong_num,


    // output  logic                   c_cfg_d_w_mc,
    // // output  logic   [3:0]           c_cfg_d_w_noc_target_id,
    // output  logic   [11:0]          c_cfg_d_w_noc_mc_scale,
    // output  logic   [23:0]          c_cfg_d_w_noc_base_addr, //11 13\u4e24\u7aef\u5730\u5740\u62fc\u63a5\u800c\u6210
    // // output  logic   [3:0]           c_cfg_d_w_noc_target_id, //to be included in c_cfg_d_w_noc_base_addr

    // output  logic   [11:0]          c_cfg_d_w_sync_target,

);

logic   [1:0]           core_cfg_addr_frag;
logic   [4:0]           core_cfg_addr_low;
logic   [12:0]          core_cfg_data_frag;

logic   [31:0][12:0]    core_cfg_core_rd_reg;
logic   [31:0][12:0]    core_cfg_core_wr_reg;

// logic   [31:0][17:0]    core_cfg_L2_rd_reg;
// logic   [31:0][17:0]    core_cfg_L2_wr_reg;

logic   [31:0][12:0]    core_cfg_dma_rd_reg;
logic   [31:0][12:0]    core_cfg_dma_wr_reg;

// frag 段地址 00 core rd; 01 core wr;  10 dma rd;  11 dma wr
assign core_cfg_addr_frag = core_cfg_addr[6:5];
// 低4bit为每个通道内的寄存器地址
assign core_cfg_addr_low = core_cfg_addr[4:0];
//写入寄存器的数据
assign core_cfg_data_frag = core_cfg_data[12:0];




//core read channel address calculate
logic                   c_cfg_c_r_address_mode; //0: basic phisical; 1: relative 
logic   [4:0]           c_cfg_c_r_relative_addr; // 0: + ; 1 : -
// logic                   c_cfg_c_r_address_remap;
// logic   [12:0]          c_cfg_c_r_address_remap_gap;

logic   [3:0]          c_cfg_c_r_noc_target_id_origin; 
logic   [3:0]          c_cfg_c_r_noc_target_id_cal;

// 目标节点计算
assign c_cfg_c_r_noc_target_id_cal = c_cfg_c_r_relative_addr[4] ? (NODE_ID - c_cfg_c_r_relative_addr[3:0]) : (NODE_ID + c_cfg_c_r_relative_addr[3:0]) ;
assign c_cfg_c_r_noc_target_id = c_cfg_c_r_address_mode ? c_cfg_c_r_noc_target_id_cal : c_cfg_c_r_noc_target_id_origin;

integer i;

// 向 core rd 通道的寄存器写入数据
always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        // 复位时，只有第30个clk接收core休眠中断
        for(i = 0; i < 32; i = i + 1) begin
            if(i == 30)
                core_cfg_core_rd_reg[i] <= {32{1'b1}};  // 接收核的休眠中断
            else
                core_cfg_core_rd_reg[i] <= 'b0; // 不接收
        end
    end
    else if(core_cfg_valid & (core_cfg_addr_frag == 2'd0)) begin
        core_cfg_core_rd_reg[core_cfg_addr_low] <= core_cfg_data_frag;
    end
end

// 是不是在本地传输数据，走local通道，即core从本地L2 RAM中rd数据
always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        c_cfg_c_r_local_access <= 'b0;
    end
    else if(core_cfg_valid & (core_cfg_addr_frag == 2'd0) & (core_cfg_addr_low == 5'd5)) begin
        // 在没有广播的情况下，如果是绝对寻址，targetid = NODE_ID 或者 相对寻址，相对地址为全0
        // 不考虑广播的情况，是因为，如果想要多节点读————即本节点读取好几个节点，包括本节点，那为了统一，读取本节点也要走mc
        // 节点的core rd先发送请求给router，然后router再返回来配置本地的dma wr通道，然后从本地的sram中读取数据，返回给core rd(饶了一圈)
        // (所以寄存器也要按照顺序配)
        if((((core_cfg_data_frag[3:0] == NODE_ID) & ~c_cfg_c_r_address_mode) | (c_cfg_c_r_address_mode & ~|c_cfg_c_r_relative_addr[3:0])) & ~c_cfg_c_r_mc)
            c_cfg_c_r_local_access <= 1'b1;
        else
            c_cfg_c_r_local_access <= 1'b0;
    end
end
// TODO: 记录： core wr 没有广播，因为广播是被动，收到了好多req，才给那些node发送，而不是主动的要写很多的node

// 从相应的寄存器中取出有效的字段
assign c_cfg_c_r_address_mode           = core_cfg_core_rd_reg[0][0];
assign c_cfg_c_r_relative_addr          = core_cfg_core_rd_reg[1][4:0];
assign c_cfg_c_r_mc                     = core_cfg_core_rd_reg[2][0];
assign c_cfg_c_r_dma_transfer           = core_cfg_core_rd_reg[3][0];
assign c_cfg_c_r_pingpong_en            = core_cfg_core_rd_reg[4][0];
assign c_cfg_c_r_noc_target_id_origin   = core_cfg_core_rd_reg[5][3:0];
assign c_cfg_c_r_base_addr[0]           = core_cfg_core_rd_reg[6][12:0];
assign c_cfg_c_r_base_addr[1]           = core_cfg_core_rd_reg[7][12:0];
assign c_cfg_c_r_loop_gap[0]            = core_cfg_core_rd_reg[8][12:0];
assign c_cfg_c_r_loop_gap[1]            = core_cfg_core_rd_reg[9][12:0];
assign c_cfg_c_r_loop_gap[2]            = core_cfg_core_rd_reg[10][12:0];
assign c_cfg_c_r_loop_gap[3]            = core_cfg_core_rd_reg[11][12:0];
assign c_cfg_c_r_loop_lenth[0]          = core_cfg_core_rd_reg[12][12:0];
assign c_cfg_c_r_loop_lenth[1]          = core_cfg_core_rd_reg[13][12:0];
assign c_cfg_c_r_loop_lenth[2]          = core_cfg_core_rd_reg[14][12:0];
assign c_cfg_c_r_loop_lenth[3]          = core_cfg_core_rd_reg[15][12:0];
assign c_cfg_c_r_pingpong_num           = core_cfg_core_rd_reg[16][10:0];
assign c_cfg_c_r_ping_lenth             = core_cfg_core_rd_reg[17][12:0];
assign c_cfg_c_r_pong_lenth             = core_cfg_core_rd_reg[18][12:0];
assign c_cfg_c_r_noc_mc_scale           = core_cfg_core_rd_reg[19][11:0];
assign c_cfg_c_r_sync_target            = core_cfg_core_rd_reg[20][11:0];
assign c_cfg_c_r_dma_access_mode        = core_cfg_core_rd_reg[21][0];
assign c_cfg_c_r_pad_left_len           = core_cfg_core_rd_reg[22][3:0];
assign c_cfg_c_r_pad_right_len          = core_cfg_core_rd_reg[23][3:0];
assign c_cfg_c_r_pad_up_len             = core_cfg_core_rd_reg[24][3:0];
assign c_cfg_c_r_pad_bottom_len         = core_cfg_core_rd_reg[25][3:0];
assign c_cfg_c_r_pad_row_num            = core_cfg_core_rd_reg[26][10:0];
assign c_cfg_c_r_pad_col_num            = core_cfg_core_rd_reg[27][10:0];
assign c_cfg_c_r_pad_mode               = core_cfg_core_rd_reg[28][0];


//core write channel address calculate
logic                   c_cfg_c_w_address_mode; //0: basic phisical; 1: relative 
logic   [4:0]           c_cfg_c_w_relative_addr; // 0: + ; 1 : -
// logic                   c_cfg_c_r_address_remap;
// logic   [12:0]          c_cfg_c_r_address_remap_gap;

logic   [3:0]          c_cfg_c_w_noc_target_id_origin; 
logic   [3:0]          c_cfg_c_w_noc_target_id_cal;

assign c_cfg_c_w_noc_target_id_cal = c_cfg_c_w_relative_addr[4] ? (NODE_ID - c_cfg_c_w_relative_addr[3:0]) : (NODE_ID + c_cfg_c_w_relative_addr[3:0]) ;
assign c_cfg_c_w_noc_target_id = c_cfg_c_w_address_mode ? c_cfg_c_w_noc_target_id_cal : c_cfg_c_w_noc_target_id_origin;


always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        core_cfg_core_wr_reg <= 'b0;
    end
    else if(core_cfg_valid & (core_cfg_addr_frag == 2'd1)) begin
        core_cfg_core_wr_reg[core_cfg_addr_low] <= core_cfg_data_frag;
    end
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        c_cfg_c_w_local_access <= 'b0;
    end
    else if(core_cfg_valid & (core_cfg_addr_frag == 2'd1) & (core_cfg_addr_low == 5'd4)) begin
        if((((core_cfg_data_frag[3:0] == NODE_ID) & ~c_cfg_c_w_address_mode) | (c_cfg_c_w_address_mode & ~|c_cfg_c_w_relative_addr[3:0])))
            c_cfg_c_w_local_access <= 1'b1;
        else
            c_cfg_c_w_local_access <= 1'd0;
    end
end

assign c_cfg_c_w_address_mode           = core_cfg_core_wr_reg[0][0];
assign c_cfg_c_w_relative_addr          = core_cfg_core_wr_reg[1][4:0];
assign c_cfg_c_w_dma_transfer           = core_cfg_core_wr_reg[2][0];
assign c_cfg_c_w_pingpong_en            = core_cfg_core_wr_reg[3][0];
assign c_cfg_c_w_noc_target_id_origin   = core_cfg_core_wr_reg[4][3:0];
assign c_cfg_c_w_base_addr[0]           = core_cfg_core_wr_reg[5][12:0];
assign c_cfg_c_w_base_addr[1]           = core_cfg_core_wr_reg[6][12:0];
assign c_cfg_c_w_loop_gap[0]            = core_cfg_core_wr_reg[7][12:0];
assign c_cfg_c_w_loop_gap[1]            = core_cfg_core_wr_reg[8][12:0];
assign c_cfg_c_w_loop_gap[2]            = core_cfg_core_wr_reg[9][12:0];
assign c_cfg_c_w_loop_gap[3]            = core_cfg_core_wr_reg[10][12:0];
assign c_cfg_c_w_loop_lenth[0]          = core_cfg_core_wr_reg[11][12:0];
assign c_cfg_c_w_loop_lenth[1]          = core_cfg_core_wr_reg[12][12:0];
assign c_cfg_c_w_loop_lenth[2]          = core_cfg_core_wr_reg[13][12:0];
assign c_cfg_c_w_loop_lenth[3]          = core_cfg_core_wr_reg[14][12:0];
assign c_cfg_c_w_pingpong_num           = core_cfg_core_wr_reg[15][10:0];
assign c_cfg_c_w_ping_lenth             = core_cfg_core_wr_reg[16][12:0];
assign c_cfg_c_w_pong_lenth             = core_cfg_core_wr_reg[17][12:0];
// assign c_cfg_c_w_dma_access_mode        = core_cfg_core_wr_reg[18][0];


//-------------------------------dma read channel address calculate--------------------------------------------//

logic                   c_cfg_d_r_address_mode;
logic   [4:0]           c_cfg_d_r_relative_addr;
// logic                   c_cfg_d_r_address_remap;
// logic   [12:0]          c_cfg_d_r_address_remap_gap;

logic   [11:0]          c_cfg_d_r_noc_base_addr_high;
logic   [12:0]          c_cfg_d_r_noc_base_addr_low;
logic   [3:0]           d_r_noc_base_addr_high_cal;
// logic   [12:0]          d_r_noc_base_addr_low_cal;
logic   [11:0]          d_r_noc_base_addr_high_sel;
// logic   [12:0]          d_r_noc_base_addr_low_sel;

assign d_r_noc_base_addr_high_cal = c_cfg_d_r_relative_addr[4] ? (NODE_ID - c_cfg_d_r_relative_addr[3:0]) : (NODE_ID + c_cfg_d_r_relative_addr[3:0]);
assign d_r_noc_base_addr_high_sel = c_cfg_d_r_address_mode ? {8'b0, d_r_noc_base_addr_high_cal} : c_cfg_d_r_noc_base_addr_high;
// 高位地址可以根据寻址模式变换
assign c_cfg_d_r_noc_base_addr = {d_r_noc_base_addr_high_sel, c_cfg_d_r_noc_base_addr_low};

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        core_cfg_dma_rd_reg <= 'b0;
    end
    else if(core_cfg_valid & (core_cfg_addr_frag == 2'd2)) begin
        core_cfg_dma_rd_reg[core_cfg_addr_low] <= core_cfg_data_frag;
    end
end

assign c_cfg_d_r_address_mode           = core_cfg_dma_rd_reg[0][0];
assign c_cfg_d_r_relative_addr          = core_cfg_dma_rd_reg[1][4:0];
assign c_cfg_d_r_dma_transfer           = core_cfg_dma_rd_reg[2][0];
assign c_cfg_d_r_pingpong_en            = core_cfg_dma_rd_reg[3][0];
assign c_cfg_d_r_ram_base_addr[0]       = core_cfg_dma_rd_reg[4][12:0];
assign c_cfg_d_r_ram_base_addr[1]       = core_cfg_dma_rd_reg[5][12:0];
assign c_cfg_d_r_noc_base_addr_low      = core_cfg_dma_rd_reg[6][12:0];
assign c_cfg_d_r_noc_base_addr_high     = core_cfg_dma_rd_reg[7][11:0];
assign c_cfg_d_r_loop_gap[0]            = core_cfg_dma_rd_reg[8][12:0];
assign c_cfg_d_r_loop_gap[1]            = core_cfg_dma_rd_reg[9][12:0];
assign c_cfg_d_r_loop_gap[2]            = core_cfg_dma_rd_reg[10][12:0];
assign c_cfg_d_r_loop_gap[3]            = core_cfg_dma_rd_reg[11][12:0];
assign c_cfg_d_r_loop_lenth[0]          = core_cfg_dma_rd_reg[12][12:0];
assign c_cfg_d_r_loop_lenth[1]          = core_cfg_dma_rd_reg[13][12:0];
assign c_cfg_d_r_loop_lenth[2]          = core_cfg_dma_rd_reg[14][12:0];
assign c_cfg_d_r_loop_lenth[3]          = core_cfg_dma_rd_reg[15][12:0];
assign c_cfg_d_r_pingpong_num           = core_cfg_dma_rd_reg[16][10:0];
assign c_cfg_d_r_ping_lenth             = core_cfg_dma_rd_reg[17][12:0];
assign c_cfg_d_r_pong_lenth             = core_cfg_dma_rd_reg[18][12:0];
// assign c_cfg_d_r_dma_access_mode        = core_cfg_dma_rd_reg[19][0];

//--------------------dma write channel address calculate------------------------------------//
logic                   c_cfg_d_w_address_mode;
logic   [4:0]           c_cfg_d_w_relative_addr;
// logic                   c_cfg_d_r_address_remap;
// logic   [12:0]          c_cfg_d_r_address_remap_gap;

logic   [11:0]          c_cfg_d_w_noc_base_addr_high;
logic   [12:0]          c_cfg_d_w_noc_base_addr_low;
logic   [3:0]           d_w_noc_base_addr_high_cal;
// logic   [12:0]          d_r_noc_base_addr_low_cal;
logic   [11:0]          d_w_noc_base_addr_high_sel;
// logic   [12:0]          d_r_noc_base_addr_low_sel;

assign d_w_noc_base_addr_high_cal = c_cfg_d_w_relative_addr[4] ? (NODE_ID - c_cfg_d_w_relative_addr[3:0]) : (NODE_ID + c_cfg_d_w_relative_addr[3:0]);
assign d_w_noc_base_addr_high_sel = c_cfg_d_w_address_mode ? {8'b0, d_w_noc_base_addr_high_cal} : c_cfg_d_w_noc_base_addr_high;
assign c_cfg_d_w_noc_base_addr = {d_w_noc_base_addr_high_sel, c_cfg_d_w_noc_base_addr_low};

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        core_cfg_dma_wr_reg <= 'b0;
    end
    else if(core_cfg_valid & (core_cfg_addr_frag == 2'd3)) begin
        core_cfg_dma_wr_reg[core_cfg_addr_low] <= core_cfg_data_frag;
    end
end

assign c_cfg_d_w_address_mode           = core_cfg_dma_wr_reg[0][0];
assign c_cfg_d_w_relative_addr          = core_cfg_dma_wr_reg[1][4:0];
assign c_cfg_d_w_mc                     = core_cfg_dma_wr_reg[2][0];
assign c_cfg_d_w_dma_transfer           = core_cfg_dma_wr_reg[3][0];
assign c_cfg_d_w_pingpong_en            = core_cfg_dma_wr_reg[4][0];
assign c_cfg_d_w_ram_base_addr[0]       = core_cfg_dma_wr_reg[5][12:0];
assign c_cfg_d_w_ram_base_addr[1]       = core_cfg_dma_wr_reg[6][12:0];
assign c_cfg_d_w_noc_base_addr_low      = core_cfg_dma_wr_reg[7][12:0];
assign c_cfg_d_w_noc_base_addr_high     = core_cfg_dma_wr_reg[8][11:0];
assign c_cfg_d_w_loop_gap[0]            = core_cfg_dma_wr_reg[9][12:0];
assign c_cfg_d_w_loop_gap[1]            = core_cfg_dma_wr_reg[10][12:0];
assign c_cfg_d_w_loop_gap[2]            = core_cfg_dma_wr_reg[11][12:0];
assign c_cfg_d_w_loop_gap[3]            = core_cfg_dma_wr_reg[12][12:0];
assign c_cfg_d_w_loop_lenth[0]          = core_cfg_dma_wr_reg[13][12:0];
assign c_cfg_d_w_loop_lenth[1]          = core_cfg_dma_wr_reg[14][12:0];
assign c_cfg_d_w_loop_lenth[2]          = core_cfg_dma_wr_reg[15][12:0];
assign c_cfg_d_w_loop_lenth[3]          = core_cfg_dma_wr_reg[16][12:0];
assign c_cfg_d_w_pingpong_num           = core_cfg_dma_wr_reg[17][10:0];
assign c_cfg_d_w_ping_lenth             = core_cfg_dma_wr_reg[18][12:0];
assign c_cfg_d_w_pong_lenth             = core_cfg_dma_wr_reg[19][12:0];
assign c_cfg_d_w_noc_mc_scale           = core_cfg_dma_wr_reg[20][11:0];
assign c_cfg_d_w_sync_target            = core_cfg_dma_wr_reg[21][11:0];
assign c_cfg_d_w_dma_access_mode        = core_cfg_dma_wr_reg[22][0];


//finish status

// logic   [2:0]   finish_status, finish_status_set; //2:dma wr; 1:dma rd; 0:core wr;      // core rd 不会是最后一个
logic   [2:0]   finish_status, finish_status_set; //3:dma wr; 2:dma rd; 1:core wr; 0:core rd;      // core rd 不会是最后一个
// finish_status_set 是用来参考的，哪个通道配置了，就设置哪个为1，finish status是实时读取当前的状态，当finish_status = finish_status_set时代表已经finish

// 现在只有主动读取时才会

// 设置finish-status set
always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        finish_status_set <= 'b0;
    end
    else if(core_cmd_req & (core_cmd_addr == 3'd4) & (finish_status == finish_status_set)) begin
        finish_status_set <= 'b0;
    end // 如果握手成功
    else if(core_cmd_req & core_cmd_gnt) begin
        case(core_cmd_addr) // 根据地址判断需要设置哪个为1
        3'd0: finish_status_set[0] <= 1'b1;
        3'd1: finish_status_set[1] <= 1'b1;
        3'd2: finish_status_set[2] <= 1'b1;
        3'd3: finish_status_set[3] <= 1'b1;
        default: finish_status_set <= finish_status_set;
        endcase
    end
end


always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        finish_status <= 'b0;
    end 
    else if(core_cmd_req & (core_cmd_addr == 3'd4) & (finish_status == finish_status_set)) begin
        finish_status <= 'b0;
    end
    else if(core_cmd_req) begin
        case(core_cmd_addr) 
            3'd0: begin //core rd
                
            end
            3'd1: begin //core wr
                core_cmd_core_wr_req = core_cmd_req;
                core_cmd_gnt = core_cmd_core_wr_gnt;
            end
            3'd2: begin //dma rd
                core_cmd_dma_rd_req = core_cmd_req;
                core_cmd_gnt = core_cmd_dma_rd_gnt;
            end
            3'd3: begin //dma wr
                core_cmd_dma_wr_req = core_cmd_req;
                core_cmd_gnt = core_cmd_dma_wr_gnt;
            end
            3'd4: begin //finish status     
                core_cmd_gnt = (finish_status == finish_status_set);
            end
        endcase
    end
    else if(c_r_transaction_done) begin
        finish_status[0] <= 1'b1;
    end
    else if(c_w_transaction_done) begin
        finish_status[1] <= 1'b1;
    end
    else if(d_r_transaction_done) begin
        finish_status[2] <= 1'b1;
    end
    else if(d_w_transaction_done) begin
        finish_status[3] <= 1'b1;
    end
end

//------------------------itf----------------------

assign c_cfg_itf_single_fetch = core_cfg_core_rd_reg[31][0];
assign c_cfg_itf_irq_en = core_cfg_core_rd_reg[30][0];

//core data select
// assign core_in_data = c_cfg_c_r_local_access ? dmmu_rd_core_data : cmmu_in_core_data;
// assign core_in_valid = c_cfg_c_r_local_access ? dmmu_rd_core_valid : cmmu_in_core_valid;

//dmmu data select
// assign core_dmmu_wr_data = core_out_data;
// assign core_dmmu_wr_valid = core_cfg_wr_local_access & core_out_valid;
//cmmu data select
// assign core_cmmu_out_data = core_out_data;
// assign core_cmmu_out_valid = ~core_cfg_wr_local_access & core_out_valid;

//cmd req gnt select


always_comb begin
    // core配置通道的握手信号
    core_cmd_dma_rd_req = 'b0;
    core_cmd_dma_wr_req = 'b0;

    core_cmd_core_rd_req = 'b0;
    core_cmd_core_wr_req = 'b0;

    // core_cmd_itf_req = 'b0;

    core_cmd_gnt = 'b0;
    // core_cmd_ok = 'b0;  // to be determined

    case(core_cmd_addr)
    3'd0: begin //core rd
        core_cmd_core_rd_req = core_cmd_req;
        core_cmd_gnt = core_cmd_core_rd_gnt;
    end
    3'd1: begin //core wr
        core_cmd_core_wr_req = core_cmd_req;
        core_cmd_gnt = core_cmd_core_wr_gnt;
    end
    3'd2: begin //dma rd
        core_cmd_dma_rd_req = core_cmd_req;
        core_cmd_gnt = core_cmd_dma_rd_gnt;
    end
    3'd3: begin //dma wr
        core_cmd_dma_wr_req = core_cmd_req;
        core_cmd_gnt = core_cmd_dma_wr_gnt;
    end
    3'd4: begin //finish status     
        core_cmd_gnt = (finish_status == finish_status_set);
    end
    // 3'd5: begin //itf sleep
    //     core_cmd_itf_req = core_cmd_req;
    //     core_cmd_gnt = core_cmd_itf_gnt;
    // end
    // default: begin

    // end
    endcase
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        core_cmd_ok <= 'b0;
    end
    else begin
        core_cmd_ok <= core_cmd_gnt;
    end
end

endmodule