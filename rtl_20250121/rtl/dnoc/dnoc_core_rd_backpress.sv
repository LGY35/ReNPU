module dnoc_core_rd_backpress(
    input                           clk                         ,
    input                           rst_n                       ,

    input           [3:0]           c_cfg_c_r_pad_up_len        ,
    input           [3:0]           c_cfg_c_r_pad_right_len     ,
    input           [10:0]          c_cfg_c_r_pad_left_len      ,
    input           [4:0]           c_cfg_c_r_pad_bottom_len    ,
    input           [10:0]          c_cfg_c_r_pad_row_num       ,
    input           [10:0]          c_cfg_c_r_pad_col_num       ,
    input           [1:0]           c_cfg_c_r_pad_mode          ,

    input                           c_cfg_c_r_local_access      ,
    input                           c_cfg_c_r_dma_transfer_n    ,
    input           [3:0][12:0]     c_cfg_c_r_loop_lenth        ,
    input           [3:0][12:0]     c_cfg_c_r_loop_gap          ,
    input           [12:0]          no_pad_target_lenth         ,
    // input           [12:0]          c_cfg_c_r_pong_lenth        ,

    input           [12:0]          rd_initial_addr,
    input                           core_rd_start,
    output  logic                   core_rd_backpress_finish,

    output  logic                   bp_mem_rd_req,
    input                           bp_mem_rd_gnt,
    output  logic   [12:0]          bp_mem_rd_addr, //[10:0]
    input           [255:0]         bp_mem_rd_data,
    input                           bp_mem_rd_valid,

    input           [255:0]         noc_in_data,
    input                           noc_in_valid,
    output  logic                   noc_in_ready,
    input                           noc_in_last,
    // input                           noc_pingpong_sel, //0:ping; 1:pong
    // input                           ram_pingpong_sel,


    output  logic   [255:0]         core_in_data,
    output  logic                   core_in_last,
    output  logic                   core_in_valid
 
);

//----------------------------paddding zeros (NoC direct read in)----------------------------------

localparam  NOC_IDLE    = 3'd0;
localparam  NOC_UP      = 3'd1;
localparam  NOC_LEFT    = 3'd2;
localparam  NOC_FEATURE = 3'd3;
localparam  NOC_RIGHT   = 3'd4;
localparam  NOC_BOTTOM  = 3'd5;


//--------------------------

localparam  MEM_IDLE    = 3'd0;
localparam  MEM_UP      = 3'd1;
localparam  MEM_LEFT    = 3'd2;
localparam  MEM_FEATURE = 3'd3;
localparam  MEM_RIGHT   = 3'd4;
localparam  MEM_BOTTOM  = 3'd5;

localparam  DATA_IDLE    = 3'd0;
localparam  DATA_UP      = 3'd1;
localparam  DATA_LEFT    = 3'd2;
localparam  DATA_FEATURE = 3'd3;
localparam  DATA_RIGHT   = 3'd4;
localparam  DATA_BOTTOM  = 3'd5;


//--------------------------------

localparam  IDLE        = 2'd0;
localparam  NOC_IN      = 2'd1;
localparam  MEM_IN      = 2'd2;
localparam  DIRECT_IN   = 2'd3; //from other node

logic           noc_backpress_finish;
logic           mem_backpress_finish;

logic [2:0]     noc_fsm_cs, noc_fsm_ns;
logic [10:0]    noc_row_cnt, noc_row_cnt_ns;
logic [10:0]    noc_col_cnt, noc_col_cnt_ns;
logic [10:0]    row_num, row_num_ns;
logic [10:0]    col_num, col_num_ns;
logic [3:0]     up_len, up_len_ns;
logic [3:0]     right_len, right_len_ns;
logic [10:0]    left_len, left_len_ns;
logic [3:0]     bottom_len, bottom_len_ns;
logic [10:0]    total_col_num, total_row_num;
logic [1:0]     pad_mode, pad_mode_ns;

assign total_row_num = up_len + row_num + bottom_len;
assign total_col_num = left_len + col_num + right_len;

logic           noc_in_pad_valid;
logic [255:0]   noc_in_pad_data;
// logic           core_rd_pad_ready;
logic           noc_in_ready_temp;
logic           noc_in_pad_last;

logic           addr_mu_initial_en;
logic [12:0]    addr_mu_initial_addr;
logic           addr_mu_valid;
logic [12:0]    addr_mu_addr;


always_comb begin
    noc_fsm_ns = noc_fsm_cs;
    noc_row_cnt_ns = noc_row_cnt;
    noc_col_cnt_ns = noc_col_cnt;

    noc_in_ready_temp = 1'b0;
    noc_in_pad_last = 1'b0;
    noc_in_pad_data = noc_in_data;
    noc_in_pad_valid = 1'b0;

    noc_backpress_finish = 1'b0;

    case(noc_fsm_cs)
    NOC_IDLE: begin
        if(core_rd_start & (~c_cfg_c_r_dma_transfer_n) & c_cfg_c_r_pad_mode[0])begin
            if(c_cfg_c_r_pad_up_len == 4'd0) begin
                noc_fsm_ns = NOC_LEFT;
            end
            else begin
                noc_fsm_ns = NOC_UP;
            end
        end
    end
    NOC_UP: begin
        noc_in_pad_data = 'b0;
        noc_in_pad_valid = 1'b1;
        if((noc_row_cnt == up_len - 11'd1) & (noc_col_cnt == total_col_num - 11'd1)) begin
            noc_col_cnt_ns = 11'd0;
            noc_row_cnt_ns = 11'd0;
            if(left_len == 4'd0) begin
                noc_fsm_ns = NOC_FEATURE;
            end
            else begin
                noc_fsm_ns = NOC_LEFT;
            end
        end
        else if(noc_col_cnt == total_col_num - 11'd1) begin
            noc_col_cnt_ns = 11'd0;
            noc_row_cnt_ns = noc_row_cnt + 11'd1;
        end
        else begin
            noc_col_cnt_ns = noc_col_cnt + 11'd1;
        end
    end
    NOC_LEFT: begin
        noc_in_pad_data = 'b0;
        noc_in_pad_valid = 1'b1;

        if(noc_col_cnt == left_len - 11'd1) begin
            noc_fsm_ns = NOC_FEATURE;
            noc_col_cnt_ns = 11'd0;
        end
        else begin
            noc_col_cnt_ns = noc_col_cnt + 11'd1;
        end
    end
    NOC_FEATURE: begin
        noc_in_pad_data = noc_in_data;
        noc_in_pad_valid = noc_in_valid;
        noc_in_ready_temp = 1'b1;

        if((noc_col_cnt == col_num - 11'd1) & (noc_in_valid)) begin
            noc_col_cnt_ns = 11'd0;
            if(right_len == 4'd0) begin
                if((noc_row_cnt == row_num - 11'd1)) begin
                    noc_row_cnt_ns = 11'd0;
                    if(bottom_len == 5'd0) begin
                        noc_fsm_ns = NOC_IDLE;
                        noc_backpress_finish = 1'b1;
                        noc_in_pad_last = 1'b1;
                    end
                    else begin
                        noc_fsm_ns = NOC_BOTTOM;
                    end
                end
                else begin
                    noc_row_cnt_ns = noc_row_cnt + 11'd1;
                    if(left_len == 4'd0) begin
                        noc_fsm_ns = NOC_FEATURE;
                    end
                    else begin
                        noc_fsm_ns = NOC_LEFT;
                    end
                end
            end
            else begin
                noc_fsm_ns = NOC_RIGHT;
            end
        end
        else if(noc_in_valid) begin
            noc_col_cnt_ns = noc_col_cnt + 11'd1;
        end
    end
    NOC_RIGHT: begin
        noc_in_pad_data = 'b0;
        noc_in_pad_valid = 1'b1;

        if((noc_col_cnt == right_len - 11'd1) & (noc_row_cnt == row_num - 11'd1)) begin
            noc_col_cnt_ns = 11'd0;
            noc_row_cnt_ns = 11'd0;
            if(bottom_len == 5'd0) begin
                noc_fsm_ns = NOC_IDLE;
                noc_backpress_finish = 1'b1;
                noc_in_pad_last = 1'b1;
            end
            else begin
                noc_fsm_ns = NOC_BOTTOM;
            end
        end
        else if(noc_col_cnt == right_len - 11'd1) begin
            noc_col_cnt_ns = 11'd0;
            noc_row_cnt_ns = noc_row_cnt + 11'd1;
            if(left_len == 4'd0) begin
                noc_fsm_ns = NOC_FEATURE;
            end
            else begin
                noc_fsm_ns = NOC_LEFT;
            end
        end
        else begin
            noc_col_cnt_ns = noc_col_cnt + 11'd1;
        end
    end
    NOC_BOTTOM: begin
        noc_in_pad_data = 'b0;
        noc_in_pad_valid = 1'b1;
        if((noc_row_cnt == bottom_len - 5'd1) & (noc_col_cnt == total_col_num - 11'd1)) begin
            noc_col_cnt_ns = 11'd0;
            noc_row_cnt_ns = 11'd0;
            noc_fsm_ns = NOC_IDLE;
            noc_backpress_finish = 1'b1;
            noc_in_pad_last = 1'b1;
        end
        else if(noc_col_cnt == total_col_num - 11'd1) begin
            noc_col_cnt_ns = 11'd0;
            noc_row_cnt_ns = noc_row_cnt + 11'd1;
        end
        else begin
            noc_col_cnt_ns = noc_col_cnt + 11'd1;
        end
    end
    endcase
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        noc_fsm_cs <= NOC_IDLE;
        noc_row_cnt <= 'b0;
        noc_col_cnt <= 'b0;
    end
    else begin
        noc_fsm_cs <= noc_fsm_ns;
        noc_row_cnt <= noc_row_cnt_ns;
        noc_col_cnt <= noc_col_cnt_ns;
    end
end


//------------------------------mem padding zeros or replicate----------------------------

logic [2:0]     mem_fsm_cs, mem_fsm_ns;
logic [2:0]     data_fsm_cs, data_fsm_ns;

logic           mem_rd_req_en, mem_rd_req_en_ns;
logic [10:0]    mem_rd_req_row_cnt, mem_rd_req_row_cnt_ns;
logic [10:0]    mem_rd_req_col_cnt, mem_rd_req_col_cnt_ns;
logic [10:0]    mem_rd_valid_row_cnt, mem_rd_valid_row_cnt_ns;
logic [10:0]    mem_rd_valid_col_cnt, mem_rd_valid_col_cnt_ns;

logic           mem_in_pad_valid;
logic           mem_in_pad_last;
logic [255:0]   mem_in_pad_data;

logic           mem_pad_data_in_finish;
logic           mem_addr_repeat_record_en;
logic           mem_addr_repeat_init;

logic [255:0]   mem_pad_data_reg, mem_pad_data_reg_ns;
logic           mem_data_sel, mem_data_sel_ns;

logic [12:0]    no_pad_mem_rd_req_cnt, no_pad_mem_rd_req_cnt_ns;
logic [12:0]    no_pad_mem_rd_valid_cnt, no_pad_mem_rd_valid_cnt_ns;

always_comb begin
    mem_fsm_ns = mem_fsm_cs;
    mem_rd_req_en_ns = mem_rd_req_en;
    mem_rd_req_row_cnt_ns = mem_rd_req_row_cnt;
    mem_rd_req_col_cnt_ns = mem_rd_req_col_cnt;
    no_pad_mem_rd_req_cnt_ns = no_pad_mem_rd_req_cnt;

    mem_addr_repeat_record_en = 1'b0;
    mem_addr_repeat_init = 1'b0;

    bp_mem_rd_req = 1'b0;
    bp_mem_rd_addr = addr_mu_addr;

    addr_mu_initial_en = 1'b0;
    addr_mu_initial_addr = rd_initial_addr;
    addr_mu_valid = 1'b0;

    case(mem_fsm_cs)
    MEM_IDLE: begin
        if(core_rd_start & (c_cfg_c_r_dma_transfer_n) & c_cfg_c_r_local_access)begin
            if(c_cfg_c_r_pad_mode[0]) begin
                // bp_mem_rd_req = c_cfg_c_r_pad_mode[1];
                // init_sel = bp_mem_rd_gnt;
                // addr_mu_initial_addr = rd_initial_addr;
                addr_mu_initial_en = c_cfg_c_r_pad_mode[1];
                // mem_rd_req_en_ns = c_cfg_c_r_pad_mode[1];

                // if(bp_mem_rd_req & bp_mem_rd_gnt) begin /////////////////////finish check
                //     mem_rd_req_cnt_ns = 11'd1;
                // end

                if(c_cfg_c_r_pad_up_len == 4'd0) begin
                    if(c_cfg_c_r_pad_left_len == 11'd0) begin
                        mem_fsm_ns = MEM_FEATURE;
                    end
                    else begin
                        mem_fsm_ns = MEM_LEFT;
                    end
                end
                else begin
                    mem_fsm_ns = MEM_UP;
                end
            end
            else begin
                mem_fsm_ns = MEM_FEATURE;

                // bp_mem_rd_req = 1'b1;
                // init_sel = bp_mem_rd_gnt;
                // addr_mu_initial_addr = rd_initial_addr;
                addr_mu_initial_en = 1'b1;
            end
        end
    end
    MEM_UP: begin
        if(c_cfg_c_r_pad_mode[1]) begin
            // bp_mem_rd_addr = addr_mu_addr;
            bp_mem_rd_req = 1'b1;
            addr_mu_valid = bp_mem_rd_gnt;

            if(bp_mem_rd_req & bp_mem_rd_gnt)begin
                if((mem_rd_req_row_cnt == up_len - 4'd1) & (mem_rd_req_col_cnt == total_col_num - 11'd1)) begin
                    mem_rd_req_col_cnt_ns = 11'd0;
                    mem_rd_req_row_cnt_ns = 11'd0;
                    if(left_len == 11'd0) begin
                        mem_fsm_ns = MEM_FEATURE;
                    end
                    else begin
                        mem_fsm_ns = MEM_LEFT;
                    end
                end
                else if(mem_rd_req_col_cnt == total_col_num - 11'd1) begin
                    mem_rd_req_col_cnt_ns = 11'd0;
                    mem_rd_req_row_cnt_ns = mem_rd_req_row_cnt + 11'd1;
                    addr_mu_initial_en = 1'b1;
                    // addr_mu_initial_addr = rd_initial_addr;
                end
                else begin
                    mem_rd_req_col_cnt_ns = mem_rd_req_col_cnt + 11'd1;
                end
            end
        end
        else begin
            if(mem_pad_data_in_finish) begin
                if(left_len == 11'd0) begin
                    mem_fsm_ns = MEM_FEATURE;
                end
                else begin
                    mem_fsm_ns = MEM_LEFT;
                end
            end
        end
    end
    MEM_LEFT: begin
        if(c_cfg_c_r_pad_mode[1]) begin
            // bp_mem_rd_addr = addr_mu_addr;
            bp_mem_rd_req = mem_rd_req_en;

            if(bp_mem_rd_req & bp_mem_rd_gnt) begin
                if(mem_pad_data_in_finish)begin // left reg data in finish
                    mem_fsm_ns = MEM_FEATURE;
                    mem_rd_req_en_ns = 1'b1;
                end
                else begin
                    mem_rd_req_en_ns = 1'b0;
                end
            end
            else if(mem_pad_data_in_finish)begin
                mem_fsm_ns = MEM_FEATURE;
                mem_rd_req_en_ns = 1'b1;
            end
        end
        else begin
            if(mem_pad_data_in_finish) begin
                mem_fsm_ns = MEM_FEATURE;
            end
        end
    end
    MEM_FEATURE: begin
        // bp_mem_rd_addr = addr_mu_addr;
        bp_mem_rd_req = 1'b1;
        addr_mu_valid = bp_mem_rd_gnt;

        if(bp_mem_rd_req & bp_mem_rd_gnt)begin
            if(pad_mode[0]) begin
                if((mem_rd_req_row_cnt == row_num - 11'd1) & (mem_rd_req_col_cnt == col_num - 11'd1)) begin
                    mem_rd_req_col_cnt_ns = 11'd0;
                    if(right_len == 4'd0) begin
                        mem_rd_req_row_cnt_ns = 11'd0;
                        if(bottom_len == 5'd0) begin
                            mem_fsm_ns = MEM_IDLE;
                        end
                        else begin
                            mem_fsm_ns = MEM_BOTTOM;
                            mem_addr_repeat_init = 1'b1;
                        end
                    end
                    else begin
                        mem_fsm_ns = MEM_RIGHT;
                    end
                end
                else if(mem_rd_req_col_cnt == col_num - 11'd1) begin
                    mem_rd_req_col_cnt_ns = 11'd0;
                    if(right_len == 4'd0) begin
                        mem_rd_req_row_cnt_ns = mem_rd_req_row_cnt + 11'd1;
                        if(left_len == 11'd0) begin
                            mem_fsm_ns = MEM_FEATURE;
                        end
                        else begin
                            mem_fsm_ns = MEM_LEFT;
                        end
                    end
                    else begin
                        mem_fsm_ns = MEM_RIGHT;
                    end
                end
                else begin
                    mem_rd_req_col_cnt_ns = mem_rd_req_col_cnt + 11'd1;
                    if((mem_rd_req_row_cnt == row_num - 11'd1) & (mem_rd_req_col_cnt == 11'd0)) begin
                        mem_addr_repeat_record_en = pad_mode[0] & pad_mode[1];
                    end
                end
            end
            else begin
                if(no_pad_mem_rd_req_cnt == no_pad_target_lenth) begin
                    mem_fsm_ns = MEM_IDLE;
                    no_pad_mem_rd_req_cnt_ns = 13'd0;
                end
                else begin
                    no_pad_mem_rd_req_cnt_ns = no_pad_mem_rd_req_cnt + 13'd1;
                end
            end
        end
    end
    MEM_RIGHT: begin
        if(mem_pad_data_in_finish) begin
            if(mem_rd_req_row_cnt == row_num - 11'd1) begin
                mem_rd_req_row_cnt_ns = 11'd0;
                if(bottom_len == 5'd0) begin
                    mem_fsm_ns = MEM_IDLE;
                end
                else begin
                    mem_fsm_ns = MEM_BOTTOM;
                    mem_addr_repeat_init = 1'b1;
                end
            end
            else begin
                mem_rd_req_row_cnt_ns = mem_rd_req_row_cnt + 11'd1;
                if(left_len == 11'd0) begin
                    mem_fsm_ns = MEM_FEATURE;
                end
                else begin
                    mem_fsm_ns = MEM_LEFT;
                end
            end
        end
    end
    MEM_BOTTOM: begin
        if(pad_mode[1]) begin
            // bp_mem_rd_addr = addr_mu_addr;
            bp_mem_rd_req = 1'b1;
            addr_mu_valid = bp_mem_rd_gnt;

            if(bp_mem_rd_req & bp_mem_rd_gnt)begin
                if((mem_rd_req_row_cnt == bottom_len - 5'd1) & (mem_rd_req_col_cnt == total_col_num - 11'd1)) begin
                    mem_rd_req_col_cnt_ns = 11'd0;
                    mem_rd_req_row_cnt_ns = 11'd0;
                    mem_fsm_ns = MEM_IDLE;
                end
                else if(mem_rd_req_col_cnt == total_col_num - 11'd1) begin
                    mem_rd_req_col_cnt_ns = 11'd0;
                    mem_rd_req_row_cnt_ns = mem_rd_req_row_cnt + 11'd1;
                    mem_addr_repeat_init = 1'b1;
                end
                else begin
                    mem_rd_req_col_cnt_ns = mem_rd_req_col_cnt + 11'd1;
                end
            end
        end
        else begin
            if(mem_pad_data_in_finish) begin
                mem_fsm_ns = MEM_IDLE;
            end
        end
    end
    endcase
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        mem_fsm_cs <= MEM_IDLE;
        mem_rd_req_row_cnt <= 'b0;
        mem_rd_req_col_cnt <= 'b0;
        mem_rd_req_en <= 1'b1;
        no_pad_mem_rd_req_cnt <= 'b0;
    end
    else begin
        mem_fsm_cs <= mem_fsm_ns;
        mem_rd_req_row_cnt <= mem_rd_req_row_cnt_ns;
        mem_rd_req_col_cnt <= mem_rd_req_col_cnt_ns;
        mem_rd_req_en <= mem_rd_req_en_ns;
        no_pad_mem_rd_req_cnt <= no_pad_mem_rd_req_cnt_ns;
    end
end

always_comb begin
    data_fsm_ns = data_fsm_cs;
    mem_rd_valid_row_cnt_ns = mem_rd_valid_row_cnt;
    mem_rd_valid_col_cnt_ns = mem_rd_valid_col_cnt;
    mem_data_sel_ns = mem_data_sel; //sel mem rd data or reg data
    mem_pad_data_reg_ns = mem_pad_data_reg; //left or right reduce reduplicated rd
    no_pad_mem_rd_valid_cnt_ns = no_pad_mem_rd_valid_cnt;

    mem_in_pad_data = 'b0;
    mem_in_pad_valid = 1'b0;
    mem_in_pad_last = 1'b0;

    mem_pad_data_in_finish = 1'b0; // padding zero or reduplicated finish flag  pass to req phase to active req
    mem_backpress_finish = 1'b0; //all finish

    case(data_fsm_cs)
    DATA_IDLE: begin
        if(core_rd_start & (c_cfg_c_r_dma_transfer_n) & c_cfg_c_r_local_access)begin
            if(c_cfg_c_r_pad_mode[0]) begin
                if(c_cfg_c_r_pad_up_len == 4'd0) begin
                    if(c_cfg_c_r_pad_left_len == 11'd0) begin
                        data_fsm_ns = DATA_FEATURE;
                    end
                    else begin
                        data_fsm_ns = DATA_LEFT;
                    end
                end
                else begin
                    data_fsm_ns = DATA_UP;
                end
            end
            else begin
                data_fsm_ns = DATA_FEATURE;
            end
        end
    end
    DATA_UP: begin
        if(pad_mode[1]) begin
            mem_in_pad_data = bp_mem_rd_data;
            mem_in_pad_valid = bp_mem_rd_valid;

            if(mem_in_pad_valid)begin
                if((mem_rd_valid_row_cnt == up_len - 4'd1) & (mem_rd_valid_col_cnt == total_col_num - 11'd1)) begin
                    mem_rd_valid_col_cnt_ns = 11'd0;
                    mem_rd_valid_row_cnt_ns = 11'd0;
                    if(left_len == 11'd0) begin
                        data_fsm_ns = DATA_FEATURE;
                    end
                    else begin
                        data_fsm_ns = DATA_LEFT;
                    end
                end
                else if(mem_rd_valid_col_cnt == total_col_num - 11'd1) begin
                    mem_rd_valid_col_cnt_ns = 11'd0;
                    mem_rd_valid_row_cnt_ns = mem_rd_valid_row_cnt + 11'd1;
                end
                else begin
                    mem_rd_valid_col_cnt_ns = mem_rd_valid_col_cnt + 11'd1;
                end
            end
        end
        else begin
            mem_in_pad_data = 'b0;
            mem_in_pad_valid = 1'b1;
            if(mem_in_pad_valid)begin
                if((mem_rd_valid_row_cnt == up_len - 4'd1) & (mem_rd_valid_col_cnt == total_col_num - 11'd1)) begin
                    mem_rd_valid_col_cnt_ns = 11'd0;
                    mem_rd_valid_row_cnt_ns = 11'd0;
                    mem_pad_data_in_finish = 1'b1;
                    if(left_len == 11'd0) begin
                        data_fsm_ns = DATA_FEATURE;
                    end
                    else begin
                        data_fsm_ns = DATA_LEFT;
                    end
                end
                else if(mem_rd_valid_col_cnt == total_col_num - 11'd1) begin
                    mem_rd_valid_col_cnt_ns = 11'd0;
                    mem_rd_valid_row_cnt_ns = mem_rd_valid_row_cnt + 11'd1;
                end
                else begin
                    mem_rd_valid_col_cnt_ns = mem_rd_valid_col_cnt + 11'd1;
                end
            end
        end
    end
    DATA_LEFT: begin
        if(pad_mode[1]) begin
            mem_in_pad_data = mem_data_sel ? mem_pad_data_reg : bp_mem_rd_data;
            mem_in_pad_valid = mem_data_sel ? 1'b1 : bp_mem_rd_valid;
            if(bp_mem_rd_valid) begin
                mem_data_sel_ns = 1'b1;
                mem_pad_data_reg_ns = bp_mem_rd_data;
            end
        end
        else begin
            mem_in_pad_data = 'b0;
            mem_in_pad_valid = 1'b1;
        end
        if(mem_in_pad_valid)begin
            if(mem_rd_valid_col_cnt == left_len - 11'd1) begin
                mem_rd_valid_col_cnt_ns = 11'd0;
                mem_pad_data_in_finish = 1'b1;
                mem_data_sel_ns = 1'b0;
                data_fsm_ns = DATA_FEATURE;
            end
            else begin
                mem_rd_valid_col_cnt_ns = mem_rd_valid_col_cnt + 11'd1;
            end
        end
    end
    DATA_FEATURE: begin
        mem_in_pad_data = bp_mem_rd_data;
        mem_in_pad_valid = bp_mem_rd_valid;

        if(mem_in_pad_valid)begin
            if(pad_mode[0]) begin
                if((mem_rd_valid_row_cnt == row_num - 11'd1) & (mem_rd_valid_col_cnt == col_num - 11'd1)) begin
                    mem_rd_valid_col_cnt_ns = 11'd0;
                    if(right_len == 4'd0) begin
                        mem_rd_valid_row_cnt_ns = 11'd0;
                        if(bottom_len == 5'd0) begin
                            data_fsm_ns = DATA_IDLE;
                            mem_backpress_finish = 1'b1;
                        end
                        else begin
                            data_fsm_ns = DATA_BOTTOM;
                        end
                    end
                    else begin
                        data_fsm_ns = DATA_RIGHT;
                        mem_pad_data_reg_ns = bp_mem_rd_data;
                    end
                end
                else if(mem_rd_valid_col_cnt == col_num - 11'd1) begin
                    mem_rd_valid_col_cnt_ns = 11'd0;
                    if(right_len == 4'd0) begin
                        mem_rd_valid_row_cnt_ns = mem_rd_valid_row_cnt + 11'd1;
                        if(left_len == 11'd0) begin
                            data_fsm_ns = DATA_FEATURE;
                        end
                        else begin
                            data_fsm_ns = DATA_LEFT;
                        end
                    end
                    else begin
                        data_fsm_ns = DATA_RIGHT;
                        mem_pad_data_reg_ns = bp_mem_rd_data;
                    end
                end
                else begin
                    mem_rd_valid_col_cnt_ns = mem_rd_valid_col_cnt + 11'd1;
                end
            end
            else begin
                if(no_pad_mem_rd_valid_cnt == no_pad_target_lenth) begin
                    data_fsm_ns = DATA_IDLE;
                    no_pad_mem_rd_valid_cnt_ns = 13'd0;
                    mem_backpress_finish = 1'b1;
                end
                else begin
                    no_pad_mem_rd_valid_cnt_ns = no_pad_mem_rd_valid_cnt + 13'd1;
                end
            end
        end
    end
    DATA_RIGHT: begin
        mem_in_pad_data = pad_mode[1] ? mem_pad_data_reg : 'd0;
        mem_in_pad_valid = 1'b1;
        if(mem_in_pad_valid) begin
            if(mem_rd_valid_col_cnt == right_len - 4'd1) begin
                mem_rd_valid_col_cnt_ns = 11'd0;
                mem_pad_data_in_finish = 1'b1;
                if(mem_rd_valid_row_cnt == row_num - 11'd1) begin
                    mem_rd_valid_row_cnt_ns = 11'd0;
                    if(bottom_len == 5'd0) begin
                        data_fsm_ns = DATA_IDLE;
                        mem_backpress_finish = 1'b1;
                    end
                    else begin
                        data_fsm_ns = DATA_BOTTOM;
                    end
                end
                else begin
                    mem_rd_valid_row_cnt_ns = mem_rd_valid_row_cnt + 11'd1;
                    if(left_len == 11'd0) begin
                        data_fsm_ns = DATA_FEATURE;
                    end
                    else begin
                        data_fsm_ns = DATA_LEFT;
                    end
                end
            end
            else begin
                mem_rd_valid_col_cnt_ns = mem_rd_valid_col_cnt + 11'd1;
            end
        end
    end
    DATA_BOTTOM: begin
        if(pad_mode[1]) begin
            mem_in_pad_data = bp_mem_rd_data;
            mem_in_pad_valid = bp_mem_rd_valid;
        end
        else begin
            mem_in_pad_data = 'b0;
            mem_in_pad_valid = 1'b1;
        end
        if(mem_in_pad_valid)begin
            if((mem_rd_valid_row_cnt == bottom_len - 5'd1) & (mem_rd_valid_col_cnt == total_col_num - 11'd1)) begin
                mem_rd_valid_col_cnt_ns = 11'd0;
                mem_rd_valid_row_cnt_ns = 11'd0;
                data_fsm_ns = DATA_IDLE;
                mem_backpress_finish = 1'b1;
                mem_pad_data_in_finish = 1'b1;
            end
            else if(mem_rd_valid_col_cnt == total_col_num - 11'd1) begin
                mem_rd_valid_col_cnt_ns = 11'd0;
                mem_rd_valid_row_cnt_ns = mem_rd_valid_row_cnt + 11'd1;
            end
            else begin
                mem_rd_valid_col_cnt_ns = mem_rd_valid_col_cnt + 11'd1;
            end
        end
    end
    endcase
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        data_fsm_cs <= DATA_IDLE;
        mem_rd_valid_row_cnt <= 'b0;
        mem_rd_valid_col_cnt <= 'b0;

        mem_data_sel <= 'b0;
        mem_pad_data_reg <= 'b0;

        no_pad_mem_rd_valid_cnt <= 'd0;
    end
    else begin
        data_fsm_cs <= data_fsm_ns;
        mem_rd_valid_row_cnt <= mem_rd_valid_row_cnt_ns;
        mem_rd_valid_col_cnt <= mem_rd_valid_col_cnt_ns;

        mem_data_sel <= mem_data_sel_ns;
        mem_pad_data_reg <= mem_pad_data_reg_ns;

        no_pad_mem_rd_valid_cnt <= no_pad_mem_rd_valid_cnt_ns;
    end
end


pad_addr_mu U_addr_mu(
    .clk                        (clk),
    .rst_n                      (rst_n),

    .cfg_base_addr              (addr_mu_initial_addr),
    .cfg_gap                    (c_cfg_c_r_loop_gap),
    .cfg_lenth                  (c_cfg_c_r_loop_lenth),

    .repeat_record_en           (mem_addr_repeat_record_en),
    .repeat_init                (mem_addr_repeat_init),

    .addr_mu_initial_en         (addr_mu_initial_en),
    .addr_mu_valid              (addr_mu_valid),

    .addr_mu_addr               (addr_mu_addr)
);


//------------------------------input select and total fsm control-------------------------------------------

logic [1:0] fsm_cs, fsm_ns;
logic [12:0] direct_in_cnt, direct_in_cnt_ns;

always_comb begin
    fsm_ns = fsm_cs;
    row_num_ns = row_num;
    col_num_ns = col_num;
    up_len_ns = up_len;
    right_len_ns = right_len;
    left_len_ns = left_len;
    bottom_len_ns = bottom_len;
    pad_mode_ns = pad_mode;
    direct_in_cnt_ns = direct_in_cnt;

    core_in_data = noc_in_pad_data;
    core_in_valid = 1'b0;
    core_in_last = 1'b0;

    core_rd_backpress_finish = 1'b0;

    noc_in_ready = 1'b0;

    case(fsm_cs)
    IDLE: begin
        if(core_rd_start)begin
            row_num_ns = c_cfg_c_r_pad_row_num;
            col_num_ns = c_cfg_c_r_pad_col_num;
            up_len_ns = c_cfg_c_r_pad_up_len;
            right_len_ns = c_cfg_c_r_pad_right_len;
            left_len_ns = c_cfg_c_r_pad_left_len;
            bottom_len_ns = c_cfg_c_r_pad_bottom_len;
            pad_mode_ns = c_cfg_c_r_pad_mode;
            if(~c_cfg_c_r_dma_transfer_n & c_cfg_c_r_pad_mode[0]) begin
                fsm_ns = NOC_IN;
            end
            else if(~c_cfg_c_r_local_access | (~c_cfg_c_r_dma_transfer_n & ~c_cfg_c_r_pad_mode[0])) begin
                fsm_ns = DIRECT_IN;
            end
            else begin
                fsm_ns = MEM_IN;
            end
        end
    end
    NOC_IN: begin
        core_rd_backpress_finish = noc_backpress_finish;
        core_in_data = noc_in_pad_data;
        core_in_valid = noc_in_pad_valid;
        noc_in_ready = noc_in_ready_temp;
        if(noc_backpress_finish) begin
            fsm_ns = IDLE;
            core_in_last = 1'b1;
        end
    end
    MEM_IN: begin
        core_rd_backpress_finish = mem_backpress_finish;
        core_in_data = mem_in_pad_data;
        core_in_valid = mem_in_pad_valid;
        if(mem_backpress_finish) begin
            fsm_ns = IDLE;
            core_in_last = 1'b1;
        end
    end
    DIRECT_IN: begin 
        core_in_data = noc_in_data;
        core_in_valid = noc_in_valid;
        noc_in_ready = 1'b1;
        core_rd_backpress_finish = 1'b0;
        if(noc_in_valid) begin
            if(direct_in_cnt == no_pad_target_lenth) begin
                fsm_ns = IDLE;
                direct_in_cnt_ns = 13'd0;
                core_rd_backpress_finish = 1'b1;
                core_in_last = 1'b1;
            end
            else begin
                direct_in_cnt_ns = direct_in_cnt + 13'd1;
            end
        end
    end
    endcase
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        fsm_cs <= NOC_IDLE;
        row_num <= 'b0;
        col_num <= 'b0;
        up_len <= 'b0;
        bottom_len <= 'b0;
        right_len <= 'b0;
        left_len <= 'b0;
        pad_mode <= 'b0;

        direct_in_cnt <= 'd0;
    end
    else begin
        fsm_cs <= fsm_ns;
        row_num <= row_num_ns;
        col_num <= col_num_ns;
        up_len <= up_len_ns;
        bottom_len <= bottom_len_ns;
        right_len <= right_len_ns;
        left_len <= left_len_ns;
        pad_mode <= pad_mode_ns;

        direct_in_cnt <= direct_in_cnt_ns;
    end
end


endmodule