//jump target mux
parameter JT_JAL  = 2'b01;
parameter JT_JALR = 2'b10;
parameter JT_COND = 2'b11;

//branch types
parameter BRANCH_NONE = 2'b00;
parameter BRANCH_JAL  = 2'b01;
parameter BRANCH_JALR = 2'b10;
parameter BRANCH_COND = 2'b11; // conditional branches

//operand a selection
parameter OP_A_REGA_OR_FWD = 3'b000;
parameter OP_A_CURRPC      = 3'b001;
parameter OP_A_IMM         = 3'b010;
parameter OP_A_REGB_OR_FWD = 3'b011;
parameter OP_A_REGC_OR_FWD = 3'b100;
parameter OP_A_ZERO        = 3'b101;

//operand b selection
parameter OP_B_REGB_OR_FWD = 3'b000;
parameter OP_B_REGC_OR_FWD = 3'b001;
parameter OP_B_IMM         = 3'b010;
parameter OP_B_REGA_OR_FWD = 3'b011;
parameter OP_B_BMASK       = 3'b100;

//operand c selection
parameter OP_C_REGC_OR_FWD = 2'b00;
parameter OP_C_REGB_OR_FWD = 2'b01;
parameter OP_C_JT          = 2'b10;

//immediate a selection
parameter IMMA_Z      = 2'b00;
parameter IMMA_ZERO   = 2'b01;
parameter IMMA_SC     = 2'b10;
parameter IMMA_LB     = 2'b11;
//immediate b selection
parameter IMMB_I      = 4'b0000;
parameter IMMB_S      = 4'b0001;
parameter IMMB_U      = 4'b0010;
parameter IMMB_PCINCR = 4'b0011;
parameter IMMB_S2     = 4'b0100;
parameter IMMB_S3     = 4'b0101;
parameter IMMB_VS     = 4'b0110;
parameter IMMB_VU     = 4'b0111;
parameter IMMB_SHUF   = 4'b1000;
parameter IMMB_CLIP   = 4'b1001;
parameter IMMB_BI     = 4'b1011;
parameter IMMB_C      = 4'b1010;
parameter IMMB_IS     = 4'b1100;
parameter IMMB_LCI    = 4'b1101;

//forwarding operand mux
parameter SEL_REGFILE      = 2'b00;
parameter SEL_FW_EX        = 2'b01;
parameter SEL_FW_WB        = 2'b10;

//regc_mux
parameter REGC_S1   = 2'b10;
parameter REGC_S4   = 2'b00;
parameter REGC_RD   = 2'b01;
parameter REGC_ZERO = 2'b11;

//======ALU Operations======
parameter ALU_ADD   = 7'b0011000;
parameter ALU_SUB   = 7'b0011001;
parameter ALU_ADDU  = 7'b0011010;
parameter ALU_SUBU  = 7'b0011011;

parameter ALU_XOR   = 7'b0101111;
parameter ALU_OR    = 7'b0101110;
parameter ALU_AND   = 7'b0010101;

parameter ALU_SRA   = 7'b0100100;//Shifts
parameter ALU_SRL   = 7'b0100101;
parameter ALU_SLL   = 7'b0100111;

parameter ALU_LTS   = 7'b0000000;//Comparisons
parameter ALU_LTU   = 7'b0000001;
parameter ALU_GES   = 7'b0001010;
parameter ALU_GEU   = 7'b0001011;
parameter ALU_EQ    = 7'b0001100;
parameter ALU_NE    = 7'b0001101;

parameter ALU_SLTS  = 7'b0000010;//Set Lower Than operations
parameter ALU_SLTU  = 7'b0000011;

parameter ALU_DIVU  = 7'b0110000;//div/rem 
parameter ALU_DIV   = 7'b0110001; 
parameter ALU_REMU  = 7'b0110010; 
parameter ALU_REM   = 7'b0110011;

parameter ALU_MAX       = 7'b1000000;
parameter ALU_MAXU      = 7'b1000001;
parameter ALU_MIN       = 7'b1000010;
parameter ALU_MINU      = 7'b1000011;
parameter ALU_ABS       = 7'b1000100;
parameter ALU_SLETS     = 7'b1000101;
parameter ALU_SLETU     = 7'b1000110;
parameter ALU_EXTS      = 7'b1000111;
parameter ALU_EXT       = 7'b1001000;
parameter ALU_SGTS      = 7'b1001001;
parameter ALU_ADDT8     = 7'b1001010;
parameter ALU_SUBT8     = 7'b1001011;
parameter ALU_ADDT16    = 7'b1001100;
parameter ALU_SUBT16    = 7'b1001101;
parameter ALU_ADDT      = 7'b1001110;
parameter ALU_SUBT      = 7'b1001111;

//======MUL Operations======
parameter MUL_MAC32 = 3'b000;
parameter MUL_MSU32 = 3'b001;
parameter MUL_I     = 3'b010;
parameter MUL_CCNI16= 3'b011;
parameter MUL_DOT8  = 3'b100;
parameter MUL_DOT16 = 3'b101;
parameter MUL_H     = 3'b110;
parameter MUL_NCNI16= 3'b111;

// vector modes
parameter VEC_MODE32 = 2'b00;
parameter VEC_MODE16 = 2'b10;
parameter VEC_MODE8  = 2'b11;

//Privileged mode
//parameter PRIV_LVL_M = 2'b11;
//parameter PRIV_LVL_H = 2'b10;
//parameter PRIV_LVL_S = 2'b01;
//parameter PRIV_LVL_U = 2'b00;

//Exception Cause
parameter EXC_CAUSE_INSTR_FAULT   = 6'h01;
parameter EXC_CAUSE_ILLEGAL_INSTR = 6'h02;
parameter EXC_CAUSE_BREAKPOINT    = 6'h03;
parameter EXC_CAUSE_LOAD_FAULT    = 6'h05;
parameter EXC_CAUSE_STORE_FAULT   = 6'h07;
parameter EXC_CAUSE_ECALL_UMODE   = 6'h08;
parameter EXC_CAUSE_ECALL_MMODE   = 6'h0B;

//CSR operations
parameter CSR_OP_NONE  = 2'b00;
parameter CSR_OP_WRITE = 2'b01;
parameter CSR_OP_SET   = 2'b10;
parameter CSR_OP_CLEAR = 2'b11;

//PC mux selector defines
parameter PC_BOOT      = 4'b0000;
parameter PC_JUMP      = 4'b0010;
parameter PC_BRANCH    = 4'b0011;
parameter PC_EXCEPTION = 4'b0100;
parameter PC_FENCEI    = 4'b0001;
parameter PC_MRET      = 4'b0101;
parameter PC_URET      = 4'b0110;
parameter PC_DRET      = 4'b0111;
parameter PC_NPU       = 4'b1000;

//Trap mux selector
localparam TRAP_MACHINE = 1'b0;
localparam TRAP_USER    = 1'b1;

//Exception PC mux selector defines
parameter EXC_PC_EXCEPTION = 3'b000;
parameter EXC_PC_IRQ       = 3'b001;
parameter EXC_PC_DBD       = 3'b010;

//Debug Cause
parameter DBG_CAUSE_EBREAK     = 3'h1;
parameter DBG_CAUSE_TRIGGER    = 3'h2;
parameter DBG_CAUSE_HALTREQ    = 3'h3;
parameter DBG_CAUSE_STEP       = 3'h4;
parameter DBG_CAUSE_RSTHALTREQ = 3'h5;

//Privileged mode
typedef enum logic[1:0] {
  PRIV_LVL_M = 2'b11,
  PRIV_LVL_H = 2'b10,
  PRIV_LVL_S = 2'b01,
  PRIV_LVL_U = 2'b00
} PrivLvl_t;

//Debug CSR
parameter CSR_DCSR      = 12'h7b0;
parameter CSR_DPC       = 12'h7b1;
parameter CSR_DSCRATCH0 = 12'h7b2; // optional
parameter CSR_DSCRATCH1 = 12'h7b3; // optional

//Hardware Loop
parameter HWLoop0_START         = 12'h7C0; //NON standard read/write (Machine CSRs). Old address 12'h7B0;
parameter HWLoop0_END           = 12'h7C1; //NON standard read/write (Machine CSRs). Old address 12'h7B1;
parameter HWLoop0_COUNTER       = 12'h7C2; //NON standard read/write (Machine CSRs). Old address 12'h7B2;
parameter HWLoop1_START         = 12'h7C4; //NON standard read/write (Machine CSRs). Old address 12'h7B4;
parameter HWLoop1_END           = 12'h7C5; //NON standard read/write (Machine CSRs). Old address 12'h7B5;
parameter HWLoop1_COUNTER       = 12'h7C6; //NON standard read/write (Machine CSRs). Old address 12'h7B6;
parameter HWLoop2_START         = 12'h7C8; //new add
parameter HWLoop2_END           = 12'h7C9; //new add
parameter HWLoop2_COUNTER       = 12'h7CA; //new add
parameter HWLoop3_START         = 12'h7CC; //new add
parameter HWLoop3_END           = 12'h7CD; //new add
parameter HWLoop3_COUNTER       = 12'h7CE; //new add

//Performance Counters
//event and mode registers
parameter PCER_USER = 12'hCC0; //NON standard read-only (User CSRs). Old address 12'h7A0;
parameter PCMR_USER = 12'hCC1; //NON standard read-only (User CSRs). Old address 12'h7A1;

parameter PCER_MACHINE = 12'h7E0; //NON standard read/write (Machine CSRs)
parameter PCMR_MACHINE = 12'h7E1; //NON standard read/write (Machine CSRs)

// Machine information
parameter CSR_MVENDORID = 12'hF11;
parameter CSR_MARCHID   = 12'hF12;
parameter CSR_MIMPID    = 12'hF13;
parameter CSR_MHARTID   = 12'hF14;
// Machine Vendor ID - OpenHW JEDEC ID is '2 decimal (bank 13)'
parameter MVENDORID_OFFSET = 7'h2;  // Final byte without parity bit
parameter MVENDORID_BANK = 25'hC;  // Number of continuation codes
// Machine Architecture ID (https://github.com/riscv/riscv-isa-manual/blob/master/marchid.md)
parameter MARCHID = 32'h4;
