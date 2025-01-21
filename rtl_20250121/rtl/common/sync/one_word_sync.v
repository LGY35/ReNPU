//----------------------------------------------------------------------------------------
// --  Last Update        : $Date: 2021-09-24 21:37:37 +0800 (Fri, 24 Sep 2021) $
// --  Current Ver        : $Revision: 5 $
//     Last Modified by   : $Author: weijingchuan $
// --  Description        : Create
//----------------------------------------------------------------------------------------
module one_word_sync #(parameter DWID = 32)
    (
    input                        clk_push   ,    
    input                        clk_pop    ,   
    input                        rst_n_push ,    
    input                        rst_n_pop  ,    
    input                        push_req   ,   
    input                        pop_req    ,   
    output   reg                 push_full  ,   
    output                       pop_empty  ,   
    input      [DWID-1: 0]       data_in    ,   
    output reg [DWID-1: 0]       data_out      
    );

reg valid_r;
//reg valid_r1;

wire poped;
wire pushed;
wire pop_pulse;
wire push_pulse;

reg [DWID-1: 0]       oneword_data ;

//======================clk push=====================//
//------------data output----------//
always@(posedge clk_push or negedge rst_n_push)begin
    if(!rst_n_push)
        push_full <= 1'b0;
    else if(push_req)
        push_full <= 1'b1;
    else if(poped)
        push_full <= 1'b0;
end

//add buf
always@(posedge clk_push or negedge rst_n_push)begin
    if(!rst_n_push)
        oneword_data <= 'b0;
    else if(push_req&&(!push_full))
        oneword_data <= data_in;
end

assign push_pulse = push_req&&(!push_full);

pulse_sync U_push_sync
(
//-----------src-------------------//
.clk_src     (clk_push              ),
.rst_n_src   (rst_n_push            ),
.data_src    (push_pulse            ),
//-----------dst-------------------//
.clk_dst     (clk_pop               ),
.rst_n_dst   (rst_n_pop             ),
.data_dst    (pushed                )
);

//=======================clk pop=====================//
//add buf
always@(posedge clk_pop or negedge rst_n_pop)begin
    if(!rst_n_pop)
        data_out <=  1'b0;
    else if(pushed)
        data_out <= oneword_data;
end

always@(posedge clk_pop or negedge rst_n_pop)begin
    if(!rst_n_pop)
        valid_r <=  1'b0;
    else if(pushed)
        valid_r <= 1'b1;
    else if(pop_req)
        valid_r <= 1'b0;
end

//always@(posedge clk_pop or negedge rst_n_pop)begin
//    if(!rst_n_pop)
//        valid_r1 <=  1'b0;
//    else
//        valid_r1 <= valid_r;
//end

// the negedge of valid_r 
//assign valid_pulse = ~valid_r & valid_r1 ; 
assign pop_pulse = valid_r & pop_req ; 

assign pop_empty = ~valid_r;


pulse_sync U_pop_sync
(
//-----------src-------------------//
.clk_src     (clk_pop              ),
.rst_n_src   (rst_n_pop            ),
.data_src    (pop_pulse          ),
//-----------dst-------------------//
.clk_dst     (clk_push             ),
.rst_n_dst   (rst_n_push           ),
.data_dst    (poped                )
);
endmodule
