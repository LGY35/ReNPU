module fake_cu_core (
input                           clk, rst_n,

input                   [31:0]  boot_addr_i,
//instruction interface:
output  logic                   fetch_req,
input   logic                   fetch_gnt,
output  logic           [18:0]  fetch_addr,
input   logic           [31:0]  fetch_r_data,
input   logic                   fetch_r_valid,

//core cmd interface:
output  logic                   core_cmd_req,
output  logic   [2:0]           core_cmd_addr,
input   logic                   core_cmd_gnt,
input   logic                   core_cmd_ok,
output  logic                   core_enter_irq_pulse,
input                           core_wakeup_irq,

//core cfg interface:
output  logic   [6:0]           core_cfg_addr,
output  logic   [12:0]          core_cfg_data,
output  logic                   core_cfg_valid,

//core input:
input   logic           [255:0]         core_in_data,
input   logic                           core_in_valid,

//core output:
output  logic           [255:0]         core_out_data,
output  logic                           core_out_valid
);

always_comb begin
    fetch_req               = 1'b1;
    // fetch_addr              = 'b0;
    core_cmd_req            = 'b0;
    core_cmd_addr           = 'b0;
    core_enter_irq_pulse    = 'b0;
    core_cfg_addr           = 'b0;
    core_cfg_data           = 'b0;
    core_cfg_valid          = 'b0;
    core_out_data           = 'b0;
    core_out_valid          = 'b0;
end

// localparam IDLE = 2'd0;
// localparam RUN  = 2'd1;

// logic [1:0] cs, ns;

// always_comb begin
//     ns = cs;

//     case(cs)
//     IDLE: begin
    
//     end
//     RUN: begin
    
//     end
//     endcase
// end

// always_ff @(posedge clk or negedge rst_n) begin
// if(!rst_n)begin
//     cs <= SLEEP;
// end
// else
//     cs <= ns;
// end

logic [18:0] bias_addr;

assign fetch_addr = boot_addr_i + bias_addr;

always_ff @(posedge clk or negedge rst_n) begin
if(!rst_n)begin
    bias_addr <= 'b0;
end
else if(fetch_r_valid)
    bias_addr <= bias_addr + 19'd4;
end

endmodule