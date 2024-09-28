module icache_refill_ctr(

    input                   clk,

    input                   rst_n,



    input                   icache_work_en,

    input                   icache_sleep_en,



    input                   ctr_refill_req,

    input           [18:0]  ctr_refill_addr,

    input                   ctr_refill_lenth,

    input                   ctr_refill_mode,



    output  logic           icache_refill_r_valid,

    output  logic   [31:0]  icache_refill_r_data,

    output  logic           icache_refill_done,



    // 与stream buffer的接口
    output  logic           prefetch_r_valid,

    output  logic   [31:0]  prefetch_r_data,

    // output  logic           stream_buffer_refill_done,


    // 与pri_icache的接口
    output  logic           pri_cache_refill_req,

    input                   pri_cache_refill_gnt,

    output  logic   [18:0]  pri_cache_refill_addr,

    output  logic           pri_cache_refill_lenth,

    input                   pri_cache_refill_r_valid,

    input           [31:0]  pri_cache_refill_r_data,

    output  logic           refill_done





);



localparam SLEEP = 3'b000;

localparam IDLE = 3'b010;

localparam WAIT = 3'b011;

localparam STREAM_MISS = 3'b100;

localparam ICACHE_MISS = 3'b101;

localparam BOTH_MISS = 3'b110;



logic [2:0] cs, ns;

// logic [4:0] transfer_lenth, transfer_lenth_ns;

logic [3:0] transfer_cnt, transfer_cnt_ns;

logic [18:0] ctr_refill_addr_reg, ctr_refill_addr_ns;

logic ctr_refill_req_reg, ctr_refill_req_ns;

logic ctr_refill_lenth_reg, ctr_refill_lenth_ns;

logic ctr_refill_mode_reg, ctr_refill_mode_ns;

logic icache_sleep_en_reg;



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

    transfer_cnt_ns = transfer_cnt;

    // transfer_lenth_ns = transfer_lenth;



    ctr_refill_req_ns = ctr_refill_req_reg;

    ctr_refill_lenth_ns = ctr_refill_lenth_reg;

    ctr_refill_mode_ns = ctr_refill_mode_reg;

    ctr_refill_addr_ns = ctr_refill_addr_reg;



    pri_cache_refill_req = ctr_refill_req;

    pri_cache_refill_addr = ctr_refill_addr;

    pri_cache_refill_lenth = ctr_refill_lenth;



    icache_refill_r_data = pri_cache_refill_r_data;

    icache_refill_r_valid = 'b0;

    icache_refill_done = 'b0;



    prefetch_r_valid = 'b0;

    prefetch_r_data = pri_cache_refill_r_data;

    // stream_buffer_refill_done = 'b0;



	refill_done = 1'b0;



    case(cs)

        SLEEP: begin
            if(icache_work_en) begin
                ns = IDLE;
            end
        end

        IDLE: begin
            if(icache_sleep_en | icache_sleep_en_reg)
                ns = SLEEP;
            else if(ctr_refill_req) begin
                transfer_cnt_ns = 4'h0;
                // transfer_lenth_ns = 4'hf;
                // L1_L2_itf 给出了gnt
                if(pri_cache_refill_gnt) begin
                    //如果是1，就给icache和streambuffer都预取
                    if(ctr_refill_lenth) begin
                        ns = BOTH_MISS;
                    end
                    else begin
                        // mode=1是给icache，mode=0是给streambuffer
                        if(ctr_refill_mode) begin
                            ns = ICACHE_MISS;
                        end
                        else begin
                            ns = STREAM_MISS;
                        end
                    end
                end

                else begin //没有gnt就进入wait
                    ns = WAIT;
                    //把信号保存
                    ctr_refill_req_ns = ctr_refill_req;
                    ctr_refill_lenth_ns = ctr_refill_lenth;
                    ctr_refill_mode_ns = ctr_refill_mode;
                    ctr_refill_addr_ns = ctr_refill_addr;
                end
            end
        end
        
        WAIT: begin
            pri_cache_refill_req = ctr_refill_req_reg;
            pri_cache_refill_addr = ctr_refill_addr_reg;
            pri_cache_refill_lenth = ctr_refill_lenth_reg;
            if(pri_cache_refill_gnt) begin
                ctr_refill_req_ns = 1'b0;
                if(ctr_refill_lenth_reg) begin
                    ns = BOTH_MISS;
                end
                else begin
                    if(ctr_refill_mode_reg) begin
                        ns = ICACHE_MISS;
                    end
                    else begin
                        ns = STREAM_MISS;
                    end
                end
            end
        end

        BOTH_MISS: begin

            icache_refill_r_valid = pri_cache_refill_r_valid;

            if(pri_cache_refill_r_valid) begin

                if(transfer_cnt == 4'hf) begin

                    transfer_cnt_ns = 'b0;

                    ns = STREAM_MISS;

                    icache_refill_done = 1'b1;

                end

                else begin

                    transfer_cnt_ns = transfer_cnt + 1'b1;

                end

            end

        end

        ICACHE_MISS: begin

            icache_refill_r_valid = pri_cache_refill_r_valid;

            if(pri_cache_refill_r_valid) begin

                if(transfer_cnt == 4'hf) begin

                    transfer_cnt_ns = 'b0;

                    ns = IDLE;

                    icache_refill_done = 1'b1;

                    refill_done = 1'b1;

                end

                else begin

                    transfer_cnt_ns = transfer_cnt + 1'b1;

                end

            end

        end

        STREAM_MISS: begin

            prefetch_r_valid = pri_cache_refill_r_valid;

            if(pri_cache_refill_r_valid) begin

                if(transfer_cnt == 4'hf) begin

                    transfer_cnt_ns = 'b0;

                    ns = IDLE;

                    // stream_buffer_refill_done = 1'b1;

                    refill_done = 1'b1;

                end

                else begin

                    transfer_cnt_ns = transfer_cnt + 1'b1;

                end

            end

        end

    endcase

end



always_ff @(posedge clk or negedge rst_n) begin

    if(!rst_n) begin

        cs <= SLEEP;

        transfer_cnt <= 'b0;

        // transfer_lenth <= 'b0;

        ctr_refill_req_reg <= 'b0;

       	ctr_refill_lenth_reg <= 'b0;

        ctr_refill_mode_reg <= 'b0;

        ctr_refill_addr_reg <= 'b0;

    end

    else begin

        cs <= ns;

        transfer_cnt <= transfer_cnt_ns;

        // transfer_lenth <= transfer_lenth_ns;

        ctr_refill_req_reg <= ctr_refill_req_ns;

        ctr_refill_lenth_reg <= ctr_refill_lenth_ns;

        ctr_refill_mode_reg <= ctr_refill_mode_ns;

        ctr_refill_addr_reg <= ctr_refill_addr_ns;

    end

end



endmodule

