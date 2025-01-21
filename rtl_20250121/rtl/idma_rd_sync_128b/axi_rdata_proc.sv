module axi_rdata_proc #(
    parameter AXI_IDW       = 4             ,
    parameter AXI_DATA_WID  = 256           ,
    parameter AXI_STRBW     = AXI_DATA_WID/8
    )(
    //global input
    input                       aclk                    ,
    input                       aresetn                 ,
    //to rdata fifo
    input                       rdata_fifo_full_s       ,
    output                      rdata_fifo_push         ,
    output reg  [AXI_STRBW-1:0] rdata_fifo_strb_s       ,
    output  [AXI_DATA_WID-1:0]  rdata_fifo_data_s       ,
    
    output                      axi_burst_rdata_ok      ,
    // AXI write data 
    input                       i_rlast                 ,
    input [AXI_DATA_WID-1:0]    i_rdata                 ,           
    input                       i_rvalid                ,
    input [AXI_IDW-1:0]         i_rid                   ,
    input [1:0]                 i_rresp                 ,
    output                      o_rready                ,
    //strb
    input  [5:0]                strb_first_beat_num     ,
    input  [5:0]                strb_last_beat_num      ,
    input                       dma_trans_first_burst   ,
    input                       dma_trans_last_burst    
);





wire axi_burst_rdata_beat_ok;

assign axi_burst_rdata_beat_ok  = o_rready && i_rvalid;
assign rdata_fifo_push          = axi_burst_rdata_beat_ok;
assign axi_burst_rdata_ok       = i_rlast && axi_burst_rdata_beat_ok;
assign o_rready                 = ~rdata_fifo_full_s;


reg    axi_receive_rdata_st;

always @(posedge aclk or negedge aresetn) begin
    if(!aresetn)      
        axi_receive_rdata_st <= 'b0;
    else if( dma_trans_first_burst  & axi_burst_rdata_beat_ok)
        axi_receive_rdata_st <= 'b1;
    else if( dma_trans_last_burst  & axi_burst_rdata_ok )
        axi_receive_rdata_st <= 'b0;
end
        
        
wire axi_receive_rdata_first_beat, axi_receive_rdata_last_beat;

assign axi_receive_rdata_first_beat =  dma_trans_first_burst  & axi_burst_rdata_beat_ok & !axi_receive_rdata_st;
assign axi_receive_rdata_last_beat  =  dma_trans_last_burst  & axi_burst_rdata_ok;


always @(*) begin
    case(1'b1)
        axi_receive_rdata_first_beat: rdata_fifo_strb_s = {AXI_STRBW{1'b1}} - (('b1 << strb_first_beat_num )-'b1);
        axi_receive_rdata_last_beat : rdata_fifo_strb_s = (strb_last_beat_num != 0) ?  (('b1 << strb_last_beat_num)-'b1) : {AXI_STRBW{1'b1}} ;
        default:  rdata_fifo_strb_s = {AXI_STRBW{1'b1}};
    endcase
end

assign rdata_fifo_data_s = i_rdata;//data_axi = i_rdata;
assign data_last = i_rlast;



endmodule
