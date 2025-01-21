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
  input      [11:0]   io_nodes_pc_serial,
  output              io_intr,
  output              io_fsm_auto_restart_en,
  output              io_fsm_restart,
  input               clk,
  input               resetn
);

  wire       [0:0]    tmp_rd_cfg_en;
  wire       [0:0]    tmp_rd_cfg_outstd_en;
  wire       [0:0]    tmp_rd_cfg_cross4k_en;
  wire       [0:0]    tmp_rd_cfg_arvld_hold_en;
  wire       [0:0]    tmp_rd_cfg_resi_mode;
  reg        [31:0]   tmp_node_pc_0;
  reg        [31:0]   tmp_node_pc_1;
  reg        [31:0]   tmp_node_pc_2;
  reg        [31:0]   tmp_node_pc_3;
  reg        [31:0]   tmp_node_pc_4;
  reg        [31:0]   tmp_node_pc_5;
  reg        [31:0]   tmp_node_pc_6;
  reg        [31:0]   tmp_node_pc_7;
  reg        [31:0]   tmp_node_pc_8;
  reg        [31:0]   tmp_node_pc_9;
  reg        [31:0]   tmp_node_pc_10;
  reg        [31:0]   tmp_node_pc_11;
  wire       [0:0]    tmp_small_loop_end_int_mask;
  wire       [0:0]    tmp_finish_intr_mask;
  wire       [0:0]    tmp_rd_done_intr_mask;
  wire       [11:0]   tmp_13;
  wire       [0:0]    tmp_busif_readData;
  wire       [1:0]    tmp_busif_readData_1;
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
  wire                read_hit_0x0044;
  wire                write_hit_0x0044;
  wire                read_hit_0x0048;
  wire                write_hit_0x0048;
  wire                read_hit_0x004c;
  wire                write_hit_0x004c;
  wire                read_hit_0x0050;
  wire                write_hit_0x0050;
  wire                read_hit_0x0054;
  wire                write_hit_0x0054;
  wire                read_hit_0x0058;
  wire                write_hit_0x0058;
  wire                read_hit_0x005c;
  wire                write_hit_0x005c;
  wire                read_hit_0x0060;
  wire                write_hit_0x0060;
  wire                read_hit_0x0064;
  wire                write_hit_0x0064;
  wire                read_hit_0x0068;
  wire                write_hit_0x0068;
  wire                read_hit_0x006c;
  wire                write_hit_0x006c;
  wire                read_hit_0x0070;
  wire                write_hit_0x0070;
  wire                read_hit_0x0074;
  wire                write_hit_0x0074;
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
  wire       [31:0]   node_pc_0;
  wire       [31:0]   node_pc_1;
  wire       [31:0]   node_pc_2;
  wire       [31:0]   node_pc_3;
  wire       [31:0]   node_pc_4;
  wire       [31:0]   node_pc_5;
  wire       [31:0]   node_pc_6;
  wire       [31:0]   node_pc_7;
  wire       [31:0]   node_pc_8;
  wire       [31:0]   node_pc_9;
  wire       [31:0]   node_pc_10;
  wire       [31:0]   node_pc_11;
  wire                node_pc_valid_0;
  wire                node_pc_valid_1;
  wire                node_pc_valid_2;
  wire                node_pc_valid_3;
  wire                node_pc_valid_4;
  wire                node_pc_valid_5;
  wire                node_pc_valid_6;
  wire                node_pc_valid_7;
  wire                node_pc_valid_8;
  wire                node_pc_valid_9;
  wire                node_pc_valid_10;
  wire                node_pc_valid_11;
  reg        [31:0]   node_pc_lock_0;
  reg        [31:0]   node_pc_lock_1;
  reg        [31:0]   node_pc_lock_2;
  reg        [31:0]   node_pc_lock_3;
  reg        [31:0]   node_pc_lock_4;
  reg        [31:0]   node_pc_lock_5;
  reg        [31:0]   node_pc_lock_6;
  reg        [31:0]   node_pc_lock_7;
  reg        [31:0]   node_pc_lock_8;
  reg        [31:0]   node_pc_lock_9;
  reg        [31:0]   node_pc_lock_10;
  reg        [31:0]   node_pc_lock_11;
  reg        [11:0]   node_pc_end;
  reg        [4:0]    node_pc_cnt_0;
  reg        [4:0]    node_pc_cnt_1;
  reg        [4:0]    node_pc_cnt_2;
  reg        [4:0]    node_pc_cnt_3;
  reg        [4:0]    node_pc_cnt_4;
  reg        [4:0]    node_pc_cnt_5;
  reg        [4:0]    node_pc_cnt_6;
  reg        [4:0]    node_pc_cnt_7;
  reg        [4:0]    node_pc_cnt_8;
  reg        [4:0]    node_pc_cnt_9;
  reg        [4:0]    node_pc_cnt_10;
  reg        [4:0]    node_pc_cnt_11;
  reg        [11:0]   node_pc_start;
  reg        [11:0]   node_pc_cnt_is_counting;
  reg        [11:0]   node_pc_valid;
  reg        [31:0]   node_pc_entry_0_0;
  reg        [31:0]   node_pc_entry_0_1;
  reg        [31:0]   node_pc_entry_0_2;
  reg        [31:0]   node_pc_entry_0_3;
  reg        [31:0]   node_pc_entry_1_0;
  reg        [31:0]   node_pc_entry_1_1;
  reg        [31:0]   node_pc_entry_1_2;
  reg        [31:0]   node_pc_entry_1_3;
  reg        [31:0]   node_pc_entry_2_0;
  reg        [31:0]   node_pc_entry_2_1;
  reg        [31:0]   node_pc_entry_2_2;
  reg        [31:0]   node_pc_entry_2_3;
  reg        [31:0]   node_pc_entry_3_0;
  reg        [31:0]   node_pc_entry_3_1;
  reg        [31:0]   node_pc_entry_3_2;
  reg        [31:0]   node_pc_entry_3_3;
  reg        [31:0]   node_pc_entry_4_0;
  reg        [31:0]   node_pc_entry_4_1;
  reg        [31:0]   node_pc_entry_4_2;
  reg        [31:0]   node_pc_entry_4_3;
  reg        [31:0]   node_pc_entry_5_0;
  reg        [31:0]   node_pc_entry_5_1;
  reg        [31:0]   node_pc_entry_5_2;
  reg        [31:0]   node_pc_entry_5_3;
  reg        [31:0]   node_pc_entry_6_0;
  reg        [31:0]   node_pc_entry_6_1;
  reg        [31:0]   node_pc_entry_6_2;
  reg        [31:0]   node_pc_entry_6_3;
  reg        [31:0]   node_pc_entry_7_0;
  reg        [31:0]   node_pc_entry_7_1;
  reg        [31:0]   node_pc_entry_7_2;
  reg        [31:0]   node_pc_entry_7_3;
  reg        [31:0]   node_pc_entry_8_0;
  reg        [31:0]   node_pc_entry_8_1;
  reg        [31:0]   node_pc_entry_8_2;
  reg        [31:0]   node_pc_entry_8_3;
  reg        [31:0]   node_pc_entry_9_0;
  reg        [31:0]   node_pc_entry_9_1;
  reg        [31:0]   node_pc_entry_9_2;
  reg        [31:0]   node_pc_entry_9_3;
  reg        [31:0]   node_pc_entry_10_0;
  reg        [31:0]   node_pc_entry_10_1;
  reg        [31:0]   node_pc_entry_10_2;
  reg        [31:0]   node_pc_entry_10_3;
  reg        [31:0]   node_pc_entry_11_0;
  reg        [31:0]   node_pc_entry_11_1;
  reg        [31:0]   node_pc_entry_11_2;
  reg        [31:0]   node_pc_entry_11_3;
  reg        [1:0]    node_pc_read_addr_0;
  reg        [1:0]    node_pc_read_addr_1;
  reg        [1:0]    node_pc_read_addr_2;
  reg        [1:0]    node_pc_read_addr_3;
  reg        [1:0]    node_pc_read_addr_4;
  reg        [1:0]    node_pc_read_addr_5;
  reg        [1:0]    node_pc_read_addr_6;
  reg        [1:0]    node_pc_read_addr_7;
  reg        [1:0]    node_pc_read_addr_8;
  reg        [1:0]    node_pc_read_addr_9;
  reg        [1:0]    node_pc_read_addr_10;
  reg        [1:0]    node_pc_read_addr_11;
  reg        [1:0]    node_pc_write_addr_0;
  reg        [1:0]    node_pc_write_addr_1;
  reg        [1:0]    node_pc_write_addr_2;
  reg        [1:0]    node_pc_write_addr_3;
  reg        [1:0]    node_pc_write_addr_4;
  reg        [1:0]    node_pc_write_addr_5;
  reg        [1:0]    node_pc_write_addr_6;
  reg        [1:0]    node_pc_write_addr_7;
  reg        [1:0]    node_pc_write_addr_8;
  reg        [1:0]    node_pc_write_addr_9;
  reg        [1:0]    node_pc_write_addr_10;
  reg        [1:0]    node_pc_write_addr_11;
  wire       [3:0]    tmp_1;
  wire       [31:0]   tmp_node_pc_entry_0_0;
  wire       [3:0]    tmp_2;
  wire       [31:0]   tmp_node_pc_entry_1_0;
  wire       [3:0]    tmp_3;
  wire       [31:0]   tmp_node_pc_entry_2_0;
  wire       [3:0]    tmp_4;
  wire       [31:0]   tmp_node_pc_entry_3_0;
  wire       [3:0]    tmp_5;
  wire       [31:0]   tmp_node_pc_entry_4_0;
  wire       [3:0]    tmp_6;
  wire       [31:0]   tmp_node_pc_entry_5_0;
  wire       [3:0]    tmp_7;
  wire       [31:0]   tmp_node_pc_entry_6_0;
  wire       [3:0]    tmp_8;
  wire       [31:0]   tmp_node_pc_entry_7_0;
  wire       [3:0]    tmp_9;
  wire       [31:0]   tmp_node_pc_entry_8_0;
  wire       [3:0]    tmp_10;
  wire       [31:0]   tmp_node_pc_entry_9_0;
  wire       [3:0]    tmp_11;
  wire       [31:0]   tmp_node_pc_entry_10_0;
  wire       [3:0]    tmp_12;
  wire       [31:0]   tmp_node_pc_entry_11_0;
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

  assign tmp_13 = {io_apb_PADDR[11 : 2],2'b00};
  assign tmp_rd_cfg_en = ((rd_cfg_en & busif_wmaskn[0 : 0]) | (io_apb_PWDATA[0 : 0] & busif_wmask[0 : 0]));
  assign tmp_rd_cfg_outstd_en = ((rd_cfg_outstd_en & busif_wmaskn[4 : 4]) | (io_apb_PWDATA[4 : 4] & busif_wmask[4 : 4]));
  assign tmp_rd_cfg_cross4k_en = ((rd_cfg_cross4k_en & busif_wmaskn[5 : 5]) | (io_apb_PWDATA[5 : 5] & busif_wmask[5 : 5]));
  assign tmp_rd_cfg_arvld_hold_en = ((rd_cfg_arvld_hold_en & busif_wmaskn[6 : 6]) | (io_apb_PWDATA[6 : 6] & busif_wmask[6 : 6]));
  assign tmp_rd_cfg_resi_mode = ((rd_cfg_resi_mode & busif_wmaskn[7 : 7]) | (io_apb_PWDATA[7 : 7] & busif_wmask[7 : 7]));
  assign tmp_small_loop_end_int_mask = ((small_loop_end_int_mask & busif_wmaskn[0 : 0]) | (io_apb_PWDATA[0 : 0] & busif_wmask[0 : 0]));
  assign tmp_finish_intr_mask = ((finish_intr_mask & busif_wmaskn[1 : 1]) | (io_apb_PWDATA[1 : 1] & busif_wmask[1 : 1]));
  assign tmp_rd_done_intr_mask = ((rd_done_intr_mask & busif_wmaskn[2 : 2]) | (io_apb_PWDATA[2 : 2] & busif_wmask[2 : 2]));
  assign tmp_busif_readData = node_pc_valid_2;
  assign tmp_busif_readData_1 = {node_pc_valid_1,node_pc_valid_0};
  always @(*) begin
    case(node_pc_read_addr_0)
      2'b00 : tmp_node_pc_0 = node_pc_entry_0_0;
      2'b01 : tmp_node_pc_0 = node_pc_entry_0_1;
      2'b10 : tmp_node_pc_0 = node_pc_entry_0_2;
      default : tmp_node_pc_0 = node_pc_entry_0_3;
    endcase
  end

  always @(*) begin
    case(node_pc_read_addr_1)
      2'b00 : tmp_node_pc_1 = node_pc_entry_1_0;
      2'b01 : tmp_node_pc_1 = node_pc_entry_1_1;
      2'b10 : tmp_node_pc_1 = node_pc_entry_1_2;
      default : tmp_node_pc_1 = node_pc_entry_1_3;
    endcase
  end

  always @(*) begin
    case(node_pc_read_addr_2)
      2'b00 : tmp_node_pc_2 = node_pc_entry_2_0;
      2'b01 : tmp_node_pc_2 = node_pc_entry_2_1;
      2'b10 : tmp_node_pc_2 = node_pc_entry_2_2;
      default : tmp_node_pc_2 = node_pc_entry_2_3;
    endcase
  end

  always @(*) begin
    case(node_pc_read_addr_3)
      2'b00 : tmp_node_pc_3 = node_pc_entry_3_0;
      2'b01 : tmp_node_pc_3 = node_pc_entry_3_1;
      2'b10 : tmp_node_pc_3 = node_pc_entry_3_2;
      default : tmp_node_pc_3 = node_pc_entry_3_3;
    endcase
  end

  always @(*) begin
    case(node_pc_read_addr_4)
      2'b00 : tmp_node_pc_4 = node_pc_entry_4_0;
      2'b01 : tmp_node_pc_4 = node_pc_entry_4_1;
      2'b10 : tmp_node_pc_4 = node_pc_entry_4_2;
      default : tmp_node_pc_4 = node_pc_entry_4_3;
    endcase
  end

  always @(*) begin
    case(node_pc_read_addr_5)
      2'b00 : tmp_node_pc_5 = node_pc_entry_5_0;
      2'b01 : tmp_node_pc_5 = node_pc_entry_5_1;
      2'b10 : tmp_node_pc_5 = node_pc_entry_5_2;
      default : tmp_node_pc_5 = node_pc_entry_5_3;
    endcase
  end

  always @(*) begin
    case(node_pc_read_addr_6)
      2'b00 : tmp_node_pc_6 = node_pc_entry_6_0;
      2'b01 : tmp_node_pc_6 = node_pc_entry_6_1;
      2'b10 : tmp_node_pc_6 = node_pc_entry_6_2;
      default : tmp_node_pc_6 = node_pc_entry_6_3;
    endcase
  end

  always @(*) begin
    case(node_pc_read_addr_7)
      2'b00 : tmp_node_pc_7 = node_pc_entry_7_0;
      2'b01 : tmp_node_pc_7 = node_pc_entry_7_1;
      2'b10 : tmp_node_pc_7 = node_pc_entry_7_2;
      default : tmp_node_pc_7 = node_pc_entry_7_3;
    endcase
  end

  always @(*) begin
    case(node_pc_read_addr_8)
      2'b00 : tmp_node_pc_8 = node_pc_entry_8_0;
      2'b01 : tmp_node_pc_8 = node_pc_entry_8_1;
      2'b10 : tmp_node_pc_8 = node_pc_entry_8_2;
      default : tmp_node_pc_8 = node_pc_entry_8_3;
    endcase
  end

  always @(*) begin
    case(node_pc_read_addr_9)
      2'b00 : tmp_node_pc_9 = node_pc_entry_9_0;
      2'b01 : tmp_node_pc_9 = node_pc_entry_9_1;
      2'b10 : tmp_node_pc_9 = node_pc_entry_9_2;
      default : tmp_node_pc_9 = node_pc_entry_9_3;
    endcase
  end

  always @(*) begin
    case(node_pc_read_addr_10)
      2'b00 : tmp_node_pc_10 = node_pc_entry_10_0;
      2'b01 : tmp_node_pc_10 = node_pc_entry_10_1;
      2'b10 : tmp_node_pc_10 = node_pc_entry_10_2;
      default : tmp_node_pc_10 = node_pc_entry_10_3;
    endcase
  end

  always @(*) begin
    case(node_pc_read_addr_11)
      2'b00 : tmp_node_pc_11 = node_pc_entry_11_0;
      2'b01 : tmp_node_pc_11 = node_pc_entry_11_1;
      2'b10 : tmp_node_pc_11 = node_pc_entry_11_2;
      default : tmp_node_pc_11 = node_pc_entry_11_3;
    endcase
  end

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
  assign read_hit_0x0044 = (({io_apb_PADDR[11 : 2],2'b00} == 12'h044) && busif_doRead); // @ BaseType.scala l305
  assign write_hit_0x0044 = ((io_apb_PADDR == 12'h044) && busif_doWrite); // @ BaseType.scala l305
  assign read_hit_0x0048 = (({io_apb_PADDR[11 : 2],2'b00} == 12'h048) && busif_doRead); // @ BaseType.scala l305
  assign write_hit_0x0048 = ((io_apb_PADDR == 12'h048) && busif_doWrite); // @ BaseType.scala l305
  assign read_hit_0x004c = (({io_apb_PADDR[11 : 2],2'b00} == 12'h04c) && busif_doRead); // @ BaseType.scala l305
  assign write_hit_0x004c = ((io_apb_PADDR == 12'h04c) && busif_doWrite); // @ BaseType.scala l305
  assign read_hit_0x0050 = (({io_apb_PADDR[11 : 2],2'b00} == 12'h050) && busif_doRead); // @ BaseType.scala l305
  assign write_hit_0x0050 = ((io_apb_PADDR == 12'h050) && busif_doWrite); // @ BaseType.scala l305
  assign read_hit_0x0054 = (({io_apb_PADDR[11 : 2],2'b00} == 12'h054) && busif_doRead); // @ BaseType.scala l305
  assign write_hit_0x0054 = ((io_apb_PADDR == 12'h054) && busif_doWrite); // @ BaseType.scala l305
  assign read_hit_0x0058 = (({io_apb_PADDR[11 : 2],2'b00} == 12'h058) && busif_doRead); // @ BaseType.scala l305
  assign write_hit_0x0058 = ((io_apb_PADDR == 12'h058) && busif_doWrite); // @ BaseType.scala l305
  assign read_hit_0x005c = (({io_apb_PADDR[11 : 2],2'b00} == 12'h05c) && busif_doRead); // @ BaseType.scala l305
  assign write_hit_0x005c = ((io_apb_PADDR == 12'h05c) && busif_doWrite); // @ BaseType.scala l305
  assign read_hit_0x0060 = (({io_apb_PADDR[11 : 2],2'b00} == 12'h060) && busif_doRead); // @ BaseType.scala l305
  assign write_hit_0x0060 = ((io_apb_PADDR == 12'h060) && busif_doWrite); // @ BaseType.scala l305
  assign read_hit_0x0064 = (({io_apb_PADDR[11 : 2],2'b00} == 12'h064) && busif_doRead); // @ BaseType.scala l305
  assign write_hit_0x0064 = ((io_apb_PADDR == 12'h064) && busif_doWrite); // @ BaseType.scala l305
  assign read_hit_0x0068 = (({io_apb_PADDR[11 : 2],2'b00} == 12'h068) && busif_doRead); // @ BaseType.scala l305
  assign write_hit_0x0068 = ((io_apb_PADDR == 12'h068) && busif_doWrite); // @ BaseType.scala l305
  assign read_hit_0x006c = (({io_apb_PADDR[11 : 2],2'b00} == 12'h06c) && busif_doRead); // @ BaseType.scala l305
  assign write_hit_0x006c = ((io_apb_PADDR == 12'h06c) && busif_doWrite); // @ BaseType.scala l305
  assign read_hit_0x0070 = (({io_apb_PADDR[11 : 2],2'b00} == 12'h070) && busif_doRead); // @ BaseType.scala l305
  assign write_hit_0x0070 = ((io_apb_PADDR == 12'h070) && busif_doWrite); // @ BaseType.scala l305
  assign read_hit_0x0074 = (({io_apb_PADDR[11 : 2],2'b00} == 12'h074) && busif_doRead); // @ BaseType.scala l305
  assign write_hit_0x0074 = ((io_apb_PADDR == 12'h074) && busif_doWrite); // @ BaseType.scala l305
  assign reserved = 15'h0; // @ Bits.scala l133
  always @(*) begin
    node_pc_start[0] = ((node_pc_cnt_is_counting[0] == 1'b0) && (io_nodes_pc_serial[0] == 1'b1)); // @ idma_inoc_regfile.scala l124
    node_pc_start[1] = ((node_pc_cnt_is_counting[1] == 1'b0) && (io_nodes_pc_serial[1] == 1'b1)); // @ idma_inoc_regfile.scala l124
    node_pc_start[2] = ((node_pc_cnt_is_counting[2] == 1'b0) && (io_nodes_pc_serial[2] == 1'b1)); // @ idma_inoc_regfile.scala l124
    node_pc_start[3] = ((node_pc_cnt_is_counting[3] == 1'b0) && (io_nodes_pc_serial[3] == 1'b1)); // @ idma_inoc_regfile.scala l124
    node_pc_start[4] = ((node_pc_cnt_is_counting[4] == 1'b0) && (io_nodes_pc_serial[4] == 1'b1)); // @ idma_inoc_regfile.scala l124
    node_pc_start[5] = ((node_pc_cnt_is_counting[5] == 1'b0) && (io_nodes_pc_serial[5] == 1'b1)); // @ idma_inoc_regfile.scala l124
    node_pc_start[6] = ((node_pc_cnt_is_counting[6] == 1'b0) && (io_nodes_pc_serial[6] == 1'b1)); // @ idma_inoc_regfile.scala l124
    node_pc_start[7] = ((node_pc_cnt_is_counting[7] == 1'b0) && (io_nodes_pc_serial[7] == 1'b1)); // @ idma_inoc_regfile.scala l124
    node_pc_start[8] = ((node_pc_cnt_is_counting[8] == 1'b0) && (io_nodes_pc_serial[8] == 1'b1)); // @ idma_inoc_regfile.scala l124
    node_pc_start[9] = ((node_pc_cnt_is_counting[9] == 1'b0) && (io_nodes_pc_serial[9] == 1'b1)); // @ idma_inoc_regfile.scala l124
    node_pc_start[10] = ((node_pc_cnt_is_counting[10] == 1'b0) && (io_nodes_pc_serial[10] == 1'b1)); // @ idma_inoc_regfile.scala l124
    node_pc_start[11] = ((node_pc_cnt_is_counting[11] == 1'b0) && (io_nodes_pc_serial[11] == 1'b1)); // @ idma_inoc_regfile.scala l124
  end

  always @(*) begin
    node_pc_end[0] = (node_pc_cnt_is_counting[0] && (node_pc_cnt_0 == 5'h1f)); // @ idma_inoc_regfile.scala l125
    node_pc_end[1] = (node_pc_cnt_is_counting[1] && (node_pc_cnt_1 == 5'h1f)); // @ idma_inoc_regfile.scala l125
    node_pc_end[2] = (node_pc_cnt_is_counting[2] && (node_pc_cnt_2 == 5'h1f)); // @ idma_inoc_regfile.scala l125
    node_pc_end[3] = (node_pc_cnt_is_counting[3] && (node_pc_cnt_3 == 5'h1f)); // @ idma_inoc_regfile.scala l125
    node_pc_end[4] = (node_pc_cnt_is_counting[4] && (node_pc_cnt_4 == 5'h1f)); // @ idma_inoc_regfile.scala l125
    node_pc_end[5] = (node_pc_cnt_is_counting[5] && (node_pc_cnt_5 == 5'h1f)); // @ idma_inoc_regfile.scala l125
    node_pc_end[6] = (node_pc_cnt_is_counting[6] && (node_pc_cnt_6 == 5'h1f)); // @ idma_inoc_regfile.scala l125
    node_pc_end[7] = (node_pc_cnt_is_counting[7] && (node_pc_cnt_7 == 5'h1f)); // @ idma_inoc_regfile.scala l125
    node_pc_end[8] = (node_pc_cnt_is_counting[8] && (node_pc_cnt_8 == 5'h1f)); // @ idma_inoc_regfile.scala l125
    node_pc_end[9] = (node_pc_cnt_is_counting[9] && (node_pc_cnt_9 == 5'h1f)); // @ idma_inoc_regfile.scala l125
    node_pc_end[10] = (node_pc_cnt_is_counting[10] && (node_pc_cnt_10 == 5'h1f)); // @ idma_inoc_regfile.scala l125
    node_pc_end[11] = (node_pc_cnt_is_counting[11] && (node_pc_cnt_11 == 5'h1f)); // @ idma_inoc_regfile.scala l125
  end

  assign tmp_1 = ({3'd0,1'b1} <<< node_pc_write_addr_0); // @ BaseType.scala l299
  assign tmp_node_pc_entry_0_0 = {io_nodes_pc_serial[0],node_pc_lock_0[30 : 0]}; // @ BaseType.scala l299
  assign tmp_2 = ({3'd0,1'b1} <<< node_pc_write_addr_1); // @ BaseType.scala l299
  assign tmp_node_pc_entry_1_0 = {io_nodes_pc_serial[1],node_pc_lock_1[30 : 0]}; // @ BaseType.scala l299
  assign tmp_3 = ({3'd0,1'b1} <<< node_pc_write_addr_2); // @ BaseType.scala l299
  assign tmp_node_pc_entry_2_0 = {io_nodes_pc_serial[2],node_pc_lock_2[30 : 0]}; // @ BaseType.scala l299
  assign tmp_4 = ({3'd0,1'b1} <<< node_pc_write_addr_3); // @ BaseType.scala l299
  assign tmp_node_pc_entry_3_0 = {io_nodes_pc_serial[3],node_pc_lock_3[30 : 0]}; // @ BaseType.scala l299
  assign tmp_5 = ({3'd0,1'b1} <<< node_pc_write_addr_4); // @ BaseType.scala l299
  assign tmp_node_pc_entry_4_0 = {io_nodes_pc_serial[4],node_pc_lock_4[30 : 0]}; // @ BaseType.scala l299
  assign tmp_6 = ({3'd0,1'b1} <<< node_pc_write_addr_5); // @ BaseType.scala l299
  assign tmp_node_pc_entry_5_0 = {io_nodes_pc_serial[5],node_pc_lock_5[30 : 0]}; // @ BaseType.scala l299
  assign tmp_7 = ({3'd0,1'b1} <<< node_pc_write_addr_6); // @ BaseType.scala l299
  assign tmp_node_pc_entry_6_0 = {io_nodes_pc_serial[6],node_pc_lock_6[30 : 0]}; // @ BaseType.scala l299
  assign tmp_8 = ({3'd0,1'b1} <<< node_pc_write_addr_7); // @ BaseType.scala l299
  assign tmp_node_pc_entry_7_0 = {io_nodes_pc_serial[7],node_pc_lock_7[30 : 0]}; // @ BaseType.scala l299
  assign tmp_9 = ({3'd0,1'b1} <<< node_pc_write_addr_8); // @ BaseType.scala l299
  assign tmp_node_pc_entry_8_0 = {io_nodes_pc_serial[8],node_pc_lock_8[30 : 0]}; // @ BaseType.scala l299
  assign tmp_10 = ({3'd0,1'b1} <<< node_pc_write_addr_9); // @ BaseType.scala l299
  assign tmp_node_pc_entry_9_0 = {io_nodes_pc_serial[9],node_pc_lock_9[30 : 0]}; // @ BaseType.scala l299
  assign tmp_11 = ({3'd0,1'b1} <<< node_pc_write_addr_10); // @ BaseType.scala l299
  assign tmp_node_pc_entry_10_0 = {io_nodes_pc_serial[10],node_pc_lock_10[30 : 0]}; // @ BaseType.scala l299
  assign tmp_12 = ({3'd0,1'b1} <<< node_pc_write_addr_11); // @ BaseType.scala l299
  assign tmp_node_pc_entry_11_0 = {io_nodes_pc_serial[11],node_pc_lock_11[30 : 0]}; // @ BaseType.scala l299
  assign node_pc_0 = tmp_node_pc_0; // @ idma_inoc_regfile.scala l189
  assign node_pc_1 = tmp_node_pc_1; // @ idma_inoc_regfile.scala l190
  assign node_pc_2 = tmp_node_pc_2; // @ idma_inoc_regfile.scala l191
  assign node_pc_3 = tmp_node_pc_3; // @ idma_inoc_regfile.scala l192
  assign node_pc_4 = tmp_node_pc_4; // @ idma_inoc_regfile.scala l193
  assign node_pc_5 = tmp_node_pc_5; // @ idma_inoc_regfile.scala l194
  assign node_pc_6 = tmp_node_pc_6; // @ idma_inoc_regfile.scala l195
  assign node_pc_7 = tmp_node_pc_7; // @ idma_inoc_regfile.scala l196
  assign node_pc_8 = tmp_node_pc_8; // @ idma_inoc_regfile.scala l197
  assign node_pc_9 = tmp_node_pc_9; // @ idma_inoc_regfile.scala l198
  assign node_pc_10 = tmp_node_pc_10; // @ idma_inoc_regfile.scala l199
  assign node_pc_11 = tmp_node_pc_11; // @ idma_inoc_regfile.scala l200
  assign node_pc_valid_0 = node_pc_valid[0]; // @ idma_inoc_regfile.scala l202
  assign node_pc_valid_1 = node_pc_valid[1]; // @ idma_inoc_regfile.scala l203
  assign node_pc_valid_2 = node_pc_valid[2]; // @ idma_inoc_regfile.scala l204
  assign node_pc_valid_3 = node_pc_valid[3]; // @ idma_inoc_regfile.scala l205
  assign node_pc_valid_4 = node_pc_valid[4]; // @ idma_inoc_regfile.scala l206
  assign node_pc_valid_5 = node_pc_valid[5]; // @ idma_inoc_regfile.scala l207
  assign node_pc_valid_6 = node_pc_valid[6]; // @ idma_inoc_regfile.scala l208
  assign node_pc_valid_7 = node_pc_valid[7]; // @ idma_inoc_regfile.scala l209
  assign node_pc_valid_8 = node_pc_valid[8]; // @ idma_inoc_regfile.scala l210
  assign node_pc_valid_9 = node_pc_valid[9]; // @ idma_inoc_regfile.scala l211
  assign node_pc_valid_10 = node_pc_valid[10]; // @ idma_inoc_regfile.scala l212
  assign node_pc_valid_11 = node_pc_valid[11]; // @ idma_inoc_regfile.scala l213
  assign io_rd_cfg_ready = rd_cfg_en; // @ idma_inoc_regfile.scala l217
  assign io_rd_afifo_init = rd_afifo_init; // @ idma_inoc_regfile.scala l218
  assign io_rd_dfifo_init = rd_dfifo_init; // @ idma_inoc_regfile.scala l219
  assign io_rd_cfg_outstd = rd_cfg_outstd; // @ idma_inoc_regfile.scala l220
  assign io_rd_cfg_outstd_en = rd_cfg_outstd_en; // @ idma_inoc_regfile.scala l221
  assign io_rd_cfg_cross4k_en = rd_cfg_cross4k_en; // @ idma_inoc_regfile.scala l222
  assign io_rd_cfg_arvld_hold_en = rd_cfg_arvld_hold_en; // @ idma_inoc_regfile.scala l223
  assign io_rd_cfg_dfifo_thd = rd_cfg_dfifo_thd[6:0]; // @ idma_inoc_regfile.scala l224
  assign io_rd_cfg_resi_mode = rd_cfg_resi_mode; // @ idma_inoc_regfile.scala l225
  assign io_rd_cfg_resi_fmap_a_addr = rd_cfg_resi_fmap_a_addr; // @ idma_inoc_regfile.scala l226
  assign io_rd_cfg_resi_fmap_b_addr = rd_cfg_resi_fmap_b_addr; // @ idma_inoc_regfile.scala l227
  assign io_rd_cfg_resi_addr_gap = rd_cfg_resi_addr_gap[15:0]; // @ idma_inoc_regfile.scala l228
  assign io_rd_cfg_resi_loop_num = rd_cfg_resi_loop_num[15:0]; // @ idma_inoc_regfile.scala l229
  assign io_rd_req = rd_req; // @ idma_inoc_regfile.scala l230
  assign io_rd_addr = rd_addr; // @ idma_inoc_regfile.scala l231
  assign io_rd_num = rd_num; // @ idma_inoc_regfile.scala l232
  assign io_fsm_start = write_hit_0x0030; // @ idma_inoc_regfile.scala l233
  assign io_fsm_base_addr = fsm_base_addr; // @ idma_inoc_regfile.scala l234
  assign debug_dma_rd_in_cnt = io_debug_dma_rd_in_cnt; // @ idma_inoc_regfile.scala l237
  assign nodes_status = io_nodes_status; // @ idma_inoc_regfile.scala l238
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
  assign io_intr = INTR_intr; // @ idma_inoc_regfile.scala l239
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
      node_pc_lock_0 <= 32'h0; // @ Data.scala l400
      node_pc_lock_1 <= 32'h0; // @ Data.scala l400
      node_pc_lock_2 <= 32'h0; // @ Data.scala l400
      node_pc_lock_3 <= 32'h0; // @ Data.scala l400
      node_pc_lock_4 <= 32'h0; // @ Data.scala l400
      node_pc_lock_5 <= 32'h0; // @ Data.scala l400
      node_pc_lock_6 <= 32'h0; // @ Data.scala l400
      node_pc_lock_7 <= 32'h0; // @ Data.scala l400
      node_pc_lock_8 <= 32'h0; // @ Data.scala l400
      node_pc_lock_9 <= 32'h0; // @ Data.scala l400
      node_pc_lock_10 <= 32'h0; // @ Data.scala l400
      node_pc_lock_11 <= 32'h0; // @ Data.scala l400
      node_pc_cnt_0 <= 5'h0; // @ Data.scala l400
      node_pc_cnt_1 <= 5'h0; // @ Data.scala l400
      node_pc_cnt_2 <= 5'h0; // @ Data.scala l400
      node_pc_cnt_3 <= 5'h0; // @ Data.scala l400
      node_pc_cnt_4 <= 5'h0; // @ Data.scala l400
      node_pc_cnt_5 <= 5'h0; // @ Data.scala l400
      node_pc_cnt_6 <= 5'h0; // @ Data.scala l400
      node_pc_cnt_7 <= 5'h0; // @ Data.scala l400
      node_pc_cnt_8 <= 5'h0; // @ Data.scala l400
      node_pc_cnt_9 <= 5'h0; // @ Data.scala l400
      node_pc_cnt_10 <= 5'h0; // @ Data.scala l400
      node_pc_cnt_11 <= 5'h0; // @ Data.scala l400
      node_pc_cnt_is_counting <= 12'h0; // @ Data.scala l400
      node_pc_valid <= 12'h0; // @ Data.scala l400
      node_pc_entry_0_0 <= 32'h0; // @ Data.scala l400
      node_pc_entry_0_1 <= 32'h0; // @ Data.scala l400
      node_pc_entry_0_2 <= 32'h0; // @ Data.scala l400
      node_pc_entry_0_3 <= 32'h0; // @ Data.scala l400
      node_pc_entry_1_0 <= 32'h0; // @ Data.scala l400
      node_pc_entry_1_1 <= 32'h0; // @ Data.scala l400
      node_pc_entry_1_2 <= 32'h0; // @ Data.scala l400
      node_pc_entry_1_3 <= 32'h0; // @ Data.scala l400
      node_pc_entry_2_0 <= 32'h0; // @ Data.scala l400
      node_pc_entry_2_1 <= 32'h0; // @ Data.scala l400
      node_pc_entry_2_2 <= 32'h0; // @ Data.scala l400
      node_pc_entry_2_3 <= 32'h0; // @ Data.scala l400
      node_pc_entry_3_0 <= 32'h0; // @ Data.scala l400
      node_pc_entry_3_1 <= 32'h0; // @ Data.scala l400
      node_pc_entry_3_2 <= 32'h0; // @ Data.scala l400
      node_pc_entry_3_3 <= 32'h0; // @ Data.scala l400
      node_pc_entry_4_0 <= 32'h0; // @ Data.scala l400
      node_pc_entry_4_1 <= 32'h0; // @ Data.scala l400
      node_pc_entry_4_2 <= 32'h0; // @ Data.scala l400
      node_pc_entry_4_3 <= 32'h0; // @ Data.scala l400
      node_pc_entry_5_0 <= 32'h0; // @ Data.scala l400
      node_pc_entry_5_1 <= 32'h0; // @ Data.scala l400
      node_pc_entry_5_2 <= 32'h0; // @ Data.scala l400
      node_pc_entry_5_3 <= 32'h0; // @ Data.scala l400
      node_pc_entry_6_0 <= 32'h0; // @ Data.scala l400
      node_pc_entry_6_1 <= 32'h0; // @ Data.scala l400
      node_pc_entry_6_2 <= 32'h0; // @ Data.scala l400
      node_pc_entry_6_3 <= 32'h0; // @ Data.scala l400
      node_pc_entry_7_0 <= 32'h0; // @ Data.scala l400
      node_pc_entry_7_1 <= 32'h0; // @ Data.scala l400
      node_pc_entry_7_2 <= 32'h0; // @ Data.scala l400
      node_pc_entry_7_3 <= 32'h0; // @ Data.scala l400
      node_pc_entry_8_0 <= 32'h0; // @ Data.scala l400
      node_pc_entry_8_1 <= 32'h0; // @ Data.scala l400
      node_pc_entry_8_2 <= 32'h0; // @ Data.scala l400
      node_pc_entry_8_3 <= 32'h0; // @ Data.scala l400
      node_pc_entry_9_0 <= 32'h0; // @ Data.scala l400
      node_pc_entry_9_1 <= 32'h0; // @ Data.scala l400
      node_pc_entry_9_2 <= 32'h0; // @ Data.scala l400
      node_pc_entry_9_3 <= 32'h0; // @ Data.scala l400
      node_pc_entry_10_0 <= 32'h0; // @ Data.scala l400
      node_pc_entry_10_1 <= 32'h0; // @ Data.scala l400
      node_pc_entry_10_2 <= 32'h0; // @ Data.scala l400
      node_pc_entry_10_3 <= 32'h0; // @ Data.scala l400
      node_pc_entry_11_0 <= 32'h0; // @ Data.scala l400
      node_pc_entry_11_1 <= 32'h0; // @ Data.scala l400
      node_pc_entry_11_2 <= 32'h0; // @ Data.scala l400
      node_pc_entry_11_3 <= 32'h0; // @ Data.scala l400
      node_pc_read_addr_0 <= 2'b00; // @ Data.scala l400
      node_pc_read_addr_1 <= 2'b00; // @ Data.scala l400
      node_pc_read_addr_2 <= 2'b00; // @ Data.scala l400
      node_pc_read_addr_3 <= 2'b00; // @ Data.scala l400
      node_pc_read_addr_4 <= 2'b00; // @ Data.scala l400
      node_pc_read_addr_5 <= 2'b00; // @ Data.scala l400
      node_pc_read_addr_6 <= 2'b00; // @ Data.scala l400
      node_pc_read_addr_7 <= 2'b00; // @ Data.scala l400
      node_pc_read_addr_8 <= 2'b00; // @ Data.scala l400
      node_pc_read_addr_9 <= 2'b00; // @ Data.scala l400
      node_pc_read_addr_10 <= 2'b00; // @ Data.scala l400
      node_pc_read_addr_11 <= 2'b00; // @ Data.scala l400
      node_pc_write_addr_0 <= 2'b00; // @ Data.scala l400
      node_pc_write_addr_1 <= 2'b00; // @ Data.scala l400
      node_pc_write_addr_2 <= 2'b00; // @ Data.scala l400
      node_pc_write_addr_3 <= 2'b00; // @ Data.scala l400
      node_pc_write_addr_4 <= 2'b00; // @ Data.scala l400
      node_pc_write_addr_5 <= 2'b00; // @ Data.scala l400
      node_pc_write_addr_6 <= 2'b00; // @ Data.scala l400
      node_pc_write_addr_7 <= 2'b00; // @ Data.scala l400
      node_pc_write_addr_8 <= 2'b00; // @ Data.scala l400
      node_pc_write_addr_9 <= 2'b00; // @ Data.scala l400
      node_pc_write_addr_10 <= 2'b00; // @ Data.scala l400
      node_pc_write_addr_11 <= 2'b00; // @ Data.scala l400
      small_loop_end_int_raw <= 1'b0; // @ Data.scala l400
      small_loop_end_int_mask <= 1'b1; // @ Data.scala l400
      finish_intr_raw <= 1'b0; // @ Data.scala l400
      finish_intr_mask <= 1'b1; // @ Data.scala l400
      rd_done_intr_raw <= 1'b0; // @ Data.scala l400
      rd_done_intr_mask <= 1'b1; // @ Data.scala l400
    end else begin
      if(write_hit_0x0000) begin
        rd_cfg_en <= tmp_rd_cfg_en[0]; // @ Bool.scala l189
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
      if(node_pc_end[0]) begin
        node_pc_cnt_is_counting[0] <= 1'b0; // @ idma_inoc_regfile.scala l128
      end else begin
        if(node_pc_start[0]) begin
          node_pc_cnt_is_counting[0] <= 1'b1; // @ idma_inoc_regfile.scala l130
        end
      end
      if(node_pc_end[0]) begin
        node_pc_cnt_0 <= 5'h0; // @ idma_inoc_regfile.scala l134
      end else begin
        if(node_pc_cnt_is_counting[0]) begin
          node_pc_cnt_0 <= (node_pc_cnt_0 + 5'h01); // @ idma_inoc_regfile.scala l136
        end
      end
      if(node_pc_cnt_is_counting[0]) begin
        node_pc_lock_0[node_pc_cnt_0] <= io_nodes_pc_serial[0]; // @ idma_inoc_regfile.scala l140
      end
      if(read_hit_0x0044) begin
        node_pc_read_addr_0 <= (node_pc_read_addr_0 + 2'b01); // @ idma_inoc_regfile.scala l145
      end
      if(read_hit_0x0048) begin
        node_pc_read_addr_1 <= (node_pc_read_addr_1 + 2'b01); // @ idma_inoc_regfile.scala l148
      end
      if(read_hit_0x004c) begin
        node_pc_read_addr_2 <= (node_pc_read_addr_2 + 2'b01); // @ idma_inoc_regfile.scala l151
      end
      if(read_hit_0x0050) begin
        node_pc_read_addr_3 <= (node_pc_read_addr_3 + 2'b01); // @ idma_inoc_regfile.scala l154
      end
      if(read_hit_0x0054) begin
        node_pc_read_addr_4 <= (node_pc_read_addr_4 + 2'b01); // @ idma_inoc_regfile.scala l157
      end
      if(read_hit_0x0058) begin
        node_pc_read_addr_5 <= (node_pc_read_addr_5 + 2'b01); // @ idma_inoc_regfile.scala l160
      end
      if(read_hit_0x005c) begin
        node_pc_read_addr_6 <= (node_pc_read_addr_6 + 2'b01); // @ idma_inoc_regfile.scala l163
      end
      if(read_hit_0x0060) begin
        node_pc_read_addr_7 <= (node_pc_read_addr_7 + 2'b01); // @ idma_inoc_regfile.scala l166
      end
      if(read_hit_0x0064) begin
        node_pc_read_addr_8 <= (node_pc_read_addr_8 + 2'b01); // @ idma_inoc_regfile.scala l169
      end
      if(read_hit_0x0068) begin
        node_pc_read_addr_9 <= (node_pc_read_addr_9 + 2'b01); // @ idma_inoc_regfile.scala l172
      end
      if(read_hit_0x006c) begin
        node_pc_read_addr_10 <= (node_pc_read_addr_10 + 2'b01); // @ idma_inoc_regfile.scala l175
      end
      if(read_hit_0x0070) begin
        node_pc_read_addr_11 <= (node_pc_read_addr_11 + 2'b01); // @ idma_inoc_regfile.scala l178
      end
      if(node_pc_end[0]) begin
        node_pc_write_addr_0 <= (node_pc_write_addr_0 + 2'b01); // @ idma_inoc_regfile.scala l182
        if(tmp_1[0]) begin
          node_pc_entry_0_0 <= tmp_node_pc_entry_0_0; // @ idma_inoc_regfile.scala l183
        end
        if(tmp_1[1]) begin
          node_pc_entry_0_1 <= tmp_node_pc_entry_0_0; // @ idma_inoc_regfile.scala l183
        end
        if(tmp_1[2]) begin
          node_pc_entry_0_2 <= tmp_node_pc_entry_0_0; // @ idma_inoc_regfile.scala l183
        end
        if(tmp_1[3]) begin
          node_pc_entry_0_3 <= tmp_node_pc_entry_0_0; // @ idma_inoc_regfile.scala l183
        end
        node_pc_valid[0] <= 1'b1; // @ idma_inoc_regfile.scala l184
      end
      if(node_pc_end[1]) begin
        node_pc_cnt_is_counting[1] <= 1'b0; // @ idma_inoc_regfile.scala l128
      end else begin
        if(node_pc_start[1]) begin
          node_pc_cnt_is_counting[1] <= 1'b1; // @ idma_inoc_regfile.scala l130
        end
      end
      if(node_pc_end[1]) begin
        node_pc_cnt_1 <= 5'h0; // @ idma_inoc_regfile.scala l134
      end else begin
        if(node_pc_cnt_is_counting[1]) begin
          node_pc_cnt_1 <= (node_pc_cnt_1 + 5'h01); // @ idma_inoc_regfile.scala l136
        end
      end
      if(node_pc_cnt_is_counting[1]) begin
        node_pc_lock_1[node_pc_cnt_1] <= io_nodes_pc_serial[1]; // @ idma_inoc_regfile.scala l140
      end
      if(read_hit_0x0044) begin
        node_pc_read_addr_0 <= (node_pc_read_addr_0 + 2'b01); // @ idma_inoc_regfile.scala l145
      end
      if(read_hit_0x0048) begin
        node_pc_read_addr_1 <= (node_pc_read_addr_1 + 2'b01); // @ idma_inoc_regfile.scala l148
      end
      if(read_hit_0x004c) begin
        node_pc_read_addr_2 <= (node_pc_read_addr_2 + 2'b01); // @ idma_inoc_regfile.scala l151
      end
      if(read_hit_0x0050) begin
        node_pc_read_addr_3 <= (node_pc_read_addr_3 + 2'b01); // @ idma_inoc_regfile.scala l154
      end
      if(read_hit_0x0054) begin
        node_pc_read_addr_4 <= (node_pc_read_addr_4 + 2'b01); // @ idma_inoc_regfile.scala l157
      end
      if(read_hit_0x0058) begin
        node_pc_read_addr_5 <= (node_pc_read_addr_5 + 2'b01); // @ idma_inoc_regfile.scala l160
      end
      if(read_hit_0x005c) begin
        node_pc_read_addr_6 <= (node_pc_read_addr_6 + 2'b01); // @ idma_inoc_regfile.scala l163
      end
      if(read_hit_0x0060) begin
        node_pc_read_addr_7 <= (node_pc_read_addr_7 + 2'b01); // @ idma_inoc_regfile.scala l166
      end
      if(read_hit_0x0064) begin
        node_pc_read_addr_8 <= (node_pc_read_addr_8 + 2'b01); // @ idma_inoc_regfile.scala l169
      end
      if(read_hit_0x0068) begin
        node_pc_read_addr_9 <= (node_pc_read_addr_9 + 2'b01); // @ idma_inoc_regfile.scala l172
      end
      if(read_hit_0x006c) begin
        node_pc_read_addr_10 <= (node_pc_read_addr_10 + 2'b01); // @ idma_inoc_regfile.scala l175
      end
      if(read_hit_0x0070) begin
        node_pc_read_addr_11 <= (node_pc_read_addr_11 + 2'b01); // @ idma_inoc_regfile.scala l178
      end
      if(node_pc_end[1]) begin
        node_pc_write_addr_1 <= (node_pc_write_addr_1 + 2'b01); // @ idma_inoc_regfile.scala l182
        if(tmp_2[0]) begin
          node_pc_entry_1_0 <= tmp_node_pc_entry_1_0; // @ idma_inoc_regfile.scala l183
        end
        if(tmp_2[1]) begin
          node_pc_entry_1_1 <= tmp_node_pc_entry_1_0; // @ idma_inoc_regfile.scala l183
        end
        if(tmp_2[2]) begin
          node_pc_entry_1_2 <= tmp_node_pc_entry_1_0; // @ idma_inoc_regfile.scala l183
        end
        if(tmp_2[3]) begin
          node_pc_entry_1_3 <= tmp_node_pc_entry_1_0; // @ idma_inoc_regfile.scala l183
        end
        node_pc_valid[1] <= 1'b1; // @ idma_inoc_regfile.scala l184
      end
      if(node_pc_end[2]) begin
        node_pc_cnt_is_counting[2] <= 1'b0; // @ idma_inoc_regfile.scala l128
      end else begin
        if(node_pc_start[2]) begin
          node_pc_cnt_is_counting[2] <= 1'b1; // @ idma_inoc_regfile.scala l130
        end
      end
      if(node_pc_end[2]) begin
        node_pc_cnt_2 <= 5'h0; // @ idma_inoc_regfile.scala l134
      end else begin
        if(node_pc_cnt_is_counting[2]) begin
          node_pc_cnt_2 <= (node_pc_cnt_2 + 5'h01); // @ idma_inoc_regfile.scala l136
        end
      end
      if(node_pc_cnt_is_counting[2]) begin
        node_pc_lock_2[node_pc_cnt_2] <= io_nodes_pc_serial[2]; // @ idma_inoc_regfile.scala l140
      end
      if(read_hit_0x0044) begin
        node_pc_read_addr_0 <= (node_pc_read_addr_0 + 2'b01); // @ idma_inoc_regfile.scala l145
      end
      if(read_hit_0x0048) begin
        node_pc_read_addr_1 <= (node_pc_read_addr_1 + 2'b01); // @ idma_inoc_regfile.scala l148
      end
      if(read_hit_0x004c) begin
        node_pc_read_addr_2 <= (node_pc_read_addr_2 + 2'b01); // @ idma_inoc_regfile.scala l151
      end
      if(read_hit_0x0050) begin
        node_pc_read_addr_3 <= (node_pc_read_addr_3 + 2'b01); // @ idma_inoc_regfile.scala l154
      end
      if(read_hit_0x0054) begin
        node_pc_read_addr_4 <= (node_pc_read_addr_4 + 2'b01); // @ idma_inoc_regfile.scala l157
      end
      if(read_hit_0x0058) begin
        node_pc_read_addr_5 <= (node_pc_read_addr_5 + 2'b01); // @ idma_inoc_regfile.scala l160
      end
      if(read_hit_0x005c) begin
        node_pc_read_addr_6 <= (node_pc_read_addr_6 + 2'b01); // @ idma_inoc_regfile.scala l163
      end
      if(read_hit_0x0060) begin
        node_pc_read_addr_7 <= (node_pc_read_addr_7 + 2'b01); // @ idma_inoc_regfile.scala l166
      end
      if(read_hit_0x0064) begin
        node_pc_read_addr_8 <= (node_pc_read_addr_8 + 2'b01); // @ idma_inoc_regfile.scala l169
      end
      if(read_hit_0x0068) begin
        node_pc_read_addr_9 <= (node_pc_read_addr_9 + 2'b01); // @ idma_inoc_regfile.scala l172
      end
      if(read_hit_0x006c) begin
        node_pc_read_addr_10 <= (node_pc_read_addr_10 + 2'b01); // @ idma_inoc_regfile.scala l175
      end
      if(read_hit_0x0070) begin
        node_pc_read_addr_11 <= (node_pc_read_addr_11 + 2'b01); // @ idma_inoc_regfile.scala l178
      end
      if(node_pc_end[2]) begin
        node_pc_write_addr_2 <= (node_pc_write_addr_2 + 2'b01); // @ idma_inoc_regfile.scala l182
        if(tmp_3[0]) begin
          node_pc_entry_2_0 <= tmp_node_pc_entry_2_0; // @ idma_inoc_regfile.scala l183
        end
        if(tmp_3[1]) begin
          node_pc_entry_2_1 <= tmp_node_pc_entry_2_0; // @ idma_inoc_regfile.scala l183
        end
        if(tmp_3[2]) begin
          node_pc_entry_2_2 <= tmp_node_pc_entry_2_0; // @ idma_inoc_regfile.scala l183
        end
        if(tmp_3[3]) begin
          node_pc_entry_2_3 <= tmp_node_pc_entry_2_0; // @ idma_inoc_regfile.scala l183
        end
        node_pc_valid[2] <= 1'b1; // @ idma_inoc_regfile.scala l184
      end
      if(node_pc_end[3]) begin
        node_pc_cnt_is_counting[3] <= 1'b0; // @ idma_inoc_regfile.scala l128
      end else begin
        if(node_pc_start[3]) begin
          node_pc_cnt_is_counting[3] <= 1'b1; // @ idma_inoc_regfile.scala l130
        end
      end
      if(node_pc_end[3]) begin
        node_pc_cnt_3 <= 5'h0; // @ idma_inoc_regfile.scala l134
      end else begin
        if(node_pc_cnt_is_counting[3]) begin
          node_pc_cnt_3 <= (node_pc_cnt_3 + 5'h01); // @ idma_inoc_regfile.scala l136
        end
      end
      if(node_pc_cnt_is_counting[3]) begin
        node_pc_lock_3[node_pc_cnt_3] <= io_nodes_pc_serial[3]; // @ idma_inoc_regfile.scala l140
      end
      if(read_hit_0x0044) begin
        node_pc_read_addr_0 <= (node_pc_read_addr_0 + 2'b01); // @ idma_inoc_regfile.scala l145
      end
      if(read_hit_0x0048) begin
        node_pc_read_addr_1 <= (node_pc_read_addr_1 + 2'b01); // @ idma_inoc_regfile.scala l148
      end
      if(read_hit_0x004c) begin
        node_pc_read_addr_2 <= (node_pc_read_addr_2 + 2'b01); // @ idma_inoc_regfile.scala l151
      end
      if(read_hit_0x0050) begin
        node_pc_read_addr_3 <= (node_pc_read_addr_3 + 2'b01); // @ idma_inoc_regfile.scala l154
      end
      if(read_hit_0x0054) begin
        node_pc_read_addr_4 <= (node_pc_read_addr_4 + 2'b01); // @ idma_inoc_regfile.scala l157
      end
      if(read_hit_0x0058) begin
        node_pc_read_addr_5 <= (node_pc_read_addr_5 + 2'b01); // @ idma_inoc_regfile.scala l160
      end
      if(read_hit_0x005c) begin
        node_pc_read_addr_6 <= (node_pc_read_addr_6 + 2'b01); // @ idma_inoc_regfile.scala l163
      end
      if(read_hit_0x0060) begin
        node_pc_read_addr_7 <= (node_pc_read_addr_7 + 2'b01); // @ idma_inoc_regfile.scala l166
      end
      if(read_hit_0x0064) begin
        node_pc_read_addr_8 <= (node_pc_read_addr_8 + 2'b01); // @ idma_inoc_regfile.scala l169
      end
      if(read_hit_0x0068) begin
        node_pc_read_addr_9 <= (node_pc_read_addr_9 + 2'b01); // @ idma_inoc_regfile.scala l172
      end
      if(read_hit_0x006c) begin
        node_pc_read_addr_10 <= (node_pc_read_addr_10 + 2'b01); // @ idma_inoc_regfile.scala l175
      end
      if(read_hit_0x0070) begin
        node_pc_read_addr_11 <= (node_pc_read_addr_11 + 2'b01); // @ idma_inoc_regfile.scala l178
      end
      if(node_pc_end[3]) begin
        node_pc_write_addr_3 <= (node_pc_write_addr_3 + 2'b01); // @ idma_inoc_regfile.scala l182
        if(tmp_4[0]) begin
          node_pc_entry_3_0 <= tmp_node_pc_entry_3_0; // @ idma_inoc_regfile.scala l183
        end
        if(tmp_4[1]) begin
          node_pc_entry_3_1 <= tmp_node_pc_entry_3_0; // @ idma_inoc_regfile.scala l183
        end
        if(tmp_4[2]) begin
          node_pc_entry_3_2 <= tmp_node_pc_entry_3_0; // @ idma_inoc_regfile.scala l183
        end
        if(tmp_4[3]) begin
          node_pc_entry_3_3 <= tmp_node_pc_entry_3_0; // @ idma_inoc_regfile.scala l183
        end
        node_pc_valid[3] <= 1'b1; // @ idma_inoc_regfile.scala l184
      end
      if(node_pc_end[4]) begin
        node_pc_cnt_is_counting[4] <= 1'b0; // @ idma_inoc_regfile.scala l128
      end else begin
        if(node_pc_start[4]) begin
          node_pc_cnt_is_counting[4] <= 1'b1; // @ idma_inoc_regfile.scala l130
        end
      end
      if(node_pc_end[4]) begin
        node_pc_cnt_4 <= 5'h0; // @ idma_inoc_regfile.scala l134
      end else begin
        if(node_pc_cnt_is_counting[4]) begin
          node_pc_cnt_4 <= (node_pc_cnt_4 + 5'h01); // @ idma_inoc_regfile.scala l136
        end
      end
      if(node_pc_cnt_is_counting[4]) begin
        node_pc_lock_4[node_pc_cnt_4] <= io_nodes_pc_serial[4]; // @ idma_inoc_regfile.scala l140
      end
      if(read_hit_0x0044) begin
        node_pc_read_addr_0 <= (node_pc_read_addr_0 + 2'b01); // @ idma_inoc_regfile.scala l145
      end
      if(read_hit_0x0048) begin
        node_pc_read_addr_1 <= (node_pc_read_addr_1 + 2'b01); // @ idma_inoc_regfile.scala l148
      end
      if(read_hit_0x004c) begin
        node_pc_read_addr_2 <= (node_pc_read_addr_2 + 2'b01); // @ idma_inoc_regfile.scala l151
      end
      if(read_hit_0x0050) begin
        node_pc_read_addr_3 <= (node_pc_read_addr_3 + 2'b01); // @ idma_inoc_regfile.scala l154
      end
      if(read_hit_0x0054) begin
        node_pc_read_addr_4 <= (node_pc_read_addr_4 + 2'b01); // @ idma_inoc_regfile.scala l157
      end
      if(read_hit_0x0058) begin
        node_pc_read_addr_5 <= (node_pc_read_addr_5 + 2'b01); // @ idma_inoc_regfile.scala l160
      end
      if(read_hit_0x005c) begin
        node_pc_read_addr_6 <= (node_pc_read_addr_6 + 2'b01); // @ idma_inoc_regfile.scala l163
      end
      if(read_hit_0x0060) begin
        node_pc_read_addr_7 <= (node_pc_read_addr_7 + 2'b01); // @ idma_inoc_regfile.scala l166
      end
      if(read_hit_0x0064) begin
        node_pc_read_addr_8 <= (node_pc_read_addr_8 + 2'b01); // @ idma_inoc_regfile.scala l169
      end
      if(read_hit_0x0068) begin
        node_pc_read_addr_9 <= (node_pc_read_addr_9 + 2'b01); // @ idma_inoc_regfile.scala l172
      end
      if(read_hit_0x006c) begin
        node_pc_read_addr_10 <= (node_pc_read_addr_10 + 2'b01); // @ idma_inoc_regfile.scala l175
      end
      if(read_hit_0x0070) begin
        node_pc_read_addr_11 <= (node_pc_read_addr_11 + 2'b01); // @ idma_inoc_regfile.scala l178
      end
      if(node_pc_end[4]) begin
        node_pc_write_addr_4 <= (node_pc_write_addr_4 + 2'b01); // @ idma_inoc_regfile.scala l182
        if(tmp_5[0]) begin
          node_pc_entry_4_0 <= tmp_node_pc_entry_4_0; // @ idma_inoc_regfile.scala l183
        end
        if(tmp_5[1]) begin
          node_pc_entry_4_1 <= tmp_node_pc_entry_4_0; // @ idma_inoc_regfile.scala l183
        end
        if(tmp_5[2]) begin
          node_pc_entry_4_2 <= tmp_node_pc_entry_4_0; // @ idma_inoc_regfile.scala l183
        end
        if(tmp_5[3]) begin
          node_pc_entry_4_3 <= tmp_node_pc_entry_4_0; // @ idma_inoc_regfile.scala l183
        end
        node_pc_valid[4] <= 1'b1; // @ idma_inoc_regfile.scala l184
      end
      if(node_pc_end[5]) begin
        node_pc_cnt_is_counting[5] <= 1'b0; // @ idma_inoc_regfile.scala l128
      end else begin
        if(node_pc_start[5]) begin
          node_pc_cnt_is_counting[5] <= 1'b1; // @ idma_inoc_regfile.scala l130
        end
      end
      if(node_pc_end[5]) begin
        node_pc_cnt_5 <= 5'h0; // @ idma_inoc_regfile.scala l134
      end else begin
        if(node_pc_cnt_is_counting[5]) begin
          node_pc_cnt_5 <= (node_pc_cnt_5 + 5'h01); // @ idma_inoc_regfile.scala l136
        end
      end
      if(node_pc_cnt_is_counting[5]) begin
        node_pc_lock_5[node_pc_cnt_5] <= io_nodes_pc_serial[5]; // @ idma_inoc_regfile.scala l140
      end
      if(read_hit_0x0044) begin
        node_pc_read_addr_0 <= (node_pc_read_addr_0 + 2'b01); // @ idma_inoc_regfile.scala l145
      end
      if(read_hit_0x0048) begin
        node_pc_read_addr_1 <= (node_pc_read_addr_1 + 2'b01); // @ idma_inoc_regfile.scala l148
      end
      if(read_hit_0x004c) begin
        node_pc_read_addr_2 <= (node_pc_read_addr_2 + 2'b01); // @ idma_inoc_regfile.scala l151
      end
      if(read_hit_0x0050) begin
        node_pc_read_addr_3 <= (node_pc_read_addr_3 + 2'b01); // @ idma_inoc_regfile.scala l154
      end
      if(read_hit_0x0054) begin
        node_pc_read_addr_4 <= (node_pc_read_addr_4 + 2'b01); // @ idma_inoc_regfile.scala l157
      end
      if(read_hit_0x0058) begin
        node_pc_read_addr_5 <= (node_pc_read_addr_5 + 2'b01); // @ idma_inoc_regfile.scala l160
      end
      if(read_hit_0x005c) begin
        node_pc_read_addr_6 <= (node_pc_read_addr_6 + 2'b01); // @ idma_inoc_regfile.scala l163
      end
      if(read_hit_0x0060) begin
        node_pc_read_addr_7 <= (node_pc_read_addr_7 + 2'b01); // @ idma_inoc_regfile.scala l166
      end
      if(read_hit_0x0064) begin
        node_pc_read_addr_8 <= (node_pc_read_addr_8 + 2'b01); // @ idma_inoc_regfile.scala l169
      end
      if(read_hit_0x0068) begin
        node_pc_read_addr_9 <= (node_pc_read_addr_9 + 2'b01); // @ idma_inoc_regfile.scala l172
      end
      if(read_hit_0x006c) begin
        node_pc_read_addr_10 <= (node_pc_read_addr_10 + 2'b01); // @ idma_inoc_regfile.scala l175
      end
      if(read_hit_0x0070) begin
        node_pc_read_addr_11 <= (node_pc_read_addr_11 + 2'b01); // @ idma_inoc_regfile.scala l178
      end
      if(node_pc_end[5]) begin
        node_pc_write_addr_5 <= (node_pc_write_addr_5 + 2'b01); // @ idma_inoc_regfile.scala l182
        if(tmp_6[0]) begin
          node_pc_entry_5_0 <= tmp_node_pc_entry_5_0; // @ idma_inoc_regfile.scala l183
        end
        if(tmp_6[1]) begin
          node_pc_entry_5_1 <= tmp_node_pc_entry_5_0; // @ idma_inoc_regfile.scala l183
        end
        if(tmp_6[2]) begin
          node_pc_entry_5_2 <= tmp_node_pc_entry_5_0; // @ idma_inoc_regfile.scala l183
        end
        if(tmp_6[3]) begin
          node_pc_entry_5_3 <= tmp_node_pc_entry_5_0; // @ idma_inoc_regfile.scala l183
        end
        node_pc_valid[5] <= 1'b1; // @ idma_inoc_regfile.scala l184
      end
      if(node_pc_end[6]) begin
        node_pc_cnt_is_counting[6] <= 1'b0; // @ idma_inoc_regfile.scala l128
      end else begin
        if(node_pc_start[6]) begin
          node_pc_cnt_is_counting[6] <= 1'b1; // @ idma_inoc_regfile.scala l130
        end
      end
      if(node_pc_end[6]) begin
        node_pc_cnt_6 <= 5'h0; // @ idma_inoc_regfile.scala l134
      end else begin
        if(node_pc_cnt_is_counting[6]) begin
          node_pc_cnt_6 <= (node_pc_cnt_6 + 5'h01); // @ idma_inoc_regfile.scala l136
        end
      end
      if(node_pc_cnt_is_counting[6]) begin
        node_pc_lock_6[node_pc_cnt_6] <= io_nodes_pc_serial[6]; // @ idma_inoc_regfile.scala l140
      end
      if(read_hit_0x0044) begin
        node_pc_read_addr_0 <= (node_pc_read_addr_0 + 2'b01); // @ idma_inoc_regfile.scala l145
      end
      if(read_hit_0x0048) begin
        node_pc_read_addr_1 <= (node_pc_read_addr_1 + 2'b01); // @ idma_inoc_regfile.scala l148
      end
      if(read_hit_0x004c) begin
        node_pc_read_addr_2 <= (node_pc_read_addr_2 + 2'b01); // @ idma_inoc_regfile.scala l151
      end
      if(read_hit_0x0050) begin
        node_pc_read_addr_3 <= (node_pc_read_addr_3 + 2'b01); // @ idma_inoc_regfile.scala l154
      end
      if(read_hit_0x0054) begin
        node_pc_read_addr_4 <= (node_pc_read_addr_4 + 2'b01); // @ idma_inoc_regfile.scala l157
      end
      if(read_hit_0x0058) begin
        node_pc_read_addr_5 <= (node_pc_read_addr_5 + 2'b01); // @ idma_inoc_regfile.scala l160
      end
      if(read_hit_0x005c) begin
        node_pc_read_addr_6 <= (node_pc_read_addr_6 + 2'b01); // @ idma_inoc_regfile.scala l163
      end
      if(read_hit_0x0060) begin
        node_pc_read_addr_7 <= (node_pc_read_addr_7 + 2'b01); // @ idma_inoc_regfile.scala l166
      end
      if(read_hit_0x0064) begin
        node_pc_read_addr_8 <= (node_pc_read_addr_8 + 2'b01); // @ idma_inoc_regfile.scala l169
      end
      if(read_hit_0x0068) begin
        node_pc_read_addr_9 <= (node_pc_read_addr_9 + 2'b01); // @ idma_inoc_regfile.scala l172
      end
      if(read_hit_0x006c) begin
        node_pc_read_addr_10 <= (node_pc_read_addr_10 + 2'b01); // @ idma_inoc_regfile.scala l175
      end
      if(read_hit_0x0070) begin
        node_pc_read_addr_11 <= (node_pc_read_addr_11 + 2'b01); // @ idma_inoc_regfile.scala l178
      end
      if(node_pc_end[6]) begin
        node_pc_write_addr_6 <= (node_pc_write_addr_6 + 2'b01); // @ idma_inoc_regfile.scala l182
        if(tmp_7[0]) begin
          node_pc_entry_6_0 <= tmp_node_pc_entry_6_0; // @ idma_inoc_regfile.scala l183
        end
        if(tmp_7[1]) begin
          node_pc_entry_6_1 <= tmp_node_pc_entry_6_0; // @ idma_inoc_regfile.scala l183
        end
        if(tmp_7[2]) begin
          node_pc_entry_6_2 <= tmp_node_pc_entry_6_0; // @ idma_inoc_regfile.scala l183
        end
        if(tmp_7[3]) begin
          node_pc_entry_6_3 <= tmp_node_pc_entry_6_0; // @ idma_inoc_regfile.scala l183
        end
        node_pc_valid[6] <= 1'b1; // @ idma_inoc_regfile.scala l184
      end
      if(node_pc_end[7]) begin
        node_pc_cnt_is_counting[7] <= 1'b0; // @ idma_inoc_regfile.scala l128
      end else begin
        if(node_pc_start[7]) begin
          node_pc_cnt_is_counting[7] <= 1'b1; // @ idma_inoc_regfile.scala l130
        end
      end
      if(node_pc_end[7]) begin
        node_pc_cnt_7 <= 5'h0; // @ idma_inoc_regfile.scala l134
      end else begin
        if(node_pc_cnt_is_counting[7]) begin
          node_pc_cnt_7 <= (node_pc_cnt_7 + 5'h01); // @ idma_inoc_regfile.scala l136
        end
      end
      if(node_pc_cnt_is_counting[7]) begin
        node_pc_lock_7[node_pc_cnt_7] <= io_nodes_pc_serial[7]; // @ idma_inoc_regfile.scala l140
      end
      if(read_hit_0x0044) begin
        node_pc_read_addr_0 <= (node_pc_read_addr_0 + 2'b01); // @ idma_inoc_regfile.scala l145
      end
      if(read_hit_0x0048) begin
        node_pc_read_addr_1 <= (node_pc_read_addr_1 + 2'b01); // @ idma_inoc_regfile.scala l148
      end
      if(read_hit_0x004c) begin
        node_pc_read_addr_2 <= (node_pc_read_addr_2 + 2'b01); // @ idma_inoc_regfile.scala l151
      end
      if(read_hit_0x0050) begin
        node_pc_read_addr_3 <= (node_pc_read_addr_3 + 2'b01); // @ idma_inoc_regfile.scala l154
      end
      if(read_hit_0x0054) begin
        node_pc_read_addr_4 <= (node_pc_read_addr_4 + 2'b01); // @ idma_inoc_regfile.scala l157
      end
      if(read_hit_0x0058) begin
        node_pc_read_addr_5 <= (node_pc_read_addr_5 + 2'b01); // @ idma_inoc_regfile.scala l160
      end
      if(read_hit_0x005c) begin
        node_pc_read_addr_6 <= (node_pc_read_addr_6 + 2'b01); // @ idma_inoc_regfile.scala l163
      end
      if(read_hit_0x0060) begin
        node_pc_read_addr_7 <= (node_pc_read_addr_7 + 2'b01); // @ idma_inoc_regfile.scala l166
      end
      if(read_hit_0x0064) begin
        node_pc_read_addr_8 <= (node_pc_read_addr_8 + 2'b01); // @ idma_inoc_regfile.scala l169
      end
      if(read_hit_0x0068) begin
        node_pc_read_addr_9 <= (node_pc_read_addr_9 + 2'b01); // @ idma_inoc_regfile.scala l172
      end
      if(read_hit_0x006c) begin
        node_pc_read_addr_10 <= (node_pc_read_addr_10 + 2'b01); // @ idma_inoc_regfile.scala l175
      end
      if(read_hit_0x0070) begin
        node_pc_read_addr_11 <= (node_pc_read_addr_11 + 2'b01); // @ idma_inoc_regfile.scala l178
      end
      if(node_pc_end[7]) begin
        node_pc_write_addr_7 <= (node_pc_write_addr_7 + 2'b01); // @ idma_inoc_regfile.scala l182
        if(tmp_8[0]) begin
          node_pc_entry_7_0 <= tmp_node_pc_entry_7_0; // @ idma_inoc_regfile.scala l183
        end
        if(tmp_8[1]) begin
          node_pc_entry_7_1 <= tmp_node_pc_entry_7_0; // @ idma_inoc_regfile.scala l183
        end
        if(tmp_8[2]) begin
          node_pc_entry_7_2 <= tmp_node_pc_entry_7_0; // @ idma_inoc_regfile.scala l183
        end
        if(tmp_8[3]) begin
          node_pc_entry_7_3 <= tmp_node_pc_entry_7_0; // @ idma_inoc_regfile.scala l183
        end
        node_pc_valid[7] <= 1'b1; // @ idma_inoc_regfile.scala l184
      end
      if(node_pc_end[8]) begin
        node_pc_cnt_is_counting[8] <= 1'b0; // @ idma_inoc_regfile.scala l128
      end else begin
        if(node_pc_start[8]) begin
          node_pc_cnt_is_counting[8] <= 1'b1; // @ idma_inoc_regfile.scala l130
        end
      end
      if(node_pc_end[8]) begin
        node_pc_cnt_8 <= 5'h0; // @ idma_inoc_regfile.scala l134
      end else begin
        if(node_pc_cnt_is_counting[8]) begin
          node_pc_cnt_8 <= (node_pc_cnt_8 + 5'h01); // @ idma_inoc_regfile.scala l136
        end
      end
      if(node_pc_cnt_is_counting[8]) begin
        node_pc_lock_8[node_pc_cnt_8] <= io_nodes_pc_serial[8]; // @ idma_inoc_regfile.scala l140
      end
      if(read_hit_0x0044) begin
        node_pc_read_addr_0 <= (node_pc_read_addr_0 + 2'b01); // @ idma_inoc_regfile.scala l145
      end
      if(read_hit_0x0048) begin
        node_pc_read_addr_1 <= (node_pc_read_addr_1 + 2'b01); // @ idma_inoc_regfile.scala l148
      end
      if(read_hit_0x004c) begin
        node_pc_read_addr_2 <= (node_pc_read_addr_2 + 2'b01); // @ idma_inoc_regfile.scala l151
      end
      if(read_hit_0x0050) begin
        node_pc_read_addr_3 <= (node_pc_read_addr_3 + 2'b01); // @ idma_inoc_regfile.scala l154
      end
      if(read_hit_0x0054) begin
        node_pc_read_addr_4 <= (node_pc_read_addr_4 + 2'b01); // @ idma_inoc_regfile.scala l157
      end
      if(read_hit_0x0058) begin
        node_pc_read_addr_5 <= (node_pc_read_addr_5 + 2'b01); // @ idma_inoc_regfile.scala l160
      end
      if(read_hit_0x005c) begin
        node_pc_read_addr_6 <= (node_pc_read_addr_6 + 2'b01); // @ idma_inoc_regfile.scala l163
      end
      if(read_hit_0x0060) begin
        node_pc_read_addr_7 <= (node_pc_read_addr_7 + 2'b01); // @ idma_inoc_regfile.scala l166
      end
      if(read_hit_0x0064) begin
        node_pc_read_addr_8 <= (node_pc_read_addr_8 + 2'b01); // @ idma_inoc_regfile.scala l169
      end
      if(read_hit_0x0068) begin
        node_pc_read_addr_9 <= (node_pc_read_addr_9 + 2'b01); // @ idma_inoc_regfile.scala l172
      end
      if(read_hit_0x006c) begin
        node_pc_read_addr_10 <= (node_pc_read_addr_10 + 2'b01); // @ idma_inoc_regfile.scala l175
      end
      if(read_hit_0x0070) begin
        node_pc_read_addr_11 <= (node_pc_read_addr_11 + 2'b01); // @ idma_inoc_regfile.scala l178
      end
      if(node_pc_end[8]) begin
        node_pc_write_addr_8 <= (node_pc_write_addr_8 + 2'b01); // @ idma_inoc_regfile.scala l182
        if(tmp_9[0]) begin
          node_pc_entry_8_0 <= tmp_node_pc_entry_8_0; // @ idma_inoc_regfile.scala l183
        end
        if(tmp_9[1]) begin
          node_pc_entry_8_1 <= tmp_node_pc_entry_8_0; // @ idma_inoc_regfile.scala l183
        end
        if(tmp_9[2]) begin
          node_pc_entry_8_2 <= tmp_node_pc_entry_8_0; // @ idma_inoc_regfile.scala l183
        end
        if(tmp_9[3]) begin
          node_pc_entry_8_3 <= tmp_node_pc_entry_8_0; // @ idma_inoc_regfile.scala l183
        end
        node_pc_valid[8] <= 1'b1; // @ idma_inoc_regfile.scala l184
      end
      if(node_pc_end[9]) begin
        node_pc_cnt_is_counting[9] <= 1'b0; // @ idma_inoc_regfile.scala l128
      end else begin
        if(node_pc_start[9]) begin
          node_pc_cnt_is_counting[9] <= 1'b1; // @ idma_inoc_regfile.scala l130
        end
      end
      if(node_pc_end[9]) begin
        node_pc_cnt_9 <= 5'h0; // @ idma_inoc_regfile.scala l134
      end else begin
        if(node_pc_cnt_is_counting[9]) begin
          node_pc_cnt_9 <= (node_pc_cnt_9 + 5'h01); // @ idma_inoc_regfile.scala l136
        end
      end
      if(node_pc_cnt_is_counting[9]) begin
        node_pc_lock_9[node_pc_cnt_9] <= io_nodes_pc_serial[9]; // @ idma_inoc_regfile.scala l140
      end
      if(read_hit_0x0044) begin
        node_pc_read_addr_0 <= (node_pc_read_addr_0 + 2'b01); // @ idma_inoc_regfile.scala l145
      end
      if(read_hit_0x0048) begin
        node_pc_read_addr_1 <= (node_pc_read_addr_1 + 2'b01); // @ idma_inoc_regfile.scala l148
      end
      if(read_hit_0x004c) begin
        node_pc_read_addr_2 <= (node_pc_read_addr_2 + 2'b01); // @ idma_inoc_regfile.scala l151
      end
      if(read_hit_0x0050) begin
        node_pc_read_addr_3 <= (node_pc_read_addr_3 + 2'b01); // @ idma_inoc_regfile.scala l154
      end
      if(read_hit_0x0054) begin
        node_pc_read_addr_4 <= (node_pc_read_addr_4 + 2'b01); // @ idma_inoc_regfile.scala l157
      end
      if(read_hit_0x0058) begin
        node_pc_read_addr_5 <= (node_pc_read_addr_5 + 2'b01); // @ idma_inoc_regfile.scala l160
      end
      if(read_hit_0x005c) begin
        node_pc_read_addr_6 <= (node_pc_read_addr_6 + 2'b01); // @ idma_inoc_regfile.scala l163
      end
      if(read_hit_0x0060) begin
        node_pc_read_addr_7 <= (node_pc_read_addr_7 + 2'b01); // @ idma_inoc_regfile.scala l166
      end
      if(read_hit_0x0064) begin
        node_pc_read_addr_8 <= (node_pc_read_addr_8 + 2'b01); // @ idma_inoc_regfile.scala l169
      end
      if(read_hit_0x0068) begin
        node_pc_read_addr_9 <= (node_pc_read_addr_9 + 2'b01); // @ idma_inoc_regfile.scala l172
      end
      if(read_hit_0x006c) begin
        node_pc_read_addr_10 <= (node_pc_read_addr_10 + 2'b01); // @ idma_inoc_regfile.scala l175
      end
      if(read_hit_0x0070) begin
        node_pc_read_addr_11 <= (node_pc_read_addr_11 + 2'b01); // @ idma_inoc_regfile.scala l178
      end
      if(node_pc_end[9]) begin
        node_pc_write_addr_9 <= (node_pc_write_addr_9 + 2'b01); // @ idma_inoc_regfile.scala l182
        if(tmp_10[0]) begin
          node_pc_entry_9_0 <= tmp_node_pc_entry_9_0; // @ idma_inoc_regfile.scala l183
        end
        if(tmp_10[1]) begin
          node_pc_entry_9_1 <= tmp_node_pc_entry_9_0; // @ idma_inoc_regfile.scala l183
        end
        if(tmp_10[2]) begin
          node_pc_entry_9_2 <= tmp_node_pc_entry_9_0; // @ idma_inoc_regfile.scala l183
        end
        if(tmp_10[3]) begin
          node_pc_entry_9_3 <= tmp_node_pc_entry_9_0; // @ idma_inoc_regfile.scala l183
        end
        node_pc_valid[9] <= 1'b1; // @ idma_inoc_regfile.scala l184
      end
      if(node_pc_end[10]) begin
        node_pc_cnt_is_counting[10] <= 1'b0; // @ idma_inoc_regfile.scala l128
      end else begin
        if(node_pc_start[10]) begin
          node_pc_cnt_is_counting[10] <= 1'b1; // @ idma_inoc_regfile.scala l130
        end
      end
      if(node_pc_end[10]) begin
        node_pc_cnt_10 <= 5'h0; // @ idma_inoc_regfile.scala l134
      end else begin
        if(node_pc_cnt_is_counting[10]) begin
          node_pc_cnt_10 <= (node_pc_cnt_10 + 5'h01); // @ idma_inoc_regfile.scala l136
        end
      end
      if(node_pc_cnt_is_counting[10]) begin
        node_pc_lock_10[node_pc_cnt_10] <= io_nodes_pc_serial[10]; // @ idma_inoc_regfile.scala l140
      end
      if(read_hit_0x0044) begin
        node_pc_read_addr_0 <= (node_pc_read_addr_0 + 2'b01); // @ idma_inoc_regfile.scala l145
      end
      if(read_hit_0x0048) begin
        node_pc_read_addr_1 <= (node_pc_read_addr_1 + 2'b01); // @ idma_inoc_regfile.scala l148
      end
      if(read_hit_0x004c) begin
        node_pc_read_addr_2 <= (node_pc_read_addr_2 + 2'b01); // @ idma_inoc_regfile.scala l151
      end
      if(read_hit_0x0050) begin
        node_pc_read_addr_3 <= (node_pc_read_addr_3 + 2'b01); // @ idma_inoc_regfile.scala l154
      end
      if(read_hit_0x0054) begin
        node_pc_read_addr_4 <= (node_pc_read_addr_4 + 2'b01); // @ idma_inoc_regfile.scala l157
      end
      if(read_hit_0x0058) begin
        node_pc_read_addr_5 <= (node_pc_read_addr_5 + 2'b01); // @ idma_inoc_regfile.scala l160
      end
      if(read_hit_0x005c) begin
        node_pc_read_addr_6 <= (node_pc_read_addr_6 + 2'b01); // @ idma_inoc_regfile.scala l163
      end
      if(read_hit_0x0060) begin
        node_pc_read_addr_7 <= (node_pc_read_addr_7 + 2'b01); // @ idma_inoc_regfile.scala l166
      end
      if(read_hit_0x0064) begin
        node_pc_read_addr_8 <= (node_pc_read_addr_8 + 2'b01); // @ idma_inoc_regfile.scala l169
      end
      if(read_hit_0x0068) begin
        node_pc_read_addr_9 <= (node_pc_read_addr_9 + 2'b01); // @ idma_inoc_regfile.scala l172
      end
      if(read_hit_0x006c) begin
        node_pc_read_addr_10 <= (node_pc_read_addr_10 + 2'b01); // @ idma_inoc_regfile.scala l175
      end
      if(read_hit_0x0070) begin
        node_pc_read_addr_11 <= (node_pc_read_addr_11 + 2'b01); // @ idma_inoc_regfile.scala l178
      end
      if(node_pc_end[10]) begin
        node_pc_write_addr_10 <= (node_pc_write_addr_10 + 2'b01); // @ idma_inoc_regfile.scala l182
        if(tmp_11[0]) begin
          node_pc_entry_10_0 <= tmp_node_pc_entry_10_0; // @ idma_inoc_regfile.scala l183
        end
        if(tmp_11[1]) begin
          node_pc_entry_10_1 <= tmp_node_pc_entry_10_0; // @ idma_inoc_regfile.scala l183
        end
        if(tmp_11[2]) begin
          node_pc_entry_10_2 <= tmp_node_pc_entry_10_0; // @ idma_inoc_regfile.scala l183
        end
        if(tmp_11[3]) begin
          node_pc_entry_10_3 <= tmp_node_pc_entry_10_0; // @ idma_inoc_regfile.scala l183
        end
        node_pc_valid[10] <= 1'b1; // @ idma_inoc_regfile.scala l184
      end
      if(node_pc_end[11]) begin
        node_pc_cnt_is_counting[11] <= 1'b0; // @ idma_inoc_regfile.scala l128
      end else begin
        if(node_pc_start[11]) begin
          node_pc_cnt_is_counting[11] <= 1'b1; // @ idma_inoc_regfile.scala l130
        end
      end
      if(node_pc_end[11]) begin
        node_pc_cnt_11 <= 5'h0; // @ idma_inoc_regfile.scala l134
      end else begin
        if(node_pc_cnt_is_counting[11]) begin
          node_pc_cnt_11 <= (node_pc_cnt_11 + 5'h01); // @ idma_inoc_regfile.scala l136
        end
      end
      if(node_pc_cnt_is_counting[11]) begin
        node_pc_lock_11[node_pc_cnt_11] <= io_nodes_pc_serial[11]; // @ idma_inoc_regfile.scala l140
      end
      if(read_hit_0x0044) begin
        node_pc_read_addr_0 <= (node_pc_read_addr_0 + 2'b01); // @ idma_inoc_regfile.scala l145
      end
      if(read_hit_0x0048) begin
        node_pc_read_addr_1 <= (node_pc_read_addr_1 + 2'b01); // @ idma_inoc_regfile.scala l148
      end
      if(read_hit_0x004c) begin
        node_pc_read_addr_2 <= (node_pc_read_addr_2 + 2'b01); // @ idma_inoc_regfile.scala l151
      end
      if(read_hit_0x0050) begin
        node_pc_read_addr_3 <= (node_pc_read_addr_3 + 2'b01); // @ idma_inoc_regfile.scala l154
      end
      if(read_hit_0x0054) begin
        node_pc_read_addr_4 <= (node_pc_read_addr_4 + 2'b01); // @ idma_inoc_regfile.scala l157
      end
      if(read_hit_0x0058) begin
        node_pc_read_addr_5 <= (node_pc_read_addr_5 + 2'b01); // @ idma_inoc_regfile.scala l160
      end
      if(read_hit_0x005c) begin
        node_pc_read_addr_6 <= (node_pc_read_addr_6 + 2'b01); // @ idma_inoc_regfile.scala l163
      end
      if(read_hit_0x0060) begin
        node_pc_read_addr_7 <= (node_pc_read_addr_7 + 2'b01); // @ idma_inoc_regfile.scala l166
      end
      if(read_hit_0x0064) begin
        node_pc_read_addr_8 <= (node_pc_read_addr_8 + 2'b01); // @ idma_inoc_regfile.scala l169
      end
      if(read_hit_0x0068) begin
        node_pc_read_addr_9 <= (node_pc_read_addr_9 + 2'b01); // @ idma_inoc_regfile.scala l172
      end
      if(read_hit_0x006c) begin
        node_pc_read_addr_10 <= (node_pc_read_addr_10 + 2'b01); // @ idma_inoc_regfile.scala l175
      end
      if(read_hit_0x0070) begin
        node_pc_read_addr_11 <= (node_pc_read_addr_11 + 2'b01); // @ idma_inoc_regfile.scala l178
      end
      if(node_pc_end[11]) begin
        node_pc_write_addr_11 <= (node_pc_write_addr_11 + 2'b01); // @ idma_inoc_regfile.scala l182
        if(tmp_12[0]) begin
          node_pc_entry_11_0 <= tmp_node_pc_entry_11_0; // @ idma_inoc_regfile.scala l183
        end
        if(tmp_12[1]) begin
          node_pc_entry_11_1 <= tmp_node_pc_entry_11_0; // @ idma_inoc_regfile.scala l183
        end
        if(tmp_12[2]) begin
          node_pc_entry_11_2 <= tmp_node_pc_entry_11_0; // @ idma_inoc_regfile.scala l183
        end
        if(tmp_12[3]) begin
          node_pc_entry_11_3 <= tmp_node_pc_entry_11_0; // @ idma_inoc_regfile.scala l183
        end
        node_pc_valid[11] <= 1'b1; // @ idma_inoc_regfile.scala l184
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
        case(tmp_13)
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
          12'h044 : begin
            busif_readData <= node_pc_0; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h048 : begin
            busif_readData <= node_pc_1; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h04c : begin
            busif_readData <= node_pc_2; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h050 : begin
            busif_readData <= node_pc_3; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h054 : begin
            busif_readData <= node_pc_4; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h058 : begin
            busif_readData <= node_pc_5; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h05c : begin
            busif_readData <= node_pc_6; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h060 : begin
            busif_readData <= node_pc_7; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h064 : begin
            busif_readData <= node_pc_8; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h068 : begin
            busif_readData <= node_pc_9; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h06c : begin
            busif_readData <= node_pc_10; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h070 : begin
            busif_readData <= node_pc_11; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h074 : begin
            busif_readData <= {20'h0,{node_pc_valid_11,{node_pc_valid_10,{node_pc_valid_9,{node_pc_valid_8,{node_pc_valid_7,{node_pc_valid_6,{node_pc_valid_5,{node_pc_valid_4,{node_pc_valid_3,{tmp_busif_readData,tmp_busif_readData_1}}}}}}}}}}}; // @ BusIfBase.scala l357
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
