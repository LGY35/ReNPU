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

    input                           c_cfg_c_r_local_access, //\u8ba1\u7b97\u5f97\u5230\uff0c\u5e76\u975e\u76f4\u63a5\u914d\u7f6e

    input           [3:0][12:0]     c_cfg_c_r_loop_lenth,
    input           [3:0][12:0]     c_cfg_c_r_loop_gap,
    input           [3:0]           c_cfg_c_r_pad_up_len,
    input           [3:0]           c_cfg_c_r_pad_right_len,
    input           [3:0]           c_cfg_c_r_pad_left_len,
    input           [3:0]           c_cfg_c_r_pad_bottom_len,

    input           [10:0]          c_cfg_c_r_pad_row_num,
    input           [10:0]          c_cfg_c_r_pad_col_num,
    input                           c_cfg_c_r_pad_mode,

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

    // output  logic   [255:0] cmmu_out_noc_out_data,
    // output  logic           cmmu_out_noc_out_valid,
    // output  logic           cmmu_out_noc_out_last, //to be determined
    // input                   cmmu_out_noc_out_ready,

    //noc input data
    input      [255:0]              noc_in_core_rd_data,
    input                           noc_in_core_rd_valid,
    input                           noc_in_core_rd_last,
    output  logic                   noc_in_core_rd_ready,

    output  logic                   L2_dmem_core_rd_en,
    output  logic   [12:0]          L2_dmem_core_rd_addr,
    input           [255:0]         L2_dmem_core_rd_data

);

localparam IDLE                 = 3'd0;
localparam NOC_RD_REQ           = 3'd1;
localparam NOC_PINGPONG_CHECK   = 3'd2;
localparam NOC_PING_RD          = 3'd3;
localparam NOC_PONG_RD          = 3'd4;
// localparam NORMAL_RD        = 3'd3;
localparam PINGPONG_CHECK       = 3'd5;
localparam PING_RD              = 3'd6;
localparam PONG_RD              = 3'd7;
// localparam WR_OUT_RESP  = 3'd3; //determine link list

logic [2:0] cs, ns;
logic [12:0] transfer_cnt, transfer_cnt_ns;
logic [11:0] pingpong_cnt, pingpong_cnt_ns;

logic addr_mu_initial_en;
logic [12:0] addr_mu_initial_addr;
logic [12:0] addr_mu_addr, addr_mu_addr_ns;
logic addr_mu_valid;
// logic addr_mu_finish;

always_comb begin
    ns = cs;
    transfer_cnt_ns = transfer_cnt;
    pingpong_cnt_ns = pingpong_cnt;

    core_cmd_core_rd_gnt = 'b0;
    // core_cmd_L2_ok = 'b0;

    core_rd_noc_out_req = 'b0;
    

    // cmmu_out_noc_out_data = core_cmmu_out_data;
    // cmmu_out_noc_out_valid = 'b0;
    core_in_data = L2_dmem_core_rd_data;
    core_in_valid = 'b0;
    core_in_last = 1'b0;

    pingpong_rd_done = 'b0;
    addr_mu_initial_en = 'b0;
    addr_mu_initial_addr = c_cfg_c_r_base_addr[0];
    addr_mu_valid = 'b0;
    // addr_mu_finish = 1'b0;

    L2_dmem_core_rd_en = 'b0;
    L2_dmem_core_rd_addr = 'b0;

    noc_in_core_rd_ready = 'b0;

    c_r_transaction_done = 1'b0;

    case(cs)    
    IDLE: begin
        if(core_cmd_core_rd_req) begin
            if(c_cfg_c_r_local_access)begin
                core_cmd_core_rd_gnt = 1'b1;

                ns = PING_RD;
                L2_dmem_core_rd_en = 1'b1;
                L2_dmem_core_rd_addr = c_cfg_c_r_base_addr[0];
                addr_mu_initial_en = 1'b1;
                // if(c_cfg_c_r_pingpong_en) begin
                //     ns = PINGPONG_CHECK;
                // end
                // else begin
                //     ns = NORMAL_RD;
                //     L2_dmem_core_rd_en = 1'b1;
                //     L2_dmem_core_rd_addr = c_cfg_c_r_base_addr[0];
                //     addr_mu_initial_en = 1'b1;
                // end
            end
            else begin
                // core_cmd_core_rd_gnt = 1'b1;
                // core_cmd_L2_ok = 1'b1; //? to be determined
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
            c_r_transaction_done = 1'b1;    //TODO: check
        end
        else if(pingpong_cnt[0] & core_cmd_core_rd_req) begin
            ns = PONG_RD;
        end
        else if(~pingpong_cnt[0] & core_cmd_core_rd_req) begin
            ns = PING_RD;
        end
    end
    NOC_PING_RD: begin
        core_in_data = noc_in_core_rd_data;
        core_in_valid = noc_in_core_rd_valid;
        noc_in_core_rd_ready = 1'b1;
        if(noc_in_core_rd_valid & noc_in_core_rd_ready) begin
            // if(transfer_cnt == core_cfg_core_rd_total_lenth) begin
            if(transfer_cnt == c_cfg_c_r_ping_lenth)begin
                ns = NOC_PINGPONG_CHECK;
                transfer_cnt_ns = 'b0;
                pingpong_cnt_ns = pingpong_cnt + 1'b1;
                core_in_last = 1'b1;
            end
            else begin
                transfer_cnt_ns = transfer_cnt + 1'b1;
            end
        end
    end
    NOC_PONG_RD: begin
        core_in_data = noc_in_core_rd_data;
        core_in_valid = noc_in_core_rd_valid;
        noc_in_core_rd_ready = 1'b1;
        if(noc_in_core_rd_valid & noc_in_core_rd_ready) begin
            // if(transfer_cnt == core_cfg_core_rd_total_lenth) begin
            if(transfer_cnt == c_cfg_c_r_pong_lenth)begin
                ns = NOC_PINGPONG_CHECK;
                transfer_cnt_ns = 'b0;
                pingpong_cnt_ns = pingpong_cnt + 1'b1;
                core_in_last = 1'b1;
            end
            else begin
                transfer_cnt_ns = transfer_cnt + 1'b1;
            end
        end
    end
    // NORMAL_RD: begin
    //     L2_dmem_core_rd_addr = addr_mu_addr; //to be modified to rd addr ctrl output
    //     // core_rd_L2_data_valid = 1'b1;
    //     core_in_valid = 1'b1;
    //     if(transfer_cnt == core_cfg_core_rd_total_lenth) begin //this cycle could trun off the ram rd enable
    //         ns = IDLE;
    //         transfer_cnt_ns = 'b0;
    //     end
    //     else begin
    //         L2_dmem_core_rd_en = 1'b1;
    //         transfer_cnt_ns = transfer_cnt + 1'b1;
    //         addr_mu_valid = 1'b1;
    //     end
    // end
    PINGPONG_CHECK: begin
        if(pingpong_cnt[11:1] == c_cfg_c_r_pingpong_num)begin //pingpong pairs number
            ns = IDLE;
            pingpong_cnt_ns = 'b0;
            c_r_transaction_done = 1'b1;    //TODO: check
        end
        else if(pingpong_cnt[0] & pingpong_state[1]) begin
            pingpong_cnt_ns = pingpong_cnt + 1'b1;
            ns = PONG_RD;
            L2_dmem_core_rd_en = 1'b1;
            L2_dmem_core_rd_addr = c_cfg_c_r_base_addr[1];
            addr_mu_initial_en = 1'b1;
            addr_mu_initial_addr = c_cfg_c_r_base_addr[1];
        end
        else if(~pingpong_cnt[0] & pingpong_state[0]) begin
            pingpong_cnt_ns = pingpong_cnt + 1'b1;
            ns = PING_RD;
            L2_dmem_core_rd_en = 1'b1;
            L2_dmem_core_rd_addr = c_cfg_c_r_base_addr[0];
            addr_mu_initial_en = 1'b1;
        end
    end
    PING_RD: begin
        L2_dmem_core_rd_addr = addr_mu_addr;
        core_in_valid = 1'b1;
        if(transfer_cnt == c_cfg_c_r_ping_lenth)begin
            ns = PINGPONG_CHECK;
            transfer_cnt_ns = 'b0;
            pingpong_rd_done = c_cfg_c_r_pingpong_en;
            core_in_last = 1'b1;
        end
        else begin
            L2_dmem_core_rd_en = 1'b1;
            transfer_cnt_ns = transfer_cnt + 1'b1;
            addr_mu_valid = 1'b1;
        end
    end
    PONG_RD: begin
        L2_dmem_core_rd_addr = addr_mu_addr;
        core_in_valid = 1'b1;
        if(transfer_cnt == c_cfg_c_r_pong_lenth)begin
            ns = PINGPONG_CHECK;
            transfer_cnt_ns = 'b0;
            pingpong_rd_done = c_cfg_c_r_pingpong_en;
            core_in_last = 1'b1;
        end
        else begin
            L2_dmem_core_rd_en = 1'b1;
            transfer_cnt_ns = transfer_cnt + 1'b1;
            addr_mu_valid = 1'b1;
        end
    end
    endcase
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cs <= IDLE;
        transfer_cnt <= 'b0;
        pingpong_cnt <= 'b0;
    end
    else begin
        cs <= ns;
        transfer_cnt <= transfer_cnt_ns;
        pingpong_cnt <= pingpong_cnt_ns;
    end
end

addr_mu U_addr_mu(
    .clk                (clk),
    .rst_n              (rst_n),

    .cfg_base_addr      (addr_mu_initial_addr),
    .cfg_gap            (c_cfg_c_r_loop_gap),
    .cfg_lenth          (c_cfg_c_r_loop_lenth),

    .addr_mu_initial_en (addr_mu_initial_en),
    .addr_mu_valid      (addr_mu_valid),

    .addr_mu_addr       (addr_mu_addr)
);

addr_mu_ns U_addr_mu_ns(
    .clk                (clk),
    .rst_n              (rst_n),

    .cfg_base_addr      (addr_mu_initial_addr),
    .cfg_gap            (c_cfg_c_r_loop_gap),
    .cfg_lenth          (c_cfg_c_r_loop_lenth),

    .addr_mu_initial_en (addr_mu_initial_en),
    .addr_mu_valid      (addr_mu_valid),

    .addr_mu_addr       (addr_mu_addr_ns)
);

endmodule