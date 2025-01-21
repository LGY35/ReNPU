module idma_data_rgb2rgba_256b
(
    input clk,
    input rst_n,
    //from/to master
    input                   f_valid_in,
    input   [256-1:0]       f_data_in,
    output                  f_ready_out,
    input                   f_data_last,
    //from/to slave
    output                  b_valid_out,
    output  [256-1:0]       b_data_out,
    input                   b_ready_in,
    // when last, clear state
    input                   b_data_last
    
);
// ================= param =====================
localparam S0 = 2'd0;
localparam S1 = 2'd1;
localparam S2 = 2'd2;
localparam S3 = 2'd3;
// ================= signal =====================
reg [1:0]  cur_state;
reg [1:0]  nxt_state;
reg [191:0]data_reg;
reg [191:0]data_tmp;
reg        data_valid_reg;
reg        data_ready_reg;
wire b_handshake = b_valid_out && b_ready_in;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cur_state <= S0;
    end
    else if(b_data_last) begin
        cur_state <= S0;
    end
    else begin
        cur_state <= nxt_state;
    end
end

always @(*) begin
    case (cur_state)
        S0: begin
            if(b_handshake)
                nxt_state = S1;
            else
                nxt_state = S0;
        end
        S1: begin
            if(b_handshake)
                nxt_state = S2;
            else
                nxt_state = S1;
        end
        S2: begin
            if(b_handshake)
                nxt_state = S3;
            else
                nxt_state = S2;
        end
        S3: begin
            if(b_handshake)
                nxt_state = S0;
            else
                nxt_state = S3;
        end
        default: nxt_state = cur_state;
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        data_reg <= 192'b0;
    end
    else if(cur_state==S0 && b_handshake) begin
        data_reg <= {128'b0, f_data_in[255:192]};
    end
    else if(cur_state==S1 && b_handshake) begin
        data_reg <= {64'b0, f_data_in[255:128]};
    end
    else if(cur_state==S2 && b_handshake) begin
        data_reg <= f_data_in[255:64];
    end
end

always @(*) begin
    case (cur_state)
        S0: begin
            data_tmp = f_data_in[191:0];
        end
        S1: begin
            data_tmp = {f_data_in[127:0], data_reg[63:0]};
        end
        S2: begin
            data_tmp = {f_data_in[63:0], data_reg[127:0]};
        end
        S3: begin
            data_tmp = data_reg;
        end
        default: data_tmp = data_reg;
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        data_valid_reg <= 1'b0;
    end
    else if(b_data_last) begin
        data_valid_reg <= 1'b0;
    end
    else if(cur_state==S0 && b_handshake) begin
        data_valid_reg <= 1'b1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        data_ready_reg <= 1'b0;
    end
    else if(f_data_last) begin
        data_ready_reg <= 1'b0;
    end
    else if(cur_state==S0 && b_handshake) begin
        data_ready_reg <= 1'b1;
    end
end

// output
// assign b_valid_out= (f_valid_in && (cur_state==S0)) || data_valid_reg;
assign b_valid_out= (f_valid_in && (cur_state==S0 || data_valid_reg)) 
                 || (cur_state==S3 && data_valid_reg);
assign b_data_out = {   8'b0, data_tmp[7*24+:24],
                        8'b0, data_tmp[6*24+:24],
                        8'b0, data_tmp[5*24+:24],
                        8'b0, data_tmp[4*24+:24],
                        8'b0, data_tmp[3*24+:24],
                        8'b0, data_tmp[2*24+:24],
                        8'b0, data_tmp[1*24+:24],
                        8'b0, data_tmp[0*24+:24]};

assign f_ready_out = (b_ready_in && (cur_state==S0 || data_ready_reg)) && (cur_state!=S3);

endmodule