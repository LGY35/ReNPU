module axi_addr_fifo   #(
        parameter FIFO_WIDTH = 64   ,  
        parameter FIFO_DEPTH = 32   ,     
        parameter FIFO_CNT_WID = 6    //  ceil[log2 (FIFO_DEPTH) + 1]
      )(
        input                           clk_s                   ,
        input                           rstn_s                  ,
        input                           clk_d                   ,
        input                           rstn_d                  ,
        input                           addr_fifo_pop_d        ,
        output     [FIFO_WIDTH-1: 0]    addr_fifo_data_out_d   , 
        output                          addr_fifo_empty_d      ,
        output     [FIFO_CNT_WID-1:0]   addr_fifo_word_cnt_s   ,
        input                           addr_fifo_push_s       ,
        output                          addr_fifo_full_s       ,
        output                          addr_fifo_afull_s      ,
        input      [FIFO_WIDTH-1: 0]    addr_fifo_data_in_s    ,
        input                           addr_fifo_init_s       ,
        input                           addr_fifo_init_d        
    );



wire                            wr_fifo_push_en_s;
wire                            wr_fifo_pop_en_d;

wire                            wr_en_s_n;   // Source  write enable to RAM
wire   [FIFO_CNT_WID-2:0]       wr_addr_s;   // Source  write address to RAM
wire   [FIFO_WIDTH-1: 0]        data_s;

wire                            ram_re_d_n;   // Destination  RAM read enable
wire   [FIFO_CNT_WID-2:0]       rd_addr_d;    // Destination  read address to RAM
wire   [FIFO_WIDTH-1: 0]        rd_data_d;    // Destination  data read from RAM

// Wire debug signals
wire                            clr_sync_s;
wire                            clr_in_prog_s;
wire   [FIFO_CNT_WID-1:0]       fifo_word_cnt_s;
wire   [FIFO_CNT_WID-1:0]       word_cnt_s;
wire                            fifo_empty_s;
wire                            empty_s;
wire                            error_s;
wire                            clr_sync_d;
wire                            clr_in_prog_d;
wire   [FIFO_CNT_WID-1:0]       ram_word_cnt_d;
wire                            full_d;
wire                            error_d;

assign wr_fifo_push_en_s = !addr_fifo_full_s  && addr_fifo_push_s;
assign wr_fifo_pop_en_d  = !addr_fifo_empty_d && addr_fifo_pop_d;

//==================================================
// DW fifo ctrl
//==================================================

DW_fifoctl_2c_df #(.width(FIFO_WIDTH),
                   .ram_depth(FIFO_DEPTH),
                   .mem_mode(1),
                   .verif_en(0)
                   )
    i_raddr_fifoctl(
        //push
        .clk_s           (clk_s                 ),
        .rst_s_n         (rstn_s                ),
        .init_s_n        (!addr_fifo_init_s    ),
        .clr_s           (1'b0                  ),
        .ae_level_s      (6'b0                  ),
        .af_level_s      (6'd3                  ),
        .push_s_n        (!wr_fifo_push_en_s    ),
        .clr_sync_s      (clr_sync_s            ),
        .clr_in_prog_s   (clr_in_prog_s         ),
        .clr_cmplt_s     (),
        .wr_en_s_n       (wr_en_s_n             ),
        .wr_addr_s       (wr_addr_s             ),
        .fifo_word_cnt_s (addr_fifo_word_cnt_s ),
        .word_cnt_s      (word_cnt_s            ),
        .fifo_empty_s    (fifo_empty_s          ),
        .empty_s         (empty_s               ),
        .almost_empty_s  (),
        .half_full_s     (),
        .almost_full_s   (addr_fifo_afull_s    ),
        .full_s          (addr_fifo_full_s     ),
        .error_s         (error_s               ),
        //pop
        .clk_d           (clk_d                 ),
        .rst_d_n         (rstn_d                ),
        .init_d_n        (!addr_fifo_init_d     ),
        .clr_d           (1'b0                  ),
        .ae_level_d      (6'b0                  ),
        .af_level_d      (6'b0                  ),
        .pop_d_n         (!wr_fifo_pop_en_d     ),
        .rd_data_d       (rd_data_d             ),
        .clr_sync_d      (clr_sync_d            ),
        .clr_in_prog_d   (clr_in_prog_d         ),
        .clr_cmplt_d     (),
        .ram_re_d_n      (ram_re_d_n            ),
        .rd_addr_d       (rd_addr_d             ),
        .data_d          (addr_fifo_data_out_d ),
        .word_cnt_d      (),
        .ram_word_cnt_d  (ram_word_cnt_d        ),
        .empty_d         (addr_fifo_empty_d    ),
        .almost_empty_d  (),
        .half_full_d     (),
        .almost_full_d   (),
        .full_d          (full_d                ),
        .error_d         (error_d               ),
        .test            (1'b0                  ));

assign data_s = addr_fifo_data_in_s;

//==================================================
// ram 32x32
//==================================================

std_tpram32x32
    i_std_tpram32x32_rlen(
        .RCLK    (clk_d       ),
        .RADDR   (rd_addr_d  ),
        .RCEB    (ram_re_d_n ),
        .RDATA   (rd_data_d[FIFO_WIDTH/2-1:0]  ),
        .WCLK    (clk_s        ),
        .WADDR   (wr_addr_s  ),
        .WCEB    (wr_en_s_n  ),
        .WDATA   (addr_fifo_data_in_s[FIFO_WIDTH/2-1:0]     ));

std_tpram32x32
    i_std_tpram32x32_raddr(
        .RCLK    (clk_d       ),
        .RADDR   (rd_addr_d  ),
        .RCEB    (ram_re_d_n ),
        .RDATA   (rd_data_d[FIFO_WIDTH-1: FIFO_WIDTH/2]  ),
        .WCLK    (clk_s        ),
        .WADDR   (wr_addr_s  ),
        .WCEB    (wr_en_s_n  ),
        .WDATA   (addr_fifo_data_in_s  [FIFO_WIDTH-1: FIFO_WIDTH/2]     ));
endmodule
