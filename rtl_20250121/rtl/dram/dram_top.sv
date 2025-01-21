module dram_top (
    input          clk,
    input          rst_n,
    input          data_req,
    output         data_gnt,
    input          data_we,
    input  [3:0]   data_be,
    input  [8:0]   data_addr,
    input  [31:0]  data_wdata,
    output logic   data_rvalid,
    output [31:0]  data_rdata
);

  assign data_gnt = 1'b1;


  always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            data_rvalid <= 1'b0;
        end
        else if (data_gnt && data_req)begin
            data_rvalid <= 1'b1;
        end
        else begin
            data_rvalid <= 1'b0;
        end
  end

  std_spram512x32 U_spram512x32_wrapper (
    .CLK(clk),
//    .rst_n(rst_n),
    .D(data_wdata),
    .Q(data_rdata),
    .CEB(~data_req),
    .WEB(~data_we),
    .A(data_addr),
    .BE(data_be)
  );

endmodule
