module noc_buffer 
#(
    parameter FLIT_WIDTH = 32,
    parameter DEPTH = 16  // must be a power of 2
)(
    input                            clk,
    input                            rst_n,

    // FIFO input side
    input [FLIT_WIDTH-1:0]           in_flit,
    input                            in_last,
    input                            in_valid,
    output                           in_ready,

    //FIFO output side
    output reg [FLIT_WIDTH-1:0]      out_flit,  //输出是一个reg，所以可以保存，相当于FIFO深度加1
    output reg                       out_last,
    output                           out_valid,
    input                            out_ready
);
    localparam AW = $clog2(DEPTH); // the width of the index

    // Ensure that parameters are set to allowed values
    initial begin
        if ((1 << $clog2(DEPTH)) != DEPTH) begin
            $fatal("noc_buffer: the DEPTH must be a power of two.");
        end
    end

    reg [AW-1:0]    wr_addr;
    reg [AW-1:0]    rd_addr;
    reg [AW:0]      rd_count;
    wire            fifo_read;
    wire            fifo_write;
    wire            read_ram;
    wire            write_through;
    wire            write_ram;

    assign in_ready = (rd_count < DEPTH + 1); // The actual depth is DEPTH+1 because of the output register
    assign fifo_read = out_valid & out_ready;
    assign fifo_write = in_ready & in_valid;
    assign read_ram = fifo_read & (rd_count > 1);
    assign write_through = ((rd_count == 0) | ((rd_count == 1) & fifo_read));
    assign write_ram = fifo_write & ~write_through;

   // Address logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_addr <= 'b0;
            rd_addr <= 'b0;
            rd_count <= 'b0;
        end else begin
            if (fifo_write & ~fifo_read)    // 只有写
                rd_count <=  rd_count + 1'b1;
            else if (fifo_read & ~fifo_write)   //只有读
                rd_count <= rd_count - 1'b1;    
            if (write_ram)
                wr_addr <= wr_addr + 1'b1;  // 写到ram中
            if (read_ram)
                rd_addr <= rd_addr + 1'b1;  //从ram中读取
        end
    end

   // Generic dual-port, single clock memory
    reg [FLIT_WIDTH:0] ram [DEPTH-1:0]; // 最高bit表示是不是 last——flit

    // Write
    always_ff @(posedge clk) begin
        if (write_ram) begin
            ram[wr_addr] <= {in_last, in_flit};
        end
    end

    // Read
    always_ff @(posedge clk) begin
        if (read_ram) begin
            out_flit <= ram[rd_addr][0 +: FLIT_WIDTH]; //0 ~ FLIT_WIDTH - 1
            out_last <= ram[rd_addr][FLIT_WIDTH];
        end else if (fifo_write & write_through) begin
            out_flit <= in_flit;
            out_last <= in_last;
        end
    end

    assign out_valid = rd_count > 0;

endmodule // noc_buffer
