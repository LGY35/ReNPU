// +define+FPGA
// +define+SMIC12

// stdcell
/home/linyx/project/ReCUC/rtl/common/stdcell/ts_stdcell.v
// T22
/tech_lib/t22/TSMCHOME/digital/Front_End/verilog/tcbn22ulpbwp7t30p140_100a/tcbn22ulpbwp7t30p140.v
/home/linyx/project/ReCUC/lib/mem_lib/tsmc_t22hpcp_hvt_uhd_r2p64x144/VERILOG/tsmc_t22hpcp_hvt_uhd_r2p64x144_tt1v85c.v
/home/linyx/project/ReCUC/lib/mem_lib/tsmc_t22hpcp_hvt_uhd_s1p32x32/VERILOG/tsmc_t22hpcp_hvt_uhd_s1p32x32_tt0p9v25c.v
/home/linyx/project/ReCUC/lib/mem_lib/tsmc_t22hpcp_hvt_uhd_s1p512x128/VERILOG/tsmc_t22hpcp_hvt_uhd_s1p512x128_tt1v25c.v
/home/linyx/project/ReCUC/lib/mem_lib/tsmc_t22hpcp_hvt_uhd_s1p512x128e/VERILOG/tsmc_t22hpcp_hvt_uhd_s1p512x128e_ffg0p99v0c.v

// SMIC12
// /tech_lib/s12/stdcell/7P5T/SCC12NSFE_96SDB_7P5TC24_RVT_V1P1D/Verilog/scc12nsfe_96sdb_7p5tc24_rvt.v
// /home/linyx/project/mem/s12_mem/compout/views/s12_tpram64x144/tt0p8v25c/s12_tpram64x144.v
// /home/linyx/project/ReCUC/lib/mem_lib_s12/s12_s1pram32x32/tt0p8v25c/s12_s1pram32x32.v
// /home/linyx/project/ReCUC/lib/mem_lib_s12/s12_s1pram512x128/tt0p8v25c/s12_s1pram512x128.v

// common
../../common/pipeline/fwd_pipe.v
../../common/pipeline/bwd_pipe.v
../../common/pipeline/fwdbwd_pipe.v

// sram
../../common/ram_wrapper/std_tpram32x32.v
../../common/ram_wrapper/std_tpram64x144.v
../../common/ram_wrapper/std_spram512x128.v
../../common/ram_wrapper/std_spram1024x128b.v




// axi
../axi_ar_buffer.v
../axi_aw_buffer.v
../axi_b_buffer.v
../axi_r_buffer.v
../axi_w_buffer.v
../axi2apb.sv
../axi_to_mem.v


// ictrl
../fifo.v
../arb_rr.sv
../idma_inoc_regfile.v
../idma_inoc_interface.sv
../idma_write_ibuffer.v
../idma_inoc_rd_ibuffer.v
../idma_inoc_control.sv
../idma_inoc_ibuffer_arbiter.v
../ibuffer.v
../idma_inoc_top.sv

// dma
../idma_rd_sync_128b/idma_rd_sync_top.v
../idma_rd_sync_128b/idma_rd_sync_resi_raddr_gen.sv
../idma_rd_sync_128b/axi_addr_fifo_sync.v
../idma_rd_sync_128b/axi_data_fifo_sync_128b.v
../idma_rd_sync_128b/axi_rd_if.sv
../idma_rd_sync_128b/axi_rdata_proc.sv
../idma_rd_sync_128b/axi_addr_cross4k.sv
../idma_rd_sync_128b/axi_addr_manager.sv
../idma_rd_sync_128b/fifo_sync_sram.v
../idma_rd_sync_128b/fifo_sync_tpsram.v
