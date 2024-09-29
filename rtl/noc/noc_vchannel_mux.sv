/* 
 *
 * =============================================================================
 *
 * Mux virtual channels
 *
 */

module noc_vchannel_mux #(
    parameter FLIT_WIDTH = 256

)
(
    // input                               clk,
    // input                               rst_n,

    input [1:0][FLIT_WIDTH-1:0]         in_flit,
    input [1:0]                         in_last,
    input [1:0]                         in_valid,
    output [1:0]                        in_ready,

    output reg [FLIT_WIDTH-1:0]         out_flit,
    output reg                          out_last,
    output [1:0]                        out_valid,
    input [1:0]                         out_ready
);

   // reg [1:0]                    select;
   // logic [1:0]                  nxt_select;

    wire [1:0]                    select;

    assign select = in_valid[1] & out_ready[1] ? 2'b10 : 2'b01;

    assign out_valid = in_valid & select;
    assign in_ready  = out_ready & select;


    // 选择哪个虚拟通道
    assign out_flit = select[1] ? in_flit[1] : in_flit[0] ;
    assign out_last = select[1] ? in_last[1] : in_last[0] ;


    // integer c;
    // always @(*) begin
    //     out_flit = 'x;
    //     out_last = 'x;
    //     for (c = 0; c < 2; c = c + 1) begin
    //         if(select[c]) begin
    //             out_flit = in_flit[c];
    //             out_last = in_last[c];
    //         end
    //     end
    // end



   // arb_rr
   //   #(.N (CHANNELS))
   // u_arbiter
   //   (.req (in_valid & out_ready),
   //    .en  (1'b1),
   //    .gnt (select),
   //    .nxt_gnt (nxt_select));

   // always_ff @(posedge clk) begin
   //    if (rst) begin
   //       select <= {{1{1'b0}},1'b1};
   //    end else begin
   //       select <= nxt_select;
   //    end
   // end

endmodule // noc_vchannel_mux
