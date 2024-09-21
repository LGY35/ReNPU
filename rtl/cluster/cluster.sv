module cluster #(

    localparam DATA_FIFO_DEPTH      = 64 ,  

    localparam DATA_FIFO_CNT_WID    = 6+1,

    localparam ADDR_FIFO_DEPTH      = 32 ,

    localparam ADDR_FIFO_CNT_WID    = 5+1,


    //数据AXI   —— 2个 AXI 
    localparam D_AXI_DATA_WID       = 256,

    localparam D_AXI_ADDR_WID       = 32 ,

    localparam D_AXI_IDW            = 4  ,  //AXI ID宽度

    localparam D_AXI_LENW           = 4  ,  // AXI 长度字段宽度

    localparam D_AXI_LOCKW          = 2  ,  // AXI 锁字段宽度

    localparam D_AXI_STRBW          = 32 ,  // AXI 写数据选通宽度


    //指令AXI
    localparam AXI_DW               = 128,

    localparam AXI_AW               = 32,

    localparam STRB_WIDTH           = (AXI_DW/8),   // AXI 字节宽度

    localparam ID_WIDTH             = 8,

    localparam AXI_LENW             = 4,

    localparam AXI_LOCKW            = 1,

    localparam I_FLIT_WIDTH         = 32





    // localparam AXI4_ADDRESS_WIDTH   = 32,

    // localparam AXI4_RDATA_WIDTH     = 32,

    // localparam AXI4_WDATA_WIDTH     = 32,

    // localparam AXI4_ID_WIDTH        = 8,

    // localparam AXI4_USER_WIDTH      = 1,

    // localparam AXI_NUMBYTES         = AXI4_WDATA_WIDTH/8,

    // localparam BUFF_DEPTH_SLAVE     = 4,

    // localparam APB_ADDR_WIDTH       = 12

)

(

    input                                   clk,

    input                                   rst_n,



    //data

    output  [1:0]                           d_arvalid,

    output  [1:0][D_AXI_IDW-1:0]            d_arid   ,

    output  [1:0][D_AXI_ADDR_WID-1:0]       d_araddr ,

    output  [1:0][D_AXI_LENW-1:0]           d_arlen  ,

    output  [1:0][2:0]                      d_arsize ,

    output  [1:0][1:0]                      d_arburst,

    output  [1:0][D_AXI_LOCKW-1:0]          d_arlock ,

    output  [1:0][3:0]                      d_arcache,

    output  [1:0][2:0]                      d_arprot ,

    input   [1:0]                           d_arready,

    input   [1:0]                           d_rvalid ,

    input   [1:0][D_AXI_IDW-1:0]            d_rid    ,

    input   [1:0]                           d_rlast  ,

    input   [1:0][D_AXI_DATA_WID-1:0]       d_rdata  ,

    input   [1:0][1:0]                      d_rresp  ,

    output  [1:0]                           d_rready ,

    output  [1:0]                           d_awvalid,

    output  [1:0][D_AXI_IDW-1:0]            d_awid   ,

    output  [1:0][D_AXI_ADDR_WID-1:0]       d_awaddr ,

    output  [1:0][D_AXI_LENW-1:0]           d_awlen  ,

    output  [1:0][2:0]                      d_awsize ,

    output  [1:0][1:0]                      d_awburst,

    output  [1:0][D_AXI_LOCKW-1:0]          d_awlock ,

    output  [1:0][3:0]                      d_awcache,

    output  [1:0][2:0]                      d_awprot ,

    input   [1:0]                           d_awready,

    output  [1:0]                           d_wvalid ,

    output  [1:0][D_AXI_IDW-1:0]            d_wid    ,

    output  [1:0]                           d_wlast  ,

    output  [1:0][D_AXI_DATA_WID-1:0]       d_wdata  ,

    output  [1:0][D_AXI_STRBW-1:0]          d_wstrb  ,

    input   [1:0]                           d_wready ,

    input   [1:0]                           d_bvalid ,

    input   [1:0][D_AXI_IDW-1:0]            d_bid    ,

    input   [1:0][1:0]                      d_bresp  ,

    output  [1:0]                           d_bready ,

    //instruction & control



    // AXI slave port

    input   [ID_WIDTH-1:0]                  s_axi_awid,

    input   [AXI_AW-1:0]                    s_axi_awaddr,

    input   [7:0]                           s_axi_awlen,

    input   [2:0]                           s_axi_awsize,

    input   [1:0]                           s_axi_awburst,

    input                                   s_axi_awlock,

    input   [3:0]                           s_axi_awcache,

    input   [2:0]                           s_axi_awprot,

    input                                   s_axi_awvalid,

    output                                  s_axi_awready,

    input   [AXI_DW-1:0]                    s_axi_wdata,

    input   [STRB_WIDTH-1:0]                s_axi_wstrb,

    input                                   s_axi_wlast,

    input                                   s_axi_wvalid,

    output                                  s_axi_wready,

    output  [ID_WIDTH-1:0]                  s_axi_bid,

    output  [1:0]                           s_axi_bresp,

    output                                  s_axi_bvalid,

    input                                   s_axi_bready,

    input   [ID_WIDTH-1:0]                  s_axi_arid,

    input   [AXI_AW-1:0]                    s_axi_araddr,

    input   [7:0]                           s_axi_arlen,

    input   [2:0]                           s_axi_arsize,

    input   [1:0]                           s_axi_arburst,

    input                                   s_axi_arlock,

    input   [3:0]                           s_axi_arcache,

    input   [2:0]                           s_axi_arprot,

    input                                   s_axi_arvalid,

    output                                  s_axi_arready,

    output  [ID_WIDTH-1:0]                  s_axi_rid,

    output  [AXI_DW-1:0]                    s_axi_rdata,

    output  [1:0]                           s_axi_rresp,

    output                                  s_axi_rlast,

    output                                  s_axi_rvalid,

    input                                   s_axi_rready,



    //dma axi master interface

    output                                  m_arvalid,

    output [ID_WIDTH-1:0]                   m_arid   ,

    output [AXI_AW-1:0]                     m_araddr ,

    output [AXI_LENW-1:0]                   m_arlen  ,

    output [2:0]                            m_arsize ,

    output [1:0]                            m_arburst,

    output [AXI_LOCKW-1:0]                  m_arlock ,

    output [3:0]                            m_arcache,

    output [2:0]                            m_arprot ,

    input                                   m_arready,

    input                                   m_rvalid ,

    input  [ID_WIDTH-1:0]                   m_rid    ,

    input                                   m_rlast  ,

    input  [AXI_DW-1:0]                     m_rdata  ,

    input  [1:0]                            m_rresp  ,

    output                                  m_rready ,



    // config AXI slave port

    // input   [AXI4_ID_WIDTH-1:0]             cfg_awid,

    // input   [AXI4_ADDRESS_WIDTH-1:0]        cfg_awaddr,

    // input   [7:0]                           cfg_awlen,

    // input   [2:0]                           cfg_awsize,

    // input   [1:0]                           cfg_awburst,

    // input                                   cfg_awlock,

    // input   [3:0]                           cfg_awcache,

    // input   [2:0]                           cfg_awprot,

    // input                                   cfg_awvalid,

    // output                                  cfg_awready,

    // input   [AXI4_WDATA_WIDTH-1:0]          cfg_wdata,

    // input   [AXI_NUMBYTES-1:0]              cfg_wstrb,

    // input                                   cfg_wlast,

    // input                                   cfg_wvalid,

    // output                                  cfg_wready,

    // output  [AXI4_ID_WIDTH-1:0]             cfg_bid,

    // output  [1:0]                           cfg_bresp,

    // output                                  cfg_bvalid,

    // input                                   cfg_bready,

    // input   [AXI4_ID_WIDTH-1:0]             cfg_arid,

    // input   [AXI4_ADDRESS_WIDTH-1:0]        cfg_araddr,

    // input   [7:0]                           cfg_arlen,

    // input   [2:0]                           cfg_arsize,

    // input   [1:0]                           cfg_arburst,

    // input                                   cfg_arlock,

    // input   [3:0]                           cfg_arcache,

    // input   [2:0]                           cfg_arprot,

    // input                                   cfg_arvalid,

    // output                                  cfg_arready,

    // output  [AXI4_ID_WIDTH-1:0]             cfg_rid,

    // output  [AXI4_RDATA_WIDTH-1:0]          cfg_rdata,

    // output  [1:0]                           cfg_rresp,

    // output                                  cfg_rlast,

    // output                                  cfg_rvalid,

    // input                                   cfg_rready,



    input      [11:0]                       cfg_apb_PADDR,

    input      [0:0]                        cfg_apb_PSEL,

    input                                   cfg_apb_PENABLE,

    output                                  cfg_apb_PREADY,

    input                                   cfg_apb_PWRITE,

    input      [3:0]                        cfg_apb_PSTRB,

    input      [2:0]                        cfg_apb_PPROT,

    input      [31:0]                       cfg_apb_PWDATA,

    output     [31:0]                       cfg_apb_PRDATA,

    output                                  cfg_apb_PSLVERR,



    output                                  i_interrupt

);



localparam NODES        = 16;

localparam CHANNELS     = 2;

localparam FLIT_WIDTH   = 256;

localparam X            = 4;

localparam Y            = 4;



logic   [NODES-1:0][CHANNELS-1:0][FLIT_WIDTH-1:0]   in_flit;

logic   [NODES-1:0][CHANNELS-1:0]                   in_last;

logic   [NODES-1:0][CHANNELS-1:0]                   in_valid;

logic   [NODES-1:0][CHANNELS-1:0]                   in_ready;



logic   [NODES-1:0][CHANNELS-1:0][FLIT_WIDTH-1:0]   out_flit;

logic   [NODES-1:0][CHANNELS-1:0]                   out_last;

logic   [NODES-1:0][CHANNELS-1:0]                   out_valid;

logic   [NODES-1:0][CHANNELS-1:0]                   out_ready;



logic   [11:0][31:0]                                fetch_L2cache_info;

logic   [11:0]                                      fetch_L2cache_req;

logic   [11:0]                                      fetch_L2cache_gnt;

logic   [11:0][31:0]                                fetch_L2cache_r_data;

logic   [11:0]                                      fetch_L2cache_r_valid;

logic   [11:0]                                      fetch_L2cache_r_ready;





logic                                               aclk            ;

logic                                               aresetn         ;

// apb interface

logic   [1:0][11:0]                                 d_paddr         ;

logic   [1:0][0:0]                                  d_psel          ;

logic   [1:0]                                       d_penable       ;

logic   [1:0]                                       d_pready        ;

logic   [1:0]                                       d_pwrite        ;

logic   [1:0][3:0]                                  d_pstrb         ;

logic   [1:0][2:0]                                  d_pprot         ;

logic   [1:0][31:0]                                 d_pwdata        ;

logic   [1:0][31:0]                                 d_prdata        ;

logic   [1:0]                                       d_pslverr       ;

// interrupt

logic   [1:0]                                       d_interrupt     ;

// noc interface

// logic                                               data_out_valid  ;

// logic   [D_AXI_DATA_WID-1:0]                          data_out_flit   ;

// logic                                               data_out_last   ;

// logic                                               data_out_ready  ;

// logic                                               data_in_valid   ;

// logic   [D_AXI_DATA_WID-1:0]                          data_in_flit    ;

// logic                                               data_in_last    ;

// logic                                               data_in_ready   ;

// logic                                               ctrl_out_valid  ;

// logic   [D_AXI_DATA_WID-1:0]                          ctrl_out_flit   ;

// logic                                               ctrl_out_last   ;

// logic                                               ctrl_out_ready  ;

// logic                                               ctrl_in_valid   ;

// logic   [D_AXI_DATA_WID-1:0]                          ctrl_in_flit    ;

// logic                                               ctrl_in_last    ;

// logic                                               ctrl_in_ready   ;

//axi interface

// logic   [1:0]                                       d_arvalid       ;

// logic   [1:0][D_AXI_IDW-1:0]                          d_arid          ;

// logic   [1:0][D_AXI_ADDR_WID-1:0]                     d_araddr        ;

// logic   [1:0][D_AXI_LENW-1:0]                         d_arlen         ;

// logic   [1:0][2:0]                                  d_arsize        ;

// logic   [1:0][1:0]                                  d_arburst       ;

// logic   [1:0][D_AXI_LOCKW-1:0]                        d_arlock        ;

// logic   [1:0][3:0]                                  d_arcache       ;

// logic   [1:0][2:0]                                  d_arprot        ;

// logic   [1:0]                                       d_arready       ;

// logic   [1:0]                                       d_rvalid        ;

// logic   [1:0][D_AXI_IDW-1:0]                          d_rid           ;

// logic   [1:0]                                       d_rlast         ;

// logic   [1:0][D_AXI_DATA_WID-1:0]                     d_rdata         ;

// logic   [1:0][1:0]                                  d_rresp         ;

// logic   [1:0]                                       d_rready        ;

// logic   [1:0]                                       d_awvalid       ;

// logic   [1:0][D_AXI_IDW-1:0]                          d_awid          ;

// logic   [1:0][D_AXI_ADDR_WID-1:0]                     d_awaddr        ;

// logic   [1:0][D_AXI_LENW-1:0]                         d_awlen         ;

// logic   [1:0][2:0]                                  d_awsize        ;

// logic   [1:0][1:0]                                  d_awburst       ;

// logic   [1:0][D_AXI_LOCKW-1:0]                        d_awlock        ;

// logic   [1:0][3:0]                                  d_awcache       ;

// logic   [1:0][2:0]                                  d_awprot        ;

// logic   [1:0]                                       d_awready       ;

// logic   [1:0]                                       d_wvalid        ;

// logic   [1:0][D_AXI_IDW-1:0]                          d_wid           ;

// logic   [1:0]                                       d_wlast         ;

// logic   [1:0][D_AXI_DATA_WID-1:0]                     d_wdata         ;

// logic   [1:0][D_AXI_STRBW-1:0]                        d_wstrb         ;

// logic   [1:0]                                       d_wready        ;

// logic   [1:0]                                       d_bvalid        ;

// logic   [1:0][D_AXI_IDW-1:0]                          d_bid           ;

// logic   [1:0][1:0]                                  d_bresp         ;

// logic   [1:0]                                       d_bready        ;



//noc mesh

noc_mesh #(

    .FLIT_WIDTH         (256),

    .CHANNELS           (2),

    .X                  (4),

    .Y                  (4),

    .BUFFER_SIZE_IN     (4),

    .BUFFER_SIZE_OUT    (4)

)

U_noc_mesh

(

    .clk                (clk), 

    .rst_n              (rst_n),



    .in_flit            (in_flit),

    .in_last            (in_last),

    .in_valid           (in_valid),

    .in_ready           (in_ready),



    .out_flit           (out_flit),

    .out_last           (out_last),

    .out_valid          (out_valid),

    .out_ready          (out_ready)

);



//cu core



genvar x, y;

generate 

    for(y = 0; y < 4; y = y + 1) begin: y_dir 

        for(x = 0; x < 4; x = x + 1) begin: x_dir

            if(y < 3) begin

                if(x < 2) begin

                    cu_node #(

                        .NODE_ID    (nodenum(x,y)),

                        .DMA_ID     (4'd12)

                    )

                    U_cu_node

                    (

                        .clk                        (clk),

                        .rst_n                      (rst_n),



                        //noc interface



                        .out_flit                   (out_flit[nodenum(x,y)]),

                        .out_last                   (out_last[nodenum(x,y)]),

                        .out_valid                  (out_valid[nodenum(x,y)]),

                        .out_ready                  (out_ready[nodenum(x,y)]),



                        .in_flit                    (in_flit[nodenum(x,y)]),

                        .in_last                    (in_last[nodenum(x,y)]),

                        .in_valid                   (in_valid[nodenum(x,y)]),

                        .in_ready                   (in_ready[nodenum(x,y)]),



                        //instruction interface

                        .fetch_L2cache_info         (fetch_L2cache_info[nodenum(x,y)]),

                        .fetch_L2cache_req          (fetch_L2cache_req[nodenum(x,y)]),

                        .fetch_L2cache_gnt          (fetch_L2cache_gnt[nodenum(x,y)]),

                        .fetch_L2cache_r_data       (fetch_L2cache_r_data[nodenum(x,y)]),

                        .fetch_L2cache_r_valid      (fetch_L2cache_r_valid[nodenum(x,y)]),

                        .fetch_L2cache_r_ready      (fetch_L2cache_r_ready[nodenum(x,y)])

                    );

                end

                else begin

                    cu_node #(

                        .NODE_ID    (nodenum(x,y)),

                        .DMA_ID     (4'd15)

                    )

                    U_cu_node

                    (

                        .clk                        (clk),

                        .rst_n                      (rst_n),



                        //noc interface



                        .out_flit                   (out_flit[nodenum(x,y)]),

                        .out_last                   (out_last[nodenum(x,y)]),

                        .out_valid                  (out_valid[nodenum(x,y)]),

                        .out_ready                  (out_ready[nodenum(x,y)]),



                        .in_flit                    (in_flit[nodenum(x,y)]),

                        .in_last                    (in_last[nodenum(x,y)]),

                        .in_valid                   (in_valid[nodenum(x,y)]),

                        .in_ready                   (in_ready[nodenum(x,y)]),



                        //instruction interface

                        .fetch_L2cache_info         (fetch_L2cache_info[nodenum(x,y)]),

                        .fetch_L2cache_req          (fetch_L2cache_req[nodenum(x,y)]),

                        .fetch_L2cache_gnt          (fetch_L2cache_gnt[nodenum(x,y)]),

                        .fetch_L2cache_r_data       (fetch_L2cache_r_data[nodenum(x,y)]),

                        .fetch_L2cache_r_valid      (fetch_L2cache_r_valid[nodenum(x,y)]),

                        .fetch_L2cache_r_ready      (fetch_L2cache_r_ready[nodenum(x,y)])

                    );

                end

            end

            else begin // y == 3;

                if((x == 1) | (x == 2)) begin

                    assign in_flit[nodenum(x,y)] = 'b0;

                    assign in_last[nodenum(x,y)] = 'b0;

                    assign in_valid[nodenum(x,y)] = 'b0;



                    assign out_ready[nodenum(x,y)] = 1'b0;

                end

            end

        end

    end

endgenerate



//data dma



assign aclk = clk;

assign aresetn = rst_n;





genvar d_i;

generate 

    for(d_i = 0; d_i < 2; d_i = d_i + 1)begin: DATA_DMA

        // logic [3:0] dma_id;



        // if (d_i == 0)

        //     assign dma_id = 4'd12;

        // else

        //     assign dma_id = 4'd15;





        idma_data_noc_top 

        #(

          .DATA_FIFO_DEPTH      (DATA_FIFO_DEPTH),

          .DATA_FIFO_CNT_WID    (DATA_FIFO_CNT_WID),

          .ADDR_FIFO_DEPTH      (ADDR_FIFO_DEPTH),

          .ADDR_FIFO_CNT_WID    (ADDR_FIFO_CNT_WID),



          .AXI_DATA_WID         (D_AXI_DATA_WID),

          .AXI_ADDR_WID         (D_AXI_ADDR_WID),

          .AXI_IDW              (D_AXI_IDW),

          .AXI_LENW             (D_AXI_LENW),

          .AXI_LOCKW            (D_AXI_LOCKW),

          .AXI_STRBW            (D_AXI_STRBW)

        )

        U_idma_data_noc_top

        ( 

            .aclk               (aclk),

            .aresetn            (aresetn),

        // apb interface

            .paddr              (d_paddr[d_i]),

            .psel               (d_psel[d_i]),

            .penable            (d_penable[d_i]),

            .pready             (d_pready[d_i]),

            .pwrite             (d_pwrite[d_i]),

            .pstrb              (d_pstrb[d_i]),

            .pprot              (3'd0),

            .pwdata             (d_pwdata[d_i]),

            .prdata             (d_prdata[d_i]),

            .pslverr            (d_pslverr[d_i]),

        // interrupt

            .interrupt          (d_interrupt[d_i]),

        // noc interface

            .data_out_valid     (in_valid[12+d_i*3][0]),

            .data_out_flit      (in_flit[12+d_i*3][0]),

            .data_out_last      (in_last[12+d_i*3][0]),

            .data_out_ready     (in_ready[12+d_i*3][0]),

            .data_in_valid      (out_valid[12+d_i*3][0]),

            .data_in_flit       (out_flit[12+d_i*3][0]),

            .data_in_last       (out_last[12+d_i*3][0]),

            .data_in_ready      (out_ready[12+d_i*3][0]),

            .ctrl_out_valid     (in_valid[12+d_i*3][1]),

            .ctrl_out_flit      (in_flit[12+d_i*3][1]),

            .ctrl_out_last      (in_last[12+d_i*3][1]),

            .ctrl_out_ready     (in_ready[12+d_i*3][1]),

            .ctrl_in_valid      (out_valid[12+d_i*3][1]),

            .ctrl_in_flit       (out_flit[12+d_i*3][1]),

            .ctrl_in_last       (out_last[12+d_i*3][1]),

            .ctrl_in_ready      (out_ready[12+d_i*3][1]),

        //axi interface

            .arvalid            (d_arvalid[d_i]),

            .arid               (d_arid[d_i]),

            .araddr             (d_araddr[d_i]),

            .arlen              (d_arlen[d_i]),

            .arsize             (d_arsize[d_i]),

            .arburst            (d_arburst[d_i]),

            .arlock             (d_arlock[d_i]),

            .arcache            (d_arcache[d_i]),

            .arprot             (d_arprot[d_i]),

            .arready            (d_arready[d_i]),

            .rvalid             (d_rvalid[d_i]),

            .rid                (d_rid[d_i]),

            .rlast              (d_rlast[d_i]),

            .rdata              (d_rdata[d_i]),

            .rresp              (d_rresp[d_i]),

            .rready             (d_rready[d_i]),

            .awvalid            (d_awvalid[d_i]),

            .awid               (d_awid[d_i]),

            .awaddr             (d_awaddr[d_i]),

            .awlen              (d_awlen[d_i]),

            .awsize             (d_awsize[d_i]),

            .awburst            (d_awburst[d_i]),

            .awlock             (d_awlock[d_i]),

            .awcache            (d_awcache[d_i]),

            .awprot             (d_awprot[d_i]),

            .awready            (d_awready[d_i]),

            .wvalid             (d_wvalid[d_i]),

            // .wid                (d_wid[d_i]),

            .wlast              (d_wlast[d_i]),

            .wdata              (d_wdata[d_i]),

            .wstrb              (d_wstrb[d_i]),

            .wready             (d_wready[d_i]),

            .bvalid             (d_bvalid[d_i]),

            .bid                (d_bid[d_i]),

            .bresp              (d_bresp[d_i]),

            .bready             (d_bready[d_i])

        );

    end

endgenerate



//control unit



idma_inoc_top

#(

    .AXI_DW                     (AXI_DW),

    .AXI_AW                     (AXI_AW),

    .STRB_WIDTH                 (STRB_WIDTH),

    .ID_WIDTH                   (ID_WIDTH),

    .AXI_LENW                   (AXI_LENW),

    .AXI_LOCKW                  (AXI_LOCKW),

    .FLIT_WIDTH                 (I_FLIT_WIDTH)



    // .AXI4_ADDRESS_WIDTH         (AXI4_ADDRESS_WIDTH),

    // .AXI4_RDATA_WIDTH           (AXI4_RDATA_WIDTH),

    // .AXI4_WDATA_WIDTH           (AXI4_WDATA_WIDTH),

    // .AXI4_ID_WIDTH              (AXI4_ID_WIDTH),

    // .AXI4_USER_WIDTH            (AXI4_USER_WIDTH),

    // .AXI_NUMBYTES               (AXI_NUMBYTES),

    // .BUFF_DEPTH_SLAVE           (BUFF_DEPTH_SLAVE),

    // .APB_ADDR_WIDTH             (APB_ADDR_WIDTH)

) 

U_idma_inoc(



    .aclk                       (aclk),

    .aresetn                    (aresetn),



    // .cfg_awid                   (cfg_awid),

    // .cfg_awaddr                 (cfg_awaddr),

    // .cfg_awlen                  (cfg_awlen),

    // .cfg_awsize                 (cfg_awsize),

    // .cfg_awburst                (cfg_awburst),

    // .cfg_awlock                 (cfg_awlock),

    // .cfg_awcache                (cfg_awcache),

    // .cfg_awprot                 (cfg_awprot),

    // .cfg_awvalid                (cfg_awvalid),

    // .cfg_awready                (cfg_awready),

    // .cfg_wdata                  (cfg_wdata),

    // .cfg_wstrb                  (cfg_wstrb),

    // .cfg_wlast                  (cfg_wlast),

    // .cfg_wvalid                 (cfg_wvalid),

    // .cfg_wready                 (cfg_wready),

    // .cfg_bid                    (cfg_bid),

    // .cfg_bresp                  (cfg_bresp),

    // .cfg_bvalid                 (cfg_bvalid),

    // .cfg_bready                 (cfg_bready),

    // .cfg_arid                   (cfg_arid),

    // .cfg_araddr                 (cfg_araddr),

    // .cfg_arlen                  (cfg_arlen),

    // .cfg_arsize                 (cfg_arsize),

    // .cfg_arburst                (cfg_arburst),

    // .cfg_arlock                 (cfg_arlock),

    // .cfg_arcache                (cfg_arcache),

    // .cfg_arprot                 (cfg_arprot),

    // .cfg_arvalid                (cfg_arvalid),

    // .cfg_arready                (cfg_arready),

    // .cfg_rid                    (cfg_rid),

    // .cfg_rdata                  (cfg_rdata),

    // .cfg_rresp                  (cfg_rresp),

    // .cfg_rlast                  (cfg_rlast),

    // .cfg_rvalid                 (cfg_rvalid),

    // .cfg_rready                 (cfg_rready),



    .cfg_apb_PADDR              (cfg_apb_PADDR  ),

    .cfg_apb_PSEL               (cfg_apb_PSEL   ),

    .cfg_apb_PENABLE            (cfg_apb_PENABLE),

    .cfg_apb_PREADY             (cfg_apb_PREADY ),

    .cfg_apb_PWRITE             (cfg_apb_PWRITE ),

    .cfg_apb_PSTRB              (cfg_apb_PSTRB  ),

    .cfg_apb_PPROT              (cfg_apb_PPROT  ),

    .cfg_apb_PWDATA             (cfg_apb_PWDATA ),

    .cfg_apb_PRDATA             (cfg_apb_PRDATA ),

    .cfg_apb_PSLVERR            (cfg_apb_PSLVERR),



    .s_axi_awid                 (s_axi_awid     ),

    .s_axi_awaddr               (s_axi_awaddr   ),

    .s_axi_awlen                (s_axi_awlen    ),

    .s_axi_awsize               (s_axi_awsize   ),

    .s_axi_awburst              (s_axi_awburst  ),

    .s_axi_awlock               (s_axi_awlock   ),

    .s_axi_awcache              (s_axi_awcache  ),

    .s_axi_awprot               (s_axi_awprot   ),

    .s_axi_awvalid              (s_axi_awvalid  ),

    .s_axi_awready              (s_axi_awready  ),

    .s_axi_wdata                (s_axi_wdata)   ,

    .s_axi_wstrb                (s_axi_wstrb),

    .s_axi_wlast                (s_axi_wlast),

    .s_axi_wvalid               (s_axi_wvalid),

    .s_axi_wready               (s_axi_wready),

    .s_axi_bid                  (s_axi_bid),

    .s_axi_bresp                (s_axi_bresp),

    .s_axi_bvalid               (s_axi_bvalid),

    .s_axi_bready               (s_axi_bready),

    .s_axi_arid                 (s_axi_arid),

    .s_axi_araddr               (s_axi_araddr),

    .s_axi_arlen                (s_axi_arlen),

    .s_axi_arsize               (s_axi_arsize),

    .s_axi_arburst              (s_axi_arburst),

    .s_axi_arlock               (s_axi_arlock),

    .s_axi_arcache              (s_axi_arcache),

    .s_axi_arprot               (s_axi_arprot),

    .s_axi_arvalid              (s_axi_arvalid),

    .s_axi_arready              (s_axi_arready),

    .s_axi_rid                  (s_axi_rid),

    .s_axi_rdata                (s_axi_rdata),

    .s_axi_rresp                (s_axi_rresp),

    .s_axi_rlast                (s_axi_rlast),

    .s_axi_rvalid               (s_axi_rvalid),

    .s_axi_rready               (s_axi_rready),



    .m_arvalid                  (m_arvalid),

    .m_arid                     (m_arid),

    .m_araddr                   (m_araddr),

    .m_arlen                    (m_arlen),

    .m_arsize                   (m_arsize),

    .m_arburst                  (m_arburst),

    .m_arlock                   (m_arlock),

    .m_arcache                  (m_arcache),

    .m_arprot                   (m_arprot),

    .m_arready                  (m_arready),

    .m_rvalid                   (m_rvalid),

    .m_rid                      (m_rid),

    .m_rlast                    (m_rlast),

    .m_rdata                    (m_rdata),

    .m_rresp                    (m_rresp),

    .m_rready                   (m_rready),



    .send_valid                 (fetch_L2cache_r_valid),

    .send_flit                  (fetch_L2cache_r_data),

    .send_ready                 (fetch_L2cache_r_ready),



    .recv_valid                 (fetch_L2cache_req),

    .recv_flit                  (fetch_L2cache_info),

    .recv_ready                 (fetch_L2cache_gnt),



    .interrupt                  (i_interrupt),



    .m0_paddr                   (d_paddr[0]),

    .m0_psel                    (d_psel[0]),

    .m0_penable                 (d_penable[0]),

    .m0_pready                  (d_pready[0]),

    .m0_pwrite                  (d_pwrite[0]),

    .m0_pstrb                   (d_pstrb[0]),

    .m0_pwdata                  (d_pwdata[0]),

    .m1_paddr                   (d_paddr[1]),

    .m1_psel                    (d_psel[1]),

    .m1_penable                 (d_penable[1]),

    .m1_pready                  (d_pready[1]),

    .m1_pwrite                  (d_pwrite[1]),

    .m1_pstrb                   (d_pstrb[1]),

    .m1_pwdata                  (d_pwdata[1])

);





// Get the node number

function [3:0] nodenum(input integer x_in,input integer y_in);

    reg [2:0] x, y;

    x = x_in[1:0];

    y = y_in[1:0];

    nodenum = x+y*X;

endfunction // nodenum



endmodule

