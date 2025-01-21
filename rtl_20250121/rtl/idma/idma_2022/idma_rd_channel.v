module idma_rd_channel(
        aclk                    ,           
        aresetn                 ,
        cclk                    ,
        rst_n                   ,      
        rd_cfg_ready            ,   //ctr   
        rd_afifo_init           ,   //ctr
        rd_dfifo_init           ,   //ctr
        rd_dfifo_word_cnt       ,   //ctr
        rd_afifo_word_cnt       ,   //ctr
        rd_cfg_outstd           ,   //ctr
        rd_cfg_outstd_en        ,   //ctr
        rd_cfg_cross4k_en       ,   //ctr
        rd_cfg_arvld_hold_en    ,
        rd_cfg_dfifo_thd        ,
        rd_resi_mode            ,   //1:resi 0:norm
        rd_resi_fmapA_addr      ,
        rd_resi_fmapB_addr      ,
        rd_resi_addr_gap        ,
        rd_resi_loop_num        ,
        rd_req                  ,
        rd_addr                 ,
        rd_num                  ,
        rd_addr_ready           ,
        rd_data_valid           ,
        rd_data                 ,
        rd_data_ready           ,
        rd_strb                 ,
        read_all_done           ,
        //axi                   
        o_arvalid               ,
        o_arid                  ,
        o_araddr                ,
        o_arlen                 ,
        o_arsize                ,
        o_arburst               ,
        o_arlock                ,
        o_arcache               ,
        o_arprot                ,
        i_arready               ,
        i_rvalid                ,
        i_rid                   ,
        i_rlast                 ,
        i_rdata                 ,
        i_rresp                 ,
        o_rready                ,
        //intr
        rd_done_intr            ,
        //debug signal
        debug_dma_rd_in_cnt
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
input                              	rd_cfg_ready            ;
input                              	rd_afifo_init           ;//ctr_new
input                              	rd_dfifo_init           ;//ctr_new
output  [DATA_FIFO_CNT_WID-1: 0]    rd_dfifo_word_cnt       ;//debug
output  [ADDR_FIFO_CNT_WID-1: 0]    rd_afifo_word_cnt       ;//debug
input	[3:0]			            rd_cfg_outstd           ;//ctr_new 
input	     			            rd_cfg_outstd_en        ;//ctr_new
input                               rd_cfg_cross4k_en       ;//ctr_new
input                               rd_cfg_arvld_hold_en    ;
input  [DATA_FIFO_CNT_WID-1:0]      rd_cfg_dfifo_thd        ;
input                               rd_resi_mode            ;//1:resi 0:norm
input  [AXI_ADDR_WID-1:0]           rd_resi_fmapA_addr      ;
input  [AXI_ADDR_WID-1:0]           rd_resi_fmapB_addr      ;
input  [16-1:0]                     rd_resi_addr_gap        ;
input  [16-1:0]                     rd_resi_loop_num        ;
input                              	rd_req                  ;
input  [AXI_ADDR_WID-1:0]           rd_addr                 ;
input  [31:0]                     	rd_num                  ;//word
output                             	rd_addr_ready           ;
output                             	rd_data_valid           ;
output [AXI_DATA_WID-1:0]           rd_data                 ;
input                              	rd_data_ready           ;
output [AXI_STRBW-1:0] 	        	rd_strb                 ;
output  							read_all_done           ;

//axi interface
output                             	o_arvalid               ;
output [AXI_IDW-1:0]               	o_arid                  ;
output [AXI_ADDR_WID-1:0]           o_araddr                ;
output [AXI_LENW-1:0]              	o_arlen                 ;
output [2:0]                       	o_arsize                ;
output [1:0]                       	o_arburst               ;
output [AXI_LOCKW-1:0]             	o_arlock                ;
output [3:0]                       	o_arcache               ;
output [2:0]                       	o_arprot                ;
input                              	i_arready               ;
input                              	i_rvalid                ;
input  [AXI_IDW-1:0]               	i_rid                   ;
input                              	i_rlast                 ;
input  [AXI_DATA_WID-1:0]          	i_rdata                 ;
input  [1:0]                       	i_rresp                 ;
output                             	o_rready                ;

//intr
output                              rd_done_intr            ;
//debug signal
output  [16-1:0]                    debug_dma_rd_in_cnt     ;

//==================================================
// to data  fifo
//==================================================
wire                                 rd_dfifo_push_s     ;
wire  [AXI_STRBW+AXI_DATA_WID-1: 0]  rd_dfifo_data_in_s  ;
wire                                 rd_dfifo_full_s     ;
wire                                 rd_dfifo_afull_s    ;
wire  [DATA_FIFO_CNT_WID-1: 0]       rd_dfifo_word_cnt_s ;
wire                                 rd_dfifo_pop_d      ;
wire  [AXI_STRBW+AXI_DATA_WID-1: 0]  rd_dfifo_data_out_d ;
wire                                 rd_dfifo_empty_d    ; 


wire  [AXI_STRBW-1:0]                rdata_fifo_strb_s   ;
wire  [AXI_DATA_WID-1:0]             rdata_fifo_data_s   ;

//==================================================
// read addr fifo
//==================================================
wire                                 rd_afifo_push_s;
wire  [AXI_ADDR_WID*2-1: 0]          rd_afifo_data_in_s;
wire                                 rd_afifo_full_s;
wire                                 rd_afifo_pop_d;
wire  [AXI_ADDR_WID*2-1: 0]          rd_afifo_data_out_d; 
wire                                 rd_afifo_empty_d;
wire                                 rd_afifo_clr_d;
wire                                 rd_afifo_clr_complete_d;
wire                                 rd_afifo_clr_complete_s; 

//from cfg addr
wire  [31:0]		                 raddr_fifo_rd_num_word;  //word
wire  [31:0]		                 raddr_fifo_raddr_in;

//
wire    rd_burst_arvld_disable = rd_cfg_arvld_hold_en ? (rd_dfifo_word_cnt_s > rd_cfg_dfifo_thd) : 1'b0;//if dfifo cannot accept one burst, make arvld disable
wire    [32-1:0]    rd_addr_p;
wire    [32-1:0]    rd_resi_addr;
wire                rd_req_p;
wire                rd_resi_req;

assign  rd_addr_p = rd_resi_mode ? rd_resi_addr : rd_addr;
assign  rd_req_p = rd_resi_mode ? rd_resi_req : rd_req;

//data
assign  rd_dfifo_data_in_s = {rdata_fifo_data_s, rdata_fifo_strb_s};
assign  rd_dfifo_pop_d     	= rd_data_ready & rd_data_valid;
assign  rd_strb		   		= rd_dfifo_data_out_d[31:0];
assign  rd_data		   		= rd_dfifo_data_out_d[287:32];
assign  rd_data_valid      	= ~rd_dfifo_empty_d;

//addr
assign  rd_afifo_push_s     = rd_req_p;
assign  rd_afifo_data_in_s  = {rd_addr_p, rd_num};    //out
assign  raddr_fifo_rd_num_word   =    rd_afifo_data_out_d[AXI_ADDR_WID-1:0];                // in
assign  raddr_fifo_raddr_in      =    rd_afifo_data_out_d[AXI_ADDR_WID*2-1:AXI_ADDR_WID];   // in
assign  rd_addr_ready       = ~rd_afifo_full_s;


//==================================================
// o_interrupt gen
//==================================================
wire    rd_done_intr;
reg     rd_done_flag,rd_done_flag_r;

always @(posedge cclk or negedge rst_n) begin
    if(!rst_n)
        rd_done_flag <= 1'b0;
    else if(read_all_done)
        rd_done_flag <= 1'b1;
    else if(rd_dfifo_empty_d)
        rd_done_flag <= 1'b0;
end

always @(posedge cclk or negedge rst_n) begin
    if(!rst_n)
        rd_done_flag_r <= 1'b0;
    else
        rd_done_flag_r <= rd_done_flag;
end

assign  rd_done_intr = ~rd_done_flag & rd_done_flag_r;


//==================================================
// debug signal
//==================================================
reg [16-1:0] debug_dma_rd_in_cnt;
always @(posedge cclk or negedge rst_n) begin
    if(!rst_n) 
        debug_dma_rd_in_cnt <= 'b0;
    //else if(rd_done_intr)
    //    debug_dma_rd_in_cnt <= 'b0;
    else if(rd_data_valid&&rd_data_ready)
        debug_dma_rd_in_cnt <= debug_dma_rd_in_cnt + 1'b1;
end


//==================================================
// pulse
//==================================================

wire rd_cfg_ready_sync, rd_cfg_outstd_en_sync, read_all_done_s;

pulse_sync i_rd_cfg_rdy_sync(
    .clk_src     (cclk),
    .rst_n_src   (rst_n),
    .data_src    (rd_cfg_ready),
    .clk_dst     (aclk),
    .rst_n_dst   (aresetn),
    .data_dst    (rd_cfg_ready_sync)
);


pulse_sync o_read_all_done_sync(
    .clk_src     (aclk  ),
    .rst_n_src   (aresetn),
    .data_src    (read_all_done_s),
    .clk_dst     (cclk),
    .rst_n_dst   (rst_n),
    .data_dst    (read_all_done)
);

level_sync i_rd_cfg_outstd_en_sync(
    .clk_src     (cclk),
    .rst_n_src   (rst_n),
    .data_src    (rd_cfg_outstd_en),
    .clk_dst     (aclk),
    .rst_n_dst   (aresetn),
    .data_dst    (rd_cfg_outstd_en_sync)
);


//==================================================
// resi_raddr_gen
//==================================================
idma_resi_raddr_gen U_idma_resi_raddr_gen(
    .cclk(cclk),
    .rst_n(rst_n),
    .rd_resi_mode(rd_resi_mode),
    .rd_resi_fmapA_addr(rd_resi_fmapA_addr),
    .rd_resi_fmapB_addr(rd_resi_fmapB_addr),
    .rd_resi_addr_gap(rd_resi_addr_gap),
    .rd_resi_loop_num(rd_resi_loop_num),
    .rd_req(rd_req),//in
    .rd_afifo_full_s(rd_afifo_full_s),
    .rd_resi_req(rd_resi_req),
    .rd_resi_addr(rd_resi_addr)//out
    );


    axi_addr_fifo    #(
    .FIFO_WIDTH   (AXI_ADDR_WID*2),    //32*2
    .FIFO_DEPTH   (ADDR_FIFO_DEPTH),
    .FIFO_CNT_WID (ADDR_FIFO_CNT_WID)
    )
    U_axi_raddr_fifo(
		.clk_s		                            (cclk                   ),
		.rstn_s		                            (rst_n                  ),
		.clk_d		                            (aclk                   ),
		.rstn_d		            	            (aresetn                ),
		.addr_fifo_pop_d		                (rd_afifo_pop_d         ),
		.addr_fifo_data_out_d		    	    (rd_afifo_data_out_d    ), 
		.addr_fifo_empty_d		    	        (rd_afifo_empty_d       ),
		.addr_fifo_word_cnt_s		            (rd_afifo_word_cnt      ),
		.addr_fifo_push_s		                (rd_afifo_push_s        ),
		.addr_fifo_full_s		                (rd_afifo_full_s        ),
		.addr_fifo_afull_s		    	        (),
		.addr_fifo_data_in_s		    	    (rd_afifo_data_in_s     ),
		.addr_fifo_init_s		                (rd_afifo_init          ),
        .addr_fifo_init_d		                (1'b0)
    
    );



    axi_data_fifo    #(
    .FIFO_WIDTH   (AXI_STRBW+AXI_DATA_WID  ),    //FIFO_WIDTH=256+32+1=289
    .FIFO_DEPTH   (DATA_FIFO_DEPTH         ),
    .FIFO_CNT_WID (DATA_FIFO_CNT_WID       )
    )
    U_axi_rdata_fifo(
    .clk_s		                        (aclk                   ),
    .rstn_s		                        (aresetn                ),
    .clk_d		                        (cclk                   ),  
    .rstn_d		            	        (rst_n                  ),
    .data_fifo_pop_d		            (rd_dfifo_pop_d         ),
    .data_fifo_data_out_d		    	(rd_dfifo_data_out_d    ), 
    .data_fifo_word_cnt_d		        (rd_dfifo_word_cnt      ),
    .data_fifo_empty_d		    	    (rd_dfifo_empty_d       ),
    .data_fifo_word_cnt_s               (rd_dfifo_word_cnt_s    ),
    .data_fifo_push_s		            (rd_dfifo_push_s        ),
    .data_fifo_full_s		            (rd_dfifo_full_s        ),
    .data_fifo_afull_s		    	    (), //no use
    .data_fifo_data_in_s		    	(rd_dfifo_data_in_s     ),
    .data_fifo_init_s		            (1'b0),
    .data_fifo_init_d		            (rd_dfifo_init          )
    );



    axi_rd_if #(
    .AXI_IDW       ( AXI_IDW       ),
    .AXI_LOCKW     ( AXI_LOCKW     ),
    .AXI_DATA_WID  ( AXI_DATA_WID  ))
    U_axi_rd_if (
    .aclk                       (aclk                      ),
    .aresetn                    (aresetn                   ),
    .rd_cfg_ready               (rd_cfg_ready_sync         ), 
    .rd_cfg_outstd              (rd_cfg_outstd             ), 
    .rd_cfg_outstd_en           (rd_cfg_outstd_en_sync     ), 
    .rd_cfg_cross4k_en          (rd_cfg_cross4k_en         ),
    .raddr_fifo_rd_num_word     (raddr_fifo_rd_num_word    ),  //word
    .raddr_fifo_raddr_in        (raddr_fifo_raddr_in       ),
    .raddr_fifo_empty           (rd_afifo_empty_d          ),
    .raddr_fifo_pop             (rd_afifo_pop_d            ), 
    .rdata_fifo_full_s          (rd_dfifo_full_s           ),
    .rdata_fifo_push            (rd_dfifo_push_s           ),
    .rdata_fifo_strb_s          (rdata_fifo_strb_s         ),
    .rdata_fifo_data_s          (rdata_fifo_data_s         ),
    .rd_burst_arvld_disable     (rd_burst_arvld_disable    ),
    // AXI read data 
    .i_rlast                    (i_rlast                 ),
    .i_rdata                    (i_rdata                 ),           
    .i_rvalid                   (i_rvalid                ),
    .i_rid                      (i_rid                   ),
    .i_rresp                    (i_rresp                 ),
    .o_rready                   (o_rready                ),
    // AXI write request
    .o_arvalid                  (o_arvalid               ),
    .o_arid                     (o_arid                  ),
    .o_araddr                   (o_araddr                ),
    .o_arlen                    (o_arlen                 ),
    .o_arsize                   (o_arsize                ),
    .o_arburst                  (o_arburst               ),
    .o_arlock                   (o_arlock                ),
    .o_arcache                  (o_arcache               ),
    .o_arprot                   (o_arprot                ),
    .i_arready                  (i_arready               ),
    .read_all_done              (read_all_done_s         )
    );

endmodule
