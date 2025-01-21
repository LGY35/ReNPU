module axi_addr_cross4k #(
    parameter AXI_IDW       = 4                                 ,
    parameter AXI_SIZE      = 3'd4                              ,
    parameter AXI_LOCKW     = 2                                 ,
    parameter ID            = 0

 )(
        input                           aclk                    ,
        input                           aresetn                 ,
        // AXI write request
        output                          o_axvalid               ,
        output [AXI_IDW-1:0]            o_axid                  ,
        output [32-1:0]                 o_axaddr                ,
        output [4-1:0]                  o_axlen                 ,
        output [2:0]                    o_axsize                ,
        output [1:0]                    o_axburst               ,
        output [AXI_LOCKW-1:0]          o_axlock                ,
        output [3:0]                    o_axcache               ,
        output [2:0]                    o_axprot                ,
        input                           i_axready               ,
        //
        input                           cfg_cross4k_en          ,
        input                           x_burst_arvld_disable  ,
        //
        output                          axi_burst_xaddr_ok      ,
        input                           axi_burst_xdata_ok      ,
        //
        input                           dma_trans_burst_avalid  ,
        input       [31:0]              dma_trans_burst_addr    ,
        input       [3:0]               dma_trans_burst_len     ,

        output                          dma_xaddr_burst_ok      ,
        output  reg                     cross_4k_stage          ,
        output                          cross_4k_flag           ,
        output                          cross_4k_flag_fst//new
 );


wire [31:0]     maddr_first                   ;
wire [3:0]      mlen_first                    ;
wire [31:0]     mlen_first_real               ;
wire [31:0]     maddr_last                    ;
wire [3:0]      mlen_last                     ;

wire [31:0]     axi_maddr_burst_start         ;
wire [31:0]     axi_maddr_burst_end           ;

wire            burst_cross_4k                ;

reg  [31:0]     axi_maddr                     ;
reg  [3:0]      axi_mlen                      ;
reg  [3:0]      axi_mvld                      ;

wire [4:0]      dma_trans_burst_len_real;

//---------------------------------------------------------------------
//==================================================
// ar
//==================================================
reg [AXI_IDW-1:0] axid;
reg [2:0] axsize;
reg [1:0] axburst;
reg [AXI_LOCKW-1:0] axlock;
reg [3:0] axcache;
reg [2:0] axprot;
always @(posedge aclk or negedge aresetn) begin
    if(!aresetn) begin
        axid    <= ID[AXI_IDW-1:0];
        axsize  <= AXI_SIZE;
        axburst <= 2'b1;
        axlock  <= {AXI_LOCKW{1'b0}};
        axcache <= 4'b0;
        axprot  <= 3'b0;
    end
    else begin
        axid    <= ID[AXI_IDW-1:0];
        axsize  <= AXI_SIZE;
        axburst <= 2'b1;
        axlock  <= {AXI_LOCKW{1'b0}};
        axcache <= 4'b0;
        axprot  <= 3'b0;
    end
end

assign  o_axid    = axid;
assign  o_axsize  = axsize;
assign  o_axburst = axburst;
assign  o_axlock  = axlock;
assign  o_axcache = axcache;
assign  o_axprot  = axprot;
assign  o_axaddr  = axi_maddr;
assign  o_axlen   = axi_mlen;
assign  o_axvalid = axi_mvld;
assign  axi_burst_xaddr_ok = o_axvalid && i_axready;


//----------------------------------------------------------

enum reg[1:0]    { IDLE,  CROSS4K_FST,  CROSS4K_LST } cs , ns;

//-----------------------cross 4k assertion--------------------------
assign dma_trans_burst_len_real = {1'b0, dma_trans_burst_len} + 5'b1;
assign axi_maddr_burst_start = dma_trans_burst_addr ;
assign axi_maddr_burst_end   = dma_trans_burst_addr + {23'b0, dma_trans_burst_len_real, 4'b0} -1 ;

assign burst_cross_4k =  cfg_cross4k_en & (axi_maddr_burst_start[12] ^ axi_maddr_burst_end[12]);

//assign cross_4k_flag = burst_cross_4k & axi_burst_xaddr_ok ; //pulse
assign cross_4k_flag = burst_cross_4k & dma_xaddr_burst_ok; //pulse
assign cross_4k_flag_fst = burst_cross_4k & axi_burst_xaddr_ok  & (cs == CROSS4K_FST);
//-----------------------------FSM---------------------------------
always @(posedge aclk or negedge aresetn) begin
    if(!aresetn)
            cs <= IDLE;
    else
            cs <= ns;
end

always @(*) begin
    case(cs)
        IDLE:  
            if(dma_trans_burst_avalid && (!x_burst_arvld_disable) && burst_cross_4k)
                    ns = CROSS4K_FST;
            else
                    ns = IDLE;
        CROSS4K_FST:  
            if(axi_burst_xaddr_ok)
                    ns = CROSS4K_LST;
            else
                    ns = CROSS4K_FST;                    
        CROSS4K_LST:  
            if(axi_burst_xaddr_ok)
                    ns = IDLE;
            else
                    ns = CROSS4K_LST;
        default:    ns = IDLE;
    endcase
end



//----------------------Input from inner fsm-------------------------

assign   dma_xaddr_burst_ok = axi_burst_xaddr_ok  & (burst_cross_4k ? cs == CROSS4K_LST :  1'b1);

//-----------------------output to gm port---------------------------
assign maddr_first = dma_trans_burst_addr ;
assign mlen_first_real = ((32'h1000 - (maddr_first & 32'hff0))>>4) -1;
assign mlen_first  = mlen_first_real[3:0];
assign maddr_last  = axi_maddr_burst_end & 32'hFFFF_F000;
assign mlen_last   = dma_trans_burst_len - mlen_first -1;


always @(*) begin
    case(cs)
        IDLE: begin
                axi_mvld   = dma_trans_burst_avalid && (!burst_cross_4k)&& (!x_burst_arvld_disable);
                axi_maddr  = dma_trans_burst_addr;
                axi_mlen   = dma_trans_burst_len;
              end
        CROSS4K_FST: begin
                axi_mvld   = dma_trans_burst_avalid;
                axi_maddr  = maddr_first;
                axi_mlen   = mlen_first;
              end
        CROSS4K_LST: begin
                axi_mvld   = 1'b1;
                axi_maddr  = maddr_last;
                axi_mlen   = mlen_last;
              end
        default: begin
                axi_mvld   = dma_trans_burst_avalid && (!burst_cross_4k)&& (!x_burst_arvld_disable);
                axi_maddr  = dma_trans_burst_addr;
                axi_mlen   = dma_trans_burst_len;
              end
    endcase
end

//==================================================
// cross_4k_stage
//==================================================

always @(posedge aclk or negedge aresetn) begin
    if (!aresetn)      
        cross_4k_stage <= 'd0;
    else if(cross_4k_flag ) 
        cross_4k_stage <= 'd1;
    else if(axi_burst_xdata_ok ) 
        cross_4k_stage <=  'd0;
end



endmodule
