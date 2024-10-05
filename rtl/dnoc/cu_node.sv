




module cu_node #(
    parameter NODE_ID       = 4'd0,
    parameter CLUSTER_ID    = 6'd0,
    parameter DMA_ID        = 4'b1101
)
(
    input                           clk,
    input                           rst_n,
    
    // core node 与noc的接口，即core与router之间的接口
    //noc interface 
    // core node给router发送的信号    
    input           [256-1:0]       node_out_flit_local,
    input                           node_out_last_local,
    input           [1:0]           node_out_valid_local,
    output  logic   [1:0]           node_out_ready_local,
    // router给core发送的信号
    output  logic   [256-1:0]       node_in_flit_local,
    output  logic                   node_in_last_local,
    output  logic   [1:0]           node_in_valid_local,
    input           [1:0]           node_in_ready_local,

    //instruction interface //指令是all2all的
    output  logic   [31:0]          fetch_L2cache_info,
    output  logic                   fetch_L2cache_req,
    input                           fetch_L2cache_gnt,
    input   [31:0]                  fetch_L2cache_r_data,
    input                           fetch_L2cache_r_valid,
    output  logic                   fetch_L2cache_r_ready
);


//memory

logic                           L2_dmem_core_rd_en;
logic           [12:0]          L2_dmem_core_rd_addr;
logic           [255:0]         L2_dmem_core_rd_data;

logic                           L2_dmem_core_wr_en;
logic           [12:0]          L2_dmem_core_wr_addr;
logic           [255:0]         L2_dmem_core_wr_data;

logic                           L2_dmem_dma_rd_en;
logic           [12:0]          L2_dmem_dma_rd_addr;
logic           [255:0]         L2_dmem_dma_rd_data;

logic                           L2_dmem_dma_wr_en;
logic           [12:0]          L2_dmem_dma_wr_addr;
logic           [255:0]         L2_dmem_dma_wr_data;

//core cfg
logic   [6:0]           core_cfg_addr;
logic   [12:0]          core_cfg_data;
logic                   core_cfg_valid;

logic                   core_cmd_req;
logic   [2:0]           core_cmd_addr;
logic                   core_cmd_gnt;
logic                   core_cmd_ok;
logic                   core_sleep_irq_pulse;

logic                   core_cmd_dma_rd_req;
logic                   core_cmd_dma_rd_gnt;

logic                   d_r_transaction_done;

logic                   c_cfg_d_r_pingpong_en;
logic   [10:0]          c_cfg_d_r_pingpong_num;
logic   [12:0]          c_cfg_d_r_ping_lenth;
logic   [12:0]          c_cfg_d_r_pong_lenth;

logic   [1:0][12:0]     c_cfg_d_r_ram_base_addr;
logic   [24:0]          c_cfg_d_r_noc_base_addr;
logic   [3:0][12:0]     c_cfg_d_r_loop_lenth;
logic   [3:0][12:0]     c_cfg_d_r_loop_gap;

logic                   c_cfg_d_r_dma_transfer;
// logic                   c_cfg_d_r_dma_access_mode;


logic                   core_cmd_dma_wr_req;
logic                   core_cmd_dma_wr_gnt;

logic                   d_w_transaction_done;

logic                   c_cfg_d_w_pingpong_en;
logic   [10:0]          c_cfg_d_w_pingpong_num;
logic   [12:0]          c_cfg_d_w_ping_lenth;
logic   [12:0]          c_cfg_d_w_pong_lenth;

logic   [1:0][12:0]     c_cfg_d_w_ram_base_addr;
logic   [24:0]          c_cfg_d_w_noc_base_addr;
logic   [3:0][12:0]     c_cfg_d_w_loop_lenth;
logic   [3:0][12:0]     c_cfg_d_w_loop_gap;

logic                   c_cfg_d_w_mc;
logic                   c_cfg_d_w_dma_transfer;
logic                   c_cfg_d_w_dma_access_mode;

logic         [11:0]    c_cfg_d_w_noc_mc_scale;

logic         [11:0]    c_cfg_d_w_sync_target;

//ctr core read channel
logic                   core_cmd_core_rd_req;
logic                   core_cmd_core_rd_gnt;

logic                   c_cfg_c_r_pingpong_en;
logic   [10:0]          c_cfg_c_r_pingpong_num;
logic   [12:0]          c_cfg_c_r_ping_lenth;
logic   [12:0]          c_cfg_c_r_pong_lenth;

logic                   c_cfg_c_r_local_access;

logic   [1:0][12:0]     c_cfg_c_r_base_addr;
logic   [3:0]           c_cfg_c_r_noc_target_id;
logic   [3:0][12:0]     c_cfg_c_r_loop_lenth;
logic   [3:0][12:0]     c_cfg_c_r_loop_gap;

logic                   c_cfg_c_r_mc;
logic                   c_cfg_c_r_dma_transfer;
logic                   c_cfg_c_r_dma_access_mode;

logic         [11:0]    c_cfg_c_r_noc_mc_scale;
logic         [11:0]    c_cfg_c_r_sync_target;

logic         [3:0]     c_cfg_c_r_pad_up_len;
logic         [3:0]     c_cfg_c_r_pad_right_len;
logic         [3:0]     c_cfg_c_r_pad_left_len;
logic         [3:0]     c_cfg_c_r_pad_bottom_len;

logic         [10:0]    c_cfg_c_r_pad_row_num;
logic         [10:0]    c_cfg_c_r_pad_col_num;
logic                   c_cfg_c_r_pad_mode;

//ctr core write channel
logic                   core_cmd_core_wr_req;
logic                   core_cmd_core_wr_gnt;

logic                   c_w_transaction_done;

logic                   c_cfg_c_w_local_access;

logic                   c_cfg_c_w_pingpong_en;
logic   [10:0]          c_cfg_c_w_pingpong_num;
logic   [12:0]          c_cfg_c_w_ping_lenth;
logic   [12:0]          c_cfg_c_w_pong_lenth;

logic   [1:0][12:0]     c_cfg_c_w_base_addr;
logic   [3:0]           c_cfg_c_w_noc_target_id;
logic   [3:0][12:0]     c_cfg_c_w_loop_lenth;
logic   [3:0][12:0]     c_cfg_c_w_loop_gap;

logic                   c_cfg_c_w_dma_transfer;
// logic                   c_cfg_c_w_dma_access_mode;

//--------------------- virtual channel mux -------------------------

logic   [1:0][256-1:0]  out_flit;
logic   [1:0]           out_last;
logic   [1:0]           out_valid;
logic   [1:0]           out_ready;

logic   [1:0][256-1:0]  in_flit;
logic   [1:0]           in_last;
logic   [1:0]           in_valid;
logic   [1:0]           in_ready;

noc_vchannel_mux
#(
    .FLIT_WIDTH (256)
)
u_vc_mux
(
    // .clk        (clk),
    .in_flit    (in_flit),
    .in_last    (in_last),
    .in_valid   (in_valid),
    .in_ready   (in_ready),
    .out_flit   (node_in_flit_local),
    .out_last   (node_in_last_local),
    .out_valid  (node_in_valid_local),
    .out_ready  (node_in_ready_local)
);


//--------------------- virtual channel demux -------------------------

assign out_valid = node_out_valid_local;
assign node_out_ready_local = out_ready;

genvar i;

generate
    for(i = 0; i < 2; i = i+1) begin
        assign out_flit[i] = node_out_flit_local;
        assign out_last[i] = node_out_last_local;
    end
endgenerate

//----------------itf-------------------------------
logic                   c_cfg_itf_single_fetch;
logic                   c_cfg_itf_irq_en;
logic                   core_rst_n;

// logic                   core_cmd_itf_req;
// logic                   core_cmd_itf_gnt;

dnoc_itf_ctr
#(
    .NODE_ID(NODE_ID)
)
U_dnoc_itf_ctr
(
    .clk                        (clk),
    .rst_n                      (core_rst_n),

    //core cfg
    .core_cfg_addr              (core_cfg_addr),
    .core_cfg_data              (core_cfg_data),
    .core_cfg_valid             (core_cfg_valid),

    .core_cmd_req               (core_cmd_req),
    .core_cmd_addr              (core_cmd_addr),
    .core_cmd_gnt               (core_cmd_gnt),
    .core_cmd_ok                (core_cmd_ok),

    .core_cmd_dma_rd_req        (core_cmd_dma_rd_req),
    .core_cmd_dma_rd_gnt        (core_cmd_dma_rd_gnt),

    .d_r_transaction_done       (d_r_transaction_done),

    .c_cfg_d_r_pingpong_en      (c_cfg_d_r_pingpong_en),
    .c_cfg_d_r_pingpong_num     (c_cfg_d_r_pingpong_num),
    .c_cfg_d_r_ping_lenth       (c_cfg_d_r_ping_lenth),
    .c_cfg_d_r_pong_lenth       (c_cfg_d_r_pong_lenth),
    
    .c_cfg_d_r_ram_base_addr    (c_cfg_d_r_ram_base_addr),
    .c_cfg_d_r_noc_base_addr    (c_cfg_d_r_noc_base_addr),
    .c_cfg_d_r_loop_lenth       (c_cfg_d_r_loop_lenth),
    .c_cfg_d_r_loop_gap         (c_cfg_d_r_loop_gap),

    .c_cfg_d_r_dma_transfer     (c_cfg_d_r_dma_transfer),
    // .c_cfg_d_r_dma_access_mode  (c_cfg_d_r_dma_access_mode),

    .core_cmd_dma_wr_req        (core_cmd_dma_wr_req),
    .core_cmd_dma_wr_gnt        (core_cmd_dma_wr_gnt),

    .d_w_transaction_done       (d_w_transaction_done),

    .c_cfg_d_w_pingpong_en      (c_cfg_d_w_pingpong_en),
    .c_cfg_d_w_pingpong_num     (c_cfg_d_w_pingpong_num),
    .c_cfg_d_w_ping_lenth       (c_cfg_d_w_ping_lenth),
    .c_cfg_d_w_pong_lenth       (c_cfg_d_w_pong_lenth),
    
    .c_cfg_d_w_ram_base_addr    (c_cfg_d_w_ram_base_addr),
    .c_cfg_d_w_noc_base_addr    (c_cfg_d_w_noc_base_addr),
    .c_cfg_d_w_loop_lenth       (c_cfg_d_w_loop_lenth),
    .c_cfg_d_w_loop_gap         (c_cfg_d_w_loop_gap),

    .c_cfg_d_w_mc               (c_cfg_d_w_mc),
    .c_cfg_d_w_dma_transfer     (c_cfg_d_w_dma_transfer),
    .c_cfg_d_w_dma_access_mode  (c_cfg_d_w_dma_access_mode),

    .c_cfg_d_w_noc_mc_scale     (c_cfg_d_w_noc_mc_scale),

    .c_cfg_d_w_sync_target      (c_cfg_d_w_sync_target),

    //ctr core read channel
    .core_cmd_core_rd_req       (core_cmd_core_rd_req),
    .core_cmd_core_rd_gnt       (core_cmd_core_rd_gnt),

    .c_cfg_c_r_pingpong_en      (c_cfg_c_r_pingpong_en),
    .c_cfg_c_r_pingpong_num     (c_cfg_c_r_pingpong_num),
    .c_cfg_c_r_ping_lenth       (c_cfg_c_r_ping_lenth),
    .c_cfg_c_r_pong_lenth       (c_cfg_c_r_pong_lenth),
    
    .c_cfg_c_r_local_access     (c_cfg_c_r_local_access),

    .c_cfg_c_r_base_addr        (c_cfg_c_r_base_addr),
    .c_cfg_c_r_noc_target_id    (c_cfg_c_r_noc_target_id),
    .c_cfg_c_r_loop_lenth       (c_cfg_c_r_loop_lenth),
    .c_cfg_c_r_loop_gap         (c_cfg_c_r_loop_gap),

    .c_cfg_c_r_mc               (c_cfg_c_r_mc),
    .c_cfg_c_r_dma_transfer     (c_cfg_c_r_dma_transfer),
    .c_cfg_c_r_dma_access_mode  (c_cfg_c_r_dma_access_mode),
    .c_cfg_c_r_noc_mc_scale     (c_cfg_c_r_noc_mc_scale),
    .c_cfg_c_r_sync_target      (c_cfg_c_r_sync_target),
    .c_cfg_c_r_pad_up_len       (c_cfg_c_r_pad_up_len),
    .c_cfg_c_r_pad_right_len    (c_cfg_c_r_pad_right_len),
    .c_cfg_c_r_pad_left_len     (c_cfg_c_r_pad_left_len),
    .c_cfg_c_r_pad_bottom_len   (c_cfg_c_r_pad_bottom_len),

    .c_cfg_c_r_pad_row_num      (c_cfg_c_r_pad_row_num),
    .c_cfg_c_r_pad_col_num      (c_cfg_c_r_pad_col_num),
    .c_cfg_c_r_pad_mode         (c_cfg_c_r_pad_mode),

    //ctr core write channel
    .core_cmd_core_wr_req       (core_cmd_core_wr_req),
    .core_cmd_core_wr_gnt       (core_cmd_core_wr_gnt),

    .c_w_transaction_done       (c_w_transaction_done),

    .c_cfg_c_w_local_access     (c_cfg_c_w_local_access),

    .c_cfg_c_w_pingpong_en      (c_cfg_c_w_pingpong_en),
    .c_cfg_c_w_pingpong_num     (c_cfg_c_w_pingpong_num),
    .c_cfg_c_w_ping_lenth       (c_cfg_c_w_ping_lenth),
    .c_cfg_c_w_pong_lenth       (c_cfg_c_w_pong_lenth),
    
    .c_cfg_c_w_base_addr        (c_cfg_c_w_base_addr),
    .c_cfg_c_w_noc_target_id    (c_cfg_c_w_noc_target_id),
    .c_cfg_c_w_loop_lenth       (c_cfg_c_w_loop_lenth),
    .c_cfg_c_w_loop_gap         (c_cfg_c_w_loop_gap),

    .c_cfg_c_w_dma_transfer     (c_cfg_c_w_dma_transfer),
    // .c_cfg_c_w_dma_access_mode  (c_cfg_c_w_dma_access_mode),

    //----------------itf-------------------------------
    .c_cfg_itf_irq_en           (c_cfg_itf_irq_en),
    .c_cfg_itf_single_fetch     (c_cfg_itf_single_fetch)

    // .core_cmd_itf_req           (core_cmd_itf_req),
    // .core_cmd_itf_gnt           (core_cmd_itf_gnt)
);

//

logic                   sync_req;
logic   [3:0]           sync_node_id;

//noc to dma rd cmd and cfg
logic                   noc_cmd_dma_rd_req;
logic                   noc_cmd_dma_rd_gnt;

logic   [1:0][12:0]     n_cfg_d_r_ram_base_addr;
logic   [12:0]          n_cfg_d_r_ping_lenth;
logic   [12:0]          n_cfg_d_r_pong_lenth;
logic   [11:0]          n_cfg_d_r_noc_mc_scale;
logic                   n_cfg_d_r_req_sel;
logic                   n_cfg_d_r_pingpong_en;
logic   [10:0]          n_cfg_d_r_pingpong_num;
logic   [3:0][12:0]     n_cfg_d_r_loop_lenth;
logic   [3:0][12:0]     n_cfg_d_r_loop_gap;

logic                   noc_in_dma_rd_response;
logic                   noc_in_core_wr_response;

dnoc_itf_in_c_channel U_in_c_channel
(
    .clk                        (clk),
    .rst_n                      (core_rst_n),

    //noc signals
    .out_flit                   (out_flit[1]),
    .out_last                   (out_last[1]),
    .out_valid                  (out_valid[1]),
    .out_ready                  (out_ready[1]),

    .sync_req                   (sync_req),
    .sync_node_id               (sync_node_id),

    .noc_cmd_dma_rd_req         (noc_cmd_dma_rd_req),
    .noc_cmd_dma_rd_gnt         (noc_cmd_dma_rd_gnt),

    .n_cfg_d_r_ram_base_addr    (n_cfg_d_r_ram_base_addr),
    .n_cfg_d_r_ping_lenth       (n_cfg_d_r_ping_lenth),
    .n_cfg_d_r_pong_lenth       (n_cfg_d_r_pong_lenth),
    .n_cfg_d_r_noc_mc_scale     (n_cfg_d_r_noc_mc_scale),
    .n_cfg_d_r_req_sel          (n_cfg_d_r_req_sel),
    .n_cfg_d_r_pingpong_en      (n_cfg_d_r_pingpong_en),
    .n_cfg_d_r_pingpong_num     (n_cfg_d_r_pingpong_num),
    .n_cfg_d_r_loop_lenth       (n_cfg_d_r_loop_lenth),
    .n_cfg_d_r_loop_gap         (n_cfg_d_r_loop_gap),

    .noc_in_dma_rd_response     (noc_in_dma_rd_response),

    //core wr response
    .noc_in_core_wr_response    (noc_in_core_wr_response)
);


//
logic   [255:0]         noc_in_core_rd_data;
logic                   noc_in_core_rd_valid;
logic                   noc_in_core_rd_last;
logic                   noc_in_core_rd_ready;

logic                   noc_cmd_dma_wr_req;
logic                   noc_cmd_dma_wr_gnt;

logic   [255:0]         noc_in_dma_wr_data;
logic                   noc_in_dma_wr_valid;
logic                   noc_in_dma_wr_ready;

logic   [12:0]          n_cfg_d_w_ram_base_addr;
logic   [12:0]          n_cfg_d_w_ram_total_lenth;
logic   [3:0]           n_cfg_d_w_source_id;
logic                   n_cfg_d_w_resp_sel;

logic   [3:0][12:0]     n_cfg_d_w_loop_lenth;
logic   [3:0][12:0]     n_cfg_d_w_loop_gap;

dnoc_itf_in_d_channel U_in_d_channel
(
    .clk                        (clk),
    .rst_n                      (core_rst_n),

    //noc signals
    .out_flit                   (out_flit[0]),
    .out_last                   (out_last[0]),
    .out_valid                  (out_valid[0]),
    .out_ready                  (out_ready[0]),

    .noc_in_core_rd_data        (noc_in_core_rd_data),
    .noc_in_core_rd_valid       (noc_in_core_rd_valid),
    .noc_in_core_rd_last        (noc_in_core_rd_last),
    .noc_in_core_rd_ready       (noc_in_core_rd_ready),


    //noc to dma wr data and cfg
    .noc_cmd_dma_wr_req         (noc_cmd_dma_wr_req),
    .noc_cmd_dma_wr_gnt         (noc_cmd_dma_wr_gnt),

    .noc_in_dma_wr_data         (noc_in_dma_wr_data),
    .noc_in_dma_wr_valid        (noc_in_dma_wr_valid),
    .noc_in_dma_wr_ready        (noc_in_dma_wr_ready),

    .n_cfg_d_w_ram_base_addr    (n_cfg_d_w_ram_base_addr),
    .n_cfg_d_w_ram_total_lenth  (n_cfg_d_w_ram_total_lenth),
    .n_cfg_d_w_source_id        (n_cfg_d_w_source_id),
    .n_cfg_d_w_resp_sel         (n_cfg_d_w_resp_sel),

    .n_cfg_d_w_loop_lenth       (n_cfg_d_w_loop_lenth),
    .n_cfg_d_w_loop_gap         (n_cfg_d_w_loop_gap)
    
);

//
logic                           sync_hit;
logic                           sync_init;
logic           [11:0]          sync_target;

//core rd channel req
logic                           core_rd_noc_out_req;
logic                           core_rd_noc_out_gnt;

//dma wr channel rd-from-out req and noc wr response 
logic                           dma_wr_noc_out_req;
logic                           dma_wr_noc_out_gnt;

logic           [24:0]          d_w_n_o_cfg_base_addr;
logic           [12:0]          d_w_n_o_cfg_lenth;
logic                           d_w_n_o_cfg_mode;
logic                           d_w_n_o_cfg_resp_sel;

dnoc_itf_out_c_channel
#(
    .NODE_ID                    (NODE_ID),
    .DMA_ID                     (DMA_ID)
)
U_out_c_channel
(
    .clk                        (clk),
    .rst_n                      (core_rst_n),

    //noc 
    .in_flit                    (in_flit[1]),
    .in_last                    (in_last[1]),
    .in_valid                   (in_valid[1]),
    .in_ready                   (in_ready[1]),

    //sync signal
    .sync_hit                   (sync_hit),
    .sync_init                  (sync_init),
    .sync_target                (sync_target),

    //core rd channel req
    .core_rd_noc_out_req        (core_rd_noc_out_req),
    .core_rd_noc_out_gnt        (core_rd_noc_out_gnt),

    .c_cfg_c_r_mc               (c_cfg_c_r_mc),
    .c_cfg_c_r_dma_transfer     (c_cfg_c_r_dma_transfer),
    .c_cfg_c_r_dma_access_mode  (c_cfg_c_r_dma_access_mode),
    .c_cfg_c_r_noc_target_id    (c_cfg_c_r_noc_target_id),

    .c_cfg_c_r_noc_mc_scale     (c_cfg_c_r_noc_mc_scale),

    .c_cfg_c_r_sync_target      (c_cfg_c_r_sync_target),

    .c_cfg_c_r_base_addr        (c_cfg_c_r_base_addr),
    .c_cfg_c_r_ping_lenth       (c_cfg_c_r_ping_lenth),
    .c_cfg_c_r_pong_lenth       (c_cfg_c_r_pong_lenth),
    .c_cfg_c_r_pingpong_en      (c_cfg_c_r_pingpong_en),
    .c_cfg_c_r_pingpong_num     (c_cfg_c_r_pingpong_num),

    .c_cfg_c_r_loop_lenth       (c_cfg_c_r_loop_lenth),
    .c_cfg_c_r_loop_gap         (c_cfg_c_r_loop_gap),

    .dma_wr_noc_out_req         (dma_wr_noc_out_req),
    .dma_wr_noc_out_gnt         (dma_wr_noc_out_gnt),

    .d_w_n_o_cfg_base_addr      (d_w_n_o_cfg_base_addr),
    .d_w_n_o_cfg_lenth          (d_w_n_o_cfg_lenth),
    .d_w_n_o_cfg_mode           (d_w_n_o_cfg_mode),
    .d_w_n_o_cfg_resp_sel       (d_w_n_o_cfg_resp_sel),

    .c_cfg_d_w_mc               (c_cfg_d_w_mc),
    .c_cfg_d_w_dma_transfer     (c_cfg_d_w_dma_transfer),
    .c_cfg_d_w_dma_access_mode  (c_cfg_d_w_dma_access_mode),
    .c_cfg_d_w_noc_mc_scale     (c_cfg_d_w_noc_mc_scale),

    .c_cfg_d_w_sync_target      (c_cfg_d_w_sync_target)
);

//

//core wr channel 
logic                           core_wr_noc_out_req;
logic                           core_wr_noc_out_gnt;

logic           [255:0]         core_wr_noc_out_data;
logic                           core_wr_noc_out_valid;
logic                           core_wr_noc_out_last;
logic                           core_wr_noc_out_ready;

//dma rd channel wr-out req and noc rd return data 
logic                           dma_rd_noc_out_req;
logic                           dma_rd_noc_out_gnt;

logic           [255:0]         dma_rd_noc_out_data;
logic                           dma_rd_noc_out_valid;
logic                           dma_rd_noc_out_last; 
logic                           dma_rd_noc_out_ready;

logic           [24:0]          d_r_n_o_cfg_base_addr;
logic           [12:0]          d_r_n_o_cfg_lenth;
logic                           d_r_n_o_cfg_mode;
logic                           d_r_n_o_cfg_req_sel;

logic           [11:0]          d_r_n_o_cfg_noc_mc_scale;


dnoc_itf_out_d_channel 
#(
    .NODE_ID                    (NODE_ID),
    .DMA_ID                     (DMA_ID)
)
U_out_d_channel
(
    .clk                        (clk),
    .rst_n                      (core_rst_n),

    .in_flit                    (in_flit[0]),
    .in_last                    (in_last[0]),
    .in_valid                   (in_valid[0]),
    .in_ready                   (in_ready[0]),

    .core_wr_noc_out_req        (core_wr_noc_out_req),
    .core_wr_noc_out_gnt        (core_wr_noc_out_gnt),

    .core_wr_noc_out_data       (core_wr_noc_out_data),
    .core_wr_noc_out_valid      (core_wr_noc_out_valid),
    .core_wr_noc_out_last       (core_wr_noc_out_last),
    .core_wr_noc_out_ready      (core_wr_noc_out_ready),

    .c_cfg_c_w_dma_transfer     (c_cfg_c_w_dma_transfer),
    // .c_cfg_c_w_dma_access_mode  (c_cfg_c_w_dma_access_mode),
    .c_cfg_c_w_noc_target_id    (c_cfg_c_w_noc_target_id),

    .c_cfg_c_w_base_addr        (c_cfg_c_w_base_addr[0]),
    .c_cfg_c_w_ping_lenth       (c_cfg_c_w_ping_lenth),
    .c_cfg_c_w_loop_lenth       (c_cfg_c_w_loop_lenth),
    .c_cfg_c_w_loop_gap         (c_cfg_c_w_loop_gap),

    .dma_rd_noc_out_req         (dma_rd_noc_out_req),
    .dma_rd_noc_out_gnt         (dma_rd_noc_out_gnt),

    .dma_rd_noc_out_data        (dma_rd_noc_out_data),
    .dma_rd_noc_out_valid       (dma_rd_noc_out_valid),
    .dma_rd_noc_out_last        (dma_rd_noc_out_last), 
    .dma_rd_noc_out_ready       (dma_rd_noc_out_ready),

    .d_r_n_o_cfg_base_addr      (d_r_n_o_cfg_base_addr),
    .d_r_n_o_cfg_lenth          (d_r_n_o_cfg_lenth),
    .d_r_n_o_cfg_mode           (d_r_n_o_cfg_mode),
    .d_r_n_o_cfg_req_sel        (d_r_n_o_cfg_req_sel),

    .d_r_n_o_cfg_noc_mc_scale   (d_r_n_o_cfg_noc_mc_scale),

    // .c_cfg_d_r_dma_access_mode  (c_cfg_d_r_dma_access_mode),
    .c_cfg_d_r_dma_transfer     (c_cfg_d_r_dma_transfer)
);

//

logic           [1:0]           in_pingpong_state;
logic                           in_pingpong_rd_done;

logic           [255:0]         core_in_data;
logic                           core_in_last;
logic                           core_in_valid;

dnoc_itf_core_rd U_core_rd
(
    .clk                        (clk),
    .rst_n                      (core_rst_n),

    .core_cmd_core_rd_req       (core_cmd_core_rd_req),
    .core_cmd_core_rd_gnt       (core_cmd_core_rd_gnt),

    //core cfg cmmu
    .c_cfg_c_r_base_addr        (c_cfg_c_r_base_addr),
    .c_cfg_c_r_ping_lenth       (c_cfg_c_r_ping_lenth),
    .c_cfg_c_r_pong_lenth       (c_cfg_c_r_pong_lenth),

    .c_cfg_c_r_pingpong_en      (c_cfg_c_r_pingpong_en),
    .c_cfg_c_r_pingpong_num     (c_cfg_c_r_pingpong_num),

    .c_cfg_c_r_local_access     (c_cfg_c_r_local_access),

    .c_cfg_c_r_loop_lenth       (c_cfg_c_r_loop_lenth),
    .c_cfg_c_r_loop_gap         (c_cfg_c_r_loop_gap),

    .c_cfg_c_r_pad_up_len       (c_cfg_c_r_pad_up_len),
    .c_cfg_c_r_pad_right_len    (c_cfg_c_r_pad_right_len),
    .c_cfg_c_r_pad_left_len     (c_cfg_c_r_pad_left_len),
    .c_cfg_c_r_pad_bottom_len   (c_cfg_c_r_pad_bottom_len),

    .c_cfg_c_r_pad_row_num      (c_cfg_c_r_pad_row_num),
    .c_cfg_c_r_pad_col_num      (c_cfg_c_r_pad_col_num),
    .c_cfg_c_r_pad_mode         (c_cfg_c_r_pad_mode),

    .pingpong_state             (in_pingpong_state),
    .pingpong_rd_done           (in_pingpong_rd_done),

    //core input data
    .core_in_data               (core_in_data),
    .core_in_last               (core_in_last),
    .core_in_valid              (core_in_valid),

    //noc output read req 
    .core_rd_noc_out_req        (core_rd_noc_out_req),
    .core_rd_noc_out_gnt        (core_rd_noc_out_gnt),

    //noc input data
    .noc_in_core_rd_data        (noc_in_core_rd_data),
    .noc_in_core_rd_valid       (noc_in_core_rd_valid),
    .noc_in_core_rd_last        (noc_in_core_rd_last),
    .noc_in_core_rd_ready       (noc_in_core_rd_ready),

    .L2_dmem_core_rd_en         (L2_dmem_core_rd_en),
    .L2_dmem_core_rd_addr       (L2_dmem_core_rd_addr),
    .L2_dmem_core_rd_data       (L2_dmem_core_rd_data)
);

//
logic           [1:0]           out_pingpong_state;
logic                           out_pingpong_wr_done;

//core output data
logic           [255:0]         core_out_data;
logic                           core_out_valid;

dnoc_itf_core_wr U_core_wr
(
    .clk                        (clk),
    .rst_n                      (core_rst_n),

    .core_cmd_core_wr_req       (core_cmd_core_wr_req),
    .core_cmd_core_wr_gnt       (core_cmd_core_wr_gnt),

    //core cfg cmmu
    .c_cfg_c_w_base_addr        (c_cfg_c_w_base_addr),
    .c_cfg_c_w_ping_lenth       (c_cfg_c_w_ping_lenth),
    .c_cfg_c_w_pong_lenth       (c_cfg_c_w_pong_lenth),

    .c_cfg_c_w_pingpong_en      (c_cfg_c_w_pingpong_en),
    .c_cfg_c_w_pingpong_num     (c_cfg_c_w_pingpong_num),

    .c_cfg_c_w_local_access     (c_cfg_c_w_local_access),

    .c_cfg_c_w_loop_lenth       (c_cfg_c_w_loop_lenth),
    .c_cfg_c_w_loop_gap         (c_cfg_c_w_loop_gap),

    .pingpong_state             (out_pingpong_state),
    .pingpong_wr_done           (out_pingpong_wr_done),

    .c_w_transaction_done       (c_w_transaction_done),

    //core output data
    .core_out_data              (core_out_data),
    .core_out_valid             (core_out_valid),

    //noc output read req
    .core_wr_noc_out_req        (core_wr_noc_out_req),
    .core_wr_noc_out_gnt        (core_wr_noc_out_gnt),

    .core_wr_noc_out_data       (core_wr_noc_out_data),
    .core_wr_noc_out_valid      (core_wr_noc_out_valid),
    .core_wr_noc_out_last       (core_wr_noc_out_last),
    .core_wr_noc_out_ready      (core_wr_noc_out_ready),

    .noc_in_core_wr_response    (noc_in_core_wr_response),

    .L2_dmem_core_wr_en         (L2_dmem_core_wr_en),
    .L2_dmem_core_wr_addr       (L2_dmem_core_wr_addr),
    .L2_dmem_core_wr_data       (L2_dmem_core_wr_data)
);

//
logic                           out_pingpong_rd_done;


dnoc_itf_dma_rd U_dma_rd
(
    .clk                        (clk),
    .rst_n                      (core_rst_n),

    //core cfg dmmu
    .c_cfg_d_r_ram_base_addr    (c_cfg_d_r_ram_base_addr),
    .c_cfg_d_r_ping_lenth       (c_cfg_d_r_ping_lenth),
    .c_cfg_d_r_pong_lenth       (c_cfg_d_r_pong_lenth),

    .c_cfg_d_r_pingpong_en      (c_cfg_d_r_pingpong_en),
    .c_cfg_d_r_pingpong_num     (c_cfg_d_r_pingpong_num),

    .c_cfg_d_r_noc_base_addr    (c_cfg_d_r_noc_base_addr),

    .c_cfg_d_r_loop_lenth       (c_cfg_d_r_loop_lenth),
    .c_cfg_d_r_loop_gap         (c_cfg_d_r_loop_gap),

    .core_cmd_dma_rd_req        (core_cmd_dma_rd_req),
    .core_cmd_dma_rd_gnt        (core_cmd_dma_rd_gnt),
    .d_r_transaction_done       (d_r_transaction_done),

    .pingpong_state             (out_pingpong_state),
    .pingpong_rd_done           (out_pingpong_rd_done),

    //noc cfg dma,
    .n_cfg_d_r_ram_base_addr    (n_cfg_d_r_ram_base_addr),
    .n_cfg_d_r_ping_lenth       (n_cfg_d_r_ping_lenth),
    .n_cfg_d_r_pong_lenth       (n_cfg_d_r_pong_lenth),
    .n_cfg_d_r_pingpong_en      (n_cfg_d_r_pingpong_en),
    .n_cfg_d_r_pingpong_num     (n_cfg_d_r_pingpong_num),

    .n_cfg_d_r_loop_lenth       (n_cfg_d_r_loop_lenth),
    .n_cfg_d_r_loop_gap         (n_cfg_d_r_loop_gap),

    .n_cfg_d_r_noc_mc_scale     (n_cfg_d_r_noc_mc_scale),
    .n_cfg_d_r_req_sel          (n_cfg_d_r_req_sel),

    .noc_cmd_dma_rd_req         (noc_cmd_dma_rd_req),
    .noc_cmd_dma_rd_gnt         (noc_cmd_dma_rd_gnt),

    //noc req 
    .dma_rd_noc_out_req         (dma_rd_noc_out_req),
    .dma_rd_noc_out_gnt         (dma_rd_noc_out_gnt),
    .d_r_n_o_cfg_base_addr      (d_r_n_o_cfg_base_addr),
    .d_r_n_o_cfg_lenth          (d_r_n_o_cfg_lenth),
    .d_r_n_o_cfg_noc_mc_scale   (d_r_n_o_cfg_noc_mc_scale),
    .d_r_n_o_cfg_req_sel        (d_r_n_o_cfg_req_sel),
    .d_r_n_o_cfg_mode           (d_r_n_o_cfg_mode),

    //noc read output data
    .dma_rd_noc_out_data        (dma_rd_noc_out_data),
    .dma_rd_noc_out_valid       (dma_rd_noc_out_valid),
    .dma_rd_noc_out_last        (dma_rd_noc_out_last),
    .dma_rd_noc_out_ready       (dma_rd_noc_out_ready),

    //noc response
    .noc_in_dma_rd_response     (noc_in_dma_rd_response),

    //ram rd control
    .L2_dmem_dma_rd_en          (L2_dmem_dma_rd_en),
    .L2_dmem_dma_rd_addr        (L2_dmem_dma_rd_addr),
    .L2_dmem_dma_rd_data        (L2_dmem_dma_rd_data)
);

//
logic                           in_pingpong_wr_done;

dnoc_itf_dma_wr U_dma_wr
(
    .clk                        (clk),
    .rst_n                      (core_rst_n),

    //core cfg cmmu
    .c_cfg_d_w_ram_base_addr    (c_cfg_d_w_ram_base_addr),
    .c_cfg_d_w_ping_lenth       (c_cfg_d_w_ping_lenth),
    .c_cfg_d_w_pong_lenth       (c_cfg_d_w_pong_lenth),

    .c_cfg_d_w_pingpong_en      (c_cfg_d_w_pingpong_en),
    .c_cfg_d_w_pingpong_num     (c_cfg_d_w_pingpong_num),

    .c_cfg_d_w_noc_base_addr    (c_cfg_d_w_noc_base_addr),

    .c_cfg_d_w_loop_lenth       (c_cfg_d_w_loop_lenth),
    .c_cfg_d_w_loop_gap         (c_cfg_d_w_loop_gap),

    .core_cmd_dma_wr_req        (core_cmd_dma_wr_req),
    .core_cmd_dma_wr_gnt        (core_cmd_dma_wr_gnt),
    .d_w_transaction_done       (d_w_transaction_done),

    .pingpong_state             (in_pingpong_state),
    .pingpong_wr_done           (in_pingpong_wr_done),

    //noc cfg dma,
    .n_cfg_d_w_ram_base_addr    (n_cfg_d_w_ram_base_addr),
    .n_cfg_d_w_ram_total_lenth  (n_cfg_d_w_ram_total_lenth),
    .n_cfg_d_w_source_id        (n_cfg_d_w_source_id),
    .n_cfg_d_w_resp_sel         (n_cfg_d_w_resp_sel),

    .n_cfg_d_w_loop_lenth       (n_cfg_d_w_loop_lenth),
    .n_cfg_d_w_loop_gap         (n_cfg_d_w_loop_gap),

    .noc_cmd_dma_wr_req         (noc_cmd_dma_wr_req),
    .noc_cmd_dma_wr_gnt         (noc_cmd_dma_wr_gnt),

    //noc write input data
    .noc_in_dma_wr_data         (noc_in_dma_wr_data),
    .noc_in_dma_wr_valid        (noc_in_dma_wr_valid),
    .noc_in_dma_wr_ready        (noc_in_dma_wr_ready),

    //noc req : read out req or write in response
    .dma_wr_noc_out_req         (dma_wr_noc_out_req),
    .dma_wr_noc_out_gnt         (dma_wr_noc_out_gnt),
    .d_w_n_o_cfg_base_addr      (d_w_n_o_cfg_base_addr),
    .d_w_n_o_cfg_lenth          (d_w_n_o_cfg_lenth),
    .d_w_n_o_cfg_mode           (d_w_n_o_cfg_mode),
    .d_w_n_o_cfg_resp_sel       (d_w_n_o_cfg_resp_sel),

    //ram rd control
    .L2_dmem_dma_wr_en          (L2_dmem_dma_wr_en),
    .L2_dmem_dma_wr_addr        (L2_dmem_dma_wr_addr),
    .L2_dmem_dma_wr_data        (L2_dmem_dma_wr_data)
);

//
dnoc_itf_pingpong U_in_pingpong
(
    .clk                        (clk),
    .rst_n                      (core_rst_n),

    .pingpong_rd_done           (in_pingpong_rd_done),
    .pingpong_wr_done           (in_pingpong_wr_done),

    .pingpong_state             (in_pingpong_state)
);

dnoc_itf_pingpong U_out_pingpong
(
    .clk                        (clk),
    .rst_n                      (core_rst_n),

    .pingpong_rd_done           (out_pingpong_rd_done),
    .pingpong_wr_done           (out_pingpong_wr_done),

    .pingpong_state             (out_pingpong_state)
);

//

sync_collect U_sync_collect
(
    .clk                    (clk),
    .rst_n                  (core_rst_n),

    .sync_req               (sync_req),
    .sync_node_id           (sync_node_id),

    .sync_hit               (sync_hit),
    .sync_init              (sync_init),
    .sync_target            (sync_target)
);

//

L2_dmem U_L2_dmem
(
    .clk                    (clk),
    .rst_n                  (core_rst_n),

    .L2_dmem_core_rd_en     (L2_dmem_core_rd_en),
    .L2_dmem_core_rd_addr   (L2_dmem_core_rd_addr),
    .L2_dmem_core_rd_data   (L2_dmem_core_rd_data),

    .L2_dmem_core_wr_en     (L2_dmem_core_wr_en),
    .L2_dmem_core_wr_addr   (L2_dmem_core_wr_addr),
    .L2_dmem_core_wr_data   (L2_dmem_core_wr_data),

    .L2_dmem_dma_rd_en      (L2_dmem_dma_rd_en),
    .L2_dmem_dma_rd_addr    (L2_dmem_dma_rd_addr),
    .L2_dmem_dma_rd_data    (L2_dmem_dma_rd_data),

    .L2_dmem_dma_wr_en      (L2_dmem_dma_wr_en),
    .L2_dmem_dma_wr_addr    (L2_dmem_dma_wr_addr),
    .L2_dmem_dma_wr_data    (L2_dmem_dma_wr_data)
);

//interface with core
logic                   fetch_req;
logic                   fetch_gnt;
logic           [31:0]  fetch_addr;
logic           [31:0]  fetch_r_data;
logic                   fetch_r_valid;


//interface with L1 to L2 interface
logic                   pri_cache_refill_req;
logic                   pri_cache_refill_gnt;
logic           [18:0]  pri_cache_refill_addr;
logic                   pri_cache_refill_lenth;
logic                   pri_cache_refill_r_valid;
logic           [31:0]  pri_cache_refill_r_data;

logic                   refill_done;
logic                   icache_work_en;
logic                   icache_sleep_en;
logic                   icache_lowpower_en;
logic                   core_wakeup_irq;
logic           [31:0]  boot_addr_i;

// instruction itf
icache_L1_L2_itf U_icache_L1_L2_itf(
    .clk                        (clk),
    .rst_n                      (rst_n),

    // .core_cmd_itf_req           (core_cmd_itf_req),
    // .core_cmd_itf_gnt           (core_cmd_itf_gnt),
    .c_cfg_itf_single_fetch     (c_cfg_itf_single_fetch),
    .c_cfg_itf_irq_en           (c_cfg_itf_irq_en),
    .core_sleep_irq_pulse       (core_sleep_irq_pulse),

    //pri cache interface
    .pri_cache_refill_req       (pri_cache_refill_req),
    .pri_cache_refill_gnt       (pri_cache_refill_gnt),
    .pri_cache_refill_addr      (pri_cache_refill_addr),
    .pri_cache_refill_lenth     (pri_cache_refill_lenth),
    .pri_cache_refill_r_valid   (pri_cache_refill_r_valid),
    .pri_cache_refill_r_data    (pri_cache_refill_r_data),

    .refill_done                (refill_done),
    .icache_work_en             (icache_work_en),
    .icache_sleep_en            (icache_sleep_en),
    .icache_lowpower_en         (icache_lowpower_en),
    .core_wakeup_irq            (core_wakeup_irq),
    .boot_addr_i                (boot_addr_i),
    .core_rst_n                 (core_rst_n),

    //to control core
    .fetch_L2cache_info         (fetch_L2cache_info),
    .fetch_L2cache_req          (fetch_L2cache_req),
    .fetch_L2cache_gnt          (fetch_L2cache_gnt),
    .fetch_L2cache_r_data       (fetch_L2cache_r_data),
    .fetch_L2cache_r_valid      (fetch_L2cache_r_valid),
    .fetch_L2cache_r_ready      (fetch_L2cache_r_ready)
);

logic core_rst_n_buf;

logic_buf U_rstn_buf(.Z(core_rst_n_buf),.I(core_rst_n));

// pri cache

pri_icache U_pri_icache(
    .clk                        (clk),
    .rst_n                      (core_rst_n_buf),

    //interface with core
    .fetch_req                  (fetch_req),
    .fetch_gnt                  (fetch_gnt),
    .fetch_addr                 (fetch_addr[18:0]),
    .fetch_r_data               (fetch_r_data),
    .fetch_r_valid              (fetch_r_valid),


    //interface with L1 to L2 interface
    .pri_cache_refill_req       (pri_cache_refill_req),
    .pri_cache_refill_gnt       (pri_cache_refill_gnt),
    .pri_cache_refill_addr      (pri_cache_refill_addr),
    .pri_cache_refill_lenth     (pri_cache_refill_lenth),
    .pri_cache_refill_r_valid   (pri_cache_refill_r_valid),
    .pri_cache_refill_r_data    (pri_cache_refill_r_data),

    .refill_done                (refill_done),
    .icache_work_en             (icache_work_en),
    .icache_sleep_en            (icache_sleep_en),
    .icache_lowpower_en         (icache_lowpower_en)
);

// core instance
/*

logic                   clk, rst_n;

logic           [31:0]  boot_addr_i,

//instruction interface:
logic                   fetch_req;
logic                   fetch_gnt;
logic           [18:0]  fetch_addr;
logic           [31:0]  fetch_r_data;
logic                   fetch_r_valid;

//core cmd interface:
logic                   core_cmd_req;
logic   [2:0]           core_cmd_addr;
logic                   core_cmd_gnt;
logic                   core_cmd_ok;
logic                   core_sleep_irq_pulse;
logic                   core_wakeup_irq;

//core cfg interface:
logic   [6:0]           core_cfg_addr;
logic   [12:0]          core_cfg_data;
logic                   core_cfg_valid;

//core input:
logic           [255:0]         core_in_data;
logic                           core_in_valid;

//core output:
logic           [255:0]         core_out_data;
logic                           core_out_valid;

*/

// fake_cu_core U_cu_core(
//     .clk                (clk), 
//     .rst_n              (rst_n),

//     .boot_addr_i        (boot_addr_i),

// //instruction interface:
//     .fetch_req          (fetch_req),
//     .fetch_gnt          (fetch_gnt),
//     .fetch_addr         (fetch_addr),
//     .fetch_r_data       (fetch_r_data),
//     .fetch_r_valid      (fetch_r_valid),

// //core cmd interface:
//     .core_cmd_req       (core_cmd_req),
//     .core_cmd_addr      (core_cmd_addr),
//     .core_cmd_gnt       (core_cmd_gnt),
//     .core_cmd_ok        (core_cmd_ok),
//     .core_enter_irq_pulse   (core_sleep_irq_pulse),
//     .core_wakeup_irq    (core_wakeup_irq),

// //core cfg interface:
//     .core_cfg_addr      (core_cfg_addr),
//     .core_cfg_data      (core_cfg_data),
//     .core_cfg_valid     (core_cfg_valid),

// //core input:
//     .core_in_data       (core_in_data),
//     .core_in_valid      (core_in_valid),

// //core output:
//     .core_out_data      (core_out_data),
//     .core_out_valid     (core_out_valid)
// );

CU_core_wrapper #(
    .NODE_ID                    (NODE_ID),
    .CLUSTER_ID                 (CLUSTER_ID)
)U_cu_core_wrapper(
    .clk                        (clk),
    .rst_n                      (core_rst_n),
    
    //riscv core
    .clock_en_i                 (1'b1), //enable clock, otherwise it is gated
    // .test_en_i                  (1'b0), //enable all clock gates for testing

    .boot_addr_i                (boot_addr_i),
    // .core_id_i                  (NODE_ID),
    // .cluster_id_i               (),    

    .fetch_enable_i             (icache_work_en),
    // .core_busy_o                (),

    //Instruction memory interface
    .riscv_instr_req_o          (fetch_req),
    .riscv_instr_gnt_i          (fetch_gnt),
    .riscv_instr_addr_o         (fetch_addr),
    .riscv_instr_rvalid_i       (fetch_r_valid),
    .riscv_instr_rdata_i        (fetch_r_data),

    //Interrupt inputs
    .core_wakeup_irq            (core_wakeup_irq),
      
    //Debug Interface
    // .debug_req_i                (1'b0), //to id
    // .ext_perf_counters_i        (1'b0),

    //to NOC
    .Noc_cmd_req_o              (core_cmd_req),
    .Noc_cmd_addr_o             (core_cmd_addr),
    .Noc_cmd_gnt_i              (core_cmd_gnt),
    .Noc_cmd_ok_i               (core_cmd_ok),
    
    .Noc_cfg_vld_o              (core_cfg_valid),
    .Noc_cfg_addr_o             (core_cfg_addr),
    .Noc_cfg_data_o             (core_cfg_data),
    .core_sleep_en_o            (core_sleep_irq_pulse),

    //from l2 noc
    .tcache_l2c_datain_vld      (core_in_valid),
    .tcache_l2c_datain_last     (core_in_last),
    .tcache_l2c_datain_ch0      (core_in_data),

    //to share cache
    .core_data_out              (core_out_data),
    .core_data_out_vld          (core_out_valid)
);

endmodule



// 这个out_valid代表当前节点的router接收到的数据有效，要发送给core内了
assign out_valid = node_out_valid_local;    //其他router传递给本router的valid信号，当有效时，router发送给core

assign node_out_ready_local = out_ready;    //out_ready 连接到in_c_channel的out_ready

genvar i;

generate

    for(i = 0; i < 2; i = i+1) begin

        assign out_flit[i] = node_out_flit_local;   //router要发送给core的flit

        assign out_last[i] = node_out_last_local;

    end

endgenerate
