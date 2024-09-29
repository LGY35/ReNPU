// core wr channel


module dnoc_itf_in_c_channel(

    input                           clk,

    input                           rst_n,



    //noc signals

    input           [256-1:0]       out_flit,

    input                           out_last,

    input                           out_valid,

    output  logic                   out_ready,



    //rd req sync signals

    output  logic                   sync_req,

    output  logic   [3:0]           sync_node_id,



    //noc to dma rd cmd and cfg

    output  logic                   noc_cmd_dma_rd_req,

    input                           noc_cmd_dma_rd_gnt,



    output  logic   [1:0][12:0]     n_cfg_d_r_ram_base_addr,

    // output           [12:0]          n_cfg_d_r_ram_total_lenth,

    output  logic   [12:0]          n_cfg_d_r_ping_lenth,

    output  logic   [12:0]          n_cfg_d_r_pong_lenth,

    output  logic   [11:0]          n_cfg_d_r_noc_mc_scale,

    output  logic                   n_cfg_d_r_req_sel,//rd req from core or dma

    output  logic                   n_cfg_d_r_pingpong_en,

    output  logic   [10:0]          n_cfg_d_r_pingpong_num,

    output  logic   [3:0][12:0]     n_cfg_d_r_loop_lenth,

    output  logic   [3:0][12:0]     n_cfg_d_r_loop_gap,



    output  logic                   noc_in_dma_rd_response,



    //core wr response

    output  logic                   noc_in_core_wr_response



);



localparam IDLE     = 2'd0;

localparam RD_REQ   = 2'd1;

localparam WR_RESP  = 2'd2;

localparam SYNC     = 2'd3;



logic [1:0] cs, ns;



always_comb begin

    ns = cs;



    out_ready = 'b0;



    sync_req = 'b0;

    sync_node_id = out_flit[10:7];



    noc_cmd_dma_rd_req = 'b0;



    n_cfg_d_r_ram_base_addr[0]  = out_flit[31:19];

    n_cfg_d_r_ram_base_addr[1]  = out_flit[56:44];

    n_cfg_d_r_ping_lenth        = out_flit[81:69];

    n_cfg_d_r_pong_lenth        = out_flit[94:82];

    n_cfg_d_r_pingpong_num      = out_flit[68:58];

    n_cfg_d_r_noc_mc_scale      = out_flit[18:7];

    n_cfg_d_r_pingpong_en       = out_flit[57];

    n_cfg_d_r_req_sel           = out_flit[5];

    n_cfg_d_r_loop_lenth        = out_flit[198:147];

    n_cfg_d_r_loop_gap          = out_flit[146:95];

    

    noc_in_dma_rd_response = 'b0;

    noc_in_core_wr_response = 'b0;



    case(cs)

    IDLE: begin

        if(out_valid) begin

            if(out_flit[4]) begin

                ns = WR_RESP;

            end

            else begin

                if(out_flit[6]) begin

                    ns = SYNC;

                end

                else begin

                    ns = RD_REQ;

                end

            end

        end

    end

    RD_REQ: begin

        noc_cmd_dma_rd_req = 1'b1;

        out_ready = noc_cmd_dma_rd_gnt;

        if(noc_cmd_dma_rd_gnt) begin

            ns = IDLE;

            // if(out_flit[4]) begin

            //     ns = WR_RESP;

            // end

            // else begin

            //     ns = RD_REQ;

            // end

        end

    end

    WR_RESP: begin

        ns = IDLE;

        out_ready = 1'b1;

        if(out_flit[5]) begin

            noc_in_dma_rd_response = 1'b1;

        end

        else begin

            noc_in_core_wr_response = 1'b1;

        end

    end

    SYNC: begin

        out_ready = 1'b1;

        sync_req = 1'b1;

    end

    endcase

end



always_ff @(posedge clk or negedge rst_n) begin

    if(!rst_n) begin

        cs <= IDLE;

    end

    else begin

        cs <= ns;

    end

end





endmodule