module recuc #(
    localparam DATA_FIFO_DEPTH      = 64 ,
    localparam DATA_FIFO_CNT_WID    = 6+1,
    localparam ADDR_FIFO_DEPTH      = 32 ,
    localparam ADDR_FIFO_CNT_WID    = 5+1,

    localparam D_AXI_DATA_WID       = 256,
    localparam D_AXI_ADDR_WID       = 32 ,
    localparam D_AXI_IDW            = 4  ,
    localparam D_AXI_LENW           = 4  ,
    localparam D_AXI_LOCKW          = 1  ,
    localparam D_AXI_STRBW          = 32 ,

    localparam AXI_DW               = 128,
    localparam AXI_AW               = 32,
    localparam STRB_WIDTH           = (AXI_DW/8),
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
    output                             d_arvalid_0,
    output  [D_AXI_IDW-1:0]            d_arid_0   ,
    output  [D_AXI_ADDR_WID-1:0]       d_araddr_0 ,
    output  [D_AXI_LENW-1:0]           d_arlen_0  ,
    output  [2:0]                      d_arsize_0 ,
    output  [1:0]                      d_arburst_0,
    output  [D_AXI_LOCKW-1:0]          d_arlock_0 ,
    output  [3:0]                      d_arcache_0,
    output  [2:0]                      d_arprot_0 ,
    input                              d_arready_0,
    input                              d_rvalid_0 ,
    input   [D_AXI_IDW-1:0]            d_rid_0    ,
    input                              d_rlast_0  ,
    input   [D_AXI_DATA_WID-1:0]       d_rdata_0  ,
    input   [1:0]                      d_rresp_0  ,
    output                             d_rready_0 ,
    output                             d_awvalid_0,
    output  [D_AXI_IDW-1:0]            d_awid_0   ,
    output  [D_AXI_ADDR_WID-1:0]       d_awaddr_0 ,
    output  [D_AXI_LENW-1:0]           d_awlen_0  ,
    output  [2:0]                      d_awsize_0 ,
    output  [1:0]                      d_awburst_0,
    output  [D_AXI_LOCKW-1:0]          d_awlock_0 ,
    output  [3:0]                      d_awcache_0,
    output  [2:0]                      d_awprot_0 ,
    input                              d_awready_0,
    output                             d_wvalid_0 ,
    output                             d_wlast_0  ,
    output  [D_AXI_DATA_WID-1:0]       d_wdata_0  ,
    output  [D_AXI_STRBW-1:0]          d_wstrb_0  ,
    input                              d_wready_0 ,
    input                              d_bvalid_0 ,
    input   [D_AXI_IDW-1:0]            d_bid_0    ,
    input   [1:0]                      d_bresp_0  ,
    output                             d_bready_0 ,

    output                             d_arvalid_1,
    output  [D_AXI_IDW-1:0]            d_arid_1   ,
    output  [D_AXI_ADDR_WID-1:0]       d_araddr_1 ,
    output  [D_AXI_LENW-1:0]           d_arlen_1  ,
    output  [2:0]                      d_arsize_1 ,
    output  [1:0]                      d_arburst_1,
    output  [D_AXI_LOCKW-1:0]          d_arlock_1 ,
    output  [3:0]                      d_arcache_1,
    output  [2:0]                      d_arprot_1 ,
    input                              d_arready_1,
    input                              d_rvalid_1 ,
    input   [D_AXI_IDW-1:0]            d_rid_1    ,
    input                              d_rlast_1  ,
    input   [D_AXI_DATA_WID-1:0]       d_rdata_1  ,
    input   [1:0]                      d_rresp_1  ,
    output                             d_rready_1 ,
    output                             d_awvalid_1,
    output  [D_AXI_IDW-1:0]            d_awid_1   ,
    output  [D_AXI_ADDR_WID-1:0]       d_awaddr_1 ,
    output  [D_AXI_LENW-1:0]           d_awlen_1  ,
    output  [2:0]                      d_awsize_1 ,
    output  [1:0]                      d_awburst_1,
    output  [D_AXI_LOCKW-1:0]          d_awlock_1 ,
    output  [3:0]                      d_awcache_1,
    output  [2:0]                      d_awprot_1 ,
    input                              d_awready_1,
    output                             d_wvalid_1 ,
    output                             d_wlast_1  ,
    output  [D_AXI_DATA_WID-1:0]       d_wdata_1  ,
    output  [D_AXI_STRBW-1:0]          d_wstrb_1  ,
    input                              d_wready_1 ,
    input                              d_bvalid_1 ,
    input   [D_AXI_IDW-1:0]            d_bid_1    ,
    input   [1:0]                      d_bresp_1  ,
    output                             d_bready_1 ,
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

localparam INSTR_PIPE_LVL   = 6;

localparam NODES        = 16;
localparam CHANNELS     = 2;
localparam FLIT_WIDTH   = 256;
localparam X            = 4;
localparam Y            = 4;

logic   [NODES-1:0][FLIT_WIDTH-1:0]                 node_in_flit_local;
logic   [NODES-1:0]                                 node_in_last_local;
logic   [NODES-1:0][CHANNELS-1:0]                   node_in_valid_local;
logic   [NODES-1:0][CHANNELS-1:0]                   node_in_ready_local;

logic   [NODES-1:0][FLIT_WIDTH-1:0]                 node_out_flit_local;
logic   [NODES-1:0]                                 node_out_last_local;
logic   [NODES-1:0][CHANNELS-1:0]                   node_out_valid_local;
logic   [NODES-1:0][CHANNELS-1:0]                   node_out_ready_local;

logic   [11:0][31:0]                                fetch_L2cache_info;
logic   [11:0]                                      fetch_L2cache_req;
logic   [11:0]                                      fetch_L2cache_gnt;
logic   [11:0][31:0]                                fetch_L2cache_r_data;
logic   [11:0]                                      fetch_L2cache_r_valid;
logic   [11:0]                                      fetch_L2cache_r_ready;

logic   [11:0][31:0]                                fetch_L2cache_info_final;
logic   [11:0]                                      fetch_L2cache_req_final;
logic   [11:0]                                      fetch_L2cache_gnt_final;
logic   [11:0][31:0]                                fetch_L2cache_r_data_final;
logic   [11:0]                                      fetch_L2cache_r_valid_final;
logic   [11:0]                                      fetch_L2cache_r_ready_final;

logic   [11:0][INSTR_PIPE_LVL-1:0][31:0]            fetch_L2cache_info_pipe;
logic   [11:0][INSTR_PIPE_LVL-1:0]                  fetch_L2cache_req_pipe;
logic   [11:0][INSTR_PIPE_LVL-1:0]                  fetch_L2cache_gnt_pipe;
logic   [11:0][INSTR_PIPE_LVL-1:0][31:0]            fetch_L2cache_r_data_pipe;
logic   [11:0][INSTR_PIPE_LVL-1:0]                  fetch_L2cache_r_valid_pipe;
logic   [11:0][INSTR_PIPE_LVL-1:0]                  fetch_L2cache_r_ready_pipe;


logic                                               aclk            ;
logic                                               aresetn         ;
// apb interface from idma_inoc
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
// apb interface from cluster decoder
logic   [1:0][11:0]                                 idma_dnoc_paddr   ;
logic   [1:0][0:0]                                  idma_dnoc_psel    ;
logic   [1:0]                                       idma_dnoc_penable ;
logic   [1:0]                                       idma_dnoc_pready  ;
logic   [1:0]                                       idma_dnoc_pwrite  ;
logic   [1:0][3:0]                                  idma_dnoc_pstrb   ;
logic   [1:0][2:0]                                  idma_dnoc_pprot   ;
logic   [1:0][31:0]                                 idma_dnoc_pwdata  ;
logic   [1:0][31:0]                                 idma_dnoc_prdata  ;
logic   [1:0]                                       idma_dnoc_pslverr ;
// apb of idma_inoc
logic   [11:0]                                      idma_inoc_PADDR ;
logic   [0:0]                                       idma_inoc_PSEL  ;
logic                                               idma_inoc_PENABLE;
logic                                               idma_inoc_PREADY;
logic                                               idma_inoc_PWRITE;
logic   [3:0]                                       idma_inoc_PSTRB ;
logic   [2:0]                                       idma_inoc_PPROT ;
logic   [31:0]                                      idma_inoc_PWDATA;
logic   [31:0]                                      idma_inoc_PRDATA;
logic                                               idma_inoc_PSLVERR;
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

logic [11:0] nodes_pc;
logic [7:0] rst_n_reg;
logic       rst_n_sync_8;
logic       rst_n_sync_2;

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        rst_n_reg <= 8'd0;
    end
    else begin
        rst_n_reg <= {rst_n_reg[6:0], 1'b1};
    end
end

assign rst_n_sync_8 = rst_n_reg[7];
assign rst_n_sync_2 = rst_n_reg[1];


// APB decoder
cluster_apb_decoder U_cluster_apb_decoder (
  .io_apb_PADDR  (cfg_apb_PADDR),
  .io_apb_PSEL   (cfg_apb_PSEL),
  .io_apb_PENABLE(cfg_apb_PENABLE),
  .io_apb_PREADY (cfg_apb_PREADY),
  .io_apb_PWRITE (cfg_apb_PWRITE),
  .io_apb_PSTRB  (cfg_apb_PSTRB),
  .io_apb_PPROT  (cfg_apb_PPROT),
  .io_apb_PWDATA (cfg_apb_PWDATA),
  .io_apb_PRDATA (cfg_apb_PRDATA),
  .io_apb_PSLVERR(cfg_apb_PSLVERR),
  .apb_0_PADDR   (idma_inoc_PADDR  ),
  .apb_0_PSEL    (idma_inoc_PSEL   ),
  .apb_0_PENABLE (idma_inoc_PENABLE),
  .apb_0_PREADY  (idma_inoc_PREADY ),
  .apb_0_PWRITE  (idma_inoc_PWRITE ),
  .apb_0_PSTRB   (idma_inoc_PSTRB  ),
  .apb_0_PPROT   (idma_inoc_PPROT  ),
  .apb_0_PWDATA  (idma_inoc_PWDATA ),
  .apb_0_PRDATA  (idma_inoc_PRDATA ),
  .apb_0_PSLVERR (idma_inoc_PSLVERR),
  .apb_1_PADDR   (idma_dnoc_paddr  [0]),
  .apb_1_PSEL    (idma_dnoc_psel   [0]),
  .apb_1_PENABLE (idma_dnoc_penable[0]),
  .apb_1_PREADY  (idma_dnoc_pready [0]),
  .apb_1_PWRITE  (idma_dnoc_pwrite [0]),
  .apb_1_PSTRB   (idma_dnoc_pstrb  [0]),
  .apb_1_PPROT   (idma_dnoc_pprot  [0]),
  .apb_1_PWDATA  (idma_dnoc_pwdata [0]),
  .apb_1_PRDATA  (idma_dnoc_prdata [0]),
  .apb_1_PSLVERR (idma_dnoc_pslverr[0]),
  .apb_2_PADDR   (idma_dnoc_paddr  [1]),
  .apb_2_PSEL    (idma_dnoc_psel   [1]),
  .apb_2_PENABLE (idma_dnoc_penable[1]),
  .apb_2_PREADY  (idma_dnoc_pready [1]),
  .apb_2_PWRITE  (idma_dnoc_pwrite [1]),
  .apb_2_PSTRB   (idma_dnoc_pstrb  [1]),
  .apb_2_PPROT   (idma_dnoc_pprot  [1]),
  .apb_2_PWDATA  (idma_dnoc_pwdata [1]),
  .apb_2_PRDATA  (idma_dnoc_prdata [1]),
  .apb_2_PSLVERR (idma_dnoc_pslverr[1])
);


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
    .clk                    (clk), 
    .rst_n                  (rst_n_sync_2),

    .node_in_flit_local     (node_in_flit_local),
    .node_in_last_local     (node_in_last_local),
    .node_in_valid_local    (node_in_valid_local),
    .node_in_ready_local    (node_in_ready_local),

    .node_out_flit_local    (node_out_flit_local),
    .node_out_last_local    (node_out_last_local),
    .node_out_valid_local   (node_out_valid_local),
    .node_out_ready_local   (node_out_ready_local)
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
                        .rst_n                      (rst_n_sync_2),

                        .pc_serial_out              (nodes_pc[nodenum(x,y)]),

                        //noc interface

                        .node_out_flit_local        (node_out_flit_local[nodenum(x,y)]),
                        .node_out_last_local        (node_out_last_local[nodenum(x,y)]),
                        .node_out_valid_local       (node_out_valid_local[nodenum(x,y)]),
                        .node_out_ready_local       (node_out_ready_local[nodenum(x,y)]),

                        .node_in_flit_local         (node_in_flit_local[nodenum(x,y)]),
                        .node_in_last_local         (node_in_last_local[nodenum(x,y)]),
                        .node_in_valid_local        (node_in_valid_local[nodenum(x,y)]),
                        .node_in_ready_local        (node_in_ready_local[nodenum(x,y)]),

                        //instruction interface
                        .fetch_L2cache_info         (fetch_L2cache_info[nodenum(x,y)]),
                        .fetch_L2cache_req          (fetch_L2cache_req[nodenum(x,y)]),
                        .fetch_L2cache_gnt          (fetch_L2cache_gnt[nodenum(x,y)]),
                        .fetch_L2cache_r_data       (fetch_L2cache_r_data_final[nodenum(x,y)]),
                        .fetch_L2cache_r_valid      (fetch_L2cache_r_valid_final[nodenum(x,y)]),
                        .fetch_L2cache_r_ready      (fetch_L2cache_r_ready_final[nodenum(x,y)])
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
                        .rst_n                      (rst_n_sync_2),

                        .pc_serial_out              (nodes_pc[nodenum(x,y)]),

                        //noc interface

                        .node_out_flit_local        (node_out_flit_local[nodenum(x,y)]),
                        .node_out_last_local        (node_out_last_local[nodenum(x,y)]),
                        .node_out_valid_local       (node_out_valid_local[nodenum(x,y)]),
                        .node_out_ready_local       (node_out_ready_local[nodenum(x,y)]),

                        .node_in_flit_local         (node_in_flit_local[nodenum(x,y)]),
                        .node_in_last_local         (node_in_last_local[nodenum(x,y)]),
                        .node_in_valid_local        (node_in_valid_local[nodenum(x,y)]),
                        .node_in_ready_local        (node_in_ready_local[nodenum(x,y)]),

                        //instruction interface
                        .fetch_L2cache_info         (fetch_L2cache_info[nodenum(x,y)]),
                        .fetch_L2cache_req          (fetch_L2cache_req[nodenum(x,y)]),
                        .fetch_L2cache_gnt          (fetch_L2cache_gnt[nodenum(x,y)]),
                        .fetch_L2cache_r_data       (fetch_L2cache_r_data_final[nodenum(x,y)]),
                        .fetch_L2cache_r_valid      (fetch_L2cache_r_valid_final[nodenum(x,y)]),
                        .fetch_L2cache_r_ready      (fetch_L2cache_r_ready_final[nodenum(x,y)])
                    );
                end
            end
            else begin // y == 3;
                if((x == 1) | (x == 2)) begin
                    assign node_in_flit_local[nodenum(x,y)] = 'b0;
                    assign node_in_last_local[nodenum(x,y)] = 'b0;
                    assign node_in_valid_local[nodenum(x,y)] = 'b0;

                    assign node_out_ready_local[nodenum(x,y)] = 1'b0;
                end
            end
        end
    end
endgenerate

//data dma

assign aclk = clk;
assign aresetn = rst_n_sync_8;

genvar d_i, i;

logic   [1:0][1:0][256-1:0]  dma_out_flit;
logic   [1:0][1:0]           dma_out_last;
logic   [1:0][1:0]           dma_out_valid;
logic   [1:0][1:0]           dma_out_ready;

logic   [1:0][1:0][256-1:0]  dma_in_flit;
logic   [1:0][1:0]           dma_in_last;
logic   [1:0][1:0]           dma_in_valid;
logic   [1:0][1:0]           dma_in_ready;

generate 
    for(d_i = 0; d_i < 2; d_i = d_i + 1)begin: DATA_DMA
        // logic [3:0] dma_id;

        // if (d_i == 0)
        //     assign dma_id = 4'd12;
        // else
        //     assign dma_id = 4'd15;
        //--------------------- virtual channel mux -------------------------



        noc_vchannel_mux
        #(
            .FLIT_WIDTH (256)
        )
        u_vc_mux
        (
            // .clk        (clk),
            .in_flit    (dma_in_flit[d_i]),
            .in_last    (dma_in_last[d_i]),
            .in_valid   (dma_in_valid[d_i]),
            .in_ready   (dma_in_ready[d_i]),
            .out_flit   (node_in_flit_local[12+d_i*3]),
            .out_last   (node_in_last_local[12+d_i*3]),
            .out_valid  (node_in_valid_local[12+d_i*3]),
            .out_ready  (node_in_ready_local[12+d_i*3])
        );


        //--------------------- virtual channel demux -------------------------

        assign dma_out_valid[d_i] = node_out_valid_local[12+d_i*3];
        assign node_out_ready_local[12+d_i*3] = dma_out_ready[d_i];


        for(i = 0; i < 2; i = i+1) begin
            assign dma_out_flit[d_i][i] = node_out_flit_local[12+d_i*3];
            assign dma_out_last[d_i][i] = node_out_last_local[12+d_i*3];
        end

    end
endgenerate

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
U_idma_data_noc_top_0
( 
    .aclk               (aclk),
    .aresetn            (aresetn),
// apb interface
    .paddr              (d_paddr[0]),
    .psel               (d_psel[0]),
    .penable            (d_penable[0]),
    .pready             (d_pready[0]),
    .pwrite             (d_pwrite[0]),
    .pstrb              (d_pstrb[0]),
    .pprot              (3'd0),
    .pwdata             (d_pwdata[0]),
    .prdata             (d_prdata[0]),
    .pslverr            (d_pslverr[0]),
    .cluster_paddr      (idma_dnoc_paddr[0] - 12'h400),
    .cluster_psel       (idma_dnoc_psel[0]),
    .cluster_penable    (idma_dnoc_penable[0]),
    .cluster_pready     (idma_dnoc_pready[0]),
    .cluster_pwrite     (idma_dnoc_pwrite[0]),
    .cluster_pstrb      (idma_dnoc_pstrb[0]),
    .cluster_pprot      (3'd0),
    .cluster_pwdata     (idma_dnoc_pwdata[0]),
    .cluster_prdata     (idma_dnoc_prdata[0]),
    .cluster_pslverr    (idma_dnoc_pslverr[0]),
// interrupt
    .interrupt          (d_interrupt[0]),
// noc interface
    .data_out_valid     (dma_in_valid[0][0]),
    .data_out_flit      (dma_in_flit[0][0]),
    .data_out_last      (dma_in_last[0][0]),
    .data_out_ready     (dma_in_ready[0][0]),
    .data_in_valid      (dma_out_valid[0][0]),
    .data_in_flit       (dma_out_flit[0][0]),
    .data_in_last       (dma_out_last[0][0]),
    .data_in_ready      (dma_out_ready[0][0]),
    .ctrl_out_valid     (dma_in_valid[0][1]),
    .ctrl_out_flit      (dma_in_flit[0][1]),
    .ctrl_out_last      (dma_in_last[0][1]),
    .ctrl_out_ready     (dma_in_ready[0][1]),
    .ctrl_in_valid      (dma_out_valid[0][1]),
    .ctrl_in_flit       (dma_out_flit[0][1]),
    .ctrl_in_last       (dma_out_last[0][1]),
    .ctrl_in_ready      (dma_out_ready[0][1]),
//axi interface
    .arvalid            (d_arvalid_0),
    .arid               (d_arid_0),
    .araddr             (d_araddr_0),
    .arlen              (d_arlen_0),
    .arsize             (d_arsize_0),
    .arburst            (d_arburst_0),
    .arlock             (d_arlock_0),
    .arcache            (d_arcache_0),
    .arprot             (d_arprot_0),
    .arready            (d_arready_0),
    .rvalid             (d_rvalid_0),
    .rid                (d_rid_0),
    .rlast              (d_rlast_0),
    .rdata              (d_rdata_0),
    .rresp              (d_rresp_0),
    .rready             (d_rready_0),
    .awvalid            (d_awvalid_0),
    .awid               (d_awid_0),
    .awaddr             (d_awaddr_0),
    .awlen              (d_awlen_0),
    .awsize             (d_awsize_0),
    .awburst            (d_awburst_0),
    .awlock             (d_awlock_0),
    .awcache            (d_awcache_0),
    .awprot             (d_awprot_0),
    .awready            (d_awready_0),
    .wvalid             (d_wvalid_0),
    .wlast              (d_wlast_0),
    .wdata              (d_wdata_0),
    .wstrb              (d_wstrb_0),
    .wready             (d_wready_0),
    .bvalid             (d_bvalid_0),
    .bid                (d_bid_0),
    .bresp              (d_bresp_0),
    .bready             (d_bready_0)
);

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
U_idma_data_noc_top_1
( 
    .aclk               (aclk),
    .aresetn            (aresetn),
// apb interface
    .paddr              (d_paddr[1]),
    .psel               (d_psel[1]),
    .penable            (d_penable[1]),
    .pready             (d_pready[1]),
    .pwrite             (d_pwrite[1]),
    .pstrb              (d_pstrb[1]),
    .pprot              (3'd0),
    .pwdata             (d_pwdata[1]),
    .prdata             (d_prdata[1]),
    .pslverr            (d_pslverr[1]),
    .cluster_paddr      (idma_dnoc_paddr[1] - 12'h800),
    .cluster_psel       (idma_dnoc_psel[1]),
    .cluster_penable    (idma_dnoc_penable[1]),
    .cluster_pready     (idma_dnoc_pready[1]),
    .cluster_pwrite     (idma_dnoc_pwrite[1]),
    .cluster_pstrb      (idma_dnoc_pstrb[1]),
    .cluster_pprot      (3'd0),
    .cluster_pwdata     (idma_dnoc_pwdata[1]),
    .cluster_prdata     (idma_dnoc_prdata[1]),
    .cluster_pslverr    (idma_dnoc_pslverr[1]),
// interrupt
    .interrupt          (d_interrupt[1]),
// noc interface
    .data_out_valid     (dma_in_valid[1][0]),
    .data_out_flit      (dma_in_flit[1][0]),
    .data_out_last      (dma_in_last[1][0]),
    .data_out_ready     (dma_in_ready[1][0]),
    .data_in_valid      (dma_out_valid[1][0]),
    .data_in_flit       (dma_out_flit[1][0]),
    .data_in_last       (dma_out_last[1][0]),
    .data_in_ready      (dma_out_ready[1][0]),
    .ctrl_out_valid     (dma_in_valid[1][1]),
    .ctrl_out_flit      (dma_in_flit[1][1]),
    .ctrl_out_last      (dma_in_last[1][1]),
    .ctrl_out_ready     (dma_in_ready[1][1]),
    .ctrl_in_valid      (dma_out_valid[1][1]),
    .ctrl_in_flit       (dma_out_flit[1][1]),
    .ctrl_in_last       (dma_out_last[1][1]),
    .ctrl_in_ready      (dma_out_ready[1][1]),
//axi interface
    .arvalid            (d_arvalid_1),
    .arid               (d_arid_1),
    .araddr             (d_araddr_1),
    .arlen              (d_arlen_1),
    .arsize             (d_arsize_1),
    .arburst            (d_arburst_1),
    .arlock             (d_arlock_1),
    .arcache            (d_arcache_1),
    .arprot             (d_arprot_1),
    .arready            (d_arready_1),
    .rvalid             (d_rvalid_1),
    .rid                (d_rid_1),
    .rlast              (d_rlast_1),
    .rdata              (d_rdata_1),
    .rresp              (d_rresp_1),
    .rready             (d_rready_1),
    .awvalid            (d_awvalid_1),
    .awid               (d_awid_1),
    .awaddr             (d_awaddr_1),
    .awlen              (d_awlen_1),
    .awsize             (d_awsize_1),
    .awburst            (d_awburst_1),
    .awlock             (d_awlock_1),
    .awcache            (d_awcache_1),
    .awprot             (d_awprot_1),
    .awready            (d_awready_1),
    .wvalid             (d_wvalid_1),
    .wlast              (d_wlast_1),
    .wdata              (d_wdata_1),
    .wstrb              (d_wstrb_1),
    .wready             (d_wready_1),
    .bvalid             (d_bvalid_1),
    .bid                (d_bid_1),
    .bresp              (d_bresp_1),
    .bready             (d_bready_1)
);

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

    .cfg_apb_PADDR              (idma_inoc_PADDR  ),
    .cfg_apb_PSEL               (idma_inoc_PSEL   ),
    .cfg_apb_PENABLE            (idma_inoc_PENABLE),
    .cfg_apb_PREADY             (idma_inoc_PREADY ),
    .cfg_apb_PWRITE             (idma_inoc_PWRITE ),
    .cfg_apb_PSTRB              (idma_inoc_PSTRB  ),
    .cfg_apb_PPROT              (idma_inoc_PPROT  ),
    .cfg_apb_PWDATA             (idma_inoc_PWDATA ),
    .cfg_apb_PRDATA             (idma_inoc_PRDATA ),
    .cfg_apb_PSLVERR            (idma_inoc_PSLVERR),

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

    .recv_valid                 (fetch_L2cache_req_final),
    .recv_flit                  (fetch_L2cache_info_final),
    .recv_ready                 (fetch_L2cache_gnt_final),

    .interrupt                  (i_interrupt),
    .nodes_pc                   (nodes_pc),

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

genvar instr_i, instr_j;



generate
    for(instr_j = 0; instr_j < 12; instr_j = instr_j + 1) begin
        fwdbwd_pipe 
        #( 
            .DATA_W(32)
        )
        U_instr_req_pipe
        (
            .clk            (clk),
            .rst_n          (rst_n_sync_2),
        //from/to master
            .f_valid_in     (fetch_L2cache_req[instr_j]),
            .f_data_in      (fetch_L2cache_info[instr_j]),
            .f_ready_out    (fetch_L2cache_gnt[instr_j]),
        //from/to slave
            .b_valid_out    (fetch_L2cache_req_pipe[instr_j][0]),
            .b_data_out     (fetch_L2cache_info_pipe[instr_j][0]),
            .b_ready_in     (fetch_L2cache_gnt_pipe[instr_j][0])
        );

        fwdbwd_pipe 
        #( 
            .DATA_W(32)
        )
        U_instr_rd_pipe
        (
            .clk            (clk),
            .rst_n          (rst_n_sync_2),
        //from/to master
            .f_valid_in     (fetch_L2cache_r_valid[instr_j]),
            .f_data_in      (fetch_L2cache_r_data[instr_j]),
            .f_ready_out    (fetch_L2cache_r_ready[instr_j]),
        //from/to slave
            .b_valid_out    (fetch_L2cache_r_valid_pipe[instr_j][0]),
            .b_data_out     (fetch_L2cache_r_data_pipe[instr_j][0]),
            .b_ready_in     (fetch_L2cache_r_ready_pipe[instr_j][0])
        );

        if(INSTR_PIPE_LVL == 1)begin
            assign fetch_L2cache_req_final[instr_j] = fetch_L2cache_req_pipe[instr_j][0];
            assign fetch_L2cache_info_final[instr_j] = fetch_L2cache_info_pipe[instr_j][0];
            assign fetch_L2cache_gnt_pipe[instr_j][0] = fetch_L2cache_gnt_final[instr_j];

            assign fetch_L2cache_r_valid_final[instr_j] = fetch_L2cache_r_valid_pipe[instr_j][0];
            assign fetch_L2cache_r_data_final[instr_j] = fetch_L2cache_r_data_pipe[instr_j][0];
            assign fetch_L2cache_r_ready_pipe[instr_j][0] = fetch_L2cache_r_ready_final[instr_j];
        end
        else begin
            for(instr_i = 1; instr_i < INSTR_PIPE_LVL; instr_i = instr_i + 1) begin
                fwdbwd_pipe 
                #( 
                    .DATA_W(32)
                )
                U_instr_req_pipe
                (
                    .clk            (clk),
                    .rst_n          (rst_n_sync_2),
                //from/to master
                    .f_valid_in     (fetch_L2cache_req_pipe[instr_j][instr_i-1]),
                    .f_data_in      (fetch_L2cache_info_pipe[instr_j][instr_i-1]),
                    .f_ready_out    (fetch_L2cache_gnt_pipe[instr_j][instr_i-1]),
                //from/to slave
                    .b_valid_out    (fetch_L2cache_req_pipe[instr_j][instr_i]),
                    .b_data_out     (fetch_L2cache_info_pipe[instr_j][instr_i]),
                    .b_ready_in     (fetch_L2cache_gnt_pipe[instr_j][instr_i])
                );

                fwdbwd_pipe 
                #( 
                    .DATA_W(32)
                )
                U_instr_rd_pipe
                (
                    .clk            (clk),
                    .rst_n          (rst_n_sync_2),
                //from/to master
                    .f_valid_in     (fetch_L2cache_r_valid_pipe[instr_j][instr_i-1]),
                    .f_data_in      (fetch_L2cache_r_data_pipe[instr_j][instr_i-1]),
                    .f_ready_out    (fetch_L2cache_r_ready_pipe[instr_j][instr_i-1]),
                //from/to slave
                    .b_valid_out    (fetch_L2cache_r_valid_pipe[instr_j][instr_i]),
                    .b_data_out     (fetch_L2cache_r_data_pipe[instr_j][instr_i]),
                    .b_ready_in     (fetch_L2cache_r_ready_pipe[instr_j][instr_i])
                );
            end

            assign fetch_L2cache_req_final[instr_j] = fetch_L2cache_req_pipe[instr_j][INSTR_PIPE_LVL-1];
            assign fetch_L2cache_info_final[instr_j] = fetch_L2cache_info_pipe[instr_j][INSTR_PIPE_LVL-1];
            assign fetch_L2cache_gnt_pipe[instr_j][INSTR_PIPE_LVL-1] = fetch_L2cache_gnt_final[instr_j];

            assign fetch_L2cache_r_valid_final[instr_j] = fetch_L2cache_r_valid_pipe[instr_j][INSTR_PIPE_LVL-1];
            assign fetch_L2cache_r_data_final[instr_j] = fetch_L2cache_r_data_pipe[instr_j][INSTR_PIPE_LVL-1];
            assign fetch_L2cache_r_ready_pipe[instr_j][INSTR_PIPE_LVL-1] = fetch_L2cache_r_ready_final[instr_j];
        end
    end
endgenerate


// Get the node number
function [3:0] nodenum(input integer x_in,input integer y_in);
    reg [1:0] x, y;
    x = x_in[1:0];
    y = y_in[1:0];
    nodenum = x+y*X;
endfunction // nodenum

endmodule
