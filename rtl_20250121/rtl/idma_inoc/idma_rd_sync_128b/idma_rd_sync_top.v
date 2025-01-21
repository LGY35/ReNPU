module idma_rd_sync_top #(
    parameter DATA_FIFO_DEPTH   = 64    ,
    parameter DATA_FIFO_CNT_WID = 6+1   ,
    parameter ADDR_FIFO_DEPTH   = 32    ,
    parameter ADDR_FIFO_CNT_WID = 5+1   ,

    parameter AXI_DATA_WID      = 128   ,
    parameter AXI_ADDR_WID      = 32    ,
    parameter AXI_IDW           = 4     ,
    parameter AXI_LENW          = 4     ,
    parameter AXI_LOCKW         = 2     ,
    parameter AXI_STRBW         = AXI_DATA_WID/8,
    parameter ID                = 0
)
(
    //==================================================
    // ports
    //==================================================
    input                              	aclk                    ,
    input                              	aresetn                 ,
    input                              	rd_cfg_ready            ,
    input                               rd_afifo_init           ,
    input                               rd_dfifo_init           ,
    input	[3:0]			            rd_cfg_outstd           ,//ctr_new 
    input	     			            rd_cfg_outstd_en        ,//ctr_new
    input                               rd_cfg_cross4k_en       ,//ctr_new
    input                               rd_cfg_arvld_hold_en    ,
    input  [DATA_FIFO_CNT_WID-1:0]      rd_cfg_dfifo_thd        ,
    input                               rd_resi_mode            ,//1:resi 0:norm
    input  [AXI_ADDR_WID-1:0]           rd_resi_fmapA_addr      ,
    input  [AXI_ADDR_WID-1:0]           rd_resi_fmapB_addr      ,
    input  [16-1:0]                     rd_resi_addr_gap        ,
    input  [16-1:0]                     rd_resi_loop_num        ,
    input                              	rd_req                  ,
    input  [AXI_ADDR_WID-1:0]           rd_addr                 ,
    input  [31:0]                     	rd_num                  ,//word
    output                             	rd_addr_ready           ,
    output                             	rd_data_valid           ,
    output [AXI_DATA_WID-1:0]           rd_data                 ,
    input                              	rd_data_ready           ,
    output [AXI_STRBW-1:0] 	        	rd_strb                 ,
    
    //axi interface
    output                             	o_arvalid               ,
    output [AXI_IDW-1:0]               	o_arid                  ,
    output [AXI_ADDR_WID-1:0]           o_araddr                ,
    output [AXI_LENW-1:0]              	o_arlen                 ,
    output [2:0]                       	o_arsize                ,
    output [1:0]                       	o_arburst               ,
    output [AXI_LOCKW-1:0]             	o_arlock                ,
    output [3:0]                       	o_arcache               ,
    output [2:0]                       	o_arprot                ,
    input                              	i_arready               ,
    input                              	i_rvalid                ,
    input  [AXI_IDW-1:0]               	i_rid                   ,
    input                              	i_rlast                 ,
    input  [AXI_DATA_WID-1:0]          	i_rdata                 ,
    input  [1:0]                       	i_rresp                 ,
    output                             	o_rready                ,

    //intr
    output                              rd_done_intr            ,
    output  							read_all_done           ,
    //debug signal
    output reg[16-1:0]                  debug_dma_rd_in_cnt     ,
    output  [DATA_FIFO_CNT_WID-1: 0]    rd_dfifo_word_cnt       ,
    output  [ADDR_FIFO_CNT_WID-1 :0]    rd_afifo_word_cnt      
);


//==================================================
// to data  fifo
//==================================================
wire                                 rd_dfifo_push     ;
wire  [AXI_STRBW+AXI_DATA_WID-1: 0]  rd_dfifo_data_in  ;
wire                                 rd_dfifo_full     ;
wire                                 rd_dfifo_afull    ;
wire                                 rd_dfifo_pop      ;
wire  [AXI_STRBW+AXI_DATA_WID-1: 0]  rd_dfifo_data_out ;
wire                                 rd_dfifo_empty    ; 
wire  [AXI_STRBW-1:0]                rdata_fifo_strb   ;
wire  [AXI_DATA_WID-1:0]             rdata_fifo_data   ;

//==================================================
// read addr fifo
//==================================================
wire                                 rd_afifo_push;
wire  [AXI_ADDR_WID*2-1: 0]          rd_afifo_data_in;
wire                                 rd_afifo_full;
wire                                 rd_afifo_afull;
wire                                 rd_afifo_pop;
wire  [AXI_ADDR_WID*2-1: 0]          rd_afifo_data_out; 
wire                                 rd_afifo_empty;

//from cfg addr
wire  [31:0]		                 raddr_fifo_rd_num_word;  //word
wire  [31:0]		                 raddr_fifo_raddr_in;

//if dfifo cannot accept one burst, make arvld disable
wire    rd_burst_arvld_disable = rd_cfg_arvld_hold_en ? (rd_dfifo_word_cnt > rd_cfg_dfifo_thd) : 1'b0;
wire    [32-1:0]    rd_addr_p;
wire    [32-1:0]    rd_resi_addr;
wire                rd_req_p;
wire                rd_resi_req;

assign  rd_addr_p = rd_resi_mode ? rd_resi_addr : rd_addr;
assign  rd_req_p  = rd_resi_mode ? rd_resi_req : rd_req;

//data
assign  rd_dfifo_data_in    = {rdata_fifo_data, rdata_fifo_strb};
// assign  rd_dfifo_pop     	= rd_data_ready & rd_data_valid;
assign  rd_dfifo_pop     	= rd_data_ready;
assign  rd_strb		   		= rd_dfifo_data_out[0+:AXI_STRBW];
assign  rd_data		   		= rd_dfifo_data_out[AXI_STRBW+:AXI_DATA_WID];
// assign  rd_data_valid      	= ~rd_dfifo_empty;

//addr
assign  rd_afifo_push           = rd_req_p;
assign  rd_afifo_data_in        = {rd_addr_p, rd_num};    //out
assign  raddr_fifo_rd_num_word  =  rd_afifo_data_out[AXI_ADDR_WID-1:0];                // in
assign  raddr_fifo_raddr_in     =  rd_afifo_data_out[AXI_ADDR_WID*2-1:AXI_ADDR_WID];   // in
assign  rd_addr_ready           = ~rd_afifo_full;


//==================================================
// o_interrupt gen
//==================================================
reg     rd_done_flag;
reg     rd_done_flag_r;

always @(posedge aclk or negedge aresetn) begin
    if(!aresetn)
        rd_done_flag <= 1'b0;
    else if(read_all_done)
        rd_done_flag <= 1'b1;
    else if(rd_dfifo_empty)
        rd_done_flag <= 1'b0;
end

always @(posedge aclk or negedge aresetn) begin
    if(!aresetn)
        rd_done_flag_r <= 1'b0;
    else
        rd_done_flag_r <= rd_done_flag;
end

assign  rd_done_intr = ~rd_done_flag & rd_done_flag_r;


//==================================================
// debug signal
//==================================================
always @(posedge aclk or negedge aresetn) begin
    if(!aresetn) 
        debug_dma_rd_in_cnt <= 'b0;
    else if(rd_data_valid && rd_data_ready)
        debug_dma_rd_in_cnt <= debug_dma_rd_in_cnt + 1'b1;
end

//==================================================
// resi_raddr_gen
//==================================================
idma_rd_sync_resi_raddr_gen U_idma_resi_raddr_gen(
    .clk(aclk),
    .rst_n(aresetn),
    .rd_resi_mode(rd_resi_mode),
    .rd_resi_fmapA_addr(rd_resi_fmapA_addr),
    .rd_resi_fmapB_addr(rd_resi_fmapB_addr),
    .rd_resi_addr_gap(rd_resi_addr_gap),
    .rd_resi_loop_num(rd_resi_loop_num),
    .rd_req(rd_req),//in
    .rd_afifo_full_s(rd_afifo_full),
    .rd_resi_req(rd_resi_req),
    .rd_resi_addr(rd_resi_addr)//out
);


axi_addr_fifo_sync    #(
    .FIFO_WIDTH   (AXI_ADDR_WID*2),    //32*2
    .FIFO_DEPTH   (ADDR_FIFO_DEPTH),
    .FIFO_CNT_WID (ADDR_FIFO_CNT_WID)
    )
U_axi_raddr_fifo(
	.clk		        (aclk                 ),
	.rst_n		        (aresetn              ),
	.addr_fifo_pop		(rd_afifo_pop         ),
	.addr_fifo_data_out	(rd_afifo_data_out    ), 
	.addr_fifo_empty    (rd_afifo_empty       ),
	.addr_fifo_push		(rd_afifo_push        ),
	.addr_fifo_full		(rd_afifo_full        ),
	.addr_fifo_afull	(rd_afifo_afull       ),
	.addr_fifo_data_in	(rd_afifo_data_in     ),
    .addr_fifo_init     (rd_afifo_init        ),
    .addr_fifo_word_cnt (rd_afifo_word_cnt    )
);



axi_data_fifo_sync_128b    #(
    .FIFO_WIDTH   (AXI_STRBW+AXI_DATA_WID  ),    //FIFO_WIDTH=128+16
    // .FIFO_WIDTH   (16+128  ),    //FIFO_WIDTH=128+16
    .FIFO_DEPTH   (DATA_FIFO_DEPTH         ),
    .FIFO_CNT_WID (DATA_FIFO_CNT_WID       )
)
U_axi_rdata_fifo(
    .clk		        (aclk                 ),
	.rst_n		        (aresetn              ),
	.data_fifo_pop		(rd_dfifo_pop         ),
	.data_fifo_valid	(rd_data_valid        ),
	.data_fifo_data_out	(rd_dfifo_data_out    ), 
	.data_fifo_empty    (rd_dfifo_empty       ),
	.data_fifo_push		(rd_dfifo_push        ),
	.data_fifo_full		(rd_dfifo_full        ),
	.data_fifo_afull	(rd_dfifo_afull       ),
	.data_fifo_data_in	(rd_dfifo_data_in     ),
    .data_fifo_init     (rd_dfifo_init        ),
    .data_fifo_word_cnt (rd_dfifo_word_cnt    )
);



axi_rd_if #(
    .AXI_IDW       ( AXI_IDW       ),
    .AXI_LOCKW     ( AXI_LOCKW     ),
    .AXI_DATA_WID  ( AXI_DATA_WID  ),
    .ID            ( ID            ))
U_axi_rd_if (
    .aclk                       (aclk                      ),
    .aresetn                    (aresetn                   ),
    .rd_cfg_ready               (rd_cfg_ready              ), 
    .rd_cfg_outstd              (rd_cfg_outstd             ), 
    .rd_cfg_outstd_en           (rd_cfg_outstd_en          ), 
    .rd_cfg_cross4k_en          (rd_cfg_cross4k_en         ),
    .raddr_fifo_rd_num_word     (raddr_fifo_rd_num_word    ),  //word
    .raddr_fifo_raddr_in        (raddr_fifo_raddr_in       ),
    .raddr_fifo_empty           (rd_afifo_empty            ),
    .raddr_fifo_pop             (rd_afifo_pop              ), 
    .rdata_fifo_full_s          (rd_dfifo_full             ),
    .rdata_fifo_push            (rd_dfifo_push             ),
    .rdata_fifo_strb_s          (rdata_fifo_strb           ),
    .rdata_fifo_data_s          (rdata_fifo_data           ),
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
    .read_all_done              (read_all_done           )
);

endmodule
