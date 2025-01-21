module fifo_with_flush
#(
    parameter DEPTH = 4,
    parameter DATA_W = 32
)
(
    input clk,
    input rst_n,
    input flush,
    //from/to master
    input                   f_valid_in,
    input   [DATA_W-1:0]    f_data_in,
    output                  f_ready_out,
    //from/to slave
    output                  b_valid_out,
    output  [DATA_W-1:0]    b_data_out,
    input                   b_ready_in
);

localparam PTR_W = $clog2(DEPTH)+1;

reg [DATA_W-1:0] fifo_ram [DEPTH-1:0] ;
reg [PTR_W-1:0] read_ptr;
reg [PTR_W-1:0] write_ptr;
wire[PTR_W-2:0] read_addr;
wire[PTR_W-2:0] write_addr;
wire empty;
wire full;
integer i;

// read pointer
always @(posedge clk or negedge rst_n) begin
    if (rst_n==1'b0) begin
        read_ptr <= {PTR_W{1'b0}};
    end
    else if(flush) begin
        read_ptr <= {PTR_W{1'b0}};
    end
    else if(b_valid_out && b_ready_in) begin
        read_ptr <= read_ptr + 1;
    end
end

// write pointer
always @(posedge clk or negedge rst_n) begin
    if (rst_n==1'b0) begin
        write_ptr <= {PTR_W{1'b0}};
    end
    else if(flush) begin
        write_ptr <= {PTR_W{1'b0}};
    end
    else if(f_valid_in && f_ready_out) begin
        write_ptr <= write_ptr + 1;
    end
end

// read data
assign read_addr = read_ptr[PTR_W-2:0];
assign b_data_out = fifo_ram[read_addr];

// write data
assign write_addr = write_ptr[PTR_W-2:0];
always @(posedge clk or negedge rst_n) begin
    if (rst_n==1'b0) begin
        for(i=0; i<DEPTH; i=i+1) begin
            fifo_ram[i] <= {DATA_W{1'b0}};
        end
    end
    else if(f_valid_in && f_ready_out) begin
        fifo_ram[write_addr] <= f_data_in;
    end
end

// output
assign empty = (read_ptr==write_ptr);
assign full = (read_ptr[PTR_W-1]!=write_ptr[PTR_W-1]) && (read_ptr[PTR_W-2]==write_ptr[PTR_W-2]);
assign f_ready_out = !full;
assign b_valid_out = !empty;


endmodule