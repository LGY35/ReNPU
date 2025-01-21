module idma_sync_256b_addr_manager(
input                       aclk,
input                       aresetn,
// config
input                       rd_cfg_ready        , 
input   [3:0]               rd_cfg_outstd       , 
input                       rd_cfg_outstd_en    , 
// addr/len FIFO
input   [31:0]              raddr_fifo_rd_num_word  ,  //word
input   [31:0]              raddr_fifo_raddr_in     ,
input                       raddr_fifo_empty        ,
output                      raddr_fifo_pop          , 
// cross 4K
input                       cross_4k_stage      ,
input                       cross_4k_flag       ,
input                       cross_4k_flag_fst   ,
// AXI signals
input                       dma_raddr_burst_ok  ,
input                       axi_burst_rdata_ok  ,
output  reg  [3:0]          dma_trans_burst_len    ,
output  reg  [31:0]         dma_trans_burst_addr   ,
output  reg                 dma_trans_burst_avalid ,
// AXI INFO
// output       [5:0]          strb_first_beat_num     ,
// output       [5:0]          strb_last_beat_num      ,
output                      dma_trans_first_burst   ,
output                      dma_trans_last_burst    ,
//trans done
output                      read_all_done           ,
// back pressure
input                       wlen_fifo_full_s
);

//==================================================
// wire and regs
//==================================================
// ------------------stage 0------------------
wire [28:0]         rd_num_8word_w;
wire [24:0]	        trans_rdata_num_burst16_w;
wire [3:0]          trans_rdata_beat_num_last_w;

// ------------------stage 1------------------
reg  [24:0]  trans_raddr_num_burst16;
reg  [25:0]  trans_raddr_num_burst;
reg          trans_raddr_num_last_burst;

reg  [24:0]  trans_rdata_num_burst16;
reg  [25:0]  trans_rdata_num_burst;
reg  [3:0]   trans_rdata_beat_num_last;

reg          all_burst16_trans;

// ------------------FSM------------------
reg 	[24:0]      trans_raddr_cnt_burst16;
wire    [25:0]      trans_raddr_cnt_burst;
reg     [25:0]      trans_rdata_cnt_burst;
reg                 trans_raddr_cnt_last_burst;
wire                trans_raddr_done;
wire    [25:0]      trans_raddr_remain_burst;

// FSM state
enum reg [2:0] { TRANS_IDLE, TRANS_PRO_ADDR, TRANS_BURST16, TRANS_LAST, TRANS_OVER} trans_raddr_cs, trans_raddr_ns ;

// outstanding
reg [3:0] outstd_raddr_cnt;
wire [4:0] dma_trans_burst_len_real = {1'b0, dma_trans_burst_len} + 5'b1;
wire [31:0] dma_trans_burst_len_extd = {22'b0, dma_trans_burst_len_real, 5'b0};

//==================================================
// Stage 0
//==================================================
// 8word num = raddr_fifo_rd_num_word /8;
assign rd_num_8word_w = raddr_fifo_rd_num_word[31:3];
// burst16 num = rd_num_8word_w /16;
assign trans_rdata_num_burst16_w = rd_num_8word_w[28:4];
// beats num of last trans
assign trans_rdata_beat_num_last_w = rd_num_8word_w[3:0];


//==================================================
// Stage 1
//==================================================
always @(posedge aclk or negedge aresetn) begin
    if(!aresetn) begin
        // addr
        trans_raddr_num_burst16     <= 25'b0;
        trans_raddr_num_burst       <= 26'b0;
        trans_raddr_num_last_burst  <= 1'b0;
        // data
        trans_rdata_num_burst16     <= 25'b0;
        trans_rdata_num_burst       <= 26'b0;
        trans_rdata_beat_num_last   <= 4'b0;

        all_burst16_trans           <= 1'b0;
     end
    else if(trans_raddr_ns == TRANS_IDLE) begin 
        // addr
        trans_raddr_num_burst16     <= 25'b0;
        trans_raddr_num_burst       <= 26'b0; 
        trans_raddr_num_last_burst  <= 1'b0; 
        // data
        trans_rdata_num_burst16     <= 25'b0;
        trans_rdata_num_burst       <= 26'b0; 
        trans_rdata_beat_num_last   <= 4'b0;
        
        all_burst16_trans           <= 1'b0; 
     end
    else if(trans_raddr_ns == TRANS_PRO_ADDR) begin
        // addr
        trans_raddr_num_burst16     <= trans_rdata_num_burst16_w;
        trans_raddr_num_burst       <= {1'b0, trans_rdata_num_burst16_w} + {25'b0, (|trans_rdata_beat_num_last_w)};
        trans_raddr_num_last_burst  <= (|trans_rdata_beat_num_last_w);
        // data
        trans_rdata_num_burst16     <= trans_rdata_num_burst16_w;
        trans_rdata_num_burst       <= {1'b0, trans_rdata_num_burst16_w} + {25'b0, (|trans_rdata_beat_num_last_w)};
        trans_rdata_beat_num_last   <= trans_rdata_beat_num_last_w;
        
        all_burst16_trans           <= (trans_rdata_beat_num_last_w == 0);
     end
    else if((trans_raddr_ns == TRANS_BURST16 || trans_raddr_ns == TRANS_LAST) && cross_4k_flag_fst) begin  // pro cross4k
        // if cross4k in trans busrt16 , then +1 to trans_rdata_num_burst16
        trans_rdata_num_burst16     <= trans_rdata_num_burst16 + (( trans_raddr_cs == TRANS_BURST16 ) ? 25'b1 : 25'b0) ; 
        trans_rdata_num_burst       <= trans_rdata_num_burst + 26'b1;
     end
 end



//running
reg dma_trans_burst_run;
always @(posedge aclk or negedge aresetn) begin
    if(!aresetn)
        dma_trans_burst_run <= 1'b0;
    else if(rd_cfg_ready)
        dma_trans_burst_run <= 1'b1;
    else if(read_all_done)
        dma_trans_burst_run <= 1'b0;
end


//==================================================
// trans RADDR fsm
//==================================================
wire trans_raddr_burst16_done     = (trans_raddr_num_burst16-1 == trans_raddr_cnt_burst16) & dma_raddr_burst_ok & (trans_raddr_cs ==  TRANS_BURST16);
wire trans_raddr_last_busrt_done  = (trans_raddr_num_last_burst-1 == trans_raddr_cnt_last_burst) & dma_raddr_burst_ok & (trans_raddr_cs ==  TRANS_LAST);

always @(posedge aclk or negedge aresetn) begin 
    if(!aresetn) 
        trans_raddr_cnt_burst16 <= 25'b0; 
    else if(trans_raddr_burst16_done)
        trans_raddr_cnt_burst16 <= 25'b0;
    else if(dma_raddr_burst_ok && trans_raddr_cs == TRANS_BURST16)
        trans_raddr_cnt_burst16 <= trans_raddr_cnt_burst16 + 1;
end

always @(posedge aclk or negedge aresetn) begin
    if(!aresetn)
        trans_raddr_cnt_last_burst <= 1'b0;
    else if(trans_raddr_cs !=  TRANS_LAST)
        trans_raddr_cnt_last_burst <= 1'b0;
    else if(dma_raddr_burst_ok && trans_raddr_cs == TRANS_LAST)
        trans_raddr_cnt_last_burst <= 1'b1;
end

//fsm
always @(posedge aclk or negedge aresetn) begin
    if(!aresetn)
        trans_raddr_cs <= TRANS_IDLE;
    else
        trans_raddr_cs <= trans_raddr_ns;
end

always @(*) begin
    case(trans_raddr_cs)
        TRANS_IDLE:
            if(!raddr_fifo_empty && dma_trans_burst_run)
                trans_raddr_ns = TRANS_PRO_ADDR;
            else
                trans_raddr_ns = TRANS_IDLE;
        TRANS_PRO_ADDR:
                trans_raddr_ns = trans_rdata_num_burst16 > 0 ? TRANS_BURST16 : TRANS_LAST;
        TRANS_BURST16:  
            if(trans_raddr_burst16_done && !all_burst16_trans)
                trans_raddr_ns = TRANS_LAST;
            else if(trans_raddr_burst16_done && all_burst16_trans)
                trans_raddr_ns = TRANS_OVER;
            else
                trans_raddr_ns = trans_raddr_cs;
        TRANS_LAST:  
            if(trans_raddr_last_busrt_done)
                trans_raddr_ns = TRANS_OVER;
            else
                trans_raddr_ns = trans_raddr_cs;
        TRANS_OVER:  //wait trans data end
            if(trans_rdata_cnt_burst == trans_rdata_num_burst)
                trans_raddr_ns = TRANS_IDLE;
            else
                trans_raddr_ns = trans_raddr_cs;
            
        default: trans_raddr_ns = TRANS_IDLE;
    endcase
end

//len
always @(*) begin
    case(trans_raddr_cs)
        TRANS_BURST16: begin
              	dma_trans_burst_len = 4'd15;
              end
        TRANS_LAST: begin
              	dma_trans_burst_len = trans_rdata_beat_num_last - 4'b1;
              end
        default: begin
              	dma_trans_burst_len = 4'd15;
              end
    endcase
end

wire trans_raddr_st = (trans_raddr_cs == TRANS_BURST16) || (trans_raddr_cs  == TRANS_LAST);


//==================================================
//--------------------outstanding------------------//
//==================================================
assign trans_raddr_cnt_burst = trans_raddr_cnt_burst16 + {24'b0, trans_raddr_cnt_last_burst};

assign trans_raddr_done = dma_raddr_burst_ok && (trans_raddr_num_last_burst ? trans_raddr_last_busrt_done : trans_raddr_burst16_done);

assign trans_raddr_remain_burst = (trans_raddr_cs==TRANS_IDLE || trans_raddr_cs==TRANS_OVER) ? 
                                    26'd0 : (trans_raddr_num_burst - trans_raddr_cnt_burst);

// outstanding receive addr burst
always @(posedge aclk or negedge aresetn) begin
    if(!aresetn)
        outstd_raddr_cnt <= 4'b0;
    else if(trans_raddr_ns==TRANS_IDLE)
        outstd_raddr_cnt <= 4'b0;
    else if(~dma_raddr_burst_ok && axi_burst_rdata_ok && (outstd_raddr_cnt > 4'b0))
        outstd_raddr_cnt <= outstd_raddr_cnt - 1;
    else if(dma_raddr_burst_ok && (outstd_raddr_cnt < rd_cfg_outstd))
        outstd_raddr_cnt <= outstd_raddr_cnt + 1;
end


always @(posedge aclk or negedge aresetn) begin
    if(!aresetn) 
        dma_trans_burst_avalid <= 1'b0;
    else if(trans_raddr_done)
        dma_trans_burst_avalid <= 1'b0;
    else if(trans_raddr_st) begin
        if(rd_cfg_outstd_en && ~wlen_fifo_full_s) begin  //outstding
            if(outstd_raddr_cnt < rd_cfg_outstd-1) begin
                dma_trans_burst_avalid <= 1'b1;
            end
            else if(((outstd_raddr_cnt == rd_cfg_outstd-1) && dma_raddr_burst_ok)
                ||   (outstd_raddr_cnt == rd_cfg_outstd)) begin
                dma_trans_burst_avalid <= 1'b0;
            end
            else if(dma_raddr_burst_ok) begin
                dma_trans_burst_avalid <= 1'b0;
            end
            else if(trans_raddr_remain_burst != 26'b0) begin
                dma_trans_burst_avalid <= 1'b1;
            end
        end
        else if(dma_raddr_burst_ok) 
            dma_trans_burst_avalid <= 1'b0;        
        else if(((trans_raddr_cnt_burst == 0)&&((trans_raddr_ns == TRANS_BURST16) || (trans_raddr_ns  == TRANS_LAST))) 
            || axi_burst_rdata_ok)
            dma_trans_burst_avalid <= 1'b1;
    end
    else
        dma_trans_burst_avalid <= 1'b0;

end

//send raddr
always @(posedge aclk or negedge aresetn) begin
    if(!aresetn)
        dma_trans_burst_addr <= 32'b0;
    else if(trans_raddr_ns == TRANS_IDLE)
        dma_trans_burst_addr <= 32'b0;
    else if(trans_raddr_ns == TRANS_PRO_ADDR)
        dma_trans_burst_addr <= raddr_fifo_raddr_in;
    else if(dma_raddr_burst_ok && dma_trans_burst_avalid )
        dma_trans_burst_addr <= dma_trans_burst_addr + dma_trans_burst_len_extd;
end

// cnt rdata
always @(posedge aclk or negedge aresetn) begin
    if(!aresetn)
        trans_rdata_cnt_burst <= 26'b0;
    else if(trans_rdata_cnt_burst == trans_rdata_num_burst)
        trans_rdata_cnt_burst <= 26'b0;
    else if(axi_burst_rdata_ok && (trans_rdata_cnt_burst < trans_rdata_num_burst))
        trans_rdata_cnt_burst <= trans_rdata_cnt_burst + 1;
end


//==================================================
// Output
//==================================================
// assign strb_first_beat_num = 6'd0;
// assign strb_last_beat_num  = 6'd0;

assign dma_trans_first_burst = (trans_rdata_cnt_burst == 0) && (trans_raddr_cs == TRANS_BURST16 || trans_raddr_cs == TRANS_LAST);
assign dma_trans_last_burst = ((trans_rdata_num_burst - trans_rdata_cnt_burst) == 1);

assign read_all_done = (trans_raddr_cs==TRANS_OVER) && (trans_rdata_cnt_burst == trans_rdata_num_burst);

assign raddr_fifo_pop = (!raddr_fifo_empty) && (trans_raddr_ns == TRANS_PRO_ADDR);

endmodule

