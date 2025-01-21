module dnoc_itf_core_wr(
    input                           clk,
    input                           rst_n,

    input                           core_cmd_core_wr_req,
    output  logic                   core_cmd_core_wr_gnt,

    //core cfg cmmu
    input           [1:0][12:0]     c_cfg_c_w_base_addr,
    // input           [12:0]          c_cfg_c_w_ping_lenth, //total lenth替换成了ping lenth
    input           [12:0]          c_cfg_c_w_ping_lenth,
    input           [12:0]          c_cfg_c_w_pong_lenth,

    input                           c_cfg_c_w_pingpong_en,
    input           [10:0]          c_cfg_c_w_pingpong_num,

    input                           c_cfg_c_w_local_access,

    input           [3:0][12:0]     c_cfg_c_w_loop_lenth,
    input           [3:0][12:0]     c_cfg_c_w_loop_gap,

    input           [1:0]           pingpong_state,
    output  logic                   pingpong_wr_done,

    output  logic                   c_w_transaction_done,//to reg 

    //core output data
    input   logic   [255:0]         core_out_data,
    input   logic                   core_out_valid,
    output  logic                   core_out_ready,

    //noc output read req 
    output  logic                   core_wr_noc_out_req,
    input                           core_wr_noc_out_gnt,

    output  logic   [255:0]         core_wr_noc_out_data,
    output  logic                   core_wr_noc_out_valid,
    output  logic                   core_wr_noc_out_last, //to be determined
    input                           core_wr_noc_out_ready,

    //noc input data
    // input      [255:0]              noc_in_core_rd_data,
    // input                           noc_in_core_rd_valid,
    // output  logic                   noc_in_core_rd_ready,
    input   logic                   noc_in_core_wr_response, //noc write response

    output  logic                   L2_dmem_core_wr_req,
    input                           L2_dmem_core_wr_gnt,
    output  logic   [12:0]          L2_dmem_core_wr_addr,
    output  logic   [255:0]         L2_dmem_core_wr_data,
    input                           L2_dmem_core_wr_resp

);

localparam IDLE             = 3'd0;
localparam NOC_WR_REQ       = 3'd1; //wr to next node pingpong to be determined
localparam NOC_WR           = 3'd2;
localparam NOC_WR_RESP      = 3'd3;
// localparam NORMAL_WR        = 3'd4;
localparam PINGPONG_CHECK   = 3'd5;
localparam PING_WR          = 3'd6;
localparam PONG_WR          = 3'd7;
// localparam WR_OUT_RESP  = 3'd3; //determine link list

logic [2:0] cs, ns;
logic [12:0] transfer_req_cnt, transfer_req_cnt_ns;
logic [12:0] transfer_valid_cnt, transfer_valid_cnt_ns;
logic [11:0] pingpong_cnt, pingpong_cnt_ns;
logic        wr_resp_cnt_hit;
logic        wr_req_en, wr_req_en_ns;

logic addr_mu_initial_en;
logic [12:0] addr_mu_initial_addr, addr_mu_addr;
logic addr_mu_valid;

always_comb begin
    ns = cs;
    transfer_req_cnt_ns = transfer_req_cnt;
    pingpong_cnt_ns = pingpong_cnt;
    wr_req_en_ns = wr_req_en;

    core_cmd_core_wr_gnt = 'b0;
    // core_cmd_L2_ok = 'b0;

    core_wr_noc_out_req = 'b0;
    

    // cmmu_out_noc_out_data = core_cmmu_out_data;
    // cmmu_out_noc_out_valid = 'b0;
    L2_dmem_core_wr_data = core_out_data;

    pingpong_wr_done = 'b0;
    addr_mu_initial_en = 'b0;
    addr_mu_initial_addr = c_cfg_c_w_base_addr[0];
    addr_mu_valid = 'b0;

    L2_dmem_core_wr_req = 'b0;
    L2_dmem_core_wr_addr = 'b0;

    core_wr_noc_out_valid = 'b0;
    core_wr_noc_out_last = 'b0;
    core_wr_noc_out_data = core_out_data;

    c_w_transaction_done = 1'b0;

    core_out_ready = 1'b0;

    case(cs)
    IDLE: begin
        if(core_cmd_core_wr_req) begin
            if(c_cfg_c_w_local_access)begin
                core_cmd_core_wr_gnt = 1'b1;

                addr_mu_initial_en = 1'b1;
                ns = PING_WR;
            end
            else begin
                ns = NOC_WR_REQ;
            end
        end
    end
    NOC_WR_REQ: begin
        core_wr_noc_out_req = 1'b1;

        if(core_wr_noc_out_gnt) begin
            core_cmd_core_wr_gnt = 1'b1;

            ns = NOC_WR;
        end
    end
    NOC_WR: begin
        core_wr_noc_out_valid = core_out_valid;
        core_out_ready = core_wr_noc_out_ready;

        // noc_in_core_rd_ready = 1'b1;
        if(core_wr_noc_out_valid & core_wr_noc_out_ready) begin
            if(transfer_req_cnt == c_cfg_c_w_ping_lenth) begin
                ns = NOC_WR_RESP;
                transfer_req_cnt_ns = 'b0;
                core_wr_noc_out_last = 1'b1;
            end
            else begin
                transfer_req_cnt_ns = transfer_req_cnt + 1'b1;
            end
        end
    end
    NOC_WR_RESP: begin
        if(noc_in_core_wr_response) begin
            ns = IDLE;
            c_w_transaction_done = 1'b1;
        end
    end
    PINGPONG_CHECK: begin
        if(pingpong_cnt[11:1] == c_cfg_c_w_pingpong_num)begin //pingpong pairs number
            ns = IDLE;
            pingpong_cnt_ns = 'b0;
            c_w_transaction_done = 1'b1;
        end
        else if(core_cmd_core_wr_req) begin
            if(pingpong_cnt[0] & ~pingpong_state[1]) begin
                core_cmd_core_wr_gnt = 1'b1;
                pingpong_cnt_ns = pingpong_cnt + 1'b1;
                ns = PONG_WR;
                addr_mu_initial_en = 1'b1;
                addr_mu_initial_addr = c_cfg_c_w_base_addr[1];
            end
            else if(~pingpong_cnt[0] & ~pingpong_state[0]) begin
                core_cmd_core_wr_gnt = 1'b1;
                pingpong_cnt_ns = pingpong_cnt + 1'b1;
                ns = PING_WR;
                addr_mu_initial_en = 1'b1;
            end
        end
    end
    PING_WR: begin
        L2_dmem_core_wr_addr = addr_mu_addr;
        L2_dmem_core_wr_req = core_out_valid & wr_req_en;
        core_out_ready = L2_dmem_core_wr_gnt;
        addr_mu_valid = L2_dmem_core_wr_req & L2_dmem_core_wr_gnt;
        if(L2_dmem_core_wr_req & L2_dmem_core_wr_gnt) begin
            if(transfer_req_cnt == c_cfg_c_w_ping_lenth)begin
                wr_req_en_ns = 1'b0;
                transfer_req_cnt_ns = 'b0;
                pingpong_wr_done = c_cfg_c_w_pingpong_en;
            end
            else begin
                transfer_req_cnt_ns = transfer_req_cnt + 1'b1;
            end
        end
        if(wr_resp_cnt_hit) begin
            wr_req_en_ns = 1'b1;
            ns = PINGPONG_CHECK;
        end
    end
    PONG_WR: begin
        L2_dmem_core_wr_addr = addr_mu_addr;
        L2_dmem_core_wr_req = core_out_valid & wr_req_en;
        core_out_ready = L2_dmem_core_wr_gnt;
        addr_mu_valid = L2_dmem_core_wr_req & L2_dmem_core_wr_gnt;
        if(L2_dmem_core_wr_req & L2_dmem_core_wr_gnt) begin
            if(transfer_req_cnt == c_cfg_c_w_pong_lenth)begin
                wr_req_en_ns = 1'b0;
                transfer_req_cnt_ns = 'b0;
                pingpong_wr_done = c_cfg_c_w_pingpong_en;
            end
            else begin
                transfer_req_cnt_ns = transfer_req_cnt + 1'b1;
            end
        end
        if(wr_resp_cnt_hit) begin
            wr_req_en_ns = 1'b1;
            ns = PINGPONG_CHECK;
        end
    end
    endcase
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        transfer_valid_cnt <= 'd0;
    end
    else if(wr_resp_cnt_hit) begin
        transfer_valid_cnt <= 'd0;
    end
    else if(((cs == PING_WR) | (cs == PONG_WR)) & L2_dmem_core_wr_resp) begin
        transfer_valid_cnt <= transfer_valid_cnt + 13'd1;
    end
end

assign wr_resp_cnt_hit = ((cs == PING_WR) & (transfer_valid_cnt == c_cfg_c_w_ping_lenth) & L2_dmem_core_wr_resp) | 
                         ((cs == PONG_WR) & (transfer_valid_cnt == c_cfg_c_w_pong_lenth) & L2_dmem_core_wr_resp);

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cs <= IDLE;
        transfer_req_cnt <= 'b0;
        pingpong_cnt <= 'b0;
        wr_req_en <= 1'b1;
    end
    else begin
        cs <= ns;
        transfer_req_cnt <= transfer_req_cnt_ns;
        pingpong_cnt <= pingpong_cnt_ns;
        wr_req_en <= wr_req_en_ns;
    end
end

addr_mu U_addr_mu(
    .clk                (clk),
    .rst_n              (rst_n),

    .cfg_base_addr      (addr_mu_initial_addr),
    .cfg_gap            (c_cfg_c_w_loop_gap),
    .cfg_lenth          (c_cfg_c_w_loop_lenth),

    .addr_mu_initial_en (addr_mu_initial_en),
    .addr_mu_valid      (addr_mu_valid),

    .addr_mu_addr       (addr_mu_addr)
);

endmodule