module ictrl_send_recv_flit
#(
    parameter FLIT_WIDTH = 32
) 
(
    input clk,
    input rst_n,

    // config ports
    input                  cfg_send_start,
    input [FLIT_WIDTH-1:0] cfg_group_info,
    input                  cfg_group_info_valid,
    input [FLIT_WIDTH-1:0] cfg_cache_info,
    input                  cfg_cache_info_valid,

    // read to noc port
    output                 noc_wr_start,
    output [16:0]          noc_wr_ibuffer_word_addr,
    output [12:0]          noc_wr_ibuffer_word_num,
    input                  noc_wr_done,
    input                  noc_wr_req,
    output                 noc_wr_ready,
    input [FLIT_WIDTH-1:0] noc_wr_data,
    input                  noc_wr_last,

    // send to noc
    output [11:0]           send_valid ,
    output [FLIT_WIDTH-1:0] send_flit  [11:0],
    input  [11:0]           send_ready ,

    // receive from noc
    input  [11:0]           recv_valid ,
    input  [FLIT_WIDTH-1:0] recv_flit  [11:0],
    output [11:0]           recv_ready ,

    // send intr
    output [11:0]           nodes_status,
    output                  nodes_intr
);

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
reg [3:0] cfg_flit_cnt;
reg [3:0] send_cfg_flit_cnt;

logic [11:0] lut_group [11:0];
logic [11:0] lut_flush;
logic [11:0] group_info;
logic [11:0] group_info_next;
logic [11:0] group_info_all;

logic [11:0]          recv_gnt_next ;
logic [11:0]          recv_gnt_curr ;
logic [11:0]          recv_intr     ;
wire                  recv_fifo_valid_in;
wire  [19:0]          recv_fifo_data_in;
wire                  recv_fifo_ready_out;
wire                  recv_fifo_valid_out;
wire  [19:0]          recv_fifo_data_out;
wire                  recv_fifo_ready_in;
wire                  recv_fifo_out_handshake;
wire                  recv_fifo_in_handshake;


localparam IDLE     = 3'd0;
localparam SEND_CFG = 3'd1;
localparam RECV_INFO = 3'd3;
localparam SEND_DATA = 3'd4;
reg [2:0] cur_state;
reg [2:0] nxt_state;

wire send_flit_valid_pipe [1:0];
wire send_flit_last_pipe [1:0];
wire send_flit_ready_pipe [1:0];
wire [FLIT_WIDTH-1:0] send_flit_pipe [1:0];
wire [12-1:0] group_info_pipe [1:0];
wire send_flit_handshake = | (send_valid & send_ready);
wire send_cfg_done;
wire send_flit_done;

// ===================================
// Config ports
// ===================================
// store cache config into fifo
assign cfg_fifo_valid_in = cfg_cache_info_valid;
assign cfg_fifo_data_in  = cfg_cache_info;
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

assign group_fifo_valid_in = cfg_group_info_valid;
assign group_fifo_data_in  = cfg_group_info;
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


assign cfg_fifo_ready_in = (cur_state==SEND_CFG) && send_flit_ready_pipe[0];
assign group_fifo_ready_in = cfg_fifo_ready_in;

assign cfg_fifo_out_handshake = cfg_fifo_valid_out && cfg_fifo_ready_in;
assign group_fifo_out_handshake = group_fifo_valid_out && group_fifo_ready_in;

// total num of cfg to send
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cfg_flit_cnt <= 4'd0;
    end
    else if(send_cfg_done) begin
        cfg_flit_cnt <= 4'd0;
    end
    else if(cfg_fifo_valid_in && !cfg_fifo_out_handshake) begin
        cfg_flit_cnt <= cfg_flit_cnt + 1;
    end
end
// num of cfg has sent
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        send_cfg_flit_cnt <= 4'd0;
    end
    else if(send_cfg_done) begin
        send_cfg_flit_cnt <= 4'd0;
    end
    else if(cur_state==SEND_CFG && send_flit_handshake) begin
        send_cfg_flit_cnt <= send_cfg_flit_cnt + 1;
    end
end

assign send_cfg_done = (send_cfg_flit_cnt==cfg_flit_cnt-1) && send_flit_handshake;

// store group info into lut
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for (int i = 0; i < 12; i++) begin
            lut_group[i] <= 12'd0;
        end
    end
    else if(cfg_group_info_valid) begin
        for (int i = 0; i < 12; i++) begin
            if(cfg_group_info[i]==1'b1)
                lut_group[i] <= cfg_group_info[11:0];
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
    else if(cfg_group_info_valid) begin
        group_info_all <= group_info_all | cfg_group_info[11:0];
    end
    else begin
        for (int i = 0; i < 12; i++) begin
            if(recv_intr[i] && recv_valid[i])
                group_info_all[i] <= 1'b0;
        end
    end
end

// read group info from lut
assign group_info_next = ({12{recv_gnt_next[0]}} & lut_group[0])
                        |({12{recv_gnt_next[1]}} & lut_group[1])
                        |({12{recv_gnt_next[2]}} & lut_group[2])
                        |({12{recv_gnt_next[3]}} & lut_group[3])
                        |({12{recv_gnt_next[4]}} & lut_group[4])
                        |({12{recv_gnt_next[5]}} & lut_group[5])
                        |({12{recv_gnt_next[6]}} & lut_group[6])
                        |({12{recv_gnt_next[7]}} & lut_group[7])
                        |({12{recv_gnt_next[8]}} & lut_group[8])
                        |({12{recv_gnt_next[9]}} & lut_group[9])
                        |({12{recv_gnt_next[10]}} & lut_group[10])
                        |({12{recv_gnt_next[11]}} & lut_group[11])
                        ;

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        group_info <= 12'd0;
    end
    else if(recv_fifo_in_handshake) begin
        group_info <= group_info_next;
    end
end

// ===================================
// receive flit ports
// ===================================

// if receive flit[31]==1, it's interrupt
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

// arbit, store recv info into fifo
always @(posedge clk or negedge rst_n) begin
    if (rst_n==1'b0) begin
        recv_gnt_curr <= 12'b1000_0000_0000;
    end
    else begin
        recv_gnt_curr <= recv_gnt_next;
    end
end

arb_rr
    #(.N(12))
    U_iarb
    (   .nxt_gnt    (recv_gnt_next),
        .req        (recv_valid & ~recv_intr),
        .gnt        (recv_gnt_curr),
        .en         (1'b1)
    );

assign recv_fifo_valid_in = | (recv_valid & ~recv_intr);
assign recv_fifo_data_in  = ({20{recv_gnt_next[0]}} & recv_flit[0][19:0])
                        |   ({20{recv_gnt_next[1]}} & recv_flit[1][19:0])
                        |   ({20{recv_gnt_next[2]}} & recv_flit[2][19:0])
                        |   ({20{recv_gnt_next[3]}} & recv_flit[3][19:0])
                        |   ({20{recv_gnt_next[4]}} & recv_flit[4][19:0])
                        |   ({20{recv_gnt_next[5]}} & recv_flit[5][19:0])
                        |   ({20{recv_gnt_next[6]}} & recv_flit[6][19:0])
                        |   ({20{recv_gnt_next[7]}} & recv_flit[7][19:0])
                        |   ({20{recv_gnt_next[8]}} & recv_flit[8][19:0])
                        |   ({20{recv_gnt_next[9]}} & recv_flit[9][19:0])
                        |   ({20{recv_gnt_next[10]}} & recv_flit[10][19:0])
                        |   ({20{recv_gnt_next[11]}} & recv_flit[11][19:0])
                        ;
fwd_pipe#(
    .DATA_W      ( 20 )
)u_recv_fifo(
    .clk         ( clk         ),
    .rst_n       ( rst_n       ),
    .f_valid_in  ( recv_fifo_valid_in  ),
    .f_data_in   ( recv_fifo_data_in   ),
    .f_ready_out ( recv_fifo_ready_out ),
    .b_valid_out ( recv_fifo_valid_out ),
    .b_data_out  ( recv_fifo_data_out  ),
    .b_ready_in  ( recv_fifo_ready_in  )
);
assign recv_fifo_in_handshake = recv_fifo_valid_in && recv_fifo_ready_out;
assign recv_fifo_ready_in = noc_wr_done;
assign recv_fifo_out_handshake = recv_fifo_valid_out && recv_fifo_ready_in;
assign recv_ready = ({12{recv_fifo_ready_out}} & group_info_next) | recv_intr;

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
            if(cfg_send_start && cfg_fifo_valid_out)
                nxt_state = SEND_CFG;
            else if(recv_fifo_in_handshake || recv_fifo_valid_out)
                nxt_state = RECV_INFO;
            else
                nxt_state = IDLE;
        end
        SEND_CFG : begin
            if(send_cfg_done)
                nxt_state = IDLE;
            else
                nxt_state = SEND_CFG;
        end
        RECV_INFO : begin
                nxt_state = SEND_DATA;
        end
        SEND_DATA : begin
            if(send_flit_done)
                nxt_state = IDLE;
            else
                nxt_state = SEND_DATA;
        end
        default : 
            nxt_state = IDLE;
    endcase
end


// ===================================
// read ibuffer to noc
// ===================================
assign noc_wr_start = (cur_state==RECV_INFO);
assign noc_wr_ready = (cur_state==SEND_DATA) && send_flit_ready_pipe[0];
assign noc_wr_ibuffer_word_addr = recv_fifo_data_out[18:2];
assign noc_wr_ibuffer_word_num  = recv_fifo_data_out[19] ? 13'd32 : 13'd16;

// ===================================
// send flit
// ===================================

assign send_flit_valid_pipe[0] = ((cur_state==SEND_CFG) && cfg_fifo_valid_out)
                            ||   ((cur_state==SEND_DATA) && noc_wr_req);

assign send_flit_pipe[0] = ({32{(cur_state==SEND_CFG)}} & cfg_fifo_data_out)
                         | ({32{(cur_state==SEND_DATA)}} & noc_wr_data)
                         ;

assign send_flit_last_pipe[0] = noc_wr_last;

assign group_info_pipe[0] = ({12{(cur_state==SEND_CFG)}} & group_fifo_data_out)
                          | ({12{(cur_state==SEND_DATA)}} & group_info);

fwd_pipe #(
    .DATA_W(12+1+FLIT_WIDTH)
) u_send_flit_pipe(
    .clk(clk),
    .rst_n(rst_n),
    .f_valid_in(send_flit_valid_pipe[0]),
    .f_data_in({group_info_pipe[0], send_flit_last_pipe[0] , send_flit_pipe[0]}),
    .f_ready_out(send_flit_ready_pipe[0]),
    .b_valid_out(send_flit_valid_pipe[1]),
    .b_data_out({group_info_pipe[1], send_flit_last_pipe[1] , send_flit_pipe[1]}),
    .b_ready_in(send_flit_ready_pipe[1])
);

// fork one stream to 12 streams
assign send_flit_ready_pipe[1] = & (send_ready | ~group_info_pipe[1]);
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


// ===================================
// collect node status, send intr
// ===================================

assign nodes_status = recv_valid & recv_intr;
assign nodes_intr   = (& (~group_info_all | nodes_status)) && (group_info_all!=12'd0);


endmodule