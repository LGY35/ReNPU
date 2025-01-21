parameter OPCODE_SYSTEM     =7'h73;
parameter OPCODE_FENCE      =7'h0f;
parameter OPCODE_OP         =7'h33;
parameter OPCODE_OPIMM      =7'h13; 
parameter OPCODE_STORE      =7'h23; 
parameter OPCODE_LOAD       =7'h03; 
parameter OPCODE_BRANCH     =7'h63; 
parameter OPCODE_JALR       =7'h67; 
parameter OPCODE_JAL        =7'h6f; 
parameter OPCODE_AUIPC      =7'h17; 
parameter OPCODE_LUI        =7'h37; 
//parameter OPCODE_OP_FP      =7'h53; 
//parameter OPCODE_OP_FMADD   =7'h43; 
//parameter OPCODE_OP_FNMADD  =7'h4f; 
//parameter OPCODE_OP_FMSUB   =7'h47; 
//parameter OPCODE_OP_FNMSUB  =7'h4b; 
//parameter OPCODE_STORE_FP   =7'h27; 
//parameter OPCODE_LOAD_FP    =7'h07;

// PULP custom
parameter OPCODE_HWLOOP     = 7'h7b;//cus3
parameter OPCODE_LOAD_POST  = 7'h0b;//cus0
parameter OPCODE_STORE_POST = 7'h2b;//cus1
//parameter OPCODE_PULP_OP    = 7'h5b;//cus2
parameter OPCODE_VECOP      = 7'h57;

parameter OPCODE_ACCEL      = 7'h5b;
