// Generator : SpinalHDL v1.8.1    git head : 2a7592004363e5b40ec43e1f122ed8641cd8965b
// Component : idma_inoc_regfile
// Git hash  : 5ed3a227fa124f7bf84f7232dae0a17f3dade535

`timescale 1ns/1ps

module idma_inoc_regfile (
  input      [11:0]   io_apb_PADDR,
  input      [0:0]    io_apb_PSEL,
  input               io_apb_PENABLE,
  output              io_apb_PREADY,
  input               io_apb_PWRITE,
  input      [3:0]    io_apb_PSTRB,
  input      [2:0]    io_apb_PPROT,
  input      [31:0]   io_apb_PWDATA,
  output     [31:0]   io_apb_PRDATA,
  output              io_apb_PSLVERR,
  output              io_fsm_start,
  output     [16:0]   io_fsm_base_addr,
  output              io_fsm_auto_restart_en,
  output              io_fsm_restart,
  output              io_rd_cfg_ready,
  output              io_rd_afifo_init,
  output              io_rd_dfifo_init,
  output     [3:0]    io_rd_cfg_outstd,
  output              io_rd_cfg_outstd_en,
  output              io_rd_cfg_cross4k_en,
  output              io_rd_cfg_arvld_hold_en,
  output     [6:0]    io_rd_cfg_dfifo_thd,
  output              io_rd_cfg_resi_mode,
  output     [31:0]   io_rd_cfg_resi_fmap_a_addr,
  output     [31:0]   io_rd_cfg_resi_fmap_b_addr,
  output     [15:0]   io_rd_cfg_resi_addr_gap,
  output     [15:0]   io_rd_cfg_resi_loop_num,
  output              io_rd_req,
  output     [31:0]   io_rd_addr,
  output     [31:0]   io_rd_num,
  input               io_rd_done_intr,
  input               io_finish_intr,
  input               io_small_loop_end_int,
  input      [15:0]   io_debug_dma_rd_in_cnt,
  input      [11:0]   io_nodes_status,
  output              io_intr,
  input               clk,
  input               resetn
);

  wire       [0:0]    tmp_rd_cfg_outstd_en;
  wire       [0:0]    tmp_rd_cfg_cross4k_en;
  wire       [0:0]    tmp_rd_cfg_arvld_hold_en;
  wire       [0:0]    tmp_rd_cfg_resi_mode;
  wire       [0:0]    tmp_small_loop_end_int_mask;
  wire       [0:0]    tmp_finish_intr_mask;
  wire       [0:0]    tmp_rd_done_intr_mask;
  wire       [11:0]   tmp_1;
  reg                 busif_readError;
  reg        [31:0]   busif_readData;
  wire       [3:0]    busif_wstrb;
  reg        [31:0]   busif_wmask;
  reg        [31:0]   busif_wmaskn;
  wire                busif_askWrite;
  wire                busif_askRead;
  wire                busif_doWrite;
  wire                busif_doRead;
  wire                read_hit_0x0000;
  wire                write_hit_0x0000;
  wire                read_hit_0x0004;
  wire                write_hit_0x0004;
  wire                read_hit_0x0008;
  wire                write_hit_0x0008;
  wire                read_hit_0x000c;
  wire                write_hit_0x000c;
  wire                read_hit_0x0010;
  wire                write_hit_0x0010;
  wire                read_hit_0x0014;
  wire                write_hit_0x0014;
  wire                read_hit_0x0018;
  wire                write_hit_0x0018;
  wire                read_hit_0x001c;
  wire                write_hit_0x001c;
  wire                read_hit_0x0020;
  wire                write_hit_0x0020;
  wire                read_hit_0x0024;
  wire                write_hit_0x0024;
  wire                read_hit_0x0028;
  wire                write_hit_0x0028;
  wire                read_hit_0x002c;
  wire                write_hit_0x002c;
  wire                read_hit_0x0030;
  wire                write_hit_0x0030;
  wire                read_hit_0x0034;
  wire                write_hit_0x0034;
  reg                 rd_cfg_en;
  reg                 rd_afifo_init;
  reg                 rd_dfifo_init;
  wire       [14:0]   reserved;
  reg        [7:0]    rd_cfg_dfifo_thd;
  reg        [3:0]    rd_cfg_outstd;
  reg                 rd_cfg_outstd_en;
  reg                 rd_cfg_cross4k_en;
  reg                 rd_cfg_arvld_hold_en;
  reg                 rd_cfg_resi_mode;
  reg        [31:0]   rd_cfg_resi_fmap_a_addr;
  reg        [31:0]   rd_cfg_resi_fmap_b_addr;
  reg        [31:0]   rd_cfg_resi_addr_gap;
  reg        [31:0]   rd_cfg_resi_loop_num;
  reg                 rd_req;
  reg        [31:0]   rd_addr;
  reg        [31:0]   rd_num;
  reg        [16:0]   fsm_base_addr;
  wire       [15:0]   debug_dma_rd_in_cnt;
  wire       [11:0]   nodes_status;
  wire                read_hit_0x0038;
  wire                write_hit_0x0038;
  wire                read_hit_0x003c;
  wire                write_hit_0x003c;
  wire                read_hit_0x0040;
  wire                write_hit_0x0040;
  reg                 small_loop_end_int_raw;
  reg                 small_loop_end_int_mask;
  wire                small_loop_end_int_status;
  reg                 finish_intr_raw;
  reg                 finish_intr_mask;
  wire                finish_intr_status;
  reg                 rd_done_intr_raw;
  reg                 rd_done_intr_mask;
  wire                rd_done_intr_status;
  wire                INTR_intr;

  assign tmp_1 = {io_apb_PADDR[11 : 2],2'b00};
  assign tmp_rd_cfg_outstd_en = ((rd_cfg_outstd_en & busif_wmaskn[4 : 4]) | (io_apb_PWDATA[4 : 4] & busif_wmask[4 : 4]));
  assign tmp_rd_cfg_cross4k_en = ((rd_cfg_cross4k_en & busif_wmaskn[5 : 5]) | (io_apb_PWDATA[5 : 5] & busif_wmask[5 : 5]));
  assign tmp_rd_cfg_arvld_hold_en = ((rd_cfg_arvld_hold_en & busif_wmaskn[6 : 6]) | (io_apb_PWDATA[6 : 6] & busif_wmask[6 : 6]));
  assign tmp_rd_cfg_resi_mode = ((rd_cfg_resi_mode & busif_wmaskn[7 : 7]) | (io_apb_PWDATA[7 : 7] & busif_wmask[7 : 7]));
  assign tmp_small_loop_end_int_mask = ((small_loop_end_int_mask & busif_wmaskn[0 : 0]) | (io_apb_PWDATA[0 : 0] & busif_wmask[0 : 0]));
  assign tmp_finish_intr_mask = ((finish_intr_mask & busif_wmaskn[1 : 1]) | (io_apb_PWDATA[1 : 1] & busif_wmask[1 : 1]));
  assign tmp_rd_done_intr_mask = ((rd_done_intr_mask & busif_wmaskn[2 : 2]) | (io_apb_PWDATA[2 : 2] & busif_wmask[2 : 2]));
  assign busif_wstrb = io_apb_PSTRB; // @ Apb4BusInterface.scala l16
  assign io_apb_PREADY = 1'b1; // @ Apb4BusInterface.scala l21
  assign io_apb_PRDATA = busif_readData; // @ Apb4BusInterface.scala l22
  assign busif_askWrite = (io_apb_PSEL[0] && io_apb_PWRITE); // @ BaseType.scala l305
  assign busif_askRead = (io_apb_PSEL[0] && (! io_apb_PWRITE)); // @ BaseType.scala l305
  assign busif_doWrite = ((busif_askWrite && io_apb_PENABLE) && io_apb_PREADY); // @ BaseType.scala l305
  assign busif_doRead = ((busif_askRead && io_apb_PENABLE) && io_apb_PREADY); // @ BaseType.scala l305
  always @(*) begin
    busif_wmask[7 : 0] = (busif_wstrb[0] ? 8'hff : 8'h0); // @ BusIfBase.scala l42
    busif_wmask[15 : 8] = (busif_wstrb[1] ? 8'hff : 8'h0); // @ BusIfBase.scala l42
    busif_wmask[23 : 16] = (busif_wstrb[2] ? 8'hff : 8'h0); // @ BusIfBase.scala l42
    busif_wmask[31 : 24] = (busif_wstrb[3] ? 8'hff : 8'h0); // @ BusIfBase.scala l42
  end

  always @(*) begin
    busif_wmaskn[7 : 0] = (busif_wstrb[0] ? 8'h0 : 8'hff); // @ BusIfBase.scala l43
    busif_wmaskn[15 : 8] = (busif_wstrb[1] ? 8'h0 : 8'hff); // @ BusIfBase.scala l43
    busif_wmaskn[23 : 16] = (busif_wstrb[2] ? 8'h0 : 8'hff); // @ BusIfBase.scala l43
    busif_wmaskn[31 : 24] = (busif_wstrb[3] ? 8'h0 : 8'hff); // @ BusIfBase.scala l43
  end

  assign io_apb_PSLVERR = busif_readError; // @ Apb4BusInterface.scala l32
  assign read_hit_0x0000 = (({io_apb_PADDR[11 : 2],2'b00} == 12'h0) && busif_doRead); // @ BaseType.scala l305
  assign write_hit_0x0000 = ((io_apb_PADDR == 12'h0) && busif_doWrite); // @ BaseType.scala l305
  assign read_hit_0x0004 = (({io_apb_PADDR[11 : 2],2'b00} == 12'h004) && busif_doRead); // @ BaseType.scala l305
  assign write_hit_0x0004 = ((io_apb_PADDR == 12'h004) && busif_doWrite); // @ BaseType.scala l305
  assign read_hit_0x0008 = (({io_apb_PADDR[11 : 2],2'b00} == 12'h008) && busif_doRead); // @ BaseType.scala l305
  assign write_hit_0x0008 = ((io_apb_PADDR == 12'h008) && busif_doWrite); // @ BaseType.scala l305
  assign read_hit_0x000c = (({io_apb_PADDR[11 : 2],2'b00} == 12'h00c) && busif_doRead); // @ BaseType.scala l305
  assign write_hit_0x000c = ((io_apb_PADDR == 12'h00c) && busif_doWrite); // @ BaseType.scala l305
  assign read_hit_0x0010 = (({io_apb_PADDR[11 : 2],2'b00} == 12'h010) && busif_doRead); // @ BaseType.scala l305
  assign write_hit_0x0010 = ((io_apb_PADDR == 12'h010) && busif_doWrite); // @ BaseType.scala l305
  assign read_hit_0x0014 = (({io_apb_PADDR[11 : 2],2'b00} == 12'h014) && busif_doRead); // @ BaseType.scala l305
  assign write_hit_0x0014 = ((io_apb_PADDR == 12'h014) && busif_doWrite); // @ BaseType.scala l305
  assign read_hit_0x0018 = (({io_apb_PADDR[11 : 2],2'b00} == 12'h018) && busif_doRead); // @ BaseType.scala l305
  assign write_hit_0x0018 = ((io_apb_PADDR == 12'h018) && busif_doWrite); // @ BaseType.scala l305
  assign read_hit_0x001c = (({io_apb_PADDR[11 : 2],2'b00} == 12'h01c) && busif_doRead); // @ BaseType.scala l305
  assign write_hit_0x001c = ((io_apb_PADDR == 12'h01c) && busif_doWrite); // @ BaseType.scala l305
  assign read_hit_0x0020 = (({io_apb_PADDR[11 : 2],2'b00} == 12'h020) && busif_doRead); // @ BaseType.scala l305
  assign write_hit_0x0020 = ((io_apb_PADDR == 12'h020) && busif_doWrite); // @ BaseType.scala l305
  assign read_hit_0x0024 = (({io_apb_PADDR[11 : 2],2'b00} == 12'h024) && busif_doRead); // @ BaseType.scala l305
  assign write_hit_0x0024 = ((io_apb_PADDR == 12'h024) && busif_doWrite); // @ BaseType.scala l305
  assign read_hit_0x0028 = (({io_apb_PADDR[11 : 2],2'b00} == 12'h028) && busif_doRead); // @ BaseType.scala l305
  assign write_hit_0x0028 = ((io_apb_PADDR == 12'h028) && busif_doWrite); // @ BaseType.scala l305
  assign read_hit_0x002c = (({io_apb_PADDR[11 : 2],2'b00} == 12'h02c) && busif_doRead); // @ BaseType.scala l305
  assign write_hit_0x002c = ((io_apb_PADDR == 12'h02c) && busif_doWrite); // @ BaseType.scala l305
  assign read_hit_0x0030 = (({io_apb_PADDR[11 : 2],2'b00} == 12'h030) && busif_doRead); // @ BaseType.scala l305
  assign write_hit_0x0030 = ((io_apb_PADDR == 12'h030) && busif_doWrite); // @ BaseType.scala l305
  assign read_hit_0x0034 = (({io_apb_PADDR[11 : 2],2'b00} == 12'h034) && busif_doRead); // @ BaseType.scala l305
  assign write_hit_0x0034 = ((io_apb_PADDR == 12'h034) && busif_doWrite); // @ BaseType.scala l305
  assign reserved = 15'h0; // @ Bits.scala l133
  assign io_rd_cfg_ready = rd_cfg_en; // @ idma_inoc_regfile.scala l75
  assign io_rd_afifo_init = rd_afifo_init; // @ idma_inoc_regfile.scala l76
  assign io_rd_dfifo_init = rd_dfifo_init; // @ idma_inoc_regfile.scala l77
  assign io_rd_cfg_outstd = rd_cfg_outstd; // @ idma_inoc_regfile.scala l78
  assign io_rd_cfg_outstd_en = rd_cfg_outstd_en; // @ idma_inoc_regfile.scala l79
  assign io_rd_cfg_cross4k_en = rd_cfg_cross4k_en; // @ idma_inoc_regfile.scala l80
  assign io_rd_cfg_arvld_hold_en = rd_cfg_arvld_hold_en; // @ idma_inoc_regfile.scala l81
  assign io_rd_cfg_dfifo_thd = rd_cfg_dfifo_thd[6:0]; // @ idma_inoc_regfile.scala l82
  assign io_rd_cfg_resi_mode = rd_cfg_resi_mode; // @ idma_inoc_regfile.scala l83
  assign io_rd_cfg_resi_fmap_a_addr = rd_cfg_resi_fmap_a_addr; // @ idma_inoc_regfile.scala l84
  assign io_rd_cfg_resi_fmap_b_addr = rd_cfg_resi_fmap_b_addr; // @ idma_inoc_regfile.scala l85
  assign io_rd_cfg_resi_addr_gap = rd_cfg_resi_addr_gap[15:0]; // @ idma_inoc_regfile.scala l86
  assign io_rd_cfg_resi_loop_num = rd_cfg_resi_loop_num[15:0]; // @ idma_inoc_regfile.scala l87
  assign io_rd_req = rd_req; // @ idma_inoc_regfile.scala l88
  assign io_rd_addr = rd_addr; // @ idma_inoc_regfile.scala l89
  assign io_rd_num = rd_num; // @ idma_inoc_regfile.scala l90
  assign io_fsm_start = write_hit_0x0030; // @ idma_inoc_regfile.scala l91
  assign io_fsm_base_addr = fsm_base_addr; // @ idma_inoc_regfile.scala l92
  assign debug_dma_rd_in_cnt = io_debug_dma_rd_in_cnt; // @ idma_inoc_regfile.scala l95
  assign nodes_status = io_nodes_status; // @ idma_inoc_regfile.scala l96
  assign read_hit_0x0038 = (({io_apb_PADDR[11 : 2],2'b00} == 12'h038) && busif_doRead); // @ BaseType.scala l305
  assign write_hit_0x0038 = ((io_apb_PADDR == 12'h038) && busif_doWrite); // @ BaseType.scala l305
  assign read_hit_0x003c = (({io_apb_PADDR[11 : 2],2'b00} == 12'h03c) && busif_doRead); // @ BaseType.scala l305
  assign write_hit_0x003c = ((io_apb_PADDR == 12'h03c) && busif_doWrite); // @ BaseType.scala l305
  assign read_hit_0x0040 = (({io_apb_PADDR[11 : 2],2'b00} == 12'h040) && busif_doRead); // @ BaseType.scala l305
  assign write_hit_0x0040 = ((io_apb_PADDR == 12'h040) && busif_doWrite); // @ BaseType.scala l305
  assign small_loop_end_int_status = (small_loop_end_int_raw && (! small_loop_end_int_mask)); // @ BusIfBase.scala l313
  assign finish_intr_status = (finish_intr_raw && (! finish_intr_mask)); // @ BusIfBase.scala l313
  assign rd_done_intr_status = (rd_done_intr_raw && (! rd_done_intr_mask)); // @ BusIfBase.scala l313
  assign INTR_intr = (|((small_loop_end_int_status || finish_intr_status) || rd_done_intr_status)); // @ BaseType.scala l312
  assign io_intr = INTR_intr; // @ idma_inoc_regfile.scala l97
  always @(posedge clk or negedge resetn) begin
    if(!resetn) begin
      busif_readError <= 1'b0; // @ Data.scala l400
      busif_readData <= 32'h0; // @ Data.scala l400
      rd_cfg_en <= 1'b0; // @ Data.scala l400
      rd_afifo_init <= 1'b0; // @ Data.scala l400
      rd_dfifo_init <= 1'b0; // @ Data.scala l400
      rd_cfg_dfifo_thd <= 8'h0; // @ Data.scala l400
      rd_cfg_outstd <= 4'b0000; // @ Data.scala l400
      rd_cfg_outstd_en <= 1'b0; // @ Data.scala l400
      rd_cfg_cross4k_en <= 1'b0; // @ Data.scala l400
      rd_cfg_arvld_hold_en <= 1'b0; // @ Data.scala l400
      rd_cfg_resi_mode <= 1'b0; // @ Data.scala l400
      rd_cfg_resi_fmap_a_addr <= 32'h0; // @ Data.scala l400
      rd_cfg_resi_fmap_b_addr <= 32'h0; // @ Data.scala l400
      rd_cfg_resi_addr_gap <= 32'h0; // @ Data.scala l400
      rd_cfg_resi_loop_num <= 32'h0; // @ Data.scala l400
      rd_req <= 1'b0; // @ Data.scala l400
      rd_addr <= 32'h0; // @ Data.scala l400
      rd_num <= 32'h0; // @ Data.scala l400
      fsm_base_addr <= 17'h0; // @ Data.scala l400
      small_loop_end_int_raw <= 1'b0; // @ Data.scala l400
      small_loop_end_int_mask <= 1'b1; // @ Data.scala l400
      finish_intr_raw <= 1'b0; // @ Data.scala l400
      finish_intr_mask <= 1'b1; // @ Data.scala l400
      rd_done_intr_raw <= 1'b0; // @ Data.scala l400
      rd_done_intr_mask <= 1'b1; // @ Data.scala l400
    end else begin
      if((write_hit_0x0000 && (io_apb_PWDATA[0] && busif_wmask[0]))) begin
        rd_cfg_en <= ((rd_cfg_en && busif_wmaskn[0]) || ((! rd_cfg_en) && busif_wmask[0])); // @ RegInst.scala l741
      end else begin
        rd_cfg_en <= 1'b0; // @ RegInst.scala l742
      end
      if((write_hit_0x0004 && (io_apb_PWDATA[0] && busif_wmask[0]))) begin
        rd_afifo_init <= ((rd_afifo_init && busif_wmaskn[0]) || ((! rd_afifo_init) && busif_wmask[0])); // @ RegInst.scala l741
      end else begin
        rd_afifo_init <= 1'b0; // @ RegInst.scala l742
      end
      if((write_hit_0x0008 && (io_apb_PWDATA[0] && busif_wmask[0]))) begin
        rd_dfifo_init <= ((rd_dfifo_init && busif_wmaskn[0]) || ((! rd_dfifo_init) && busif_wmask[0])); // @ RegInst.scala l741
      end else begin
        rd_dfifo_init <= 1'b0; // @ RegInst.scala l742
      end
      if(write_hit_0x0008) begin
        rd_cfg_dfifo_thd <= ((rd_cfg_dfifo_thd & busif_wmaskn[23 : 16]) | (io_apb_PWDATA[23 : 16] & busif_wmask[23 : 16])); // @ UInt.scala l381
      end
      if(write_hit_0x000c) begin
        rd_cfg_outstd <= ((rd_cfg_outstd & busif_wmaskn[3 : 0]) | (io_apb_PWDATA[3 : 0] & busif_wmask[3 : 0])); // @ UInt.scala l381
      end
      if(write_hit_0x000c) begin
        rd_cfg_outstd_en <= tmp_rd_cfg_outstd_en[0]; // @ Bool.scala l189
      end
      if(write_hit_0x000c) begin
        rd_cfg_cross4k_en <= tmp_rd_cfg_cross4k_en[0]; // @ Bool.scala l189
      end
      if(write_hit_0x000c) begin
        rd_cfg_arvld_hold_en <= tmp_rd_cfg_arvld_hold_en[0]; // @ Bool.scala l189
      end
      if(write_hit_0x000c) begin
        rd_cfg_resi_mode <= tmp_rd_cfg_resi_mode[0]; // @ Bool.scala l189
      end
      if(write_hit_0x0010) begin
        rd_cfg_resi_fmap_a_addr <= ((rd_cfg_resi_fmap_a_addr & busif_wmaskn[31 : 0]) | (io_apb_PWDATA[31 : 0] & busif_wmask[31 : 0])); // @ UInt.scala l381
      end
      if(write_hit_0x0014) begin
        rd_cfg_resi_fmap_b_addr <= ((rd_cfg_resi_fmap_b_addr & busif_wmaskn[31 : 0]) | (io_apb_PWDATA[31 : 0] & busif_wmask[31 : 0])); // @ UInt.scala l381
      end
      if(write_hit_0x0018) begin
        rd_cfg_resi_addr_gap <= ((rd_cfg_resi_addr_gap & busif_wmaskn[31 : 0]) | (io_apb_PWDATA[31 : 0] & busif_wmask[31 : 0])); // @ UInt.scala l381
      end
      if(write_hit_0x001c) begin
        rd_cfg_resi_loop_num <= ((rd_cfg_resi_loop_num & busif_wmaskn[31 : 0]) | (io_apb_PWDATA[31 : 0] & busif_wmask[31 : 0])); // @ UInt.scala l381
      end
      if((write_hit_0x0020 && (io_apb_PWDATA[0] && busif_wmask[0]))) begin
        rd_req <= ((rd_req && busif_wmaskn[0]) || ((! rd_req) && busif_wmask[0])); // @ RegInst.scala l741
      end else begin
        rd_req <= 1'b0; // @ RegInst.scala l742
      end
      if(write_hit_0x0024) begin
        rd_addr <= ((rd_addr & busif_wmaskn[31 : 0]) | (io_apb_PWDATA[31 : 0] & busif_wmask[31 : 0])); // @ UInt.scala l381
      end
      if(write_hit_0x0028) begin
        rd_num <= ((rd_num & busif_wmaskn[31 : 0]) | (io_apb_PWDATA[31 : 0] & busif_wmask[31 : 0])); // @ UInt.scala l381
      end
      if(write_hit_0x0030) begin
        fsm_base_addr <= ((fsm_base_addr & busif_wmaskn[16 : 0]) | (io_apb_PWDATA[16 : 0] & busif_wmask[16 : 0])); // @ UInt.scala l381
      end
      if(write_hit_0x0038) begin
        if((io_apb_PWDATA[0] && busif_wmask[0])) begin
          small_loop_end_int_raw <= (small_loop_end_int_raw && busif_wmaskn[0]); // @ RegInst.scala l642
        end
      end
      if(write_hit_0x003c) begin
        small_loop_end_int_mask <= tmp_small_loop_end_int_mask[0]; // @ Bool.scala l189
      end
      if(io_small_loop_end_int) begin
        small_loop_end_int_raw <= 1'b1; // @ BusIfBase.scala l312
      end
      if(write_hit_0x0038) begin
        if((io_apb_PWDATA[1] && busif_wmask[1])) begin
          finish_intr_raw <= (finish_intr_raw && busif_wmaskn[1]); // @ RegInst.scala l642
        end
      end
      if(write_hit_0x003c) begin
        finish_intr_mask <= tmp_finish_intr_mask[0]; // @ Bool.scala l189
      end
      if(io_finish_intr) begin
        finish_intr_raw <= 1'b1; // @ BusIfBase.scala l312
      end
      if(write_hit_0x0038) begin
        if((io_apb_PWDATA[2] && busif_wmask[2])) begin
          rd_done_intr_raw <= (rd_done_intr_raw && busif_wmaskn[2]); // @ RegInst.scala l642
        end
      end
      if(write_hit_0x003c) begin
        rd_done_intr_mask <= tmp_rd_done_intr_mask[0]; // @ Bool.scala l189
      end
      if(io_rd_done_intr) begin
        rd_done_intr_raw <= 1'b1; // @ BusIfBase.scala l312
      end
      if(busif_askRead) begin
        case(tmp_1)
          12'h0 : begin
            busif_readData <= {31'h0,rd_cfg_en}; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h004 : begin
            busif_readData <= {31'h0,rd_afifo_init}; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h008 : begin
            busif_readData <= {8'h0,{rd_cfg_dfifo_thd,{reserved,rd_dfifo_init}}}; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h00c : begin
            busif_readData <= {24'h0,{rd_cfg_resi_mode,{rd_cfg_arvld_hold_en,{rd_cfg_cross4k_en,{rd_cfg_outstd_en,rd_cfg_outstd}}}}}; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h010 : begin
            busif_readData <= rd_cfg_resi_fmap_a_addr; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h014 : begin
            busif_readData <= rd_cfg_resi_fmap_b_addr; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h018 : begin
            busif_readData <= rd_cfg_resi_addr_gap; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h01c : begin
            busif_readData <= rd_cfg_resi_loop_num; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h020 : begin
            busif_readData <= {31'h0,rd_req}; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h024 : begin
            busif_readData <= rd_addr; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h028 : begin
            busif_readData <= rd_num; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h02c : begin
            busif_readData <= {16'h0,debug_dma_rd_in_cnt}; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h030 : begin
            busif_readData <= {15'h0,fsm_base_addr}; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h034 : begin
            busif_readData <= {20'h0,nodes_status}; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h038 : begin
            busif_readData <= {29'h0,{rd_done_intr_raw,{finish_intr_raw,small_loop_end_int_raw}}}; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h03c : begin
            busif_readData <= {29'h0,{rd_done_intr_mask,{finish_intr_mask,small_loop_end_int_mask}}}; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h040 : begin
            busif_readData <= {29'h0,{rd_done_intr_status,{finish_intr_status,small_loop_end_int_status}}}; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          default : begin
            busif_readData <= 32'h0; // @ BusIfBase.scala l364
            busif_readError <= 1'b0; // @ BusIfBase.scala l366
          end
        endcase
      end else begin
        busif_readData <= 32'h0; // @ BusIfBase.scala l375
        busif_readError <= 1'b0; // @ BusIfBase.scala l376
      end
    end
  end

  // hand write
  assign io_fsm_auto_restart_en = small_loop_end_int_mask;
  assign io_fsm_restart = write_hit_0x0038 
                      && (io_apb_PWDATA[0] && busif_wmask[0]) 
                      && small_loop_end_int_raw
                      ;

endmodule
