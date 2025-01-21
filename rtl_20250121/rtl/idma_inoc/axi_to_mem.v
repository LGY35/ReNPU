module axi_to_mem #
(
    // Width of data bus in bits
    parameter DATA_WIDTH = 32,
    // Width of address bus in bits
    parameter ADDR_WIDTH = 16,
    // Width of wstrb (width of data bus in words)
    parameter STRB_WIDTH = (DATA_WIDTH/8),
    // Width of ID signal
    parameter ID_WIDTH = 8,
    // Extra pipeline register stages on input
    parameter INPUT_PIPE_STAGES = 1,
    // Extra pipeline register stages on output
    parameter OUTPUT_PIPE_STAGES = 1,
    // Access Memory Latency
    parameter MEM_LATENCY = 1,
    // Memory Address Width
    parameter MEM_ADDR_WIDTH = ADDR_WIDTH - $clog2(STRB_WIDTH)
)
(
    input                     clk,
    input                     rst_n,

    input   [ID_WIDTH-1:0]    s_axi_awid,
    input   [ADDR_WIDTH-1:0]  s_axi_awaddr,
    input   [7:0]             s_axi_awlen,
    input   [2:0]             s_axi_awsize,
    input   [1:0]             s_axi_awburst,
    input                     s_axi_awlock,
    input   [3:0]             s_axi_awcache,
    input   [2:0]             s_axi_awprot,
    input                     s_axi_awvalid,
    output                    s_axi_awready,
    input   [DATA_WIDTH-1:0]  s_axi_wdata,
    input   [STRB_WIDTH-1:0]  s_axi_wstrb,
    input                     s_axi_wlast,
    input                     s_axi_wvalid,
    output                    s_axi_wready,
    output  [ID_WIDTH-1:0]    s_axi_bid,
    output  [1:0]             s_axi_bresp,
    output                    s_axi_bvalid,
    input                     s_axi_bready,
    input   [ID_WIDTH-1:0]    s_axi_arid,
    input   [ADDR_WIDTH-1:0]  s_axi_araddr,
    input   [7:0]             s_axi_arlen,
    input   [2:0]             s_axi_arsize,
    input   [1:0]             s_axi_arburst,
    input                     s_axi_arlock,
    input   [3:0]             s_axi_arcache,
    input   [2:0]             s_axi_arprot,
    input                     s_axi_arvalid,
    output                    s_axi_arready,
    output  [ID_WIDTH-1:0]    s_axi_rid,
    output  [DATA_WIDTH-1:0]  s_axi_rdata,
    output  [1:0]             s_axi_rresp,
    output                    s_axi_rlast,
    output                    s_axi_rvalid,
    input                     s_axi_rready,
    // mem ports
    output                    mem_cen, // mem chip enable
    output                    mem_last, // last mem read req
    output  [MEM_ADDR_WIDTH-1:0]  mem_addr, // mem address
    input                     mem_ready, // mem req back pressure
    output                    mem_wen, // mem write enable
    output  [DATA_WIDTH-1:0]  mem_wdata, // write data
    output  [STRB_WIDTH-1:0]  mem_wstrb, // write strobe
    input                     mem_rvalid, // read valid
    input                     mem_rlast, // last read data
    output                    mem_rready, // resp back pressure
    input   [DATA_WIDTH-1:0]  mem_rdata // read data from mem

);


localparam WORD_WIDTH = STRB_WIDTH;
localparam WORD_SIZE = DATA_WIDTH/WORD_WIDTH;

// bus width assertions
// initial begin
//     if (WORD_SIZE * STRB_WIDTH != DATA_WIDTH) begin
//         $error("Error: AXI data width not evenly divisble (instance %m)");
//         $finish;
//     end

//     if (2**$clog2(WORD_WIDTH) != WORD_WIDTH) begin
//         $error("Error: AXI word width must be even power of two (instance %m)");
//         $finish;
//     end

//     if((INPUT_PIPE_STAGES<1) || (OUTPUT_PIPE_STAGES<1) || (MEM_LATENCY<1)) begin
//         $error("Error: Input or Output pipeline stages or Memory Latency must equal or great than 1");
//         $finish;
//     end
// end

// state parameter
localparam [1:0]
    READ_STATE_IDLE = 2'd0,
    READ_STATE_BURST = 2'd1,
    READ_STATE_RESP = 2'd2;

reg [1:0] read_state_reg;
reg [1:0] read_state_next;

localparam [1:0]
    WRITE_STATE_IDLE = 2'd0,
    WRITE_STATE_BURST = 2'd1,
    WRITE_STATE_RESP = 2'd2;

reg [1:0] write_state_reg;
reg [1:0] write_state_next;

// internal signals
wire mem_wr_en;
wire mem_wr_done;
wire mem_rd_en;
wire mem_rd_last;

wire [INPUT_PIPE_STAGES:0] mem_cen_pipe;
wire [INPUT_PIPE_STAGES:0] mem_ready_pipe;
wire [INPUT_PIPE_STAGES:0] mem_wen_pipe;
wire [INPUT_PIPE_STAGES:0] mem_last_pipe;
wire [MEM_ADDR_WIDTH-1:0]  mem_addr_pipe [INPUT_PIPE_STAGES:0] ;
wire [DATA_WIDTH-1:0]      mem_wdata_pipe [INPUT_PIPE_STAGES:0] ;
wire [STRB_WIDTH-1:0]      mem_wstrb_pipe [INPUT_PIPE_STAGES:0] ;
reg [INPUT_PIPE_STAGES+MEM_LATENCY-1:0] mem_wr_done_reg;

wire [OUTPUT_PIPE_STAGES:0] mem_rvalid_pipe;
wire [OUTPUT_PIPE_STAGES:0] mem_rready_pipe;
wire [DATA_WIDTH-1:0]       mem_rdata_pipe [OUTPUT_PIPE_STAGES:0];
wire [ID_WIDTH-1:0]         mem_rid_pipe [OUTPUT_PIPE_STAGES:0];
wire [OUTPUT_PIPE_STAGES:0] mem_rlast_pipe ;

wire [OUTPUT_PIPE_STAGES:0] mem_bvalid_pipe;
wire [OUTPUT_PIPE_STAGES:0] mem_bready_pipe;
wire [ID_WIDTH-1:0]         mem_bid_pipe [OUTPUT_PIPE_STAGES:0];

reg [ID_WIDTH-1:0] read_id_reg;
reg [ID_WIDTH-1:0] read_id_next;
reg [ADDR_WIDTH-1:0] read_addr_reg;
reg [ADDR_WIDTH-1:0] read_addr_next;
wire[ADDR_WIDTH-1:0] read_addr_add_size;
wire[ADDR_WIDTH-1:0] read_byte_num;
wire[ADDR_WIDTH-1:0] read_byte_num_x4;
wire[ADDR_WIDTH-1:0] read_byte_num_x8;
wire[ADDR_WIDTH-1:0] read_byte_num_x16;
reg [7:0] read_count_reg;
reg [7:0] read_count_next;
reg [2:0] read_size_reg;
reg [2:0] read_size_next;
reg [1:0] read_burst_reg;
reg [1:0] read_burst_next;
reg [7:0] read_len_reg;
reg [7:0] read_len_next;
reg [ID_WIDTH-1:0] write_id_reg;
reg [ID_WIDTH-1:0] write_id_next;
reg [ADDR_WIDTH-1:0] write_addr_reg;
reg [ADDR_WIDTH-1:0] write_addr_next;
wire[ADDR_WIDTH-1:0] write_addr_add_size;
wire[ADDR_WIDTH-1:0] write_byte_num;
wire[ADDR_WIDTH-1:0] write_byte_num_x4;
wire[ADDR_WIDTH-1:0] write_byte_num_x8;
wire[ADDR_WIDTH-1:0] write_byte_num_x16;
reg [7:0] write_count_reg;
reg [7:0] write_count_next;
reg [2:0] write_size_reg;
reg [2:0] write_size_next;
reg [1:0] write_burst_reg;
reg [1:0] write_burst_next;
reg [7:0] write_len_reg;
reg [7:0] write_len_next;
wire[ADDR_WIDTH-1:0] read_addr_aligned_size;
wire[ADDR_WIDTH-1:0] write_addr_aligned_size;

reg s_axi_awready_reg;
reg s_axi_awready_next;
reg s_axi_arready_reg;
reg s_axi_arready_next;

wire s_axi_aw_handshake;
wire s_axi_w_handshake;
wire s_axi_ar_handshake;
wire s_axi_r_handshake;
wire s_axi_b_handshake;

assign s_axi_awready = s_axi_awready_reg && (read_state_next==READ_STATE_IDLE);
assign s_axi_wready = mem_wr_en && mem_ready_pipe[0];
assign s_axi_bid = mem_bid_pipe[OUTPUT_PIPE_STAGES];
assign s_axi_bresp = 2'b00;
assign s_axi_bvalid = mem_bvalid_pipe[OUTPUT_PIPE_STAGES];
assign s_axi_arready = s_axi_arready_reg;
assign s_axi_rid = mem_rid_pipe[OUTPUT_PIPE_STAGES];
assign s_axi_rdata = mem_rdata_pipe[OUTPUT_PIPE_STAGES];
assign s_axi_rresp = 2'b00;
assign s_axi_rlast = mem_rlast_pipe[OUTPUT_PIPE_STAGES];
assign s_axi_rvalid = mem_rvalid_pipe[OUTPUT_PIPE_STAGES];
assign s_axi_aw_handshake = s_axi_awready && s_axi_awvalid;
assign s_axi_w_handshake = s_axi_wready && s_axi_wvalid;
assign s_axi_ar_handshake = s_axi_arready && s_axi_arvalid;
assign s_axi_r_handshake = s_axi_rready && s_axi_rvalid;
assign s_axi_b_handshake = s_axi_bready && s_axi_bvalid;

integer i;
genvar j;

// ===================================
// Write State
// ===================================

// state trans
always @* begin
    case (write_state_reg)
        WRITE_STATE_IDLE: begin
            if (s_axi_aw_handshake) begin
                write_state_next = WRITE_STATE_BURST;
            end
            else begin
                write_state_next = WRITE_STATE_IDLE;
            end
        end
        WRITE_STATE_BURST: begin
            if (s_axi_w_handshake) begin
                if (write_count_reg > 0) begin
                    write_state_next = WRITE_STATE_BURST;
                end
                else begin
                    write_state_next = WRITE_STATE_RESP;
                end
            end
            else begin
                write_state_next = WRITE_STATE_BURST;
            end
        end
        WRITE_STATE_RESP: begin
            if (s_axi_b_handshake) begin
                write_state_next = WRITE_STATE_IDLE;
            end
            else begin
                write_state_next = WRITE_STATE_RESP;
            end
        end
        default:
            write_state_next = WRITE_STATE_IDLE;
    endcase
end

// aw ready, w id, w size
always @* begin
    case (write_state_reg)
        WRITE_STATE_IDLE: begin
            if(s_axi_aw_handshake) begin
                s_axi_awready_next = 1'b0;
                write_id_next = s_axi_awid;
                write_size_next = s_axi_awsize < $clog2(STRB_WIDTH) ? s_axi_awsize : $clog2(STRB_WIDTH);
                write_burst_next = s_axi_awburst;
                write_len_next = s_axi_awlen;
            end
            else begin
                s_axi_awready_next = (read_state_next==READ_STATE_IDLE);
                write_id_next = write_id_reg;
                write_size_next = write_size_reg;
                write_burst_next = write_burst_reg;
                write_len_next = write_len_reg;
            end
        end
        default: begin
            s_axi_awready_next = 1'b0;
            write_id_next = write_id_reg;
            write_size_next = write_size_reg;
            write_burst_next = write_burst_reg;
            write_len_next = write_len_reg;
        end
    endcase
end

// mem write addr/enable/len
assign mem_wr_en = (write_state_reg==WRITE_STATE_BURST);
assign write_addr_aligned_size = write_addr_reg >> write_size_reg;
assign write_byte_num = (1 << write_size_reg);
assign write_addr_add_size = write_addr_reg + write_byte_num;
assign write_byte_num_x4 = write_byte_num << 3'd2;
assign write_byte_num_x8 = write_byte_num << 3'd3;
assign write_byte_num_x16 =write_byte_num << 3'd4;
always @* begin
    case (write_state_reg)
        WRITE_STATE_IDLE: begin
            if(s_axi_aw_handshake) begin
                write_addr_next = s_axi_awaddr;
                write_count_next = s_axi_awlen;
            end
            else begin
                write_addr_next = write_addr_reg;
                write_count_next = write_count_reg;
            end
        end
        WRITE_STATE_BURST: begin
            if(s_axi_w_handshake) begin
                // write_addr_next = ((write_burst_reg==2'd2) && (write_addr_aligned_size%(write_len_reg+1) == write_len_reg)) ? 
                //                   (write_addr_reg - (1 << write_size_reg)*write_len_reg) : write_addr_reg + (1 << write_size_reg);
                // WRAP burst, write_len_reg can only be 1/3/7/15
                if (write_burst_reg==2'd2) begin
                    case (write_len_reg)
                        8'd1 : write_addr_next = (write_addr_aligned_size[0:0]==1'd1) ? (write_addr_reg - write_byte_num) : write_addr_add_size;
                        8'd3 : write_addr_next = (write_addr_aligned_size[1:0]==2'd3) ? (write_addr_add_size - write_byte_num_x4) : write_addr_add_size;
                        8'd7 : write_addr_next = (write_addr_aligned_size[2:0]==3'd7) ? (write_addr_add_size - write_byte_num_x8) : write_addr_add_size;
                        8'd15: write_addr_next = (write_addr_aligned_size[3:0]==4'd15)? (write_addr_add_size - write_byte_num_x16): write_addr_add_size;
                        default: write_addr_next = write_addr_add_size;
                    endcase
                end
                else begin
                    write_addr_next = write_addr_add_size;
                end
                write_count_next = write_count_reg - 1;
            end
            else begin
                write_addr_next = write_addr_reg;
                write_count_next = write_count_reg;
            end
        end
        default: begin
            write_addr_next = write_addr_reg;
            write_count_next = write_count_reg;
        end
    endcase
end

// b chn
assign mem_wr_done = mem_wr_en && mem_ready_pipe[0] && (write_count_reg==8'd0);
always @(posedge clk or negedge rst_n) begin
    if(rst_n==1'b0) begin
        for(i=0; i<INPUT_PIPE_STAGES+MEM_LATENCY; i=i+1) begin
            mem_wr_done_reg[i] <= 1'b0;
        end
    end
    else begin
        mem_wr_done_reg[0] <= mem_wr_done;
        for(i=1; i<INPUT_PIPE_STAGES+MEM_LATENCY; i=i+1) begin
            mem_wr_done_reg[i] <= mem_wr_done_reg[i-1];
        end
    end
end

// write related reg
always @(posedge clk or negedge rst_n) begin
    if (rst_n==1'b0) begin
        write_state_reg <= WRITE_STATE_IDLE;
        write_size_reg  <= 3'b0;
        write_id_reg <= {ID_WIDTH{1'b0}};
        write_addr_reg <= {ADDR_WIDTH{1'b0}};
        write_count_reg <= 8'b0;
        write_burst_reg <= 2'b0;
        write_len_reg   <= 8'b0;

        s_axi_awready_reg <= 1'b0;
    end
    else begin
        write_state_reg <= write_state_next;
        write_size_reg <= write_size_next;
        write_id_reg <= write_id_next;
        write_addr_reg <= write_addr_next;
        write_count_reg <= write_count_next;
        write_burst_reg <= write_burst_next;
        write_len_reg   <= write_len_next  ;
        
        s_axi_awready_reg <= s_axi_awready_next;
    end
end


// ===================================
// Read State
// ===================================

// state trans
always @* begin
    case (read_state_reg)
        READ_STATE_IDLE: begin
            if (s_axi_ar_handshake) begin
                read_state_next = READ_STATE_BURST;
            end
            else begin
                read_state_next = READ_STATE_IDLE;
            end
        end
        READ_STATE_BURST: begin
            if (mem_rd_en && mem_ready_pipe[0]) begin
                if (read_count_reg > 0) begin
                    read_state_next = READ_STATE_BURST;
                end
                else begin
                    read_state_next = READ_STATE_RESP;
                end
            end
            else begin
                read_state_next = READ_STATE_BURST;
            end
        end
        READ_STATE_RESP: begin
            if(s_axi_r_handshake && s_axi_rlast) begin
                read_state_next = READ_STATE_IDLE;
            end
            else begin
                read_state_next = READ_STATE_RESP;
            end
        end
        default: begin
            read_state_next = READ_STATE_IDLE;
        end
    endcase
end

// ar ready, r id, r size
always @* begin
    case (read_state_reg)
        READ_STATE_IDLE: begin
            if(s_axi_ar_handshake) begin
                s_axi_arready_next = 1'b0;
                read_id_next = s_axi_arid;
                read_size_next = s_axi_arsize < $clog2(STRB_WIDTH) ? s_axi_arsize : $clog2(STRB_WIDTH);
                read_burst_next = s_axi_arburst;
                read_len_next = s_axi_arlen;
            end
            else begin
                s_axi_arready_next = !s_axi_awvalid && (write_state_reg==WRITE_STATE_IDLE);
                read_id_next = read_id_reg;
                read_size_next = read_size_reg;
                read_burst_next = read_burst_reg;
                read_len_next = read_len_reg;
            end
        end
        default: begin
            s_axi_arready_next = 1'b0;
            read_id_next = read_id_reg;
            read_size_next = read_size_reg;
            read_burst_next = read_burst_reg;
            read_len_next = read_len_reg;
        end
    endcase
end

// mem read addr/enable/len
assign mem_rd_en = (read_state_reg==READ_STATE_BURST);
assign read_addr_aligned_size = read_addr_reg >> read_size_reg;
assign read_byte_num = (1 << read_size_reg);
assign read_addr_add_size = read_addr_reg + read_byte_num;
assign read_byte_num_x4 = read_byte_num << 3'd2;
assign read_byte_num_x8 = read_byte_num << 3'd3;
assign read_byte_num_x16 =read_byte_num << 3'd4;

always @* begin
    case (read_state_reg)
        READ_STATE_IDLE: begin
            if(s_axi_ar_handshake) begin
                read_addr_next = s_axi_araddr;
                read_count_next = s_axi_arlen;
            end
            else begin
                read_addr_next = read_addr_reg;
                read_count_next= read_count_reg;
            end
        end
        READ_STATE_BURST: begin
            if(mem_rd_en && mem_ready_pipe[0]) begin
                // read_addr_next = ((read_burst_reg==2'd2) && (read_addr_aligned_size%(read_len_reg+1) == read_len_reg)) ? 
                //                  (read_addr_reg - (1 << read_size_reg)*read_len_reg) : read_addr_reg + (1 << read_size_reg);
                
                // WRAP burst, read_len_reg can only be 1/3/7/15
                if (read_burst_reg==2'd2) begin
                    case (read_len_reg)
                        8'd1 : read_addr_next = (read_addr_aligned_size[0:0]==1'd1) ? (read_addr_reg - read_byte_num) : read_addr_add_size;
                        8'd3 : read_addr_next = (read_addr_aligned_size[1:0]==2'd3) ? (read_addr_add_size - read_byte_num_x4) : read_addr_add_size;
                        8'd7 : read_addr_next = (read_addr_aligned_size[2:0]==3'd7) ? (read_addr_add_size - read_byte_num_x8) : read_addr_add_size;
                        8'd15: read_addr_next = (read_addr_aligned_size[3:0]==4'd15)? (read_addr_add_size - read_byte_num_x16): read_addr_add_size;
                        default: read_addr_next = read_addr_add_size;
                    endcase
                end
                else begin
                    read_addr_next = read_addr_add_size;
                end
                read_count_next = read_count_reg - 1;
            end
            else begin
                read_addr_next = read_addr_reg;
                read_count_next = read_count_reg;
            end
        end
        default: begin
            read_addr_next = read_addr_reg;
            read_count_next = read_count_reg;
        end
    endcase
end

// read related reg
always @(posedge clk or negedge rst_n) begin
    if (rst_n==1'b0) begin
        read_state_reg <= READ_STATE_IDLE;
        read_size_reg  <= 3'b0;
        read_id_reg <= {ID_WIDTH{1'b0}};
        read_addr_reg <= {ADDR_WIDTH{1'b0}};
        read_count_reg <= 8'b0;
        read_burst_reg <= 2'b0;
        read_len_reg   <= 8'b0;

        s_axi_arready_reg <= 1'b0;
    end
    else begin
        read_state_reg <= read_state_next;
        read_size_reg <= read_size_next;
        read_id_reg <= read_id_next;
        read_addr_reg <= read_addr_next;
        read_count_reg <= read_count_next;
        read_burst_reg <= read_burst_next;
        read_len_reg   <= read_len_next;
        
        s_axi_arready_reg <= s_axi_arready_next;
    end
end

// r chn
assign mem_rd_last = mem_rd_en && mem_ready_pipe[0] && (read_count_reg==8'd0);


// ===================================
// Request Stage 0
// ===================================
assign mem_cen_pipe[0] = mem_wr_en || mem_rd_en;
assign mem_wen_pipe[0] = mem_wr_en;
assign mem_last_pipe[0] = mem_rd_last;
assign mem_addr_pipe[0] = mem_wr_en ? write_addr_reg[$clog2(STRB_WIDTH)+:MEM_ADDR_WIDTH] : read_addr_reg[$clog2(STRB_WIDTH)+:MEM_ADDR_WIDTH];
assign mem_wdata_pipe[0] = s_axi_wdata;
assign mem_wstrb_pipe[0] = s_axi_wstrb;

// ===================================
// Request Stage 1~INPUT_PIPE_STAGES-1
// ===================================
assign mem_cen = mem_cen_pipe[INPUT_PIPE_STAGES];
assign mem_last= mem_last_pipe[INPUT_PIPE_STAGES];
assign mem_wen = mem_wen_pipe[INPUT_PIPE_STAGES];
assign mem_addr = mem_addr_pipe[INPUT_PIPE_STAGES];
assign mem_wdata = mem_wdata_pipe[INPUT_PIPE_STAGES];
assign mem_wstrb = mem_wstrb_pipe[INPUT_PIPE_STAGES];
assign mem_ready_pipe[INPUT_PIPE_STAGES] = mem_ready;

generate
    for(j=1; j<=INPUT_PIPE_STAGES; j=j+1) begin:INPUT_PIPE
        fwd_pipe #(
            .DATA_W(1+1+MEM_ADDR_WIDTH+DATA_WIDTH+STRB_WIDTH)
        ) u_fwd_pipe_wen_addr_wdata(
            .clk(clk),
            .rst_n(rst_n),
            .f_valid_in(mem_cen_pipe[j-1]),
            .f_data_in({mem_last_pipe[j-1], mem_wen_pipe[j-1], mem_addr_pipe[j-1], mem_wdata_pipe[j-1], mem_wstrb_pipe[j-1]}),
            .f_ready_out(mem_ready_pipe[j-1]),
            .b_valid_out(mem_cen_pipe[j]),
            .b_data_out({mem_last_pipe[j], mem_wen_pipe[j], mem_addr_pipe[j], mem_wdata_pipe[j], mem_wstrb_pipe[j]}),
            .b_ready_in(mem_ready_pipe[j])
        );
    end
endgenerate

// ===================================
// Response Stage 0
// ===================================
assign mem_bvalid_pipe[0] = mem_wr_done_reg[INPUT_PIPE_STAGES+MEM_LATENCY-1];
assign mem_bid_pipe[0] = write_id_reg;
assign mem_rvalid_pipe[0] = mem_rvalid;
assign mem_rdata_pipe[0]  = mem_rdata;
assign mem_rid_pipe[0] = read_id_reg;
assign mem_rlast_pipe[0] = mem_rlast;

// ===================================
// Response Stage 1~OUTPUT_PIPE_STAGES-1
// ===================================
assign mem_bready_pipe[OUTPUT_PIPE_STAGES] = s_axi_bready;
assign mem_rready_pipe[OUTPUT_PIPE_STAGES] = s_axi_rready;
assign mem_rready = mem_rready_pipe[0];

generate
    for(j=1; j<=OUTPUT_PIPE_STAGES; j=j+1) begin:OUTPUT_PIPE
        
        fwd_pipe #(
            .DATA_W(ID_WIDTH)
        ) u_fwd_pipe_bid(
            .clk(clk),
            .rst_n(rst_n),
            .f_valid_in(mem_bvalid_pipe[j-1]),
            .f_data_in(mem_bid_pipe[j-1]),
            .f_ready_out(mem_bready_pipe[j-1]),
            .b_valid_out(mem_bvalid_pipe[j]),
            .b_data_out(mem_bid_pipe[j]),
            .b_ready_in(mem_bready_pipe[j])
        );
        
        fwd_pipe #(
        // fwdbwd_pipe #(
            .DATA_W(DATA_WIDTH+ID_WIDTH+1)
        ) u_fwd_pipe_rlast_rid_rdata(
            .clk(clk),
            .rst_n(rst_n),
            .f_valid_in(mem_rvalid_pipe[j-1]),
            .f_data_in({mem_rlast_pipe[j-1], mem_rid_pipe[j-1], mem_rdata_pipe[j-1]}),
            .f_ready_out(mem_rready_pipe[j-1]),
            .b_valid_out(mem_rvalid_pipe[j]),
            .b_data_out({mem_rlast_pipe[j], mem_rid_pipe[j], mem_rdata_pipe[j]}),
            .b_ready_in(mem_rready_pipe[j])
        );
    end
endgenerate 


endmodule