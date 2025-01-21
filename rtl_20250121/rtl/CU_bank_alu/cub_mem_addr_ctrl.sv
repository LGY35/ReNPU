module cub_mem_addr_ctrl #()
        (
   input                                                                    clk                     ,
   input                                                                    rst_n                   ,
   //-----------------------------------------------------------------------------------------------//
    //signals from ex stage
   input                                                                    cub_mem_op_sta_clr      ,
   input                                                                    cub_mem_op_enable       ,
   input         [1:0]                                                      cub_mem_sel             ,   // mem bank sel 00: l1b 01: cram 10,11:sharecache
   input         [4:0]                                                      cub_mem_rdst_greg_in    ,   // dst general regs
   input                                                                    cub_mem_we              ,   // 1: write 0: read
   input         [1:0 ]                                                     cub_mem_data_type       ,   //00:word, 01:halfword, 11,10:byte  -> from ex stage
   input         [31:0]                                                     cub_mem_wr_data         ,
   input                                                                    cub_mem_rdata_sign_ext   ,    //sign extension                    -> from ex stage
   input         [31:0]                                                     cub_mem_operand_a       ,    //operand a from RF for address 16bit    -> from ex stage
   input         [31:0]                                                     cub_mem_operand_b       ,    //operand b from RF for address 16bit    -> from ex stage 
   output logic                                                             cub_mem_rvalid        ,
   output logic  [31:0]                                                     cub_mem_rdata         ,
   output logic  [4:0]                                                      cub_mem_rdst_greg_out ,
   output logic                                                             cub_mem_l1b_rdst_crossbar_en,

   //----------------------------------------------------------------------------------------------//
   //l1b
   output logic                                                             cub_mif_data_l1b_req        ,
   output logic                                                             cub_mif_data_cram_req       ,
   output logic                                                             cub_mif_data_scache_req     ,
   output logic                                                             cub_mif_data_we             ,
   output logic  [3 : 0]                                                    cub_mif_data_be             ,
   output logic  [31: 0]                                                    cub_mif_data_wdata          ,
   output logic  [15-2 : 0]                                                 cub_mif_data_addr           , //word addr
   input                                                                    cub_mif_data_l1b_gnt        ,
   input                                                                    cub_mif_data_l1b_rvalid     ,
   input         [31 : 0]                                                   cub_mif_data_l1b_rdata      ,
   input                                                                    cub_mif_data_cram_gnt       ,
   input                                                                    cub_mif_data_cram_rvalid    ,
   input         [31 : 0]                                                   cub_mif_data_cram_rdata     ,
   input                                                                    cub_mif_data_scache_gnt     ,
   input                                                                    cub_mif_data_scache_rvalid  ,
   input         [31 : 0]                                                   cub_mif_data_scache_rdata   
   );


   //----------------------- memory select-----------------------------//
   parameter  L1B_SEL       = 2'b00 ;
   parameter  CRAM_SEL      = 2'b01 ;
   parameter  SCACHE_SEL    = 2'b10 ;
  // parameter  REGFILE_SEL   = 2'b11 ;
   
   always_comb begin 
    case(cub_mem_sel)
        L1B_SEL     : begin cub_mif_data_l1b_req = cub_mem_op_enable ;  cub_mif_data_cram_req = 1'b0; cub_mif_data_scache_req =1'b0; end
        CRAM_SEL    : begin cub_mif_data_l1b_req = 1'b0 ;  cub_mif_data_cram_req = cub_mem_op_enable; cub_mif_data_scache_req =1'b0; end
        SCACHE_SEL  : begin cub_mif_data_l1b_req = 1'b0 ;  cub_mif_data_cram_req = 1'b0; cub_mif_data_scache_req = cub_mem_op_enable; end
        default     : begin cub_mif_data_l1b_req = 1'b0 ;  cub_mif_data_cram_req = 1'b0; cub_mif_data_scache_req = cub_mem_op_enable; end //default: sharecache
    endcase
   end
  
 //-----------------------write / read enable--------------------------//
 assign cub_mif_data_we = cub_mem_we  ;  

 //
 wire [15:0]  cub_mem_bt_addr = cub_mem_operand_a[15:0]  +  cub_mem_operand_b[15:0] ;
 assign       cub_mif_data_addr = { cub_mem_bt_addr[15:2] };

 wire [1:0]   cub_mem_bt_addr_offset =  cub_mem_bt_addr[1:0];


//---------------------------------bitmask----------------------------------//
 //00:word, 01:halfword, 11,10:byte
 parameter WORD_TYPE    = 2'b00     ;
 parameter HALFWORD_TYPE= 2'b01     ;
 parameter BYTE_TYPE    = 2'b10     ;
 parameter DEFAULT_TYPE = 2'b11     ; //default :byte

 //BE generation
    always_comb begin
      case(cub_mem_data_type) //Data type 00 Word, 01 Half word, 11,10 byte
       WORD_TYPE: begin // Writing a word
            cub_mif_data_be = 4'b1111;
        end

   HALFWORD_TYPE: begin // Writing a half word
            case(cub_mem_bt_addr_offset[1])
              1'b0: cub_mif_data_be = 4'b0011;
              1'b1: cub_mif_data_be = 4'b1100;
            endcase
        end

      BYTE_TYPE,
      DEFAULT_TYPE: begin // Writing a byte
          case (cub_mem_bt_addr_offset[1:0])
            2'b00: cub_mif_data_be = 4'b0001;
            2'b01: cub_mif_data_be = 4'b0010;
            2'b10: cub_mif_data_be = 4'b0100;
            2'b11: cub_mif_data_be = 4'b1000;
          endcase
        end
      endcase

    end

    //---------------------------------write data----------------------------------//
      always_comb begin
      case(cub_mem_data_type) //Data type 00 Word, 01 Half word, 11,10 byte
       WORD_TYPE: begin // Writing a word
            cub_mif_data_wdata = cub_mem_wr_data;
        end

   HALFWORD_TYPE: begin // Writing a half word
            case(cub_mem_bt_addr_offset[1])
              1'b0: cub_mif_data_wdata = cub_mem_wr_data;
              1'b1: cub_mif_data_wdata = cub_mem_wr_data<<16;
            endcase
        end

      BYTE_TYPE,
      DEFAULT_TYPE: begin // Writing a byte
          case (cub_mem_bt_addr_offset[1:0])
            2'b00:  cub_mif_data_wdata = cub_mem_wr_data;
            2'b01:  cub_mif_data_wdata = cub_mem_wr_data << 8;
            2'b10:  cub_mif_data_wdata = cub_mem_wr_data << 16;
            2'b11:  cub_mif_data_wdata = cub_mem_wr_data << 24;
           // default:cub_mif_data_wdata = cub_mem_wr_data;
          endcase
        end
      endcase

    end

    //---------------------------------rd data----------------------------------//
    wire [31:0] cub_mif_data_rdata ;

    wire [1:0]   cub_mem_sel_out;
    wire [1:0]   cub_mem_data_type_out ;
    //wire [1:0]   cub_mem_sel  ;
    wire [1:0]   cub_mem_bt_addr_offset_out ; 
    wire         cub_mem_rdata_sign_ext_out ;

    wire   cub_mem_rvalid_i =  cub_mif_data_l1b_rvalid | cub_mif_data_cram_rvalid | cub_mif_data_scache_rvalid ;

    DW_fifo_s1_sf #(.width(12),  .depth(4),   .err_mode(0),  .rst_mode(0)) //depth need to be redefined   according to read_pipe_delay cycle
    U_pooling_ctrl_wr_gen_raddr_fifo (
        .clk                (clk                    ),   
        .rst_n              (rst_n                  ),   
        .push_req_n         (!(cub_mem_op_enable & !cub_mem_we )), //only read operate can push 
        .pop_req_n          (!cub_mem_rvalid        ), //mod by jiangyz
        .diag_n             (!cub_mem_op_sta_clr    ),
        .empty              (),
        .almost_empty       (),   
        .half_full          (),
        .almost_full        (),   
        .full               (),
        .error              (),   
        .data_in            ({ cub_mem_sel      , cub_mem_rdst_greg_in, cub_mem_data_type , cub_mem_bt_addr_offset, cub_mem_rdata_sign_ext } ),   
        .data_out           ({ cub_mem_sel_out  , cub_mem_rdst_greg_out,cub_mem_data_type_out ,cub_mem_bt_addr_offset_out, cub_mem_rdata_sign_ext_out  } )
        );
       
    assign cub_mem_l1b_rdst_crossbar_en = (cub_mem_sel_out==2'b0) & (cub_mem_rdst_greg_out==5'b0);

    logic [31:0] cub_mem_rdata_i;
    logic [31:0] cub_mem_rdata_ext;
    logic [31:0] cub_mem_rdata_wd_ext; //sign extension for words, actually only misaligned assembly
    logic [31:0] cub_mem_rdata_hw_ext; //sign extension for half words
    logic [31:0] cub_mem_rdata_bt_ext; //sign extension for bytes

    logic [31:0] cub_mem_rdata_q;
  
   
    always_comb begin 
       case(cub_mem_sel_out)
           L1B_SEL     :    cub_mem_rdata_i  = cub_mif_data_l1b_rdata     ;
           CRAM_SEL    :    cub_mem_rdata_i  = cub_mif_data_cram_rdata    ;
           SCACHE_SEL  :    cub_mem_rdata_i  = cub_mif_data_scache_rdata  ;
           default     :    cub_mem_rdata_i  = cub_mif_data_scache_rdata  ;
       endcase
      end


 //select word, half word or byte sign extended version
    //word
    assign cub_mem_rdata_wd_ext = cub_mem_rdata_i ;

   
    //sign extension for half words
    always_comb begin
      case(cub_mem_bt_addr_offset_out[1]) //cub_mem_bt_addr[1:0]
        1'b0: begin
          if(cub_mem_rdata_sign_ext_out == 1'b0)
            cub_mem_rdata_hw_ext = {16'h0000, cub_mem_rdata_i[15:0]}; //zero ext
          else
            cub_mem_rdata_hw_ext = {{16{cub_mem_rdata_i[15]}}, cub_mem_rdata_i[15:0]}; //sign ext
        end

        1'b1: begin
          if(cub_mem_rdata_sign_ext_out == 1'b0)
            cub_mem_rdata_hw_ext = {16'h0000, cub_mem_rdata_i[31:16]}; //zero ext
          else
            cub_mem_rdata_hw_ext = {{16{cub_mem_rdata_i[31]}}, cub_mem_rdata_i[31:16]};//sign ext
        end
       endcase //case (rdata_offset_q)
    end

    //sign extension for bytes
    always_comb begin
      case(cub_mem_bt_addr_offset_out)
        2'b00: begin
          if(cub_mem_rdata_sign_ext_out == 1'b0)
            cub_mem_rdata_bt_ext = {24'h00_0000, cub_mem_rdata_i[7:0]};  //zero ext
          else
            cub_mem_rdata_bt_ext = {{24{cub_mem_rdata_i[7]}}, cub_mem_rdata_i[7:0]};
        end

        2'b01: begin
          if(cub_mem_rdata_sign_ext_out == 1'b0)
            cub_mem_rdata_bt_ext = {24'h00_0000, cub_mem_rdata_i[15:8]};
          else
            cub_mem_rdata_bt_ext = {{24{cub_mem_rdata_i[15]}}, cub_mem_rdata_i[15:8]};
        end

        2'b10: begin
          if(cub_mem_rdata_sign_ext_out == 1'b0)
            cub_mem_rdata_bt_ext = {24'h00_0000, cub_mem_rdata_i[23:16]};
          else
            cub_mem_rdata_bt_ext = {{24{cub_mem_rdata_i[23]}}, cub_mem_rdata_i[23:16]};
        end

        2'b11:
        begin
          if(cub_mem_rdata_sign_ext_out == 1'b0)
            cub_mem_rdata_bt_ext = {24'h00_0000, cub_mem_rdata_i[31:24]};
          else
            cub_mem_rdata_bt_ext = {{24{cub_mem_rdata_i[31]}}, cub_mem_rdata_i[31:24]};
        end
      endcase //case (rdata_offset_q)
    end


    // rdata ext
   always_comb begin
      case (cub_mem_data_type_out)
        WORD_TYPE    : cub_mem_rdata_ext = cub_mem_rdata_wd_ext;
        HALFWORD_TYPE: cub_mem_rdata_ext = cub_mem_rdata_hw_ext;
        BYTE_TYPE    ,
        DEFAULT_TYPE : cub_mem_rdata_ext = cub_mem_rdata_bt_ext;  //BYTE_TYPE
      endcase
    end

  //------------------------------------------------------------------------------//
   //always_ff @(posedge clk or negedge rst_n) begin
   // if(!rst_n)
   //     cub_mem_rvalid <= 1'b0;
   // else
   //     cub_mem_rvalid <= cub_mem_rvalid_i ;
   //end


   // always_ff @(posedge clk ) begin
   // if(cub_mem_rvalid_i)
   //     cub_mem_rdata <= cub_mem_rdata_ext ;
   // end

    assign cub_mem_rdata = cub_mem_rdata_ext;
    assign cub_mem_rvalid = cub_mem_rvalid_i;

endmodule
