module axi_wdata_proc #(
    parameter AXI_IDW       = 4             ,
    parameter AXI_DATA_WID  = 256           ,
    parameter AXI_STRBW     = AXI_DATA_WID/8
    )(
    //global input
    input                           aclk                    ,
    input                           aresetn                 ,
    //to wdata fifo
    input                           wdata_fifo_empty_d      ,
    input  [AXI_STRBW-1:0]          wdata_fifo_strb_d       ,
    input  [AXI_DATA_WID-1:0]       wdata_fifo_data_d       ,
    output                          wdata_fifo_pop          ,
    //axi wlen 
    input                           wr_cfg_init             ,
    output                          wlen_fifo_full_s        ,
    input  [3:0]                    wlen_fifo_data_s        ,
    input                           wlen_fifo_push          ,

    input                           axi_burst_waddr_ok      ,
    output                          axi_burst_wdata_ok      ,
    // AXI inf write data 
    output reg                      o_wvalid                ,
    output                          o_wlast                 ,
    output [AXI_IDW-1:0]            o_wid                   ,
    output reg [AXI_DATA_WID-1:0]   o_wdata                 ,
    output reg[AXI_STRBW-1:0]       o_wstrb                 ,
    input                           i_wready                ,
    // AXI write response   
    input                           i_bvalid                ,
    input [AXI_IDW-1:0]             i_bid                   ,
    input [1:0]                     i_bresp                 ,
    output                          o_bready                ,

    //strb
    input  [5:0]                    strb_first_beat_num     ,
    input  [5:0]                    strb_last_beat_num      ,
    input                           dma_trans_first_burst   ,
    input                           dma_trans_last_burst    
);

    enum reg [1:0] {IDLE, TRANS_DATA} cs, ns;
    reg [3:0] wdata_cnt;

    wire                      wlen_fifo_empty_d      ;
    wire [4-1:0]              wlen_fifo_data_d       ;
    wire                      wlen_fifo_pop          ;

    assign  wlen_fifo_pop = (ns == TRANS_DATA) && (cs == IDLE);  

    DW_fifo_s1_sf #(.width(4),  .depth(4),   .err_mode(0),  .rst_mode(0))
     U_axi_wlen_fifo (
    .clk                (aclk                       ),   
    .rst_n              (aresetn                    ),   
    .push_req_n         (!wlen_fifo_push            ),
    .pop_req_n          (!wlen_fifo_pop             ),   
    .diag_n             (!wr_cfg_init               ),
    .data_in            (wlen_fifo_data_s           ),   
    .empty              (wlen_fifo_empty_d          ),
    .almost_empty       (),   
    .half_full          (),
    .almost_full        (),   
    .full               (wlen_fifo_full_s           ),
    .error              (),   
    .data_out           (wlen_fifo_data_d           ) 
    );


//==================================================
// b
//==================================================

//always @(posedge aclk or negedge aresetn) begin
//    if (!aresetn) begin
//        o_bready <= 1'b0;
//    end 
//    else if(axi_trans_addr_ok) o_bready <= 1'b1;
//    else if(i_bvalid && i_bresp == 2'b00)  o_bready <= 1'b0;
//end

assign o_wid = 'b0;
assign o_bready = 1'b1;
assign axi_burst_wdata_ok = o_bready && i_bvalid &&(i_bresp == 2'b00);
assign axi_wdata_beat_ok = i_wready && o_wvalid;


//==================================================
// fsm
//==================================================

always @(posedge aclk or negedge aresetn) begin
    if(!aresetn) 
        cs  <=  IDLE;
    else 
        cs  <=  ns;
end

always @(*) begin
    case(cs)
        IDLE:begin
            if(!wlen_fifo_empty_d && !wdata_fifo_empty_d)
                ns = TRANS_DATA;
            else
                ns = IDLE;
        end
        TRANS_DATA:begin
            if(wdata_cnt == 'b0 && axi_wdata_beat_ok)
                ns = IDLE ;
            else 
                ns = TRANS_DATA;
        end
        default:ns=IDLE;
    endcase
end


always @(posedge aclk or negedge aresetn) begin
    if(!aresetn) 
        wdata_cnt <= 'b0;
    else if((ns == TRANS_DATA) && (cs == IDLE))
        wdata_cnt <= wlen_fifo_data_d;
    else if(cs == TRANS_DATA && wdata_cnt!= 0 &&  axi_wdata_beat_ok )
        wdata_cnt <= wdata_cnt - 1;
end

//assign wdata_fifo_pop = (/*axi_burst_waddr_ok*/wlen_fifo_pop || axi_wdata_beat_ok) && (ns == TRANS_DATA) && (!wdata_fifo_empty_d);
assign wdata_fifo_pop = (ns == TRANS_DATA) && (i_wready |(!o_wvalid)) && (!wdata_fifo_empty_d);//eco:add "|(!o_wvalid)"
assign o_wlast = axi_wdata_beat_ok && (wdata_cnt == 'b0);

always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
        o_wdata <= 'd0;
        o_wstrb <= 'd0;
    end
    else if(wdata_fifo_pop) begin 
        o_wdata <= wdata_fifo_data_d;
        o_wstrb <= wdata_fifo_strb_d;
    end
end

always @(posedge aclk or negedge aresetn) begin
    if (!aresetn)
        o_wvalid <= 1'b0;
   // else if(/*wdata_fifo_pop*/) 
   //     o_wvalid <= 1'b1;
   // else if(axi_wdata_beat_ok) 
   //     o_wvalid <= 1'b0;
   else if (i_wready |(!o_wvalid))//eco 2 
        o_wvalid <= (!wdata_fifo_empty_d)&&(ns == TRANS_DATA);//after eco
end
/*
always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) 
        wdata_fifo_pop <= 1'b0;
    else if(o_wvalid && ~i_wready) 
        wdata_fifo_pop <= 1'b0;
    else if((ns == TRANS_DATA) && (!wdata_fifo_empty_d))
        wdata_fifo_pop <= 1'b1;
end
*/
endmodule
