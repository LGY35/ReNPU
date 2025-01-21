module cub_alu_instr_ram #(
    parameter   INSN_WIDTH = 32,
    parameter   IRAM_AWID = 8
)
(
    input                           clk,
    input                           rst_n,

    input                           alu_instr_fill_state_i,
    input                           alu_instr_fill_stall_i,
    input [IRAM_AWID-1:0]           alu_instr_fill_addr_i,
    input [INSN_WIDTH-1:0]          alu_instr_in_i,

    input                           alu_instr_req_i,
    output logic                    alu_instr_gnt_o,
    input [IRAM_AWID-1:0]           alu_instr_addr_i,
    output logic [INSN_WIDTH-1:0]   alu_instr_rdata_o,
    output logic                    alu_instr_rvalid_o
);

    logic                           alu_fetch_en;

    logic [1:0]                     insn_read, insn_write;
    logic [1:0][IRAM_AWID-2:0]      addr_read, addr_write;
    logic [1:0]                     insn_read_q;
    logic [INSN_WIDTH-1:0]          alu_instr_rdata_q;

    logic [1:0]                     alu_insn_ram_en;
    logic [1:0]                     alu_insn_ram_we;
    logic [1:0][IRAM_AWID-2:0]      alu_insn_ram_addr;
    logic [1:0][INSN_WIDTH-1:0]     alu_insn_ram_wdata;
    logic [1:0][INSN_WIDTH-1:0]     alu_insn_ram_rdata;


    //============================
    //  spram w/r
    //============================
    //assign insn_write = alu_instr_fill_state_i;
    //assign addr_write = alu_instr_fill_addr_i;
    //assign insn_read = alu_fetch_en;
    //assign addr_read = alu_instr_addr_i;

    //read: CE high, WE low
    //write: CE high, WE high
    //assign CE = WE ? insn_write : insn_read;
    //assign WE = insn_write ? 1'b1 : 1'b0;
    //assign Addr = WE ? addr_write : addr_read;
    //assign Data = alu_instr_in_i;

    assign insn_write[0] = alu_instr_fill_state_i && ~alu_instr_fill_stall_i && (~alu_instr_fill_addr_i[7]);
    assign insn_write[1] = alu_instr_fill_state_i && ~alu_instr_fill_stall_i && alu_instr_fill_addr_i[7];
    assign addr_write[0] = alu_instr_fill_addr_i[6:0];
    assign addr_write[1] = alu_instr_fill_addr_i[6:0];

    assign insn_read[0] = alu_fetch_en && (~alu_instr_addr_i[7]);
    assign insn_read[1] = alu_fetch_en && alu_instr_addr_i[7];
    assign addr_read[0] = alu_instr_addr_i[6:0];
    assign addr_read[1] = alu_instr_addr_i[6:0];

    assign alu_insn_ram_en[0] = insn_write[0] || insn_read[0];
    assign alu_insn_ram_we[0] = insn_write[0];
    assign alu_insn_ram_addr[0] = insn_write[0] ? addr_write[0] : addr_read[0];
    assign alu_insn_ram_wdata[0] = alu_instr_in_i;

    assign alu_insn_ram_en[1] = insn_write[1] || insn_read[1];
    assign alu_insn_ram_we[1] = insn_write[1];
    assign alu_insn_ram_addr[1] = insn_write[1] ? addr_write[1] : addr_read[1];
    assign alu_insn_ram_wdata[1] = alu_instr_in_i;    

    std_spram128x32 U_alu_instr_ram0 (
        .CLK(clk),
        .CE(alu_insn_ram_en[0]),
        .WE(alu_insn_ram_we[0]),
        .D(alu_insn_ram_wdata[0]),
        .A(alu_insn_ram_addr[0]),
        .Q(alu_insn_ram_rdata[0])
    );

    std_spram128x32 U_alu_instr_ram1 (
        .CLK(clk),
        .CE(alu_insn_ram_en[1]),
        .WE(alu_insn_ram_we[1]),
        .D(alu_insn_ram_wdata[1]),
        .A(alu_insn_ram_addr[1]),
        .Q(alu_insn_ram_rdata[1])
    );

     always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            insn_read_q <= 2'b0;
        else begin
            insn_read_q <= insn_read;
            alu_instr_rdata_q <= alu_instr_rdata_o;
	end
    end   
    assign alu_instr_rdata_o = insn_read_q[0] ? alu_insn_ram_rdata[0] : insn_read_q[1] ? alu_insn_ram_rdata[1] : alu_instr_rdata_q;

    //============================
    //  Read FSM
    //============================
    enum logic [2:0] {IDLE, WAIT_GNT, SEND_RDATA} CS, NS;

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            CS <= IDLE;
        else
            CS <= NS;
    end

    always_comb begin
        alu_fetch_en = 1'b0;
        alu_instr_gnt_o = 1'b0;
        alu_instr_rvalid_o = 1'b0;
        NS=CS;

        case(CS)
            IDLE: begin
                if(alu_instr_req_i) begin

                    if((~alu_instr_addr_i[7])&&(~insn_write[0]) || alu_instr_addr_i[7]&&(~insn_write[1])) begin
                        alu_instr_gnt_o = 1'b1;
                        alu_fetch_en = 1'b1;
                        NS = SEND_RDATA;
                    end
                end
            end
            SEND_RDATA: begin
                alu_instr_rvalid_o = 1'b1;

                if(alu_instr_req_i) begin
                    if((~alu_instr_addr_i[7])&&insn_write[0] || alu_instr_addr_i[7]&&insn_write[1])
                        NS = IDLE;
                    else begin
                        alu_instr_gnt_o = 1'b1;
                        alu_fetch_en = 1'b1;
                    end
                end
                else begin
                    NS = IDLE;
                end
            end
            default: begin
                NS = IDLE;
            end
        endcase
    end

endmodule
