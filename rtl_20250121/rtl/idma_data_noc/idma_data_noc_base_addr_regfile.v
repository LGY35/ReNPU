// Generator : SpinalHDL v1.8.1    git head : 2a7592004363e5b40ec43e1f122ed8641cd8965b
// Component : idma_data_noc_base_addr_regfile
// Git hash  : 5ed3a227fa124f7bf84f7232dae0a17f3dade535

`timescale 1ns/1ps

module idma_data_noc_base_addr_regfile (
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
  output     [31:0]   io_base_addr_0,
  output     [31:0]   io_base_addr_1,
  output     [31:0]   io_base_addr_2,
  output     [31:0]   io_base_addr_3,
  output     [31:0]   io_base_addr_4,
  output     [31:0]   io_base_addr_5,
  output     [31:0]   io_group_base_addr_0,
  output     [31:0]   io_group_base_addr_1,
  output     [31:0]   io_group_base_addr_2,
  output     [31:0]   io_group_base_addr_3,
  output     [31:0]   io_group_base_addr_4,
  output     [31:0]   io_group_base_addr_5,
  output     [31:0]   io_write_base_addr_0,
  output     [31:0]   io_write_base_addr_1,
  output     [31:0]   io_write_base_addr_2,
  output     [31:0]   io_write_base_addr_3,
  output     [31:0]   io_write_base_addr_4,
  output     [31:0]   io_write_base_addr_5,
  input               clk,
  input               resetn
);

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
  reg        [31:0]   base_addr_0;
  reg        [31:0]   base_addr_1;
  reg        [31:0]   base_addr_2;
  reg        [31:0]   base_addr_3;
  reg        [31:0]   base_addr_4;
  reg        [31:0]   base_addr_5;
  reg        [31:0]   group_base_addr_0;
  reg        [31:0]   group_base_addr_1;
  reg        [31:0]   group_base_addr_2;
  reg        [31:0]   group_base_addr_3;
  reg        [31:0]   group_base_addr_4;
  reg        [31:0]   group_base_addr_5;
  reg        [31:0]   write_base_addr_0;
  reg        [31:0]   write_base_addr_1;
  reg        [31:0]   write_base_addr_2;
  reg        [31:0]   write_base_addr_3;
  reg        [31:0]   write_base_addr_4;
  reg        [31:0]   write_base_addr_5;

  assign tmp_1 = {io_apb_PADDR[11 : 2],2'b00};
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
  assign io_base_addr_0 = base_addr_0; // @ idma_data_noc_base_addr_regfile.scala l80
  assign io_base_addr_1 = base_addr_1; // @ idma_data_noc_base_addr_regfile.scala l81
  assign io_base_addr_2 = base_addr_2; // @ idma_data_noc_base_addr_regfile.scala l82
  assign io_base_addr_3 = base_addr_3; // @ idma_data_noc_base_addr_regfile.scala l83
  assign io_base_addr_4 = base_addr_4; // @ idma_data_noc_base_addr_regfile.scala l84
  assign io_base_addr_5 = base_addr_5; // @ idma_data_noc_base_addr_regfile.scala l85
  assign io_group_base_addr_0 = group_base_addr_0; // @ idma_data_noc_base_addr_regfile.scala l87
  assign io_group_base_addr_1 = group_base_addr_1; // @ idma_data_noc_base_addr_regfile.scala l88
  assign io_group_base_addr_2 = group_base_addr_2; // @ idma_data_noc_base_addr_regfile.scala l89
  assign io_group_base_addr_3 = group_base_addr_3; // @ idma_data_noc_base_addr_regfile.scala l90
  assign io_group_base_addr_4 = group_base_addr_4; // @ idma_data_noc_base_addr_regfile.scala l91
  assign io_group_base_addr_5 = group_base_addr_5; // @ idma_data_noc_base_addr_regfile.scala l92
  assign io_write_base_addr_0 = write_base_addr_0; // @ idma_data_noc_base_addr_regfile.scala l94
  assign io_write_base_addr_1 = write_base_addr_1; // @ idma_data_noc_base_addr_regfile.scala l95
  assign io_write_base_addr_2 = write_base_addr_2; // @ idma_data_noc_base_addr_regfile.scala l96
  assign io_write_base_addr_3 = write_base_addr_3; // @ idma_data_noc_base_addr_regfile.scala l97
  assign io_write_base_addr_4 = write_base_addr_4; // @ idma_data_noc_base_addr_regfile.scala l98
  assign io_write_base_addr_5 = write_base_addr_5; // @ idma_data_noc_base_addr_regfile.scala l99
  always @(posedge clk or negedge resetn) begin
    if(!resetn) begin
      busif_readError <= 1'b0; // @ Data.scala l400
      busif_readData <= 32'h0; // @ Data.scala l400
      base_addr_0 <= 32'h0; // @ Data.scala l400
      base_addr_1 <= 32'h0; // @ Data.scala l400
      base_addr_2 <= 32'h0; // @ Data.scala l400
      base_addr_3 <= 32'h0; // @ Data.scala l400
      base_addr_4 <= 32'h0; // @ Data.scala l400
      base_addr_5 <= 32'h0; // @ Data.scala l400
      group_base_addr_0 <= 32'h0; // @ Data.scala l400
      group_base_addr_1 <= 32'h0; // @ Data.scala l400
      group_base_addr_2 <= 32'h0; // @ Data.scala l400
      group_base_addr_3 <= 32'h0; // @ Data.scala l400
      group_base_addr_4 <= 32'h0; // @ Data.scala l400
      group_base_addr_5 <= 32'h0; // @ Data.scala l400
      write_base_addr_0 <= 32'h0; // @ Data.scala l400
      write_base_addr_1 <= 32'h0; // @ Data.scala l400
      write_base_addr_2 <= 32'h0; // @ Data.scala l400
      write_base_addr_3 <= 32'h0; // @ Data.scala l400
      write_base_addr_4 <= 32'h0; // @ Data.scala l400
      write_base_addr_5 <= 32'h0; // @ Data.scala l400
    end else begin
      if(write_hit_0x0000) begin
        base_addr_0 <= ((base_addr_0 & busif_wmaskn[31 : 0]) | (io_apb_PWDATA[31 : 0] & busif_wmask[31 : 0])); // @ UInt.scala l381
      end
      if(write_hit_0x0004) begin
        base_addr_1 <= ((base_addr_1 & busif_wmaskn[31 : 0]) | (io_apb_PWDATA[31 : 0] & busif_wmask[31 : 0])); // @ UInt.scala l381
      end
      if(write_hit_0x0008) begin
        base_addr_2 <= ((base_addr_2 & busif_wmaskn[31 : 0]) | (io_apb_PWDATA[31 : 0] & busif_wmask[31 : 0])); // @ UInt.scala l381
      end
      if(write_hit_0x000c) begin
        base_addr_3 <= ((base_addr_3 & busif_wmaskn[31 : 0]) | (io_apb_PWDATA[31 : 0] & busif_wmask[31 : 0])); // @ UInt.scala l381
      end
      if(write_hit_0x0010) begin
        base_addr_4 <= ((base_addr_4 & busif_wmaskn[31 : 0]) | (io_apb_PWDATA[31 : 0] & busif_wmask[31 : 0])); // @ UInt.scala l381
      end
      if(write_hit_0x0014) begin
        base_addr_5 <= ((base_addr_5 & busif_wmaskn[31 : 0]) | (io_apb_PWDATA[31 : 0] & busif_wmask[31 : 0])); // @ UInt.scala l381
      end
      if(write_hit_0x0018) begin
        group_base_addr_0 <= ((group_base_addr_0 & busif_wmaskn[31 : 0]) | (io_apb_PWDATA[31 : 0] & busif_wmask[31 : 0])); // @ UInt.scala l381
      end
      if(write_hit_0x001c) begin
        group_base_addr_1 <= ((group_base_addr_1 & busif_wmaskn[31 : 0]) | (io_apb_PWDATA[31 : 0] & busif_wmask[31 : 0])); // @ UInt.scala l381
      end
      if(write_hit_0x0020) begin
        group_base_addr_2 <= ((group_base_addr_2 & busif_wmaskn[31 : 0]) | (io_apb_PWDATA[31 : 0] & busif_wmask[31 : 0])); // @ UInt.scala l381
      end
      if(write_hit_0x0024) begin
        group_base_addr_3 <= ((group_base_addr_3 & busif_wmaskn[31 : 0]) | (io_apb_PWDATA[31 : 0] & busif_wmask[31 : 0])); // @ UInt.scala l381
      end
      if(write_hit_0x0028) begin
        group_base_addr_4 <= ((group_base_addr_4 & busif_wmaskn[31 : 0]) | (io_apb_PWDATA[31 : 0] & busif_wmask[31 : 0])); // @ UInt.scala l381
      end
      if(write_hit_0x002c) begin
        group_base_addr_5 <= ((group_base_addr_5 & busif_wmaskn[31 : 0]) | (io_apb_PWDATA[31 : 0] & busif_wmask[31 : 0])); // @ UInt.scala l381
      end
      if(write_hit_0x0030) begin
        write_base_addr_0 <= ((write_base_addr_0 & busif_wmaskn[31 : 0]) | (io_apb_PWDATA[31 : 0] & busif_wmask[31 : 0])); // @ UInt.scala l381
      end
      if(write_hit_0x0034) begin
        write_base_addr_1 <= ((write_base_addr_1 & busif_wmaskn[31 : 0]) | (io_apb_PWDATA[31 : 0] & busif_wmask[31 : 0])); // @ UInt.scala l381
      end
      if(write_hit_0x0038) begin
        write_base_addr_2 <= ((write_base_addr_2 & busif_wmaskn[31 : 0]) | (io_apb_PWDATA[31 : 0] & busif_wmask[31 : 0])); // @ UInt.scala l381
      end
      if(write_hit_0x003c) begin
        write_base_addr_3 <= ((write_base_addr_3 & busif_wmaskn[31 : 0]) | (io_apb_PWDATA[31 : 0] & busif_wmask[31 : 0])); // @ UInt.scala l381
      end
      if(write_hit_0x0040) begin
        write_base_addr_4 <= ((write_base_addr_4 & busif_wmaskn[31 : 0]) | (io_apb_PWDATA[31 : 0] & busif_wmask[31 : 0])); // @ UInt.scala l381
      end
      if(write_hit_0x0044) begin
        write_base_addr_5 <= ((write_base_addr_5 & busif_wmaskn[31 : 0]) | (io_apb_PWDATA[31 : 0] & busif_wmask[31 : 0])); // @ UInt.scala l381
      end
      if(busif_askRead) begin
        case(tmp_1)
          12'h0 : begin
            busif_readData <= base_addr_0; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h004 : begin
            busif_readData <= base_addr_1; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h008 : begin
            busif_readData <= base_addr_2; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h00c : begin
            busif_readData <= base_addr_3; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h010 : begin
            busif_readData <= base_addr_4; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h014 : begin
            busif_readData <= base_addr_5; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h018 : begin
            busif_readData <= group_base_addr_0; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h01c : begin
            busif_readData <= group_base_addr_1; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h020 : begin
            busif_readData <= group_base_addr_2; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h024 : begin
            busif_readData <= group_base_addr_3; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h028 : begin
            busif_readData <= group_base_addr_4; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h02c : begin
            busif_readData <= group_base_addr_5; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h030 : begin
            busif_readData <= write_base_addr_0; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h034 : begin
            busif_readData <= write_base_addr_1; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h038 : begin
            busif_readData <= write_base_addr_2; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h03c : begin
            busif_readData <= write_base_addr_3; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h040 : begin
            busif_readData <= write_base_addr_4; // @ BusIfBase.scala l357
            busif_readError <= 1'b0; // @ BusIfBase.scala l358
          end
          12'h044 : begin
            busif_readData <= write_base_addr_5; // @ BusIfBase.scala l357
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
