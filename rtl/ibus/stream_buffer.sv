


//TODO: 如果没有icache miss，stream怎么变？

module stream_buffer(

    input                   clk,

    input                   rst_n,
    // fetch_stream_req 会连接到core，当streamhit的时候，一边向core搬运数据，一边向icache中也搬运数据
    input                   fetch_stream_req,
    input           [18:0]  fetch_stream_addr,  //预取的地址
    input           [18:0]  fetch_stream_addr_reg, //both compare
    output  logic           fetch_stream_gnt,
    output  logic           fetch_stream_r_valid,
    output  logic   [31:0]  fetch_stream_r_data,

    output  logic           stream_to_icache_valid,
    output  logic   [31:0]  stream_to_icache_data,
    
    // 从L2取出来的数据
    input                   prefetch_r_valid,
    input           [31:0]  prefetch_r_data,

    // output  logic   [18:0]  prefetch_addr,

    // output  logic           prefetch_req,

    // input                   prefetch_gnt,

    input                   icache_work_en,
    input                   icache_sleep_en,
    input                   stream_fetch_valid,
    input                   stream_miss,
    output  logic           stream_busy,
    output  logic           stream_move_done,
    output  logic           stream_hit

);

localparam SLEEP = 3'b000;
localparam IDLE = 3'b001;
localparam FETCH_CHECK = 3'b010;
localparam STREAM_MOVE = 3'b011;
// localparam STREAM_MOVE_WAIT = 3'b100;
localparam STREAM_MOVE_HIT = 3'b101;

//TODO: set怎么显示？
logic [15:0][31:0] stream_buffer;   //每个buffer里面存了16个words，即1个cacheline

logic [12:0] stream_buffer_addr;    // tag + entry(即3bit代表8个cacheline) 

logic [3:0] hit_index;

logic [3:0] move_hit_index, move_hit_index_ns;

logic stream_hit_reg;

logic stream_move_hit, stream_move_hit_reg;

logic stream_refilling;

logic stream_moving;

logic sfetch_miss, sfetch_miss_ns;

logic refill_done;

logic stream_buffer_valid;

logic [12:0] line_addr_cut;

// logic [31:0] stream_move_hit_data_reg

// logic []


logic [15:0][31:0] prefetch_buffer;

logic [12:0] prefetch_buffer_addr, prefetch_buffer_addr_ns; //////////////////////////////////

logic [3:0] stream_move_cnt, stream_move_cnt_ns;

logic [3:0] stream_refill_cnt;


logic icache_sleep_en_reg;

logic [2:0] cs, ns;


always_ff @(posedge clk or negedge rst_n) begin

    if(!rst_n) begin
        icache_sleep_en_reg <= 'b0;
    end
    else if((cs == IDLE) & (icache_sleep_en | icache_sleep_en_reg)) begin
        icache_sleep_en_reg <= 'b0;
    end

    else if(icache_sleep_en) begin
        icache_sleep_en_reg <= icache_sleep_en;
    end

end



always_comb begin

    ns = cs;

    stream_move_cnt_ns = stream_move_cnt;

    // stream_refill_cnt_ns = stream_refill_cnt;

    sfetch_miss_ns = sfetch_miss;
    prefetch_buffer_addr_ns = prefetch_buffer_addr;

    // stream_hit = 1'b0;
    // stream_hit = (stream_buffer_addr == fetch_stream_addr[18:6]) & stream_buffer_valid;
    stream_hit = (stream_buffer_addr == fetch_stream_addr_reg[18:6]) & stream_buffer_valid;
    stream_move_hit = 1'b0;

    stream_moving = 1'b1;
    stream_move_done = 1'b0;

    stream_to_icache_valid = 1'b0;
    stream_to_icache_data = stream_buffer[stream_move_cnt];

    fetch_stream_r_valid = 'b0;
    // hit_index = fetch_stream_addr[5:2];
    hit_index = fetch_stream_addr_reg[5:2];

    move_hit_index_ns = move_hit_index;
    fetch_stream_r_data = stream_buffer[hit_index];
    fetch_stream_gnt = 'b0;

    // line_addr_cut = fetch_stream_addr[18:6];

    case(cs)
        SLEEP: begin
            stream_moving = 1'b0;
            if(icache_work_en) begin
                ns = IDLE;
            end
        end

        IDLE: begin
            stream_moving = 1'b0;
            if(icache_sleep_en | icache_sleep_en_reg)
                ns = SLEEP;
                // BOTH_COMPARE 时，或者 ICACHE_STREAM_HIT
            else if(fetch_stream_req) begin
                // stream_hit = (stream_buffer_addr == fetch_stream_addr[18:6]) & stream_buffer_valid;  // 在上面直接赋值了  // req 环路 会把req加入判断
                if(stream_hit) begin
                    // prefetch_buffer_addr_ns = (line_addr_cut + 1'b1);
                    ns = FETCH_CHECK;
                    // fetch_stream_r_valid = 1'b1;    //hit之后就给出valid信号      //TODO: 回环??
                end
                else if(stream_miss) begin
                    // prefetch_buffer_addr_ns = line_addr_cut;
                    ns = FETCH_CHECK;
                end
            end
        end

        // TODO: 是为了与pri_icache中时序对齐所以多打了一拍，这一拍没有做太多事情
        FETCH_CHECK: begin  
		    stream_moving = 1'b0;
            //stream_fetch_valid之后就需要预取了
            if(stream_fetch_valid) begin    
                // 下一个cacheline的地址
                prefetch_buffer_addr_ns = (line_addr_cut + 1'b1); //加1就代表一个cacheline
                if(stream_hit_reg)begin
                    // stream hit之后就可以开始move了
                    ns = STREAM_MOVE;
                    // stream_move_cnt_ns = 'b0; 
                end
                else begin
                    ns = IDLE;
                end
            end
            else begin
                ns = IDLE;
            end

        end

        // MOVE是从stream buffer向ICACHE搬运数据
        STREAM_MOVE: begin
            stream_to_icache_valid = 1'b1;
            // 在0-14的时候，这前15个每个周期都会处理上级的fetch_stream_req，而15的时候，也就是第16个周期如果也处理上级的req，
            // 就需要再延迟一拍才能完成操作，就需要再打一拍才能完成。所以这一拍不处理，而先返回，然后再有pri icache处理req
            if(stream_move_cnt == 4'hf)begin    //需要搬16次    
                stream_move_cnt_ns = 'b0;
                ns = IDLE;
                stream_move_done = 1'b1;
                sfetch_miss_ns = 1'b0;  //恢复推测预取
            end

            else begin
                stream_move_cnt_ns = stream_move_cnt + 1'b1;
                //只有req有效，并且恢复推测执行的时候，才会计数继续加
                if(fetch_stream_req & ~sfetch_miss) begin
                    //move hit
                    stream_move_hit = (stream_buffer_addr == fetch_stream_addr[18:6]);
                    if(stream_move_hit) begin
                        //TODO: 这里的gnt逻辑是什么，与valid的关系？
                        fetch_stream_gnt = 1'b1;
                        move_hit_index_ns = fetch_stream_addr[5:2];
                    end
                    else begin
                        // ns = STREAM_MOVE_WAIT;
                        sfetch_miss_ns = 1'b1;
                    end
                end
            end
            if(stream_move_hit_reg)begin
                fetch_stream_r_valid = 1'b1;
                fetch_stream_r_data = stream_buffer[move_hit_index];
            end
        end
    endcase

    // 要写在最后，因为stream_refilling 和 stream_moving可能会在前面被更新
	stream_busy = stream_refilling | stream_moving; // refill 启动由状态机； 

end


always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        stream_hit_reg <= 'b0;
    else
        stream_hit_reg <= stream_hit;
end


always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        stream_move_hit_reg <= 'b0;
    else
        stream_move_hit_reg <= stream_move_hit;
end


always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cs <= SLEEP;
        stream_move_cnt <= 'b0;
        sfetch_miss <= 'b0;
        move_hit_index <= 'b0;
        prefetch_buffer_addr <= 'b0;
    end

    else begin
        cs <= ns;
        stream_move_cnt <= stream_move_cnt_ns;
        sfetch_miss <= sfetch_miss_ns;
        move_hit_index <= move_hit_index_ns;
        prefetch_buffer_addr <= prefetch_buffer_addr_ns;
    end
end


always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        refill_done <= 'b0;
    // 完成refill时，复位
    else if((((stream_refill_cnt == 4'hf) & prefetch_r_valid) | refill_done) & stream_refilling & ~stream_moving)
        refill_done <= 'b0;
    //
    else if((stream_refill_cnt == 4'hf) & prefetch_r_valid & stream_refilling)
        refill_done <= 'b1;
end


always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        stream_refilling <= 'b0;
    else if((((stream_refill_cnt == 4'hf) & prefetch_r_valid) | refill_done) & stream_refilling & ~stream_moving)
        stream_refilling <= 'b0;
    else if((cs == FETCH_CHECK) & stream_fetch_valid)
        stream_refilling <= 1'b1;
end


always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        stream_refill_cnt <= 'b0;
    else if((stream_refill_cnt == 4'hf) & prefetch_r_valid & stream_refilling)
        stream_refill_cnt <= 'b0;
    else if(prefetch_r_valid & stream_refilling)
        stream_refill_cnt <= stream_refill_cnt + 1'b1;
end


always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        prefetch_buffer <= 'b0;
    else if(prefetch_r_valid & stream_refilling)
        prefetch_buffer[stream_refill_cnt] <= prefetch_r_data;
end


always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        stream_buffer <= 'b0;
        stream_buffer_addr <= 'b0;
    end
    // prefetch完之后，把预取的数据一次性给出
    else if((((stream_refill_cnt == 4'hf) & prefetch_r_valid) | refill_done) & stream_refilling & ~stream_moving) begin
        stream_buffer <= prefetch_buffer;
        stream_buffer_addr <= prefetch_buffer_addr;
    end
end


always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        stream_buffer_valid <= 'b0;
    end
    else if((cs == IDLE) & (icache_sleep_en | icache_sleep_en_reg))
        stream_buffer_valid <= 'b0;
    // 当正在refilling 最后
    else if((((stream_refill_cnt == 4'hf) & prefetch_r_valid) | refill_done) & stream_refilling & ~stream_moving) begin
        stream_buffer_valid <= 1'b1;
    end
end


always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        line_addr_cut <= 'b0;
    else if((cs == IDLE) & fetch_stream_req)    //如果IDLE状态收到了req，就接收预取的cacheline的地址
        // line_addr_cut <= fetch_stream_addr[18:6];   //
        line_addr_cut <= fetch_stream_addr_reg[18:6];
end

endmodule

