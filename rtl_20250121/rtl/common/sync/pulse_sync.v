//----------------------------------------------------------------------------------------
// --  Last Update        : $Date: 2021-09-24 21:37:37 +0800 (Fri, 24 Sep 2021) $
// --  Current Ver        : $Revision: 5 $
//     Last Modified by   : $Author: weijingchuan $
// --  Description        : Create
//----------------------------------------------------------------------------------------
module pulse_sync
(
     //-----------src-------------------//
     input                  clk_src     ,
     input                  rst_n_src   ,
     input                  data_src    ,
     //-----------dst-------------------//
     input                  clk_dst     ,
     input                  rst_n_dst   ,
     output                 data_dst
 );

reg sync_reg_0;
reg sync_reg_1;
reg sync_reg_2;

reg  puls2level_r;
wire level2puls_w;

//=======================clk src=====================//
always@(posedge clk_src or negedge rst_n_src)begin
    if(!rst_n_src)
        puls2level_r <= 1'b0;
    else if(data_src)
        puls2level_r <= ~puls2level_r;
end

//=======================clk dst=====================//
always@(posedge clk_dst or negedge rst_n_dst)begin
    if(!rst_n_dst) begin
        sync_reg_0 <= 1'b0;
        sync_reg_1 <= 1'b0;
        sync_reg_2 <= 1'b0;
    end
    else begin
        sync_reg_0 <= puls2level_r;
        sync_reg_1 <= sync_reg_0;
        sync_reg_2 <= sync_reg_1;
    end
end

assign level2puls_w = sync_reg_2 ^ sync_reg_1;
assign data_dst = level2puls_w;

endmodule
