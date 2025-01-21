
// 接口模块，连接了DMA、Ibuffer、APB 总线、NOC（Network on Chip）接口，负责在这些模块之间进行数据的读写、控制和管理。

module idma_inoc_interface
#(
    parameter DATA_WIDTH = 128,
    parameter MEM_AW = 15,
    parameter STRB_WIDTH = (DATA_WIDTH/8),
    parameter FLIT_WIDTH = 32,
    parameter APB_BASE_ADDR = 12'h30
) 
(
    input clk,
    input rst_n,

    // config ports
    input                  fsm_start,
    input [16:0]           fsm_base_addr,
    input                  fsm_auto_restart_en, // if 1, auto restart next loop
    input                  fsm_restart, // if pulse asserts, restart next loop

    // dma port     //idma 从DDR读取指令
    input                  dma_rd_req,
    input                  dma_rd_data_valid,
    input [DATA_WIDTH-1:0] dma_rd_data,
    output                 dma_rd_data_ready,
    input [STRB_WIDTH-1:0] dma_rd_strb,
    input [31:0]           dma_rd_addr,
    input [31:0]           dma_rd_num, // how many word

    // ibuffer port    // 读取的指令放到ibuffer中
    output                 ibuffer_cen,
    output                 ibuffer_wen,
    input                  ibuffer_ready,
    output[MEM_AW-1:0]     ibuffer_addr,
    output[DATA_WIDTH-1:0] ibuffer_wdata,
    output[STRB_WIDTH-1:0] ibuffer_strb,
    input[DATA_WIDTH-1:0]  ibuffer_rdata,
    input                  ibuffer_rvalid,
    output                 ibuffer_rready,

    // apb interface master 0   //
    output [11:0]          m0_paddr  ,
    output [0:0]           m0_psel   ,
    output                 m0_penable,
    input                  m0_pready ,
    output                 m0_pwrite ,
    output [3:0]           m0_pstrb  ,
    output [31:0]          m0_pwdata ,

    // apb interface master 1
    output [11:0]          m1_paddr  ,
    output [0:0]           m1_psel   ,
    output                 m1_penable,
    input                  m1_pready ,
    output                 m1_pwrite ,
    output [3:0]           m1_pstrb  ,
    output [31:0]          m1_pwdata ,


    // send to noc      //与节点之间的通信端口
    output [11:0]           send_valid ,
    output [11:0][FLIT_WIDTH-1:0] send_flit  ,
    input  [11:0]           send_ready ,

    // receive from noc
    input  [11:0]           recv_valid ,
    input  [11:0][FLIT_WIDTH-1:0] recv_flit  ,
    output [11:0]           recv_ready ,

    // send intr    //反馈给顶层SoC CPU的状态
    output [11:0]           nodes_status,
    output                  small_loop_end_int,
    output                  finish_intr
);

wire [MEM_AW-1:0]     dma_rd_data_num;
// DDR[31:0] 内部应该是按照128bit来寻址的。因为上面的rd_data是128bit
// 所以这里 + 2 目的是为了能转换成word
wire [MEM_AW+2-1:0]   dma_rd_word_addr; 
wire [MEM_AW+2-1:0]   dma_rd_word_addr_end;
wire                  dma_read_to_ibuffer_cen;
wire                  dma_read_to_ibuffer_wen;
wire                  dma_read_to_ibuffer_ready;
wire [MEM_AW-1:0]     dma_read_to_ibuffer_addr;
wire [DATA_WIDTH-1:0] dma_read_to_ibuffer_wdata;
wire [STRB_WIDTH-1:0] dma_read_to_ibuffer_strb;
wire                  dma_read_to_ibuffer_done;

// noc wr port   从内部缓冲区 (ibuffer) 中读取数据，并通过 noc 传输数据到节点
// MEM_AW 是寻址ibuffer内部的一个cacheline的，而要具体定位到每个word，就需要增加地址位宽。
// ibuffer内部的一个cacheline是128bit，而一个flit是32bit，所以 可以用DATA_WIDTH/FLIT_WIDTH的对数来确定需要增加地址线 2条。
// 虽然是128bit的一个line，但是实际上的存储组织应该还是按照一个地址线一个word这样，或者是一个地址bit一个byte这样组织的。
wire [MEM_AW+$clog2(DATA_WIDTH/FLIT_WIDTH)-1:0] ibuffer_word_addr; // word addr
wire [12:0]             ibuffer_word_num; // how many word
wire                    noc_read_from_ibuffer_cen;
wire                    noc_read_from_ibuffer_wen;
wire                    noc_read_from_ibuffer_ready;
wire [MEM_AW-1:0]       noc_read_from_ibuffer_addr;
wire [DATA_WIDTH-1:0]   noc_read_from_ibuffer_rdata;
wire                    noc_read_from_ibuffer_rvalid;
wire                    noc_read_from_ibuffer_rready;
wire                    ibuffer_rd_start;
wire                    return_done;
wire                    return_valid;
wire                    return_ready;
wire                    return_last;
wire [FLIT_WIDTH-1:0]   return_data;

// 应该不是以字节寻址
/////////// 如果DDR以字节寻址：
///////////          [2:17] 共16bit，每个bit对应一个4B，所以共 2^18B = 256 KB
// 如果DDR以128bit寻址：
//          [2:17] 共16bit，每个bit对应一个128bit=16B，所以共 2^20B = 1 MB
assign dma_rd_word_addr = dma_rd_addr[2+:(MEM_AW+2)];   //[2:17] 2+: 指从 dma_rd_addr 的第2位开始，选择MEM_AW+2位。
// [0+:(MEM_AW+2)]从0开始选择MEM_AW+2位，实际上就是0到MEM_AW+1。所以后面 MEM_AW+1{1'b0} 个0，最后补1个1
assign dma_rd_word_addr_end = dma_rd_word_addr + dma_rd_num[0+:(MEM_AW+2)] - {{MEM_AW+1{1'b0}}, 1'b1};
//用word的end地址和start地址得到word的数量
assign dma_rd_data_num = dma_rd_word_addr_end[2+:MEM_AW] - dma_rd_word_addr[2+:MEM_AW] + {{MEM_AW-1{1'b0}}, 1'b1};


idma_write_ibuffer#(
    .DATA_WIDTH        ( DATA_WIDTH ),
    .MEM_AW            ( MEM_AW ),
    .STRB_WIDTH        ( STRB_WIDTH )
)u_idma_write_ibuffer(
    .clk               ( clk               ),
    .rst_n             ( rst_n             ),
    .dma_rd_data_num   ( dma_rd_data_num),
    .dma_rd_req        ( dma_rd_req        ),
    .dma_rd_data_valid ( dma_rd_data_valid ),
    .dma_rd_data       ( dma_rd_data       ),
    .dma_rd_data_ready ( dma_rd_data_ready ),
    .dma_rd_strb       ( dma_rd_strb       ),
    .dma_write_done    ( dma_read_to_ibuffer_done      ),
    .ibuffer_cen       ( dma_read_to_ibuffer_cen       ),
    .ibuffer_wen       ( dma_read_to_ibuffer_wen       ),
    .ibuffer_ready     ( dma_read_to_ibuffer_ready     ),
    .ibuffer_addr      ( dma_read_to_ibuffer_addr      ),
    .ibuffer_wdata     ( dma_read_to_ibuffer_wdata     ),
    .ibuffer_strb      ( dma_read_to_ibuffer_strb      )
);

idma_inoc_rd_ibuffer#(
    .DATA_WIDTH      ( DATA_WIDTH ),
    .MEM_AW          ( MEM_AW ),
    .STRB_WIDTH      ( STRB_WIDTH ),
    .WORD_WIDTH      ( FLIT_WIDTH )
)u_idma_inoc_rd_ibuffer(
    .clk               ( clk              ),
    .rst_n             ( rst_n            ),
    .ibuffer_rd_start  ( ibuffer_rd_start ),
    .ibuffer_word_addr ( ibuffer_word_addr),
    .ibuffer_word_num  ( ibuffer_word_num ),
    .ibuffer_cen       ( noc_read_from_ibuffer_cen      ),
    .ibuffer_wen       ( noc_read_from_ibuffer_wen      ),
    .ibuffer_ready     ( noc_read_from_ibuffer_ready    ),
    .ibuffer_addr      ( noc_read_from_ibuffer_addr     ),
    .ibuffer_rdata     ( noc_read_from_ibuffer_rdata    ),
    .ibuffer_rvalid    ( noc_read_from_ibuffer_rvalid   ),
    .ibuffer_rready    ( noc_read_from_ibuffer_rready   ),
    .return_done       ( return_done      ),
    .return_valid      ( return_valid     ),
    .return_ready      ( return_ready     ),
    .return_last       ( return_last      ),
    .return_data       ( return_data      )
);

idma_inoc_control#(
    .FLIT_WIDTH               ( FLIT_WIDTH ),
    .APB_BASE_ADDR            ( APB_BASE_ADDR )
)u_idma_inoc_control(
    .clk                      ( clk               ),
    .rst_n                    ( rst_n             ),
    .fsm_start                ( fsm_start         ),
    .fsm_base_addr            ( fsm_base_addr     ),
    .fsm_auto_restart_en      ( fsm_auto_restart_en),
    .fsm_restart              ( fsm_restart       ),
    .ibuffer_rd_start         ( ibuffer_rd_start  ),
    .ibuffer_word_addr        ( ibuffer_word_addr ),
    .ibuffer_word_num         ( ibuffer_word_num  ),
    .return_done              ( return_done       ),
    .return_valid             ( return_valid      ),
    .return_ready             ( return_ready      ),
    .return_data              ( return_data       ),
    .return_last              ( return_last       ),
    .m0_paddr                 ( m0_paddr          ),
    .m0_psel                  ( m0_psel           ),
    .m0_penable               ( m0_penable        ),
    .m0_pready                ( m0_pready         ),
    .m0_pwrite                ( m0_pwrite         ),
    .m0_pstrb                 ( m0_pstrb          ),
    .m0_pwdata                ( m0_pwdata         ),
    .m1_paddr                 ( m1_paddr          ),
    .m1_psel                  ( m1_psel           ),
    .m1_penable               ( m1_penable        ),
    .m1_pready                ( m1_pready         ),
    .m1_pwrite                ( m1_pwrite         ),
    .m1_pstrb                 ( m1_pstrb          ),
    .m1_pwdata                ( m1_pwdata         ),
    .send_valid               ( send_valid        ),
    .send_flit                ( send_flit         ),
    .send_ready               ( send_ready        ),
    .recv_valid               ( recv_valid        ),
    .recv_flit                ( recv_flit         ),
    .recv_ready               ( recv_ready        ),
    .nodes_status             ( nodes_status      ),
    .small_loop_end_int       ( small_loop_end_int),
    .finish_intr              ( finish_intr       )

);


idma_inoc_ibuffer_arbiter#(
    .DATA_WIDTH                    ( DATA_WIDTH ),
    .MEM_AW                        ( MEM_AW ),
    .STRB_WIDTH                    ( STRB_WIDTH )
)u_idma_inoc_ibuffer_arbiter(
    .clk                           ( clk                           ),
    .rst_n                         ( rst_n                         ),
    .dma_read_start                ( dma_rd_req                    ),
    .dma_write_done                ( dma_read_to_ibuffer_done      ),
    .dma_read_to_ibuffer_cen       ( dma_read_to_ibuffer_cen       ),
    .dma_read_to_ibuffer_wen       ( dma_read_to_ibuffer_wen       ),
    .dma_read_to_ibuffer_ready     ( dma_read_to_ibuffer_ready     ),
    .dma_read_to_ibuffer_addr      ( dma_read_to_ibuffer_addr      ),
    .dma_read_to_ibuffer_wdata     ( dma_read_to_ibuffer_wdata     ),
    .dma_read_to_ibuffer_strb      ( dma_read_to_ibuffer_strb      ),
    .noc_read_from_ibuffer_cen     ( noc_read_from_ibuffer_cen         ),
    .noc_read_from_ibuffer_wen     ( noc_read_from_ibuffer_wen         ),
    .noc_read_from_ibuffer_ready   ( noc_read_from_ibuffer_ready       ),
    .noc_read_from_ibuffer_addr    ( noc_read_from_ibuffer_addr        ),
    .noc_read_from_ibuffer_rdata   ( noc_read_from_ibuffer_rdata       ),
    .noc_read_from_ibuffer_rvalid  ( noc_read_from_ibuffer_rvalid      ),
    .noc_read_from_ibuffer_rready  ( noc_read_from_ibuffer_rready      ),
    .ibuffer_cen                   ( ibuffer_cen                   ),
    .ibuffer_wen                   ( ibuffer_wen                   ),
    .ibuffer_ready                 ( ibuffer_ready                 ),
    .ibuffer_addr                  ( ibuffer_addr                  ),
    .ibuffer_wdata                 ( ibuffer_wdata                 ),
    .ibuffer_strb                  ( ibuffer_strb                  ),
    .ibuffer_rdata                 ( ibuffer_rdata                 ),
    .ibuffer_rvalid                ( ibuffer_rvalid                ),
    .ibuffer_rready                ( ibuffer_rready                )
);



endmodule