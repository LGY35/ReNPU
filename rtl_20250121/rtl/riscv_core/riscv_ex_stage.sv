/*
Design Name     : Execute Stage
Data            : 2024/2/18      
Description     : Hosts ALU and MAC unit                    
                  ALU: computes additions/subtractions/comparisons           
                  MULT: computes normal multiplications.
*/

module riscv_ex_stage
#(
    parameter RF_ADDR_WIDTH = 5,
    parameter ALU_OP_WIDTH = 7
)
(
    input                           clk,
    input                           rst_n,

    //ALU signals from ID stage
    input  [ALU_OP_WIDTH-1:0]       alu_operator_i,
    input  [31:0]                   alu_operand_a_i,
    input  [31:0]                   alu_operand_b_i,
    input  [31:0]                   alu_operand_c_i,
    input                           alu_en_i,

    //Multiplier signals
    input  [ 2:0]                   mult_operator_i,
    input  [31:0]                   mult_operand_a_i,
    input  [31:0]                   mult_operand_b_i,
    //input  [31:0]                   mult_operand_c_i,
    input                           mult_en_i,
    input  [ 1:0]                   mult_signed_mode_i,
    //input  [ 4:0]                   mult_imm_i,

    //input  [31:0]                   mult_dot_op_a_i,
    //input  [31:0]                   mult_dot_op_b_i,
    //input  [31:0]                   mult_dot_op_c_i,
    //input  [ 1:0]                   mult_dot_signed_i,

    //output logic                    mult_multicycle_o,

    input                           lsu_en_i,
    input  [31:0]                   lsu_rdata_i,

    //Jump and branch target and decision
    input                           branch_in_ex_i, 
    output logic                    branch_decision_o, //to ID
    output logic [31:0]             jump_target_o, //to IF

    //directly passed through to WB stage, not used in EX, from ID stage
    input                           regfile_we_i,
    input  [RF_ADDR_WIDTH-1:0]      regfile_waddr_i,
    //forward
    input  [RF_ADDR_WIDTH-1:0]      regfile_alu_waddr_i,
    input                           regfile_alu_we_i,

    //Output of EX stage pipeline
    output logic [RF_ADDR_WIDTH-1:0]    regfile_waddr_wb_o,
    output logic                        regfile_we_wb_o,
    output logic [31:0]                 regfile_wdata_wb_o,
    //Forwarding ports : to ID stage    
    output logic [RF_ADDR_WIDTH-1:0]    regfile_alu_waddr_fw_o,
    output logic                        regfile_alu_we_fw_o,
    output logic [31:0]                 regfile_alu_wdata_fw_o, //forward to RF and ID/EX pipe, ALU & MUL
    

    //CSR access
    input                           csr_access_i,
    input  [31:0]                   csr_rdata_i,

    // Stall Control
    input                           lsu_ready_ex_i, //EX part of LSU is done
    input                           lsu_err_i, //0

    output logic                    ex_ready_o, //EX stage ready for new data
    output logic                    ex_valid_o, //EX stage gets new data
    input                           wb_ready_i  //WB stage ready for new data
);


    logic [31:0]                    alu_result;
    logic [31:0]                    mult_result;
    logic                           alu_cmp_result;

    logic                           regfile_we_lsu;
    logic [RF_ADDR_WIDTH-1:0]       regfile_waddr_lsu;

    logic                           alu_ready;
    logic                           mult_ready;

    //============================
    //  ALU
    //============================
    riscv_alu
    #(
        .ALU_OP_WIDTH(7)    
    )
    U_alu
    (
      .clk                 ( clk             ),
      .rst_n               ( rst_n           ),
      .enable_i            ( alu_en_i        ),
      .operator_i          ( alu_operator_i  ),
      .operand_a_i         ( alu_operand_a_i ),
      .operand_b_i         ( alu_operand_b_i ),
      .operand_c_i         ( alu_operand_c_i ),

      .result_o            ( alu_result      ),
      .comparison_result_o ( alu_cmp_result  ),

      .ready_o             ( alu_ready       ),
      .ex_ready_i          ( ex_ready_o      )
    );

    //branch handling
    assign branch_decision_o = alu_cmp_result;
    assign jump_target_o     = alu_operand_c_i;


    //ALU write port mux
    always_comb begin
        regfile_alu_we_fw_o    = regfile_alu_we_i; 
        regfile_alu_waddr_fw_o = regfile_alu_waddr_i;
        regfile_alu_wdata_fw_o = 'b0;
        if(alu_en_i)
            regfile_alu_wdata_fw_o = alu_result;
        if(mult_en_i)
            regfile_alu_wdata_fw_o = mult_result;
        if(csr_access_i)
            regfile_alu_wdata_fw_o = csr_rdata_i;
    end

    //LSU write port mux
    always_comb begin
        regfile_we_wb_o    = regfile_we_lsu;
        regfile_waddr_wb_o = regfile_waddr_lsu;
        regfile_wdata_wb_o = lsu_rdata_i;
    end


    //============================
    //  MULT
    //============================
    riscv_mult U_mult
     (
      .clk             ( clk                  ),
      .rst_n           ( rst_n                ),

      .enable_i        ( mult_en_i            ),
      .operator_i      ( mult_operator_i      ),

      .op_a_i          ( mult_operand_a_i     ),
      .op_b_i          ( mult_operand_b_i     ),
      //.op_c_i          ( mult_operand_c_i     ),
      //.imm_i           ( mult_imm_i           ),
      .short_signed_i  ( mult_signed_mode_i   ),

      .result_o        ( mult_result          ),

      //.multicycle_o    ( mult_multicycle_o    ),
      .ready_o         ( mult_ready           ),
      .ready_i         ( ex_ready_o           )
    );



    //============================
    //  EX/WB Pipeline Register
    //============================

    always_ff@(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            regfile_waddr_lsu <= 'b0;
            regfile_we_lsu    <= 1'b0;
        end
        else begin
            if(ex_valid_o) begin //wb_ready_i is implied
                regfile_we_lsu <= regfile_we_i;
                if(regfile_we_i)
                    regfile_waddr_lsu <= regfile_waddr_i;
            end
            else if(wb_ready_i) begin
                //we are ready for a new instruction, but there is none available,
                //so we just flush the current one out of the pipe
                regfile_we_lsu <= 1'b0;
            end
        end
    end

    //As valid always goes to the right and ready to the left, and we are able
    //to finish branches without going to the WB stage, ex_valid does not depend on ex_ready.
    assign ex_ready_o = (alu_ready & mult_ready & lsu_ready_ex_i & wb_ready_i) | (branch_in_ex_i); //EX stage ready for new data
    assign ex_valid_o = (alu_en_i | mult_en_i | csr_access_i | lsu_en_i) & (alu_ready & mult_ready & lsu_ready_ex_i & wb_ready_i); //EX stage gets new data


endmodule
