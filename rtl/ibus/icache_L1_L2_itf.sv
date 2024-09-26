module icache_L1_L2_itf(

    input                   clk,

    input                   rst_n,



    // input                   core_cmd_itf_req,

    // output  logic           core_cmd_itf_gnt,

    // output  logic           core_cmd_ok,

    // input                   core_cmd_task_done,

    input                   c_cfg_itf_single_fetch,

    input                   core_sleep_irq_pulse,

    input                   c_cfg_itf_irq_en,





    //pri cache interface

    input                   pri_cache_refill_req,

    output  logic           pri_cache_refill_gnt,

    input           [18:0]  pri_cache_refill_addr,

    input                   pri_cache_refill_lenth,

    output  logic           pri_cache_refill_r_valid,

    output  logic   [31:0]  pri_cache_refill_r_data,



    input                   refill_done,

    output  logic           icache_work_en,

    output  logic           icache_sleep_en, //soft rst

    output  logic           icache_lowpower_en,

    output  logic           core_wakeup_irq,

    output  logic   [31:0]  boot_addr_i,

    output  logic           core_rst_n,



    //to cu core

    output  logic   [31:0]  fetch_L2cache_info,

    output  logic           fetch_L2cache_req,

    input                   fetch_L2cache_gnt,

    input   [31:0]          fetch_L2cache_r_data,

    input                   fetch_L2cache_r_valid,

    output  logic           fetch_L2cache_r_ready



);



    localparam SLEEP    = 2'd0;

    localparam IDLE     = 2'd1;

    localparam MISS     = 2'd2;

    localparam RESET    = 2'd3;



    // localparam WAKEUP   = 3'd2;

    // localparam WAIT_FIRST = 3'b001;

    // localparam FIRST_FETCH = 3'b010;



    // localparam IRQ = 3'b101;



    logic [18:0] first_cache_addr;

    // logic [4:0] fetch_lenth, fetch_cnt;

    logic sleep_irq_reg;

    logic core_enter_irq_pulse;

    logic soft_rst_n;



    logic [1:0] cs, ns;



    always_comb begin

        ns = cs;

        // core_cmd_itf_gnt = 1'b0;

        // core_cmd_ok = 1'b0;

        pri_cache_refill_gnt = 1'b0;

        pri_cache_refill_r_valid = 1'b0;

        pri_cache_refill_r_data = 'b0;

        fetch_L2cache_info = 'b0;

        fetch_L2cache_req = 'b0;

        fetch_L2cache_r_ready = 1'b1;

        core_wakeup_irq = 1'b0;

        soft_rst_n = 1'b1;

        case(cs)

        SLEEP: begin

            // if(fetch_L2cache_r_valid & fetch_L2cache_r_data[19]) begin

            if(fetch_L2cache_r_valid) begin

                // if(core_rst_n) begin
                //     ns = RESET;
                // end
                // else begin
                //     ns = WAKEUP;
                // end

                ns = IDLE;

            end

        end

        // WAKEUP: begin

        //     ns = IDLE;

        //     core_wakeup_irq = 1'b1;

        //     fetch_L2cache_r_ready = 1'b0;

        // end

        IDLE: begin

            if(core_enter_irq_pulse | sleep_irq_reg) begin

                fetch_L2cache_req = 1'b1;

                fetch_L2cache_info = {1'b1,31'b0};



                // core_cmd_itf_gnt = fetch_L2cache_gnt;

                // core_cmd_ok = fetch_L2cache_gnt;



                if(fetch_L2cache_gnt) begin

                    ns = SLEEP;

                end

            end

            else if(pri_cache_refill_req) begin

                pri_cache_refill_gnt = fetch_L2cache_gnt;

                pri_cache_refill_r_valid = fetch_L2cache_r_valid;

                pri_cache_refill_r_data = fetch_L2cache_r_data;



                fetch_L2cache_req = pri_cache_refill_req;

                fetch_L2cache_info = {11'b0, c_cfg_itf_single_fetch, pri_cache_refill_lenth, pri_cache_refill_addr};

                if(pri_cache_refill_gnt) begin

                    ns = MISS;

                end

            end

        end

        MISS: begin

            pri_cache_refill_r_valid = fetch_L2cache_r_valid;

            pri_cache_refill_r_data = fetch_L2cache_r_data;



            if(refill_done) begin

                ns = IDLE;

            end

        end

        RESET: begin

            ns = SLEEP;

            soft_rst_n = 1'b0;

            fetch_L2cache_r_ready = 1'b0;

        end

        endcase

    end



    always_ff @(posedge clk or negedge rst_n) begin

    if(!rst_n)begin

        cs <= SLEEP;

    end

    else

        cs <= ns;

    end



    always_ff @(posedge clk or negedge rst_n) begin

    if(!rst_n)begin

        first_cache_addr <= 'b0;

    end

    // else if(cs == RESET)

    //     first_cache_addr <= 'b0;

    else if((cs == SLEEP) & fetch_L2cache_r_valid)

        first_cache_addr <= fetch_L2cache_r_data[18:0];

    end



    assign boot_addr_i = {13'd0,first_cache_addr};



    always_ff @(posedge clk or negedge rst_n) begin

    if(!rst_n)begin

        icache_work_en <= 'b0;

    end

    // else if((cs == SLEEP) & fetch_L2cache_r_valid)

    //     icache_work_en <= fetch_L2cache_r_data[19];

    else if((cs == SLEEP) & fetch_L2cache_r_valid)

        icache_work_en <= 1'b1;

    else if((cs == IDLE) & (core_enter_irq_pulse | sleep_irq_reg))

        icache_work_en <= 'b0;

    end



    assign icache_sleep_en = 1'b0;

    assign icache_lowpower_en = core_enter_irq_pulse;



    always_ff @(posedge clk or negedge rst_n) begin

    if(!rst_n)begin

        sleep_irq_reg <= 'b0;

    end

    else if((cs == IDLE) & (core_enter_irq_pulse | sleep_irq_reg) & fetch_L2cache_gnt)

        sleep_irq_reg <= 'b0;

    else if(core_enter_irq_pulse)

        sleep_irq_reg <= 1'b1;

    end



    assign core_rst_n = soft_rst_n & rst_n;



    assign core_enter_irq_pulse = core_sleep_irq_pulse & c_cfg_itf_irq_en;

endmodule