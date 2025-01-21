module l1b_bank #(
            parameter BANK_CH         = 16                          ,
            parameter WORD_WID        = 8                           ,
            parameter LB_CH           = 16                          ,
            parameter DATA_16CH_WID   = WORD_WID * LB_CH            ,   //128bit
            parameter DATA_32CH_WID   = WORD_WID * LB_CH * 2        ,   //128bit
            parameter L1B_RAM_DEPTH   = 256                         ,
            parameter NUM_WORDS       = L1B_RAM_DEPTH*4            ,    //depth,byte
            parameter BITMASK_WIDTH   = 16                                      
            )(
   //----------------------------------------------------------------//
   input                                                  clk                   ,
   input                                                  rst_n                 ,
   input                                                  l1b_gpu_mode           ,//0: tcache 1:cubank
   //------------------------cubank lsu inf-------------------------------//
   input  [BANK_CH-1 : 0]                                 cubank_data_req       ,
   input  [BANK_CH-1 : 0]                                 cubank_data_we        ,
   input  [BANK_CH-1 : 0][3 : 0]                          cubank_data_be        ,
   input  [BANK_CH-1 : 0][31 : 0]                         cubank_data_wdata     ,
   input  [BANK_CH-1 : 0][$clog2(NUM_WORDS)-1 : 0]        cubank_data_addr      ,
   output [BANK_CH-1 : 0]                                 cubank_data_gnt       ,
   output [BANK_CH-1 : 0]                                 cubank_data_rvalid    ,
   output [BANK_CH-1 : 0][31 : 0]                         cubank_data_rdata     ,

   //---------------------from tcache-------------------------------------//
   input  [BANK_CH-1 : 0]                                 tcache_data_cs         ,
   input                                                  tcache_data_data_we    ,
   input  [DATA_32CH_WID-1     : 0]                       tcache_data_wdata      ,
   input  [2*BITMASK_WIDTH-1     : 0]                     tcache_data_bitmask    ,
   input  [$clog2(L1B_RAM_DEPTH)-1 : 0]                   tcache_data_addr       ,
   output [BANK_CH-1 : 0][DATA_16CH_WID-1     : 0]        tcache_data_rdata      ,
   output [BANK_CH-1 : 0]                                 tcache_data_rvalid     
//   output [BANK_CH-1 : 0][DATA_16CH_WID-1     : 0]        cubank_weight          ,
//   output [BANK_CH-1 : 0]                                 cubank_weight_valid
     );

   wire  [ 1        : 0][DATA_16CH_WID-1     : 0]        tcache_data_wdata_w    =  tcache_data_wdata  ;
   wire  [ 1        : 0][BITMASK_WIDTH-1     : 0]        tcache_data_bitmask_w  =  tcache_data_bitmask;

//   assign tcache_data_rvalid = | (cubank_weight_valid & tcache_data_cs);
//   assign tcache_data_rdata  = cubank_weight;

genvar m;
generate 
    for(m=0; m<16; m=m+1) begin: l1b_bank
     l1b_ch U_l1b_ch (
      .clk                   (clk                           ),
      .rst_n                 (rst_n                         ),
      .l1b_gpu_mode            (l1b_gpu_mode                    ),   //0: tcache 1:cubank
      .cubank_data_req       (cubank_data_req       [m]     ),
      .cubank_data_we        (cubank_data_we        [m]     ),
      .cubank_data_be        (cubank_data_be        [m]     ),
      .cubank_data_wdata     (cubank_data_wdata     [m]     ),
      .cubank_data_addr      (cubank_data_addr      [m]     ),
      .cubank_data_gnt       (cubank_data_gnt       [m]     ),
      .cubank_data_rvalid    (cubank_data_rvalid    [m]     ),
      .cubank_data_rdata     (cubank_data_rdata     [m]     ),
      .tcache_data_cs        (tcache_data_cs        [m]     ),
      .tcache_data_data_we   (tcache_data_data_we           ),
      .tcache_data_wdata     (tcache_data_wdata_w   [m/8]   ),
      .tcache_data_bitmask   (tcache_data_bitmask_w [m/8]   ),
      .tcache_data_addr      (tcache_data_addr              ),
      .tcache_data_rdata     (tcache_data_rdata     [m]     ),
      .tcache_data_rvalid    (tcache_data_rvalid    [m]     ) 
         );
    end
endgenerate
endmodule
