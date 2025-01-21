module hid_lsu #(
             parameter           L1B_RAM_DEPTH       =       256,
             parameter           L1B_RAM_DBANK       =       16 , //double bank
             parameter           L1B_RAM_ADDR_WID    =       $clog2(L1B_RAM_DEPTH)+$clog2(L1B_RAM_DBANK)  // 9+4
            )(
            //--------------------   clk /rst_n------------------------------------//
            input                                           clk                                 ,
            input                                           rst_n                               ,
            //-------------------------------------------------------------------------//
            input                                           hlsu_data_req                       ,
            output                                          hlsu_data_gnt                       ,
            output reg                                      hlsu_data_ok                        ,
            input                                           hlsu_l1b_mode                       , // 1: norm weight mode 0: fmap cache
            input                                           hlsu_data_we                        ,
            input  [L1B_RAM_ADDR_WID-1 : 0]                 hlsu_data_addr                      ,//12bit
            input  [$clog2(L1B_RAM_DEPTH)-1: 0]             hlsu_data_sys_len                   ,  
            input  [$clog2(L1B_RAM_DEPTH)-1: 0]             hlsu_data_sub_len                   ,  //9bit
            input  [$clog2(L1B_RAM_DEPTH)-1: 0]             hlsu_data_sys_gap                   ,  //1 bit signed, 16bank = 4bit , 512depth = 9bit , 14bit

            output                                          hlsu_chk_done_gnt                   ,
            input                                           hlsu_chk_done_req                  ,
            //cfg
            input                                           hlsu_cfg_vld                        ,
            input  [1:0]                                    hlsu_cfg_type                       ,
            input  [$clog2(L1B_RAM_DBANK)  :0]              hlsu_data_sys_gap_ext               ,  //1 bit signed, 16bank = 4bit , 512depth = 9bit , 14bit
            input                                           hlsu_l1b_norm_paral_mode            ,
            input  [$clog2(L1B_RAM_DEPTH)-1: 0]             hlsu_data_sub_gap                   ,    
            
            //-------------------------------------------------------------------------//
            input      [2:0]                                tcache_mode                         , 
            output reg                                      l1b_op_norm_mode                    ,  //1: norm    mode   0: L1cache mode
            output                                          l1b_op_norm_parallel_mode           ,  //to addr table
            //--------------------from NoC data valid --------------------//
            input                                           load_data_to_l1b_vld                ,
            output                                          load_data_to_l2_ready               ,
            //--------------------to l1b --------------------------------//
            output reg                                      hlsu_l1b_wr_en                      ,
            input                                           hlsu_l1b_addr_ready                 ,
            output reg                                      hlsu_l1b_addr_valid                 ,
            output      [L1B_RAM_ADDR_WID-1: 0]             hlsu_l1b_addr                         
        );


          wire                                         tcache_core_move_fmap_en   = 1'b1;

          reg                                          hlsu_data_done        ;
          reg                                          load_data_done_r      ;
          reg                                          chk_done_waiting      ;

          reg                                          hlsu_l1b_rd_mode_r    ;// 1: norm weight mode 0: fmap cache
          reg                                          hlsu_data_we_r        ;
          reg                                          hlsu_data_mv_last_dis_r   ;
          reg        [$clog2(L1B_RAM_DEPTH)-1 : 0]     hlsu_data_sys_len_r   ;  


          reg        [$clog2(L1B_RAM_DEPTH)-1: 0]      hlsu_data_sub_len_r   ;  //  addr :    config  min is 1, load data to l1b
          reg        [$clog2(L1B_RAM_DEPTH)  : 0]      hlsu_data_sub_gap_r   ;  //  addr :    config  min is 1, load data to l1b

          reg        [$clog2(L1B_RAM_DEPTH)-1 : 0]     hlsu_data_sys_gap_r   ;//1 bit signed, 16bank = 4bit , 512depth = 9bit , 14bit

          reg        [$clog2(L1B_RAM_DBANK):0]         hlsu_data_sys_gap_ext_r ;  //1 bit signed, 16bank = 4bit , 512depth = 9bit , 14bit
          reg        [L1B_RAM_ADDR_WID   : 0]          hlsu_data_addr_r      ;//1 bit signed, 16bank = 4bit , 512depth = 9bit , 14bit, same as sys_gap  
          reg signed [L1B_RAM_ADDR_WID   : 0]          hlsu_l1b_addr_signed  ; 

          assign  hlsu_l1b_addr = hlsu_l1b_addr_signed [L1B_RAM_ADDR_WID-1: 0] ;       

          
 //---------------------------------hlsu_tcache_mode-------------------------------------//
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
    } hlsu_cs, hlsu_ns;



    wire l1b_op_fmap_fifo_mode =  (tcache_mode == CONV16CH_SFIFO_MODE) || (tcache_mode == CONV32CH_SFIFO_MODE)  ;

//-------------------------------------------------------------------------------------------------//
//-------------------------------------------------------------------------------------------------//
//-----------------------------------       request command      ----------------------------------//
//-------------------------------------------------------------------------------------------------//
//-------------------------------------------------------------------------------------------------//
    
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n)  begin
          //  hlsu_l1b_rd_mode_r  <= 'b0  ;  // 1: norm weight mode 0: fmap cache
            l1b_op_norm_mode            <= 'b0    ;  //1: norm    mode   0: L1cache mode
            hlsu_data_we_r              <= 'b0  ;
            hlsu_data_addr_r            <= 'b0  ;  //  addr :  8+5
            hlsu_data_sys_len_r         <= 'b1  ;                 
            hlsu_data_sub_len_r         <= 'b1  ; //init 1
            end
        else if( hlsu_data_req ) begin
           // hlsu_l1b_rd_mode_r  <= hlsu_l1b_mode    ;  // 1: norm weight mode 0: fmap cache
            l1b_op_norm_mode            <= hlsu_l1b_mode     ;  //1: norm    mode   0: L1cache mode
            hlsu_data_we_r              <= 1'b1 ;//hlsu_data_we      ;
            hlsu_data_addr_r            <= {1'b0, hlsu_data_addr  } ;  //  addr :  8+5
            hlsu_data_sub_len_r         <= hlsu_data_sub_len ;
            hlsu_data_sys_len_r         <= hlsu_data_sys_len ;  
            hlsu_data_sys_gap_r         <= hlsu_data_sys_gap ;
        end
    end

    //
   assign hlsu_data_ok     = hlsu_data_req ; 
   assign hlsu_data_gnt    = hlsu_data_req ; 

   always@(posedge  clk or negedge rst_n ) begin
        if(!rst_n) 
            load_data_done_r <= 'b0 ;
        else if(hlsu_data_done && (!chk_done_waiting) &&  !( hlsu_chk_done_req || hlsu_data_req))
            load_data_done_r <= 1'b1 ;
        else if(hlsu_data_req || hlsu_chk_done_req )
            load_data_done_r <= 1'b0 ;
   end



   always@(posedge  clk or negedge rst_n ) begin
        if(!rst_n) 
            chk_done_waiting <= 'b0 ;
        else if(hlsu_chk_done_req && !hlsu_data_done && (!load_data_done_r) )
            chk_done_waiting <= 1'b1 ;
        else if(hlsu_data_done)
            chk_done_waiting <= 1'b0 ;
   end

   
  // assign hlsu_chk_done_gnt    = hlsu_chk_done_req || chk_done_waiting ?  hlsu_data_done :  load_data_done_r ;
   assign hlsu_chk_done_gnt    =   hlsu_data_done || load_data_done_r ;

    wire  signed [L1B_RAM_ADDR_WID   : 0]  hlsu_data_sys_gap_signed = {hlsu_data_sys_gap_ext_r, hlsu_data_sys_gap_r} == 0 ? L1B_RAM_DEPTH :   {hlsu_data_sys_gap_ext_r, hlsu_data_sys_gap_r} ;//1 bit signed, 16bank = 4bit , 512depth = 9bit , 14bit
    
    wire [$clog2(L1B_RAM_DEPTH)-1: 0]  hlsu_data_sub_len_sub1 = ( hlsu_data_sub_len_r == 0 )?  (L1B_RAM_DEPTH -1 ): hlsu_data_sub_len_r-1   ;  //  addr :    config  min is 1, load data to l1b

   
    wire [L1B_RAM_ADDR_WID-1     : 0]  hlsu_data_sys_len_sub1 = hlsu_data_sys_len_r == 0 ?  (L1B_RAM_DEPTH -1 ): hlsu_data_sys_len_r - 1       ;  //  addr :  8+5

//-------------------------------------------------------------------------------------------------//
//-------------------------------------------------------------------------------------------------//
//-----------------------------------       config      -------------------------------------------//
//-------------------------------------------------------------------------------------------------//
//-------------------------------------------------------------------------------------------------//


    reg l1b_norm_paral_mode;

     //cfg regs 1
   always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            hlsu_data_sys_gap_ext_r <= 'b0  ;
            hlsu_data_sub_gap_r     <= 'b1  ; 
            l1b_norm_paral_mode     <= 'b0  ;
        end
        else if( hlsu_cfg_vld  && (hlsu_cfg_type == 2'b10)) begin
            hlsu_data_sys_gap_ext_r <= hlsu_data_sys_gap_ext  ;
            hlsu_data_sub_gap_r     <= hlsu_data_sub_gap  == 0 ?  L1B_RAM_DEPTH :    hlsu_data_sub_gap  ;
            l1b_norm_paral_mode     <= hlsu_l1b_norm_paral_mode  ;
        end
   end

 //--------------------------------------------------------------------------------------//


      always@(posedge clk or negedge rst_n) begin
        if(!rst_n)
            hlsu_cs <= SLSU_IDLE;
        else
            hlsu_cs <= hlsu_ns ;
    end
    
    //------------------------------------------------------------------------------//
    //---------------------------very important-------------------------------------//
    //------------------------------------------------------------------------------//
    //work mode is decided by hlsu_l1b_mode,hlsu_tcache_mode,hlsu_data_we
    //l1b mode, tcache mode, wr/rd mode


    assign bcfmap_req_disable = hlsu_data_req && hlsu_ns == MOVE_FMAP_NORM ;

    assign load_data_to_l2_ready = (hlsu_cs == LOAD_WEIGHT) || (hlsu_cs == LOAD_FMAP_NORM) ? hlsu_l1b_addr_ready : 1'b1;

    always_comb begin
    case(hlsu_cs)
        //--------------------------------------------------------------------------//
        SLSU_IDLE       :  if(hlsu_data_req ) begin //hlsu_tcache_mode[2] 1: use tcache 0: not use
                            casez({hlsu_l1b_mode, tcache_mode[2], hlsu_data_we})
                            'b000:   hlsu_ns = MOVE_FMAP_NORM   ;   //cache, read  l1b cache
                            'b001:   hlsu_ns = LOAD_FMAP_NORM   ;   //cache, Write l1b cache
                            'b011:   hlsu_ns = LOAD_TRANS_MATRIX;   //cache, Write l1b cache
                            'b1?0:   hlsu_ns = MOVE_WEIGHT      ;   //norm,  read Weight+DWCONV parallel, not use tcache
                            'b101:   hlsu_ns = LOAD_WEIGHT      ;   //norm,  load Weight, not use tcache
                            'b111:   hlsu_ns = LOAD_TRANS_DWCONV;   //norm,  load DWCONV, use tcache
                            default: hlsu_ns = SLSU_IDLE        ;
                            endcase
        end
        else    hlsu_ns = SLSU_IDLE;
        //--------------------------------------------------------------------------//
        MOVE_FMAP_NORM   ,   
        LOAD_FMAP_NORM   ,
        LOAD_TRANS_MATRIX, 
        LOAD_TRANS_DWCONV,
        MOVE_WEIGHT      ,     
        LOAD_WEIGHT      :    begin
                if(hlsu_data_done)  begin
                    if(hlsu_data_req ) begin //hlsu_tcache_mode[2] 1: use tcache 0: not use
                            casez({hlsu_l1b_mode,tcache_mode[2],hlsu_data_we})
                            'b000:   hlsu_ns = MOVE_FMAP_NORM   ;   //cache, read  l1b cache
                            'b001:   hlsu_ns = LOAD_FMAP_NORM   ;   //cache, Write l1b cache
                            'b011:   hlsu_ns = LOAD_TRANS_MATRIX;   //cache, Write l1b cache
                            'b1?0:   hlsu_ns = MOVE_WEIGHT      ;   //norm,  read Weight+DWCONV parallel,  not use tcache
                            'b101:   hlsu_ns = LOAD_WEIGHT      ;   //norm,  load Weight, not use tcache
                            'b111:   hlsu_ns = LOAD_TRANS_DWCONV;   //norm,  load DWCONV, use tcache
                            default: hlsu_ns = SLSU_IDLE        ;
                            endcase
                    end
                    else    hlsu_ns = SLSU_IDLE;
                end
                else hlsu_ns = hlsu_cs ;
             end
        default:   hlsu_ns = SLSU_IDLE;          
    endcase
    end
    
    //----------------------------------------------------------------------------------------------//
    assign l1b_op_norm_parallel_mode  =  (l1b_norm_paral_mode == 1);

    
    reg  [$clog2(L1B_RAM_DEPTH)-1: 0]    addr_sub_len_cnt           ;
    reg [L1B_RAM_ADDR_WID-1 : 0]         addr_sys_len_cnt           ;  

    always@(posedge clk or negedge rst_n) begin
        if(!rst_n)  begin
            hlsu_l1b_addr_signed   <= 'b0  ;  
            addr_sub_len_cnt           <= 'b0  ;
            addr_sys_len_cnt           <= 'b0  ;
          //  hlsu_data_done           <= 'b0;
            end
        else if(hlsu_data_req ) begin
            hlsu_l1b_addr_signed   <=  hlsu_data_addr  ;                 
            addr_sub_len_cnt           <= 'b0  ;
            addr_sys_len_cnt           <= 'b0  ;
          //  hlsu_data_done           <= 'b0;
        end
        else if(hlsu_cs == SLSU_IDLE) begin
            hlsu_l1b_addr_signed   <=  hlsu_data_addr_r  ;                 
            addr_sub_len_cnt           <= 'b0  ;
            addr_sys_len_cnt           <= 'b0  ;
          //  hlsu_data_done           <= 'b0;
        end
        else if(hlsu_cs != SLSU_IDLE) begin
            case(hlsu_cs)
            MOVE_FMAP_NORM : if(tcache_core_move_fmap_en) begin          //read L1b, dirtect to generate address
                     if(addr_sub_len_cnt == hlsu_data_sub_len_sub1 ) begin
                            addr_sub_len_cnt        <= 0;

                         if(addr_sys_len_cnt ==  hlsu_data_sys_len_sub1 ) begin
                            hlsu_l1b_addr_signed    <= hlsu_data_addr_r; //initial  start addr for next loop
                            addr_sys_len_cnt        <= 0;
                            end
                         else begin
                            addr_sys_len_cnt        <=  addr_sys_len_cnt  +  1  ;
                            hlsu_l1b_addr_signed    <=  hlsu_l1b_addr_signed + hlsu_data_sys_gap_signed + (!l1b_op_fmap_fifo_mode && hlsu_data_sys_gap_signed[0] ? 1 : 0)  ;  
                         end
                     end
                     else begin
                         addr_sub_len_cnt        <= addr_sub_len_cnt     +   1  ;
                         hlsu_l1b_addr_signed    <= hlsu_l1b_addr_signed + hlsu_data_sub_gap_r + ( !l1b_op_fmap_fifo_mode && hlsu_data_sub_gap_r[0] ? 1 : 0) ;
                         addr_sys_len_cnt        <= addr_sys_len_cnt     ;
                     end

            end
            MOVE_WEIGHT    : begin          //read L1b, dirtect to generate address
                     if(addr_sub_len_cnt == hlsu_data_sub_len_sub1 ) begin
                         addr_sub_len_cnt        <=  0    ;

                         if(addr_sys_len_cnt ==  hlsu_data_sys_len_sub1 ) begin
                            hlsu_l1b_addr_signed<= hlsu_data_addr_r;
                            addr_sys_len_cnt        <= 0;
                            end
                         else begin
                            addr_sys_len_cnt        <=  addr_sys_len_cnt  + 1 ;
                            hlsu_l1b_addr_signed<=  hlsu_l1b_addr_signed + hlsu_data_sys_gap_signed  ;  
                            end
                     end 
                     else begin
                         addr_sub_len_cnt        <= addr_sub_len_cnt  +  1;
                         hlsu_l1b_addr_signed<= hlsu_l1b_addr_signed + hlsu_data_sub_gap_r ;  
                         addr_sys_len_cnt        <= addr_sys_len_cnt     ;
                     end

            end
            LOAD_FMAP_NORM ,
            LOAD_TRANS_MATRIX ,
            LOAD_TRANS_DWCONV ,
            LOAD_WEIGHT    :   if(hlsu_l1b_addr_ready) begin
                if(load_data_to_l1b_vld) begin
                     if(addr_sub_len_cnt == hlsu_data_sub_len_sub1 ) begin
                         addr_sub_len_cnt        <=  0    ;

                         if(addr_sys_len_cnt ==  hlsu_data_sys_len_sub1 ) begin
                            hlsu_l1b_addr_signed    <= hlsu_data_addr_r;
                            addr_sys_len_cnt        <= 0;
                            end
                         else begin
                            addr_sys_len_cnt        <=  addr_sys_len_cnt  + 1 ;
                            hlsu_l1b_addr_signed    <=  hlsu_l1b_addr_signed + hlsu_data_sys_gap_signed  ;  
                            end
                     end 
                     else begin
                         addr_sub_len_cnt           <= addr_sub_len_cnt  + 1 ;
                         hlsu_l1b_addr_signed       <= hlsu_l1b_addr_signed + hlsu_data_sub_gap_r;  
                         addr_sys_len_cnt           <= addr_sys_len_cnt     ;
                     end
                end

            end
            default:   hlsu_l1b_addr_signed    <= hlsu_data_addr_r; 
            endcase
        end
      else if(hlsu_cs == SLSU_IDLE) begin
              hlsu_l1b_addr_signed          <= hlsu_data_addr_r ;                 
              addr_sub_len_cnt           <= 'b0  ;
              addr_sys_len_cnt           <= 'b0  ;
      end
    end


    always_comb begin
        if(hlsu_cs != SLSU_IDLE) begin
            case(hlsu_cs)
            MOVE_FMAP_NORM : if(tcache_core_move_fmap_en) begin          //read L1b, dirtect to generate address
                     hlsu_l1b_addr_valid    = 'b1 ;
                     hlsu_l1b_wr_en         = 'b0  ;  

               if((addr_sub_len_cnt == hlsu_data_sub_len_sub1)&&(addr_sys_len_cnt == hlsu_data_sys_len_sub1 ))
                     hlsu_data_done           = 'b1;
                else
                     hlsu_data_done           = 'b0;
            end
            else begin
                     hlsu_l1b_wr_en         = 'b0  ;  
                     hlsu_l1b_addr_valid    = 'b0 ;
                     hlsu_data_done           = 'b0;
            end

            MOVE_WEIGHT    : begin          //read L1b, dirtect to generate address
                     hlsu_l1b_addr_valid    = 'b1 ;
                     hlsu_l1b_wr_en         = 'b0  ;  
               if((addr_sub_len_cnt == hlsu_data_sub_len_sub1)&&(addr_sys_len_cnt == hlsu_data_sys_len_sub1 ))
                     hlsu_data_done           = 'b1;
                else
                     hlsu_data_done           = 'b0;
            end
            LOAD_FMAP_NORM ,
            LOAD_TRANS_MATRIX ,
            LOAD_TRANS_DWCONV , 
            LOAD_WEIGHT    :   begin
                if(load_data_to_l1b_vld) begin
                     hlsu_l1b_addr_valid    = 'b1 ;
                     hlsu_l1b_wr_en         = 'b1  ;  
                end
                else begin
                     hlsu_l1b_addr_valid    = 'b0 ;
                     hlsu_l1b_wr_en         = 'b1  ;  
                end

               if((addr_sub_len_cnt == hlsu_data_sub_len_sub1)&&(addr_sys_len_cnt ==  hlsu_data_sys_len_sub1 )&&load_data_to_l1b_vld)
                     hlsu_data_done           = 'b1;
                else
                     hlsu_data_done           = 'b0;
            end
            default: begin
                     hlsu_l1b_addr_valid    = 'b0 ;
                     hlsu_l1b_wr_en         = 'b0  ;  
                     hlsu_data_done           = 'b0;
            end
            endcase
        end
      else begin
              hlsu_l1b_addr_valid     = 'b0  ;
              hlsu_l1b_wr_en          = 'b0  ;  
              hlsu_data_done          = 'b0  ;

      end
    end


endmodule
