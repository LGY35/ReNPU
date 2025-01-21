module axi_data_fifo_sync_256b #(
    parameter FIFO_WIDTH = 288 ,     //FIFO_WIDTH=256+32
    parameter FIFO_DEPTH = 64  ,    
    parameter FIFO_CNT_WID = 6+1    //ceil[log2 (FIFO_DEPTH) + 1]
    )(
    input                           clk                  ,
    input                           rst_n                ,
    input                           data_fifo_pop        ,
    output                          data_fifo_valid      ,
    output     [FIFO_WIDTH-1: 0]    data_fifo_data_out   ,
    output                          data_fifo_empty      ,
    input                           data_fifo_push       ,
    output                          data_fifo_full       ,
    output                          data_fifo_afull      ,
    input      [FIFO_WIDTH-1: 0]    data_fifo_data_in    ,
    output reg [FIFO_CNT_WID-1:0]   data_fifo_word_cnt   ,
    input                           data_fifo_init
   );

wire                            fifo_push_en;
wire                            fifo_pop_en;
wire                            sram_re;
wire                            sram_we;
wire       [FIFO_WIDTH-1: 0]    sram_wdata;
wire                            we_n;      // Source  write enable to RAM
wire                            re_n;      // Source  read  enable to RAM
wire   [FIFO_CNT_WID-2:0]       wr_addr;   // Source  write address to RAM
wire   [FIFO_CNT_WID-2:0]       rd_addr;   // read address to RAM
wire   [FIFO_WIDTH-1: 0]        rd_data;   // read data from RAM

assign fifo_push_en = !data_fifo_full  && data_fifo_push;
// assign fifo_pop_en  = !data_fifo_empty && data_fifo_pop;
assign fifo_pop_en  = data_fifo_pop;
assign we_n = !sram_we;
assign re_n = !sram_re;

//==================================================
// fifo ctrl
//==================================================
fifo_sync_tpsram#(
    .FIFO_WIDTH     ( FIFO_WIDTH ),
    .FIFO_DEPTH     ( FIFO_DEPTH ),
    .FIFO_CNT_WID   ( FIFO_CNT_WID )
)u_fifo_sync_tpsram(
    .clk            ( clk            ),
    .rst_n          ( rst_n          ),
    .fifo_pop       ( fifo_pop_en         ),
    .fifo_valid     ( data_fifo_valid     ),
    .fifo_data_out  ( data_fifo_data_out  ),
    .fifo_empty     ( data_fifo_empty     ),
    .fifo_push      ( fifo_push_en        ),
    .fifo_full      ( data_fifo_full      ),
    .fifo_afull     ( data_fifo_afull     ),
    .fifo_data_in   ( data_fifo_data_in   ),
    .fifo_word_cnt  ( data_fifo_word_cnt  ),
    .fifo_init      ( data_fifo_init      ),
    .sram_re        ( sram_re        ),
    .sram_we        ( sram_we        ),
    .sram_raddr     ( rd_addr        ),
    .sram_waddr     ( wr_addr        ),
    .sram_wdata     ( sram_wdata     ),
    .sram_rdata     ( rd_data      )
);



//==================================================
// ram 64x144 *1
//==================================================

std_tpram64x288
    i1_std_tpram64x288(
        .RCLK    (clk      ),
        .RADDR   (rd_addr  ),
        .RCEB    (re_n     ),
        .RDATA   (rd_data  ),
        .WCLK    (clk      ),
        .WADDR   (wr_addr  ),
        .WCEB    (we_n     ),
        .WDATA   (sram_wdata )); 

endmodule
