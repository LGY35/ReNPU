module pc_debug(
    input                           clk,
    input                           rst_n,
    input           [18:0]          pc_input,

    input                           fetch_en,
    input                           fetch_req,
    input                           sleep_en,

    output  logic                   pc_serial_out
);

localparam  IDLE    = 2'd0;
localparam  WAIT    = 2'd1;
localparam  WORK    = 2'd2;

logic   [18:0]  pc_reg;
logic           sleep_en_reg, fetch_en_reg;
logic           fetch_req_reg;
logic   [18:0]  pc_input_reg;
logic   [4:0]   status_cnt;

logic [1:0] fsm_cs, fsm_ns;

always_comb begin
    fsm_ns = fsm_cs;

    case(fsm_cs)
    IDLE: begin
        // only core start , can enter "wait" state waiting for core fetch instr. 
        if(~fetch_en_reg & fetch_en) begin
            fsm_ns = WAIT;
        end
    end
    WAIT: begin
        // when core start fetch instr, can enter work where fsm sending pc
        if(fetch_req | fetch_req_reg) begin
            fsm_ns = WORK;
        end
    end
    WORK: begin
        // only finish sending can swith state.
        if(status_cnt == 5'd18) begin
            // if core exu wfi, wait for next.
            if((sleep_en | sleep_en_reg)) begin
                // (1) core send wfi in sleep_en_reg and idma send fetch_en / or fetch_en_reg (when fetch_en arrives, cnt doesn't reach max)
                // (2) core send wfi in sleep_en and idma send fetch_en_reg
                if((fetch_en | fetch_en_reg)) begin
                    fsm_ns = WAIT;
                end
                //  core send wfi in sleep_en , so switch to IDLE
                else begin
                    fsm_ns = IDLE;
                end
            end
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

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        sleep_en_reg <= 'b0;
    end
    // reset because have used the signal
    else if((fsm_cs == WORK) & (status_cnt == 5'd18)) begin
        sleep_en_reg <= 'b0;
    end
    // rising edge
    else if((fsm_cs == WORK) & (sleep_en & ~sleep_en_reg)) begin
        sleep_en_reg <= 1'b1;
    end
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        fetch_en_reg <= 'b0;
    end
    else if((fsm_cs == WORK) & (status_cnt == 5'd18)) begin
        fetch_en_reg <= 1'b0;
    end
    //  only when core send wfi and find rising edge can set hign.
    else if((fsm_cs == WORK) & (fetch_en & ~fetch_en_reg) & (sleep_en_reg)) begin
        fetch_en_reg <= 1'b1;
    end
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        fetch_req_reg <= 'b0;
    end
    // everytime when finish one send and find rising edge, must wfi , so has hign priority.
    else if((fsm_cs == WORK) & (status_cnt == 5'd18) & (sleep_en & ~sleep_en_reg)) begin
        fetch_req_reg <= 1'b0;
    end
    // as long as fetch req when wait/work, reg set to hign
    else if(((fsm_cs == WAIT) | (fsm_cs == WORK)) & fetch_req) begin
        fetch_req_reg <= 1'b1;
    end
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        pc_input_reg <= 'b0;
    end
    else if(((fsm_cs == WAIT) | (fsm_cs == WORK)) & fetch_req) begin
        pc_input_reg <= pc_input;
    end
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        pc_reg <= 'b0;
    end
    else if((fsm_cs == WAIT)) begin
        if(fetch_req) begin
            pc_reg <= pc_input;
        end
        else if(fetch_req_reg) begin
            pc_reg <= pc_input_reg; // for holding the pc value
        end
    end
    else if((fsm_cs == WORK) & (status_cnt == 5'd18)) begin
        if(fetch_req) begin
            pc_reg <= pc_input;
        end
        else if(fetch_req_reg) begin
            pc_reg <= pc_input_reg;
        end
    end
    // left shift
    else if((fsm_cs == WORK)) begin
        pc_reg <= {pc_reg[17:0],1'b0};
    end
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        status_cnt <= 'b0;
    end
    else if((fsm_cs == WORK) & (status_cnt == 5'd18)) begin
        status_cnt <= 'b0;
    end
    else if((fsm_cs == WORK)) begin
        status_cnt <= status_cnt + 5'd1;
    end
end

assign pc_serial_out = ((fsm_cs == WAIT) & (fetch_req | fetch_req_reg)) // wait status send a 1 in front to tell idma it's a valid signal 
                     | ((fsm_cs == WORK) & pc_reg[18]);


endmodule