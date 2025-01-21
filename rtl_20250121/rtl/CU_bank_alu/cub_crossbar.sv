module cub_crossbar  #(
        parameter    DWID    = 32 ,
        parameter    CH_IN   = 5  ,
        parameter    CH_OUT  = 5
        )(
         input           [CH_OUT-1:0][CH_IN-1:0]          cub_crbr_cfg_bitmask        ,
         input           [CH_IN-1:0][DWID-1 : 0]          cub_crbr_cflow_data_in      ,
         input           [CH_IN-1:0]                      cub_crbr_cflow_valid_in     ,
         output logic    [CH_OUT-1:0][DWID-1 : 0]         cub_crbr_cflow_data_out     ,
         output logic    [CH_OUT-1:0]                     cub_crbr_cflow_valid_out     
        );



        int i;
        //logic [CH_OUT-1:0] crbr_or_tmp ;
        /*
        always_comb begin
            foreach(cub_crbr_cflow_valid_out[o]) begin
                     cub_crbr_cflow_valid_out[o] = 'b0;
                     cub_crbr_cflow_data_out[o] = 'b0 ;
                    for(i=0; i < CH_IN-1; i=i+1) begin
                        cub_crbr_cflow_valid_out[o] =  cub_crbr_cflow_valid_out[o] | (cub_crbr_cflow_valid_in[i] & cub_crbr_cfg_bitmask[o][i]);
                        cub_crbr_cflow_data_out[o]  =  cub_crbr_cflow_data_out[o]  | (cub_crbr_cflow_data_in [i] & {DWID{cub_crbr_cfg_bitmask[o][i]}});
                    end
            end
        end
        */
        always_comb begin
            foreach(cub_crbr_cflow_valid_out[o]) begin
                     cub_crbr_cflow_valid_out[o] = 'b0;
                     cub_crbr_cflow_data_out[o] = 'b0 ;

                     cub_crbr_cflow_valid_out[o] =  (cub_crbr_cflow_valid_in[0] & cub_crbr_cfg_bitmask[o][0]) |
                                                    (cub_crbr_cflow_valid_in[1] & cub_crbr_cfg_bitmask[o][1]) |
                                                    (cub_crbr_cflow_valid_in[2] & cub_crbr_cfg_bitmask[o][2]) |
                                                    (cub_crbr_cflow_valid_in[3] & cub_crbr_cfg_bitmask[o][3]) |
                                                    (cub_crbr_cflow_valid_in[4] & cub_crbr_cfg_bitmask[o][4]) ;
                     cub_crbr_cflow_data_out[o]  =  (cub_crbr_cflow_data_in [0] & {DWID{cub_crbr_cfg_bitmask[o][0]}}) | 
                                                    (cub_crbr_cflow_data_in [1] & {DWID{cub_crbr_cfg_bitmask[o][1]}}) |
                                                    (cub_crbr_cflow_data_in [2] & {DWID{cub_crbr_cfg_bitmask[o][2]}}) |
                                                    (cub_crbr_cflow_data_in [3] & {DWID{cub_crbr_cfg_bitmask[o][3]}}) |
                                                    (cub_crbr_cflow_data_in [4] & {DWID{cub_crbr_cfg_bitmask[o][4]}}) ;
            end
        end


endmodule
