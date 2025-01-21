module riscv_prefetch_buffer
(
    input                               clk,
    input                               rst_n,
    //addr req
    input                               req_i, //from id_stage, start to fetch instr
    //branch addr req 
    input                               branch_i, //switch to new PC req
    input   [31:0]                      addr_i,   //new PC mux value
    //hwloop req
    input                               hwloop_jump_i,
    input   [31:0]                      hwloop_target_i,
    output                              hwloop_branch_o,
    //to instr memory / instr cache
    output  reg                         instr_req_o,
    input                               instr_gnt_i,
    output  [31:0]                      instr_addr_o,
    input                               instr_rvalid_i,
    input   [31:0]                      instr_rdata_i,
    //addr pop
    input                               ready_i,
    output  [31:0]                      addr_o,
    output  [31:0]                      rdata_o,
    output                              valid_o,
    output                              is_hwlp_o, //is set when the currently served data is from a hwloop
    
    output                              busy_o,
    input                               is_npu_insn_i
);

    logic   [31:0]  pc_nxt;
    logic   [31:0]  pc_nxt_r; //pc_nxt_r <= pc_nxt
    logic   [31:0]  pc_nxt_plus_4; //pc_nxt_plus_4 = pc_nxt_r + 4
    logic   addr_valid;
    logic   fetch_is_hwlp;
    logic   hwlp_masked, hwlp_branch, hwlp_speculative;
    logic   valid_stored;
    logic   unaligned_is_compressed;

    logic   fifo_valid;
    logic   fifo_ready;
    logic   fifo_hwlp;
    logic   fifo_clear;
 
    assign hwloop_branch_o = hwlp_branch;
    
    //============================
    //  fetch fifo
    //============================
    riscv_fetch_fifo U_riscv_fetch_fifo(
    .clk            (clk),
    .rst_n          (rst_n),
    .clear_i        (fifo_clear),
    
    .in_addr_i      (pc_nxt_r),
    .in_rdata_i     (instr_rdata_i),
    .in_valid_i     (fifo_valid),
    .in_ready_o     (fifo_ready),
    .in_is_hwlp_i   (fifo_hwlp),

    .out_addr_o     (addr_o),
    .out_rdata_o    (rdata_o),
    .out_valid_o    (valid_o),
    .out_ready_i    (ready_i),
    .out_is_hwlp_o  (is_hwlp_o),
    .unaligned_is_compressed_o(unaligned_is_compressed),
    .out_valid_stored_o(valid_stored),
    .is_npu_insn_i(is_npu_insn_i)
    );

    //============================
    //  fetch addr
    //============================
    assign  pc_nxt_plus_4 = {pc_nxt_r[31:2], 2'b00} + 32'd4;

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            pc_nxt_r <= 'b0;
        end
        else if(addr_valid) begin                                                          
            pc_nxt_r <= (hwlp_speculative & ~branch_i) ? hwloop_target_i : pc_nxt;
        end
    end

    //============================
    //  Instr Fetch FSM
    //============================
    enum logic [2:0] {IDLE, WAIT_GNT, WAIT_RVALID, WAIT_ABORTED} CS, NS;

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            CS <= IDLE;
        else
            CS <= NS;
    end

    always_comb begin
    case(CS)
        IDLE: begin
            if(req_i & (fifo_ready | branch_i | hwlp_branch | (hwlp_masked & valid_stored))) begin
                if(instr_gnt_i)
                    NS = WAIT_RVALID;
                else
                    NS = WAIT_GNT;
            end
            else begin
                NS = IDLE;
            end
        end
        WAIT_GNT: begin //we sent a req but did not yet get a grant
            if(instr_gnt_i)
                NS = WAIT_RVALID;
            else
                NS = WAIT_GNT;
        end
        WAIT_RVALID: begin //we wait for rvalid, after that we are ready to serve a new req
            if(req_i & (fifo_ready | branch_i | hwlp_branch | hwlp_masked)) begin
                if(instr_rvalid_i) begin
                    if(instr_gnt_i)
                        NS = WAIT_RVALID;
                    else
                        NS = WAIT_GNT;
                end
                else begin
                    if(branch_i | hwlp_branch | (hwlp_masked & valid_o))
                        NS = WAIT_ABORTED;
                    else
                        NS = WAIT_RVALID;
                end
            end
            else begin
                if(instr_rvalid_i)
                    NS = IDLE;
                else
                    NS = WAIT_RVALID;
            end
        end
        WAIT_ABORTED: begin
            if(instr_rvalid_i) begin
                if(instr_gnt_i)
                    NS = WAIT_RVALID;
                else
                    NS = WAIT_GNT;
            end
            else begin
                NS = WAIT_ABORTED;
            end
        end
        default:
            NS = IDLE;
    endcase
    end

    always_comb begin
    instr_req_o = 1'b0;
    pc_nxt = pc_nxt_plus_4;
    addr_valid = 1'b0;
    fifo_valid = 1'b0;
    fetch_is_hwlp = 1'b0;
    //fetch_failed_o = 1'b0;    
    case(CS)
        IDLE: begin
            pc_nxt = branch_i ? addr_i : 
                        hwlp_branch ? pc_nxt_r : 
                            (hwlp_masked & valid_stored) ? hwloop_target_i : pc_nxt_plus_4;
            if(req_i & (fifo_ready | branch_i | hwlp_branch | (hwlp_masked & valid_stored))) begin
                instr_req_o = 1'b1;
                addr_valid = 1'b1;
                fetch_is_hwlp = (hwlp_masked & valid_stored);
            end
        end
        WAIT_GNT: begin
            instr_req_o = 1'b1;
            pc_nxt = branch_i ? addr_i : 
                        hwlp_branch ? pc_nxt_r : 
                           (hwlp_masked & valid_stored) ? hwloop_target_i : pc_nxt_r;
            addr_valid = (branch_i | hwlp_branch | (hwlp_masked & valid_stored)) ? 1'b1 : 1'b0;
            fetch_is_hwlp = (hwlp_masked & valid_stored);
        end
        WAIT_RVALID: begin
            pc_nxt = branch_i ? addr_i : 
                        hwlp_branch ? pc_nxt_r : 
                           (hwlp_masked/* & valid_stored*/) ? hwloop_target_i : pc_nxt_plus_4;
            fifo_valid = instr_rvalid_i;
            if(req_i & (fifo_ready | branch_i | hwlp_branch | hwlp_masked)) begin
                //prepare for next reqrest
                if(instr_rvalid_i) begin
                    instr_req_o = 1'b1;
                    addr_valid = 1'b1;
                    fifo_valid = 1'b1;
                    fetch_is_hwlp = hwlp_masked;
                end
                else begin
                    //we didn't get an rvalid yet, so wait for it
                    instr_req_o = 1'b0;
                    addr_valid = (branch_i | hwlp_branch | hwlp_masked & valid_o);
                    fifo_valid = 1'b0;
                    fetch_is_hwlp = hwlp_masked & valid_o;
                end
            end
        end
        WAIT_ABORTED: begin
            pc_nxt = branch_i ? addr_i : pc_nxt_r;
            instr_req_o = instr_rvalid_i;
            addr_valid = (branch_i | hwlp_branch);
            //fifo_valid = instr_rvalid_i;
        end
        default:
            instr_req_o = 1'b0;
    endcase
    end

    assign instr_addr_o = {pc_nxt[31:2],2'b00};
    assign busy_o = (CS != IDLE) || instr_req_o;



    //============================
    //  HWloop FSM
    //============================
    enum logic [2:0] {HWLP_NONE, HWLP_IN, HWLP_FETCHING, HWLP_DONE, HWLP_UNALIGNED_COMPRESSED, HWLP_UNALIGNED} hwlp_CS, hwlp_NS;

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            hwlp_CS <= HWLP_NONE;
        else
            hwlp_CS <= hwlp_NS;
    end

    always_comb begin
        //hwlp_NS = hwlp_CS;
        case(hwlp_CS)
        HWLP_NONE: begin
            if(hwloop_jump_i) begin
                if(valid_o & pc_nxt_r[1] & unaligned_is_compressed) //why not jump to FETCHING?
                    hwlp_NS = HWLP_UNALIGNED_COMPRESSED;
                else if(pc_nxt_r[1] & ~valid_o) // If we are fetching an instruction which is misaligned (compressed or not)
                                                // before jumping we need to wait the valid_o from the FIFO
                    hwlp_NS = HWLP_UNALIGNED;
                else if(fetch_is_hwlp)
                    hwlp_NS = HWLP_FETCHING;
                else
                    hwlp_NS = HWLP_IN;
            end
            else begin
                hwlp_NS = hwlp_CS;
            end 
        end
        HWLP_UNALIGNED: begin
            if(valid_o)
                hwlp_NS = HWLP_FETCHING;
            else
                hwlp_NS = hwlp_CS;
        end
        HWLP_UNALIGNED_COMPRESSED: begin
            hwlp_NS = HWLP_FETCHING;
        end
        HWLP_IN: begin
            if(fetch_is_hwlp)
                hwlp_NS = HWLP_FETCHING;
            else
                hwlp_NS = hwlp_CS;
        end
        HWLP_FETCHING: begin //just waiting for rvalid really?
            if(instr_rvalid_i && (CS != WAIT_ABORTED)) begin
                if(valid_o && is_hwlp_o)
                    hwlp_NS = HWLP_NONE;
                else 
                    hwlp_NS = HWLP_DONE;
            end 
            else begin
                hwlp_NS = hwlp_CS;
            end
        end
        HWLP_DONE: begin
            if(valid_o && is_hwlp_o)
                hwlp_NS = HWLP_NONE;
            else
                hwlp_NS = hwlp_CS;
        end
        default: hwlp_NS = HWLP_NONE;
        endcase

        if(branch_i) hwlp_NS = HWLP_NONE;
    end

    always_comb begin
        fifo_hwlp = 1'b0;
        fifo_clear = 1'b0;
        hwlp_branch = 1'b0;
        hwlp_speculative = 1'b0;
        hwlp_masked = 1'b0;
    
        case(hwlp_CS)
        HWLP_NONE: begin
            if(hwloop_jump_i) begin
                hwlp_masked = ~pc_nxt_r[1]; //did not jump(hwlp_masked) as instr is unaligned.
                if(valid_o & pc_nxt_r[1] & unaligned_is_compressed) //if compressed, we can jump
                    hwlp_speculative = 1'b1;
                else if(pc_nxt_r[1] & ~valid_o)                                                 
                    hwlp_speculative = 1'b1;

                if(ready_i)
                    fifo_clear = 1'b1;
            end
            else begin
                hwlp_masked = 1'b0;
            end 
        end
        HWLP_UNALIGNED: begin
            hwlp_masked = 1'b1;
            if(valid_o && ready_i)
                fifo_clear = 1'b1;
        end
        HWLP_UNALIGNED_COMPRESSED: begin
            hwlp_branch = 1'b1;
            fifo_clear = 1'b1;
        end
        HWLP_IN: begin
            hwlp_masked = 1'b1;
            if(ready_i)
                fifo_clear = 1'b1;
        end
        HWLP_FETCHING: begin //just waiting for rvalid really?
            hwlp_masked = 1'b0;
            fifo_hwlp = 1'b1;
            if(instr_rvalid_i && (CS != WAIT_ABORTED))
                fifo_clear = 1'b0;
            else if(ready_i)
                fifo_clear = 1'b1;
        end
        HWLP_DONE: begin
            hwlp_masked = 1'b0;
        end
        default: hwlp_masked = 1'b0;
        endcase

        if(branch_i)
            fifo_clear = 1'b1;
    end

endmodule
