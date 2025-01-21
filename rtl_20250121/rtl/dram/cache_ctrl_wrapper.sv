module cache_ctrl_wrapper(
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
    input                           dcache_refill_rvalid,
    input           [255:0]         dcache_refill_rdata,

    // pc_debug
    input                           sleep_en,
    output  logic                   debug_serial_out,
    output  logic                   debug_finish_status
);

// interface with pc_debug
logic               debug_enq_valid; 
logic               fetch_en_reg;

// only sleep can invalid fetch_en_reg
always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        fetch_en_reg <= 'b0;
    end
    else if(sleep_en) begin
        fetch_en_reg <= 'b0;
    end
    else if(fetch_en & ~ fetch_en_reg) begin
        fetch_en_reg <= 'b1;
    end
end

assign debug_enq_valid = (fetch_en | fetch_en_reg) && (fetch_req && (fetch_addr == h'0000))

pc_debug U_pc_debug(
    .clk                    (clk),
    .rst_n                  (rst_n),

    //interface with core
    .debug_enq_valid        (debug_enq_valid),
    .debug_w_data           (fetch_w_data),

    .sleep                  (sleep_en),
    .debug_serial_out       (debug_serial_out),
    .finish_status          (debug_finish_status)
);

dcache_ctrl U_dcache_ctrl(
    .clk            (clk),
    .rst_n          (rst_n),

    //interface with core
    .fetch_req      (fetch_req),
    .fetch_we       (fetch_we),
    .fetch_gnt      (fetch_gnt),
    .fetch_addr     (fetch_addr),
    .fetch_r_data   (fetch_r_data),
    .fetch_r_valid  (fetch_r_valid),
    .fetch_w_data   (fetch_w_data),

    .flush_req      (flush_req),
    .flush_gnt      (flush_gnt),
    .flush_ok       (flush_ok),

    //interface with Tcache
    .wen            (wen),
    .wdata          (wdata),
    .addr_w         (addr_w),
    .addr_r         (addr_r),
    .ren            (ren),
    .rdata          (rdata),

    //interface with LB
    .dcache_refill_req           (dcache_refill_req),
    .dcache_refill_gnt           (dcache_refill_gnt),
    .dcache_refill_we            (dcache_refill_we),
    .dcache_refill_addr          (dcache_refill_addr),
    .dcache_refill_addr_valid    (dcache_refill_addr_valid),
    .dcache_refill_addr_ready    (dcache_refill_addr_ready),
    .dcache_refill_wvalid        (dcache_refill_wvalid),
    .dcache_refill_wdata         (dcache_refill_wdata),
    .dcache_refill_rvalid        (dcache_refill_rvalid),
    .dcache_refill_rdata         (dcache_refill_rdata)
);


endmodule