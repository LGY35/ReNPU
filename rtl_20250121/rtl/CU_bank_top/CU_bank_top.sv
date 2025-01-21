module CU_bank_top(
    input clk,
    input rst_n,

    //Broadcast 
    input [128-1:0] BC_data_in,
    input BC_data_vld,
    input tcache_conv3d_bcfmap_vector_data_mask,

    //LB
    input [128-1:0] LB_data_in,
    input LB_data_vld,
    input [1:0] LB_mv_cub_dst_sel,

    //weight in
    //input weight_wr_start,
    //output weight_wr_req,

    //share cache out
    output logic [32-1:0]   CU_bank_data_out,
    output logic            CU_bank_data_out_vld,
    output logic            CU_bank_data_out_last,
    input                   CU_bank_data_out_ready,

    output logic            CU_bank_scache_dout_en,

    input dwconv_start,
    input dw_cross_ram_from_left, //向左借数
    input dw_cross_ram_from_right, //向右借数
    input [3:0] dw_trans_num, //dwconv一次填几行cram-1,实际计算行数会少1-4行：以15为例，3x3上pading下0-14，5x5上pading下0-12，3x3无pading下1-14，5x5无pading下2-13
    input dwconv_right_padding,
    input dwconv_left_padding,
    input dwconv_bottom_padding,
    input dwconv_top_padding,
    
    input conv3d_psum_data_trans_start,
    input [4:0] conv3d_psum_rd_num,
    input conv3d_psum_rd_ch_sel,
    input conv3d_psum_rd_rgb_sel,
    input [4:0] conv3d_psum_rd_offset,

    input conv3d_start,
    input [4:0] conv3d_psum_end_index,
    input [4:0] conv3d_psum_start_index,
    input conv3d_first_subch_flag,
    input conv3d_result_output_flag,
    input [1:0]conv3d_weight_16ch_sel,

    input Y_mode_pre_en,
    input Y_mode_cram_sel,

    input [1:0] vector_cfg_addr, //00:dw相关 01:Routing_code 10:other 11:conv3d
    input [22-1:0] vector_cfg_data,
    input vector_cfg_vld,

    output cram_fill_done,
    output psum_full,

    input [32-1:0]          Vec_core_cal_16ch_part_data_i,
    output [32-1:0]         Vec_core_cal_16ch_part_data_o,
    input [32-1:0]          scache_rd_16ch_part_data_i,
    output [32-1:0]         scache_rd_16ch_part_data_o,

    output                  lb_bank_data_req_o   ,
    output                  lb_bank_data_we_o    ,
    output [3 : 0]          lb_bank_data_be_o    ,
    output [31: 0]          lb_bank_data_wdata_o ,
    output [9 : 0]          lb_bank_data_addr_o  , //256*4
    input                   lb_bank_data_gnt_i   ,
    input                   lb_bank_data_rvalid_i,
    input  [31 : 0]         lb_bank_data_rdata_i ,

    input  [31:0]           Cub_alu_instr_i,
    input                   Cub_alu_instr_valid_i,
    input                   deassert_we_i,
    input [4:0]             cub_id_i,

    input                   VQ_cub_csr_access_i,
    input [5:0]             VQ_cub_csr_addr_i,
    input [15:0]            VQ_cub_csr_wdata_i,

    input                   VQ_scache_wr_en_i,
    input [8:0]             VQ_scache_wr_addr_i,
    input [1:0]             VQ_scache_wr_size_i,

    input                   VQ_scache_rd_en_i,
    input [8:0]             VQ_scache_rd_addr_i,
    input [1:0]             VQ_scache_rd_size_i,
    input                   VQ_scache_rd_sign_ext_i,

    //cubank interconnect reg
    input   [31:0]          cub_interconnect_top_reg_0_i,
    input   [31:0]          cub_interconnect_top_reg_1_i,
    input   [31:0]          cub_interconnect_top_reg_2_i,
    input   [31:0]          cub_interconnect_top_reg_3_i,
    input   [31:0]          cub_interconnect_bottom_reg_0_i,
    input   [31:0]          cub_interconnect_bottom_reg_1_i,
    input   [31:0]          cub_interconnect_bottom_reg_2_i,
    input   [31:0]          cub_interconnect_bottom_reg_3_i,
    input   [31:0]          cub_interconnect_side_reg_i,
    input   [31:0]          cub_interconnect_gap_reg_i,
    output logic [31:0]     cub_interconnect_reg_o,
    input		            cub_interconnect_reg_valid_i,
    output logic            cub_interconnect_reg_ready_o,

    output logic            scache_cflow_data_rd_st_rdy_o
);

    
    //to share cache
    logic [32-1:0]          Vec_core_cal_data;
    logic                   Vec_core_cal_data_vld;

    logic [32-1:0]          cub_alu_cal_data;
    logic                   cub_alu_cal_data_vld;
    logic [32-1:0]          cub_alu_data_in;
    logic                   cub_alu_data_in_vld;

    logic                   cram_access_req;
    logic                   cram_access_we;
    logic                   cram_access_gnt;
    logic [4:0]             cram_access_addr;
    logic [31:0]            cram_access_wdata;
    logic [31:0]            cram_access_rdata;
    logic                   cram_access_rvalid;

    logic [ 7: 0]           scache_wr_sub_len;
    logic [ 7: 0]           scache_wr_sys_len;
    logic [ 8: 0]           scache_wr_sub_gap;
    logic [ 9: 0]           scache_wr_sys_gap;
    logic [ 7: 0]           scache_rd_sub_len;
    logic [ 7: 0]           scache_rd_sys_len;
    logic [ 8: 0]           scache_rd_sub_gap;
    logic [ 9: 0]           scache_rd_sys_gap;
    logic [ 0: 0]           scache_lut_mode;
    logic [ 0: 0]           scache_lut_ram_sel;
    logic [ 2: 0]           cub_alu_din_cflow_sel;
    logic [ 0: 0]           cub_alu_dout_cflow_sel;
    logic [ 0: 0]           cub_scache_dout_cflow_sel;
    logic [ 0: 0]           cub_alu_din_sc_cross_rd_en;

    logic                   cub_alu_scache_en;
    logic                   cub_alu_scache_we;
    logic [8:0]             cub_alu_scache_addr;
    logic [1:0]             cub_alu_scache_size;
    logic                   cub_alu_scache_sign_ext;

    logic                   cub_mif_data_l1b_req      ;
    logic                   cub_mif_data_cram_req     ;
    logic                   cub_mif_data_scache_req   ;
    logic                   cub_mif_data_we           ;
    logic [3 : 0]           cub_mif_data_be           ;
    logic [31: 0]           cub_mif_data_wdata        ;
    logic [13: 0]           cub_mif_data_addr         ; //word addr
    logic                   cub_mif_data_l1b_gnt      ;
    logic                   cub_mif_data_l1b_rvalid   ;
    logic [31: 0]           cub_mif_data_l1b_rdata    ;
    logic                   cub_mif_data_cram_gnt     ;
    logic                   cub_mif_data_cram_rvalid  ;
    logic [31: 0]           cub_mif_data_cram_rdata   ;
    logic                   cub_mif_data_scache_gnt   ;
    logic                   cub_mif_data_scache_rvalid;
    logic [31: 0]           cub_mif_data_scache_rdata ;
    logic [31: 0]           cub_mem_rdata_to_crossbar;
    logic                   cub_mem_rvalid_to_crossbar;

    logic                   cub_alu_scache_wr_en,cub_alu_scache_rd_en;
    logic                   scache_wr_en;
    logic                   scache_rd_en;
    logic [8:0]             scache_wr_addr,scache_rd_addr;
    logic [1:0]             scache_wr_size,scache_rd_size;
    logic                   scache_rd_sign_ext;
    logic [31:0]            scache_rd_data;
    logic                   scache_rd_data_vld;
    logic                   scache_rd_data_last;

    logic [15:0]            tcache_bcfmap_data_alu_i16;
    logic [31:0]            tcache_bcfmap_data_alu_i32;
    logic [31:0]            tcache_bcfmap_data_alu;
    logic                   tcache_bcfmap_data_alu_valid;

    //assign                  tcache_bcfmap_data_alu = {{16'b0}, BC_data_in[16*(cub_id_i%8)+:16]};
    assign                  tcache_bcfmap_data_alu = {{16{BC_data_in[16*(cub_id_i%8)+15]}}, BC_data_in[16*(cub_id_i%8)+:16]};
    assign                  tcache_bcfmap_data_alu_valid = BC_data_vld;


    always@(posedge clk) begin
        if(BC_data_vld)
        tcache_bcfmap_data_alu_i16 <=  BC_data_in[16*(cub_id_i%8)+:16] ;
    end

    assign tcache_bcfmap_data_alu_i32 =  {{16{tcache_bcfmap_data_alu_i16[15]}}, tcache_bcfmap_data_alu_i16};


    assign  Vec_core_cal_16ch_part_data_o = Vec_core_cal_data;
    assign  scache_rd_16ch_part_data_o = scache_rd_data;

    assign cub_alu_scache_wr_en = cub_alu_scache_en && (cub_alu_scache_we==1'b1);
    assign cub_alu_scache_rd_en = cub_alu_scache_en && (cub_alu_scache_we==1'b0);
     
    assign scache_wr_en = VQ_scache_wr_en_i || cub_alu_scache_wr_en;
    assign scache_rd_en = VQ_scache_rd_en_i || cub_alu_scache_rd_en;
    assign scache_wr_size = cub_alu_scache_wr_en ? cub_alu_scache_size : VQ_scache_wr_size_i;
    assign scache_wr_addr = cub_alu_scache_wr_en ? cub_alu_scache_addr : VQ_scache_wr_addr_i;
    assign scache_rd_size     = cub_alu_scache_rd_en ? cub_alu_scache_size     : VQ_scache_rd_size_i;
    assign scache_rd_addr     = cub_alu_scache_rd_en ? cub_alu_scache_addr     : VQ_scache_rd_addr_i;
    assign scache_rd_sign_ext = cub_alu_scache_rd_en ? cub_alu_scache_sign_ext : VQ_scache_rd_sign_ext_i; 

    
    Vector_core U_Vector_core(
        .clk(clk),
        .rstn(rst_n),
        
        //Broadcast 
        .BC_data_in(BC_data_in),
        .BC_data_vld(BC_data_vld && !tcache_conv3d_bcfmap_vector_data_mask),

        //LB
        .LB_data_in(LB_data_in),
        .LB_data_vld(LB_data_vld),
        .LB_mv_cub_dst_sel(LB_mv_cub_dst_sel),
        
        //share cache
        .Vec_core_data_out(Vec_core_cal_data),
        .Vec_core_data_vld(Vec_core_cal_data_vld),
        
        //.weight_wr_start(weight_wr_start),
        //.weight_wr_req(weight_wr_req),
        
        .dwconv_start(dwconv_start),
        .dw_cross_ram_from_left(dw_cross_ram_from_left), //向左借数
        .dw_cross_ram_from_right(dw_cross_ram_from_right), //向右借数
        .dw_trans_num(dw_trans_num), //dwconv一次填几行cram-1),实际计算行数会少1-4行：以15为例，3x3上pading下0-14，5x5上pading下0-12，3x3无pading下1-14，5x5无pading下2-13
        .dw_top_pad(dwconv_top_padding),
        .dw_bottom_pad(dwconv_bottom_padding),
        .dw_left_pad(dwconv_left_padding),
        .dw_right_pad(dwconv_right_padding),

        .conv3d_start(conv3d_start),
        .conv3d_psum_end_index(conv3d_psum_end_index),
        .conv3d_psum_start_index(conv3d_psum_start_index),
        .conv3d_first_subch_flag(conv3d_first_subch_flag),
        .conv3d_result_output_flag(conv3d_result_output_flag),
        .conv3d_weight_16ch_sel(conv3d_weight_16ch_sel),

        .Y_mode_pre_en(Y_mode_pre_en),
        .Y_mode_cram_sel(Y_mode_cram_sel),

        .conv3d_psum_data_trans_start(conv3d_psum_data_trans_start),
        .conv3d_psum_rd_num(conv3d_psum_rd_num),
        .conv3d_psum_rd_ch_sel(conv3d_psum_rd_ch_sel),
        .conv3d_psum_rd_rgb_sel(conv3d_psum_rd_rgb_sel),
        .conv3d_psum_rd_offset(conv3d_psum_rd_offset),
        
        .vector_cfg_addr(vector_cfg_addr), //00:dw相关 01:Routing_code 10:other 11:conv3d
        .vector_cfg_data(vector_cfg_data),
        .vector_cfg_vld(vector_cfg_vld),

        //new
        .cram_access_req        (cub_mif_data_cram_req),
        .cram_access_we         (cub_mif_data_we),
        //.cram_access_be         (cub_mif_data_be),
        .cram_access_addr       (cub_mif_data_addr[6:0]), //4*2*16
        .cram_access_wr_data    (cub_mif_data_wdata),
        .cram_access_gnt        (cub_mif_data_cram_gnt),
        .cram_access_rd_data    (cub_mif_data_cram_rdata),
        .cram_access_rd_data_vld(cub_mif_data_cram_rvalid),
        
        .cram_fill_done(cram_fill_done),
        .psum_full(psum_full)
        );


    cub_alu_top U_cub_alu_top(
        .clk(clk),
        .rst_n(rst_n),

        .cub_alu_data_i(cub_alu_data_in),
        .cub_alu_data_valid_i(cub_alu_data_in_vld),

        .cub_alu_data_o(cub_alu_cal_data),
        .cub_alu_data_valid_o(cub_alu_cal_data_vld),

        .Cub_alu_instr_i(Cub_alu_instr_i),
        .Cub_alu_instr_valid_i(Cub_alu_instr_valid_i),
        .deassert_we_i(deassert_we_i),
        .cub_id_i(cub_id_i),

        .VQ_cub_csr_access_i(VQ_cub_csr_access_i),
        .VQ_cub_csr_addr_i(VQ_cub_csr_addr_i),
        .VQ_cub_csr_wdata_i(VQ_cub_csr_wdata_i),

        //scache cfg signal from cub_csr
        .scache_wr_sub_len_o(scache_wr_sub_len),
        .scache_wr_sys_len_o(scache_wr_sys_len),
        .scache_wr_sub_gap_o(scache_wr_sub_gap),
        .scache_wr_sys_gap_o(scache_wr_sys_gap),
        .scache_rd_sub_len_o(scache_rd_sub_len),
        .scache_rd_sys_len_o(scache_rd_sys_len),
        .scache_rd_sub_gap_o(scache_rd_sub_gap),
        .scache_rd_sys_gap_o(scache_rd_sys_gap),
        .scache_lut_mode_o(scache_lut_mode),
        .scache_lut_ram_sel_o(scache_lut_ram_sel),

        .cub_alu_din_cflow_sel_o(cub_alu_din_cflow_sel),
        .cub_scache_dout_cflow_sel_o(cub_scache_dout_cflow_sel),
        .cub_alu_dout_cflow_sel_o(cub_alu_dout_cflow_sel),
        .cub_alu_din_sc_cross_rd_en_o(cub_alu_din_sc_cross_rd_en),

        .cub_alu_scache_en_o(cub_alu_scache_en),
        .cub_alu_scache_we_o(cub_alu_scache_we),
        .cub_alu_scache_addr_o(cub_alu_scache_addr),
        .cub_alu_scache_size_o(cub_alu_scache_size),
        .cub_alu_scache_sign_ext_o(cub_alu_scache_sign_ext),

        //cub ld/st req
        .cub_mif_data_l1b_req_o        (cub_mif_data_l1b_req      ),
        .cub_mif_data_cram_req_o       (cub_mif_data_cram_req     ),
        .cub_mif_data_scache_req_o     (cub_mif_data_scache_req   ),
        .cub_mif_data_we_o             (cub_mif_data_we           ),
        .cub_mif_data_be_o             (cub_mif_data_be           ),
        .cub_mif_data_wdata_o          (cub_mif_data_wdata        ),
        .cub_mif_data_addr_o           (cub_mif_data_addr         ), //word addr
        .cub_mif_data_l1b_gnt_i        (cub_mif_data_l1b_gnt      ),
        .cub_mif_data_l1b_rvalid_i     (cub_mif_data_l1b_rvalid   ),
        .cub_mif_data_l1b_rdata_i      (cub_mif_data_l1b_rdata    ),
        .cub_mif_data_cram_gnt_i       (cub_mif_data_cram_gnt     ),
        .cub_mif_data_cram_rvalid_i    (cub_mif_data_cram_rvalid  ),
        .cub_mif_data_cram_rdata_i     (cub_mif_data_cram_rdata   ),
        .cub_mif_data_scache_gnt_i     (cub_mif_data_scache_gnt   ),
        .cub_mif_data_scache_rvalid_i  (cub_mif_data_scache_rvalid),
        .cub_mif_data_scache_rdata_i   (cub_mif_data_scache_rdata ),
        
        .cub_mem_rdata_to_crossbar_o   (cub_mem_rdata_to_crossbar ),
        .cub_mem_rvalid_to_crossbar_o  (cub_mem_rvalid_to_crossbar),

        //cubank interconnect reg
        .cub_interconnect_top_reg_0_i   (cub_interconnect_top_reg_0_i),
        .cub_interconnect_top_reg_1_i   (cub_interconnect_top_reg_1_i),
        .cub_interconnect_top_reg_2_i   (cub_interconnect_top_reg_2_i),
        .cub_interconnect_top_reg_3_i   (cub_interconnect_top_reg_3_i),
        .cub_interconnect_bottom_reg_0_i(cub_interconnect_bottom_reg_0_i),
        .cub_interconnect_bottom_reg_1_i(cub_interconnect_bottom_reg_1_i),
        .cub_interconnect_bottom_reg_2_i(cub_interconnect_bottom_reg_2_i),
        .cub_interconnect_bottom_reg_3_i(cub_interconnect_bottom_reg_3_i),
        .cub_interconnect_side_reg_i    (cub_interconnect_side_reg_i),
        .cub_interconnect_gap_reg_i     (cub_interconnect_gap_reg_i),
        .cub_interconnect_reg_o         (cub_interconnect_reg_o),
        .cub_interconnect_reg_valid_i   (cub_interconnect_reg_valid_i),
        .cub_interconnect_reg_ready_o   (cub_interconnect_reg_ready_o),
        .tcache_bcfmap_data_alu_i       (tcache_bcfmap_data_alu_i32)
    );

    assign lb_bank_data_req_o      = cub_mif_data_l1b_req;
    assign lb_bank_data_we_o       = cub_mif_data_we;
    assign lb_bank_data_be_o       = cub_mif_data_be;
    assign lb_bank_data_wdata_o    = cub_mif_data_wdata;
    assign lb_bank_data_addr_o     = cub_mif_data_addr[9:0];
    assign cub_mif_data_l1b_gnt    = lb_bank_data_gnt_i;
    assign cub_mif_data_l1b_rvalid = lb_bank_data_rvalid_i;
    assign cub_mif_data_l1b_rdata  = lb_bank_data_rdata_i;
    
    //crossbar in data source
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n)
                cub_alu_data_in_vld <= 'b0;
        else begin
             case(cub_alu_din_cflow_sel)
                 3'b000: begin //Vec_core out
                     cub_alu_data_in <= Vec_core_cal_data[31:0];
                     cub_alu_data_in_vld <= Vec_core_cal_data_vld;
                 end 
                 3'b001: begin //Scache_rd_data
                     cub_alu_data_in <= scache_rd_data;
                     cub_alu_data_in_vld <= scache_rd_data_vld & cub_scache_dout_cflow_sel;
                 end
                 3'b010: begin //LB instr load data
                     cub_alu_data_in <= cub_mem_rdata_to_crossbar;
                     cub_alu_data_in_vld <= cub_mem_rvalid_to_crossbar;
                 end
                 3'b011: begin //add neighbor cubank Vec_cal_16ch_part_data
                     cub_alu_data_in <= Vec_core_cal_data+Vec_core_cal_16ch_part_data_i;
                     cub_alu_data_in_vld <= Vec_core_cal_data_vld;
                 end
                 3'b100: begin //Scache rd data of cross bank
                    cub_alu_data_in <= scache_rd_16ch_part_data_i;
                    cub_alu_data_in_vld <= scache_rd_data_vld & cub_scache_dout_cflow_sel;
                 end
                 3'b101: begin //tcache broadcast fmap
                    cub_alu_data_in <= tcache_bcfmap_data_alu;
                    cub_alu_data_in_vld <= tcache_bcfmap_data_alu_valid;
                 end
                 default: begin
                     cub_alu_data_in_vld <= 1'b0;
                 end
             endcase
        end
    end


    //CU_bank out sel
    logic   CU_bank_data_out_valid;
    assign  CU_bank_data_out_valid = cub_alu_dout_cflow_sel ? cub_alu_cal_data_vld : cub_scache_dout_cflow_sel==1'b0 ? scache_rd_data_vld : 1'b0;
    assign  CU_bank_scache_dout_en = cub_scache_dout_cflow_sel==1'b0;
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            CU_bank_data_out <= 32'b0;
            CU_bank_data_out_vld <= 1'b0;
            CU_bank_data_out_last <= 1'b0;
        end
        else if(CU_bank_data_out_ready) begin
            if(CU_bank_data_out_valid)
                CU_bank_data_out <= cub_alu_dout_cflow_sel ? cub_alu_cal_data : scache_rd_data;
                
            CU_bank_data_out_vld <= CU_bank_data_out_valid;
            CU_bank_data_out_last <= cub_alu_dout_cflow_sel ? 1'b0 : scache_rd_data_last; 
        end
    end

    //scache wr sel
    logic [31:0]    scache_wr_data;
    logic           scache_wr_valid;
    assign scache_wr_data  = cub_alu_cal_data;
    assign scache_wr_valid = cub_alu_dout_cflow_sel==1'b0 ? cub_alu_cal_data_vld : 1'b0;

    logic   scache_rd2l2_mode;
    assign  scache_rd2l2_mode = cub_scache_dout_cflow_sel==1'b0;


    cub_scache U_cub_scache(
        .clk                              (clk                              ),
        .rst_n                            (rst_n                            ),
        //data
        .scache_cflow_data_wr_valid       (cub_alu_cal_data_vld             ), //wr
        .scache_cflow_data_wr_data        (cub_alu_cal_data                 ),
        //instr
        .scache_cflow_data_wr_en          (scache_wr_en                     ),
        .scache_cflow_data_wr_dst_addr    (scache_wr_addr                   ),
        .scache_cflow_data_wr_size        (scache_wr_size                   ),
        //csr cfg
        .scache_cflow_data_wr_sub_len     ({1'b0, scache_wr_sub_len}),  
        .scache_cflow_data_wr_sub_gap     (scache_wr_sub_gap),  
        .scache_cflow_data_wr_sys_len     ({1'b0 , scache_wr_sys_len}),   
        .scache_cflow_data_wr_sys_gap     (scache_wr_sys_gap),  
        .scache_cflow_data_wr_done        (),  
        //data
        .scache_cflow_data_rd_valid       (scache_rd_data_vld               ), //rd
        .scache_cflow_data_rd2l2_last     (scache_rd_data_last              ), 
        .scache_cflow_data_rd_data        (scache_rd_data                   ), //default to CU_bank_data_out
        .scache_cflow_data_rd2l2_ready    (cub_scache_dout_cflow_sel ? 1'b1 : CU_bank_data_out_ready),
        //instr
        .scache_cflow_data_rd_en          (scache_rd_en                     ),
        .scache_cflow_data_rd_dst_addr    (scache_rd_addr                   ),
        .scache_cflow_data_rd_size        (scache_rd_size                   ),
        .scache_cflow_data_rd_sign_ext    (scache_rd_sign_ext               ),
        //csr cfg
        .scache_cflow_data_rd_sub_len     ({1'b0, scache_rd_sub_len}),
        .scache_cflow_data_rd_sub_gap     (scache_rd_sub_gap),
        .scache_cflow_data_rd_sys_len     ({1'b0, scache_rd_sys_len}),
        .scache_cflow_data_rd_sys_gap     (scache_rd_sys_gap),
        .scache_cflow_data_rd_done        (),
        .scache_cflow_data_rd_st_rdy      (scache_cflow_data_rd_st_rdy_o    ),
        //lut mode
        .scache_rd2l2_mode                (scache_rd2l2_mode                ),
        .scache_lut_mode                  (scache_lut_mode),
        .scache_lut_ram_sel               (scache_lut_ram_sel),
        //sigle data load/store
        .scache_data_req                  (cub_mif_data_scache_req          ),
        .scache_data_we                   (cub_mif_data_we                  ),
        .scache_data_be                   (cub_mif_data_be                  ),
        .scache_data_wdata                (cub_mif_data_wdata               ),
        .scache_data_addr                 (cub_mif_data_addr[6:0]           ),//64*2
        .scache_data_gnt                  (cub_mif_data_scache_gnt          ),
        .scache_data_rvalid               (cub_mif_data_scache_rvalid       ),
        .scache_data_rdata                (cub_mif_data_scache_rdata        ),
        .scache_data_sfu_hw_offset        (1'b0)
    );

endmodule
