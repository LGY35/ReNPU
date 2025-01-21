module idma_inoc_ibuffer_arbiter
#(
    parameter DATA_WIDTH = 128,
    parameter MEM_AW = 15,
    parameter STRB_WIDTH = (DATA_WIDTH/8)
) 
(   
    input clk,
    input rst_n,

    // control signal
    input                  dma_read_start,
    input                  dma_write_done,

    // dma read port
    input                 dma_read_to_ibuffer_cen,
    input                 dma_read_to_ibuffer_wen,
    output                dma_read_to_ibuffer_ready,
    input[MEM_AW-1:0]     dma_read_to_ibuffer_addr,
    input[DATA_WIDTH-1:0] dma_read_to_ibuffer_wdata,
    input[STRB_WIDTH-1:0] dma_read_to_ibuffer_strb,

    // noc write port
    input                 noc_read_from_ibuffer_cen,
    input                 noc_read_from_ibuffer_wen,
    output                noc_read_from_ibuffer_ready,
    input [MEM_AW-1:0]    noc_read_from_ibuffer_addr,
    output[DATA_WIDTH-1:0]noc_read_from_ibuffer_rdata,
    output                noc_read_from_ibuffer_rvalid,
    input                 noc_read_from_ibuffer_rready,

    // ibuffer port
    output                ibuffer_cen,
    output                ibuffer_wen,
    input                 ibuffer_ready,
    output[MEM_AW-1:0]    ibuffer_addr,
    output[DATA_WIDTH-1:0]ibuffer_wdata,
    output[STRB_WIDTH-1:0]ibuffer_strb,
    input[DATA_WIDTH-1:0] ibuffer_rdata,
    input                 ibuffer_rvalid,
    output                ibuffer_rready
);

localparam IDLE     = 2'd0;
localparam DMA_READ = 2'd1;
localparam NOC_WRITE = 2'd2;

reg [1:0] cur_state;
reg [1:0] nxt_state;

wire state_is_dma_read;
wire state_is_noc_write;

// ===================================
// FSM
// ===================================
always @(posedge clk or negedge rst_n) begin
    if (rst_n==1'b0) begin
        cur_state <= IDLE;
    end
    else begin
        cur_state <= nxt_state;
    end
end

always @* begin
    case(cur_state)
        IDLE : begin
            if(dma_read_start)
                nxt_state = DMA_READ;
            else
                nxt_state = IDLE;
        end
        DMA_READ : begin
            if(dma_write_done)
                nxt_state = NOC_WRITE;
            else
                nxt_state = DMA_READ;
        end
        NOC_WRITE : begin
            if(dma_read_start)
                nxt_state = DMA_READ;
            else
                nxt_state = NOC_WRITE;
        end
        default :
            nxt_state = IDLE;
    endcase
end

// ===================================
// output
// ===================================
assign state_is_dma_read = (cur_state==DMA_READ);
assign state_is_noc_write = (cur_state==NOC_WRITE);

assign dma_read_to_ibuffer_ready = state_is_dma_read && ibuffer_ready;

assign noc_read_from_ibuffer_ready   = state_is_noc_write && ibuffer_ready;
assign noc_read_from_ibuffer_rdata   = ibuffer_rdata;
assign noc_read_from_ibuffer_rvalid  = state_is_noc_write && ibuffer_rvalid;

assign ibuffer_cen = (state_is_dma_read & dma_read_to_ibuffer_cen)
                    |(state_is_noc_write & noc_read_from_ibuffer_cen)
                    ;
assign ibuffer_wen = (state_is_dma_read & dma_read_to_ibuffer_wen)
                    |(state_is_noc_write & noc_read_from_ibuffer_wen)
                    ;
assign ibuffer_addr =    ({MEM_AW{state_is_dma_read}} & dma_read_to_ibuffer_addr)
                        |({MEM_AW{state_is_noc_write}} & noc_read_from_ibuffer_addr)
                    ;
assign ibuffer_wdata = dma_read_to_ibuffer_wdata;
assign ibuffer_strb  = dma_read_to_ibuffer_strb;
assign ibuffer_rready =  (state_is_noc_write & noc_read_from_ibuffer_rready)
                        | state_is_dma_read
                    ;

endmodule