module idma_data_align_256b
(
    input clk,
    input rst_n,
    //from/to master
    input                   f_valid_in,
    input   [256-1:0]       f_data_in,
    input                   f_data_last,
    output                  f_ready_out,
    //from/to slave
    output                  b_valid_out,
    output  [256-1:0]       b_data_out,
    output                  b_data_last,
    input                   b_ready_in,
    // start/end addr
    input   [4:0]           start_addr,
    input   [4:0]           end_addr
);

// ======================== signals =========================
wire f_handshake = f_valid_in && f_ready_out;
wire b_handshake = b_valid_out && b_ready_in;

wire [255:0] data_tmp;
reg  [255:0] data_buffer;
reg          data_valid_reg;
reg          data_last_reg;
wire [7:0]   start_addr_bit = {start_addr, 3'b0};
wire [255:0] last_data_mask;

// ======================== buffer data =========================
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    data_buffer <= 256'b0;
    data_last_reg <= 1'b0;
  end
  else if(f_handshake) begin
    data_buffer <= f_data_in;
    data_last_reg <= f_data_last;
  end
end

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    data_valid_reg <= 1'b0;
  end
  else if(b_data_last) begin
    data_valid_reg <= 1'b0;
  end
  else if(~f_valid_in & b_ready_in) begin
    data_valid_reg <= 1'b0;
  end
  else if(f_valid_in) begin
    data_valid_reg <= 1'b1;
  end
end

// assign data_tmp = (start_addr==5'd0) ? 
//                     data_buffer : {f_data_in[start_addr_bit-1:0], data_buffer[255:start_addr_bit]};

assign data_tmp = 
      {256{(start_addr==5'd0 )}} &                      data_buffer[255:0*8]
    | {256{(start_addr==5'd1 )}} & {f_data_in[0+:1*8],  data_buffer[255:1*8]}
    | {256{(start_addr==5'd2 )}} & {f_data_in[0+:2*8],  data_buffer[255:2*8]}
    | {256{(start_addr==5'd3 )}} & {f_data_in[0+:3*8],  data_buffer[255:3*8]}
    | {256{(start_addr==5'd4 )}} & {f_data_in[0+:4*8],  data_buffer[255:4*8]}
    | {256{(start_addr==5'd5 )}} & {f_data_in[0+:5*8],  data_buffer[255:5*8]}
    | {256{(start_addr==5'd6 )}} & {f_data_in[0+:6*8],  data_buffer[255:6*8]}
    | {256{(start_addr==5'd7 )}} & {f_data_in[0+:7*8],  data_buffer[255:7*8]}
    | {256{(start_addr==5'd8 )}} & {f_data_in[0+:8*8],  data_buffer[255:8*8]}
    | {256{(start_addr==5'd9 )}} & {f_data_in[0+:9*8],  data_buffer[255:9*8]}
    | {256{(start_addr==5'd10)}} & {f_data_in[0+:10*8], data_buffer[255:10*8]}
    | {256{(start_addr==5'd11)}} & {f_data_in[0+:11*8], data_buffer[255:11*8]}
    | {256{(start_addr==5'd12)}} & {f_data_in[0+:12*8], data_buffer[255:12*8]}
    | {256{(start_addr==5'd13)}} & {f_data_in[0+:13*8], data_buffer[255:13*8]}
    | {256{(start_addr==5'd14)}} & {f_data_in[0+:14*8], data_buffer[255:14*8]}
    | {256{(start_addr==5'd15)}} & {f_data_in[0+:15*8], data_buffer[255:15*8]}
    | {256{(start_addr==5'd16)}} & {f_data_in[0+:16*8], data_buffer[255:16*8]}
    | {256{(start_addr==5'd17)}} & {f_data_in[0+:17*8], data_buffer[255:17*8]}
    | {256{(start_addr==5'd18)}} & {f_data_in[0+:18*8], data_buffer[255:18*8]}
    | {256{(start_addr==5'd19)}} & {f_data_in[0+:19*8], data_buffer[255:19*8]}
    | {256{(start_addr==5'd20)}} & {f_data_in[0+:20*8], data_buffer[255:20*8]}
    | {256{(start_addr==5'd21)}} & {f_data_in[0+:21*8], data_buffer[255:21*8]}
    | {256{(start_addr==5'd22)}} & {f_data_in[0+:22*8], data_buffer[255:22*8]}
    | {256{(start_addr==5'd23)}} & {f_data_in[0+:23*8], data_buffer[255:23*8]}
    | {256{(start_addr==5'd24)}} & {f_data_in[0+:24*8], data_buffer[255:24*8]}
    | {256{(start_addr==5'd25)}} & {f_data_in[0+:25*8], data_buffer[255:25*8]}
    | {256{(start_addr==5'd26)}} & {f_data_in[0+:26*8], data_buffer[255:26*8]}
    | {256{(start_addr==5'd27)}} & {f_data_in[0+:27*8], data_buffer[255:27*8]}
    | {256{(start_addr==5'd28)}} & {f_data_in[0+:28*8], data_buffer[255:28*8]}
    | {256{(start_addr==5'd29)}} & {f_data_in[0+:29*8], data_buffer[255:29*8]}
    | {256{(start_addr==5'd30)}} & {f_data_in[0+:30*8], data_buffer[255:30*8]}
    | {256{(start_addr==5'd31)}} & {f_data_in[0+:31*8], data_buffer[255:31*8]};

// assign last_data_mask = 
//       {256{(end_addr==5'd0 )}} & {{(32-1 ){8'h0}}, {1{8'hff}}}
//     | {256{(end_addr==5'd1 )}} & {{(32-2 ){8'h0}}, {2{8'hff}}}
//     | {256{(end_addr==5'd2 )}} & {{(32-3 ){8'h0}}, {3{8'hff}}}
//     | {256{(end_addr==5'd3 )}} & {{(32-4 ){8'h0}}, {4{8'hff}}}
//     | {256{(end_addr==5'd4 )}} & {{(32-5 ){8'h0}}, {5{8'hff}}}
//     | {256{(end_addr==5'd5 )}} & {{(32-6 ){8'h0}}, {6{8'hff}}}
//     | {256{(end_addr==5'd6 )}} & {{(32-7 ){8'h0}}, {7{8'hff}}}
//     | {256{(end_addr==5'd7 )}} & {{(32-8 ){8'h0}}, {8{8'hff}}}
//     | {256{(end_addr==5'd8 )}} & {{(32-9 ){8'h0}}, {9{8'hff}}}
//     | {256{(end_addr==5'd9 )}} & {{(32-10){8'h0}}, {10{8'hff}}}
//     | {256{(end_addr==5'd10)}} & {{(32-11){8'h0}}, {11{8'hff}}}
//     | {256{(end_addr==5'd11)}} & {{(32-12){8'h0}}, {12{8'hff}}}
//     | {256{(end_addr==5'd12)}} & {{(32-13){8'h0}}, {13{8'hff}}}
//     | {256{(end_addr==5'd13)}} & {{(32-14){8'h0}}, {14{8'hff}}}
//     | {256{(end_addr==5'd14)}} & {{(32-15){8'h0}}, {15{8'hff}}}
//     | {256{(end_addr==5'd15)}} & {{(32-16){8'h0}}, {16{8'hff}}}
//     | {256{(end_addr==5'd16)}} & {{(32-17){8'h0}}, {17{8'hff}}}
//     | {256{(end_addr==5'd17)}} & {{(32-18){8'h0}}, {18{8'hff}}}
//     | {256{(end_addr==5'd18)}} & {{(32-19){8'h0}}, {19{8'hff}}}
//     | {256{(end_addr==5'd19)}} & {{(32-20){8'h0}}, {20{8'hff}}}
//     | {256{(end_addr==5'd20)}} & {{(32-21){8'h0}}, {21{8'hff}}}
//     | {256{(end_addr==5'd21)}} & {{(32-22){8'h0}}, {22{8'hff}}}
//     | {256{(end_addr==5'd22)}} & {{(32-23){8'h0}}, {23{8'hff}}}
//     | {256{(end_addr==5'd23)}} & {{(32-24){8'h0}}, {24{8'hff}}}
//     | {256{(end_addr==5'd24)}} & {{(32-25){8'h0}}, {25{8'hff}}}
//     | {256{(end_addr==5'd25)}} & {{(32-26){8'h0}}, {26{8'hff}}}
//     | {256{(end_addr==5'd26)}} & {{(32-27){8'h0}}, {27{8'hff}}}
//     | {256{(end_addr==5'd27)}} & {{(32-28){8'h0}}, {28{8'hff}}}
//     | {256{(end_addr==5'd28)}} & {{(32-29){8'h0}}, {29{8'hff}}}
//     | {256{(end_addr==5'd29)}} & {{(32-30){8'h0}}, {30{8'hff}}}
//     | {256{(end_addr==5'd30)}} & {{(32-31){8'h0}}, {31{8'hff}}}
//     | {256{(end_addr==5'd31)}} & {32{8'hff}};
assign last_data_mask = (end_addr==5'd7) ? {{(32-8 ){8'h0}}, {8{8'hff}}} :
                        (end_addr==5'd15)? {{(32-16){8'h0}}, {16{8'hff}}} :
                        (end_addr==5'd23)? {{(32-24){8'h0}}, {24{8'hff}}} : {32{8'hff}};

// ======================== output =========================
assign b_valid_out = data_valid_reg;
assign b_data_out = data_tmp & last_data_mask;
assign b_data_last= b_handshake && 
                    ((end_addr==5'd31 && start_addr!=5'd0 && f_data_last) || data_last_reg);

assign f_ready_out = !data_valid_reg || b_ready_in;

endmodule