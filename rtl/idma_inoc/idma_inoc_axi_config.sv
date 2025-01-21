module idma_inoc_axi_config #(
    parameter AXI4_ADDRESS_WIDTH = 32,
    parameter AXI4_RDATA_WIDTH   = 32,
    parameter AXI4_WDATA_WIDTH   = 32,
    parameter AXI4_ID_WIDTH      = 16,
    parameter AXI4_USER_WIDTH    = 10,
    parameter AXI_NUMBYTES       = AXI4_WDATA_WIDTH/8,

    parameter BUFF_DEPTH_SLAVE   = 4,
    parameter APB_ADDR_WIDTH     = 12
)
(
    input aclk,
    input aresetn,
    // AXI slave port
    input   [AXI4_ID_WIDTH-1:0]       awid,
    input   [AXI4_ADDRESS_WIDTH-1:0]  awaddr,
    input   [7:0]                     awlen,
    input   [2:0]                     awsize,
    input   [1:0]                     awburst,
    input                             awlock,
    input   [3:0]                     awcache,
    input   [2:0]                     awprot,
    input                             awvalid,
    output                            awready,
    input   [AXI4_WDATA_WIDTH-1:0]    wdata,
    input   [AXI_NUMBYTES-1:0]        wstrb,
    input                             wlast,
    input                             wvalid,
    output                            wready,
    output  [AXI4_ID_WIDTH-1:0]       bid,
    output  [1:0]                     bresp,
    output                            bvalid,
    input                             bready,
    input   [AXI4_ID_WIDTH-1:0]       arid,
    input   [AXI4_ADDRESS_WIDTH-1:0]  araddr,
    input   [7:0]                     arlen,
    input   [2:0]                     arsize,
    input   [1:0]                     arburst,
    input                             arlock,
    input   [3:0]                     arcache,
    input   [2:0]                     arprot,
    input                             arvalid,
    output                            arready,
    output  [AXI4_ID_WIDTH-1:0]       rid,
    output  [AXI4_RDATA_WIDTH-1:0]    rdata,
    output  [1:0]                     rresp,
    output                            rlast,
    output                            rvalid,
    input                             rready,

    output                            io_fsm_start,
    output  [16:0]                    io_fsm_base_addr,
    output                            io_rd_cfg_ready,
    output                            io_rd_afifo_init,
    output                            io_rd_dfifo_init,
    output  [3:0]                     io_rd_cfg_outstd,
    output                            io_rd_cfg_outstd_en,
    output                            io_rd_cfg_cross4k_en,
    output                            io_rd_cfg_arvld_hold_en,
    output  [6:0]                     io_rd_cfg_dfifo_thd,
    output                            io_rd_cfg_resi_mode,
    output  [31:0]                    io_rd_cfg_resi_fmap_a_addr,
    output  [31:0]                    io_rd_cfg_resi_fmap_b_addr,
    output  [15:0]                    io_rd_cfg_resi_addr_gap,
    output  [15:0]                    io_rd_cfg_resi_loop_num,
    output                            io_rd_req,
    output  [31:0]                    io_rd_addr,
    output  [31:0]                    io_rd_num,
    
    input                             io_rd_done_intr,
    input                             io_finish_intr,
    input   [15:0]                    io_debug_dma_rd_in_cnt,
    input   [11:0]                    io_nodes_status,
    output                            io_intr,
    input                             rd_addr_ready
);

logic                            io_flit_send;
logic  [31:0]                    io_group_info;
logic  [31:0]                    io_cache_info;
logic                            io_group_info_valid;
logic                            io_cache_info_valid;

logic     [11:0]   io_apb_PADDR;
logic     [0:0]    io_apb_PSEL;
logic              io_apb_PENABLE;
logic              io_apb_PREADY;
logic              io_apb_PWRITE;
logic     [3:0]    io_apb_PSTRB;
logic     [2:0]    io_apb_PPROT = 3'b0;
logic     [31:0]   io_apb_PWDATA;
logic     [31:0]   io_apb_PRDATA;
logic              io_apb_PSLVERR;

axi2apb #(
    .AXI4_ADDRESS_WIDTH ( AXI4_ADDRESS_WIDTH ),
    .AXI4_RDATA_WIDTH   ( AXI4_RDATA_WIDTH   ),
    .AXI4_WDATA_WIDTH   ( AXI4_WDATA_WIDTH   ),
    .AXI4_ID_WIDTH      ( AXI4_ID_WIDTH      ),
    .AXI4_USER_WIDTH    ( AXI4_USER_WIDTH    ),
    .AXI_NUMBYTES       ( AXI4_WDATA_WIDTH/8 ),
    .BUFF_DEPTH_SLAVE   ( BUFF_DEPTH_SLAVE),
    .APB_ADDR_WIDTH     ( APB_ADDR_WIDTH  )
) u_axi2apb
(
    .ACLK(aclk),
    .ARESETn(aresetn),
    .test_en_i(1'b0),

    .AWID_i(awid),
    .AWADDR_i(awaddr),
    .AWLEN_i(awlen),
    .AWSIZE_i(awsize),
    .AWBURST_i(awburst),
    .AWLOCK_i(awlock),
    .AWCACHE_i(awcache),
    .AWPROT_i(awprot),
    .AWREGION_i(4'b0),
    .AWUSER_i({AXI4_USER_WIDTH{1'b0}}),
    .AWQOS_i(4'b0),
    .AWVALID_i(awvalid),
    .AWREADY_o(awready),

    .WDATA_i(wdata),
    .WSTRB_i(wstrb),
    .WLAST_i(wlast),
    .WUSER_i({AXI4_USER_WIDTH{1'b0}}),
    .WVALID_i(wvalid),
    .WREADY_o(wready),

    .BID_o(bid),
    .BRESP_o(bresp),
    .BVALID_o(bvalid),
    .BUSER_o(),
    .BREADY_i(bready),

    .ARID_i(arid),
    .ARADDR_i(araddr),
    .ARLEN_i(arlen),
    .ARSIZE_i(arsize),
    .ARBURST_i(arburst),
    .ARLOCK_i(arlock),
    .ARCACHE_i(arcache),
    .ARPROT_i(arprot),
    .ARREGION_i(4'b0),
    .ARUSER_i({AXI4_USER_WIDTH{1'b0}}),
    .ARQOS_i(4'b0),
    .ARVALID_i(arvalid),
    .ARREADY_o(arready),

    .RID_o(rid),
    .RDATA_o(rdata),
    .RRESP_o(rresp),
    .RLAST_o(rlast),
    .RUSER_o(),
    .RVALID_o(rvalid),
    .RREADY_i(rready),

    .PENABLE(io_apb_PENABLE),
    .PWRITE(io_apb_PWRITE),
    .PWSTRB(io_apb_PSTRB),
    .PADDR(io_apb_PADDR),
    .PSEL(io_apb_PSEL),
    .PWDATA(io_apb_PWDATA),
    .PRDATA(io_apb_PRDATA),
    .PREADY(io_apb_PREADY && rd_addr_ready),
    .PSLVERR(io_apb_PSLVERR)
);

idma_inoc_regfile u_idma_inoc_regfile(
    .io_apb_PADDR               ( io_apb_PADDR               ),
    .io_apb_PSEL                ( io_apb_PSEL                ),
    .io_apb_PENABLE             ( io_apb_PENABLE             ),
    .io_apb_PREADY              ( io_apb_PREADY              ),
    .io_apb_PWRITE              ( io_apb_PWRITE              ),
    .io_apb_PSTRB               ( io_apb_PSTRB               ),
    .io_apb_PPROT               ( io_apb_PPROT               ),
    .io_apb_PWDATA              ( io_apb_PWDATA              ),
    .io_apb_PRDATA              ( io_apb_PRDATA              ),
    .io_apb_PSLVERR             ( io_apb_PSLVERR             ),
    .io_fsm_start               ( io_fsm_start               ),
    .io_fsm_base_addr           ( io_fsm_base_addr           ),
    .io_rd_cfg_ready            ( io_rd_cfg_ready            ),
    .io_rd_afifo_init           ( io_rd_afifo_init           ),
    .io_rd_dfifo_init           ( io_rd_dfifo_init           ),
    .io_rd_cfg_outstd           ( io_rd_cfg_outstd           ),
    .io_rd_cfg_outstd_en        ( io_rd_cfg_outstd_en        ),
    .io_rd_cfg_cross4k_en       ( io_rd_cfg_cross4k_en       ),
    .io_rd_cfg_arvld_hold_en    ( io_rd_cfg_arvld_hold_en    ),
    .io_rd_cfg_dfifo_thd        ( io_rd_cfg_dfifo_thd        ),
    .io_rd_cfg_resi_mode        ( io_rd_cfg_resi_mode        ),
    .io_rd_cfg_resi_fmap_a_addr ( io_rd_cfg_resi_fmap_a_addr ),
    .io_rd_cfg_resi_fmap_b_addr ( io_rd_cfg_resi_fmap_b_addr ),
    .io_rd_cfg_resi_addr_gap    ( io_rd_cfg_resi_addr_gap    ),
    .io_rd_cfg_resi_loop_num    ( io_rd_cfg_resi_loop_num    ),
    .io_rd_req                  ( io_rd_req                  ),
    .io_rd_addr                 ( io_rd_addr                 ),
    .io_rd_num                  ( io_rd_num                  ),
    .io_rd_done_intr            ( io_rd_done_intr            ),
    .io_finish_intr             ( io_finish_intr             ),
    .io_debug_dma_rd_in_cnt     ( io_debug_dma_rd_in_cnt     ),
    .io_nodes_status            ( io_nodes_status            ),
    .io_intr                    ( io_intr                    ),
    .clk                        ( aclk                       ),
    .resetn                     ( aresetn                    )
);



endmodule