module tcache_dfifo #(
    parameter WORD_WID        = 8                           ,
    parameter CH_X            = 32                          ,
    parameter DATA_32CH_WID   = WORD_WID * CH_X             ,
    parameter DATA_16CH_WID   = WORD_WID * CH_X /2          ,
    parameter NUM_WORDS       = 16                          ,
    parameter RAM_ADDR_WID   =  $clog2(NUM_WORDS)           ,
    parameter TRANS_RAM_BANK_DDR_WID = RAM_ADDR_WID    ,
    parameter NUM_WORDS_Y     = CH_X 
)(
   input  logic                                     clk                                  ,
   input  logic                                     rst_n                                ,
   //---------------------x direction---------------------//
   input    [2:0]                                   tcache_mode                          ,  
   input                                            tcache_ram_state_clr                 ,
   input                                            tcache_ram_datain_vld                ,
   input                                            tcache_ram_datain_last               ,
   input   logic [DATA_32CH_WID-1:0]                tcache_ram_datain_ch0                ,
   input   logic [DATA_32CH_WID-1:0]                tcache_ram_datain_ch1                ,
   input                                            conv3d_bcfmap_req                    ,
   input                                            conv3d_bcfmap_rgba_mode              , 
   input                                            conv3d_bcfmap_tcache_stride          ,
   input  [4:0]                                     conv3d_bcfmap_tcache_offset          ,
   input  [4:0]                                     tcache_mvfmap_offset                 ,
   input                                            tcache_ram_dataout_bank0_rqt         ,
   input                                            tcache_ram_dataout_bank1_rqt         ,
   input                                            tcache_ram_dataout_bank0_rqt_last    ,
   input                                            tcache_ram_dataout_bank1_rqt_last    ,
   output  logic                                    tcache_ram_dataout_bank0_not_empty   ,
   output  logic                                    tcache_ram_dataout_bank1_not_empty   ,
   output  logic                                    tcache_ram_dataout_vld               ,
   output  logic [DATA_32CH_WID-1:0]                tcache_ram_dataout_ch0               ,
   output  logic [DATA_32CH_WID-1:0]                tcache_ram_dataout_ch1               ,
   output                                           tcache_ram_move_fmap_en              ,
   //--------------------pingpang cfg-----------------------------------------//
   input                                            tcache_ram_load_bank_num             ,
   input                                            tcache_core_trans_prici              ,
  // input                                            tcache_core_trans_swbank             ,
   input  [1:0]                                     l1b_op_wr_hl_mask                    ,
   //---------------------trans cfg----------------------------------------//
   output reg                                       tcache_ram_trans_dataout_vld         ,
   output reg [DATA_32CH_WID-1:0]                   tcache_ram_trans_dataout             ,
   output reg [DATA_16CH_WID-1:0]                   tcache_ram_trans_dataout_lb_bank0    , 
   output reg [DATA_16CH_WID-1:0]                   tcache_ram_trans_dataout_lb_bank1    ,
   output reg                                       tcache_ram_trans_dataout_done        

);


    //--------------------------------------------------------------------------------------//
    //---------------------------------slsu_tcache_mode-------------------------------------//
    //--------------------------------------------------------------------------------------//
    localparam CONV16CH_DFIFO_MODE  = 'b000   ; //wr/rd    l1b cache    tcache_FIFO
    localparam CONV16CH_SFIFO_MODE  = 'b001   ; //wr/rd    l1b cache    tcache_FIFO
    localparam CONV32CH_DFIFO_MODE  = 'b010   ; //wr/rd    l1b cache    tcache_FIFO
    localparam CONV32CH_SFIFO_MODE  = 'b011   ; //wr/rd    l1b cache    tcache_FIFO
    localparam TRANS_MATRIX_MODE    = 'b100   ; //wr       l1b cache    tcache_TRANS in l1b_cache
    localparam TRANS_DWCONV_MODE    = 'b111   ; //wr       l1b norm     tcache_TRANS in l1b_weight
    
    //---------------------------------------------------------------------------//

   
    reg [CH_X-1:0][WORD_WID-1:0]              tcache_ram_trans_dataout_byte ;

    reg [RAM_ADDR_WID + 1:0]   tcache_ram_datain_cnt  ;  //6bit

    reg [RAM_ADDR_WID + 1: 0]   trans_dataout_y_cnt;   //32x2=6bit

  
  //---------manual switch loading bank------------------//
  reg tcache_ram_load_bank_num_tmp;
  wire tcache_ram_load_bank_switch = tcache_ram_load_bank_num_tmp^tcache_ram_load_bank_num;

  always@(posedge clk or negedge rst_n)begin
        if(!rst_n)
            tcache_ram_load_bank_num_tmp <= 'b0;
        else
            tcache_ram_load_bank_num_tmp <= tcache_ram_load_bank_num;
  end

  //FIFO mode loading data, fifo cnt and addr gen
    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)
            tcache_ram_datain_cnt <= 'b0;
        else if(tcache_ram_state_clr)
            tcache_ram_datain_cnt <= 'b0;
        else  begin//mode
        case(tcache_mode)
         CONV32CH_DFIFO_MODE,
         CONV16CH_SFIFO_MODE,  
         CONV32CH_SFIFO_MODE,  
         CONV16CH_DFIFO_MODE: begin
             if( tcache_ram_datain_last )  //5bit 'b11111 = 32
                    tcache_ram_datain_cnt <=   tcache_mvfmap_offset[4:1];
             else if(tcache_ram_datain_vld) 
                    tcache_ram_datain_cnt <=  tcache_ram_datain_cnt + 1;
          end
         TRANS_MATRIX_MODE,
         TRANS_DWCONV_MODE: begin  //pingpong load
                if(tcache_ram_load_bank_switch) 
                    tcache_ram_datain_cnt <=  tcache_ram_load_bank_num ? {2'b01,{(RAM_ADDR_WID){1'b0}} } : 0;   
                else if(tcache_ram_datain_last)
                    tcache_ram_datain_cnt <= 'b0;
                else if(tcache_ram_datain_vld)   
                    tcache_ram_datain_cnt <= tcache_ram_datain_cnt == {{(RAM_ADDR_WID+1){1'b1}}} ? 'b0 :   tcache_ram_datain_cnt + 1;  // auto switch bank
            end
            default: tcache_ram_datain_cnt   <= 'b0;
       endcase
       end
    end

       //-------------------------------------------------------------------------------------//

   wire tcache_ram_double_ch_in = ( tcache_mode == CONV32CH_DFIFO_MODE ) || (tcache_mode == CONV16CH_SFIFO_MODE ) || (tcache_mode == CONV16CH_DFIFO_MODE ) || ( tcache_mode == CONV32CH_SFIFO_MODE ) ;

   //addr contrl
   wire  [RAM_ADDR_WID:0]       tcache_ram_datain_addr ;//,  tcache_ram_dataout_addr ;

   assign   tcache_ram_datain_addr  =  tcache_ram_datain_cnt[RAM_ADDR_WID:0]; // low bit addr of fifo loop cnt as addr

   wire                         tcache_ram_datain_lthram_bank0_cs  =  tcache_ram_double_ch_in ? 1'b1 : ~tcache_ram_datain_addr[RAM_ADDR_WID] ;
   wire                         tcache_ram_datain_lthram_bank1_cs  =  tcache_ram_double_ch_in ? 1'b1 :  tcache_ram_datain_addr[RAM_ADDR_WID] ; 
   wire [RAM_ADDR_WID-1:0]      tcache_ram_datain_lthram_addr      =  tcache_ram_datain_addr[RAM_ADDR_WID-1:0]   ;

   //wen ctrl
  wire  tcache_ram_datain_lthram_bank0_wen =  tcache_ram_double_ch_in ? tcache_ram_datain_vld && (tcache_ram_datain_cnt<16) : tcache_ram_datain_vld ;
  wire  tcache_ram_datain_lthram_bank1_wen =  tcache_ram_double_ch_in ? tcache_ram_datain_vld && (tcache_ram_datain_cnt<16) : tcache_ram_datain_vld ;

  //data in ctrl
  wire  [DATA_32CH_WID-1:0]     trans_lthram_bank0_datain, trans_lthram_bank1_datain;

  assign                        trans_lthram_bank0_datain =  tcache_ram_datain_ch0;
  assign                        trans_lthram_bank1_datain =  tcache_ram_double_ch_in ?  tcache_ram_datain_ch1  : tcache_ram_datain_ch0;  //when double ch in, bank1 will keep connecting to tcache_ram_datain_ch1

    
  //-------------------------------------------------------------------------------------------------------------------------//
  //-------------------------------------------------------------------------------------------------------------------------//
  //-------------------------------------------------------------------------------------------------------------------------//
  //dataout
       
    reg [RAM_ADDR_WID + 1:0]      tcache_ram_dataout_bank1_cnt, tcache_ram_dataout_bank0_cnt ;  //6bit

  reg       tcache_ram_dataout_stride ;
  reg [1:0] tcache_ram_dataout_offset ;

  always@(posedge clk or negedge rst_n)begin
        if(!rst_n) begin
            tcache_ram_dataout_stride <= 'b0;
            tcache_ram_dataout_offset <= 'b0;
        end
        else if( conv3d_bcfmap_req) begin
            tcache_ram_dataout_stride <=  conv3d_bcfmap_rgba_mode&&conv3d_bcfmap_tcache_stride;
            tcache_ram_dataout_offset <=  conv3d_bcfmap_rgba_mode ? conv3d_bcfmap_tcache_offset : (conv3d_bcfmap_tcache_offset>>1);
        end
    end
    //tcache bank0  dataout
     always@(posedge clk or negedge rst_n)begin
        if(!rst_n)
            tcache_ram_dataout_bank0_cnt <= 'b0;
        else if(tcache_ram_state_clr)
            tcache_ram_dataout_bank0_cnt <= 'b0;
        else if( conv3d_bcfmap_req)
            tcache_ram_dataout_bank0_cnt <= conv3d_bcfmap_rgba_mode ? conv3d_bcfmap_tcache_offset : (conv3d_bcfmap_tcache_offset>>1);
        else begin
            case(tcache_mode)
            CONV32CH_DFIFO_MODE , 
            CONV32CH_SFIFO_MODE , 
            CONV16CH_SFIFO_MODE , 
            CONV16CH_DFIFO_MODE : 
                if(tcache_ram_dataout_bank0_rqt_last )      
                   tcache_ram_dataout_bank0_cnt <=  tcache_ram_dataout_offset;
                else  if(tcache_ram_dataout_bank0_rqt )
                   tcache_ram_dataout_bank0_cnt <=  tcache_ram_dataout_bank0_cnt + (tcache_ram_dataout_stride ?  2 : 1);
            TRANS_DWCONV_MODE   : 
                tcache_ram_dataout_bank0_cnt <= 'b0;
            TRANS_MATRIX_MODE   : 
                tcache_ram_dataout_bank0_cnt <= 'b0;
            default:
                tcache_ram_dataout_bank0_cnt <= 'b0;
            endcase
        end
    end

    //tcache bank1  dataout
     always@(posedge clk or negedge rst_n)begin
        if(!rst_n)
            tcache_ram_dataout_bank1_cnt <= 'b0;
        else if(tcache_ram_state_clr)
            tcache_ram_dataout_bank1_cnt <= 'b0;
        else if( conv3d_bcfmap_req)
            tcache_ram_dataout_bank1_cnt <=  conv3d_bcfmap_rgba_mode ? conv3d_bcfmap_tcache_offset : (conv3d_bcfmap_tcache_offset>>1);
        else begin
            case(tcache_mode)
            CONV32CH_SFIFO_MODE , 
            CONV16CH_SFIFO_MODE , 
            CONV32CH_DFIFO_MODE , 
            CONV16CH_DFIFO_MODE : 
                if(tcache_ram_dataout_bank1_rqt_last )      
                   tcache_ram_dataout_bank1_cnt <=  tcache_ram_dataout_offset;
                else  if(tcache_ram_dataout_bank1_rqt )
                   tcache_ram_dataout_bank1_cnt <=  tcache_ram_dataout_bank1_cnt + (tcache_ram_dataout_stride ?  2 : 1);
            TRANS_DWCONV_MODE   : 
                tcache_ram_dataout_bank1_cnt <= 'b0;
            TRANS_MATRIX_MODE   : 
                tcache_ram_dataout_bank1_cnt <= 'b0;
            default:
                tcache_ram_dataout_bank1_cnt <= 'b0;
            endcase
        end
    end
    

   //wire tcache_ram_double_ch_out = ( tcache_mode != CONV32CH_SFIFO_MODE );



   wire [RAM_ADDR_WID-1:0]   tcache_ram_dataout_lthram_bank0_addr  =  tcache_ram_dataout_bank0_cnt[RAM_ADDR_WID-1:0]   ;
   wire [RAM_ADDR_WID-1:0]   tcache_ram_dataout_lthram_bank1_addr  =  tcache_ram_dataout_bank1_cnt[RAM_ADDR_WID-1:0]   ;

   wire trans_lthram_bank0_ren  =   tcache_ram_dataout_bank0_rqt   ;
   wire trans_lthram_bank1_ren  =   tcache_ram_dataout_bank1_rqt   ;

   //--------------------------------------wr tcache enable control in case: reading in writing, writing flow up reading------------------------------------------//

   reg  tcache_ram_bank0_not_empty, tcache_ram_bank1_not_empty;

     always@(posedge clk or negedge rst_n)begin
        if(!rst_n) begin
           tcache_ram_bank0_not_empty  <= 'b0;
           tcache_ram_bank1_not_empty  <= 'b0;
        end
        else if(tcache_ram_state_clr) begin
           tcache_ram_bank0_not_empty  <= 'b0;
           tcache_ram_bank1_not_empty  <= 'b0;
        end
        else begin
            case(tcache_mode)
            CONV16CH_SFIFO_MODE,  
            CONV32CH_SFIFO_MODE,  
            CONV32CH_DFIFO_MODE ,
            CONV16CH_DFIFO_MODE : begin
                //bank0
                if(tcache_ram_dataout_bank0_rqt_last )      
                    tcache_ram_bank0_not_empty   <=  'b0;
                else if(tcache_ram_datain_last )
                    tcache_ram_bank0_not_empty   <=  'b1;
                //bank1
                if(tcache_ram_dataout_bank1_rqt_last )      
                    tcache_ram_bank1_not_empty   <=  'b0;
                else if(tcache_ram_datain_last )
                    tcache_ram_bank1_not_empty   <=  'b1;

            end
       //  CONV16CH_SFIFO_MODE,  
       //  CONV32CH_SFIFO_MODE,  
       //       CONV32CH_SFIFO_MODE,         
       //    TRANS_DWCONV_MODE,    
       //    TRANS_MATRIX_MODE,  
            default: begin
                    tcache_ram_bank0_not_empty  <= 'b0;
                    tcache_ram_bank1_not_empty  <= 'b0;
                end
            endcase
        end
    end

    assign tcache_ram_dataout_bank0_not_empty = tcache_ram_bank0_not_empty  ;
    assign tcache_ram_dataout_bank1_not_empty = tcache_ram_bank1_not_empty  ;
    
     //cnt  keep
    reg [RAM_ADDR_WID  : 0]    tcache_ram_bank1_datain_cnt_keep, tcache_ram_bank0_datain_cnt_keep;
     always@(posedge clk or negedge rst_n)begin
        if(!rst_n) begin
            tcache_ram_bank0_datain_cnt_keep <= 'b0;
            tcache_ram_bank1_datain_cnt_keep <= 'b0;
            end
        else if(tcache_ram_state_clr) begin
            tcache_ram_bank1_datain_cnt_keep <= 'b0;
            tcache_ram_bank0_datain_cnt_keep <= 'b0;
            end
        else  begin//mode
        case(tcache_mode)
        CONV16CH_SFIFO_MODE,  
        CONV32CH_SFIFO_MODE,  
        CONV32CH_DFIFO_MODE,
        CONV16CH_DFIFO_MODE: 
             if( tcache_ram_datain_last ) begin //5bit 'b11111 = 32
                    tcache_ram_bank1_datain_cnt_keep <=  tcache_ram_datain_cnt[RAM_ADDR_WID] ? 16 : tcache_ram_datain_cnt[RAM_ADDR_WID  : 0] ;
                    tcache_ram_bank0_datain_cnt_keep <=  tcache_ram_datain_cnt[RAM_ADDR_WID] ? 16 : tcache_ram_datain_cnt[RAM_ADDR_WID  : 0] ;
            end
     //    CONV16CH_SFIFO_MODE,  
     //    CONV32CH_DFIFO_MODE,  
     //         CONV32CH_SFIFO_MODE,         
     //      TRANS_DWCONV_MODE,    
     //      TRANS_MATRIX_MODE,  
         default: tcache_ram_bank1_datain_cnt_keep <= 'b0;
       endcase
       end
    end
      

    //only in CONV16CH_DFIFO_MODE, mvfmap speed is 4x as fast as broadcast, CONV32CH_DFIFO_MODE is 2x
    assign tcache_ram_move_fmap_en = (tcache_mode==CONV16CH_DFIFO_MODE || tcache_mode==CONV32CH_DFIFO_MODE ) && tcache_ram_bank1_not_empty ? tcache_ram_dataout_bank1_cnt >= (tcache_ram_bank1_datain_cnt_keep>>1)   :  1;               //when read cnt > tcache_ram_bank1_datain_cnt_keep/2 - 2 , it can start wr;

     //----------------------------------cs delay--------------------------------------------------//

    always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        tcache_ram_dataout_vld <= 1'b0;
    else
        tcache_ram_dataout_vld <= tcache_ram_dataout_bank0_rqt | tcache_ram_dataout_bank1_rqt;
    end

   wire  [DATA_32CH_WID-1:0]        trans_lthram_bank0_dataout, trans_lthram_bank1_dataout;
   assign   tcache_ram_dataout_ch0 =  trans_lthram_bank0_dataout  ;
   assign   tcache_ram_dataout_ch1 =  trans_lthram_bank1_dataout  ;
  
   /****************************************************************************************************/
   /*************************************transpose read ************************************************/
   /****************************************************************************************************/

     
   reg   tcache_ram_trans_load_bank0_ok, tcache_ram_trans_load_bank1_ok;

    always@(posedge clk or negedge rst_n) begin
     if(!rst_n)
          tcache_ram_trans_load_bank0_ok   <= 'b0;
        else if(tcache_ram_state_clr)
          tcache_ram_trans_load_bank0_ok   <= 'b0;
        else if( tcache_mode == TRANS_DWCONV_MODE || tcache_mode == TRANS_MATRIX_MODE ) begin 
            if((((tcache_ram_datain_cnt  == {1'b0,{(RAM_ADDR_WID){1'b1}}}) &&  tcache_ram_datain_vld ) || (tcache_ram_datain_last && !tcache_ram_datain_cnt[RAM_ADDR_WID])) )  // datain_cnt = 5'b01111  bank0 load over
                tcache_ram_trans_load_bank0_ok   <= 'b1;
            else if((trans_dataout_y_cnt == {1'b0,{(RAM_ADDR_WID){1'b1}},1'b0}))
                tcache_ram_trans_load_bank0_ok   <= 'b0;
        end
	else
                tcache_ram_trans_load_bank0_ok   <= 'b0;
    end

    
    always@(posedge clk or negedge rst_n) begin
     if(!rst_n)
          tcache_ram_trans_load_bank1_ok   <= 'b0;
        else if(tcache_ram_state_clr)
          tcache_ram_trans_load_bank1_ok   <= 'b0;
        else if  (tcache_mode == TRANS_DWCONV_MODE || tcache_mode == TRANS_MATRIX_MODE) begin
            if((((tcache_ram_datain_cnt  == {(RAM_ADDR_WID+1){1'b1}} ) &&  tcache_ram_datain_vld) || (tcache_ram_datain_last && tcache_ram_datain_cnt[RAM_ADDR_WID]  ) )  ) //datain_cnt = 5'11111  
                tcache_ram_trans_load_bank1_ok   <= 'b1;
            else if((trans_dataout_y_cnt  == {1'b1,{(RAM_ADDR_WID){1'b1}},1'b0}))
                tcache_ram_trans_load_bank1_ok   <= 'b0;
        end
    end


   reg [RAM_ADDR_WID :0]     tcache_ram_datain_cnt_last  ;  //6bit

    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)
            tcache_ram_datain_cnt_last <= 'b0;
        else if(tcache_ram_state_clr)
            tcache_ram_datain_cnt_last <= 'b0;
        else if(tcache_mode ==  TRANS_DWCONV_MODE || tcache_mode == TRANS_MATRIX_MODE) begin 
                if(tcache_ram_datain_last )
                    tcache_ram_datain_cnt_last <= tcache_ram_datain_cnt[RAM_ADDR_WID :0];
               //  else if(tcache_ram_datain_cnt_last[RAM_ADDR_WID + 1] & !tcache_ram_trans_load_bank1_ok ||  !tcache_ram_datain_cnt_last[RAM_ADDR_WID + 1] & !tcache_ram_trans_load_bank0_ok  )
		// else if(tcache_ram_datain_cnt_last == trans_dataout_y_cnt[RAM_ADDR_WID+1 :1])
                //    tcache_ram_datain_cnt_last <= 'b0;
        end
    end
   
   logic tcache_ram_datain_last_valid ;
    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)
            tcache_ram_datain_last_valid <= 'b0;
        else if(tcache_ram_state_clr)
            tcache_ram_datain_last_valid <= 'b0;
        else if(tcache_mode ==  TRANS_DWCONV_MODE || tcache_mode == TRANS_MATRIX_MODE) begin 
                if(tcache_ram_datain_last )
                    tcache_ram_datain_last_valid <= 1'b1;
		else if( (tcache_ram_datain_cnt_last[RAM_ADDR_WID] == trans_dataout_y_cnt[RAM_ADDR_WID+1]) && &trans_dataout_y_cnt[RAM_ADDR_WID: 1])
                    tcache_ram_datain_last_valid <= 1'b0;
        end
    end

    //----------------------------------------------------------------------------------------------------------//
   wire [8*16-1:0]                  trans_dataout_y0_bank1, trans_dataout_y0_bank0  ;
   wire [8*16-1:0]                  trans_dataout_y1_bank1, trans_dataout_y1_bank0  ;
   
   reg trans_last_flag, trans_last_bank;

   always@(posedge clk or negedge rst_n) begin
     if(!rst_n) begin
	    trans_last_flag <= 'b0;
	    trans_last_bank <= 'b0;
    end
     else if(tcache_mode ==  TRANS_DWCONV_MODE || tcache_mode == TRANS_MATRIX_MODE  ) begin
	    if(tcache_ram_datain_last) begin
		    trans_last_flag <= 'b1;
		    trans_last_bank <= tcache_ram_datain_cnt[RAM_ADDR_WID];
        end
     	else if(trans_dataout_y_cnt[RAM_ADDR_WID: 1] == 'hf && trans_dataout_y_cnt[RAM_ADDR_WID+1] == trans_last_bank) begin
		    trans_last_flag <= 'b0;	
		    trans_last_bank <= 'b0;
        end
      end
   end

    always@(posedge clk or negedge rst_n) begin
     if(!rst_n)
          trans_dataout_y_cnt   <= 'b0;
        else if(tcache_ram_state_clr)
          trans_dataout_y_cnt   <= 'b0;
        else if(tcache_mode ==  TRANS_DWCONV_MODE || tcache_mode == TRANS_MATRIX_MODE) begin
               if((trans_dataout_y_cnt[RAM_ADDR_WID+1] == trans_last_bank) && (trans_dataout_y_cnt[RAM_ADDR_WID: 1] == 'hf) && trans_last_flag)
                    trans_dataout_y_cnt   <=  'b0 ;
 	           else if((tcache_ram_trans_load_bank0_ok | tcache_ram_trans_load_bank1_ok) )//&& (trans_dataout_y_cnt[RAM_ADDR_WID: 1] != 'hf))
                    trans_dataout_y_cnt   <= trans_dataout_y_cnt +   2 ;
	     // else if((tcache_ram_trans_load_bank0_ok | tcache_ram_trans_load_bank1_ok) && (trans_dataout_y_cnt[RAM_ADDR_WID: 1] == 'hf) && !trans_last_flag )
         //       trans_dataout_y_cnt   <= trans_dataout_y_cnt +   2 ;
	     // else if((tcache_ram_trans_load_bank0_ok && (trans_dataout_y_cnt[RAM_ADDR_WID: 1] == 'hf) && !tcache_ram_datain_cnt_last[RAM_ADDR_WID])  //last at bank0,read end in bank0
		//	 || (tcache_ram_trans_load_bank1_ok && (trans_dataout_y_cnt[RAM_ADDR_WID: 1] == 'hf)&& tcache_ram_datain_cnt_last[RAM_ADDR_WID]) ) //last at bank1,read in bank1
        //  else if((trans_dataout_y_cnt[RAM_ADDR_WID+1] == trans_last_bank) && (trans_dataout_y_cnt[RAM_ADDR_WID: 1] == 'hf) && trans_last_flag)
          //      trans_dataout_y_cnt   <=  'b0 ;
        end
    end

   
    wire trans_ren_y_bank0 = ~trans_dataout_y_cnt[RAM_ADDR_WID+1] && tcache_ram_trans_load_bank0_ok;   
    wire trans_ren_y_bank1 =  trans_dataout_y_cnt[RAM_ADDR_WID+1] && tcache_ram_trans_load_bank1_ok;

    wire [RAM_ADDR_WID : 0]  trans_addr_dp_rd_y = {1'b0, trans_dataout_y_cnt[RAM_ADDR_WID: 1]};

    reg     tcache_ram_trans_dataout_vld_tmp ;

    always@(posedge clk or negedge rst_n) begin
     if(!rst_n) begin 
        tcache_ram_trans_dataout_vld_tmp <= 'b0;
        tcache_ram_trans_dataout_vld     <= 'b0;
        end
    else begin
        tcache_ram_trans_dataout_vld_tmp <= tcache_ram_trans_load_bank0_ok | tcache_ram_trans_load_bank1_ok;
        tcache_ram_trans_dataout_vld     <= tcache_ram_trans_dataout_vld_tmp;
        end
    end

    //output bank select
    reg trans_ren_y_cs_dly;
    always@(posedge clk or negedge rst_n) begin
     if(!rst_n)
        trans_ren_y_cs_dly <= 'b0;
    else if (tcache_ram_trans_load_bank0_ok | tcache_ram_trans_load_bank1_ok)
        trans_ren_y_cs_dly <= trans_dataout_y_cnt[RAM_ADDR_WID+1]; //read ram sel 
    end

    function   [16-1:0][7:0]  trans_mask_invalid_dataout (input [3:0] mask_cnt);
        integer i;
        trans_mask_invalid_dataout = {16{8'h00}};
        //if(mask_cnt == 0)   trans_mask_invalid_dataout  = {16{8'hff}};
        //else for(i=1; i <= mask_cnt; i=i+1) trans_mask_invalid_dataout[i] = 8'hff;  
         for(i=0; i <= mask_cnt; i=i+1) trans_mask_invalid_dataout[i] = 8'hff;  
    endfunction
  

   wire [16-1:0][7:0]  trans_mask = trans_mask_invalid_dataout(tcache_ram_datain_cnt_last[3:0]) ;

    logic tcache_ram_datain_last_valid_dly;
    always@(posedge clk or negedge rst_n ) 
    if(!rst_n) 
 	tcache_ram_datain_last_valid_dly <= 'b0;
    else
	tcache_ram_datain_last_valid_dly <= tcache_ram_datain_last_valid;
		
	
    always@(posedge clk ) 
    if(tcache_ram_trans_dataout_vld_tmp) begin
     tcache_ram_trans_dataout_lb_bank0    <= ((trans_ren_y_cs_dly == tcache_ram_datain_cnt_last[4])&&tcache_ram_datain_last_valid_dly  ?  trans_mask :  {16{8'hff}}  ) & (trans_ren_y_cs_dly ? trans_dataout_y0_bank1  :  trans_dataout_y0_bank0 )  ;                   
     tcache_ram_trans_dataout_lb_bank1    <= ((trans_ren_y_cs_dly == tcache_ram_datain_cnt_last[4])&&tcache_ram_datain_last_valid_dly  ?  trans_mask :  {16{8'hff}}  ) & (trans_ren_y_cs_dly ? trans_dataout_y1_bank1  :  trans_dataout_y1_bank0 )  ;
   end

   //wire  [DATA_32CH_WID-1:0]       tcache_ram_trans_dataout_byte_bus =   {tcache_ram_trans_dataout_lb_bank1, tcache_ram_trans_dataout_lb_bank0 } ;

   wire  [CH_X-1:0] [WORD_WID-1:0] tcache_ram_trans_dataout_byte_bus = {tcache_ram_trans_dataout_lb_bank1, tcache_ram_trans_dataout_lb_bank0 } ;

    //switch byte out
   always_comb begin
     foreach(tcache_ram_trans_dataout_byte[n])
            tcache_ram_trans_dataout_byte[n] = tcache_core_trans_prici ?  ((n%2 == 1) ? tcache_ram_trans_dataout_byte_bus[16+n/2] : tcache_ram_trans_dataout_byte_bus[n/2] ) : tcache_ram_trans_dataout_byte_bus[n] ; //0~15 low byte, 16~31 high byte
    end

   always_comb begin
       tcache_ram_trans_dataout = tcache_ram_trans_dataout_byte ; //tcache_core_trans_swbank ? { tcache_ram_trans_dataout_byte[15:0] , tcache_ram_trans_dataout_byte[31:16] } :  tcache_ram_trans_dataout_byte; 
    end


   wire [RAM_ADDR_WID:0]  tcache_ram_trans_dataout_remain_cnt  =    (NUM_WORDS*2-1) -  trans_dataout_y_cnt[RAM_ADDR_WID:0]    +  (tcache_ram_trans_load_bank0_ok | tcache_ram_trans_load_bank1_ok ? NUM_WORDS*2 : 0);

   always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        tcache_ram_trans_dataout_done <= 'b0;
    else
        tcache_ram_trans_dataout_done <= (tcache_ram_trans_dataout_remain_cnt == 0); 
    end

trans_latchram256x16  U_trans_latchram256x16_bank0 (
.clk         (clk                                    ),
.wen_x_cs    (tcache_ram_datain_lthram_bank0_cs      ),
.wen_x       (tcache_ram_datain_lthram_bank0_wen     ),
.addr_w_x    (tcache_ram_datain_lthram_addr          ),
.addr_r_x    (tcache_ram_dataout_lthram_bank0_addr   ),
.wdata_x     (trans_lthram_bank0_datain              ),
.ren_x       (trans_lthram_bank0_ren                 ),
.rdata_x     (trans_lthram_bank0_dataout             ),
.ren_y       (trans_ren_y_bank0                      ),
.addr_dp_r_y (trans_addr_dp_rd_y                     ),
.rdata_y_0   (trans_dataout_y0_bank0                 ),
.rdata_y_1   (trans_dataout_y1_bank0                 )
            );
    
trans_latchram256x16  U_trans_latchram256x16_bank1 (
.clk         (clk                                    ),
.wen_x_cs    (tcache_ram_datain_lthram_bank1_cs      ),
.wen_x       (tcache_ram_datain_lthram_bank1_wen     ),
.addr_w_x    (tcache_ram_datain_lthram_addr          ),
.addr_r_x    (tcache_ram_dataout_lthram_bank1_addr   ),
.wdata_x     (trans_lthram_bank1_datain              ),
.ren_x       (trans_lthram_bank1_ren                 ),
.rdata_x     (trans_lthram_bank1_dataout             ),
.ren_y       (trans_ren_y_bank1                      ),
.addr_dp_r_y (trans_addr_dp_rd_y                     ),
.rdata_y_0   (trans_dataout_y0_bank1                 ),
.rdata_y_1   (trans_dataout_y1_bank1                 )
            );

endmodule
