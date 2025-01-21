module scache_cflow_ctrl #(    
            parameter   SCACHE_RAM_DEPTH  = 64 *  4 * 2 , // tow ram_bank, addrs by byte
            parameter   SCACHE_RAM_WDEPTH  = 64 * 2 , // tow ram_bank, addrs by byte
            parameter   SCACHE_RAM_DWID   = 32
            )(  
   //----------------------------------------------------------------//
   input                                      clk                   ,
   input                                      rst_n                 ,

   //-----------------------wr-----------------------------------------//
   input                                      scache_cflow_data_wr_valid       ,//data flow  from pooling 
   input  [SCACHE_RAM_DWID-1:0]               scache_cflow_data_wr_data        ,
   //output                                     scache_cflow_data_wr_ready       ,
   //instr
   input                                      scache_cflow_data_wr_en          ,
   input  [$clog2(SCACHE_RAM_DEPTH)-1:0 ]     scache_cflow_data_wr_dst_addr    ,  //byte addr, 2*64word*4byte
   //cfg                                 
   input  [1:0 ]                              scache_cflow_data_wr_size        ,  //10: byte 01: half word 00: word
   input  [$clog2(SCACHE_RAM_DEPTH)-1:0 ]     scache_cflow_data_wr_sub_len     ,  //
   input  [$clog2(SCACHE_RAM_DEPTH)-1:0 ]     scache_cflow_data_wr_sub_gap     ,  //
   input  [$clog2(SCACHE_RAM_DEPTH)-1:0 ]     scache_cflow_data_wr_sys_len     ,  //system len 
   input  [$clog2(SCACHE_RAM_DEPTH)  :0 ]     scache_cflow_data_wr_sys_gap     ,  //
   output logic                               scache_cflow_data_wr_done        ,  
        
   //-----------------------rd-----------------------------------------//
   output logic                               scache_cflow_data_rd_valid       ,//data flow to pooling 
   output logic [SCACHE_RAM_DWID-1:0]         scache_cflow_data_rd_data        ,
   input                                      scache_cflow_data_rd2l2_ready    ,
   output                                     scache_cflow_data_rd2l2_last    ,

   //instr
   input                                      scache_cflow_data_rd_en          ,
   output  reg                                scache_cflow_data_rd_st_rdy      ,
   input                                      scache_cflow_data_rd_sign_ext    ,
   input  [$clog2(SCACHE_RAM_DEPTH)-1:0 ]     scache_cflow_data_rd_dst_addr    ,  //byte addr, 2*64word*4byte
   //cfg
   input  [1:0 ]                              scache_cflow_data_rd_size        ,  //10: byte 01: half word 00: word
   input  [$clog2(SCACHE_RAM_DEPTH)-1:0 ]     scache_cflow_data_rd_sub_len     ,  //
   input  [$clog2(SCACHE_RAM_DEPTH)-1:0 ]     scache_cflow_data_rd_sub_gap     ,  //
   input  [$clog2(SCACHE_RAM_DEPTH)-1:0 ]     scache_cflow_data_rd_sys_len     ,  //
   input  [$clog2(SCACHE_RAM_DEPTH)  :0 ]     scache_cflow_data_rd_sys_gap     ,  //
   output logic                               scache_cflow_data_rd_done        ,  
   //--------------------------------------------------------------------------//
   input                                      scache_rd2l2_mode                ,
   input                                      scache_lut_mode                  ,
   input                                      scache_lut_ram_sel               ,
   input                                      scache_data_req                  ,
   input                                      scache_data_sfu_hw_offset        ,
   input                                      scache_data_we                   ,
   input    [3 : 0]                           scache_data_be                   ,
   input    [31 : 0]                          scache_data_wdata                ,
   input    [$clog2(SCACHE_RAM_WDEPTH)-1: 0]  scache_data_addr                 ,
   output                                     scache_data_gnt                  ,
   output   logic                             scache_data_rvalid               ,
   output   logic [31 : 0]                    scache_data_rdata                ,
   //------------------------ram port------------------------------------------//
   input  logic[1:0] [SCACHE_RAM_DWID-1:0]              scache_cflow_ram_rd_data         ,   
   output logic[1:0] [SCACHE_RAM_DWID-1:0]              scache_cflow_ram_wr_data         , 
   output logic[1:0] [$clog2(SCACHE_RAM_DEPTH)-1-3:0]   scache_cflow_ram_addr            ,  
   output      [1:0]                                    scache_cflow_ram_we              ,
   output      [1:0] [3:0]                              scache_cflow_ram_bm              ,
   output      [1:0]                                    scache_cflow_ram_en
);




    parameter   WORD  = 2'b00 ;
    parameter   HWRD  = 2'b01 ;
    parameter   BYTE  = 2'b10 ;
    parameter   DEFAULT_TYPE  = 2'b11 ;

   logic                               scache_cflow_data_rd_valid_inner       ;
   logic                               scache_cflow_data_rd_ready_inner       ;

   assign scache_cflow_data_rd_ready_inner = scache_rd2l2_mode  ?  scache_cflow_data_rd2l2_ready : 1'b1;
   
   //parameter SCACHE_RAM_DEPTH = 64*4 ;  // byte 
   //assign scache_cflow_data_wr_ready = 1;
   assign scache_data_gnt  = scache_data_req ;

   assign  scache_cflow_data_rd_valid = scache_lut_mode ? 1'b0  : scache_cflow_data_rd_valid_inner ;

   wire  scache_cflow_data_wr_valid_inner  = scache_lut_mode ?  scache_cflow_data_rd_valid_inner :  scache_cflow_data_wr_valid    ; //data flow  
   wire  [SCACHE_RAM_DWID-1:0] scache_cflow_data_wr_data_inner =     scache_lut_mode ? scache_cflow_data_rd_data : scache_cflow_data_wr_data ;
 
//-----------------------------------shcache write addr---------------------------------------------//
   logic [1:0] scache_cflow_data_wr_size_r     ;
   logic scache_cflow_ram_wr_en ;

   logic  [$clog2(SCACHE_RAM_DEPTH)-1: 0]  scache_cflow_data_wr_addr_cnt_tmp, scache_cflow_data_wr_sys_len_cnt_tmp, scache_cflow_data_wr_ram_addr;

   logic  [$clog2(SCACHE_RAM_DEPTH)  : 0]   scache_cflow_data_wr_ram_addr_signed ;
   logic  [$clog2(SCACHE_RAM_DEPTH)-1:0 ]   scache_cflow_data_wr_sub_len_cnt_tmp ;

   assign  scache_cflow_data_wr_ram_addr = scache_cflow_data_wr_ram_addr_signed[$clog2(SCACHE_RAM_DEPTH)-1: 0];
       

   wire   [$clog2(SCACHE_RAM_DEPTH)-1: 0]  scache_cflow_data_wr_sys_gap_add1   = scache_cflow_data_wr_sys_gap   + 1  ;  


   wire   [$clog2(SCACHE_RAM_DEPTH)-1: 0]  scache_cflow_data_wr_sub_len_sub1    = ( scache_cflow_data_wr_sub_len == 0 )?  SCACHE_RAM_DEPTH-1 : scache_cflow_data_wr_sub_len-1   ;  //  addr :    config  min is 1, load data to l1b
   wire   [$clog2(SCACHE_RAM_DEPTH)-1: 0]  scache_cflow_data_wr_sys_len_sub1    =   scache_cflow_data_wr_sys_len - 1       ;  //  addr :  8+5

      logic sh_wr_sta ;

      always@(posedge clk or negedge rst_n) begin
           if(!rst_n)
               sh_wr_sta <= 'b0;
           else if(scache_cflow_data_wr_en)
               sh_wr_sta <= 'b1;
           else if(scache_cflow_data_wr_done)
               sh_wr_sta <= 'b0;
      end

       always@(posedge clk or negedge rst_n ) begin
       if(!rst_n ) begin
            scache_cflow_data_wr_sub_len_cnt_tmp      <= 'b0    ;
            scache_cflow_data_wr_ram_addr_signed      <= 'b0    ;  
            scache_cflow_data_wr_sys_len_cnt_tmp      <= 'b0    ;
            scache_cflow_data_wr_size_r               <= 'b0    ;
       end
       else if(scache_cflow_data_wr_en) begin
            scache_cflow_data_wr_sub_len_cnt_tmp      <= 'b0    ;
            scache_cflow_data_wr_ram_addr_signed      <= {1'b0, scache_cflow_data_wr_dst_addr } ;  
            scache_cflow_data_wr_sys_len_cnt_tmp      <= 'b0    ;
            scache_cflow_data_wr_size_r               <=  scache_cflow_data_wr_size    ;
       end
       else if(sh_wr_sta && scache_cflow_data_wr_valid_inner) begin          //read L1b, dirtect to generate address
           if(scache_cflow_data_wr_sub_len_cnt_tmp == scache_cflow_data_wr_sub_len_sub1) begin
                scache_cflow_data_wr_sub_len_cnt_tmp <= 'b0;
               if(scache_cflow_data_wr_sys_len_cnt_tmp ==  scache_cflow_data_wr_sys_len_sub1 ) begin
                   scache_cflow_data_wr_ram_addr_signed   <= scache_cflow_data_wr_dst_addr ;
                   scache_cflow_data_wr_sys_len_cnt_tmp   <= 0;
                   end
                else begin
                   scache_cflow_data_wr_sys_len_cnt_tmp   <=  scache_cflow_data_wr_sys_len_cnt_tmp  +  1 ;
                   scache_cflow_data_wr_ram_addr_signed   <=  scache_cflow_data_wr_ram_addr_signed + scache_cflow_data_wr_sys_gap  ;  
                   end
           end 
            else begin
                scache_cflow_data_wr_sub_len_cnt_tmp      <= scache_cflow_data_wr_sub_len_cnt_tmp  +   1 ;
                scache_cflow_data_wr_ram_addr_signed      <= scache_cflow_data_wr_ram_addr_signed + scache_cflow_data_wr_sub_gap;
                scache_cflow_data_wr_sys_len_cnt_tmp      <= scache_cflow_data_wr_sys_len_cnt_tmp ;
            end
       end
    end


   always_comb begin
      if(sh_wr_sta &&  scache_cflow_data_wr_valid_inner) begin          
                scache_cflow_ram_wr_en         = 'b1 ;   

          if((scache_cflow_data_wr_sub_len_cnt_tmp == scache_cflow_data_wr_sub_len_sub1)&&(scache_cflow_data_wr_sys_len_cnt_tmp == scache_cflow_data_wr_sys_len_sub1 ))
                scache_cflow_data_wr_done      = 'b1 ;
           else
                scache_cflow_data_wr_done      = 'b0 ;

       end
       else begin
                scache_cflow_ram_wr_en         = 'b0 ;
                scache_cflow_data_wr_done      = 'b0 ;
       end
   end


//-----------------------------------shcache read addr---------------------------------------------//

    logic       scache_cflow_ram_rd_en ;
    logic       scache_cflow_data_rd_sign_ext_r ;
    logic [1:0] scache_cflow_data_rd_size_r     ;

   wire   [$clog2(SCACHE_RAM_DEPTH)-1: 0]  scache_cflow_data_rd_sub_len_sub1 = ( scache_cflow_data_rd_sub_len == 0 )?  SCACHE_RAM_DEPTH-1 : scache_cflow_data_rd_sub_len-1   ;  //  addr :    config  min is 1, load data to l1b
   wire   [$clog2(SCACHE_RAM_DEPTH)-1: 0]  scache_cflow_data_rd_sys_len_sub1 =   scache_cflow_data_rd_sys_len - 1       ;  //  addr :  8+5

   logic  [$clog2(SCACHE_RAM_DEPTH)-1: 0]  scache_cflow_data_rd_addr_cnt_tmp, scache_cflow_data_rd_sub_len_cnt_tmp, scache_cflow_data_rd_sys_len_cnt_tmp, scache_cflow_data_rd_ram_addr;

    logic  [$clog2(SCACHE_RAM_DEPTH) : 0]   scache_cflow_data_rd_ram_addr_signed ;

    assign scache_cflow_data_rd_ram_addr = scache_lut_mode ? {1'b0,scache_cflow_data_wr_data[$clog2(SCACHE_RAM_DEPTH)-2: 0] } : scache_cflow_data_rd_ram_addr_signed[$clog2(SCACHE_RAM_DEPTH)-1: 0];

      logic [1:0] scache_cflow_rd_pend;
      logic sh_rd_pend ; // pending when write sh ram 
      logic sh_rd_sta ;

    //reading conflict with writing
    //assign sh_rd_pend =  scache_cflow_ram_rd_en &&  scache_cflow_ram_wr_en && !(scache_cflow_data_wr_ram_addr[$clog2(SCACHE_RAM_DEPTH)-1] ^ scache_cflow_data_rd_ram_addr[$clog2(SCACHE_RAM_DEPTH)-1] ) || !scache_cflow_data_rd_ready_inner ;
    //assign sh_rd_pend =  scache_cflow_ram_rd_en &&  scache_cflow_ram_wr_en && !(scache_cflow_data_wr_ram_addr[$clog2(SCACHE_RAM_DEPTH)-1] ^ scache_cflow_data_rd_ram_addr[$clog2(SCACHE_RAM_DEPTH)-1] )  ;
    
      assign sh_rd_pend =  (| scache_cflow_rd_pend) | (~scache_cflow_data_rd_ready_inner);

      always@(posedge clk or negedge rst_n) begin
           if(!rst_n)
               sh_rd_sta <= 'b0;
           else if(scache_cflow_data_rd_en && !sh_rd_pend)
               sh_rd_sta <= 'b1;
           else if(scache_cflow_data_rd_done && !sh_rd_pend )
               sh_rd_sta <= 'b0;
      end

       always@(posedge clk or negedge rst_n ) begin
       if(!rst_n ) begin
            scache_cflow_data_rd_sub_len_cnt_tmp      <= 'b0    ;
            scache_cflow_data_rd_ram_addr_signed      <= 'b0    ;  
            scache_cflow_data_rd_sys_len_cnt_tmp      <= 'b0    ;
            scache_cflow_data_rd_sign_ext_r           <= 'b0    ;
            scache_cflow_data_rd_size_r               <= 'b0    ;
       end
       else if(scache_cflow_data_rd_en) begin
            scache_cflow_data_rd_sub_len_cnt_tmp      <= 'b0    ;
            scache_cflow_data_rd_ram_addr_signed      <= {1'b0, scache_cflow_data_rd_dst_addr   } ;  
            scache_cflow_data_rd_sys_len_cnt_tmp      <= 'b0    ;
            scache_cflow_data_rd_sign_ext_r           <= scache_cflow_data_rd_sign_ext    ;
            scache_cflow_data_rd_size_r               <= scache_cflow_data_rd_size    ;
       end
       else if(sh_rd_sta && !sh_rd_pend) begin          //read L1b, dirtect to generate address
            if(scache_cflow_data_rd_sub_len_cnt_tmp == scache_cflow_data_rd_sub_len_sub1 ) begin
                   scache_cflow_data_rd_sub_len_cnt_tmp  <=  0    ;

                if(scache_cflow_data_rd_sys_len_cnt_tmp ==  scache_cflow_data_rd_sys_len_sub1 ) begin
                   scache_cflow_data_rd_ram_addr_signed  <= scache_cflow_data_rd_dst_addr ;
                   scache_cflow_data_rd_sys_len_cnt_tmp  <= 0;
                   end
                else begin
                   scache_cflow_data_rd_sys_len_cnt_tmp  <=  scache_cflow_data_rd_sys_len_cnt_tmp  +  1;
                   scache_cflow_data_rd_ram_addr_signed  <=  scache_cflow_data_rd_ram_addr_signed + scache_cflow_data_rd_sys_gap ;  
                   end
           end 
            else begin
                scache_cflow_data_rd_sub_len_cnt_tmp     <= scache_cflow_data_rd_sub_len_cnt_tmp  +  1;
                scache_cflow_data_rd_ram_addr_signed     <= scache_cflow_data_rd_ram_addr_signed + scache_cflow_data_rd_sub_gap ;
                scache_cflow_data_rd_sys_len_cnt_tmp     <= scache_cflow_data_rd_sys_len_cnt_tmp ;
            end
         end
    end

   always_comb begin
    if(!scache_lut_mode) begin
      if(sh_rd_sta  ) begin          //read L1b, dirtect to generate address
                scache_cflow_ram_rd_en          = 'b1 ;  //read 

          if((scache_cflow_data_rd_sub_len_cnt_tmp == scache_cflow_data_rd_sub_len_sub1)&&(scache_cflow_data_rd_sys_len_cnt_tmp == scache_cflow_data_rd_sys_len_sub1 ))
                scache_cflow_data_rd_done       = 'b1 ;
           else
                scache_cflow_data_rd_done       = 'b0 ;

       end
       else begin
                scache_cflow_ram_rd_en          = 'b0 ;
                scache_cflow_data_rd_done       = 'b0 ;
       end
    end
    else begin  //lut mode
        scache_cflow_ram_rd_en          = scache_cflow_data_wr_valid       ;
        scache_cflow_data_rd_done       = 'b0 ;
    end
   end


   reg [2:0] scache_cflow_data_rd_done_dly;
    always@(posedge clk or negedge rst_n ) begin
       if(!rst_n ) 
            scache_cflow_data_rd_done_dly <= 'b0;
        else
            scache_cflow_data_rd_done_dly <= { scache_cflow_data_rd_done_dly[1:0], scache_cflow_data_rd_done};
    end
   
   assign scache_cflow_data_rd2l2_last =  scache_cflow_data_rd_done_dly[1];



    always@(posedge clk or negedge rst_n ) begin
       if(!rst_n ) 
        scache_cflow_data_rd_st_rdy <= 'b1 ;
      else if(scache_cflow_data_rd_en)
        scache_cflow_data_rd_st_rdy <= 'b0 ;
      else if(scache_cflow_data_rd2l2_last)
        scache_cflow_data_rd_st_rdy <= 'b1 ;
    end

//---------------------------------------shram--------------------------------------------//
wire   [1:0] cflow_ram_we ;
wire   [1:0] cflow_ram_re ;
wire   [1:0] instr_ram_en ;
wire   [1:0] instr_ram_we ;
wire   [1:0] instr_ram_re ;

  


assign  instr_ram_en[0]  = scache_data_req && !scache_data_addr[$clog2(SCACHE_RAM_WDEPTH)-1] ;
assign  instr_ram_en[1]  = scache_data_req &&  scache_data_addr[$clog2(SCACHE_RAM_WDEPTH)-1] ;

assign  instr_ram_re[0]  = instr_ram_en[0] && !scache_data_we ;
assign  instr_ram_re[1]  = instr_ram_en[1] && !scache_data_we ;

assign  instr_ram_we[0]  = instr_ram_en[0] &&  scache_data_we ;
assign  instr_ram_we[1]  = instr_ram_en[1] &&  scache_data_we ;

assign  cflow_ram_we[0]  =  scache_cflow_ram_wr_en && ( scache_lut_mode? !scache_lut_ram_sel : !scache_cflow_data_wr_ram_addr[$clog2(SCACHE_RAM_DEPTH)-1] ) ;
assign  cflow_ram_we[1]  =  scache_cflow_ram_wr_en && ( scache_lut_mode?  scache_lut_ram_sel :  scache_cflow_data_wr_ram_addr[$clog2(SCACHE_RAM_DEPTH)-1] );

assign  cflow_ram_re[0]  =  scache_lut_mode && !scache_lut_ram_sel ?  scache_cflow_ram_rd_en : scache_cflow_ram_rd_en && !scache_cflow_data_rd_ram_addr[$clog2(SCACHE_RAM_DEPTH)-1] ;
assign  cflow_ram_re[1]  =  scache_lut_mode &&  scache_lut_ram_sel ?  scache_cflow_ram_rd_en : scache_cflow_ram_rd_en &&  scache_cflow_data_rd_ram_addr[$clog2(SCACHE_RAM_DEPTH)-1] ;

assign scache_cflow_rd_pend[0] =  cflow_ram_we[0]  && cflow_ram_re[0] ;
assign scache_cflow_rd_pend[1] =  cflow_ram_we[1]  && cflow_ram_re[1] ;

assign scache_cflow_ram_en[0]   = cflow_ram_we[0] || ( cflow_ram_re[0]&& scache_cflow_data_rd_ready_inner) || instr_ram_en[0] ;
assign scache_cflow_ram_en[1]   = cflow_ram_we[1] || ( cflow_ram_re[1]&& scache_cflow_data_rd_ready_inner) || instr_ram_en[1] ;


assign  scache_cflow_ram_we[0]  =  instr_ram_en[0] ?  scache_data_we :  cflow_ram_we[0] ;
assign  scache_cflow_ram_we[1]  =  instr_ram_en[1] ?  scache_data_we :  cflow_ram_we[1] ;

assign  scache_cflow_ram_addr[0] = instr_ram_en[0] ? scache_data_addr: ( cflow_ram_we[0] ? scache_cflow_data_wr_ram_addr[$clog2(SCACHE_RAM_DEPTH)-2:2] : scache_cflow_data_rd_ram_addr[$clog2(SCACHE_RAM_DEPTH)-2:2]  );
assign  scache_cflow_ram_addr[1] = instr_ram_en[1] ? scache_data_addr: ( cflow_ram_we[1] ? scache_cflow_data_wr_ram_addr[$clog2(SCACHE_RAM_DEPTH)-2:2] : scache_cflow_data_rd_ram_addr[$clog2(SCACHE_RAM_DEPTH)-2:2]  );

//bitmask
logic [3:0] scache_cflow_ram_bm_inmd;


always_comb begin
     case(scache_cflow_data_wr_size_r)
      BYTE :
          scache_cflow_ram_bm_inmd  =  4'b0001 << scache_cflow_data_wr_ram_addr[1:0];
      HWRD :                 
          scache_cflow_ram_bm_inmd  =  4'b0011 << scache_cflow_data_wr_ram_addr[1];
      WORD :                 
          scache_cflow_ram_bm_inmd  =  4'b1111;
  default: scache_cflow_ram_bm_inmd =  4'b1111;
  endcase
end

assign scache_cflow_ram_bm[0] =  instr_ram_we[0] ? scache_data_be : scache_cflow_ram_bm_inmd;
assign scache_cflow_ram_bm[1] =  instr_ram_we[1] ? scache_data_be : scache_cflow_ram_bm_inmd;

//wr data
always_comb
    if(instr_ram_we[0])
                     scache_cflow_ram_wr_data[0]  = scache_data_sfu_hw_offset == 'b1 ?  scache_data_wdata<<16  : scache_data_wdata  ;
else begin
  case(scache_cflow_data_wr_size_r)
      BYTE : begin
          case(scache_cflow_data_wr_ram_addr[1:0])
              2'b11: scache_cflow_ram_wr_data[0]  =  scache_cflow_data_wr_data_inner << 24 ;
              2'b10: scache_cflow_ram_wr_data[0]  =  scache_cflow_data_wr_data_inner << 16 ;
              2'b01: scache_cflow_ram_wr_data[0]  =  scache_cflow_data_wr_data_inner << 8  ;
              2'b00: scache_cflow_ram_wr_data[0]  =  scache_cflow_data_wr_data_inner << 0  ;
          endcase
      end
      HWRD : begin
          case(scache_cflow_data_wr_ram_addr[1])
               1'b1: scache_cflow_ram_wr_data[0]  =  scache_cflow_data_wr_data_inner << 16  ;
               1'b0: scache_cflow_ram_wr_data[0]  =  scache_cflow_data_wr_data_inner << 0   ;
          endcase                               
       end                                      
      WORD :         scache_cflow_ram_wr_data[0]  =  scache_cflow_data_wr_data_inner        ;
    default:         scache_cflow_ram_wr_data[0]  =  scache_cflow_data_wr_data_inner        ;
  endcase
end

always_comb
    if(instr_ram_we[1])
                     scache_cflow_ram_wr_data[1]  =  scache_data_sfu_hw_offset == 'b1 ?  scache_data_wdata<<16  : scache_data_wdata  ;
else begin
  case(scache_cflow_data_wr_size_r)
      BYTE : begin
          case(scache_cflow_data_wr_ram_addr[1:0])
              2'b11: scache_cflow_ram_wr_data[1]  =  scache_cflow_data_wr_data_inner << 24 ;
              2'b10: scache_cflow_ram_wr_data[1]  =  scache_cflow_data_wr_data_inner << 16 ;
              2'b01: scache_cflow_ram_wr_data[1]  =  scache_cflow_data_wr_data_inner << 8  ;
              2'b00: scache_cflow_ram_wr_data[1]  =  scache_cflow_data_wr_data_inner << 0  ;
          endcase
      end
      HWRD : begin
          case(scache_cflow_data_wr_ram_addr[1])
               1'b1: scache_cflow_ram_wr_data[1]  =  scache_cflow_data_wr_data_inner << 16  ;
               1'b0: scache_cflow_ram_wr_data[1]  =  scache_cflow_data_wr_data_inner << 0   ;
          endcase                               
       end                                      
      WORD :         scache_cflow_ram_wr_data[1]  =  scache_cflow_data_wr_data_inner        ;
    default:         scache_cflow_ram_wr_data[1]  =  scache_cflow_data_wr_data_inner        ;
  endcase
end

//-----------------------------------------------------------------//

logic scache_cflow_ram_rd_en_dly ;

always@(posedge clk or negedge rst_n ) begin
    if(!rst_n)
        scache_cflow_ram_rd_en_dly <= 'b0;
    else  if(scache_cflow_data_rd_ready_inner)
        scache_cflow_ram_rd_en_dly <= ( cflow_ram_re[0]&& !scache_cflow_rd_pend[0]) || (cflow_ram_re[1]&& !scache_cflow_rd_pend[1]); //scache_data_req ? (!scache_data_we) : scache_cflow_ram_rd_en && (!sh_rd_pend) ;
end

    logic [31:0] scache_cflow_ram_rdata_ext;
    logic [31:0] scache_cflow_ram_rdata_wd_ext; //sign extension for words, actually only misaligned assembly
    logic [31:0] scache_cflow_ram_rdata_hw_ext; //sign extension for half words
    logic [31:0] scache_cflow_ram_rdata_bt_ext; //sign extension for bytes

    logic [1:0]  scache_cflow_data_rd_ram_addr_offset ;
    logic        cflow_ram_rd_sel                     ;
    logic        instr_ram_rd_sel                     ;
    logic        instr_ram_rd_en_dly                  ;


    always@(posedge clk or negedge rst_n ) begin
        if(!rst_n) begin
            instr_ram_rd_sel    <= 'b0;
            instr_ram_rd_en_dly <= 'b0;
        end
          else begin
            instr_ram_rd_en_dly <= instr_ram_re[0] || instr_ram_re[1] ;
            if(scache_data_req)   instr_ram_rd_sel <=  instr_ram_re[1];
        end
    end
  
  always@(posedge clk ) 
     if(instr_ram_rd_en_dly )
         scache_data_rdata <= instr_ram_rd_sel ? scache_cflow_ram_rd_data[1] : scache_cflow_ram_rd_data[0];


    //------------------------------------------------------------------------//
    always@(posedge clk or negedge rst_n ) begin
        if(!rst_n) begin
            cflow_ram_rd_sel <= 'b0;
        end
          else if(scache_cflow_ram_rd_en && !sh_rd_pend ) begin
            cflow_ram_rd_sel <=  cflow_ram_re[1];
        end
    end
    //sign extension for words
    wire [SCACHE_RAM_DWID-1:0]  scache_cflow_ram_rd_data_org =  cflow_ram_rd_sel ?  scache_cflow_ram_rd_data[1] :   scache_cflow_ram_rd_data[0] ;

    //---------------------extend-----------------------//
    always@(posedge clk or negedge rst_n ) begin
        if(!rst_n) begin
            scache_cflow_data_rd_ram_addr_offset <= 'b0;
        end
          else if(scache_cflow_ram_rd_en && !sh_rd_pend ) begin
            scache_cflow_data_rd_ram_addr_offset <=  scache_cflow_data_rd_ram_addr[1:0];
        end
    end
    assign scache_cflow_ram_rdata_wd_ext = scache_cflow_ram_rd_data_org ;

   
    //sign extension for half words
    always_comb begin
      case(scache_cflow_data_rd_ram_addr_offset[1]) //scache_cflow_ram_bt_addr[1:0]
        1'b0: begin
          if(scache_cflow_data_rd_sign_ext_r == 1'b0)
            scache_cflow_ram_rdata_hw_ext = {16'h0000, scache_cflow_ram_rd_data_org[15:0]}; //zero ext
          else
            scache_cflow_ram_rdata_hw_ext = {{16{scache_cflow_ram_rd_data_org[15]}}, scache_cflow_ram_rd_data_org[15:0]}; //sign ext
        end

        1'b1: begin
          if(scache_cflow_data_rd_sign_ext_r == 1'b0)
            scache_cflow_ram_rdata_hw_ext = {16'h0000, scache_cflow_ram_rd_data_org[31:16]}; //zero ext
          else
            scache_cflow_ram_rdata_hw_ext = {{16{scache_cflow_ram_rd_data_org[31]}}, scache_cflow_ram_rd_data_org[31:16]};//sign ext
        end
       endcase //case (rdata_offset_q)
    end

    //sign extension for bytes
    always_comb begin
      case(scache_cflow_data_rd_ram_addr_offset)
        2'b00: begin
          if(scache_cflow_data_rd_sign_ext_r == 1'b0)
            scache_cflow_ram_rdata_bt_ext = {24'h00_0000, scache_cflow_ram_rd_data_org[7:0]};  //zero ext
          else
            scache_cflow_ram_rdata_bt_ext = {{24{scache_cflow_ram_rd_data_org[7]}}, scache_cflow_ram_rd_data_org[7:0]};
        end

        2'b01: begin
          if(scache_cflow_data_rd_sign_ext_r == 1'b0)
            scache_cflow_ram_rdata_bt_ext = {24'h00_0000, scache_cflow_ram_rd_data_org[15:8]};
          else
            scache_cflow_ram_rdata_bt_ext = {{24{scache_cflow_ram_rd_data_org[15]}}, scache_cflow_ram_rd_data_org[15:8]};
        end

        2'b10: begin
          if(scache_cflow_data_rd_sign_ext_r == 1'b0)
            scache_cflow_ram_rdata_bt_ext = {24'h00_0000, scache_cflow_ram_rd_data_org[23:16]};
          else
            scache_cflow_ram_rdata_bt_ext = {{24{scache_cflow_ram_rd_data_org[23]}}, scache_cflow_ram_rd_data_org[23:16]};
        end

        2'b11:
        begin
          if(scache_cflow_data_rd_sign_ext_r == 1'b0)
            scache_cflow_ram_rdata_bt_ext = {24'h00_0000, scache_cflow_ram_rd_data_org[31:24]};
          else
            scache_cflow_ram_rdata_bt_ext = {{24{scache_cflow_ram_rd_data_org[31]}}, scache_cflow_ram_rd_data_org[31:24]};
        end
      endcase //case (rdata_offset_q)
    end


    // rdata ext
    always@(posedge clk ) 
    if(scache_cflow_ram_rd_en_dly && scache_cflow_data_rd_ready_inner) begin
        case (scache_cflow_data_rd_size_r)
          WORD    : scache_cflow_data_rd_data <= scache_cflow_ram_rdata_wd_ext;
          HWRD    : scache_cflow_data_rd_data <= scache_cflow_ram_rdata_hw_ext;
          BYTE    : scache_cflow_data_rd_data <= scache_cflow_ram_rdata_bt_ext;  //BYTE_TYPE
          default : scache_cflow_data_rd_data <= scache_cflow_ram_rdata_bt_ext;  //BYTE_TYPE
        endcase
    end

    //read valid
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n)
            scache_cflow_data_rd_valid_inner <= 'b0;
        else if(scache_cflow_data_rd_ready_inner)
            scache_cflow_data_rd_valid_inner <=  scache_cflow_ram_rd_en_dly ;
    end

    always@(posedge clk or negedge rst_n) begin
        if(!rst_n)
            scache_data_rvalid <= 'b0;
        else 
            scache_data_rvalid <=  instr_ram_rd_en_dly ;
    end


   //---------------------------------------------------------------------------------------//


endmodule
