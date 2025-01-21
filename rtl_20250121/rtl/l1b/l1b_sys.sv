module l1b_sys  #(
    parameter L1B_RAM_DBANK   = 16                                          ,
    parameter L1B_RAM_DEPTH   = 256                                         ,
    parameter L1B_RAM_ADDR_WID= $clog2(L1B_RAM_DEPTH)+$clog2(L1B_RAM_DBANK)  , // 9+4
    parameter NUM_WORDS       = L1B_RAM_DEPTH*4                //depth,byte
    )(
   input  logic                                                 clk                     ,
   input  logic                                                 rst_n                   ,
   //-------------------------system lsu------------------- -----------------------------//
   input                                                        slsu_data_req                       ,
   output                                                       slsu_data_gnt                       ,
   output                                                       slsu_data_ok                        ,
   input                                                        slsu_data_we                        ,
   input                                                        slsu_data_mv_last_dis               ,
   input                                                        slsu_l1b_mode                       ,  
   input                                                        slsu_tcache_core_load_bank_num      , 
   input  [L1B_RAM_ADDR_WID-1 : 0]                              slsu_data_addr                      ,  
   input  [$clog2(L1B_RAM_DEPTH)-1: 0]                          slsu_data_sys_len                   ,
   input  [$clog2(L1B_RAM_DEPTH)-1: 0]                          slsu_data_sub_len                   ,
   input  [$clog2(L1B_RAM_DEPTH)-1: 0]                          slsu_data_sub_gap                   ,
   input  [$clog2(L1B_RAM_DEPTH)-1: 0]                          slsu_data_sys_gap                   ,
   input  [$clog2(L1B_RAM_DBANK)  : 0]                          slsu_data_sys_gap_ext               ,
   input                                                        slsu_cfg_vld                        ,
   input  [1:0]                                                 slsu_cfg_type                       ,
   input                                                        slsu_state_clr                      ,
   input  [2:0]                                                 slsu_tcache_mode                    ,
   input                                                        slsu_l1b_gpu_mode                   ,
   input                                                        slsu_l1b_norm_paral_mode            ,
   input                                                        slsu_tcache_trans_prici             ,
   input                                                        slsu_tcache_trans_swbank            ,
   input  [1:0]                                                 slsu_l1b_op_wr_hl_mask              ,
   input  [$clog2(L1B_RAM_DEPTH)-1:0]                           slsu_cache_one_ram_qw_base_addr     ,
   input  [1:0]                                                 slsu_mv_cub_dst_sel                 ,
   input                                                        slsu_iob_pric                       ,
   input                                                        slsu_iob_l2c_in_cfg                 ,
   input  [4:0]                                                 slsu_tcache_mvfmap_offset           ,
   input                                                        slsu_tcache_mvfmap_stride           ,
   output [1:0]                                                 cubank_lb_mv_cub_dst_sel            ,
   //---------------------------------hid_lsu------------------------------------------------------------//
   input                                                        hlsu_data_req                       ,
   output                                                       hlsu_data_gnt                       ,
   output                                                       hlsu_data_ok                        ,
   input                                                        hlsu_l1b_mode                       ,
   input                                                        hlsu_data_we                        ,
   input  [L1B_RAM_ADDR_WID-1 : 0]                              hlsu_data_addr                      ,
   input  [$clog2(L1B_RAM_DEPTH)-1: 0]                          hlsu_data_sys_len                   ,
   input  [$clog2(L1B_RAM_DEPTH)-1: 0]                          hlsu_data_sub_len                   ,
   input  [$clog2(L1B_RAM_DEPTH)-1: 0]                          hlsu_data_sys_gap                   ,
   input                                                        hlsu_chk_done_req                   ,
   output                                                       hlsu_chk_done_gnt                   ,
   input                                                        hlsu_cfg_vld                        ,
   input  [1:0]                                                 hlsu_cfg_type                       ,
   input  [$clog2(L1B_RAM_DBANK)  :0]                           hlsu_data_sys_gap_ext               ,
   input  [$clog2(L1B_RAM_DEPTH)-1: 0]                          hlsu_data_sub_gap                   ,
   input                                                        hlsu_l1b_norm_paral_mode            ,
    //----------------------------fmap broadcast---- --------------------------------//
   input                                                        conv3d_bcfmap_req                   ,
   output                                                       conv3d_bcfmap_gnt                   ,
   output                                                       conv3d_bcfmap_ok                    ,
   input                                                        conv3d_bcfmap_elt_mode              , 
   input                                                        conv3d_bcfmap_elt_pric              , 
   input                                                        conv3d_bcfmap_elt_bsel              , 
   input                                                        conv3d_bcfmap_elt_32ch_i16          , 
   input                                                        conv3d_bcfmap_group                 , 
   input                                                        conv3d_bcfmap_mode                  ,
   input  [5:0]                                                 conv3d_bcfmap_len                   ,
   input                                                        conv3d_bcfmap_rgba_mode             ,
   input                                                        conv3d_bcfmap_rgba_stride           ,
   input                                                        conv3d_bcfmap_keep_2cycle_en        ,
   input                                                        conv3d_bcfmap_hl_op                 ,
   input signed [4:0]                                           conv3d_bcfmap_rgba_shift            ,
   input                                                        conv3d_bcfmap_pad0_he_sel           ,
   input [3:0]                                                  conv3d_bcfmap_pad0_len              ,
   input                                                        conv3d_bcfmap_tcache_stride         ,
   input [4:0]                                                  conv3d_bcfmap_tcache_offset         ,
    //----------------------------fmap broadcast inf ------------------------------------//
   output  [3:0]                                                tcache_conv3d_bcfmap_valid          ,           
   output  [3:0]                                                tcache_conv3d_bcfmap_vector_data_mask          ,           
   output  [128-1:0]                                            tcache_conv3d_bcfmap_dataout_bank0[1:0], 
   output  [128-1:0]                                            tcache_conv3d_bcfmap_dataout_bank1[1:0], 
    //----------------------------weight to cubank inf ----------------------------------//
   output [31 : 0][128-1: 0]                                    cubank_weight                       ,
   output [31 : 0]                                              cubank_weight_valid                 ,
   output [31 : 0][1:0]                                         cubank_weight_mv_cub_dst_sel        ,
    //---------------------------from l2 noc ---------------------------//
   input                                                        l2c_datain_vld                      ,
   input                                                        l2c_datain_last                     ,
   output                                                       l2c_datain_rdy                      ,
   input   [256-1:0]                                            l2c_datain_data                     ,
   //to l2 noc
   output                                                       l2c_dataout_vld                     ,
   output                                                       l2c_dataout_last                    ,
   input logic                                                  l2c_dataout_rdy                     ,
   output [256-1:0]                                             l2c_dataout_data                    ,
   //from cubank out
   input     logic [32-1:0][32-1:0]                             CU_bank_data_out                    ,
   input     logic [32-1:0]                                     CU_bank_data_out_vld                ,
   output    logic [32-1:0]                                     CU_bank_data_out_ready              ,
   input     logic [32-1:0]                                     CU_bank_data_out_last               ,

   //----------------------------cubank lsu inf--------------------------//
   input  [32-1 : 0]                                            cubank_data_req                     ,
   input  [32-1 : 0]                                            cubank_data_we                      ,
   input  [32-1 : 0][3 : 0]                                     cubank_data_be                      ,
   input  [32-1 : 0][31: 0]                                     cubank_data_wdata                   ,
   input  [32-1 : 0][$clog2(NUM_WORDS)-1 : 0]                   cubank_data_addr                    ,
   output [32-1 : 0]                                            cubank_data_gnt                     ,
   output [32-1 : 0]                                            cubank_data_rvalid                  ,
   output [32-1 : 0][31 : 0]                                    cubank_data_rdata       
  );

    //parameter
    parameter BANK_CH         = 16                          ;
    parameter BITMASK_WIDTH   = 16                          ;
    parameter WORD_WID        = 8                           ;
    parameter CH_X            = 32                          ;
    parameter DATA_32CH_WID   = WORD_WID * CH_X             ;
    parameter DATA_16CH_WID   = WORD_WID * CH_X /2          ;
    parameter NUM_WORDS_Y     = CH_X                        ;


   wire                                                    l1b_gpu_mode               ;

   wire                                                    l1b_bank0_weight_rd_mode   ;
   wire                                                    l1b_bank1_weight_rd_mode   ;
   wire  [1:0]                                             l1b_bank0_mv_cub_dst_sel   ;
   wire  [1:0]                                             l1b_bank1_mv_cub_dst_sel   ;

   wire  [1: 0][BANK_CH-1 : 0]                             tcache_l1b_data_cs         ;
   wire  [1: 0]                                            tcache_l1b_data_data_we    ;  
   wire  [1: 0][DATA_32CH_WID-1     : 0]                   tcache_l1b_data_wdata      ;
   wire  [1: 0][2*BITMASK_WIDTH-1     : 0]                 tcache_l1b_data_bitmask    ;
   wire  [1: 0][$clog2(L1B_RAM_DEPTH)-1 : 0]               tcache_l1b_data_addr       ;
   wire  [1: 0][DATA_32CH_WID-1: 0]                        tcache_l1b_data_rdata      ;
   wire  [1: 0]                                            tcache_l1b_data_rvalid     ;

  
tcache_sys U_tcache_sys(
   .clk                                 (clk                                ),
   .rst_n                               (rst_n                              ),
   .slsu_data_req                       (slsu_data_req                      ),
   .slsu_data_gnt                       (slsu_data_gnt                      ),
   .slsu_data_ok                        (slsu_data_ok                       ),
   .slsu_l1b_mode                       (slsu_l1b_mode                      ), 
   .slsu_data_we                        (slsu_data_we                       ),
   .slsu_data_mv_last_dis               (slsu_data_mv_last_dis              ),
   .slsu_data_addr                      (slsu_data_addr                     ), 
   .slsu_data_sys_len                   (slsu_data_sys_len                  ), 
   .slsu_data_sub_len                   (slsu_data_sub_len                  ), 
   .slsu_data_sub_gap                   (slsu_data_sub_gap                  ), 
   .slsu_data_sys_gap                   (slsu_data_sys_gap                  ), 
   .slsu_data_sys_gap_ext               (slsu_data_sys_gap_ext              ), 
   .slsu_cfg_vld                        (slsu_cfg_vld                       ),
   .slsu_cfg_type                       (slsu_cfg_type                      ),
   .slsu_state_clr                      (slsu_state_clr                     ),
   .slsu_tcache_mode                    (slsu_tcache_mode                   ), 
   .slsu_l1b_gpu_mode                   (slsu_l1b_gpu_mode                  ),  
   .slsu_l1b_norm_paral_mode            (slsu_l1b_norm_paral_mode           ),
   //.slsu_l1b_weight_rd_mode                (slsu_l1b_weight_rd_mode       ),  
   .slsu_l1b_op_wr_hl_mask              (slsu_l1b_op_wr_hl_mask             ),                                      
   .slsu_cache_one_ram_qw_base_addr     (slsu_cache_one_ram_qw_base_addr    ),
   .slsu_tcache_core_load_bank_num      (slsu_tcache_core_load_bank_num     ), 
   .slsu_mv_cub_dst_sel                 (slsu_mv_cub_dst_sel                ),
   .slsu_tcache_trans_prici             (slsu_tcache_trans_prici            ),
   .slsu_tcache_trans_swbank            (slsu_tcache_trans_swbank           ),
   .slsu_iob_pric                       (slsu_iob_pric                      ),
   .slsu_iob_l2c_in_cfg                 (slsu_iob_l2c_in_cfg                ),
   .slsu_tcache_mvfmap_offset           (slsu_tcache_mvfmap_offset          ),
   .slsu_tcache_mvfmap_stride           (slsu_tcache_mvfmap_stride          ),
   .hlsu_data_req                       (hlsu_data_req                      ),
   .hlsu_data_gnt                       (hlsu_data_gnt                      ),
   .hlsu_data_ok                        (hlsu_data_ok                       ),
   .hlsu_l1b_mode                       (hlsu_l1b_mode                      ),
   .hlsu_data_we                        (hlsu_data_we                       ),
   .hlsu_data_addr                      (hlsu_data_addr                     ),
   .hlsu_data_sys_len                   (hlsu_data_sys_len                  ),
   .hlsu_data_sub_len                   (hlsu_data_sub_len                  ),
   .hlsu_data_sys_gap                   (hlsu_data_sys_gap                  ),
   .hlsu_chk_done_req                   (hlsu_chk_done_req                  ),
   .hlsu_chk_done_gnt                   (hlsu_chk_done_gnt                  ),
   .hlsu_cfg_vld                        (hlsu_cfg_vld                       ),
   .hlsu_cfg_type                       (hlsu_cfg_type                      ),
   .hlsu_data_sys_gap_ext               (hlsu_data_sys_gap_ext              ),
   .hlsu_data_sub_gap                   (hlsu_data_sub_gap                  ),
   .hlsu_l1b_norm_paral_mode            (hlsu_l1b_norm_paral_mode           ),
   .cubank_lb_mv_cub_dst_sel            (cubank_lb_mv_cub_dst_sel           ),
   .conv3d_bcfmap_req                   (conv3d_bcfmap_req                  ),
   .conv3d_bcfmap_gnt                   (conv3d_bcfmap_gnt                  ),  
   .conv3d_bcfmap_ok                    (conv3d_bcfmap_ok                   ),  
   .conv3d_bcfmap_elt_mode              (conv3d_bcfmap_elt_mode             ),
   .conv3d_bcfmap_elt_pric              (conv3d_bcfmap_elt_pric             ),
   .conv3d_bcfmap_elt_bsel              (conv3d_bcfmap_elt_bsel             ),
   .conv3d_bcfmap_elt_32ch_i16          (conv3d_bcfmap_elt_32ch_i16         ), 
   .conv3d_bcfmap_group                 (conv3d_bcfmap_group                ), 
   .conv3d_bcfmap_mode                  (conv3d_bcfmap_mode                 ),  
   .conv3d_bcfmap_len                   (conv3d_bcfmap_len                  ),  
   .conv3d_bcfmap_rgba_mode             (conv3d_bcfmap_rgba_mode            ),  
   .conv3d_bcfmap_rgba_stride           (conv3d_bcfmap_rgba_stride          ),  
   .conv3d_bcfmap_keep_2cycle_en        (conv3d_bcfmap_keep_2cycle_en       ),
   .conv3d_bcfmap_hl_op                 (conv3d_bcfmap_hl_op                ),  
   .conv3d_bcfmap_rgba_shift            (conv3d_bcfmap_rgba_shift           ),
   .conv3d_bcfmap_pad0_he_sel           (conv3d_bcfmap_pad0_he_sel          ),  
   .conv3d_bcfmap_pad0_len              (conv3d_bcfmap_pad0_len             ),  
   .conv3d_bcfmap_tcache_stride         (conv3d_bcfmap_tcache_stride        ),
   .conv3d_bcfmap_tcache_offset         (conv3d_bcfmap_tcache_offset        ),
   .tcache_conv3d_bcfmap_valid          (tcache_conv3d_bcfmap_valid         ),
   .tcache_conv3d_bcfmap_vector_data_mask          (tcache_conv3d_bcfmap_vector_data_mask         ),
   .tcache_conv3d_bcfmap_dataout_bank0  (tcache_conv3d_bcfmap_dataout_bank0 ),                            
   .tcache_conv3d_bcfmap_dataout_bank1  (tcache_conv3d_bcfmap_dataout_bank1 ),
   .l2c_datain_vld                      (l2c_datain_vld                     ),
   .l2c_datain_last                     (l2c_datain_last                    ),
   .l2c_datain_rdy                      (l2c_datain_rdy                     ),
   .l2c_datain_data                     (l2c_datain_data                    ),
   .l2c_dataout_vld                     (l2c_dataout_vld                    ),
   .l2c_dataout_last                    (l2c_dataout_last                   ),
   .l2c_dataout_rdy                     (l2c_dataout_rdy                    ),
   .l2c_dataout_data                    (l2c_dataout_data                   ),
   .CU_bank_data_out                    (CU_bank_data_out                   ),
   .CU_bank_data_out_vld                (CU_bank_data_out_vld               ),
   .CU_bank_data_out_ready              (CU_bank_data_out_ready             ),
   .CU_bank_data_out_last               (CU_bank_data_out_last              ),
   //-------------------------------------------------------------------------//
   .l1b_gpu_mode                        (l1b_gpu_mode                       ),
   .l1b_bank0_weight_rd_mode            (l1b_bank0_weight_rd_mode           ),
   .l1b_bank1_weight_rd_mode            (l1b_bank1_weight_rd_mode           ),
   .l1b_bank0_mv_cub_dst_sel            (l1b_bank0_mv_cub_dst_sel           ),
   .l1b_bank1_mv_cub_dst_sel            (l1b_bank1_mv_cub_dst_sel           ),
   .tcache_l1b_data_cs                  (tcache_l1b_data_cs                 ),
   .tcache_l1b_data_data_we             (tcache_l1b_data_data_we            ),
   .tcache_l1b_data_wdata               (tcache_l1b_data_wdata              ),
   .tcache_l1b_data_bitmask             (tcache_l1b_data_bitmask            ),
   .tcache_l1b_data_addr                (tcache_l1b_data_addr               ),
   .tcache_l1b_data_rdata               (tcache_l1b_data_rdata              ),
   .tcache_l1b_data_rvalid              (tcache_l1b_data_rvalid             )
 );



l1b_core U_l1b_core (
   .clk                    (clk                    ),
   .rst_n                  (rst_n                  ),
   .cubank_data_req        (cubank_data_req        ),
   .cubank_data_we         (cubank_data_we         ),
   .cubank_data_be         (cubank_data_be         ),
   .cubank_data_wdata      (cubank_data_wdata      ),
   .cubank_data_addr       (cubank_data_addr       ),
   .cubank_data_gnt        (cubank_data_gnt        ),
   .cubank_data_rvalid     (cubank_data_rvalid     ),
   .cubank_data_rdata      (cubank_data_rdata      ),
   //---------------from tcache  ctrl---------------//
   .l1b_gpu_mode           (l1b_gpu_mode           ),
   .l1b_bank0_weight_rd_mode (l1b_bank0_weight_rd_mode ),
   .l1b_bank1_weight_rd_mode (l1b_bank1_weight_rd_mode ),
   .l1b_bank0_mv_cub_dst_sel (l1b_bank0_mv_cub_dst_sel ),
   .l1b_bank1_mv_cub_dst_sel (l1b_bank1_mv_cub_dst_sel ),
   .tcache_data_cs         (tcache_l1b_data_cs     ),
   .tcache_data_data_we    (tcache_l1b_data_data_we),
   .tcache_data_wdata      (tcache_l1b_data_wdata  ),
   .tcache_data_bitmask    (tcache_l1b_data_bitmask),
   .tcache_data_addr       (tcache_l1b_data_addr   ),
   .tcache_data_rdata      (tcache_l1b_data_rdata  ),
   .tcache_data_rvalid     (tcache_l1b_data_rvalid ),
   .tcache_data_busy       (),
   //--------------------weight to cubank-------------//
   .cubank_weight          (cubank_weight          ),
   .cubank_weight_mv_cub_dst_sel(cubank_weight_mv_cub_dst_sel ),
   .cubank_weight_valid    (cubank_weight_valid    )
   );




endmodule
