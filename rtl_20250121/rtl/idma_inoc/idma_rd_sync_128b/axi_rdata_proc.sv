module axi_rdata_proc #(
    parameter AXI_IDW       = 4             ,
    parameter AXI_DATA_WID  = 256           ,
    parameter AXI_STRBW     = AXI_DATA_WID/8,
    parameter ID            = 0
    )(
    //global input
    input                       aclk                    ,
    input                       aresetn                 ,
    //to rdata fifo
    input                       rdata_fifo_full_s       ,
    output                      rdata_fifo_push         ,
    output  [AXI_STRBW-1:0]     rdata_fifo_strb_s       ,
    output  [AXI_DATA_WID-1:0]  rdata_fifo_data_s       ,
    
    output                      axi_burst_rdata_ok      ,
    // AXI write data 
    input                       i_rlast                 ,
    input [AXI_DATA_WID-1:0]    i_rdata                 ,           
    input                       i_rvalid                ,
    input [AXI_IDW-1:0]         i_rid                   ,
    input [1:0]                 i_rresp                 ,
    output                      o_rready                ,
    input                       dma_trans_first_burst   ,
    input                       dma_trans_last_burst    
);

wire axi_burst_rdata_beat_ok;
wire rvalid_pipe;
wire rlast_pipe;
wire [AXI_IDW-1:0] rid_pipe;
wire [1:0] rresp_pipe;
wire [AXI_DATA_WID-1:0] rdata_pipe;
wire pipe_ready_in;

// ==================== pipe input rdata ======================
fwd_pipe#(
    .DATA_W      ( 1+AXI_IDW+2+AXI_DATA_WID )
)u_rchannel_pipe(
    .clk         ( aclk         ),
    .rst_n       ( aresetn      ),
    .f_valid_in  ( i_rvalid     ),
    .f_data_in   ( {i_rlast, i_rid, i_rresp, i_rdata} ),
    .f_ready_out ( o_rready     ),
    .b_valid_out ( rvalid_pipe  ),
    .b_data_out  ( {rlast_pipe, rid_pipe, rresp_pipe, rdata_pipe}),
    .b_ready_in  ( pipe_ready_in)
);
assign pipe_ready_in            = ~rdata_fifo_full_s;
assign axi_burst_rdata_beat_ok  = pipe_ready_in && rvalid_pipe && (rid_pipe==ID[AXI_IDW-1:0]);
assign rdata_fifo_push          = axi_burst_rdata_beat_ok;
assign axi_burst_rdata_ok       = rlast_pipe && axi_burst_rdata_beat_ok;
      
assign rdata_fifo_strb_s = {AXI_STRBW{1'b1}};
assign rdata_fifo_data_s = rdata_pipe;


endmodule
