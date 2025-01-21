module riscv_core
#(
    parameter PULP_SECURE         =  0,
    parameter PULP_CLUSTER        =  1,
    parameter DW_HaltAddress      = 32'h1A110800,
    parameter N_EXT_PERF_COUNTERS =  0
)
(
    input                               clk_i,
    input                               rst_n,

    input                               clock_en_i, //enable clock, otherwise it is gated
    input                               test_en_i, //enable all clock gates for testing

    //Core ID, Cluster ID and boot address are considered more or less static
    input  [31:0]                       boot_addr_i,
    input  [ 3:0]                       core_id_i,
    input  [ 5:0]                       cluster_id_i,    

    //CPU Control Signals
    input                               fetch_enable_i,
    output logic                        core_busy_o,
    output logic                        core_sleep_en_o,
    
    //Instruction memory interface
    output                              riscv_instr_req_o,
    input                               riscv_instr_gnt_i,
    output  [31:0]                      riscv_instr_addr_o,
    input                               riscv_instr_rvalid_i,
    input   [31:0]                      riscv_instr_rdata_i,

    //Data memory interface
    output                              riscv_data_req_o,
    input                               riscv_data_gnt_i,
    output                              riscv_data_we_o,
    output  [3:0]                       riscv_data_be_o,
    output  [31:0]                      riscv_data_addr_o,
    output  [31:0]                      riscv_data_wdata_o,
    input                               riscv_data_rvalid_i,
    input   [31:0]                      riscv_data_rdata_i,

    //Interrupt inputs
    input                               irq_i, //level sensitive IR lines
    input   [4:0]                       irq_id_i,
    output logic                        irq_ack_o,
    input                               irq_sec_i,
    output logic [4:0]                  irq_id_o,
    output logic                        sec_lvl_o, //csr out
      
    //Debug Interface
    input                               debug_req_i, //to id

    input  [N_EXT_PERF_COUNTERS-1:0]    ext_perf_counters_i,

    //to MU
    output logic                        npu_en_mu_o,
    output logic [31:0]                 instr_npu_mu_o,

    output logic                        MQ_Cfifo_req_o,
    output logic                        VQ_Cfifo_req_o,
    output logic                        SQ_Cfifo_req_o,
    output logic                        ALU_Cfifo_req_o,
    output logic [31:0]                 Cfifo_data_in_o,
    input                               MQ_Cfifo_full_i,
    input                               VQ_Cfifo_full_i,
    input                               SQ_Cfifo_full_i,
    input                               ALU_Cfifo_full_i,

    output logic                        is_VQ_insn_mu_o,
    output logic                        is_MQ_insn_mu_o,
    output logic                        is_SQ_insn_mu_o,
    output logic                        is_Cub_alu_insn_mu_o,

    input                               mu_VQ_ready_i,
    input                               mu_MQ_ready_i,
    input                               mu_SQ_ready_i,
    input                               mu_Cub_alu_ready_i,

    output logic                        MQ_clear_o,
    output logic                        VQ_clear_o,
    output logic                        SQ_clear_o,
    output logic                        MQ_Cfifo_clear_o,
    output logic                        VQ_Cfifo_clear_o,
    output logic                        SQ_Cfifo_clear_o,   
    output logic                        ALU_Cfifo_clear_o,

    input [32-1 : 0][31 : 0]            cub_interconnect_reg_i
);

    localparam  HWLP_NUM      = 4;
    localparam  ALU_OP_WIDTH  = 7;
    localparam  RF_ADDR_WIDTH = 5;

    // IF/ID signals
    logic              is_hwlp_id;
    logic [HWLP_NUM-1:0] hwlp_cnt_dec_id;
    logic              instr_valid_id;
    logic [31:0]       instr_rdata_id;    // Instruction sampled inside IF stage
    logic              is_compressed_id;
    //logic              is_fetch_failed_id;
    logic              illegal_c_instr_id; // Illegal compressed instruction sent to ID stage
    logic [31:0]       pc_if;             // Program counter in IF stage
    logic [31:0]       pc_id;             // Program counter in ID stage
    logic              is_npu_insn;

    logic              clear_instr_valid;
    logic              pc_set;
    logic [2+1:0]      pc_mux_id;     // Mux selector for next PC
    logic [2:0]        exc_pc_mux_id; // Mux selector for exception PC
    logic [5:0]        exc_cause;
    logic              trap_addr_mux;
    //logic              lsu_load_err;
    //logic              lsu_store_err;

    // ID performance counter signals
    logic        is_decoding;

    logic        useincr_addr_ex;   // Active when post increment
    logic        data_misaligned;

    //logic        mult_multicycle;

    // Jump and branch target and decision (EX->IF)
    logic [31:0] jump_target_id, jump_target_ex;
    logic        branch_in_ex;
    logic        branch_decision;

    logic        ctrl_busy;
    logic        if_busy;
    logic        lsu_busy;

    logic [31:0] pc_ex; // PC of last executed branch or p.elw

    // ALU Control
    logic        alu_en_ex;
    logic [ALU_OP_WIDTH-1:0] alu_operator_ex;
    logic [31:0] alu_operand_a_ex;
    logic [31:0] alu_operand_b_ex;
    logic [31:0] alu_operand_c_ex;
    //logic [ 4:0] bmask_a_ex;
    //logic [ 4:0] bmask_b_ex;
    //logic [ 1:0] imm_vec_ext_ex;
    //logic [ 1:0] alu_vec_mode_ex;
    //logic        alu_is_clpx_ex, alu_is_subrot_ex;
    //logic [ 1:0] alu_clpx_shift_ex;

    // Multiplier Control
    logic [ 2:0] mult_operator_ex;
    logic [31:0] mult_operand_a_ex;
    logic [31:0] mult_operand_b_ex;
    //logic [31:0] mult_operand_c_ex;
    logic        mult_en_ex;
    //logic        mult_sel_subword_ex;
    logic [ 1:0] mult_signed_mode_ex;
    logic [ 4:0] mult_imm_ex;
    //logic [31:0] mult_dot_op_a_ex;
    //logic [31:0] mult_dot_op_b_ex;
    //logic [31:0] mult_dot_op_c_ex;
    //logic [ 1:0] mult_dot_signed_ex;
    //logic        mult_is_clpx_ex_o;
    //logic [ 1:0] mult_clpx_shift_ex;
    //logic        mult_clpx_img_ex;

    // Register Write Control
    logic [RF_ADDR_WIDTH-1:0]   regfile_waddr_ex;
    logic                       regfile_we_ex;
    logic [RF_ADDR_WIDTH-1:0]   regfile_waddr_fw_wb_o;        // From WB to ID
    logic                       regfile_we_wb;
    logic [31:0]                regfile_wdata;

    logic [RF_ADDR_WIDTH-1:0]   regfile_alu_waddr_ex;
    logic                       regfile_alu_we_ex;

    logic [RF_ADDR_WIDTH-1:0]   regfile_alu_waddr_fw;
    logic                       regfile_alu_we_fw;
    logic [31:0]                regfile_alu_wdata_fw;

    // CSR control
    logic        csr_access_ex;
    logic  [1:0] csr_op_ex;
    logic [23:0] mtvec, utvec;

    logic        csr_access;
    logic  [1:0] csr_op;
    logic [11:0] csr_addr;
    logic [11:0] csr_addr_int;
    logic [31:0] csr_rdata;
    logic [31:0] csr_wdata;
    logic [1:0]  current_priv_lvl;

    // Data Memory Control:  From ID stage (id-ex pipe) <--> load store unit
    logic        data_req_ex;
    logic        data_we_ex;
    logic [1:0]  data_type_ex;
    logic [1:0]  data_sign_ext_ex;
    logic [1:0]  data_reg_offset_ex;
    logic        data_load_event_ex;
    logic        data_misaligned_ex;

    logic [31:0] lsu_rdata;

    // stall control
    logic        halt_if;
    logic        id_ready;
    logic        ex_ready;

    logic        id_valid;
    logic        ex_valid;
    logic        wb_valid;

    logic        lsu_ready_ex;
    logic        lsu_ready_wb;

    // Signals between instruction core interface and pipe (if and id stages)
    logic        instr_req_int;    // Id stage asserts a req to instruction core interface

    // Interrupts
    logic        m_irq_enable, u_irq_enable;
    logic        csr_irq_sec;
    logic [31:0] mepc, uepc, depc;

    logic        csr_save_cause;
    logic        csr_save_if;
    logic        csr_save_id;
    logic        csr_save_ex;
    logic [5:0]  csr_cause;
    logic        csr_restore_mret_id;
    logic        csr_restore_uret_id;

    logic        csr_restore_dret_id;

    // debug mode and dcsr configuration
    logic        debug_mode;
    logic [2:0]  debug_cause;
    logic        debug_csr_save;
    logic        debug_single_step;
    logic        debug_ebreakm;
    logic        debug_ebreaku;

    // Hardware loop controller signals
    logic [HWLP_NUM-1:0] [31:0] hwlp_start;
    logic [HWLP_NUM-1:0] [31:0] hwlp_end;
    logic [HWLP_NUM-1:0] [31:0] hwlp_cnt;

    // used to write from CS registers to hardware loop registers
    logic [1:0]                 csr_hwlp_regid;
    logic [2:0]                 csr_hwlp_we;
    logic [31:0]                csr_hwlp_data;


    // Performance Counters
    logic        perf_imiss;
    logic        perf_jump;
    logic        perf_jr_stall;
    logic        perf_ld_stall;
    logic        perf_pipeline_stall;

    //core busy signals
    logic        core_ctrl_firstfetch, core_busy_int, core_busy_q, core_sleep_en;

    //==========clk management==========
    logic           clk;
    logic           clock_en;

    assign core_busy_o = core_ctrl_firstfetch ? 1'b1 : core_busy_q;
    always_ff @(posedge clk_i or negedge rst_n) begin
      if(!rst_n) begin
            core_busy_q <= 1'b0;
            core_sleep_en_o <= 1'b0;
      end 
      else begin
            core_busy_q <= core_busy_int;
            core_sleep_en_o <= core_sleep_en;
      end
    end

    // if we are sleeping on a barrier let's just wait on the instruction
    // interface to finish loading instructions
    assign core_busy_int = ((PULP_CLUSTER == 1) & data_load_event_ex & riscv_data_req_o) ? (if_busy) : (if_busy | ctrl_busy | lsu_busy);
    assign clock_en      =  (PULP_CLUSTER == 1) ? clock_en_i | core_busy_o : irq_i | debug_req_i | core_busy_o;

`ifdef CORE_FPGA
	assign clk=clk_i;
`else 
    icg U_ICG(.TE(test_en_i),.E(clock_en),.CP(clk_i),.Q(clk));
`endif


    //--------------------------------------------------------
    //  riscv IF stage
    //--------------------------------------------------------
    riscv_if_stage 
    #(
        .HWLP_NUM(HWLP_NUM),
        .DW_HaltAddress(DW_HaltAddress)
    )
    U_if_stage
    (
        .clk(clk),
        .rst_n(rst_n),
        
        .pc_mux_i(pc_mux_id),
        .boot_addr_i(boot_addr_i[31:1]),
        .jump_target_id_i(jump_target_id),
        .jump_target_ex_i(jump_target_ex),
        .mepc_i(mepc),
        .uepc_i(uepc),
        .depc_i(depc),
        .pc_set_i(pc_set), //set pc to a new value
        
        .trap_addr_mux_i(trap_addr_mux),
        .m_trap_base_addr_i(mtvec),
        .u_trap_base_addr_i(utvec),
        .exc_pc_mux_i(exc_pc_mux_id),
        .exc_vec_pc_mux_i(exc_cause[4:0]),
        
        .req_i(instr_req_int),
        
        .instr_req_o(riscv_instr_req_o),
        .instr_gnt_i(riscv_instr_gnt_i),
        .instr_addr_o(riscv_instr_addr_o),
        .instr_rvalid_i(riscv_instr_rvalid_i),
        .instr_rdata_i(riscv_instr_rdata_i),
        
        .if_instr_id_o(instr_rdata_id),
        .if_valid_id_o(instr_valid_id),
        .pc_if_o(pc_if),
        .pc_id_o(pc_id), //pc_id_o <= pc_if_o 
        .if_busy_o(if_busy), // is the IF stage busy fetching instr?
        .perf_imiss_o(perf_imiss),
        .id_ready_i(id_ready), //pipe stall
        .halt_if_i(halt_if),  //pipe stall
        
        .is_compressed_id_o(is_compressed_id),
        .illegal_c_instr_id_o(illegal_c_instr_id),
        .is_hwlp_id_o(is_hwlp_id),
        .hwlp_cnt_dec_id_o(hwlp_cnt_dec_id),
        .clear_instr_valid_i(clear_instr_valid), //clear instr valid bit in IF/ID pipe
        .is_npu_insn_i(is_npu_insn),
        
        .hwlp_start_i(hwlp_start), //hardware loop start addresses
        .hwlp_end_i(hwlp_end),   //hardware loop end addresses
        .hwlp_cnt_i(hwlp_cnt)    //hardware loop counters
    ); //IF
    
    
    //--------------------------------------------------------
    //  riscv ID stage
    //--------------------------------------------------------
    riscv_id_stage 
    #(
        .RF_ADDR_WIDTH(RF_ADDR_WIDTH),
        .HWLP_NUM(HWLP_NUM)
        //.PULP_SECURE(PULP_SECURE)
    )
    U_id_stage
    (
        .clk(clk),
        .rst_n(rst_n),    

        .test_en_i                    ( test_en_i            ),

        // Processor Enable
        .fetch_enable_i               ( fetch_enable_i       ),
        .ctrl_busy_o                  ( ctrl_busy            ),
        .core_sleep_en_o              ( core_sleep_en        ),
        .core_ctrl_firstfetch_o       ( core_ctrl_firstfetch ),
        .is_decoding_o                ( is_decoding          ),

        // to MU
        .npu_en_mu_o(npu_en_mu_o),
        .instr_npu_mu_o(instr_npu_mu_o),

        .MQ_Cfifo_req_o(MQ_Cfifo_req_o),
        .VQ_Cfifo_req_o(VQ_Cfifo_req_o),
        .SQ_Cfifo_req_o(SQ_Cfifo_req_o),
        .ALU_Cfifo_req_o(ALU_Cfifo_req_o),
        .Cfifo_data_in_o(Cfifo_data_in_o),
        .MQ_Cfifo_full_i(MQ_Cfifo_full_i),
        .VQ_Cfifo_full_i(VQ_Cfifo_full_i),
        .SQ_Cfifo_full_i(SQ_Cfifo_full_i),
        .ALU_Cfifo_full_i(ALU_Cfifo_full_i),

        .is_VQ_insn_o(is_VQ_insn_mu_o),
        .is_MQ_insn_o(is_MQ_insn_mu_o),
        .is_SQ_insn_o(is_SQ_insn_mu_o),
        .is_Cub_alu_insn_o(is_Cub_alu_insn_mu_o),
        
        .mu_VQ_ready_i(mu_VQ_ready_i),
        .mu_MQ_ready_i(mu_MQ_ready_i),
        .mu_SQ_ready_i(mu_SQ_ready_i),
        .mu_Cub_alu_ready_i(mu_Cub_alu_ready_i),

        .MQ_clear_o(MQ_clear_o),
        .VQ_clear_o(VQ_clear_o),
        .SQ_clear_o(SQ_clear_o),
        .MQ_Cfifo_clear_o(MQ_Cfifo_clear_o),
        .VQ_Cfifo_clear_o(VQ_Cfifo_clear_o),
        .SQ_Cfifo_clear_o(SQ_Cfifo_clear_o),        
        .ALU_Cfifo_clear_o(ALU_Cfifo_clear_o),        

        // Interface to instruction memory
        .hwlp_cnt_dec_i               ( hwlp_cnt_dec_id      ),
        .is_hwlp_i                    ( is_hwlp_id           ),
        .instr_valid_i                ( instr_valid_id       ),
        .instr_rdata_i                ( instr_rdata_id       ),
        .instr_req_o                  ( instr_req_int        ),

        // Jumps and branches
        .branch_in_ex_o               ( branch_in_ex         ),
        .branch_decision_i            ( branch_decision      ),
        .jump_target_o                ( jump_target_id       ),

        // IF and ID control signals
        .clear_instr_valid_o          ( clear_instr_valid    ),
        .pc_set_o                     ( pc_set               ),
        .pc_mux_o                     ( pc_mux_id            ),
        .exc_pc_mux_o                 ( exc_pc_mux_id        ),
        .exc_cause_o                  ( exc_cause            ),
        .trap_addr_mux_o              ( trap_addr_mux        ),
        .illegal_c_instr_i            ( illegal_c_instr_id   ),
        .is_compressed_i              ( is_compressed_id     ),
        .is_fetch_failed_i            ( 1'b0   ),
        .is_npu_insn_if_o             (is_npu_insn           ),

        .pc_if_i                      ( pc_if                ),
        .pc_id_i                      ( pc_id                ),

        // Stalls
        .halt_if_o                    ( halt_if              ),

        .id_ready_o                   ( id_ready             ),
        .ex_ready_i                   ( ex_ready             ),
        .wb_ready_i                   ( lsu_ready_wb         ),

        .id_valid_o                   ( id_valid             ),
        .ex_valid_i                   ( ex_valid             ),

        // From the Pipeline ID/EX
        .pc_ex_o                      ( pc_ex                ),

        .alu_en_ex_o                  ( alu_en_ex            ),
        .alu_operator_ex_o            ( alu_operator_ex      ),
        .alu_operand_a_ex_o           ( alu_operand_a_ex     ),
        .alu_operand_b_ex_o           ( alu_operand_b_ex     ),
        .alu_operand_c_ex_o           ( alu_operand_c_ex     ),

        .regfile_waddr_ex_o           ( regfile_waddr_ex     ),
        .regfile_we_ex_o              ( regfile_we_ex        ),

        .regfile_alu_we_ex_o          ( regfile_alu_we_ex    ),
        .regfile_alu_waddr_ex_o       ( regfile_alu_waddr_ex ),

        // MUL
        .mult_operator_ex_o           ( mult_operator_ex     ), // from ID to EX stage
        .mult_en_ex_o                 ( mult_en_ex           ), // from ID to EX stage
        .mult_signed_mode_ex_o        ( mult_signed_mode_ex  ), // from ID to EX stage
        .mult_operand_a_ex_o          ( mult_operand_a_ex    ), // from ID to EX stage
        .mult_operand_b_ex_o          ( mult_operand_b_ex    ), // from ID to EX stage
        //.mult_operand_c_ex_o          ( mult_operand_c_ex    ), // from ID to EX stage

        //.mult_dot_op_a_ex_o           ( mult_dot_op_a_ex     ), // from ID to EX stage
        //.mult_dot_op_b_ex_o           ( mult_dot_op_b_ex     ), // from ID to EX stage
        //.mult_dot_op_c_ex_o           ( mult_dot_op_c_ex     ), // from ID to EX stage
        //.mult_dot_signed_ex_o         ( mult_dot_signed_ex   ), // from ID to EX stage


        // CSR ID/EX
        .csr_access_ex_o              ( csr_access_ex        ),
        .csr_op_ex_o                  ( csr_op_ex            ),
        .current_priv_lvl_i           ( current_priv_lvl     ),
        .csr_irq_sec_o                ( csr_irq_sec          ),
        .csr_cause_o                  ( csr_cause            ),
        .csr_save_if_o                ( csr_save_if          ), // control signal to save pc
        .csr_save_id_o                ( csr_save_id          ), // control signal to save pc
        .csr_save_ex_o                ( csr_save_ex          ), // control signal to save pc
        .csr_restore_mret_id_o        ( csr_restore_mret_id  ), // control signal to restore pc
        .csr_restore_uret_id_o        ( csr_restore_uret_id  ), // control signal to restore pc
        .csr_restore_dret_id_o        ( csr_restore_dret_id  ), // control signal to restore pc
        .csr_save_cause_o             ( csr_save_cause       ),

        // hardware loop signals to IF hwlp controller
        .hwlp_start_o                 ( hwlp_start           ),
        .hwlp_end_o                   ( hwlp_end             ),
        .hwlp_cnt_o                   ( hwlp_cnt             ),

        // hardware loop signals from CSR
        .csr_hwlp_regid_i             ( csr_hwlp_regid       ),
        .csr_hwlp_we_i                ( csr_hwlp_we          ),
        .csr_hwlp_data_i              ( csr_hwlp_data        ),

        //LSU
        .data_req_ex_o                ( data_req_ex          ), // to load store unit
        .data_we_ex_o                 ( data_we_ex           ), // to load store unit
        .data_type_ex_o               ( data_type_ex         ), // to load store unit
        .data_sign_ext_ex_o           ( data_sign_ext_ex     ), // to load store unit
        .data_reg_offset_ex_o         ( data_reg_offset_ex   ), // to load store unit
        .data_load_event_ex_o         ( data_load_event_ex   ), // to load store unit  

        .data_misaligned_ex_o         ( data_misaligned_ex   ), // to load store unit
        .data_misaligned_i            ( data_misaligned      ),
        .prepost_useincr_ex_o         ( useincr_addr_ex      ),
        .data_err_i                   ( 1'b0                 ),
        //.data_err_ack_o               (                      ),
        
        //Interrupt Signals
        .irq_i                        ( irq_i                ), // incoming interrupts
        .irq_sec_i                    ( (PULP_SECURE) ? irq_sec_i : 1'b0 ),
        .irq_id_i                     ( irq_id_i             ),
        .m_irq_enable_i               ( m_irq_enable         ),
        .u_irq_enable_i               ( u_irq_enable         ),
        .irq_ack_o                    ( irq_ack_o            ),
        .irq_id_o                     ( irq_id_o             ),

        //Debug Signal
        .debug_mode_o                 ( debug_mode           ),
        .debug_cause_o                ( debug_cause          ),
        .debug_csr_save_o             ( debug_csr_save       ),
        .debug_req_i                  ( debug_req_i          ),
        .debug_single_step_i          ( debug_single_step    ),
        .debug_ebreakm_i              ( debug_ebreakm        ),
        .debug_ebreaku_i              ( debug_ebreaku        ),    

        //Forward Signals
        .regfile_waddr_wb_i           ( regfile_waddr_fw_wb_o),  // Write address ex-wb pipeline
        .regfile_we_wb_i              ( regfile_we_wb        ),  // write enable for the register file
        .regfile_wdata_wb_i           ( regfile_wdata        ),  // write data to commit in the register file

        .regfile_alu_waddr_fw_i       ( regfile_alu_waddr_fw ),
        .regfile_alu_we_fw_i          ( regfile_alu_we_fw    ),
        .regfile_alu_wdata_fw_i       ( regfile_alu_wdata_fw ),  

        //from ALU
        //.mult_multicycle_i            ( mult_multicycle      ),

        //Performance Counters
        .perf_jump_o                  ( perf_jump            ),
        .perf_jr_stall_o              ( perf_jr_stall        ),
        .perf_ld_stall_o              ( perf_ld_stall        ),
        .perf_pipeline_stall_o        ( perf_pipeline_stall  )        
   ); //ID
    
    
    
    //--------------------------------------------------------
    //  riscv EX stage
    //--------------------------------------------------------
    riscv_ex_stage
    #(
        .RF_ADDR_WIDTH(RF_ADDR_WIDTH),
        .ALU_OP_WIDTH(7)
    )
    ex_stage_i
    (
      .clk                        ( clk                          ),
      .rst_n                      ( rst_n                        ),

      // Alu signals from ID stage
      .alu_en_i                   ( alu_en_ex                    ),
      .alu_operator_i             ( alu_operator_ex              ), // from ID/EX pipe registers
      .alu_operand_a_i            ( alu_operand_a_ex             ), // from ID/EX pipe registers
      .alu_operand_b_i            ( alu_operand_b_ex             ), // from ID/EX pipe registers
      .alu_operand_c_i            ( alu_operand_c_ex             ), // from ID/EX pipe registers

      // Multipler
      .mult_operator_i            ( mult_operator_ex             ), // from ID/EX pipe registers
      .mult_operand_a_i           ( mult_operand_a_ex            ), // from ID/EX pipe registers
      .mult_operand_b_i           ( mult_operand_b_ex            ), // from ID/EX pipe registers
      //.mult_operand_c_i           ( mult_operand_c_ex            ), // from ID/EX pipe registers
      .mult_en_i                  ( mult_en_ex                   ), // from ID/EX pipe registers
      .mult_signed_mode_i         ( mult_signed_mode_ex          ), // from ID/EX pipe registers
      //.mult_imm_i                 ( mult_imm_ex                  ), // from ID/EX pipe registers
      //.mult_dot_op_a_i            ( mult_dot_op_a_ex             ), // from ID/EX pipe registers
      //.mult_dot_op_b_i            ( mult_dot_op_b_ex             ), // from ID/EX pipe registers
      //.mult_dot_op_c_i            ( mult_dot_op_c_ex             ), // from ID/EX pipe registers
      //.mult_dot_signed_i          ( mult_dot_signed_ex           ), // from ID/EX pipe registers

      //.mult_multicycle_o          ( mult_multicycle              ), // to ID/EX pipe registers

      .lsu_en_i                   ( data_req_ex                  ),
      .lsu_rdata_i                ( lsu_rdata                    ),

      // interface with CSRs
      .csr_access_i               ( csr_access_ex                ),
      .csr_rdata_i                ( csr_rdata                    ),

      // From ID Stage: Regfile control signals
      .branch_in_ex_i             ( branch_in_ex                 ),
      .regfile_alu_waddr_i        ( regfile_alu_waddr_ex         ),
      .regfile_alu_we_i           ( regfile_alu_we_ex            ),

      .regfile_waddr_i            ( regfile_waddr_ex             ),
      .regfile_we_i               ( regfile_we_ex                ),

      // Output of ex stage pipeline
      .regfile_waddr_wb_o         ( regfile_waddr_fw_wb_o        ),
      .regfile_we_wb_o            ( regfile_we_wb                ),
      .regfile_wdata_wb_o         ( regfile_wdata                ),

      // To IF: Jump and branch target and decision
      .jump_target_o              ( jump_target_ex               ),
      .branch_decision_o          ( branch_decision              ),

      // To ID stage: Forwarding signals
      .regfile_alu_waddr_fw_o     ( regfile_alu_waddr_fw         ),
      .regfile_alu_we_fw_o        ( regfile_alu_we_fw            ),
      .regfile_alu_wdata_fw_o     ( regfile_alu_wdata_fw         ),

      // stall control
      .lsu_ready_ex_i             ( lsu_ready_ex                 ),
      .lsu_err_i                  ( 1'b0                 ),

      .ex_ready_o                 ( ex_ready                     ),
      .ex_valid_o                 ( ex_valid                     ),
      .wb_ready_i                 ( lsu_ready_wb                 )
    );    
    
    
    
    //--------------------------------------------------------
    //  riscv LD/ST
    //--------------------------------------------------------
    riscv_load_store_unit  U_load_store
    (
        .clk                   ( clk                ),
        .rst_n                 ( rst_n              ),

        //output to data memory
        .data_req_o            ( riscv_data_req_o         ),
        .data_gnt_i            ( riscv_data_gnt_i         ),
        .data_rvalid_i         ( riscv_data_rvalid_i      ),
        .data_err_i            ( 1'b0               ),

        .data_addr_o           ( riscv_data_addr_o        ),
        .data_we_o             ( riscv_data_we_o          ),
        .data_be_o             ( riscv_data_be_o          ),
        .data_wdata_o          ( riscv_data_wdata_o       ),
        .data_rdata_i          ( riscv_data_rdata_i       ),

        //signal from ex stage  
        .data_req_ex_i         ( data_req_ex        ),
        .data_we_ex_i          ( data_we_ex         ),
        .data_type_ex_i        ( data_type_ex       ),
        .data_reg_offset_ex_i  ( data_reg_offset_ex ),
        .data_sign_ext_ex_i    ( data_sign_ext_ex   ),  // sign extension

        .data_wdata_ex_i       ( alu_operand_c_ex   ),
        .data_rdata_ex_o       ( lsu_rdata          ),
        .operand_a_ex_i        ( alu_operand_a_ex   ),
        .operand_b_ex_i        ( alu_operand_b_ex   ),
        .addr_useincr_ex_i     ( useincr_addr_ex    ),

        .data_misaligned_ex_i  ( data_misaligned_ex ), // from ID/EX pipeline
        .data_misaligned_o     ( data_misaligned    ),

        //control signals
        .lsu_ready_ex_o        ( lsu_ready_ex       ),
        .lsu_ready_wb_o        ( lsu_ready_wb       ),

        .ex_valid_i            ( ex_valid           ),
        .busy_o                ( lsu_busy           )
    );    
    
    assign wb_valid = lsu_ready_wb; 
    
    
    
    //--------------------------------------------------------
    //  riscv CSRs (Control and Status Registers)
    //--------------------------------------------------------
    riscv_cs_registers
    #(
      .N_EXT_CNT       ( N_EXT_PERF_COUNTERS   ),
      .HWLP_NUM        ( HWLP_NUM              ),
      .PULP_SECURE     ( PULP_SECURE           )
    )
    cs_registers_i
    (
      .clk                     ( clk                ),
      .rst_n                   ( rst_n              ),

      // Core and Cluster ID from outside
      .core_id_i               ( core_id_i          ),
      .cluster_id_i            ( cluster_id_i       ),
      .mtvec_o                 ( mtvec              ),
      .utvec_o                 ( utvec              ),
      // boot address
      .boot_addr_i             ( boot_addr_i[31:1]  ),
      // Interface to CSRs (SRAM like)
      .csr_access_i            ( csr_access         ),
      .csr_addr_i              ( csr_addr           ),
      .csr_wdata_i             ( csr_wdata          ),
      .csr_op_i                ( csr_op             ),
      .csr_rdata_o             ( csr_rdata          ),

      //.frm_o                   (),
      //.fprec_o                 (),
      //.fflags_i                (),
      //.fflags_we_i             (),

      // Interrupt related control signals
      .m_irq_enable_o          ( m_irq_enable       ),
      .u_irq_enable_o          ( u_irq_enable       ),
      .csr_irq_sec_i           ( csr_irq_sec        ),
      .sec_lvl_o               ( sec_lvl_o          ),
      .mepc_o                  ( mepc               ),
      .uepc_o                  ( uepc               ),

      // debug
      .debug_mode_i            ( debug_mode         ),
      .debug_cause_i           ( debug_cause        ),
      .debug_csr_save_i        ( debug_csr_save     ),
      .depc_o                  ( depc               ),
      .debug_single_step_o     ( debug_single_step  ),
      .debug_ebreakm_o         ( debug_ebreakm      ),
      .debug_ebreaku_o         ( debug_ebreaku      ),

      .priv_lvl_o              ( current_priv_lvl   ),

      //.pmp_addr_o              ( pmp_addr           ),
      //.pmp_cfg_o               ( pmp_cfg            ),

      .pc_if_i                 ( pc_if              ),
      .pc_id_i                 ( pc_id              ),
      .pc_ex_i                 ( pc_ex              ),

      .csr_save_if_i           ( csr_save_if        ),
      .csr_save_id_i           ( csr_save_id        ),
      .csr_save_ex_i           ( csr_save_ex        ),
      .csr_restore_mret_i      ( csr_restore_mret_id ),
      .csr_restore_uret_i      ( csr_restore_uret_id ),

      .csr_restore_dret_i      ( csr_restore_dret_id ),

      .csr_cause_i             ( csr_cause          ),
      .csr_save_cause_i        ( csr_save_cause     ),

      // from hwloop registers
      .hwlp_start_i            ( hwlp_start         ),
      .hwlp_end_i              ( hwlp_end           ),
      .hwlp_cnt_i              ( hwlp_cnt           ),

      .hwlp_regid_o            ( csr_hwlp_regid     ),
      .hwlp_we_o               ( csr_hwlp_we        ),
      .hwlp_data_o             ( csr_hwlp_data      ),

      //cubank reg
      .cub_interconnect_reg_i  (cub_interconnect_reg_i),

      // performance counter related signals
      .id_valid_i              ( id_valid           ),
      .is_compressed_i         ( is_compressed_id   ),
      .is_decoding_i           ( is_decoding        ),

      .imiss_i                 ( perf_imiss         ),
      .pc_set_i                ( pc_set             ),
      .jump_i                  ( perf_jump          ),
      .branch_i                ( branch_in_ex       ),
      .branch_taken_i          ( branch_decision    ),
      .ld_stall_i              ( perf_ld_stall      ),
      .jr_stall_i              ( perf_jr_stall      ),
      .pipeline_stall_i        ( perf_pipeline_stall ),

      //.apu_typeconflict_i      ( perf_apu_type      ),
      //.apu_contention_i        ( perf_apu_cont      ),
      //.apu_dep_i               ( perf_apu_dep       ),
      //.apu_wb_i                ( perf_apu_wb        ),

      .mem_load_i              ( riscv_data_req_o & riscv_data_gnt_i & (~riscv_data_we_o) ),
      .mem_store_i             ( riscv_data_req_o & riscv_data_gnt_i & riscv_data_we_o    ),

      .ext_counters_i          ( ext_perf_counters_i                    )
    );

    //CSR access
    assign csr_access   =  csr_access_ex;
    assign csr_addr     =  csr_addr_int;
    assign csr_wdata    =  alu_operand_a_ex;
    assign csr_op       =  csr_op_ex;

    assign csr_addr_int = csr_access_ex ? alu_operand_b_ex[11:0] : 'b0;    


endmodule
