module axi_addr_fifo_sync   #(
        parameter FIFO_WIDTH = 64   ,  
        parameter FIFO_DEPTH = 32   ,     
        parameter FIFO_CNT_WID = 5+1    //  ceil[log2 (FIFO_DEPTH) + 1]
      )(
        input                           clk                    ,
        input                           rst_n                  ,
        input                           addr_fifo_pop          ,
        output     [FIFO_WIDTH-1: 0]    addr_fifo_data_out     , 
        output                          addr_fifo_empty        ,
        input                           addr_fifo_push         ,
        output                          addr_fifo_full         ,
        output                          addr_fifo_afull        ,
        input      [FIFO_WIDTH-1: 0]    addr_fifo_data_in      ,
        input                           addr_fifo_init         ,
        output     [FIFO_CNT_WID-1:0]   addr_fifo_word_cnt
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

assign fifo_push_en = !addr_fifo_full  && addr_fifo_push;
assign fifo_pop_en  = !addr_fifo_empty && addr_fifo_pop;
assign we_n = !sram_we;
assign re_n = !sram_re;

//==================================================
// fifo ctrl
//==================================================
fifo_sync_sram#(
    .FIFO_WIDTH     ( FIFO_WIDTH ),
    .FIFO_DEPTH     ( FIFO_DEPTH ),
    .FIFO_CNT_WID   ( FIFO_CNT_WID )
)u_fifo_sync_sram(
    .clk            ( clk            ),
    .rst_n          ( rst_n          ),
    .fifo_pop       ( fifo_pop_en         ),
    .fifo_data_out  ( addr_fifo_data_out  ),
    .fifo_empty     ( addr_fifo_empty     ),
    .fifo_push      ( fifo_push_en        ),
    .fifo_full      ( addr_fifo_full      ),
    .fifo_afull     ( addr_fifo_afull     ),
    .fifo_data_in   ( addr_fifo_data_in   ),
    .fifo_word_cnt  ( addr_fifo_word_cnt  ),
    .fifo_init      ( addr_fifo_init      ),
    .sram_re        ( sram_re        ),
    .sram_we        ( sram_we        ),
    .sram_raddr     ( rd_addr        ),
    .sram_waddr     ( wr_addr        ),
    .sram_wdata     ( sram_wdata     ),
    .sram_rdata     ( rd_data        )
);
//==================================================
// ram 32x32
//==================================================

std_tpram32x32
    i_std_tpram32x32_rlen(
        .RCLK    (clk      ),
        .RADDR   (rd_addr  ),
        .RCEB    (re_n ),
        .RDATA   (rd_data[FIFO_WIDTH/2-1:0]  ),
        .WCLK    (clk       ),
        .WADDR   (wr_addr  ),
        .WCEB    (we_n     ),
        .WDATA   (sram_wdata[FIFO_WIDTH/2-1:0] ));

std_tpram32x32
    i_std_tpram32x32_raddr(
        .RCLK    (clk       ),
        .RADDR   (rd_addr  ),
        .RCEB    (re_n ),
        .RDATA   (rd_data[FIFO_WIDTH-1: FIFO_WIDTH/2]  ),
        .WCLK    (clk        ),
        .WADDR   (wr_addr  ),
        .WCEB    (we_n  ),
        .WDATA   (sram_wdata[FIFO_WIDTH-1: FIFO_WIDTH/2] ));

endmodule
