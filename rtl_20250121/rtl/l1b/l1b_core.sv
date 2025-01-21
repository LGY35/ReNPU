module l1b_core #(
            parameter BANK_CH         = 16                          ,
            parameter WORD_WID        = 8                           ,
            parameter LB_CH           = 16                          ,
            parameter DATA_16CH_WID   = WORD_WID * LB_CH            ,   //128bit
            parameter DATA_32CH_WID   = WORD_WID * LB_CH *2         ,   //256bit
            parameter L1B_RAM_DEPTH   = 256                         ,
            parameter NUM_WORDS       = L1B_RAM_DEPTH*4            ,    //depth,byte
            parameter BITMASK_WIDTH   = 16                                      
            )(
   //----------------------------------------------------------------//
   input                                                       clk                    ,
   input                                                       rst_n                  ,
   //------------------------cubank lsu inf--------------------------//
   input  [32-1 : 0]                                           cubank_data_req        ,
   input  [32-1 : 0]                                           cubank_data_we         ,
   input  [32-1 : 0][3 : 0]                                    cubank_data_be         ,
   input  [32-1 : 0][31 : 0]                                   cubank_data_wdata      ,
   input  [32-1 : 0][$clog2(NUM_WORDS)-1 : 0]                  cubank_data_addr       ,
   output [32-1 : 0]                                           cubank_data_gnt        ,
   output [32-1 : 0]                                           cubank_data_rvalid     ,
   output [32-1 : 0][31 : 0]                                   cubank_data_rdata      ,
   //------------------------------------------------------------------//
   input                                                       l1b_gpu_mode           ,
   input                                                       l1b_bank0_weight_rd_mode        ,
   input                                                       l1b_bank1_weight_rd_mode        ,
   input  [1:0]                                                l1b_bank0_mv_cub_dst_sel        ,
   input  [1:0]                                                l1b_bank1_mv_cub_dst_sel        ,
   input  [1: 0][BANK_CH-1 : 0]                                tcache_data_cs         ,
   input  [1: 0]                                               tcache_data_data_we    ,
   input  [1: 0][DATA_32CH_WID-1     : 0]                      tcache_data_wdata      ,
   input  [1: 0][2*BITMASK_WIDTH-1   : 0]                      tcache_data_bitmask    ,
   input  [1: 0][$clog2(L1B_RAM_DEPTH)-1 : 0]                  tcache_data_addr       ,
   output reg [1: 0][DATA_32CH_WID-1 : 0]                      tcache_data_rdata      ,
   output reg [1: 0]                                           tcache_data_rvalid     ,
   output                                                      tcache_data_busy       ,
   //------------------------------------------------------------------//
   output [32-1 : 0] [1:0]                                     cubank_weight_mv_cub_dst_sel   , 
   output [32-1 : 0][DATA_16CH_WID-1: 0]                       cubank_weight          ,
   output [32-1 : 0]                                           cubank_weight_valid    
   );

   assign tcache_data_busy = |cubank_data_req;

   wire [1 : 0][BANK_CH-1 : 0][DATA_16CH_WID-1     : 0]        tcache_data_rdata_w     ;  
   wire [1 : 0][BANK_CH-1 : 0]                                 tcache_data_rvalid_w    ;


   wire [1 : 0]                                                tcache_data_rvalid_32ch_w   = {|tcache_data_rvalid_w[1][7:0], |tcache_data_rvalid_w[0][7:0]}; //half channel

   reg  [1 : 0][BANK_CH/2-1 : 0][DATA_32CH_WID-1     : 0]      tcache_data_rdata_32ch_w  ;

   integer m,n;
   always_comb begin
     for(n=0; n<2; n=n+1)
        for(m=0; m<8; m=m+1)
            tcache_data_rdata_32ch_w[n][m] =  {tcache_data_rdata_w[n][m+8],tcache_data_rdata_w[n][m]};
   end

   reg l1b_bank0_weight_rd_mode_r, l1b_bank1_weight_rd_mode_r;
   always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        l1b_bank0_weight_rd_mode_r <= 'b0;
        l1b_bank1_weight_rd_mode_r <= 'b0;
    end
    else begin
        l1b_bank0_weight_rd_mode_r <= l1b_bank0_weight_rd_mode;
        l1b_bank1_weight_rd_mode_r <= l1b_bank1_weight_rd_mode;
    end
   end

   wire [1:0] l1b_weight_rd_mode = {l1b_bank1_weight_rd_mode_r, l1b_bank0_weight_rd_mode_r};  

    reg [1:0] l1b_bank0_mv_cub_dst_sel_r, l1b_bank1_mv_cub_dst_sel_r;
    always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        l1b_bank0_mv_cub_dst_sel_r <= 'b0;
        l1b_bank1_mv_cub_dst_sel_r <= 'b0;
    end
    else begin
        l1b_bank0_mv_cub_dst_sel_r <= l1b_bank0_mv_cub_dst_sel;
        l1b_bank1_mv_cub_dst_sel_r <= l1b_bank1_mv_cub_dst_sel;
    end
   end

assign cubank_weight_mv_cub_dst_sel = { {8{l1b_bank1_mv_cub_dst_sel_r}}, {8{l1b_bank0_mv_cub_dst_sel_r}},  {8{l1b_bank1_mv_cub_dst_sel_r}}, {8{l1b_bank0_mv_cub_dst_sel_r}} } ;


   always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        tcache_data_rvalid <= 'b0;
    else
        tcache_data_rvalid <= tcache_data_rvalid_32ch_w & ( ~l1b_weight_rd_mode  );
   end
    
   reg  [1: 0][DATA_32CH_WID-1 : 0]                      tcache_data_rdata_tmp      ;
   integer p,q;
   always_comb begin
   tcache_data_rdata_tmp = 'b0 ;
     for(p=0; p<2; p=p+1)
        for(q=0; q<8; q=q+1) 
            if(tcache_data_rvalid_w[p][q]) begin
                tcache_data_rdata_tmp[p] = tcache_data_rdata_32ch_w[p][q];
                break;
            end
   end

   always@(posedge clk ) begin
     foreach(tcache_data_rdata[k])
        if(tcache_data_rvalid_32ch_w[k])
            tcache_data_rdata[k]  <=  tcache_data_rdata_tmp[k];
   end

   //to cubank weight
   assign cubank_weight_valid = {tcache_data_rvalid_w[1][15:8],tcache_data_rvalid_w[0][15:8],tcache_data_rvalid_w[1][7:0] ,tcache_data_rvalid_w[0][7:0]} & { {8{l1b_weight_rd_mode[1]}}, {8{l1b_weight_rd_mode[0]}},  {8{l1b_weight_rd_mode[1]}}, {8{l1b_weight_rd_mode[0]}} }; // [1:0][15:0]  32 valid 
   assign cubank_weight       = {tcache_data_rdata_w[1][15:8],tcache_data_rdata_w[0][15:8],tcache_data_rdata_w[1][7:0] ,tcache_data_rdata_w[0][7:0]} ;// [1:0][15:0]  32ch


    //from  cubank alu
   wire  [1:0][BANK_CH-1 : 0]                          cubank_data_req_w      = {cubank_data_req[31:24],cubank_data_req[15:8],cubank_data_req[23:16],cubank_data_req[7:0] }; 
   wire  [1:0][BANK_CH-1 : 0]                          cubank_data_we_w       = {cubank_data_we[31:24],cubank_data_we[15:8],cubank_data_we[23:16],cubank_data_we[7:0] }; 
   wire  [1:0][BANK_CH-1 : 0][3 : 0]                   cubank_data_be_w       = {cubank_data_be[31:24],cubank_data_be[15:8],cubank_data_be[23:16],cubank_data_be[7:0] };
   wire  [1:0][BANK_CH-1 : 0][31 : 0]                  cubank_data_wdata_w    = {cubank_data_wdata[31:24],cubank_data_wdata[15:8],cubank_data_wdata[23:16],cubank_data_wdata[7:0] };
   wire  [1:0][BANK_CH-1 : 0][$clog2(NUM_WORDS)-1 : 0] cubank_data_addr_w     = {cubank_data_addr[31:24],cubank_data_addr[15:8],cubank_data_addr[23:16],cubank_data_addr[7:0] };


   wire [1:0][BANK_CH-1 : 0]              cubank_data_gnt_w        ;
   wire [1:0][BANK_CH-1 : 0]              cubank_data_rvalid_w     ;
   wire [1:0][BANK_CH-1 : 0][31 : 0]      cubank_data_rdata_w      ;


   //to cubank alu 
   assign cubank_data_gnt        = {cubank_data_gnt_w[1][15:8] ,cubank_data_gnt_w[0][15:8] ,cubank_data_gnt_w[1][7:0]  ,cubank_data_gnt_w[0][7:0] };
   assign cubank_data_rvalid     = {cubank_data_rvalid_w[1][15:8] ,cubank_data_rvalid_w[0][15:8] ,cubank_data_rvalid_w[1][7:0]  ,cubank_data_rvalid_w[0][7:0] };
   assign cubank_data_rdata      = {cubank_data_rdata_w[1][15:8] ,cubank_data_rdata_w[0][15:8] ,cubank_data_rdata_w[1][7:0]  ,cubank_data_rdata_w[0][7:0] };

   //to tcache
   //wire [1: 0][BANK_CH-1 : 0][DATA_16CH_WID-1: 0]            tcache_data_rdata_w      ;
   //wire [1: 0]                                               tcache_data_rvalid_w     ;

   //assign tcache_data_rdata   =   {tcache_data_rdata_w[1][15:8] ,tcache_data_rdata_w[0][15:8] ,tcache_data_rdata_w[1][7:0]  ,tcache_data_rdata_w[0][7:0] };
   //assign tcache_data_rvalid  =   {tcache_data_rvalid_w[1][15:8],tcache_data_rvalid_w[0][15:8],tcache_data_rvalid_w[1][7:0] ,tcache_data_rvalid_w[0][7:0]};


   //wire  [1: 0][BANK_CH-1 : 0]            tcache_data_cs_w      = {tcache_data_cs[1][15:8],tcache_data_cs[0][15:8],tcache_data_cs[1][7:0] ,tcache_data_cs[0][7:0]};   
   //wire  [1: 0]                           tcache_data_data_we_w = {tcache_data_data_we[1][15:8],tcache_data_data_we[0][15:8],tcache_data_data_we[1][7:0] ,tcache_data_data_we[0][7:0]};     
   //wire  [1: 0][DATA_16CH_WID-1     : 0]  tcache_data_wdata_w   = {tcache_data_wdata[1][15:8],tcache_data_wdata[0][15:8],tcache_data_wdata[1][7:0] ,tcache_data_wdata[0][7:0]};
   //wire  [1: 0][BITMASK_WIDTH-1     : 0]  tcache_data_bitmask_w = {tcache_data_bitmask[1][15:8],tcache_data_bitmask[0][15:8],tcache_data_bitmask[1][7:0] ,tcache_data_bitmask[0][7:0]}; 
   //wire  [1: 0][$clog2(NUM_WORDS)-1 : 0]  tcache_data_addr_w    = {tcache_data_addr[1][15:8],tcache_data_addr[0][15:8],tcache_data_addr[1][7:0] ,tcache_data_addr[0][7:0]};



 l1b_bank U_l1b_bank0(
.clk                    (clk                      ),
.rst_n                  (rst_n                    ),
.l1b_gpu_mode            (l1b_gpu_mode             ),//0: tcache 1:cubank
.cubank_data_req        (cubank_data_req_w    [0] ),
.cubank_data_we         (cubank_data_we_w     [0] ),
.cubank_data_be         (cubank_data_be_w     [0] ),
.cubank_data_wdata      (cubank_data_wdata_w  [0] ),
.cubank_data_addr       (cubank_data_addr_w   [0] ),
.cubank_data_gnt        (cubank_data_gnt_w    [0] ),
.cubank_data_rvalid     (cubank_data_rvalid_w [0] ),
.cubank_data_rdata      (cubank_data_rdata_w  [0] ),
.tcache_data_cs         (tcache_data_cs       [0] ),
.tcache_data_data_we    (tcache_data_data_we  [0] ),
.tcache_data_wdata      (tcache_data_wdata    [0] ),
.tcache_data_bitmask    (tcache_data_bitmask  [0] ),
.tcache_data_addr       (tcache_data_addr     [0] ),
.tcache_data_rdata      (tcache_data_rdata_w  [0] ),
.tcache_data_rvalid     (tcache_data_rvalid_w [0] )
//.cubank_weight          (tcache_data_rdata_w      [0] ),
//.cubank_weight_valid    (tcache_data_rvalid_w[0] )
     );

 l1b_bank U_l1b_bank1(
.clk                    (clk                      ),
.rst_n                  (rst_n                    ),
.l1b_gpu_mode            (l1b_gpu_mode             ),//0: tcache 1:cubank
.cubank_data_req        (cubank_data_req_w    [1] ),
.cubank_data_we         (cubank_data_we_w     [1] ),
.cubank_data_be         (cubank_data_be_w     [1] ),
.cubank_data_wdata      (cubank_data_wdata_w  [1] ),
.cubank_data_addr       (cubank_data_addr_w   [1] ),
.cubank_data_gnt        (cubank_data_gnt_w    [1] ),
.cubank_data_rvalid     (cubank_data_rvalid_w [1] ),
.cubank_data_rdata      (cubank_data_rdata_w  [1] ),
.tcache_data_cs         (tcache_data_cs       [1] ),
.tcache_data_data_we    (tcache_data_data_we  [1] ),
.tcache_data_wdata      (tcache_data_wdata    [1] ),
.tcache_data_bitmask    (tcache_data_bitmask  [1] ),
.tcache_data_addr       (tcache_data_addr     [1] ),
.tcache_data_rdata      (tcache_data_rdata_w  [1] ),
.tcache_data_rvalid     (tcache_data_rvalid_w [1] )
//.cubank_weight          (tcache_data_rdata_w      [1] )
//.cubank_weight_valid    (tcache_data_rvalid_w[1] )
     );


endmodule
