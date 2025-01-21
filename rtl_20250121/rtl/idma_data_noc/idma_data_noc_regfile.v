// Generator : SpinalHDL v1.8.1    git head : 2a7592004363e5b40ec43e1f122ed8641cd8965b
// Component : idma_data_noc_regfile
// Git hash  : 5ed3a227fa124f7bf84f7232dae0a17f3dade535

module idma_data_noc_regfile (
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
  output              io_intr,
  input               clk,
  input               resetn
);

  wire       [0:0]    tmp_wr_done_intr_mask;
  wire       [0:0]    tmp_rd_done_intr_mask;
  wire       [0:0]    tmp_rd_cfg_en;
  wire       [0:0]    tmp_rd_cfg_outstd_en;
  wire       [0:0]    tmp_rd_cfg_cross4k_en;
  wire       [0:0]    tmp_rd_cfg_arvld_hold_en;
  wire       [0:0]    tmp_wr_cfg_en;
  wire       [0:0]    tmp_wr_cfg_outstd_en;
  wire       [0:0]    tmp_wr_cfg_cross4k_en;
  wire       [0:0]    tmp_wr_cfg_arvld_hold_en;
  wire       [0:0]    tmp_wr_cfg_arvld_hold_olen_en;
  wire       [0:0]    tmp_wr_cfg_strb_force;
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
  reg                 wr_done_intr_raw;
  reg                 wr_done_intr_mask;
  wire                wr_done_intr_status;
  reg                 rd_done_intr_raw;
  reg                 rd_done_intr_mask;
  wire                rd_done_intr_status;
  wire                INTR_intr;
  reg                 rd_cfg_en;
  reg                 rd_afifo_init;
  reg                 rd_dfifo_init;
  wire       [14:0]   reserved;
  reg        [7:0]    rd_cfg_dfifo_thd;
  reg        [3:0]    rd_cfg_outstd;
  reg                 rd_cfg_outstd_en;
  reg                 rd_cfg_cross4k_en;
  reg                 rd_cfg_arvld_hold_en;
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

  assign tmp_1 = {io_apb_PADDR[11 : 2],2'b00};
  assign tmp_wr_done_intr_mask = ((wr_done_intr_mask & busif_wmaskn[0 : 0]) | (io_apb_PWDATA[0 : 0] & busif_wmask[0 : 0]));
  assign tmp_rd_done_intr_mask = ((rd_done_intr_mask & busif_wmaskn[1 : 1]) | (io_apb_PWDATA[1 : 1] & busif_wmask[1 : 1]));
  assign tmp_rd_cfg_en = ((rd_cfg_en & busif_wmaskn[0 : 0]) | (io_apb_PWDATA[0 : 0] & busif_wmask[0 : 0]));
  assign tmp_rd_cfg_outstd_en = ((rd_cfg_outstd_en & busif_wmaskn[4 : 4]) | (io_apb_PWDATA[4 : 4] & busif_wmask[4 : 4]));
  assign tmp_rd_cfg_cross4k_en = ((rd_cfg_cross4k_en & busif_wmaskn[5 : 5]) | (io_apb_PWDATA[5 : 5] & busif_wmask[5 : 5]));
  assign tmp_rd_cfg_arvld_hold_en = ((rd_cfg_arvld_hold_en & busif_wmaskn[6 : 6]) | (io_apb_PWDATA[6 : 6] & busif_wmask[6 : 6]));
  assign tmp_wr_cfg_en = ((wr_cfg_en & busif_wmaskn[0 : 0]) | (io_apb_PWDATA[0 : 0] & busif_wmask[0 : 0]));
  assign tmp_wr_cfg_outstd_en = ((wr_cfg_outstd_en & busif_wmaskn[4 : 4]) | (io_apb_PWDATA[4 : 4] & busif_wmask[4 : 4]));
  assign tmp_wr_cfg_cross4k_en = ((wr_cfg_cross4k_en & busif_wmaskn[5 : 5]) | (io_apb_PWDATA[5 : 5] & busif_wmask[5 : 5]));
  assign tmp_wr_cfg_arvld_hold_en = ((wr_cfg_arvld_hold_en & busif_wmaskn[6 : 6]) | (io_apb_PWDATA[6 : 6] & busif_wmask[6 : 6]));
  assign tmp_wr_cfg_arvld_hold_olen_en = ((wr_cfg_arvld_hold_olen_en & busif_wmaskn[7 : 7]) | (io_apb_PWDATA[7 : 7] & busif_wmask[7 : 7]));
  assign tmp_wr_cfg_strb_force = ((wr_cfg_strb_force & busif_wmaskn[8 : 8]) | (io_apb_PWDATA[8 : 8] & busif_wmask[8 : 8]));
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
  assign wr_done_intr_status = (wr_done_intr_raw && (! wr_done_intr_mask)); // @ BusIfBase.scala l313
  assign rd_done_intr_status = (rd_done_intr_raw && (! rd_done_intr_mask)); // @ BusIfBase.scala l313
  assign INTR_intr = (|(wr_done_intr_status || rd_done_intr_status)); // @ BaseType.scala l312
  assign io_intr = INTR_intr; // @ idma_data_noc_regfile.scala l58
  assign reserved = 15'h0; // @ Bits.scala l133
  assign reserved_1 = 15'h0; // @ Bits.scala l133
  assign io_rd_cfg_ready = rd_cfg_en; // @ idma_data_noc_regfile.scala l89
  assign io_rd_afifo_init = rd_afifo_init; // @ idma_data_noc_regfile.scala l90
  assign io_rd_dfifo_init = rd_dfifo_init; // @ idma_data_noc_regfile.scala l91
  assign io_rd_cfg_outstd = rd_cfg_outstd; // @ idma_data_noc_regfile.scala l92
  assign io_rd_cfg_outstd_en = rd_cfg_outstd_en; // @ idma_data_noc_regfile.scala l93
  assign io_rd_cfg_cross4k_en = rd_cfg_cross4k_en; // @ idma_data_noc_regfile.scala l94
  assign io_rd_cfg_arvld_hold_en = rd_cfg_arvld_hold_en; // @ idma_data_noc_regfile.scala l95
  assign io_rd_cfg_dfifo_thd = rd_cfg_dfifo_thd[6:0]; // @ idma_data_noc_regfile.scala l96
  assign io_wr_cfg_ready = wr_cfg_en; // @ idma_data_noc_regfile.scala l102
  assign io_wr_afifo_init = wr_afifo_init; // @ idma_data_noc_regfile.scala l103
  assign io_wr_dfifo_init = wr_dfifo_init; // @ idma_data_noc_regfile.scala l104
  assign io_wr_cfg_outstd = wr_cfg_outstd; // @ idma_data_noc_regfile.scala l105
  assign io_wr_cfg_outstd_en = wr_cfg_outstd_en; // @ idma_data_noc_regfile.scala l106
  assign io_wr_cfg_cross4k_en = wr_cfg_cross4k_en; // @ idma_data_noc_regfile.scala l107
  assign io_wr_cfg_arvld_hold_en = wr_cfg_arvld_hold_en; // @ idma_data_noc_regfile.scala l108
  assign io_wr_cfg_arvld_hold_olen_en = wr_cfg_arvld_hold_olen_en; // @ idma_data_noc_regfile.scala l109
  assign io_wr_cfg_dfifo_thd = wr_cfg_dfifo_thd[6:0]; // @ idma_data_noc_regfile.scala l110
  assign io_wr_cfg_strb_force = wr_cfg_strb_force; // @ idma_data_noc_regfile.scala l111
  assign debug_dma_rd_in_cnt = io_debug_dma_rd_in_cnt; // @ idma_data_noc_regfile.scala l112
  assign debug_dma_wr_out_cnt = io_debug_dma_wr_out_cnt; // @ idma_data_noc_regfile.scala l113
  always @(posedge clk or negedge resetn) begin
    if(!resetn) begin
      busif_readError <= 1'b0; // @ Data.scala l400
      busif_readData <= 32'h0; // @ Data.scala l400
      wr_done_intr_raw <= 1'b0; // @ Data.scala l400
      wr_done_intr_mask <= 1'b1; // @ Data.scala l400
      rd_done_intr_raw <= 1'b0; // @ Data.scala l400
      rd_done_intr_mask <= 1'b1; // @ Data.scala l400
      rd_cfg_en <= 1'b1; // @ Data.scala l400
      rd_afifo_init <= 1'b0; // @ Data.scala l400
      rd_dfifo_init <= 1'b0; // @ Data.scala l400
      rd_cfg_dfifo_thd <= 8'h0; // @ Data.scala l400
      rd_cfg_outstd <= 4'b0100; // @ Data.scala l400
      rd_cfg_outstd_en <= 1'b1; // @ Data.scala l400
      rd_cfg_cross4k_en <= 1'b1; // @ Data.scala l400
      rd_cfg_arvld_hold_en <= 1'b0; // @ Data.scala l400
      wr_cfg_en <= 1'b1; // @ Data.scala l400
      wr_afifo_init <= 1'b0; // @ Data.scala l400
      wr_dfifo_init <= 1'b0; // @ Data.scala l400
      wr_cfg_dfifo_thd <= 8'h0; // @ Data.scala l400
      wr_cfg_outstd <= 4'b0100; // @ Data.scala l400
      wr_cfg_outstd_en <= 1'b1; // @ Data.scala l400
      wr_cfg_cross4k_en <= 1'b1; // @ Data.scala l400
      wr_cfg_arvld_hold_en <= 1'b0; // @ Data.scala l400
      wr_cfg_arvld_hold_olen_en <= 1'b0; // @ Data.scala l400
      wr_cfg_strb_force <= 1'b0; // @ Data.scala l400
    end else begin
      if(write_hit_0x0050) begin
        if((io_apb_PWDATA[0] && busif_wmask[0])) begin
          wr_done_intr_raw <= (wr_done_intr_raw && busif_wmaskn[0]); // @ RegInst.scala l642
        end
      end
      if(write_hit_0x0054) begin
        wr_done_intr_mask <= tmp_wr_done_intr_mask[0]; // @ Bool.scala l189
      end
      if(io_wr_done_intr) begin
        wr_done_intr_raw <= 1'b1; // @ BusIfBase.scala l312
      end
      if(write_hit_0x0050) begin
        if((io_apb_PWDATA[1] && busif_wmask[1])) begin
          rd_done_intr_raw <= (rd_done_intr_raw && busif_wmaskn[1]); // @ RegInst.scala l642
        end
      end
      if(write_hit_0x0054) begin
        rd_done_intr_mask <= tmp_rd_done_intr_mask[0]; // @ Bool.scala l189
      end
      if(io_rd_done_intr) begin
        rd_done_intr_raw <= 1'b1; // @ BusIfBase.scala l312
      end
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
      if(write_hit_0x0010) begin
        wr_cfg_en <= tmp_wr_cfg_en[0]; // @ Bool.scala l189
      end
      if((write_hit_0x0014 && (io_apb_PWDATA[0] && busif_wmask[0]))) begin
        wr_afifo_init <= ((wr_afifo_init && busif_wmaskn[0]) || ((! wr_afifo_init) && busif_wmask[0])); // @ RegInst.scala l741
      end else begin
        wr_afifo_init <= 1'b0; // @ RegInst.scala l742
      end
      if((write_hit_0x0018 && (io_apb_PWDATA[0] && busif_wmask[0]))) begin
        wr_dfifo_init <= ((wr_dfifo_init && busif_wmaskn[0]) || ((! wr_dfifo_init) && busif_wmask[0])); // @ RegInst.scala l741
      end else begin
        wr_dfifo_init <= 1'b0; // @ RegInst.scala l742
      end
      if(write_hit_0x0018) begin
        wr_cfg_dfifo_thd <= ((wr_cfg_dfifo_thd & busif_wmaskn[23 : 16]) | (io_apb_PWDATA[23 : 16] & busif_wmask[23 : 16])); // @ UInt.scala l381
      end
      if(write_hit_0x001c) begin
        wr_cfg_outstd <= ((wr_cfg_outstd & busif_wmaskn[3 : 0]) | (io_apb_PWDATA[3 : 0] & busif_wmask[3 : 0])); // @ UInt.scala l381
      end
      if(write_hit_0x001c) begin
        wr_cfg_outstd_en <= tmp_wr_cfg_outstd_en[0]; // @ Bool.scala l189
      end
      if(write_hit_0x001c) begin
        wr_cfg_cross4k_en <= tmp_wr_cfg_cross4k_en[0]; // @ Bool.scala l189
      end
      if(write_hit_0x001c) begin
        wr_cfg_arvld_hold_en <= tmp_wr_cfg_arvld_hold_en[0]; // @ Bool.scala l189
      end
      if(write_hit_0x001c) begin
        wr_cfg_arvld_hold_olen_en <= tmp_wr_cfg_arvld_hold_olen_en[0]; // @ Bool.scala l189
      end
      if(write_hit_0x001c) begin
        wr_cfg_strb_force <= tmp_wr_cfg_strb_force[0]; // @ Bool.scala l189
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
            busif_readData <= {25'h0,{rd_cfg_arvld_hold_en,{rd_cfg_cross4k_en,{rd_cfg_outstd_en,rd_cfg_outstd}}}}; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h010 : begin
            busif_readData <= {31'h0,wr_cfg_en}; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h014 : begin
            busif_readData <= {31'h0,wr_afifo_init}; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h018 : begin
            busif_readData <= {8'h0,{wr_cfg_dfifo_thd,{reserved_1,wr_dfifo_init}}}; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h01c : begin
            busif_readData <= {23'h0,{wr_cfg_strb_force,{wr_cfg_arvld_hold_olen_en,{wr_cfg_arvld_hold_en,{wr_cfg_cross4k_en,{wr_cfg_outstd_en,wr_cfg_outstd}}}}}}; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h048 : begin
            busif_readData <= {16'h0,debug_dma_rd_in_cnt}; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h04c : begin
            busif_readData <= {16'h0,debug_dma_wr_out_cnt}; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h050 : begin
            busif_readData <= {30'h0,{rd_done_intr_raw,wr_done_intr_raw}}; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h054 : begin
            busif_readData <= {30'h0,{rd_done_intr_mask,wr_done_intr_mask}}; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h058 : begin
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
