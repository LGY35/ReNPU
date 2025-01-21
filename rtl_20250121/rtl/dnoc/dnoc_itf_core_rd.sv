module dnoc_itf_core_rd(
    input                           clk,
    input                           rst_n,

    input                           core_cmd_core_rd_req,
    output  logic                   core_cmd_core_rd_gnt,

    //core cfg cmmu
    input           [1:0][12:0]     c_cfg_c_r_base_addr,
    // input           [21:0]          core_cfg_core_rd_total_lenth,
    input           [12:0]          c_cfg_c_r_ping_lenth,
    input           [12:0]          c_cfg_c_r_pong_lenth,

    input                           c_cfg_c_r_pingpong_en,
    input           [10:0]          c_cfg_c_r_pingpong_num,

    input                           c_cfg_c_r_local_access, //计算得到，并非直接配置
    input                           c_cfg_c_r_dma_transfer_n,

    input           [3:0][12:0]     c_cfg_c_r_loop_lenth,
    input           [3:0][12:0]     c_cfg_c_r_loop_gap,
    input           [3:0]           c_cfg_c_r_pad_up_len,
    input           [3:0]           c_cfg_c_r_pad_right_len,
    input           [10:0]          c_cfg_c_r_pad_left_len,
    input           [4:0]           c_cfg_c_r_pad_bottom_len,

    input           [10:0]          c_cfg_c_r_pad_row_num,
    input           [10:0]          c_cfg_c_r_pad_col_num,
    input           [1:0]           c_cfg_c_r_pad_mode,

    input           [1:0]           pingpong_state,
    output  logic                   pingpong_rd_done,

    output  logic                   c_r_transaction_done,//to reg 

    //core output data
    output  logic   [255:0]         core_in_data,
    output  logic                   core_in_valid,
    output  logic                   core_in_last,

    //noc output read req 
    output  logic                   core_rd_noc_out_req,
    input                           core_rd_noc_out_gnt,

    //noc input data
    input      [255:0]              noc_in_core_rd_data,
    input                           noc_in_core_rd_valid,
    input                           noc_in_core_rd_last,
    output  logic                   noc_in_core_rd_ready,

    output  logic                   L2_dmem_core_rd_req,
    input                           L2_dmem_core_rd_gnt,
    output  logic   [12:0]          L2_dmem_core_rd_addr,
    input                           L2_dmem_core_rd_valid,
    input           [255:0]         L2_dmem_core_rd_data,
    output  logic                   L2_dmem_core_rd_ready

);

localparam IDLE                 = 3'd0;
localparam NOC_RD_REQ           = 3'd1;
localparam NOC_PINGPONG_CHECK   = 3'd2;
localparam NOC_PING_RD          = 3'd3;
localparam NOC_PONG_RD          = 3'd4;
localparam PINGPONG_CHECK       = 3'd5;
localparam PING_RD              = 3'd6;
localparam PONG_RD              = 3'd7;
// localparam WR_OUT_RESP  = 3'd3; //determine link list

logic [2:0] cs, ns;
// logic [12:0] transfer_cnt, transfer_cnt_ns;
logic [11:0] pingpong_cnt, pingpong_cnt_ns;

// logic addr_mu_initial_en;
logic core_rd_start;
logic core_rd_backpress_finish;
logic [12:0] addr_mu_initial_addr;
// logic [12:0] addr_mu_addr, addr_mu_addr_ns;
// logic addr_mu_valid;
// logic addr_mu_finish;
logic [12:0] no_pad_target_lenth;

logic      [255:0]      bp_noc_in_data     ;
logic                   bp_noc_in_valid    ;
logic                   bp_noc_in_last     ;
logic                   bp_noc_in_ready    ;


always_comb begin
    ns = cs;
    pingpong_cnt_ns = pingpong_cnt;

    core_cmd_core_rd_gnt = 'b0;
    c_r_transaction_done = 1'b0;

    core_rd_noc_out_req = 'b0;

    pingpong_rd_done = 'b0;


    addr_mu_initial_addr = c_cfg_c_r_base_addr[0];
    core_rd_start = 1'b0;
    no_pad_target_lenth = c_cfg_c_r_ping_lenth;

    bp_noc_in_data = noc_in_core_rd_data;
    bp_noc_in_valid = 1'b0;
    bp_noc_in_last = 1'b0;
    noc_in_core_rd_ready = 1'b0;
    // bp_core_rd_ready = ;

    L2_dmem_core_rd_ready = 1'b1;

    case(cs)
    IDLE: begin
        if(core_cmd_core_rd_req) begin
            core_rd_start = 1'b1;

            if(c_cfg_c_r_local_access & c_cfg_c_r_dma_transfer_n)begin
                core_cmd_core_rd_gnt = 1'b1;
                ns = PING_RD;
            end
            else begin
                ns = NOC_RD_REQ;
            end
        end
    end
    NOC_RD_REQ: begin
        core_rd_noc_out_req = 1'b1;

        if(core_rd_noc_out_gnt) begin
            core_cmd_core_rd_gnt = 1'b1;

            ns = NOC_PING_RD;
        end
    end
    NOC_PINGPONG_CHECK: begin
        if(pingpong_cnt[11:1] == c_cfg_c_r_pingpong_num)begin //pingpong pairs number
            ns = IDLE;
            pingpong_cnt_ns = 'b0;
            c_r_transaction_done = 1'b1;
        end
        else if(pingpong_cnt[0] & core_cmd_core_rd_req) begin
            ns = NOC_PONG_RD;
        end
        else if(~pingpong_cnt[0] & core_cmd_core_rd_req) begin
            ns = NOC_PING_RD;
        end
    end
    NOC_PING_RD: begin
        noc_in_core_rd_ready = bp_noc_in_ready;
        bp_noc_in_valid = noc_in_core_rd_valid;
        if(core_rd_backpress_finish) begin
            ns = NOC_PINGPONG_CHECK;
            pingpong_cnt_ns = pingpong_cnt + 12'd1;
        end
    end
    NOC_PONG_RD: begin
        noc_in_core_rd_ready = bp_noc_in_ready;
        bp_noc_in_valid = noc_in_core_rd_valid;
        no_pad_target_lenth = c_cfg_c_r_pong_lenth;
        if(core_rd_backpress_finish) begin
            ns = NOC_PINGPONG_CHECK;
            pingpong_cnt_ns = pingpong_cnt + 12'd1;
        end
    end
    PINGPONG_CHECK: begin
        if(pingpong_cnt[11:1] == c_cfg_c_r_pingpong_num)begin //pingpong pairs number
            ns = IDLE;
            pingpong_cnt_ns = 'b0;
            c_r_transaction_done = 1'b1;
        end
        else if(pingpong_cnt[0] & pingpong_state[1]) begin
            ns = PONG_RD;
            core_rd_start = 1'b1;
            addr_mu_initial_addr = c_cfg_c_r_base_addr[1];
        end
        else if(~pingpong_cnt[0] & pingpong_state[0]) begin
            ns = PING_RD;
            core_rd_start = 1'b1;
        end
    end
    PING_RD: begin
        if(core_rd_backpress_finish)begin
            ns = PINGPONG_CHECK;
            pingpong_rd_done = c_cfg_c_r_pingpong_en;
            // core_in_last = 1'b1;
            pingpong_cnt_ns = pingpong_cnt + 1'b1;
        end
    end
    PONG_RD: begin
        no_pad_target_lenth = c_cfg_c_r_pong_lenth;
        if(core_rd_backpress_finish)begin
            ns = PINGPONG_CHECK;
            pingpong_rd_done = c_cfg_c_r_pingpong_en;
            pingpong_cnt_ns = pingpong_cnt + 1'b1;
            // core_in_last = 1'b1;
        end
    end
    endcase
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cs <= IDLE;
        // transfer_cnt <= 'b0;
        pingpong_cnt <= 'b0;
    end
    else begin
        cs <= ns;
        // transfer_cnt <= transfer_cnt_ns;
        pingpong_cnt <= pingpong_cnt_ns;
    end
end

// addr_mu U_addr_mu(
//     .clk                (clk),
//     .rst_n              (rst_n),

//     .cfg_base_addr      (addr_mu_initial_addr),
//     .cfg_gap            (c_cfg_c_r_loop_gap),
//     .cfg_lenth          (c_cfg_c_r_loop_lenth),

//     .addr_mu_initial_en (addr_mu_initial_en),
//     .addr_mu_valid      (addr_mu_valid),

//     .addr_mu_addr       (addr_mu_addr)
// );

// addr_mu_ns U_addr_mu_ns(
//     .clk                (clk),
//     .rst_n              (rst_n),

//     .cfg_base_addr      (addr_mu_initial_addr),
//     .cfg_gap            (c_cfg_c_r_loop_gap),
//     .cfg_lenth          (c_cfg_c_r_loop_lenth),

//     .addr_mu_initial_en (addr_mu_initial_en),
//     .addr_mu_valid      (addr_mu_valid),

//     .addr_mu_addr       (addr_mu_addr_ns)
// );

dnoc_core_rd_backpress U_dnoc_core_rd_backpress(
    .clk                        (clk),
    .rst_n                      (rst_n),

    .c_cfg_c_r_pad_up_len       (c_cfg_c_r_pad_up_len),
    .c_cfg_c_r_pad_right_len    (c_cfg_c_r_pad_right_len),
    .c_cfg_c_r_pad_left_len     (c_cfg_c_r_pad_left_len),
    .c_cfg_c_r_pad_bottom_len   (c_cfg_c_r_pad_bottom_len),

    .c_cfg_c_r_pad_row_num      (c_cfg_c_r_pad_row_num),
    .c_cfg_c_r_pad_col_num      (c_cfg_c_r_pad_col_num),

    .c_cfg_c_r_pad_mode         (c_cfg_c_r_pad_mode),

    .c_cfg_c_r_local_access     (c_cfg_c_r_local_access),
    .c_cfg_c_r_dma_transfer_n   (c_cfg_c_r_dma_transfer_n),
    .c_cfg_c_r_loop_lenth       (c_cfg_c_r_loop_lenth),
    .c_cfg_c_r_loop_gap         (c_cfg_c_r_loop_gap),
    .no_pad_target_lenth        (no_pad_target_lenth),

    .rd_initial_addr            (addr_mu_initial_addr),
    .core_rd_start              (core_rd_start),
    .core_rd_backpress_finish   (core_rd_backpress_finish),

    .bp_mem_rd_req              (L2_dmem_core_rd_req),
    .bp_mem_rd_gnt              (L2_dmem_core_rd_gnt),
    .bp_mem_rd_addr             (L2_dmem_core_rd_addr),
    .bp_mem_rd_data             (L2_dmem_core_rd_data),
    .bp_mem_rd_valid            (L2_dmem_core_rd_valid),

    .noc_in_data                (bp_noc_in_data),
    .noc_in_valid               (bp_noc_in_valid),
    .noc_in_ready               (bp_noc_in_ready),
    .noc_in_last                (bp_noc_in_last),

    .core_in_data               (core_in_data),
    .core_in_last               (core_in_last),
    .core_in_valid              (core_in_valid)

);

endmodule