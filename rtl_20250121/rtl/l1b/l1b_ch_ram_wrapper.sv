module l1b_ch_ram_wrapper #(
            parameter WORD_WID        = 8                           ,
            parameter LB_CH           = 16                          ,
            parameter DATA_16CH_WID   = WORD_WID * LB_CH            ,   //128bit
            parameter L1B_RAM_DEPTH   = 256                         ,
            parameter BITMASK_WIDTH   = 16                                      
            )(
   //----------------------------------------------------------------//
   input                                      clk                   ,
   input                                      rst_n                 ,
   input                                      l1b_gpu_mode            ,           //0: tcache 1:cubank
   //---------------------from cubank-----------------------------------//
   input                                      l1b_cubank_cs           ,
   input                                      l1b_cubank_data_we      ,
   input   [DATA_16CH_WID-1 : 0]              l1b_cubank_wdata        ,
   input   [BITMASK_WIDTH-1 : 0]              l1b_cubank_bitmask      ,
   input   [$clog2(L1B_RAM_DEPTH)-1 : 0]      l1b_cubank_addr         ,
   output  [DATA_16CH_WID-1 : 0]              l1b_cubank_rdata        ,
   output                                     l1b_cubank_rvalid       ,            
   //---------------------from tcache-----------------------------------//
   input                                      l1b_tcache_cs           ,
   input                                      l1b_tcache_data_we      ,
   input   [DATA_16CH_WID-1 : 0]              l1b_tcache_wdata        ,
   input   [BITMASK_WIDTH-1 : 0]              l1b_tcache_bitmask      ,
   input   [$clog2(L1B_RAM_DEPTH)-1 : 0]      l1b_tcache_addr         ,
   //output                                     l1b_tcache_ready        ,  
   output  [DATA_16CH_WID-1 : 0]              l1b_tcache_rdata        ,
   output                                     l1b_tcache_rvalid                   
   );
    
    //
   wire                                       l1b_ch_ram_cs              ;
   wire                                       l1b_ch_ram_data_we      ;
   wire  [DATA_16CH_WID-1 : 0]                l1b_ch_ram_wdata          ;
   wire  [BITMASK_WIDTH-1 : 0]                l1b_ch_ram_bitmask         ;
   wire  [DATA_16CH_WID-1 : 0]                l1b_ch_ram_rdata         ;
   wire  [$clog2(L1B_RAM_DEPTH)-1 : 0]        l1b_ch_ram_addr            ;
    //
    //
    //
    //
    reg     [DATA_16CH_WID-1 : 0]            ram_rdata_r        ;
    reg                                      ram_cubank_rvalid_r       ;
    reg                                      ram_tcache_rvalid_r       ;
    //
  //  assign          l1b_ch_ram_cs            = l1b_gpu_mode ?  l1b_cubank_cs            :   l1b_tcache_cs            ;
  //  assign          l1b_ch_ram_data_we       = l1b_gpu_mode ?  l1b_cubank_data_we       :   l1b_tcache_data_we       ;
  //  assign          l1b_ch_ram_wdata         = l1b_gpu_mode ?  l1b_cubank_wdata         :   l1b_tcache_wdata         ;
  //  assign          l1b_ch_ram_bitmask       = l1b_gpu_mode ?  l1b_cubank_bitmask       :   l1b_tcache_bitmask       ;
  //  assign          l1b_ch_ram_addr          = l1b_gpu_mode ?  l1b_cubank_addr          :   l1b_tcache_addr          ;

      assign          l1b_ch_ram_cs            =                  l1b_cubank_cs            ||   l1b_tcache_cs            ;
      assign          l1b_ch_ram_data_we       = l1b_cubank_cs ?  l1b_cubank_data_we       :   l1b_tcache_data_we       ;
      assign          l1b_ch_ram_wdata         = l1b_cubank_cs ?  l1b_cubank_wdata         :   l1b_tcache_wdata         ;
      assign          l1b_ch_ram_bitmask       = l1b_cubank_cs ?  l1b_cubank_bitmask       :   l1b_tcache_bitmask       ;
      assign          l1b_ch_ram_addr          = l1b_cubank_cs ?  l1b_cubank_addr          :   l1b_tcache_addr          ;

    assign          l1b_tcache_rdata       =  ram_rdata_r    ;
    assign          l1b_cubank_rdata       =  ram_rdata_r    ;



    assign           l1b_cubank_rvalid     = ram_cubank_rvalid_r      ;
    assign           l1b_tcache_rvalid     = ram_tcache_rvalid_r      ;
    
    reg ram_rvalid_src_r;
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            ram_rvalid_src_r <= 1'b0;
        end
        else begin
            ram_rvalid_src_r <=  l1b_cubank_cs; //1:cubank req 0:tcache req
        end
    end

    //-----------------------------------------------------------------//
    reg  ram_rvalid_r ;

    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            ram_rvalid_r <= 1'b0;
        end
        else begin
            ram_rvalid_r <= l1b_ch_ram_cs & !l1b_ch_ram_data_we ;
        end
    end


    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            ram_cubank_rvalid_r <= 1'b0;
            ram_tcache_rvalid_r <= 1'b0;
        end
        else begin
            ram_cubank_rvalid_r <= ram_rvalid_r &  ram_rvalid_src_r ;
            ram_tcache_rvalid_r <= ram_rvalid_r & !ram_rvalid_src_r ;
        end
    end

    always@(posedge clk ) begin
        if(ram_rvalid_r)
            ram_rdata_r <= l1b_ch_ram_rdata;
    end
    


    std_spram256x128_b16 U_l1b_ch_ram(
	.CLK     (    clk                    ),
	.CEB     (    ~l1b_ch_ram_cs          ),
	.WEB     (    ~l1b_ch_ram_data_we  ),
	.A       (    l1b_ch_ram_addr         ),
	.D       (    l1b_ch_ram_wdata       ),
	.Q       (    l1b_ch_ram_rdata      ),
	.BWEB    (    ~l1b_ch_ram_bitmask      )
    );


endmodule
