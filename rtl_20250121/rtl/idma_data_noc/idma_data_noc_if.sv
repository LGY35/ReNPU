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

  // idma 0 ports
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

  output                   rd_resi_mode     ,
  output [ADDR_WIDTH-1:0]  rd_resi_fmapA_addr,
  output [ADDR_WIDTH-1:0]  rd_resi_fmapB_addr,
  output [16-1:0]          rd_resi_addr_gap ,
  output [16-1:0]          rd_resi_loop_num,

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

localparam IDLE = 3'd0;
localparam SEND_HEAD = 3'd1;
localparam HALT = 3'd2;
localparam SEND_RDATA = 3'd3;
localparam RECV_RDATA = 3'd4;

localparam WRITE_IDLE = 3'd0;
localparam WRITE_REQ = 3'd1;
localparam WRITE_DATA = 3'd2;
localparam WAIT_BRESP = 3'd3;
localparam SEND_BRESP = 3'd4;

reg [2:0] read_cur_state;
reg [2:0] read_nxt_state;
reg [2:0] write_cur_state;
reg [2:0] write_nxt_state;

wire [3:0]      noc_read_id;
wire [14:0]     dma_rd_num_fifo [1:0];
reg  [26:0]     dma_total_num_reg;
wire [26:0]     dma_total_num_w;
reg  [26:0]     send_total_num_reg;
wire [26:0]     send_total_num_w;
wire [13:0]     read_len;
wire [14:0]     read_len_actual;
wire [18:0]     read_byte_num;
wire [13:0]     read_len_fifo;
wire [10:0]     loop_num;
wire [10:0]     loop_num_fifo;
wire [14:0]     dma_read_len;
wire [20:0]     read_byte_rgb_tmp;
wire [5:0]      read_addr_rgb_low6;
wire [14:0]     read_len_rgb;
wire [14:0]     read_len_rgb_actual;
wire [18:0]     read_byte_rgb;
wire [25:0]     dma_read_len_loop_mode;
wire [24:0]     send_len_loop_mode;
wire [1:0]      ctrl_in_flit_bit5;
wire [11:0]     ctrl_in_flit_bit18_7 [1:0];
wire [11:0]     ctrl_in_flit_bit210_199 [1:0];
wire            read_fifo_valid_out;
wire            read_fifo_ready_in;

wire [3:0]      noc_write_id;
reg  [13:0]     write_num_reg;
reg             data_in_flit_bit13;
reg  [3:0]      data_in_flit_bit17_14;

wire           noc_read_base_sel;
wire [25-1:0]  noc_read_addr_256bit;
wire [25-1:0]  noc_write_addr_256bit;
wire [ADDR_WIDTH-1:0] read_base_addr;
wire [ADDR_WIDTH-1:0] read_group_base_addr;
wire [ADDR_WIDTH-1:0] read_base_addr_after_sel;
wire [4:0]            read_addr_low_5bit;
wire [4:0]            read_addr_low_5bit_fifo;
reg  [4:0]            read_addr_low_5bit_reg;
wire [4:0]            end_addr_low_5bit;
wire [4:0]            end_addr_low_5bit_fifo;
reg  [4:0]            end_addr_low_5bit_reg;
wire                  addr_fifo_ready;
wire                  addr_fifo_valid;
wire [ADDR_WIDTH-1:0] write_base_addr;
wire [ADDR_WIDTH-1:0] dma_read_addr [1:0];
wire [13:0]  dma_read_num  [1:0];

// add for 2D DMA
wire [1:0] dma_read_mode;
wire       dma_read_mode_fifo;
wire [ADDR_WIDTH-1:0] dma_read_addr_a [1:0];
wire [ADDR_WIDTH-1:0] dma_read_addr_b [1:0];
wire [16-1:0] dma_read_gap  [1:0];
wire [16-1:0] dma_read_loop [1:0];

wire [1:0]     dma_read_ready ;
wire [1:0]     dma_read_req ;
reg  [25:0]    dma_rd_data_cnt;
wire           dma_rd_data_done;
reg  [13:0]    dma_wr_data_cnt;
wire           dma_wr_data_done;
wire [ADDR_WIDTH-1:0]  dma_write_addr [1:0];
wire [13:0]    dma_write_num  [1:0];
wire [1:0]     dma_write_ready ;
wire [1:0]     dma_write_req ;

wire [DATA_WIDTH-1:0]  send_data_payload  [1:0];
wire [1:0] send_data_last  ;
wire [1:0] send_data_ready ;
wire [1:0] send_data_valid ;

wire         align_ready_out;
wire         align_ready_in;
wire         align_valid_out;
wire         align_valid_in;
wire [255:0] align_data_out;
wire         algin_data_last;

wire [255:0] rgb_data;
wire         rgb_valid;
wire         rgb_ready;
wire [255:0] rgba_data;
wire         rgba_valid;
wire         rgba_ready;
wire         rgba_last;
reg  [26:0]  rgba_data_cnt;
wire         rgb2rgba_enable;
wire         rgb2rgba_enable_fifo;
reg          rgb2rgba_enable_reg;

wire read_fifo_hs = read_fifo_valid_out && read_fifo_ready_in;
wire data_in_hs = data_in_valid && data_in_ready;
wire rd_data_hs = rd_data_valid && rd_data_ready;
wire ctrl_in_hs = ctrl_in_valid && ctrl_in_ready;
wire wr_data_hs = wr_data_valid && wr_data_ready;
wire rgba_out_hs = rgba_valid && rgba_ready;
wire align_out_hs= align_valid_out && align_ready_in;
wire read_cur_state_is_send_rdata = (read_cur_state==SEND_RDATA);
wire read_cur_state_is_recv_rdata = (read_cur_state==RECV_RDATA);
wire read_cur_state_recv_or_send  = (read_cur_state_is_send_rdata || read_cur_state_is_recv_rdata);

// =================================================================================
//                               Processing Read Req
// =================================================================================
// =======================================
// fifo store req num and other useful info
// =======================================
assign rgb2rgba_enable        = ctrl_in_flit[253];
assign noc_read_id            = ctrl_in_flit[10:7];
assign read_len               = ctrl_in_flit[81:69] + 13'd1; // 14 bit
assign loop_num               = ctrl_in_flit[68:58];
assign read_addr_low_5bit     = read_base_addr_after_sel[4:0];
assign read_byte_num          = {read_len, 5'b0};
assign read_len_actual        = read_len + {13'b0, (|read_addr_low_5bit)};
// rgb byte num = byte_num * 3/4
assign read_byte_rgb_tmp      = read_byte_num * 2'd3;
assign read_byte_rgb          = read_byte_rgb_tmp[20:2];
assign read_addr_rgb_low6     = read_byte_rgb[4:0] + read_addr_low_5bit;
assign read_len_rgb           = read_byte_rgb[18:5] + {13'b0, read_addr_rgb_low6[5]};
assign read_len_rgb_actual    = read_len_rgb + {14'b0, (|read_addr_rgb_low6[4:0])};
assign dma_read_len           = rgb2rgba_enable ? read_len_rgb_actual : read_len_actual;
assign dma_rd_num_fifo[0]     = dma_read_len;
assign ctrl_in_flit_bit5[0]    = ctrl_in_flit[5];
assign ctrl_in_flit_bit18_7[0] = ctrl_in_flit[18:7];
assign ctrl_in_flit_bit210_199[0] = ctrl_in_flit[210:199];

fifo_with_flush #(
  .DEPTH       ( 8 ),
  .DATA_W      ( 12+12+1 + 15+1+1+11+14 )
)u_read_fifo(
  .clk         ( clk         ),
  .rst_n       ( rst_n       ),
  .flush       ( 1'b0        ),
  .f_valid_in  ( ctrl_in_valid ),
  .f_data_in   ( {ctrl_in_flit_bit210_199[0], ctrl_in_flit_bit18_7[0], ctrl_in_flit_bit5[0], 
                  dma_rd_num_fifo[0], rgb2rgba_enable, dma_read_mode[0], loop_num, read_len}),
  .f_ready_out ( ctrl_in_ready ),
  .b_valid_out ( read_fifo_valid_out ),
  .b_data_out  ( {ctrl_in_flit_bit210_199[1], ctrl_in_flit_bit18_7[1], ctrl_in_flit_bit5[1], 
                  dma_rd_num_fifo[1], rgb2rgba_enable_fifo, dma_read_mode_fifo, loop_num_fifo, read_len_fifo}),
  .b_ready_in  ( read_fifo_ready_in )
);
assign read_fifo_ready_in = (read_cur_state==IDLE) && send_data_ready[0];

// FIFO used for unalign
assign end_addr_low_5bit = rgb2rgba_enable ? (read_byte_rgb[4:0]-1) : 5'b11111; // related to output data
fifo_with_flush #(
  .DEPTH       ( 8 ),
  .DATA_W      ( 5+5 )
)u_addr_fifo(
  .clk         ( clk         ),
  .rst_n       ( rst_n       ),
  .flush       ( 1'b0        ),
  .f_valid_in  ( ctrl_in_valid ),
  .f_data_in   ( {read_addr_low_5bit, end_addr_low_5bit} ),
  .f_ready_out ( addr_fifo_ready ),
  .b_valid_out ( addr_fifo_valid ),
  .b_data_out  ( {read_addr_low_5bit_fifo, end_addr_low_5bit_fifo} ),
  .b_ready_in  ( read_fifo_ready_in )
);

// ==================== from FIFO, register info =============================
assign dma_read_len_loop_mode = loop_num_fifo * dma_rd_num_fifo[1]; // 11bit * 15bit = 26bit
assign dma_total_num_w = dma_read_mode_fifo ? {dma_read_len_loop_mode, 1'b0} : 
                                              {12'b0, dma_rd_num_fifo[1]};

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    dma_total_num_reg <= 27'b0;
  end
  else if(read_fifo_hs) begin // how many 256bit data from DMA
    dma_total_num_reg <= dma_total_num_w; 
  end
end

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    rgb2rgba_enable_reg <= 1'b0;
  end
  else if(read_fifo_hs) begin
    rgb2rgba_enable_reg <= rgb2rgba_enable_fifo;
  end
end

assign send_len_loop_mode = loop_num_fifo * read_len_fifo; // 11bit * 14bit = 25bit
assign send_total_num_w   = dma_read_mode_fifo ? {1'b0, send_len_loop_mode, 1'b0} : 
                                                 {13'b0, read_len_fifo};
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    send_total_num_reg <= 27'b0;
  end
  else if(read_fifo_hs) begin // how many 256bit data to send
    send_total_num_reg <= rgb2rgba_enable_fifo ? {1'b0, send_total_num_w} : dma_total_num_w; 
  end
end

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    read_addr_low_5bit_reg <= 5'b0;
    end_addr_low_5bit_reg  <= 5'b0;
  end
  else if(read_fifo_hs) begin
    read_addr_low_5bit_reg <= read_addr_low_5bit_fifo;
    end_addr_low_5bit_reg  <= end_addr_low_5bit_fifo;
  end
end

// ===================================
// Pipe read addr/num for DMA
// ===================================
assign noc_read_base_sel = ctrl_in_flit[254]; // 1: choose group_base_addr; 0: choose base_addr
assign noc_read_addr_256bit = ctrl_in_flit[43:19];
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
assign dma_read_req[0]   = ctrl_in_hs;
assign dma_read_addr[0]  = read_base_addr_after_sel + {2'b0, noc_read_addr_256bit, 5'b0};
assign dma_read_num[0]   = dma_rd_num_fifo[0];
assign dma_read_mode[0]  = ctrl_in_flit[57];
assign dma_read_addr_a[0]= read_base_addr_after_sel + {14'b0, ctrl_in_flit[31:19], 5'b0};
assign dma_read_addr_b[0]= read_base_addr_after_sel + {14'b0, ctrl_in_flit[56:44], 5'b0};
assign dma_read_gap[0]   = {ctrl_in_flit[144:134], 5'b0};
assign dma_read_loop[0]  = {5'b0, loop_num};


fwd_pipe#(
    .DATA_W      ( 14 + ADDR_WIDTH +1+ADDR_WIDTH*2+16*2)
)u_read_pipe(
    .clk         ( clk         ),
    .rst_n       ( rst_n       ),
    .f_valid_in  ( dma_read_req[0] ),
    .f_data_in   ( {dma_read_num[0], dma_read_addr[0], 
                    dma_read_mode[0], dma_read_addr_a[0], dma_read_addr_b[0], dma_read_gap[0], dma_read_loop[0]} ),
    .f_ready_out ( dma_read_ready[0] ),
    .b_valid_out ( dma_read_req[1] ),
    .b_data_out  ( {dma_read_num[1], dma_read_addr[1], 
                    dma_read_mode[1], dma_read_addr_a[1], dma_read_addr_b[1], dma_read_gap[1], dma_read_loop[1]} ),
    .b_ready_in  ( dma_read_ready[1] )
);
assign dma_read_ready[1] = rd_addr_ready;


// ===================================
// Pipe send data flits
// ===================================
// count rdata from dma
assign dma_rd_data_done =   read_cur_state_is_recv_rdata
                        &&  (dma_rd_data_cnt==dma_total_num_reg-1) 
                        &&  rd_data_hs
                        ;
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    dma_rd_data_cnt <= 26'b0;
  end
  else if(dma_rd_data_done) begin
    dma_rd_data_cnt <= 26'b0;
  end
  else if(rd_data_hs && read_cur_state_is_recv_rdata) begin
    dma_rd_data_cnt <= dma_rd_data_cnt + 26'b1;
  end
end

// convert to aligned data
assign align_valid_in = rd_data_valid && read_cur_state_is_recv_rdata;
idma_data_align_256b u_idma_data_align_256b(
    .clk         ( clk   ),
    .rst_n       ( rst_n ),
    .f_valid_in  ( align_valid_in  ),
    .f_data_last ( dma_rd_data_done),
    .f_data_in   ( rd_data ),
    .f_ready_out ( align_ready_out),
    .b_valid_out ( align_valid_out),
    .b_data_out  ( align_data_out ),
    .b_ready_in  ( align_ready_in ),
    .b_data_last ( algin_data_last),
    .start_addr  ( read_addr_low_5bit_reg),
    .end_addr    ( end_addr_low_5bit_reg )
);
assign align_ready_in = rgb2rgba_enable_reg ? rgb_ready : rgba_ready;

// convert RGB to RGBA when cfg_rgb2rgba_enable
assign rgb_valid = align_valid_out && rgb2rgba_enable_reg;
assign rgb_data  = align_data_out;
idma_data_rgb2rgba_256b u_idma_data_rgb2rgba_256b(
    .clk           ( clk   ),
    .rst_n         ( rst_n ),
    .f_valid_in    ( rgb_valid ),
    .f_data_last   ( algin_data_last),
    .f_data_in     ( rgb_data  ),
    .f_ready_out   ( rgb_ready ),
    .b_valid_out   ( rgba_valid),
    .b_data_out    ( rgba_data ),
    .b_ready_in    ( rgba_ready),
    .b_data_last   ( rgba_last )
);
assign rgba_ready = read_cur_state_recv_or_send && send_data_ready[0];
assign rgba_last  = read_cur_state_recv_or_send
                &&  (rgba_data_cnt==send_total_num_reg-1) 
                &&  rgba_out_hs
                ;

// count data number of RGBA
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    rgba_data_cnt <= 27'b0;
  end
  else if(rgba_last) begin
    rgba_data_cnt <= 27'b0;
  end
  else if(rgba_out_hs && read_cur_state_recv_or_send) begin
    rgba_data_cnt <= rgba_data_cnt + 27'b1;
  end
end

// to send pipe
assign send_data_valid[0] = read_fifo_hs || (rgb2rgba_enable_reg ? rgba_valid : align_valid_out);

assign send_data_payload[0] = 
  read_fifo_hs ? 
  {84'b0, ctrl_in_flit_bit210_199[1], 146'b0, ctrl_in_flit_bit5[1], 1'b1, ctrl_in_flit_bit18_7[1]} : 
  rgb2rgba_enable_reg ? rgba_data : align_data_out
  ;
assign send_data_last[0] = rgb2rgba_enable_reg ? rgba_last : algin_data_last;
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
        read_nxt_state = RECV_RDATA;
      else
        read_nxt_state = HALT;
    end
    HALT : begin
      if(send_data_ready[1])
        read_nxt_state = RECV_RDATA;
      else
        read_nxt_state = HALT;
    end
    RECV_RDATA : begin
      if(dma_rd_data_done && send_data_last[0])
        read_nxt_state = IDLE;
      else if(dma_rd_data_done)
        read_nxt_state = SEND_RDATA;
      else
        read_nxt_state = RECV_RDATA;
    end
    SEND_RDATA : begin
      if(send_data_last[0])
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
    write_num_reg <= 14'b0;
    data_in_flit_bit13 <= 1'b0;
    data_in_flit_bit17_14 <= 4'b0;
  end
  else if(dma_write_req[0]) begin 
    write_num_reg <= data_in_flit[55:43] + 13'd1;// how many 256bit data to read
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
assign dma_write_addr[0]= write_base_addr + {2'b0, noc_write_addr_256bit, 5'b0};
assign dma_write_num[0] = data_in_flit[55:43] + 13'd1;
fwd_pipe#(
    .DATA_W      ( 14 + ADDR_WIDTH )
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
assign dma_wr_data_done =   ((write_cur_state==WRITE_DATA) || (write_cur_state==WRITE_REQ))
                        &&  (dma_wr_data_cnt==write_num_reg-1) 
                        &&  wr_data_hs
                        ;
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    dma_wr_data_cnt <= 14'b0;
  end
  else if(dma_wr_data_done) begin
    dma_wr_data_cnt <= 14'b0;
  end
  else if(wr_data_hs && ((write_cur_state==WRITE_DATA) || (write_cur_state==WRITE_REQ))) begin
    dma_wr_data_cnt <= dma_wr_data_cnt + 14'b1;
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
      if(dma_wr_data_done)
        write_nxt_state = WAIT_BRESP;
      else if(wr_addr_ready)
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
assign rd_num        = {15'd0, dma_read_num[1], 3'd0};// 256bit data num -> 32bit word num(DMA need)
// assign rd_data_ready = align_ready_out && (read_cur_state==SEND_RDATA) && (read_nxt_state==SEND_RDATA);
assign rd_data_ready = align_ready_out && read_cur_state_is_recv_rdata;
assign wr_req        = (write_cur_state==WRITE_REQ);
assign wr_addr       = dma_write_addr[1];
assign wr_num        = {15'd0, dma_write_num[1], 3'd0};// 256bit data num -> 32bit word num(DMA need)
assign wr_data_valid = (write_cur_state==WRITE_DATA || write_cur_state==WRITE_REQ) && data_in_valid;
assign wr_data       = data_in_flit;
assign wr_strb       = {STRB_WIDTH{1'b1}};

assign rd_resi_mode  = dma_read_mode[1];
assign rd_resi_fmapA_addr = dma_read_addr_a[1];
assign rd_resi_fmapB_addr = dma_read_addr_b[1];
assign rd_resi_addr_gap   = dma_read_gap[1];
assign rd_resi_loop_num   = dma_read_loop[1];

assign data_out_valid = send_data_valid[1];
assign data_out_flit  = send_data_payload[1];
assign data_out_last  = send_data_last[1];
assign data_in_ready  = (write_cur_state==WRITE_IDLE || write_cur_state==WRITE_REQ || write_cur_state==WRITE_DATA) && wr_data_ready;
assign ctrl_out_valid = (write_cur_state==SEND_BRESP);
assign ctrl_out_flit  = {250'b0, data_in_flit_bit13, 1'b1, data_in_flit_bit17_14};
assign ctrl_out_last  = 1'b1;

endmodule