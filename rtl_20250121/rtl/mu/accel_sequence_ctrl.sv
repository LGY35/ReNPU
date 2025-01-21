module accel_sequence_ctrl #(
    parameter   MQ_DEPTH = 8,
    parameter   VQ_DEPTH = 8,
    parameter   SQ_DEPTH = 4,
    parameter   IRAM_AWID = 8,
    parameter   IRAM_FILL_AWID = 15,
    parameter   BANK_NUM = 32
)(
    input                               clk,
    input                               rst_n,

    input                               npu_req_i,
    input  [31:0]                       instr_npu_i,

    //to Cub alu
    output logic                        Cub_alu_insn_fill_state_o,
    output logic                        Cub_alu_insn_fill_stall_o,
    output logic [IRAM_AWID-1:0]        Cub_alu_insn_fill_addr_o,
    output logic [31:0]                 Cub_alu_insn_o,

    input                               VQ_alu_event_call_i,
    input  [IRAM_AWID-1:0]              VQ_alu_event_addr_i,
    output logic                        VQ_alu_event_finish_o,

    //from/to alu_id_stage
    output logic                        Cub_alu_fetch_req_o, 
    output logic [IRAM_AWID-1:0]        Cub_alu_boot_addr_o, 
    input                               Cub_alu_fetch_end_i,
    input [IRAM_AWID-1:0]               Cub_alu_fetch_req_addr_i,

    output logic [BANK_NUM/2-1:0]       Cub_alu_mask_o, //1:bank valid 0:bank invalid
    output logic                        Cub_alu_mask_update_o,
    output logic                        Cub_alu_mask_sel_o, 

    output logic [BANK_NUM-1:0]         VQ_disp_cubank_mask_o,

    //from riscv ID
    input                               is_MQ_insn_i,
    input                               is_VQ_insn_i,
    input                               is_SQ_insn_i,
    input                               is_Cub_alu_insn_i,
    //to riscv ID
    output logic                        MQ_ready_o,
    output logic                        VQ_ready_o,
    output logic                        SQ_ready_o,
    output logic                        Cub_alu_ready_o,

    //from/to Cons FIFO 
    output logic                        MQ_Cfifo_pop_o,
    input [31:0]                        MQ_Cfifo_data_i,
    input                               MQ_Cfifo_empty_i,

    output logic                        VQ_Cfifo_pop_o,
    input [31:0]                        VQ_Cfifo_data_i,
    input                               VQ_Cfifo_empty_i,

    output logic                        SQ_Cfifo_pop_o,
    input [31:0]                        SQ_Cfifo_data_i,
    input                               SQ_Cfifo_empty_i,

    //from/to accel_dispatch unit
    input                               MQ_disp_ready_i,
    input                               VQ_disp_ready_i,
    input                               SQ_disp_ready_i,

    output logic                        MQ_disp_req_o,
    output logic                        MQ_disp_cfifo_en_o,
    output logic [31:0]                 MQ_disp_cfifo_data_o,

    output logic [3:0]                  VQ_disp_req_o,
    output logic [3:0]                  VQ_disp_cfifo_en_o,
    output logic [3:0][31:0]            VQ_disp_cfifo_data_o,

    output logic                        SQ_disp_req_o,
    output logic                        SQ_disp_cfifo_en_o,
    output logic [31:0]                 SQ_disp_cfifo_data_o,
     

    //to accel_decode unit
    output logic [31:7]                 MQ_disp_instr_dec_o,
    output logic [3:0][31:7]            VQ_disp_instr_dec_o,
    output logic [31:7]                 SQ_disp_instr_dec_o,

    output logic [2:0]                  MQ_disp_func_o,
    output logic [3:0][1:0]             VQ_disp_func_o,
    output logic                        SQ_disp_func_o,

    input                               MQ_clear_i,
    input                               VQ_clear_i,
    input                               SQ_clear_i
);

    `include "npu_decode_param.v"

    localparam  BAR_NUM = 6;
    localparam  BAR_SET = 1'b1;
    localparam  BAR_CLR = 1'b0;

    localparam  BAR_FIRST = 1'b1;
    localparam  BAR_SEC   = 1'b0;

    localparam  CUB_ALU_INSN_FILL   = 2'b00;
    localparam  CUB_ALU_EVENT_CALL  = 2'b01;
    localparam  CHK_ALU_EVENT_FINISH= 2'b10;
    localparam  CUB_ALU_MASK        = 2'B11;


    logic [31:0] instr;
    assign instr = instr_npu_i;

    //Queue Fifo
    logic               MQ_push,VQ_push,SQ_push;
    logic               MQ_pop,VQ_pop,SQ_pop;
    logic               MQ_full,VQ_full,SQ_full,MQ_afull,VQ_afull,SQ_afull;
    logic               MQ_empty,VQ_empty,SQ_empty;

    logic               MQ_req_bar_en;
    logic [2:0]         MQ_req_bar_id;
    enum logic [2:0]    {OP_MQ_CFG, OP_MQ_LOAD, OP_MQ_STORE, OP_MQ_MV, OP_MQ_NOC_CFG, OP_MQ_NOC, OP_MQ_NOP, OP_MQ_HLOAD} MQ_req_func, MQ_disp_func;
    logic               MQ_req_use_cfifo;
    
    logic               MQ_disp_bar_en;
    logic               MQ_disp_bar_first;
    logic [2:0]         MQ_disp_bar_id;
    //logic [2:0]         MQ_disp_func;
    logic               MQ_disp_use_cfifo;
    logic [31:7]        MQ_disp_instr;

    logic [31:7]        MQ_disp_instr_q;
    logic [2:0]         MQ_disp_func_q;
    logic               MQ_disp_use_cfifo_q;
    logic               MQ_disp_bar_en_q;
    logic [2:0]         MQ_disp_bar_id_q;
    logic               MQ_disp_bar_first_q;
    
    logic               VQ_req_bar_en;
    logic [2:0]         VQ_req_bar_id;
    enum logic [1:0]    {OP_VQ_ALU_CFG, OP_VQ_VEC_CFG, OP_VQ_MAC, OP_VQ_ALU} VQ_req_func, VQ_disp_func;
    logic               VQ_req_use_cfifo;
    logic               VQ_req_is_alu_event_call;
    logic               VQ_req_cubank_mask;

    logic               VQ_req_alu_event_call_iram_sel;
    logic               VQ_req_alu_event_call_iram_lock_en;

    logic               VQ_disp_bar_en;
    logic               VQ_disp_bar_first;
    logic [2:0]         VQ_disp_bar_id;
    //logic [1:0]         VQ_disp_func;
    logic               VQ_disp_use_cfifo;
    logic               VQ_disp_is_alu_event_call;
    logic [31:7]        VQ_disp_instr;

    logic [3:0][31:7]   VQ_disp_instr_q;
    logic [3:0][1:0]    VQ_disp_func_q;
    logic               VQ_disp_use_cfifo_q;
    logic               VQ_disp_is_alu_event_call_q;
    logic               VQ_disp_bar_en_q;
    logic [2:0]         VQ_disp_bar_id_q; 
    logic               VQ_disp_bar_first_q;

    logic               SQ_req_bar_en;
    logic [2:0]         SQ_req_bar_id;
    enum logic          {OP_SQ} SQ_req_func,SQ_disp_func;
    logic               SQ_req_use_cfifo;
    
    logic               SQ_disp_bar_en;
    logic               SQ_disp_bar_first;
    logic [2:0]         SQ_disp_bar_id;
    //logic               SQ_disp_func;
    logic               SQ_disp_use_cfifo;
    logic [31:7]        SQ_disp_instr;

    logic [31:7]        SQ_disp_instr_q;
    logic               SQ_disp_func_q;
    logic               SQ_disp_use_cfifo_q;
    logic               SQ_disp_bar_en_q;
    logic [2:0]         SQ_disp_bar_id_q;
    logic               SQ_disp_bar_first_q;

    //disp req
    logic                       MQ_disp_req;
    logic                       VQ_disp_req;
    logic                       SQ_disp_req;

    //VQ_cubank_mask
    logic                       VQ_disp_cubank_mask;
    logic                       cubank_mask_sel;
    logic [BANK_NUM/2-1:0]      cubank_mask;

    //BAR
    logic                       req_bar_en;
    logic [2:0]                 req_bar_id; //0-6
    logic                       req_bar_first;
    logic                       MQ_disp_bar_halt;
    logic                       VQ_disp_bar_halt;
    logic                       SQ_disp_bar_halt;

    logic [BAR_NUM-1:0]         bar_wr_accel_req;
    logic [BAR_NUM-1:0]         bar_wr_MQ;
    logic [BAR_NUM-1:0]         bar_wr_VQ;
    logic [BAR_NUM-1:0]         bar_wr_SQ;
    logic [BAR_NUM-1:0]         bar_wr_en;
    logic [BAR_NUM-1:0]         bar_set_or_clr;
    logic [BAR_NUM-1:0]         bar_status_q;
    logic [BAR_NUM-1:0]         req_bar_type;
    logic [BAR_NUM-1:0]         bar_status_type;
    logic [BAR_NUM-1:0]         bar_wr_accel_req_ready;
    logic [BAR_NUM-1:0]         MQ_disp_bar_flag;
    logic [BAR_NUM-1:0]         VQ_disp_bar_flag;
    logic [BAR_NUM-1:0]         SQ_disp_bar_flag;
    

    enum logic [1:0] {IDLE, WAIT_CFIFO, WAIT_BAR_HALT} MQ_CS, MQ_NS, VQ_CS, VQ_NS, SQ_CS, SQ_NS;
    //enum logic [1:0] {IDLE, WAIT_CFIFO, WAIT_BAR_HALT} VQ_CS, VQ_NS;
    //enum logic [1:0] {IDLE, WAIT_CFIFO, WAIT_BAR_HALT} SQ_CS, SQ_NS;

    //============Queue============
    assign MQ_push = npu_req_i && is_MQ_insn_i && MQ_ready_o;//~MQ_full;
    assign VQ_push = npu_req_i && is_VQ_insn_i && VQ_ready_o;//~VQ_full;
    assign SQ_push = npu_req_i && is_SQ_insn_i && SQ_ready_o;//~SQ_full;

    assign MQ_ready_o = ~MQ_full && (is_MQ_insn_i & MQ_req_bar_en & req_bar_first ? bar_wr_accel_req_ready[MQ_req_bar_id] : 1'b1); //afull
    assign VQ_ready_o = ~VQ_full && (is_VQ_insn_i & VQ_req_bar_en & req_bar_first ? bar_wr_accel_req_ready[VQ_req_bar_id] : 1'b1);
    assign SQ_ready_o = ~SQ_full && (is_SQ_insn_i & SQ_req_bar_en & req_bar_first ? bar_wr_accel_req_ready[SQ_req_bar_id] : 1'b1);

    wire MQ_pop_ready = MQ_disp_ready_i && (MQ_CS==IDLE);
    wire VQ_pop_ready = VQ_disp_ready_i && (VQ_CS==IDLE);
    wire SQ_pop_ready = SQ_disp_ready_i;

    assign MQ_pop = MQ_pop_ready && ~MQ_empty/* && ~MQ_disp_req_o*/;
    assign VQ_pop = VQ_pop_ready && ~VQ_empty/* && ~VQ_disp_req_o*/;
    assign SQ_pop = SQ_pop_ready && ~SQ_empty/* && ~SQ_disp_req_o*/;


    //============BAR CHECK============

    assign req_bar_en = npu_req_i && (MQ_req_bar_en | VQ_req_bar_en | SQ_req_bar_en);
    assign req_bar_id = MQ_req_bar_en ? MQ_req_bar_id : VQ_req_bar_en ? VQ_req_bar_id : SQ_req_bar_en ? SQ_req_bar_id : 'b0;
    //assign req_bar_masked = req_bar_en ? |((1<<<req_bar_id)&bar_status_q[BAR_NUM-1:0]) : 1'b1;
    assign req_bar_first = req_bar_en ? (req_bar_type[req_bar_id]==BAR_FIRST) : 1'b0;

    genvar i;
    generate
    for(i = 0; i < BAR_NUM; i = i + 1) begin : BAR_CHEAK

        assign bar_wr_accel_req[i] = (req_bar_id==i)&&(MQ_push | VQ_push | SQ_push) ? req_bar_first : 1'b0; //check and set bar when insn is first coming
        assign bar_wr_MQ[i] = (MQ_disp_bar_id_q==i) && MQ_disp_bar_first_q && MQ_pop_ready; //clr bar when insn is excuted done
        assign bar_wr_VQ[i] = (VQ_disp_bar_id_q==i) && VQ_disp_bar_first_q && VQ_pop_ready; //clr bar when insn is excuted done
        assign bar_wr_SQ[i] = (SQ_disp_bar_id_q==i) && SQ_disp_bar_first_q && SQ_pop_ready; //clr bar when insn is excuted done
        assign bar_wr_en[i] = bar_wr_accel_req[i] | bar_wr_MQ[i] | bar_wr_VQ[i] | bar_wr_SQ[i];
        assign bar_set_or_clr[i] = bar_wr_accel_req[i] ? BAR_SET : BAR_CLR;

        always_ff @(posedge clk or negedge rst_n) begin
            if(!rst_n) begin
                bar_status_q[i] <= 1'b0;
            end
            else if(bar_wr_en[i]) begin
                bar_status_q[i] <= bar_set_or_clr[i];
            end
        end

        always_ff @(posedge clk or negedge rst_n) begin
            if(!rst_n) begin
                req_bar_type[i] <= BAR_FIRST;
            end
            else if(req_bar_en && req_bar_id==i && (MQ_push | VQ_push | SQ_push)) begin
                req_bar_type[i] <= req_bar_type[i] + 1'b1;
            end
        end

        always_ff @(posedge clk or negedge rst_n) begin
            if(!rst_n) begin
                bar_status_type[i] <= 1'b0;
            end
            else if(bar_wr_accel_req[i] || VQ_disp_bar_flag[i] || MQ_disp_bar_flag[i] || SQ_disp_bar_flag[i]) begin
                bar_status_type[i] <= bar_status_type[i] + 1'b1; //bar status type: 1: bar busy 0: bar clear
            end
        end        

        assign VQ_disp_bar_flag[i] = VQ_disp_req && (VQ_CS==IDLE ? (VQ_disp_bar_en && ~VQ_disp_bar_first && VQ_disp_bar_id==i) : (VQ_disp_bar_en_q && ~VQ_disp_bar_first_q && VQ_disp_bar_id_q==i));
        assign MQ_disp_bar_flag[i] = MQ_disp_req && (MQ_CS==IDLE ? (MQ_disp_bar_en && ~MQ_disp_bar_first && MQ_disp_bar_id==i) : (MQ_disp_bar_en_q && ~MQ_disp_bar_first_q && MQ_disp_bar_id_q==i));
        assign SQ_disp_bar_flag[i] = SQ_disp_req && (SQ_CS==IDLE ? (SQ_disp_bar_en && ~SQ_disp_bar_first && SQ_disp_bar_id==i) : (SQ_disp_bar_en_q && ~SQ_disp_bar_first_q && SQ_disp_bar_id_q==i));

        assign bar_wr_accel_req_ready[i] = (bar_status_type[i] == 1'b0);
    end
    endgenerate
    

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            MQ_CS <= IDLE;
            VQ_CS <= IDLE;
            SQ_CS <= IDLE;
        end
        else begin
            MQ_CS <= MQ_NS;
            VQ_CS <= VQ_NS;
            SQ_CS <= SQ_NS;
        end
    end


    //============MQ Queue============
    DW_fifo_s1_sf #(.width(1+1+3+3+1+32-7), .depth(MQ_DEPTH), .err_mode(0), .rst_mode(0))
    U_Mem_queue(
        .clk        (clk),
        .rst_n      (rst_n),
        .push_req_n (!MQ_push),
        .pop_req_n  (!MQ_pop),
        .diag_n     (!MQ_clear_i),
        .empty(MQ_empty),
        .almost_empty(),
        .half_full(),
        .almost_full(MQ_afull),
        .full(MQ_full),
        .error(MQ_err),
        .data_in({MQ_req_bar_en,req_bar_first,
                  MQ_req_bar_id,
                  MQ_req_func,
                  MQ_req_use_cfifo,
                  instr_npu_i[31:7]}),
        .data_out({MQ_disp_bar_en,MQ_disp_bar_first,
                   MQ_disp_bar_id,
                   MQ_disp_func,
                   MQ_disp_use_cfifo,
                   MQ_disp_instr})
    );

    assign MQ_disp_bar_halt = MQ_disp_bar_en && (~MQ_disp_bar_first) && (bar_status_q[MQ_disp_bar_id] == 1'b1);


    //MQ_pop
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            MQ_disp_instr_q <= 'b0;
            MQ_disp_func_q <= 'b0;
            MQ_disp_use_cfifo_q <= 1'b0;
            MQ_disp_bar_en_q <= 1'b0;
            MQ_disp_bar_id_q <= 3'b0;
            MQ_disp_bar_first_q <= 1'b0;
        end
        else if(MQ_pop) begin
            MQ_disp_instr_q <= MQ_disp_instr;
            MQ_disp_func_q <= MQ_disp_func;
            MQ_disp_use_cfifo_q <= MQ_disp_use_cfifo;
            MQ_disp_bar_en_q <= MQ_disp_bar_en;
            MQ_disp_bar_id_q <= MQ_disp_bar_id;
            MQ_disp_bar_first_q <= MQ_disp_bar_first;
        end
    end
    assign MQ_disp_instr_dec_o = MQ_disp_instr_q;
    assign MQ_disp_func_o = MQ_disp_func_q;

    //MQ_dispatch
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            MQ_disp_req_o <= 'b0;
        else if(MQ_disp_req)
            MQ_disp_req_o <= 1'b1;
        else if(MQ_disp_ready_i) begin
            MQ_disp_req_o <= 1'b0;
        end
    end

    //MQ_Cfifo_pop
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin 
            MQ_disp_cfifo_en_o <= 1'b0;
            MQ_disp_cfifo_data_o <= 'b0;
        end
        else if(MQ_Cfifo_pop_o) begin
            MQ_disp_cfifo_en_o <= 1'b1;
            MQ_disp_cfifo_data_o <= MQ_Cfifo_data_i;
        end
        else if(MQ_disp_ready_i) begin
            MQ_disp_cfifo_en_o <= 1'b0;
            MQ_disp_cfifo_data_o <= 32'b0;
        end
    end

    //==========MQ FSM==========
    always_comb begin
        MQ_NS = MQ_CS;
        
        MQ_disp_req = 1'b0;
        MQ_Cfifo_pop_o = 1'b0;

        case(MQ_CS)
            IDLE: begin
                if(MQ_pop) begin //disp unit free, and MQ insn valid
                    if(MQ_disp_bar_halt) begin //check bar
                        MQ_NS = WAIT_BAR_HALT;
                    end
                    else if(MQ_disp_use_cfifo==1) begin
                        if(MQ_Cfifo_empty_i) begin
                            MQ_NS = WAIT_CFIFO;
                        end
                        else begin
                            MQ_Cfifo_pop_o = 1'b1;
                            MQ_disp_req = 1'b1;
                        end
                    end
                    else begin
                        MQ_disp_req = 1'b1;
                    end                    
                end
            end
            WAIT_CFIFO: begin
                MQ_Cfifo_pop_o = ~MQ_Cfifo_empty_i;
                if(MQ_Cfifo_pop_o) begin
                    MQ_disp_req = 1'b1;
                    MQ_NS = IDLE;
                end
            end
            WAIT_BAR_HALT: begin
                if(bar_status_q[MQ_disp_bar_id_q] == 1'b0) begin //can disp
                    if(MQ_disp_use_cfifo_q) begin
                        if(MQ_Cfifo_empty_i) begin
                            MQ_NS = WAIT_CFIFO;
                        end
                        else begin
                            MQ_disp_req = 1'b1;
                            MQ_Cfifo_pop_o = 1'b1;
                            MQ_NS = IDLE;
                        end
                    end
                    else begin
                        MQ_disp_req = 1'b1;
                        MQ_NS = IDLE;
                    end
                end
            end

            default: MQ_NS = IDLE;
        endcase
    end



    //============VQ Queue============
    DW_fifo_s1_sf #(.width(1+1+3+2+1+1+1+32-7), .depth(VQ_DEPTH), .err_mode(0), .rst_mode(0))
    U_Vector_queue(
        .clk        (clk),
        .rst_n      (rst_n),
        .push_req_n (!VQ_push),
        .pop_req_n  (!VQ_pop),
        .diag_n     (!VQ_clear_i),
        .empty(VQ_empty),
        .almost_empty(),
        .half_full(),
        .almost_full(VQ_afull),
        .full(VQ_full),
        .error(VQ_err),
        .data_in({VQ_req_bar_en,req_bar_first,
                  VQ_req_bar_id,
                  VQ_req_func,
                  VQ_req_use_cfifo,
                  VQ_req_is_alu_event_call,
                  VQ_req_cubank_mask,
                  instr_npu_i[31:7]}),
        .data_out({VQ_disp_bar_en,VQ_disp_bar_first,
                   VQ_disp_bar_id,
                   VQ_disp_func,
                   VQ_disp_use_cfifo,
                   VQ_disp_is_alu_event_call,
                   VQ_disp_cubank_mask,
                   VQ_disp_instr})
    );

    assign VQ_disp_bar_halt = VQ_disp_bar_en && (~VQ_disp_bar_first) && (bar_status_q[VQ_disp_bar_id] == 1'b1);
     

    //VQ_pop
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            VQ_disp_use_cfifo_q <= 1'b0;
            VQ_disp_bar_en_q <= 1'b0;
            VQ_disp_bar_id_q <= 3'b0;
            VQ_disp_bar_first_q <= 1'b0;
        end
        else if(VQ_pop) begin
            VQ_disp_use_cfifo_q <= VQ_disp_use_cfifo;
            VQ_disp_bar_en_q <= VQ_disp_bar_en;
            VQ_disp_bar_id_q <= VQ_disp_bar_id;
            VQ_disp_bar_first_q <= VQ_disp_bar_first;
        end
    end

 
    //VQ_pop
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            VQ_disp_instr_q <= 'b0;
            VQ_disp_func_q <= 'b0;
        end
        else if(VQ_pop) begin
            VQ_disp_instr_q <= {4{VQ_disp_instr}};
            VQ_disp_func_q <= {4{VQ_disp_func}};
            VQ_disp_is_alu_event_call_q <= VQ_disp_is_alu_event_call;
        end
    end

    //VQ_dispatch
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            VQ_disp_req_o <= 4'b0;
        else if(VQ_disp_req)
            VQ_disp_req_o <= {4{1'b1}};
        else if(VQ_disp_ready_i) begin
            VQ_disp_req_o <= 4'b0;
        end
    end

    assign VQ_disp_instr_dec_o = VQ_disp_instr_q;
    assign VQ_disp_func_o = VQ_disp_func_q;

    //VQ_Cfifo_pop
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin 
            VQ_disp_cfifo_en_o <= 4'b0;
            VQ_disp_cfifo_data_o <= {4{32'b0}};
        end
        else if(VQ_Cfifo_pop_o) begin
            VQ_disp_cfifo_en_o <= {4{1'b1}};
            VQ_disp_cfifo_data_o <= {4{VQ_Cfifo_data_i}};
        end
        else if(VQ_disp_ready_i) begin
            VQ_disp_cfifo_en_o <= 4'b0;
            VQ_disp_cfifo_data_o <= {4{32'b0}};
        end
    end

    assign cubank_mask_sel = VQ_disp_instr[23];
    assign cubank_mask = VQ_disp_instr[22:7];

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin 
            VQ_disp_cubank_mask_o <= 32'b0;
        end
        else if(VQ_disp_cubank_mask)begin
            VQ_disp_cubank_mask_o <= cubank_mask_sel ? {cubank_mask[15:0],VQ_disp_cubank_mask_o[15:0]} : {VQ_disp_cubank_mask_o[31:16],cubank_mask[15:0]};
        end
    end


    //==========VQ FSM==========
    always_comb begin
        VQ_NS = VQ_CS;
        
        VQ_disp_req = 1'b0;
        VQ_Cfifo_pop_o = 1'b0;

        case(VQ_CS)
            IDLE: begin
                if(VQ_pop) begin //disp unit free, and VQ insn valid
                    if(VQ_disp_cubank_mask) begin
                        VQ_NS = VQ_CS;
                    end
                    else if(VQ_disp_bar_halt) begin //check bar
                        VQ_NS = WAIT_BAR_HALT;
                    end
                    else if(VQ_disp_use_cfifo==1) begin
                        if(VQ_Cfifo_empty_i) begin
                            VQ_NS = WAIT_CFIFO;
                        end
                        else begin
                            VQ_Cfifo_pop_o = 1'b1;
                            VQ_disp_req = 1'b1;
                        end
                    end
                    else begin
                        VQ_disp_req = 1'b1;
                    end
                end
            end
            WAIT_CFIFO: begin
                VQ_Cfifo_pop_o = ~VQ_Cfifo_empty_i;
                if(VQ_Cfifo_pop_o) begin
                    VQ_disp_req = 1'b1;
                    VQ_NS = IDLE;
                end
            end
            WAIT_BAR_HALT: begin
                if(bar_status_q[VQ_disp_bar_id_q] == 1'b0) begin //can disp
                    if(VQ_disp_use_cfifo_q) begin
                        if(VQ_Cfifo_empty_i) begin
                            VQ_NS = WAIT_CFIFO;
                        end
                        else begin
                            VQ_Cfifo_pop_o = 1'b1;
                            VQ_disp_req = 1'b1;
                            VQ_NS = IDLE;
                        end
                    end
                    else begin
                        VQ_disp_req = 1'b1;
                        VQ_NS = IDLE;
                    end
                end
            end

            default: VQ_NS = IDLE;
        endcase
    end
  


    //============SQ Queue============
    DW_fifo_s1_sf #(.width(1+1+3+1+1+32-7), .depth(SQ_DEPTH), .err_mode(0), .rst_mode(0))
    U_Special_function_queue(
        .clk        (clk),
        .rst_n      (rst_n),
        .push_req_n (!SQ_push),
        .pop_req_n  (!SQ_pop),
        .diag_n     (!SQ_clear_i),
        .empty(SQ_empty),
        .almost_empty(),
        .half_full(),
        .almost_full(SQ_afull),
        .full(SQ_full),
        .error(SQ_err),
        .data_in({SQ_req_bar_en,req_bar_first,
                  SQ_req_bar_id,
                  SQ_req_func,
                  SQ_req_use_cfifo,
                  instr_npu_i[31:7]}),
        .data_out({SQ_disp_bar_en,SQ_disp_bar_first,
                   SQ_disp_bar_id,
                   SQ_disp_func,
                   SQ_disp_use_cfifo,
                   SQ_disp_instr})
    );

    assign SQ_disp_bar_halt = SQ_disp_bar_en && (~SQ_disp_bar_first) && (bar_status_q[SQ_disp_bar_id] == 1'b1);

    //SQ_pop
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            SQ_disp_instr_q <= 'b0;
            SQ_disp_func_q <= 'b0;
            SQ_disp_use_cfifo_q <= 1'b0;
            SQ_disp_bar_en_q <= 1'b0;
            SQ_disp_bar_id_q <= 3'b0;
            SQ_disp_bar_first_q <= 1'b0;
        end
        else if(SQ_pop) begin
            SQ_disp_instr_q <= SQ_disp_instr;
            SQ_disp_func_q <= SQ_disp_func;
            SQ_disp_use_cfifo_q <= SQ_disp_use_cfifo;
            SQ_disp_bar_en_q <= SQ_disp_bar_en;
            SQ_disp_bar_id_q <= SQ_disp_bar_id;
            SQ_disp_bar_first_q <= SQ_disp_bar_first;
        end
    end
    assign SQ_disp_instr_dec_o = SQ_disp_instr_q;
    assign SQ_disp_func_o = SQ_disp_func_q;

    //SQ_dispatch
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            SQ_disp_req_o <= 'b0;
        else if(SQ_disp_req)
            SQ_disp_req_o <= 1'b1;
        else if(SQ_disp_ready_i) begin
            SQ_disp_req_o <= 1'b0;
        end
    end

    //SQ_Cfifo_pop
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin 
            SQ_disp_cfifo_en_o <= 1'b0;
            SQ_disp_cfifo_data_o <= 'b0;
        end
        else if(SQ_Cfifo_pop_o) begin
            SQ_disp_cfifo_en_o <= 1'b1;
            SQ_disp_cfifo_data_o <= SQ_Cfifo_data_i;
        end
        else if(SQ_disp_ready_i) begin
            SQ_disp_cfifo_en_o <= 1'b0;
            SQ_disp_cfifo_data_o <= 32'b0;
        end
    end

    //==========SQ FSM==========
    always_comb begin
        SQ_NS = SQ_CS;
        
        SQ_disp_req = 1'b0;
        SQ_Cfifo_pop_o = 1'b0;

        case(SQ_CS)
            IDLE: begin
                if(SQ_pop) begin //disp unit free, and SQ insn valid
                    if(SQ_disp_bar_halt) begin //check bar
                        SQ_NS = WAIT_BAR_HALT;
                    end
                    else if(SQ_disp_use_cfifo==1) begin
                        if(SQ_Cfifo_empty_i) begin
                            SQ_NS = WAIT_CFIFO;
                        end
                        else begin
                            SQ_Cfifo_pop_o = 1'b1;
                            SQ_disp_req = 1'b1;
                        end
                    end
                    else begin
                        SQ_disp_req = 1'b1;
                    end
                end
            end
            WAIT_CFIFO: begin
                SQ_Cfifo_pop_o = ~SQ_Cfifo_empty_i;
                if(SQ_Cfifo_pop_o) begin
                    SQ_disp_req = 1'b1;
                    SQ_NS = IDLE;
                end
            end
            WAIT_BAR_HALT: begin
                if(bar_status_q[SQ_disp_bar_id_q] == 1'b0) begin //can disp
                    if(SQ_disp_use_cfifo_q) begin
                        if(SQ_Cfifo_empty_i) begin
                            SQ_NS = WAIT_CFIFO;
                        end
                        else begin
                            SQ_Cfifo_pop_o = 1'b1;
                            SQ_disp_req = 1'b1;
                            SQ_NS = IDLE;
                        end
                    end
                    else begin
                        SQ_disp_req = 1'b1;
                        SQ_NS = IDLE;
                    end
                end
            end

            default: SQ_NS = IDLE;
        endcase
    end



    logic                           Cub_alu_insn_fill_en;
    logic [IRAM_AWID-1:0]           Cub_alu_insn_fill_addr;
    logic [15-1:0]                  Cub_alu_insn_fill_num,Cub_alu_insn_fill_num_q,Cub_alu_insn_fill_cnt;


    logic                           Cub_alu_event_call;
    logic [IRAM_AWID-1:0]           Cub_alu_event_addr;
    logic                           Cub_alu_iram_lock_en;

    //logic                           Cub_alu_mask_update;
    //logic                           Cub_alu_mask_sel;
    //logic [BANK_NUM/2-1:0]          Cub_alu_mask;

    logic [2:0]                     VQ_alu_event_call_in_queue;
    logic                           Cheak_alu_event_done_en;

    logic [1:0]                     alu_fetch_ready,alu_fill_ready;

    //==========Cub_alu_insn_fill_req==============
    assign Cub_alu_insn_o = instr[31:0];

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            Cub_alu_insn_fill_state_o <= 'b0;
            Cub_alu_insn_fill_addr_o <= 'b0;
            Cub_alu_insn_fill_stall_o <= 1'b0;
            Cub_alu_insn_fill_num_q <= 'b0;
        end
        else if((Cub_alu_insn_fill_cnt == Cub_alu_insn_fill_num_q-1) && npu_req_i) begin
            Cub_alu_insn_fill_state_o <= 'b0;
            Cub_alu_insn_fill_addr_o <= 'b0;
        end
        else if(Cub_alu_insn_fill_en && (Cub_alu_insn_fill_addr[7] ? alu_fill_ready[1] : alu_fill_ready[0])) begin
            Cub_alu_insn_fill_state_o <= 1'b1;
            Cub_alu_insn_fill_addr_o <= Cub_alu_insn_fill_addr;
            Cub_alu_insn_fill_num_q <= Cub_alu_insn_fill_num;
        end
        else if(Cub_alu_insn_fill_state_o && npu_req_i) begin
            if(Cub_alu_insn_fill_addr_o == {(IRAM_AWID-1){1'b1}}) begin //127
                if(~alu_fill_ready[1]) begin
                    Cub_alu_insn_fill_stall_o <= 1'b1;
                end
                else begin
                    Cub_alu_insn_fill_addr_o <= Cub_alu_insn_fill_addr_o+1;
                    Cub_alu_insn_fill_stall_o <= 1'b0;
                end
            end
            else if(Cub_alu_insn_fill_addr_o == {IRAM_AWID{1'b1}}) begin //255
                if(~alu_fill_ready[0]) begin
                    Cub_alu_insn_fill_stall_o <= 1'b1;
                end
                else begin
                    Cub_alu_insn_fill_addr_o <= Cub_alu_insn_fill_addr_o+1;
                    Cub_alu_insn_fill_stall_o <= 1'b0;
                end
            end
            else
                Cub_alu_insn_fill_addr_o <= Cub_alu_insn_fill_addr_o+1;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            Cub_alu_insn_fill_cnt <= 'b0;
        else if((Cub_alu_insn_fill_cnt == Cub_alu_insn_fill_num_q-1) && npu_req_i)
            Cub_alu_insn_fill_cnt <= 'b0;
        else if(Cub_alu_insn_fill_state_o && npu_req_i && ~Cub_alu_insn_fill_stall_o)
            Cub_alu_insn_fill_cnt <= Cub_alu_insn_fill_cnt + 1;
    end

    assign alu_fill_ready[0] = ~((Cub_alu_fetch_req_o && ~Cub_alu_fetch_req_addr_i[7]) || 
                                 (|VQ_alu_event_call_in_queue && ~VQ_req_alu_event_call_iram_sel));
    assign alu_fill_ready[1] = ~((Cub_alu_fetch_req_o && Cub_alu_fetch_req_addr_i[7]) || 
                                 (Cub_alu_fetch_req_o && ~Cub_alu_fetch_req_addr_i[7] && Cub_alu_iram_lock_en) || 
                                 (|VQ_alu_event_call_in_queue && VQ_req_alu_event_call_iram_sel) || 
                                 (|VQ_alu_event_call_in_queue && ~VQ_req_alu_event_call_iram_sel && VQ_req_alu_event_call_iram_lock_en));


    //==========Cub_alu_insn_fetch_req==============
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin 
            Cub_alu_fetch_req_o <= 1'b0;
            Cub_alu_boot_addr_o <= 'b0;
        end
        else if(Cub_alu_fetch_end_i) begin
            Cub_alu_fetch_req_o <= 1'b0;
        end
        else if(~Cub_alu_fetch_req_o && Cub_alu_event_call && (Cub_alu_event_addr[7] ? alu_fetch_ready[1] : alu_fetch_ready[0])) begin
            Cub_alu_fetch_req_o <= 1'b1;
            Cub_alu_boot_addr_o <= Cub_alu_event_addr;
        end        
        else if(~Cub_alu_fetch_req_o && VQ_alu_event_call_i && (VQ_alu_event_addr_i[7] ? alu_fetch_ready[1] : alu_fetch_ready[0])) begin
            Cub_alu_fetch_req_o <= 1'b1;
            Cub_alu_boot_addr_o <= VQ_alu_event_addr_i;
        end
    end

    assign alu_fetch_ready[0] = Cub_alu_insn_fill_state_o&&(~Cub_alu_insn_fill_addr_o[7]) ? 1'b0 : ~Cub_alu_fetch_req_o;
    assign alu_fetch_ready[1] = Cub_alu_insn_fill_state_o&&Cub_alu_insn_fill_addr_o[7] ? 1'b0 : ~Cub_alu_fetch_req_o;
    assign Cub_alu_ready_o = Cub_alu_event_call ? (Cub_alu_event_addr[7] ? alu_fetch_ready[1] : alu_fetch_ready[0]) : 
                                Cub_alu_insn_fill_en ? (Cub_alu_insn_fill_addr[7] ? alu_fill_ready[1] : alu_fill_ready[0]) : 
                                    Cub_alu_insn_fill_state_o ? ~Cub_alu_insn_fill_stall_o :
                                        Cheak_alu_event_done_en ? ~(Cub_alu_fetch_req_o || VQ_alu_event_call_i || (|VQ_alu_event_call_in_queue)) : 1'b1;
    
    assign VQ_alu_event_finish_o = ~Cub_alu_fetch_req_o;
    //assign Cub_alu_ready_o = ~(Cub_alu_fetch_req_o || VQ_alu_event_call_i /*|| Cub_alu_event_call*/ || (|VQ_alu_event_call_in_queue));
    //assign Cub_alu_fill_ready = ~(Cub_alu_event_call | VQ_alu_event_call_i | Cub_alu_fetch_req_o);

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) 
            VQ_alu_event_call_in_queue <= 3'b0;
        else if(VQ_disp_req_o[0] && VQ_disp_is_alu_event_call_q)
            VQ_alu_event_call_in_queue <= VQ_alu_event_call_in_queue - 1;
        else if(VQ_req_is_alu_event_call)
            VQ_alu_event_call_in_queue <= VQ_alu_event_call_in_queue + 1;
    end
    
    //============NPU req decode============
    always_comb begin
        MQ_req_bar_en = 1'b0;
        MQ_req_bar_id = 3'b0;
        MQ_req_func = OP_MQ_CFG; //cfg, noc_cfg, load, store, mv, noc
        MQ_req_use_cfifo = 1'b0;

        VQ_req_bar_en = 1'b0;
        VQ_req_bar_id = 3'b0;
        VQ_req_func = OP_VQ_ALU_CFG; //cfg, alu, mac, scache
        VQ_req_use_cfifo = 1'b0;
        VQ_req_is_alu_event_call = 1'b0;
        VQ_req_cubank_mask = 1'b0;

        VQ_req_alu_event_call_iram_sel = 1'b0;
        VQ_req_alu_event_call_iram_lock_en = 1'b0;

        SQ_req_bar_en = 1'b0;
        SQ_req_bar_id = 3'b0;
        SQ_req_func = OP_SQ; 
        SQ_req_use_cfifo = 1'b0;

        Cub_alu_insn_fill_en = 1'b0;
        Cub_alu_insn_fill_addr = 'b0;
        Cub_alu_insn_fill_num = 'b0;

        Cub_alu_event_call = 1'b0;
        Cub_alu_event_addr = 'b0;
        Cub_alu_iram_lock_en = 1'b0;

        Cub_alu_mask_update_o = 1'b0;
        Cub_alu_mask_sel_o = 1'b0;
        Cub_alu_mask_o = 'b0;

        Cheak_alu_event_done_en = 1'b0;

        if(is_MQ_insn_i) begin
            //==========MQ==========
            case(instr[0])
                1'b0: begin //cfg
                    case(instr[1])
                        1'b0:   MQ_req_func = OP_MQ_CFG;    //3'b000;
                        1'b1: begin
                            MQ_req_func = OP_MQ_NOC_CFG;    //3'b100;
                            MQ_req_use_cfifo = instr[31];
                        end
                    endcase
                end

                1'b1: begin //load,store,mv,noc
                    MQ_req_bar_en = |(instr[30:28]);
                    MQ_req_bar_id = MQ_req_bar_en ? instr[30:28]-1 : 'b0;
                    MQ_req_use_cfifo = instr[31];
                    

                    case(instr[3:1])
                        3'b000:  MQ_req_func = OP_MQ_LOAD   ;//3'b001;
                        3'b001:  MQ_req_func = OP_MQ_STORE  ;//3'b010;
                        3'b010:  MQ_req_func = OP_MQ_MV     ;//3'b011;
                        3'b011:  MQ_req_func = OP_MQ_NOC    ;//3'b101;
                        3'b100:  MQ_req_func = OP_MQ_NOP    ;//3'b110;
                        3'b101:  MQ_req_func = OP_MQ_HLOAD  ;//3'b111;
                    endcase
                end
            endcase
        end
        else if(is_VQ_insn_i) begin
            case(instr[0])
                //==========VQ==========
                1'b0: begin //OPCODE_VQ_*_CFG
                    if(instr[2]) 
                        VQ_req_cubank_mask = 1'b1; //OPCODE_VQ_CFG
                    else if(instr[1])
                        VQ_req_func = OP_VQ_VEC_CFG;
                    else begin
                        VQ_req_func = OP_VQ_ALU_CFG;
                        VQ_req_use_cfifo = instr[29];
                    end
                end

                1'b1: begin //OPCODE_VQ_*
                    if(instr[1]) begin
                        VQ_req_func = OP_VQ_ALU;//2'b11
                        VQ_req_bar_en = |(instr[30:28]);
                        VQ_req_bar_id = VQ_req_bar_en ? instr[30:28]-1 : 'b0;
                        VQ_req_use_cfifo = instr[31];
                        VQ_req_is_alu_event_call = (instr[27:26]==2'b0);
                        if(VQ_req_is_alu_event_call) begin
                            VQ_req_alu_event_call_iram_sel = instr[7+IRAM_AWID-1]; //event_call_addr[IRAM_AWID-1]
                            VQ_req_alu_event_call_iram_lock_en = instr[7+IRAM_AWID];
                        end
                    end
                    else begin
                        VQ_req_func = OP_VQ_MAC;//2'b10
                        VQ_req_bar_en = |(instr[30:28]);
                        VQ_req_bar_id = VQ_req_bar_en ? instr[30:28]-1 : 'b0;
                        VQ_req_use_cfifo = instr[31];
                    end                    
                end
            endcase
        end
        else if(is_SQ_insn_i) begin
            SQ_req_func = OP_SQ;
            SQ_req_bar_en = |(instr[30:28]);
            SQ_req_bar_id = SQ_req_bar_en ? instr[30:28]-1 : 'b0;
            SQ_req_use_cfifo = instr[31];        
        end

        else if(is_Cub_alu_insn_i) begin
            if(instr[2:0] == 3'b0) begin //CUB_ALU_EVENT
                case(instr[31:30])
                    CUB_ALU_EVENT_CALL: begin
                        Cub_alu_event_call = 1'b1;
                        Cub_alu_event_addr = instr[7+:IRAM_AWID];
                        Cub_alu_iram_lock_en = instr[7+IRAM_AWID];
                    end
                    CUB_ALU_INSN_FILL: begin
                        Cub_alu_insn_fill_en = 1'b1;
                        Cub_alu_insn_fill_addr = instr[7+:IRAM_AWID];
                        Cub_alu_insn_fill_num = instr[7+IRAM_AWID+:IRAM_FILL_AWID]; //fill num > iram size
                    end
                    CHK_ALU_EVENT_FINISH: begin
                        Cheak_alu_event_done_en = 1'b1;
                    end
                    CUB_ALU_MASK: begin
                        Cub_alu_mask_update_o = 1'b1;
                        Cub_alu_mask_sel_o = instr[23];
                        Cub_alu_mask_o = instr[22:7];
                    end
                endcase
            end
        end
    end

    //always_ff @(posedge clk or negedge rst_n) begin
    //    if(!rst_n) begin 
    //        Cub_alu_mask_o <= 32'b0;
    //        Cub_alu_mask_update_o <= 1'b0;
    //    end
    //    else if(Cub_alu_mask_update) begin
    //        Cub_alu_mask_o <= Cub_alu_mask_sel ? {Cub_alu_mask[15:0],Cub_alu_mask_o[15:0]} : {Cub_alu_mask_o[31:16],Cub_alu_mask[15:0]};
    //        Cub_alu_mask_update_o <= 1'b1;
    //    end
    //    else
    //        Cub_alu_mask_update_o <= 1'b0;
    //end

endmodule
