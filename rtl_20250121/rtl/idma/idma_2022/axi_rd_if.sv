module axi_rd_if #(
    parameter AXI_IDW       = 4             ,
    parameter AXI_LOCKW     = 2             ,
    parameter AXI_DATA_WID  = 256           ,
    parameter AXI_STRBW     = AXI_DATA_WID/8            
    )(
    //global input
    input                       aclk                        ,
    input                       aresetn                     ,
    //from cfg cmd
    input				        rd_cfg_ready                , 
    input	[3:0]			    rd_cfg_outstd               , 
    input	    			    rd_cfg_outstd_en            ,
    input                       rd_cfg_cross4k_en           ,
    //from cfg addr
    input	[31:0]		        raddr_fifo_rd_num_word     ,  //word
    input	[31:0]		        raddr_fifo_raddr_in        ,
    input				        raddr_fifo_empty           ,
    output                      raddr_fifo_pop             , 
    //to rdata fifo
    input                       rdata_fifo_full_s           ,
    output                      rdata_fifo_push             ,
    output  [AXI_STRBW-1:0]     rdata_fifo_strb_s           ,
    output  [AXI_DATA_WID-1:0]  rdata_fifo_data_s           ,
    input                       rd_burst_arvld_disable      ,
    // AXI read data 
    input                       i_rlast                     ,
    input [AXI_DATA_WID-1:0]    i_rdata                     ,           
    input                       i_rvalid                    ,
    input [AXI_IDW-1:0]         i_rid                       ,
    input [1:0]                 i_rresp                     ,
    output                      o_rready                    ,
    // AXI write request
    output                      o_arvalid               ,
    output [AXI_IDW-1:0]        o_arid                  ,
    output [32-1:0]             o_araddr                ,
    output [4-1:0]              o_arlen                 ,
    output [2:0]                o_arsize                ,
    output [1:0]                o_arburst               ,
    output [AXI_LOCKW-1:0]      o_arlock                ,
    output [3:0]                o_arcache               ,
    output [2:0]                o_arprot                ,
    input                       i_arready               ,
     
    output                      read_all_done           
    );
    
    wire                        axi_burst_rdata_ok      ;
    //strb
    wire  [5:0]                 strb_first_beat_num     ;
    wire  [5:0]                 strb_last_beat_num      ;
    wire                        dma_trans_first_burst   ;
    wire                        dma_trans_last_burst    ;
    
    wire                        dma_trans_burst_avalid     ;
    wire  [31:0]                dma_trans_burst_addr       ;
    wire  [3:0]                 dma_trans_burst_len        ;
    wire                        dma_raddr_burst_ok         ;
    wire                        cross_4k_stage             ;
    wire                        cross_4k_flag              ;
    wire                        axi_burst_raddr_ok         ;
    
    //==================================================
    axi_rdata_proc #(
    .AXI_IDW       (AXI_IDW       ),
    .AXI_DATA_WID  (AXI_DATA_WID  ))
    U_rd_data_proc (
    .aclk                    (aclk                    ),
    .aresetn                 (aresetn                 ),
    .rdata_fifo_full_s       (rdata_fifo_full_s       ),
    .rdata_fifo_push         (rdata_fifo_push         ),
    .rdata_fifo_strb_s       (rdata_fifo_strb_s       ),
    .rdata_fifo_data_s       (rdata_fifo_data_s       ),
    .axi_burst_rdata_ok      (axi_burst_rdata_ok      ),
    .i_rlast                 (i_rlast                 ),
    .i_rdata                 (i_rdata                 ),
    .i_rvalid                (i_rvalid                ),
    .i_rid                   (i_rid                   ),
    .i_rresp                 (i_rresp                 ),
    .o_rready                (o_rready                ),
    .strb_first_beat_num     (strb_first_beat_num     ),
    .strb_last_beat_num      (strb_last_beat_num      ),
    .dma_trans_first_burst   (dma_trans_first_burst   ),
    .dma_trans_last_burst    (dma_trans_last_burst    )
    );
    
    
    
    axi_addr_cross4k  U_rd_addr_cross4k(
    .aclk		        	(aclk                   ),
    .aresetn		        (aresetn                ),
    .o_axvalid              (o_arvalid              ),
    .o_axid                 (o_arid                 ),
    .o_axaddr               (o_araddr               ),
    .o_axlen                (o_arlen                ),
    .o_axsize               (o_arsize               ),
    .o_axburst              (o_arburst              ),
    .o_axlock               (o_arlock               ),
    .o_axcache              (o_arcache              ),
    .o_axprot               (o_arprot               ),
    .i_axready              (i_arready              ),
    .cfg_cross4k_en         (rd_cfg_cross4k_en      ),
    .axi_burst_xaddr_ok     (axi_burst_raddr_ok     ),
    .axi_burst_xdata_ok     (axi_burst_rdata_ok     ),
    .dma_trans_burst_avalid (dma_trans_burst_avalid ),
    .dma_trans_burst_addr   (dma_trans_burst_addr   ),
    .dma_trans_burst_len    (dma_trans_burst_len    ),
    .dma_xaddr_burst_ok		(dma_raddr_burst_ok	    ),
    .cross_4k_stage         (cross_4k_stage         ),
    .cross_4k_flag			(cross_4k_flag          ),
    .x_burst_arvld_disable  (rd_burst_arvld_disable )
    );
    
    
    axi_addr_manager U_rd_addr_manager(
    .aclk                   (aclk                      ),
    .aresetn                (aresetn                   ),
    .rd_cfg_ready           (rd_cfg_ready              ), 
    .rd_cfg_outstd          (rd_cfg_outstd             ), 
    .rd_cfg_outstd_en       (rd_cfg_outstd_en          ), 
    .raddr_fifo_rd_num_word (raddr_fifo_rd_num_word    ),  
    .raddr_fifo_raddr_in    (raddr_fifo_raddr_in       ),
    .raddr_fifo_empty       (raddr_fifo_empty          ),
    .raddr_fifo_pop         (raddr_fifo_pop            ), 
    .cross_4k_stage         (cross_4k_stage            ),
    .cross_4k_flag	        (cross_4k_flag             ),
    .dma_raddr_burst_ok     (dma_raddr_burst_ok        ),
    .axi_burst_rdata_ok     (axi_burst_rdata_ok        ),
    .dma_trans_burst_len    (dma_trans_burst_len       ),
    .dma_trans_burst_addr   (dma_trans_burst_addr      ),
    .dma_trans_burst_avalid (dma_trans_burst_avalid    ),
    .strb_first_beat_num    (strb_first_beat_num       ),
    .strb_last_beat_num     (strb_last_beat_num        ),
    .dma_trans_first_burst  (dma_trans_first_burst     ),
    .dma_trans_last_burst   (dma_trans_last_burst      ),
    .read_all_done          (read_all_done             )
    );
endmodule
