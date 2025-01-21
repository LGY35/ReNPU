//sram
/home/linyx/project/ReCUC/rtl/common/ram_wrapper/std_spram512x128.v
/home/linyx/project/ReCUC/rtl/common/ram_wrapper/std_tpram64x144.v
/home/linyx/project/ReCUC/rtl/common/ram_wrapper/std_tpram64x288.v
/home/linyx/project/ReCUC/rtl/common/ram_wrapper/std_tpram32x32.v
/home/linyx/project/ReCUC/rtl/common/ram_wrapper/std_spram1024x128b.v

//----common---
/home/linyx/project/ReCUC/rtl/common/stdcell/ts_stdcell.v
/home/linyx/project/ReCUC/rtl/common/handshake/datapath_dst_mux2.sv
/home/linyx/project/ReCUC/rtl/common/handshake/datapath_src_mux2.sv

//---noc--
/home/linyx/project/ReCUC/rtl/noc/arb_rr.sv
/home/linyx/project/ReCUC/rtl/noc/noc_buffer.sv
/home/linyx/project/ReCUC/rtl/noc/noc_mux.sv
/home/linyx/project/ReCUC/rtl/noc/noc_mesh.sv
/home/linyx/project/ReCUC/rtl/noc/noc_router_fbpipe.sv
/home/linyx/project/ReCUC/rtl/noc/noc_router_input.sv
/home/linyx/project/ReCUC/rtl/noc/noc_router_lookup_m.sv
/home/linyx/project/ReCUC/rtl/noc/noc_router_lookup_slice.sv
/home/linyx/project/ReCUC/rtl/noc/noc_router_lookup.sv
/home/linyx/project/ReCUC/rtl/noc/noc_router_output.sv
/home/linyx/project/ReCUC/rtl/noc/noc_router.sv
/home/linyx/project/ReCUC/rtl/noc/noc_vchannel_mux.sv
/home/linyx/project/ReCUC/rtl/noc/noc_pchannel_fbpipe.sv

//--data dma--
/home/linyx/project/ReCUC/rtl/idma_data_noc/idma_sync_256b_top.v
/home/linyx/project/ReCUC/rtl/idma_data_noc/idma_sync_256b_rd_channel.v
/home/linyx/project/ReCUC/rtl/idma_data_noc/idma_sync_256b_wr_channel.v
/home/linyx/project/ReCUC/rtl/idma_data_noc/idma_sync_256b_wdata_proc.sv
/home/linyx/project/ReCUC/rtl/idma_data_noc/idma_sync_256b_wr_if.sv
/home/linyx/project/ReCUC/rtl/idma_data_noc/idma_sync_256b_rd_if.sv
/home/linyx/project/ReCUC/rtl/idma_data_noc/idma_sync_256b_addr_manager.sv
/home/linyx/project/ReCUC/rtl/idma_data_noc/axi_addr_cross4k_256b.v
/home/linyx/project/ReCUC/rtl/idma_data_noc/fifo_with_flush.v
/home/linyx/project/ReCUC/rtl/idma_data_noc/idma_data_noc_if.sv
/home/linyx/project/ReCUC/rtl/idma_data_noc/idma_data_noc_regfile.v
/home/linyx/project/ReCUC/rtl/idma_data_noc/idma_data_noc_base_addr_regfile.v
/home/linyx/project/ReCUC/rtl/idma_data_noc/idma_data_noc_kernel.sv
/home/linyx/project/ReCUC/rtl/idma_data_noc/idma_data_noc_top.sv
/home/linyx/project/ReCUC/rtl/idma_data_noc/axi_data_fifo_sync_256b.v
/home/linyx/project/ReCUC/rtl/idma/idma_resi_raddr_gen.sv
/home/linyx/project/ReCUC/rtl/idma_data_noc/idma_data_rgb2rgba_256b.v
/home/linyx/project/ReCUC/rtl/idma_data_noc/idma_data_align_256b.v

//common
/home/linyx/project/ReCUC/rtl/common/pipeline/fwd_pipe.v
/home/linyx/project/ReCUC/rtl/common/pipeline/bwd_pipe.v
/home/linyx/project/ReCUC/rtl/common/pipeline/fwdbwd_pipe.v

//--ictrl dma
// axi
/home/linyx/project/ReCUC/rtl/idma_inoc/axi_ar_buffer.v
/home/linyx/project/ReCUC/rtl/idma_inoc/axi_aw_buffer.v
/home/linyx/project/ReCUC/rtl/idma_inoc/axi_b_buffer.v
/home/linyx/project/ReCUC/rtl/idma_inoc/axi_r_buffer.v
/home/linyx/project/ReCUC/rtl/idma_inoc/axi_w_buffer.v
/home/linyx/project/ReCUC/rtl/idma_inoc/axi2apb.sv
/home/linyx/project/ReCUC/rtl/idma_inoc/axi_to_mem.v
//ictrl
/home/linyx/project/ReCUC/rtl/idma_inoc/fifo.v
/home/linyx/project/ReCUC/rtl/idma_inoc/idma_inoc_regfile.v
/home/linyx/project/ReCUC/rtl/idma_inoc/idma_inoc_interface.sv
/home/linyx/project/ReCUC/rtl/idma_inoc/idma_write_ibuffer.v
/home/linyx/project/ReCUC/rtl/idma_inoc/idma_inoc_rd_ibuffer.v
/home/linyx/project/ReCUC/rtl/idma_inoc/idma_inoc_control.sv
/home/linyx/project/ReCUC/rtl/idma_inoc/idma_inoc_ibuffer_arbiter.v
/home/linyx/project/ReCUC/rtl/idma_inoc/ibuffer.v
/home/linyx/project/ReCUC/rtl/idma_inoc/idma_inoc_top.sv
//dma
/home/linyx/project/ReCUC/rtl/idma_inoc/idma_rd_sync_128b/fifo_sync_sram.v
/home/linyx/project/ReCUC/rtl/idma_inoc/idma_rd_sync_128b/fifo_sync_tpsram.v
/home/linyx/project/ReCUC/rtl/idma_inoc/idma_rd_sync_128b/axi_addr_fifo_sync.v
/home/linyx/project/ReCUC/rtl/idma_inoc/idma_rd_sync_128b/axi_data_fifo_sync_128b.v
/home/linyx/project/ReCUC/rtl/idma_inoc/idma_rd_sync_128b/idma_rd_sync_top.v
/home/linyx/project/ReCUC/rtl/idma_inoc/idma_rd_sync_128b/idma_rd_sync_resi_raddr_gen.sv
/home/linyx/project/ReCUC/rtl/idma_inoc/idma_rd_sync_128b/axi_rd_if.sv
/home/linyx/project/ReCUC/rtl/idma_inoc/idma_rd_sync_128b/axi_rdata_proc.sv
/home/linyx/project/ReCUC/rtl/idma_inoc/idma_rd_sync_128b/axi_addr_cross4k.sv
/home/linyx/project/ReCUC/rtl/idma_inoc/idma_rd_sync_128b/axi_addr_manager.sv


/home/linyx/project/ReCUC/rtl/recuc/recuc.sv
/home/linyx/project/ReCUC/rtl/recuc/cluster_apb_decoder.v
/home/linyx/project/ReCUC/rtl/recuc/vbrain_recuc.sv