`define REG_S1 19:15

module cub_alu_pre_decode #(
    parameter   IRAM_AWID = 8,
    parameter   IRAM_FILL_AWID = 15,
    parameter   LOOP_NUM = 4,
    parameter   BANK_NUM = 32
)
(
    input                               clk,
    input                               rst_n,

    input [31:0]                        instr_rdata_i,
    input                               instr_valid_i,

    //to sequence ctrl for fetch_ready
    input [IRAM_AWID-1:0]               cub_alu_boot_addr_i,
    input [IRAM_AWID-1:0]               alu_instr_addr_i,
    output logic [IRAM_AWID-1:0]        Cub_alu_fetch_req_addr_o,

    input                               fetch_enable_i,
    output logic                        fetch_req_o,
    input [IRAM_FILL_AWID-1:0]          pc_if_i,
    input [IRAM_FILL_AWID-1:0]          pc_id_i,
    output logic [0:0]                  pc_mux_o,
    output logic                        pc_set_o,
    output logic                        id_ready_o,

    output logic [LOOP_NUM-1:0][31:0]   loop_start_o,
    output logic [LOOP_NUM-1:0][31:0]   loop_end_o,
    output logic [LOOP_NUM-1:0][31:0]   loop_cnt_o,
    input [LOOP_NUM-1:0]                loop_cnt_dec_i,
    input                               is_loop_i,

    input [BANK_NUM/2-1:0]              Cub_alu_mask_i,
    input                               Cub_alu_mask_update_i,
    input                               Cub_alu_mask_sel_i,

    output logic                        cub_alu_fetch_end_o,
    output logic                        first_fetch_o,

    output logic [BANK_NUM-1:0][31:0]   Cub_alu_instr_o,
    output logic [BANK_NUM-1:0]         Cub_alu_instr_valid_o,
    output logic [BANK_NUM-1:0]         deassert_we_o,

    output logic                        cub_nop_state_o,

    output logic                        ALU_Cfifo_pop_o,
    input [15:0]                        ALU_Cfifo_data_i,
    input                               ALU_Cfifo_empty_i
);

    parameter ALU_PC_BOOT = 1'b0;

    logic [1:0]             loop_regid, loop_regid_int;
    logic [2:0]             loop_we, loop_we_int;
    logic                   loop_target_mux_sel;
    logic                   loop_start_mux_sel;
    logic                   loop_cnt_mux_sel;

    logic [31:0]            loop_target;
    logic [31:0]            loop_start, loop_start_int;
    logic [31:0]            loop_end;
    logic [31:0]            loop_cnt, loop_cnt_int;
    logic                   loop_valid;

    logic [31:0]            imm_iz_type;
    logic [31:0]            imm_z_type;

    logic [BANK_NUM-1:0]    Cubank_alu_mask;
    logic                   cub_event_finish;    
    logic                   sys_mask;
    logic                   nop_mask;
    logic [7:0]             cub_nop_cycle_num,cub_nop_cycle_cnt;
    logic [31:0]            instr_rdata_q;
    logic [31:0]            instr_rdata_replace;
    logic                   is_decoding_Cub_alu;
    logic                   Cfifo_stall;
    logic                   nop_ready;
    logic                   cfifo_ready;
    logic                   nop_en;
    logic                   cub_cflow_nop_en;
    logic                   cub_mask_update;
    logic                   cub_mask_sel;
    logic [15:0]            cub_mask;

    //============================
    //  main controller
    //============================

    enum logic [2:0] {IDLE, BOOT_SET, FIRST_FETCH, SLEEP, DECODE, CTRL_NOP_WAIT,CFIFO_STALL} ctrl_cs, ctrl_ns;

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            ctrl_cs <= IDLE;
        else
            ctrl_cs <= ctrl_ns;
    end

    always_comb begin
        ctrl_ns = ctrl_cs;
        fetch_req_o = 1'b1;
        pc_mux_o = ALU_PC_BOOT;
        pc_set_o = 1'b0;
        
        cub_alu_fetch_end_o = 1'b0;

        is_decoding_Cub_alu = 1'b0;
        first_fetch_o = 1'b0;

        cfifo_ready = 1'b1;

        Cub_alu_fetch_req_addr_o = alu_instr_addr_i;

        case(ctrl_cs)
            IDLE: begin //just reset, wait for fetch_enable
                fetch_req_o = 1'b0;
                if(fetch_enable_i) begin
                    ctrl_ns = BOOT_SET;
                    Cub_alu_fetch_req_addr_o = cub_alu_boot_addr_i;
                end
            end
            BOOT_SET: begin //copy boot address to instr fetch address
                pc_mux_o    = ALU_PC_BOOT;
                pc_set_o    = 1'b1;
                ctrl_ns     = FIRST_FETCH;
            end
            FIRST_FETCH: begin
                is_decoding_Cub_alu = 1'b0;
                first_fetch_o = 1'b1;
                ctrl_ns = DECODE;
            end
            DECODE: begin
                if(instr_valid_i)
                    is_decoding_Cub_alu = 1'b1;
                    
                    if(cub_nop_state_o) begin
                        is_decoding_Cub_alu = 1'b0;
                        if((cub_nop_cycle_num!='b0) && (cub_nop_cycle_num!='b1)) begin
                            ctrl_ns = CTRL_NOP_WAIT;
                            fetch_req_o = 1'b0;
                        end
                    end
                    if(cub_event_finish) begin
                        ctrl_ns = SLEEP;
                        fetch_req_o = 1'b0;                        
                        cub_alu_fetch_end_o = 1'b1;
                        is_decoding_Cub_alu = 1'b0;
                    end
                    if(Cfifo_stall) begin
                        cfifo_ready = 1'b0;
                        ctrl_ns = CFIFO_STALL;
                        is_decoding_Cub_alu = 1'b0;
                    end
            end
            CTRL_NOP_WAIT: begin
                fetch_req_o = 1'b0;
                if(nop_ready) begin
                    ctrl_ns = DECODE;
                    fetch_req_o = 1'b1;
                end
            end
            CFIFO_STALL: begin
                fetch_req_o = 1'b0;
                cfifo_ready = 1'b0;
                if(!ALU_Cfifo_empty_i) begin
                    ctrl_ns = DECODE;
                    fetch_req_o = 1'b1;
                    cfifo_ready = 1'b1;
                end
            end
            SLEEP: begin //need wait cycles?!!
                fetch_req_o = 1'b0;
                ctrl_ns     = IDLE;
            end
        endcase
    end
    

    //update cub alu mask
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) 
            Cubank_alu_mask <= 32'b0;
        else if(Cub_alu_mask_update_i && (ctrl_cs==IDLE || ctrl_cs==BOOT_SET || ctrl_cs==FIRST_FETCH || ctrl_cs==SLEEP))
            Cubank_alu_mask <= Cub_alu_mask_sel_i ? {Cub_alu_mask_i[15:0],Cubank_alu_mask[15:0]} : {Cubank_alu_mask[31:16],Cub_alu_mask_i[15:0]};
        else if(cub_mask_update)
            Cubank_alu_mask <= cub_mask_sel ? {cub_mask[15:0],Cubank_alu_mask[15:0]} : {Cubank_alu_mask[31:16],cub_mask[15:0]};
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin 
            instr_rdata_q <= 32'b0;
        end
        else if(!cub_nop_state_o) begin
            instr_rdata_q <= ALU_Cfifo_pop_o ? instr_rdata_replace : instr_rdata_i;
        end
    end

    assign instr_rdata_replace = {ALU_Cfifo_data_i,instr_rdata_i[15:0]};
    assign Cub_alu_instr_o = ALU_Cfifo_pop_o ? {32{instr_rdata_replace}} : (cub_nop_state_o==1'b1 && cub_cflow_nop_en==1'b0) ? {32{instr_rdata_q}} : {32{instr_rdata_i}};
    assign Cub_alu_instr_valid_o = {32{instr_valid_i}} & (~Cubank_alu_mask) & {32{~sys_mask}} & {32{~nop_mask}};
    //assign deassert_we_o = /*{32{instr_valid_i}}*/ & (~Cubank_alu_mask) & {32{(~is_decoding_Cub_alu) | sys_mask}};
    assign deassert_we_o = (~Cubank_alu_mask) & {32{(~is_decoding_Cub_alu) | sys_mask}};

    assign imm_iz_type = {20'b0, instr_rdata_i[31:20]};
    assign imm_z_type  = {27'b0, instr_rdata_i[`REG_S1]};


    //============================
    //  loop regs
    //============================

    // loop register id
    assign loop_regid_int = instr_rdata_i[8:7];   //rd contains loop register id

    // loop target mux
    always_comb begin
      case (loop_target_mux_sel)
        1'b0: loop_target = {{(32-IRAM_FILL_AWID){1'b0}},pc_id_i} + imm_iz_type[31:0]/*{imm_iz_type[30:0], 1'b0}*/;
        1'b1: loop_target = {{(32-IRAM_FILL_AWID){1'b0}},pc_id_i} + imm_z_type[31:0]/*{imm_z_type[30:0], 1'b0}*/;
      endcase
    end

    // loop start mux
    always_comb begin
      case (loop_start_mux_sel)
        1'b0: loop_start_int = loop_target; //for PC + I imm
        1'b1: loop_start_int = {{(32-IRAM_FILL_AWID){1'b0}},pc_if_i}; //for next PC
      endcase
    end

    // loop cnt mux
    always_comb begin : loop_cnt_mux
      //case (loop_cnt_mux_sel)
      //  1'b0: loop_cnt_int = imm_iz_type;
      //  1'b1: loop_cnt_int = operand_a_fw_id;
      //endcase;
      loop_cnt_int = imm_iz_type;
    end

    //assign loop_we_masked = loop_we_int/* & ~{3{loop_mask}} & {3{nop_ready}}*/;

    //multiplex between access from instructions and access via CSR registers
    assign loop_start = loop_we_int[0] ? loop_start_int : 'b0;
    assign loop_end   = loop_we_int[1] ? loop_target    : 'b0;
    assign loop_cnt   = loop_we_int[2] ? loop_cnt_int   : 'b0;
    assign loop_regid = (|loop_we_int) ? loop_regid_int : 'b0;
    assign loop_we    = loop_we_int;

    always_comb begin
        loop_start_mux_sel  = 1'b0;
        loop_target_mux_sel = 1'b0;
        loop_cnt_mux_sel    = 1'b0;
        loop_we_int         = 3'b0;
        
        sys_mask            = 1'b0;
        cub_event_finish    = 1'b0;

        cub_nop_state_o     = 1'b0;
        cub_nop_cycle_num   = 8'b0;
        cub_cflow_nop_en    = 1'b0;
        nop_mask = 1'b0;

        ALU_Cfifo_pop_o     = 1'b0;
        Cfifo_stall         = 1'b0;

        cub_mask_update     = 1'b0;
        cub_mask_sel        = 1'b0;
        cub_mask            = 16'b0;        

        if(instr_rdata_i[0] == 1'b0) begin
            if(instr_rdata_i[2:1] == 2'b10) begin //Ctrl
                case(instr_rdata_i[14:12])
                    3'b000: begin //cub.lci rd
                        if(!ALU_Cfifo_empty_i)
                            ALU_Cfifo_pop_o = 1'b1;
                        else begin
                            Cfifo_stall = 1'b1;
                            sys_mask = 1'b1;
                        end
                    end
                    3'b001: begin //cub.event_finish
                        cub_event_finish = 1'b1;
                        sys_mask = 1'b1;
                    end
                    3'b010: begin //cub.nop
                        cub_nop_state_o = 1'b1;
                        cub_nop_cycle_num = instr_rdata_i[22:15];
                        nop_mask = 1'b1;
                    end
                    3'b011: begin //cub.cflow_nop
                        cub_nop_state_o = 1'b1;
                        cub_nop_cycle_num = instr_rdata_i[22:15];
                        cub_cflow_nop_en = 1'b1;
                    end
                    3'b100: begin //cub.alu_mask
                        cub_mask_update = 1'b1;
                        cub_mask_sel = instr_rdata_i[15];
                        cub_mask = instr_rdata_i[31:16];
                    end
                endcase
            end
            else begin//Hwloop
                sys_mask = 1'b1;
                case (instr_rdata_i[14:12])
                  3'b000: begin
                    // lp.starti L,uimmL, lpstart[L] = PC + (uimmL << 1) : set start address to PC + I-type immediate
                    loop_we_int[0]     = 1'b1;
                    loop_start_mux_sel = 1'b0;
                  end

                  3'b001: begin
                    // lp.endi L,uimmL, lpend[L] = PC + (uimmL << 1) : set end address to PC + I-type immediate
                    loop_we_int[1]     = 1'b1;
                  end

                  //3'b010: begin
                  //  // lp.count L,rs1, lpcount[L] = rs1 : initialize counter from rs1
                  //  loop_we_int[2]     = 1'b1;
                  //  loop_cnt_mux_sel   = 1'b1;
                  //  rega_used_o        = 1'b1;
                  //end

                  3'b011: begin
                    // lp.counti L,uimmL, lpcount[L] = uimmL : initialize counter from I-type immediate
                    loop_we_int[2]     = 1'b1;
                    loop_cnt_mux_sel   = 1'b0;
                  end

                  //3'b100: begin
                  //  // lp.setup L,rs1,uimmL : initialize counter from rs1, set start address to next instruction and end address to PC + I-type immediate
                  //  /* lpstart[L] = pc + 4
                  //     lpend[L] = pc + (uimmL << 1)
                  //     lpcount[L] = rs1 */
                  //  loop_we_int        = 3'b111;
                  //  loop_start_mux_sel = 1'b1;
                  //  loop_cnt_mux_sel   = 1'b1;
                  //  rega_used_o        = 1'b1;
                  //end

                  3'b101: begin
                    // lp.setupi: initialize counter from immediate, set start address to next instruction and end address to PC + I-type immediate
                    /* lpstart[L] = pc + 4
                       lpend[L] = pc + (uimmS << 1)
                       lpcount[L] = uimmL */
                    loop_we_int         = 3'b111;
                    loop_start_mux_sel  = 1'b1;
                    loop_target_mux_sel = 1'b1;
                    loop_cnt_mux_sel    = 1'b0;
                  end
                  //default:;
                endcase
            end
        end
    end

    riscv_hwloop_regs
    #(
        .HWLP_NUM(LOOP_NUM)
    )
    U_cub_alu_loop_regs
    (
        .clk                   ( clk                       ),
        .rst_n                 ( rst_n                     ),
        //from ID
        .hwlp_start_data_i     ( loop_start                ),
        .hwlp_end_data_i       ( loop_end                  ),
        .hwlp_cnt_data_i       ( loop_cnt                  ),
        .hwlp_we_i             ( loop_we                   ),
        .hwlp_regid_i          ( loop_regid                ),
        //from controller
        .valid_i               ( loop_valid                ),
        //from hwloop controller
        .hwlp_cnt_dec_i        ( loop_cnt_dec_i            ),
        //to hwloop controller
        .hwlp_start_addr_o     ( loop_start_o              ),
        .hwlp_end_addr_o       ( loop_end_o                ),
        .hwlp_counter_o        ( loop_cnt_o                )
    ); 

    assign loop_valid = instr_valid_i & is_loop_i;

    //cub nop cycle cnt
    //always_ff @(posedge clk or negedge rst_n) begin
    //    if(!rst_n)
    //        cub_nop_cycle_cnt <= 'b0;
    //    else if(cub_nop_cycle_cnt != 'b0)
    //        cub_nop_cycle_cnt <= cub_nop_cycle_cnt - 1;            
    //    else if(nop_en && cub_nop_cycle_num!='b0)
    //        cub_nop_cycle_cnt <= cub_nop_cycle_num - 1;
    //end
    //
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            cub_nop_cycle_cnt <= 'b0;
        else if(cub_nop_cycle_cnt == cub_nop_cycle_num-1)
            cub_nop_cycle_cnt <= 'b0;            
        else if(nop_en)
            cub_nop_cycle_cnt <= cub_nop_cycle_cnt + 1;
    end

    enum logic [1:0] {NOP_IDLE, NOP_WAIT} nop_ns,nop_cs;

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            nop_cs <= NOP_IDLE;
        else
            nop_cs <= nop_ns;
    end
    
    always_comb begin
        nop_ns = nop_cs;
        nop_ready = 1'b1;
        nop_en = 1'b0;
        //nop_state = 1'b0;
        
        case(nop_cs)
            NOP_IDLE: begin
                nop_ready = 1'b1;

                if(cub_nop_state_o & ((cub_nop_cycle_num!='b0) && (cub_nop_cycle_num!='b1))) begin
                    nop_en = 1'b1;
                    nop_ready = 1'b0;
                    nop_ns = NOP_WAIT;
                end
            end
            NOP_WAIT: begin
                nop_ready = 1'b0;
                nop_en = 1'b1;
                //nop_state = 1'b1;
                if(cub_nop_cycle_cnt==cub_nop_cycle_num-1) begin
                    nop_ready = 1'b1;
                    nop_en = 1'b0;
                    nop_ns = NOP_IDLE;
                end
            end
        endcase
    end

    assign id_ready_o = nop_ready & cfifo_ready;
endmodule
