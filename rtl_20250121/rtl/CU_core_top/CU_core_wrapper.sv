module CU_core_wrapper #(
    parameter   NODE_ID     = 4'd0,
    parameter   CLUSTER_ID  = 6'd0
)
(
    input                               clk,
    input                               rst_n,
    
    //riscv core
    input                               clock_en_i, //enable clock, otherwise it is gated

    input  [31:0]                       boot_addr_i,

    input                               fetch_enable_i,

    //Instruction memory interface
    output logic                        riscv_instr_req_o,
    input                               riscv_instr_gnt_i,
    output logic [31:0]                 riscv_instr_addr_o,
    input                               riscv_instr_rvalid_i,
    input   [31:0]                      riscv_instr_rdata_i,

    //Interrupt inputs
    input                               core_wakeup_irq, //level sensitive IR lines

    //Debug Interface
    // input                               debug_req_i, //to id
    // input  [N_EXT_PERF_COUNTERS-1:0]    ext_perf_counters_i,

    //to NOC
    output logic                        Noc_cmd_req_o,
    output logic [2:0]                  Noc_cmd_addr_o,
    input                               Noc_cmd_gnt_i,
    input                               Noc_cmd_ok_i,
    output                              core_sleep_en_o, //sleep irq
    
    output logic                        Noc_cfg_vld_o,
    output logic [6:0]                  Noc_cfg_addr_o,
    output logic [12:0]                 Noc_cfg_data_o,

    //from l2 noc
    input                               l2c_datain_vld   ,
    input                               l2c_datain_last  ,
    output logic                        l2c_datain_rdy   ,
    input [256-1:0]                     l2c_datain_data  ,
    //to l2 noc
    output                              l2c_dataout_vld  ,
    output                              l2c_dataout_last ,
    input logic                         l2c_dataout_rdy  ,
    output [256-1:0]                    l2c_dataout_data    

);

//Data memory interface
logic                               riscv_data_req_o;
logic                               riscv_data_gnt_i;
logic                               riscv_data_we_o;
logic [3:0]                         riscv_data_be_o;
logic [31:0]                        riscv_data_addr_o;
logic [31:0]                        riscv_data_wdata_o;
logic                               riscv_data_rvalid_i;
logic   [31:0]                      riscv_data_rdata_i;

logic                               irq_i;
logic   [4:0]                       irq_id_i;
logic                               irq_ack_o;
logic                               irq_sec_i;
logic [4:0]                         irq_id_o;
logic                               sec_lvl_o; //csr out

logic [32-1:0][32-1:0]              CU_bank_data_out;
logic [32-1:0]                      CU_bank_data_out_vld;


CU_core_top U_cu_core_top(
    .clk                        (clk),
    .rst_n                      (rst_n),
    
    //riscv core
    .clock_en_i                 (clock_en_i), //enable clock, otherwise it is gated
    .test_en_i                  (1'b0), //enable all clock gates for testing

    .boot_addr_i                (boot_addr_i),
    .core_id_i                  (NODE_ID),
    .cluster_id_i               (CLUSTER_ID),

    .fetch_enable_i             (fetch_enable_i),
    .core_busy_o                (),

    //Instruction memory interface
    .riscv_instr_req_o          (riscv_instr_req_o),
    .riscv_instr_gnt_i          (riscv_instr_gnt_i),
    .riscv_instr_addr_o         (riscv_instr_addr_o),
    .riscv_instr_rvalid_i       (riscv_instr_rvalid_i),
    .riscv_instr_rdata_i        (riscv_instr_rdata_i),

    //Data memory interface
    .riscv_data_req_o           (riscv_data_req_o),  
    .riscv_data_gnt_i           (riscv_data_gnt_i),
    .riscv_data_we_o            (riscv_data_we_o),
    .riscv_data_be_o            (riscv_data_be_o),
    .riscv_data_addr_o          (riscv_data_addr_o),
    .riscv_data_wdata_o         (riscv_data_wdata_o),
    .riscv_data_rvalid_i        (riscv_data_rvalid_i),
    .riscv_data_rdata_i         (riscv_data_rdata_i),

    //Interrupt inputs
    .irq_i                      (irq_i), //level sensitive IR lines
    .irq_id_i                   (irq_id_i),
    .irq_ack_o                  (irq_ack_o),
    .irq_sec_i                  (1'b1),
    .irq_id_o                   (irq_id_o),
    .sec_lvl_o                  (), //csr out
      
    //Debug Interface
    .debug_req_i                (1'b0), //to id
    .ext_perf_counters_i        (1'b0),

    //to NOC
    .Noc_cmd_req_o              (Noc_cmd_req_o),
    .Noc_cmd_addr_o             (Noc_cmd_addr_o),
    .Noc_cmd_gnt_i              (Noc_cmd_gnt_i),
    .Noc_cmd_ok_i               (Noc_cmd_ok_i),
    .core_sleep_en_o            (core_sleep_en_o),
    
    .Noc_cfg_vld_o              (Noc_cfg_vld_o),
    .Noc_cfg_addr_o             (Noc_cfg_addr_o),
    .Noc_cfg_data_o             (Noc_cfg_data_o),

    //from l2 noc
    .l2c_datain_vld              (l2c_datain_vld),
    .l2c_datain_last             (l2c_datain_last),
    .l2c_datain_rdy              (l2c_datain_rdy),
    .l2c_datain_data             (l2c_datain_data),
    //to l2 noc
    .l2c_dataout_vld             (l2c_dataout_vld),
    .l2c_dataout_last            (l2c_dataout_last),
    .l2c_dataout_rdy             (l2c_dataout_rdy),
    .l2c_dataout_data            (l2c_dataout_data)   
);

irq_ctr U_irq_ctr(
    .clk                        (clk),
    .rst_n                      (rst_n),

    .core_wakeup_irq            (core_wakeup_irq),
    .irq_i                      (irq_i),
    .irq_id_i                   (irq_id_i),
    .irq_ack_o                  (irq_ack_o),
    .irq_id_o                   (irq_id_o)
);


dram_top U_dram_top(
    .clk                        (clk),
    .rst_n                      (rst_n),
    .data_req                   (riscv_data_req_o),
    .data_gnt                   (riscv_data_gnt_i),
    .data_we                    (riscv_data_we_o),
    .data_be                    (riscv_data_be_o),
    .data_addr                  (riscv_data_addr_o[8:0]),
    .data_wdata                 (riscv_data_wdata_o),
    .data_rvalid                (riscv_data_rvalid_i),
    .data_rdata                 (riscv_data_rdata_i)
);

endmodule