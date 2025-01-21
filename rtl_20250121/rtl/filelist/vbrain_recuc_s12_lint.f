+define+SMIC12

// stdcell
-gateslib /tech_lib/s12/stdcell/7P5T/SCC12NSFE_96SDB_7P5TC16_LVT_V1P1D/Liberty/0.8v/scc12nsfe_96sdb_7p5tc16_lvt_ssgs_v0p72_-40c_ccs.lib
-gateslib /tech_lib/s12/stdcell/7P5T/SCC12NSFE_96SDB_7P5TC24_RVT_V1P1D/Liberty/0.8v/scc12nsfe_96sdb_7p5tc24_rvt_ssgs_v0p72_-40c_ccs.lib

// DW
+libext+.v+.V+.sv+.vh+.svh
-y /tools/eda/synopsys/syn/O-2018.06-SP5-5/dw//dw01/src_ver/
-y /tools/eda/synopsys/syn/O-2018.06-SP5-5/dw//dw02/src_ver/
-y /tools/eda/synopsys/syn/O-2018.06-SP5-5/dw//dw03/src_ver/
-y /tools/eda/synopsys/syn/O-2018.06-SP5-5/dw//dw04/src_ver/
-y /tools/eda/synopsys/syn/O-2018.06-SP5-5/dw//dw05/src_ver/
-y /tools/eda/synopsys/syn/O-2018.06-SP5-5/dw//dw06/src_ver/
+incdir+/tools/eda/synopsys/syn/O-2018.06-SP5-5/dw//dw01/src_ver/
+incdir+/tools/eda/synopsys/syn/O-2018.06-SP5-5/dw//dw02/src_ver/
+incdir+/tools/eda/synopsys/syn/O-2018.06-SP5-5/dw//dw03/src_ver/
+incdir+/tools/eda/synopsys/syn/O-2018.06-SP5-5/dw//dw04/src_ver/
+incdir+/tools/eda/synopsys/syn/O-2018.06-SP5-5/dw//dw05/src_ver/
+incdir+/tools/eda/synopsys/syn/O-2018.06-SP5-5/dw//dw06/src_ver/

+incdir+/home/linyx/project/ReCUC/rtl/include/

// mem
/home/luguangyang/project/ReCUC/lib/mem_lib_s12/s12_s1pram32x32/s12_s1pram32x32_stub.v  
/home/luguangyang/project/ReCUC/lib/mem_lib_s12/s12_s1pram16x64/s12_s1pram16x64_stub.v  
/home/luguangyang/project/ReCUC/lib/mem_lib_s12/s12_s1pram64x32/s12_s1pram64x32_stub.v 
/home/luguangyang/project/ReCUC/lib/mem_lib_s12/s12_s1pram64x144/s12_s1pram64x144_stub.v 
/home/luguangyang/project/ReCUC/lib/mem_lib_s12/s12_s1pram64x288/s12_s1pram64x288_stub.v 
/home/luguangyang/project/ReCUC/lib/mem_lib_s12/s12_s1pram128x32/s12_s1pram128x32_stub.v 
/home/luguangyang/project/ReCUC/lib/mem_lib_s12/s12_s1pram256x128/s12_s1pram256x128_stub.v 
/home/luguangyang/project/ReCUC/lib/mem_lib_s12/s12_s1pram512x32/s12_s1pram512x32_stub.v 
/home/luguangyang/project/ReCUC/lib/mem_lib_s12/s12_s1pram512x128/s12_s1pram512x128_stub.v 

-f /home/linyx/project/ReCUC/rtl/filelist/cu_node.f
-f /home/linyx/project/ReCUC/rtl/filelist/vbrain_recuc.f