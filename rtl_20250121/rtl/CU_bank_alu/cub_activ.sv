module cub_activ  #(
        parameter           DWID                =   32   
    )
    (  
    input                                           clk                             ,
    input                                           rst_n                           ,
    //-----------------------------------------------------------------------------//
    input                         [7:0]             cub_activ_work_op              ,  
    input                                           cub_activ_cflow_mode           ,
    input signed                  [DWID-1:0]        cub_activ_operand              ,
    input                                           cub_activ_valid                , //op_enable
    //
    output reg signed             [DWID-1:0]        cub_activ_rslt_data            ,
    output reg                                      cub_activ_rslt_valid           ,
    //
    input signed                  [DWID-1:0]        cub_activ_relu6_bias           ,
    input signed                  [DWID-1:0]        cub_activ_relu6_ref_min        ,
    input signed                  [DWID-1:0]        cub_activ_relu6_ref_max        ,
    //input signed                  [DWID/2-1:0]      cub_activ_xorg_scaling         ,             //16bit
    //input                         [5-1:0]           cub_activ_xorg_pdt_Qp          ,
    input signed                  [DWID/2-1:0]      cub_activ_prelu_scaling        ,             //16bit
    input                         [5-1:0]           cub_activ_mul_pdt_Qp           ,

    //---------------------------------reused by prelu module-------------------------------------------//
    output                                          prelu_mult_en                   ,
    output  [16:0]                                  prelu_mult_multiplier           ,
    output  [32:0]                                  prelu_mult_multiplicand         ,
    input   [49:0]                                  prelu_mult_product              ,
    output logic                                    cub_activ_ready                 

    );

    logic [1:0]  cub_activ_relu_mode    ;
    logic        cub_activ_prelu_mode   ;
    logic [1:0]  cub_activ_hswish_mode  ;
    logic [1:0]  cub_activ_rslt_mode    ;
    logic        cub_activ_muladd_mode  ;


    logic signed                  [DWID-1:0]      cub_activ_add_relu6_bias_data , 
                                                  cub_activ_relu6_rslt_data     , 
                                                  cub_activ_relu_data_in        ,      
                                                  cub_activ_relu_data_out       ,     
                                                  cub_activ_prelu_neg_data      ,    
                                                  cub_activ_relu_rslt_data      ,     
                                                  cub_activ_hswish_rslt_data    ,     
                                                  cub_activ_hsigmoid_rslt_data  ;    
                                           
    logic                                  cub_activ_relu_rslt_valid       ; 
    logic                                  cub_activ_hswish_rslt_valid     ; 
    logic                                  cub_activ_hsigmoid_rslt_valid   ; 

    logic   signed                   [DWID-1:0]       cub_activ_pipe_data ;
    logic   signed                   [DWID-1:0]       cub_activ_relu6_datain ;
    logic                                             cub_activ_pipe_valid;
    logic                                             cub_activ_relu6_valid_in;

    logic signed   [DWID-1:0]  mul_pdt_truncate, mul_pdt_truncate_r;
    logic  mul_pdt_truncate_valid ;

    parameter PASS          = 8'b0_11_??_?_?? ;
    parameter RELU          = 8'b0_00_??_0_00 ;
    parameter PRELU         = 8'b0_00_??_1_00 ;
    parameter RELU6         = 8'b0_01_??_?_?? ;
    parameter HSMD          = 8'b0_10_01_?_?? ; //hsigmoid
    parameter HSWD          = 8'b0_10_10_?_?? ; //hswish
    parameter LINE          = 8'b1_01_??_?_?? ;
  

    assign cub_activ_relu_mode   = cub_activ_work_op[1:0] ;
    assign cub_activ_prelu_mode  = cub_activ_work_op[2]   ;
    assign cub_activ_hswish_mode = cub_activ_work_op[4:3] ;                         
    assign cub_activ_rslt_mode   = cub_activ_work_op[6:5] ;                         
    assign cub_activ_muladd_mode = cub_activ_work_op[7]   ;
   
    assign  cub_activ_pipe_data     = cub_activ_operand ;
    assign  cub_activ_pipe_valid    = cub_activ_valid   ;
    //----------------------relu6 compute-------------------------//
    assign  cub_activ_relu6_valid_in = cub_activ_muladd_mode ? mul_pdt_truncate_valid : cub_activ_pipe_valid ;
    assign  cub_activ_relu6_datain  = cub_activ_muladd_mode ?  mul_pdt_truncate_r : cub_activ_pipe_data ;
    assign cub_activ_add_relu6_bias_data = cub_activ_relu6_datain + cub_activ_relu6_bias;  
      always@(posedge clk) begin  
         if(cub_activ_relu6_valid_in)
            cub_activ_relu6_rslt_data <= ($signed(cub_activ_add_relu6_bias_data) > $signed(cub_activ_relu6_ref_max)) ? cub_activ_relu6_ref_max :
                           (($signed(cub_activ_add_relu6_bias_data) < $signed(cub_activ_relu6_ref_min)) ? cub_activ_relu6_ref_min : cub_activ_add_relu6_bias_data); 
     end

     logic  cub_activ_relu6_rslt_valid ;
    always@(posedge clk or negedge  rst_n ) begin
        if(!rst_n)
            cub_activ_relu6_rslt_valid <= 'b0;
        else
            cub_activ_relu6_rslt_valid <= cub_activ_relu6_valid_in ; //cub_activ_muladd_mode ? cub_activ_hswish_rslt_valid : cub_activ_pipe_valid;
    end

    //-----------------relu_in pipe register-----------------------------//
   logic cub_activ_relu_data_in_valid;
    
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            cub_activ_relu_data_in <= 'b0;
        end
        else if(cub_activ_pipe_valid)  begin
           cub_activ_relu_data_in <= cub_activ_relu_mode[1] ? cub_activ_relu6_rslt_data : cub_activ_pipe_data;
        end
    end

    //relu valid
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
           cub_activ_relu_data_in_valid <= 'b0;
        end
        else begin
           cub_activ_relu_data_in_valid <= cub_activ_pipe_valid;
        end
    end


    
    
    //relu_out compute
    assign cub_activ_relu_data_out = cub_activ_relu_mode[0] ? cub_activ_relu_data_in : (cub_activ_relu_data_in[DWID-1] ? cub_activ_prelu_neg_data : cub_activ_relu_data_in);
    


     
    //-----------------------------------------prelu------------------------------------------------------//
    //mul_pdt
    logic signed   [DWID-1:0] mul_A, mul_B;
    logic signed   [49:0] mul_pdt_w;
    logic mul_pdt_valid;
    
    always_comb begin
        mul_A = cub_activ_hswish_mode[0] ? cub_activ_relu6_rslt_data : (cub_activ_hswish_mode==2'b10 ? cub_activ_relu_data_in  : cub_activ_pipe_data   )    ; //33bit
    end

    always_comb begin
        mul_B = cub_activ_hswish_mode[1] ? cub_activ_relu6_rslt_data[16:0] : {cub_activ_prelu_scaling[DWID/2-1], cub_activ_prelu_scaling}; //17bit because scaling is int16
    end

   
    //inst mult, reused mult 
    assign   prelu_mult_en                   =  cub_activ_hswish_mode[0] || cub_activ_hswish_mode[1] ?  cub_activ_relu6_rslt_valid  : cub_activ_pipe_valid     ;  //relu6 has one reg pipe when using relu6 rslt
    assign   prelu_mult_multiplicand         =  {mul_A[31],mul_A}  ;
    assign   prelu_mult_multiplier           =  mul_B                    ;

    assign   mul_pdt_w                       =  prelu_mult_product       ;


    always@(posedge clk or negedge rst_n) begin
        if(!rst_n)
           mul_pdt_valid <= 'b0;
        else  begin
           mul_pdt_valid <= prelu_mult_en;
        end
    end


    function    [32-1:0] mul_pdt_shift_left_truncate(input signed    [49:0]  data_in, input [4:0] truncate_Qp);
        logic signed      [49-31:0] truncate_high;
        logic [4:0]    truncate_shift_Qp;
        truncate_shift_Qp=truncate_Qp;
        truncate_high = $signed(data_in[49:31])>>>truncate_shift_Qp;
         mul_pdt_shift_left_truncate = (data_in[49])&&(~& truncate_high)  ?  32'h8000_0000:  //negtive num                                  
                                                 (~data_in[49])&&(| truncate_high)  ?  32'h7fff_ffff:  //postive num
                                                 {data_in[truncate_shift_Qp+:32]}; //recopy signed bit
    endfunction


    assign mul_pdt_truncate = mul_pdt_shift_left_truncate(mul_pdt_w,cub_activ_mul_pdt_Qp);

   
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n)
           mul_pdt_truncate_valid <= 'b0;
        else  begin
           mul_pdt_truncate_valid <= mul_pdt_valid;
        end
    end

    always@(posedge clk ) begin
        if(mul_pdt_valid)
            mul_pdt_truncate_r <= mul_pdt_truncate ;
    end

    

    //prelu neg or relu neg
    always_comb begin
       cub_activ_prelu_neg_data = cub_activ_prelu_mode ?  mul_pdt_truncate : 'd0 ;
    end    



    assign  cub_activ_relu_rslt_data  = cub_activ_relu_data_out;
    assign  cub_activ_relu_rslt_valid = cub_activ_relu_data_in_valid ;

    
    always_comb begin
           cub_activ_hswish_rslt_data  <= mul_pdt_truncate;
           cub_activ_hswish_rslt_valid <= mul_pdt_valid;
    end


 //cub_activ_rslt_data
    always_comb begin
        case(cub_activ_rslt_mode) 
        2'b00: begin//relu,prule
                cub_activ_rslt_valid = cub_activ_relu_data_in_valid ;
                cub_activ_rslt_data  = cub_activ_relu_rslt_data     ;
        end
        2'b01: begin //relu6
                cub_activ_rslt_valid = cub_activ_relu6_rslt_valid   ;
                cub_activ_rslt_data  = cub_activ_relu6_rslt_data    ; 
        end
        2'b10: begin //hsigmoid,hswish
                cub_activ_rslt_valid = cub_activ_hswish_rslt_valid  ;
                cub_activ_rslt_data  = cub_activ_hswish_rslt_data   ;
        end
        2'b11: begin //passthorgh
                cub_activ_rslt_valid = cub_activ_pipe_valid         ;
                cub_activ_rslt_data  = cub_activ_pipe_data          ;
        end
        endcase
    end
   
   assign cub_activ_ready = (!cub_activ_cflow_mode) && cub_activ_rslt_valid;


endmodule
