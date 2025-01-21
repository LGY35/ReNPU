module tb_fifo_sync_sram();

parameter FIFO_WIDTH = 64 ;
parameter FIFO_DEPTH = 64  ;    
parameter FIFO_CNT_WID = 6+1;

logic clk, rst_n;
logic                     fifo_pop        ;
logic[FIFO_WIDTH-1: 0]    fifo_data_out   ;
logic                     fifo_empty      ;
logic                     fifo_push       ;
logic                     fifo_full       ;
logic                     fifo_afull      ;
logic[FIFO_WIDTH-1: 0]    fifo_data_in    ;
logic[FIFO_CNT_WID-1:0]   fifo_word_cnt   ;
logic                     fifo_init       ;
logic                     sram_re         ;
logic                     sram_we         ;
logic[FIFO_CNT_WID-2: 0]  sram_raddr      ;
logic[FIFO_CNT_WID-2: 0]  sram_waddr      ;
logic[FIFO_WIDTH-1: 0]    sram_wdata      ;
logic[FIFO_WIDTH-1: 0]    sram_rdata      ;

// ========================== sram =============================	 
reg [63:0] sram_sim [63:0];
always @(posedge clk) begin
    if(sram_we) begin
        sram_sim[sram_waddr] <= sram_wdata;
    end
end
always @(posedge clk) begin
    if(sram_re)
        sram_rdata <= sram_sim[sram_raddr];
end

// ========================== clk and reset =============================	 
initial begin
  clk = 1'b0;  
  # 50;
  forever begin
    #1
    clk = ~clk;
  end
end
initial begin
  rst_n = 1'b0;
  #50
  rst_n = 1'b1;
end

// ========================== Time out =============================
initial begin
  #2000
  $display("\n============== TimeOut ! Simulation finish ! ============\n");
  $finish;
end

// ============================== dump fsdb =============================
initial begin
	$display("\n================== Time:%d, Dump Start ================\n",$time);
	$fsdbDumpfile("tb_fifo_sync_sram.fsdb");
  $fsdbDumpvars("+all");
end

// ===============================
// assign fifo_push = !fifo_full;
initial begin
    fifo_push = 1'b0;
    # 50
    fifo_push = 1'b1;
    # 200
    fifo_push = 1'b0;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        fifo_data_in <= 64'b0;
    end
    else if(fifo_push && !fifo_full) begin
        fifo_data_in <= fifo_data_in + 1;
    end
end

// assign fifo_pop = 1'b1;
assign fifo_pop = !fifo_empty;
// initial begin
//     fifo_pop = 1'b0;
//     # 100
//     fifo_pop = 1'b1;
//     // forever begin
//     //     repeat(3) @(posedge clk);
//     //     fifo_pop <= 1'b1;
//     //     @(posedge clk);
//     //     fifo_pop <= 1'b0;
//     // end
// end

always@(posedge clk or negedge rst_n) begin
    // if(fifo_push && !fifo_full) begin
    //     $display("push data: %h ", fifo_data_in);
    // end
    if(fifo_pop && !fifo_empty) begin
        $display("data out: %h ", fifo_data_out);
    end
end


fifo_sync_sram #(
    .FIFO_WIDTH   (64),
    .FIFO_DEPTH   (64), 
    .FIFO_CNT_WID (6+1)
) u_fifo_sync_sram(
    .clk          (clk          )   ,
    .rst_n        (rst_n        )   ,
    .fifo_pop     (fifo_pop     )   ,
    .fifo_data_out(fifo_data_out)   ,
    .fifo_empty   (fifo_empty   )   ,
    .fifo_push    (fifo_push    )   ,
    .fifo_full    (fifo_full    )   ,
    .fifo_afull   (fifo_afull   )   ,
    .fifo_data_in (fifo_data_in )   ,
    .fifo_word_cnt(fifo_word_cnt)   ,
    .fifo_init    (fifo_init    )   ,
    .sram_re      (sram_re      )   ,
    .sram_we      (sram_we      )   ,
    .sram_raddr   (sram_raddr   )   ,
    .sram_waddr   (sram_waddr   )   ,
    .sram_wdata   (sram_wdata   )   ,
    .sram_rdata   (sram_rdata   )
);

endmodule