`define WRITE_FIRST // READ_FIRST

module ram_sp #(
	parameter WIDTH      = 8,
	parameter DEPTH      = 8,
	parameter ADDR_WIDTH = 3
)
(
    input  wire                  clk  ,
	input  wire                  en   ,
	input  wire                  we   ,
	input  wire [ADDR_WIDTH-1:0] addr ,
	input  wire [WIDTH-1:0]      din  ,
	output reg  [WIDTH-1:0]      dout
);

(* ram_style="distributed" *) reg [WIDTH-1:0] mem [0:DEPTH-1];

always@(posedge clk)
begin
	if(en && we)
	begin
		mem[addr] <= din;
        `ifdef WRITE_FIRST
        dout      <= din;
        `endif
    end
    else if(en)
    begin
        dout      <= mem[addr];
    end 
end

endmodule

// byte enable and WIDTH_BE >= 8, 16, ... , 8^N
module ram_sp_be #(
	parameter WIDTH_BE      = 8,
	parameter DEPTH_BE      = 8,
	parameter ADDR_WIDTH_BE = 3
)
(
    input  wire                     clk  ,
	input  wire                     en   ,
	input  wire [WIDTH_BE/8-1:0]    we   ,
	input  wire [ADDR_WIDTH_BE-1:0] addr ,
	input  wire [WIDTH_BE-1:0]      din  ,
	output reg  [WIDTH_BE-1:0]      dout
);

generate
genvar i;
for(i = 0; i < WIDTH_BE/8; i = i+1)
begin : loop_i
    ram_sp#(
        .WIDTH      ( 8                  ) ,
        .DEPTH      ( DEPTH_BE           ) ,
        .ADDR_WIDTH ( ADDR_WIDTH_BE      )
    )u_ram_sp(
        .clk        ( clk                ),
        .en         ( en                 ),
        .we         ( we[i]              ),
        .addr       ( addr               ),
        .din        ( din[8*(i+1)-1:8*i] ),
        .dout       ( dout[8*(i+1)-1:8*i])
    );
end
endgenerate

endmodule

// bit enable and WIDTH_IE
module ram_sp_ie #(
	parameter WIDTH_IE      = 8,
	parameter DEPTH_IE      = 8,
	parameter ADDR_WIDTH_IE = 3
)
(
    input  wire                     clk  ,
	input  wire                     en   ,
	input  wire [WIDTH_IE-1:0]      we   ,
	input  wire [ADDR_WIDTH_IE-1:0] addr ,
	input  wire [WIDTH_IE-1:0]      din  ,
	output reg  [WIDTH_IE-1:0]      dout
);

generate
genvar i;
for(i=0 ; i < WIDTH_IE; i = i+1)
begin : loop_i
    ram_sp#(
        .WIDTH      ( 1             ) ,
        .DEPTH      ( DEPTH_IE      ) ,
        .ADDR_WIDTH ( ADDR_WIDTH_IE )
    )u_ram_sp(
        .clk        ( clk           ) ,
        .en         ( en            ) ,
        .we         ( we[i]         ) ,
        .addr       ( addr          ) ,
        .din        ( din[i]        ) ,
        .dout       ( dout[i]       )
    );
end
endgenerate

endmodule

// Simple Dual Port RAM
module simple_dpram #(
	parameter ADDR_WIDTH = 3,
	parameter DATA_WIDTH = 8
) (
   input  wire                  clka  ,
   input  wire                  ena   ,
   input  wire                  wea   ,
   input  wire [ADDR_WIDTH-1:0] addra ,
   input  wire [DATA_WIDTH-1:0] dina  ,
   input  wire                  clkb  ,
   input  wire                  enb   ,
   input  wire [ADDR_WIDTH-1:0] addrb ,
   output wire [DATA_WIDTH-1:0] doutb
);

localparam DEPTH = 2**ADDR_WIDTH;

(* ram_style="block" *) reg [DATA_WIDTH-1:0] mem[0:DEPTH-1];

integer index;
initial
begin
   for(index = 0; index < DEPTH; index = index+1)
   begin
       mem[index] = 'b0;
   end
end

reg [DATA_WIDTH-1:0] doutb_d0;

always@(posedge clka)
begin
   if(ena && wea)
   begin
       mem[addra] <= dina;
   end
end

always@(posedge clkb)
begin
   if(enb)
   begin
       doutb_d0 <= mem[addrb];
   end
end

assign doutb = doutb_d0;

endmodule