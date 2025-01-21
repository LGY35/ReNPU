/*
Design Name     : Main CPU controller
Data            : 2024/2/1          
Description     : Main CPU controller(RI5CY)
*/

module riscv_controller#(
    parameter RF_ADDR_WIDTH = 5
)(
    input                       clk,
    input                       rst_n,
    input                       fetch_enable_i, //Start the decoding

    input                       npu_insn_i, //Start to fetch npu instr
    output logic                is_npu_insn_o,
    input                       is_npu_insn_i,
    input                       MQ_Cfifo_req_i,
    input                       VQ_Cfifo_req_i,
    input                       SQ_Cfifo_req_i,
    input                       ALU_Cfifo_req_i,
    input                       MQ_Cfifo_full_i,
    input                       VQ_Cfifo_full_i,
    input                       SQ_Cfifo_full_i,
    input                       ALU_Cfifo_full_i,
    output logic                Cfifo_stall_o,
    input                       VQ_insn_i,
    input                       MQ_insn_i,
    input                       SQ_insn_i,
    input                       Cub_alu_insn_i,
    input                       mu_VQ_ready_i,
    input                       mu_MQ_ready_i,
    input                       mu_SQ_ready_i,
    input                       mu_Cub_alu_ready_i,
    output logic                mu_stall_o,

    output logic                first_fetch_o, // Core is at the FIRST FETCH stage
    output logic                is_decoding_o, // Core is in decoding state
    output logic                ctrl_busy_o, // Core is busy processing instructions
    input                       is_fetch_failed_i,
    output logic                core_sleep_en_o, //to Noc

    //decoder related signals
    output logic                deassert_we_o, //deassert write enable for next instruction
    output logic                hwloop_mask_o, //prevent writes on the hwloop instructions in case interrupt are taken

    input                       illegal_instr_i,     //decoder encountered an invalid instruction
    //input                       instr_multicycle_i, //true when multiple cycles are decoded
    input                       ebrk_insn_i,   //decoder encountered an ebreak instruction
    input                       pipe_flush_i,  //decoder wants to do a pipe flush
    input                       ecall_insn_i,  //ecall encountered an mret instruction
    input                       fencei_insn_i, //decoder encountered an fence.i instruction
    input                       csr_status_i,  //decoder encountered an csr status instruction

    input                       mret_insn_i, //decoder encountered an mret instruction
    input                       uret_insn_i, //decoder encountered an uret instruction
    input                       dret_insn_i, //decoder encountered an dret instruction
    input                       mret_dec_i, //without deassert
    input                       uret_dec_i,
    input                       dret_dec_i,

    //from IF/ID pipeline
    input                       instr_valid_i,   //instruction coming from IF/ID pipeline is valid

    //from prefetcher
    output logic                instr_req_o,     //Start fetching instructions

    //to prefetcher
    output logic                pc_set_o,        //jump to address set by pc_mux
    output logic [2+1:0]        pc_mux_o,        //Selector in the Fetch stage to select the rigth PC (normal, jump ...)
    output logic [2:0]          exc_pc_mux_o,    //Selects target PC for exception
    output logic                trap_addr_mux_o, //Selects trap address base

    //LSU
    input                       data_req_ex_i,//data memory access is currently performed in EX stage
    input                       data_we_ex_i,
    input                       data_misaligned_i,
    input                       data_load_event_i,
    input                       data_err_i,
    //output logic                data_err_ack_o,

    //from ALU
    //input                       mult_multicycle_i, //multiplier is taken multiple cycles and uses op c as storage

    //jump/branch signals
    input                       branch_taken_ex_i, // branch taken signal from EX ALU
    input [1:0]                 jump_in_id_i,      // jump is being calculated in ALU
    input [1:0]                 jump_in_dec_i,     // jump is being calculated in ALU

    //Regfile target
    input                       regfile_we_id_i,        // currently decoded we enable
    input   [RF_ADDR_WIDTH-1:0] regfile_alu_waddr_id_i, // currently decoded target address

    //Forwa signals from regfile
    input                       regfile_we_ex_i,        // FW: write enable from  EX stage
    input   [RF_ADDR_WIDTH-1:0] regfile_waddr_ex_i,     // FW: write address from EX stage
    input                       regfile_we_wb_i,        // FW: write enable from  WB stage
    input                       regfile_alu_we_fw_i,    // FW: ALU/MUL write enable from  EX stage

    //forwarding signals
    output logic [1:0]          operand_a_fw_mux_sel_o, // regfile ra data selector form ID stage
    output logic [1:0]          operand_b_fw_mux_sel_o, // regfile rb data selector form ID stage
    output logic [1:0]          operand_c_fw_mux_sel_o, // regfile rc data selector form ID stage

    //forwarding detection signals
    input                       reg_d_ex_is_reg_a_i,
    input                       reg_d_ex_is_reg_b_i,
    input                       reg_d_ex_is_reg_c_i,
    input                       reg_d_wb_is_reg_a_i,
    input                       reg_d_wb_is_reg_b_i,
    input                       reg_d_wb_is_reg_c_i,
    input                       reg_d_alu_is_reg_a_i,
    input                       reg_d_alu_is_reg_b_i,
    input                       reg_d_alu_is_reg_c_i,


    //stall signals
    output logic                halt_if_o,
    output logic                halt_id_o,

    output logic                misaligned_stall_o,
    output logic                jr_stall_o,
    output logic                load_stall_o,

    input                       id_ready_i, //ID stage is ready
    input                       ex_valid_i, //EX stage is done
    input                       wb_ready_i, //WB stage is ready


    //Interrupt Controller Signals
    input                       irq_i,
    input                       irq_req_ctrl_i, //from Irq Controller
    input                       irq_sec_ctrl_i, //from Irq Controller
    input   [4:0]               irq_id_ctrl_i,  //from Irq Controller
    input                       m_Irq_Enable_i, //interrupt enable bit from CSR (M mode)
    input                       u_Irq_Enable_i, //interrupt enable bit from CSR (U mode)
    input   [1:0]               current_priv_lvl_i,

    output logic                irq_ack_o,
    output logic [4:0]          irq_id_o,

    output logic [5:0]          exc_cause_o,
    output logic                exc_ack_o,
    output logic                exc_kill_o,

    //csr
    output logic                csr_save_if_o,
    output logic                csr_save_id_o,
    output logic                csr_save_ex_o,
    output logic [5:0]          csr_cause_o,
    output logic                csr_irq_sec_o,
    output logic                csr_restore_mret_id_o,
    output logic                csr_restore_uret_id_o,
    output logic                csr_restore_dret_id_o,
    output logic                csr_save_cause_o,

    //Debug Signal
    output logic                debug_mode_o,
    output logic [2:0]          debug_cause_o,
    output logic                debug_csr_save_o,
    input                       debug_req_i,
    input                       debug_single_step_i,
    input                       debug_ebreakm_i,
    input                       debug_ebreaku_i,

    //Performance Counters
    output logic        perf_jump_o,          // we are executing a jump instruction   (j, jr, jal, jalr)
    output logic        perf_jr_stall_o,      // stall due to jump-register-hazard
    output logic        perf_ld_stall_o,      // stall due to load-use-hazard
    output logic        perf_pipeline_stall_o // stall due to elw extra cycles
);

`include "decode_param.v"


    logic   irq_enable_int;
    assign  irq_enable_int = ((u_Irq_Enable_i | irq_sec_ctrl_i) & current_priv_lvl_i == PRIV_LVL_U) | (m_Irq_Enable_i & current_priv_lvl_i == PRIV_LVL_M);
    logic   jump_done, jump_done_q, jump_in_dec, branch_in_id;
    logic   boot_done, boot_done_q;
    logic   data_err_q;

    logic   debug_mode_q, debug_mode_n;
    logic   ebrk_force_debug_mode;

    logic   illegal_instr_q, illegal_instr_n;

    logic   instr_valid_irq_flush_n, instr_valid_irq_flush_q;


    //============================
    //  FSM
    //============================

    enum logic [4:0] {RESET, BOOT_SET, WAIT_SLEEP, SLEEP, FIRST_FETCH, DECODE,
                      IRQ_TAKEN_ID, IRQ_TAKEN_IF, IRQ_FLUSH, IRQ_FLUSH_ELW, ELW_EXE,
                      FLUSH_EX, FLUSH_WB, XRET_JUMP,
                      DBG_TAKEN_ID, DBG_TAKEN_IF, DBG_FLUSH, DBG_WAIT_BRANCH} ctrl_fsm_cs, ctrl_fsm_ns; //(18)

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            ctrl_fsm_cs <= RESET;
        else
            ctrl_fsm_cs <= ctrl_fsm_ns;
    end

    always_comb begin
        //Default values
        instr_req_o = 1'b1;  
        is_decoding_o   = 1'b0;
        ctrl_busy_o     = 1'b1;
        first_fetch_o   = 1'b0;          
        boot_done       = 1'b0;
        jump_done       = jump_done_q;
        core_sleep_en_o = 1'b0;

        pc_mux_o        = PC_BOOT;
        pc_set_o        = 1'b0;

        exc_pc_mux_o    = EXC_PC_IRQ;
        trap_addr_mux_o = TRAP_MACHINE;
        exc_kill_o = 1'b0;
        exc_ack_o = 1'b0;
        exc_cause_o = 'b0;      

        halt_if_o = 1'b0;
        halt_id_o = 1'b0;

        csr_save_if_o    = 1'b0;
        csr_save_id_o    = 1'b0;
        csr_save_ex_o    = 1'b0;
        csr_save_cause_o = 1'b0;
        csr_cause_o      = 'b0;
        csr_irq_sec_o    = 1'b0;
        csr_restore_mret_id_o  = 1'b0;
        csr_restore_uret_id_o  = 1'b0;
        csr_restore_dret_id_o  = 1'b0;        

        irq_ack_o = 1'b0;
        irq_id_o  = irq_id_ctrl_i;


        jump_in_dec = (jump_in_dec_i == BRANCH_JALR) || (jump_in_dec_i == BRANCH_JAL);
        branch_in_id = (jump_in_id_i == BRANCH_COND);

        hwloop_mask_o = 1'b0;
        illegal_instr_n = illegal_instr_q;

        ctrl_fsm_ns = ctrl_fsm_cs;

        ebrk_force_debug_mode  = (debug_ebreakm_i && current_priv_lvl_i == PRIV_LVL_M) ||
                                 (debug_ebreaku_i && current_priv_lvl_i == PRIV_LVL_U);
        debug_csr_save_o       = 1'b0;
        debug_cause_o          = DBG_CAUSE_EBREAK;
        debug_mode_n           = debug_mode_q;  
        //this signal goes to 1 only registered interrupt requests are killed by exc_kill_o
        //so that the current instructions will have the deassert_we_o signal equal to 0 once the controller is back to DECODE
        instr_valid_irq_flush_n = 1'b0;
        //a trap towards the debug unit is generated when one of the
        //following conditions are true:
        //- ebreak instruction encountered
        //- single-stepping mode enabled
        //- illegal instruction exception and IIE bit is set
        //- IRQ and INTE bit is set and no exception is currently running
        //- Debuger requests halt        
        perf_pipeline_stall_o = 1'b0;
        //data_err_ack_o = 1'b0;

        is_npu_insn_o = 1'b0;

        case(ctrl_fsm_cs)
        RESET: begin //just reset, wait for fetch_enable
            instr_req_o   = 1'b0;
            is_decoding_o = 1'b0;
            if(fetch_enable_i == 1'b1) begin
                ctrl_fsm_ns = BOOT_SET;
            end
        end
        BOOT_SET: begin //copy boot address to instr fetch address
            instr_req_o   = 1'b1;
            is_decoding_o = 1'b0;
            pc_mux_o      = PC_BOOT;
            pc_set_o      = 1'b1;
            boot_done     = 1'b1;
            ctrl_fsm_ns   = FIRST_FETCH;
        end
        WAIT_SLEEP: begin // when wfi, pipe_flush and wait for interrupt, while(no_Interrupt_Pending) idle
            is_decoding_o = 1'b0;
            ctrl_busy_o   = 1'b0;
            instr_req_o   = 1'b0;
            halt_if_o     = 1'b1;
            halt_id_o     = 1'b1;
            ctrl_fsm_ns   = SLEEP;
        end
        SLEEP: begin 
            // we begin execution when an
            // interrupt has arrived
            is_decoding_o = 1'b0;
            ctrl_busy_o   = 1'b0;
            instr_req_o   = 1'b0;
            halt_if_o     = 1'b1;
            halt_id_o     = 1'b1;

            // normal execution flow
            // in debug mode or single step mode we leave immediately (wfi=nop)
            if(irq_i || (debug_req_i || debug_mode_q || debug_single_step_i)) begin
                ctrl_fsm_ns  = FIRST_FETCH;
            end
        end
        FIRST_FETCH: begin
            is_decoding_o = 1'b0;
            first_fetch_o = 1'b1;
            //Stall because of IF miss
            if(id_ready_i) begin
                ctrl_fsm_ns = DECODE;
            end

            //handle interrupts
            if(irq_req_ctrl_i && irq_enable_int) begin //This assumes that the pipeline is always flushed before going to sleep.
                ctrl_fsm_ns = IRQ_TAKEN_IF;
                halt_if_o   = 1'b1;
                halt_id_o   = 1'b1;
            end

            //handle debug req
            if(debug_req_i & (~debug_mode_q)) begin
                ctrl_fsm_ns = DBG_TAKEN_IF;
                halt_if_o   = 1'b1;
                halt_id_o   = 1'b1;
            end
        end

        DECODE: begin
            if(branch_taken_ex_i) begin //taken branch (there is a branch in the EX stage that is taken)
                is_decoding_o = 1'b0;
                pc_mux_o      = PC_BRANCH;
                pc_set_o      = 1'b1;   
            end
            
            //data_err and fetch_failed
            else if(data_err_i) begin //the current LW or SW have been blocked by the PMP
                is_decoding_o     = 1'b0;
                halt_if_o         = 1'b1;
                halt_id_o         = 1'b1;
                csr_save_ex_o     = 1'b1;
                csr_save_cause_o  = 1'b1;
                //data_err_ack_o    = 1'b1;
                //no jump in this stage as we have to wait one cycle to go to Machine Mode
                csr_cause_o       = data_we_ex_i ? EXC_CAUSE_STORE_FAULT : EXC_CAUSE_LOAD_FAULT;
                ctrl_fsm_ns       = FLUSH_WB;
            end
            else if(is_fetch_failed_i) begin //the current instruction has been blocked by the PMP
                is_decoding_o     = 1'b0;
                halt_id_o         = 1'b1;
                halt_if_o         = 1'b1;
                csr_save_if_o     = 1'b1;
                csr_save_cause_o  = 1'b1;
                //no jump in this stage as we have to wait one cycle to go to Machine Mode
                csr_cause_o       = EXC_CAUSE_INSTR_FAULT;
                ctrl_fsm_ns       = FLUSH_WB;
            end

            /*  decode and execute instructions only if the current conditional branch in the EX stage 
                is either not taken, or there is no conditional branch in the EX stage */          
            else if(instr_valid_i || instr_valid_irq_flush_q) begin //now analyze the current instruction in the ID stage
                is_decoding_o = 1'b1;
                case(1'b1)

                    /*  irq_req_ctrl_i: comes from a FF in the interrupt controller
                        irq_enable_int: check again irq_enable_int because xIE could have changed
                        Don't serve in debug mode */
                    irq_req_ctrl_i && irq_enable_int && (~debug_req_i) && (~debug_mode_q): begin
                        //Serving the external interrupt
                        ctrl_fsm_ns   = IRQ_FLUSH;
                        halt_if_o     = 1'b1;
                        halt_id_o     = 1'b1;
                        hwloop_mask_o = 1'b1;
                    end

                    debug_req_i && (~debug_mode_q): begin
                        //Serving the debug
                        ctrl_fsm_ns = DBG_FLUSH;
                        halt_if_o   = 1'b1;
                        halt_id_o   = 1'b1;
                    end

                    default: begin
                        exc_kill_o = irq_req_ctrl_i ? 1'b1 : 1'b0; //indicate irq not enable? so that kill that irq.
                        if(illegal_instr_i) begin
                            //exceptions
                            ctrl_fsm_ns      = FLUSH_EX;
                            halt_if_o        = 1'b1;
                            halt_id_o        = 1'b1;
                            illegal_instr_n  = 1'b1;
                            csr_save_id_o    = 1'b1;
                            csr_save_cause_o = 1'b1;
                            csr_cause_o      = EXC_CAUSE_ILLEGAL_INSTR;
                        end
                        else begin

                            //decoding block
                            case(1'b1)
                                npu_insn_i: begin
                                    is_npu_insn_o = 1'b1;
                                end

                                jump_in_dec: begin
                                    /*  handle unconditional jumps
                                        we can jump directly since we know the address already
                                        we don't need to worry about conditional branches here as they
                                        will be evaluated in the EX stage */
                                    pc_mux_o = PC_JUMP;
                                    //if there is a jr stall, wait for it to be done
                                    if((~jr_stall_o) && (~jump_done_q)) begin
                                        pc_set_o    = 1'b1;
                                        jump_done   = 1'b1;
                                    end
                                end

                                ebrk_insn_i: begin
                                    halt_if_o = 1'b1;
                                    halt_id_o = 1'b1;
                                    if(debug_mode_q) //we got back to the park loop in the debug rom
                                        ctrl_fsm_ns = DBG_FLUSH;
                                    else if(ebrk_force_debug_mode) //debug module commands us to enter debug mode anyway
                                        ctrl_fsm_ns = DBG_FLUSH;
                                    else begin //otherwise just a normal ebreak exception
                                        ctrl_fsm_ns = FLUSH_EX;
                                        csr_save_id_o    = 1'b1;
                                        csr_save_cause_o = 1'b1;
                                        csr_cause_o      = EXC_CAUSE_BREAKPOINT;
                                    end
                                end

                                pipe_flush_i: begin
                                    ctrl_fsm_ns = FLUSH_EX;
                                    halt_if_o   = 1'b1;
                                    halt_id_o   = 1'b1;
                                end

                                ecall_insn_i: begin
                                    ctrl_fsm_ns   = FLUSH_EX;
                                    halt_if_o = 1'b1;
                                    halt_id_o = 1'b1;
                                    csr_save_id_o    = 1'b1;
                                    csr_save_cause_o = 1'b1;
                                    csr_cause_o      = (current_priv_lvl_i == PRIV_LVL_U) ? EXC_CAUSE_ECALL_UMODE : EXC_CAUSE_ECALL_MMODE;
                                end
                                
                                fencei_insn_i: begin
                                    ctrl_fsm_ns = FLUSH_EX;
                                    halt_if_o   = 1'b1;
                                    halt_id_o   = 1'b1;
                                end

                                mret_insn_i | uret_insn_i | dret_insn_i: begin
                                    ctrl_fsm_ns = FLUSH_EX;
                                    halt_if_o   = 1'b1;
                                    halt_id_o   = 1'b1;
                                end

                                csr_status_i: begin
                                    ctrl_fsm_ns = id_ready_i ? FLUSH_EX : DECODE;
                                    halt_if_o = 1'b1;
                                end

                                data_load_event_i: begin
                                    ctrl_fsm_ns = id_ready_i ? ELW_EXE : DECODE;
                                    halt_if_o = 1'b1;
                                end
                                //default:;
                            endcase 
                        end //end decoding block
                        
                        if(debug_single_step_i & ~debug_mode_q) begin //??
                            // prevent any more instructions from executing
                            halt_if_o = 1'b1;

                            // we don't handle dret here because its should be illegal
                            // anyway in this context

                            // illegal, ecall, ebrk and xrettransition to later to a DBG
                            // state since we need the return address which is
                            // determined later

                            // TODO: handle ebrk_force_debug_mode plus single stepping over ebreak
                            if(id_ready_i) begin // make sure the current instruction has been executed
                                unique case(1'b1)
                                    illegal_instr_i | ecall_insn_i:
                                        ctrl_fsm_ns = FLUSH_EX; // TODO: flush ex
                                    (~ebrk_force_debug_mode & ebrk_insn_i):
                                        ctrl_fsm_ns = FLUSH_EX;
                                    mret_insn_i | uret_insn_i:
                                        ctrl_fsm_ns = FLUSH_EX;
                                    branch_in_id:
                                        ctrl_fsm_ns = DBG_WAIT_BRANCH;
                                    default: // regular instruction
                                        ctrl_fsm_ns = DBG_FLUSH;
                                endcase // unique case (1'b1)
                            end
                        end
                    end //default end
                endcase
            end //valid block

            else begin
                is_decoding_o = 1'b0;
                perf_pipeline_stall_o = data_load_event_i; //??
            end
        end

        FLUSH_EX: begin //flush the pipeline, insert NOP into EX stage??
            is_decoding_o = 1'b0;

            halt_if_o = 1'b1;
            halt_id_o = 1'b1;

            if(data_err_i) begin //data error
                // the current LW or SW have been blocked by the PMP
                csr_save_ex_o     = 1'b1;
                csr_save_cause_o  = 1'b1;
                //data_err_ack_o    = 1'b1;
                //no jump in this stage as we have to wait one cycle to go to Machine Mode
                csr_cause_o       = data_we_ex_i ? EXC_CAUSE_STORE_FAULT : EXC_CAUSE_LOAD_FAULT;
                ctrl_fsm_ns       = FLUSH_WB;
                //putting illegal to 0 as if it was 1, the core is going to jump to the exception of the EX stage,
                //so the illegal was never executed
                illegal_instr_n    = 1'b0;
            end  //data erro
            else if(ex_valid_i)
                //check done to prevent data harzard in the CSR registers
                ctrl_fsm_ns = FLUSH_WB;
        end

        IRQ_FLUSH: begin
            is_decoding_o = 1'b0;

            halt_if_o   = 1'b1;
            halt_id_o   = 1'b1;

            if(data_err_i) begin //data error
                //the current LW or SW have been blocked by the PMP
                csr_save_ex_o     = 1'b1;
                csr_save_cause_o  = 1'b1;
                //data_err_ack_o    = 1'b1;
                //no jump in this stage as we have to wait one cycle to go to Machine Mode
                csr_cause_o       = data_we_ex_i ? EXC_CAUSE_STORE_FAULT : EXC_CAUSE_LOAD_FAULT;
                ctrl_fsm_ns       = FLUSH_WB;
            end
            else begin
                if(irq_i & irq_enable_int) begin
                    ctrl_fsm_ns = IRQ_TAKEN_ID;
                end 
                else begin
                    // we can go back to decode in case the IRQ is not taken (no ELW REPLAY)
                    exc_kill_o              = 1'b1;
                    instr_valid_irq_flush_n = 1'b1;
                    ctrl_fsm_ns             = DECODE;
                end
            end
        end
        IRQ_FLUSH_ELW: begin
            is_decoding_o = 1'b0;

            halt_if_o   = 1'b1;
            halt_id_o   = 1'b1;

            perf_pipeline_stall_o = data_load_event_i;

            if(irq_i & irq_enable_int) begin
                ctrl_fsm_ns = IRQ_TAKEN_ID;
            end 
            else begin
                // we can go back to decode in case the IRQ is not taken (no ELW REPLAY)
                exc_kill_o  = 1'b1;
                ctrl_fsm_ns = DECODE;
            end
        end
        ELW_EXE: begin
            is_decoding_o = 1'b0;

            halt_if_o   = 1'b1;
            halt_id_o   = 1'b1;

            //if we are here, a elw is executing now in the EX stage
            //or if an interrupt has been received
            //the ID stage contains the PC_ID of the elw, therefore halt_id is set to invalid the instruction
            //If an interrupt occurs, we replay the ELW
            //No needs to check irq_int_req_i since in the EX stage there is only the elw, no CSR pendings
            if(id_ready_i)
                ctrl_fsm_ns = (debug_req_i & ~debug_mode_q) ? DBG_FLUSH : IRQ_FLUSH_ELW;
                // if from the ELW EXE we go to IRQ_FLUSH_ELW, it is assumed that if there was an IRQ req together with the grant and IE was valid, then
                // there must be no hazard due to xIE
            else
                ctrl_fsm_ns = ELW_EXE;

            perf_pipeline_stall_o = data_load_event_i;
        end
        IRQ_TAKEN_ID: begin
            is_decoding_o = 1'b0;

            pc_set_o          = 1'b1;
            pc_mux_o          = PC_EXCEPTION;
            exc_pc_mux_o      = EXC_PC_IRQ;
            exc_cause_o       = {1'b0,irq_id_ctrl_i};

            csr_irq_sec_o     = irq_sec_ctrl_i;
            csr_save_cause_o  = 1'b1;
            csr_cause_o       = {1'b1,irq_id_ctrl_i};

            csr_save_id_o     = 1'b1;

            if(irq_sec_ctrl_i)
                trap_addr_mux_o  = TRAP_MACHINE;
            else
                trap_addr_mux_o  = current_priv_lvl_i == PRIV_LVL_U ? TRAP_USER : TRAP_MACHINE;

            irq_ack_o         = 1'b1;
            exc_ack_o         = 1'b1;
            ctrl_fsm_ns       = DECODE;
        end
        IRQ_TAKEN_IF: begin
            is_decoding_o = 1'b0;

            pc_set_o          = 1'b1;
            pc_mux_o          = PC_EXCEPTION;
            exc_pc_mux_o      = EXC_PC_IRQ;
            exc_cause_o       = {1'b0,irq_id_ctrl_i};

            csr_irq_sec_o     = irq_sec_ctrl_i;
            csr_save_cause_o  = 1'b1;
            csr_cause_o       = {1'b1,irq_id_ctrl_i};

            csr_save_if_o     = 1'b1;

            if(irq_sec_ctrl_i)
                trap_addr_mux_o  = TRAP_MACHINE;
            else
                trap_addr_mux_o  = current_priv_lvl_i == PRIV_LVL_U ? TRAP_USER : TRAP_MACHINE;

            irq_ack_o         = 1'b1;
            exc_ack_o         = 1'b1;
            ctrl_fsm_ns       = DECODE;
        end
        FLUSH_WB: begin //flush the pipeline, insert NOP into EX and WB stage??
            is_decoding_o = 1'b0;

            halt_if_o = 1'b1;
            halt_id_o = 1'b1;

            ctrl_fsm_ns = DECODE;

            if(data_err_q) begin
                //data_error
                pc_mux_o              = PC_EXCEPTION;
                pc_set_o              = 1'b1;
                trap_addr_mux_o       = TRAP_MACHINE;
                //little hack during testing
                exc_pc_mux_o          = EXC_PC_EXCEPTION;
                exc_cause_o           = data_we_ex_i ? EXC_CAUSE_LOAD_FAULT : EXC_CAUSE_STORE_FAULT;
            end
            else if(is_fetch_failed_i) begin
                //data_error
                pc_mux_o              = PC_EXCEPTION;
                pc_set_o              = 1'b1;
                trap_addr_mux_o       = TRAP_MACHINE;
                exc_pc_mux_o          = EXC_PC_EXCEPTION;
                exc_cause_o           = EXC_CAUSE_INSTR_FAULT;
            end
            else begin
                if(illegal_instr_q) begin
                    //exceptions
                    pc_mux_o              = PC_EXCEPTION;
                    pc_set_o              = 1'b1;
                    trap_addr_mux_o       = TRAP_MACHINE;
                    exc_pc_mux_o          = EXC_PC_EXCEPTION;
                    illegal_instr_n       = 1'b0;
                    if(debug_single_step_i && ~debug_mode_q)
                        ctrl_fsm_ns = DBG_TAKEN_IF;
                end 
                else begin
                  unique case(1'b1)
                    ebrk_insn_i: begin
                        //ebreak
                        pc_mux_o              = PC_EXCEPTION;
                        pc_set_o              = 1'b1;
                        trap_addr_mux_o       = TRAP_MACHINE;
                        exc_pc_mux_o          = EXC_PC_EXCEPTION;

                        if (debug_single_step_i && ~debug_mode_q)
                            ctrl_fsm_ns = DBG_TAKEN_IF;
                    end
                    ecall_insn_i: begin
                        //ecall
                        pc_mux_o              = PC_EXCEPTION;
                        pc_set_o              = 1'b1;
                        trap_addr_mux_o       = TRAP_MACHINE;
                        exc_pc_mux_o          = EXC_PC_EXCEPTION;
                        // TODO: why is this here, signal only needed for async exceptions
                        exc_cause_o           = EXC_CAUSE_ECALL_MMODE;

                        if (debug_single_step_i && ~debug_mode_q)
                            ctrl_fsm_ns = DBG_TAKEN_IF;
                    end

                    mret_insn_i: begin
                       csr_restore_mret_id_o =  1'b1;
                       ctrl_fsm_ns           = XRET_JUMP;
                    end
                    uret_insn_i: begin
                       csr_restore_uret_id_o =  1'b1;
                       ctrl_fsm_ns           = XRET_JUMP;
                    end
                    dret_insn_i: begin
                        csr_restore_dret_id_o = 1'b1;
                        ctrl_fsm_ns           = XRET_JUMP;
                    end

                    csr_status_i: begin

                    end
                    pipe_flush_i: begin
                        ctrl_fsm_ns = WAIT_SLEEP;
                        core_sleep_en_o = 1'b1;
                    end
                    fencei_insn_i: begin
                        // we just jump to instruction after the fence.i since that
                        // forces the instruction cache to refetch
                        pc_mux_o = PC_FENCEI;
                        pc_set_o = 1'b1;
                    end
                    //default:;
                  endcase
                end
            end
        end
        XRET_JUMP: begin //??
            is_decoding_o = 1'b0;
            ctrl_fsm_ns   = DECODE;
            unique case(1'b1)
              mret_dec_i: begin
                  //mret
                  pc_mux_o              = PC_MRET;
                  pc_set_o              = 1'b1;
              end
              uret_dec_i: begin
                  //uret
                  pc_mux_o              = PC_URET;
                  pc_set_o              = 1'b1;
              end
              dret_dec_i: begin
                  //dret
                  //TODO: is illegal when not in debug mode
                  pc_mux_o              = PC_DRET;
                  pc_set_o              = 1'b1;
                  debug_mode_n          = 1'b0;
              end
              //default:;
            endcase

            if(debug_single_step_i && ~debug_mode_q) begin
                ctrl_fsm_ns = DBG_TAKEN_IF;
            end
        end

        // a branch was in ID when a trying to go to debug rom wait until we can
        // determine branch target address (for saving into dpc) before proceeding
        DBG_WAIT_BRANCH: begin //??
            is_decoding_o = 1'b0;
            halt_if_o = 1'b1;

            if(branch_taken_ex_i) begin // there is a branch in the EX stage that is taken
              pc_mux_o = PC_BRANCH;
              pc_set_o = 1'b1;
            end

            ctrl_fsm_ns = DBG_FLUSH;
        end

        DBG_TAKEN_ID: begin //??
            is_decoding_o     = 1'b0;
            pc_set_o          = 1'b1;
            pc_mux_o          = PC_EXCEPTION;
            exc_pc_mux_o      = EXC_PC_DBD;
            if((debug_req_i && (~debug_mode_q)) ||
               (ebrk_insn_i && ebrk_force_debug_mode && (~debug_mode_q))) begin
                csr_save_cause_o = 1'b1;
                csr_save_id_o    = 1'b1;
                debug_csr_save_o = 1'b1;
                if(debug_req_i)
                    debug_cause_o = DBG_CAUSE_HALTREQ;
                if(ebrk_insn_i)
                    debug_cause_o = DBG_CAUSE_EBREAK;
            end
            ctrl_fsm_ns  = DECODE;
            debug_mode_n = 1'b1;
        end
        DBG_TAKEN_IF: begin //??
            is_decoding_o     = 1'b0;
            pc_set_o          = 1'b1;
            pc_mux_o          = PC_EXCEPTION;
            exc_pc_mux_o      = EXC_PC_DBD;
            csr_save_if_o     = 1'b1;
            csr_save_cause_o  = 1'b1;
            debug_csr_save_o  = 1'b1;
            if(debug_single_step_i)
                debug_cause_o = DBG_CAUSE_STEP;
            if(debug_req_i)
                debug_cause_o = DBG_CAUSE_HALTREQ;
            if(ebrk_insn_i)
                debug_cause_o = DBG_CAUSE_EBREAK;
            ctrl_fsm_ns     = DECODE;
            debug_mode_n    = 1'b1;
        end
        DBG_FLUSH: begin //??
            is_decoding_o = 1'b0;
            halt_if_o   = 1'b1;
            halt_id_o   = 1'b1;
            perf_pipeline_stall_o = data_load_event_i;

            if (data_err_i) begin //data error
                // the current LW or SW have been blocked by the PMP
                csr_save_ex_o     = 1'b1;
                csr_save_cause_o  = 1'b1;
                //data_err_ack_o    = 1'b1;
                //no jump in this stage as we have to wait one cycle to go to Machine Mode
                csr_cause_o       = data_we_ex_i ? EXC_CAUSE_STORE_FAULT : EXC_CAUSE_LOAD_FAULT;
                ctrl_fsm_ns       = FLUSH_WB;
            end 
            else begin
                if(debug_mode_q) begin //ebreak in debug rom
                    ctrl_fsm_ns = DBG_TAKEN_ID;
                end 
                else if(data_load_event_i) begin
                    ctrl_fsm_ns = DBG_TAKEN_ID;
                end 
                else if (debug_single_step_i) begin
                    // save the next instruction when single stepping regular insn
                    ctrl_fsm_ns  = DBG_TAKEN_IF;
                end 
                else begin
                    ctrl_fsm_ns  = DBG_TAKEN_ID;
                end
            end
        end

        default: begin
            is_decoding_o = 1'b0;
            instr_req_o = 1'b0;
            ctrl_fsm_ns = RESET;
        end
        endcase
    end
   




    //==========Stall Ctrl==========
    always_comb begin
        load_stall_o  = 1'b0;
        jr_stall_o    = 1'b0;
        deassert_we_o = 1'b0;
        Cfifo_stall_o = 1'b0;
        mu_stall_o    = 1'b0;

        //deassert WE when the core is not decoding instructions
        if(!is_decoding_o) begin
            deassert_we_o = 1'b1;
        end

        //deassert WE in case of illegal instruction
        if(illegal_instr_i) begin
            deassert_we_o = 1'b1;
        end

        //Stall because of load operation
        if(
            ( (data_req_ex_i == 1'b1) && (regfile_we_ex_i == 1'b1) ||
              (wb_ready_i == 1'b0) && (regfile_we_wb_i == 1'b1) ) &&
           ( (reg_d_ex_is_reg_a_i == 1'b1) || (reg_d_ex_is_reg_b_i == 1'b1) || (reg_d_ex_is_reg_c_i == 1'b1) ||
             (is_decoding_o && regfile_we_id_i && (regfile_waddr_ex_i == regfile_alu_waddr_id_i)) )
        ) begin
            deassert_we_o = 1'b1;
            load_stall_o  = 1'b1;            
        end

        //Stall because of jr path
        /*  always stall if a result is to be forwarded to the PC
            we don't care about in which state the ctrl_fsm is as we deassert_we anyway when we are not in DECODE */
        if((jump_in_dec_i == BRANCH_JALR) &&
           (((regfile_we_wb_i == 1'b1) && (reg_d_wb_is_reg_a_i == 1'b1)) ||
            ((regfile_we_ex_i == 1'b1) && (reg_d_ex_is_reg_a_i == 1'b1)) ||
            ((regfile_alu_we_fw_i == 1'b1) && (reg_d_alu_is_reg_a_i == 1'b1)))) //why is rega just??
        begin 
            jr_stall_o    = 1'b1;
            deassert_we_o = 1'b1;
        end

        //Stall because Cfifo is full
        if((MQ_Cfifo_req_i && MQ_Cfifo_full_i) || (VQ_Cfifo_req_i && VQ_Cfifo_full_i) || (SQ_Cfifo_req_i && SQ_Cfifo_full_i) || (ALU_Cfifo_req_i && ALU_Cfifo_full_i)) begin
            Cfifo_stall_o = 1'b1;
            deassert_we_o = 1'b1;
        end

        //Stall because queue is full
        if(is_npu_insn_i && 
            (VQ_insn_i && ~mu_VQ_ready_i) || 
            (MQ_insn_i && ~mu_MQ_ready_i) ||
            (SQ_insn_i && ~mu_SQ_ready_i) ||
            (Cub_alu_insn_i && ~mu_Cub_alu_ready_i)) begin
            mu_stall_o = 1'b1;
            deassert_we_o = 1'b1;
        end        
    end

    //stall because of misaligned data access
    assign misaligned_stall_o = data_misaligned_i;


    //==========Forwarding Ctrl==========

    always_comb begin
        //default assignements
        operand_a_fw_mux_sel_o = SEL_REGFILE;
        operand_b_fw_mux_sel_o = SEL_REGFILE;
        operand_c_fw_mux_sel_o = SEL_REGFILE;

        //Forwarding WB -> ID
        if(regfile_we_wb_i == 1'b1) begin
            if(reg_d_wb_is_reg_a_i == 1'b1)
                operand_a_fw_mux_sel_o = SEL_FW_WB;
            if(reg_d_wb_is_reg_b_i == 1'b1)
                operand_b_fw_mux_sel_o = SEL_FW_WB;
            if(reg_d_wb_is_reg_c_i == 1'b1)
                operand_c_fw_mux_sel_o = SEL_FW_WB;
        end

        //Forwarding EX -> ID
        if(regfile_alu_we_fw_i == 1'b1) begin
            if(reg_d_alu_is_reg_a_i == 1'b1)
                operand_a_fw_mux_sel_o = SEL_FW_EX;
            if(reg_d_alu_is_reg_b_i == 1'b1)
                operand_b_fw_mux_sel_o = SEL_FW_EX;
            if(reg_d_alu_is_reg_c_i == 1'b1)
                operand_c_fw_mux_sel_o = SEL_FW_EX;
        end

        //for misaligned memory accesses
        if(data_misaligned_i) begin
          operand_a_fw_mux_sel_o  = SEL_FW_EX;
          operand_b_fw_mux_sel_o  = SEL_REGFILE;
        end 
        //else if(mult_multicycle_i) begin
        //  operand_c_fw_mux_sel_o  = SEL_FW_EX;
        //end
    end


    //==========update registers==========
    always_ff @(posedge clk or negedge rst_n) begin : UPDATE_REGS
        if(!rst_n) begin
            illegal_instr_q <= 1'b0;
            instr_valid_irq_flush_q <= 1'b0;
            debug_mode_q <= 1'b0;
            jump_done_q <= 1'b0;
            boot_done_q <= 1'b0;
            data_err_q <= 1'b0;
        end
        else begin
            illegal_instr_q <= illegal_instr_n;
            instr_valid_irq_flush_q <= instr_valid_irq_flush_n;
            debug_mode_q <= debug_mode_n;
            jump_done_q <= jump_done & (~id_ready_i);
            boot_done_q <= boot_done | (~boot_done & boot_done_q);
            data_err_q <= data_err_i;
        end
    end

    // Performance Counters
    assign perf_jump_o      = (jump_in_id_i == BRANCH_JAL || jump_in_id_i == BRANCH_JALR);
    assign perf_jr_stall_o  = jr_stall_o;
    assign perf_ld_stall_o  = load_stall_o;
    //Debug mode
    assign debug_mode_o = debug_mode_q;
























endmodule
