
//一个DMA (Direct Memory Access) 同步通道，负责将数据从内存中读取或写入到目标地址中。
// 它支持256-bit宽度的数据传输，并且有独立的读通道和写通道。
// 通过AXI总线进行数据的读写操作，并且通过一些控制信号管理FIFO读写状态、AXI读写请求、响应等。


module idma_sync_256b_top(

        aclk                    ,           

        aresetn                 ,

        idma_cfg_ready          ,   // 配置就绪信号，区分读和写

        rd_afifo_init           ,   //rd ctr

        rd_dfifo_init           ,   //rd ctr

        rd_dfifo_word_cnt       ,   //rd ctr

        rd_afifo_word_cnt       ,   //rd ctr

        rd_cfg_outstd           ,   //rd ctr

        rd_cfg_outstd_en        ,   //rd ctr

        rd_cfg_cross4k_en       ,   //rd ctr

        rd_cfg_arvld_hold_en    ,   //rd ctr    

        rd_cfg_dfifo_thd        ,   //rd ctr

        rd_resi_mode            ,   //1:resi 0:norm

        rd_resi_fmapA_addr      ,

        rd_resi_fmapB_addr      ,

        rd_resi_addr_gap        ,

        rd_resi_loop_num        ,        

        wr_afifo_init           ,   //wr ctr

        wr_dfifo_init           ,   //wr ctr

        // wr_cfg_init             ,   //wr ctr

        wr_dfifo_word_cnt       ,   //wr ctr

        wr_afifo_word_cnt       ,   //wr ctr

        wr_cfg_outstd           ,   //wr ctr

        wr_cfg_outstd_en        ,   //wr ctr

        wr_cfg_cross4k_en       ,   //wr ctr  

        wr_cfg_arvld_hold_en    ,   //wr ctr

	wr_cfg_arvld_hold_olen_en,    

        wr_cfg_dfifo_thd        ,   //wr ctr

        wr_cfg_strb_force       ,

        rd_req                  ,

        rd_addr                 ,

        rd_num                  ,   //word

        rd_addr_ready           ,

        rd_data_valid           ,

        rd_data                 ,

        rd_data_ready           ,

        rd_strb                 ,

        //read_all_done           ,

        rd_done_intr            ,

        debug_dma_rd_in_cnt     ,

        wr_req                  ,

        wr_addr                 ,

        wr_num                  ,   //word

        wr_addr_ready           ,

        wr_data_valid           ,

        wr_data                 ,

        wr_data_ready           ,

        wr_strb                 ,

        //write_all_done          ,

        wr_done_intr            ,

        debug_dma_wr_out_cnt  ,

        //axi                   

        arvalid               ,

        arid                  ,

        araddr                ,

        arlen                 ,

        arsize                ,

        arburst               ,

        arlock                ,

        arcache               ,

        arprot                ,

        arready               ,

        rvalid                ,

        rid                   ,

        rlast                 ,

        rdata                 ,

        rresp                 ,

        rready                ,             

        awvalid               ,

        awid                  ,

        awaddr                ,

        awlen                 ,

        awsize                ,

        awburst               ,

        awlock                ,

        awcache               ,

        awprot                ,

        awready               ,

        wvalid                ,

        wid                   ,

        wlast                 ,

        wdata                 ,

        wstrb                 ,

        wready                ,

	    bvalid                ,//brespond

	    bid                   ,

	    bresp                 ,

	    bready    

);



parameter DATA_FIFO_DEPTH   = 64    ;

parameter DATA_FIFO_CNT_WID = 6+1   ;

parameter ADDR_FIFO_DEPTH   = 32    ;

parameter ADDR_FIFO_CNT_WID = 5+1   ;



parameter AXI_DATA_WID      = 256   ;

parameter AXI_ADDR_WID      = 32    ;

parameter AXI_IDW           = 4     ;

parameter AXI_LENW          = 4     ;

parameter AXI_LOCKW         = 2     ;

parameter AXI_STRBW         = 32    ;





input                              	aclk                    ;

input                              	aresetn                 ;

input    [1:0]                      idma_cfg_ready          ;

//rd channel

input                              	rd_afifo_init           ;

input                              	rd_dfifo_init           ;

output  [DATA_FIFO_CNT_WID-1: 0]    rd_dfifo_word_cnt       ;

output  [ADDR_FIFO_CNT_WID-1: 0]    rd_afifo_word_cnt       ;

input	[3:0]			            rd_cfg_outstd           ;

input	     			            rd_cfg_outstd_en        ;

input                               rd_cfg_cross4k_en       ;

input                               rd_cfg_arvld_hold_en    ;

input  [DATA_FIFO_CNT_WID-1:0]      rd_cfg_dfifo_thd        ;

input                               rd_resi_mode            ;//1:resi 0:norm

input  [AXI_ADDR_WID-1:0]           rd_resi_fmapA_addr      ;

input  [AXI_ADDR_WID-1:0]           rd_resi_fmapB_addr      ;

input  [16-1:0]                     rd_resi_addr_gap        ;

input  [16-1:0]                     rd_resi_loop_num        ;

input                              	rd_req                  ;

input  [AXI_ADDR_WID-1:0]           rd_addr                 ;

input  [31:0]                     	rd_num                  ;

output                             	rd_addr_ready           ;

output                             	rd_data_valid           ;

output [AXI_DATA_WID-1:0]           rd_data                 ;

input                              	rd_data_ready           ;

output [AXI_STRBW-1:0] 	        	rd_strb                 ;

output  							rd_done_intr            ;

//wr channel

input                              	wr_afifo_init           ;

input                              	wr_dfifo_init           ;

output  [DATA_FIFO_CNT_WID-1: 0]    wr_dfifo_word_cnt       ;

output  [ADDR_FIFO_CNT_WID-1: 0]    wr_afifo_word_cnt       ;

input	[3:0]			            wr_cfg_outstd           ; 

input	     			            wr_cfg_outstd_en        ;

input                               wr_cfg_cross4k_en       ;

input                               wr_cfg_arvld_hold_en    ;

input				                wr_cfg_arvld_hold_olen_en;

input  [DATA_FIFO_CNT_WID-1:0]      wr_cfg_dfifo_thd        ;

input                               wr_cfg_strb_force       ;//new 1:force wr_strb to ffff_ffff

input                              	wr_req                  ;

input  [AXI_ADDR_WID-1:0]           wr_addr                 ;

input  [31:0]                     	wr_num                  ;

output                             	wr_addr_ready           ;

input                             	wr_data_valid           ;

input  [AXI_DATA_WID-1:0]           wr_data                 ;

output                              wr_data_ready           ;

input  [AXI_STRBW-1:0] 	        	wr_strb                 ;

output  							wr_done_intr            ;

output  [16-1:0]                    debug_dma_rd_in_cnt     ;





//axi interface

output                             	arvalid               ;

output [AXI_IDW-1:0]               	arid                  ;

output [AXI_ADDR_WID-1:0]           araddr                ;

output [AXI_LENW-1:0]              	arlen                 ;

output [2:0]                       	arsize                ;

output [1:0]                       	arburst               ;

output [AXI_LOCKW-1:0]             	arlock                ;

output [3:0]                       	arcache               ;

output [2:0]                       	arprot                ;

input                              	arready               ;

input                              	rvalid                ;

input  [AXI_IDW-1:0]               	rid                   ;

input                              	rlast                 ;

input  [AXI_DATA_WID-1:0]          	rdata                 ;

input  [1:0]                       	rresp                 ;

output                             	rready                ;

output                             	awvalid               ;

output [AXI_IDW-1:0]               	awid                  ;

output [AXI_ADDR_WID-1:0]           awaddr                ;

output [AXI_LENW-1:0]              	awlen                 ;

output [2:0]                       	awsize                ;

output [1:0]                       	awburst               ;

output [AXI_LOCKW-1:0]             	awlock                ;

output [3:0]                       	awcache               ;

output [2:0]                       	awprot                ;

input                              	awready               ;

output                              wvalid                ;

output  [AXI_IDW-1:0]               wid                   ;

output                              wlast                 ;

output  [AXI_DATA_WID-1:0]          wdata                 ;

output  [AXI_STRBW-1:0]             wstrb                 ;

input                             	wready                ;

input                               bvalid                ;//brespond

input  [AXI_IDW-1:0]                bid                   ;

input  [1:0]                        bresp                 ;

output                              bready                ;

output [16-1:0]                     debug_dma_wr_out_cnt  ;



wire                                write_all_done,read_all_done;



//==================================================

// DUTs

//==================================================


// 读通道的逻辑，包括从AXI总线读取数据并存储到内部的FIFO中，处理地址和数据的交互。
idma_sync_256b_rd_channel #(

    .DATA_FIFO_DEPTH   (DATA_FIFO_DEPTH   ),

    .DATA_FIFO_CNT_WID (DATA_FIFO_CNT_WID ),

    .ADDR_FIFO_DEPTH   (ADDR_FIFO_DEPTH   ),

    .ADDR_FIFO_CNT_WID (ADDR_FIFO_CNT_WID ),

    

    .AXI_DATA_WID      (AXI_DATA_WID      ),

    .AXI_ADDR_WID      (AXI_ADDR_WID      ),

    .AXI_IDW           (AXI_IDW           ),

    .AXI_LENW          (AXI_LENW          ),

    .AXI_LOCKW         (AXI_LOCKW         ),

    .AXI_STRBW         (AXI_STRBW         )

)

U_idma_rd_channel(

    .aclk                   (aclk               ),           

    .aresetn                (aresetn            ),     

    .rd_cfg_ready           (idma_cfg_ready[1]  ),      

    .rd_afifo_init          (rd_afifo_init      ),   

    .rd_dfifo_init          (rd_dfifo_init      ),   

    .rd_dfifo_word_cnt      (rd_dfifo_word_cnt  ),   

    .rd_afifo_word_cnt      (rd_afifo_word_cnt  ),   

    .rd_cfg_outstd          (rd_cfg_outstd      ),   

    .rd_cfg_outstd_en       (rd_cfg_outstd_en   ),   

    .rd_cfg_cross4k_en      (rd_cfg_cross4k_en  ),

    .rd_cfg_arvld_hold_en   (rd_cfg_arvld_hold_en),

    .rd_cfg_dfifo_thd       (rd_cfg_dfifo_thd   ),

    .rd_resi_mode           (rd_resi_mode       ),   //1:resi 0:norm

    .rd_resi_fmapA_addr     (rd_resi_fmapA_addr ),

    .rd_resi_fmapB_addr     (rd_resi_fmapB_addr ),

    .rd_resi_addr_gap       (rd_resi_addr_gap   ),

    .rd_resi_loop_num       (rd_resi_loop_num   ),

    .rd_req                 (rd_req             ),

    .rd_addr                (rd_addr            ),

    .rd_num                 (rd_num             ),

    .rd_addr_ready          (rd_addr_ready      ),

    .rd_data_valid          (rd_data_valid      ),

    .rd_data                (rd_data            ),

    .rd_data_ready          (rd_data_ready      ),

    .rd_strb                (rd_strb            ),

    .read_all_done          (read_all_done      ),

    //axi              

    .o_arvalid              (arvalid          ),

    .o_arid                 (arid             ),

    .o_araddr               (araddr           ),

    .o_arlen                (arlen            ),

    .o_arsize               (arsize           ),

    .o_arburst              (arburst          ),

    .o_arlock               (arlock           ),

    .o_arcache              (arcache          ),

    .o_arprot               (arprot           ),

    .i_arready              (arready          ),

    .i_rvalid               (rvalid           ),

    .i_rid                  (rid              ),

    .i_rlast                (rlast            ),

    .i_rdata                (rdata            ),

    .i_rresp                (rresp            ),

    .o_rready               (rready           ),

    //intr

    .rd_done_intr           (rd_done_intr     ),

    .debug_dma_rd_in_cnt    (debug_dma_rd_in_cnt)

    );






// 写通道的逻辑，包括将数据写入AXI总线的目标地址中。
idma_sync_256b_wr_channel #(

    .DATA_FIFO_DEPTH   (DATA_FIFO_DEPTH   ),

    .DATA_FIFO_CNT_WID (DATA_FIFO_CNT_WID ),

    .ADDR_FIFO_DEPTH   (ADDR_FIFO_DEPTH   ),

    .ADDR_FIFO_CNT_WID (ADDR_FIFO_CNT_WID ),

    

    .AXI_DATA_WID      (AXI_DATA_WID      ),

    .AXI_ADDR_WID      (AXI_ADDR_WID      ),

    .AXI_IDW           (AXI_IDW           ),

    .AXI_LENW          (AXI_LENW          ),

    .AXI_LOCKW         (AXI_LOCKW         ),

    .AXI_STRBW         (AXI_STRBW         )

)

U_idma_wr_channel(

    .aclk                   (aclk                ),           

    .aresetn                (aresetn             ),     

    .wr_cfg_ready           (idma_cfg_ready[0]   ),      

    .wr_afifo_init          (wr_afifo_init       ),   

    .wr_dfifo_init          (wr_dfifo_init       ),   

    .wr_cfg_init            (1'b0                ),

    .wr_dfifo_word_cnt      (wr_dfifo_word_cnt   ),   

    .wr_afifo_word_cnt      (wr_afifo_word_cnt   ),   

    .wr_cfg_outstd          (wr_cfg_outstd       ),   

    .wr_cfg_outstd_en       (wr_cfg_outstd_en    ),   

    .wr_cfg_cross4k_en      (wr_cfg_cross4k_en   ), 

    .wr_cfg_arvld_hold_en   (wr_cfg_arvld_hold_en),

    .wr_cfg_arvld_hold_olen_en(wr_cfg_arvld_hold_olen_en),

    .wr_cfg_dfifo_thd       (wr_cfg_dfifo_thd    ),

    .wr_cfg_strb_force      (wr_cfg_strb_force   ),

    .wr_req                 (wr_req              ),

    .wr_addr                (wr_addr             ),

    .wr_num                 (wr_num              ),

    .wr_addr_ready          (wr_addr_ready       ),

    .wr_data_valid          (wr_data_valid       ),

    .wr_data                (wr_data             ),

    .wr_data_ready          (wr_data_ready       ),

    .wr_strb                (wr_strb             ),

    .write_all_done         (write_all_done      ),

    //axi               

    .o_awvalid              (awvalid           ),

    .o_awid                 (awid              ),

    .o_awaddr               (awaddr            ),

    .o_awlen                (awlen             ),

    .o_awsize               (awsize            ),

    .o_awburst              (awburst           ),

    .o_awlock               (awlock            ),

    .o_awcache              (awcache           ),

    .o_awprot               (awprot            ),

    .i_awready              (awready           ),

    .o_wvalid               (wvalid            ),

    .o_wid                  (wid               ),

    .o_wlast                (wlast             ),

    .o_wdata                (wdata             ),

    .o_wstrb                (wstrb             ),

    .i_wready               (wready            ),

    .i_bvalid               (bvalid            ),//brespond

    .i_bid                  (bid               ),

    .i_bresp                (bresp             ),

    .o_bready               (bready            ),

    //intr

    .wr_done_intr           (wr_done_intr      ),

    //debug

    .debug_dma_wr_out_cnt   (debug_dma_wr_out_cnt)

    );



endmodule



