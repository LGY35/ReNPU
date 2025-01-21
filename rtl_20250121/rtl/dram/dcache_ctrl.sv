module dcache_ctrl(
    input                           clk,
    input                           rst_n,

    //interface with core
    input                           fetch_req,
    input                           fetch_we,
    output  logic                   fetch_gnt,
    input           [16:0]          fetch_addr,
    output  logic   [31:0]          fetch_r_data,
    output  logic                   fetch_r_valid,
    input           [31:0]          fetch_w_data,

    input                           flush_req,
    output  logic                   flush_gnt,
    output  logic                   flush_ok,

    //interface with Tcache

    output  logic   [1:0]           wen,
    output  logic   [7:0][31:0]     wdata,
    output  logic        [3:0]      addr_w,
    output  logic        [3:0]      addr_r,
    output  logic   [1:0]           ren,
    input           [1:0][255:0]    rdata,

    //interface with LB
    output  logic                   dcache_refill_req,
    input                           dcache_refill_gnt,
    output  logic                   dcache_refill_we,
    output  logic   [11:0]          dcache_refill_addr, //256
    output  logic                   dcache_refill_addr_valid,
    input                           dcache_refill_addr_ready,
    output  logic                   dcache_refill_wvalid,
    output  logic           [255:0] dcache_refill_wdata,
    output  logic   [5:0]           dcache_refill_lenth,
    input                           dcache_refill_rvalid,
    input           [255:0]         dcache_refill_rdata

);

localparam IDLE = 3'd0;
localparam COMPARE = 3'd1;
// localparam MISS_CHECK = 3'd2;
localparam STORE_REQ = 3'd2;
localparam REFILL_REQ = 3'd3;
localparam STORE = 3'd4;
localparam REFILL = 3'd5;
localparam FLUSH = 3'd6;


logic [2:0]     cs, ns;
logic           fetch_we_reg_cs, fetch_we_reg_ns;
logic [31:0]    fetch_w_data_reg_cs, fetch_w_data_reg_ns;

// logic [1:0] me,wen,ren;
logic [3:0] data_ram_addr;
logic [2:0] word_addr;
logic [3:0] ram_addr_cs, ram_addr_ns;
logic [2:0] tag_ram_addr;
// logic [3:0][31:0] data_ram_out;
// logic [:0] data_ram_in;
logic [1:0][7:0] tag_ram_out;
logic [7:0] tag_ram_in;

// logic [31:0] bit_mask_write;

logic dcache_hit, hit;
logic [1:0] hit_state;
logic [16:0] fetch_addr_reg;
logic [7:0] tag_input;
logic [7:0][1:0] cache_line_valid;
logic [7:0][1:0] cache_line_dirty;
logic [1:0] cache_line_miss_sel, cache_line_miss_sel_reg, not_valid_onehot;

// logic cache_line_hit_sel;
logic [2:0] cache_set_addr;
logic [4:0] dirty_cnt;

// logic ctr_refill_req;
// logic [18:0] ctr_refill_addr;
// logic ctr_refill_lenth;
// logic ctr_refill_mode;
logic dcache_refill_done;
// logic icache_refill_r_valid;
// logic [31:0] icache_refill_r_data;

logic plru_hit;
logic [2:0] hit_cache_line_addr;
logic [3:0] plru_hit_index;
logic [2:0] miss_cache_line_addr;
logic [3:0] plru_old_onehot;

logic [4:0] flush_cnt_cs, flush_cnt_ns;
logic move_cnt_cs, move_cnt_ns;
logic rd_req_cnt_cs, rd_req_cnt_ns;
logic rd_en_cs, rd_en_ns;
logic rdata_sel;
logic [15:0] cache_line_dirty_1d;
logic flush_dirty_flag_cs, flush_dirty_flag_ns;
logic flush_done;
logic way_sel_cs, way_sel_ns;

assign cache_line_dirty_1d = cache_line_dirty;

integer j;
// integer wdata_i; //word index

always_comb begin
    ns = cs;
    ram_addr_ns = ram_addr_cs;
    fetch_we_reg_ns = fetch_we_reg_cs;
    fetch_w_data_reg_ns = fetch_w_data_reg_cs;
    flush_cnt_ns = flush_cnt_cs; 
    move_cnt_ns = move_cnt_cs;
    rd_req_cnt_ns = rd_req_cnt_cs;
    rd_en_ns = rd_en_cs;
    flush_dirty_flag_ns = flush_dirty_flag_cs;
    way_sel_ns = way_sel_cs;
    // fetch_r_data_ns = fetch_r_data_cs;

    fetch_gnt = 'b0;
    fetch_r_valid = 'b0;
    fetch_r_data = 'b0;

    data_ram_addr = fetch_addr[8:5];
    tag_ram_addr = fetch_addr[8:6];


    // data_ram_in = dcache_refill_r_data;
    tag_ram_in = fetch_addr_reg[16:9];

    //use for compare
    tag_input = fetch_addr_reg[16:9];
    cache_set_addr = fetch_addr_reg[8:6];
    word_addr = fetch_addr_reg[4:2];

    wen = 'b0;
    ren = 'b0; 
    wdata = rdata[0];
    addr_w = fetch_addr_reg[8:5];
    addr_r = fetch_addr[8:5];



    plru_hit = 'b0;
    hit_cache_line_addr = cache_set_addr;
    plru_hit_index = hit_state;
    miss_cache_line_addr = cache_set_addr;

    flush_gnt = 1'b0;
    flush_ok = 1'b0;

    dcache_refill_req = 1'b0;
    dcache_refill_we = 1'b0;
    dcache_refill_addr = 'd0;
    dcache_refill_lenth = 6'd2;
    dcache_refill_addr_valid = 1'b0;
    dcache_refill_wvalid = 1'b0;
    dcache_refill_wdata = 'd0;

    dcache_refill_done = 1'b0;
    flush_done = 1'b0;

    case(cs)
        IDLE: begin
            if(flush_req)begin
                if(|cache_line_dirty_1d) begin
                    dcache_refill_lenth = {dirty_cnt,1'b0};
                    dcache_refill_req = 1'b1;
                    dcache_refill_we = 1'b1;
                    if(dcache_refill_gnt) begin
                        ns = FLUSH;
                        flush_gnt = 1'b1;
                        flush_dirty_flag_ns = 1'b1;

                        ren = 2'b01;
                        data_ram_addr = 4'd0;
                        tag_ram_addr = 3'd0;
                        ram_addr_ns = 4'd1;
                    end
                end
                else begin
                    ns = FLUSH;
                    flush_gnt = 1'b1;
                end
            end
            else if(fetch_req) begin
                ns = COMPARE;
                fetch_gnt = 1'b1;
                fetch_we_reg_ns = fetch_we;
                if(fetch_we) begin
                    fetch_w_data_reg_ns = fetch_w_data;
                end
                ren = 2'b11;
            end
        end
        COMPARE: begin
            if(dcache_hit) begin
                plru_hit = 1'b1;//----------------------------------
                if(fetch_we_reg_cs) begin
                    if(hit_state[1]) begin
                        wdata = rdata[1];
                    end
                    wdata[word_addr] = fetch_w_data_reg_cs;
                    wen = hit_state; //hit_onehot
                end
                else begin
                    fetch_r_valid = 1'b1;
                    for(j = 0; j < 2 ; j = j + 1)begin
                        if(hit_state[j])
                            fetch_r_data = rdata[j];
                    end
                end

                if(fetch_req) begin
                    ren = 2'b11;
                    ns = COMPARE;
                    fetch_gnt = 1'b1;
                    fetch_we_reg_ns = fetch_we;
                    if(fetch_we) begin
                        fetch_w_data_reg_ns = fetch_w_data;
                    end
                end
                else begin
                    ns = IDLE;
                end
            end
            else begin
                ram_addr_ns = {fetch_addr_reg[8:6], 1'b0};
                if(|(cache_line_dirty[miss_cache_line_addr] & cache_line_miss_sel)) begin //dirty need to write back
                    dcache_refill_req = 1'b1;
                    dcache_refill_we = 1'b1;
                    if(dcache_refill_gnt) begin
                        ns = STORE;
                    end
                    else begin
                        ns = STORE_REQ;
                    end
                end
                else begin //not dirty or not valid only need to read refill
                    dcache_refill_req = 1'b1;
                    dcache_refill_we = 1'b0;
                    if(dcache_refill_gnt) begin
                        ns = REFILL;
                    end
                    else begin
                        ns = REFILL_REQ;
                    end
                end
            end
        end
        STORE_REQ: begin
            dcache_refill_req = 1'b1;
            dcache_refill_we = 1'b1;
            if(dcache_refill_gnt) begin
                ns = STORE;
                ren = cache_line_miss_sel_reg;
                addr_r = ram_addr_cs;
                tag_ram_addr = ram_addr_cs[3:1];
            end
        end
        REFILL_REQ: begin
            dcache_refill_req = 1'b1;
            dcache_refill_we = 1'b0;
            if(dcache_refill_gnt) begin
                ns = REFILL;
                // ren = cache_line_miss_sel_reg;
                // addr_r = ram_addr_cs;
            end
        end
        STORE: begin  //2 * 256 write back to LB
            dcache_refill_addr_valid = 1'b1;
            dcache_refill_wvalid = 1'b1;
            dcache_refill_wdata = rdata[rdata_sel];

            if(~move_cnt_cs & dcache_refill_addr_ready) begin
                dcache_refill_addr = {tag_ram_out, fetch_addr_reg[8:6], 1'b0};
                ren = cache_line_miss_sel_reg;
                addr_r = ram_addr_cs + 4'd1;
                tag_ram_addr = ram_addr_cs[3:1];
                move_cnt_ns = ~move_cnt_cs;
            end
            else if(move_cnt_cs & dcache_refill_addr_ready) begin
                move_cnt_ns = ~move_cnt_cs;
                dcache_refill_addr = {tag_ram_out, fetch_addr_reg[8:6], 1'b1};
                dcache_refill_req = 1'b1;
                dcache_refill_we = 1'b0;
                if(dcache_refill_gnt) begin
                    ns = REFILL;
                end
                else begin
                    ns = REFILL_REQ;
                end
            end
        end
        REFILL: begin // read 2 * 256 to Tcache
            // prefetch_r_valid = 1'b0;
            dcache_refill_addr_valid = rd_en_cs;
            if(dcache_refill_addr_valid & dcache_refill_addr_ready) begin
                if(rd_req_cnt_cs) begin
                    dcache_refill_addr = {fetch_addr_reg[16:6], 1'b1};
                    rd_en_ns = 1'b0;
                    rd_req_cnt_ns = ~rd_req_cnt_cs;
                end
                else begin
                    dcache_refill_addr = {fetch_addr_reg[16:6], 1'b0};
                    rd_req_cnt_ns = ~rd_req_cnt_cs;
                end
            end

            data_ram_addr = ram_addr_cs;
            tag_ram_addr = ram_addr_cs[3:1];
            
            if(dcache_refill_rvalid) begin
                wen = cache_line_miss_sel_reg;
                if(move_cnt_cs) begin
                    ns = IDLE;
                    dcache_refill_done = 1'b1;
                    move_cnt_ns = ~move_cnt_cs;
                    rd_en_ns = 1'b1;
                end
                else begin
                    ram_addr_ns = ram_addr_cs + 4'd1;
                    move_cnt_ns = ~move_cnt_cs;
                end

                if(fetch_we_reg_cs) begin
                    if(data_ram_addr[0] == fetch_addr_reg[5]) begin
                        wdata = dcache_refill_rdata;
                        wdata[word_addr] = fetch_w_data_reg_cs;
                    end
                end
                else begin
                    if(data_ram_addr[0] == fetch_addr_reg[5]) begin
                        fetch_r_valid = 1'b1;
                        fetch_r_data = dcache_refill_rdata[word_addr*32 +: 32];
                        wdata = dcache_refill_rdata;
                    end
                end
            end

            if(dcache_refill_done) begin
                plru_hit = 1'b1;
                plru_hit_index = cache_line_miss_sel_reg;
            end
        end
        FLUSH: begin
            if(flush_dirty_flag_cs) begin
                dcache_refill_addr_valid = cache_line_valid[flush_cnt_cs[3:1]][way_sel_ns] & cache_line_dirty[flush_cnt_cs[3:1]][way_sel_ns];
                dcache_refill_wvalid = cache_line_valid[flush_cnt_cs[3:1]][way_sel_ns] & cache_line_dirty[flush_cnt_cs[3:1]][way_sel_ns];
                dcache_refill_wdata = (flush_cnt_cs < 5'd16) ? rdata[0] : rdata[1];
                dcache_refill_addr = {tag_ram_out, flush_cnt_cs[3:0]};
                if((dcache_refill_addr_valid & dcache_refill_addr_ready) | (~dcache_refill_addr_valid)) begin
                    if(flush_cnt_cs == 5'd31)begin
                        flush_done = 1'b1;
                        flush_ok = 1'b1;
                        ns = IDLE;
                        flush_cnt_ns = 5'd0;
                        flush_dirty_flag_ns = 1'b0;
                        way_sel_ns = 1'b0;
                    end
                    else begin
                        flush_cnt_ns = flush_cnt_cs + 5'd1;
                        ren = (flush_cnt_cs < 5'd15) ? 2'b01 : 2'b10;
                        data_ram_addr = ram_addr_cs;
                        tag_ram_addr = ram_addr_cs[3:1];
                        ram_addr_ns = ram_addr_cs + 4'd1;
                        if(flush_cnt_cs == 5'd15)begin
                            way_sel_ns = 1'b1;
                        end
                    end
                end
            end
            else begin
                flush_ok = 1'b1;
                ns = IDLE;
            end
        end
    endcase

	// me = wen | ren;

end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cs <= IDLE;
        ram_addr_cs <= 'b0;
        // fetch_r_data_cs <= 'b0;
        fetch_we_reg_cs <= 1'b0;
        fetch_w_data_reg_cs <= 'd0;
        flush_cnt_cs <= 'd0;
        move_cnt_cs <= 1'b0;
        rd_req_cnt_cs <= 'd0;
        rd_en_cs <= 1'b1;
        flush_dirty_flag_cs <= 1'b0;
        way_sel_cs <= 1'b0;
    end
    else begin
        cs <= ns;
        ram_addr_cs <= ram_addr_ns;
        // fetch_r_data_cs <= fetch_r_data_ns;
        fetch_we_reg_cs <= fetch_we_reg_ns;
        fetch_w_data_reg_cs <= fetch_w_data_reg_ns;
        flush_cnt_cs <= flush_cnt_ns;
        move_cnt_cs <= move_cnt_ns;
        rd_req_cnt_cs <= rd_req_cnt_ns;
        rd_en_cs <= rd_en_ns;
        flush_dirty_flag_cs <= flush_dirty_flag_ns;
        way_sel_cs <= way_sel_ns;
    end
end

//---------------------------------------fetch interface-----------------------------------------------------------

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        fetch_addr_reg <= 'b0;
    else if(fetch_gnt)
        fetch_addr_reg <= fetch_addr;
end

//------------------------------------cache dcache_hit------------------------------

assign dcache_hit = |hit_state;
assign hit = dcache_hit;

integer k;

always_comb begin
    hit_state = 'b0;
    for(k = 0; k < 2 ; k = k + 1)begin
        if((tag_ram_out[k][7:0] == tag_input) & cache_line_valid[cache_set_addr][k]) begin
            hit_state[k] = 1'b1;
        end
    end
end

always_comb begin
    not_valid_onehot = 'd0;

    case(cache_line_valid[cache_set_addr])
    2'b00: not_valid_onehot = 2'b01;
    2'b01: not_valid_onehot = 2'b10;
    2'b10: not_valid_onehot = 2'b01;
    2'b11: not_valid_onehot = 2'b01;
    endcase
end

assign cache_line_miss_sel = (&cache_line_valid[cache_set_addr]) ? plru_old_onehot : not_valid_onehot;

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cache_line_miss_sel_reg <= 'b0;
    // else if((cs == BOTH_COMPARE) & (~hit | stream_hit))
    else if((cs == COMPARE) & (~dcache_hit))
        cache_line_miss_sel_reg <= cache_line_miss_sel;
end

assign rdata_sel = cache_line_miss_sel_reg[1] | (~(cache_line_miss_sel_reg == 2'b01));

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cache_line_valid <= 'd0;
    else if((cs == FLUSH) & flush_done)begin
        cache_line_valid <= 'd0;
    end
    else if((cs == REFILL) & dcache_refill_done)
        cache_line_valid[cache_set_addr] <= cache_line_valid[cache_set_addr] | cache_line_miss_sel_reg;
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cache_line_dirty <= 'd0;
    end
    else if((cs == FLUSH) & flush_done)begin
        cache_line_dirty <= 'd0;
    end
    else if((cs == REFILL) & dcache_refill_done)begin
        cache_line_dirty[cache_set_addr] <= cache_line_dirty[cache_set_addr] & (~cache_line_miss_sel_reg);
    end
    else if((cs == COMPARE) & dcache_hit & fetch_we_reg_cs)begin
        cache_line_dirty[cache_set_addr] <= cache_line_dirty[cache_set_addr] | hit_state;
    end
end

integer dirty_i;

always_comb begin
    dirty_cnt = 5'd0;
    for(dirty_i = 0; dirty_i < 2; dirty_i = dirty_i + 1) begin
        if(cache_line_dirty_1d[dirty_i])
            dirty_cnt = dirty_cnt + 5'd1;
    end
end

// always_ff @(posedge clk or negedge rst_n) begin
//     if(!rst_n)
//         cache_line_use <= 'b0;
//     else if((cs == ICACHE) & (icache_sleep_en | icache_sleep_en_reg))
//         cache_line_use <= 'b0;
//     else if((cs == ICACHE_COMPARE) & dcache_hit) begin
//         for(j = 0; j < 4; j = j + 1) begin
//             if(hit_state[j])
//                 cache_line_use[cache_set_addr][j] <= 2'b11;
//             else begin
//                 case(cache_line_use[cache_set_addr][j])
//                 2'b00:  cache_line_use[cache_set_addr][j] <= 2'b00;
//                 2'b01:  cache_line_use[cache_set_addr][j] <= 2'b00;
//                 2'b10:  cache_line_use[cache_set_addr][j] <= 2'b01;
//                 2'b11:  cache_line_use[cache_set_addr][j] <= 2'b10;
//                 endcase
//             end
//         end
//     end
//     else if(((cs == ICACHE_MISS) & dcache_refill_done) | ((cs == ICACHE_STREAM_HIT) & stream_move_done)) begin
//         for(j = 0; j < 4; j = j + 1) begin
//             if(cache_line_miss_sel_reg[j])
//                 cache_line_use[cache_set_addr][j] <= 2'b11;
//             else begin
//                 case(cache_line_use[cache_set_addr][j])
//                 2'b00:  cache_line_use[cache_set_addr][j] <= 2'b00;
//                 2'b01:  cache_line_use[cache_set_addr][j] <= 2'b00;
//                 2'b10:  cache_line_use[cache_set_addr][j] <= 2'b01;
//                 2'b11:  cache_line_use[cache_set_addr][j] <= 2'b10;
//                 endcase
//             end
//         end
//     end
// end

//--------------------------------------------ram interface---------------------------------------------------

// assign bit_mask_write = {32{1'b1}};

// genvar i;
// generate
//     for(i = 0; i < 4; i = i + 1) begin: pri_icache_sram_bank
//         std_spram128x32 U_pri_icache_data(
//             .CLK(clk),
//             .CE(me[i]),
//             .WE(wen[i]),
//             .A(data_ram_addr),
//             .D(data_ram_in),
//             .Q(data_ram_out[i])
//             // .WEM(bit_mask_write)
//         );

//         tag_reg8x10 U_pri_icache_tag(
//             .CLK(clk),
//             .ME(me[i]),
//             .WE(wen[i]),
//             .A(tag_ram_addr),
//             .D(tag_ram_in),
//             .Q(tag_ram_out[i])
//             // .WEM(bit_mask_write[15:0])
//         );
//     end
// endgenerate

logic [1:0][7:0][7:0] tag_reg;

integer tag_i;

always @(posedge clk) begin
    for(tag_i = 0; tag_i < 2; tag_i = tag_i + 1) begin
        if(wen[tag_i])
            tag_reg[tag_i][tag_ram_addr] <= tag_ram_in;
        if(ren[tag_i])
            tag_ram_out[tag_i] <= tag_reg[tag_i][tag_ram_addr];
    end
end

//--------------------------module instance------------------------------

logic [7:0] cache_line_lru;

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cache_line_lru <= 'd0;
    end
    else if(plru_hit)begin
        if(plru_hit_index == 2'b01)
            cache_line_lru[hit_cache_line_addr] <= 1'b1;
        else if(plru_hit_index == 2'b10)
            cache_line_lru[hit_cache_line_addr] <= 1'b0;
    end
end

always_comb begin
    plru_old_onehot = 2'd0;

    if(cache_line_lru[miss_cache_line_addr]) begin
        plru_old_onehot = 2'b10;
    end
    else begin
        plru_old_onehot = 2'b01;
    end
end

endmodule