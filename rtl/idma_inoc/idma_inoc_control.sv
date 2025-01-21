
//控制和管理数据流：连接到ibuffer、APB接口、以及NoC接口。
//主要负责启动和监控数据读取、处理FSM的启动和重新启动、以及控制数据发送到NoC和从NoC接收数据。

module idma_inoc_control
#(
    parameter FLIT_WIDTH = 32,
    parameter APB_BASE_ADDR = 12'h30
) 
(
    input clk,
    input rst_n,

    // config FSM addr and start
    input                  fsm_start,
    input  [16:0]          fsm_base_addr, // ibuffer word addr
    input                  fsm_auto_restart_en, // if 1, auto restart next loop
    input                  fsm_restart, // if pulse asserts, restart next loop

    // read ibuffer of DMA base addr, or FSM code, or instruction write to noc
    output                 ibuffer_rd_start,
    output [16:0]          ibuffer_word_addr,
    output [12:0]          ibuffer_word_num,
    input                  return_valid,    //ibuffer的数据valid
    output                 return_ready,    //FSM准备好接收指令，ready
    input [FLIT_WIDTH-1:0] return_data,
    input                  return_last,
    input                  return_done,

    // apb interface master 0
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

    // send to noc
    output [11:0]          send_valid ,
    output [11:0][FLIT_WIDTH-1:0]send_flit  ,
    input  [11:0]          send_ready ,

    // receive from noc
    input  [11:0]          recv_valid ,
    input  [11:0][FLIT_WIDTH-1:0]recv_flit  ,
    output [11:0]          recv_ready ,

    // send intr
    output [11:0]          nodes_status,
    output                 small_loop_end_int,
    output                 finish_intr
);

//opcode
localparam OP_BASE = 7'd0;
localparam OP_GROUP = 7'd1;
localparam OP_LAST = 7'd2;
localparam OP_FINISH = 7'd3;

// 取feature基地址
localparam APB_BASE_ADDR_GROUP_0 = 12'h5c;
localparam APB_BASE_ADDR_GROUP_1 = 12'h60;
localparam APB_BASE_ADDR_GROUP_2 = 12'h5c;
localparam APB_BASE_ADDR_GROUP_3 = 12'h60;
localparam APB_BASE_ADDR_GROUP_4 = 12'h64;
localparam APB_BASE_ADDR_GROUP_5 = 12'h68;
localparam APB_BASE_ADDR_GROUP_6 = 12'h64;
localparam APB_BASE_ADDR_GROUP_7 = 12'h68;
localparam APB_BASE_ADDR_GROUP_8 = 12'h6c;
localparam APB_BASE_ADDR_GROUP_9 = 12'h70;
localparam APB_BASE_ADDR_GROUP_10 = 12'h6c;
localparam APB_BASE_ADDR_GROUP_11 = 12'h70;

// 写回地址
localparam APB_BASE_ADDR_WRITE = 12'h74;
localparam APB_BASE_ADDR_WRITE_0 = 12'h74;
localparam APB_BASE_ADDR_WRITE_1 = 12'h78;
localparam APB_BASE_ADDR_WRITE_2 = 12'h74;
localparam APB_BASE_ADDR_WRITE_3 = 12'h78;
localparam APB_BASE_ADDR_WRITE_4 = 12'h7c;
localparam APB_BASE_ADDR_WRITE_5 = 12'h80;
localparam APB_BASE_ADDR_WRITE_6 = 12'h7c;
localparam APB_BASE_ADDR_WRITE_7 = 12'h80;
localparam APB_BASE_ADDR_WRITE_8 = 12'h84;
localparam APB_BASE_ADDR_WRITE_9 = 12'h88;
localparam APB_BASE_ADDR_WRITE_10 = 12'h84;
localparam APB_BASE_ADDR_WRITE_11 = 12'h88;

//握手成功
wire return_handshake = return_valid && return_ready;

// config ports
wire                  base1_info_valid;
wire  [12-1:0]        group_info;
wire                  group_info_valid;
wire  [FLIT_WIDTH-1:0]cfg_info;
wire                  cfg_info_valid;
wire                  cfg_fifo_valid_in;
wire  [FLIT_WIDTH-1:0]cfg_fifo_data_in;
wire                  cfg_fifo_ready_out;
wire                  cfg_fifo_valid_out;
wire  [FLIT_WIDTH-1:0]cfg_fifo_data_out;
wire                  cfg_fifo_ready_in;
wire                  cfg_fifo_out_handshake;
wire                  group_fifo_valid_in;
wire  [12-1:0]        group_fifo_data_in;
wire                  group_fifo_ready_out;
wire                  group_fifo_valid_out;
wire  [12-1:0]        group_fifo_data_out;
wire                  group_fifo_ready_in;
wire                  group_fifo_out_handshake;
reg [3:0] cfg_fifo_cnt;
reg [3:0] send_cfg_cnt;

logic [11:0] lut_group [11:0];
logic [11:0] lut_flush;
logic [11:0] group_info_reg;
logic [11:0] group_info_next;
logic [11:0] group_info_all;

logic [11:0] recv_gnt_next ;
logic [11:0] recv_gnt_reg;
logic [11:0] recv_gnt_curr ;
logic [11:0] recv_intr     ;
logic [11:0] recv_intr_valid;
logic [11:0] recv_req_valid;
wire         recv_pipe_valid_in;
wire  [20:0] recv_pipe_data_in;
wire         recv_pipe_ready_out;
wire         recv_pipe_valid_out;
wire  [20:0] recv_pipe_data_out;
wire         recv_pipe_ready_in;
wire         recv_pipe_in_handshake;

// 状态机
localparam IDLE      = 3'd0;
localparam RD_BASE   = 3'd1;
localparam RD_INFO   = 3'd2;
localparam SEND_CFG  = 3'd3;
localparam RECV_NOC  = 3'd4;
localparam SEND_DATA = 3'd5;
localparam WAIT_INTR = 3'd6;
localparam FINISH    = 3'd7;
reg [2:0] cur_state;
reg [2:0] nxt_state;

//   m0  |    m1
// 8  9  |  10 11
// 4  5  |  6  7
// 0  1  |  2  3
localparam GROUP_VALID_BITS_M0 = 12'b001100110011;
localparam GROUP_VALID_BITS_M1 = 12'b110011001100;
localparam APB_IDLE = 2'd0;
localparam APB_GROUP = 2'd1;
localparam APB_SEND = 2'd2;
reg [1:0] apb_state_curr;
reg [1:0] apb_state_next;

wire send_flit_valid_pipe [1:0];
wire send_flit_last_pipe [1:0];
wire send_flit_ready_pipe [1:0];
wire [FLIT_WIDTH-1:0] send_flit_pipe [1:0];
wire [12-1:0] group_info_pipe [1:0];
wire send_flit_handshake = | (send_valid & send_ready);
wire send_cfg_done;
wire send_flit_done;

reg [16:0] small_loop_cnt;
wire small_loop_cnt_clear;
wire small_loop_cnt_incr;
reg small_loop_processing;
reg [3:0] return_info_cnt;
wire return_info_cnt_clear;
wire return_info_cnt_incr;
reg [1:0] return_base1_cfg_group_cnt; // 0: base1;  1: cfg;  2: group
wire return_base1_cfg_group_cnt_clr;
wire return_base1_cfg_group_cnt_inc;

//return_data就是ibuffer中的一个flit，即32bit的指令/数据
wire return_data_op_base = (return_data[6:0]==OP_BASE);
wire return_data_op_group= (return_data[6:0]==OP_GROUP);
wire return_data_op_last = (return_data[6:0]==OP_LAST);
wire return_data_op_finish = (return_data[6:0]==OP_FINISH);
wire [11:0] return_group_info = return_data[27:16];
wire return_last_or_finish;

reg [11:0] m0_paddr_reg;
reg [11:0] m1_paddr_reg;
reg [11:0] m0_paddr_next;
reg [11:0] m1_paddr_next;
reg m0_penable_reg;
reg m1_penable_reg;
reg [32-1:0]        m0_pwdata_reg;
reg [32-1:0]        m1_pwdata_reg;
wire m0_handshake = m0_penable && m0_pready;
wire m1_handshake = m1_penable && m1_pready;
// reg m0_m1_sel_reg;
wire send_base_to_m0;
wire send_base_to_m1;
reg [11:0] apb_group_reg;
wire [11:0] apb_group_next;
wire [11:0] apb_group_m0;
wire [11:0] apb_group_m1;
wire [11:0] apb_group_m0_onehot;
wire [11:0] apb_group_m1_onehot;
wire apb_done;
reg finish_flag;
reg last_flag;
wire read_cfg_info_first_start;
reg  read_cfg_info_first_start_reg;
wire read_cfg_info_loop_start;
reg  read_cfg_info_loop_start_reg;
wire read_noc_instr_start;
wire return_apb_ready;
wire return_cfg_fifo_ready;
wire return_send_pipe_ready;
wire group_fifo_in_handshake;
reg small_loop_end_flag;
wire read_base_loop_start;
reg [16:0] ibuffer_word_addr_info;
reg read_base_loop_start_reg;


// ======================================================================
// ALL    Counters   HERE
// ======================================================================
// count base, cfg info and group info number   
//每个小循环中的基地址、配置信息、组信息的处理
assign small_loop_cnt_clear = (return_data_op_last || return_data_op_finish) && return_handshake;//清零条件：处理到小循环中的最后一个task，或最后一个小循环，且正确握手
assign small_loop_cnt_incr  = small_loop_processing && return_handshake;// 递增条件：正在处理中，并且握手成功，那么进入下一个小循环
always @(posedge clk or negedge rst_n) begin
    if (rst_n==1'b0) begin
        small_loop_cnt <= 17'd0;
    end
    else if(small_loop_cnt_clear) begin
        small_loop_cnt <= 17'd0;
    end
    else if(small_loop_cnt_incr) begin
        small_loop_cnt <= small_loop_cnt + 1;
    end
end

// count info num
//当前已经处理的小循环的信息
assign return_info_cnt_clear = ((return_info_cnt==4'd11) && return_handshake) || small_loop_cnt_clear;  //小循环清0或者 
assign return_info_cnt_incr = (cur_state==RD_INFO) && return_handshake;
always @(posedge clk or negedge rst_n) begin
    if (rst_n==1'b0) begin
        return_info_cnt <= 4'd0;
    end
    else if(return_info_cnt_clear) begin
        return_info_cnt <= 4'd0;
    end
    else if(return_info_cnt_incr) begin
        return_info_cnt <= return_info_cnt + 4'd1;
    end
end

// when return is info, 0 -> 1 -> 2 means: base1 -> cfg -> group
assign return_base1_cfg_group_cnt_clr = (return_base1_cfg_group_cnt==2'd2) && return_handshake;
assign return_base1_cfg_group_cnt_inc = (cur_state==RD_INFO) && return_handshake;
always @(posedge clk or negedge rst_n) begin
    if (rst_n==1'b0) begin
        return_base1_cfg_group_cnt <= 2'd0;
    end
    else if(return_base1_cfg_group_cnt_clr) begin
        return_base1_cfg_group_cnt <= 2'd0;
    end
    else if(return_base1_cfg_group_cnt_inc) begin
        return_base1_cfg_group_cnt <= return_base1_cfg_group_cnt + 2'd1;
    end
end


// total num of cfg to send
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cfg_fifo_cnt <= 4'd0;
    end
    else if(send_cfg_done) begin
        cfg_fifo_cnt <= 4'd0;
    end
    else if(cfg_fifo_valid_in && !cfg_fifo_out_handshake) begin
        cfg_fifo_cnt <= cfg_fifo_cnt + 1;
    end
end

// ======================================================================
// Store cfg(flit to send) and group into FIFO
// ======================================================================
assign cfg_info_valid = small_loop_processing 
                    && (cur_state==RD_INFO) 
                    && (return_base1_cfg_group_cnt==2'd1) 
                    && return_valid
                    ;
assign cfg_info = return_data;

assign group_info_valid =   small_loop_processing
                        && !return_data_op_base
                        && (cur_state==RD_INFO)
                        && (return_base1_cfg_group_cnt==2'd2) 
                        && return_valid
                        ;
assign group_info = return_data[27:16];

// store config info into fifo
assign cfg_fifo_valid_in = cfg_info_valid;
assign cfg_fifo_data_in  = cfg_info;
fifo#(
    .DEPTH       ( 16 ),
    .DATA_W      ( FLIT_WIDTH )
)u_cfg_fifo(
    .clk         ( clk         ),
    .rst_n       ( rst_n       ),
    .f_valid_in  ( cfg_fifo_valid_in  ),
    .f_data_in   ( cfg_fifo_data_in   ),
    .f_ready_out ( cfg_fifo_ready_out ),
    .b_valid_out ( cfg_fifo_valid_out ),
    .b_data_out  ( cfg_fifo_data_out  ),
    .b_ready_in  ( cfg_fifo_ready_in  )
);
assign cfg_fifo_ready_in = (cur_state==SEND_CFG) && send_flit_ready_pipe[0];
assign cfg_fifo_out_handshake = cfg_fifo_valid_out && cfg_fifo_ready_in;

// store group info into fifo
assign group_fifo_in_handshake = group_fifo_valid_in && group_fifo_ready_out;
assign group_fifo_valid_in = group_info_valid;
assign group_fifo_data_in  = group_info;
fifo#(
    .DEPTH       ( 16 ),
    .DATA_W      ( 12 )
)u_group_fifo(
    .clk         ( clk         ),
    .rst_n       ( rst_n       ),
    .f_valid_in  ( group_fifo_valid_in  ),
    .f_data_in   ( group_fifo_data_in   ),
    .f_ready_out ( group_fifo_ready_out ),
    .b_valid_out ( group_fifo_valid_out ),
    .b_data_out  ( group_fifo_data_out  ),
    .b_ready_in  ( group_fifo_ready_in  )
);
assign group_fifo_ready_in = cfg_fifo_ready_in;
assign group_fifo_out_handshake = group_fifo_valid_out && group_fifo_ready_in;

// record finish flag
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        finish_flag <= 1'b0;
    end
    else if(finish_intr) begin
        finish_flag <= 1'b0;
    end
    else if(group_fifo_in_handshake && return_data_op_finish) begin
        finish_flag <= 1'b1;
    end
end
// record last flag
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        last_flag <= 1'b0;
    end
    else if(cur_state==WAIT_INTR && nxt_state==RD_BASE) begin
        last_flag <= 1'b0;
    end
    else if(group_fifo_in_handshake && return_data_op_last) begin
        last_flag <= 1'b1;
    end
end

// ======================================================================
// store group info into lut
// ======================================================================
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for (int i = 0; i < 12; i++) begin
            lut_group[i] <= 12'd0;
        end
    end
    else if(group_info_valid) begin
        for (int i = 0; i < 12; i++) begin
            if(group_info[i]==1'b1)
                lut_group[i] <= group_info[11:0];
        end
    end
    else begin
        for (int i = 0; i < 12; i++) begin
            if(lut_flush[i]==1'b1)
                lut_group[i] <= 12'd0;
        end
    end
end
assign lut_flush = group_info_pipe[1] & {12{send_flit_done}};

// merge all group info
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        group_info_all <= 12'd0;
    end
    else if(group_info_valid) begin
        group_info_all <= group_info_all | group_info[11:0];
    end
    else begin
        for (int i = 0; i < 12; i++) begin
            if(recv_intr_valid[i])
                group_info_all[i] <= 1'b0;
        end
    end
end

// read group info from lut
assign group_info_next = ({12{recv_gnt_next[0]}}  & lut_group[0])
                        |({12{recv_gnt_next[1]}}  & lut_group[1])
                        |({12{recv_gnt_next[2]}}  & lut_group[2])
                        |({12{recv_gnt_next[3]}}  & lut_group[3])
                        |({12{recv_gnt_next[4]}}  & lut_group[4])
                        |({12{recv_gnt_next[5]}}  & lut_group[5])
                        |({12{recv_gnt_next[6]}}  & lut_group[6])
                        |({12{recv_gnt_next[7]}}  & lut_group[7])
                        |({12{recv_gnt_next[8]}}  & lut_group[8])
                        |({12{recv_gnt_next[9]}}  & lut_group[9])
                        |({12{recv_gnt_next[10]}} & lut_group[10])
                        |({12{recv_gnt_next[11]}} & lut_group[11])
                        ;


// ======================================================================
// receive flit ports
// ======================================================================

// if receive flit[31]==1, it's interrupt
assign recv_intr_valid = recv_intr & recv_valid;
assign recv_intr[0] = recv_flit[0][31];
assign recv_intr[1] = recv_flit[1][31];
assign recv_intr[2] = recv_flit[2][31];
assign recv_intr[3] = recv_flit[3][31];
assign recv_intr[4] = recv_flit[4][31];
assign recv_intr[5] = recv_flit[5][31];
assign recv_intr[6] = recv_flit[6][31];
assign recv_intr[7] = recv_flit[7][31];
assign recv_intr[8] = recv_flit[8][31];
assign recv_intr[9] = recv_flit[9][31];
assign recv_intr[10] = recv_flit[10][31];
assign recv_intr[11] = recv_flit[11][31];

// if receive flit[31]==0, it's read req
assign recv_req_valid = recv_valid & ~recv_intr;

// arbit, store recv info into fifo
always @(posedge clk or negedge rst_n) begin
    if (rst_n==1'b0) begin
        recv_gnt_curr <= 12'b1000_0000_0000;
    end
    else begin
        recv_gnt_curr <= recv_gnt_next;
    end
end

arb_rr #(.N(12))
U_iarb
(   .nxt_gnt    (recv_gnt_next),
    .req        (recv_req_valid),
    .gnt        (recv_gnt_curr),
    .en         (1'b1)
);


assign recv_pipe_in_handshake = recv_pipe_valid_in && recv_pipe_ready_out;
assign recv_pipe_valid_in = | (recv_req_valid & group_info_next);
assign recv_pipe_data_in  = ({21{recv_gnt_next[0]}}  & recv_flit[0][20:0])
                        |   ({21{recv_gnt_next[1]}}  & recv_flit[1][20:0])
                        |   ({21{recv_gnt_next[2]}}  & recv_flit[2][20:0])
                        |   ({21{recv_gnt_next[3]}}  & recv_flit[3][20:0])
                        |   ({21{recv_gnt_next[4]}}  & recv_flit[4][20:0])
                        |   ({21{recv_gnt_next[5]}}  & recv_flit[5][20:0])
                        |   ({21{recv_gnt_next[6]}}  & recv_flit[6][20:0])
                        |   ({21{recv_gnt_next[7]}}  & recv_flit[7][20:0])
                        |   ({21{recv_gnt_next[8]}}  & recv_flit[8][20:0])
                        |   ({21{recv_gnt_next[9]}}  & recv_flit[9][20:0])
                        |   ({21{recv_gnt_next[10]}} & recv_flit[10][20:0])
                        |   ({21{recv_gnt_next[11]}} & recv_flit[11][20:0])
                        ;

assign recv_ready = ({12{recv_pipe_ready_out}} & group_info_next) | recv_intr;
fwd_pipe#(
    .DATA_W      ( 21 )
)u_recv_pipe(
    .clk         ( clk         ),
    .rst_n       ( rst_n       ),
    .f_valid_in  ( recv_pipe_valid_in  ),
    .f_data_in   ( recv_pipe_data_in   ),
    .f_ready_out ( recv_pipe_ready_out ),
    .b_valid_out ( recv_pipe_valid_out ),
    .b_data_out  ( recv_pipe_data_out  ),
    .b_ready_in  ( recv_pipe_ready_in  )
);
assign recv_pipe_ready_in = return_done && (cur_state==SEND_DATA);


// when receive noc req, record group info
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        group_info_reg <= 12'd0;
    end
    else if(recv_pipe_in_handshake) begin
        group_info_reg <= group_info_next;
    end
end
// when receive noc req, record granted noc id
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        recv_gnt_reg <= 12'd0;
    end
    else if(recv_pipe_in_handshake) begin
        recv_gnt_reg <= recv_gnt_next;
    end
end


// ======================================================================
// FSM
// ======================================================================
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
            if(fsm_start)
                nxt_state = RD_BASE;
            else
                nxt_state = IDLE;
        end
        RD_BASE : begin
            if(apb_done)
                nxt_state = RD_INFO;
            else
                nxt_state = RD_BASE;
        end
        RD_INFO : begin
            if(return_last_or_finish)
                nxt_state = SEND_CFG;
            else
                nxt_state = RD_INFO;
        end
        SEND_CFG : begin
            if(send_cfg_done)
                nxt_state = RECV_NOC;
            else
                nxt_state = SEND_CFG;
        end
        RECV_NOC : begin
            if(recv_pipe_valid_out)
                nxt_state = SEND_DATA;
            else
                nxt_state = RECV_NOC;
        end
        SEND_DATA : begin
            if(send_flit_done && !recv_pipe_valid_out)
                nxt_state = WAIT_INTR;
            else if(send_flit_done && recv_pipe_valid_out)
                nxt_state = RECV_NOC;
            else
                nxt_state = SEND_DATA;
        end
        WAIT_INTR : begin
            if(finish_flag)
                nxt_state = FINISH;
            else if((small_loop_end_flag && fsm_auto_restart_en) || fsm_restart)
                nxt_state = RD_BASE;
            else
                nxt_state = WAIT_INTR;
        end
        FINISH : begin
            nxt_state = IDLE;
        end
        default : 
            nxt_state = IDLE;
    endcase
end


// ======================================================================
// read ibuffer. process return data
// ======================================================================
assign read_cfg_info_first_start = (nxt_state==RD_INFO && cur_state==RD_BASE);
assign read_base_loop_start      = (nxt_state==RD_BASE && cur_state==WAIT_INTR);
assign read_cfg_info_loop_start  = (nxt_state==RD_INFO && return_info_cnt_clear && !last_flag && !finish_flag);
assign read_noc_instr_start      = (nxt_state==SEND_DATA && cur_state==RECV_NOC);

always @(posedge clk or negedge rst_n) begin
    if (rst_n==1'b0) begin
        read_base_loop_start_reg      <= 1'b0;
        read_cfg_info_first_start_reg <= 1'b0;
        read_cfg_info_loop_start_reg  <= 1'b0;
    end
    else begin
        read_base_loop_start_reg      <= read_base_loop_start;
        read_cfg_info_first_start_reg <= read_cfg_info_first_start;
        read_cfg_info_loop_start_reg  <= read_cfg_info_loop_start;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (rst_n==1'b0) begin
        ibuffer_word_addr_info <= 17'd0;
    end
    else if(fsm_start) begin
        ibuffer_word_addr_info <= fsm_base_addr;
    end
    else if(small_loop_cnt_incr) begin
        ibuffer_word_addr_info <= ibuffer_word_addr_info + 1;
    end
end

assign ibuffer_rd_start =   fsm_start
                        ||  read_base_loop_start_reg
                        ||  read_cfg_info_first_start_reg
                        ||  read_cfg_info_loop_start_reg
                        ||  read_noc_instr_start
                        ;
assign ibuffer_word_addr =  fsm_start ? fsm_base_addr :
                            (read_cfg_info_first_start_reg || read_cfg_info_loop_start_reg || read_base_loop_start_reg) ? ibuffer_word_addr_info : 
                            recv_pipe_data_out[18:2]
                            ;
assign ibuffer_word_num  =   (fsm_start || read_base_loop_start_reg) ? 17'd24 :
                            (read_cfg_info_first_start_reg || read_cfg_info_loop_start_reg) ? 17'd12 : 
                            recv_pipe_data_out[19] ? 13'd32 : 13'd16;
// assign ibuffer_word_num  = (ibuffer_rd_start && !read_noc_instr_start) ? 17'd12 :
//                             recv_pipe_data_out[19] ? 13'd32 : 13'd16;


assign return_apb_ready = (cur_state==RD_BASE);
assign return_cfg_fifo_ready = ((cur_state==RD_INFO) && cfg_fifo_ready_out);
assign return_send_pipe_ready = ((cur_state==SEND_DATA) && send_flit_ready_pipe[0]);

assign return_ready =   (apb_state_curr==APB_IDLE)
                    &&  (return_apb_ready
                    ||  return_cfg_fifo_ready
                    ||  return_send_pipe_ready
                    ||  (cur_state==SEND_CFG || cur_state==RECV_NOC)) // consume unused return data
                    ;

assign return_last_or_finish = small_loop_cnt_clear;
always @(posedge clk or negedge rst_n) begin
    if (rst_n==1'b0) begin
        small_loop_processing <= 1'b0;
    end
    else if(small_loop_cnt_clear) begin
        small_loop_processing <= 1'b0;
    end
    else if(cur_state==RD_BASE) begin
        small_loop_processing <= 1'b1;
    end
end




// ======================================================================
// send flit
// ======================================================================
assign send_flit_valid_pipe[0] = ((cur_state==SEND_CFG) && cfg_fifo_valid_out)
                            ||   ((cur_state==SEND_DATA) && return_valid);

assign send_flit_pipe[0] = ({32{(cur_state==SEND_CFG)}} & cfg_fifo_data_out)
                         | ({32{(cur_state==SEND_DATA)}} & return_data)
                         ;

assign send_flit_last_pipe[0] = (cur_state==SEND_DATA) && return_last;

assign group_info_pipe[0] = ({12{(cur_state==SEND_CFG)}} & group_fifo_data_out)
                          | ({12{(cur_state==SEND_DATA)}} & (recv_pipe_data_out[20] ? recv_gnt_reg : group_info_reg)); //[20] means async

fwd_pipe #(
    .DATA_W(12+1+FLIT_WIDTH)
) u_send_flit_pipe(
    .clk(clk),
    .rst_n(rst_n),
    .f_valid_in(send_flit_valid_pipe[0]),
    .f_data_in({group_info_pipe[0], send_flit_last_pipe[0], send_flit_pipe[0]}),
    .f_ready_out(send_flit_ready_pipe[0]),
    .b_valid_out(send_flit_valid_pipe[1]),
    .b_data_out({group_info_pipe[1], send_flit_last_pipe[1], send_flit_pipe[1]}),
    .b_ready_in(send_flit_ready_pipe[1])
);

// fork one stream to 12 streams
assign send_flit_ready_pipe[1] = & (send_ready | ~group_info_pipe[1]); // only care group_info_pipe[i]=1, i ready
assign send_valid = {12{send_flit_valid_pipe[1]}} & group_info_pipe[1];
assign send_flit[0] = send_flit_pipe[1];
assign send_flit[1] = send_flit_pipe[1];
assign send_flit[2] = send_flit_pipe[1];
assign send_flit[3] = send_flit_pipe[1];
assign send_flit[4] = send_flit_pipe[1];
assign send_flit[5] = send_flit_pipe[1];
assign send_flit[6] = send_flit_pipe[1];
assign send_flit[7] = send_flit_pipe[1];
assign send_flit[8] = send_flit_pipe[1];
assign send_flit[9] = send_flit_pipe[1];
assign send_flit[10] = send_flit_pipe[1];
assign send_flit[11] = send_flit_pipe[1];
assign send_flit_done = send_flit_handshake && send_flit_last_pipe[1];

// num of cfg has sent
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        send_cfg_cnt <= 4'd0;
    end
    else if(send_cfg_done) begin
        send_cfg_cnt <= 4'd0;
    end
    else if(cur_state==SEND_CFG && send_flit_handshake) begin
        send_cfg_cnt <= send_cfg_cnt + 1;
    end
end
assign send_cfg_done = (send_cfg_cnt==cfg_fifo_cnt-1) && send_flit_handshake;




// ======================================================================
// APB ports
// ======================================================================
always @(posedge clk or negedge rst_n) begin
    if (rst_n==1'b0) begin
        apb_state_curr <= APB_IDLE;
    end
    else begin
        apb_state_curr <= apb_state_next;
    end
end

always @(*) begin
    case (apb_state_curr)
        APB_IDLE : begin
            if(group_info_valid)
                apb_state_next = APB_GROUP;
            else
                apb_state_next = APB_IDLE;
        end
        APB_GROUP : begin
             apb_state_next = APB_SEND;
        end
        APB_SEND : begin
            if(apb_group_reg==12'd0)
                apb_state_next = APB_IDLE;
            else
                apb_state_next = APB_SEND;
        end
        default: 
            apb_state_next = APB_IDLE;
    endcase
end

assign send_base_to_m0 =    (small_loop_cnt==17'd0) || (small_loop_cnt==17'd1) ||
                            (small_loop_cnt==17'd4) || (small_loop_cnt==17'd5) ||
                            (small_loop_cnt==17'd8) || (small_loop_cnt==17'd9) ||
                            (small_loop_cnt==17'd12) || (small_loop_cnt==17'd13) ||
                            (small_loop_cnt==17'd16) || (small_loop_cnt==17'd17) ||
                            (small_loop_cnt==17'd20) || (small_loop_cnt==17'd21)
                            ;

assign send_base_to_m1 =    (small_loop_cnt==17'd2) || (small_loop_cnt==17'd3) ||
                            (small_loop_cnt==17'd6) || (small_loop_cnt==17'd7) ||
                            (small_loop_cnt==17'd10)|| (small_loop_cnt==17'd11) ||
                            (small_loop_cnt==17'd14) || (small_loop_cnt==17'd15) ||
                            (small_loop_cnt==17'd18) || (small_loop_cnt==17'd19) ||
                            (small_loop_cnt==17'd22) || (small_loop_cnt==17'd23)
                            ;

// record group info for apb send
always @(posedge clk or negedge rst_n) begin
    if (rst_n==1'b0) begin
        apb_group_reg <= 12'd0;
    end
    else if(group_info_valid) begin
        apb_group_reg <= group_info;
    end
    else if(apb_state_curr!=APB_IDLE) begin
        apb_group_reg <= apb_group_next;
    end
end
assign apb_group_next = apb_group_reg & (~apb_group_m0_onehot) & (~apb_group_m1_onehot);
assign apb_group_m0 = apb_group_reg & GROUP_VALID_BITS_M0;
assign apb_group_m1 = apb_group_reg & GROUP_VALID_BITS_M1;
assign apb_group_m0_onehot = apb_group_m0 & (~apb_group_m0 + 12'd1);
assign apb_group_m1_onehot = apb_group_m1 & (~apb_group_m1 + 12'd1);

assign m0_paddr_next = ({12{apb_group_m0_onehot[0]}} & APB_BASE_ADDR_GROUP_0)
                    |  ({12{apb_group_m0_onehot[1]}} & APB_BASE_ADDR_GROUP_1)
                    |  ({12{apb_group_m0_onehot[2]}} & APB_BASE_ADDR_GROUP_2)
                    |  ({12{apb_group_m0_onehot[3]}} & APB_BASE_ADDR_GROUP_3)
                    |  ({12{apb_group_m0_onehot[4]}} & APB_BASE_ADDR_GROUP_4)
                    |  ({12{apb_group_m0_onehot[5]}} & APB_BASE_ADDR_GROUP_5)
                    |  ({12{apb_group_m0_onehot[6]}} & APB_BASE_ADDR_GROUP_6)
                    |  ({12{apb_group_m0_onehot[7]}} & APB_BASE_ADDR_GROUP_7)
                    |  ({12{apb_group_m0_onehot[8]}} & APB_BASE_ADDR_GROUP_8)
                    |  ({12{apb_group_m0_onehot[9]}} & APB_BASE_ADDR_GROUP_9)
                    |  ({12{apb_group_m0_onehot[10]}} & APB_BASE_ADDR_GROUP_10)
                    |  ({12{apb_group_m0_onehot[11]}} & APB_BASE_ADDR_GROUP_11)
                    ;

assign m1_paddr_next = ({12{apb_group_m1_onehot[0]}} & APB_BASE_ADDR_GROUP_0)
                    |  ({12{apb_group_m1_onehot[1]}} & APB_BASE_ADDR_GROUP_1)
                    |  ({12{apb_group_m1_onehot[2]}} & APB_BASE_ADDR_GROUP_2)
                    |  ({12{apb_group_m1_onehot[3]}} & APB_BASE_ADDR_GROUP_3)
                    |  ({12{apb_group_m1_onehot[4]}} & APB_BASE_ADDR_GROUP_4)
                    |  ({12{apb_group_m1_onehot[5]}} & APB_BASE_ADDR_GROUP_5)
                    |  ({12{apb_group_m1_onehot[6]}} & APB_BASE_ADDR_GROUP_6)
                    |  ({12{apb_group_m1_onehot[7]}} & APB_BASE_ADDR_GROUP_7)
                    |  ({12{apb_group_m1_onehot[8]}} & APB_BASE_ADDR_GROUP_8)
                    |  ({12{apb_group_m1_onehot[9]}} & APB_BASE_ADDR_GROUP_9)
                    |  ({12{apb_group_m1_onehot[10]}} & APB_BASE_ADDR_GROUP_10)
                    |  ({12{apb_group_m1_onehot[11]}} & APB_BASE_ADDR_GROUP_11)
                    ;

always @(posedge clk or negedge rst_n) begin
    if (rst_n==1'b0) begin
        m0_paddr_reg <= APB_BASE_ADDR;
    end
    else if(return_handshake && (small_loop_cnt==17'd0)) begin
        m0_paddr_reg <= APB_BASE_ADDR;
    end
    else if(return_handshake && (small_loop_cnt==17'd12)) begin
        m0_paddr_reg <= APB_BASE_ADDR_WRITE;
    end
    else if(return_handshake && send_base_to_m0) begin
        m0_paddr_reg <= m0_paddr_reg + 12'd4;
    end
    else if(apb_state_curr!=APB_IDLE) begin
        m0_paddr_reg <= m0_paddr_next;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (rst_n==1'b0) begin
        m1_paddr_reg <= APB_BASE_ADDR;
    end
    else if(return_handshake && (small_loop_cnt==17'd2)) begin
        m1_paddr_reg <= APB_BASE_ADDR;
    end
    else if(return_handshake && (small_loop_cnt==17'd14)) begin
        m1_paddr_reg <= APB_BASE_ADDR_WRITE;
    end
    else if(return_handshake && send_base_to_m1) begin
        m1_paddr_reg <= m1_paddr_reg + 12'd4;
    end
    else if(apb_state_curr!=APB_IDLE) begin
        m1_paddr_reg <= m1_paddr_next;
    end
end

assign base1_info_valid = small_loop_processing
                        && !return_data_op_base
                        && (cur_state==RD_INFO)
                        && (return_base1_cfg_group_cnt==2'd0) 
                        && return_handshake
                        ;

always @(posedge clk or negedge rst_n) begin
    if (rst_n==1'b0) begin
        m0_pwdata_reg <= 32'd0;
    end
    else if(return_handshake && send_base_to_m0) begin
        m0_pwdata_reg <= return_data;
    end
    else if(base1_info_valid) begin
        m0_pwdata_reg <= return_data;
    end
end
always @(posedge clk or negedge rst_n) begin
    if (rst_n==1'b0) begin
        m1_pwdata_reg <= 32'd0;
    end
    else if(return_handshake && send_base_to_m1) begin
        m1_pwdata_reg <= return_data;
    end
    else if(base1_info_valid) begin
        m1_pwdata_reg <= return_data;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (rst_n==1'b0) begin
        m0_penable_reg <= 1'b0;
    end
    else if(return_handshake && send_base_to_m0 && (cur_state==RD_BASE)) begin
        m0_penable_reg <= 1'b1;
    end
    else if(apb_state_curr!=APB_IDLE) begin
        m0_penable_reg <= (| apb_group_m0_onehot);
    end
    else begin
        m0_penable_reg <= 1'b0;
    end
end
always @(posedge clk or negedge rst_n) begin
    if (rst_n==1'b0) begin
        m1_penable_reg <= 1'b0;
    end
    else if(return_handshake && send_base_to_m1 && (cur_state==RD_BASE)) begin
        m1_penable_reg <= 1'b1;
    end
    else if(apb_state_curr!=APB_IDLE) begin
        m1_penable_reg <= (| apb_group_m1_onehot);
    end
    else begin
        m1_penable_reg <= 1'b0;
    end
end

reg apb_done_reg;
always @(posedge clk or negedge rst_n) begin
    if (rst_n==1'b0) begin
        apb_done_reg <= 1'b0;
    end
    else begin
        apb_done_reg <= (small_loop_cnt==17'd23 && return_handshake);
    end
end

assign m0_paddr = m0_paddr_reg;
assign m1_paddr = m1_paddr_reg;
assign m0_psel  = 1'b1;
assign m1_psel  = 1'b1;
assign m0_penable = m0_penable_reg;
assign m1_penable = m1_penable_reg;
assign m0_pwrite = 1'b1;
assign m1_pwrite = 1'b1;
assign m0_pstrb  = 4'hf;
assign m1_pstrb  = 4'hf;
assign m0_pwdata = m0_pwdata_reg;
assign m1_pwdata = m1_pwdata_reg;

assign apb_done = apb_done_reg;



// ======================================================================
// collect node status, send intr
// ======================================================================
assign nodes_status = group_info_all;
assign small_loop_end_int = (& (~group_info_all | recv_intr_valid)) && (group_info_all!=12'd0);
assign finish_intr  = (cur_state==FINISH);

always @(posedge clk or negedge rst_n) begin
    if (rst_n==1'b0) begin
        small_loop_end_flag <= 1'b0;
    end
    else if((nxt_state==FINISH || nxt_state==RD_BASE) && cur_state==WAIT_INTR) begin
        small_loop_end_flag <= 1'b0;
    end
    else if(small_loop_end_int) begin
        small_loop_end_flag <= 1'b1;
    end
end

endmodule