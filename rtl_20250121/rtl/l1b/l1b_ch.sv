module l1b_ch #(
            parameter WORD_WID        = 8                           ,
            parameter LB_CH           = 16                          ,
            parameter DATA_16CH_WID   = WORD_WID * LB_CH            ,   //128bit
            parameter L1B_RAM_DEPTH   = 256                         ,
            parameter NUM_WORDS       = L1B_RAM_DEPTH*4            ,    //depth,byte
            parameter BITMASK_WIDTH   = 16                                      
            )(
   //----------------------------------------------------------------//
   input                                      clk                   ,
   input                                      rst_n                 ,
   input                                      l1b_gpu_mode           ,   //0: tcache 1:cubank
   //------------------------cubank lsu inf--------------------------//
   input                                      cubank_data_req       ,
   input                                      cubank_data_we        ,
   input    [3 : 0]                           cubank_data_be        ,
   input    [31 : 0]                          cubank_data_wdata     ,
   input    [$clog2(NUM_WORDS)-1 : 0]         cubank_data_addr      ,
   output                                     cubank_data_gnt       ,
   output                                     cubank_data_rvalid    ,
   output   [31 : 0]                          cubank_data_rdata     ,

   //---------------------from tcache-----------------------------------//
   input                                      tcache_data_cs        ,
   input                                      tcache_data_data_we   ,
   input   [DATA_16CH_WID-1 : 0]              tcache_data_wdata     ,
   input   [BITMASK_WIDTH-1 : 0]              tcache_data_bitmask   ,
   input   [$clog2(L1B_RAM_DEPTH)-1 : 0]      tcache_data_addr      ,
   output  [DATA_16CH_WID-1 : 0]              tcache_data_rdata     ,
   output                                     tcache_data_rvalid

     );
    
   //---------------------from cubank-----------------------------------//
   wire                                     l1b_cubank_cs              ;
   wire                                     l1b_cubank_data_we         ;
   wire  [DATA_16CH_WID-1 : 0]              l1b_cubank_wdata           ;
   wire  [BITMASK_WIDTH-1 : 0]              l1b_cubank_bitmask         ;
   wire  [$clog2(L1B_RAM_DEPTH)-1 : 0]      l1b_cubank_addr            ;
   wire  [DATA_16CH_WID-1 : 0]              l1b_cubank_rdata           ;
   wire                                     l1b_cubank_rvalid          ;

    logic [1:0] cubank_data_addr_r0,cubank_data_addr_r1;

//-----------------------------------------------------------------------------------//
//----------------------------ALU  LSU protocol--------------------------------------//
//-----------------------------------------------------------------------------------//
    
    assign  l1b_cubank_cs       =  cubank_data_req        ;
    assign  l1b_cubank_data_we  =  cubank_data_we         ; 
    assign  l1b_cubank_wdata    =  cubank_data_wdata << (cubank_data_addr[1:0]*32);//mod by jiangyz
    assign  l1b_cubank_addr     =  cubank_data_addr[2+:$clog2(L1B_RAM_DEPTH)] ;
    assign  cubank_data_rdata  =  l1b_cubank_rdata  >>  (cubank_data_addr_r1[1:0]*32);//mod by jiangyz
    assign  cubank_data_rvalid =  l1b_cubank_rvalid       ;


    assign  l1b_cubank_bitmask = cubank_data_be << {cubank_data_addr[1:0],2'b00} ;
    
    assign  cubank_data_gnt = 1'b1; //l1b_gpu_mode ? 1 : 0         ;

    always_ff@(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            cubank_data_addr_r0 <= 2'b0;
            cubank_data_addr_r1 <= 2'b0;
        end
        else begin
            cubank_data_addr_r0 <= cubank_data_addr[1:0];
            cubank_data_addr_r1 <= cubank_data_addr_r0;
        end
    end


l1b_ch_ram_wrapper U_l1b_ch_ram_wrapper(
.clk                                    (clk                      ),
.rst_n                                  (rst_n                    ),
.l1b_gpu_mode                             (l1b_gpu_mode               ), //0: tcache 1:cubank
.l1b_cubank_cs                           (l1b_cubank_cs             ),
.l1b_cubank_data_we                      (l1b_cubank_data_we        ),
.l1b_cubank_wdata                        (l1b_cubank_wdata          ),
.l1b_cubank_bitmask                      (l1b_cubank_bitmask        ),
.l1b_cubank_addr                         (l1b_cubank_addr           ),
.l1b_cubank_rdata                        (l1b_cubank_rdata          ),
.l1b_cubank_rvalid                       (l1b_cubank_rvalid         ),
.l1b_tcache_cs                           (tcache_data_cs           ),
.l1b_tcache_data_we                      (tcache_data_data_we      ),
.l1b_tcache_wdata                        (tcache_data_wdata        ),
.l1b_tcache_bitmask                      (tcache_data_bitmask      ),
.l1b_tcache_addr                         (tcache_data_addr         ),
.l1b_tcache_rdata                        (tcache_data_rdata        ),
.l1b_tcache_rvalid                       (tcache_data_rvalid       )
   );
endmodule
