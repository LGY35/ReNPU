//----------------------------------------------------------------------------------------
// --  Last Update        : $Date: 2021-09-24 21:37:37 +0800 (Fri, 24 Sep 2021) $
// --  Current Ver        : $Revision: 5 $
//     Last Modified by   : $Author: weijingchuan $
// --  Description        : Create
//----------------------------------------------------------------------------------------
module rstn_sync(
    i_rstn_in,
    i_clk,

    o_rstn_out
    );
//-----------------------------------
// port declaration
// ----------------------------------
input  i_rstn_in ;
input  i_clk;
 
output o_rstn_out;

//------------------------------------
// signal declaration : wire
// -----------------------------------
wire  rstn_in;
wire  clk    ;

//------------------------------------
// signal declaration : reg
// -----------------------------------
reg    rstn_sync_r ;
reg    rstn_sync_r2;

//------------------------------------
// port assign
// -----------------------------------
assign rstn_in    = i_rstn_in ;
assign clk        = i_clk ;
assign o_rstn_out = rstn_sync_r2 ;

always@(posedge clk or negedge rstn_in) begin
    if(!rstn_in) begin
        rstn_sync_r  <= 1'b0;
        rstn_sync_r2 <= 1'b0;
    end
    else begin
        rstn_sync_r  <= 1'b1;
        rstn_sync_r2 <= rstn_sync_r;
    end
end

endmodule

