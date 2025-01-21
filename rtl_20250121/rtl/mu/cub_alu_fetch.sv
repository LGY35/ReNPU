module cub_alu_fetch #(
    parameter   IRAM_AWID = 8,
    parameter   IRAM_FILL_AWID = 15,
    parameter   LOOP_NUM = 4
)
(
    input                               clk,
    input                               rst_n,

    input   [IRAM_AWID-1:0]             alu_boot_addr_i,

    //to instr ram
    output  logic                       instr_req_o,
    input                               instr_gnt_i,
    output  logic  [IRAM_AWID-1:0]      instr_addr_o,
    input   [31:0]                      instr_rdata_i,
    input                               instr_rvalid_i,

    //from alu decoder
    input                               req_i,
    input [0:0]                         pc_mux_i,
    input                               pc_set_i, //jump to address set by pc_mux (set pc to a new value)
    //input   [31:0]                      jump_target_id_i,
    //input                               clear_instr_valid_i,

    //to alu decoder
    output  logic  [IRAM_FILL_AWID-1:0] pc_if_o,
    output  logic  [IRAM_FILL_AWID-1:0] pc_id_o,
    output  logic  [31:0]               fetch_instr_o,
    output  logic                       fetch_valid_o,
    input                               id_ready_i,
    input                               cub_alu_fetch_end_i,

    //from loop_reg
    input   [LOOP_NUM-1:0][31:0]        loop_start_i,
    input   [LOOP_NUM-1:0][31:0]        loop_end_i,
    input   [LOOP_NUM-1:0][31:0]        loop_cnt_i,
    //to loop_reg
    output  logic   [LOOP_NUM-1:0]      loop_cnt_dec_o,
    output  logic                       is_loop_id_o,

    input                               cub_nop_state_i
);

    parameter   ALU_PC_BOOT = 2'b00;

    logic                               branch_req;
    logic   [IRAM_FILL_AWID-1:0]        branch_addr;

    logic                               fetch_valid;
    logic                               fetch_ready;
    logic                               addr_valid;

    logic                               loop_jump;
    logic   [IRAM_FILL_AWID-1:0]        loop_target;
    logic                               loop_branch;
    logic                               fetch_is_loop;
    logic   [LOOP_NUM-1:0]              loop_cnt_dec, loop_cnt_dec_if;
    logic                               loop_fetched; //when fetched loop start instr
    logic                               is_loop_id_q;
    

    //============================
    //  fetch addr selection mux
    //============================
    always_comb begin
        branch_addr = 'b0; 
        case(pc_mux_i) //new PC mux
            ALU_PC_BOOT:        branch_addr = {{(IRAM_FILL_AWID-IRAM_AWID){1'b0}},alu_boot_addr_i};
            //PC_JUMP:          branch_addr = jump_target_id_i; //unconditional
            //PC_BRANCH:        branch_addr = jump_target_ex_i; //conditional
            //default:;
        endcase
    end 


    //============================
    //  Main FSM 
    //============================
    logic           if_valid, valid;
    enum logic {IDLE, WAIT} CS, NS;

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            CS <= IDLE;
        else
            CS <= NS;
    end

    always_comb begin
        branch_req = 1'b0;
        fetch_ready = 1'b0;
        valid = 1'b0;
        NS = CS;

        case(CS)
            IDLE: begin
                if(req_i) begin
                    branch_req = 1'b1;
                    NS = WAIT;
                end
                else begin
                    branch_req =1'b0;
                    NS = IDLE;
                end
            end
            WAIT: begin
                if(fetch_valid) begin //fetched instr valid
                    valid = 1'b1; //an instruction is ready for ID stage
                    fetch_ready = req_i && valid;
                end
            end
            default: NS = IDLE;
        endcase

        if(pc_set_i) begin
            branch_req = 1'b1;
            valid = 1'b0;
            NS = WAIT;
        end
    end

    assign  if_valid = valid & id_ready_i;


    //============================
    //  Fetch-Decode pipe 
    //============================
    always_ff @(posedge clk  or negedge rst_n) begin
        if(!rst_n) begin
            fetch_instr_o <= 'b0;
            fetch_valid_o <= 'b0;
            pc_id_o <= 'b0;

            is_loop_id_q <= 'b0;
            loop_cnt_dec_o <= 'b0;
        end        
        else if(cub_alu_fetch_end_i) begin
            fetch_valid_o <= 'b0;
        end
        else if(if_valid) begin
            fetch_instr_o <= instr_rdata_i;
            fetch_valid_o <= 1'b1; //fetch valid cause
            pc_id_o <= pc_if_o;
            is_loop_id_q <= loop_fetched;
            if(loop_fetched)
                loop_cnt_dec_o <= loop_cnt_dec_if;
        end
        else begin
            is_loop_id_q <= loop_fetched;
            if(loop_fetched)
                loop_cnt_dec_o <= loop_cnt_dec_if;
        end
        //else if(clear_instr_valid_i) begin
        //    fetch_valid_o <= 'b0;
        //end
    end

    assign is_loop_id_o = is_loop_id_q & fetch_valid_o;

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            loop_cnt_dec_if <= 'b0;
        else if(loop_jump)
            loop_cnt_dec_if <= loop_cnt_dec;
    end


    //==============================================================
    //  pc_nxt_r(already send req, waiting for rinsn, pc fetching) 
    //==============================================================
    logic   [IRAM_FILL_AWID-1:0]   pc_nxt,pc_nxt_r,pc_nxt_puls;   

    assign instr_addr_o = pc_nxt[IRAM_AWID-1:0];
    assign pc_if_o = pc_nxt_r;
    assign pc_nxt_puls = pc_nxt_r+1;

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            pc_nxt_r <= 'b0; //req next cycle
        end
        else if(addr_valid) begin 
            pc_nxt_r <= pc_nxt;
        end
    end

    //============================
    //  Fetch FSM
    //============================
    enum logic [2:0] {FETCH_IDLE, WAIT_GNT, WAIT_RVALID, WAIT_ABORTED} FETCH_CS, FETCH_NS;

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            FETCH_CS <= FETCH_IDLE;
        else
            FETCH_CS <= FETCH_NS;
    end

    always_comb begin
    instr_req_o = 1'b0;
    pc_nxt = pc_nxt_puls;
    addr_valid = 1'b0;
    fetch_valid = 1'b0;
    fetch_is_loop = 1'b0;
    FETCH_NS=FETCH_CS;

    case(FETCH_CS)
        FETCH_IDLE: begin
            pc_nxt = branch_req ? branch_addr : 
                        loop_branch ? loop_target : pc_nxt_puls;
            if(req_i & (fetch_ready | branch_req | loop_branch)) begin
                instr_req_o = 1'b1;
                addr_valid = 1'b1;
                fetch_is_loop = loop_branch;

                if(instr_gnt_i)
                    FETCH_NS = WAIT_RVALID;
                else
                    FETCH_NS = WAIT_GNT;
            end
            fetch_valid = cub_nop_state_i;
        end
        WAIT_GNT: begin //we sent a req but did not yet get a grant
            instr_req_o = 1'b1;
            pc_nxt = branch_req ? branch_addr : 
                        loop_branch ? loop_target : pc_nxt_r;
            addr_valid = (branch_req | loop_branch) ? 1'b1 : 1'b0;
            fetch_is_loop = loop_branch;

            if(instr_gnt_i)
                FETCH_NS = WAIT_RVALID;
        end
        WAIT_RVALID: begin
            pc_nxt = branch_req ? branch_addr : 
                        loop_branch ? loop_target : pc_nxt_puls;
            fetch_valid = instr_rvalid_i;
            if(req_i & (fetch_ready | branch_req | loop_branch)) begin //prepare for next reqrest
                if(instr_rvalid_i) begin
                    instr_req_o = 1'b1;
                    addr_valid = 1'b1;
                    fetch_is_loop = loop_branch;

                    if(instr_gnt_i)
                        FETCH_NS = WAIT_RVALID;
                    else
                        FETCH_NS = WAIT_GNT;
                end
                else begin //we are requested to abort our current request. we didn't get an rvalid yet, so wait for it
                    instr_req_o = 1'b0;
                    addr_valid = (branch_req | loop_branch);
                    fetch_is_loop = loop_branch;

                    if(branch_req | loop_branch)
                        FETCH_NS = WAIT_ABORTED;
                end
            end
            else begin //no next reqrest
                if(instr_rvalid_i)
                    FETCH_NS = FETCH_IDLE;
            end
        end
        WAIT_ABORTED: begin
            pc_nxt = branch_req ? branch_addr : pc_nxt_r;
            addr_valid = branch_req; //no need to send address, already done in WAIT_RVALID

            if(instr_rvalid_i) begin
                //fetch_valid = 1'b1;
                instr_req_o = 1'b1;

                if(instr_gnt_i)
                    FETCH_NS = WAIT_RVALID;
                else
                    FETCH_NS = WAIT_GNT;
            end
        end
        default: begin
            instr_req_o = 1'b0;
            FETCH_NS = FETCH_IDLE;
        end
    endcase
    end


      
    cub_alu_loop_controller
    #(
        .LOOP_NUM(LOOP_NUM),
        .IRAM_FILL_AWID(IRAM_FILL_AWID)
    )
    U_cub_alu_loop_controller(
        .current_pc_i(pc_nxt_r), 
        
        .loop_start_addr_i(loop_start_i),
        .loop_end_addr_i(loop_end_i),
        .loop_counter_i(loop_cnt_i),

        //pc is end addr, so jump to loop start(inner or outer)
        .loop_jump_o(loop_jump), //req next cycle 
        .loop_target_addr_o(loop_target), 

        .loop_cnt_dec_o(loop_cnt_dec),
        .loop_cnt_dec_id_i(loop_cnt_dec_o & {LOOP_NUM{is_loop_id_o}})
    );


    //============================
    // Fetch loop FSM
    //============================
    enum logic [2:0] {LOOP_NONE, LOOP_IN, LOOP_FETCHING, LOOP_DONE} LOOP_CS, LOOP_NS;

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            LOOP_CS <= LOOP_NONE;
        else
            LOOP_CS <= LOOP_NS;
    end

    always_comb begin
        loop_branch = 1'b0;
        loop_fetched = 1'b0;
        LOOP_NS = LOOP_CS;

        case(LOOP_CS)
        LOOP_NONE: begin
            if(loop_jump) begin
                loop_branch = 1'b1;
                
                if(fetch_is_loop)
                    LOOP_NS = LOOP_FETCHING;
                else
                    LOOP_NS = LOOP_IN;
            end
        end
        LOOP_IN: begin
            loop_branch = 1'b1;
            if(fetch_is_loop)
                LOOP_NS = LOOP_FETCHING;
            else
                LOOP_NS = LOOP_CS;
        end
        LOOP_FETCHING: begin
            loop_branch = 1'b0;
            loop_fetched = 1'b1;
            if(instr_rvalid_i && (FETCH_CS != WAIT_ABORTED)) begin
                LOOP_NS = LOOP_NONE;
            end
        end
        endcase
    end

endmodule
