module cub_cs_registers(
    input                       clk,
    input                       rst_n,
    
    input                       csr_access_en_i,
    input        [ 5: 0]        csr_addr_i,
    input        [15: 0]        csr_wdata_i,

    output logic [ 7: 0]        scache_wr_sub_len_o    ,
    output logic [ 7: 0]        scache_wr_sys_len_o    ,
    output logic [ 8: 0]        scache_wr_sub_gap_o    ,
    output logic [ 9: 0]        scache_wr_sys_gap_o    ,
    output logic [ 7: 0]        scache_rd_sub_len_o    ,
    output logic [ 7: 0]        scache_rd_sys_len_o    ,
    output logic [ 8: 0]        scache_rd_sub_gap_o    ,
    output logic [ 9: 0]        scache_rd_sys_gap_o    ,
    output logic [ 7: 0]        acti_work_mode_o       ,
    //output logic [ 0: 0]        pool_cflow_mode_o      ,
    output logic [ 0: 0]        pool_comp_sign_o       ,
    output logic [ 1: 0]        pool_comp_vect_o       ,
    output logic [ 1: 0]        pool_comp_mode_o       ,
    output logic [ 0: 0]        pool_cflow_wind_step_o ,
    output logic [ 7: 0]        pool_cflow_wind_size_o ,
    output logic [ 1: 0]        pool_cflow_lab_mode_o  ,
    output logic [ 7: 0]        pool_cflow_data_len_o  ,
    output logic [ 2: 0]        cub_alu_din_cflow_sel_o,
    output logic [ 0: 0]        cub_scache_dout_cflow_sel_o,
    output logic [ 0: 0]        cub_cflow_mode_o,
    output logic [ 0: 0]        cub_alu_dout_cflow_sel_o,
    output logic [ 0: 0]        cub_alu_elt_mode_o,
    output logic [ 0: 0]        cub_alu_elt_arith_or_mult_o,
    output logic [14: 0]        cub_crbr_bitmask_cfg0_o,
    output logic [ 9: 0]        cub_crbr_bitmask_cfg1_o,
    output logic [ 0: 0]        cub_mult_param_sel_o,
    output logic [ 0: 0]        cub_arithmetic_param_sel_o,
    output logic [ 0: 0]        cub_activ_param_sel_o,
    output logic [ 0: 0]        cub_mem_op_sta_clr_o,
    output logic [ 0: 0]        scache_lut_mode_o,
    output logic [ 0: 0]        scache_lut_ram_sel_o,
    output logic [ 6: 0]        arithmetic_cflow_operator_o
    //output logic                arithmetic_trun_prec_o,
    //output logic [ 4: 0]        arithmetic_trun_Q_o
);
    
`include "cub_csr_param.v"

logic [15:0]                  scache_wr_cfg0;
logic [ 8:0]                  scache_wr_cfg1;
logic [ 9:0]                  scache_wr_cfg2;
logic [15:0]                  scache_rd_cfg0;
logic [ 8:0]                  scache_rd_cfg1;
logic [ 9:0]                  scache_rd_cfg2;
logic [ 7:0]                  acti_cfg0;
logic [15:0]                  pool_cfg0;
logic [ 7:0]                  pool_cfg1;
logic [ 7:0]                  alu_cflow_cfg0;
logic [ 2:0]                  alu_cflow_cfg1;
logic [14:0]                  alu_crbr_cfg0;
logic [ 9:0]                  alu_crbr_cfg1;
logic [ 0:0]                  cub_mem_cfg0;
logic [ 1:0]                  scache_lut_cfg0;
logic [ 6:0]                  alu_fu_cfg0;

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        scache_wr_cfg0  <= 'b0;
        scache_wr_cfg1  <= 'b0;
        scache_wr_cfg2  <= 'b0;
        scache_rd_cfg0  <= 'b0;
        scache_rd_cfg1  <= 'b0;
        scache_rd_cfg2  <= 'b0;
        acti_cfg0       <= 'b0;
        pool_cfg0       <= 'b0;
        pool_cfg1       <= 'b0;
        alu_cflow_cfg0  <= 'b0;
        alu_cflow_cfg1  <= 'b0;
        alu_crbr_cfg0   <= 'b0;
        alu_crbr_cfg1   <= 'b0;
        cub_mem_cfg0    <= 'b0;
        scache_lut_cfg0 <= 'b0;
        alu_fu_cfg0     <= 'b0011000; //ALU_ADD
    end
    else if(csr_access_en_i) begin
        case(csr_addr_i)
            CSR_SCACHE_WR_CFG0:     scache_wr_cfg0 <= csr_wdata_i[15:0];
            CSR_SCACHE_WR_CFG1:     scache_wr_cfg1 <= csr_wdata_i[8:0];
            CSR_SCACHE_WR_CFG2:     scache_wr_cfg2 <= csr_wdata_i[9:0];
            CSR_SCACHE_RD_CFG0:     scache_rd_cfg0 <= csr_wdata_i[15:0];
            CSR_SCACHE_RD_CFG1:     scache_rd_cfg1 <= csr_wdata_i[8:0];
            CSR_SCACHE_RD_CFG2:     scache_rd_cfg2 <= csr_wdata_i[9:0];
            CSR_ACTI_CFG0:          acti_cfg0 <= csr_wdata_i[7:0];
            CSR_POOL_CFG0:          pool_cfg0 <= csr_wdata_i[15:0];
            CSR_POOL_CFG1:          pool_cfg1 <= csr_wdata_i[7:0];
            CSR_ALU_FLOW_CFG0:      alu_cflow_cfg0 <= csr_wdata_i[7:0];
            CSR_ALU_FLOW_CFG1:      alu_cflow_cfg1 <= csr_wdata_i[2:0];
            CSR_ALU_CRBR_CFG0:      alu_crbr_cfg0 <= csr_wdata_i[14:0];
            CSR_ALU_CRBR_CFG1:      alu_crbr_cfg1 <= csr_wdata_i[9:0];
            CSR_CUB_MEM_CFG0:       cub_mem_cfg0 <= csr_wdata_i[0];
            CSR_SCACHE_LUT_CFG0:    scache_lut_cfg0 <= csr_wdata_i[1:0];
            CSR_ALU_FU_CFG0:        alu_fu_cfg0 <= csr_wdata_i[6:0];
        endcase
    end
    else begin
        cub_mem_cfg0 <= 'b0;
    end
end

assign scache_wr_sub_len_o          = scache_wr_cfg0[7:0];
assign scache_wr_sys_len_o          = scache_wr_cfg0[15:8];
assign scache_wr_sub_gap_o          = scache_wr_cfg1[8:0];
assign scache_wr_sys_gap_o          = scache_wr_cfg2[9:0];
assign scache_rd_sub_len_o          = scache_rd_cfg0[7:0];
assign scache_rd_sys_len_o          = scache_rd_cfg0[15:8];
assign scache_rd_sub_gap_o          = scache_rd_cfg1[8:0];
assign scache_rd_sys_gap_o          = scache_rd_cfg2[9:0];
assign acti_work_mode_o             = acti_cfg0[7:0];
//assign pool_cflow_mode_o            = pool_cfg0[0]; 
assign pool_comp_sign_o             = pool_cfg0[0];
assign pool_comp_vect_o             = pool_cfg0[2:1];
assign pool_comp_mode_o             = pool_cfg0[4:3];
assign pool_cflow_wind_step_o       = pool_cfg0[5];
assign pool_cflow_wind_size_o       = pool_cfg0[13:6];
assign pool_cflow_lab_mode_o        = pool_cfg0[15:14];
assign pool_cflow_data_len_o        = pool_cfg1[7:0];
assign cub_alu_din_cflow_sel_o      = alu_cflow_cfg0[2:0];
assign cub_scache_dout_cflow_sel_o  = alu_cflow_cfg0[3];
assign cub_cflow_mode_o             = alu_cflow_cfg0[4];
assign cub_alu_dout_cflow_sel_o     = alu_cflow_cfg0[5];
assign cub_alu_elt_mode_o           = alu_cflow_cfg0[6];
assign cub_alu_elt_arith_or_mult_o  = alu_cflow_cfg0[7];
assign cub_mult_param_sel_o         = alu_cflow_cfg1[0];
assign cub_arithmetic_param_sel_o   = alu_cflow_cfg1[1];
assign cub_activ_param_sel_o        = alu_cflow_cfg1[2];
assign cub_crbr_bitmask_cfg0_o      = alu_crbr_cfg0[14:0];
assign cub_crbr_bitmask_cfg1_o      = alu_crbr_cfg1[9:0];
assign cub_mem_op_sta_clr_o         = cub_mem_cfg0[0];
assign scache_lut_mode_o            = scache_lut_cfg0[0];
assign scache_lut_ram_sel_o         = scache_lut_cfg0[1];
assign arithmetic_cflow_operator_o  = alu_fu_cfg0[6:0];
//assign arithmetic_trun_prec_o       = alu_cfg0[0];
//assign arithmetic_trun_Q_o          = alu_cfg0[5:1];


endmodule
