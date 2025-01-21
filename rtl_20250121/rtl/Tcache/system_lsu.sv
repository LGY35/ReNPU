module system_lsu #(
             parameter           L1B_RAM_DEPTH       =       256,
             parameter           L1B_RAM_DBANK       =       16 , //double bank
             parameter           L1B_RAM_ADDR_WID    =       $clog2(L1B_RAM_DEPTH)+$clog2(L1B_RAM_DBANK)  // 9+4
            )(
            //--------------------   clk /rst_n------------------------------------//
            input                                           clk                                 ,
            input                                           rst_n                               ,
            //-------------------------------------------------------------------------//
            input                                           slsu_data_req                       ,
            output                                          slsu_data_gnt                       ,
            output reg                                      slsu_data_ok                        ,
            input                                           slsu_l1b_mode                       , // 1: norm weight mode 0: fmap cache
            input  [2:0]                                    slsu_tcache_mode                    , 
            input                                           slsu_data_we                        ,
            input                                           slsu_data_mv_last_dis                   ,
            input  [L1B_RAM_ADDR_WID-1 : 0]                 slsu_data_addr                      ,  
            input  [$clog2(L1B_RAM_DEPTH)-1: 0]             slsu_data_sys_len                   ,  
            input  [$clog2(L1B_RAM_DEPTH)-1: 0]             slsu_data_sub_len                   ,  //9bit
            input  [$clog2(L1B_RAM_DEPTH)-1: 0]             slsu_data_sys_gap                   ,  //1 bit signed, 16bank = 4bit , 512depth = 9bit , 14bit
            //cfg
            input                                           slsu_cfg_vld                        ,
            input                                           slsu_cfg_type                        ,
            input                                           slsu_state_clr                      ,
            input                                           slsu_l1b_gpu_mode                   ,  
            input                                           slsu_l1b_norm_paral_mode            ,
            input   [1:0]                                   slsu_l1b_op_wr_hl_mask              ,                                     
            input  [$clog2(L1B_RAM_DEPTH)-1:0]              slsu_cache_one_ram_qw_base_addr     ,
            input  [$clog2(L1B_RAM_DBANK)  :0]              slsu_data_sys_gap_ext               ,  //1 bit signed, 16bank = 4bit , 512depth = 9bit , 14bit
            input  [$clog2(L1B_RAM_DEPTH)-1: 0]             slsu_data_sub_gap                   ,    
            input  [1:0]                                    slsu_mv_cub_dst_sel                 ,
            input                                           slsu_tcache_trans_prici             , // 0: byte 1:hword
            input                                           slsu_tcache_trans_swbank            , // 0: byte 1:hword
            input                                           slsu_tcache_core_load_bank_num      ,
            input                                           slsu_iob_pric                       ,       //1: int16  0: int8
            input                                           slsu_iob_l2c_in_cfg                 ,
            //-------------------------------------------------------------------------//
            output reg                                      state_clr                           , 
            output reg                                      iob_pric                            ,       //1: int16  0: int8
            output reg                                      iob_l2c_in_cfg                      ,
            output reg [2:0]                                tcache_mode                         , 
            output reg                                      l1b_gpu_mode                        ,
            output reg                                      bcfmap_dfifo_addr_odd               ,
            output                                          bcfmap_req_disable                  ,
            output reg                                      mvfmap_dfifo_addr_odd               ,
            output reg                                      l1b_op_weight_rd_mode               ,
            output reg                                      l1b_op_norm_mode                    ,  //1: norm    mode   0: L1cache mode
            output                                          l1b_op_norm_parallel_mode           ,  //to addr table
            output                                          l1b_op_fmap_rd_mode                 ,
            output                                          l1b_op_fmap_wr_mode                 ,
            output reg [1:0]                                l1b_op_wr_hl_mask                   ,
            output reg [$clog2(L1B_RAM_DEPTH)-1:0]          cache_one_ram_qw_base_addr          ,
            output reg [$clog2(L1B_RAM_DEPTH)  :0]          cache_one_ram_qw_addr_section       , //1/32 
            output reg [1:0]                                cubank_lb_mv_cub_dst_sel            ,
            output reg                                      tcache_core_load_bank_num           ,
            output                                          tcache_core_move_fmap_last          ,
            output reg                                      tcache_core_trans_prici             ,
            output reg                                      tcache_core_trans_swbank            ,
            input                                           tcache_core_move_fmap_en            ,
            //--------------------from NoC data valid --------------------//
            input                                           load_data_to_l1b_vld                ,
            //--------------------to l1b --------------------------------//
            output reg                                      slsu_l1b_wr_en                      ,
            output reg                                      slsu_l1b_addr_valid                 ,
            output      [L1B_RAM_ADDR_WID-1: 0]             slsu_l1b_addr                         
        );


          reg                                          slsu_l1b_rd_mode_r    ;// 1: norm weight mode 0: fmap cache
          reg                                          slsu_data_we_r        ;
          reg                                          slsu_data_mv_last_dis_r   ;
          reg        [$clog2(L1B_RAM_DEPTH)-1 : 0]     slsu_data_sys_len_r   ;  


          reg        [$clog2(L1B_RAM_DEPTH)-1: 0]      slsu_data_sub_len_r   ;  //  addr :    config  min is 1, load data to l1b
          reg        [$clog2(L1B_RAM_DEPTH)  : 0]      slsu_data_sub_gap_r   ;  //  addr :    config  min is 1, load data to l1b

          reg        [$clog2(L1B_RAM_DEPTH)-1 : 0]     slsu_data_sys_gap_r   ;//1 bit signed, 16bank = 4bit , 512depth = 9bit , 14bit

          reg        [$clog2(L1B_RAM_DBANK):0]         slsu_data_sys_gap_ext_r ;  //1 bit signed, 16bank = 4bit , 512depth = 9bit , 14bit
          reg        [L1B_RAM_ADDR_WID   : 0]          slsu_data_addr_r      ;//1 bit signed, 16bank = 4bit , 512depth = 9bit , 14bit, same as sys_gap  
          reg signed [L1B_RAM_ADDR_WID   : 0]          slsu_l1b_addr_signed  ;       

          assign  slsu_l1b_addr = slsu_l1b_addr_signed [L1B_RAM_ADDR_WID-1: 0] ;       
   
          
 //---------------------------------slsu_tcache_mode-------------------------------------//
 //--------------------------------------------------------------------------------------//
    localparam CONV16CH_DFIFO_MODE  = 'b000   ;       //wr/rd    l1b cache    tcache_FIFO
    localparam CONV16CH_SFIFO_MODE  = 'b001   ;       //wr/rd    l1b cache    tcache_FIFO
    localparam CONV32CH_DFIFO_MODE  = 'b010   ;       //wr/rd    l1b cache    tcache_FIFO
    localparam CONV32CH_SFIFO_MODE  = 'b011   ;       //wr/rd    l1b cache    tcache_FIFO
    localparam TRANS_MATRIX_MODE    = 'b100   ;       //wr       l1b cache    tcache_TRANS in l1b_cache
    localparam TRANS_DWCONV_MODE    = 'b111   ;       //wr       l1b norm     tcache_TRANS in l1b_weight

          //auto rd fsm
    enum logic [2:0] {
         SLSU_IDLE = 'b0    ,
         MOVE_FMAP_NORM     ,    
         LOAD_FMAP_NORM     ,
         LOAD_TRANS_MATRIX  ,
         MOVE_WEIGHT        ,
         LOAD_WEIGHT        ,
         LOAD_TRANS_DWCONV  
    } slsu_cs, slsu_ns;



//-------------------------------------------------------------------------------------------------//
//-------------------------------------------------------------------------------------------------//
//-----------------------------------       request command      ----------------------------------//
//-------------------------------------------------------------------------------------------------//
//-------------------------------------------------------------------------------------------------//
    
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n)  begin
          //  slsu_l1b_rd_mode_r  <= 'b0  ;  // 1: norm weight mode 0: fmap cache
            l1b_op_norm_mode            <= 'b0    ;  //1: norm    mode   0: L1cache mode
            slsu_data_we_r              <= 'b0  ;
            slsu_data_mv_last_dis_r     <= 'b0  ;
            slsu_data_addr_r            <= 'b0  ;  //  addr :  8+5
            slsu_data_sys_len_r         <= 'b1  ;                 
            slsu_data_sub_len_r         <= 'b1  ; //init 1
            slsu_data_sys_gap_r         <= 'b1  ; 
            tcache_core_load_bank_num   <= 'b0    ;
            end
        else if( slsu_data_req) begin
           // slsu_l1b_rd_mode_r  <= slsu_l1b_mode    ;  // 1: norm weight mode 0: fmap cache
            l1b_op_norm_mode            <= slsu_l1b_mode     ;  //1: norm    mode   0: L1cache mode
            slsu_data_we_r              <= slsu_data_we      ;
            slsu_data_mv_last_dis_r     <= slsu_data_mv_last_dis ;
            slsu_data_addr_r            <= {1'b0, slsu_data_addr  } ;  //  addr :  8+5
            slsu_data_sub_len_r         <= slsu_data_sub_len ;
            slsu_data_sys_len_r         <= slsu_data_sys_len ;  
            slsu_data_sys_gap_r         <=  slsu_data_sys_gap  ;  
            tcache_core_load_bank_num   <= slsu_tcache_core_load_bank_num         ;
        end
    end


    always@(posedge clk or negedge rst_n ) begin
        if(!rst_n)
            bcfmap_dfifo_addr_odd <= 'b0 ;
        else if(slsu_data_ok && (slsu_cs == MOVE_FMAP_NORM) )
            bcfmap_dfifo_addr_odd <= slsu_data_addr_r[0] && (  tcache_mode == CONV16CH_DFIFO_MODE || tcache_mode == CONV32CH_DFIFO_MODE ) ;
    end

    always@(posedge clk or negedge rst_n ) begin
        if(!rst_n)
            mvfmap_dfifo_addr_odd <= 'b0 ;
        else if(slsu_cs == MOVE_FMAP_NORM )
            mvfmap_dfifo_addr_odd <= slsu_data_addr_r[0] && (  tcache_mode == CONV16CH_DFIFO_MODE || tcache_mode == CONV32CH_DFIFO_MODE ) ;
    end
    wire  signed [L1B_RAM_ADDR_WID   : 0]  slsu_data_sys_gap_signed = {slsu_data_sys_gap_ext_r, slsu_data_sys_gap_r} == 0 ? L1B_RAM_DEPTH :   {slsu_data_sys_gap_ext_r, slsu_data_sys_gap_r} ;//1 bit signed, 16bank = 4bit , 512depth = 9bit , 14bit
    assign  slsu_data_gnt    = slsu_data_req;

        wire [$clog2(L1B_RAM_DEPTH)-1: 0]  slsu_data_sub_len_sub1 = ( slsu_data_sub_len_r == 0 )?  (L1B_RAM_DEPTH -1 ): slsu_data_sub_len_r-1   ;  //  addr :    config  min is 1, load data to l1b
//    `ifdef SMIC12
//        wire [$clog2(L1B_RAM_DEPTH)-1: 0]  slsu_data_sub_len_sub1 = ( slsu_data_sub_len_r == 0 )? 511 : slsu_data_sub_len_r-1   ;  //  addr :    config  min is 1, load data to l1b
//    `else
//        wire [$clog2(L1B_RAM_DEPTH)-1: 0]  slsu_data_sub_len_sub1 = ( slsu_data_sub_len_r == 0 )? 255 : slsu_data_sub_len_r-1   ;  //  addr :    config  min is 1, load data to l1b
//    `endif

   wire [L1B_RAM_ADDR_WID-1     : 0]  slsu_data_sys_len_sub1 = slsu_data_sys_len_r == 0 ?  (L1B_RAM_DEPTH -1 ): slsu_data_sys_len_r - 1       ;  //  addr :  8+5

//-------------------------------------------------------------------------------------------------//
//-------------------------------------------------------------------------------------------------//
//-----------------------------------       config      -------------------------------------------//
//-------------------------------------------------------------------------------------------------//
//-------------------------------------------------------------------------------------------------//
    //assign tcache_mode = slsu_tcache_mode_r;
//-------------------------------------------------------------------//
    //l1b op mode 1: cubank 0:tcache
    //IDLE to config
    //command cfg
    //
    //`ifdef SMIC12
    //    wire [$clog2(L1B_RAM_DEPTH) : 0]   slsu_cache_one_ram_qw_addr_section = 512 - slsu_cache_one_ram_qw_base_addr ;
    //`else
    //    wire [$clog2(L1B_RAM_DEPTH) : 0]   slsu_cache_one_ram_qw_addr_section = 256 - slsu_cache_one_ram_qw_base_addr ;
    //`endif

    wire [$clog2(L1B_RAM_DEPTH) : 0]   slsu_cache_one_ram_qw_addr_section = L1B_RAM_DEPTH - slsu_cache_one_ram_qw_base_addr ;


    reg l1b_norm_paral_mode;

    //cfg reg 0
 always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            l1b_gpu_mode                    <= 'b0    ;
            tcache_mode                     <= 'b0  ;  // 1: tcache transpose 0: fifo
            l1b_norm_paral_mode             <= 'b0    ;
            l1b_op_wr_hl_mask               <= 'b11   ;
            cache_one_ram_qw_base_addr      <= 'b0    ;
            cache_one_ram_qw_addr_section   <= 'b0    ;
            state_clr                       <= 'b0    ;
            cubank_lb_mv_cub_dst_sel        <= 'b0    ;
            tcache_core_trans_prici         <= 'b0    ;
            tcache_core_trans_swbank         <= 'b0    ;
            iob_pric                <=  'b0 ;
            iob_l2c_in_cfg          <=  'b0 ;
        end
        else if( slsu_cfg_vld  && !slsu_cfg_type) begin
            tcache_mode                     <= slsu_tcache_mode  ;  // 1: tcache transpose 0: fifo
            l1b_gpu_mode                    <= slsu_l1b_gpu_mode                      ;
            l1b_norm_paral_mode             <= slsu_l1b_norm_paral_mode               ;
            l1b_op_wr_hl_mask               <= ~slsu_l1b_op_wr_hl_mask                ;
            cache_one_ram_qw_base_addr      <= slsu_cache_one_ram_qw_base_addr        ;
            cache_one_ram_qw_addr_section   <= slsu_cache_one_ram_qw_addr_section     ;//(slsu_cache_one_ram_qw_addr_section  == 0 )? 256 :   {1'b0,  slsu_cache_one_ram_qw_addr_section };   
            state_clr                       <= slsu_state_clr                         ;
            cubank_lb_mv_cub_dst_sel        <= slsu_mv_cub_dst_sel                    ;
            tcache_core_trans_prici         <= slsu_tcache_trans_prici                ;
            tcache_core_trans_swbank        <= slsu_tcache_trans_swbank                ;
            iob_pric                <=  slsu_iob_pric ;
            iob_l2c_in_cfg          <=  slsu_iob_l2c_in_cfg ;
        end
        else
            state_clr               <= 'b0  ;
    end

    //cfg regs 1
   always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            slsu_data_sys_gap_ext_r <= 'b0  ;
            slsu_data_sub_gap_r     <= 'b1  ; 
        end
        else if( slsu_cfg_vld  && slsu_cfg_type) begin
            slsu_data_sys_gap_ext_r <= slsu_data_sys_gap_ext  ;
            slsu_data_sub_gap_r     <= slsu_data_sub_gap  == 0 ?  L1B_RAM_DEPTH :    slsu_data_sub_gap  ;
        end
   end
 //--------------------------------------------------------------------------------------//


      always@(posedge clk or negedge rst_n) begin
        if(!rst_n)
            slsu_cs <= SLSU_IDLE;
        else
            slsu_cs <= slsu_ns ;
    end
    
    //------------------------------------------------------------------------------//
    //---------------------------very important-------------------------------------//
    //------------------------------------------------------------------------------//
    //work mode is decided by slsu_l1b_mode,slsu_tcache_mode,slsu_data_we
    //l1b mode, tcache mode, wr/rd mode


    assign bcfmap_req_disable = slsu_data_req && slsu_ns == MOVE_FMAP_NORM ;

    always_comb begin
    case(slsu_cs)
        //--------------------------------------------------------------------------//
        SLSU_IDLE       :  if(slsu_data_req) begin //slsu_tcache_mode[2] 1: use tcache 0: not use
                            casez({slsu_l1b_mode, tcache_mode[2], slsu_data_we})
                            'b000:   slsu_ns = MOVE_FMAP_NORM   ;   //cache, read  l1b cache
                            'b001:   slsu_ns = LOAD_FMAP_NORM   ;   //cache, Write l1b cache
                            'b011:   slsu_ns = LOAD_TRANS_MATRIX;   //cache, Write l1b cache
                            'b1?0:   slsu_ns = MOVE_WEIGHT      ;   //norm,  read Weight+DWCONV parallel, not use tcache
                            'b101:   slsu_ns = LOAD_WEIGHT      ;   //norm,  load Weight, not use tcache
                            'b111:   slsu_ns = LOAD_TRANS_DWCONV;   //norm,  load DWCONV, use tcache
                            default: slsu_ns = SLSU_IDLE        ;
                            endcase
        end
        else    slsu_ns = SLSU_IDLE;
        //--------------------------------------------------------------------------//
        MOVE_FMAP_NORM   ,   
        LOAD_FMAP_NORM   ,
        LOAD_TRANS_MATRIX, 
        LOAD_TRANS_DWCONV,
        MOVE_WEIGHT      ,     
        LOAD_WEIGHT      :    begin
                if(slsu_data_ok)  begin
                    if(slsu_data_req) begin //slsu_tcache_mode[2] 1: use tcache 0: not use
                            casez({slsu_l1b_mode,tcache_mode[2],slsu_data_we})
                            'b000:   slsu_ns = MOVE_FMAP_NORM   ;   //cache, read  l1b cache
                            'b001:   slsu_ns = LOAD_FMAP_NORM   ;   //cache, Write l1b cache
                            'b011:   slsu_ns = LOAD_TRANS_MATRIX;   //cache, Write l1b cache
                            'b1?0:   slsu_ns = MOVE_WEIGHT      ;   //norm,  read Weight+DWCONV parallel,  not use tcache
                            'b101:   slsu_ns = LOAD_WEIGHT      ;   //norm,  load Weight, not use tcache
                            'b111:   slsu_ns = LOAD_TRANS_DWCONV;   //norm,  load DWCONV, use tcache
                            default: slsu_ns = SLSU_IDLE        ;
                            endcase
                    end
                    else    slsu_ns = SLSU_IDLE;
                end
                else slsu_ns = slsu_cs ;
             end
        default:   slsu_ns = SLSU_IDLE;          
    endcase
    end
    

   //------------------------------------------------------------//
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n)
            l1b_op_weight_rd_mode   <= 'b0;
        else
            l1b_op_weight_rd_mode   <= ( slsu_cs == MOVE_WEIGHT );
    end

   // always@(posedge clk or negedge rst_n) begin
   //     if(!rst_n)
   //         l1b_op_fmap_rd_mode   <= 'b0;
   //     else
   //         l1b_op_fmap_rd_mode   <= (( slsu_cs == MOVE_FMAP_NORM ) && ((slsu_tcache_mode == CONV16CH_DFIFO_MODE) || (slsu_tcache_mode == CONV32CH_DFIFO_MODE) ) );
   // end

    assign l1b_op_norm_parallel_mode  = ( slsu_cs == MOVE_WEIGHT ) || (l1b_norm_paral_mode == 1);
    assign l1b_op_fmap_rd_mode   =  (tcache_mode == CONV16CH_SFIFO_MODE) || (tcache_mode == CONV32CH_SFIFO_MODE)  ; //(( slsu_cs == MOVE_FMAP_NORM ));//
    assign l1b_op_fmap_wr_mode =    (tcache_mode == CONV16CH_SFIFO_MODE) || (tcache_mode == CONV32CH_SFIFO_MODE)  ;
    //assign slsu_cfg_rdy = ( slsu_cs == SLSU_IDLE );

    
    reg  [$clog2(L1B_RAM_DEPTH)-1: 0]    addr_sub_len_cnt           ;
    reg [L1B_RAM_ADDR_WID-1 : 0]         addr_sys_len_cnt           ;  

    always@(posedge clk or negedge rst_n) begin
        if(!rst_n)  begin
            slsu_l1b_addr_signed   <= 'b0  ;  
            addr_sub_len_cnt           <= 'b0  ;
            addr_sys_len_cnt           <= 'b0  ;
          //  slsu_data_ok           <= 'b0;
            end
        else if(slsu_data_req) begin
            slsu_l1b_addr_signed   <=  slsu_data_addr  ;                 
            addr_sub_len_cnt           <= 'b0  ;
            addr_sys_len_cnt           <= 'b0  ;
          //  slsu_data_ok           <= 'b0;
        end
        else if(slsu_cs == SLSU_IDLE) begin
            slsu_l1b_addr_signed   <=  slsu_data_addr_r  ;                 
            addr_sub_len_cnt           <= 'b0  ;
            addr_sys_len_cnt           <= 'b0  ;
          //  slsu_data_ok           <= 'b0;
        end
        else if(slsu_cs != SLSU_IDLE) begin
            case(slsu_cs)
            MOVE_FMAP_NORM : if(tcache_core_move_fmap_en) begin          //read L1b, dirtect to generate address
                     if(addr_sub_len_cnt == slsu_data_sub_len_sub1 ) begin
                         addr_sub_len_cnt           <=  0    ;

                         if(addr_sys_len_cnt ==  slsu_data_sys_len_sub1 ) begin
                            slsu_l1b_addr_signed    <= slsu_data_addr_r; //initial  start addr for next loop
                            addr_sys_len_cnt        <= 0;
                            end
                         else begin
                            addr_sys_len_cnt        <=  addr_sys_len_cnt  +  1  ;
                            slsu_l1b_addr_signed    <=  slsu_l1b_addr_signed + slsu_data_sys_gap_signed + (!l1b_op_fmap_rd_mode && slsu_data_sys_gap_signed[0] ? 1 : 0)  ;  
                         end
                     end
                     else begin
                         addr_sub_len_cnt        <= addr_sub_len_cnt     +   1  ;
                         slsu_l1b_addr_signed    <= slsu_l1b_addr_signed + slsu_data_sub_gap_r + ( !l1b_op_fmap_rd_mode && slsu_data_sub_gap_r[0] ? 1 : 0) ;
                         addr_sys_len_cnt        <= addr_sys_len_cnt     ;
                     end

            end
            MOVE_WEIGHT    : begin          //read L1b, dirtect to generate address
                     if(addr_sub_len_cnt == slsu_data_sub_len_sub1 ) begin
                         addr_sub_len_cnt        <=  0    ;

                         if(addr_sys_len_cnt ==  slsu_data_sys_len_sub1 ) begin
                            slsu_l1b_addr_signed<= slsu_data_addr_r;
                            addr_sys_len_cnt        <= 0;
                            end
                         else begin
                            addr_sys_len_cnt        <=  addr_sys_len_cnt  + 1 ;
                            slsu_l1b_addr_signed<=  slsu_l1b_addr_signed + slsu_data_sys_gap_signed  ;  
                            end
                     end 
                     else begin
                         addr_sub_len_cnt        <= addr_sub_len_cnt  +  1;
                         slsu_l1b_addr_signed<= slsu_l1b_addr_signed + slsu_data_sub_gap_r ;  
                         addr_sys_len_cnt        <= addr_sys_len_cnt     ;
                     end

            end
            LOAD_FMAP_NORM ,
            LOAD_TRANS_MATRIX ,
            LOAD_TRANS_DWCONV ,
            LOAD_WEIGHT    :  begin
                if(load_data_to_l1b_vld) begin
                     if(addr_sub_len_cnt == slsu_data_sub_len_sub1 ) begin
                         addr_sub_len_cnt        <=  0    ;

                         if(addr_sys_len_cnt ==  slsu_data_sys_len_sub1 ) begin
                            slsu_l1b_addr_signed    <= slsu_data_addr_r;
                            addr_sys_len_cnt        <= 0;
                            end
                         else begin
                            addr_sys_len_cnt        <=  addr_sys_len_cnt  + 1 ;
                            slsu_l1b_addr_signed    <=  slsu_l1b_addr_signed + slsu_data_sys_gap_signed  ;  
                            end
                     end 
                     else begin
                         addr_sub_len_cnt           <= addr_sub_len_cnt  + 1 ;
                         slsu_l1b_addr_signed       <= slsu_l1b_addr_signed + slsu_data_sub_gap_r;  
                         addr_sys_len_cnt           <= addr_sys_len_cnt     ;
                     end
                end

            end
            default:   slsu_l1b_addr_signed    <= slsu_data_addr_r; 
            endcase
        end
      else if(slsu_cs == SLSU_IDLE) begin
              slsu_l1b_addr_signed          <= slsu_data_addr_r ;                 
              addr_sub_len_cnt           <= 'b0  ;
              addr_sys_len_cnt           <= 'b0  ;
      end
    end

    assign tcache_core_move_fmap_last = (slsu_cs == MOVE_FMAP_NORM ) && !slsu_data_mv_last_dis_r ? slsu_data_ok : 0;

    always_comb begin
        if(slsu_cs != SLSU_IDLE) begin
            case(slsu_cs)
            MOVE_FMAP_NORM : if(tcache_core_move_fmap_en) begin          //read L1b, dirtect to generate address
                     slsu_l1b_addr_valid    = 'b1 ;
                     slsu_l1b_wr_en         = 'b0  ;  

               if((addr_sub_len_cnt == slsu_data_sub_len_sub1)&&(addr_sys_len_cnt == slsu_data_sys_len_sub1 ))
                     slsu_data_ok           = 'b1;
                else
                     slsu_data_ok           = 'b0;
            end
            else begin
                     slsu_l1b_wr_en         = 'b0  ;  
                     slsu_l1b_addr_valid    = 'b0 ;
                     slsu_data_ok           = 'b0;
            end

            MOVE_WEIGHT    : begin          //read L1b, dirtect to generate address
                     slsu_l1b_addr_valid    = 'b1 ;
                     slsu_l1b_wr_en         = 'b0  ;  
               if((addr_sub_len_cnt == slsu_data_sub_len_sub1)&&(addr_sys_len_cnt == slsu_data_sys_len_sub1 ))
                     slsu_data_ok           = 'b1;
                else
                     slsu_data_ok           = 'b0;
            end
            LOAD_FMAP_NORM ,
            LOAD_TRANS_MATRIX ,
            LOAD_TRANS_DWCONV , 
            LOAD_WEIGHT    :  begin
                if(load_data_to_l1b_vld) begin
                     slsu_l1b_addr_valid    = 'b1 ;
                     slsu_l1b_wr_en         = 'b1  ;  
                end
                else begin
                     slsu_l1b_addr_valid    = 'b0 ;
                     slsu_l1b_wr_en         = 'b1  ;  
                end

               if((addr_sub_len_cnt == slsu_data_sub_len_sub1)&&(addr_sys_len_cnt ==  slsu_data_sys_len_sub1 )&&load_data_to_l1b_vld)
                     slsu_data_ok           = 'b1;
                else
                     slsu_data_ok           = 'b0;
            end
            default: begin
                     slsu_l1b_addr_valid    = 'b0 ;
                     slsu_l1b_wr_en         = 'b0  ;  
                     slsu_data_ok           = 'b0;
            end
            endcase
        end
      else begin
              slsu_l1b_addr_valid     = 'b0  ;
              slsu_l1b_wr_en          = 'b0  ;  
               slsu_data_ok           = 'b0  ;

      end
    end


endmodule
