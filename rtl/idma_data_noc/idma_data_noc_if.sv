
//将DMA数据通过NOC（网络芯片）传输，并处理读写请求。
// 模块使用了一系列的FIFO和流水线结构来管理读写操作，将数据从NOC传输至DMA控制器，
// 或从DMA控制器传输至NOC，同时通过状态机控制这些操作的顺序。

module idma_data_noc_if #(
  parameter ADDR_WIDTH = 32,
  parameter DATA_WIDTH = 256,
  parameter STRB_WIDTH = DATA_WIDTH/8
)
(
  input                    clk,
  input                    rst_n,

  // config ports
  input  [ADDR_WIDTH-1:0]  base_addr_0,
  input  [ADDR_WIDTH-1:0]  base_addr_1,
  input  [ADDR_WIDTH-1:0]  base_addr_2,
  input  [ADDR_WIDTH-1:0]  base_addr_3,
  input  [ADDR_WIDTH-1:0]  base_addr_4,
  input  [ADDR_WIDTH-1:0]  base_addr_5,
  input  [ADDR_WIDTH-1:0]  group_base_addr_0,
  input  [ADDR_WIDTH-1:0]  group_base_addr_1,
  input  [ADDR_WIDTH-1:0]  group_base_addr_2,
  input  [ADDR_WIDTH-1:0]  group_base_addr_3,
  input  [ADDR_WIDTH-1:0]  group_base_addr_4,
  input  [ADDR_WIDTH-1:0]  group_base_addr_5,
  input  [ADDR_WIDTH-1:0]  write_base_addr_0,
  input  [ADDR_WIDTH-1:0]  write_base_addr_1,
  input  [ADDR_WIDTH-1:0]  write_base_addr_2,
  input  [ADDR_WIDTH-1:0]  write_base_addr_3,
  input  [ADDR_WIDTH-1:0]  write_base_addr_4,
  input  [ADDR_WIDTH-1:0]  write_base_addr_5,

  // idma 0 ports 用于向DMA发出读写请求，并通过DMA接口进行数据传输和控制数据的有效性及传输状态。
  output                   rd_req           ,
  output [ADDR_WIDTH-1:0]  rd_addr          ,
  output [31:0]            rd_num           ,
  input                    rd_addr_ready    ,
  input                    rd_data_valid    ,
  input  [DATA_WIDTH-1:0]  rd_data          ,
  output                   rd_data_ready    ,
  output                   wr_req           ,
  output [ADDR_WIDTH-1:0]  wr_addr          ,
  output [31:0]            wr_num           ,
  input                    wr_addr_ready    ,
  output                   wr_data_valid    ,
  output [DATA_WIDTH-1:0]  wr_data          ,
  input                    wr_data_ready    ,
  output [STRB_WIDTH-1:0]  wr_strb          ,
  input                    wr_done_intr     ,

  // noc ports
  output                   data_out_valid   ,
  output [DATA_WIDTH-1:0]  data_out_flit    ,
  output                   data_out_last    ,
  input                    data_out_ready   ,
  input                    data_in_valid    ,
  input  [DATA_WIDTH-1:0]  data_in_flit     ,
  input                    data_in_last     ,
  output                   data_in_ready    ,
  output                   ctrl_out_valid   ,
  output [DATA_WIDTH-1:0]  ctrl_out_flit    ,
  output                   ctrl_out_last    ,
  input                    ctrl_out_ready   ,
  input                    ctrl_in_valid    ,
  input  [DATA_WIDTH-1:0]  ctrl_in_flit     ,
  input                    ctrl_in_last     ,
  output                   ctrl_in_ready    
);

// 12 13 14 15
// 8  9  10 11
// 4  5  6  7
// 0  1  2  3

localparam LEFT_NOC_ID_0 = 4'd0;
localparam LEFT_NOC_ID_1 = 4'd1;
localparam LEFT_NOC_ID_2 = 4'd4;
localparam LEFT_NOC_ID_3 = 4'd5;
localparam LEFT_NOC_ID_4 = 4'd8;
localparam LEFT_NOC_ID_5 = 4'd9;

localparam RIGHT_NOC_ID_0 = 4'd2;
localparam RIGHT_NOC_ID_1 = 4'd3;
localparam RIGHT_NOC_ID_2 = 4'd6;
localparam RIGHT_NOC_ID_3 = 4'd7;
localparam RIGHT_NOC_ID_4 = 4'd10;
localparam RIGHT_NOC_ID_5 = 4'd11;

//读取：从NOC接收数据并将其发送至DMA
// 在 IDLE 状态下，如果接收到有效的读请求（read_fifo_hs），状态会切换到 SEND_HEAD，开始传输头部数据。
// 在 SEND_RDATA 状态下，模块将数据发送到DMA，直到传输完成。
localparam IDLE = 2'd0;
localparam SEND_HEAD = 2'd1;
localparam HALT = 2'd2;
localparam SEND_RDATA = 2'd3;

//写入：从NOC写入到DMA的过程
// 在 WRITE_IDLE 状态下，等待写请求（dma_write_req[0]），然后在 WRITE_DATA 状态下，发送数据到DMA。
localparam WRITE_IDLE = 3'd0;
localparam WRITE_REQ = 3'd1;
localparam WRITE_DATA = 3'd2;
localparam WAIT_BRESP = 3'd3;
localparam SEND_BRESP = 3'd4;

reg [1:0] read_cur_state;
reg [1:0] read_nxt_state;
reg [2:0] write_cur_state;
reg [2:0] write_nxt_state;

wire [3:0]      noc_read_id;
wire [13-1:0]   read_num_fifo  [0:1];
reg  [13-1:0]   read_num_reg;
wire            ctrl_in_flit_bit5 [0:1];
wire [11:0]     ctrl_in_flit_bit18_7 [0:1];
wire            read_fifo_valid_out;
wire            read_fifo_ready_in;
wire            read_fifo_hs = read_fifo_valid_out && read_fifo_ready_in;

wire [3:0]      noc_write_id;
reg  [13-1:0]   write_num_reg;
reg             data_in_flit_bit13;
reg  [3:0]      data_in_flit_bit17_14;

wire           noc_read_base_sel;
wire [25-1:0]  noc_read_addr_256bit;
wire [25-1:0]  noc_write_addr_256bit;
wire [ADDR_WIDTH-1:0] read_base_addr;
wire [ADDR_WIDTH-1:0] read_group_base_addr;
wire [ADDR_WIDTH-1:0] read_base_addr_after_sel;
wire [ADDR_WIDTH-1:0] write_base_addr;
wire [ADDR_WIDTH-1:0] dma_read_addr [0:1];
wire [13-1:0]  dma_read_num  [0:1];

wire [1:0]     dma_read_ready ;
wire [1:0]     dma_read_req ;
reg  [13-1:0]  dma_rd_data_cnt;
wire           dma_rd_data_done;
reg  [13-1:0]  dma_wr_data_cnt;
wire           dma_wr_data_done;
wire [ADDR_WIDTH-1:0]  dma_write_addr [0:1];
wire [13-1:0]  dma_write_num  [0:1];
wire [1:0]     dma_write_ready ;
wire [1:0]     dma_write_req ;

wire [DATA_WIDTH-1:0]  send_data_payload  [0:1];
wire [1:0] send_data_last  ;
wire [1:0] send_data_ready ;
wire [1:0] send_data_valid ;

wire data_in_hs = data_in_valid && data_in_ready;
wire rd_data_hs = rd_data_valid && rd_data_ready   ;
wire ctrl_in_hs = ctrl_in_valid && ctrl_in_ready;
wire wr_data_hs = wr_data_valid && wr_data_ready   ;



// =================================================================================
//                               Processing Read Req
// =================================================================================
// =======================================
// fifo store req num and other useful info
// =======================================
assign noc_read_id             = ctrl_in_flit[10:7];
assign read_num_fifo[0]        = ctrl_in_flit[81:69];
assign ctrl_in_flit_bit5[0]    = ctrl_in_flit[5];
assign ctrl_in_flit_bit18_7[0] = ctrl_in_flit[18:7];

fifo_with_flush #(
    .DEPTH       ( 16 ),
    .DATA_W      ( 12+1+13 )
)u_read_fifo(
    .clk         ( clk         ),
    .rst_n       ( rst_n       ),
    .flush       ( 1'b0 ),
    .f_valid_in  ( ctrl_in_valid ),
    .f_data_in   ( {ctrl_in_flit_bit18_7[0], ctrl_in_flit_bit5[0], read_num_fifo[0]} ),
    .f_ready_out ( ctrl_in_ready ),
    .b_valid_out ( read_fifo_valid_out ),
    .b_data_out  ( {ctrl_in_flit_bit18_7[1], ctrl_in_flit_bit5[1], read_num_fifo[1]} ),
    .b_ready_in  ( read_fifo_ready_in )
);

assign read_fifo_ready_in = (read_cur_state==IDLE) && send_data_ready[0];

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    read_num_reg      <= 13'b0;
  end
  else if(read_fifo_hs) begin
    read_num_reg      <= read_num_fifo[1]; // how many 256bit data to read
  end
end


// ===================================
// Pipe read addr/num for DMA
// ===================================
assign noc_read_base_sel = ctrl_in_flit[254]; // 1: choose group_base_addr; 0: choose base_addr
assign noc_read_addr_256bit = ctrl_in_flit[43:19];
assign dma_read_req[0]   = ctrl_in_hs;
assign read_base_addr    =  ({ADDR_WIDTH{(noc_read_id==LEFT_NOC_ID_0 || noc_read_id==RIGHT_NOC_ID_0)}} & base_addr_0)
                          | ({ADDR_WIDTH{(noc_read_id==LEFT_NOC_ID_1 || noc_read_id==RIGHT_NOC_ID_1)}} & base_addr_1)
                          | ({ADDR_WIDTH{(noc_read_id==LEFT_NOC_ID_2 || noc_read_id==RIGHT_NOC_ID_2)}} & base_addr_2)
                          | ({ADDR_WIDTH{(noc_read_id==LEFT_NOC_ID_3 || noc_read_id==RIGHT_NOC_ID_3)}} & base_addr_3)
                          | ({ADDR_WIDTH{(noc_read_id==LEFT_NOC_ID_4 || noc_read_id==RIGHT_NOC_ID_4)}} & base_addr_4)
                          | ({ADDR_WIDTH{(noc_read_id==LEFT_NOC_ID_5 || noc_read_id==RIGHT_NOC_ID_5)}} & base_addr_5)
;
assign read_group_base_addr=  ({ADDR_WIDTH{(noc_read_id==LEFT_NOC_ID_0 || noc_read_id==RIGHT_NOC_ID_0)}} & group_base_addr_0)
                            | ({ADDR_WIDTH{(noc_read_id==LEFT_NOC_ID_1 || noc_read_id==RIGHT_NOC_ID_1)}} & group_base_addr_1)
                            | ({ADDR_WIDTH{(noc_read_id==LEFT_NOC_ID_2 || noc_read_id==RIGHT_NOC_ID_2)}} & group_base_addr_2)
                            | ({ADDR_WIDTH{(noc_read_id==LEFT_NOC_ID_3 || noc_read_id==RIGHT_NOC_ID_3)}} & group_base_addr_3)
                            | ({ADDR_WIDTH{(noc_read_id==LEFT_NOC_ID_4 || noc_read_id==RIGHT_NOC_ID_4)}} & group_base_addr_4)
                            | ({ADDR_WIDTH{(noc_read_id==LEFT_NOC_ID_5 || noc_read_id==RIGHT_NOC_ID_5)}} & group_base_addr_5)
;
assign read_base_addr_after_sel = noc_read_base_sel ? read_group_base_addr : read_base_addr;
assign dma_read_addr[0]  = read_base_addr_after_sel + {noc_read_addr_256bit[ADDR_WIDTH-8-1:0], 8'b0};
assign dma_read_num[0]   = read_num_fifo[0];

fwd_pipe#(
    .DATA_W      ( 13 + ADDR_WIDTH )
)u_read_pipe(
    .clk         ( clk         ),
    .rst_n       ( rst_n       ),
    .f_valid_in  ( dma_read_req[0] ),
    .f_data_in   ( {dma_read_num[0], dma_read_addr[0]} ),
    .f_ready_out ( dma_read_ready[0] ),
    .b_valid_out ( dma_read_req[1] ),
    .b_data_out  ( {dma_read_num[1], dma_read_addr[1]} ),
    .b_ready_in  ( dma_read_ready[1] )
);
assign dma_read_ready[1] = rd_addr_ready;


// ===================================
// Pipe send data flits
// ===================================
// count rdata from dma
assign dma_rd_data_done =   (read_cur_state==SEND_RDATA) 
                        &&  (dma_rd_data_cnt==read_num_reg-1) 
                        &&  rd_data_hs
                        ;
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    dma_rd_data_cnt <= 13'b0;
  end
  else if(dma_rd_data_done) begin
    dma_rd_data_cnt <= 13'b0;
  end
  else if(rd_data_hs) begin
    dma_rd_data_cnt <= dma_rd_data_cnt + 1;
  end
end

assign send_data_valid[0] = read_fifo_hs || rd_data_hs;

assign send_data_payload[0] = read_fifo_hs ? 
                              {232'b0, ctrl_in_flit_bit5[1], 1'b1, ctrl_in_flit_bit18_7[1]} : rd_data   
                            ;
assign send_data_last[0] = dma_rd_data_done;

fwd_pipe#(
    .DATA_W      ( 1 + DATA_WIDTH )
)u_send_data_pipe(
    .clk         ( clk         ),
    .rst_n       ( rst_n       ),
    .f_valid_in  ( send_data_valid[0] ),
    .f_data_in   ( {send_data_last[0], send_data_payload[0]} ),
    .f_ready_out ( send_data_ready[0] ),
    .b_valid_out ( send_data_valid[1] ),
    .b_data_out  ( {send_data_last[1], send_data_payload[1]} ),
    .b_ready_in  ( send_data_ready[1] )
);
assign send_data_ready[1] = data_out_ready;


// ===================================
// Read FSM
// ===================================
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    read_cur_state <= IDLE;
  end
  else begin
    read_cur_state <= read_nxt_state;
  end
end

always @* begin
  case(read_cur_state)
    IDLE : begin
      if(read_fifo_hs)
        read_nxt_state = SEND_HEAD;
      else
        read_nxt_state = IDLE;
    end
    SEND_HEAD : begin
      if(send_data_ready[1])
        read_nxt_state = SEND_RDATA;
      else
        read_nxt_state = HALT;
    end
    HALT : begin
      if(send_data_ready[1])
        read_nxt_state = SEND_RDATA;
      else
        read_nxt_state = HALT;
    end
    SEND_RDATA : begin
      if(dma_rd_data_done)
        read_nxt_state = IDLE;
      else
        read_nxt_state = SEND_RDATA;
    end
    default:
      read_nxt_state = IDLE;
  endcase
end



// =================================================================================
//                               Processing Write Req
// =================================================================================
// =======================================
// reg store req num and other useful info
// =======================================
assign noc_write_id = data_in_flit[17:14];

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    write_num_reg <= 13'b0;
    data_in_flit_bit13 <= 1'b0;
    data_in_flit_bit17_14 <= 4'b0;
  end
  else if(dma_write_req[0]) begin 
    write_num_reg <= data_in_flit[55:43];// how many 256bit data to read
    data_in_flit_bit13 <= data_in_flit[13];
    data_in_flit_bit17_14 <= noc_write_id;
  end
end


// ===================================
// Pipe write addr/num/wdata for DMA
// ===================================
assign write_base_addr   =  ({ADDR_WIDTH{(noc_write_id==LEFT_NOC_ID_0 || noc_write_id==RIGHT_NOC_ID_0)}} & write_base_addr_0)
                          | ({ADDR_WIDTH{(noc_write_id==LEFT_NOC_ID_1 || noc_write_id==RIGHT_NOC_ID_1)}} & write_base_addr_1)
                          | ({ADDR_WIDTH{(noc_write_id==LEFT_NOC_ID_2 || noc_write_id==RIGHT_NOC_ID_2)}} & write_base_addr_2)
                          | ({ADDR_WIDTH{(noc_write_id==LEFT_NOC_ID_3 || noc_write_id==RIGHT_NOC_ID_3)}} & write_base_addr_3)
                          | ({ADDR_WIDTH{(noc_write_id==LEFT_NOC_ID_4 || noc_write_id==RIGHT_NOC_ID_4)}} & write_base_addr_4)
                          | ({ADDR_WIDTH{(noc_write_id==LEFT_NOC_ID_5 || noc_write_id==RIGHT_NOC_ID_5)}} & write_base_addr_5)
;
assign noc_write_addr_256bit = data_in_flit[42:18];
assign dma_write_req[0] = data_in_hs && (write_cur_state==WRITE_IDLE);
// assign dma_write_addr[0]= write_base_addr + {noc_write_addr_256bit[ADDR_WIDTH-8-1:0], 8'b0}; 多补了0，而且没有取全，33bit，截掉了1bit.(noc_write_addr_256bit是25bit)
assign dma_write_addr[0]= write_base_addr + {2'b0, noc_write_addr_256bit, 5'b0};
assign dma_write_num[0] = data_in_flit[55:43];
fwd_pipe#(
    .DATA_W      ( 13 + ADDR_WIDTH )
)u_write_pipe(
    .clk         ( clk         ),
    .rst_n       ( rst_n       ),
    .f_valid_in  ( dma_write_req[0] ),
    .f_data_in   ( {dma_write_num[0], dma_write_addr[0]} ),
    .f_ready_out ( dma_write_ready[0] ),
    .b_valid_out ( dma_write_req[1] ),
    .b_data_out  ( {dma_write_num[1], dma_write_addr[1]} ),
    .b_ready_in  ( dma_write_ready[1] )
); 
assign dma_write_ready[1] = wr_addr_ready;


// ===================================
// Write FSM
// ===================================
// count wdata to dma
assign dma_wr_data_done =   (write_cur_state==WRITE_DATA) 
                        &&  (dma_wr_data_cnt==write_num_reg-1) 
                        &&  wr_data_hs
                        ;
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    dma_wr_data_cnt <= 13'b0;
  end
  else if(dma_wr_data_done) begin
    dma_wr_data_cnt <= 13'b0;
  end
  else if(wr_data_hs) begin
    dma_wr_data_cnt <= dma_wr_data_cnt + 1;
  end
end

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    write_cur_state <= WRITE_IDLE;
  end
  else begin
    write_cur_state <= write_nxt_state;
  end
end

always @* begin
  case(write_cur_state)
    WRITE_IDLE : begin
      if(dma_write_req[0])
        write_nxt_state = WRITE_REQ;
      else
        write_nxt_state = WRITE_IDLE;
    end
    WRITE_REQ : begin
      if(wr_addr_ready)
        write_nxt_state = WRITE_DATA;
      else
        write_nxt_state = WRITE_REQ;
    end
    WRITE_DATA : begin
      if(dma_wr_data_done)
        write_nxt_state = WAIT_BRESP;
      else
        write_nxt_state = WRITE_DATA;
    end
    WAIT_BRESP : begin
      if(wr_done_intr)
        write_nxt_state = SEND_BRESP;
      else
        write_nxt_state = WAIT_BRESP;
    end
    SEND_BRESP : begin
      if(ctrl_out_ready)
        write_nxt_state = WRITE_IDLE;
      else
        write_nxt_state = SEND_BRESP;
    end
    default:
      write_nxt_state = WRITE_IDLE;
  endcase
end


// ===================================
// output
// ===================================
assign rd_req        = dma_read_req[1];
assign rd_addr       = dma_read_addr[1];
assign rd_num        = {16'd0, dma_read_num[1], 3'd0};// 256bit data num -> 32bit word num(DMA need)
assign rd_data_ready = (read_cur_state==SEND_RDATA) && send_data_ready[0];
assign wr_req        = (write_cur_state==WRITE_REQ);
assign wr_addr       = dma_write_addr[1];
assign wr_num        = {16'd0, dma_write_num[1], 3'd0};// 256bit data num -> 32bit word num(DMA need)
assign wr_data_valid = (write_cur_state==WRITE_DATA || write_cur_state==WRITE_REQ) && data_in_valid;
assign wr_data       = data_in_flit;
assign wr_strb       = {STRB_WIDTH{1'b1}};

assign data_out_valid = send_data_valid[1];
assign data_out_flit  = send_data_payload[1];
assign data_out_last  = send_data_last[1];
assign data_in_ready  = (write_cur_state==WRITE_IDLE || write_cur_state==WRITE_REQ || write_cur_state==WRITE_DATA);
assign ctrl_out_valid = (write_cur_state==SEND_BRESP);
assign ctrl_out_flit  = {250'b0, data_in_flit[13], 1'b1, data_in_flit_bit17_14};
assign ctrl_out_last  = 1'b1;

endmodule