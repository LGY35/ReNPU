module psum_out_adder (
    input clk,
    input rstn,
    input [2:0] calculation_mode,//000:普通conv模式，001:稀疏conv模式 010:dwconv模式 011:fc模式
    input [2:0] fmap_precision,
    input [2:0] weight_precision,
    input [31:0] accu_out0,
    input [31:0] accu_out1,
    input [63:0] psum_data_out,
    input psum_data_out_vld,
    input accu_out_vld,
    output reg vector_data_out_40b_vld,
    output [40-1:0] vector_data_out_40b
);
    reg [31:0] src_h;
    reg [31:0] src_l;
    wire is_shift;

    assign is_shift = (fmap_precision == 3'b010) & (weight_precision == 3'b010);

    pe_adder_shift #(
        .DATA_WIDTH(32),
        .RSLT_WIDTH(40),
        .SHIFT_AMOUNT(8)
    ) psum_out_adder_U0(
        .src_h(src_h),
        .src_l(src_l),
        .dst(vector_data_out_40b),
        .is_shift(is_shift)
    );

    always @ (posedge clk or negedge rstn) begin
        if (!rstn) begin
            src_h <= 32'b0;
            src_l <= 32'd0;
        end
        else if ((calculation_mode == 3'b010) & accu_out_vld) begin
            src_h <= accu_out0;
            src_l <= accu_out1;
        end
        else if ((calculation_mode[2:1] == 2'b00) & psum_data_out_vld) begin
            src_h <= psum_data_out[31:0];
            src_l <= psum_data_out[63:32];
        end
        else begin
            src_h <= 32'b0;
            src_l <= 32'd0;
        end
    end

    always @ (posedge clk or negedge rstn) begin
        if (!rstn) begin
            vector_data_out_40b_vld <=1'b0;
        end
        else begin
            vector_data_out_40b_vld <= ((calculation_mode == 3'b010) & accu_out_vld) | ((calculation_mode[2:1] == 2'b00) & psum_data_out_vld);
        end
    end
endmodule
