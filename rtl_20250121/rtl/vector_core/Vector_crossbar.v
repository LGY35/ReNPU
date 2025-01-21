module Vector_crossbar (
    input [20*16-1:0] routing_bitmask,
    input [16*8-1:0] routing_in,
    output [20*8-1:0] routing_out
);

    genvar i, j;
    generate 
        for (i = 0; i < 20; i = i + 1) begin
            for (j = 0; j < 8; j = j + 1) begin
                assign routing_out[8*i+j] = {(routing_bitmask[16*i] & routing_in[j]) | (routing_bitmask[16*i+1] & routing_in[8+j]) |
                                             (routing_bitmask[16*i+2] & routing_in[16+j]) | (routing_bitmask[16*i+3] & routing_in[24+j]) |
                                             (routing_bitmask[16*i+4] & routing_in[32+j]) | (routing_bitmask[16*i+5] & routing_in[40+j]) |
                                             (routing_bitmask[16*i+6] & routing_in[48+j]) | (routing_bitmask[16*i+7] & routing_in[56+j]) |
                                             (routing_bitmask[16*i+8] & routing_in[64+j]) | (routing_bitmask[16*i+9] & routing_in[72+j]) |
                                             (routing_bitmask[16*i+10] & routing_in[80+j]) | (routing_bitmask[16*i+11] & routing_in[88+j]) |
                                             (routing_bitmask[16*i+12] & routing_in[96+j]) | (routing_bitmask[16*i+13] & routing_in[104+j]) |
                                             (routing_bitmask[16*i+14] & routing_in[112+j]) | (routing_bitmask[16*i+15] & routing_in[120+j])};
                                              
                                              
                                              
                                              
                                            
            end
        end
    endgenerate
endmodule
