module axi_wr_if #(
    parameter AXI_IDW       = 4             ,
    parameter AXI_LOCKW     = 2             ,
    parameter AXI_DATA_WID  = 256           ,
    parameter AXI_STRBW     = AXI_DATA_WID/8            
    )(
    //global input
    input                       aclk                        ,
    input                       aresetn                     ,
    //from cfg cmd
    input				        wr_cfg_ready                , 
    input	[3:0]			    wr_cfg_outstd               , 
    input	    			    wr_cfg_outstd_en            ,
    input                       wr_cfg_cross4k_en           ,
    input                       wr_cfg_init                 ,
    //from cfg addr
    input	[31:0]		        waddr_fifo_wr_num_word     ,  //word
    input	[31:0]		        waddr_fifo_waddr_in        ,
    input				        waddr_fifo_empty           ,
    output                      waddr_fifo_pop             , 
    //to wdata fifo
    input                       wdata_fifo_empty_d          ,
    output                      wdata_fifo_pop              ,
    input  [AXI_STRBW-1:0]      wdata_fifo_strb_d           ,
    input  [AXI_DATA_WID-1:0]   wdata_fifo_data_d           ,
    input                       wr_burst_arvld_disable      ,
    // AXI write data 
    output                      o_wlast                     ,
    output [AXI_DATA_WID-1:0]   o_wdata                     ,           
    output                      o_wvalid                    ,
    output [AXI_IDW-1:0]        o_wid                       ,
    output [AXI_STRBW-1:0]      o_wstrb                     ,
    input                       i_wready                    ,
    // AXI write request
    output                      o_awvalid               ,
    output [AXI_IDW-1:0]        o_awid                  ,
    output [32-1:0]             o_awaddr                ,
    output [4-1:0]              o_awlen                 ,
    output [2:0]                o_awsize                ,
    output [1:0]                o_awburst               ,
    output [AXI_LOCKW-1:0]      o_awlock                ,
    output [3:0]                o_awcache               ,
    output [2:0]                o_awprot                ,
    input                       i_awready               ,
    // AXI write respond
    input                       i_bvalid                ,
    input [AXI_IDW-1:0]         i_bid                   ,
    input [1:0]                 i_bresp                 ,
    output                      o_bready                ,
        
    output                      write_all_done           
    );

    wire                        axi_burst_waddr_ok      ;//cross 4k out
    wire                        axi_burst_wdata_ok      ;//wdata_proc_out
    //strb
    wire  [5:0]                 strb_first_beat_num     ;
    wire  [5:0]                 strb_last_beat_num      ;
    wire                        dma_trans_first_burst   ;
    wire                        dma_trans_last_burst    ;
    
    wire                        dma_trans_burst_avalid  ;
    wire  [31:0]                dma_trans_burst_addr    ;
    wire  [3:0]                 dma_trans_burst_len     ;
    wire                        dma_waddr_burst_ok      ;
    wire                        cross_4k_stage          ;
    wire                        cross_4k_flag           ;
    wire                        cross_4k_flag_fst       ;
    
    wire        wlen_fifo_push   =  o_awvalid&i_awready;
    wire [3:0]  wlen_fifo_data_s =  o_awlen;
    wire        wlen_fifo_full_s;

    wire        waddr_fifo_pop_manager;
    assign      waddr_fifo_pop=waddr_fifo_pop_manager&(!wlen_fifo_full_s);
    //==================================================
    axi_wdata_proc #(
    .AXI_IDW       (AXI_IDW       ),
    .AXI_DATA_WID  (AXI_DATA_WID  ))
    U_wr_data_proc (
    .aclk                    (aclk                    ),
    .aresetn                 (aresetn                 ),
    .wdata_fifo_empty_d      (wdata_fifo_empty_d      ),//in
    .wdata_fifo_pop          (wdata_fifo_pop          ),//out
    .wdata_fifo_strb_d       (wdata_fifo_strb_d       ),//in
    .wdata_fifo_data_d       (wdata_fifo_data_d       ),//in
    //axi wlen
    .wr_cfg_init             (wr_cfg_init             ),//in
    .wlen_fifo_full_s        (wlen_fifo_full_s        ),//out
    .wlen_fifo_data_s        (wlen_fifo_data_s        ),//in
    .wlen_fifo_push          (wlen_fifo_push          ),//in
    //
    .axi_burst_wdata_ok      (axi_burst_wdata_ok      ),
    .o_wlast                 (o_wlast                 ),
    .o_wdata                 (o_wdata                 ),
    .o_wvalid                (o_wvalid                ),
    .o_wid                   (o_wid                   ),
    .o_wstrb                 (o_wstrb                 ),
    .i_wready                (i_wready                ),
    .i_bvalid                (i_bvalid                ),//brespond
    .i_bid                   (i_bid                   ),
    .i_bresp                 (i_bresp                 ),
    .o_bready                (o_bready                ), 
    .axi_burst_waddr_ok      (axi_burst_waddr_ok      ),
    .strb_first_beat_num     (strb_first_beat_num     ),//in
    .strb_last_beat_num      (strb_last_beat_num      ),//in
    .dma_trans_first_burst   (dma_trans_first_burst   ),//in
    .dma_trans_last_burst    (dma_trans_last_burst    ) //in
    );

    axi_addr_cross4k  U_wr_addr_cross4k(
    .aclk		        	(aclk                   ),
    .aresetn		        (aresetn                ),
    .o_axvalid              (o_awvalid              ),
    .o_axid                 (o_awid                 ),
    .o_axaddr               (o_awaddr               ),
    .o_axlen                (o_awlen                ),
    .o_axsize               (o_awsize               ),
    .o_axburst              (o_awburst              ),
    .o_axlock               (o_awlock               ),
    .o_axcache              (o_awcache              ),
    .o_axprot               (o_awprot               ),
    .i_axready              (i_awready              ),
    .cfg_cross4k_en         (wr_cfg_cross4k_en      ),
    .axi_burst_xaddr_ok     (axi_burst_waddr_ok     ),
    .axi_burst_xdata_ok     (axi_burst_wdata_ok     ),
    .dma_trans_burst_avalid (dma_trans_burst_avalid ),
    .dma_trans_burst_addr   (dma_trans_burst_addr   ),
    .dma_trans_burst_len    (dma_trans_burst_len    ),
    .dma_xaddr_burst_ok		(dma_waddr_burst_ok	    ),
    .cross_4k_stage         (cross_4k_stage         ),
    .cross_4k_flag			(cross_4k_flag          ),
    .cross_4k_flag_fst      (cross_4k_flag_fst      ),
    .x_burst_arvld_disable  (wr_burst_arvld_disable )
    );

    axi_addr_manager U_wr_addr_manager(
    .aclk                   (aclk                      ),
    .aresetn                (aresetn                   ),
    .rd_cfg_ready           (wr_cfg_ready              ), 
    .rd_cfg_outstd          (wr_cfg_outstd             ), 
    .rd_cfg_outstd_en       (wr_cfg_outstd_en          ), 
    .raddr_fifo_rd_num_word (waddr_fifo_wr_num_word    ),  
    .raddr_fifo_raddr_in    (waddr_fifo_waddr_in       ),
    .raddr_fifo_empty       (waddr_fifo_empty          ),
    .raddr_fifo_pop         (waddr_fifo_pop_manager    ), 
    .cross_4k_stage         (cross_4k_stage            ),
    .cross_4k_flag	        (cross_4k_flag             ),
    .cross_4k_flag_fst      (cross_4k_flag_fst         ),
    .dma_raddr_burst_ok     (dma_waddr_burst_ok        ),
    .axi_burst_rdata_ok     (axi_burst_wdata_ok        ),
    .dma_trans_burst_len    (dma_trans_burst_len       ),
    .dma_trans_burst_addr   (dma_trans_burst_addr      ),
    .dma_trans_burst_avalid (dma_trans_burst_avalid    ),
    .strb_first_beat_num    (strb_first_beat_num       ),
    .strb_last_beat_num     (strb_last_beat_num        ),
    .dma_trans_first_burst  (dma_trans_first_burst     ),
    .dma_trans_last_burst   (dma_trans_last_burst      ),
    .read_all_done          (write_all_done            )
    );    


endmodule
