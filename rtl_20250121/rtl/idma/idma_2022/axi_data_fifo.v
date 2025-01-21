module axi_data_fifo #(
    parameter FIFO_WIDTH = 288 ,     //FIFO_WIDTH=256+32+1
    parameter FIFO_DEPTH = 64  ,    
    parameter FIFO_CNT_WID = 6+1    //ceil[log2 (FIFO_DEPTH) + 1]
    )(
    input                           clk_s                   ,
    input                           rstn_s                  ,
    input                           clk_d                   ,
    input                           rstn_d                  ,
    input                           data_fifo_pop_d        ,
    output     [FIFO_WIDTH-1: 0]    data_fifo_data_out_d   ,
    output     [FIFO_CNT_WID-1:0]   data_fifo_word_cnt_d   ,
    output                          data_fifo_empty_d      ,
    output     [FIFO_CNT_WID-1:0]   data_fifo_word_cnt_s   ,
    input                           data_fifo_push_s       ,
    output                          data_fifo_full_s       ,
    output                          data_fifo_afull_s      ,
    input      [FIFO_WIDTH-1: 0]    data_fifo_data_in_s    ,
    input                           data_fifo_init_d       , 
    input                           data_fifo_init_s       
   );


//==================================================
// ports (clk exchange)
//==================================================


wire                            wr_fifo_push_en_s;
wire                            wr_fifo_pop_en_d;

wire                            wr_en_s_n;    // Source  write enable to RAM 
wire   [FIFO_CNT_WID-2:0]       wr_addr_s;    // Source  write address to RAM

wire                            ram_re_d_n;   // Destination  RAM read enable
wire   [FIFO_CNT_WID-2:0]       rd_addr_d;    // Destination  read address to RAM
wire   [FIFO_WIDTH-1: 0]        rd_data_d;    // Destination  data read from RAM

// Wire debug signals
wire                            clr_sync_s;
wire                            clr_in_prog_s;
wire   [FIFO_CNT_WID-1:0]       word_cnt_s;
wire                            fifo_empty_s;
wire                            empty_s;
wire                            error_s;
wire                            clr_sync_d;
wire                            clr_in_prog_d;
wire   [FIFO_CNT_WID-1:0]       ram_word_cnt_d;
wire                            full_d;
wire                            error_d;


assign wr_fifo_push_en_s = !data_fifo_full_s  && data_fifo_push_s;
assign wr_fifo_pop_en_d  = !data_fifo_empty_d && data_fifo_pop_d;




//==================================================
// DW fifo ctrl
//==================================================

DW_fifoctl_2c_df #(.width(FIFO_WIDTH),
                   .ram_depth(FIFO_DEPTH),
                   .mem_mode(1),
                   .verif_en(0)
                   )
    U_rdata_fifoctl(
        //push
        .clk_s           (clk_s                 ), //actually aclk!
        .rst_s_n         (rstn_s                ),
        .init_s_n        (!data_fifo_init_s     ),
        .clr_s           (1'b0                  ),
        .ae_level_s      (7'b0                  ),
        .af_level_s      (7'd3                  ),
        .push_s_n        (!wr_fifo_push_en_s    ),
        .clr_sync_s      (),
        .clr_in_prog_s   (),
        .clr_cmplt_s     (),
        .wr_en_s_n       (wr_en_s_n             ),
        .wr_addr_s       (wr_addr_s             ),
        .fifo_word_cnt_s (data_fifo_word_cnt_s  ),
        .word_cnt_s      (word_cnt_s            ),
        .fifo_empty_s    (fifo_empty_s          ),
        .empty_s         (empty_s               ),
        .almost_empty_s  (),
        .half_full_s     (),
        .almost_full_s   (data_fifo_afull_s     ),
        .full_s          (data_fifo_full_s      ),
        .error_s         (error_s               ),
        //pop
        .clk_d           (clk_d                 ), //actually clk!
        .rst_d_n         (rstn_d                ),
        .init_d_n        (!data_fifo_init_d     ),
        .clr_d           (1'b0                  ),
        .ae_level_d      (7'b0                  ),
        .af_level_d      (7'b0                  ),
        .pop_d_n         (!wr_fifo_pop_en_d     ),
        .rd_data_d       (rd_data_d             ),
        .clr_sync_d      (clr_sync_d            ),
        .clr_in_prog_d   (clr_in_prog_d         ),
        .clr_cmplt_d     (),
        .ram_re_d_n      (ram_re_d_n            ),
        .rd_addr_d       (rd_addr_d             ),
        .data_d          (data_fifo_data_out_d  ),
        .word_cnt_d      (data_fifo_word_cnt_d  ),
        .ram_word_cnt_d  (ram_word_cnt_d        ),
        .empty_d         (data_fifo_empty_d     ),
        .almost_empty_d  (),
        .half_full_d     (),
        .almost_full_d   (),
        .full_d          (full_d                ),
        .error_d         (error_d               ),
        .test            (1'b0                  ));


//==================================================
// ram 64x144 *2
//==================================================

std_tpram64x144
    i1_std_tpram64x144(
        .RCLK    (clk_d       ),
        .RADDR   (rd_addr_d  ),
        .RCEB    (ram_re_d_n ),
        .RDATA   (rd_data_d[FIFO_WIDTH/2-1:0] ),
        .WCLK    (clk_s      ),
        .WADDR   (wr_addr_s  ),
        .WCEB    (wr_en_s_n  ),
        .WDATA   (data_fifo_data_in_s[FIFO_WIDTH/2-1:0] )); 

std_tpram64x144
    i2_std_tpram64x144(
        .RCLK    (clk_d       ),
        .RADDR   (rd_addr_d   ),
        .RCEB    (ram_re_d_n  ),
        .RDATA   (rd_data_d[FIFO_WIDTH-1:FIFO_WIDTH/2]  ),
        .WCLK    (clk_s       ),
        .WADDR   (wr_addr_s   ),
        .WCEB    (wr_en_s_n   ),
        .WDATA   (data_fifo_data_in_s[FIFO_WIDTH-1:FIFO_WIDTH/2] )); 

endmodule
