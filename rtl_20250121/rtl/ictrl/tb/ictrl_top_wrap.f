// common
../../common/pipeline/fwd_pipe.v
../../common/pipeline/bwd_pipe.v
../../common/pipeline/fwdbwd_pipe.v

// sram
../std_tpram32x32.v
../std_tpram64x144.v
../sram_1024x128b.v

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
../ictrl_regfile.v
../ictrl_axi_config.sv
../ictrl_kernel.sv
../ictrl_dma_read_to_ibuffer.v
../ictrl_ibuffer_read_to_noc.v
../ictrl_send_recv_flit.sv
../ibuffer.v
../ictrl_ibuffer_arbiter.v
../ictrl_top.sv
../ictrl_top_wrap.sv

// dma
../../idma_rd_sync_128b/idma_rd_sync_top.v
../../idma_rd_sync_128b/idma_rd_sync_resi_raddr_gen.sv
../../idma_rd_sync_128b/axi_addr_fifo_sync.v
../../idma_rd_sync_128b/axi_data_fifo_sync.v
../../idma_rd_sync_128b/axi_rd_if.sv
../../idma_rd_sync_128b/axi_rdata_proc.sv
../../idma_rd_sync_128b/axi_addr_cross4k.sv
../../idma_rd_sync_128b/axi_addr_manager.sv
../../idma_rd_sync_128b/fifo_sync_sram.v
