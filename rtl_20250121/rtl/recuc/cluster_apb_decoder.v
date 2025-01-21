// Generator : SpinalHDL v1.8.1    git head : 2a7592004363e5b40ec43e1f122ed8641cd8965b
// Component : cluster_apb_decoder
// Git hash  : 5ed3a227fa124f7bf84f7232dae0a17f3dade535

module cluster_apb_decoder (
  input      [11:0]   io_apb_PADDR,
  input      [0:0]    io_apb_PSEL,
  input               io_apb_PENABLE,
  output reg          io_apb_PREADY,
  input               io_apb_PWRITE,
  input      [3:0]    io_apb_PSTRB,
  input      [2:0]    io_apb_PPROT,
  input      [31:0]   io_apb_PWDATA,
  output     [31:0]   io_apb_PRDATA,
  output reg          io_apb_PSLVERR,
  output     [11:0]   apb_0_PADDR,
  output     [0:0]    apb_0_PSEL,
  output              apb_0_PENABLE,
  input               apb_0_PREADY,
  output              apb_0_PWRITE,
  output     [3:0]    apb_0_PSTRB,
  output     [2:0]    apb_0_PPROT,
  output     [31:0]   apb_0_PWDATA,
  input      [31:0]   apb_0_PRDATA,
  input               apb_0_PSLVERR,
  output     [11:0]   apb_1_PADDR,
  output     [0:0]    apb_1_PSEL,
  output              apb_1_PENABLE,
  input               apb_1_PREADY,
  output              apb_1_PWRITE,
  output     [3:0]    apb_1_PSTRB,
  output     [2:0]    apb_1_PPROT,
  output     [31:0]   apb_1_PWDATA,
  input      [31:0]   apb_1_PRDATA,
  input               apb_1_PSLVERR,
  output     [11:0]   apb_2_PADDR,
  output     [0:0]    apb_2_PSEL,
  output              apb_2_PENABLE,
  input               apb_2_PREADY,
  output              apb_2_PWRITE,
  output     [3:0]    apb_2_PSTRB,
  output     [2:0]    apb_2_PPROT,
  output     [31:0]   apb_2_PWDATA,
  input      [31:0]   apb_2_PRDATA,
  input               apb_2_PSLVERR
);

  reg                 tmp_io_apb_PREADY;
  reg        [31:0]   tmp_io_apb_PRDATA;
  reg                 tmp_io_apb_PSLVERR;
  wire                tmp_when;
  reg        [2:0]    tmp_apb_0_PSEL;
  wire                tmp_psel_index;
  wire                tmp_psel_index_1;
  wire       [1:0]    psel_index;

  assign tmp_when = (io_apb_PSEL[0] && (tmp_apb_0_PSEL == 3'b000));
  always @(*) begin
    case(psel_index)
      2'b00 : begin
        tmp_io_apb_PREADY = apb_0_PREADY;
        tmp_io_apb_PRDATA = apb_0_PRDATA;
        tmp_io_apb_PSLVERR = apb_0_PSLVERR;
      end
      2'b01 : begin
        tmp_io_apb_PREADY = apb_1_PREADY;
        tmp_io_apb_PRDATA = apb_1_PRDATA;
        tmp_io_apb_PSLVERR = apb_1_PSLVERR;
      end
      default : begin
        tmp_io_apb_PREADY = apb_2_PREADY;
        tmp_io_apb_PRDATA = apb_2_PRDATA;
        tmp_io_apb_PSLVERR = apb_2_PSLVERR;
      end
    endcase
  end

  always @(*) begin
    tmp_apb_0_PSEL[0] = (((io_apb_PADDR & (~ 12'h3ff)) == 12'h0) && io_apb_PSEL[0]); // @ Apb4Decoder.scala l16
    tmp_apb_0_PSEL[1] = (((io_apb_PADDR & (~ 12'h3ff)) == 12'h400) && io_apb_PSEL[0]); // @ Apb4Decoder.scala l16
    tmp_apb_0_PSEL[2] = (((io_apb_PADDR & (~ 12'h3ff)) == 12'h800) && io_apb_PSEL[0]); // @ Apb4Decoder.scala l16
  end

  assign apb_0_PADDR = io_apb_PADDR; // @ Apb4Decoder.scala l17
  assign apb_0_PENABLE = io_apb_PENABLE; // @ Apb4Decoder.scala l18
  assign apb_0_PSEL = tmp_apb_0_PSEL[0]; // @ Apb4Decoder.scala l19
  assign apb_0_PWRITE = io_apb_PWRITE; // @ Apb4Decoder.scala l20
  assign apb_0_PWDATA = io_apb_PWDATA; // @ Apb4Decoder.scala l21
  assign apb_0_PSTRB = io_apb_PSTRB; // @ Apb4Decoder.scala l22
  assign apb_0_PPROT = io_apb_PPROT; // @ Apb4Decoder.scala l23
  assign apb_1_PADDR = io_apb_PADDR; // @ Apb4Decoder.scala l17
  assign apb_1_PENABLE = io_apb_PENABLE; // @ Apb4Decoder.scala l18
  assign apb_1_PSEL = tmp_apb_0_PSEL[1]; // @ Apb4Decoder.scala l19
  assign apb_1_PWRITE = io_apb_PWRITE; // @ Apb4Decoder.scala l20
  assign apb_1_PWDATA = io_apb_PWDATA; // @ Apb4Decoder.scala l21
  assign apb_1_PSTRB = io_apb_PSTRB; // @ Apb4Decoder.scala l22
  assign apb_1_PPROT = io_apb_PPROT; // @ Apb4Decoder.scala l23
  assign apb_2_PADDR = io_apb_PADDR; // @ Apb4Decoder.scala l17
  assign apb_2_PENABLE = io_apb_PENABLE; // @ Apb4Decoder.scala l18
  assign apb_2_PSEL = tmp_apb_0_PSEL[2]; // @ Apb4Decoder.scala l19
  assign apb_2_PWRITE = io_apb_PWRITE; // @ Apb4Decoder.scala l20
  assign apb_2_PWDATA = io_apb_PWDATA; // @ Apb4Decoder.scala l21
  assign apb_2_PSTRB = io_apb_PSTRB; // @ Apb4Decoder.scala l22
  assign apb_2_PPROT = io_apb_PPROT; // @ Apb4Decoder.scala l23
  assign tmp_psel_index = tmp_apb_0_PSEL[1]; // @ BaseType.scala l305
  assign tmp_psel_index_1 = tmp_apb_0_PSEL[2]; // @ BaseType.scala l305
  assign psel_index = {tmp_psel_index_1,tmp_psel_index}; // @ BaseType.scala l318
  always @(*) begin
    io_apb_PREADY = tmp_io_apb_PREADY; // @ Apb4Decoder.scala l29
    if(tmp_when) begin
      io_apb_PREADY = 1'b1; // @ Apb4Decoder.scala l38
    end
  end

  assign io_apb_PRDATA = tmp_io_apb_PRDATA; // @ Apb4Decoder.scala l30
  always @(*) begin
    io_apb_PSLVERR = tmp_io_apb_PSLVERR; // @ Apb4Decoder.scala l33
    if(tmp_when) begin
      io_apb_PSLVERR = 1'b1; // @ Apb4Decoder.scala l40
    end
  end


endmodule
