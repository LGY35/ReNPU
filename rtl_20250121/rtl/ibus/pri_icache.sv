
// 这个icache是使用状态机来实现的, 而cpu访存使用的cache一般是用pipeline实现
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

/*
    fetch_addr [18:0]
    1. tag 10bit: tag_input = fetch_addr_reg[18:9];
    2. 寻址tag ram的地址3bit(8个entry): tag_ram_addr = fetch_addr[8:6]
    3. cache_set_addr = fetch_addr_reg[8:6];   // 一共有8个cacheline, 所以是3bit
    4. 寻址data ram的地址7bit(128个entry, 16个entry为一个cacheline): data_ram_addr = fetch_addr[8:2];
    5. 一个cacheline内的一条指令/word地址4bit: addr[5:2], 一共16B

*/

logic [3:0] me,we,re, we_ibuffer, we_icache, re_icache;
logic [6:0] data_ram_addr;  // 7bit 对应128个entry,每个entry32bit为一条指令, 每16个entry是一条cacheline(128bit)
logic [18:0] ram_addr_cs, ram_addr_ns;  // 总的19bit地址
logic [2:0] tag_ram_addr;   // 一共8个cacheline, 所以3bit tag地址
logic [3:0][31:0] data_ram_out; // 一次读出4way的指令
logic [31:0] data_ram_in;
logic [3:0][9:0] tag_ram_out;
logic [9:0] tag_ram_in;

logic [31:0] bit_mask_write;    //一条指令里32bit的mask, 需要RAM带有WEM,此处不使用

logic icache_hit, hit;
logic [3:0] hit_state;  // 4个way的命中状态
logic [18:0] fetch_addr_reg;
//  用于时序修正
logic [18:0] fetch_addr_speculative_reg;
logic [9:0] tag_input;
logic [7:0][3:0] cache_line_valid;  // valid array, 8个cacheline, 每个4way
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
    // stream_buffer

//  这两个信号其实就是icache是否命中hit
logic sfetch_miss, sfetch_miss_ns; //推测性访问icache
logic [31:0] fetch_r_data_cs, fetch_r_data_ns;

logic stream_hit_reg;
logic [18:0] next_line_addr;
// next_line_addr 地址就是当前core要取的cacheline的下一条line的地址
assign next_line_addr = fetch_addr_reg + 64;// 一个entry是32bit=4B, 16个entry是64B


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

    data_ram_addr = fetch_addr[8:2];// fetch_addr是按照Bytes, 所以用4B对齐word
    tag_ram_addr = fetch_addr[8:6]; // 一个tag对应16个entry,多了4bit.7-4=3bit = 8entry
    data_ram_in = icache_refill_r_data;
    tag_ram_in = fetch_addr_reg[18:9];  // 给到tag array的输入

    //use for compare
    tag_input = fetch_addr_reg[18:9];
    cache_set_addr = fetch_addr_reg[8:6];   // 一共有8个cacheline, 所以是3bit

    we = 'b0;
    re = 'b0; 

    // refill接口
    ctr_refill_req = 1'b0;
    ctr_refill_addr = {next_line_addr[18:6],6'b0};  // 64Byte
    ctr_refill_lenth = 1'b0;
    ctr_refill_mode = 1'b0; //0: stream buffer; 1: icache

    // 更新plru
    plru_hit = 'b0;
    hit_cache_line_addr = cache_set_addr;
    plru_hit_index = hit_state;
    miss_cache_line_addr = cache_set_addr;

    // stream_buffer
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
                // 如果stream正在预取, 就只判断icache
                if(stream_busy) begin
                    // 因为stream buffer在忙,所以只看icache.然后判断如果推测执行状态下,icache没有miss,就可以继续比较icache, 否则就保持.
                    // 推测执行状态下没有miss(按照cacheline下一条执行),就只需要看icache
                    // 此时因为不确定是不是可以命中,就不返回gnt
					if(~sfetch_miss)begin
                        fetch_gnt = 1'b1;
                    	ns = ICACHE_COMPARE;
                    	re = 4'hf;
					end
                    // 如果推测执行状态下miss了(sfetch_miss=1), 就保持状态不变,继续检测
                end
                // icache 和 stream buffer都需要比较
                else begin
                    ns = BOTH_COMPARE;
                    re = 4'hf;
                    // 恢复为推测状态执行:
                    // 如果icache命中，那显然就是sfetch；如果stream命中，会move到icache里面，所以也要sfetch。如果都miss，就要从L2搬到L1中，也是继续sfetch
                    sfetch_miss_ns = 1'b0;
                    // 如果上一拍没有miss,说明推测性执行肯定可以取到下一条cacheline,就可以返回gnt,代表收到了req.
                    if(~sfetch_miss) begin
                        fetch_gnt = 1'b1;
                    end
                end
            end
            // 这是发生了miss
            // stream如果没有预取,就都比较-说明此时是预取完了,恢复推测执行,
            // 反之因为icache miss, stream也在预取, 两个地方都没有数据,就等待,
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
            // fetch_addr_speculative_reg专门用作推测性执行使用, 所以只会给到icache
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
            // icache_hit=0, 即推测执行状态下miss
            else begin
                ns = ICACHE;
                sfetch_miss_ns = 1'b1;
            end
        end
        ICACHE_COMPARE_HIT: begin
            // 返回fetch有效
            fetch_r_valid = 1'b1;
            // 读取的指令
            fetch_r_data = fetch_r_data_cs;
            // 命中之后,同拍处理下一个req. 因为此时是hit, 所以一定是推测执行,不需要判断sfetch
            if(fetch_req) begin
				re = 4'hf;
                // 这种情况就可以返回gnt
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
            // 只要icache没有hit，就进入 MISS_CHECK 状态
            // 此时如果stream hit了，就直接返回有效的数据，和valid信号
            // 但是不管stream hit与否，都要用next_line_addr 从cache中取出下一个cacheline，然后比较tag是不是hit
            // 如果下一个hit了，就不用refill icache了。
            // 此时，再分析，如果stream hit，就真的不需要refill，而stream 也miss，就需要refill stream 而不需要stream icache
            else if(stream_hit) begin
                fetch_r_valid = 1'b1;
                fetch_r_data = fetch_stream_r_data;
                ns = MISS_CHECK;
                ram_addr_ns = {fetch_addr_reg[18:6],6'b0};
                // 取出下一行的tag和data
                data_ram_addr = next_line_addr[8:2];
                tag_ram_addr = next_line_addr[8:6];
                re = 4'hf;
            end
            else begin
                ns = MISS_CHECK;
                stream_miss = 1'b1;
                ram_addr_ns = {fetch_addr_reg[18:6],6'b0};

                data_ram_addr = next_line_addr[8:2];
                //取icache中的tag所用的地址，下一拍取出来之后得到icache中的实际cacheline tag
                tag_ram_addr = next_line_addr[8:6];
                //下一拍在misscheck的时候，用要取的next_line的addr和cacheline中实际的next_line addr比较
                re = 4'hf;
            end
        end
        //检查下一个地址在不在当前的icache里面。比如可能是上一个小循环留下的。//检查的方式就是看下一个cacheline的内容
        MISS_CHECK: begin
            tag_input = next_line_addr[18:9];
            cache_set_addr =  next_line_addr[8:6];
            if(stream_hit_reg) begin
                ns = ICACHE_STREAM_HIT;
                // 这个状态里面的icachehit就是判断下一条cacheline是不是在icache里面
                if(~icache_hit) begin
                    ctr_refill_req = 1'b1;  // refill都是从上一级cache中取
                    ctr_refill_lenth = 1'b0;//一个cacheline
                    stream_fetch_valid = 1'b1;//告诉stream buffer，要预取了，就是icache没有
                end
            end
            else begin
                ns = ICACHE_MISS;
                ctr_refill_req = 1'b1;
                ctr_refill_addr = {fetch_addr_reg[18:6],6'b0};
                if(icache_hit) begin    // 如果下一条是命中，就只需要取一条
                    ctr_refill_lenth = 1'b0;
                    ctr_refill_mode = 1'b1;
                end
                else begin
                    ctr_refill_lenth = 1'b1;// 如果都miss就要取2条
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
            // stream 与 core 的连接
            //stream一边给icache发送数据，一边给core提供数据，这就是用来处理core的req(req没有gnt的话是一直保持的)
            fetch_gnt = fetch_stream_gnt;
            fetch_stream_req = fetch_req;
            fetch_stream_addr = fetch_addr;
            fetch_r_data = fetch_stream_r_data;
            fetch_r_valid = fetch_stream_r_valid; //hit之后当拍给出valid
            // 从stream中搬数据到core中
            tag_ram_addr = ram_addr_cs[8:6];
            data_ram_addr = ram_addr_cs[8:2];
            // stream给icache发数据的valid
            if(stream_to_icache_valid) begin
                we = cache_line_miss_sel_reg;
                ram_addr_ns = ram_addr_cs + 4;//单个word 地址递增，传16个周期
            end
            //只要没有move_done，就保持这个状态
            if(stream_move_done) begin
                ns = ICACHE;
                plru_hit = 1'b1;
                plru_hit_index = cache_line_miss_sel_reg;
            end
        end
    endcase
    //ram使能信号
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

    //两组条件就是把分别在两个状态——ICACHE和ICACHE_COMPARE_HIT下，会进入到ICACHE_COMPARE状态的条件进行了提取
        //icache状态下, 如果有req,但是stream在预取, icache还在推测执行,就可以保存下这个推测地址
    else if(((cs == ICACHE) & ~(icache_sleep_en | icache_sleep_en_reg) & (fetch_req & stream_busy & ~sfetch_miss)) |
            // 如果icache比较, stream也在预取, 也可以把地址保存下来
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

integer k;  // way

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

// 选择哪个要替换哪个entry：8个entry是不是都有效，如果都有效，就用plru_old_onehot，否则就用 invalid的那个entry
assign cache_line_miss_sel = (&cache_line_valid[cache_set_addr]) ? plru_old_onehot : not_valid_onehot;

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cache_line_miss_sel_reg <= 'b0;
    // 注释的代码: 如果BOTH_COMPARE，并且 没有hit或者只有stream_hit，此时需要选判断是哪个miss
    // else if((cs == BOTH_COMPARE) & (~hit | stream_hit))
    // TODO: 更改为了: 只要icache没有命中即就要更新
    else if((cs == BOTH_COMPARE) & (~icache_hit))
        cache_line_miss_sel_reg <= cache_line_miss_sel;
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cache_line_valid <= 'b0;
    //如果是在ICACHE状态，并且需要sleep，那么就全都invalid
    else if((cs == ICACHE) & (icache_sleep_en | icache_sleep_en_reg))
        cache_line_valid <= 'b0;
    //如果MISS，并且refill完成，或者stream hit并且stream也move完成
    else if(((cs == ICACHE_MISS) & icache_refill_done) | ((cs == ICACHE_STREAM_HIT) & stream_move_done))
        // 等于自身或上miss之后选择的那个line
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

genvar i;   // 4路组相联, 所以有4个way,即生成4份.
generate
    for(i = 0; i < 4; i = i + 1) begin: pri_icache_sram_bank
        //32bit的指令, 128/8=16 为1个cacheline, 128bit为一个cacheline, 
        // 因为cache使用的是一个entry32bit, 所以需要将连续的16个entry作为一个cacheline. 
        // 因此读写mask都是4bit, 针对一个cacheline里面的16个entry.
        std_spram128x32 U_pri_icache_data(
            .CLK(clk),
            .CE(me[i]),
            .WE(we[i]),
            .A(data_ram_addr),
            .D(data_ram_in),
            .Q(data_ram_out[i])
            // .WEM(bit_mask_write)
        );
        // 10bit的tag, 8个entry
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

    .miss_cache_line_add
        // stream_bufferr           (miss_cache_line_addr       ),
    .choose_old_onehot              (plru_old_onehot            )
);

endmodule
