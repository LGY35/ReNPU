module riscv_fetch_fifo
(
    input                               clk,
    input                               rst_n,
    input                               clear_i,
    //instr in
    input   [31:0]                      in_addr_i,
    input   [31:0]                      in_rdata_i,
    input                               in_valid_i,
    output  logic                       in_ready_o,
    input                               in_is_hwlp_i,
    //instr out
    output  logic   [31:0]              out_addr_o,
    output  logic   [31:0]              out_rdata_o,
    output  logic                       out_valid_o,
    input                               out_ready_i,
    output  logic                       out_is_hwlp_o,
    output  logic                       unaligned_is_compressed_o,
    output  logic                       out_valid_stored_o,
    //same as out_valid_o, except that if something is incoming now it is not included. This signal is available immediately as it comes directly out of FFs
    input                               is_npu_insn_i
);

    localparam  DEPTH = 4;
    
    logic               aligned_is_compressed, unaligned_is_compressed;
    logic               aligned_is_compressed_st, unaligned_is_compressed_st;
    
    logic   [0:DEPTH-1][31:0]       addr_n, addr_int, addr_Q; //in ->Q[3][2][1][0]-> out
    logic   [0:DEPTH-1][31:0]       rdata_n, rdata_int, rdata_Q;
    logic   [0:DEPTH-1]             valid_n, valid_int, valid_Q;
    logic   [0:1]                   is_hwlp_n, is_hwlp_int, is_hwlp_Q;

    logic   [31:0]                  addr_next;
    logic   [31:0]                  rdata, rdata_unaligned;
    logic                           valid, valid_unaligned;
    
   
    assign rdata = valid_Q[0] ? rdata_Q[0] : (in_rdata_i & {32{in_valid_i}});  
    assign valid = valid_Q[0] || in_valid_i || is_hwlp_Q[1];
    
    //out when instr is aligned or not
    assign unaligned_is_compressed = ~is_npu_insn_i && rdata[17:16] != 2'b11;
    assign aligned_is_compressed   = ~is_npu_insn_i && rdata[1:0] != 2'b11;
    assign unaligned_is_compressed_st = valid_Q[0] && rdata_Q[0][17:16] != 2'b11 && (~is_npu_insn_i);
    assign aligned_is_compressed_st   = valid_Q[0] && rdata_Q[0][1:0] != 2'b11 && (~is_npu_insn_i);
    assign unaligned_is_compressed_o = unaligned_is_compressed;

    assign rdata_unaligned = valid_Q[1] ? {rdata_Q[1][15:0],rdata[31:16]} : {in_rdata_i[15:0],rdata[31:16]};
    assign valid_unaligned = valid_Q[1] || (valid_Q[0]&&in_valid_i);
    
    always_comb begin
        if(out_addr_o[1] && (~is_hwlp_Q[1])) begin //unaligned case
            out_rdata_o = rdata_unaligned;
            if(unaligned_is_compressed)
                out_valid_o = valid;
            else
                out_valid_o = valid_unaligned;
        end
        else begin //aligned case
            out_rdata_o = rdata;
            out_valid_o = valid;
        end
    end
    assign out_addr_o = valid_Q[0] ? addr_Q[0] : in_addr_i;
    assign out_is_hwlp_o = valid_Q[0] ? is_hwlp_Q[0] : in_is_hwlp_i;

    //this valid signal must not depend on signals from outside!
    always_comb begin
        out_valid_stored_o = 1'b1;

        if(out_addr_o[1] && (~is_hwlp_Q[1])) begin
          if(unaligned_is_compressed_st)
                out_valid_stored_o = 1'b1;
          else
                out_valid_stored_o = valid_Q[1];
        end 
        else begin
            out_valid_stored_o = valid_Q[0];
        end
    end

    // we accept data as long as our fifo is not full
    // we don't care about clear here as the data will be received one cycle later anyway   
    assign in_ready_o = ~valid_Q[DEPTH-2]; //when in_ready_o high, IF will req new instr as id is ready
                                           //the data will be received one cycle later?

    //register
    always_ff@(posedge clk  or negedge rst_n) begin
        if(!rst_n) begin
            addr_Q <= 'b0;
            rdata_Q <= 'b0;
            valid_Q <= 'b0;
            is_hwlp_Q <= 'b0;
        end
        else if(clear_i) begin
            valid_Q <= 'b0;
            is_hwlp_Q <= 'b0;
        end
        else begin
            addr_Q <= addr_n;
            rdata_Q <= rdata_n;
            valid_Q <= valid_n;
            is_hwlp_Q <= is_hwlp_n;
        end
    end

    //fifo push
    always_comb begin
        addr_int = addr_Q;
        rdata_int = rdata_Q;
        valid_int = valid_Q;
        is_hwlp_int = is_hwlp_Q;
        
        if(in_valid_i) begin
            case(1'b1)
                ~valid_Q[0]: begin 
                    addr_int[0]  = in_addr_i;
                    rdata_int[0] = in_rdata_i;
                    valid_int[0] = 1'b1;
                end
                ~valid_Q[1]: begin 
                    addr_int[1]  = in_addr_i;
                    rdata_int[1] = in_rdata_i;
                    valid_int[1] = 1'b1;
                end
                ~valid_Q[2]: begin 
                    addr_int[2]  = in_addr_i;
                    rdata_int[2] = in_rdata_i;
                    valid_int[2] = 1'b1;
                end
                ~valid_Q[3]: begin 
                    addr_int[3]  = in_addr_i;
                    rdata_int[3] = in_rdata_i;
                    valid_int[3] = 1'b1;
                end
            endcase
        end

        if(in_is_hwlp_i) begin// in_replace2_i
            if(valid_Q[0]) begin
                addr_int[1] = in_addr_i;

                // if we replace the 2nd entry, let's cache the output word in case we
                // still need it and it would span two words in the FIFO
                rdata_int[0]         = out_rdata_o;
                rdata_int[1]         = in_rdata_i;
                valid_int[1]         = 1'b1;
                valid_int[2:DEPTH-1] = 'b0;

                // hardware loop incoming?
                is_hwlp_int[1] = in_is_hwlp_i;
            end 
            else begin
                is_hwlp_int[0] = in_is_hwlp_i;
            end
        end        
    end

    //fifo pop, move everything by one step
    assign addr_next = {addr_int[0][31:2],2'b00} + 32'h4; 
    always_comb begin
        addr_n = addr_int;
        rdata_n = rdata_int;
        valid_n = valid_int;
        is_hwlp_n = is_hwlp_int;

        if(out_ready_i && out_valid_o) begin //in ->Q[3][2][1][0]-> out
            is_hwlp_n = {is_hwlp_int[1], 1'b0};
            if(is_hwlp_int[1]) begin //careful!!
                addr_n[0] = addr_int[1][31:0];
                rdata_n = (rdata_int<<32);
                valid_n = (valid_int<<1);
            end
            else begin
                if(addr_int[0][1]) begin //unaligned case
                    if(unaligned_is_compressed)
                        addr_n[0] = {addr_next[31:2], 2'b00};
                    else
                        addr_n[0] = {addr_next[31:2], 2'b10};

                    rdata_n = (rdata_int<<32);
                    valid_n = (valid_int<<1);
                end
                else begin //aligned case
                    if(aligned_is_compressed) begin //just increase address
                        addr_n[0] = {addr_int[0][31:2], 2'b10};
                    end
                    else begin //increase address and move to next entry in FIFO
                        addr_n[0] = {addr_next[31:2], 2'b00};
                        rdata_n = (rdata_int<<32);
                        valid_n = (valid_int<<1);   
                    end
                end
            end
        end
    end

endmodule 
