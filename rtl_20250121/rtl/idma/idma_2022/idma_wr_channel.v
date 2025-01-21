module idma_wr_channel(
        aclk                    ,           
        aresetn                 ,
        cclk                    ,
        rst_n                   ,      
        wr_cfg_ready            ,      
        wr_afifo_init           ,   //ctr
        wr_dfifo_init           ,   //ctr
        wr_cfg_init             ,
        wr_dfifo_word_cnt       ,   //ctr
        wr_afifo_word_cnt       ,   //ctr
        wr_cfg_outstd           ,   //ctr
        wr_cfg_outstd_en        ,   //ctr
        wr_cfg_cross4k_en       ,   //ctr
        wr_cfg_arvld_hold_en    ,
	    wr_cfg_arvld_hold_olen_en,
        wr_cfg_dfifo_thd        ,
        wr_cfg_strb_force       ,   //new
        wr_req                  ,
        wr_addr                 ,
        wr_num                  ,
        wr_addr_ready           ,
        wr_data_valid           ,
        wr_data                 ,
        wr_data_ready           ,
        wr_strb                 ,
        write_all_done           ,
        //axi                   
        o_awvalid               ,
        o_awid                  ,
        o_awaddr                ,
        o_awlen                 ,
        o_awsize                ,
        o_awburst               ,
        o_awlock                ,
        o_awcache               ,
        o_awprot                ,
        i_awready               ,
        o_wvalid                ,
        o_wid                   ,
        o_wlast                 ,
        o_wdata                 ,
        o_wstrb                 ,
        i_wready                ,
	    i_bvalid                ,//brespond
	    i_bid                   ,
	    i_bresp                 ,
	    o_bready                ,
        //intr
        wr_done_intr            ,
        //debug signal
        debug_dma_wr_out_cnt
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

//==================================================
// ports
//==================================================

input                              	aclk                    ;
input                              	aresetn                 ;
input                              	cclk                    ;
input                              	rst_n                   ;
input                              	wr_cfg_ready            ;
input                              	wr_afifo_init           ;//ctr_new
input                              	wr_dfifo_init           ;//ctr_new
input                               wr_cfg_init             ;
output  [DATA_FIFO_CNT_WID-1: 0]    wr_dfifo_word_cnt       ;//debug
output  [ADDR_FIFO_CNT_WID-1: 0]    wr_afifo_word_cnt       ;//debug
input	[3:0]			            wr_cfg_outstd           ;//ctr_new 
input	     			            wr_cfg_outstd_en        ;//ctr_new
input                               wr_cfg_cross4k_en       ;//ctr_new
input                               wr_cfg_arvld_hold_en    ;
input				                wr_cfg_arvld_hold_olen_en;
input  [DATA_FIFO_CNT_WID-1:0]      wr_cfg_dfifo_thd        ;
input                               wr_cfg_strb_force       ;//new 1:force wr_strb to ffff_ffff
input                              	wr_req                  ;
input  [AXI_ADDR_WID-1:0]           wr_addr                 ;
input  [31:0]                     	wr_num                  ;//word
output                             	wr_addr_ready           ;
input                             	wr_data_valid           ;
input  [AXI_DATA_WID-1:0]           wr_data                 ;
output                              wr_data_ready           ;
input  [AXI_STRBW-1:0] 	        	wr_strb                 ;
output  							write_all_done          ;

//axi interface
output                             	o_awvalid               ;
output [AXI_IDW-1:0]               	o_awid                  ;
output [AXI_ADDR_WID-1:0]           o_awaddr                ;
output [AXI_LENW-1:0]              	o_awlen                 ;
output [2:0]                       	o_awsize                ;
output [1:0]                       	o_awburst               ;
output [AXI_LOCKW-1:0]             	o_awlock                ;
output [3:0]                       	o_awcache               ;
output [2:0]                       	o_awprot                ;
input                              	i_awready               ;
output                              o_wvalid                ;
output  [AXI_IDW-1:0]               o_wid                   ;
output                              o_wlast                 ;
output  [AXI_DATA_WID-1:0]          o_wdata                 ;
output  [AXI_STRBW-1:0]             o_wstrb                 ;
input                             	i_wready                ;
input                               i_bvalid                ;//brespond
input  [AXI_IDW-1:0]                i_bid                   ;
input  [1:0]                        i_bresp                 ;
output                              o_bready                ;

//intr
output                              wr_done_intr            ;
//debug signal
output [16-1:0]                     debug_dma_wr_out_cnt    ;


//==================================================
// to data  fifo
//==================================================
wire                                 wr_dfifo_push_s     ;
wire  [AXI_STRBW+AXI_DATA_WID-1: 0]  wr_dfifo_data_in_s  ;
wire                                 wr_dfifo_full_s     ;
wire                                 wr_dfifo_afull_s    ;
wire  [DATA_FIFO_CNT_WID-1: 0]       wr_dfifo_word_cnt_d ;
wire                                 wr_dfifo_pop_d      ;
wire  [AXI_STRBW+AXI_DATA_WID-1: 0]  wr_dfifo_data_out_d ;
wire                                 wr_dfifo_empty_d    ; 


wire  [AXI_STRBW-1:0]                wdata_fifo_strb_d   ;
wire  [AXI_DATA_WID-1:0]             wdata_fifo_data_d   ;


//==================================================
// read addr fifo
//==================================================
wire                                 wr_afifo_push_s;
wire  [AXI_ADDR_WID*2-1: 0]          wr_afifo_data_in_s;
wire                                 wr_afifo_full_s;
wire                                 wr_afifo_pop_d;
wire  [AXI_ADDR_WID*2-1: 0]          wr_afifo_data_out_d; 
wire                                 wr_afifo_empty_d;
wire                                 wr_afifo_clr_d;
wire                                 wr_afifo_clr_complete_d;
wire                                 wr_afifo_clr_complete_s; 

//sync
wire wr_cfg_ready_sync, wr_cfg_outstd_en_sync, write_all_done_s, wr_cfg_init_sync;

//from cfg addr
wire  [31:0]		                 waddr_fifo_wr_num_word;  //word
wire  [31:0]		                 waddr_fifo_waddr_in;

//
wire    wr_burst_arvld_disable = wr_cfg_arvld_hold_en ? (wr_cfg_arvld_hold_olen_en ? (wr_dfifo_word_cnt_d < o_awlen+1) : (wr_dfifo_word_cnt_d < wr_cfg_dfifo_thd)) : 1'b0;


//debug signal
reg [16-1:0] debug_dma_wr_out_cnt;
always @(posedge aclk or negedge aresetn) begin
    if(!aresetn) 
        debug_dma_wr_out_cnt <= 'b0;
    //else if(write_all_done_s)
    //    debug_dma_wr_out_cnt <= 'b0;
    else if(o_wvalid&&i_wready)
        debug_dma_wr_out_cnt <= debug_dma_wr_out_cnt + 1'b1;
end


//data
assign  wr_dfifo_push_s     	    = wr_data_valid&wr_data_ready;
assign  wr_dfifo_data_in_s[31:0]    = wr_cfg_strb_force ? 32'hffffffff : ~wr_strb;
assign  wr_dfifo_data_in_s[287:32]  = wr_data;
assign  wdata_fifo_strb_d           = wr_dfifo_data_out_d[31:0];
assign  wdata_fifo_data_d           = wr_dfifo_data_out_d[287:32];
assign  wr_data_ready               = ~wr_dfifo_full_s;

//addr
assign  wr_afifo_push_s     = wr_req;
assign  wr_afifo_data_in_s  = {wr_addr, wr_num};
assign  waddr_fifo_wr_num_word   =    wr_afifo_data_out_d[AXI_ADDR_WID-1:0];                
assign  waddr_fifo_waddr_in      =    wr_afifo_data_out_d[AXI_ADDR_WID*2-1:AXI_ADDR_WID];   
assign  wr_addr_ready       = ~wr_afifo_full_s;


//==================================================
// wr_interrupt gen
//==================================================
wire    wr_done_intr = write_all_done;

//==================================================
// pulse
//==================================================


pulse_sync i_wr_cfg_rdy_sync(
    .clk_src     (cclk),
    .rst_n_src   (rst_n),
    .data_src    (wr_cfg_ready),
    .clk_dst     (aclk),
    .rst_n_dst   (aresetn),
    .data_dst    (wr_cfg_ready_sync)
);

pulse_sync o_write_all_done_sync(
    .clk_src     (aclk),
    .rst_n_src   (aresetn),
    .data_src    (write_all_done_s),
    .clk_dst     (cclk),
    .rst_n_dst   (rst_n),
    .data_dst    (write_all_done)
);

pulse_sync i_wr_cfg_init_sync(
    .clk_src     (cclk),
    .rst_n_src   (rst_n),
    .data_src    (wr_cfg_init),
    .clk_dst     (aclk),
    .rst_n_dst   (aresetn),
    .data_dst    (wr_cfg_init_sync)
);

level_sync i_wr_cfg_outstd_en_sync(
    .clk_src     (cclk),
    .rst_n_src   (rst_n),
    .data_src    (wr_cfg_outstd_en),
    .clk_dst     (aclk),
    .rst_n_dst   (aresetn),
    .data_dst    (wr_cfg_outstd_en_sync)
);


    axi_addr_fifo    #(
    .FIFO_WIDTH   (AXI_ADDR_WID*2),    //32*2
    .FIFO_DEPTH   (ADDR_FIFO_DEPTH),
    .FIFO_CNT_WID (ADDR_FIFO_CNT_WID)
    )
    U_axi_waddr_fifo(
		.clk_s		                            (cclk                   ),
		.rstn_s		                            (rst_n                  ),
		.clk_d		                            (aclk                   ),
		.rstn_d		            	            (aresetn                ),
		.addr_fifo_pop_d		                (wr_afifo_pop_d         ),
		.addr_fifo_data_out_d		    	    (wr_afifo_data_out_d    ), 
		.addr_fifo_empty_d		    	        (wr_afifo_empty_d       ),
		.addr_fifo_word_cnt_s		            (wr_afifo_word_cnt      ),
		.addr_fifo_push_s		                (wr_afifo_push_s        ),
		.addr_fifo_full_s		                (wr_afifo_full_s        ),
		.addr_fifo_afull_s		    	        (),
		.addr_fifo_data_in_s		    	    (wr_afifo_data_in_s     ),
		.addr_fifo_init_s		                (wr_afifo_init          ),
        .addr_fifo_init_d		                (1'b0)
    );


 
    axi_data_fifo    #(
    .FIFO_WIDTH   (AXI_STRBW+AXI_DATA_WID  ),    //FIFO_WIDTH=256+32+1=289
    .FIFO_DEPTH   (DATA_FIFO_DEPTH         ),
    .FIFO_CNT_WID (DATA_FIFO_CNT_WID       )
    )
    U_axi_wdata_fifo(
    .clk_s		                        (cclk                   ),
    .rstn_s		                        (rst_n                  ),
    .clk_d		                        (aclk                   ),  
    .rstn_d		            	        (aresetn                ),
    .data_fifo_pop_d		            (wr_dfifo_pop_d         ),
    .data_fifo_data_out_d		    	(wr_dfifo_data_out_d    ), 
    .data_fifo_word_cnt_d		        (wr_dfifo_word_cnt_d    ),
    .data_fifo_empty_d		    	    (wr_dfifo_empty_d       ),
    .data_fifo_word_cnt_s               (wr_dfifo_word_cnt      ),
    .data_fifo_push_s		            (wr_dfifo_push_s        ),
    .data_fifo_full_s		            (wr_dfifo_full_s        ),
    .data_fifo_afull_s		    	    (), //no use
    .data_fifo_data_in_s		    	(wr_dfifo_data_in_s     ),
    .data_fifo_init_s		            (wr_dfifo_init          ),
    .data_fifo_init_d		            (1'b0)
    );



    axi_wr_if #(
    .AXI_IDW       ( AXI_IDW       ),
    .AXI_LOCKW     ( AXI_LOCKW     ),
    .AXI_DATA_WID  ( AXI_DATA_WID  ))
    U_axi_wr_if (
    .aclk                       (aclk                    ),
    .aresetn                    (aresetn                 ),
    .wr_cfg_ready               (wr_cfg_ready_sync       ), 
    .wr_cfg_outstd              (wr_cfg_outstd           ), 
    .wr_cfg_outstd_en           (wr_cfg_outstd_en_sync   ), 
    .wr_cfg_cross4k_en          (wr_cfg_cross4k_en       ),
    .wr_cfg_init                (wr_cfg_init_sync        ),
    .waddr_fifo_wr_num_word     (waddr_fifo_wr_num_word  ),  //word
    .waddr_fifo_waddr_in        (waddr_fifo_waddr_in     ),
    .waddr_fifo_empty           (wr_afifo_empty_d        ),
    .waddr_fifo_pop             (wr_afifo_pop_d          ), 
    .wdata_fifo_empty_d         (wr_dfifo_empty_d        ),
    .wdata_fifo_pop             (wr_dfifo_pop_d          ),
    .wdata_fifo_strb_d          (wdata_fifo_strb_d       ),
    .wdata_fifo_data_d          (wdata_fifo_data_d       ),
    .wr_burst_arvld_disable     (wr_burst_arvld_disable  ),
    // AXI read data 
    .o_wlast                    (o_wlast                 ),
    .o_wdata                    (o_wdata                 ),           
    .o_wvalid                   (o_wvalid                ),
    .o_wid                      (o_wid                   ),
    .o_wstrb                    (o_wstrb                 ),
    .i_wready                   (i_wready                ),
    // AXI write request
    .o_awvalid                  (o_awvalid               ),
    .o_awid                     (o_awid                  ),
    .o_awaddr                   (o_awaddr                ),
    .o_awlen                    (o_awlen                 ),
    .o_awsize                   (o_awsize                ),
    .o_awburst                  (o_awburst               ),
    .o_awlock                   (o_awlock                ),
    .o_awcache                  (o_awcache               ),
    .o_awprot                   (o_awprot                ),
    .i_awready                  (i_awready               ),
    .i_bvalid                   (i_bvalid                ),//brespond
    .i_bid                      (i_bid                   ),
    .i_bresp                    (i_bresp                 ),
    .o_bready                   (o_bready                ),    
    .write_all_done             (write_all_done_s        )
    );


endmodule
