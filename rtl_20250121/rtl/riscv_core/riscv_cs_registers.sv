/*
Design Name     : Control and Status Registers
Data            : 2024/2/21      
Description     : 
*/

`define ASIC_SYNTHESIS

`ifndef PULP_FPGA_EMUL
 `ifdef SYNTHESIS
  `define ASIC_SYNTHESIS
 `endif
`endif

module riscv_cs_registers
#(
  parameter N_EXT_CNT     = 0,
  parameter HWLP_NUM      = 4,
  parameter PULP_SECURE   = 0
)
(
  // Clock and Reset
  input                         clk,
  input			                rst_n,

  // Core and Cluster ID
  input	[3:0]                   core_id_i,
  input	[5:0]                   cluster_id_i,
  output logic [23:0]           mtvec_o,
  output logic [23:0]           utvec_o,

  // Used for boot address
  input [30:0]                  boot_addr_i,

  // Interface to registers (SRAM like)
  input			                csr_access_i,
  input [11:0]                  csr_addr_i,
  input [31:0]                  csr_wdata_i,
  input  [1:0]                  csr_op_i,
  output logic [31:0]           csr_rdata_o,

  // Interrupts
  output logic                  m_irq_enable_o,
  output logic                  u_irq_enable_o,

  //csr_irq_sec_i is always 0 if PULP_SECURE is zero
  input			                csr_irq_sec_i,
  output logic                  sec_lvl_o,
  output logic [31:0]           mepc_o,
  output logic [31:0]           uepc_o,

  // debug
  input			                debug_mode_i,
  input	[2:0]                   debug_cause_i,
  input			                debug_csr_save_i,
  output logic [31:0]           depc_o,
  output logic                  debug_single_step_o,
  output logic                  debug_ebreakm_o,
  output logic                  debug_ebreaku_o,

  //output logic  [N_PMP_ENTRIES-1:0] [31:0] pmp_addr_o,
  //output logic  [N_PMP_ENTRIES-1:0] [7:0]  pmp_cfg_o,

  output [1:0]                  priv_lvl_o,

  input	[31:0]                  pc_if_i,
  input	[31:0]                  pc_id_i,
  input	[31:0]                  pc_ex_i,

  input			                csr_save_if_i,
  input			                csr_save_id_i,
  input			                csr_save_ex_i,

  input			                csr_restore_mret_i,
  input			                csr_restore_uret_i,

  input			                csr_restore_dret_i,
  //coming from controller
  input	[5:0]                   csr_cause_i,
  //coming from controller
  input			                csr_save_cause_i,
  // Hardware loops
  input	[HWLP_NUM-1:0] [31:0]   hwlp_start_i,
  input	[HWLP_NUM-1:0] [31:0]   hwlp_end_i,
  input	[HWLP_NUM-1:0] [31:0]   hwlp_cnt_i,

  output logic [31:0]           hwlp_data_o,
  output logic [1:0]            hwlp_regid_o,
  output logic [2:0]            hwlp_we_o,

  // Performance Counters
  input			                id_valid_i,        // ID stage is done
  input			                is_compressed_i,   // compressed instruction in ID
  input			                is_decoding_i,     // controller is in DECODE state

  input			                imiss_i,           // instruction fetch
  input			                pc_set_i,          // pc was set to a new value
  input			                jump_i,            // jump instruction seen   (j, jr, jal, jalr)
  input			                branch_i,          // branch instruction seen (bf, bnf)
  input			                branch_taken_i,    // branch was taken
  input			                ld_stall_i,        // load use hazard
  input			                jr_stall_i,        // jump register use hazard
  input			                pipeline_stall_i,  // extra cycles from elw

  input			                mem_load_i,        // load from memory in this cycle
  input			                mem_store_i,       // store to memory in this cycle

  input	[N_EXT_CNT-1:0]         ext_counters_i,

  input [32-1 : 0][31 : 0]      cub_interconnect_reg_i
);

`include "decode_param.v"

  parameter C_RM = 3;

  localparam N_APU_CNT       = 0;
  localparam N_PERF_COUNTERS = 12 + N_EXT_CNT + N_APU_CNT;

  localparam PERF_EXT_ID     = 12;
  localparam PERF_APU_ID     = PERF_EXT_ID + N_EXT_CNT;
  localparam MTVEC_MODE      = 2'b01;

  localparam MAX_N_PMP_ENTRIES = 16;
  localparam MAX_N_PMP_CFG     =  4;
 

`ifdef ASIC_SYNTHESIS
  localparam N_PERF_REGS     = 1;
`else
  localparam N_PERF_REGS     = N_PERF_COUNTERS;
`endif

  `define MSTATUS_UIE_BITS        0
  `define MSTATUS_SIE_BITS        1
  `define MSTATUS_MIE_BITS        3
  `define MSTATUS_UPIE_BITS       4
  `define MSTATUS_SPIE_BITS       5
  `define MSTATUS_MPIE_BITS       7
  `define MSTATUS_SPP_BITS        8
  `define MSTATUS_MPP_BITS    12:11
  `define MSTATUS_MPRV_BITS      17

  // misa
  localparam logic [1:0] MXL = 2'd1; // M-XLEN: XLEN in M-Mode for RV32
  localparam logic [31:0] MISA_VALUE =
      (0                <<  0)  // A - Atomic Instructions extension
    | (1                <<  2)  // C - Compressed extension
    | (0                <<  3)  // D - Double precision floating-point extension
    | (0                <<  4)  // E - RV32E base ISA
    | (32'b0            <<  5)  // F - Single precision floating-point extension
    | (1                <<  8)  // I - RV32I/64I/128I base ISA
    | (1                << 12)  // M - Integer Multiply/Divide extension
    | (0                << 13)  // N - User level interrupts supported
    | (0                << 18)  // S - Supervisor mode implemented
    | (32'(PULP_SECURE) << 20)  // U - User mode implemented
    | (0                << 23)  // X - Non-standard extensions present (FIXME)
    | (32'(MXL)         << 30); // M-XLEN


  typedef struct packed {
    logic uie;
    // logic sie;      - unimplemented, hardwired to '0
    // logic hie;      - unimplemented, hardwired to '0
    logic mie;
    logic upie;
    // logic spie;     - unimplemented, hardwired to '0
    // logic hpie;     - unimplemented, hardwired to '0
    logic mpie;
    // logic spp;      - unimplemented, hardwired to '0
    // logic[1:0] hpp; - unimplemented, hardwired to '0
    PrivLvl_t mpp;
    logic mprv;
  } Status_t;


  typedef struct packed{
      logic [31:28] xdebugver;
      logic [27:16] zero2;
      logic         ebreakm;
      logic         zero1;
      logic         ebreaks;
      logic         ebreaku;
      logic         stepie;
      logic         stopcount;
      logic         stoptime;
      logic [8:6]   cause;
      logic         zero0;
      logic         mprven;
      logic         nmip;
      logic         step;
      PrivLvl_t     prv;
  } Dcsr_t;

  typedef struct packed {
   logic  [MAX_N_PMP_ENTRIES-1:0] [31:0] pmpaddr;
   logic  [MAX_N_PMP_CFG-1:0]     [31:0] pmpcfg_packed;
   logic  [MAX_N_PMP_ENTRIES-1:0] [ 7:0] pmpcfg;
  } Pmp_t;

  // CSR update logic
  logic [31:0] csr_wdata_int;
  logic [31:0] csr_rdata_int;
  logic        csr_we_int;
  //logic [C_RM-1:0]     frm_q, frm_n;
  //logic [C_FFLAG-1:0]  fflags_q, fflags_n;
  //logic [C_PC-1:0]     fprec_q, fprec_n;

  // Interrupt control signals
  logic [31:0] mepc_q, mepc_n;
  logic [31:0] uepc_q, uepc_n;
  Dcsr_t       dcsr_q, dcsr_n;
  logic [31:0] depc_q, depc_n;
  logic [31:0] dscratch0_q, dscratch0_n;
  logic [31:0] dscratch1_q, dscratch1_n;
  logic [31:0] mscratch_q, mscratch_n;

  logic [31:0] exception_pc;
  Status_t mstatus_q, mstatus_n;
  logic [ 5:0] mcause_q, mcause_n;
  logic [ 5:0] ucause_q, ucause_n;
  //not implemented yet
  logic [23:0] mtvec_n, mtvec_q;
  logic [23:0] utvec_n, utvec_q;

  logic is_irq;
  PrivLvl_t priv_lvl_n, priv_lvl_q, priv_lvl_reg_q;
  //clock gating for pmp regs
  logic [MAX_N_PMP_ENTRIES-1:0] pmpaddr_we;
  logic [MAX_N_PMP_ENTRIES-1:0] pmpcfg_we;

  // Performance Counter Signals
  logic                          id_valid_q;
  logic [N_PERF_COUNTERS-1:0]    PCCR_in;  // input signals for each counter category
  logic [N_PERF_COUNTERS-1:0]    PCCR_inc, PCCR_inc_q; // should the counter be increased?

  logic [N_PERF_REGS-1:0] [31:0] PCCR_q, PCCR_n; // performance counters counter register
  logic [1:0]                    PCMR_n, PCMR_q; // mode register, controls saturation and global enable
  logic [N_PERF_COUNTERS-1:0]    PCER_n, PCER_q; // selected counter input

  logic [31:0]                   perf_rdata;
  logic [4:0]                    pccr_index;
  logic                          pccr_all_sel;
  logic                          is_pccr;
  logic                          is_pcer;
  logic                          is_pcmr;

  assign is_irq = csr_cause_i[5];

  ////////////////////////////////////////////
  //   ____ ____  ____    ____              //
  //  / ___/ ___||  _ \  |  _ \ ___  __ _   //
  // | |   \___ \| |_) | | |_) / _ \/ _` |  //
  // | |___ ___) |  _ <  |  _ <  __/ (_| |  //
  //  \____|____/|_| \_\ |_| \_\___|\__, |  //
  //                                |___/   //
  ////////////////////////////////////////////

  // read logic
  always_comb
  begin
    case (csr_addr_i)
      // fcsr: Floating-Point Control and Status Register (frm + fflags).
      12'h001: csr_rdata_int = '0;
      12'h002: csr_rdata_int = '0;
      12'h003: csr_rdata_int = '0;
      12'h006: csr_rdata_int = '0; // Optional precision control for FP DIV/SQRT Unit
      // mstatus: always M-mode, contains IE bit
      12'h300: csr_rdata_int = {
                                  14'b0,
                                  mstatus_q.mprv,
                                  4'b0,
                                  mstatus_q.mpp,
                                  3'b0,
                                  mstatus_q.mpie,
                                  2'h0,
                                  mstatus_q.upie,
                                  mstatus_q.mie,
                                  2'h0,
                                  mstatus_q.uie
                                };
      // misa: machine isa register
      12'h301: csr_rdata_int = MISA_VALUE;
      // mtvec: machine trap-handler base address
      12'h305: csr_rdata_int = {mtvec_q, 6'h0, MTVEC_MODE};
      // mscratch: machine scratch
      12'h340: csr_rdata_int = mscratch_q;
      // mepc: exception program counter
      12'h341: csr_rdata_int = mepc_q;
      // mcause: exception cause
      12'h342: csr_rdata_int = {mcause_q[5], 26'b0, mcause_q[4:0]};
      // mhartid: unique hardware thread id
      12'hF14: csr_rdata_int = {21'b0, cluster_id_i[5:0], 1'b0, core_id_i[3:0]};

        // mvendorid: Machine Vendor ID
        CSR_MVENDORID: csr_rdata_int = {MVENDORID_BANK, MVENDORID_OFFSET};

        // marchid: Machine Architecture ID
        CSR_MARCHID: csr_rdata_int = MARCHID;

      CSR_DCSR:
               csr_rdata_int = dcsr_q;//
      CSR_DPC:
               csr_rdata_int = depc_q;
      CSR_DSCRATCH0:
               csr_rdata_int = dscratch0_q;//
      CSR_DSCRATCH1:
               csr_rdata_int = dscratch1_q;//

      // hardware loops  (not official)
      HWLoop0_START: csr_rdata_int = hwlp_start_i[0];
      HWLoop0_END: csr_rdata_int = hwlp_end_i[0];
      HWLoop0_COUNTER: csr_rdata_int = hwlp_cnt_i[0];
      HWLoop1_START: csr_rdata_int = hwlp_start_i[1];
      HWLoop1_END: csr_rdata_int = hwlp_end_i[1];
      HWLoop1_COUNTER: csr_rdata_int = hwlp_cnt_i[1];

      HWLoop2_START: csr_rdata_int = hwlp_start_i[2];
      HWLoop2_END: csr_rdata_int = hwlp_end_i[2]; 
      HWLoop2_COUNTER: csr_rdata_int = hwlp_cnt_i[2];
      HWLoop3_START: csr_rdata_int = hwlp_start_i[3];
      HWLoop3_END: csr_rdata_int = hwlp_end_i[3];
      HWLoop3_COUNTER: csr_rdata_int = hwlp_cnt_i[3];

      // cubank regs  (not official)
      12'h7D0: csr_rdata_int = cub_interconnect_reg_i[0];
      12'h7D1: csr_rdata_int = cub_interconnect_reg_i[1];
      12'h7D2: csr_rdata_int = cub_interconnect_reg_i[2];
      12'h7D3: csr_rdata_int = cub_interconnect_reg_i[3];
      12'h7D4: csr_rdata_int = cub_interconnect_reg_i[4];
      12'h7D5: csr_rdata_int = cub_interconnect_reg_i[5];
      12'h7D6: csr_rdata_int = cub_interconnect_reg_i[6];
      12'h7D7: csr_rdata_int = cub_interconnect_reg_i[7];
      12'h7D8: csr_rdata_int = cub_interconnect_reg_i[8];
      12'h7D9: csr_rdata_int = cub_interconnect_reg_i[9];
      12'h7DA: csr_rdata_int = cub_interconnect_reg_i[10];
      12'h7DB: csr_rdata_int = cub_interconnect_reg_i[11];
      12'h7DC: csr_rdata_int = cub_interconnect_reg_i[12];
      12'h7DD: csr_rdata_int = cub_interconnect_reg_i[13];
      12'h7DE: csr_rdata_int = cub_interconnect_reg_i[14];
      12'h7DF: csr_rdata_int = cub_interconnect_reg_i[15];
      12'h7E0: csr_rdata_int = cub_interconnect_reg_i[16];
      12'h7E1: csr_rdata_int = cub_interconnect_reg_i[17];
      12'h7E2: csr_rdata_int = cub_interconnect_reg_i[18];
      12'h7E3: csr_rdata_int = cub_interconnect_reg_i[19];
      12'h7E4: csr_rdata_int = cub_interconnect_reg_i[20];
      12'h7E5: csr_rdata_int = cub_interconnect_reg_i[21];
      12'h7E6: csr_rdata_int = cub_interconnect_reg_i[22];
      12'h7E7: csr_rdata_int = cub_interconnect_reg_i[23];
      12'h7E8: csr_rdata_int = cub_interconnect_reg_i[24];
      12'h7E9: csr_rdata_int = cub_interconnect_reg_i[25];
      12'h7EA: csr_rdata_int = cub_interconnect_reg_i[26];
      12'h7EB: csr_rdata_int = cub_interconnect_reg_i[27];
      12'h7EC: csr_rdata_int = cub_interconnect_reg_i[28];
      12'h7ED: csr_rdata_int = cub_interconnect_reg_i[29];
      12'h7EE: csr_rdata_int = cub_interconnect_reg_i[30];
      12'h7EF: csr_rdata_int = cub_interconnect_reg_i[31];
      
      /* USER CSR */
      // dublicated mhartid: unique hardware thread id (not official)
      12'h014: csr_rdata_int = {21'b0, cluster_id_i[5:0], 1'b0, core_id_i[3:0]};
      // current priv level (not official)
      12'hC10: csr_rdata_int = {30'h0, priv_lvl_q};
      default:
        csr_rdata_int = '0;
    endcase
  end

  // write logic
  always_comb begin
    mscratch_n               = mscratch_q;
    mepc_n                   = mepc_q;
    depc_n                   = depc_q;
    dcsr_n                   = dcsr_q;
    dscratch0_n              = dscratch0_q;
    dscratch1_n              = dscratch1_q;

    mstatus_n                = mstatus_q;
    mcause_n                 = mcause_q;
    hwlp_we_o                = '0;
    hwlp_regid_o             = '0;
    exception_pc             = pc_id_i;
    priv_lvl_n               = priv_lvl_q;
    mtvec_n                  = mtvec_q;
    pmpaddr_we               = '0;
    pmpcfg_we                = '0;

    case (csr_addr_i)
      // fcsr: Floating-Point Control and Status Register (frm, fflags, fprec).
      //12'h001: if (csr_we_int) fflags_n = '0;
      //12'h002: if (csr_we_int) frm_n    = '0;
      //12'h003: if (csr_we_int) begin
      //   fflags_n = '0;
      //   frm_n    = '0;
      //end
      //12'h006: if (csr_we_int) fprec_n = '0;

      // mstatus: IE bit
      12'h300: if (csr_we_int) begin
        mstatus_n = '{
          uie:  csr_wdata_int[`MSTATUS_UIE_BITS],
          mie:  csr_wdata_int[`MSTATUS_MIE_BITS],
          upie: csr_wdata_int[`MSTATUS_UPIE_BITS],
          mpie: csr_wdata_int[`MSTATUS_MPIE_BITS],
          mpp:  PrivLvl_t'(csr_wdata_int[`MSTATUS_MPP_BITS]),
          mprv: csr_wdata_int[`MSTATUS_MPRV_BITS]
        };
      end
      // mscratch: machine scratch
      12'h340: if (csr_we_int) begin
        mscratch_n = csr_wdata_int;
      end
      // mepc: exception program counter
      12'h341: if (csr_we_int) begin
        mepc_n = csr_wdata_int & ~32'b1; // force 16-bit alignment
      end
      // mcause
      12'h342: if (csr_we_int) mcause_n = {csr_wdata_int[31], csr_wdata_int[4:0]};

      CSR_DCSR:
               if (csr_we_int)
               begin
                    dcsr_n = csr_wdata_int;
                    //31:28 xdebuger = 4 -> debug is implemented
                    dcsr_n.xdebugver=4'h4;
                    //privilege level: 0-> U;1-> S; 3->M.
                    dcsr_n.prv=priv_lvl_q;
                    //currently not supported:
                    dcsr_n.nmip=1'b0;   //nmip
                    dcsr_n.mprven=1'b0; //mprven
                    dcsr_n.stopcount=1'b0;   //stopcount
                    dcsr_n.stoptime=1'b0;  //stoptime
               end
      CSR_DPC:
               if (csr_we_int)
               begin
                    depc_n = csr_wdata_int & ~32'b1; // force 16-bit alignment
               end

      CSR_DSCRATCH0:
               if (csr_we_int)
               begin
                    dscratch0_n = csr_wdata_int;
               end

      CSR_DSCRATCH1:
               if (csr_we_int)
               begin
                    dscratch1_n = csr_wdata_int;
               end

      // hardware loops
      HWLoop0_START: if (csr_we_int) begin hwlp_we_o = 3'b001; hwlp_regid_o = 2'b00; end
      HWLoop0_END: if (csr_we_int) begin hwlp_we_o = 3'b010; hwlp_regid_o = 2'b00; end
      HWLoop0_COUNTER: if (csr_we_int) begin hwlp_we_o = 3'b100; hwlp_regid_o = 2'b00; end
      HWLoop1_START: if (csr_we_int) begin hwlp_we_o = 3'b001; hwlp_regid_o = 2'b01; end
      HWLoop1_END: if (csr_we_int) begin hwlp_we_o = 3'b010; hwlp_regid_o = 2'b01; end
      HWLoop1_COUNTER: if (csr_we_int) begin hwlp_we_o = 3'b100; hwlp_regid_o = 2'b01; end
      HWLoop2_START: if (csr_we_int) begin hwlp_we_o = 3'b001; hwlp_regid_o = 2'b10; end
      HWLoop2_END: if (csr_we_int) begin hwlp_we_o = 3'b010; hwlp_regid_o = 2'b10; end
      HWLoop2_COUNTER: if (csr_we_int) begin hwlp_we_o = 3'b100; hwlp_regid_o = 2'b10; end
      HWLoop3_START: if (csr_we_int) begin hwlp_we_o = 3'b001; hwlp_regid_o = 2'b11; end
      HWLoop3_END: if (csr_we_int) begin hwlp_we_o = 3'b010; hwlp_regid_o = 2'b11; end
      HWLoop3_COUNTER: if (csr_we_int) begin hwlp_we_o = 3'b100; hwlp_regid_o = 2'b11; end
    endcase

    // exception controller gets priority over other writes
    unique case (1'b1)

      csr_save_cause_i: begin
        unique case (1'b1)
          csr_save_if_i:
            exception_pc = pc_if_i;
          csr_save_id_i:
            exception_pc = pc_id_i;
          //default:;
        endcase

        if (debug_csr_save_i) begin
            // all interrupts are masked, don't update cause, epc, tval dpc and
            // mpstatus
            dcsr_n.prv   = PRIV_LVL_M;
            dcsr_n.cause = debug_cause_i;
            depc_n       = exception_pc;
        end else begin
            priv_lvl_n     = PRIV_LVL_M;
            mstatus_n.mpie = mstatus_q.mie;
            mstatus_n.mie  = 1'b0;
            mstatus_n.mpp  = PRIV_LVL_M;
            mepc_n = exception_pc;
            mcause_n       = csr_cause_i;
        end
      end //csr_save_cause_i

      csr_restore_mret_i: begin //MRET
        mstatus_n.mie  = mstatus_q.mpie;
        priv_lvl_n     = PRIV_LVL_M;
        mstatus_n.mpie = 1'b1;
        mstatus_n.mpp  = PRIV_LVL_M;
      end //csr_restore_mret_i

      csr_restore_dret_i: begin //DRET
        // restore to the recorded privilege level
        // TODO: prevent illegal values, see riscv-debug p.44
        priv_lvl_n = dcsr_q.prv;
      end //csr_restore_dret_i

      //default:;
    endcase
  end

  assign hwlp_data_o = csr_wdata_int;

  // CSR operation logic
  always_comb begin
    csr_wdata_int = csr_wdata_i;
    csr_we_int    = 1'b1;

    unique case (csr_op_i)
      CSR_OP_WRITE: csr_wdata_int = csr_wdata_i;
      CSR_OP_SET:   csr_wdata_int = csr_wdata_i | csr_rdata_o;
      CSR_OP_CLEAR: csr_wdata_int = (~csr_wdata_i) & csr_rdata_o;
      CSR_OP_NONE: begin
        csr_wdata_int = csr_wdata_i;
        csr_we_int    = 1'b0;
      end
      //default:;
    endcase
  end

  // output mux
  always_comb begin
    csr_rdata_o = csr_rdata_int;

    // performance counters
    if (is_pccr || is_pcer || is_pcmr)
      csr_rdata_o = perf_rdata;
  end


  // directly output some registers
  assign m_irq_enable_o  = mstatus_q.mie & priv_lvl_q == PRIV_LVL_M;
  assign u_irq_enable_o  = mstatus_q.uie & priv_lvl_q == PRIV_LVL_U;
  assign priv_lvl_o      = priv_lvl_q;
  assign sec_lvl_o       = priv_lvl_q[0];

  assign mtvec_o         = mtvec_q;
  assign utvec_o         = utvec_q;

  assign mepc_o          = mepc_q;
  assign uepc_o          = uepc_q;

  assign depc_o          = depc_q;

  //assign pmp_addr_o     = pmp_reg_q.pmpaddr;
  //assign pmp_cfg_o      = pmp_reg_q.pmpcfg;

  assign debug_single_step_o  = dcsr_q.step;
  assign debug_ebreakm_o      = dcsr_q.ebreakm;
  assign debug_ebreaku_o      = dcsr_q.ebreaku;

    assign uepc_q       = '0;
    assign ucause_q     = '0;
    assign mtvec_q      = boot_addr_i[30:7];
    assign utvec_q      = '0;
    assign priv_lvl_q   = PRIV_LVL_M;

  // actual registers
  always_ff @(posedge clk or negedge rst_n)
  begin
    if (rst_n == 1'b0) begin
      mstatus_q  <= '{
              uie:  1'b0,
              mie:  1'b0,
              upie: 1'b0,
              mpie: 1'b0,
              mpp:  PRIV_LVL_M,
              mprv: 1'b0
            };
      mepc_q      <= '0;
      mcause_q    <= '0;

      depc_q      <= '0;
      //dcsr_q      <= '0;
      //dcsr_q.prv  <= PRIV_LVL_M;
      dcsr_q      <= {'0,PRIV_LVL_M};
      dscratch0_q <= '0;
      dscratch1_q <= '0;
      mscratch_q  <= '0;
    end
    else begin
      // update CSRs
        mstatus_q  <= '{
                uie:  1'b0,
                mie:  mstatus_n.mie,
                upie: 1'b0,
                mpie: mstatus_n.mpie,
                mpp:  PRIV_LVL_M,
                mprv: 1'b0
              };
      mepc_q     <= mepc_n    ;
      mcause_q   <= mcause_n  ;

      depc_q     <= depc_n    ;
      dcsr_q     <= dcsr_n    ;
      dscratch0_q<= dscratch0_n;
      dscratch1_q<= dscratch1_n;
      mscratch_q <= mscratch_n;
    end
  end

  /////////////////////////////////////////////////////////////////
  //   ____            __     ____                  _            //
  // |  _ \ ___ _ __ / _|   / ___|___  _   _ _ __ | |_ ___ _ __  //
  // | |_) / _ \ '__| |_   | |   / _ \| | | | '_ \| __/ _ \ '__| //
  // |  __/  __/ |  |  _|  | |__| (_) | |_| | | | | ||  __/ |    //
  // |_|   \___|_|  |_|(_)  \____\___/ \__,_|_| |_|\__\___|_|    //
  //                                                             //
  /////////////////////////////////////////////////////////////////

  assign PCCR_in[0]  = 1'b1;                                          // cycle counter
  assign PCCR_in[1]  = id_valid_i & is_decoding_i;                    // instruction counter
  assign PCCR_in[2]  = ld_stall_i & id_valid_q;                       // nr of load use hazards
  assign PCCR_in[3]  = jr_stall_i & id_valid_q;                       // nr of jump register hazards
  assign PCCR_in[4]  = imiss_i & (~pc_set_i);                         // cycles waiting for instruction fetches, excluding jumps and branches
  assign PCCR_in[5]  = mem_load_i;                                    // nr of loads
  assign PCCR_in[6]  = mem_store_i;                                   // nr of stores
  assign PCCR_in[7]  = jump_i                     & id_valid_q;       // nr of jumps (unconditional)
  assign PCCR_in[8]  = branch_i                   & id_valid_q;       // nr of branches (conditional)
  assign PCCR_in[9]  = branch_i & branch_taken_i  & id_valid_q;       // nr of taken branches (conditional)
  assign PCCR_in[10] = id_valid_i & is_decoding_i & is_compressed_i;  // compressed instruction counter
  assign PCCR_in[11] = pipeline_stall_i;                              //extra cycles from elw

  // assign external performance counters
  generate
    genvar i;
    for(i = 0; i < N_EXT_CNT; i++)
    begin
      assign PCCR_in[PERF_EXT_ID + i] = ext_counters_i[i];
    end
  endgenerate

  // address decoder for performance counter registers
  always_comb
  begin
    is_pccr      = 1'b0;
    is_pcmr      = 1'b0;
    is_pcer      = 1'b0;
    pccr_all_sel = 1'b0;
    pccr_index   = '0;
    perf_rdata   = '0;

    // only perform csr access if we actually care about the read data
    if (csr_access_i) begin
      unique case (csr_addr_i)
        PCER_USER, PCER_MACHINE: begin
          is_pcer = 1'b1;
          perf_rdata[N_PERF_COUNTERS-1:0] = PCER_q;
        end
        PCMR_USER, PCMR_MACHINE: begin
          is_pcmr = 1'b1;
          perf_rdata[1:0] = PCMR_q;
        end
        12'h79F: begin // last pccr register selects all
          is_pccr = 1'b1;
          pccr_all_sel = 1'b1;
        end
        //default:;
      endcase

      // look for 780 to 79F, Performance Counter Counter Registers
      if (csr_addr_i[11:5] == 7'b0111100) begin
        is_pccr     = 1'b1;

        pccr_index = csr_addr_i[4:0];
`ifdef  ASIC_SYNTHESIS
        perf_rdata = PCCR_q[0];
`else
        perf_rdata = csr_addr_i[4:0] < N_PERF_COUNTERS ? PCCR_q[csr_addr_i[4:0]] : '0;
`endif
      end
    end
  end


  // performance counter counter update logic
`ifdef ASIC_SYNTHESIS
  // for synthesis we just have one performance counter register
  assign PCCR_inc[0] = (|(PCCR_in & PCER_q)) & PCMR_q[0];

  always_comb
  begin
    PCCR_n[0]   = PCCR_q[0];

    if ((PCCR_inc_q[0] == 1'b1) && ((PCCR_q[0] != 32'hFFFFFFFF) || (PCMR_q[1] == 1'b0)))
      PCCR_n[0] = PCCR_q[0] + 1;

    if (is_pccr == 1'b1) begin
      unique case (csr_op_i)
        //CSR_OP_NONE:   ;
        CSR_OP_WRITE:  PCCR_n[0] = csr_wdata_i;
        CSR_OP_SET:    PCCR_n[0] = csr_wdata_i | PCCR_q[0];
        CSR_OP_CLEAR:  PCCR_n[0] = csr_wdata_i & ~(PCCR_q[0]);
      endcase
    end
  end
`else
  always_comb
  begin
    for(int i = 0; i < N_PERF_COUNTERS; i++)
    begin : PERF_CNT_INC
      PCCR_inc[i] = PCCR_in[i] & PCER_q[i] & PCMR_q[0];

      PCCR_n[i]   = PCCR_q[i];

      if ((PCCR_inc_q[i] == 1'b1) && ((PCCR_q[i] != 32'hFFFFFFFF) || (PCMR_q[1] == 1'b0)))
        PCCR_n[i] = PCCR_q[i] + 1;

      if (is_pccr == 1'b1 && (pccr_all_sel == 1'b1 || pccr_index == i)) begin
        unique case (csr_op_i)
          CSR_OP_NONE:   ;
          CSR_OP_WRITE:  PCCR_n[i] = csr_wdata_i;
          CSR_OP_SET:    PCCR_n[i] = csr_wdata_i | PCCR_q[i];
          CSR_OP_CLEAR:  PCCR_n[i] = csr_wdata_i & ~(PCCR_q[i]);
        endcase
      end
    end
  end
`endif

  // update PCMR and PCER
  always_comb
  begin
    PCMR_n = PCMR_q;
    PCER_n = PCER_q;

    if (is_pcmr) begin
      unique case (csr_op_i)
        //CSR_OP_NONE:   ;
        CSR_OP_WRITE:  PCMR_n = csr_wdata_i[1:0];
        CSR_OP_SET:    PCMR_n = csr_wdata_i[1:0] | PCMR_q;
        CSR_OP_CLEAR:  PCMR_n = csr_wdata_i[1:0] & ~(PCMR_q);
      endcase
    end

    if (is_pcer) begin
      unique case (csr_op_i)
        //CSR_OP_NONE:   ;
        CSR_OP_WRITE:  PCER_n = csr_wdata_i[N_PERF_COUNTERS-1:0];
        CSR_OP_SET:    PCER_n = csr_wdata_i[N_PERF_COUNTERS-1:0] | PCER_q;
        CSR_OP_CLEAR:  PCER_n = csr_wdata_i[N_PERF_COUNTERS-1:0] & ~(PCER_q);
      endcase
    end
  end

  // Performance Counter Registers
  always_ff @(posedge clk, negedge rst_n)
  begin
    if (rst_n == 1'b0)
    begin
      id_valid_q <= 1'b0;

      PCER_q <= '0;
      PCMR_q <= 2'h3;

      for(int i = 0; i < N_PERF_REGS; i++)
      begin
        PCCR_q[i]     <= '0;
        PCCR_inc_q[i] <= '0;
      end
    end
    else
    begin
      id_valid_q <= id_valid_i;

      PCER_q <= PCER_n;
      PCMR_q <= PCMR_n;

      for(int i = 0; i < N_PERF_REGS; i++)
      begin
        PCCR_q[i]     <= PCCR_n[i];
        PCCR_inc_q[i] <= PCCR_inc[i];
      end

    end
  end

endmodule
