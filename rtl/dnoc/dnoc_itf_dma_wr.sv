//
// 有两部分通道，一部分连接core，一部分连接noc




module dnoc_itf_dma_wr(

    input                           clk,

    input                           rst_n,



    //core cfg cmmu     //core用来配置dma wr通道的端口

    input           [1:0][12:0]     c_cfg_d_w_ram_base_addr,

    // input           [12:0]          c_cfg_d_w_ram_total_lenth,

    input           [12:0]          c_cfg_d_w_ping_lenth,

    input           [12:0]          c_cfg_d_w_pong_lenth,



    input                           c_cfg_d_w_pingpong_en,

    input           [10:0]          c_cfg_d_w_pingpong_num,



    input           [24:0]          c_cfg_d_w_noc_base_addr, //11 13拼装成

    // input           [3:0]           c_cfg_d_w_noc_target_id, 

    // output  logic   [21:0]          c_cfg_d_w_noc_addr,

    // input           [21:0]          c_cfg_d_w_noc_lenth,

    // input           [2:0]   core_cmd_L2_mode,



    input           [3:0][12:0]     c_cfg_d_w_loop_lenth,

    input           [3:0][12:0]     c_cfg_d_w_loop_gap,



    input                           core_cmd_dma_wr_req,

    output  logic                   core_cmd_dma_wr_gnt,

    output  logic                   d_w_transaction_done,//to reg 

    // output  logic           core_cmd_L2_ok,



    //core data

    // input   logic   [255:0] core_wr_L2_data,

    // input   logic           core_wr_L2_data_valid,

    //////////////////////////////////////////////////////////ready?



    input           [1:0]           pingpong_state,

    output  logic                   pingpong_wr_done,



    //noc cfg dma,      //

    input           [12:0]          n_cfg_d_w_ram_base_addr,

    input           [12:0]          n_cfg_d_w_ram_total_lenth,

    input           [3:0]           n_cfg_d_w_source_id, // 这部分就是复用的noc_mc_scale的最低4bit
    input                           n_cfg_d_w_resp_sel, //0: core; 1:dma



    input           [3:0][12:0]     n_cfg_d_w_loop_lenth,

    input           [3:0][12:0]     n_cfg_d_w_loop_gap,



    input                           noc_cmd_dma_wr_req,

    output  logic                   noc_cmd_dma_wr_gnt,



    //noc write input data

    input           [255:0]         noc_in_dma_wr_data,

    input                           noc_in_dma_wr_valid,

    output  logic                   noc_in_dma_wr_ready,



    //noc req : read out req or write in response

    output  logic                   dma_wr_noc_out_req,

    input                           dma_wr_noc_out_gnt,

    output  logic   [24:0]          d_w_n_o_cfg_base_addr,

    output  logic   [12:0]          d_w_n_o_cfg_lenth, //发给c out 每次读的数据长度

    // output  logic   [3:0]           d_w_n_o_cfg_noc_target_id,

    // output  logic   [21:0]          d_w_n_o_cfg_total_lenth, 

    output  logic                   d_w_n_o_cfg_mode, // read out req or write in response

    // output  logic   [3:0]   dmmu_wr_noc_out_node_id, // addr lut

    output  logic                   d_w_n_o_cfg_resp_sel,



    //to noc input: control the read data return to dmmu or cmmu rd channel

    // output  logic                   dmmu_wr_dma_rd_in_pulse,



    //ram rd control

    output  logic                   L2_dmem_dma_wr_en,

    output  logic   [12:0]          L2_dmem_dma_wr_addr,

    output  logic   [255:0]         L2_dmem_dma_wr_data



);



localparam IDLE             = 3'd0;

localparam PINGPONG_CHECK   = 3'd1;

localparam DMA_RD_OUT_REQ   = 3'd2;

localparam PING_WR          = 3'd3;

localparam PONG_WR          = 3'd4;

// localparam NOC_WR           = 3'd4; //receive noc write data

localparam NOC_WR_RESP      = 3'd5; //return noc write response





logic [2:0] cs, ns;

logic [12:0] d_w_ram_cnt, d_w_ram_cnt_ns;

// logic dmmu_wr_noc_out_req_ns; // to be determined

logic [24:0] d_w_n_o_cfg_base_addr_ns;

// logic [21:0] d_w_n_o_cfg_total_lenth_ns;

// logic dmmu_wr_noc_out_mode_ns;



logic   [1:0][12:0] cfg_d_w_ram_base_addr, cfg_d_w_ram_base_addr_ns;

// logic   [17:0]      cfg_d_w_ram_total_lenth, cfg_d_w_ram_total_lenth_ns;

logic   [12:0]      cfg_d_w_ping_lenth, cfg_d_w_ping_lenth_ns;

logic   [12:0]      cfg_d_w_pong_lenth, cfg_d_w_pong_lenth_ns;

logic   [3:0][12:0] cfg_d_w_loop_lenth, cfg_d_w_loop_lenth_ns;

logic   [3:0][12:0] cfg_d_w_loop_gap, cfg_d_w_loop_gap_ns;



logic cfg_d_w_pingpong_num, cfg_d_w_pingpong_num_ns;

logic cfg_d_w_pingpong_en, cfg_d_w_pingpong_en_ns;





logic               d_w_n_o_cfg_mode_ns;

logic               d_w_n_o_cfg_resp_sel_ns;

// logic   [12:0]      d_w_n_o_cfg_lenth_ns;

// logic   [3:0]       d_w_n_o_cfg_noc_target_id_ns;



logic addr_mu_initial_en;

logic [12:0] addr_mu_initial_addr, addr_mu_addr;

logic addr_mu_valid;



logic [10:0] pingpong_cnt, pingpong_cnt_ns;



always_comb begin

    ns = cs;



    d_w_ram_cnt_ns = d_w_ram_cnt;

    pingpong_cnt_ns = pingpong_cnt;



    // cfg_d_w_ram_total_lenth_ns = cfg_d_w_ram_total_lenth;

    cfg_d_w_ram_base_addr_ns = cfg_d_w_ram_base_addr;

    cfg_d_w_pingpong_num_ns = cfg_d_w_pingpong_num;

    cfg_d_w_pingpong_en_ns = cfg_d_w_pingpong_en;



    cfg_d_w_ping_lenth_ns = cfg_d_w_ping_lenth;

    cfg_d_w_pong_lenth_ns = cfg_d_w_pong_lenth;

    cfg_d_w_loop_lenth_ns = cfg_d_w_loop_lenth;

    cfg_d_w_loop_gap_ns = cfg_d_w_loop_gap;



    core_cmd_dma_wr_gnt = 'b0;

    // core_cmd_L2_ok = 'b0;



    noc_cmd_dma_wr_gnt = 'b0;



    noc_in_dma_wr_ready = 'b0;



    dma_wr_noc_out_req = 'b0;

    d_w_n_o_cfg_base_addr_ns = d_w_n_o_cfg_base_addr;

    // d_w_n_o_cfg_total_lenth_ns = d_w_n_o_cfg_total_lenth;

    // dmmu_wr_noc_out_mode_ns = d_w_n_o_cfg_mode;

    d_w_n_o_cfg_mode_ns = d_w_n_o_cfg_mode;

    // d_w_n_o_cfg_mode = 1'b0;

    // dmmu_wr_noc_out_node_id = 'b0; // to be determined

    d_w_n_o_cfg_resp_sel_ns = d_w_n_o_cfg_resp_sel;

    // d_w_n_o_cfg_noc_target_id_ns = d_w_n_o_cfg_noc_target_id;



    // dmmu_wr_noc_out_data = L2_dmem_dma_wr_data;

    // dmmu_wr_noc_out_valid = 'b0;



    // dmmu_wr_dma_wr_out_pulse = 'b0;



    L2_dmem_dma_wr_en = 'b0;

    L2_dmem_dma_wr_addr = 'b0;

    L2_dmem_dma_wr_data = noc_in_dma_wr_data;



    addr_mu_initial_en = 'b0;

    addr_mu_initial_addr = cfg_d_w_ram_base_addr[0];

    addr_mu_valid = 'b0;



    d_w_transaction_done = 1'b0;



    case(cs)

    IDLE: begin

        if(core_cmd_dma_wr_req) begin

            core_cmd_dma_wr_gnt = 1'b1;



            cfg_d_w_ram_base_addr_ns = c_cfg_d_w_ram_base_addr;

            // cfg_d_w_ram_total_lenth_ns = c_cfg_d_w_ram_total_lenth; //ram read control signals (source)

            

            d_w_n_o_cfg_base_addr_ns = c_cfg_d_w_noc_base_addr; //noc write out control signals (destination)

            // d_w_n_o_cfg_total_lenth_ns = c_cfg_d_w_noc_lenth;  //lenth could be one?

            cfg_d_w_pingpong_en_ns = c_cfg_d_w_pingpong_en;

            cfg_d_w_pingpong_num_ns = c_cfg_d_w_pingpong_num;

            cfg_d_w_ping_lenth_ns = c_cfg_d_w_ping_lenth;

            cfg_d_w_pong_lenth_ns = c_cfg_d_w_pong_lenth;

            cfg_d_w_loop_lenth_ns = c_cfg_d_w_loop_lenth;

            cfg_d_w_loop_gap_ns = c_cfg_d_w_loop_gap;

            // d_w_n_o_cfg_noc_target_id_ns = c_cfg_d_w_noc_base_addr[16:13];

            

            d_w_n_o_cfg_mode_ns = 1'b0; //

            // d_w_ram_cnt_ns = 'b0;



            ns = DMA_RD_OUT_REQ;

        end

        else if(noc_cmd_dma_wr_req) begin

            noc_cmd_dma_wr_gnt = 1'b1;

            

            cfg_d_w_ram_base_addr_ns = n_cfg_d_w_ram_base_addr;

            cfg_d_w_ping_lenth_ns = n_cfg_d_w_ram_total_lenth;

            cfg_d_w_pong_lenth_ns = 'b0;

            // cfg_d_w_ram_total_lenth_ns = n_cfg_d_w_ram_total_lenth;

            cfg_d_w_pingpong_en_ns = 'b0;

            cfg_d_w_pingpong_num_ns = 'b0;

            cfg_d_w_loop_lenth_ns = n_cfg_d_w_loop_lenth;

            cfg_d_w_loop_gap_ns = n_cfg_d_w_loop_gap;



            d_w_n_o_cfg_base_addr_ns = {8'b0, n_cfg_d_w_source_id, 13'b0};

            d_w_n_o_cfg_mode_ns = 1'b1;

            d_w_n_o_cfg_resp_sel_ns = n_cfg_d_w_resp_sel;

            // d_w_n_o_cfg_noc_target_id_ns = n_cfg_d_w_source_id;



            //pingpong lenth to be determined

            // d_w_ram_cnt_ns = 'b0;



            addr_mu_initial_addr = n_cfg_d_w_ram_base_addr;

            addr_mu_initial_en = 1'b1;



            ns = PING_WR;

        end

    end

    PINGPONG_CHECK: begin

        if(pingpong_cnt[10:1] == cfg_d_w_pingpong_num)begin //pingpong pairs number

            ns = IDLE;

            pingpong_cnt_ns = 'b0;

            d_w_transaction_done = 1'b1;

        end

        else if((pingpong_cnt[0] & ~pingpong_state[1]) | (~pingpong_cnt[0] & ~pingpong_state[0])) begin

            ns = DMA_RD_OUT_REQ;

        end

        // else if(~pingpong_cnt[0] & ~pingpong_state[0]) begin

        //     ns = DMA_RD_OUT_REQ;

        // end

    end

    DMA_RD_OUT_REQ: begin

        dma_wr_noc_out_req = 1'b1;

        // d_w_n_o_cfg_mode = 1'b0;



        if(pingpong_cnt[0]) begin

            d_w_n_o_cfg_lenth = cfg_d_w_pong_lenth;

            addr_mu_initial_en = 1'b1;

            addr_mu_initial_addr = cfg_d_w_ram_base_addr[1];

        end

        else begin

            d_w_n_o_cfg_lenth = cfg_d_w_ping_lenth;

            addr_mu_initial_en = 1'b1;

        end



        if(dma_wr_noc_out_gnt) begin

            if(pingpong_cnt[0]) begin

                ns = PONG_WR;

            end

            else begin

                ns = PING_WR;

            end

        end

    end

    PING_WR: begin

        L2_dmem_dma_wr_addr = addr_mu_addr;

        L2_dmem_dma_wr_en = noc_in_dma_wr_valid;

        addr_mu_valid = noc_in_dma_wr_valid;

        // L2_dmem_dma_wr_data = noc_in_dma_wr_data;

        noc_in_dma_wr_ready = noc_in_dma_wr_valid;



        if(noc_in_dma_wr_valid) begin

            if(d_w_ram_cnt == cfg_d_w_ping_lenth) begin

                d_w_ram_cnt_ns = 'b0;

                if(d_w_n_o_cfg_mode) begin

                    ns = NOC_WR_RESP;

                end

                else begin

                    ns = PINGPONG_CHECK;

                    pingpong_cnt_ns = pingpong_cnt + 1'b1;

                    pingpong_wr_done = cfg_d_w_pingpong_en;

                    d_w_n_o_cfg_base_addr_ns = d_w_n_o_cfg_base_addr + cfg_d_w_ping_lenth;

                    // d_w_n_o_cfg_noc_target_id_ns = d_w_n_o_cfg_base_addr_ns[16:13];//

                end

            end

            else begin

                d_w_ram_cnt_ns = d_w_ram_cnt + 1'b1;

            end

        end

    end

    PONG_WR: begin

        L2_dmem_dma_wr_addr = addr_mu_addr;

        L2_dmem_dma_wr_en = noc_in_dma_wr_valid;

        addr_mu_valid = noc_in_dma_wr_valid;

        // L2_dmem_dma_wr_data = noc_in_dma_wr_data;

        noc_in_dma_wr_ready = noc_in_dma_wr_valid;



        if(noc_in_dma_wr_valid) begin

            if(d_w_ram_cnt == cfg_d_w_pong_lenth) begin

                ns = PINGPONG_CHECK;

                pingpong_cnt_ns = pingpong_cnt + 1'b1;

                d_w_ram_cnt_ns = 'b0;

                pingpong_wr_done = cfg_d_w_pingpong_en;

                d_w_n_o_cfg_base_addr_ns = d_w_n_o_cfg_base_addr + cfg_d_w_pong_lenth;

                // d_w_n_o_cfg_noc_target_id_ns = d_w_n_o_cfg_base_addr_ns[16:13];

            end

            else begin

                d_w_ram_cnt_ns = d_w_ram_cnt + 1'b1;

            end

        end

    end

    NOC_WR_RESP: begin

        dma_wr_noc_out_req = 1'b1;

        // d_w_n_o_cfg_mode = 1'b1;



        if(dma_wr_noc_out_gnt) begin

            ns = IDLE;

            d_w_transaction_done = 1'b1;

        end

    end

    endcase

end



// always_comb begin

//     cfg_d_w_ram_base_addr_ns = cfg_d_w_ram_base_addr;

//     cfg_d_w_ram_total_lenth_ns = cfg_d_w_ram_total_lenth;

//     cfg_d_w_ping_lenth_ns = cfg_d_w_ping_lenth;

//     cfg_d_w_pong_lenth_ns = cfg_d_w_pong_lenth;



//     case(cs)

//     IDLE: begin

//         if() begin



//         end

//         else if() begin

            

//         end

//     end

//     endcase



// end



always_ff @(posedge clk or negedge rst_n) begin

    if(!rst_n) begin

        cs <= IDLE;

        d_w_ram_cnt <= 'b0;

        pingpong_cnt <= 'b0;

        // cfg_d_w_ram_total_lenth <= 'b0;

        cfg_d_w_ram_base_addr <= 'b0;



        cfg_d_w_pingpong_en <= 'b0;

        cfg_d_w_pingpong_num <= 'b0;

        cfg_d_w_ping_lenth <= 'b0;

        cfg_d_w_pong_lenth <= 'b0;

        cfg_d_w_loop_lenth <= 'b0;

        cfg_d_w_loop_gap <= 'b0;



        d_w_n_o_cfg_base_addr <= 'b0;

        // d_w_n_o_cfg_total_lenth <= 'b0;

        d_w_n_o_cfg_mode <= 'b0;

        d_w_n_o_cfg_resp_sel <= 'b0;

        // d_w_n_o_cfg_noc_target_id <= 'b0;

    end

    else begin

        cs <= ns;

        d_w_ram_cnt <= d_w_ram_cnt_ns;

        pingpong_cnt <= pingpong_cnt_ns;

        // cfg_d_w_ram_total_lenth <= cfg_d_w_ram_total_lenth_ns;

        cfg_d_w_ram_base_addr <= cfg_d_w_ram_base_addr_ns;



        cfg_d_w_pingpong_en <= cfg_d_w_pingpong_en_ns;

        cfg_d_w_pingpong_num <= cfg_d_w_pingpong_num_ns;

        cfg_d_w_ping_lenth <= cfg_d_w_ping_lenth_ns;

        cfg_d_w_pong_lenth <= cfg_d_w_pong_lenth_ns;



        cfg_d_w_loop_lenth <= cfg_d_w_loop_lenth_ns;

        cfg_d_w_loop_gap <= cfg_d_w_loop_gap_ns;



        d_w_n_o_cfg_base_addr <= d_w_n_o_cfg_base_addr_ns;

        // d_w_n_o_cfg_total_lenth <= d_w_n_o_cfg_total_lenth_ns;

        d_w_n_o_cfg_mode <= d_w_n_o_cfg_mode_ns;

        d_w_n_o_cfg_resp_sel <= d_w_n_o_cfg_resp_sel_ns;

        // d_w_n_o_cfg_noc_target_id <= d_w_n_o_cfg_noc_target_id_ns;

    end

end



addr_mu U_addr_mu(

    .clk                (clk),

    .rst_n              (rst_n),



    .cfg_base_addr      (addr_mu_initial_addr),

    .cfg_gap            (cfg_d_w_loop_gap),

    .cfg_lenth          (cfg_d_w_loop_lenth),



    .addr_mu_initial_en (addr_mu_initial_en),

    .addr_mu_valid      (addr_mu_valid),



    .addr_mu_addr       (addr_mu_addr)

);



endmodule