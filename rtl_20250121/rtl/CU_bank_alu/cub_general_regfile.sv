module cub_general_regfile #(
    parameter ADDR_WIDTH = 5,
    parameter DATA_WIDTH = 32
)
(
    input		                                clk                   ,
    input		                                rst_n                 ,
    //Read port R1
    input		 [ADDR_WIDTH-1:0]               cub_greg_raddr_a      ,
    output logic [DATA_WIDTH-1:0]               cub_greg_rdata_a      ,

    //Read port R2
    input		 [ADDR_WIDTH-1:0]               cub_greg_raddr_b      ,
    output logic [DATA_WIDTH-1:0]               cub_greg_rdata_b      ,

    //Write port W1
    input logic [ADDR_WIDTH-1:0]                cub_greg_waddr_a      ,
    input logic [DATA_WIDTH-1:0]                cub_greg_wdata_a      ,
    input logic                                 cub_greg_we_a         ,

    //Write port W2
    input logic [ADDR_WIDTH-1:0]                cub_greg_waddr_b      , //port b priority is high
    input logic [DATA_WIDTH-1:0]                cub_greg_wdata_b      ,
    input logic                                 cub_greg_we_b         ,

    input       [4:0]                           cub_id_i              ,
    //to alu reg
    input                                       cub_mult_param_sel_i,
    input                                       cub_arithmetic_param_sel_i,
    input                                       cub_activ_param_sel_i,
    
    output logic [15: 0]                        cub_mult_lambda_o,
    output logic [ 3: 0]                        cub_mult_truncate_Q_o,
    output logic [31: 0]                        cub_arithmetic_bias_o,
    //output logic [ 0: 0]                        cub_arithmetic_trun_en_o,
    //output logic [ 0: 0]                        cub_arithmetic_trun_prec_o,
    output logic [ 4: 0]                        cub_arithmetic_trun_Q_o,
    output logic [ 4: 0]                        cub_arithmetic_trun_elt_Q_o,
    output logic [15: 0]                        cub_activ_prelu_scaling_o,
    output logic [ 4: 0]                        cub_activ_mul_pdt_Qp_o,
    output logic [31: 0]                        cub_activ_relu6_bias_o,
    output logic [31: 0]                        cub_activ_relu6_ref_max_o,
    output logic [31: 0]                        cub_activ_relu6_ref_min_o,

    //cubank interconnect reg
    input   [31:0]                              cub_interconnect_top_reg_0_i,
    input   [31:0]                              cub_interconnect_top_reg_1_i,
    input   [31:0]                              cub_interconnect_top_reg_2_i,
    input   [31:0]                              cub_interconnect_top_reg_3_i,
    input   [31:0]                              cub_interconnect_bottom_reg_0_i,
    input   [31:0]                              cub_interconnect_bottom_reg_1_i,
    input   [31:0]                              cub_interconnect_bottom_reg_2_i,
    input   [31:0]                              cub_interconnect_bottom_reg_3_i,
    input   [31:0]                              cub_interconnect_side_reg_i,
    input   [31:0]                              cub_interconnect_gap_reg_i,

    output logic [31:0]                         cub_interconnect_reg_o,
    input                                       cub_interconnect_reg_valid_i,
    output logic                                cub_interconnect_reg_ready_o
);

    localparam NUM_WORDS = 2**ADDR_WIDTH; //number of integer registers

    logic [NUM_WORDS-1:0][DATA_WIDTH-1:0] cub_greg_mem; //integer register file

    //masked write addresses
    //logic [ADDR_WIDTH-1:0]                cub_greg_waddr_a;
    //logic [ADDR_WIDTH-1:0]                cub_greg_waddr_b;
    //write enable signals for all registers
    logic [NUM_WORDS-1:0]                 cub_greg_we_a_dec;
    logic [NUM_WORDS-1:0]                 cub_greg_we_b_dec;


    assign cub_mult_lambda_o          = cub_mult_param_sel_i ? cub_greg_mem[2][15:0] : cub_greg_mem[1][15:0];
    assign cub_mult_truncate_Q_o      = cub_mult_param_sel_i ? cub_greg_mem[2][19:16] : cub_greg_mem[1][19:16];
    assign cub_arithmetic_bias_o      = cub_arithmetic_param_sel_i ? cub_greg_mem[4][31:0] : cub_greg_mem[3][31:0];
    //assign cub_arithmetic_trun_en_o   = cub_arithmetic_param_sel_i ? cub_greg_mem[6][0] : cub_greg_mem[5][0];
    //assign cub_arithmetic_trun_prec_o = cub_arithmetic_param_sel_i ? cub_greg_mem[6][1] : cub_greg_mem[5][1];
    assign cub_arithmetic_trun_Q_o    = cub_arithmetic_param_sel_i ? cub_greg_mem[6][4:0] : cub_greg_mem[5][4:0];
    assign cub_arithmetic_trun_elt_Q_o= cub_arithmetic_param_sel_i ? cub_greg_mem[16][4:0] : cub_greg_mem[15][4:0];
    assign cub_activ_prelu_scaling_o  = cub_activ_param_sel_i ? cub_greg_mem[8][15:0] : cub_greg_mem[7][15:0];
    assign cub_activ_mul_pdt_Qp_o     = cub_activ_param_sel_i ? cub_greg_mem[8][20:16] : cub_greg_mem[7][20:16];
    assign cub_activ_relu6_bias_o     = cub_activ_param_sel_i ? cub_greg_mem[10][31:0] : cub_greg_mem[9][31:0];
    assign cub_activ_relu6_ref_max_o  = cub_activ_param_sel_i ? cub_greg_mem[12][31:0] : cub_greg_mem[11][31:0];
    assign cub_activ_relu6_ref_min_o  = cub_activ_param_sel_i ? cub_greg_mem[14][31:0] : cub_greg_mem[13][31:0];

    assign cub_interconnect_reg_o       = cub_greg_mem[17][31:0];
    assign cub_interconnect_reg_ready_o = (cub_greg_we_a_dec[17] || cub_greg_we_b_dec[17]);
   // always_ff@(posedge clk or negedge rst_n) begin
   //     if(rst_n==1'b0)
   //         cub_interconnect_reg_valid_o <= 1'b0;
   //     else
   //         cub_interconnect_reg_valid_o <= (cub_greg_we_a_dec[17] || cub_greg_we_b_dec[17]);
   // end

    //============================
    //  READ Addr Dec
    //============================
    assign cub_greg_rdata_a = cub_greg_mem[cub_greg_raddr_a]; 
    assign cub_greg_rdata_b = cub_greg_mem[cub_greg_raddr_b];


    //============================
    //  WRITE Addr Dec
    //============================
    always_comb begin : rf_we_a_decoder
        foreach(cub_greg_we_a_dec[i]) begin
            cub_greg_we_a_dec[i] = (cub_greg_waddr_a==i) ? cub_greg_we_a : 1'b0;
        end
    end

    always_comb begin : we_b_decoder
        foreach(cub_greg_we_b_dec[i]) begin
            cub_greg_we_b_dec[i] = (cub_greg_waddr_b==i) ? cub_greg_we_b : 1'b0;
        end
    end


    //============================
    //  Write operation
    //============================

    //R0 is nil
    always_comb begin
        cub_greg_mem[0] = 32'b0;
    end

    //R18 is halfword max of positive number(unsigned)
    always_comb begin
        cub_greg_mem[18] = 32'hffff_ffff;
    end

    //R19 is word max of negetive number
    always_comb begin
        cub_greg_mem[19] = 32'h8000_0000;
    end

    //R20 is word max of positive number
    always_comb begin
        cub_greg_mem[20] = 32'h7fff_ffff;
    end

    //R21-R30 is cubank inter connection reg
    always_comb begin
        cub_greg_mem[21] = {cub_interconnect_top_reg_3_i};
    end
    always_comb begin
        cub_greg_mem[22] = {cub_interconnect_top_reg_2_i};
    end
    always_comb begin
        cub_greg_mem[23] = {cub_interconnect_top_reg_1_i};
    end
    always_comb begin
        cub_greg_mem[24] = {cub_interconnect_top_reg_0_i};
    end
    always_comb begin
        cub_greg_mem[25] = {cub_interconnect_bottom_reg_0_i};
    end
    always_comb begin
        cub_greg_mem[26] = {cub_interconnect_bottom_reg_1_i};
    end
    always_comb begin
        cub_greg_mem[27] = {cub_interconnect_bottom_reg_2_i};
    end
    always_comb begin
        cub_greg_mem[28] = {cub_interconnect_bottom_reg_3_i};
    end
    always_comb begin
        cub_greg_mem[29] = {cub_interconnect_side_reg_i};
    end
    always_comb begin
        cub_greg_mem[30] = {cub_interconnect_gap_reg_i};
    end

    //R31 is cubank_id
    always_comb begin
        cub_greg_mem[31] = {27'b0,cub_id_i};
    end

    //loop from 1 to 24
    genvar i;
    generate
    for (i = 1; i < 17; i++) begin : rf_gen_1_16
        always_ff @(posedge clk or negedge rst_n) begin : register_write_behavior_1_16
            if(rst_n==1'b0) begin
                cub_greg_mem[i] <= 32'b0;
            end 
            else begin //port b priority is high, need to avoid
                if(cub_greg_we_b_dec[i])
                    cub_greg_mem[i] <= cub_greg_wdata_b;
                else if(cub_greg_we_a_dec[i])
                    cub_greg_mem[i] <= cub_greg_wdata_a;
            end
        end
    end
    endgenerate


	always_ff @(posedge clk or negedge rst_n) begin : register_write_behavior_17
        if(rst_n==1'b0) begin
            cub_greg_mem[17] <= 32'b0;
        end 
        else begin //port b priority is high, need to avoid
            if(cub_greg_we_b_dec[17])
                cub_greg_mem[17] <= cub_greg_wdata_b; //from alu fu unit
            else if(cub_greg_we_a_dec[17])
                cub_greg_mem[17] <= cub_greg_wdata_a; //from mem
	   	    else if(cub_interconnect_reg_valid_i)
	   	 	    cub_greg_mem[17] <= cub_greg_mem[27];
        end
    end

endmodule
