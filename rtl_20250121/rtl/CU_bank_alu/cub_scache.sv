module cub_scache #(
            parameter   SCACHE_RAM_DEPTH  = 64 *  4 * 2 , // tow ram_bank, addrs by byte
            parameter   SCACHE_RAM_WDEPTH  = 64 * 2 , // tow ram_bank, addrs by byte
            parameter   SCACHE_RAM_DWID   = 32
            )(  
   //----------------------------------------------------------------//
   input                                      clk                   ,
   input                                      rst_n                 ,

   //----------------------------------------------------------------//
   //-----------------------wr-----------------------------------------//
   input                                      scache_cflow_data_wr_valid       ,//data flow  from pooling 
   input  [SCACHE_RAM_DWID-1:0]               scache_cflow_data_wr_data        ,
   //output                                     scache_cflow_data_wr_ready     ,
   //instr
   input                                      scache_cflow_data_wr_en          ,
   input  [$clog2(SCACHE_RAM_DEPTH)-1:0 ]     scache_cflow_data_wr_dst_addr    ,  //byte addr, 2*64word*4byte
   //cfg                                 
   input  [1:0 ]                              scache_cflow_data_wr_size        ,  //10: byte 01: half word 00: word
   input  [$clog2(SCACHE_RAM_DEPTH)-1:0 ]     scache_cflow_data_wr_sub_len     ,  //
   input  [$clog2(SCACHE_RAM_DEPTH)-1:0 ]     scache_cflow_data_wr_sub_gap     ,  //
   input  [$clog2(SCACHE_RAM_DEPTH)-1:0 ]     scache_cflow_data_wr_sys_len     ,  //system len 
   input  [$clog2(SCACHE_RAM_DEPTH)  :0 ]     scache_cflow_data_wr_sys_gap    ,  //
   output logic                               scache_cflow_data_wr_done        ,  
        
   //-----------------------rd-----------------------------------------//
   output logic                               scache_cflow_data_rd_valid       ,//data flow to pooling 
   output logic                               scache_cflow_data_rd2l2_last     ,//data flow to pooling 
   output logic [SCACHE_RAM_DWID-1:0]         scache_cflow_data_rd_data        ,
   input                                      scache_cflow_data_rd2l2_ready    ,
   //input                                    scache_cflow_data_rd_ready       ,
   //instr
   input                                      scache_cflow_data_rd_en          ,
   input                                      scache_cflow_data_rd_sign_ext    ,
   input  [$clog2(SCACHE_RAM_DEPTH)-1:0 ]     scache_cflow_data_rd_dst_addr    ,  //byte addr, 2*64word*4byte
   //cfg
   input  [1:0 ]                              scache_cflow_data_rd_size        ,  //10: byte 01: half word 00: word
   input  [$clog2(SCACHE_RAM_DEPTH)-1:0 ]     scache_cflow_data_rd_sub_len     ,  //
   input  [$clog2(SCACHE_RAM_DEPTH)-1:0 ]     scache_cflow_data_rd_sub_gap     ,  //
   input  [$clog2(SCACHE_RAM_DEPTH)-1:0 ]     scache_cflow_data_rd_sys_len     ,  //
   input  [$clog2(SCACHE_RAM_DEPTH)  :0 ]     scache_cflow_data_rd_sys_gap     ,  //
   output logic                               scache_cflow_data_rd_done        ,  
   output logic                               scache_cflow_data_rd_st_rdy      ,  
   //--------------------------------------------------------------------------//
   input                                      scache_rd2l2_mode                ,
   input                                      scache_lut_mode                  ,
   input                                      scache_lut_ram_sel               ,
   input                                      scache_data_req                  ,
   input                                      scache_data_sfu_hw_offset        ,
   input                                      scache_data_we                   ,
   input    [3 : 0]                           scache_data_be                   ,
   input    [31 : 0]                          scache_data_wdata                ,
   input    [$clog2(SCACHE_RAM_WDEPTH)-1 : 0] scache_data_addr                 ,
   output                                     scache_data_gnt                  ,
   output   logic                             scache_data_rvalid               ,
   output logic  [31 : 0]                     scache_data_rdata                
);

   //------------------------ram port------------------------------------------//
   logic[1:0] [SCACHE_RAM_DWID-1:0]              scache_cflow_ram_rd_data      ;   
   logic[1:0] [SCACHE_RAM_DWID-1:0]              scache_cflow_ram_wr_data      ; 
   logic[1:0] [$clog2(SCACHE_RAM_DEPTH)-1-3:0]   scache_cflow_ram_addr         ;  
   logic[1:0]                                    scache_cflow_ram_we           ;
   logic[1:0] [3:0]                              scache_cflow_ram_bm           ;
   logic[1:0]                                    scache_cflow_ram_en           ;


scache_cflow_ctrl #(    
        .SCACHE_RAM_DEPTH  (SCACHE_RAM_DEPTH ), // tow ram_bank, addrs by byte
        .SCACHE_RAM_WDEPTH (SCACHE_RAM_WDEPTH), // tow ram_bank, addrs by byte
        .SCACHE_RAM_DWID   (SCACHE_RAM_DWID  )
            )
    U_scache_cflow_ctrl (  
   .clk                              (clk                              ),
   .rst_n                            (rst_n                            ),
   .scache_cflow_data_wr_valid       (scache_cflow_data_wr_valid       ),//data flow  from pooling 
   .scache_cflow_data_wr_data        (scache_cflow_data_wr_data        ),
   .scache_cflow_data_wr_en          (scache_cflow_data_wr_en          ),
   .scache_cflow_data_wr_dst_addr    (scache_cflow_data_wr_dst_addr    ),  //byte addr, 2*64word*4byte
   .scache_cflow_data_wr_size        (scache_cflow_data_wr_size        ),  //00: byte 01: half word 10: word
   .scache_cflow_data_wr_sub_len     (scache_cflow_data_wr_sub_len     ),  //
   .scache_cflow_data_wr_sub_gap     (scache_cflow_data_wr_sub_gap     ),  //
   .scache_cflow_data_wr_sys_len     (scache_cflow_data_wr_sys_len     ),  //system len 
   .scache_cflow_data_wr_sys_gap     (scache_cflow_data_wr_sys_gap     ),  //
   .scache_cflow_data_wr_done        (scache_cflow_data_wr_done        ),  
   .scache_cflow_data_rd_valid       (scache_cflow_data_rd_valid       ),//data flow to pooling 
   .scache_cflow_data_rd2l2_ready    (scache_cflow_data_rd2l2_ready    ),
   .scache_cflow_data_rd2l2_last     (scache_cflow_data_rd2l2_last     ),
   .scache_cflow_data_rd_data        (scache_cflow_data_rd_data        ),
   .scache_cflow_data_rd_en          (scache_cflow_data_rd_en          ),
   .scache_cflow_data_rd_sign_ext    (scache_cflow_data_rd_sign_ext    ),
   .scache_cflow_data_rd_dst_addr    (scache_cflow_data_rd_dst_addr    ),  //byte addr, 2*64word*4byte
   .scache_cflow_data_rd_size        (scache_cflow_data_rd_size        ),  //00: byte 01: half word 10: word
   .scache_cflow_data_rd_sub_len     (scache_cflow_data_rd_sub_len     ),  //
   .scache_cflow_data_rd_sub_gap     (scache_cflow_data_rd_sub_gap     ),  //
   .scache_cflow_data_rd_sys_len     (scache_cflow_data_rd_sys_len     ),  //
   .scache_cflow_data_rd_sys_gap     (scache_cflow_data_rd_sys_gap     ),  //
   .scache_cflow_data_rd_done        (scache_cflow_data_rd_done        ), 
   .scache_cflow_data_rd_st_rdy      (scache_cflow_data_rd_st_rdy      ),
   .scache_rd2l2_mode                (scache_rd2l2_mode                ),
   .scache_lut_mode                  (scache_lut_mode                  ),
   .scache_lut_ram_sel               (scache_lut_ram_sel               ),
   .scache_data_req                  (scache_data_req                  ),
   .scache_data_sfu_hw_offset        (scache_data_sfu_hw_offset        ),
   .scache_data_we                   (scache_data_we                   ),
   .scache_data_be                   (scache_data_be                   ),
   .scache_data_wdata                (scache_data_wdata                ),
   .scache_data_addr                 (scache_data_addr                 ),
   .scache_data_gnt                  (scache_data_gnt                  ),
   .scache_data_rvalid               (scache_data_rvalid               ),
   .scache_data_rdata                (scache_data_rdata                ),
   .scache_cflow_ram_rd_data         (scache_cflow_ram_rd_data         ),   
   .scache_cflow_ram_wr_data         (scache_cflow_ram_wr_data         ), 
   .scache_cflow_ram_addr            (scache_cflow_ram_addr            ),  
   .scache_cflow_ram_we              (scache_cflow_ram_we              ),
   .scache_cflow_ram_bm              (scache_cflow_ram_bm              ),
   .scache_cflow_ram_en              (scache_cflow_ram_en              )  
);

std_spram64x32_b4 U_scache_ram0 (
    .CLK        (clk        ),
    .CEB        (!scache_cflow_ram_en       [0]),
    .WEB        (!scache_cflow_ram_we       [0]),
    .D          (scache_cflow_ram_wr_data   [0]),
    .A          (scache_cflow_ram_addr      [0]),
    .Q          (scache_cflow_ram_rd_data   [0]),
	.BWEB       (~scache_cflow_ram_bm       [0])
);

std_spram64x32_b4  U_scache_ram1 (
    .CLK        (clk        ),
    .CEB        (!scache_cflow_ram_en       [1]),
    .WEB        (!scache_cflow_ram_we       [1]),
    .D          (scache_cflow_ram_wr_data   [1]),
    .A          (scache_cflow_ram_addr      [1]),
    .Q          (scache_cflow_ram_rd_data   [1]),
	.BWEB       (~scache_cflow_ram_bm       [1])
);

endmodule
