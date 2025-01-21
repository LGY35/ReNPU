// --  Description :   Level sync with source registers, which can support
//                     non-registered input signal.
//                     Source register can be bypassed with "SRC_REG  = 0"
//----------------------------------------------------------------------------------------
// --  Last Update        : $Date: 2021-09-24 21:37:37 +0800 (Fri, 24 Sep 2021) $
// --  Current Ver        : $Revision: 5 $
//     Last Modified by   : $Author: weijingchuan $
// --  Description        : Create
//----------------------------------------------------------------------------------------
module level_sync(/*AUTOARG*/
   // Outputs
   data_dst,
   // Inputs
   clk_src, rst_n_src, data_src, clk_dst, rst_n_dst
   );


    parameter DWID     = 1      ;
    parameter SRC_REG  = 1      ;
    
    //-----------src-------------------//
    input                    clk_src     ;
    input                    rst_n_src   ;
    input   [DWID-1:0]       data_src    ;
    //-----------dst-------------------//
    input                    clk_dst     ;
    input                    rst_n_dst   ;
    output  [DWID-1:0]       data_dst    ;  

reg  [DWID-1:0] data_sync_0;
reg  [DWID-1:0] data_sync_1;

wire [DWID-1:0] data_to_sync;

generate
    if(SRC_REG) begin: gen_src_reg
        reg [DWID-1:0] data_src_r;
    
        always@(posedge clk_src or negedge rst_n_src)begin
            if(!rst_n_src)
                data_src_r <= 'b0;
            else
                data_src_r <= data_src;
        end
        
        assign data_to_sync = data_src_r;
    end
    else begin: no_src_reg
        assign data_to_sync = data_src ;
    end
endgenerate

//----------------dst clk-------------------------//
always@(posedge clk_dst or negedge rst_n_dst)begin
    if(!rst_n_dst) begin
        data_sync_0 <= 'b0;
        data_sync_1 <= 'b0;
    end
    else begin
        data_sync_0 <= data_to_sync;
        data_sync_1 <= data_sync_0;
    end
end

assign data_dst = data_sync_1 ;

endmodule
