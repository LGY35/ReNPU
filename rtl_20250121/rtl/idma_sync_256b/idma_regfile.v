// Generator : SpinalHDL v1.8.1    git head : 2a7592004363e5b40ec43e1f122ed8641cd8965b
// Component : idma_regfile
// Git hash  : edca641f0aace8a22429fe3d11598e4de191c343

`timescale 1ns/1ps

module idma_regfile (
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
  output              io_wr_cfg_ready,
  output              io_wr_afifo_init,
  output              io_wr_dfifo_init,
  output     [3:0]    io_wr_cfg_outstd,
  output              io_wr_cfg_outstd_en,
  output              io_wr_cfg_cross4k_en,
  output              io_wr_cfg_arvld_hold_en,
  output              io_wr_cfg_arvld_hold_olen_en,
  output     [6:0]    io_wr_cfg_dfifo_thd,
  output              io_wr_cfg_strb_force,
  input               io_rd_done_intr,
  input               io_wr_done_intr,
  input      [15:0]   io_debug_dma_rd_in_cnt,
  input      [15:0]   io_debug_dma_wr_out_cnt,
  output     [31:0]   io_base_addr_0,
  output     [31:0]   io_base_addr_1,
  output     [31:0]   io_base_addr_2,
  output     [31:0]   io_base_addr_3,
  output     [31:0]   io_base_addr_4,
  output     [31:0]   io_base_addr_5,
  output     [31:0]   io_base_addr_6,
  output     [31:0]   io_base_addr_7,
  output     [31:0]   io_base_addr_8,
  output     [31:0]   io_base_addr_9,
  output     [31:0]   io_base_addr_10,
  output     [31:0]   io_base_addr_11,
  output              io_intr,
  input               clk,
  input               resetn
);

  wire       [0:0]    tmp_rd_cfg_en;
  wire       [0:0]    tmp_rd_cfg_outstd_en;
  wire       [0:0]    tmp_rd_cfg_cross4k_en;
  wire       [0:0]    tmp_rd_cfg_arvld_hold_en;
  wire       [0:0]    tmp_rd_cfg_resi_mode;
  wire       [0:0]    tmp_wr_cfg_en;
  wire       [0:0]    tmp_wr_cfg_outstd_en;
  wire       [0:0]    tmp_wr_cfg_cross4k_en;
  wire       [0:0]    tmp_wr_cfg_arvld_hold_en;
  wire       [0:0]    tmp_wr_cfg_arvld_hold_olen_en;
  wire       [0:0]    tmp_wr_cfg_strb_force;
  wire       [0:0]    tmp_wr_done_intr_mask;
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
  wire                read_hit_0x0038;
  wire                write_hit_0x0038;
  wire                read_hit_0x003c;
  wire                write_hit_0x003c;
  wire                read_hit_0x0040;
  wire                write_hit_0x0040;
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
  reg                 wr_cfg_en;
  reg                 wr_afifo_init;
  reg                 wr_dfifo_init;
  wire       [14:0]   reserved_1;
  reg        [7:0]    wr_cfg_dfifo_thd;
  reg        [3:0]    wr_cfg_outstd;
  reg                 wr_cfg_outstd_en;
  reg                 wr_cfg_cross4k_en;
  reg                 wr_cfg_arvld_hold_en;
  reg                 wr_cfg_arvld_hold_olen_en;
  reg                 wr_cfg_strb_force;
  wire       [15:0]   debug_dma_rd_in_cnt;
  wire       [15:0]   debug_dma_wr_out_cnt;
  reg        [31:0]   base_addr_0;
  reg        [31:0]   base_addr_1;
  reg        [31:0]   base_addr_2;
  reg        [31:0]   base_addr_3;
  reg        [31:0]   base_addr_4;
  reg        [31:0]   base_addr_5;
  reg        [31:0]   base_addr_6;
  reg        [31:0]   base_addr_7;
  reg        [31:0]   base_addr_8;
  reg        [31:0]   base_addr_9;
  reg        [31:0]   base_addr_10;
  reg        [31:0]   base_addr_11;
  wire                read_hit_0x0068;
  wire                write_hit_0x0068;
  wire                read_hit_0x006c;
  wire                write_hit_0x006c;
  wire                read_hit_0x0070;
  wire                write_hit_0x0070;
  reg                 wr_done_intr_raw;
  reg                 wr_done_intr_mask;
  wire                wr_done_intr_status;
  reg                 rd_done_intr_raw;
  reg                 rd_done_intr_mask;
  wire                rd_done_intr_status;
  wire                INTR_intr;

  assign tmp_1 = {io_apb_PADDR[11 : 2],2'b00};
  assign tmp_rd_cfg_en = ((rd_cfg_en & busif_wmaskn[0 : 0]) | (io_apb_PWDATA[0 : 0] & busif_wmask[0 : 0]));
  assign tmp_rd_cfg_outstd_en = ((rd_cfg_outstd_en & busif_wmaskn[4 : 4]) | (io_apb_PWDATA[4 : 4] & busif_wmask[4 : 4]));
  assign tmp_rd_cfg_cross4k_en = ((rd_cfg_cross4k_en & busif_wmaskn[5 : 5]) | (io_apb_PWDATA[5 : 5] & busif_wmask[5 : 5]));
  assign tmp_rd_cfg_arvld_hold_en = ((rd_cfg_arvld_hold_en & busif_wmaskn[6 : 6]) | (io_apb_PWDATA[6 : 6] & busif_wmask[6 : 6]));
  assign tmp_rd_cfg_resi_mode = ((rd_cfg_resi_mode & busif_wmaskn[7 : 7]) | (io_apb_PWDATA[7 : 7] & busif_wmask[7 : 7]));
  assign tmp_wr_cfg_en = ((wr_cfg_en & busif_wmaskn[0 : 0]) | (io_apb_PWDATA[0 : 0] & busif_wmask[0 : 0]));
  assign tmp_wr_cfg_outstd_en = ((wr_cfg_outstd_en & busif_wmaskn[4 : 4]) | (io_apb_PWDATA[4 : 4] & busif_wmask[4 : 4]));
  assign tmp_wr_cfg_cross4k_en = ((wr_cfg_cross4k_en & busif_wmaskn[5 : 5]) | (io_apb_PWDATA[5 : 5] & busif_wmask[5 : 5]));
  assign tmp_wr_cfg_arvld_hold_en = ((wr_cfg_arvld_hold_en & busif_wmaskn[6 : 6]) | (io_apb_PWDATA[6 : 6] & busif_wmask[6 : 6]));
  assign tmp_wr_cfg_arvld_hold_olen_en = ((wr_cfg_arvld_hold_olen_en & busif_wmaskn[7 : 7]) | (io_apb_PWDATA[7 : 7] & busif_wmask[7 : 7]));
  assign tmp_wr_cfg_strb_force = ((wr_cfg_strb_force & busif_wmaskn[8 : 8]) | (io_apb_PWDATA[8 : 8] & busif_wmask[8 : 8]));
  assign tmp_wr_done_intr_mask = ((wr_done_intr_mask & busif_wmaskn[0 : 0]) | (io_apb_PWDATA[0 : 0] & busif_wmask[0 : 0]));
  assign tmp_rd_done_intr_mask = ((rd_done_intr_mask & busif_wmaskn[1 : 1]) | (io_apb_PWDATA[1 : 1] & busif_wmask[1 : 1]));
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
  assign read_hit_0x0038 = (({io_apb_PADDR[11 : 2],2'b00} == 12'h038) && busif_doRead); // @ BaseType.scala l305
  assign write_hit_0x0038 = ((io_apb_PADDR == 12'h038) && busif_doWrite); // @ BaseType.scala l305
  assign read_hit_0x003c = (({io_apb_PADDR[11 : 2],2'b00} == 12'h03c) && busif_doRead); // @ BaseType.scala l305
  assign write_hit_0x003c = ((io_apb_PADDR == 12'h03c) && busif_doWrite); // @ BaseType.scala l305
  assign read_hit_0x0040 = (({io_apb_PADDR[11 : 2],2'b00} == 12'h040) && busif_doRead); // @ BaseType.scala l305
  assign write_hit_0x0040 = ((io_apb_PADDR == 12'h040) && busif_doWrite); // @ BaseType.scala l305
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
  assign reserved = 15'h0; // @ Bits.scala l133
  assign reserved_1 = 15'h0; // @ Bits.scala l133
  assign io_rd_cfg_ready = rd_cfg_en; // @ idma_regfile.scala l134
  assign io_rd_afifo_init = rd_afifo_init; // @ idma_regfile.scala l135
  assign io_rd_dfifo_init = rd_dfifo_init; // @ idma_regfile.scala l136
  assign io_rd_cfg_outstd = rd_cfg_outstd; // @ idma_regfile.scala l137
  assign io_rd_cfg_outstd_en = rd_cfg_outstd_en; // @ idma_regfile.scala l138
  assign io_rd_cfg_cross4k_en = rd_cfg_cross4k_en; // @ idma_regfile.scala l139
  assign io_rd_cfg_arvld_hold_en = rd_cfg_arvld_hold_en; // @ idma_regfile.scala l140
  assign io_rd_cfg_dfifo_thd = rd_cfg_dfifo_thd[6:0]; // @ idma_regfile.scala l141
  assign io_rd_cfg_resi_mode = rd_cfg_resi_mode; // @ idma_regfile.scala l142
  assign io_rd_cfg_resi_fmap_a_addr = rd_cfg_resi_fmap_a_addr; // @ idma_regfile.scala l143
  assign io_rd_cfg_resi_fmap_b_addr = rd_cfg_resi_fmap_b_addr; // @ idma_regfile.scala l144
  assign io_rd_cfg_resi_addr_gap = rd_cfg_resi_addr_gap[15:0]; // @ idma_regfile.scala l145
  assign io_rd_cfg_resi_loop_num = rd_cfg_resi_loop_num[15:0]; // @ idma_regfile.scala l146
  assign io_wr_cfg_ready = wr_cfg_en; // @ idma_regfile.scala l148
  assign io_wr_afifo_init = wr_afifo_init; // @ idma_regfile.scala l149
  assign io_wr_dfifo_init = wr_dfifo_init; // @ idma_regfile.scala l150
  assign io_wr_cfg_outstd = wr_cfg_outstd; // @ idma_regfile.scala l151
  assign io_wr_cfg_outstd_en = wr_cfg_outstd_en; // @ idma_regfile.scala l152
  assign io_wr_cfg_cross4k_en = wr_cfg_cross4k_en; // @ idma_regfile.scala l153
  assign io_wr_cfg_arvld_hold_en = wr_cfg_arvld_hold_en; // @ idma_regfile.scala l154
  assign io_wr_cfg_arvld_hold_olen_en = wr_cfg_arvld_hold_olen_en; // @ idma_regfile.scala l155
  assign io_wr_cfg_dfifo_thd = wr_cfg_dfifo_thd[6:0]; // @ idma_regfile.scala l156
  assign io_wr_cfg_strb_force = wr_cfg_strb_force; // @ idma_regfile.scala l157
  assign debug_dma_rd_in_cnt = io_debug_dma_rd_in_cnt; // @ idma_regfile.scala l159
  assign debug_dma_wr_out_cnt = io_debug_dma_wr_out_cnt; // @ idma_regfile.scala l160
  assign read_hit_0x0068 = (({io_apb_PADDR[11 : 2],2'b00} == 12'h068) && busif_doRead); // @ BaseType.scala l305
  assign write_hit_0x0068 = ((io_apb_PADDR == 12'h068) && busif_doWrite); // @ BaseType.scala l305
  assign read_hit_0x006c = (({io_apb_PADDR[11 : 2],2'b00} == 12'h06c) && busif_doRead); // @ BaseType.scala l305
  assign write_hit_0x006c = ((io_apb_PADDR == 12'h06c) && busif_doWrite); // @ BaseType.scala l305
  assign read_hit_0x0070 = (({io_apb_PADDR[11 : 2],2'b00} == 12'h070) && busif_doRead); // @ BaseType.scala l305
  assign write_hit_0x0070 = ((io_apb_PADDR == 12'h070) && busif_doWrite); // @ BaseType.scala l305
  assign wr_done_intr_status = (wr_done_intr_raw && (! wr_done_intr_mask)); // @ BusIfBase.scala l313
  assign rd_done_intr_status = (rd_done_intr_raw && (! rd_done_intr_mask)); // @ BusIfBase.scala l313
  assign INTR_intr = (|(wr_done_intr_status || rd_done_intr_status)); // @ BaseType.scala l312
  assign io_intr = INTR_intr; // @ idma_regfile.scala l161
  assign io_base_addr_0 = base_addr_0; // @ idma_regfile.scala l163
  assign io_base_addr_1 = base_addr_1; // @ idma_regfile.scala l164
  assign io_base_addr_2 = base_addr_2; // @ idma_regfile.scala l165
  assign io_base_addr_3 = base_addr_3; // @ idma_regfile.scala l166
  assign io_base_addr_4 = base_addr_4; // @ idma_regfile.scala l167
  assign io_base_addr_5 = base_addr_5; // @ idma_regfile.scala l168
  assign io_base_addr_6 = base_addr_6; // @ idma_regfile.scala l169
  assign io_base_addr_7 = base_addr_7; // @ idma_regfile.scala l170
  assign io_base_addr_8 = base_addr_8; // @ idma_regfile.scala l171
  assign io_base_addr_9 = base_addr_9; // @ idma_regfile.scala l172
  assign io_base_addr_10 = base_addr_10; // @ idma_regfile.scala l173
  assign io_base_addr_11 = base_addr_11; // @ idma_regfile.scala l174
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
      wr_cfg_en <= 1'b0; // @ Data.scala l400
      wr_afifo_init <= 1'b0; // @ Data.scala l400
      wr_dfifo_init <= 1'b0; // @ Data.scala l400
      wr_cfg_dfifo_thd <= 8'h0; // @ Data.scala l400
      wr_cfg_outstd <= 4'b0000; // @ Data.scala l400
      wr_cfg_outstd_en <= 1'b0; // @ Data.scala l400
      wr_cfg_cross4k_en <= 1'b0; // @ Data.scala l400
      wr_cfg_arvld_hold_en <= 1'b0; // @ Data.scala l400
      wr_cfg_arvld_hold_olen_en <= 1'b0; // @ Data.scala l400
      wr_cfg_strb_force <= 1'b0; // @ Data.scala l400
      base_addr_0 <= 32'h0; // @ Data.scala l400
      base_addr_1 <= 32'h0; // @ Data.scala l400
      base_addr_2 <= 32'h0; // @ Data.scala l400
      base_addr_3 <= 32'h0; // @ Data.scala l400
      base_addr_4 <= 32'h0; // @ Data.scala l400
      base_addr_5 <= 32'h0; // @ Data.scala l400
      base_addr_6 <= 32'h0; // @ Data.scala l400
      base_addr_7 <= 32'h0; // @ Data.scala l400
      base_addr_8 <= 32'h0; // @ Data.scala l400
      base_addr_9 <= 32'h0; // @ Data.scala l400
      base_addr_10 <= 32'h0; // @ Data.scala l400
      base_addr_11 <= 32'h0; // @ Data.scala l400
      wr_done_intr_raw <= 1'b0; // @ Data.scala l400
      wr_done_intr_mask <= 1'b1; // @ Data.scala l400
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
      if(write_hit_0x0020) begin
        wr_cfg_en <= tmp_wr_cfg_en[0]; // @ Bool.scala l189
      end
      if((write_hit_0x0024 && (io_apb_PWDATA[0] && busif_wmask[0]))) begin
        wr_afifo_init <= ((wr_afifo_init && busif_wmaskn[0]) || ((! wr_afifo_init) && busif_wmask[0])); // @ RegInst.scala l741
      end else begin
        wr_afifo_init <= 1'b0; // @ RegInst.scala l742
      end
      if((write_hit_0x0028 && (io_apb_PWDATA[0] && busif_wmask[0]))) begin
        wr_dfifo_init <= ((wr_dfifo_init && busif_wmaskn[0]) || ((! wr_dfifo_init) && busif_wmask[0])); // @ RegInst.scala l741
      end else begin
        wr_dfifo_init <= 1'b0; // @ RegInst.scala l742
      end
      if(write_hit_0x0028) begin
        wr_cfg_dfifo_thd <= ((wr_cfg_dfifo_thd & busif_wmaskn[23 : 16]) | (io_apb_PWDATA[23 : 16] & busif_wmask[23 : 16])); // @ UInt.scala l381
      end
      if(write_hit_0x002c) begin
        wr_cfg_outstd <= ((wr_cfg_outstd & busif_wmaskn[3 : 0]) | (io_apb_PWDATA[3 : 0] & busif_wmask[3 : 0])); // @ UInt.scala l381
      end
      if(write_hit_0x002c) begin
        wr_cfg_outstd_en <= tmp_wr_cfg_outstd_en[0]; // @ Bool.scala l189
      end
      if(write_hit_0x002c) begin
        wr_cfg_cross4k_en <= tmp_wr_cfg_cross4k_en[0]; // @ Bool.scala l189
      end
      if(write_hit_0x002c) begin
        wr_cfg_arvld_hold_en <= tmp_wr_cfg_arvld_hold_en[0]; // @ Bool.scala l189
      end
      if(write_hit_0x002c) begin
        wr_cfg_arvld_hold_olen_en <= tmp_wr_cfg_arvld_hold_olen_en[0]; // @ Bool.scala l189
      end
      if(write_hit_0x002c) begin
        wr_cfg_strb_force <= tmp_wr_cfg_strb_force[0]; // @ Bool.scala l189
      end
      if(write_hit_0x0030) begin
        base_addr_0 <= ((base_addr_0 & busif_wmaskn[31 : 0]) | (io_apb_PWDATA[31 : 0] & busif_wmask[31 : 0])); // @ UInt.scala l381
      end
      if(write_hit_0x0034) begin
        base_addr_1 <= ((base_addr_1 & busif_wmaskn[31 : 0]) | (io_apb_PWDATA[31 : 0] & busif_wmask[31 : 0])); // @ UInt.scala l381
      end
      if(write_hit_0x0038) begin
        base_addr_2 <= ((base_addr_2 & busif_wmaskn[31 : 0]) | (io_apb_PWDATA[31 : 0] & busif_wmask[31 : 0])); // @ UInt.scala l381
      end
      if(write_hit_0x003c) begin
        base_addr_3 <= ((base_addr_3 & busif_wmaskn[31 : 0]) | (io_apb_PWDATA[31 : 0] & busif_wmask[31 : 0])); // @ UInt.scala l381
      end
      if(write_hit_0x0040) begin
        base_addr_4 <= ((base_addr_4 & busif_wmaskn[31 : 0]) | (io_apb_PWDATA[31 : 0] & busif_wmask[31 : 0])); // @ UInt.scala l381
      end
      if(write_hit_0x0044) begin
        base_addr_5 <= ((base_addr_5 & busif_wmaskn[31 : 0]) | (io_apb_PWDATA[31 : 0] & busif_wmask[31 : 0])); // @ UInt.scala l381
      end
      if(write_hit_0x0048) begin
        base_addr_6 <= ((base_addr_6 & busif_wmaskn[31 : 0]) | (io_apb_PWDATA[31 : 0] & busif_wmask[31 : 0])); // @ UInt.scala l381
      end
      if(write_hit_0x004c) begin
        base_addr_7 <= ((base_addr_7 & busif_wmaskn[31 : 0]) | (io_apb_PWDATA[31 : 0] & busif_wmask[31 : 0])); // @ UInt.scala l381
      end
      if(write_hit_0x0050) begin
        base_addr_8 <= ((base_addr_8 & busif_wmaskn[31 : 0]) | (io_apb_PWDATA[31 : 0] & busif_wmask[31 : 0])); // @ UInt.scala l381
      end
      if(write_hit_0x0054) begin
        base_addr_9 <= ((base_addr_9 & busif_wmaskn[31 : 0]) | (io_apb_PWDATA[31 : 0] & busif_wmask[31 : 0])); // @ UInt.scala l381
      end
      if(write_hit_0x0058) begin
        base_addr_10 <= ((base_addr_10 & busif_wmaskn[31 : 0]) | (io_apb_PWDATA[31 : 0] & busif_wmask[31 : 0])); // @ UInt.scala l381
      end
      if(write_hit_0x005c) begin
        base_addr_11 <= ((base_addr_11 & busif_wmaskn[31 : 0]) | (io_apb_PWDATA[31 : 0] & busif_wmask[31 : 0])); // @ UInt.scala l381
      end
      if(write_hit_0x0068) begin
        if((io_apb_PWDATA[0] && busif_wmask[0])) begin
          wr_done_intr_raw <= (wr_done_intr_raw && busif_wmaskn[0]); // @ RegInst.scala l642
        end
      end
      if(write_hit_0x006c) begin
        wr_done_intr_mask <= tmp_wr_done_intr_mask[0]; // @ Bool.scala l189
      end
      if(io_wr_done_intr) begin
        wr_done_intr_raw <= 1'b1; // @ BusIfBase.scala l312
      end
      if(write_hit_0x0068) begin
        if((io_apb_PWDATA[1] && busif_wmask[1])) begin
          rd_done_intr_raw <= (rd_done_intr_raw && busif_wmaskn[1]); // @ RegInst.scala l642
        end
      end
      if(write_hit_0x006c) begin
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
            busif_readData <= {31'h0,wr_cfg_en}; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h024 : begin
            busif_readData <= {31'h0,wr_afifo_init}; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h028 : begin
            busif_readData <= {8'h0,{wr_cfg_dfifo_thd,{reserved_1,wr_dfifo_init}}}; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h02c : begin
            busif_readData <= {23'h0,{wr_cfg_strb_force,{wr_cfg_arvld_hold_olen_en,{wr_cfg_arvld_hold_en,{wr_cfg_cross4k_en,{wr_cfg_outstd_en,wr_cfg_outstd}}}}}}; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h030 : begin
            busif_readData <= base_addr_0; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h034 : begin
            busif_readData <= base_addr_1; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h038 : begin
            busif_readData <= base_addr_2; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h03c : begin
            busif_readData <= base_addr_3; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h040 : begin
            busif_readData <= base_addr_4; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h044 : begin
            busif_readData <= base_addr_5; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h048 : begin
            busif_readData <= base_addr_6; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h04c : begin
            busif_readData <= base_addr_7; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h050 : begin
            busif_readData <= base_addr_8; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h054 : begin
            busif_readData <= base_addr_9; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h058 : begin
            busif_readData <= base_addr_10; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h05c : begin
            busif_readData <= base_addr_11; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h060 : begin
            busif_readData <= {16'h0,debug_dma_rd_in_cnt}; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h064 : begin
            busif_readData <= {16'h0,debug_dma_wr_out_cnt}; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h068 : begin
            busif_readData <= {30'h0,{rd_done_intr_raw,wr_done_intr_raw}}; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h06c : begin
            busif_readData <= {30'h0,{rd_done_intr_mask,wr_done_intr_mask}}; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h070 : begin
            busif_readData <= {30'h0,{rd_done_intr_status,wr_done_intr_status}}; // @ BusIfBase.scala l357
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


endmodule
