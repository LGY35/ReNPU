module dnoc_itf_out_d_channel #(

    parameter NODE_ID   = 4'd0,

    parameter DMA_ID    = 4'b1101

)

(

    input                           clk,

    input                           rst_n,



    //noc 

    output  logic   [256-1:0]       in_flit,

    output  logic                   in_last,

    output  logic                   in_valid,

    input                           in_ready,



    //core wr channel 

    input                           core_wr_noc_out_req,

    output  logic                   core_wr_noc_out_gnt,



    input           [255:0]         core_wr_noc_out_data,

    input                           core_wr_noc_out_valid,

    input                           core_wr_noc_out_last, //to be determined

    output  logic                   core_wr_noc_out_ready,



    // input                           c_cfg_c_w_mc,

    input                           c_cfg_c_w_dma_transfer,

    // input                           c_cfg_c_w_dma_access_mode,

    input           [3:0]           c_cfg_c_w_noc_target_id,



    // input           [11:0]          c_cfg_c_r_noc_mc_scale,



    // input           [11:0]          c_cfg_c_r_sync_target,



    input           [12:0]          c_cfg_c_w_base_addr, //鐢变簬涓嶆敮鎸佽法鑺傜偣鍐欎箳涔擄紝鎵€浠ュ彧鏈塸ing鍦板潃

    // input           [12:0]          c_cfg_c_r_total_lenth,

    input           [12:0]          c_cfg_c_w_ping_lenth,

    // input           [12:0]          c_cfg_c_w_pong_lenth,

    // input                           c_cfg_c_w_pingpong_en,

    // input           [10:0]          c_cfg_c_w_pingpong_num,

    input           [3:0][12:0]     c_cfg_c_w_loop_lenth,

    input           [3:0][12:0]     c_cfg_c_w_loop_gap,



//core妯″紡涓嬬殑dma rd浠呰繘琛屽崟鎾殑鍐欏嚭锛屾墍浠ヤ笉闇€瑕乵c_scale鍙傛暟銆乻ync_target鍙傛暟

//涓诲姩鍚戝鍐欐暟鎹病鏈塸ingpong妯″紡锛屾墍浠ヤ粎闇€瑕佸熀鍦板潃鍜岄暱搴︿袱涓弬鏁?
//noc rd 妯″紡涓嬮渶瑕佹妸璇昏姹傚彂杩囨潵鐨刴c_scale閫佸嚭



    //dma rd channel wr-out req and noc rd return data 

    input                           dma_rd_noc_out_req,

    output  logic                   dma_rd_noc_out_gnt,



    input           [255:0]         dma_rd_noc_out_data,

    input                           dma_rd_noc_out_valid,

    input                           dma_rd_noc_out_last, //to be determined

    output  logic                   dma_rd_noc_out_ready,



    input           [24:0]          d_r_n_o_cfg_base_addr, //dma mode do not include node id info; others do

    input           [12:0]          d_r_n_o_cfg_lenth, //dma 鍚戝杈撳嚭鏁版嵁鏃剁殑闀垮害

    input                           d_r_n_o_cfg_mode, //dma rd 閫氶亾鏄痗ore鎺у埗鐨勫啓杈撳嚭杩樻槸noc鎺у埗鐨勮杩斿洖

    input                           d_r_n_o_cfg_req_sel, //璇昏繑鍥炵殑鏁版嵁缁?core rd 杩樻槸dma wr



    input           [11:0]          d_r_n_o_cfg_noc_mc_scale, //璇昏繑鍥炵殑鏁版嵁浠ュ箍鎾殑褰㈠紡缁欏嚭





    // input                           c_cfg_d_r_mc,

    // input                           c_cfg_d_r_dma_access_mode,

    input                           c_cfg_d_r_dma_transfer

    // input           [11:0]          c_cfg_d_r_noc_mc_scale,



    // input           [11:0]          c_cfg_d_r_sync_target,

    //鍚岀悊锛宑ore閰嶇疆鐨刣ma妯″紡涓嶅叿澶囧箍鎾啓鍏ョ殑妯″紡

    //鍙湁鍦╮d return data鎯呭喌涓嬪箍鎾彂鍑烘暟鎹?


);



localparam IDLE     = 2'd0;

localparam CORE     = 2'd1;

localparam DMA      = 2'd2;

// localparam RETURN   = 2'd3;

// localparam TRANSFER = 2'd1;





logic [1:0] cs, ns;



logic [255:0] core_head_flit, dma_head_flit, return_head_flit;

logic [3:0] actual_c_w_noc_target_id, actual_d_r_noc_target_id;



always_comb begin

    ns = cs;



    in_flit = core_head_flit;

    in_last = 'b0;

    in_valid = 'b0;



    core_wr_noc_out_gnt = 'b0;



    core_wr_noc_out_ready = 'b0;



    dma_rd_noc_out_gnt = 'b0;



    dma_rd_noc_out_ready = 'b0;



    case(cs)

    IDLE: begin

        if(core_wr_noc_out_req) begin

            in_valid = 1'b1;

            

            if(in_ready) begin

                ns = CORE;

                core_wr_noc_out_gnt = 1'b1;

            end

        end

        else if(dma_rd_noc_out_req) begin

            in_valid = 1'b1;

            in_flit = d_r_n_o_cfg_mode ? return_head_flit : dma_head_flit;

            // if(d_r_n_o_cfg_mode) begin

            //     in_flit = return_head_flit;

            // end

            // else begin

            //     in_flit = dma_head_flit;

            // end

            if(in_ready) begin

                ns = DMA;

                dma_rd_noc_out_gnt = 1'b1;

            end

        end

    end

    CORE: begin

        in_flit = core_wr_noc_out_data;

        in_last = core_wr_noc_out_last;

        in_valid = core_wr_noc_out_valid;



        core_wr_noc_out_ready = in_ready;

        if(in_last & in_valid & in_ready) begin

            ns = IDLE;

        end

    end

    DMA: begin

        in_flit = dma_rd_noc_out_data;

        in_last = dma_rd_noc_out_last;

        in_valid = dma_rd_noc_out_valid;



        dma_rd_noc_out_ready = in_ready;

        if(in_last & in_valid & in_ready) begin

            ns = IDLE;

        end

    end

    // RETURN: begin



    // end

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





assign actual_c_w_noc_target_id = c_cfg_c_w_dma_transfer ? DMA_ID : c_cfg_c_w_noc_target_id;

assign actual_d_r_noc_target_id = c_cfg_d_r_dma_transfer ? DMA_ID : d_r_n_o_cfg_base_addr[16:13]; //鍖呭惈鍚戝叾瀹冮潪dma鑺傜偣鍙戦€佽璇锋眰浠ュ強鍐欑浉搴?




always_comb begin

    core_head_flit[255]     = 1'b0; //鏍囪褰撳墠浼犳挱鐘舵€侊紱鍗曟挱澶氭挱

    core_head_flit[254]     = 1'b0; 



    core_head_flit[253:160] = 'b0;



    core_head_flit[159:108] = c_cfg_c_w_loop_lenth;

    core_head_flit[107:56]  = c_cfg_c_w_loop_gap;



    core_head_flit[55:43]   = c_cfg_c_w_ping_lenth;

    core_head_flit[42:18]   = {12'b0, c_cfg_c_w_base_addr};

    core_head_flit[17:14]   = NODE_ID;

    core_head_flit[13]      = 1'b0; //wr from core or dma

    core_head_flit[12]      = 1'b0; //wr data or rd return data

    core_head_flit[11:0]    = {8'b0, actual_c_w_noc_target_id};

end



always_comb begin

    dma_head_flit[255]      = 1'b0;

    dma_head_flit[254]      = 1'b0;



    dma_head_flit[253:160]   = 'b0;



    dma_head_flit[159:147]  = d_r_n_o_cfg_lenth;

    dma_head_flit[146:108]  = 'b0;

    dma_head_flit[107:95]   = 13'd1;

    dma_head_flit[94:56]    = 'b0;



    dma_head_flit[55:43]    = d_r_n_o_cfg_lenth;

    dma_head_flit[42:18]    = d_r_n_o_cfg_base_addr;

    dma_head_flit[17:14]    = NODE_ID;

    dma_head_flit[13]       = 1'b1; //wr from core or dma

    dma_head_flit[12]       = 1'b0; //wr data or rd return data

    dma_head_flit[11:0]     = {8'b0, actual_d_r_noc_target_id};

end



always_comb begin

    return_head_flit[255]   = 1'b0;

    // return_head_flit[54:42] = loop;



    // return_head_flit[54:42] = c_cfg_c_w_ping_lenth;

    return_head_flit[254:18]= 'b0;

    return_head_flit[17:14] = NODE_ID;

    return_head_flit[13]    = d_r_n_o_cfg_req_sel; //return data to core or dma

    return_head_flit[12]    = 1'b1; //wr data or rd return data

    return_head_flit[11:0]  = d_r_n_o_cfg_noc_mc_scale;

end



endmodule