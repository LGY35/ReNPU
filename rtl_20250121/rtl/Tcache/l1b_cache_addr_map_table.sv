module l1b_cache_addr_map_table #(
            parameter                   LB_RAM_NUM                  =  32, //16x 2x128x256ram
            parameter                   LB_ONE_BANK_NUM             =  LB_RAM_NUM/4 , // 8*2*256 ram , dont pass this parameter from top
            parameter                   LB_CS_ADDR_WID              =  $clog2(LB_RAM_NUM),
            parameter                   LB_ONE_BANK_CS_ADDR_WID     =  LB_CS_ADDR_WID -1 ,  // 8x  2x128x256ramram
            parameter                   LB_HALF_ONE_BANK_CS_ADDR_WID=  LB_ONE_BANK_CS_ADDR_WID - 1 ,  // 8x  2x128x256ramram
            parameter                   LB_SYS_ONE_RAM_QW_ADDR_WID  =   8, // 256 qword 
            parameter                   LSU_SYS_ADDR_WID            =  LB_SYS_ONE_RAM_QW_ADDR_WID + 4,  // 256 quad-word * 16bank
            parameter                   LSU_SYS_ONE_BANK_ADDR_WID   =  LB_SYS_ONE_RAM_QW_ADDR_WID + 3 ,  // 256 quad-word * 8bank
            parameter                   LSU_CPU_ADDR_WID            =  2+LSU_SYS_ADDR_WID  // word addr: quatern word *512line*32bank
            )(
            //--------------------clk / rst_n ---------------------//
            input                                           clk                             ,
            input                                           rst_n                           ,
            //--------------------input addr info ------------------------//
            input    [LB_SYS_ONE_RAM_QW_ADDR_WID-1:0]       cache_one_ram_qw_base_addr      ,
            input    [LB_SYS_ONE_RAM_QW_ADDR_WID  :0 ]      cache_one_ram_qw_addr_section   , //1/32 
            input    [1:0]                                  cubank_lb_mv_cub_dst_sel        ,
            //-------------------addr section config--------------------------//
           // input                                           l1b_op_width_mode               ,  //1: 256bit         0: 128bit
            input                                           l1b_op_norm_mode                ,  //1: norm    mode   0: L1cache mode
            input                                           l1b_op_norm_parallel_mode       ,                                     
            input    [1:0]                                  l1b_op_wr_hl_mask               ,
            input                                           l1b_op_weight_rd_mode           ,
            input                                           l1b_op_fmap_fifo_mode             ,  //1: single ch rd   0: double ch rd
            //input                                           l1b_op_fmap_fifo_mode             ,  //1: single ch wr   0: double ch wr
            input                                           slsu_l1b_addr_valid             ,
            input                                           slsu_l1b_wr_en                  ,
            input    [LSU_SYS_ADDR_WID -1:0]                slsu_l1b_addr                   ,
            //--------------------out addr info --------------------------//
            //bank0
            output  reg                                     l1b_bank0_weight_rd_mode         ,    
            output  reg  [LB_ONE_BANK_NUM*2 -1:0]           l1b_bank0_ram_cs                 , //16 rams
            output  reg  [LB_SYS_ONE_RAM_QW_ADDR_WID-1:0]   l1b_bank0_ram_addr               , //16   0~7,24~31  ram
            output  reg                                     l1b_bank0_ram_wr_en              ,
            output  reg  [1:0]                              l1b_bank0_mv_cub_dst_sel        ,
            //bank1
            output  reg  [1:0]                              l1b_bank1_mv_cub_dst_sel        ,
            output  reg                                     l1b_bank1_weight_rd_mode         ,    
            output  reg  [LB_ONE_BANK_NUM*2 -1:0]           l1b_bank1_ram_cs                 , //16 rams
            output  reg  [LB_SYS_ONE_RAM_QW_ADDR_WID-1:0]   l1b_bank1_ram_addr               , //16   0~7,24~31  ram
            output  reg                                     l1b_bank1_ram_wr_en          
            );

            wire l1b_op_cache_mode  =  !l1b_op_norm_mode;
            wire l1b_op_weight_mode =   l1b_op_norm_mode;
            wire slsu_l1b_rd_en     =  !slsu_l1b_wr_en ;
            wire l1b_op_cache_wr_single_ch_mode = l1b_op_cache_mode && l1b_op_fmap_fifo_mode   && slsu_l1b_wr_en  ;
            wire l1b_op_cache_wr_double_ch_mode = l1b_op_cache_mode && !l1b_op_fmap_fifo_mode  && slsu_l1b_wr_en  ;
            wire l1b_op_cache_rd_single_ch_mode = l1b_op_cache_mode && l1b_op_fmap_fifo_mode   && !slsu_l1b_wr_en ;
            wire l1b_op_cache_rd_double_ch_mode = l1b_op_cache_mode && !l1b_op_fmap_fifo_mode  && !slsu_l1b_wr_en ;


            //---------------------------base_addr/section_range define--------------------------------------------------------//
            wire            [LB_SYS_ONE_RAM_QW_ADDR_WID-1 :0]  lsu_sys_one_ram_qw_base_addr_w    =    l1b_op_weight_mode ?  0 :   cache_one_ram_qw_base_addr ;
            wire            [LB_SYS_ONE_RAM_QW_ADDR_WID :0]    lsu_sys_one_ram_qw_range_w        =    l1b_op_weight_mode ?  (1'b1 << LB_SYS_ONE_RAM_QW_ADDR_WID) :  cache_one_ram_qw_addr_section ;

            wire            [LSU_SYS_ONE_BANK_ADDR_WID-3:0 ]   l1b_sys_qw_addr_section_one_8th   =    lsu_sys_one_ram_qw_range_w ;     //1/8
            wire            [LSU_SYS_ONE_BANK_ADDR_WID-1:0 ]   l1b_sys_qw_addr_section_one_2nd   =    lsu_sys_one_ram_qw_range_w << 2; //1/2 
            wire            [LSU_SYS_ONE_BANK_ADDR_WID-2:0 ]   l1b_sys_qw_addr_section_one_4th   =    lsu_sys_one_ram_qw_range_w << 1; //1/4 

            //---------------------------------------------------------------------------------------------//
            //---------------------------------------------------------------------------------------------//
            //--------------------------lb bank0 or bank1  operation valid --------------------------------//
            //---------------------------------------------------------------------------------------------//
            //---------------------------------------------------------------------------------------------//

            reg  [LSU_SYS_ONE_BANK_ADDR_WID-1:0 ]   lsu_sys_one_bank_qw_addr;    //1/2, two bank share same addr

            reg  lsu_sys_addr_bank0_valid,    lsu_sys_addr_bank1_valid;

            //incr 2 when not move/rd fmap such as load fmap to even/odd bank , incr 1 when norm /rd fmap 
            // in weight mode  or  read  in cache, 0 is addr head
            // other is pingpong to load fmap and double parallel to read fmap

            wire l1b_bank_sel = slsu_l1b_addr >= (lsu_sys_one_ram_qw_range_w << 3) ? 1 : 0 ;

            always_comb begin
                lsu_sys_one_bank_qw_addr = l1b_op_weight_mode || l1b_op_cache_wr_single_ch_mode  ||  l1b_op_cache_rd_single_ch_mode  ?  (l1b_bank_sel? slsu_l1b_addr -  (lsu_sys_one_ram_qw_range_w << 3) :  slsu_l1b_addr[LSU_SYS_ADDR_WID-2:0] ) :    slsu_l1b_addr[LSU_SYS_ADDR_WID-1:1];
            end

            // enable double bank read when fmap move/read that is fmap_rd_mode, enable enable even/odd
            // writing when fmap load/write. norm serial write  when weight
            // load norm mode
            //  

            always_comb begin
                lsu_sys_addr_bank0_valid =   l1b_op_weight_mode || l1b_op_cache_wr_single_ch_mode || l1b_op_cache_rd_single_ch_mode ?   ~l1b_bank_sel  : (l1b_op_cache_wr_double_ch_mode  ?  ~slsu_l1b_addr[0] :  1'b1) ; // write || read serial  fmap
                lsu_sys_addr_bank1_valid =   l1b_op_weight_mode || l1b_op_cache_wr_single_ch_mode || l1b_op_cache_rd_single_ch_mode ?    l1b_bank_sel  : (l1b_op_cache_wr_double_ch_mode  ?   slsu_l1b_addr[0] :  1'b1) ;
            end
                                    
            //-------------------addr section config--------------------//
            //----------------------------------------------------------//
            //wire            [LB_RAM_NUM-1:0]                            l1b_sys_cs_addr                ; //32  ram

            wire  [LB_HALF_ONE_BANK_CS_ADDR_WID-1:0]       l1b_sys_half_one_bank_cs_addr_bank;  

            //wire  [LB_ONE_BANK_CS_ADDR_WID-1:0]       l1b_sys_one_bank_cs_addr_bank =  l1b_sys_half_one_bank_cs_addr_bank;//l1b_op_norm_mode ? {slsu_l1b_addr[LSU_SYS_ADDR_WID-1],l1b_sys_half_one_bank_cs_addr_bank}  : {slsu_l1b_addr[0],l1b_sys_half_one_bank_cs_addr_bank} ;  

            wire  [LB_SYS_ONE_RAM_QW_ADDR_WID-1:0]    l1b_sys_one_ram_qw_addr_bank;

            reg  [LB_ONE_BANK_NUM -1:0]               l1b_onebank_ram_cs_w;
            reg  [LB_ONE_BANK_NUM -1:0]               l1b_bank0_ram_cs_w;
            reg  [LB_ONE_BANK_NUM -1:0]               l1b_bank1_ram_cs_w;


       //-------------------------------------------------------------------------------------//
        always_ff@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            l1b_bank0_weight_rd_mode <=  'b0;
            l1b_bank1_weight_rd_mode <=  'b0;
        end
        else begin
            l1b_bank0_weight_rd_mode <= l1b_op_weight_rd_mode ;
            l1b_bank1_weight_rd_mode <= l1b_op_weight_rd_mode ;
        end
        end

        always_ff@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            l1b_bank0_mv_cub_dst_sel <=  'b0;
            l1b_bank1_mv_cub_dst_sel <=  'b0;
        end
        else begin
            l1b_bank0_mv_cub_dst_sel <= cubank_lb_mv_cub_dst_sel ;
            l1b_bank1_mv_cub_dst_sel <= cubank_lb_mv_cub_dst_sel ;
        end
        end
       //-------------------------------------------------------------------------------------//
        always_ff@(posedge clk  or negedge rst_n ) 
        if(!rst_n) begin
            l1b_bank0_ram_addr <= 'b0; 
            l1b_bank1_ram_addr <= 'b0;
        end
        else if(slsu_l1b_addr_valid) begin
            l1b_bank0_ram_addr <= l1b_sys_one_ram_qw_addr_bank ;
            l1b_bank1_ram_addr <= l1b_sys_one_ram_qw_addr_bank ;
        end


        always_comb begin
            //default set 0
            l1b_onebank_ram_cs_w = 'b0;
            //set selected-cs  1'b1
            //l1b_onebank_ram_cs_w[l1b_sys_one_bank_cs_addr_bank] = 1'b1;
            l1b_onebank_ram_cs_w[l1b_sys_half_one_bank_cs_addr_bank] = 1'b1;
            l1b_bank0_ram_cs_w =  l1b_op_norm_parallel_mode ?    {LB_ONE_BANK_NUM{1'b1}} :   l1b_onebank_ram_cs_w & {LB_ONE_BANK_NUM{lsu_sys_addr_bank0_valid & slsu_l1b_addr_valid}};
            l1b_bank1_ram_cs_w =  l1b_op_norm_parallel_mode ?    {LB_ONE_BANK_NUM{1'b1}} :   l1b_onebank_ram_cs_w & {LB_ONE_BANK_NUM{lsu_sys_addr_bank1_valid & slsu_l1b_addr_valid}};        
        end


        wire  [LB_ONE_BANK_NUM -1:0]    l1b_bank0_ram_wr_low_cs  = slsu_l1b_wr_en ? {LB_ONE_BANK_NUM{l1b_op_wr_hl_mask[0]}} : {LB_ONE_BANK_NUM{1'b1}};
        wire  [LB_ONE_BANK_NUM -1:0]    l1b_bank0_ram_wr_high_cs = slsu_l1b_wr_en ? {LB_ONE_BANK_NUM{l1b_op_wr_hl_mask[1]}} : {LB_ONE_BANK_NUM{1'b1}};
        wire  [LB_ONE_BANK_NUM -1:0]    l1b_bank1_ram_wr_low_cs  = slsu_l1b_wr_en ? {LB_ONE_BANK_NUM{l1b_op_wr_hl_mask[0]}} : {LB_ONE_BANK_NUM{1'b1}};
        wire  [LB_ONE_BANK_NUM -1:0]    l1b_bank1_ram_wr_high_cs = slsu_l1b_wr_en ? {LB_ONE_BANK_NUM{l1b_op_wr_hl_mask[1]}} : {LB_ONE_BANK_NUM{1'b1}};

        always@(posedge clk or negedge rst_n) begin
            if(!rst_n)
               l1b_bank0_ram_cs <= 'b0;
            else
               l1b_bank0_ram_cs  <=  {l1b_bank0_ram_cs_w & l1b_bank0_ram_wr_high_cs, l1b_bank0_ram_cs_w & l1b_bank0_ram_wr_low_cs} ;
        end
        
        always@(posedge clk or negedge rst_n) begin
            if(!rst_n)
               l1b_bank1_ram_cs <= 'b0;
            else
               l1b_bank1_ram_cs  <=  {l1b_bank1_ram_cs_w & l1b_bank0_ram_wr_high_cs, l1b_bank1_ram_cs_w & l1b_bank0_ram_wr_low_cs} ;
        end
        
        always@(posedge clk or negedge rst_n) begin
            if(!rst_n) begin
               l1b_bank0_ram_wr_en <= 'b0;
               l1b_bank1_ram_wr_en <= 'b0;
            end
            else  begin
               l1b_bank0_ram_wr_en <= slsu_l1b_wr_en;
               l1b_bank1_ram_wr_en <= slsu_l1b_wr_en;
            end
        end
        //cs compute
        l1b_cache_qw_addr_dichotomie_comp      #(
                    .LB_RAM_NUM                  (LB_RAM_NUM                      ),//16 ram
                    .LB_HALF_ONE_BANK_CS_ADDR_WID(LB_HALF_ONE_BANK_CS_ADDR_WID    ),  //4
                    .LB_SYS_ONE_RAM_QW_ADDR_WID  (LB_SYS_ONE_RAM_QW_ADDR_WID      ))
        U_l1b_cache_qw_addr_dichotomie_comp (
        .clk                                        (clk                                           ),
        .rst_n                                      (rst_n                                         ),
        //config
        .lsu_sys_one_ram_qw_base_addr               (lsu_sys_one_ram_qw_base_addr_w                ),      
        .lsu_sys_one_ram_qw_range                   (lsu_sys_one_ram_qw_range_w                    ),
        .l1b_sys_qw_addr_section_one_2nd            (l1b_sys_qw_addr_section_one_2nd               ),
        .l1b_sys_qw_addr_section_one_4th            (l1b_sys_qw_addr_section_one_4th               ),
        .l1b_sys_qw_addr_section_one_8th            (l1b_sys_qw_addr_section_one_8th               ),
        //
        .lsu_sys_one_bank_qw_addr                   (lsu_sys_one_bank_qw_addr                      ),
        .l1b_sys_one_bank_cs_addr                   (l1b_sys_half_one_bank_cs_addr_bank            ), //16  ram
        .l1b_sys_one_ram_qw_addr                    (l1b_sys_one_ram_qw_addr_bank                  )
        );
         
        
endmodule
