module conv3d_broadcast_fmap #(    
    parameter WORD_WID        = 8                           ,
    parameter CH_X            = 32                          ,
    parameter DATA_32CH_WID   = WORD_WID * CH_X             ,
    parameter DATA_16CH_WID   = WORD_WID * CH_X / 2  
            )(
   input  logic                                     clk                                        ,
   input  logic                                     rst_n                                      ,
   //------------------------------------------------------------------------------------------//
   input                                            conv3d_bcfmap_req                          ,  // bcfmap : broadcast fmap
   output                                           conv3d_bcfmap_gnt                          ,
   output reg                                       conv3d_bcfmap_ok                           ,
   input                                            conv3d_bcfmap_elt_mode                     , // 1:eltwise 0:conv3d
   input                                            conv3d_bcfmap_elt_pric                     , // 1: int16 0:int8
   input                                            conv3d_bcfmap_elt_32ch_i16                 , // 1: int16 0:int8
   input                                            conv3d_bcfmap_elt_bsel                     , // 1: left 0:right
   input                                            conv3d_bcfmap_group                        , // 1: 4xgroup 0:disable
   input                                            conv3d_bcfmap_tcache_stride                ,
   input [4:0]                                      conv3d_bcfmap_tcache_offset                ,
   input                                            conv3d_bcfmap_mode                         ,  // cubank broadcast fmap  1: double bank diff fmap broadcast 32ch 0: single bank same fmap broadcast 16ch
   input [5:0]                                      conv3d_bcfmap_len                          ,  // 32ch data len <= 8
   input                                            conv3d_bcfmap_rgba_mode                    ,  // even start 16ch mask
   input                                            conv3d_bcfmap_rgba_stride                  ,  // odd  last 16ch mask
   input                                            conv3d_bcfmap_keep_2cycle_en               ,
   input                                            conv3d_bcfmap_hl_op                        ,  // 1: high 16ch 0: low 16ch
   input                                            conv3d_bcfmap_pad0_he_sel                  ,  //              
   input [3:0]                                      conv3d_bcfmap_pad0_len                     ,  // 1: head 0:end
   input signed [4:0]                               conv3d_bcfmap_rgba_shift                   ,  
   input                                            conv3d_bcfmap_state_clr                    ,
   //----------------------------- to tcache_core ---------------------------------------------//
   input       [2:0]                                tcache_mode                                ,
   input                                            bcfmap_dfifo_addr_odd                      ,
   input                                            bcfmap_req_disable                         ,
   input                                            bcfmap_req_enable                          ,
   input                                            tcache_core2bcfmap_dataout_vld             , //cub: cubank
   input       [DATA_32CH_WID-1:0]                  tcache_core2bcfmap_dataout_ch0             ,
   input       [DATA_32CH_WID-1:0]                  tcache_core2bcfmap_dataout_ch1             ,
   output  reg                                      tcache_core2bcfmap_dataout_bank0_rqt       ,
   output  reg                                      tcache_core2bcfmap_dataout_bank1_rqt       ,
   output  reg                                      tcache_core2bcfmap_dataout_bank0_rqt_last  ,
   output  reg                                      tcache_core2bcfmap_dataout_bank1_rqt_last  ,
   input                                            tcache_ram_dataout_bank0_not_empty         ,
   input                                            tcache_ram_dataout_bank1_not_empty         ,
  //
   output  reg  [3:0]                               tcache_conv3d_bcfmap_valid                 ,
   output  reg  [3:0]                               tcache_conv3d_bcfmap_vector_data_mask      ,
   output  reg [DATA_16CH_WID-1:0]                  tcache_conv3d_bcfmap_dataout_bank0    [1:0],                            
   output  reg [DATA_16CH_WID-1:0]                  tcache_conv3d_bcfmap_dataout_bank1    [1:0]     
  );

 //--------------------------------------------------------------------------------------//
 //---------------------------------slsu_tcache_mode-------------------------------------//
 //--------------------------------------------------------------------------------------//
   localparam CONV16CH_DFIFO_MODE  = 'b000   ;       //wr/rd    l1b cache    tcache_FIFO
   localparam CONV16CH_SFIFO_MODE  = 'b001   ;       //wr/rd    l1b cache    tcache_FIFO
   localparam CONV32CH_DFIFO_MODE  = 'b010   ;       //wr/rd    l1b cache    tcache_FIFO
   localparam CONV32CH_SFIFO_MODE  = 'b011   ;       //wr/rd    l1b cache    tcache_FIFO
   localparam TRANS_MATRIX_MODE    = 'b100   ;       //wr       l1b cache    tcache_TRANS in l1b_cache
   localparam TRANS_DWCONV_MODE    = 'b111   ;       //wr       l1b norm     tcache_TRANS in l1b_weight

   //wire   [5:0]   conv3d_bcfmap_len  =   conv3d_bcfmap_len    ;  // 32ch data len <= 8

   wire   last_flag_gen ;

  // wire   tcache_ram_dataout_bank_not_empty     = conv3d_bcfmap_rgba_mode_r ? 1'b1 : ((tcache_ram_dataout_bank0_not_empty && !conv3d_bcfmap_hl_op_r) || ( tcache_ram_dataout_bank1_not_empty&&conv3d_bcfmap_hl_op_r ) )  ; //after req 
  // wire   tcache_ram_dataout_bank_not_empty_req = conv3d_bcfmap_rgba_mode   ? 1'b1 : ((tcache_ram_dataout_bank0_not_empty && !conv3d_bcfmap_hl_op) || ( tcache_ram_dataout_bank1_not_empty&&conv3d_bcfmap_hl_op ) ) ; //when reqing 

  //  reg  req_empty_wait;

  //  always@(posedge clk or negedge rst_n) begin
  //      if(!rst_n)      
  //           req_empty_wait  <= 'b0 ;
  //      else if(conv3d_bcfmap_req && !tcache_ram_dataout_bank_not_empty_req)
  //           req_empty_wait  <= 'b1 ;
  //      else if(req_empty_wait && tcache_ram_dataout_bank_not_empty)
  //           req_empty_wait  <= 'b0 ;
  //      else if(conv3d_bcfmap_req && tcache_ram_dataout_bank_not_empty_req )
  //           req_empty_wait  <= 'b0 ;
  //  end



    reg          start_flag_in  , last_flag_in ,   hl_op_in  ;  //start flag_in in 16ch mode  
    reg          start_flag_out , last_flag_out,   hl_op_out ;  //start flag_in in 16ch mode  


    reg  req_valid ;

    reg [5:0]    conv3d_bcfmap_len_r  ;

    reg  conv3d_bcfmap_mode_r         ;
    reg  conv3d_bcfmap_rgba_mode_r    ;
    reg  conv3d_bcfmap_rgba_stride_r  ;
    reg  conv3d_bcfmap_hl_op_r        ;
    reg  conv3d_bcfmap_len_odd        ;
    reg  signed [5:0]    conv3d_bcfmap_rgba_shift_r   ;
    reg      keep_2cycle_en_r               ;
    reg         bcfmap_len_nq_one           ;      
    reg [5:0]   conv3d_bcfmap_pad0_len_r    ;
    reg         conv3d_bcfmap_pad0_he_sel_r ;
    reg     conv3d_bcfmap_elt_pric_r        ;
    reg     conv3d_bcfmap_elt_mode_r        ;
    reg     conv3d_bcfmap_elt_bsel_r        ;
    reg     conv3d_bcfmap_elt_32ch_i16_r    ;
    reg     conv3d_bcfmap_tcache_stride_r   ;
    reg     conv3d_bcfmap_tcache_offset_r   ;
    reg     conv3d_bcfmap_group_r           ;

    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            conv3d_bcfmap_rgba_mode_r   <= 'b0 ;
            conv3d_bcfmap_rgba_stride_r <= 'b0 ;
            conv3d_bcfmap_hl_op_r       <= 'b0 ;
            conv3d_bcfmap_mode_r        <= 'b0 ;
            conv3d_bcfmap_len_odd       <= 'b0 ;
            keep_2cycle_en_r            <= 'b0 ;
            conv3d_bcfmap_rgba_shift_r  <= 'b0 ;
            bcfmap_len_nq_one           <= 'b0 ;
            conv3d_bcfmap_pad0_he_sel_r <= 'b0 ;
            conv3d_bcfmap_elt_mode_r    <= 'b0 ;
            conv3d_bcfmap_elt_pric_r    <= 'b0 ;
            conv3d_bcfmap_elt_bsel_r    <= 'b0 ;
            conv3d_bcfmap_group_r       <= 'b0 ;
            conv3d_bcfmap_elt_32ch_i16_r<= 'b0 ;
            conv3d_bcfmap_tcache_stride_r <= 'b0;
        end
        else if(conv3d_bcfmap_req) begin
            conv3d_bcfmap_rgba_mode_r   <=  conv3d_bcfmap_rgba_mode       ;
            conv3d_bcfmap_rgba_stride_r <=  conv3d_bcfmap_rgba_stride     ;
            conv3d_bcfmap_hl_op_r       <=  conv3d_bcfmap_hl_op           ;
            conv3d_bcfmap_mode_r        <=  ( tcache_mode == CONV32CH_SFIFO_MODE ) || (tcache_mode == CONV32CH_DFIFO_MODE);  //conv3d_bcfmap_mode            ;
            conv3d_bcfmap_elt_mode_r    <=  conv3d_bcfmap_elt_mode        ;
            conv3d_bcfmap_elt_pric_r    <=  conv3d_bcfmap_elt_pric        ;
            conv3d_bcfmap_elt_bsel_r    <=  conv3d_bcfmap_elt_bsel        ;
            conv3d_bcfmap_elt_32ch_i16_r<=  conv3d_bcfmap_elt_32ch_i16    ;
            conv3d_bcfmap_len_odd       <=  conv3d_bcfmap_len[0]          ;
            keep_2cycle_en_r            <=  conv3d_bcfmap_keep_2cycle_en  ;
            conv3d_bcfmap_rgba_shift_r  <= $signed(conv3d_bcfmap_rgba_shift) + 2  ;
            bcfmap_len_nq_one           <=   ( conv3d_bcfmap_len != 1)    ;
            conv3d_bcfmap_pad0_he_sel_r <=  conv3d_bcfmap_pad0_he_sel     ;
            conv3d_bcfmap_tcache_stride_r <= conv3d_bcfmap_tcache_stride && !conv3d_bcfmap_rgba_mode  ;
            conv3d_bcfmap_group_r       <= conv3d_bcfmap_group  ;
        end 
    end
    
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) 
            conv3d_bcfmap_tcache_offset_r <= 'b0;
        else if(conv3d_bcfmap_req) 
            conv3d_bcfmap_tcache_offset_r <= conv3d_bcfmap_tcache_offset[0]  ;
        else if(conv3d_bcfmap_len_r == 1'b1 )
            conv3d_bcfmap_tcache_offset_r <= 'b0;
    end
    //detect mvfmap valid 
    wire mvfmap_valid_arrive   ;
    reg bcfmap_run_enable_r    ;
    reg bcfmap_req_st          ;

    always@(posedge clk or negedge rst_n) begin
        if(!rst_n)    
            bcfmap_run_enable_r <= 'b0;
        else if(bcfmap_req_disable || conv3d_bcfmap_state_clr )
             bcfmap_run_enable_r <= 'b0;
        else if(bcfmap_req_enable)
             bcfmap_run_enable_r <= 'b1;
    end

    always@(posedge clk or negedge rst_n) begin
        if(!rst_n)    
            bcfmap_req_st <= 'b0;
        else if(conv3d_bcfmap_req && !(bcfmap_run_enable_r || bcfmap_req_enable))
            bcfmap_req_st <= 'b1;
        else if(mvfmap_valid_arrive)
            bcfmap_req_st <= 'b0;
    end

   assign mvfmap_valid_arrive   = ( bcfmap_run_enable_r ^ bcfmap_req_enable ) && (bcfmap_run_enable_r == 'b0) && bcfmap_req_st;//mvfmap_valid_arrive==>>conv3d_bcfmap_req

   wire conv3d_bcfmap_valid_req =  mvfmap_valid_arrive || ( conv3d_bcfmap_req && (bcfmap_run_enable_r || bcfmap_req_enable)) ;


    reg  end_pad0_run  ;
    reg  start_pad0_run ;

    always@(posedge clk or negedge rst_n) begin
        if(!rst_n)      
            conv3d_bcfmap_pad0_len_r <= 'b0;
        else if(conv3d_bcfmap_req )
            conv3d_bcfmap_pad0_len_r <=   conv3d_bcfmap_keep_2cycle_en ? conv3d_bcfmap_pad0_len<<1 : conv3d_bcfmap_pad0_len ;
        else if(((conv3d_bcfmap_pad0_len_r != 0 && conv3d_bcfmap_pad0_he_sel_r == 1)||( end_pad0_run && conv3d_bcfmap_pad0_he_sel_r == 0) )&&bcfmap_run_enable_r) //head or end
            conv3d_bcfmap_pad0_len_r <= conv3d_bcfmap_pad0_len_r - 1;
    end

    wire  conv3d_bcfmap_nonzero_req_start =  ( conv3d_bcfmap_req && ( conv3d_bcfmap_pad0_len == 0 || conv3d_bcfmap_pad0_he_sel == 0 ))||(mvfmap_valid_arrive && ( conv3d_bcfmap_pad0_len_r == 0 || conv3d_bcfmap_pad0_he_sel_r == 0)) ?  
                                      conv3d_bcfmap_valid_req:(conv3d_bcfmap_pad0_len_r == 1 && conv3d_bcfmap_pad0_he_sel_r == 1)&&bcfmap_run_enable_r;

    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) 
            end_pad0_run <= 1'b0;
        else if(last_flag_gen && conv3d_bcfmap_pad0_he_sel_r == 0 && conv3d_bcfmap_pad0_len_r != 0 )
            end_pad0_run <= 1'b1;
        else if((conv3d_bcfmap_pad0_len_r == 1) && end_pad0_run)
            end_pad0_run <= 1'b0;
    end

    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) 
            start_pad0_run <= 1'b0;
        else if(conv3d_bcfmap_req && ( conv3d_bcfmap_pad0_len != 0 && conv3d_bcfmap_pad0_he_sel == 1  )&&(bcfmap_run_enable_r || bcfmap_req_enable))
            start_pad0_run <= 1'b1;
        else if(mvfmap_valid_arrive && ( conv3d_bcfmap_pad0_len_r != 0 && conv3d_bcfmap_pad0_he_sel_r == 1  ))
            start_pad0_run <= 1'b1;
        else if((conv3d_bcfmap_pad0_len_r == 1)&&start_pad0_run)
            start_pad0_run <= 1'b0;
    end


    always_comb begin
        conv3d_bcfmap_ok = (conv3d_bcfmap_pad0_len_r != 0)&&(conv3d_bcfmap_pad0_he_sel_r==0) ? conv3d_bcfmap_pad0_len_r == 1  && end_pad0_run : last_flag_gen ;
    end


    
   //reg bcfmap_valid ;
   //always@(posedge clk or negedge rst_n) begin
   //     if(!rst_n) 
   //         bcfmap_valid <= 1'b0;
   //     else if(conv3d_bcfmap_nonzero_req_start)
   //         bcfmap_valid <= 1'b1;
   //     else if(last_flag_gen)
   //         bcfmap_valid <= 1'b0;
   // end



    reg bcfmap_run ;

   always@(posedge clk or negedge rst_n) begin
        if(!rst_n) 
            bcfmap_run <= 1'b0;
        else if(conv3d_bcfmap_nonzero_req_start)
            bcfmap_run <= 1'b1;
        else if(last_flag_gen)
            bcfmap_run <= 1'b0;
    end

    assign  conv3d_bcfmap_gnt = conv3d_bcfmap_req;

  //----------------------------------  request -----------------------------------------//
    //reg     dataout_requesting 
    //conv3d_bcfmap_mode delay
    reg conv3d_bcfmap_tcache_offset_out;
    reg conv3d_bcfmap_tcache_stride_out;
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            conv3d_bcfmap_tcache_offset_out   <= 'b0 ;
            conv3d_bcfmap_tcache_stride_out   <= 'b0 ;
        end
        else begin
            conv3d_bcfmap_tcache_offset_out   <= conv3d_bcfmap_tcache_offset_r ;
            conv3d_bcfmap_tcache_stride_out   <= conv3d_bcfmap_tcache_stride_r ;

        end
    end

    reg conv3d_bcfmap_elt_mode_out;

    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            conv3d_bcfmap_elt_mode_out   <= 'b0 ;
        end
        else begin
            conv3d_bcfmap_elt_mode_out   <= conv3d_bcfmap_elt_mode_r ;
        end
    end

    reg conv3d_bcfmap_elt_pric_out  ;
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            conv3d_bcfmap_elt_pric_out   <= 'b0 ;
        end
        else begin
            conv3d_bcfmap_elt_pric_out   <= conv3d_bcfmap_elt_pric_r ;
        end
    end

    reg conv3d_bcfmap_mode_out;
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            conv3d_bcfmap_mode_out   <= 'b0 ;
        end
        else begin
            conv3d_bcfmap_mode_out   <= conv3d_bcfmap_mode_r ;
        end
    end


    //high channel or low channel
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
          //  hl_op_in   <= 'b0 ;
            hl_op_out  <= 'b0 ;
        end
        else begin
            //hl_op_in   <= conv3d_bcfmap_hl_op_r ;
            hl_op_out  <= conv3d_bcfmap_hl_op_r;
        end
    end

    //gen start
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            start_flag_in <= 'b0;
        end
        else if(conv3d_bcfmap_state_clr) begin
            start_flag_in <= 'b0;
        end
        else if( conv3d_bcfmap_nonzero_req_start ) begin
            start_flag_in <= 'b1;
        end
        else if( start_flag_in  ) begin
            start_flag_in <= 'b0;
        end
    end

    reg  offset_flag ;

   always@(posedge clk or negedge rst_n) begin
        if(!rst_n)
            offset_flag <= 'b0;
        else if(conv3d_bcfmap_nonzero_req_start)
            offset_flag <= conv3d_bcfmap_tcache_offset_r || ( conv3d_bcfmap_tcache_offset[0] && conv3d_bcfmap_req) ;
        else if(offset_flag)   
            offset_flag <= 'b0 ;
    end
    
    reg [1:0]   keep_2cycle_st ;
        always@(posedge clk or negedge rst_n) begin
        if(!rst_n)
            keep_2cycle_st <= 'b0;
        else if(conv3d_bcfmap_nonzero_req_start  )
            keep_2cycle_st <= 'b0;
        else if(offset_flag)
            keep_2cycle_st <= 'b0;
        else if(bcfmap_run)
            //keep_2cycle_st <= keep_2cycle_st + (  keep_2cycle_en_r ? 1 : 2);
            keep_2cycle_st <= keep_2cycle_st +  2 ;
        else 
            keep_2cycle_st <= 'b0;
    end
    // len cnt
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n)
            conv3d_bcfmap_len_r    <= 'b0 ;
        else if( conv3d_bcfmap_nonzero_req_start ) 
            conv3d_bcfmap_len_r    <=  conv3d_bcfmap_len;//{ conv3d_bcfmap_len , 1'b0 };
        else if( conv3d_bcfmap_len_r != 0 && bcfmap_run )
            //conv3d_bcfmap_len_r    <= keep_2cycle_en_r ? ( keep_2cycle_st[0]   ? conv3d_bcfmap_len_r -1 : conv3d_bcfmap_len_r ) : conv3d_bcfmap_len_r - 1; //auto sub 1
            conv3d_bcfmap_len_r    <=  conv3d_bcfmap_len_r - 1; //auto sub 1
    end

   
    //wire   keep_2cycle_dis =  conv3d_bcfmap_tcache_stride_r||conv3d_bcfmap_group_r ||conv3d_bcfmap_rgba_mode_r || conv3d_bcfmap_mode_r || (conv3d_bcfmap_elt_mode_r && conv3d_bcfmap_mode_r) ;

    wire   dbank_rd_en = conv3d_bcfmap_tcache_stride_r||conv3d_bcfmap_group_r ||conv3d_bcfmap_rgba_mode_r || (conv3d_bcfmap_elt_mode_r && conv3d_bcfmap_elt_32ch_i16_r )   ;

    always@(posedge clk or negedge rst_n) begin
        if(!rst_n)
            req_valid    <= 'b0 ;
        else if(conv3d_bcfmap_state_clr) 
            req_valid    <= 'b0;
        else if(conv3d_bcfmap_nonzero_req_start  )
            req_valid    <=  1'b1 ;
        else if(offset_flag)
            req_valid    <=  1'b1 ;
        else if(conv3d_bcfmap_len_r != 1 && !dbank_rd_en && bcfmap_run)
          //req_valid    <= keep_2cycle_en_r ? (req_valid ? 1'b0 : ( keep_2cycle_st ==2'b11 ) ) :  ( keep_2cycle_st[1] == 1'b1 ) ;
            req_valid    <= ( keep_2cycle_st[1] == 1'b1 ) ;
        else if(conv3d_bcfmap_len_r != 1 &&  dbank_rd_en && bcfmap_run)
            req_valid    <= 'b1;
        else
            req_valid    <= 'b0;
    end

    //gen last 
    //assign last_flag_gen = keep_2cycle_en_r ?   (   conv3d_bcfmap_len_r  == 'd1  && keep_2cycle_st ==2'b01 ) || ( conv3d_bcfmap_len_r  == 'd1  && keep_2cycle_st ==2'b11 ) :conv3d_bcfmap_len_r  == 'd1 ;
    assign last_flag_gen = conv3d_bcfmap_len_r  == 'd1 ;
   // wire last_req ;
 
    always_comb begin
      tcache_core2bcfmap_dataout_bank0_rqt_last = dbank_rd_en || conv3d_bcfmap_mode_r ? ( conv3d_bcfmap_len_r  == 'd1 ) : (( conv3d_bcfmap_len_r  == 'd2 )||( conv3d_bcfmap_len_r  == 'd1 )) && tcache_core2bcfmap_dataout_bank0_rqt;
      tcache_core2bcfmap_dataout_bank1_rqt_last = dbank_rd_en || conv3d_bcfmap_mode_r ? ( conv3d_bcfmap_len_r  == 'd1 ) : (( conv3d_bcfmap_len_r  == 'd2 )||( conv3d_bcfmap_len_r  == 'd1 )) && tcache_core2bcfmap_dataout_bank1_rqt;
    end


   // reg [2:0] tcache_core2bcfmap_dataout_bank0_rqt_last_delay;
   // reg [2:0] tcache_core2bcfmap_dataout_bank1_rqt_last_delay;
   // always@(posedge clk or negedge rst_n) begin
   //     if(!rst_n) begin
   //         tcache_core2bcfmap_dataout_bank0_rqt_last_delay <= 'b0;
   //         tcache_core2bcfmap_dataout_bank1_rqt_last_delay <= 'b0;
   //     end
   //     else begin
   //         tcache_core2bcfmap_dataout_bank0_rqt_last_delay <= {tcache_core2bcfmap_dataout_bank0_rqt_last_delay[1:0],tcache_core2bcfmap_dataout_bank0_rqt_last_w};
   //         tcache_core2bcfmap_dataout_bank1_rqt_last_delay <= {tcache_core2bcfmap_dataout_bank1_rqt_last_delay[1:0],tcache_core2bcfmap_dataout_bank1_rqt_last_w};
   //     end
   // end

   // always_comb begin
   //     case()
   //     endcase
   // end


    reg conv3d_bcfmap_pad0_valid_out ;
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            conv3d_bcfmap_pad0_valid_out <= 'b0;
        end
        else if(conv3d_bcfmap_state_clr) begin
            conv3d_bcfmap_pad0_valid_out <= 'b0;
        end
        else 
            conv3d_bcfmap_pad0_valid_out <= end_pad0_run || start_pad0_run ;
    end



    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            last_flag_in <= 'b0;
        end
        else if(conv3d_bcfmap_state_clr) begin
            last_flag_in <= 'b0;
        end
        else if( last_flag_gen) begin
            last_flag_in <= 'b1;
        end
        else if( last_flag_in  ) begin
            last_flag_in <= 'b0;
        end
    end

    reg   req_bcfmap_hl_op_bank0, req_bcfmap_hl_op_bank1 ;


   // reg tcache_core2bcfmap_dataout_bank0_rqt_w ;
   // reg tcache_core2bcfmap_dataout_bank1_rqt_w ;

    always_comb begin
            req_bcfmap_hl_op_bank0 = dbank_rd_en || conv3d_bcfmap_elt_mode_r || conv3d_bcfmap_mode_r ? 'b1 :  ~conv3d_bcfmap_hl_op_r ;
            req_bcfmap_hl_op_bank1 = dbank_rd_en || conv3d_bcfmap_elt_mode_r || conv3d_bcfmap_mode_r ? 'b1 :   conv3d_bcfmap_hl_op_r ;
            tcache_core2bcfmap_dataout_bank0_rqt = req_bcfmap_hl_op_bank0 && req_valid   ;
            tcache_core2bcfmap_dataout_bank1_rqt = req_bcfmap_hl_op_bank1 && req_valid   ;
    end
    
  //  reg [2:0] tcache_core2bcfmap_dataout_bank0_rqt_delay;
  //  reg [2:0] tcache_core2bcfmap_dataout_bank1_rqt_delay;

  //   always@(posedge clk or negedge rst_n) begin
  //      if(!rst_n) begin
  //          tcache_core2bcfmap_dataout_bank0_rqt_delay <= 'b0;
  //          tcache_core2bcfmap_dataout_bank1_rqt_delay <= 'b0;
  //      end
  //      else begin
  //          tcache_core2bcfmap_dataout_bank0_rqt_delay <= {tcache_core2bcfmap_dataout_bank0_rqt_delay[1:0],tcache_core2bcfmap_dataout_bank0_rqt_w};
  //          tcache_core2bcfmap_dataout_bank1_rqt_delay <= {tcache_core2bcfmap_dataout_bank1_rqt_delay[1:0],tcache_core2bcfmap_dataout_bank1_rqt_w};
  //      end
  //  end

    

    
   
    //---------------------------------output data port -----------------------------------//
    //DFIFO_MODE has two mode : 16ch  or 32ch ,
    //16ch mode need to process 16ch segment select option,
    //32ch need to select which 32ch from two FIFOs, select low/high 32ch segment from double 32ch
    //hl_sel_cnt is used for this function to select high/low segment

   // wire          hl_sel_cnt  = conv3d_bcfmap_len_r[0]   ;  //----- high / low  16ch------ 

    reg [1:0] hl_sel_cnt;
    reg tcache_conv3d_bcfmap_rdata_valid ;

    wire tcache_conv3d_bcfmap_rdata_valid_ext = tcache_conv3d_bcfmap_rdata_valid || start_flag_out ;

    always@(posedge clk or negedge rst_n) begin
        if(!rst_n)
            hl_sel_cnt <= 'b0      ;
        else if(conv3d_bcfmap_state_clr)
            hl_sel_cnt <= 'b0      ;
        else if(last_flag_out)
            hl_sel_cnt <=  2'b00     ;
        else if(tcache_conv3d_bcfmap_rdata_valid_ext )
            hl_sel_cnt <=  hl_sel_cnt + (keep_2cycle_en_r ? 1 : 2);
        else
            hl_sel_cnt <=  2'b00     ;
    end
    
    wire  hl_sel = conv3d_bcfmap_tcache_stride_out ? conv3d_bcfmap_tcache_offset_out : ( conv3d_bcfmap_tcache_offset_out ? !hl_sel_cnt[1]  : hl_sel_cnt[1] ); 

     //delay to output
     reg len_eq_one_st ;
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            start_flag_out <= 'b0;
            last_flag_out <= 'b0;
            len_eq_one_st <= 'b0;
        end
        else begin
            start_flag_out <= start_flag_in         ;
            last_flag_out  <= last_flag_gen;
            len_eq_one_st <= start_flag_out&&last_flag_out;
        end
    end
    //valid
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n)
            tcache_conv3d_bcfmap_rdata_valid <= 'b0;
        else if(conv3d_bcfmap_state_clr)
            tcache_conv3d_bcfmap_rdata_valid <= 'b0;
        else  begin
                if(start_flag_out && !last_flag_out)
                    tcache_conv3d_bcfmap_rdata_valid <=  1'b1;
                else if(last_flag_out && !start_flag_out)
                    tcache_conv3d_bcfmap_rdata_valid <=  1'b0;
        end 
    end



    wire tcache_conv3d_bcfmap_valid_w_0 = (tcache_conv3d_bcfmap_rdata_valid_ext || conv3d_bcfmap_pad0_valid_out) && (conv3d_bcfmap_elt_pric_out && conv3d_bcfmap_elt_mode_out && !conv3d_bcfmap_elt_32ch_i16_r ? !conv3d_bcfmap_elt_bsel_r : 1'b1);
    wire tcache_conv3d_bcfmap_valid_w_1 = (tcache_conv3d_bcfmap_rdata_valid_ext || conv3d_bcfmap_pad0_valid_out) && (conv3d_bcfmap_elt_pric_out && conv3d_bcfmap_elt_mode_out && !conv3d_bcfmap_elt_32ch_i16_r ? !conv3d_bcfmap_elt_bsel_r : 1'b1);
    wire tcache_conv3d_bcfmap_valid_w_2 = (tcache_conv3d_bcfmap_rdata_valid_ext || conv3d_bcfmap_pad0_valid_out) && (conv3d_bcfmap_elt_pric_out && conv3d_bcfmap_elt_mode_out && !conv3d_bcfmap_elt_32ch_i16_r ?  conv3d_bcfmap_elt_bsel_r : 1'b1);
    wire tcache_conv3d_bcfmap_valid_w_3 = (tcache_conv3d_bcfmap_rdata_valid_ext || conv3d_bcfmap_pad0_valid_out) && (conv3d_bcfmap_elt_pric_out && conv3d_bcfmap_elt_mode_out && !conv3d_bcfmap_elt_32ch_i16_r ?  conv3d_bcfmap_elt_bsel_r : 1'b1);

    wire [3:0] tcache_conv3d_bcfmap_valid_w =  {tcache_conv3d_bcfmap_valid_w_3, tcache_conv3d_bcfmap_valid_w_2, tcache_conv3d_bcfmap_valid_w_1, tcache_conv3d_bcfmap_valid_w_0} ;


    always@(posedge clk or negedge rst_n) begin
        if(!rst_n)
           tcache_conv3d_bcfmap_valid <='b0;
        else
           tcache_conv3d_bcfmap_valid <= tcache_conv3d_bcfmap_valid_w; //{tcache_conv3d_bcfmap_valid_w_3, tcache_conv3d_bcfmap_valid_w_2, tcache_conv3d_bcfmap_valid_w_1, tcache_conv3d_bcfmap_valid_w_0} ;
    end

    always@(posedge clk or negedge rst_n) begin
        if(!rst_n)
           tcache_conv3d_bcfmap_vector_data_mask <='b0;
        else
           tcache_conv3d_bcfmap_vector_data_mask <= tcache_conv3d_bcfmap_valid_w & {4{conv3d_bcfmap_elt_mode_out}} ;
    end


    wire  [20-1:0][WORD_WID*4 - 1:0]  rgba_extend_2o_16p_2o     = {{WORD_WID*4*2{1'b0}},tcache_core2bcfmap_dataout_ch1,tcache_core2bcfmap_dataout_ch0,{WORD_WID*4*2{1'b0}}} ;
    wire  [DATA_16CH_WID - 1:0]       rgba_get_4pxied_s1        = rgba_extend_2o_16p_2o [conv3d_bcfmap_rgba_shift_r+:4] ;
    wire  [8-1:0][WORD_WID*4 - 1:0]   rgba_get_4pxied_s2_temp   = rgba_extend_2o_16p_2o [conv3d_bcfmap_rgba_shift_r+:8] ;
    //wire  [DATA_16CH_WID - 1:0]       rgba_get_4pxied_s2        = { rgba_get_4pxied_s2_temp[0],rgba_get_4pxied_s2_temp[2],rgba_get_4pxied_s2_temp[4],rgba_get_4pxied_s2_temp[6] };
    wire  [DATA_16CH_WID - 1:0]       rgba_get_4pxied_s2        = { rgba_get_4pxied_s2_temp[6],rgba_get_4pxied_s2_temp[4],rgba_get_4pxied_s2_temp[2],rgba_get_4pxied_s2_temp[0] };


    wire  [DATA_32CH_WID - 1:0] tcache_core2bcfmap_dataout_elt_ch0 = ( tcache_mode == CONV16CH_SFIFO_MODE ) || (tcache_mode == CONV16CH_DFIFO_MODE) ? { tcache_core2bcfmap_dataout_ch1[DATA_16CH_WID - 1:0],tcache_core2bcfmap_dataout_ch0[DATA_16CH_WID - 1:0] }  :  tcache_core2bcfmap_dataout_ch0;
    wire  [DATA_32CH_WID - 1:0] tcache_core2bcfmap_dataout_elt_ch1 = ( tcache_mode == CONV16CH_SFIFO_MODE ) || (tcache_mode == CONV16CH_DFIFO_MODE) ? { tcache_core2bcfmap_dataout_ch1[DATA_32CH_WID-1:DATA_16CH_WID],tcache_core2bcfmap_dataout_ch0[DATA_32CH_WID-1:DATA_16CH_WID] }  :  tcache_core2bcfmap_dataout_ch0;

    wire  [15:0][15:0] tcache_core2bcfmap_dataout_ch0_i16 = tcache_core2bcfmap_dataout_elt_ch0;
    wire  [15:0][15:0] tcache_core2bcfmap_dataout_ch1_i16 = tcache_core2bcfmap_dataout_elt_ch1;

    logic  [31:0][15:0] tcache_core2bcfmap_dataout_ch0_i8 ;
    logic  [31:0][15:0] tcache_core2bcfmap_dataout_ch1_i8 ;

    always_comb begin
        foreach(tcache_core2bcfmap_dataout_ch0_i8[n] )
                       tcache_core2bcfmap_dataout_ch0_i8[n] = { {8{tcache_core2bcfmap_dataout_elt_ch0[n*8+7]}},{tcache_core2bcfmap_dataout_elt_ch0[n*8+:8] }};
        foreach(tcache_core2bcfmap_dataout_ch1_i8[n] )
                       tcache_core2bcfmap_dataout_ch1_i8[n] = { {8{tcache_core2bcfmap_dataout_elt_ch1[n*8+7]}},{tcache_core2bcfmap_dataout_elt_ch1[n*8+:8] }};
    end
    //data ch select
    //32ch to 16ch 
        always@(posedge clk ) 
        if(tcache_conv3d_bcfmap_rdata_valid_ext || conv3d_bcfmap_pad0_valid_out) begin
            tcache_conv3d_bcfmap_dataout_bank0[0] <=  conv3d_bcfmap_pad0_valid_out ? 'b0 :
                                                    conv3d_bcfmap_rgba_mode_r    ? (conv3d_bcfmap_rgba_stride_r ? rgba_get_4pxied_s2 : rgba_get_4pxied_s1 ) :
                                                    conv3d_bcfmap_group_r        ? tcache_core2bcfmap_dataout_ch0[DATA_16CH_WID-1:0] :
                                                    conv3d_bcfmap_elt_mode_out   ? ( conv3d_bcfmap_elt_pric_out ? (conv3d_bcfmap_elt_32ch_i16_r? tcache_core2bcfmap_dataout_ch0_i16[7:0]  : hl_sel ? tcache_core2bcfmap_dataout_ch1_i16[7:0]:tcache_core2bcfmap_dataout_ch0_i16[7:0]) :
                                                                                     hl_sel ? tcache_core2bcfmap_dataout_ch1_i8[7:0] :  tcache_core2bcfmap_dataout_ch0_i8[7:0] ) :  
                                                    conv3d_bcfmap_mode_out       ? ( hl_sel ? tcache_core2bcfmap_dataout_ch1[DATA_16CH_WID-1:0] :  tcache_core2bcfmap_dataout_ch0[DATA_16CH_WID-1:0] ) :  //low 16ch  of 32ch 
                                                                                   ( hl_op_out ? (hl_sel ? tcache_core2bcfmap_dataout_ch1[DATA_32CH_WID-1:DATA_16CH_WID] : tcache_core2bcfmap_dataout_ch1[DATA_16CH_WID-1:0] ) :  
                                                                                           (hl_sel ? tcache_core2bcfmap_dataout_ch0[DATA_32CH_WID-1:DATA_16CH_WID] : tcache_core2bcfmap_dataout_ch0[DATA_16CH_WID-1:0] ));                                    
            tcache_conv3d_bcfmap_dataout_bank0[1] <=  conv3d_bcfmap_pad0_valid_out ? 'b0 :
                                                    conv3d_bcfmap_rgba_mode_r    ? (conv3d_bcfmap_rgba_stride_r ? rgba_get_4pxied_s2 : rgba_get_4pxied_s1 ) :
                                                    conv3d_bcfmap_group_r        ? tcache_core2bcfmap_dataout_ch0[DATA_32CH_WID-1:DATA_16CH_WID]  :
                                                    conv3d_bcfmap_elt_mode_out   ? ( conv3d_bcfmap_elt_pric_out ? (conv3d_bcfmap_elt_32ch_i16_r? tcache_core2bcfmap_dataout_ch0_i16[15:8]  : hl_sel ? tcache_core2bcfmap_dataout_ch1_i16[15:8]:tcache_core2bcfmap_dataout_ch0_i16[15:8]) :
                                                                                     hl_sel ? tcache_core2bcfmap_dataout_ch1_i8[15:8] :  tcache_core2bcfmap_dataout_ch0_i8[15:8] ) :  
                                                    conv3d_bcfmap_mode_out       ? ( hl_sel ? tcache_core2bcfmap_dataout_ch1[DATA_16CH_WID-1:0] :  tcache_core2bcfmap_dataout_ch0[DATA_16CH_WID-1:0] ) :  //low 16ch  of 32ch 
                                                                                   ( hl_op_out ? (hl_sel ? tcache_core2bcfmap_dataout_ch1[DATA_32CH_WID-1:DATA_16CH_WID] : tcache_core2bcfmap_dataout_ch1[DATA_16CH_WID-1:0] ) :  
                                                                                           (hl_sel ? tcache_core2bcfmap_dataout_ch0[DATA_32CH_WID-1:DATA_16CH_WID] : tcache_core2bcfmap_dataout_ch0[DATA_16CH_WID-1:0] ));                                    
            tcache_conv3d_bcfmap_dataout_bank1[0] <=  conv3d_bcfmap_pad0_valid_out ? 'b0 :
                                                    conv3d_bcfmap_rgba_mode_r    ? (conv3d_bcfmap_rgba_stride_r ? rgba_get_4pxied_s2 : rgba_get_4pxied_s1 ) :
                                                    conv3d_bcfmap_group_r        ? tcache_core2bcfmap_dataout_ch1[DATA_16CH_WID-1:0] :
                                                    conv3d_bcfmap_elt_mode_out   ? ( conv3d_bcfmap_elt_pric_out ? (conv3d_bcfmap_elt_32ch_i16_r? tcache_core2bcfmap_dataout_ch1_i16[7:0]  : hl_sel ? tcache_core2bcfmap_dataout_ch1_i16[7:0]:tcache_core2bcfmap_dataout_ch0_i16[7:0]) :
                                                                                     hl_sel ? tcache_core2bcfmap_dataout_ch1_i8[23:16] :  tcache_core2bcfmap_dataout_ch0_i8[23:16] ) :  
                                                    conv3d_bcfmap_mode_out       ? ( hl_sel ? tcache_core2bcfmap_dataout_ch1[DATA_32CH_WID-1:DATA_16CH_WID] :  tcache_core2bcfmap_dataout_ch0[DATA_32CH_WID-1:DATA_16CH_WID]) :  
                                                                                   ( hl_op_out ? (hl_sel ? tcache_core2bcfmap_dataout_ch1[DATA_32CH_WID-1:DATA_16CH_WID] : tcache_core2bcfmap_dataout_ch1[DATA_16CH_WID-1:0] ) :  
                                                                                                 (hl_sel ? tcache_core2bcfmap_dataout_ch0[DATA_32CH_WID-1:DATA_16CH_WID] : tcache_core2bcfmap_dataout_ch0[DATA_16CH_WID-1:0] ));                              
            tcache_conv3d_bcfmap_dataout_bank1[1] <=  conv3d_bcfmap_pad0_valid_out ? 'b0 :
                                                    conv3d_bcfmap_rgba_mode_r    ? (conv3d_bcfmap_rgba_stride_r ? rgba_get_4pxied_s2 : rgba_get_4pxied_s1 ) :
                                                    conv3d_bcfmap_group_r        ? tcache_core2bcfmap_dataout_ch1[DATA_32CH_WID-1:DATA_16CH_WID]  :
                                                    conv3d_bcfmap_elt_mode_out   ? ( conv3d_bcfmap_elt_pric_out ? (conv3d_bcfmap_elt_32ch_i16_r? tcache_core2bcfmap_dataout_ch1_i16[15:8]  : hl_sel ? tcache_core2bcfmap_dataout_ch1_i16[15:8]:tcache_core2bcfmap_dataout_ch0_i16[15:8]) :
                                                                                     hl_sel ? tcache_core2bcfmap_dataout_ch1_i8[31:24] :  tcache_core2bcfmap_dataout_ch0_i8[31:24] ) :  
                                                    conv3d_bcfmap_mode_out       ? ( hl_sel ? tcache_core2bcfmap_dataout_ch1[DATA_32CH_WID-1:DATA_16CH_WID] :  tcache_core2bcfmap_dataout_ch0[DATA_32CH_WID-1:DATA_16CH_WID]) :  
                                                                                   ( hl_op_out ? (hl_sel ? tcache_core2bcfmap_dataout_ch1[DATA_32CH_WID-1:DATA_16CH_WID] : tcache_core2bcfmap_dataout_ch1[DATA_16CH_WID-1:0] ) :  
                                                                                                 (hl_sel ? tcache_core2bcfmap_dataout_ch0[DATA_32CH_WID-1:DATA_16CH_WID] : tcache_core2bcfmap_dataout_ch0[DATA_16CH_WID-1:0] ));                              
        end

        //delay one cycle to align with bcfmap_valid
 //   always@(posedge clk or negedge rst_n) begin
 //       if(!rst_n)
 //           conv3d_bcfmap_ok <=  'b0 ;
 //       else
 //          conv3d_bcfmap_ok <= last_flag_out;
 //   end
 //
endmodule
