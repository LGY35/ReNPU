module pc_debug(
    input                           clk,
    input                           rst_n,
    input                           debug_enq_valid,
    input           [31:0]          debug_w_data,
    input                           sleep,

    // interface with idma_inoc
    output  logic                   debug_serial_out,
    output  logic                   finish_status
);

logic [0:0] fsm_cs, fsm_ns;
localparam  START_SIGNAL = 2'd0;
localparam  WORK    = 2'd1;

logic   [5:0]   status_cnt; // fsm_send_bits_cnt

// fifo_cnt
// logic [1:0]                 fifo_cnt;
logic [31:0]                fifo_o_buffer;

//fifo depth = 4
logic [3:0][31:0]           fifo_entry;
logic [2:0]                 enq_ptr, deq_ptr;
// logic                       fifo_push, fifo_pop;
logic [31:0]                fifo_in_data, fifo_out_data;
logic                       fifo_full, fifo_empty;

// finish_status
assign finish_status = (fsm == START_SIGNAL) & fifo_empty;

// enq 
assign fifo_in_data = debug_w_data;

always_comb begin
    fsm_ns = fsm_cs;

    case(fsm_cs)
    START_SIGNAL: begin
        if(!fifo_empty) begin
            fsm_ns = WORK;
        end
    end
    WORK: begin
        if(status_cnt == 5'd31) begin
            fsm_ns = START_SIGNAL;
        end
    end
    endcase
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        fsm_cs <= IDLE;
    end
    else begin
        fsm_cs <= fsm_ns;
    end
end

// always_ff @(posedge clk or negedge rst_n) begin
//     if(!rst_n) begin
//         sleep_en_reg <= 'b0;
//     end
//     else if((fsm_cs == WORK) & (status_cnt == 5'd31)) begin
//         sleep_en_reg <= 'b0;
//     end
//     else if((fsm_cs == WORK) & (sleep_en & ~sleep_en_reg)) begin
//         sleep_en_reg <= 1'b1;
//     end
// end

// always_ff @(posedge clk or negedge rst_n) begin
//     if(!rst_n) begin
//         debug_enq_valid_reg <= 'b0;
//     end
//     else if((fsm_cs == WORK) & (status_cnt == 5'd31) & (sleep_en & ~sleep_en_reg)) begin
//         debug_enq_valid_reg <= 1'b0;
//     end
//     else if(((fsm_cs == WAIT) | (fsm_cs == WORK)) & debug_enq_valid) begin
//         debug_enq_valid_reg <= 1'b1;
//     end
// end


// send cnt
always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        status_cnt <= 'b0;
    end
    else if((fsm_cs == WORK) & (status_cnt == 5'd31)) begin
        status_cnt <= 'b0;
    end
    else if((fsm_cs == WORK)) begin
        status_cnt <= status_cnt + 5'd1;
    end
end

//enq
always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        enq_ptr <= 'd0;
    end
    else if(sleep) begin
        enq_ptr <= 'b0;
    end
    else if(debug_enq_valid) begin
        enq_ptr <= enq_ptr + 3'd1;
    end
end

// deq
always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        deq_ptr <= 'b0;
    end
    else if(sleep) begin
        deq_ptr <= 'b0;
    end
    else if((fsm_cs == START_SIGNAL) && !fifo_empty) begin  // clear when wfi
        deq_ptr <= deq_ptr + 'b1;
    end
    else if(debug_enq_valid && fifo_full)begin
        deq_ptr <= deq_ptr + 'b1;
    end
end

// output buffer
always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        fifo_o_buffer <= 'b0;
    end
    else if((fsm_cs == START_SIGNAL) && !fifo_empty) begin // as long as last data has popped, can update output data
        fifo_o_buffer <= fifo_out_data;
    end
    else if((fsm_cs == WORK)) begin
        fifo_o_buffer <= {fifo_o_buffer[30:0],1'b0};// shift
    end
end

assign debug_serial_out = ((fsm_cs == START_SIGNAL))  // start signal: rising edge
                     | ((fsm_cs == WORK) & fifo_o_buffer[31]);  // serial output

//=======================FIFO depth = 4===========================================

assign fifo_full = (enq_ptr[1:0] == deq_ptr[1:0]) & (enq_ptr[2] ^ deq_ptr[2]);
assign fifo_empty = (enq_ptr == deq_ptr) & !sleep;       // sleep clear fifo, output empty


always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        fifo_entry <= 'd0;
    end
    else if(fifo_push) begin
        fifo_entry[enq_ptr[1:0]] <= fifo_in_data;
    end
end

assign fifo_out_data = fifo_entry[deq_ptr[1:0]];

// assign fifo_cnt = (deq_ptr[2] == enq_ptr[2]) ? enq_ptr - deq_ptr : deq_ptr[1:0] - enq_ptr[1:0];

endmodule