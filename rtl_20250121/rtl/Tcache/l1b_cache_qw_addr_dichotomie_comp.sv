module l1b_cache_qw_addr_dichotomie_comp #(
            parameter                   LB_RAM_NUM                  =  32, //32 ram
            parameter                   LB_ONE_BANK_NUM             =  LB_RAM_NUM/2, 
            parameter                   LB_HALF_ONE_BANK_CS_ADDR_WID     =  3,  // 16 ram

            parameter                   LB_SYS_ONE_RAM_QW_ADDR_WID  =   8, // 256 qword 
            parameter                   LSU_SYS_ADDR_WID            =  LB_SYS_ONE_RAM_QW_ADDR_WID + 4,  // 256 quatern word * 16bank
            parameter                   LSU_SYS_ONE_BANK_ADDR_WID   = LB_SYS_ONE_RAM_QW_ADDR_WID + 3   // 256 quatern word * 8bank
            )(
           //--------------------clk / rst_n ---------------------//
            input                                               clk                       ,
            input                                               rst_n                     ,
            //--------------------input addr info ------------------------//
            input            [LSU_SYS_ONE_BANK_ADDR_WID-1:0 ]            lsu_sys_one_bank_qw_addr               ,//1/2  placed up level
            input            [LB_SYS_ONE_RAM_QW_ADDR_WID-1:0]            lsu_sys_one_ram_qw_base_addr           ,
            input            [LB_SYS_ONE_RAM_QW_ADDR_WID  :0]            lsu_sys_one_ram_qw_range               ,  //10bit
            //-------------------addr section config--------------------//
            input            [LSU_SYS_ONE_BANK_ADDR_WID-1:0 ]          l1b_sys_qw_addr_section_one_2nd    , //1/4 
            input            [LSU_SYS_ONE_BANK_ADDR_WID-2:0 ]          l1b_sys_qw_addr_section_one_4th    , //1/4 
            input            [LSU_SYS_ONE_BANK_ADDR_WID-3:0 ]          l1b_sys_qw_addr_section_one_8th    , //1/8 
            //----------------------------------------------------------//
            output   reg     [LB_HALF_ONE_BANK_CS_ADDR_WID-1:0]               l1b_sys_one_bank_cs_addr        , //8  ram
            output   reg     [LB_SYS_ONE_RAM_QW_ADDR_WID-1:0]            l1b_sys_one_ram_qw_addr         

            );


            reg                 [LSU_SYS_ONE_BANK_ADDR_WID-1:0 ]   lsu_sys_one_bank_qw_addr_one_2nd   ;
            reg                 [LSU_SYS_ONE_BANK_ADDR_WID-2:0 ]   lsu_sys_one_bank_qw_addr_one_4th   ;
            reg                 [LSU_SYS_ONE_BANK_ADDR_WID-3:0 ]   lsu_sys_one_bank_qw_addr_one_8th  ;



           //l1b_sys_one_bank_cs_addr[2]
           always_comb begin
            l1b_sys_one_bank_cs_addr[LB_HALF_ONE_BANK_CS_ADDR_WID-1] =  lsu_sys_one_bank_qw_addr >= l1b_sys_qw_addr_section_one_2nd  ? 1 : 0;
            lsu_sys_one_bank_qw_addr_one_2nd = l1b_sys_one_bank_cs_addr[LB_HALF_ONE_BANK_CS_ADDR_WID-1] ?  lsu_sys_one_bank_qw_addr - l1b_sys_qw_addr_section_one_2nd : lsu_sys_one_bank_qw_addr;
           end

            //l1b_sys_one_bank_cs_addr[1]
           always_comb begin
            l1b_sys_one_bank_cs_addr[LB_HALF_ONE_BANK_CS_ADDR_WID-2] = lsu_sys_one_bank_qw_addr_one_2nd >= l1b_sys_qw_addr_section_one_4th  ? 1 : 0;
            lsu_sys_one_bank_qw_addr_one_4th = l1b_sys_one_bank_cs_addr[LB_HALF_ONE_BANK_CS_ADDR_WID-2] ? lsu_sys_one_bank_qw_addr_one_2nd - l1b_sys_qw_addr_section_one_4th : lsu_sys_one_bank_qw_addr_one_2nd;
           end

            //l1b_sys_one_bank_cs_addr[0]
           always_comb begin
            l1b_sys_one_bank_cs_addr[LB_HALF_ONE_BANK_CS_ADDR_WID-3] = lsu_sys_one_bank_qw_addr_one_4th >= l1b_sys_qw_addr_section_one_8th  ? 1 : 0;
            lsu_sys_one_bank_qw_addr_one_8th = l1b_sys_one_bank_cs_addr[LB_HALF_ONE_BANK_CS_ADDR_WID-3] ? lsu_sys_one_bank_qw_addr_one_4th -  l1b_sys_qw_addr_section_one_8th : lsu_sys_one_bank_qw_addr_one_4th;
           end

           

            always_comb begin
                    l1b_sys_one_ram_qw_addr  = lsu_sys_one_ram_qw_base_addr +  (lsu_sys_one_bank_qw_addr - l1b_sys_one_bank_cs_addr * lsu_sys_one_ram_qw_range);
            end
endmodule


//32 rams,

//           //l1b_sys_one_bank_cs_addr[3]
//           always_comb begin
//            l1b_sys_one_bank_cs_addr[LB_HALF_ONE_BANK_CS_ADDR_WID-1] =  lsu_sys_one_bank_qw_addr >= l1b_sys_qw_addr_section_one_4th  ? 1 : 0;
//            lsu_sys_one_bank_qw_addr_one_4th = l1b_sys_one_bank_cs_addr[LB_HALF_ONE_BANK_CS_ADDR_WID-1] ?  lsu_sys_one_bank_qw_addr - l1b_sys_qw_addr_section_one_4th : lsu_sys_one_bank_qw_addr;
//           end
//
//            //l1b_sys_one_bank_cs_addr[2]
//           always_comb begin
//            l1b_sys_one_bank_cs_addr[LB_HALF_ONE_BANK_CS_ADDR_WID-2] = lsu_sys_one_bank_qw_addr_one_4th >= l1b_sys_qw_addr_section_one_8th  ? 1 : 0;
//            lsu_sys_one_bank_qw_addr_one_8th = l1b_sys_one_bank_cs_addr[LB_HALF_ONE_BANK_CS_ADDR_WID-2] ? lsu_sys_one_bank_qw_addr_one_4th - l1b_sys_qw_addr_section_one_8th : lsu_sys_one_bank_qw_addr_one_4th;
//           end
//
//            //l1b_sys_one_bank_cs_addr[1]
//           always_comb begin
//            l1b_sys_one_bank_cs_addr[LB_HALF_ONE_BANK_CS_ADDR_WID-3] = lsu_sys_one_bank_qw_addr_one_8th >= l1b_sys_qw_addr_section_one_16th  ? 1 : 0;
//            lsu_sys_one_bank_qw_addr_one_16th = l1b_sys_one_bank_cs_addr[LB_HALF_ONE_BANK_CS_ADDR_WID-3] ? lsu_sys_one_bank_qw_addr_one_8th -  l1b_sys_qw_addr_section_one_16th : lsu_sys_one_bank_qw_addr_one_8th;
//           end
//
//            //l1b_sys_one_bank_cs_addr[0]
//           always_comb begin
//            l1b_sys_one_bank_cs_addr[LB_HALF_ONE_BANK_CS_ADDR_WID-4] = lsu_sys_one_bank_qw_addr_one_16th >= l1b_sys_qw_addr_section_one_32nd  ? 1 : 0;
//           end
//
//
//           
//
//            always_comb begin
//                if(lsu_sys_one_ram_qw_range == 0)  //all addr can use if range = 0
//                    l1b_sys_one_ram_qw_addr  = lsu_sys_one_bank_qw_addr[LSU_SYS_ONE_BANK_ADDR_WID-4:0];
//                else
//                    l1b_sys_one_ram_qw_addr  = lsu_sys_one_ram_qw_base_addr +  (lsu_sys_one_bank_qw_addr - l1b_sys_one_bank_cs_addr * lsu_sys_one_ram_qw_range);
//            end
