// +define+SMIC12


//---------------data dma------------------
../idma_sync_256b_top.v
../idma_sync_256b_rd_channel.v
../idma_sync_256b_wr_channel.v
../idma_sync_256b_wdata_proc.sv
../idma_sync_256b_wr_if.sv
../idma_sync_256b_rd_if.sv
../idma_sync_256b_addr_manager.sv
../fifo_with_flush.v
../idma_data_noc_if.sv
../idma_data_noc_regfile.v
../idma_data_noc_base_addr_regfile.v
../idma_data_noc_kernel.sv
../idma_data_noc_top.sv
../axi_data_fifo_sync_256b.v
../axi_addr_cross4k_256b.v
../idma_data_rgb2rgba_256b.v
../idma_data_align_256b.v
../../idma_inoc/idma_rd_sync_128b/fifo_sync_sram.v
../../idma_inoc/idma_rd_sync_128b/fifo_sync_tpsram.v
../../idma_inoc/idma_rd_sync_128b/axi_addr_fifo_sync.v
../../idma/idma_resi_raddr_gen.sv
../../idma_inoc/idma_rd_sync_128b/axi_rdata_proc.sv

/home/linyx/project/ReCUC/rtl/common/ram_wrapper/std_tpram64x288.v
/home/linyx/project/ReCUC/rtl/common/ram_wrapper/std_tpram64x144.v
/home/linyx/project/ReCUC/rtl/common/ram_wrapper/std_tpram32x32.v


// stdcell
/home/linyx/project/ReCUC/rtl/common/stdcell/ts_stdcell.v

// SMIC12
// /tech_lib/s12/stdcell/7P5T/SCC12NSFE_96SDB_7P5TC24_RVT_V1P1D/Verilog/scc12nsfe_96sdb_7p5tc24_rvt.v
// /home/linyx/project/mem/s12_mem/compout/views/s12_tpram64x144/tt0p8v25c/s12_tpram64x144.v
// /home/linyx/project/ReCUC/lib/mem_lib_s12/s12_s1pram32x32/tt0p8v25c/s12_s1pram32x32.v

// T22
/tech_lib/t22/TSMCHOME/digital/Front_End/verilog/tcbn22ulpbwp7t30p140_100a/tcbn22ulpbwp7t30p140.v
/home/linyx/project/ReCUC/lib/mem_lib/tsmc_t22hpcp_hvt_uhd_r2p64x144/VERILOG/tsmc_t22hpcp_hvt_uhd_r2p64x144_tt1v85c.v
/home/linyx/project/ReCUC/lib/mem_lib/tsmc_t22hpcp_hvt_uhd_s1p32x32/VERILOG/tsmc_t22hpcp_hvt_uhd_s1p32x32_tt1v85c.v

// common
../../common/pipeline/fwd_pipe.v
../../common/pipeline/bwd_pipe.v
../../common/pipeline/fwdbwd_pipe.v
../../idma_inoc/fifo.v
