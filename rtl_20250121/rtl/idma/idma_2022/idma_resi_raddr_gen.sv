module idma_resi_raddr_gen(
input                       cclk,
input                       rst_n,
input                       rd_resi_mode,
input  [32-1:0]             rd_resi_fmapA_addr,
input  [32-1:0]             rd_resi_fmapB_addr,
input  [16-1:0]             rd_resi_addr_gap,
input  [16-1:0]             rd_resi_loop_num,

input                       rd_req,
input                       rd_afifo_full_s,

output                      rd_resi_req,
output  reg [32-1:0]        rd_resi_addr
);

reg  [16-1:0]   rd_resi_loop_cnt;
reg  [32-1:0]   resi_fmapA_addr,resi_fmapB_addr;
reg             resi_addr_gen_run;
wire            resi_addr_last;

enum reg [2:0] {RESI_IDLE, RESI_TRANS_FMAPA, RESI_TRANS_FMAPB}  resi_cs, resi_ns;

assign  rd_resi_req = ~rd_afifo_full_s & resi_addr_gen_run;
assign  resi_addr_last = (rd_resi_loop_cnt == rd_resi_loop_num-1) & rd_resi_req & (resi_cs==RESI_TRANS_FMAPB);

//resi_addr_gen_run
always @(posedge cclk or negedge rst_n) begin
    if (!rst_n)      
        resi_addr_gen_run <= 'b0;
    else if(rd_req && rd_resi_mode) 
        resi_addr_gen_run <= 'b1;
    else if(resi_addr_last)
        resi_addr_gen_run <= 'b0;
end

//fmapA addr
always @(posedge cclk or negedge rst_n) begin
    if (!rst_n)      
        resi_fmapA_addr <= 'b0;
    else if(resi_addr_last)
        resi_fmapA_addr <= 'b0;        
    else if(rd_req && rd_resi_mode) 
        resi_fmapA_addr <= rd_resi_fmapA_addr;
    else if(rd_resi_req && (resi_cs==RESI_TRANS_FMAPA))
        resi_fmapA_addr <= resi_fmapA_addr + rd_resi_addr_gap;
end

//fmapB addr
always @(posedge cclk or negedge rst_n) begin
    if (!rst_n)      
        resi_fmapB_addr <= 'b0;
    else if(resi_addr_last)
        resi_fmapB_addr <= 'b0;                
    else if(rd_req && rd_resi_mode) 
        resi_fmapB_addr <= rd_resi_fmapB_addr;        
    else if(rd_resi_req && (resi_cs==RESI_TRANS_FMAPB))
        if(rd_resi_loop_cnt == rd_resi_loop_num -2)
            resi_fmapB_addr <= resi_fmapB_addr + rd_resi_addr_gap +1;
        else
            resi_fmapB_addr <= resi_fmapB_addr + rd_resi_addr_gap;
end

//loop_cnt
always @(posedge cclk or negedge rst_n) begin
    if (!rst_n)      
        rd_resi_loop_cnt <= 'b0;
    else if(resi_addr_last)
        rd_resi_loop_cnt <= 0;        
    else if(rd_resi_req && (resi_cs==RESI_TRANS_FMAPB)) 
        rd_resi_loop_cnt <= rd_resi_loop_cnt +1;
end


//==================================================
// fsm
//==================================================
always @(posedge cclk or negedge rst_n) begin
    if(!rst_n) 
        resi_cs  <=  RESI_IDLE;
    else 
        resi_cs  <=  resi_ns;
end

always @(*) begin
    case(resi_cs)
        RESI_IDLE:begin
            if(rd_req && rd_resi_mode && !rd_afifo_full_s)
                resi_ns = RESI_TRANS_FMAPA;
            else
                resi_ns = RESI_IDLE;
        end
        RESI_TRANS_FMAPA:begin
            if(rd_resi_req)
                resi_ns = RESI_TRANS_FMAPB;
            else
                resi_ns = RESI_TRANS_FMAPA;
        end
        RESI_TRANS_FMAPB:begin
            if(rd_resi_req) begin
                if(rd_resi_loop_cnt < rd_resi_loop_num -1)
                    resi_ns =  RESI_TRANS_FMAPA;
                else
                    resi_ns = RESI_IDLE;
            end
            else
                resi_ns =  RESI_TRANS_FMAPB;
        end        
        default:resi_ns = RESI_IDLE;
    endcase
end

always @(*) begin
    case(resi_cs)
        RESI_IDLE: begin
            rd_resi_addr='b0;
        end
        RESI_TRANS_FMAPA:begin
            rd_resi_addr=resi_fmapA_addr;
        end
        RESI_TRANS_FMAPB:begin
            rd_resi_addr=resi_fmapB_addr;
        end      
        default:rd_resi_addr='b0;
    endcase
end

endmodule
