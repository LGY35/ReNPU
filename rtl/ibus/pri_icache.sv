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

logic [3:0] me,we,re, we_ibuffer, we_icache, re_icache; // me是使能ram，re是读使能，we是写使能
logic [6:0] data_ram_addr;
logic [18:0] ram_addr_cs, ram_addr_ns;
logic [2:0] tag_ram_addr;
logic [3:0][31:0] data_ram_out;
logic [31:0] data_ram_in;
logic [3:0][9:0] tag_ram_out;  //4路
logic [9:0] tag_ram_in;

logic [31:0] bit_mask_write;

// // fetch_addr:[18:0] 其中
// 10bit: [18:9] 为 tag, 
// 3bit: [8:6] 为set地址，即entry选择,  // 4路组相联，纵向共8个，这里是要从下一行。（每个line有16Byte，所以是4bit，再加上4路，即2bit，共6bit）
// 6bit:  
//      2bit用于选择set(4路)，
//      4bit用于选择word,16 * 4Bytes = 64Bytes, 正好一个cacheline长度
logic icache_hit, hit;
logic [3:0] hit_state;  //四路
logic [18:0] fetch_addr_reg;
logic [18:0] fetch_addr_speculative_reg;    // 时序修正
logic [9:0] tag_input;
logic [7:0][3:0] cache_line_valid;   // 8个cacheline，每个4路   
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

logic sfetch_miss, sfetch_miss_ns;//推测性访问icache
logic [31:0] fetch_r_data_cs, fetch_r_data_ns;

logic stream_hit_reg;
logic [18:0] next_line_addr;
// next_line_addr 地址就是当前core要取的cacheline的下一条line的地址
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
    // ns = cs 的作用是为了在下面没有改变输出的时候保持当前的值
    ns = cs;
    ram_addr_ns = ram_addr_cs;
    sfetch_miss_ns = sfetch_miss;
    fetch_r_data_ns = fetch_r_data_cs;      

    fetch_gnt = 'b0;
    fetch_r_valid = 'b0;
    fetch_r_data = 'b0;     //会导致中间有一些0，当下面没有进入到对应得状态去改变值的时候，这里会给0

    data_ram_addr = fetch_addr[8:2]; //fetch_addr按照Bytes，所以这里用data_ram_addr = [8:2]来寻址word
    tag_ram_addr = fetch_addr[8:6];  //tag是用来寻址set的，tag是 10bit: [18:9]，但是cacheline内部的tag只有8个，这是用来寻址的地址
    data_ram_in = icache_refill_r_data; //从L2取出的data 31:0
    tag_ram_in = fetch_addr_reg[18:9];//从

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
            else if(fetch_req) begin    //收到core的取指请求
                if(stream_busy) begin   //如果stream正在取指，那么就需要判断
					if(~sfetch_miss)begin   // 如果sfetch=0，说明仍在推测执行状态，没有miss(按照icache的下一条继续执行)，就只需要看icache即可       s 是 speculative  
                    	ns = ICACHE_COMPARE;    //此时进入到ICACHE的比较中，先不给gnt，因为如果miss，且icache会
                    	re = 4'hf;   //读使能 -> 启动sram读取，得到tag 和 data(instr)
					end
					else begin      // 如果 sfetch = 1，就说明在推测状态下miss，这时候就保持状态不变，继续检测
						ns = ICACHE;
					end
                end
                else begin          //stream没有正在预取
                    ns = BOTH_COMPARE;  //两个都需要比较
                    fetch_gnt = 1'b1;   //此时就可以直接gnt，因为icache已经确认接收到了req
					re = 4'hf;
                    sfetch_miss_ns = 1'b0;  //恢复为推测状态执行  //如果icache命中，那显然就是sfetch；ruguostream命中，会move到icache里面，所以也要sfetch。如果都miss，就要从L2搬到L1中，也是继续sfetch
                end
            end
        end
        // 推测状态执行：
        ICACHE_COMPARE: begin
            // tag_input = fetch_addr[18:9];   //取指的tag部分
            // cache_set_addr = fetch_addr[8:6];   //取指的set部分(4路组相联) ，icache一共有8个entry，所以是3bit 
            // 为了修正时序。fetch_addr_speculative_reg只有进入到ICACHE_COMPARE状态时才立刻更新，然后给到tag_input
            tag_input = fetch_addr_speculative_reg[18:9];
            cache_set_addr = fetch_addr_speculative_reg[8:6];   
            if(icache_hit) begin        
                plru_hit = 1'b1;
                ns = ICACHE_COMPARE_HIT;    
                fetch_gnt = 1'b1;   //如果icache hit, 就可以gnt了
			//	re = 4'hf;
                for(j = 0; j < 4 ; j = j + 1)begin
                    if(hit_state[j])    //选择cacheline中的1路输出
                    	fetch_r_data_ns = data_ram_out[j];      
                end
                // fetch_r_data_ns = ({32{hit_state[3]}} & data_ram_out[3]) | ({32{hit_state[2]}} & data_ram_out[2]) | ...;
            end
            else begin  //如果icache miss, 则返回ICACHE状态重新检测
                ns = ICACHE;
                sfetch_miss_ns = 1'b1;  // icache miss, 即 推测执行miss
            end
        end
        ICACHE_COMPARE_HIT: begin   //Core要求gnt要比valid和data早一拍输出，所以这里就是为了打拍
            fetch_r_valid = 1'b1;           //hit-> 返回valid
            fetch_r_data = fetch_r_data_cs; // data_cs = ns 在下面的always_ff里面

            if(fetch_req) begin        //这一步是为了能够流水起来，在读取出上一个数据之后，同一级流水，就去处理下一个请求。所以这部分逻辑跟之前一致，不过因为是icache命中的，所以肯定是在推测执行，就不需要sfetch的判断
				re = 4'hf;  //读使能
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
        // 流水优化：可以把ICACHE_COMPARE中的hit情况下，就开始处理下一个fetch_req
        // 然后在ICACHE_COMPARE_HIT，首先是把上一拍的vaild和data输出，然后再复制一份if(icache_hit) 的逻辑，之后就可以在ICACHE_COMPARE_HIT中进行自己跳转循环了。
        // 这种情况只有循环的时候，反复使用一个cacheline的时候才有用，不然还是会被取下一个cacheline的时候L1 到L2的访存时间给限制
        BOTH_COMPARE: begin
            fetch_stream_req = 1'b1;    //两个都要用到，所以要发送stream_req
            fetch_stream_addr = fetch_addr_reg; 
            if(icache_hit) begin      // TODO: 因为gnt已经上一拍给出了
                fetch_r_valid = 1'b1;//给出valid
                plru_hit = 1'b1;
                for(j = 0; j < 4 ; j = j + 1)begin
                    if(hit_state[j])
                    fetch_r_data = data_ram_out[j];
                end
                if(fetch_req) begin //为了流水起来，将下一拍的取指请求的处理压缩到了一起。
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
            // 但是如果stream hit了，就直接返回有效的数据，和valid信号
            // 而不管stream hit与否，都要用next_line_addr 从cache中取出下一个cacheline，然后比较tag是不是hit
            // 如果下一个hit了，就不用refill icache了。
            // 此时，再分析，如果stream hit，就真的不需要refill，而stream 也miss，就需要refill stream 而不需要stream icache

            else if(stream_hit) begin   //如果icache miss，但是stream hit
                fetch_r_valid = 1'b1;
                fetch_r_data = fetch_stream_r_data;
                ns = MISS_CHECK;
                ram_addr_ns = {fetch_addr_reg[18:6],6'b0};  // 

                data_ram_addr = next_line_addr[8:2];    
                tag_ram_addr = next_line_addr[8:6]; 
                re = 4'hf;
            end
            else begin  //如果都miss
                ns = MISS_CHECK;
                stream_miss = 1'b1;
                ram_addr_ns = {fetch_addr_reg[18:6],6'b0};

                data_ram_addr = next_line_addr[8:2];        //下一条指令的地址
                tag_ram_addr = next_line_addr[8:6];         //取icache中的tag所用的地址，下一拍取出来之后得到icache中的实际cacheline tag
                re = 4'hf;                                  //下一拍在misscheck的时候，用要取得next_line的addr和cacheline中实际的next_line addr比较
            end
        end
        MISS_CHECK: begin //检查下一个地址在不在当前的icache里面。比如可能是上一个小循环留下的。//检查的方式就是看下一个cacheline的内容
            tag_input = next_line_addr[18:9];   
            cache_set_addr =  next_line_addr[8:6];  
            if(stream_hit_reg) begin    //上一个状态的stream hit打一拍传递过来
                ns = ICACHE_STREAM_HIT;
                if(~icache_hit) begin   //如果icache没有命中，但是stream命中了，就把stream中的搬到icache中，然后icache refill
                    ctr_refill_req = 1'b1;      // refill都是从上一级cache中取
                    ctr_refill_lenth = 1'b0;    //一个cacheline
                    stream_fetch_valid = 1'b1;  //告诉stream buffer，要预取了
                end
            end
            else begin
                ns = ICACHE_MISS;   //stream和icache都miss，这时候就看下一条
                ctr_refill_req = 1'b1;
                ctr_refill_addr = {fetch_addr_reg[18:6],6'b0};// 低6bit是4路cacheline的地址
                if(icache_hit) begin        // 如果下一条是命中，就只需要取一条  //TODO: 这一条放到哪里
                    ctr_refill_lenth = 1'b0;
                    ctr_refill_mode = 1'b1;
                end
                else begin
                    ctr_refill_lenth = 1'b1;//否则取两条
                    stream_fetch_valid = 1'b1;  //都miss了，stream buffer需要预取  
                end
            end
        end
        ICACHE_MISS: begin
            // prefetch_r_valid = 1'b0;
            data_ram_addr = ram_addr_cs[8:2];   
            tag_ram_addr = ram_addr_cs[8:6];
            if(icache_refill_r_valid) begin     
                we = cache_line_miss_sel_reg;   //we是给每个控制cache中的8个entry，选择哪个entry miss了，就写到哪里
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
            fetch_r_valid = fetch_stream_r_valid;   //hit之后当拍给出valid

            // 从stream中搬数据到core中
            tag_ram_addr = ram_addr_cs[8:6];
            data_ram_addr = ram_addr_cs[8:2];
            if(stream_to_icache_valid) begin    // stream给icache发数据的valid
                we = cache_line_miss_sel_reg;   //选择要写入哪个entry  
                ram_addr_ns = ram_addr_cs + 4;  //单个word 地址递增，传16个周期
            end
            if(stream_move_done) begin      //只要没有move_done，就保持这个状态
                ns = ICACHE;
                plru_hit = 1'b1;
                plru_hit_index = cache_line_miss_sel_reg;
            end
        end
    endcase

	me = we | re;   //ram使能信号

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
    else if(fetch_gnt)  //只有fetchreq被gnt了之后，才会更新地址
        fetch_addr_reg <= fetch_addr;
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        fetch_addr_speculative_reg <= 'b0;
        //两组条件就是把分别在两个状态——ICACHE和ICACHE_COMPARE_HIT下，会进入到ICACHE_COMPARE状态的条件进行了提取
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
    for(k = 0; k < 4 ; k = k + 1)begin  //4路set组相联，所以对于同一个tag，要检查4组。检查10bit的tag匹配，并且 cacheline对应的路是valid
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
    else if((cs == BOTH_COMPARE) & (~hit | stream_hit))
        cache_line_miss_sel_reg <= cache_line_miss_sel;
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cache_line_miss_sel_reg <= 'b0;
    // else if((cs == BOTH_COMPARE) & (~hit | stream_hit))      // hit = icache_hit | stream_hit;    //如果BOTH_COMPARE，并且 没有hit或者只有stream_hit，此时需要选判断是哪个miss
    else if((cs == BOTH_COMPARE) & (~icache_hit))   // 只要     // TODO: 只要icache没有命中即就要更新
        cache_line_miss_sel_reg <= cache_line_miss_sel;
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cache_line_valid <= 'b0;
    else if((cs == ICACHE) & (icache_sleep_en | icache_sleep_en_reg))   //如果是在ICACHE状态，并且需要sleep，那么就全都invalid
        cache_line_valid <= 'b0;
    else if(((cs == ICACHE_MISS) & icache_refill_done) | ((cs == ICACHE_STREAM_HIT) & stream_move_done)) //如果MISS，并且refill完成，或者stream hit并且stream也move完成
        cache_line_valid[cache_set_addr] <= cache_line_valid[cache_set_addr] | cache_line_miss_sel_reg;// 等于自身或上miss之后选择的那个line
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

/***
cache bank(即1路set)的结构，tag sram只保存tag，而data sram只保存data部分
因为data_ram不是按照一行一个cacheline来设计的，而是按照一行一个word，
所以寻址的时候，为了找到同一个tag(即同一个cacheline)，需要用tag的3bit一起来选出其中16个相同tag的words，这就是一个cacheline
**/
genvar i;
generate
    for(i = 0; i < 4; i = i + 1) begin: pri_icache_sram_bank
        t22_s1pram128x32_wrapper U_pri_icache_data(
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
