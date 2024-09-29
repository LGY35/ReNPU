module dnoc_itf_dma_rd(

    input                           clk,

    input                           rst_n,



    //core cfg dmmu

    input           [1:0][12:0]     c_cfg_d_r_ram_base_addr,

    // input           [12:0]          c_cfg_d_r_ram_total_lenth,

    input           [12:0]          c_cfg_d_r_ping_lenth,

    input           [12:0]          c_cfg_d_r_pong_lenth,



    input                           c_cfg_d_r_pingpong_en,

    input           [10:0]          c_cfg_d_r_pingpong_num,



    input           [24:0]          c_cfg_d_r_noc_base_addr,

    // input           [17:0]          core_cfg_dmmu_lenth,



    input           [3:0][12:0]     c_cfg_d_r_loop_lenth,

    input           [3:0][12:0]     c_cfg_d_r_loop_gap,



    input                           core_cmd_dma_rd_req,

    output  logic                   core_cmd_dma_rd_gnt,

    output  logic                   d_r_transaction_done,//to reg 

    // output  logic                   core_cmd_rd_L2_ok,

    // input           [1:0]           core_cmd_rd_L2_mode, //0: core read; 1: core cfg dma write out



    //core data

    // output  logic   [255:0]         core_rd_L2_data,

    // output  logic                   core_rd_L2_data_valid,



    input           [1:0]           pingpong_state,

    output  logic                   pingpong_rd_done,



    //noc cfg dma,

    input           [1:0][12:0]     n_cfg_d_r_ram_base_addr,

    // input           [12:0]          n_cfg_d_r_ram_total_lenth,

    input           [12:0]          n_cfg_d_r_ping_lenth,

    input           [12:0]          n_cfg_d_r_pong_lenth,

    // input           [11:0]          n_cfg_d_r_source_id,

    input                           n_cfg_d_r_pingpong_en,

    input           [10:0]          n_cfg_d_r_pingpong_num,



    input           [3:0][12:0]     n_cfg_d_r_loop_lenth,

    input           [3:0][12:0]     n_cfg_d_r_loop_gap,



    input           [11:0]          n_cfg_d_r_noc_mc_scale,

    input                           n_cfg_d_r_req_sel,



    input                           noc_cmd_dma_rd_req,

    output  logic                   noc_cmd_dma_rd_gnt,



    //noc req 

    output  logic                   dma_rd_noc_out_req,

    input                           dma_rd_noc_out_gnt,

    output  logic   [24:0]          d_r_n_o_cfg_base_addr,

    output  logic   [12:0]          d_r_n_o_cfg_lenth,

    output  logic   [11:0]          d_r_n_o_cfg_noc_mc_scale,

    output  logic                   d_r_n_o_cfg_req_sel,

    // output  logic   [21:0]          dmmu_rd_noc_out_cfg_lenth,

    output  logic                   d_r_n_o_cfg_mode, // dma write or noc read

    // output  logic   [3:0]   dmmu_rd_noc_out_node_id,



    //noc read output data

    output  logic   [255:0]         dma_rd_noc_out_data,

    output  logic                   dma_rd_noc_out_valid,

    output  logic                   dma_rd_noc_out_last, //to be determined

    input                           dma_rd_noc_out_ready,



    //to noc input: control the write response return to dmmu or cmmu

    // output  logic                   dmmu_rd_dma_wr_out_pulse,



    //noc response

    input   logic                   noc_in_dma_rd_response, //dma write response



    //ram rd control

    output  logic                   L2_dmem_dma_rd_en,

    output  logic   [12:0]          L2_dmem_dma_rd_addr,

    input           [255:0]         L2_dmem_dma_rd_data





    // //addr lut

    // output  logic   [3:0]   node_id,

    // input           [21:0]  node_base_addr,



);



localparam IDLE             = 3'd0;

localparam PINGPONG_CHECK   = 3'd1;

localparam DMA_WR_OUT_REQ   = 3'd2;

localparam PING_RD          = 3'd3;

localparam PONG_RD          = 3'd4;

localparam DMA_WR_OUT_RESP  = 3'd5;

// localparam NOC_RD_REQ       = 3'd5;

// localparam NOC_RD           = 3'd6; // determine link list state





logic [2:0] cs, ns;

logic [12:0] d_r_ram_cnt, d_r_ram_cnt_ns;

// logic [21:0] d_r_total_cnt, d_r_total_cnt_ns;

// logic [21:0] cfg_d_r_ram_total_lenth, cfg_d_r_ram_total_lenth_ns;

// logic [21:0] cfg_d_r_ram_base_addr, cfg_d_r_ram_base_addr_ns;

// logic dmmu_rd_noc_out_req_ns; // to be determined

logic [24:0] d_r_n_o_cfg_base_addr_ns;

// logic [21:0] dmmu_rd_noc_out_cfg_lenth_ns;

// logic dmmu_rd_noc_out_mode_ns;



logic   [1:0][12:0] cfg_d_r_ram_base_addr, cfg_d_r_ram_base_addr_ns;

// logic   [17:0]      cfg_d_r_ram_total_lenth, cfg_d_r_ram_total_lenth_ns;

logic   [12:0]      cfg_d_r_ping_lenth, cfg_d_r_ping_lenth_ns;

logic   [12:0]      cfg_d_r_pong_lenth, cfg_d_r_pong_lenth_ns;

logic   [10:0]      cfg_d_r_pingpong_num, cfg_d_r_pingpong_num_ns;

logic               d_r_n_o_cfg_mode_ns;

logic   [11:0]      d_r_n_o_cfg_noc_mc_scale_ns;

logic               d_r_n_o_cfg_req_sel_ns;

logic               cfg_d_r_pingpong_en, cfg_d_r_pingpong_en_ns;

logic   [3:0][12:0] cfg_d_r_loop_lenth, cfg_d_r_loop_lenth_ns;

logic   [3:0][12:0] cfg_d_r_loop_gap, cfg_d_r_loop_gap_ns;



logic addr_mu_initial_en;

logic [12:0] addr_mu_initial_addr, addr_mu_addr, addr_mu_addr_ns;

logic addr_mu_valid;

// logic addr_mu_finish;



logic [10:0] pingpong_cnt, pingpong_cnt_ns;

logic noc_out_gnt_mux;

logic first_transfer_n, first_transfer_n_ns;

assign noc_out_gnt_mux = d_r_n_o_cfg_mode ? (first_transfer_n | dma_rd_noc_out_gnt) : dma_rd_noc_out_gnt;





always_comb begin

    ns = cs;



    d_r_ram_cnt_ns = d_r_ram_cnt;

    // d_r_total_cnt_ns = d_r_total_cnt;

    pingpong_cnt_ns = pingpong_cnt;

    first_transfer_n_ns = first_transfer_n;



    // cfg_d_r_ram_total_lenth_ns = cfg_d_r_ram_total_lenth;

    cfg_d_r_ram_base_addr_ns = cfg_d_r_ram_base_addr;

    cfg_d_r_ping_lenth_ns = cfg_d_r_ping_lenth;

    cfg_d_r_pong_lenth_ns = cfg_d_r_pong_lenth;

    cfg_d_r_pingpong_en_ns = cfg_d_r_pingpong_en;

    cfg_d_r_pingpong_num_ns = cfg_d_r_pingpong_num;

    cfg_d_r_loop_lenth_ns = cfg_d_r_loop_lenth;

    cfg_d_r_loop_gap_ns = cfg_d_r_loop_gap;



    core_cmd_dma_rd_gnt = 'b0;

    // core_cmd_rd_L2_ok = 'b0;



    // core_rd_L2_data = L2_dmem_dma_rd_data;

    // core_rd_L2_data_valid = 1'b0;



    noc_cmd_dma_rd_gnt = 'b0;



    dma_rd_noc_out_req = 'b0;

    d_r_n_o_cfg_base_addr_ns = d_r_n_o_cfg_base_addr;

    // dmmu_rd_noc_out_cfg_lenth_ns = dmmu_rd_noc_out_cfg_lenth;

    d_r_n_o_cfg_mode_ns = d_r_n_o_cfg_mode;

    d_r_n_o_cfg_noc_mc_scale_ns = d_r_n_o_cfg_noc_mc_scale;

    d_r_n_o_cfg_req_sel_ns = d_r_n_o_cfg_req_sel;

    // d_r_n_o_cfg_mode = 1'b0;

    // dmmu_rd_noc_out_node_id = 'b0; // to be determined



    dma_rd_noc_out_data = L2_dmem_dma_rd_data;

    dma_rd_noc_out_valid = 'b0;

    dma_rd_noc_out_last = 'b0;



    pingpong_rd_done = 'b0;

    addr_mu_initial_en = 'b0;

    // addr_mu_initial_addr = cfg_d_r_ram_base_addr[0] + 6'd32;

    addr_mu_initial_addr = cfg_d_r_ram_base_addr[0];

    addr_mu_valid = 'b0;

    // addr_mu_finish = 'b0;



    // dmmu_rd_dma_wr_out_pulse = 'b0;



    L2_dmem_dma_rd_en = 'b0;

    L2_dmem_dma_rd_addr = addr_mu_addr;



    d_r_transaction_done = 1'b0;



    case(cs)

    IDLE: begin

        if(core_cmd_dma_rd_req) begin

            core_cmd_dma_rd_gnt = 1'b1;



            cfg_d_r_ram_base_addr_ns = c_cfg_d_r_ram_base_addr;

            // cfg_d_r_ram_total_lenth_ns = c_cfg_d_r_ram_total_lenth; //ram read control signals (source)

            d_r_n_o_cfg_base_addr_ns = c_cfg_d_r_noc_base_addr; //noc write out control signals (destination)

            // dmmu_rd_noc_out_cfg_lenth_ns = core_cfg_dmmu_lenth;  //lenth could be one?

            // dmmu_rd_noc_out_mode_ns = ;

            cfg_d_r_ping_lenth_ns = c_cfg_d_r_ping_lenth;

            cfg_d_r_pong_lenth_ns = c_cfg_d_r_pong_lenth;

            cfg_d_r_pingpong_en_ns = c_cfg_d_r_pingpong_en;

            cfg_d_r_pingpong_num_ns = c_cfg_d_r_pingpong_num;

            cfg_d_r_loop_lenth_ns = c_cfg_d_r_loop_lenth;

            cfg_d_r_loop_gap_ns = c_cfg_d_r_loop_gap;



            d_r_n_o_cfg_mode_ns = 1'b0;

            // core_cmd_rd_L2_ok = 1'b1; //? to be determined

            ns = DMA_WR_OUT_REQ;



            // L2_dmem_dma_rd_en = 1'b1;

            // L2_dmem_dma_rd_addr = c_cfg_d_r_ram_base_addr;



        end

        else if(noc_cmd_dma_rd_req) begin

            noc_cmd_dma_rd_gnt = 1'b1;



            cfg_d_r_ram_base_addr_ns = n_cfg_d_r_ram_base_addr;

            // d_r_ram_cnt_ns = 'b0;

            // cfg_d_r_ram_total_lenth_ns = n_cfg_d_r_ram_total_lenth;

            // d_r_n_o_cfg_base_addr_ns = {n_cfg_d_r_source_id, 14'b0};

            d_r_n_o_cfg_base_addr_ns = 'b0;

            cfg_d_r_ping_lenth_ns = n_cfg_d_r_ping_lenth;

            cfg_d_r_pong_lenth_ns = n_cfg_d_r_pong_lenth;

            cfg_d_r_pingpong_en_ns = n_cfg_d_r_pingpong_en;

            cfg_d_r_pingpong_num_ns = n_cfg_d_r_pingpong_num;

            cfg_d_r_loop_lenth_ns = n_cfg_d_r_loop_lenth;

            cfg_d_r_loop_gap_ns = n_cfg_d_r_loop_gap;



            d_r_n_o_cfg_mode_ns = 1'b1;

            d_r_n_o_cfg_noc_mc_scale_ns = n_cfg_d_r_noc_mc_scale;

            d_r_n_o_cfg_req_sel_ns = n_cfg_d_r_req_sel;



            ns = DMA_WR_OUT_REQ;

        end

    end

    PINGPONG_CHECK: begin

        if(pingpong_cnt[10:1] == cfg_d_r_pingpong_num)begin //pingpong pairs number

            ns = IDLE;

            pingpong_cnt_ns = 'b0;

            first_transfer_n_ns = 1'b0;

            d_r_transaction_done = 1'b1;

        end

        else if((pingpong_cnt[0] & pingpong_state[1]) | (~pingpong_cnt[0] & pingpong_state[0])) begin

            ns = DMA_WR_OUT_REQ;

        end

        // else if(~pingpong_cnt[0] & pingpong_state[0]) begin

        //     ns = DMA_RD_OUT_REQ;

        // end



        // if(d_r_n_o_cfg_mode) begin



        // end

        // else begin



        // end

        // L2_dmem_dma_rd_en = 1'b1;

        // L2_dmem_dma_rd_addr = c_cfg_d_r_ram_base_addr; //to be modified to rd addr ctrl output

    end

    DMA_WR_OUT_REQ: begin

        dma_rd_noc_out_req = 1'b1;



        if(pingpong_cnt[0]) begin

            d_r_n_o_cfg_lenth = c_cfg_d_r_pong_lenth;

        end

        else begin

            d_r_n_o_cfg_lenth = c_cfg_d_r_ping_lenth;

        end

        

        if(noc_out_gnt_mux) begin

            if(pingpong_cnt[0]) begin

                ns = PONG_RD;

                L2_dmem_dma_rd_en = 1'b1;

                L2_dmem_dma_rd_addr = cfg_d_r_ram_base_addr[1];

                addr_mu_initial_en = 1'b1;

                // addr_mu_initial_addr = cfg_d_r_ram_base_addr[1] + 6'd32;

                addr_mu_initial_addr = cfg_d_r_ram_base_addr[1];

            end

            else begin

                ns = PING_RD;

                L2_dmem_dma_rd_en = 1'b1;

                L2_dmem_dma_rd_addr = cfg_d_r_ram_base_addr[0];

                addr_mu_initial_en = 1'b1;

            end

        end

    end

    PING_RD: begin

        // L2_dmem_dma_rd_addr = addr_mu_addr; //to be modified to rd addr ctrl output



        dma_rd_noc_out_valid = 1'b1;

        if(dma_rd_noc_out_ready) begin

            if(d_r_ram_cnt == cfg_d_r_ping_lenth) begin

                first_transfer_n_ns = 1'b1;

                // addr_mu_finish = 1'b1;

                d_r_ram_cnt_ns = 'b0;

                pingpong_cnt_ns = pingpong_cnt + 1'b1;

                pingpong_rd_done = cfg_d_r_pingpong_en;

                // d_r_n_o_cfg_base_addr_ns = d_r_n_o_cfg_base_addr + (cfg_d_r_ping_lenth << 5);

                d_r_n_o_cfg_base_addr_ns = d_r_n_o_cfg_base_addr + cfg_d_r_ping_lenth;

                if(d_r_n_o_cfg_mode) begin

                    ns = PINGPONG_CHECK;

                    dma_rd_noc_out_last = ~cfg_d_r_pingpong_en;

                end

                else begin

                    ns = DMA_WR_OUT_RESP;

                    dma_rd_noc_out_last = 1'b1;

                end

            end

            else begin

                L2_dmem_dma_rd_en = 1'b1;

                // L2_dmem_dma_rd_addr = addr_mu_addr + 6'd32;

                L2_dmem_dma_rd_addr = addr_mu_addr_ns;

                d_r_ram_cnt_ns = d_r_ram_cnt + 1'b1;

                addr_mu_valid = 1'b1;

            end

        end

    end

    PONG_RD: begin

        dma_rd_noc_out_valid = 1'b1;

        if(dma_rd_noc_out_ready) begin

            if(d_r_ram_cnt == cfg_d_r_pong_lenth) begin

                // addr_mu_finish = 1'b1;

                d_r_ram_cnt_ns = 'b0;

                pingpong_cnt_ns = pingpong_cnt + 1'b1;

                pingpong_rd_done = cfg_d_r_pingpong_en;

                // d_r_n_o_cfg_base_addr_ns = d_r_n_o_cfg_base_addr + (cfg_d_r_pong_lenth << 5);

                d_r_n_o_cfg_base_addr_ns = d_r_n_o_cfg_base_addr + cfg_d_r_pong_lenth;

                if(d_r_n_o_cfg_mode) begin

                    ns = PINGPONG_CHECK;

                    dma_rd_noc_out_last = (pingpong_cnt_ns[10:1] == cfg_d_r_pingpong_num);

                end

                else begin

                    ns = DMA_WR_OUT_RESP;

                    dma_rd_noc_out_last = 1'b1;

                end

            end

            else begin

                L2_dmem_dma_rd_en = 1'b1;

                // L2_dmem_dma_rd_addr = addr_mu_addr + 6'd32;

                L2_dmem_dma_rd_addr = addr_mu_addr_ns;

                d_r_ram_cnt_ns = d_r_ram_cnt + 1'b1;

                addr_mu_valid = 1'b1;

                //addr_mu_ns_valid = 1'b1;

            end

        end

    end

    DMA_WR_OUT_RESP: begin

        if(noc_in_dma_rd_response) begin

            ns = PINGPONG_CHECK;

        end

    end

    endcase

end



always_ff @(posedge clk or negedge rst_n) begin

    if(!rst_n) begin

        cs <= IDLE;



        d_r_ram_cnt <= 'b0;

        // d_r_total_cnt <= 'b0;

        pingpong_cnt <= 'b0;

        first_transfer_n <= 'b0;



        // cfg_d_r_ram_total_lenth <= 'b0;

        cfg_d_r_ram_base_addr <= 'b0;



        cfg_d_r_ping_lenth <= 'b0;

        cfg_d_r_pong_lenth <= 'b0;

        cfg_d_r_pingpong_num <= 'b0;

        cfg_d_r_loop_lenth <= 'b0;

        cfg_d_r_loop_gap <= 'b0;



        d_r_n_o_cfg_base_addr <= 'b0;

        // dmmu_rd_noc_out_cfg_lenth <= 'b0;

        d_r_n_o_cfg_mode <= 'b0;

        d_r_n_o_cfg_noc_mc_scale <= 'b0;

        d_r_n_o_cfg_req_sel <= 'b0;

    end

    else begin

        cs <= ns;

        d_r_ram_cnt <= d_r_ram_cnt_ns;

        // d_r_total_cnt <= d_r_total_cnt_ns;

        pingpong_cnt <= pingpong_cnt_ns;

        first_transfer_n <= first_transfer_n_ns;



        // cfg_d_r_ram_total_lenth <= cfg_d_r_ram_total_lenth_ns;

        cfg_d_r_ram_base_addr <= cfg_d_r_ram_base_addr_ns;



        cfg_d_r_ping_lenth <= cfg_d_r_ping_lenth_ns;

        cfg_d_r_pong_lenth <= cfg_d_r_pong_lenth_ns;

        cfg_d_r_pingpong_num <= cfg_d_r_pingpong_num_ns;

        cfg_d_r_loop_lenth <= cfg_d_r_loop_lenth_ns;

        cfg_d_r_loop_gap <= cfg_d_r_loop_gap_ns;



        d_r_n_o_cfg_base_addr <= d_r_n_o_cfg_base_addr_ns;

        // dmmu_rd_noc_out_cfg_lenth <= dmmu_rd_noc_out_cfg_lenth_ns;

        d_r_n_o_cfg_mode <= d_r_n_o_cfg_mode_ns;

        d_r_n_o_cfg_noc_mc_scale <= d_r_n_o_cfg_noc_mc_scale_ns;

        d_r_n_o_cfg_req_sel <= d_r_n_o_cfg_req_sel_ns;

    end

end



addr_mu U_addr_mu(

    .clk                (clk),

    .rst_n              (rst_n),



    .cfg_base_addr      (addr_mu_initial_addr),

    .cfg_gap            (cfg_d_r_loop_gap),

    .cfg_lenth          (cfg_d_r_loop_lenth),



    .addr_mu_initial_en (addr_mu_initial_en),

    .addr_mu_valid      (addr_mu_valid),



    .addr_mu_addr       (addr_mu_addr)

);



addr_mu_ns U_addr_mu_ns(

    .clk                (clk),

    .rst_n              (rst_n),



    .cfg_base_addr      (addr_mu_initial_addr),

    .cfg_gap            (cfg_d_r_loop_gap),

    .cfg_lenth          (cfg_d_r_loop_lenth),



    .addr_mu_initial_en (addr_mu_initial_en),

    .addr_mu_valid      (addr_mu_valid),



    .addr_mu_addr       (addr_mu_addr_ns)

);



endmodule

