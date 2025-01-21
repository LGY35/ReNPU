module axi_addr_manager(
	input				        aclk,
	input				        aresetn,

	input				        rd_cfg_ready        , 
	input	[3:0]			    rd_cfg_outstd       , 
	input	     			    rd_cfg_outstd_en    , 

	input	[31:0]		        raddr_fifo_rd_num_word  ,  //word
	input	[31:0]		        raddr_fifo_raddr_in     ,
	input				        raddr_fifo_empty        ,
    output                      raddr_fifo_pop          , 

    input                       cross_4k_stage      ,
    input                       cross_4k_flag       ,
    input                       cross_4k_flag_fst   ,

	input				        dma_raddr_burst_ok  ,
	input				        axi_burst_rdata_ok  ,

	output	reg	 [3:0]	        dma_trans_burst_len    ,
	output	reg	 [31:0]	        dma_trans_burst_addr   ,
	output	reg	    	        dma_trans_burst_avalid ,
    
    //
    output reg [5:0]            strb_first_beat_num     ,
    output reg [5:0]            strb_last_beat_num      ,
    output                      dma_trans_first_burst   ,
    output                      dma_trans_last_burst    ,
    //trans done
	output	    		        read_all_done
);

//==================================================
// wire and regs
//==================================================

wire 	[31-5-4:0]	trans_rdata_num_burst8_w;
reg  	[31-5-4:0]	trans_raddr_num_burst8;
reg  	[31-5-4:0]	trans_rdata_num_burst8;
reg 	[31-5-4:0]	trans_rdata_num_burst; //trans_rdata_num_burst8_w + trans_raddr_num_last_burst
reg 	[31-5-4:0]	trans_raddr_num_burst;
reg 	[31-5-4:0]	trans_rdata_cnt_burst8;
reg 	[31-5-4:0]	trans_raddr_cnt_burst8;
wire    [31-5-4:0]	trans_raddr_cnt_burst ; //trans_raddr_cnt_burst8+trans_raddr_cnt_last_burst
reg     [31-5-4:0]	trans_rdata_cnt_burst ; //trans_rdata_cnt_burst8+trans_rdata_cnt_last_burst

//last data
reg 	[1:0]    	trans_rdata_num_last_burst;
reg 	[1:0]   	trans_rdata_cnt_last_burst;

//last addr
reg 	    	    trans_raddr_num_last_burst;
reg 	    	    trans_raddr_cnt_last_burst;

reg 	[3:0]	    trans_rdata_peat_num_last;
wire 	[3:0]	    trans_rdata_peat_num_last_w;

reg  			    all_burst8_trans;

reg				    trans_raddr_burst8_done_r;
wire			    cfg_ready_last;

reg [31:0]          aligned_8woraddr  ;

wire [31:0]         raddr_align_word_start;

reg                 strb_flag            ;

enum reg [2:0] { TRANS_IDLE, TRANS_PRO_ADDR, TRANS_BURST8, TRANS_LAST, TRANS_OVER} trans_rdata_cs, trans_rdata_ns, trans_raddr_cs, trans_raddr_ns ;

assign raddr_align_word_start = {raddr_fifo_raddr_in[31:2], 2'b0};

wire [31:0] aligned_4word_addr_w =  raddr_align_word_start  & 32'hffff_fff0 ;
// addr fifo pop
assign raddr_fifo_pop = (!raddr_fifo_empty)&&(trans_raddr_ns == TRANS_PRO_ADDR);

wire raddr_strb_flag_w       = (raddr_align_word_start&32'hf)? 1 : 0;
wire rdata_num_strb_flag_w   = (raddr_fifo_rd_num_word[29:0] & 'b11) + ((raddr_align_word_start & 32'hf)>>2) > 4 ? 1 : 0;

//align addr to word (32BIT)
wire [31:0]   rd_num_byte       =  raddr_fifo_rd_num_word[29:0] << 2; // byte num = raddr_fifo_rd_num_word<<2;
wire [31-5:0] rd_num_4word_nm   =  raddr_fifo_rd_num_word[29:0] >> 2; //4word num = raddr_fifo_rd_num_word>>2;
//rd word num to rd 4 word(128) num, if less than one 4word, its 1;
wire [31-5:0] rd_num_4word_w    = (raddr_align_word_start + rd_num_byte) > (aligned_4word_addr_w + 16) ? 
                                  (rd_num_4word_nm + raddr_strb_flag_w + rdata_num_strb_flag_w) : 1;

assign trans_rdata_num_burst8_w = (rd_num_4word_w >> 3);
assign trans_rdata_peat_num_last_w =  rd_num_4word_w - (trans_rdata_num_burst8_w << 3); //single trans data num

reg raddr_done_enble ;

always @(posedge aclk or negedge aresetn) begin
    if(!aresetn) begin
        strb_flag                   <= 'b0;
        raddr_done_enble            <= 'b0;
        aligned_8woraddr            <= 'b0;  
        strb_first_beat_num         <= 'b0;
        strb_last_beat_num          <= 'b0;          
        trans_rdata_num_burst8      <= 'b0;
        trans_raddr_num_burst8      <= 'b0;
        trans_rdata_peat_num_last   <= 'b0;
        trans_rdata_num_burst       <= 'b0;
        trans_rdata_num_last_burst  <= 'b0;         
        trans_raddr_num_burst       <= 'b0; 
        trans_raddr_num_last_burst  <= 'b0;         
        all_burst8_trans            <= 'b0; 
     end
    else if(trans_raddr_ns == TRANS_IDLE) begin
        strb_flag                   <= 'b0;
        raddr_done_enble            <= 'b0;
        aligned_8woraddr            <= 'b0;  
        strb_first_beat_num         <= 'b0;
        strb_last_beat_num          <= 'b0;          
        trans_rdata_num_burst8      <= 'b0;
        trans_raddr_num_burst8      <= 'b0;
        trans_rdata_peat_num_last   <= 'b0;
        trans_rdata_num_burst       <= 'b0;
        trans_rdata_num_last_burst  <= 'b0;         
        trans_raddr_num_burst       <= 'b0; 
        trans_raddr_num_last_burst  <= 'b0;         
        all_burst8_trans            <= 'b0; 
     end
    else if(trans_raddr_ns == TRANS_PRO_ADDR) begin           
        strb_flag                   <= raddr_strb_flag_w;  //no align 128
        raddr_done_enble            <= raddr_fifo_raddr_in[0];
        aligned_8woraddr            <= aligned_4word_addr_w;            
        strb_first_beat_num         <= raddr_align_word_start & 'hf ; //raddr_align_word_start -  aligned_4word_addr_w ; // aligned_addr = raddr_align_word_start  & 32'hffff_fff0;
        strb_last_beat_num          <= ((raddr_align_word_start & 'hf) + rd_num_byte) & 32'hf; //strb_first_beat_num = raddr_align_word_start - aligned_addr
        trans_rdata_num_burst8      <= trans_rdata_num_burst8_w; //busrt8 num
        trans_raddr_num_burst8      <= trans_rdata_num_burst8_w ; //busrt8 num
        trans_rdata_peat_num_last   <= trans_rdata_peat_num_last_w; 
        trans_rdata_num_burst       <= trans_rdata_num_burst8_w + (|trans_rdata_peat_num_last_w)  ; //busrt8 num
        trans_raddr_num_burst       <= trans_rdata_num_burst8_w + (|trans_rdata_peat_num_last_w)  ; //busrt8 num
        trans_raddr_num_last_burst  <= (|trans_rdata_peat_num_last_w); 
        trans_rdata_num_last_burst  <= (|trans_rdata_peat_num_last_w);
        all_burst8_trans            <= (trans_rdata_peat_num_last_w == 0); // if single trans data num
     end
    else if((trans_raddr_ns == TRANS_BURST8 || trans_raddr_ns == TRANS_LAST)&& cross_4k_flag_fst) begin  // pro cross4k
        trans_rdata_num_burst8      <= trans_rdata_num_burst8    + (( trans_raddr_cs == TRANS_BURST8 ) ? 1 :0) ; // if cross4k in trans busrt8 , then +1 to trans_rdata_num_burst8
        trans_rdata_num_last_burst  <= trans_rdata_num_last_burst + (( trans_raddr_cs == TRANS_LAST )? 1 : 0);  // if cross4k in trans last , then +1 to  trans_rdata_peat_num_last
        trans_rdata_num_burst       <= trans_rdata_num_burst + 1;
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

wire trans_raddr_burst8_done     = (trans_raddr_num_burst8-1 == trans_raddr_cnt_burst8) & dma_raddr_burst_ok & (trans_raddr_cs ==  TRANS_BURST8);
wire trans_raddr_last_busrt_done  = (trans_raddr_num_last_burst-1 == trans_raddr_cnt_last_burst) & dma_raddr_burst_ok & (trans_raddr_cs ==  TRANS_LAST);

always @(posedge aclk or negedge aresetn) begin 
    if(!aresetn) 
        trans_raddr_cnt_burst8 <= 'b0; 
    else if(trans_raddr_burst8_done)
        trans_raddr_cnt_burst8 <= 'b0;
    else if(dma_raddr_burst_ok && trans_raddr_cs == TRANS_BURST8)
        trans_raddr_cnt_burst8 <= trans_raddr_cnt_burst8 + 1;
end

always @(posedge aclk or negedge aresetn) begin
    if(!aresetn)
        trans_raddr_cnt_last_burst <= 'b0;
    else if(trans_raddr_cs !=  TRANS_LAST/*trans_raddr_last_busrt_done*/)
        trans_raddr_cnt_last_burst <= 'b0;
    else if(dma_raddr_burst_ok && trans_raddr_cs == TRANS_LAST)
        trans_raddr_cnt_last_burst <= 'b1;
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
                trans_raddr_ns = trans_rdata_num_burst8 > 0 ? TRANS_BURST8 : TRANS_LAST;
        TRANS_BURST8:  
            if(trans_raddr_burst8_done && !all_burst8_trans)
                trans_raddr_ns = TRANS_LAST;
            else if(trans_raddr_burst8_done && all_burst8_trans)
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
        TRANS_BURST8: begin
              	dma_trans_burst_len = 4'd7;
              end
        TRANS_LAST: begin
              	dma_trans_burst_len = trans_rdata_peat_num_last - 1;
              end
        default: begin
              	dma_trans_burst_len = 4'd7;
              end
    endcase
end

wire trans_raddr_st = (trans_raddr_cs == TRANS_BURST8) || (trans_raddr_cs  == TRANS_LAST);
//wire trans_raddr_st = ( trans_raddr_ns == TRANS_BURST8) || (trans_raddr_ns  == TRANS_LAST);

//--------------------outstanding------------------//

enum reg [2:0] {OUTSTD_IDLE,OUTSTD_PRO, OUTSTD_TRANS, OUTSTD_DIS           } outstd_cs, outstd_ns;

//reg [4:0] outstd_raddr_cnt;
//reg [5:0] outstd_rdata_cnt;  //if cross 4k , 1 more than raddr_cnt
reg [3:0] outstd_raddr_cnt;
reg [4:0] outstd_rdata_cnt;  //if cross 4k , 1 more than raddr_cnt 


always @(posedge aclk or negedge aresetn) begin
    if(!aresetn)
        outstd_cs <= OUTSTD_IDLE;
    else
        outstd_cs <= outstd_ns;
end

assign 	 trans_raddr_cnt_burst = trans_raddr_cnt_burst8 + trans_raddr_cnt_last_burst;

//wire             trans_raddr_done = (trans_raddr_cnt_burst ==  trans_raddr_num_burst - 1) && dma_raddr_burst_ok;
wire             trans_raddr_done = dma_raddr_burst_ok && (trans_raddr_num_last_burst ? trans_raddr_last_busrt_done : trans_raddr_burst8_done);
wire [31-5-4:0]	 trans_raddr_remain_burst = trans_raddr_num_burst - trans_raddr_cnt_burst;


reg outstd_cross_4k_stage ;

always @(*) begin
    case(outstd_cs)
    OUTSTD_IDLE: 
            if(!raddr_fifo_empty && dma_trans_burst_run)
                outstd_ns = OUTSTD_PRO;
            else
                outstd_ns = OUTSTD_IDLE;
    OUTSTD_PRO:
            if((trans_raddr_remain_burst > rd_cfg_outstd) && rd_cfg_outstd_en )  
                outstd_ns = OUTSTD_TRANS;
            else
                outstd_ns = OUTSTD_DIS;
    OUTSTD_TRANS:
            if((trans_raddr_remain_burst < rd_cfg_outstd) && (outstd_rdata_cnt == rd_cfg_outstd + outstd_cross_4k_stage))  
                outstd_ns = OUTSTD_DIS;
            else
                outstd_ns = OUTSTD_TRANS;
    OUTSTD_DIS:
            if(trans_raddr_done)
                outstd_ns = OUTSTD_IDLE;
            else
                outstd_ns = OUTSTD_DIS;
    default: outstd_ns = OUTSTD_IDLE;
    endcase
end






//outstanding receive data burst

always @(posedge aclk or negedge aresetn) begin
    if(!aresetn)
        outstd_cross_4k_stage <= 'b0;
    else if(cross_4k_flag && (outstd_cs == OUTSTD_TRANS))
        outstd_cross_4k_stage <= 'b1;
    else if( outstd_rdata_cnt == rd_cfg_outstd+1) //outstd rdata over
        outstd_cross_4k_stage <= 'b0;
end


always @(posedge aclk or negedge aresetn) begin
    if(!aresetn)
        outstd_rdata_cnt <= 'b0;
    else if((outstd_raddr_cnt == rd_cfg_outstd) && (outstd_rdata_cnt == rd_cfg_outstd + outstd_cross_4k_stage) || (outstd_cs !=  OUTSTD_TRANS) )
         outstd_rdata_cnt <= 'b0;
    else if(axi_burst_rdata_ok && (outstd_cs ==  OUTSTD_TRANS) && (outstd_rdata_cnt < rd_cfg_outstd + outstd_cross_4k_stage))
        outstd_rdata_cnt <= outstd_rdata_cnt + 1;
end



//outstanding receive addr burst
always @(posedge aclk or negedge aresetn) begin
    if(!aresetn)
        outstd_raddr_cnt <= 'b0;
    else if((outstd_raddr_cnt == rd_cfg_outstd && outstd_rdata_cnt == rd_cfg_outstd + outstd_cross_4k_stage) || (outstd_cs != OUTSTD_TRANS))
        outstd_raddr_cnt <= 'b0;
    else if(dma_raddr_burst_ok && (outstd_cs ==  OUTSTD_TRANS) && (outstd_raddr_cnt < rd_cfg_outstd))
        outstd_raddr_cnt <= outstd_raddr_cnt + 1;
end


always @(posedge aclk or negedge aresetn) begin
    if(!aresetn) 
        dma_trans_burst_avalid <= 'b0;
    else if(trans_raddr_st) begin
        if(rd_cfg_outstd_en) begin  //outstding
            if(outstd_cs == OUTSTD_TRANS) begin
                if(outstd_raddr_cnt < rd_cfg_outstd-1)
                    dma_trans_burst_avalid <=  1'b1;
                else if((outstd_raddr_cnt == rd_cfg_outstd-1) && dma_raddr_burst_ok)
                    dma_trans_burst_avalid <=  1'b0;
            end
            else if(dma_raddr_burst_ok) begin
                dma_trans_burst_avalid <=  1'b0;
            end
            else if(trans_raddr_remain_burst!=0) begin
                dma_trans_burst_avalid <=  1'b1;
            end
        end
        else if(dma_raddr_burst_ok) 
            dma_trans_burst_avalid <= 1'b0;        
        else if(((trans_raddr_cnt_burst == 0)&&((trans_raddr_ns == TRANS_BURST8) || (trans_raddr_ns  == TRANS_LAST)))/*&(trans_raddr_cs!=TRANS_LAST)*/ || axi_burst_rdata_ok /*& (!cross_4k_stage)*/)  //outstanding, block burst ok in 4k fist stage
            dma_trans_burst_avalid <= 1'b1;
    end
    else
        dma_trans_burst_avalid <= 'b0;

end

//send raddr
always @(posedge aclk or negedge aresetn) begin
    if(!aresetn)
        dma_trans_burst_addr <= 'b0;
    else if(outstd_ns ==  OUTSTD_IDLE)//(outstd_cs ==  OUTSTD_IDLE)
        dma_trans_burst_addr <= 'b0;
    else if(outstd_ns ==  OUTSTD_PRO)//(outstd_cs ==  OUTSTD_PRO)
        dma_trans_burst_addr <= aligned_4word_addr_w ;
    else if(dma_raddr_burst_ok && dma_trans_burst_avalid )
        dma_trans_burst_addr <= dma_trans_burst_addr + ((dma_trans_burst_len + 1)<<5) ;
end


always @(posedge aclk or negedge aresetn) begin
    if(!aresetn)
        trans_rdata_cnt_burst <= 'b0;
    else if(trans_rdata_cnt_burst == trans_rdata_num_burst || trans_raddr_cs == TRANS_IDLE)
        trans_rdata_cnt_burst <= 'b0;
    else if(axi_burst_rdata_ok && trans_rdata_cnt_burst < trans_rdata_num_burst)
        trans_rdata_cnt_burst <= trans_rdata_cnt_burst + 1;
end




// assign dma_trans_first_burst = (trans_rdata_cnt_burst == 0) && (trans_raddr_cs == TRANS_BURST8 || trans_raddr_cs == TRANS_LAST);
assign dma_trans_first_burst = (trans_rdata_cnt_burst == 0) && (trans_raddr_cs == TRANS_BURST8 || trans_raddr_cs == TRANS_LAST || trans_raddr_cs== TRANS_OVER);
assign dma_trans_last_burst = (trans_rdata_num_burst - trans_rdata_cnt_burst == 1);//&&  (trans_raddr_cs == TRANS_OVER) ;

// assign read_all_done = raddr_done_enble &&(trans_rdata_cnt_burst == trans_rdata_num_burst );
assign read_all_done = (trans_raddr_cs==TRANS_OVER) && (trans_rdata_cnt_burst == trans_rdata_num_burst );
endmodule