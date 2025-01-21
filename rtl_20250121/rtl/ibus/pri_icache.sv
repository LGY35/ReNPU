module pri_icache(
    input                   clk,
    input                   rst_n,

    //interface with core
    input                   fetch_req,
    output  logic           fetch_gnt,
    input           [18:0]  fetch_addr,
    output  logic   [31:0]  fetch_r_data,
    output  logic           fetch_r_valid,


    //interface with L1 to L2 interface
    output  logic           pri_cache_refill_req,
    input                   pri_cache_refill_gnt,
    output  logic   [18:0]  pri_cache_refill_addr,
    output  logic           pri_cache_refill_lenth,
    input                   pri_cache_refill_r_valid,
    input           [31:0]  pri_cache_refill_r_data,

    output  logic           refill_done,
    input                   icache_work_en,
    input                   icache_sleep_en,
    input                   icache_lowpower_en

);

localparam SLEEP = 3'b000;
// localparam FLUSH = 3'b001;
localparam MISS_CHECK = 3'b001;
localparam ICACHE = 3'b010;
localparam ICACHE_COMPARE = 3'b011;
localparam ICACHE_COMPARE_HIT = 3'b100;
localparam BOTH_COMPARE = 3'b101;
localparam ICACHE_MISS = 3'b110;
localparam ICACHE_STREAM_HIT = 3'b111;

logic [2:0] cs, ns;
logic icache_sleep_en_reg;

logic [3:0] me,we,re, we_ibuffer, we_icache, re_icache;
logic [6:0] data_ram_addr;
logic [18:0] ram_addr_cs, ram_addr_ns;
logic [2:0] tag_ram_addr;
logic [3:0][31:0] data_ram_out;
logic [31:0] data_ram_in;
logic [3:0][9:0] tag_ram_out;
logic [9:0] tag_ram_in;

logic [31:0] bit_mask_write;

logic icache_hit, hit;
logic [3:0] hit_state;
logic [18:0] fetch_addr_reg;
logic [18:0] fetch_addr_speculative_reg;
logic [9:0] tag_input;
logic [7:0][3:0] cache_line_valid;
//logic [2:0][3:0][1:0] cache_line_use;
logic [3:0] cache_line_miss_sel, cache_line_miss_sel_reg, not_valid_onehot;

// logic [3:0] small_of4_onehot;
// logic cache_line_hit_sel;
logic [2:0] cache_set_addr;

logic stream_busy;
logic stream_fetch_valid;
logic stream_miss; //
logic fetch_stream_req;
logic [18:0] fetch_stream_addr;
logic [18:0] fetch_stream_addr_reg;
logic fetch_stream_gnt;
logic fetch_stream_r_valid;
logic [31:0] fetch_stream_r_data;
logic stream_to_icache_valid;
logic [31:0] stream_to_icache_data;
logic prefetch_r_valid;
logic [31:0] prefetch_r_data;
logic stream_move_done, stream_hit;

logic ctr_refill_req;
logic [18:0] ctr_refill_addr;
logic ctr_refill_lenth;
logic ctr_refill_mode;
logic icache_refill_done;
logic icache_refill_r_valid;
logic [31:0] icache_refill_r_data;

logic plru_hit;
logic [2:0] hit_cache_line_addr;
logic [3:0] plru_hit_index;
logic [2:0] miss_cache_line_addr;
logic [3:0] plru_old_onehot;

logic sfetch_miss, sfetch_miss_ns; //推测性访问icache
logic [31:0] fetch_r_data_cs, fetch_r_data_ns;

logic stream_hit_reg;
logic [18:0] next_line_addr;
assign next_line_addr = fetch_addr_reg + 64;


always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        icache_sleep_en_reg <= 'b0;
    end
    else if((cs == ICACHE) & (icache_sleep_en | icache_sleep_en_reg)) begin
        icache_sleep_en_reg <= 'b0;
    end
    else if(icache_sleep_en) begin
        icache_sleep_en_reg <= icache_sleep_en;
    end
end

integer j;

always_comb begin
    ns = cs;
    ram_addr_ns = ram_addr_cs;
    sfetch_miss_ns = sfetch_miss;
    fetch_r_data_ns = fetch_r_data_cs;

    fetch_gnt = 'b0;
    fetch_r_valid = 'b0;
    fetch_r_data = 'b0;

    data_ram_addr = fetch_addr[8:2];
    tag_ram_addr = fetch_addr[8:6];
    data_ram_in = icache_refill_r_data;
    tag_ram_in = fetch_addr_reg[18:9];

    //use for compare
    tag_input = fetch_addr_reg[18:9];
    cache_set_addr = fetch_addr_reg[8:6];

    we = 'b0;
    re = 'b0; 

    ctr_refill_req = 1'b0;
    ctr_refill_addr = {next_line_addr[18:6],6'b0};
    ctr_refill_lenth = 1'b0;
    ctr_refill_mode = 1'b0; //0: stream buffer; 1: icache

    plru_hit = 'b0;
    hit_cache_line_addr = cache_set_addr;
    plru_hit_index = hit_state;
    miss_cache_line_addr = cache_set_addr;

    stream_fetch_valid = 1'b0;
    fetch_stream_req = 'b0;
    fetch_stream_addr = fetch_addr;
    fetch_stream_addr_reg = fetch_addr_reg;
    stream_miss = 'b0;

    case(cs)
        SLEEP: begin
            if(icache_work_en) begin
                ns = ICACHE;
            end
        end
        ICACHE: begin
            if(icache_sleep_en | icache_sleep_en_reg)
                ns = SLEEP;
            else if(fetch_req) begin
                if(stream_busy) begin
					if(~sfetch_miss)begin
                        fetch_gnt = 1'b1;
                    	ns = ICACHE_COMPARE;
                    	re = 4'hf;
					end
                end
                else begin
                    ns = BOTH_COMPARE;
                    re = 4'hf;
                    sfetch_miss_ns = 1'b0;
                    if(~sfetch_miss) begin
                        fetch_gnt = 1'b1;
                    end
                end
            end
            else if(sfetch_miss) begin
                if(~stream_busy) begin
                    ns = BOTH_COMPARE;
                    re = 4'hf;
                    sfetch_miss_ns = 1'b0;
                end
            end
        end
        ICACHE_COMPARE: begin
            // tag_input = fetch_addr[18:9];
            // cache_set_addr = fetch_addr[8:6];
            tag_input = fetch_addr_speculative_reg[18:9];
            cache_set_addr = fetch_addr_speculative_reg[8:6];
            if(icache_hit) begin
                plru_hit = 1'b1;
                ns = ICACHE_COMPARE_HIT;

			//	re = 4'hf;
                for(j = 0; j < 4 ; j = j + 1)begin
                    if(hit_state[j])
                    	fetch_r_data_ns = data_ram_out[j];
                end
                // fetch_r_data_ns = ({32{hit_state[3]}} & data_ram_out[3]) | ({32{hit_state[2]}} & data_ram_out[2]) | ...;
            end
            else begin
                ns = ICACHE;
                sfetch_miss_ns = 1'b1;
            end
        end
        ICACHE_COMPARE_HIT: begin
            fetch_r_valid = 1'b1;
            fetch_r_data = fetch_r_data_cs;

            if(fetch_req) begin
				re = 4'hf;
                fetch_gnt = 1'b1;
                if(stream_busy) begin
                    ns = ICACHE_COMPARE;
                end
                else begin
                    ns = BOTH_COMPARE;
                end
            end
            else begin
                ns = ICACHE;
            end
        end
        BOTH_COMPARE: begin
            fetch_stream_req = 1'b1;
            fetch_stream_addr_reg = fetch_addr_reg;
            if(icache_hit) begin
                fetch_r_valid = 1'b1;
                plru_hit = 1'b1;
                for(j = 0; j < 4 ; j = j + 1)begin
                    if(hit_state[j])
                    fetch_r_data = data_ram_out[j];
                end
                if(fetch_req) begin
					re = 4'hf;
                    if(stream_busy) begin
                        ns = ICACHE_COMPARE;
                    end
                    else begin
                        ns = BOTH_COMPARE;
                        fetch_gnt = 1'b1;
                    end
                end
                else begin
                    ns = ICACHE;
                end
            end
            else if(stream_hit) begin
                fetch_r_valid = 1'b1;
                fetch_r_data = fetch_stream_r_data;
                ns = MISS_CHECK;
                ram_addr_ns = {fetch_addr_reg[18:6],6'b0};

                data_ram_addr = next_line_addr[8:2];
                tag_ram_addr = next_line_addr[8:6];
                re = 4'hf;
            end
            else begin
                ns = MISS_CHECK;
                stream_miss = 1'b1;
                ram_addr_ns = {fetch_addr_reg[18:6],6'b0};

                data_ram_addr = next_line_addr[8:2];
                tag_ram_addr = next_line_addr[8:6];
                re = 4'hf;
            end
        end
        MISS_CHECK: begin
            tag_input = next_line_addr[18:9];
            cache_set_addr =  next_line_addr[8:6];
            if(stream_hit_reg) begin
                ns = ICACHE_STREAM_HIT;
                if(~icache_hit) begin
                    ctr_refill_req = 1'b1;
                    ctr_refill_lenth = 1'b0;
                    stream_fetch_valid = 1'b1;
                end
            end
            else begin
                ns = ICACHE_MISS;
                ctr_refill_req = 1'b1;
                ctr_refill_addr = {fetch_addr_reg[18:6],6'b0};
                if(icache_hit) begin
                    ctr_refill_lenth = 1'b0;
                    ctr_refill_mode = 1'b1;
                end
                else begin
                    ctr_refill_lenth = 1'b1;
                    stream_fetch_valid = 1'b1;
                end
            end
        end
        ICACHE_MISS: begin
            // prefetch_r_valid = 1'b0;
            data_ram_addr = ram_addr_cs[8:2];
            tag_ram_addr = ram_addr_cs[8:6];
            if(icache_refill_r_valid) begin
                we = cache_line_miss_sel_reg;
                ram_addr_ns = ram_addr_cs + 4;
                if(data_ram_addr == fetch_addr_reg[8:2]) begin
                    fetch_r_valid = 1'b1;
                    fetch_r_data = icache_refill_r_data;
                end
            end
            if(icache_refill_done) begin
                ns = ICACHE;
                plru_hit = 1'b1;
                plru_hit_index = cache_line_miss_sel_reg;
            end
        end
        ICACHE_STREAM_HIT: begin
            data_ram_in = stream_to_icache_data;

            fetch_gnt = fetch_stream_gnt;
            fetch_stream_req = fetch_req;
            fetch_stream_addr = fetch_addr;
            fetch_r_data = fetch_stream_r_data;
            fetch_r_valid = fetch_stream_r_valid;

            tag_ram_addr = ram_addr_cs[8:6];
            data_ram_addr = ram_addr_cs[8:2];
            if(stream_to_icache_valid) begin
                we = cache_line_miss_sel_reg;
                ram_addr_ns = ram_addr_cs + 4;
            end
            if(stream_move_done) begin
                ns = ICACHE;
                plru_hit = 1'b1;
                plru_hit_index = cache_line_miss_sel_reg;
            end
        end
    endcase

	me = we | re;

end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cs <= SLEEP;
        sfetch_miss <= 'b0;
        ram_addr_cs <= 'b0;
        fetch_r_data_cs <= 'b0;
    end
    else begin
        cs <= ns;
        sfetch_miss <= sfetch_miss_ns;
        ram_addr_cs <= ram_addr_ns;
        fetch_r_data_cs <= fetch_r_data_ns;
    end
end

//---------------------------------------fetch interface-----------------------------------------------------------

// assign cache_set_addr = fetch_addr_reg[8:6];

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        fetch_addr_reg <= 'b0;
    else if(fetch_gnt)
        fetch_addr_reg <= fetch_addr;
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        fetch_addr_speculative_reg <= 'b0;
    else if(((cs == ICACHE) & ~(icache_sleep_en | icache_sleep_en_reg) & (fetch_req & stream_busy & ~sfetch_miss)) |
            ((cs == ICACHE_COMPARE_HIT) & (fetch_req & stream_busy)))
        fetch_addr_speculative_reg <= fetch_addr;
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        stream_hit_reg <= 'b0;
    else
        stream_hit_reg <= stream_hit;
end

//------------------------------------cache icache_hit------------------------------

assign icache_hit = |hit_state;
assign hit = icache_hit | stream_hit;

integer k;

always_comb begin
    hit_state = 'b0;
    for(k = 0; k < 4 ; k = k + 1)begin
        if((tag_ram_out[k][9:0] == tag_input) & cache_line_valid[cache_set_addr][k]) begin
            hit_state[k] = 1'b1;
        end
    end
end

// choose_small_of4 U_choose_small_of4(
//     .data_in(cache_line_use[cache_set_addr]),
//     .result_onehot(small_of4_onehot)
// );

find_not_valid U_find_not_valid(
    .valid(cache_line_valid[cache_set_addr]),
    .result_onehot(not_valid_onehot)
);

assign cache_line_miss_sel = (&cache_line_valid[cache_set_addr]) ? plru_old_onehot : not_valid_onehot;

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cache_line_miss_sel_reg <= 'b0;
    // else if((cs == BOTH_COMPARE) & (~hit | stream_hit))
    else if((cs == BOTH_COMPARE) & (~icache_hit))
        cache_line_miss_sel_reg <= cache_line_miss_sel;
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cache_line_valid <= 'b0;
    else if((cs == ICACHE) & (icache_sleep_en | icache_sleep_en_reg))
        cache_line_valid <= 'b0;
    else if(((cs == ICACHE_MISS) & icache_refill_done) | ((cs == ICACHE_STREAM_HIT) & stream_move_done))
        cache_line_valid[cache_set_addr] <= cache_line_valid[cache_set_addr] | cache_line_miss_sel_reg;
end

// always_ff @(posedge clk or negedge rst_n) begin
//     if(!rst_n)
//         cache_line_use <= 'b0;
//     else if((cs == ICACHE) & (icache_sleep_en | icache_sleep_en_reg))
//         cache_line_use <= 'b0;
//     else if((cs == ICACHE_COMPARE) & icache_hit) begin
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
//     else if(((cs == ICACHE_MISS) & icache_refill_done) | ((cs == ICACHE_STREAM_HIT) & stream_move_done)) begin
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

assign bit_mask_write = {32{1'b1}};

genvar i;
generate
    for(i = 0; i < 4; i = i + 1) begin: pri_icache_sram_bank
        std_spram128x32 U_pri_icache_data(
            .CLK(clk),
            .CE(me[i]),
            .WE(we[i]),
            .A(data_ram_addr),
            .D(data_ram_in),
            .Q(data_ram_out[i])
            // .WEM(bit_mask_write)
        );

        tag_reg8x10 U_pri_icache_tag(
            .CLK(clk),
            .ME(me[i]),
            .WE(we[i]),
            .A(tag_ram_addr),
            .D(tag_ram_in),
            .Q(tag_ram_out[i])
            // .WEM(bit_mask_write[15:0])
        );
    end
endgenerate

//--------------------------module instance------------------------------

stream_buffer U_stream_buffer(
    .clk                            (clk                    ),
    .rst_n                          (rst_n                  ),

    .fetch_stream_req               (fetch_stream_req       ),
    .fetch_stream_addr              (fetch_stream_addr      ),
    .fetch_stream_addr_reg          (fetch_stream_addr_reg  ),
    .fetch_stream_gnt               (fetch_stream_gnt       ),
    .fetch_stream_r_valid           (fetch_stream_r_valid   ),
    .fetch_stream_r_data            (fetch_stream_r_data    ),

    .stream_to_icache_valid         (stream_to_icache_valid ),
    .stream_to_icache_data          (stream_to_icache_data  ),

    .prefetch_r_valid               (prefetch_r_valid       ),
    .prefetch_r_data                (prefetch_r_data        ),
    // .prefetch_addr                  (),
    // .prefetch_req                   (),
    // .prefetch_gnt                   (),

    .icache_work_en                 (icache_work_en         ),
    .icache_sleep_en                (icache_lowpower_en     ),
    .stream_fetch_valid             (stream_fetch_valid     ),
    .stream_miss                    (stream_miss            ),
    .stream_busy                    (stream_busy            ),
    .stream_move_done               (stream_move_done       ),
    .stream_hit                     (stream_hit             )
);

icache_refill_ctr U_icache_refill_ctr(
    .clk                            (clk                        ),
    .rst_n                          (rst_n                      ),

    .icache_work_en                 (icache_work_en             ),
    .icache_sleep_en                (icache_sleep_en            ),

    .ctr_refill_req                 (ctr_refill_req             ),
    .ctr_refill_addr                (ctr_refill_addr            ),
    .ctr_refill_lenth               (ctr_refill_lenth           ),
    .ctr_refill_mode                (ctr_refill_mode            ),

    .icache_refill_r_valid          (icache_refill_r_valid      ),
    .icache_refill_r_data           (icache_refill_r_data       ),
    .icache_refill_done             (icache_refill_done         ),

    .prefetch_r_valid               (prefetch_r_valid           ),
    .prefetch_r_data                (prefetch_r_data            ),
    // .stream_buffer_refill_done      (),

    .pri_cache_refill_req           (pri_cache_refill_req       ),
    .pri_cache_refill_gnt           (pri_cache_refill_gnt       ),
    .pri_cache_refill_addr          (pri_cache_refill_addr      ),
    .pri_cache_refill_lenth         (pri_cache_refill_lenth     ),
    .pri_cache_refill_r_valid       (pri_cache_refill_r_valid   ),
    .pri_cache_refill_r_data        (pri_cache_refill_r_data    ),
    .refill_done                    (refill_done                )
);

plru U_plru(
    .clk                            (clk                        ),
    .rst_n                          (rst_n                      ),

    .plru_hit                       (plru_hit                   ),
    .hit_cache_line_addr            (hit_cache_line_addr        ),
    .plru_hit_index                 (plru_hit_index             ),

    .miss_cache_line_addr           (miss_cache_line_addr       ),
    .choose_old_onehot              (plru_old_onehot            )
);

endmodule
