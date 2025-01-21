module trans_latchram256x16 #(
    parameter WORD_WID      = 8                     ,
    parameter CH_X          = 32                    ,
    parameter DATA_WID      = WORD_WID * CH_X       ,
    parameter NUM_WORDS     = 16                    ,
    parameter DATA_WID_Y    = NUM_WORDS*WORD_WID    ,
    parameter NUM_WORDS_Y   = CH_X 
)(
   input  logic                                     clk         ,
   //---------------------x direction---------------------//
   input  logic                                     wen_x_cs    ,
   input  logic                                     wen_x       ,
   input  logic [$clog2(NUM_WORDS)-1:0]             addr_w_x    ,
   input  logic [$clog2(NUM_WORDS)-1:0]             addr_r_x    ,
   input  logic [DATA_WID-1:0]                      wdata_x     ,
   input                                            ren_x       ,
   output logic [DATA_WID-1:0]                      rdata_x     ,

   //---------------------y direction---------------------//
   input  logic                                   ren_y         , 
   input  logic [$clog2(NUM_WORDS_Y)-1:0]         addr_dp_r_y   , //double read port 
   output logic [DATA_WID_Y-1:0]                  rdata_y_0     ,
   output logic [DATA_WID_Y-1:0]                  rdata_y_1
);
    localparam ADDR_WID = $clog2(NUM_WORDS);

    logic  [NUM_WORDS-1:0]  [CH_X-1:0] [WORD_WID -1 : 0] ram    ;

    logic [ADDR_WID-1:0] raddr_w_x_q, raddr_r_x_q, raddr_dp_r_y_q ;

    logic [CH_X-1:0] [NUM_WORDS-1:0]  [WORD_WID -1 : 0] ram_y  ;

    logic [NUM_WORDS-1:0]  [WORD_WID -1 : 0] ram_y_cell ; 

	//int m,n; 
    //always_comb begin  
    //    foreach(ram_y[m]) begin
    //    	foreach(ram_y[m][n])
	//	 ram_y[m][n] = ram[n][m];
	//    end
    //end


	int m,n; 
    always_comb begin  
       // foreach(ram_y[m]) begin
        for(m=0; m<CH_X; m=m+1) begin
           	for(n=0; n<NUM_WORDS; n=n+1)
	        	 ram_y[m][n] = ram[n][m];
	    end
    end
    // 1. randomize array
    // 2. randomize output when no request is active
    always_ff @(posedge clk) begin
        if (wen_x & wen_x_cs ) begin
                 ram[addr_w_x] <= wdata_x;
        end
    end

    always_comb begin
        raddr_r_x_q    = addr_r_x;
        raddr_dp_r_y_q = addr_dp_r_y;
    end

    always_ff @(posedge clk ) if(ren_x) rdata_x   <= ram[raddr_r_x_q];
    always_ff @(posedge clk ) if(ren_y) rdata_y_0 <= ram_y[raddr_dp_r_y_q         ];
    always_ff @(posedge clk ) if(ren_y) rdata_y_1 <= ram_y[raddr_dp_r_y_q + 16    ];


endmodule
