module tcache_core #(
    parameter WORD_WID        = 8                           ,
    parameter CH_X            = 32                          ,
    parameter DATA_32CH_WID   = WORD_WID * CH_X             ,
    parameter DATA_16CH_WID   = WORD_WID * CH_X /2          ,
    parameter NUM_WORDS       = 16                          ,
    parameter TRANS_RAM_BANK_DDR_WID = $clog2(NUM_WORDS)    ,
    parameter NUM_WORDS_Y     = CH_X 
)(
   input  logic                                     clk                                     ,
   input  logic                                     rst_n                                   ,
   //---------------------x direction---------------------//
   input   [2:0]                                    tcache_mode                             ,  
   input                                            tcache_core_state_clr                   ,
   input                                            tcache_core_load_bank_num               ,
   output                                           tcache_core_move_fmap_en                ,
   input                                            tcache_core_trans_prici                 ,
   input                                            tcache_core_trans_swbank                ,
   input  [1:0]                                     l1b_op_wr_hl_mask                       ,
   input                                            mvfmap_dfifo_addr_odd                   ,
   input  [4:0]                                     tcache_mvfmap_offset                    ,
   input                                            tcache_mvfmap_stride                    ,
    //l1
   input                                            tcache_l1b_datain_vld_ch0               ,
   input                                            tcache_l1b_datain_vld_ch1               ,
   input                                            tcache_l1b_datain_last                  ,
   input         [DATA_32CH_WID-1:0]                tcache_l1b_datain_ch0                   ,
   input         [DATA_32CH_WID-1:0]                tcache_l1b_datain_ch1                   ,
    //l2
   input                                            tcache_l2c_datain_vld                   ,
   input                                            tcache_l2c_datain_last                  ,
   output                                           tcache_l2c_datain_rdy                   ,
   input         [DATA_32CH_WID-1:0]                tcache_l2c_datain                       ,

   //out
   output                                           tcache_l1b_dataout_vld2lsu              ,
   output  reg                                      tcache_l1b_dataout_vld                  ,
   output  logic [DATA_32CH_WID-1:0]                tcache_l1b_dataout_ch0                  ,
   output  logic [DATA_32CH_WID-1:0]                tcache_l1b_dataout_ch1                  ,

   output                                           tcache_core2bcfmap_datain_valid             ,
   input                                            conv3d_bcfmap_req                           ,
   input                                            conv3d_bcfmap_rgba_mode                     ,
   input                                            conv3d_bcfmap_tcache_stride                 ,
   input  [4:0]                                     conv3d_bcfmap_tcache_offset                 ,
   input                                            tcache_core2bcfmap_dataout_bank0_rqt        ,
   input                                            tcache_core2bcfmap_dataout_bank1_rqt        ,
   input                                            tcache_core2bcfmap_dataout_bank0_rqt_last   ,
   input                                            tcache_core2bcfmap_dataout_bank1_rqt_last   ,
   output  logic                                    tcache_ram_dataout_bank0_not_empty          ,
   output  logic                                    tcache_ram_dataout_bank1_not_empty          ,
   output                                           tcache_core2bcfmap_dataout_vld              , //cub: cubank
   output  logic [DATA_32CH_WID-1:0]                tcache_core2bcfmap_dataout_ch0              ,
   output  logic [DATA_32CH_WID-1:0]                tcache_core2bcfmap_dataout_ch1              

);

   logic [DATA_32CH_WID-1:0]                        tcache_ram_datain_ch0_r       ;
   logic [DATA_32CH_WID-1:0]                        tcache_ram_datain_ch1_r       ;
   logic [DATA_32CH_WID-1:0]                        tcache_ram_datain_ch0       ;
   logic [DATA_32CH_WID-1:0]                        tcache_ram_datain_ch1       ;
   logic                                            tcache_ram_datain_vld       ;
   logic                                            tcache_ram_datain_last      ;

    //--------------------------------------------------------------------------------------//
    //---------------------------------slsu_tcache_mode-------------------------------------//
    //--------------------------------------------------------------------------------------//
     localparam CONV16CH_DFIFO_MODE  = 'b000   ;  //wr/rd    l1b cache    tcache_FIFO
     localparam CONV16CH_SFIFO_MODE  = 'b001   ;  //wr/rd    l1b cache    tcache_FIFO
     localparam CONV32CH_DFIFO_MODE  = 'b010   ;  //wr/rd    l1b cache    tcache_FIFO
     localparam CONV32CH_SFIFO_MODE  = 'b011   ;  //wr/rd    l1b cache    tcache_FIFO
     localparam TRANS_MATRIX_MODE    = 'b100   ;  //wr       l1b cache    tcache_TRANS in l1b_cache
     localparam TRANS_DWCONV_MODE    = 'b111   ;  //wr       l1b norm     tcache_TRANS in l1b_weight

    //mode
    wire    tcache_ram_trans_dataout_done   ;
    wire    tcache_l1b_dataout_vld_src      ;

    wire  tcache_core_datain_rdy    = 1'b1; //!tcache_ram_fifo_full ;

    wire tcache_ram_load_bank_num   = tcache_core_load_bank_num ;

    assign  tcache_core2bcfmap_datain_valid = tcache_ram_datain_vld ;
    wire    tcache_ram_move_fmap_en ;
    assign tcache_core_move_fmap_en   = tcache_ram_move_fmap_en ;



    reg [3:0]   tcache_l1b_datain_last_dly ;
    always_ff@(posedge clk or negedge rst_n) begin
        if(!rst_n ) 
           tcache_l1b_datain_last_dly <=  'b0;
        else if(tcache_core_datain_rdy)
           tcache_l1b_datain_last_dly <= {tcache_l1b_datain_last_dly[2:0], tcache_l1b_datain_last}  ;
    end

    // datain vld
    wire  tcache_core_datain_vld    = ( tcache_mode == TRANS_DWCONV_MODE || tcache_mode == TRANS_MATRIX_MODE ) ?    tcache_l2c_datain_vld  : tcache_l1b_datain_vld_ch0|tcache_l1b_datain_vld_ch1   ; 
    wire  tcache_core_datain_last   = ( tcache_mode == TRANS_DWCONV_MODE || tcache_mode == TRANS_MATRIX_MODE ) ?    tcache_l2c_datain_last : tcache_l1b_datain_last_dly[3] ; 


    assign  tcache_l2c_datain_rdy   = ( tcache_mode == TRANS_DWCONV_MODE || tcache_mode == TRANS_MATRIX_MODE ) ?   tcache_core_datain_rdy   : 1;

    reg hl_shift;
   always@(posedge clk or negedge rst_n) begin
        if(!rst_n)
            hl_shift <= 'b0;
        else if(tcache_core_datain_last)
            hl_shift <= 'b0;
        else if(tcache_core_datain_vld && (tcache_mode == CONV16CH_SFIFO_MODE || tcache_mode == CONV32CH_SFIFO_MODE )) 
            hl_shift <= ~hl_shift;
   end

    always_ff@(posedge clk or negedge rst_n) begin
        if(!rst_n ) 
           tcache_ram_datain_vld <=  'b0;
        else if(tcache_core_datain_rdy) begin
            if((tcache_mode == CONV16CH_SFIFO_MODE || tcache_mode == CONV32CH_SFIFO_MODE )&& !tcache_mvfmap_stride)
                tcache_ram_datain_vld <= ( tcache_core_datain_vld & hl_shift ) || tcache_core_datain_last;
            else
                tcache_ram_datain_vld <= tcache_core_datain_vld ;
        end
    end


    always_ff@(posedge clk or negedge rst_n) begin
        if(!rst_n ) 
           tcache_ram_datain_last <=  'b0;
        else if(tcache_core_datain_rdy)
           tcache_ram_datain_last <= tcache_core_datain_last ;
    end

   wire [DATA_32CH_WID-1:0]    tcache_l1b_datain_single_ch        =  tcache_l1b_datain_vld_ch0 ? tcache_l1b_datain_ch0 : tcache_l1b_datain_ch1 ;
   wire [DATA_32CH_WID/2-1:0]    tcache_l1b_datain_16ch_sfifo_bank0 =  tcache_l1b_datain_single_ch[DATA_32CH_WID/2-1:0]             ;
   wire [DATA_32CH_WID/2-1:0]    tcache_l1b_datain_16ch_sfifo_bank1 =  tcache_l1b_datain_single_ch[DATA_32CH_WID-1:DATA_32CH_WID/2] ;

   wire [DATA_32CH_WID-1:0]    tcache_l1b_datain_32ch_sfifo =  tcache_l1b_datain_vld_ch0 ? tcache_l1b_datain_ch0 : tcache_l1b_datain_ch1; //merge to one port
    
    
   //switch byte in
   logic       [CH_X-1:0] [WORD_WID-1:0]        tcache_l2c_datain_sw_hl;
   logic       [CH_X-1:0] [WORD_WID-1:0]        tcache_l2c_datain_byte;
   
   always_comb begin
    tcache_l2c_datain_byte = tcache_l2c_datain ;
    foreach(tcache_l2c_datain_sw_hl[n])
        tcache_l2c_datain_sw_hl[n] =  n < 16 ? tcache_l2c_datain_byte[n*2] :  tcache_l2c_datain_byte[(n-16)*2+1];
   end

    //data
    always_ff@(posedge clk ) begin
        if(tcache_core_datain_vld & tcache_core_datain_rdy) begin
            tcache_ram_datain_ch0_r <= ( tcache_mode == TRANS_DWCONV_MODE  || tcache_mode == TRANS_MATRIX_MODE ) ? ( tcache_core_trans_prici ?  tcache_l2c_datain_sw_hl : tcache_l2c_datain ) : 
                                     ( tcache_mode == CONV16CH_DFIFO_MODE ) ?  { tcache_l1b_datain_ch1[DATA_32CH_WID/2-1:0], tcache_l1b_datain_ch0[DATA_32CH_WID/2-1:0] } :
                                     ( tcache_mode == CONV16CH_SFIFO_MODE ) && tcache_mvfmap_stride ? (tcache_mvfmap_offset[0] ? { tcache_l1b_datain_16ch_sfifo_bank0,128'b0 } :{128'b0, tcache_l1b_datain_16ch_sfifo_bank0}) :
                                     ( tcache_mode == CONV32CH_SFIFO_MODE ) && tcache_mvfmap_stride ? (tcache_mvfmap_offset[0] ? { 256'b0 } : tcache_l1b_datain_32ch_sfifo) :
                                     ( tcache_mode == CONV16CH_SFIFO_MODE ) ?  tcache_core_datain_last && !hl_shift ? {  tcache_ram_datain_ch0_r[DATA_32CH_WID-1:DATA_32CH_WID/2],tcache_l1b_datain_16ch_sfifo_bank0 } : {  tcache_l1b_datain_16ch_sfifo_bank0,tcache_ram_datain_ch0_r[DATA_32CH_WID-1:DATA_32CH_WID/2] }  : //low 16ch put low bits
                                     ( tcache_mode == CONV32CH_SFIFO_MODE ) ?  ( !hl_shift ?  tcache_l1b_datain_32ch_sfifo : tcache_ram_datain_ch0_r ) : tcache_l1b_datain_ch0 ; //single channel

            tcache_ram_datain_ch1_r <= ( tcache_mode == CONV16CH_DFIFO_MODE ) ?  { tcache_l1b_datain_ch1[DATA_32CH_WID-1:DATA_32CH_WID/2], tcache_l1b_datain_ch0[DATA_32CH_WID-1:DATA_32CH_WID/2] } : 
                                     ( tcache_mode == CONV16CH_SFIFO_MODE ) && tcache_mvfmap_stride ? (tcache_mvfmap_offset[0] ? { tcache_l1b_datain_16ch_sfifo_bank1,128'b0 } :{128'b0, tcache_l1b_datain_16ch_sfifo_bank1}) :
                                     ( tcache_mode == CONV32CH_SFIFO_MODE ) && tcache_mvfmap_stride ? (tcache_mvfmap_offset[0] ?  tcache_l1b_datain_32ch_sfifo : { 256'b0 } ) :
                                     ( tcache_mode == CONV16CH_SFIFO_MODE ) ?  tcache_core_datain_last && !hl_shift ?  {  tcache_ram_datain_ch1_r[DATA_32CH_WID-1:DATA_32CH_WID/2],tcache_l1b_datain_16ch_sfifo_bank1 } : {  tcache_l1b_datain_16ch_sfifo_bank1,tcache_ram_datain_ch1_r[DATA_32CH_WID-1:DATA_32CH_WID/2] } : //low 16ch put low bits
                                     ( tcache_mode == CONV32CH_SFIFO_MODE ) ?   ( hl_shift ?  tcache_l1b_datain_32ch_sfifo : tcache_ram_datain_ch1_r ) : tcache_l1b_datain_ch1 ; //single channel
    end
  end

  //note ch0 is even addr, ch0_r high is odd addr
  assign tcache_ram_datain_ch0 =  ( tcache_mode == CONV16CH_DFIFO_MODE ) && mvfmap_dfifo_addr_odd ?  { tcache_l1b_datain_ch0[DATA_32CH_WID/2-1:0], tcache_ram_datain_ch0_r[DATA_32CH_WID-1:DATA_32CH_WID/2] } :
                                  ( tcache_mode == CONV32CH_DFIFO_MODE ) && mvfmap_dfifo_addr_odd ?  tcache_ram_datain_ch1_r : tcache_ram_datain_ch0_r ;

  assign tcache_ram_datain_ch1 =  ( tcache_mode == CONV16CH_DFIFO_MODE ) && mvfmap_dfifo_addr_odd ?  {tcache_l1b_datain_ch0[DATA_32CH_WID-1:DATA_32CH_WID/2], tcache_ram_datain_ch1_r[DATA_32CH_WID-1:DATA_32CH_WID/2]} :
                                  ( tcache_mode == CONV32CH_DFIFO_MODE ) && mvfmap_dfifo_addr_odd ?  tcache_l1b_datain_ch0 : tcache_ram_datain_ch1_r ;
    //------------------------------------------ data out to l1b-------------------------------------------------------//
   wire                         tcache_ram_trans_dataout_vld              ;                         
   wire  [DATA_32CH_WID-1:0]    tcache_ram_trans_dataout                  ;                         
   wire  [DATA_16CH_WID-1:0]    tcache_ram_trans_dataout_lb_bank0         ;                   
   wire  [DATA_16CH_WID-1:0]    tcache_ram_trans_dataout_lb_bank1         ;
   wire  [CH_X-1:0]             tcache_ram_trans_dataout_remain_cnt       ;

   //to l1b valid & data
   // will insert one pipe reg in addr table module !!!!!!!!!!!!!!!!!!
   assign tcache_l1b_dataout_vld_src  = ( tcache_mode == TRANS_DWCONV_MODE || tcache_mode == TRANS_MATRIX_MODE) ? tcache_ram_trans_dataout_vld : tcache_l2c_datain_vld ;

   assign tcache_l1b_dataout_vld2lsu = tcache_l1b_dataout_vld_src;

   // always_ff@(posedge clk or negedge rst_n) begin
   //     if(!rst_n ) 
   //         tcache_l1b_dataout_vld_src <= 'b0;
   //     else
   //         tcache_l1b_dataout_vld_src <=  tcache_l1b_dataout_vld_w ;
   // end

  reg tcache_l1b_dataout_vld_trace;

	//sync tcache_l1b_dataout_ch0/ch1, not use tcache_l1b_dataout_vld_src

    always_ff@(posedge clk or negedge rst_n) begin
        if(!rst_n ) 
  	    tcache_l1b_dataout_vld <= 'b0;
	else
        tcache_l1b_dataout_vld <=  tcache_l1b_dataout_vld_src ;
 	end

   wire [DATA_32CH_WID-1:0]   tcache_l1b_dataout_ch0_wire  =    ( tcache_mode == TRANS_DWCONV_MODE  || tcache_mode == TRANS_MATRIX_MODE ) ?  tcache_ram_trans_dataout : tcache_l2c_datain            ;
   wire [DATA_32CH_WID-1:0]   tcache_l1b_dataout_ch1_wire  =     ( tcache_mode == TRANS_DWCONV_MODE || tcache_mode == TRANS_MATRIX_MODE ) ?  tcache_ram_trans_dataout : tcache_l2c_datain           ;



    always_ff@(posedge clk ) begin
        if(tcache_l1b_dataout_vld_src)
            tcache_l1b_dataout_ch0 <=  tcache_core_trans_swbank ? { tcache_l1b_dataout_ch0_wire[DATA_16CH_WID-1:0] ,tcache_l1b_dataout_ch0_wire[DATA_16CH_WID+:DATA_16CH_WID] } : tcache_l1b_dataout_ch0_wire ; //32ch data in    
    end

    always_ff@(posedge clk ) begin
        if(tcache_l1b_dataout_vld_src)
            tcache_l1b_dataout_ch1 <=  tcache_core_trans_swbank ? { tcache_l1b_dataout_ch1_wire[DATA_16CH_WID-1:0] ,tcache_l1b_dataout_ch0_wire[DATA_16CH_WID+:DATA_16CH_WID] } : tcache_l1b_dataout_ch0_wire; //32ch data in   
    end



    //--------------------------------- conv3d broadcast featuremap ---------------------------------------------------//
   wire    tcache_ram_dataout_bank0_rqt         = tcache_core2bcfmap_dataout_bank0_rqt          ;
   wire    tcache_ram_dataout_bank1_rqt         = tcache_core2bcfmap_dataout_bank1_rqt          ;
   wire    tcache_ram_dataout_bank0_rqt_last    = tcache_core2bcfmap_dataout_bank0_rqt_last     ;
   wire    tcache_ram_dataout_bank1_rqt_last    = tcache_core2bcfmap_dataout_bank1_rqt_last     ;

   wire                                     tcache_ram_dataout_vld     ; 
   wire    [DATA_32CH_WID-1:0]              tcache_ram_dataout_ch0     ;
   wire    [DATA_32CH_WID-1:0]              tcache_ram_dataout_ch1     ;

   assign  tcache_core2bcfmap_dataout_vld   =       tcache_ram_dataout_vld     ;
   assign  tcache_core2bcfmap_dataout_ch0   =       tcache_ram_dataout_ch0     ;
   assign  tcache_core2bcfmap_dataout_ch1   =       tcache_ram_dataout_ch1     ;    




tcache_dfifo  U_tcache_dfifo(
.clk                                (clk                               ),
.rst_n                              (rst_n                             ),
.tcache_mode                        (tcache_mode                       ),
.tcache_ram_state_clr               (tcache_core_state_clr             ),
.tcache_ram_datain_vld              (tcache_ram_datain_vld             ),
.tcache_ram_datain_last             (tcache_ram_datain_last            ),
.conv3d_bcfmap_req                  (conv3d_bcfmap_req                 ),
.conv3d_bcfmap_rgba_mode            (conv3d_bcfmap_rgba_mode           ),
.tcache_mvfmap_offset               (tcache_mvfmap_offset              ),
.conv3d_bcfmap_tcache_stride        (conv3d_bcfmap_tcache_stride       ),
.conv3d_bcfmap_tcache_offset        (conv3d_bcfmap_tcache_offset       ),
.tcache_ram_dataout_bank0_rqt       (tcache_ram_dataout_bank0_rqt      ),
.tcache_ram_dataout_bank1_rqt       (tcache_ram_dataout_bank1_rqt      ),
.tcache_ram_dataout_bank0_rqt_last  (tcache_ram_dataout_bank0_rqt_last ),
.tcache_ram_dataout_bank1_rqt_last  (tcache_ram_dataout_bank1_rqt_last ),
.tcache_ram_dataout_bank0_not_empty (tcache_ram_dataout_bank0_not_empty),
.tcache_ram_dataout_bank1_not_empty (tcache_ram_dataout_bank1_not_empty),
.tcache_ram_datain_ch0              (tcache_ram_datain_ch0             ),
.tcache_ram_datain_ch1              (tcache_ram_datain_ch1             ),
.tcache_ram_dataout_vld             (tcache_ram_dataout_vld            ),
.tcache_ram_dataout_ch0             (tcache_ram_dataout_ch0            ),
.tcache_ram_dataout_ch1             (tcache_ram_dataout_ch1            ),
.tcache_ram_move_fmap_en            (tcache_ram_move_fmap_en           ),  //wid=5, max value=16
.tcache_ram_load_bank_num           (tcache_ram_load_bank_num          ),
.tcache_core_trans_prici            (tcache_core_trans_prici           ),
.l1b_op_wr_hl_mask                  (l1b_op_wr_hl_mask                 ),  
.tcache_ram_trans_dataout_vld       (tcache_ram_trans_dataout_vld      ),                            
.tcache_ram_trans_dataout           (tcache_ram_trans_dataout          ),                            
.tcache_ram_trans_dataout_lb_bank0  (                                  ),                            
.tcache_ram_trans_dataout_lb_bank1  (                                  ),
.tcache_ram_trans_dataout_done      (tcache_ram_trans_dataout_done     )
);

   
endmodule
