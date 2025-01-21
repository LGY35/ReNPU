module idma_sync_256b_noc_if #(
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
  input  [ADDR_WIDTH-1:0]  base_addr_6,
  input  [ADDR_WIDTH-1:0]  base_addr_7,
  input  [ADDR_WIDTH-1:0]  base_addr_8,
  input  [ADDR_WIDTH-1:0]  base_addr_9,
  input  [ADDR_WIDTH-1:0]  base_addr_10,
  input  [ADDR_WIDTH-1:0]  base_addr_11,

  // idma ports
  output                   rd_req        ,
  output [ADDR_WIDTH-1:0]  rd_addr       ,
  output [31:0]            rd_num        ,
  input                    rd_addr_ready ,
  input                    rd_data_valid ,
  input  [DATA_WIDTH-1:0]  rd_data       ,
  output                   rd_data_ready ,
  output                   wr_req        ,
  output [ADDR_WIDTH-1:0]  wr_addr       ,
  output [31:0]            wr_num        ,
  input                    wr_addr_ready ,
  output                   wr_data_valid ,
  output [DATA_WIDTH-1:0]  wr_data       ,
  input                    wr_data_ready ,
  output [STRB_WIDTH-1:0]  wr_strb       ,
  input                    wr_done_intr  ,

  // noc ports
  output                   send_valid    ,
  output [DATA_WIDTH-1:0]  send_flit     ,
  output                   send_last     ,
  input                    send_ready    ,

  input                    recv_valid    ,
  input  [DATA_WIDTH-1:0]  recv_flit     ,
  input                    recv_last     ,
  output                   recv_ready  
);

// rw 0: read  1: write
localparam RW_POS = 0; 
// node coordinate, 4bits
localparam COOR_START_POS = 2;
localparam COOR_WIDTH = 4;
// base addr, 16 bits
localparam BASE_START_POS = 56; 
localparam BASE_WIDTH = 16; 
// length, 20 bits
localparam LEN_START_POS  = 72;
localparam LEN_WIDTH  = 20;
// write response, 1 bits
localparam RESP_START_POS = 8;
// write response flag, 1 bits
localparam RESP_FLAG_POS = 9;

localparam IDLE = 3'd0;
localparam SEND_CFG_1 = 3'd1;
localparam SEND_CFG_2 = 3'd2;
localparam SEND_RDATA = 3'd3;
localparam WRITE = 3'd4;
localparam WDATA = 3'd5;
localparam WRESP = 3'd6;

reg [2:0] cur_state;
reg [2:0] nxt_state;

wire switch_cfg_1;
wire switch_cfg_2;
wire switch_send_rdata;
wire send_rdata_switch_idle;
wire switch_write;
wire switch_wdata;
wire switch_wresp;

wire          recv_fifo_valid_in;
wire  [127:0] recv_fifo_data_in;
wire          recv_fifo_ready_out;
wire          recv_fifo_valid_out;
wire  [127:0] recv_fifo_data_out;
wire          recv_fifo_ready_in;
wire          recv_fifo_full;

wire recv_req_is_read;
wire [COOR_WIDTH-1:0] recv_coor;
wire [ADDR_WIDTH-1:0] base_addr;
wire [BASE_WIDTH-1:0] recv_base_addr;
wire [ADDR_WIDTH-1:0] recv_req_addr [0:1];
wire [LEN_WIDTH-1:0]  recv_req_num  [0:1];
wire [1:0] recv_req_ready ;
wire [1:0] recv_req_valid ;

wire [DATA_WIDTH-1:0]  recv_wdata  [0:1];
wire [1:0] recv_wdata_ready;
wire [1:0] recv_wdata_valid;
wire [1:0] recv_wdata_handshake;

wire [DATA_WIDTH-1:0]  send_pipe_data  [0:1];
wire [1:0] send_pipe_last  ;
wire [1:0] send_pipe_ready ;
wire [1:0] send_pipe_valid ;

wire send_flit_handshake = send_valid && send_ready;
wire recv_flit_handshake = recv_valid && recv_ready;
wire rd_handshake = rd_req && rd_addr_ready;
wire wr_handshake = wr_req && wr_addr_ready;

reg [LEN_WIDTH-1:0] send_rdata_cnt;
reg [LEN_WIDTH-1:0] send_rdata_cnt_nxt;
reg [LEN_WIDTH-1:0] recv_wdata_cnt;
reg [LEN_WIDTH-1:0] rd_num_reg;
reg [LEN_WIDTH-1:0] wr_num_reg;

// ===================================
// FIFO store receive flits(except wdata)
// ===================================
assign recv_fifo_full = !recv_fifo_ready_out;
assign recv_fifo_valid_in = recv_valid;
assign recv_fifo_data_in = recv_flit[127:0];
fifo_with_flush #(
    .DEPTH       ( 2 ),
    .DATA_W      ( 128 )
)u_recv_fifo(
    .clk         ( clk         ),
    .rst_n       ( rst_n       ),
    .flush       ( (cur_state==WRESP) && (nxt_state==IDLE) ),
    .f_valid_in  ( recv_fifo_valid_in  ),
    .f_data_in   ( recv_fifo_data_in   ),
    .f_ready_out ( recv_fifo_ready_out ),
    .b_valid_out ( recv_fifo_valid_out ),
    .b_data_out  ( recv_fifo_data_out  ),
    .b_ready_in  ( recv_fifo_ready_in  )
);
assign recv_fifo_ready_in = switch_cfg_1 || switch_cfg_2;

always @(posedge clk or negedge rst_n) begin
  if (rst_n==1'b0) begin
    rd_num_reg <= {LEN_WIDTH{1'b0}};
  end
  else if(switch_cfg_1) begin
    rd_num_reg <= recv_req_num[0];
  end
end

always @(posedge clk or negedge rst_n) begin
  if (rst_n==1'b0) begin
    wr_num_reg <= {LEN_WIDTH{1'b0}};
  end
  else if(switch_write) begin
    wr_num_reg <= recv_req_num[0];
  end
end

// ===================================
// Pipe store addr/num
// ===================================
assign recv_req_is_read = (recv_fifo_data_out[RW_POS]==1'b0);
assign recv_coor = recv_fifo_data_out[COOR_START_POS+:COOR_WIDTH];
assign recv_base_addr = recv_fifo_data_out[BASE_START_POS+:BASE_WIDTH];
assign base_addr =   ({ADDR_WIDTH{(recv_coor==4'd0)}} & base_addr_0)
                    |({ADDR_WIDTH{(recv_coor==4'd1)}} & base_addr_1)
                    |({ADDR_WIDTH{(recv_coor==4'd2)}} & base_addr_2)
                    |({ADDR_WIDTH{(recv_coor==4'd3)}} & base_addr_3)
                    |({ADDR_WIDTH{(recv_coor==4'd4)}} & base_addr_4)
                    |({ADDR_WIDTH{(recv_coor==4'd5)}} & base_addr_5)
                    |({ADDR_WIDTH{(recv_coor==4'd6)}} & base_addr_6)
                    |({ADDR_WIDTH{(recv_coor==4'd7)}} & base_addr_7)
                    |({ADDR_WIDTH{(recv_coor==4'd8)}} & base_addr_8)
                    |({ADDR_WIDTH{(recv_coor==4'd9)}} & base_addr_9)
                    |({ADDR_WIDTH{(recv_coor==4'd10)}} & base_addr_10)
                    |({ADDR_WIDTH{(recv_coor==4'd11)}} & base_addr_11)
                    ;

assign recv_req_addr[0] = base_addr + {{(ADDR_WIDTH-BASE_WIDTH){1'b0}}, recv_base_addr};
assign recv_req_num[0]  = recv_fifo_data_out[LEN_START_POS+:LEN_WIDTH];
assign recv_req_valid[0] = switch_cfg_1 || switch_write;
fwd_pipe#(
    .DATA_W      ( ADDR_WIDTH + LEN_WIDTH )
)u_addr_num_pipe(
    .clk         ( clk         ),
    .rst_n       ( rst_n       ),
    .f_valid_in  ( recv_req_valid[0] ),
    .f_data_in   ( {recv_req_num[0], recv_req_addr[0]} ),
    .f_ready_out ( recv_req_ready[0] ),
    .b_valid_out ( recv_req_valid[1] ),
    .b_data_out  ( {recv_req_num[1], recv_req_addr[1]} ),
    .b_ready_in  ( recv_req_ready[1] )
);
assign recv_req_ready[1] = (cur_state==WRITE) ? wr_addr_ready : rd_addr_ready;

// ===================================
// Pipe store wdata
// ===================================
assign recv_wdata_valid[0] = recv_flit_handshake && recv_fifo_full;
assign recv_wdata[0] = recv_flit;
fwd_pipe#(
    .DATA_W      ( DATA_WIDTH )
)u_wdata_pipe(
    .clk         ( clk         ),
    .rst_n       ( rst_n       ),
    .f_valid_in  ( recv_wdata_valid[0] ),
    .f_data_in   ( recv_wdata[0] ),
    .f_ready_out ( recv_wdata_ready[0] ),
    .b_valid_out ( recv_wdata_valid[1] ),
    .b_data_out  ( recv_wdata[1] ),
    .b_ready_in  ( recv_wdata_ready[1] )
);
assign recv_wdata_ready[1] = wr_data_ready;
assign recv_wdata_handshake = recv_wdata_valid & recv_wdata_ready;

always @(posedge clk or negedge rst_n) begin
  if (rst_n==1'b0) begin
    recv_wdata_cnt <= {LEN_WIDTH{1'b0}};
  end
  else if(recv_wdata_handshake[0] && (recv_wdata_cnt==wr_num_reg-1)) begin
    recv_wdata_cnt <= {LEN_WIDTH{1'b0}};
  end
  else if(recv_wdata_handshake[0]) begin
    recv_wdata_cnt <= recv_wdata_cnt + 1'b1;
  end
end

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

assign switch_cfg_1 = recv_fifo_full && (recv_fifo_data_out[RW_POS]==1'b0) && (cur_state==IDLE);
assign switch_cfg_2 = send_flit_handshake && (cur_state==SEND_CFG_1);
assign switch_send_rdata = send_flit_handshake;
assign send_rdata_switch_idle = (send_rdata_cnt==rd_num_reg-1) && send_flit_handshake;
assign switch_write = recv_fifo_full && (recv_fifo_data_out[RW_POS]==1'b1) && (cur_state==IDLE);
assign switch_wdata = wr_handshake;
assign switch_wresp = wr_done_intr;

always @* begin
  case(cur_state)
    IDLE : begin
      if(switch_cfg_1)
        nxt_state = SEND_CFG_1;
      else if(switch_write)
        nxt_state = WRITE;
      else
        nxt_state = IDLE;
    end
    SEND_CFG_1 : begin
      if(switch_cfg_2)
        nxt_state = SEND_CFG_2;
      else
        nxt_state = SEND_CFG_1;
    end
    SEND_CFG_2 : begin
      if(switch_send_rdata)
        nxt_state = SEND_RDATA;
      else
        nxt_state = SEND_CFG_2;
    end
    SEND_RDATA : begin
      if(send_rdata_switch_idle)
        nxt_state = IDLE;
      else
        nxt_state = SEND_RDATA;
    end
    WRITE : begin
      if(switch_wdata)
        nxt_state = WDATA;
      else
        nxt_state = WRITE;
    end
    WDATA : begin
      if(switch_wresp)
        nxt_state = WRESP;
      else
        nxt_state = WDATA;
    end
    WRESP : begin
      if(send_flit_handshake)
        nxt_state = IDLE;
      else
        nxt_state = WRESP;
    end
    default:
      nxt_state = IDLE;
  endcase
end

// ===================================
// Pipe send flits
// ===================================
assign send_pipe_valid[0] = (nxt_state==SEND_CFG_1)
                          ||(nxt_state==SEND_CFG_2)
                          ||((nxt_state==SEND_RDATA) && rd_data_valid)
                          ||(nxt_state==WRESP);

assign send_pipe_data[0] = ({DATA_WIDTH{(nxt_state==SEND_CFG_1)}} & {128'b0, recv_fifo_data_out[127:1], 1'b1})
                          |({DATA_WIDTH{(nxt_state==SEND_CFG_2)}} & recv_fifo_data_out)
                          |({DATA_WIDTH{(nxt_state==SEND_RDATA)}} & rd_data)
                          |({DATA_WIDTH{(nxt_state==WRESP)}}      & {126'b0, 1'b1, 1'b1})
                          ;
assign send_pipe_last[0] = ({(nxt_state==SEND_CFG_1)} & 1'b0)
                          |({(nxt_state==SEND_CFG_2)} & 1'b0)
                          |({(nxt_state==SEND_RDATA)} & (send_rdata_cnt_nxt==rd_num_reg-1))
                          |({(nxt_state==WRESP)}      & 1'b1)
                          ;

fwd_pipe#(
    .DATA_W      ( 1 + DATA_WIDTH )
)u_send_pipe(
    .clk         ( clk         ),
    .rst_n       ( rst_n       ),
    .f_valid_in  ( send_pipe_valid[0] ),
    .f_data_in   ( {send_pipe_last[0], send_pipe_data[0]} ),
    .f_ready_out ( send_pipe_ready[0] ),
    .b_valid_out ( send_pipe_valid[1] ),
    .b_data_out  ( {send_pipe_last[1], send_pipe_data[1]} ),
    .b_ready_in  ( send_pipe_ready[1] )
);
assign send_pipe_ready[1] = send_ready;

assign send_rdata_cnt_nxt = send_rdata_switch_idle ? {LEN_WIDTH{1'b0}} :
                            (send_flit_handshake && (cur_state==SEND_RDATA)) ? 
                            (send_rdata_cnt + 1'b1) : send_rdata_cnt;
always @(posedge clk or negedge rst_n) begin
  if (rst_n==1'b0) begin
    send_rdata_cnt <= {LEN_WIDTH{1'b0}};
  end
  else begin
    send_rdata_cnt <= send_rdata_cnt_nxt;
  end
end

// ===================================
// output
// ===================================
assign rd_req = (cur_state!=WRITE) && recv_req_valid[1];
assign rd_addr = recv_req_addr[1];
assign rd_num  = {9'd0, recv_req_num[1], 3'd0}; // data num -> word num(DMA input)
assign rd_data_ready = (nxt_state==SEND_RDATA) && send_pipe_ready[0];

assign wr_req = (cur_state==WRITE) && recv_req_valid[1];
assign wr_addr = recv_req_addr[1];
assign wr_num  = {9'd0, recv_req_num[1], 3'd0}; // data num -> word num(DMA input)
assign wr_data_valid = recv_wdata_valid[1];
assign wr_data = recv_wdata[1];
assign wr_strb = {STRB_WIDTH{1'b1}};

assign send_valid = send_pipe_valid[1];
assign send_flit  = send_pipe_data[1];
assign send_last  = send_pipe_last[1];
assign recv_ready = ((nxt_state==WRITE || nxt_state==WDATA || nxt_state==WRESP) && recv_wdata_ready[0])
                  ||((nxt_state!=WRITE && nxt_state!=WDATA && nxt_state!=WRESP) && recv_fifo_ready_out)
                  ;
endmodule