//  
// 从noc 输入数据

module dnoc_itf_in_d_channel(

    input                           clk,
    input                           rst_n,


    //noc signals    // noc传到 channel的信号
    input           [256-1:0]       out_flit,
    input                           out_last,
    input                           out_valid,
    output  logic                   out_ready,

    // channel 传递给本地节点的core rd通道的数据(core rd从其他节点读取过来的数据)
    output  logic   [255:0]         noc_in_core_rd_data,
    output  logic                   noc_in_core_rd_valid,
    output  logic                   noc_in_core_rd_last,
    input                           noc_in_core_rd_ready,


    //noc to dma wr data and cfg
    output  logic                   noc_cmd_dma_wr_req,
    input                           noc_cmd_dma_wr_gnt,

    // channel 传给 dma_wr通道的信号
    output  logic   [255:0]         noc_in_dma_wr_data,
    output  logic                   noc_in_dma_wr_valid,    
    input                           noc_in_dma_wr_ready,


    output  logic   [12:0]          n_cfg_d_w_ram_base_addr,
    output  logic   [12:0]          n_cfg_d_w_ram_total_lenth, //给到dma wr的ping长度
    output  logic   [3:0]           n_cfg_d_w_source_id, // wr req node id 用于dma wr 返回response信号
    output  logic                   n_cfg_d_w_resp_sel, //0: core; 1:dma

    output  logic   [3:0][12:0]     n_cfg_d_w_loop_lenth,
    output  logic   [3:0][12:0]     n_cfg_d_w_loop_gap
);



localparam IDLE         = 2'd0;
localparam DMA          = 2'd1;
localparam CORE_RETURN  = 2'd2;
// localparam DMA_RETURN   = 2'd3;


logic [1:0] cs, ns;


always_comb begin
    ns = cs;

    out_ready = 'b0;

    noc_in_core_rd_data = out_flit;
    noc_in_core_rd_valid = 'b0;
    noc_in_core_rd_last = 'b0;

    noc_cmd_dma_wr_req = 'b0;

    noc_in_dma_wr_data = out_flit;
    noc_in_dma_wr_valid = 'b0;


    n_cfg_d_w_ram_base_addr     = out_flit[30:18];
    n_cfg_d_w_ram_total_lenth   = out_flit[55:43];
    n_cfg_d_w_source_id         = out_flit[17:14];  //节点ID，用于查表
    n_cfg_d_w_resp_sel          = out_flit[13];
    n_cfg_d_w_loop_lenth        = out_flit[159:108];
    n_cfg_d_w_loop_gap          = out_flit[107:56];

    case(cs)

    IDLE: begin
        if(out_valid) begin //传入的数据有效
            if(out_flit[12]) begin  // 是主动从外面读取数据还是其他core想要写入借用dma wr通道
                out_ready = 1'b1;
                if(out_flit[13]) begin  //[13]要放在 out ctrl通道的[5], 表示: 读请求是来自core还是dma；response返回给core还是dma
                    ns = DMA;   //读请求来自dma
                end
                else begin
                    ns = CORE_RETURN;//来自core
                end
            end
            else begin
                noc_cmd_dma_wr_req = 1'b1;
                out_ready = noc_cmd_dma_wr_gnt;
                if(noc_cmd_dma_wr_gnt) begin
                    ns = DMA;
                end
            end
        end
    end

    DMA: begin
        noc_in_dma_wr_valid = out_valid;    
        out_ready = noc_in_dma_wr_ready;

        if(noc_in_dma_wr_valid & noc_in_dma_wr_ready & out_last) begin  //最后一次握手成功返回IDLE状态
            ns = IDLE;
        end
    end

    CORE_RETURN: begin
        noc_in_core_rd_valid = out_valid;
        noc_in_core_rd_last = out_last;
        out_ready = noc_in_core_rd_ready;

        if(noc_in_core_rd_valid & noc_in_core_rd_ready & out_last) begin
            ns = IDLE;
        end
    end

    // DMA_RETURN: begin
    //     noc_in_dma_wr_valid = out_valid;
    //     out_ready = noc_in_dma_wr_ready;


    //     if(noc_in_dma_wr_valid & noc_in_dma_wr_ready & out_last) begin
    //         ns = IDLE;
    //     end
    // end
    endcase
end


always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cs <= IDLE;
    end
    else begin
        cs <= ns;
    end
end







endmodule