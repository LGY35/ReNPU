module iob_sw (
    
    //-------------------------------------------------------------------------------------//
   input                                                 clk                                ,
   input                                                 rst_n                              ,
   //--------------------------------------------------------------------------------------//
   input                                                 iob_pric                            ,       //1: int16  0: int8
   input                                                 iob_l2c_in_cfg                   ,
   //from cubank scache
   input    [32-1:0][32-1:0]                             CU_bank_data_out                    ,
   input    [4-1 :0][7:0]                                CU_bank_data_out_vld                ,
   output   [32-1:0]                                     CU_bank_data_out_ready              ,
   input    [32-1:0]                                     CU_bank_data_out_last               ,

    //
   output                                               tcache_l2c_datain_vld                ,
   output                                               tcache_l2c_datain_last               ,
   input                                                tcache_l2c_datain_rdy                ,
   output  [256-1:0]                                    tcache_l2c_datain                    ,

    //from l2 noc
    input                                               l2c_datain_vld                       ,
    input                                               l2c_datain_last                      ,
    output logic                                        l2c_datain_rdy                       ,
    input [256-1:0]                                     l2c_datain_data                      ,

    //to l2 noc
   output                                               l2c_dataout_vld                     ,
   output                                               l2c_dataout_last                    ,
   input                                                l2c_dataout_rdy                     ,
   output [256-1:0]                                     l2c_dataout_data                         
   );


    //to l2 noc
   wire                                                iob2l2_dataout_vld                    ;
   wire                                                iob2l2_dataout_last                   ;
   wire                                                iob2l2_dataout_rdy                    ;
   wire [256-1:0]                                      iob2l2_dataout_data                   ;

   wire                                                iob2l2_datain_vld                     ;
   wire                                                iob2l2_datain_last                    ;
   wire                                                iob2l2_datain_rdy                     ;
   wire [256-1:0]                                      iob2l2_datain_data                    ;


     bwd_pipe     #( .DATA_W ( 256 ))
    U_iob2l2_dataout_pipe
    (
    .clk                    (clk    ),
    .rst_n                  (rst_n  ),
    //from/to master
    .f_valid_in             (iob2l2_dataout_vld   ),
    .f_data_in              (iob2l2_dataout_data  ),
    .f_ready_out            (iob2l2_dataout_rdy   ),
    //from/to slave
    .b_valid_out            (l2c_dataout_vld     ),
    .b_data_out             (l2c_dataout_data    ),
    .b_ready_in             (l2c_dataout_rdy     )
    );

    logic [3:0][8-1:0][7:0]    iob_sw_data_data ;
    logic                      iob_sw_data_vld  ;
    logic                      iob_sw_data_rdy  ; 
    logic                      iob_sw_data_last ;

   assign  l2c_dataout_last = 1'b0;

   //l2 in to 0:tc 1:iob
  datapath_dst_mux2 #(
                            .DWID    ( 8 ),
                            .CH_NUM  ( 32 ))
   U_l2_out_datapath (
     .S             (iob_l2c_in_cfg             ), //1: broadcast    0: other
     .Z0_ready      (iob2l2_dataout_rdy        ),
     .Z0_valid      (iob2l2_dataout_vld        ),
     .Z0_last       (iob2l2_dataout_last       ),
     .Z0_data       (iob2l2_dataout_data       ),
     .Z1_ready      (iob2l2_datain_rdy         ),
     .Z1_valid      (iob2l2_datain_vld         ),
     .Z1_last       (iob2l2_datain_last        ),
     .Z1_data       (iob2l2_datain_data        ),
     .A_ready       (iob_sw_data_rdy           ),
     .A_valid       (iob_sw_data_vld           ),
     .A_last        (iob_sw_data_last          ),
     .A_data        (iob_sw_data_data          )
    );

wire            l2c_datain_rdy_w       ; 
wire            l2c_datain_vld_w       ;
wire            l2c_datain_last_w      ;
wire  [255:0]   l2c_datain_data_w      ;


fwd_pipe #(.DATA_W(257))
 U_l2c_datain_pipe_       (
.clk        (clk        ),
.rst_n      (rst_n      ),
.f_valid_in (l2c_datain_vld                      ),
.f_data_in  ({l2c_datain_data,l2c_datain_last}   ),
.f_ready_out(l2c_datain_rdy                      ),
.b_valid_out(l2c_datain_vld_w                         ),
.b_data_out ({l2c_datain_data_w,l2c_datain_last_w}      ),
.b_ready_in (l2c_datain_rdy_w                         )
);

//sc to  0:iob 1:l2 out
 datapath_src_mux2 #(
                            .DWID    ( 8 ),
                            .CH_NUM  ( 32 ))
   U_sc_l2c_in_datapath (
     .S            (iob_l2c_in_cfg           ), //1: broadcast    0: other
     .A_ready      (l2c_datain_rdy_w           ),
     .A_valid      (l2c_datain_vld_w           ),
     .A_last       (l2c_datain_last_w & l2c_datain_vld_w      ),
     .A_data       (l2c_datain_data_w          ),
     .B_ready      (iob2l2_datain_rdy        ),
     .B_valid      (iob2l2_datain_vld        ),
     .B_last       (iob2l2_datain_last       ),
     .B_data       (iob2l2_datain_data       ),
     .Z_ready      (tcache_l2c_datain_rdy    ),
     .Z_valid      (tcache_l2c_datain_vld    ),
     .Z_last       (tcache_l2c_datain_last   ),
     .Z_data       (tcache_l2c_datain        )
    );



    

    logic [3:0]                iob_sw_data_vld_4ch  ;

    wire   [3:0]               iob_sw_data_vld_left_16bank  = {2{|CU_bank_data_out_vld[3],|CU_bank_data_out_vld[2]}};
    wire   [3:0]               iob_sw_data_vld_right_16bank = {2{|CU_bank_data_out_vld[1],|CU_bank_data_out_vld[0]}};
    wire   [3:0]               iob_sw_data_vld_all_32bank   = {|CU_bank_data_out_vld[3],|CU_bank_data_out_vld[2],|CU_bank_data_out_vld[1],|CU_bank_data_out_vld[0]} ; 


    assign iob_sw_data_vld_4ch = iob_pric ? ( |iob_sw_data_vld_left_16bank ? iob_sw_data_vld_left_16bank : iob_sw_data_vld_right_16bank ): iob_sw_data_vld_all_32bank ;
                                                              

    always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        iob_sw_data_last <= 'b0;
    else if(iob_sw_data_rdy)
        iob_sw_data_last <= |CU_bank_data_out_last;
    end


    always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        iob_sw_data_vld <= 'b0;
    else if(iob_sw_data_rdy)
        iob_sw_data_vld <= |iob_sw_data_vld_4ch;
    end
 
    reg    [16-1:0][16-1:0]        CU_bank_data_out_w16 ;
    reg    [32-1:0][8-1:0]        CU_bank_data_out_w8  ;

   // int i,j;

    always_comb begin
        foreach(CU_bank_data_out_w16[i])
            CU_bank_data_out_w16[i] = |iob_sw_data_vld_left_16bank ? CU_bank_data_out[(i+16)][15:0] : CU_bank_data_out[i][15:0];
        foreach(CU_bank_data_out_w8[j])
            CU_bank_data_out_w8[j] =  CU_bank_data_out[j][7:0];
    end



    always@(posedge clk) begin
        foreach(iob_sw_data_data[i]) begin
            if((iob_sw_data_vld_4ch[i])&&iob_sw_data_rdy) //64bit
                iob_sw_data_data[i] <= iob_pric ?  CU_bank_data_out_w16[i*4+:4] : CU_bank_data_out_w8[i*8+:8] ;
        end
    end


assign  CU_bank_data_out_ready = {32{iob_sw_data_rdy}};




endmodule 
