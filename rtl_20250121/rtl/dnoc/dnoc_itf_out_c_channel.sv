module dnoc_itf_out_c_channel #(
    parameter NODE_ID   = 4'd0,
    parameter DMA_ID    = 4'b1101
    // parameter RAM_W     = 13,
    // parameter SYNC_W    = 12,
    // parameter L_RAM_W   = 24
)
(
    input                           clk,
    input                           rst_n,

    //noc 
    output  logic   [256-1:0]       in_flit,
    output  logic                   in_last,
    output  logic                   in_valid,
    input                           in_ready,

    //sync signal
    input                           sync_hit,
    output  logic                   sync_init,
    output  logic   [11:0]          sync_target,

    //core rd channel req
    input                           core_rd_noc_out_req,
    output  logic                   core_rd_noc_out_gnt,

    input                           c_cfg_c_r_mc,
    input                           c_cfg_c_r_dma_transfer_n,
    input                           c_cfg_c_r_dma_rgba_en,
    input                           c_cfg_c_r_dma_access_mode,//
    input   logic                   c_cfg_c_r_dma_loop_en,
    input   logic   [12:0]          c_cfg_c_r_dma_loop_len,
    input   logic   [10:0]          c_cfg_c_r_dma_loop_gap,
    input   logic   [10:0]          c_cfg_c_r_dma_loop_num,
    input           [11:0]          c_cfg_c_r_noc_target_id, //相当于地址的高4位，决定节点地址

    input           [11:0]          c_cfg_c_r_noc_mc_scale,

    input           [11:0]          c_cfg_c_r_sync_target,

    input           [1:0][12:0]     c_cfg_c_r_base_addr,
    // input           [12:0]          c_cfg_c_r_total_lenth,
    input           [12:0]          c_cfg_c_r_ping_lenth,
    input           [12:0]          c_cfg_c_r_pong_lenth,
    input                           c_cfg_c_r_pingpong_en,
    input           [10:0]          c_cfg_c_r_pingpong_num,

    input           [3:0][12:0]     c_cfg_c_r_loop_lenth,
    input           [3:0][12:0]     c_cfg_c_r_loop_gap,

    //dma wr channel rd-from-out req and noc wr response 
    input                           dma_wr_noc_out_req,
    output  logic                   dma_wr_noc_out_gnt,

    input           [24:0]          d_w_n_o_cfg_base_addr, //dma mode do not include node id info; others do
    input           [12:0]          d_w_n_o_cfg_lenth,
    input                           d_w_n_o_cfg_mode,
    input                           d_w_n_o_cfg_resp_sel,

    input                           c_cfg_d_w_mc,
    input                           c_cfg_d_w_dma_transfer_n,
    input                           c_cfg_d_w_dma_rgba_en,
    input                           c_cfg_d_w_dma_access_mode,//
    input   logic                   c_cfg_d_w_dma_loop_en,
    input   logic   [12:0]          c_cfg_d_w_dma_loop_len,
    input   logic   [10:0]          c_cfg_d_w_dma_loop_gap,
    input   logic   [10:0]          c_cfg_d_w_dma_loop_num,
    input           [12:0]          d_w_n_o_cfg_dma_loop_Baddr,
    input           [11:0]          c_cfg_d_w_noc_mc_scale,

    input           [11:0]          c_cfg_d_w_sync_target

    // input           [3:0]           d_w_n_o_cfg_noc_target_id,

);

localparam IDLE         = 2'd0;
localparam CORE         = 2'd1;
localparam DMA          = 2'd2;
localparam WAIT         = 2'd3;

logic [1:0] cs, ns;
logic [255:0] core_head_flit, dma_head_flit;
logic [255:0] head_flit_ns, head_flit;
logic [3:0] c_cfg_c_r_noc_sync_tid;
logic [3:0] c_cfg_d_w_noc_sync_tid;
logic [3:0] actual_c_r_noc_target_id;
logic [3:0] actual_d_w_noc_target_id;

always_comb begin
    ns = cs;
    head_flit_ns = head_flit;

    in_valid = 'b0;
    in_last = 'b0;
    in_flit = core_head_flit;

    sync_init = 'b0;
    sync_target = 'b0;

    core_rd_noc_out_gnt = 'b0;

    dma_wr_noc_out_gnt = 'b0;

    case(cs)
    IDLE: begin
        if(core_rd_noc_out_req) begin
            head_flit_ns = core_head_flit;
            if(c_cfg_c_r_mc & (c_cfg_c_r_noc_sync_tid == NODE_ID)) begin
                ns = CORE;
                sync_init = 1'b1;
                sync_target = c_cfg_c_r_sync_target & (~(11'd1 << (NODE_ID)));
            end
            else begin
                in_valid = 1'b1;
                in_last = 1'b1;

                core_rd_noc_out_gnt = in_ready;
            end
        end
        else if(dma_wr_noc_out_req) begin
            head_flit_ns = dma_head_flit;
            in_flit = dma_head_flit;
            if(c_cfg_d_w_mc & (c_cfg_d_w_noc_sync_tid == NODE_ID)) begin
                ns = DMA;
                sync_init = 1'b1;
                sync_target = c_cfg_d_w_sync_target & (~(11'd1 << (NODE_ID)));
            end
            else begin
                in_valid = 1'b1;
                in_last = 1'b1;

                dma_wr_noc_out_gnt = in_ready;
            end
        end
    end
    CORE: begin
        in_flit = head_flit;
        if(sync_hit) begin
            in_valid = 1'b1;
            in_last = 1'b1;
            if(in_ready) begin
                ns = IDLE;
                core_rd_noc_out_gnt = 1'b1;
            end
            else begin
                ns = WAIT;
            end
        end
    end
    DMA: begin
        // in_flit = dma_head_flit;
        in_flit = head_flit;
        if(sync_hit) begin
            in_valid = 1'b1;
            in_last = 1'b1;
            if(in_ready) begin
                ns = IDLE;
                dma_wr_noc_out_gnt = 1'b1;
            end
            else begin
                ns = WAIT;
            end
        end
    end
    WAIT: begin
        in_valid = 1'b1;
        in_last = 1'b1;
        in_flit = head_flit;

        if(core_rd_noc_out_req) begin
            if(in_ready) begin
                core_rd_noc_out_gnt = 1'b1;
                ns = IDLE;
            end
        end
        else begin
            // in_flit = dma_head_flit;
            if(in_ready) begin
                dma_wr_noc_out_gnt = 1'b1;
                ns = IDLE;
            end
        end
    end
    endcase
end

assign c_cfg_c_r_noc_sync_tid = c_cfg_c_r_noc_mc_scale[3:0];
assign actual_c_r_noc_target_id = c_cfg_c_r_dma_transfer_n ? c_cfg_c_r_noc_target_id[3:0] : DMA_ID;
assign c_cfg_d_w_noc_sync_tid = c_cfg_d_w_noc_mc_scale[3:0];
assign actual_d_w_noc_target_id = c_cfg_d_w_dma_transfer_n ? d_w_n_o_cfg_base_addr[16:13] : DMA_ID; //包含向其它非dma节点发送读请求以及写相应

always_comb begin

    // core_head_flit[44:32]   = c_cfg_c_r_loop_lenth[3];
    // core_head_flit[44:32]   = c_cfg_c_r_loop_gap[3];    //最内层循环，设计较大的lenth和gap

    // core_head_flit[44:32]   = c_cfg_c_r_loop_lenth[2];
    // core_head_flit[44:32]   = c_cfg_c_r_loop_gap[2];

    // core_head_flit[44:32]   = c_cfg_c_r_loop_lenth[1];
    // core_head_flit[44:32]   = c_cfg_c_r_loop_gap[1];

    // core_head_flit[44:32]   = c_cfg_c_r_loop_lenth[0];
    // core_head_flit[44:32]   = c_cfg_c_r_loop_gap[0];

    core_head_flit[255]     = 1'b0;
    core_head_flit[254]     = c_cfg_c_r_dma_access_mode; //DMA NODE gb lb sel;
    core_head_flit[253]     = c_cfg_c_r_dma_rgba_en;
    core_head_flit[252:211] = 'b0;

    core_head_flit[210:199] = c_cfg_c_r_sync_target;

    core_head_flit[198:147] = c_cfg_c_r_loop_lenth;
    core_head_flit[146:95]  = (~c_cfg_c_r_dma_transfer_n & c_cfg_c_r_dma_loop_en) ? {2'b0, c_cfg_c_r_dma_loop_gap, c_cfg_c_r_loop_gap[2:0]} : c_cfg_c_r_loop_gap;

    core_head_flit[94:82]   = c_cfg_c_r_pong_lenth;
    core_head_flit[81:69]   = (~c_cfg_c_r_dma_transfer_n & c_cfg_c_r_dma_loop_en) ? c_cfg_c_r_dma_loop_len : c_cfg_c_r_ping_lenth; //ping lenth就是非pingpong模式下的传输长度
    core_head_flit[68:58]   = c_cfg_c_r_dma_transfer_n ? c_cfg_c_r_pingpong_num : c_cfg_c_r_dma_loop_num;
    core_head_flit[57]      = c_cfg_c_r_dma_transfer_n ? c_cfg_c_r_pingpong_en : c_cfg_c_r_dma_loop_en;
    // core_head_flit[56:44]   = c_cfg_c_r_total_lenth;
    core_head_flit[56:44]   = c_cfg_c_r_base_addr[1];
    core_head_flit[43:19]   = {c_cfg_c_r_noc_target_id, c_cfg_c_r_base_addr[0]}; //给dma的地址用长地址，给其它节点的用短13bit地址

    core_head_flit[18:7]    = (c_cfg_c_r_mc & (c_cfg_c_r_noc_sync_tid == NODE_ID)) ? c_cfg_c_r_noc_mc_scale : {NODE_ID[1:0],NODE_ID[3:2],NODE_ID[1:0],NODE_ID[3:2], NODE_ID}; //规定返回的地址
    //需要考虑同步请求类的，需要包含节点id
    core_head_flit[6]       = c_cfg_c_r_mc & (c_cfg_c_r_noc_sync_tid != NODE_ID);
    core_head_flit[5]       = 1'b0; //读请求是来自core还是dma；response返回给core还是dma；
    core_head_flit[4]       = 1'b0; //是rd req还是response
    core_head_flit[3:0]     = c_cfg_c_r_mc ? 
                            ((c_cfg_c_r_noc_sync_tid == NODE_ID) ? actual_c_r_noc_target_id : c_cfg_c_r_noc_sync_tid)
                            : actual_c_r_noc_target_id ;
end

always_comb begin

    // dma_head_flit[44:32]   = c_cfg_d_w_loop_lenth[3];
    // dma_head_flit[44:32]   = c_cfg_d_w_loop_gap[3];

    // dma_head_flit[44:32]   = c_cfg_d_w_loop_lenth[2];
    // dma_head_flit[44:32]   = c_cfg_d_w_loop_gap[2];

    // dma_head_flit[44:32]   = c_cfg_d_w_loop_lenth[1];
    // dma_head_flit[44:32]   = c_cfg_d_w_loop_gap[1];

    // dma_head_flit[44:32]   = c_cfg_d_w_loop_lenth[0];
    // dma_head_flit[44:32]   = c_cfg_d_w_loop_gap[0];

    dma_head_flit[255]      = 1'b0;
    dma_head_flit[254]      = c_cfg_d_w_dma_access_mode;
    dma_head_flit[253]      = c_cfg_d_w_dma_rgba_en;
    dma_head_flit[252:211]  = 'b0;

    dma_head_flit[210:199]  = c_cfg_d_w_sync_target;

    dma_head_flit[198:186]  = d_w_n_o_cfg_lenth;
    dma_head_flit[185:147]  = 'b0;
    dma_head_flit[146:134]  = (~c_cfg_d_w_dma_transfer_n & c_cfg_d_w_dma_loop_en) ? {2'b0, c_cfg_d_w_dma_loop_gap} : 13'd1;
    dma_head_flit[133:82]   = 'b0;

    dma_head_flit[81:69]    = (~c_cfg_d_w_dma_transfer_n & c_cfg_d_w_dma_loop_en) ? c_cfg_d_w_dma_loop_len : d_w_n_o_cfg_lenth; //ping lenth就是非pingpong模式下的传输长度
    dma_head_flit[68:58]    = c_cfg_d_w_dma_transfer_n ? 'b0 : c_cfg_d_w_dma_loop_num; //pingpong num
    dma_head_flit[57]       = c_cfg_d_w_dma_transfer_n ? 'b0 : c_cfg_d_w_dma_loop_en; //pingpong en
    // core_head_flit[56:44]   = c_cfg_c_r_total_lenth;
    dma_head_flit[56:44]    = c_cfg_d_w_dma_transfer_n ? 'b0 : d_w_n_o_cfg_dma_loop_Baddr;
    dma_head_flit[43:19]    = d_w_n_o_cfg_base_addr; //给dma的地址用长地址，给其它节点的用短13bdma

    dma_head_flit[18:7]     = (c_cfg_d_w_mc & (c_cfg_d_w_noc_sync_tid == NODE_ID)) ? c_cfg_d_w_noc_mc_scale : {NODE_ID[1:0],NODE_ID[3:2],NODE_ID[1:0],NODE_ID[3:2], NODE_ID};

    dma_head_flit[6]        = c_cfg_d_w_mc & (c_cfg_d_w_noc_sync_tid != NODE_ID);
    // dma_head_flit[6]        = 1'b1; // 标志是读请求是来自core还是dma
    dma_head_flit[5]        = d_w_n_o_cfg_mode ? d_w_n_o_cfg_resp_sel : 1'b1;
    dma_head_flit[4]        = d_w_n_o_cfg_mode;
    dma_head_flit[3:0]      = d_w_n_o_cfg_mode ? 
                              d_w_n_o_cfg_base_addr[16:13] :
                              (c_cfg_d_w_mc ? ((c_cfg_d_w_noc_sync_tid == NODE_ID) ? actual_d_w_noc_target_id : c_cfg_d_w_noc_mc_scale[3:0]) : actual_d_w_noc_target_id);
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cs <= IDLE;
        head_flit <= 'b0;
    end
    else begin
        cs <= ns;
        head_flit <= head_flit_ns;
    end
end

endmodule
