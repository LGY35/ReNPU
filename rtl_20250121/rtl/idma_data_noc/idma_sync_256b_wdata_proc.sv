module idma_sync_256b_wdata_proc #(
    parameter AXI_IDW       = 4             ,
    parameter AXI_DATA_WID  = 256           ,
    parameter AXI_STRBW     = AXI_DATA_WID/8,
    parameter ID            = 0
    )(
    //global input
    input                           aclk                    ,
    input                           aresetn                 ,
    //to wdata fifo
    input                           wdata_fifo_empty_d      ,
    input  [AXI_STRBW-1:0]          wdata_fifo_strb_d       ,
    input  [AXI_DATA_WID-1:0]       wdata_fifo_data_d       ,
    output                          wdata_fifo_pop          ,
    input                           wdata_fifo_valid        ,
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
    // input  [5:0]                    strb_first_beat_num     ,
    // input  [5:0]                    strb_last_beat_num      ,
    input                           dma_trans_first_burst   ,
    input                           dma_trans_last_burst    
);

    enum reg [1:0] {IDLE, TRANS_DATA, TRANS_CONTINUE} cs, ns;
    reg [3:0] wdata_cnt;

    wire                      wlen_fifo_empty      ;
    wire [4-1:0]              wlen_fifo_data       ;
    wire                      wlen_fifo_pop          ;
    wire                      axi_wlen_fifo_ready_out;
    wire                      axi_wlen_fifo_valid_out;
    wire                      axi_wdata_beat_ok      ;

     

    assign wlen_fifo_full_s = !axi_wlen_fifo_ready_out;
    fifo #(
        .DATA_W(4),
        .DEPTH(8)
    ) U_axi_wlen_fifo(
        .clk(aclk),
        .rst_n(aresetn),
        .f_valid_in(wlen_fifo_push),
        .f_data_in(wlen_fifo_data_s),
        .f_ready_out(axi_wlen_fifo_ready_out),
        .b_valid_out(axi_wlen_fifo_valid_out),
        .b_data_out(wlen_fifo_data),
        .b_ready_in(wlen_fifo_pop)
    );
    assign wlen_fifo_pop    = ((ns == TRANS_DATA) && (cs == IDLE)) || (ns == TRANS_CONTINUE); 
    assign wlen_fifo_empty  = !axi_wlen_fifo_valid_out;

//==================================================
// b
//==================================================

assign o_wid = {AXI_IDW{1'b0}};
assign o_bready = 1'b1;
assign axi_burst_wdata_ok = o_bready && i_bvalid &&(i_bresp == 2'b00) && (i_bid==ID[AXI_IDW-1:0]);
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
            if(!wlen_fifo_empty && !wdata_fifo_empty_d)
                ns = TRANS_DATA;
            else
                ns = IDLE;
        end
        TRANS_DATA:begin
            if(wdata_cnt == 4'b0 && axi_wdata_beat_ok && wlen_fifo_empty)
                ns = IDLE;
            else if(wdata_cnt == 4'b0 && axi_wdata_beat_ok)
                ns = TRANS_CONTINUE;
            else
                ns = TRANS_DATA;
        end
        TRANS_CONTINUE: begin
            if (wdata_cnt == 4'b0 && axi_wdata_beat_ok && !wlen_fifo_empty)
                ns = TRANS_CONTINUE;
            else
                ns = TRANS_DATA;
        end
        default:ns=IDLE;
    endcase
end


always @(posedge aclk or negedge aresetn) begin
    if(!aresetn) 
        wdata_cnt <= 4'b0;
    else if(wlen_fifo_pop && axi_wlen_fifo_valid_out)
        wdata_cnt <= wlen_fifo_data;
    else if((cs == TRANS_DATA || cs == TRANS_CONTINUE) && wdata_cnt!= 4'b0 && axi_wdata_beat_ok )
        wdata_cnt <= wdata_cnt - 1;
end

assign wdata_fifo_pop = (ns == TRANS_DATA || ns == TRANS_CONTINUE) && (i_wready |(!o_wvalid));
assign o_wlast = (wdata_cnt == 4'b0) && o_wvalid;

always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
        o_wdata <= 'd0;
        o_wstrb <= 'd0;
    end
    else if(wdata_fifo_valid && wdata_fifo_pop) begin 
        o_wdata <= wdata_fifo_data_d;
        o_wstrb <= wdata_fifo_strb_d;
    end
end

always @(posedge aclk or negedge aresetn) begin
    if (!aresetn)
        o_wvalid <= 1'b0;
   else if (i_wready |(!o_wvalid))
        o_wvalid <= (wdata_fifo_valid && wdata_fifo_pop);
end

endmodule
