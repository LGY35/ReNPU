/*
Design Name     : Instruction Fetch Stage
Data            : 2023/12/22           
Description     : Selection of the next PC,and buffering (sampling) of the read instruction.
*/

module riscv_if_stage
#(
    parameter HWLP_NUM = 4,
    parameter DW_HaltAddress = 32'h1A110800
)
(
    input                               clk,
    input                               rst_n,
    //pc mux and ctrl signal
    input   [2+1:0]                     pc_mux_i,
    input   [30:0]                      boot_addr_i,
    //input   [31:0]                      npu_addr_i,
    input   [31:0]                      jump_target_id_i,
    input   [31:0]                      jump_target_ex_i,
    input   [31:0]                      mepc_i,
    input   [31:0]                      uepc_i,
    input   [31:0]                      depc_i,
    input                               pc_set_i, //jump to address set by pc_mux (set pc to a new value)
    //trap mux
    input                               trap_addr_mux_i, //Selects trap address base
    input   [23:0]                      m_trap_base_addr_i,
    input   [23:0]                      u_trap_base_addr_i,
    input   [2:0]                       exc_pc_mux_i, //Selects target PC for exception
    input   [4:0]                       exc_vec_pc_mux_i,
    
    //instr req ctrl from ID
    input                               req_i,

    //instr cache interface
    output                              instr_req_o,
    input                               instr_gnt_i,
    output  [31:0]                      instr_addr_o,
    input                               instr_rvalid_i,
    input   [31:0]                      instr_rdata_i,

    //out to ID stage
    output  reg [31:0]                  if_instr_id_o,
    output  reg                         if_valid_id_o,
    output  [31:0]                      pc_if_o,
    output  reg [31:0]                  pc_id_o, //pc_id_o <= pc_if_o 
    output                              if_busy_o, // is the IF stage busy fetching instr?
    output                              perf_imiss_o, // Instruction Fetch Miss 
    input                               id_ready_i, //pipe stall
    input                               halt_if_i,  //pipe stall

    output  reg                         is_compressed_id_o,
    output  reg                         illegal_c_instr_id_o,
    output                              is_hwlp_id_o,
    output  reg [HWLP_NUM-1:0]          hwlp_cnt_dec_id_o,
    input                               clear_instr_valid_i, //clear instr valid bit in IF/ID pipe
    input                               is_npu_insn_i,
    
    //from hwloop regs(ID)
    input   [HWLP_NUM-1:0][31:0]        hwlp_start_i, //hardware loop start addresses
    input   [HWLP_NUM-1:0][31:0]        hwlp_end_i,   //hardware loop end addresses
    input   [HWLP_NUM-1:0][31:0]        hwlp_cnt_i    //hardware loop counters
);

`include "decode_param.v"


    logic                               branch_req;
    logic   [31:0]                      fetch_addr_n;
    logic                               if_valid;
    logic                               if_ready;
    logic                               valid;

    logic                               fetch_valid;
    logic                               fetch_ready;
    logic   [31:0]                      fetch_rdata;
    logic   [31:0]                      fetch_addr;
    logic                               fetch_is_hwlp;

    logic                               hwlp_jump;
    logic   [31:0]                      hwlp_target;
    logic                               hwlp_branch;
    logic   [HWLP_NUM-1:0]              hwlp_cnt_dec;
    logic   [HWLP_NUM-1:0]              hwlp_cnt_dec_if;

    logic   [31:0]                      exc_pc;
    logic   [23:0]                      trap_base_addr;

    logic                               is_hwlp_id_q;
    logic                               prefetch_busy;

    //==============================
    //  exception PC selection mux
    //==============================
    always_comb begin
        case(trap_addr_mux_i)
            TRAP_MACHINE: trap_base_addr = m_trap_base_addr_i;
            TRAP_USER:    trap_base_addr = u_trap_base_addr_i;
        endcase
    end

    always_comb begin
        exc_pc = 'b0;
        case(exc_pc_mux_i)
            EXC_PC_EXCEPTION: exc_pc = {trap_base_addr, 8'b0}; //1.10 all the exceptions go to base address
            EXC_PC_IRQ:       exc_pc = {trap_base_addr, 1'b0, exc_vec_pc_mux_i[4:0], 2'b0};
            EXC_PC_DBD:       exc_pc = {DW_HaltAddress};
        endcase
    end


    //============================
    //  fetch addr selection mux
    //============================
    always_comb begin
        fetch_addr_n = 'b0; //new PC mux
        case(pc_mux_i)
            PC_BOOT:        fetch_addr_n = {boot_addr_i, 1'b0};
            PC_JUMP:        fetch_addr_n = jump_target_id_i; //unconditional
            PC_BRANCH:      fetch_addr_n = jump_target_ex_i; //conditional
            PC_EXCEPTION:   fetch_addr_n = exc_pc;
            PC_MRET:        fetch_addr_n = mepc_i;
            PC_URET:        fetch_addr_n = uepc_i;
            PC_DRET:        fetch_addr_n = depc_i;
            PC_FENCEI:      fetch_addr_n = pc_id_o + 4; // jump to next instr forces prefetch buffer reload
            //PC_NPU:         fetch_addr_n = npu_addr_i;
            //default:;
        endcase
    end 
    

    //============================
    //  Prefetch Buffer 
    //============================
    //fetch_addr_n push, fetch_addr and fetch_rdata pop
    riscv_prefetch_buffer U_prefetch_buffer
    (
    .clk(clk),
    .rst_n(rst_n),
    
    .req_i          (req_i), //from id_stage, start to fetch instr
    
    .branch_i       (branch_req),                //switch to new PC
    .addr_i         ({fetch_addr_n[31:1],1'b0}), //new PC mux
    
    .hwloop_jump_i  (hwlp_jump),   //switch to hwlp PC
    .hwloop_target_i(hwlp_target), //hwlp PC
    .hwloop_branch_o(hwlp_branch),
    
    .instr_req_o    (instr_req_o),
    .instr_gnt_i    (instr_gnt_i),
    .instr_addr_o   (instr_addr_o),
    .instr_rvalid_i (instr_rvalid_i),
    .instr_rdata_i  (instr_rdata_i),
    
    .ready_i        (fetch_ready),
    .addr_o         (fetch_addr), //fifo pop pc
    .rdata_o        (fetch_rdata),//fifo pop instr
    .valid_o        (fetch_valid),
    .is_hwlp_o      (fetch_is_hwlp), //is set when the currently served data is from a hwloop
    
    .busy_o         (prefetch_busy),
    .is_npu_insn_i  (is_npu_insn_i)
    );

    assign  pc_if_o = fetch_addr;
    assign  if_busy_o = prefetch_busy;
    assign  perf_imiss_o = (~fetch_valid) | branch_req;
        

    logic   [31:0]      instr_decompressed;
    logic               is_compressed;
    logic               illegal_c_instr;

    riscv_compressed_decoder U_compressed_decoder
    (
        .instr_i(fetch_rdata),
        .instr_o(instr_decompressed),
        .is_compressed_o(is_compressed),
        .illegal_instr_o(illegal_c_instr),
        .is_npu_insn_i(is_npu_insn_i)
    );


    //============================
    //  Hwlp Controller 
    //============================
    riscv_hwloop_controller 
    #(
        .HWLP_NUM(HWLP_NUM)
    )
    U_hwloop_controller(
        .current_pc_i(fetch_addr), 
        
        .hwlp_start_addr_i(hwlp_start_i),
        .hwlp_end_addr_i(hwlp_end_i),
        .hwlp_counter_i(hwlp_cnt_i),

        .hwlp_jump_o(hwlp_jump), //pc is end addr, so jump to loop start(inner or outer) 
        .hwlp_target_addr_o(hwlp_target), 
        
        .hwlp_cnt_dec_o(hwlp_cnt_dec),
        .hwlp_cnt_dec_id_i(hwlp_cnt_dec_id_o & {HWLP_NUM{is_hwlp_id_o}})
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            hwlp_cnt_dec_if <= 'b0;
        else if(hwlp_jump)
            hwlp_cnt_dec_if <= hwlp_cnt_dec;
    end


    //============================
    //  FSM 
    //============================
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
                    NS = CS;
                end
            end
            WAIT: begin
                if(fetch_valid) begin //fifo pop instr valid
                    valid = 1'b1; //an instruction is ready for ID stage
                    fetch_ready = req_i && if_valid;
                end
            end
            default: NS = IDLE;
        endcase

        if(pc_set_i) begin
            branch_req = 1'b1;
            valid = 1'b0;
            NS = WAIT;
        end
        else if(hwlp_branch) begin
            valid = 1'b0;
        end 
    end

    assign if_ready = valid & id_ready_i;
    assign if_valid = if_ready & (~halt_if_i);

    //============================
    //  IF-ID pipeline reg 
    //============================
    always_ff @(posedge clk  or negedge rst_n) begin
        if(!rst_n) begin
            if_instr_id_o <= 'b0;
            if_valid_id_o <= 'b0;
            is_compressed_id_o <= 'b0;
            illegal_c_instr_id_o <= 'b0;            
            pc_id_o <= 'b0;  
            is_hwlp_id_q <= 'b0;
            hwlp_cnt_dec_id_o <= 'b0;
        end
        else if(if_valid) begin
            if_instr_id_o <= instr_decompressed;
            if_valid_id_o <= 1'b1; //fetch valid cause
            is_compressed_id_o <= is_compressed;
            illegal_c_instr_id_o <= illegal_c_instr;            
            pc_id_o <= pc_if_o;  
            is_hwlp_id_q <= fetch_is_hwlp;
            if(fetch_is_hwlp)
                hwlp_cnt_dec_id_o <= hwlp_cnt_dec_if;
        end
        else if(clear_instr_valid_i) begin
            if_valid_id_o <= 'b0;
        end        
    end

    assign is_hwlp_id_o = is_hwlp_id_q & if_valid_id_o;

endmodule

