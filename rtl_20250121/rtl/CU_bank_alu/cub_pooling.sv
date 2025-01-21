module cub_pooling #(
            parameter DWID     = 32  ,
            parameter EWID = 8  // EWID: width of vector's element
            )(
    input                                       clk                             ,
    input                                       rst_n                           ,

    // --------------------------------------------------------------------
    input                                       cub_pooling_en                  , // instr  ex /cflow set 
    input                                       cub_pooling_cflow_mode          , // 1: flow mode 0: instr mode
    //only for instr
    //input  [1:0]                                cub_pooling_operator            , //no use 
    input  [DWID-1:0]                           cub_pooling_op_a                ,
    input  [DWID-1:0]                           cub_pooling_op_b                ,
    //output logic [1:0]                          cub_pooling_cflow_reg0_act    ,
    output logic                                cub_pooling_cflow_reg1_act      ,

    //comparator cflow & instr use
    input                                       cub_pooling_comp_sign           , // 0: signed data 1: unsigned
    input  [1:0]                                cub_pooling_comp_vect           , // 2'b10: int8x4  2'b01: int16x2      2'b00: int32x1
    input  [1:0]                                cub_pooling_comp_mode           , // 2'b11: sub     2'b10:compare(min)  2'b01: compare(max) 2'b00: accumulator

    //only for cflow
    input                                       cub_pooling_cflow_wind_step     ,  // 1:  windsize-1 == step  0: windsize == step
    input  [7:0]                                cub_pooling_cflow_wind_size     ,
    input  [7:0]                                cub_pooling_cflow_data_len      ,
    input  [1:0]                                cub_pooling_cflow_lab_mode      ,  // 2'b0: data 2'b1:label 2'b10: data & label

    //cflow  data in port
    //input  [DWID-1:0]                           cub_pooling_cflow_data        ,
    input                                       cub_pooling_cflow_data_valid    ,    

    // ---------------------------------------------------------------------    
    output reg [3:0][EWID-1:0]                  cub_pooling_vect_rslt            , //replace original cub_pooling_cflow_rslt

    output reg [DWID-1:0]                       cub_pooling_cflow_rslt           ,
    output reg                                  cub_pooling_cflow_rslt_valid     ,
    output                                      cub_pooling_ready                ,
    output                                      cub_pooling_done                
);

assign cub_pooling_ready = (!cub_pooling_cflow_mode)&& cub_pooling_en ;
    // Define parameters for cub_pooling_operator
    localparam ALU_AVG_POOLING = 2'b00; 
    localparam ALU_MAX_POOLING = 2'b01;
    localparam ALU_MIN_POOLING = 2'b10;
    localparam ALU_SUB_POOLING = 2'b11; // reg0 - reg1

    reg                 cub_pooling_sumsub_valid            ;
    reg [3:0][7:0]      cub_pooling_cflow_rslt_lab          ;
 
    reg [DWID-1:0]      cub_pooling_op_reg0                 ;
    reg [DWID-1:0]      cub_pooling_op_reg1                 ;
    

   // assign   cub_pooling_op_a = cub_pooling_op_reg0         ;
   // assign   cub_pooling_op_b = cub_pooling_op_reg1         ; 

    logic [7:0]           cub_pooling_cflow_data_len_cnt ;
    reg   [7:0]           cub_pooling_cflow_rslt_lab_cnt       ;
    reg   [3:0][DWID-1:0] cub_pooling_cflow_rslt_tmp_lab        ;
    reg   [7:0]           pooling_wind_data_cnt          ;

    // FSM states
    enum logic [1:0] {
    POOL_IDLE        = 'b00 ,
    POOL_PIP_R0_R1   = 'b01 ,
    POOL_FU_TO_R1    = 'b10 ,
    POOL_FU_TO_RSLT  = 'b11
    } pl_cs, pl_ns;
    

    wire cub_pooling_cflow_data_last = (cub_pooling_cflow_data_len_cnt == cub_pooling_cflow_data_len-1)&&cub_pooling_cflow_data_valid;

    wire  [4:0] cub_pooling_cflow_wind_size_sub_two = cub_pooling_cflow_wind_size -2;
    wire        cub_pooling_calculate_last_valid    = cub_pooling_cflow_data_valid && cub_pooling_cflow_data_last;


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            cub_pooling_cflow_data_len_cnt <=  'b0 ;
        else if((cub_pooling_cflow_data_len_cnt == cub_pooling_cflow_data_len-1) && cub_pooling_cflow_data_valid)
            cub_pooling_cflow_data_len_cnt <=  'b0 ;
        else if(cub_pooling_cflow_data_valid) begin
            cub_pooling_cflow_data_len_cnt <=  cub_pooling_cflow_data_len_cnt + 'b1 ;
        end
    end
    
  
    // FSM state transition
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pl_cs <= POOL_IDLE;
        end 
        else if(cub_pooling_cflow_mode) begin //cflow mode ,state change
            pl_cs <= pl_ns;
        end
        else
            pl_cs <= POOL_IDLE;
    end

    // FSM next state logic
    always @(*) begin
        pl_ns = POOL_IDLE; 
        case (pl_cs)
            POOL_IDLE: begin
                if ( cub_pooling_cflow_mode) 
                    pl_ns = POOL_PIP_R0_R1;
                else   
                    pl_ns = POOL_IDLE;
            end
            POOL_PIP_R0_R1: begin           
                  if(!cub_pooling_cflow_mode)
                    pl_ns = POOL_IDLE;
                  else if(cub_pooling_cflow_data_valid) begin //wait data valid input
                    if (cub_pooling_calculate_last_valid) 
                         pl_ns = POOL_IDLE; 
                   else if(cub_pooling_cflow_wind_size  == 'd2 )  //wind=2 special process: Jump  POOL_PIP_RO_R1 to  POOL_FU_TO_R1 until pooling_wind_data_cnt ==1, which means 2 cycles for POOL_PIP_RO_R1
                         pl_ns = POOL_FU_TO_RSLT;                        
                   else if(pooling_wind_data_cnt  == 'd1 &&  cub_pooling_cflow_wind_size  == 'd3)  //wind=3
                         pl_ns = POOL_FU_TO_RSLT; 
                   else if(pooling_wind_data_cnt  == 'd1  )  //wind > 3, load r0,r1 in POOL_PIP_R0_R1 state
                         pl_ns = POOL_FU_TO_R1;
                   else
                         pl_ns = POOL_PIP_R0_R1;
                end
                else 
                         pl_ns = POOL_PIP_R0_R1;
            end
          POOL_FU_TO_R1: begin  //wind size > 3
                 if(cub_pooling_cflow_data_valid) begin //wait data valid input
                    if (cub_pooling_calculate_last_valid) 
                         pl_ns = POOL_IDLE; 
                   else if(pooling_wind_data_cnt == cub_pooling_cflow_wind_size_sub_two)       
                         pl_ns = POOL_FU_TO_RSLT;                        
                   else
                         pl_ns = POOL_FU_TO_R1;
                end
                else
                         pl_ns = POOL_FU_TO_R1;
            end
           POOL_FU_TO_RSLT: begin             
                if (cub_pooling_cflow_data_valid) begin
                    if ( !cub_pooling_cflow_data_last) 
                        pl_ns = POOL_PIP_R0_R1;                   
                   else
                        pl_ns = POOL_IDLE; 
                end
                else    
                        pl_ns = POOL_FU_TO_RSLT;
            end
            default: begin
                pl_ns = POOL_IDLE;
            end
        endcase
    end

    // wind cnt in the pooling process for each cub_pooling window
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pooling_wind_data_cnt <=  'd0;
        end else begin
            case(pl_cs)
                POOL_IDLE :
                    pooling_wind_data_cnt <= 'd0;
                POOL_PIP_R0_R1 ,
                POOL_FU_TO_R1 :
                    if(cub_pooling_cflow_data_valid)
                        pooling_wind_data_cnt <= pooling_wind_data_cnt + 'd1;
                POOL_FU_TO_RSLT: begin
                   if (cub_pooling_cflow_data_valid) begin
                        if(cub_pooling_cflow_wind_step == 1) 
                            pooling_wind_data_cnt <= 'd1;
                        else 
                            pooling_wind_data_cnt <= 'd0;
                    end
                end
               default :  pooling_wind_data_cnt <= pooling_wind_data_cnt; 
            endcase           
        end
    end 
    
    // FSM  control reg0/reg1

  //  always @(posedge clk or negedge rst_n) begin
  //      if (!rst_n) begin
  //          cub_pooling_op_reg0 <= 32'd0 ;
  //          cub_pooling_op_reg1 <= 32'd0 ;
  //      end else begin
  //          case (pl_cs)
  //                  POOL_IDLE: begin
  //                      if(cub_pooling_en && !cub_pooling_cflow_mode) begin
  //                      case(cub_pooling_operator)  
  //                      2'b00:  begin 
  //                          cub_pooling_op_reg0 <= cub_pooling_op_a;
  //                          cub_pooling_op_reg1 <= cub_pooling_op_b;
  //                          end
  //                      2'b01: begin
  //                          cub_pooling_op_reg0 <= cub_pooling_op_a;
  //                          cub_pooling_op_reg1 <= cub_pooling_op_reg0;
  //                          end
  //                      2'b10: begin
  //                          cub_pooling_op_reg0 <= cub_pooling_op_a;
  //                          cub_pooling_op_reg1 <= cub_pooling_vect_rslt;
  //                          end
  //                      2'b11: begin
  //                          cub_pooling_op_reg0 <= cub_pooling_op_a;
  //                          cub_pooling_op_reg1 <= cub_pooling_vect_rslt;
  //                          end
  //                      endcase
  //                  end
  //              end
  //             POOL_PIP_R0_R1: begin
  //                  if(cub_pooling_cflow_data_valid) begin
  //                      cub_pooling_op_reg1 <= cub_pooling_op_reg0;
  //                      cub_pooling_op_reg0 <= cub_pooling_cflow_data;                                            
  //                  end
  //              end
  //             POOL_FU_TO_R1 :begin
  //                  if(cub_pooling_cflow_data_valid) begin
  //                      cub_pooling_op_reg1 <= cub_pooling_vect_rslt;
  //                      cub_pooling_op_reg0 <= cub_pooling_cflow_data;                                            
  //                  end
  //             end
  //              POOL_FU_TO_RSLT: begin
  //                  if (cub_pooling_cflow_data_valid) begin
  //                      //reg0
  //                          cub_pooling_op_reg0 <= cub_pooling_cflow_data;
  //                      //reg1
  //                     // if(cub_pooling_cflow_wind_size > 2) 
  //                     //     cub_pooling_op_reg1 <= cub_pooling_vect_rslt;
  //                     // else 
  //                          cub_pooling_op_reg1 <= cub_pooling_op_reg0;
  //                  end
  //              end
  //              default: begin
  //                          cub_pooling_op_reg0 <= cub_pooling_op_a;
  //                          cub_pooling_op_reg1 <= cub_pooling_op_b;                
  //              end
  //          endcase
  //      end
  //  end
   parameter   R0_PIP_R1   = 1'b0 ;
   parameter   RSLT_PIP_R1 = 1'b1 ;
    always_comb begin
           cub_pooling_cflow_reg1_act = 1'b0 ;
            case (pl_cs)
              // POOL_IDLE: begin
              //  end
               POOL_PIP_R0_R1: begin
                    if(cub_pooling_cflow_data_valid) begin
                        cub_pooling_cflow_reg1_act = R0_PIP_R1 ; //cub_pooling_op_reg1 <= cub_pooling_op_reg0;
                        //cub_pooling_op_reg0 <= cub_pooling_cflow_data;                                            
                    end
                end
               POOL_FU_TO_R1 :begin
                    if(cub_pooling_cflow_data_valid) begin
                        cub_pooling_cflow_reg1_act = RSLT_PIP_R1 ; //cub_pooling_op_reg1 <= cub_pooling_cflow_rslt;
                        //cub_pooling_op_reg0 <= cub_pooling_cflow_data;                                            
                    end
               end
                POOL_FU_TO_RSLT: begin
                    if (cub_pooling_cflow_data_valid) begin
                        // cub_pooling_op_reg0 <= cub_pooling_cflow_data;
                        if(cub_pooling_cflow_wind_size > 2)  //wind = 3,
                            cub_pooling_cflow_reg1_act = RSLT_PIP_R1 ;//cub_pooling_op_reg1 <= cub_pooling_cflow_rslt;
                        else 
                            cub_pooling_cflow_reg1_act = R0_PIP_R1 ;
                    end
                end
                default: begin
                end
            endcase
        end
    //-----------------lab cnt-----------------------//
    always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cub_pooling_cflow_rslt_lab_cnt <= 'b0 ;
    else if(cub_pooling_cflow_mode) begin
            case (pl_cs)
               POOL_IDLE: begin
                    cub_pooling_cflow_rslt_lab_cnt <= 'b0 ;
                end
               POOL_PIP_R0_R1: begin
                    if(cub_pooling_cflow_data_valid && pooling_wind_data_cnt  == 'd1) begin
                        cub_pooling_cflow_rslt_lab_cnt <= cub_pooling_cflow_rslt_lab_cnt  +  1 ;
                    end
                    else
                        cub_pooling_cflow_rslt_lab_cnt <= 'b0 ;
                end
               POOL_FU_TO_R1 :begin
                    if(cub_pooling_cflow_data_valid) begin
                        cub_pooling_cflow_rslt_lab_cnt <= cub_pooling_cflow_rslt_lab_cnt  +  1 ;
                    end
               end
                POOL_FU_TO_RSLT: begin
                    if (cub_pooling_cflow_data_valid) begin
                        //if(cub_pooling_cflow_wind_ == 1) 
                            cub_pooling_cflow_rslt_lab_cnt <= cub_pooling_cflow_rslt_lab_cnt  +  1 ;
                        //else 
                        //    cub_pooling_cflow_rslt_lab_cnt <= 'b0 ;
                    end
                end
                default: begin
                end
            endcase
        end
     else
        cub_pooling_cflow_rslt_lab_cnt <= 'b0 ;
    end

    //-----------------------------------------------------------------------------//
    //founction unit : comparator
    parameter SEL_ZERO  =  3'b000;
    parameter SEL_ONES  =  3'b001;
    parameter SEL_A     =  3'b010;
    parameter SEL_B     =  3'b011;
    parameter SEL_SUM   =  3'b100;

 

   function [EWID-1+3:0] cub_pooling_comparator;
       input  [EWID-1:0]           A          ;
       input  [EWID-1:0]           B          ;
       input  [EWID  :0]           sumsub     ;

       input  [1:0]                comp_mode  ; //11:sub 10:compare(min) 01: compare(max) 00: accumulator
       input                       comp_sign  ; //1: unsigned 0: signed

       logic                       overflow   ;

       begin
           cub_pooling_comparator = 'b0;

           if(comp_sign == 1'b1) begin //unsigned
               case(comp_mode) 
                   2'b00:  begin 
                           cub_pooling_comparator[EWID-1 :0] = sumsub[EWID] ? {EWID{1'b1}} : sumsub[EWID-1:0];//acc, if  sumsub[EWID] == 1,then rslt is negative and overflow
                           cub_pooling_comparator[EWID  +:3] = sumsub[EWID] ? SEL_ONES     : SEL_SUM         ; 
                           end                             
                   2'b01:  begin                           
                           cub_pooling_comparator[EWID-1 :0] = sumsub[EWID] ?          A : B        ;  //compare(big)
                           cub_pooling_comparator[EWID  +:3] = sumsub[EWID] ?      SEL_A : SEL_B    ; 
                           end                   
                   2'b10:  begin                 
                           cub_pooling_comparator[EWID-1 :0] = sumsub[EWID] ?          B : A        ; //compare(small)
                           cub_pooling_comparator[EWID  +:3] = sumsub[EWID] ?      SEL_B : SEL_A    ; 
                           end                   
                   2'b11:  begin                 
                           cub_pooling_comparator[EWID-1 :0] = sumsub[EWID] ? sumsub[EWID-1:0]: {EWID{1'b0}} ;//sub, if  sumsub[EWID] == 1,then rslt is positive
                           cub_pooling_comparator[EWID  +:3] = sumsub[EWID] ?          SEL_SUM: SEL_ZERO     ; 
                           end
               endcase
           end
           else begin
               overflow = ( comp_mode !=2'b0 ) ? ( A[EWID-1]&~B[EWID-1]& ~sumsub[EWID-1] || ~A[EWID-1]&B[EWID-1]&sumsub[EWID-1] ) : ( A[EWID-1]&B[EWID-1]&~sumsub[EWID-1] || ~A[EWID-1]&~B[EWID-1]&sumsub[EWID-1]);
               case(comp_mode) 
                   2'b00:  begin
                           cub_pooling_comparator[EWID-1 :0] = overflow ? (A[EWID-1] ? {1'b1,{EWID-1{1'b0}}} : {1'b0,{EWID-1{1'b1}}}) : sumsub    ;//acc
                           cub_pooling_comparator[EWID  +:3] = overflow ? (A[EWID-1] ?          SEL_ZERO     : SEL_ONES             ) : SEL_SUM   ; 
                           end                             
                   2'b01:  begin                           
                           cub_pooling_comparator[EWID-1 :0] = overflow ? (A[EWID-1] ?        B :     A ) : (sumsub[EWID-1] ?     B :     A); //compare(big)
                           cub_pooling_comparator[EWID  +:3] = overflow ? (A[EWID-1] ?    SEL_B : SEL_A ) : (sumsub[EWID-1] ? SEL_B : SEL_A); 
                           end                   
                   2'b10:  begin                 
                           cub_pooling_comparator[EWID-1 :0] = overflow ? (A[EWID-1] ?        A :     B ) : (sumsub[EWID-1] ?     A :     B); //compare(small)
                           cub_pooling_comparator[EWID  +:3] = overflow ? (A[EWID-1] ?    SEL_A : SEL_B ) : (sumsub[EWID-1] ? SEL_A : SEL_B); 
                           end                   
                   2'b11:  begin                 
                           cub_pooling_comparator[EWID-1 :0] = overflow ? (A[EWID-1] ? {1'b1,{EWID-1{1'b0}}} : {1'b0,{EWID-1{1'b1}}}) : sumsub;//sub
                           cub_pooling_comparator[EWID  +:3] = overflow ? (A[EWID-1] ?              SEL_ZERO :             SEL_ONES ) : SEL_SUM; 
                           end
               endcase
           end
       end
       
   endfunction

   //-------------------------   sel function   -------------------------------------//
     function [EWID-1:0] cub_pooling_vect_sel;
       input  [2:0]                sel        ;
       input  [EWID-1:0]           A          ;
       input  [EWID-1:0]           B          ;
       input  [EWID  :0]           sumsub     ;

        case(sel)
        SEL_ZERO  :  cub_pooling_vect_sel  = {EWID{1'b0}}       ;
        SEL_ONES  :  cub_pooling_vect_sel  = {EWID{1'b1}}       ;
        SEL_A     :  cub_pooling_vect_sel  = A                  ;
        SEL_B     :  cub_pooling_vect_sel  = B                  ;
        SEL_SUM   :  cub_pooling_vect_sel  = sumsub[EWID-1:0]   ;
        default   :  cub_pooling_vect_sel  = {EWID{1'b0}}       ;
        endcase

    endfunction
   //--------------------------------------------------------------------------------//

    // 2'b10: int8x4  2'b01: int16x2   2'b00: int32x1/
    parameter VECT_MODE32 = 2'b00 ;
    parameter VECT_MODE16 = 2'b01 ;
    parameter VECT_MODE8  = 2'b10 ;
    parameter VECT_CCNI16 = 2'b11 ;

    //founction unit : comparator
    logic  [DWID-1:0]     cub_pooling_fu_rslt;

    


    logic  [DWID-1:0]   adder_in_a_i, adder_in_b_i;
    logic  [DWID-1:0]   cub_pooling_op_b_neg ;
    logic  [DWID-1:0]   adder_result ;
    logic  [36:0]       adder_in_a  , adder_in_b  , adder_result_expanded;

    logic  [3:0][EWID-1+3:0]   adder_result_segment;

    logic  [3:0]        vect_max_rslt_sel ;
    //----------------------------------------comparator function unit-------------------------------------------------//
  always_comb begin
         //prepare operand b
          vect_max_rslt_sel = 4'b0;
          cub_pooling_op_b_neg = cub_pooling_comp_vect == VECT_CCNI16 ? { cub_pooling_op_b[31:16], ~cub_pooling_op_b[15:0] }: ~cub_pooling_op_b ;
          
          adder_in_b_i = (cub_pooling_comp_mode !=  2'b00) ? cub_pooling_op_b_neg : cub_pooling_op_b;

          adder_in_a_i = cub_pooling_op_a ;

          //prepare carry
          adder_in_a[    0] = 1'b1;
          adder_in_a[ 8: 1] = adder_in_a_i[ 7: 0];
          adder_in_a[    9] = 1'b1;
          adder_in_a[17:10] = adder_in_a_i[15: 8];
          adder_in_a[   18] = 1'b1;
          adder_in_a[26:19] = adder_in_a_i[23:16];
          adder_in_a[   27] = 1'b1;
          adder_in_a[35:28] = adder_in_a_i[31:24];
          adder_in_a[   36] = 1'b0;

          adder_in_b[    0] = 1'b0; //special case for subtractions and absolute number calculations, other computes is sub except acc/add
          adder_in_b[ 8: 1] = adder_in_b_i[ 7: 0];
          adder_in_b[    9] = 1'b0;
          adder_in_b[17:10] = adder_in_b_i[15: 8];
          adder_in_b[   18] = 1'b0;
          adder_in_b[26:19] = adder_in_b_i[23:16];
          adder_in_b[   27] = 1'b0;
          adder_in_b[35:28] = adder_in_b_i[31:24];
          adder_in_b[   36] = 1'b0;

            // special case for subtractions and absolute number calculations
          if (cub_pooling_comp_mode != 2'b00 ) begin 
            adder_in_b[0] = 1'b1;

            case (cub_pooling_comp_vect)
              VECT_MODE16: begin
                adder_in_b[18] = 1'b1;
              end

              VECT_CCNI16: begin
                adder_in_a[18] = 1'b0;
                adder_in_b[18] = 1'b0;
              end

              VECT_MODE8: begin
                adder_in_b[ 9] = 1'b1;
                adder_in_b[18] = 1'b1;
                adder_in_b[27] = 1'b1;
              end
            endcase

          end else begin //add/acc
            // take care of partitioning the adder for the addition case
            case (cub_pooling_comp_vect)
              VECT_MODE16: begin
                adder_in_a[18] = 1'b0;
              end

              VECT_MODE8: begin
                adder_in_a[ 9] = 1'b0;
                adder_in_a[18] = 1'b0;
                adder_in_a[27] = 1'b0;
              end
            endcase
          end

          //actual adder
          adder_result_expanded  = $signed(adder_in_a) + $signed(adder_in_b);
           


         adder_result = {adder_result_expanded[35:28],
                         adder_result_expanded[26:19],
                         adder_result_expanded[17:10],
                         adder_result_expanded[8 :1 ]};



         //--------------------------------------------------------------------------------------------------------------------------------------------------------//
         //vector process
          adder_result_segment[3] =  cub_pooling_comparator(cub_pooling_op_a[31:24],cub_pooling_op_b[31:24],adder_result_expanded[36:28], cub_pooling_comp_mode,cub_pooling_comp_sign);
          adder_result_segment[2] =  cub_pooling_comparator(cub_pooling_op_a[23:16],cub_pooling_op_b[23:16],adder_result_expanded[27:19], cub_pooling_comp_mode,cub_pooling_comp_sign);
          adder_result_segment[1] =  cub_pooling_comparator(cub_pooling_op_a[15: 8],cub_pooling_op_b[15: 8],adder_result_expanded[18:10], cub_pooling_comp_mode,cub_pooling_comp_sign);
          adder_result_segment[0] =  cub_pooling_comparator(cub_pooling_op_a[ 7: 0],cub_pooling_op_b[ 7: 0],adder_result_expanded[9 : 1], cub_pooling_comp_mode,cub_pooling_comp_sign);

          case (cub_pooling_comp_vect)
              VECT_MODE32: begin
                  cub_pooling_vect_rslt[3] =   adder_result_segment[3][EWID-1:0] ;
                  cub_pooling_vect_rslt[2] =   cub_pooling_vect_sel(adder_result_segment[3][EWID+2:EWID], cub_pooling_op_a[23:16],cub_pooling_op_b[23:16],adder_result_expanded[27:19]);
                  cub_pooling_vect_rslt[1] =   cub_pooling_vect_sel(adder_result_segment[3][EWID+2:EWID], cub_pooling_op_a[15: 8],cub_pooling_op_b[15: 8],adder_result_expanded[18:10]);
                  cub_pooling_vect_rslt[0] =   cub_pooling_vect_sel(adder_result_segment[3][EWID+2:EWID], cub_pooling_op_a[ 7: 0],cub_pooling_op_b[ 7: 0],adder_result_expanded[9 : 1]);
                  vect_max_rslt_sel       =   adder_result_segment[3][EWID+2:EWID] == SEL_A ?   4'b1 : 4'b0;
              end
              VECT_CCNI16,
              VECT_MODE16: begin
                  cub_pooling_vect_rslt[3] =   adder_result_segment[3][EWID-1:0] ;
                  cub_pooling_vect_rslt[2] =   cub_pooling_vect_sel(adder_result_segment[3][EWID+2:EWID], cub_pooling_op_a[23:16],cub_pooling_op_b[23:16],adder_result_expanded[27:19]);
                  cub_pooling_vect_rslt[1] =   adder_result_segment[1][EWID-1:0] ;
                  cub_pooling_vect_rslt[0] =   cub_pooling_vect_sel(adder_result_segment[1][EWID+2:EWID], cub_pooling_op_a[ 7: 0],cub_pooling_op_b[ 7: 0],adder_result_expanded[9 : 1]);
                  vect_max_rslt_sel       =   {2'b0,adder_result_segment[3][EWID+2:EWID] == SEL_A ?   1'b1 : 1'b0, adder_result_segment[1][EWID+2:EWID] == SEL_A ?   1'b1 : 1'b0} ;
              end

              VECT_MODE8: begin
                  cub_pooling_vect_rslt[3] =   adder_result_segment[3][EWID-1:0] ;
                  cub_pooling_vect_rslt[2] =   adder_result_segment[2][EWID-1:0] ;
                  cub_pooling_vect_rslt[1] =   adder_result_segment[1][EWID-1:0] ;
                  cub_pooling_vect_rslt[0] =   adder_result_segment[0][EWID-1:0] ;
                  vect_max_rslt_sel       =   {adder_result_segment[3][EWID+2:EWID] == SEL_A ?   1'b1 : 1'b0, adder_result_segment[2][EWID+2:EWID] == SEL_A ?   1'b1 : 1'b0 , adder_result_segment[1][EWID+2:EWID] == SEL_A ?   1'b1 : 1'b0, adder_result_segment[0][EWID+2:EWID] == SEL_A ?   1'b1 : 1'b0} ;
              end
              default: begin
                  cub_pooling_vect_rslt[3] =   adder_result_segment[3][EWID-1:0] ;
                  cub_pooling_vect_rslt[2] =   cub_pooling_vect_sel(adder_result_segment[3][EWID+2:EWID], cub_pooling_op_a[23:16],cub_pooling_op_b[23:16],adder_result_expanded[27:19]);
                  cub_pooling_vect_rslt[1] =   cub_pooling_vect_sel(adder_result_segment[3][EWID+2:EWID], cub_pooling_op_a[15: 8],cub_pooling_op_b[15: 8],adder_result_expanded[18:10]);
                  cub_pooling_vect_rslt[0] =   cub_pooling_vect_sel(adder_result_segment[3][EWID+2:EWID], cub_pooling_op_a[ 7: 0],cub_pooling_op_b[ 7: 0],adder_result_expanded[9 : 1]);
                  vect_max_rslt_sel       =   {adder_result_segment[3][EWID+2:EWID] == SEL_A ?   1 : 0 } ;

              end
            endcase

          
    end

    //reg   [3:0][DWID-1:0] cub_pooling_cflow_rslt_tmp_lab        ;
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            cub_pooling_cflow_rslt_tmp_lab <= 'b0;
        else if(  cub_pooling_cflow_rslt_lab_cnt == 'b0)
            cub_pooling_cflow_rslt_tmp_lab <= 'b0;
        else if((cub_pooling_comp_mode == 2'b01 || cub_pooling_comp_mode == 2'b10 ) && cub_pooling_cflow_mode && cub_pooling_cflow_data_valid && cub_pooling_cflow_rslt_lab_cnt != 0) begin
            case(cub_pooling_comp_vect)
            VECT_MODE32 : begin
                cub_pooling_cflow_rslt_tmp_lab[0] <= vect_max_rslt_sel[0] == 1'b1 ?  cub_pooling_cflow_rslt_lab_cnt : cub_pooling_cflow_rslt_tmp_lab[0];
            end
            VECT_MODE16 : begin
                cub_pooling_cflow_rslt_tmp_lab[0] <= vect_max_rslt_sel[0] == 1'b1 ?  cub_pooling_cflow_rslt_lab_cnt : cub_pooling_cflow_rslt_tmp_lab[0];
                cub_pooling_cflow_rslt_tmp_lab[1] <= vect_max_rslt_sel[1] == 1'b1 ?  cub_pooling_cflow_rslt_lab_cnt : cub_pooling_cflow_rslt_tmp_lab[1];
            end
            VECT_MODE8  : begin
                cub_pooling_cflow_rslt_tmp_lab[0] <= vect_max_rslt_sel[0] == 1'b1 ?  cub_pooling_cflow_rslt_lab_cnt : cub_pooling_cflow_rslt_tmp_lab[0];
                cub_pooling_cflow_rslt_tmp_lab[1] <= vect_max_rslt_sel[1] == 1'b1 ?  cub_pooling_cflow_rslt_lab_cnt : cub_pooling_cflow_rslt_tmp_lab[1];
                cub_pooling_cflow_rslt_tmp_lab[2] <= vect_max_rslt_sel[2] == 1'b1 ?  cub_pooling_cflow_rslt_lab_cnt : cub_pooling_cflow_rslt_tmp_lab[2];
                cub_pooling_cflow_rslt_tmp_lab[3] <= vect_max_rslt_sel[3] == 1'b1 ?  cub_pooling_cflow_rslt_lab_cnt : cub_pooling_cflow_rslt_tmp_lab[3];
            end
            default     :
                cub_pooling_cflow_rslt_tmp_lab[0] <= vect_max_rslt_sel[0] == 1'b1 ?  cub_pooling_cflow_rslt_lab_cnt : cub_pooling_cflow_rslt_tmp_lab[0];
            endcase
        end
    end

    //-----------------------------------------------------//

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            cub_pooling_sumsub_valid <= 'b0;
        else if(!cub_pooling_cflow_mode)     
            cub_pooling_sumsub_valid <= 'b0;
        else begin 
            case (pl_cs)
            POOL_PIP_R0_R1,
            POOL_FU_TO_R1:
                if(cub_pooling_cflow_data_last) 
                    cub_pooling_sumsub_valid <= 1'b1;
                else
                    cub_pooling_sumsub_valid <= 1'b0;
            POOL_FU_TO_RSLT :
                cub_pooling_sumsub_valid <= cub_pooling_cflow_data_valid;
            default :
                cub_pooling_sumsub_valid <= 1'b0;
            endcase
      end
    end

    always_comb begin
        cub_pooling_cflow_rslt_lab = 'b0;
      case(cub_pooling_comp_vect)
      VECT_MODE32 : begin
          cub_pooling_cflow_rslt_lab[0] = vect_max_rslt_sel[0] ? cub_pooling_cflow_rslt_lab_cnt : cub_pooling_cflow_rslt_tmp_lab[0];
        end                                                                          
      VECT_MODE16 : begin                                                            
          cub_pooling_cflow_rslt_lab[0] = vect_max_rslt_sel[0] ? cub_pooling_cflow_rslt_lab_cnt : cub_pooling_cflow_rslt_tmp_lab[0];
          cub_pooling_cflow_rslt_lab[1] = vect_max_rslt_sel[1] ? cub_pooling_cflow_rslt_lab_cnt : cub_pooling_cflow_rslt_tmp_lab[1];
        end                                                                          
      VECT_MODE8  : begin                                                            
          cub_pooling_cflow_rslt_lab[0] = vect_max_rslt_sel[0] ? cub_pooling_cflow_rslt_lab_cnt : cub_pooling_cflow_rslt_tmp_lab[0];
          cub_pooling_cflow_rslt_lab[1] = vect_max_rslt_sel[1] ? cub_pooling_cflow_rslt_lab_cnt : cub_pooling_cflow_rslt_tmp_lab[1];
          cub_pooling_cflow_rslt_lab[2] = vect_max_rslt_sel[2] ? cub_pooling_cflow_rslt_lab_cnt : cub_pooling_cflow_rslt_tmp_lab[2];
          cub_pooling_cflow_rslt_lab[3] = vect_max_rslt_sel[3] ? cub_pooling_cflow_rslt_lab_cnt : cub_pooling_cflow_rslt_tmp_lab[3];
        end
      default     :
          cub_pooling_cflow_rslt_lab[0] = vect_max_rslt_sel[0] ? cub_pooling_cflow_rslt_lab_cnt : cub_pooling_cflow_rslt_tmp_lab[0];
      endcase
    end

    reg cub_pooling_cflow_rslt_lab_valid ;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            cub_pooling_cflow_rslt_lab_valid <= 'b0;
        else if(!cub_pooling_cflow_mode)
            cub_pooling_cflow_rslt_lab_valid <= 'b0;
        else
            cub_pooling_cflow_rslt_lab_valid <= cub_pooling_cflow_lab_mode ==2'b10 ? cub_pooling_sumsub_valid : 1'b0; //expand one lab cycle
            
    end

    always_comb begin
        if(!cub_pooling_cflow_mode)
            cub_pooling_cflow_rslt =  cub_pooling_vect_rslt;
        else if(cub_pooling_sumsub_valid)
            cub_pooling_cflow_rslt = cub_pooling_cflow_lab_mode == 2'b01 ? cub_pooling_cflow_rslt_lab :   cub_pooling_vect_rslt ; 
        else if(cub_pooling_cflow_rslt_lab_valid)
            cub_pooling_cflow_rslt = cub_pooling_cflow_rslt_tmp_lab; //delay  cub_pooling_cflow_rslt_lab
        else
            cub_pooling_cflow_rslt =  cub_pooling_vect_rslt;
    end

    always_comb begin
            cub_pooling_cflow_rslt_valid =  cub_pooling_cflow_lab_mode != 2'b10 ? cub_pooling_sumsub_valid : cub_pooling_sumsub_valid|cub_pooling_cflow_rslt_lab_valid;
    end


endmodule
