module ahb_pipe #(
    parameter       PIPE_LVL = 1    ,
    parameter       ADDR_WID = 21   ,
    parameter       HREADY_RESP_EN = 0)
    (
    input                   hclk            ,
    input                   hrstn           ,
    //ctrl
    input                   i_hsel            ,
    input                   i_hsel_ram        ,
    input                   i_hready_resp_ram ,
    input                   i_hready_resp     ,
    //input    [2:0]          i_hsize           ,
    input    [ADDR_WID-1:0] i_haddr           ,
    input    [1:0]          i_htrans          ,
    input    [31:0]         i_hwdata          ,
    input                   i_hwrite          ,
    input    [31:0]         i_hrdata          ,
    //out
    output                   o_hready_resp_ram ,
    output                   o_hready_resp     ,
    output                   o_hsel           ,
    output                   o_hsel_ram        ,
   // output    [2:0]          o_hsize          ,
    output    [ADDR_WID-1:0] o_haddr          ,
    output    [1:0]          o_htrans         ,
    output    [31:0]         o_hwdata         ,
    output                   o_hwrite         ,
    output    [31:0]         o_hrdata         
    );

    reg                   r_hready_resp   [PIPE_LVL-1:0] ;
    reg                   r_hsel          [PIPE_LVL-1:0] ;
    reg                   r_hsel_ram      [PIPE_LVL-1:0] ;
  //  reg    [2:0]          r_hsize         [PIPE_LVL-1:0] ;
    reg    [ADDR_WID-1:0] r_haddr         [PIPE_LVL-1:0] ;
    reg    [1:0]          r_htrans        [PIPE_LVL-1:0] ;
    reg    [31:0]         r_hwdata        [PIPE_LVL-1:0] ;
    reg                   r_hwrite        [PIPE_LVL-1:0] ;
    reg    [31:0]         r_hrdata        [PIPE_LVL-1:0] ;

    parameter SEL_IN_RAM = 1'b1;
    parameter SEL_IN_CTR = 1'b0;

    parameter SEL_OUT_RAM = 2'b1;
    parameter SEL_OUT_CTR = 2'b0;
    parameter SEL_OUT_OTH = 2'b11;
    //wire pip_hready, pip_hsel;

    assign o_hready_resp_ram  = r_hready_resp[PIPE_LVL-1];
    
    //assign pip_hready   = i_hsel_ram ?  i_hready_resp_ram : 1 ;

    //assign pip_hsel     = (i_hsel_ram | i_hsel) & i_hready;



        always@(posedge hclk or negedge hrstn ) begin
            if(!hrstn) begin
                r_hsel      [0] <= 'b0;    
                r_hsel_ram  [0] <= 'b0;    
            end
            else begin
                r_hsel  [0]     <= i_hsel       ;    
                r_hsel_ram  [0] <= i_hsel_ram   ;    
            end
        end


        always@(posedge hclk or negedge hrstn ) begin
            if(!hrstn) begin
                //r_hsize [0] <= 'b0;
                r_haddr [0] <= 'b0;
                r_htrans[0] <= 'b0;
                r_hwrite[0] <= 'b0;
            end
            else if(i_hsel | i_hsel_ram) begin
               // r_hsize [0] <= i_hsize  ;
                r_haddr [0] <= i_haddr  ;
                r_htrans[0] <= i_htrans ;
                r_hwrite[0] <= i_hwrite ;
            end
        end

        always@(posedge hclk or negedge hrstn ) begin
            if(!hrstn) begin
                r_hwdata[0] <= 'b0;
            end
            else if( r_hsel[0] | r_hsel_ram[0] ) begin
                r_hwdata[0] <= i_hwdata ;
            end
        end



        reg  ahb_in_flag;
        reg [1:0] ahb_out_flag;

       always@(posedge hclk or negedge hrstn ) begin
           if(!hrstn) begin
              ahb_in_flag <= SEL_IN_CTR;
           end
           else  if( i_hsel )
                ahb_in_flag <= SEL_IN_CTR;
           else  if( i_hsel_ram)             
                ahb_in_flag <= SEL_IN_RAM;
       end

       always@(posedge hclk or negedge hrstn ) begin
           if(!hrstn) begin
              ahb_out_flag <= SEL_OUT_OTH;
           end
           else  if( o_hsel )
                ahb_out_flag <= SEL_OUT_CTR;
           else  if( o_hsel_ram)             
                ahb_out_flag <= SEL_OUT_RAM;
           else if(r_hready_resp[0])
                ahb_out_flag <= SEL_OUT_OTH;
       end

        always@(posedge hclk or negedge hrstn ) begin
            if(!hrstn) begin
                r_hready_resp[0] <= 'b1;
            end
            else  if(((!i_hwrite) & i_hsel & i_htrans[1]) | ( i_hsel_ram & i_htrans[1]))
                r_hready_resp[0] <= 'b0;
            else  if(ahb_out_flag == SEL_OUT_CTR ) 
                r_hready_resp[0] <= HREADY_RESP_EN ? i_hready_resp : 1'b1;
            else  if(ahb_out_flag == SEL_OUT_RAM ) 
                r_hready_resp[0] <= i_hready_resp_ram ; 
        end

         always@(posedge hclk or negedge hrstn ) begin
            if(!hrstn) begin
                r_hrdata[0] <= 'b0;
            end
            else if(ahb_out_flag != SEL_OUT_OTH) begin
                r_hrdata[0] <= i_hrdata ;
            end
        end
        
        assign o_hready_resp = (ahb_in_flag == SEL_IN_CTR) & ( r_hwrite[0] & r_hsel[0] & r_htrans[0][1] ) ? 1 : r_hready_resp[PIPE_LVL-1]; // wr ctr or wr_rd ram



genvar i;

generate  
    if( PIPE_LVL > 1 ) begin : ahb_pip_gen_lg1

      for(i=1; i<PIPE_LVL; i =i+1) begin: ahb_pip_gen
            always@(posedge hclk or negedge hrstn ) begin
                if(!hrstn) begin
                    r_hsel      [i] <= 'b0;    
                    r_hsel_ram  [i] <= 'b0;    
                end
                else  begin
                    r_hsel      [i] <= r_hsel    [i-1]   ;    
                    r_hsel_ram  [i] <= r_hsel_ram[i-1]   ;    
                end
            end

        always@(posedge hclk or negedge hrstn ) begin
            if(!hrstn) begin
                r_hrdata[i] <= 'b0;
            end
            else if(r_hready_resp[i-1]) begin
                r_hrdata[i] <= r_hrdata[i-1] ;
            end
        end


    
        always@(posedge hclk or negedge hrstn ) begin
            if(!hrstn) begin
                r_hready_resp[i] <= 'b1;
            end
            else  if(((!i_hwrite) & i_hsel & i_htrans[1]) | ( i_hsel_ram & i_htrans[1]))
                r_hready_resp[i] <= 'b0;
            else 
                r_hready_resp[i] <=  r_hready_resp[i-1]  ; //  0: rd ctr_data 1: wr_rd ram
        end


           always@(posedge hclk or negedge hrstn ) begin
                if(!hrstn) begin
                    r_hwdata[i] <= 'b0;
                end
                else if(r_hsel[i] | r_hsel_ram[i]) begin
                    r_hwdata[i] <= r_hwdata[i-1] ;
                end
            end

            always@(posedge hclk or negedge hrstn ) begin
                if(!hrstn) begin
                  // r_hsize [i] <= 'b0;
                    r_haddr [i] <= 'b0;
                    r_htrans[i] <= 'b0;
                    r_hwrite[i] <= 'b0;
                end
                else if(r_hsel[i-1] | r_hsel_ram[i-1]) begin
                 //   r_hsize [i] <= r_hsize [i-1] ;
                    r_haddr [i] <= r_haddr [i-1] ;
                    r_htrans[i] <= r_htrans[i-1] ;
                    r_hwrite[i] <= r_hwrite[i-1] ;
                end
            end
       end
       end
endgenerate

assign o_hsel      =   r_hsel      [PIPE_LVL-1] ;
assign o_hsel_ram  =   r_hsel_ram  [PIPE_LVL-1] ;
///assign o_hsize     =   r_hsize     [PIPE_LVL-1] ;
assign o_haddr     =   r_haddr     [PIPE_LVL-1] ;
assign o_htrans    =   r_htrans    [PIPE_LVL-1] ;
assign o_hwdata    =   r_hwdata    [PIPE_LVL-1] ;
assign o_hwrite    =   r_hwrite    [PIPE_LVL-1] ;
assign o_hrdata    =   r_hrdata    [PIPE_LVL-1] ;




endmodule

