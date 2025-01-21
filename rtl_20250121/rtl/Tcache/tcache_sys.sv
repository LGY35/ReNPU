module tcache_sys #(
    parameter L1B_RAM_DBANK   = 16                                          ,
    parameter L1B_RAM_DEPTH   = 256                                         ,
    parameter L1B_RAM_ADDR_WID= $clog2(L1B_RAM_DEPTH)+$clog2(L1B_RAM_DBANK) , // 9+4
    parameter WORD_WID        = 8                                           ,
    parameter CH_X            = 32                                          ,
    parameter DATA_32CH_WID   = WORD_WID * CH_X                             ,
    parameter DATA_16CH_WID   = WORD_WID * CH_X /2                          ,
    parameter L1B_RAM_DEPTH_Y = CH_X                                        ,
    parameter BITMASK_WIDTH   = 16                                      
)(
   input  logic                                                 clk                                 ,
   input  logic                                                 rst_n                               ,
  //-------------------------slsu-------------------------------------------------------------------//
   input                                                        slsu_data_req                       ,
   output                                                       slsu_data_gnt                       ,
   output                                                       slsu_data_ok                        ,
   input                                                        slsu_l1b_mode                       ,  // 1: norm weight mode 0: fmap cache
   input                                                        slsu_data_we                        ,
   input                                                        slsu_data_mv_last_dis               ,
   input  [L1B_RAM_ADDR_WID-1 : 0]                              slsu_data_addr                      ,  
   input                                                        slsu_cfg_vld                        ,
   input  [1:0]                                                 slsu_cfg_type                       ,
   input  [$clog2(L1B_RAM_DEPTH)-1: 0]                          slsu_data_sys_len                   ,
   input  [$clog2(L1B_RAM_DEPTH)-1: 0]                          slsu_data_sub_len                   ,
   input  [$clog2(L1B_RAM_DEPTH)-1: 0]                          slsu_data_sub_gap                   ,
   input  [$clog2(L1B_RAM_DEPTH)-1: 0]                          slsu_data_sys_gap                   ,
   input  [$clog2(L1B_RAM_DBANK)  : 0]                          slsu_data_sys_gap_ext               ,
   input                                                        slsu_state_clr                      ,
   input  [2:0]                                                 slsu_tcache_mode                    ,
   input                                                        slsu_l1b_gpu_mode                   ,
   input                                                        slsu_l1b_norm_paral_mode            ,
   input  [1:0]                                                 slsu_l1b_op_wr_hl_mask              ,
   input  [$clog2(L1B_RAM_DEPTH)-1:0]                           slsu_cache_one_ram_qw_base_addr     ,
   input                                                        slsu_tcache_core_load_bank_num      ,
   input                                                        slsu_tcache_trans_prici             , 
   input                                                        slsu_tcache_trans_swbank            , 
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
    //----------------------------fmap broadcast---------------------------------------------------//
   input                                                        conv3d_bcfmap_req                   , 
   output                                                       conv3d_bcfmap_gnt                   ,
   output                                                       conv3d_bcfmap_ok                    ,
   input                                                        conv3d_bcfmap_elt_mode              , 
   input                                                        conv3d_bcfmap_elt_pric              , 
   input                                                        conv3d_bcfmap_elt_bsel              , 
   input                                                        conv3d_bcfmap_elt_32ch_i16          , 
   input                                                        conv3d_bcfmap_group                 , 
   input                                                        conv3d_bcfmap_tcache_stride         ,
   input [4:0]                                                  conv3d_bcfmap_tcache_offset         ,
   input                                                        conv3d_bcfmap_mode                  , 
   input       [5:0]                                            conv3d_bcfmap_len                   , 
   input                                                        conv3d_bcfmap_keep_2cycle_en        , 
   input                                                        conv3d_bcfmap_rgba_mode             , 
   input                                                        conv3d_bcfmap_rgba_stride           , 
   input                                                        conv3d_bcfmap_hl_op                 , 
   input signed [4:0]                                           conv3d_bcfmap_rgba_shift            , 
   input                                                        conv3d_bcfmap_pad0_he_sel           , 
   input        [3:0]                                           conv3d_bcfmap_pad0_len              , 

    //----------------------------fmap broadcast inf -----------------------------------------------//
   output   [3:0]                                               tcache_conv3d_bcfmap_valid          ,
   output   [3:0]                                               tcache_conv3d_bcfmap_vector_data_mask          ,
   output  [DATA_16CH_WID-1:0]                                  tcache_conv3d_bcfmap_dataout_bank0[1:0]  ,                            
   output  [DATA_16CH_WID-1:0]                                  tcache_conv3d_bcfmap_dataout_bank1[1:0]  ,
    //----------------------------to l1b core----------------------------------------------------//
   output  [1: 0][L1B_RAM_DBANK-1 : 0]                          tcache_l1b_data_cs                  ,
   output  [1: 0]                                               tcache_l1b_data_data_we             ,   
   output  [1: 0][DATA_32CH_WID-1     : 0]                      tcache_l1b_data_wdata               ,
   output  [1: 0][2*BITMASK_WIDTH-1     : 0]                    tcache_l1b_data_bitmask             ,
   output  [1: 0][$clog2(L1B_RAM_DEPTH)-1 : 0]                  tcache_l1b_data_addr                ,
   input   [1: 0][DATA_32CH_WID-1: 0]                           tcache_l1b_data_rdata               ,
   input   [1: 0]                                               tcache_l1b_data_rvalid              ,
   output                                                       l1b_gpu_mode                        ,
   output                                                       l1b_bank0_weight_rd_mode            ,
   output                                                       l1b_bank1_weight_rd_mode            ,
   output [1:0]                                                 l1b_bank0_mv_cub_dst_sel            ,
   output [1:0]                                                 l1b_bank1_mv_cub_dst_sel            ,
    //---------------------------from l2 noc -----------------------------------------------------//
    //
   input     logic [32-1:0][32-1:0]                             CU_bank_data_out                    ,
   input     logic [32-1:0]                                     CU_bank_data_out_vld                ,
   output    logic [32-1:0]                                     CU_bank_data_out_ready              ,
   input     logic [32-1:0]                                     CU_bank_data_out_last               ,
    //
   input                                                        l2c_datain_vld                      ,
   input                                                        l2c_datain_last                     ,
   output                                                       l2c_datain_rdy                      ,
   input           [DATA_32CH_WID-1:0]                          l2c_datain_data                     ,
    //to l2 noc
   output                                                       l2c_dataout_vld                     ,
   output                                                       l2c_dataout_last                    ,
   input logic                                                  l2c_dataout_rdy                     ,
   output           [DATA_32CH_WID-1:0]                         l2c_dataout_data                         

 );

     parameter   LB_RAM_NUM                  =  32                                        ; //32 ram
     parameter   LB_ONE_BANK_NUM             =  LB_RAM_NUM/2                              ; 
     parameter   LB_CS_ADDR_WID              =  $clog2(LB_RAM_NUM)                        ;
     parameter   LB_ONE_BANK_CS_ADDR_WID     =  LB_CS_ADDR_WID -1                         ;  // 16 ram
     parameter   LB_SYS_ONE_RAM_QW_ADDR_WID  =   8                                        ; // 256 qword 
     parameter   LSU_SYS_ADDR_WID            =  LB_SYS_ONE_RAM_QW_ADDR_WID + 5            ;  // 256 quatern word * 32bank
     parameter   LSU_SYS_ONE_BANK_ADDR_WID   = LSU_SYS_ADDR_WID - 1                       ;  // 256 quatern word * 16bank
     parameter   LSU_CPU_ADDR_WID            =  2+LSU_SYS_ADDR_WID                        ;// word addr: quatern word *512line*32bank

     parameter   L1B_RAM_CH                  =  32                                        ;

   //bitmask disable
   assign    tcache_l1b_data_bitmask = {2*2*BITMASK_WIDTH{1'b1}};

   //-------------------------------------------------------------------------------------

   wire                                       bcfmap_dfifo_addr_odd                      ;
   wire                                       mvfmap_dfifo_addr_odd                      ;
   wire  [2:0]                                tcache_mode                                ;
   wire                                       tcache_core2bcfmap_datain_valid            ;
   wire                                       bcfmap_req_enable = tcache_core2bcfmap_datain_valid ;
   wire                                       bcfmap_req_disable                         ;
   wire                                       tcache_core2bcfmap_dataout_vld             ; //cub: cubank
   wire  [DATA_32CH_WID-1:0]                  tcache_core2bcfmap_dataout_ch0             ;
   wire  [DATA_32CH_WID-1:0]                  tcache_core2bcfmap_dataout_ch1             ;
   wire                                       tcache_core2bcfmap_dataout_bank0_rqt       ;
   wire                                       tcache_core2bcfmap_dataout_bank1_rqt       ;
   wire                                       tcache_core2bcfmap_dataout_bank0_rqt_last  ;
   wire                                       tcache_core2bcfmap_dataout_bank1_rqt_last  ;
   wire                                       tcache_ram_dataout_bank0_not_empty         ;
   wire                                       tcache_ram_dataout_bank1_not_empty         ;


   wire  [4:0]                                tcache_mvfmap_offset                       ;
   wire                                       tcache_mvfmap_stride                       ;




    //
   wire                                       tcache_l2c_datain_vld                     ;
   wire                                       tcache_l2c_datain_last                    ;
   wire                                       tcache_l2c_datain_rdy                     ;
   wire  [256-1:0]                            tcache_l2c_datain                         ;

   wire                                       iob_pric                            ;       //1: int16  0: int8
   wire                                       iob_l2c_in_cfg                      ;


   wire                              state_clr                          ; 
   wire [1:0]                        l1b_op_wr_hl_mask                  ;
   wire                              l1b_op_weight_rd_mode              ;
   wire                              l1b_op_fmap_fifo_mode              ;
   wire                              l1b_op_fmap_wr_mode                ;
   wire [$clog2(L1B_RAM_DEPTH)-1:0]  cache_one_ram_qw_base_addr         ;
   wire [$clog2(L1B_RAM_DEPTH)  :0]  cache_one_ram_qw_addr_section      ; //1/32 
   wire                              tcache_core_load_bank_num          ;
   wire                              tcache_core_move_fmap_en           ;
   wire                              tcache_core_move_fmap_last         ;

   wire                              tcache_l1b_dataout_vld2lsu         ; 
   wire                              tcache_core_trans_prici            ;
   wire                              tcache_core_trans_swbank           ;


   wire                              hlsu_l1b_wr_en                     ;
   wire                              hlsu_l1b_addr_valid                ;
   wire  [L1B_RAM_ADDR_WID-1: 0]     hlsu_l1b_addr                      ;
   wire                              hlsu_l1b_op_norm_mode              ;
   wire                              hlsu_l1b_op_norm_parallel_mode     ;

   wire                              slsu_l1b_addr_valid                ;
   wire                              slsu_l1b_wr_en                     ;
   wire [L1B_RAM_ADDR_WID -1 : 0]    slsu_l1b_addr                      ;
   wire                              slsu_l1b_op_norm_mode              ;
   wire                              slsu_l1b_op_norm_parallel_mode     ;

   wire                              lsu_l1b_wr_en         = slsu_l1b_addr_valid ?  slsu_l1b_wr_en  : hlsu_l1b_wr_en    ;
   wire                              lsu_l1b_addr_valid    = slsu_l1b_addr_valid || hlsu_l1b_addr_valid                 ;
   wire  [L1B_RAM_ADDR_WID-1: 0]     lsu_l1b_addr          = slsu_l1b_addr_valid ?  slsu_l1b_addr   : hlsu_l1b_addr     ;  

   wire                              lsu_l1b_op_norm_mode          =  slsu_l1b_addr_valid ? slsu_l1b_op_norm_mode           :   hlsu_l1b_op_norm_mode         ;      
   wire                              lsu_l1b_op_norm_parallel_mode =  slsu_l1b_addr_valid ? slsu_l1b_op_norm_parallel_mode  :   hlsu_l1b_op_norm_parallel_mode;

     sys_lsu  U_sys_lsu(
     .clk                                   (clk                                 ),
     .rst_n                                 (rst_n                               ),
     .slsu_data_req                         (slsu_data_req                       ),
     .slsu_data_gnt                         (slsu_data_gnt                       ),
     .slsu_data_ok                          (slsu_data_ok                        ),
     .slsu_l1b_mode                         (slsu_l1b_mode                       ),  
     .slsu_tcache_mode                      (slsu_tcache_mode                    ),  
     .slsu_data_we                          (slsu_data_we                        ),
     .slsu_data_mv_last_dis                 (slsu_data_mv_last_dis               ),
     .slsu_data_addr                        (slsu_data_addr                      ),  
     .slsu_data_sys_len                     (slsu_data_sys_len                   ),  
     .slsu_data_sys_gap                     (slsu_data_sys_gap                   ),  
     .slsu_data_sub_gap                     (slsu_data_sub_gap                   ),  
     .slsu_data_sys_gap_ext                 (slsu_data_sys_gap_ext               ),  
     .slsu_cfg_vld                          (slsu_cfg_vld                        ),
     .slsu_cfg_type                         (slsu_cfg_type                       ),
     .slsu_data_sub_len                     (slsu_data_sub_len                   ),  
     .slsu_state_clr                        (slsu_state_clr                      ),
     .slsu_l1b_gpu_mode                     (slsu_l1b_gpu_mode                   ),  
     .slsu_l1b_norm_paral_mode              (slsu_l1b_norm_paral_mode            ),  
     .slsu_l1b_op_wr_hl_mask                (slsu_l1b_op_wr_hl_mask              ),  
     .slsu_cache_one_ram_qw_base_addr       (slsu_cache_one_ram_qw_base_addr     ),
     .slsu_tcache_core_load_bank_num        (slsu_tcache_core_load_bank_num      ),
     .slsu_tcache_trans_prici               (slsu_tcache_trans_prici             ),
     .slsu_tcache_trans_swbank              (slsu_tcache_trans_swbank            ),
     .slsu_mv_cub_dst_sel                   (slsu_mv_cub_dst_sel                 ),
     .slsu_iob_pric                         (slsu_iob_pric                       ),  
     .slsu_iob_l2c_in_cfg                   (slsu_iob_l2c_in_cfg                 ),
     .slsu_tcache_mvfmap_offset             (slsu_tcache_mvfmap_offset           ),
     .slsu_tcache_mvfmap_stride             (slsu_tcache_mvfmap_stride           ),
     .cubank_lb_mv_cub_dst_sel              (cubank_lb_mv_cub_dst_sel            ),
     //-----------config  reg output-----------------------------------------------//
     .state_clr                             (state_clr                           ), 
     .tcache_mvfmap_offset                  (tcache_mvfmap_offset                ),
     .tcache_mvfmap_stride                  (tcache_mvfmap_stride                ),
     .iob_pric                              (iob_pric                            ),  
     .iob_l2c_in_cfg                        (iob_l2c_in_cfg                      ),
     .tcache_mode                           (tcache_mode                         ),
     .bcfmap_req_disable                    (bcfmap_req_disable                  ),
     .bcfmap_dfifo_addr_odd                 (bcfmap_dfifo_addr_odd               ),
     .mvfmap_dfifo_addr_odd                 (mvfmap_dfifo_addr_odd               ),
     .l1b_gpu_mode                          (l1b_gpu_mode                        ),
     .l1b_op_norm_mode                      (slsu_l1b_op_norm_mode                    ),  
     .l1b_op_norm_parallel_mode             (slsu_l1b_op_norm_parallel_mode           ),  
     .l1b_op_wr_hl_mask                     (l1b_op_wr_hl_mask                   ),                                     
     .l1b_op_weight_rd_mode                 (l1b_op_weight_rd_mode               ),
     .l1b_op_fmap_fifo_mode                 (l1b_op_fmap_fifo_mode               ),
     //.l1b_op_fmap_wr_mode                   (l1b_op_fmap_wr_mode               ),
     .cache_one_ram_qw_base_addr            (cache_one_ram_qw_base_addr          ),
     .cache_one_ram_qw_addr_section         (cache_one_ram_qw_addr_section       ), 
     .tcache_core_load_bank_num             (tcache_core_load_bank_num           ),
     .tcache_core_move_fmap_last            (tcache_core_move_fmap_last          ),
     .tcache_core_move_fmap_en              (tcache_core_move_fmap_en            ),
     .tcache_core_trans_prici               (tcache_core_trans_prici             ),
     .tcache_core_trans_swbank              (tcache_core_trans_swbank            ),
     //-----------------from Tcache2l1b -----------------------------------------//
     .load_data_to_l1b_vld                  (tcache_l1b_dataout_vld2lsu          ),
     //-----------------to addr map table----------------------------------------//
     .slsu_l1b_addr_valid                   (slsu_l1b_addr_valid                 ),
     .slsu_l1b_wr_en                        (slsu_l1b_wr_en                      ),
     .slsu_l1b_addr                         (slsu_l1b_addr                       )
     );

hid_lsu U_hid_lsu(
     .clk                                 (clk                                 ),
     .rst_n                               (rst_n                               ),
     .hlsu_data_req                       (hlsu_data_req                       ),
     .hlsu_data_gnt                       (hlsu_data_gnt                       ),
     .hlsu_data_ok                        (hlsu_data_ok                        ),
     .hlsu_l1b_mode                       (hlsu_l1b_mode                       ),
     .hlsu_data_we                        (hlsu_data_we                        ),
     .hlsu_data_addr                      (hlsu_data_addr                      ),
     .hlsu_data_sys_len                   (hlsu_data_sys_len                   ),
     .hlsu_data_sub_len                   (hlsu_data_sub_len                   ),
     .hlsu_data_sys_gap                   (hlsu_data_sys_gap                   ),
     .hlsu_chk_done_req                   (hlsu_chk_done_req                  ),
     .hlsu_chk_done_gnt                   (hlsu_chk_done_gnt                  ),
     .hlsu_cfg_vld                        (hlsu_cfg_vld                        ),
     .hlsu_cfg_type                       (hlsu_cfg_type                       ),
     .hlsu_data_sys_gap_ext               (hlsu_data_sys_gap_ext               ),
     .hlsu_data_sub_gap                   (hlsu_data_sub_gap                   ),
     .hlsu_l1b_norm_paral_mode            (hlsu_l1b_norm_paral_mode            ),
      //-------------------------------------------------------------------------//
     .tcache_mode                         (tcache_mode                         ),
     .l1b_op_norm_mode                    (hlsu_l1b_op_norm_mode               ),
     .l1b_op_norm_parallel_mode           (hlsu_l1b_op_norm_parallel_mode      ),
      //--------------------from NoC data valid --------------------//
     .load_data_to_l1b_vld               (tcache_l1b_dataout_vld2lsu           ),
     .load_data_to_l2_ready              (tcache_l2c_datain_rdy                ),
      //--------------------to l1b --------------------------------//
      .hlsu_l1b_addr_ready               (!slsu_l1b_addr_valid                 ),
      .hlsu_l1b_wr_en                    (hlsu_l1b_wr_en                       ),
      .hlsu_l1b_addr_valid               (hlsu_l1b_addr_valid                  ),
      .hlsu_l1b_addr                     (hlsu_l1b_addr                        )    
        );


conv3d_broadcast_fmap  U_conv3d_broadcast_fmap (
   .clk                                        ( clk                                      ),
   .rst_n                                      ( rst_n                                    ),
   //------------------------------------------------------------------------------------------//
   .conv3d_bcfmap_req                          (conv3d_bcfmap_req                          ),
   .conv3d_bcfmap_gnt                          (conv3d_bcfmap_gnt                          ),
   .conv3d_bcfmap_ok                           (conv3d_bcfmap_ok                           ),
   .conv3d_bcfmap_elt_mode                     (conv3d_bcfmap_elt_mode                     ),
   .conv3d_bcfmap_elt_pric                     (conv3d_bcfmap_elt_pric                     ),
   .conv3d_bcfmap_elt_bsel                     (conv3d_bcfmap_elt_bsel                     ),
   .conv3d_bcfmap_elt_32ch_i16                 (conv3d_bcfmap_elt_32ch_i16                 ), 
   .conv3d_bcfmap_group                        (conv3d_bcfmap_group                        ), 
   .conv3d_bcfmap_tcache_stride                (conv3d_bcfmap_tcache_stride                ),
   .conv3d_bcfmap_tcache_offset                (conv3d_bcfmap_tcache_offset               ),
   .conv3d_bcfmap_mode                         (conv3d_bcfmap_mode                         ),
   .conv3d_bcfmap_len                          (conv3d_bcfmap_len                          ),
   .conv3d_bcfmap_keep_2cycle_en               (conv3d_bcfmap_keep_2cycle_en               ),
   .conv3d_bcfmap_rgba_mode                    (conv3d_bcfmap_rgba_mode                    ),
   .conv3d_bcfmap_rgba_stride                  (conv3d_bcfmap_rgba_stride                  ),
   .conv3d_bcfmap_hl_op                        (conv3d_bcfmap_hl_op                        ),
   .conv3d_bcfmap_rgba_shift                   (conv3d_bcfmap_rgba_shift                   ),
   .conv3d_bcfmap_state_clr                    (state_clr                                  ),
   .conv3d_bcfmap_pad0_he_sel                  (conv3d_bcfmap_pad0_he_sel                  ),
   .conv3d_bcfmap_pad0_len                     (conv3d_bcfmap_pad0_len                     ),
   //----------------------------- to tcache_core -------------------------------------------
   .tcache_mode                                (tcache_mode                                ),
   .bcfmap_req_disable                         (bcfmap_req_disable                         ),
   .bcfmap_req_enable                          (bcfmap_req_enable                          ),
   .bcfmap_dfifo_addr_odd                      (bcfmap_dfifo_addr_odd                      ),
   .tcache_core2bcfmap_dataout_vld             (tcache_core2bcfmap_dataout_vld             ),
   .tcache_core2bcfmap_dataout_ch0             (tcache_core2bcfmap_dataout_ch0             ),
   .tcache_core2bcfmap_dataout_ch1             (tcache_core2bcfmap_dataout_ch1             ),
   .tcache_core2bcfmap_dataout_bank0_rqt       (tcache_core2bcfmap_dataout_bank0_rqt       ),
   .tcache_core2bcfmap_dataout_bank1_rqt       (tcache_core2bcfmap_dataout_bank1_rqt       ),
   .tcache_core2bcfmap_dataout_bank0_rqt_last  (tcache_core2bcfmap_dataout_bank0_rqt_last  ),
   .tcache_core2bcfmap_dataout_bank1_rqt_last  (tcache_core2bcfmap_dataout_bank1_rqt_last  ),
   .tcache_ram_dataout_bank0_not_empty         (tcache_ram_dataout_bank0_not_empty         ),
   .tcache_ram_dataout_bank1_not_empty         (tcache_ram_dataout_bank1_not_empty         ),
   //--------------------------------- ---------------
   .tcache_conv3d_bcfmap_valid                 (tcache_conv3d_bcfmap_valid                 ),
   .tcache_conv3d_bcfmap_vector_data_mask      (tcache_conv3d_bcfmap_vector_data_mask      ),
   .tcache_conv3d_bcfmap_dataout_bank0         (tcache_conv3d_bcfmap_dataout_bank0         ), 
   .tcache_conv3d_bcfmap_dataout_bank1         (tcache_conv3d_bcfmap_dataout_bank1         ) 
  );

 iob_sw  U_iob_sw(
   .clk                                (clk ),
   .rst_n                              (rst_n),
   .iob_pric                            (iob_pric                            ),       //1: int16  0: int8
   .iob_l2c_in_cfg                      (iob_l2c_in_cfg                      ),
   //from cubank scache
   .CU_bank_data_out                    (CU_bank_data_out                    ),
   .CU_bank_data_out_vld                (CU_bank_data_out_vld                ),
   .CU_bank_data_out_ready              (CU_bank_data_out_ready              ),
   .CU_bank_data_out_last               (CU_bank_data_out_last               ),
    //
   .tcache_l2c_datain_vld               (tcache_l2c_datain_vld               ),
   .tcache_l2c_datain_last              (tcache_l2c_datain_last              ),
   .tcache_l2c_datain_rdy               (tcache_l2c_datain_rdy               ),
   .tcache_l2c_datain                   (tcache_l2c_datain                   ),
    //from l2 noc
   .l2c_datain_vld                      (l2c_datain_vld                      ),
   .l2c_datain_last                     (l2c_datain_last                     ),
   .l2c_datain_rdy                      (l2c_datain_rdy                      ),
   .l2c_datain_data                     (l2c_datain_data                     ),
    //to l2 noc
   .l2c_dataout_vld                     (l2c_dataout_vld                     ),
   .l2c_dataout_last                    (l2c_dataout_last                    ),
   .l2c_dataout_rdy                     (l2c_dataout_rdy                     ),
   .l2c_dataout_data                    (l2c_dataout_data                    )     
   );
          

tcache_core U_tcache_core(
   .clk                                     ( clk                                      ),
   .rst_n                                   ( rst_n                                    ),
   //---------------------x direction----------------------------------------//
   .tcache_mode                             (tcache_mode                               ),  //00:read fifo 01:trans mode 10:dw mode 11: rgb
   .tcache_core_state_clr                   (state_clr                                 ),
   .tcache_core_move_fmap_en                (tcache_core_move_fmap_en                  ),
   .tcache_core_load_bank_num               (tcache_core_load_bank_num                 ),
   .tcache_core_trans_prici                 (tcache_core_trans_prici                   ),
   .tcache_core_trans_swbank                (tcache_core_trans_swbank                   ),
   .l1b_op_wr_hl_mask                       (l1b_op_wr_hl_mask                         ),  
   .mvfmap_dfifo_addr_odd                   (mvfmap_dfifo_addr_odd                      ),
    .tcache_mvfmap_offset                   (tcache_mvfmap_offset                       ),
    .tcache_mvfmap_stride                   (tcache_mvfmap_stride                       ),
    //l1
   .tcache_l1b_datain_vld_ch0               (tcache_l1b_data_rvalid[0]                 ),
   .tcache_l1b_datain_vld_ch1               (tcache_l1b_data_rvalid[1]                 ),
   .tcache_l1b_datain_last                  (tcache_core_move_fmap_last                ),
   .tcache_l1b_datain_ch0                   (tcache_l1b_data_rdata[0]                  ),
   .tcache_l1b_datain_ch1                   (tcache_l1b_data_rdata[1]                  ),
    //l2
   .tcache_l2c_datain_vld                   (tcache_l2c_datain_vld                     ),
   .tcache_l2c_datain_last                  (tcache_l2c_datain_last                    ),
   .tcache_l2c_datain_rdy                   (),
   .tcache_l2c_datain                       (tcache_l2c_datain                         ),
   //out
   .tcache_l1b_dataout_vld2lsu              (tcache_l1b_dataout_vld2lsu                ),
   .tcache_l1b_dataout_vld                  (),
   .tcache_l1b_dataout_ch0                  (tcache_l1b_data_wdata[0]                  ),
   .tcache_l1b_dataout_ch1                  (tcache_l1b_data_wdata[1]                  ),
   .tcache_core2bcfmap_datain_valid         (tcache_core2bcfmap_datain_valid           ),
   .conv3d_bcfmap_req                       (conv3d_bcfmap_req                         ),
   .conv3d_bcfmap_rgba_mode                 (conv3d_bcfmap_rgba_mode                   ),
   .conv3d_bcfmap_tcache_stride             (conv3d_bcfmap_tcache_stride               ),
   .conv3d_bcfmap_tcache_offset             (conv3d_bcfmap_tcache_offset               ),
   .tcache_core2bcfmap_dataout_bank0_rqt     (tcache_core2bcfmap_dataout_bank0_rqt      ),
   .tcache_core2bcfmap_dataout_bank1_rqt     (tcache_core2bcfmap_dataout_bank1_rqt      ),
   .tcache_core2bcfmap_dataout_bank0_rqt_last(tcache_core2bcfmap_dataout_bank0_rqt_last ),
   .tcache_core2bcfmap_dataout_bank1_rqt_last(tcache_core2bcfmap_dataout_bank1_rqt_last ),
   .tcache_ram_dataout_bank0_not_empty       (tcache_ram_dataout_bank0_not_empty),
   .tcache_ram_dataout_bank1_not_empty       (tcache_ram_dataout_bank1_not_empty),
   .tcache_core2bcfmap_dataout_vld           (tcache_core2bcfmap_dataout_vld            ), //cub: cubank
   .tcache_core2bcfmap_dataout_ch0           (tcache_core2bcfmap_dataout_ch0            ),
   .tcache_core2bcfmap_dataout_ch1           (tcache_core2bcfmap_dataout_ch1            )
);




l1b_cache_addr_map_table U_l1b_cache_addr_map_table(
   .clk                             (clk                             ),
   .rst_n                           (rst_n                           ),
   //--------------------input addr info ------------------------//
   .cache_one_ram_qw_base_addr      (cache_one_ram_qw_base_addr      ),
   .cache_one_ram_qw_addr_section   (cache_one_ram_qw_addr_section   ),
   .cubank_lb_mv_cub_dst_sel        (cubank_lb_mv_cub_dst_sel        ),
   .l1b_op_norm_mode                (lsu_l1b_op_norm_mode            ),
   .l1b_op_norm_parallel_mode       (lsu_l1b_op_norm_parallel_mode   ),
   .l1b_op_wr_hl_mask               (l1b_op_wr_hl_mask               ),
   .l1b_op_weight_rd_mode           (l1b_op_weight_rd_mode           ),
   .l1b_op_fmap_fifo_mode           (l1b_op_fmap_fifo_mode           ),
   //.l1b_op_fmap_wr_mode             (l1b_op_fmap_wr_mode        ),
   //---------------------------------------------------------------//
   .slsu_l1b_addr_valid             (lsu_l1b_addr_valid             ),
   .slsu_l1b_addr                   (lsu_l1b_addr                   ),
   .slsu_l1b_wr_en                  (lsu_l1b_wr_en                  ),
   //--------------------out addr info -----------------------------//
   //bank0
   .l1b_bank0_mv_cub_dst_sel        (l1b_bank0_mv_cub_dst_sel        ),
   .l1b_bank0_weight_rd_mode        (l1b_bank0_weight_rd_mode        ),
   .l1b_bank0_ram_cs                (tcache_l1b_data_cs[0]           ), //16 rams
   .l1b_bank0_ram_addr              (tcache_l1b_data_addr[0]         ), //16   0~7,24~31  ram
   .l1b_bank0_ram_wr_en             (tcache_l1b_data_data_we[0]      ),
   //bank1
   .l1b_bank1_mv_cub_dst_sel        (l1b_bank1_mv_cub_dst_sel        ),
   .l1b_bank1_weight_rd_mode        (l1b_bank1_weight_rd_mode        ),
   .l1b_bank1_ram_cs                (tcache_l1b_data_cs[1]           ), //16 rams
   .l1b_bank1_ram_addr              (tcache_l1b_data_addr[1]         ), //16   0~7,24~31  ram
   .l1b_bank1_ram_wr_en             (tcache_l1b_data_data_we[1]      ) 
   );



endmodule
