module ictrl_ibuffer_read_to_noc
#(
    parameter DATA_WIDTH = 128,
    parameter MEM_AW = 15,
    parameter STRB_WIDTH = (DATA_WIDTH/8),
    parameter WORD_WIDTH = 32
) 
(   
    input clk,
    input rst_n,

    // ibuffer port
    input [MEM_AW+$clog2(DATA_WIDTH/WORD_WIDTH)-1:0] ibuffer_word_addr, // word start addr
    input [12:0]           ibuffer_word_num, // how many word
    output reg             ibuffer_cen,
    output                 ibuffer_wen,
    input                  ibuffer_ready,
    output reg [MEM_AW-1:0]ibuffer_addr,
    input[DATA_WIDTH-1:0]  ibuffer_rdata,
    input                  ibuffer_rvalid,
    output                 ibuffer_rready,

    // control signal
    input                  noc_wr_start,
    output                 noc_wr_done,

    // noc port
    output                 noc_wr_req,
    input                  noc_wr_ready,
    output[WORD_WIDTH-1:0] noc_wr_data,
    output                 noc_wr_last
);

localparam WORD_NUM = DATA_WIDTH/WORD_WIDTH; // 128/32=4
localparam MAX_WORD_LEN = 13;

wire [MEM_AW+$clog2(WORD_NUM)-1:0] ibuffer_word_addr_end;
wire [MEM_AW-1:0] ibuffer_data_addr_end;
wire [MEM_AW-1:0] ibuffer_data_num;
wire [MEM_AW-1:0] ibuffer_data_addr;
wire ibuffer_pause_req;
wire ibuffer_restart_req;
wire ibuffer_handshake;
wire ibuffer_r_handshake;
wire ibuffer_rd_done;
reg  ibuffer_rd_flag;
reg  [MEM_AW-1:0] ibuffer_req_cnt;
reg  [DATA_WIDTH-1:0] rd_data_pingpong [1:0];
reg  [1:0] read_ptr_pingpong;
wire read_ptr_increase;
reg  [1:0] write_ptr_pingpong;
reg  [1:0] space_of_pingpong;
wire [1:0] space_of_pingpong_next;
reg  [1:0] ibuffer_outsd_req_num;
wire [1:0] ibuffer_outsd_req_num_next;
wire empty_pingpong;
wire full_pingpong;

reg  [$clog2(WORD_NUM)-1:0] word_offset;
wire [$clog2(DATA_WIDTH)-1:0] bits_offset;
reg  [MAX_WORD_LEN-1:0] wr_req_cnt;
reg  [MAX_WORD_LEN-1:0] rd_pingpong_cnt;
wire noc_rd_pingpong_handshake;
wire noc_rd_pingpong_done;
wire [WORD_WIDTH-1:0] noc_rd_pingpong_data;
wire noc_read_pingpong;
wire noc_wr_req_pipe [1:0];
wire noc_wr_last_pipe [1:0];
wire noc_wr_ready_pipe [1:0];
wire [WORD_WIDTH-1:0] noc_wr_wdata_pipe [1:0];

// ===================================
// read ibuffer
// ===================================
assign ibuffer_word_addr_end = ibuffer_word_addr + ibuffer_word_num - 1;
assign ibuffer_data_addr_end = ibuffer_word_addr_end[$clog2(WORD_NUM)+:MEM_AW];
assign ibuffer_data_addr = ibuffer_word_addr[$clog2(WORD_NUM)+:MEM_AW];
assign ibuffer_data_num = ibuffer_data_addr_end - ibuffer_data_addr + 1;
assign ibuffer_handshake = ibuffer_cen && ibuffer_ready;
assign ibuffer_rd_done = ibuffer_handshake && ibuffer_req_cnt==ibuffer_data_num-1;

always @(posedge clk or negedge rst_n) begin
    if (rst_n==1'b0) begin
        ibuffer_req_cnt <= {MEM_AW{1'b0}};
    end
    else if(ibuffer_rd_done) begin
        ibuffer_req_cnt <= {MEM_AW{1'b0}};
    end
    else if(ibuffer_handshake) begin
        ibuffer_req_cnt <= ibuffer_req_cnt + 1;
    end
end

assign ibuffer_outsd_req_num_next = (ibuffer_handshake && !ibuffer_r_handshake) ? (ibuffer_outsd_req_num + 2'd1) :
                                    (!ibuffer_handshake && ibuffer_r_handshake) ? (ibuffer_outsd_req_num - 2'd1) :
                                    ibuffer_outsd_req_num;

always @(posedge clk or negedge rst_n) begin
    if (rst_n==1'b0) begin
        ibuffer_outsd_req_num <= 2'd0;
    end
    else begin
        ibuffer_outsd_req_num <= ibuffer_outsd_req_num_next;
    end
end

// access ibuffer
assign ibuffer_wen = 1'b0;
assign ibuffer_rready = !full_pingpong;
assign ibuffer_r_handshake = ibuffer_rready && ibuffer_rvalid;
assign ibuffer_pause_req = (ibuffer_outsd_req_num >= space_of_pingpong);
assign ibuffer_restart_req = (ibuffer_handshake || !ibuffer_cen) 
                          && (ibuffer_outsd_req_num_next < space_of_pingpong_next) 
                          && ibuffer_rd_flag;

always @(posedge clk or negedge rst_n) begin
    if (rst_n==1'b0) begin
        ibuffer_rd_flag <= 1'b0;
    end
    else if(ibuffer_rd_done) begin
        ibuffer_rd_flag <= 1'b0;
    end
    else if(noc_wr_start) begin
        ibuffer_rd_flag <= 1'b1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (rst_n==1'b0) begin
        ibuffer_cen <= 1'b0;
    end
    else if(ibuffer_rd_done) begin
        ibuffer_cen <= 1'b0;
    end
    else if(ibuffer_req_cnt < ibuffer_data_num) begin
        // when back pressure, hold
        if(ibuffer_cen && !ibuffer_ready) begin
            ibuffer_cen <= 1'b1;
        end
        // initial read ibuffer
        else if(!ibuffer_cen && noc_wr_start) begin
            ibuffer_cen <= 1'b1;
        end
        // when run out of pingpong space, stop read
        else if(ibuffer_pause_req) begin
            ibuffer_cen <= 1'b0;
        end
        // when space enough to accept rdata, restart read
        else if(ibuffer_restart_req) begin
            ibuffer_cen <= 1'b1;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (rst_n==1'b0) begin
        ibuffer_addr <= {MEM_AW{1'b0}};
    end
    else if(noc_wr_start) begin
        ibuffer_addr <= ibuffer_data_addr;
    end
    else if (ibuffer_handshake) begin
        ibuffer_addr <= ibuffer_addr + 1;
    end
end

// process rdata from ibuffer
always @(posedge clk or negedge rst_n) begin
    if (rst_n==1'b0) begin
        rd_data_pingpong[0] <= {DATA_WIDTH{1'b0}};
        rd_data_pingpong[1] <= {DATA_WIDTH{1'b0}};
    end
    else if(ibuffer_r_handshake) begin
        rd_data_pingpong[write_ptr_pingpong[0]] <= ibuffer_rdata;
    end
end

assign empty_pingpong = read_ptr_pingpong==write_ptr_pingpong;
assign full_pingpong  = (read_ptr_pingpong[1]!=write_ptr_pingpong[1]) 
                     && (read_ptr_pingpong[0]==write_ptr_pingpong[1]);

assign read_ptr_increase = noc_rd_pingpong_handshake && (word_offset=={$clog2(WORD_NUM){1'b1}} || noc_rd_pingpong_done);
always @(posedge clk or negedge rst_n) begin
    if (rst_n==1'b0) begin
        read_ptr_pingpong  <= 2'd0;
    end
    else if (noc_wr_start) begin
        read_ptr_pingpong  <= 2'd0;
    end
    else if(read_ptr_increase) begin
        read_ptr_pingpong <= read_ptr_pingpong + 1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (rst_n==1'b0) begin
        write_ptr_pingpong <= 2'd0;
    end
    else if (noc_wr_start) begin
        write_ptr_pingpong  <= 2'd0;
    end
    else if(ibuffer_r_handshake) begin
        write_ptr_pingpong <= write_ptr_pingpong + 1;
    end
end

assign space_of_pingpong_next = (read_ptr_increase && !ibuffer_r_handshake) ? (space_of_pingpong + 2'd1) :
                                (!read_ptr_increase && ibuffer_r_handshake) ? (space_of_pingpong - 2'd1) :
                                space_of_pingpong;

always @(posedge clk or negedge rst_n) begin
    if (rst_n==1'b0) begin
        space_of_pingpong  <= 2'd2;
    end
    else begin
        space_of_pingpong <= space_of_pingpong_next;
    end
end

// ===================================
// read pingpong buffer
// ===================================
//read pinpong buffer
assign noc_read_pingpong = noc_wr_ready_pipe[0];
assign noc_rd_pingpong_handshake = noc_read_pingpong && !empty_pingpong;
assign noc_rd_pingpong_done = noc_rd_pingpong_handshake && (rd_pingpong_cnt==ibuffer_word_num-1);

always @(posedge clk or negedge rst_n) begin
    if (rst_n==1'b0) begin
        rd_pingpong_cnt <= {MAX_WORD_LEN{1'b0}};
    end
    else if(noc_wr_start) begin
        rd_pingpong_cnt <= {MAX_WORD_LEN{1'b0}};
    end
    else if(noc_rd_pingpong_handshake) begin
        rd_pingpong_cnt <= rd_pingpong_cnt + 1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (rst_n==1'b0) begin
        word_offset <= {$clog2(WORD_NUM){1'b0}};
    end
    else if(noc_wr_start) begin
        word_offset <= ibuffer_word_addr[0+:$clog2(WORD_NUM)];
    end
    else if(noc_rd_pingpong_handshake) begin
        word_offset <= word_offset + 1;
    end
end
assign bits_offset = {word_offset, {$clog2(WORD_WIDTH){1'b0}}};
assign noc_rd_pingpong_data = rd_data_pingpong[read_ptr_pingpong[0]][bits_offset+:WORD_WIDTH];


// ===================================
// write noc
// ===================================
always @(posedge clk or negedge rst_n) begin
    if (rst_n==1'b0) begin
        wr_req_cnt <= {MAX_WORD_LEN{1'b0}};
    end
    else if(noc_wr_start) begin
        wr_req_cnt <= {MAX_WORD_LEN{1'b0}};
    end
    else if(noc_wr_done) begin
        wr_req_cnt <= {MAX_WORD_LEN{1'b0}};
    end
    else if(noc_wr_ready_pipe[1] && noc_wr_req_pipe[1]) begin
        wr_req_cnt <= wr_req_cnt + 1;
    end
end

assign noc_wr_req_pipe[0] = !empty_pingpong;
assign noc_wr_wdata_pipe[0] = noc_rd_pingpong_data;
assign noc_wr_last_pipe[0] = noc_rd_pingpong_done;

// fwd_pipe #(
//     .DATA_W(1+WORD_WIDTH)
// ) u_noc_last_wdata_pipe(
//     .clk(clk),
//     .rst_n(rst_n),
//     .f_valid_in(noc_wr_req_pipe[0]),
//     .f_data_in({noc_wr_last_pipe[0], noc_wr_wdata_pipe[0]}),
//     .f_ready_out(noc_wr_ready_pipe[0]),
//     .b_valid_out(noc_wr_req_pipe[1]),
//     .b_data_out({noc_wr_last_pipe[1], noc_wr_wdata_pipe[1]}),
//     .b_ready_in(noc_wr_ready_pipe[1])
// );

// bypass
assign noc_wr_req_pipe[1] = noc_wr_req_pipe[0];
assign {noc_wr_last_pipe[1], noc_wr_wdata_pipe[1]} = {noc_wr_last_pipe[0], noc_wr_wdata_pipe[0]};
assign noc_wr_ready_pipe[0] = noc_wr_ready_pipe[1];


assign noc_wr_ready_pipe[1] = noc_wr_ready;
assign noc_wr_req  = noc_wr_req_pipe[1];
assign noc_wr_data = noc_wr_wdata_pipe[1];
assign noc_wr_last = noc_wr_last_pipe[1];
assign noc_wr_done = (noc_wr_ready_pipe[1] && noc_wr_req_pipe[1]) && (wr_req_cnt==ibuffer_word_num-1);
endmodule