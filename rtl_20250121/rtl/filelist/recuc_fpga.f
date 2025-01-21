+define+FPGA
+incdir+${PRJ_DIR}/rtl/include/
+libext+.v+.V+.sv+.vh+.svh
-y /tools/eda/synopsys/syn/O-2018.06-SP5-5/dw/dw01/src_ver/
-y /tools/eda/synopsys/syn/O-2018.06-SP5-5/dw/dw02/src_ver/
-y /tools/eda/synopsys/syn/O-2018.06-SP5-5/dw/dw03/src_ver/
-y /tools/eda/synopsys/syn/O-2018.06-SP5-5/dw/dw04/src_ver/
-y /tools/eda/synopsys/syn/O-2018.06-SP5-5/dw/dw05/src_ver/
-y /tools/eda/synopsys/syn/O-2018.06-SP5-5/dw/dw06/src_ver/
+incdir+/tools/eda/synopsys/syn/O-2018.06-SP5-5/dw/sim_ver/
+incdir+/tools/eda/synopsys/syn/O-2018.06-SP5-5/dw/dw01/src_ver/
+incdir+/tools/eda/synopsys/syn/O-2018.06-SP5-5/dw/dw02/src_ver/
+incdir+/tools/eda/synopsys/syn/O-2018.06-SP5-5/dw/dw03/src_ver/
+incdir+/tools/eda/synopsys/syn/O-2018.06-SP5-5/dw/dw04/src_ver/
+incdir+/tools/eda/synopsys/syn/O-2018.06-SP5-5/dw/dw05/src_ver/
+incdir+/tools/eda/synopsys/syn/O-2018.06-SP5-5/dw/dw06/src_ver/

// common
${PRJ_DIR}/rtl/common/pipeline/fwd_pipe.v
${PRJ_DIR}/rtl/common/pipeline/bwd_pipe.v
${PRJ_DIR}/rtl/common/pipeline/fwdbwd_pipe.v
${PRJ_DIR}/rtl/common/handshake/datapath_dst_mux2.sv
${PRJ_DIR}/rtl/common/handshake/datapath_src_mux2.sv
${PRJ_DIR}/rtl/common/stdcell/ts_stdcell.v

//sram
${PRJ_DIR}/rtl/common/ram_wrapper/ram_fpga.v
${PRJ_DIR}/rtl/common/ram_wrapper/std_tpram64x144.v
${PRJ_DIR}/rtl/common/ram_wrapper/std_tpram64x288.v
${PRJ_DIR}/rtl/common/ram_wrapper/std_tpram32x32.v
${PRJ_DIR}/rtl/common/ram_wrapper/std_spram1024x128b.v
${PRJ_DIR}/rtl/common/ram_wrapper/std_spram512x128.v
${PRJ_DIR}/rtl/common/ram_wrapper/std_spram512x32.v
${PRJ_DIR}/rtl/common/ram_wrapper/std_spram128x32.v

${PRJ_DIR}/rtl/dram/dram_top.sv
${PRJ_DIR}/rtl/dram/dcache_ctrl.sv

//-----------------------core-----------------------------

${PRJ_DIR}/rtl/riscv_core/riscv_if_stage.sv
${PRJ_DIR}/rtl/riscv_core/riscv_prefetch_buffer.sv
${PRJ_DIR}/rtl/riscv_core/riscv_compressed_decoder.sv
${PRJ_DIR}/rtl/riscv_core/riscv_hwloop_controller.sv
${PRJ_DIR}/rtl/riscv_core/riscv_fetch_fifo.sv

${PRJ_DIR}/rtl/riscv_core/riscv_id_stage.sv
${PRJ_DIR}/rtl/riscv_core/riscv_register_file.sv
${PRJ_DIR}/rtl/riscv_core/riscv_decoder.sv
${PRJ_DIR}/rtl/riscv_core/npu_first_decoder.sv
${PRJ_DIR}/rtl/riscv_core/riscv_controller.sv
${PRJ_DIR}/rtl/riscv_core/riscv_int_controller.sv
${PRJ_DIR}/rtl/riscv_core/riscv_hwloop_regs.sv

${PRJ_DIR}/rtl/riscv_core/riscv_ex_stage.sv
${PRJ_DIR}/rtl/riscv_core/riscv_alu.sv
${PRJ_DIR}/rtl/riscv_core/riscv_alu_div.sv
${PRJ_DIR}/rtl/riscv_core/riscv_alu_div_ctrl.sv
${PRJ_DIR}/rtl/riscv_core/riscv_mult.sv

${PRJ_DIR}/rtl/riscv_core/riscv_load_store_unit.sv
${PRJ_DIR}/rtl/riscv_core/riscv_cs_registers.sv
${PRJ_DIR}/rtl/riscv_core/riscv_core.sv
${PRJ_DIR}/rtl/mu/accel_dispatch.sv
${PRJ_DIR}/rtl/mu/accel_decode.sv
${PRJ_DIR}/rtl/mu/accel_sequence_ctrl.sv
${PRJ_DIR}/rtl/mu/cub_alu_fetch.sv
${PRJ_DIR}/rtl/mu/cub_alu_pre_decode.sv
${PRJ_DIR}/rtl/mu/cub_alu_instr_ram.sv
${PRJ_DIR}/rtl/mu/cub_alu_loop_controller.sv
${PRJ_DIR}/rtl/mu/mu_top.sv
${PRJ_DIR}/rtl/CU_bank_alu/cub_alu_top.sv
${PRJ_DIR}/rtl/CU_bank_alu/cub_id_stage.sv
${PRJ_DIR}/rtl/CU_bank_alu/cub_decoder.sv
${PRJ_DIR}/rtl/CU_bank_alu/cub_general_regfile.sv
${PRJ_DIR}/rtl/CU_bank_alu/cub_cs_registers.sv
${PRJ_DIR}/rtl/CU_bank_alu/cub_scache.sv
${PRJ_DIR}/rtl/CU_bank_alu/cub_mem_addr_ctrl.sv
${PRJ_DIR}/rtl/CU_bank_alu/scache_cflow_ctrl.sv
${PRJ_DIR}/rtl/CU_bank_alu/cub_mult.sv
${PRJ_DIR}/rtl/CU_bank_alu/cub_arithmetic.sv
${PRJ_DIR}/rtl/CU_bank_alu/cub_activ.sv
${PRJ_DIR}/rtl/CU_bank_alu/cub_pooling.sv
${PRJ_DIR}/rtl/CU_bank_alu/cub_crossbar.sv
${PRJ_DIR}/rtl/vector_core/Cram_16x128.v
${PRJ_DIR}/rtl/vector_core/Cram_ctrl.v
${PRJ_DIR}/rtl/vector_core/pe_accu.v
${PRJ_DIR}/rtl/vector_core/pe_base_unit.v
${PRJ_DIR}/rtl/vector_core/pe_mac_array.v
${PRJ_DIR}/rtl/vector_core/psum_out_adder.v
${PRJ_DIR}/rtl/vector_core/Routing_array.v
${PRJ_DIR}/rtl/vector_core/Sparse_detect.v
${PRJ_DIR}/rtl/vector_core/Vector_core.v
${PRJ_DIR}/rtl/vector_core/Vector_crossbar.v
${PRJ_DIR}/rtl/vector_core/Weight_reg.v
${PRJ_DIR}/rtl/l1b/l1b_bank.sv
${PRJ_DIR}/rtl/l1b/l1b_ch_ram_wrapper.sv
${PRJ_DIR}/rtl/l1b/l1b_ch.sv
${PRJ_DIR}/rtl/l1b/l1b_core.sv
${PRJ_DIR}/rtl/l1b/l1b_sys.sv
${PRJ_DIR}/rtl/Tcache/conv3d_broadcast_fmap.sv
${PRJ_DIR}/rtl/Tcache/l1b_cache_addr_map_table.sv
${PRJ_DIR}/rtl/Tcache/l1b_cache_qw_addr_dichotomie_comp.sv
${PRJ_DIR}/rtl/Tcache/system_lsu.sv
${PRJ_DIR}/rtl/Tcache/tcache_core.sv
${PRJ_DIR}/rtl/Tcache/tcache_dfifo.sv
${PRJ_DIR}/rtl/Tcache/tcache_sys.sv
${PRJ_DIR}/rtl/Tcache/sys_lsu.sv
${PRJ_DIR}/rtl/Tcache/hid_lsu.sv
${PRJ_DIR}/rtl/Tcache/trans_latchram256x16.sv
${PRJ_DIR}/rtl/Tcache/iob_sw.sv
${PRJ_DIR}/rtl/common/ram_wrapper/std_spram256x128_b16.v
${PRJ_DIR}/rtl/common/ram_wrapper/std_spram16x64.v
${PRJ_DIR}/rtl/common/ram_wrapper/std_spram32x32.v
${PRJ_DIR}/rtl/common/ram_wrapper/std_spram64x32.v
${PRJ_DIR}/rtl/common/ram_wrapper/std_spram64x16.v
${PRJ_DIR}/rtl/common/ram_wrapper/std_spram64x32_b4.v

${PRJ_DIR}/rtl/CU_bank_top/CU_bank_top.sv
${PRJ_DIR}/rtl/CU_core_top/CU_core_top.sv
${PRJ_DIR}/rtl/CU_sfu/sfu.v

//--------------------noc---------------------
${PRJ_DIR}/rtl/noc/arb_rr.sv
${PRJ_DIR}/rtl/noc/noc_buffer.sv
${PRJ_DIR}/rtl/noc/noc_mux.sv
${PRJ_DIR}/rtl/noc/noc_mesh.sv
${PRJ_DIR}/rtl/noc/noc_router_fbpipe.sv
${PRJ_DIR}/rtl/noc/noc_router_input.sv
${PRJ_DIR}/rtl/noc/noc_router_lookup_m.sv
${PRJ_DIR}/rtl/noc/noc_router_lookup_slice.sv
${PRJ_DIR}/rtl/noc/noc_router_lookup.sv
${PRJ_DIR}/rtl/noc/noc_router_output.sv
${PRJ_DIR}/rtl/noc/noc_router.sv
${PRJ_DIR}/rtl/noc/noc_vchannel_mux.sv
${PRJ_DIR}/rtl/noc/noc_pchannel_fbpipe.sv


//------------------------dnoc----------------------
${PRJ_DIR}/rtl/dnoc/dnoc_itf_ctr.sv
${PRJ_DIR}/rtl/dnoc/dnoc_itf_core_rd.sv
${PRJ_DIR}/rtl/dnoc/dnoc_core_rd_backpress.sv
${PRJ_DIR}/rtl/dnoc/dnoc_itf_core_wr.sv
${PRJ_DIR}/rtl/dnoc/dnoc_itf_dma_rd.sv
${PRJ_DIR}/rtl/dnoc/dnoc_itf_dma_wr.sv
${PRJ_DIR}/rtl/dnoc/dnoc_itf_in_c_channel.sv
${PRJ_DIR}/rtl/dnoc/dnoc_itf_in_d_channel.sv
${PRJ_DIR}/rtl/dnoc/dnoc_itf_out_c_channel.sv
${PRJ_DIR}/rtl/dnoc/dnoc_itf_out_d_channel.sv
${PRJ_DIR}/rtl/dnoc/dnoc_itf_pingpong.sv
${PRJ_DIR}/rtl/dnoc/L2_dmem_bank.sv
${PRJ_DIR}/rtl/dnoc/L2_dmem.sv
${PRJ_DIR}/rtl/dnoc/sync_collect.sv
${PRJ_DIR}/rtl/dnoc/addr_mu.sv
${PRJ_DIR}/rtl/dnoc/addr_mu_ns.sv
${PRJ_DIR}/rtl/dnoc/pad_addr_mu.sv
${PRJ_DIR}/rtl/dnoc/cu_node.sv
${PRJ_DIR}/rtl/dnoc/pc_debug.sv
${PRJ_DIR}/rtl/dnoc/ram_req_fifo.sv


//----------------ibus-------------------
${PRJ_DIR}/rtl/ibus/find_not_valid.sv
${PRJ_DIR}/rtl/ibus/plru.sv
${PRJ_DIR}/rtl/ibus/icache_refill_ctr.sv
${PRJ_DIR}/rtl/ibus/stream_buffer.sv
${PRJ_DIR}/rtl/ibus/tag_reg8x10.sv
${PRJ_DIR}/rtl/ibus/pri_icache.sv
${PRJ_DIR}/rtl/ibus/icache_L1_L2_itf.sv

//----------------------node top------------------
${PRJ_DIR}/rtl/CU_core_top/irq_ctr.sv
${PRJ_DIR}/rtl/CU_core_top/CU_core_wrapper.sv


//--data dma--
${PRJ_DIR}/rtl/idma_data_noc/idma_sync_256b_top.v
${PRJ_DIR}/rtl/idma_data_noc/idma_sync_256b_rd_channel.v
${PRJ_DIR}/rtl/idma_data_noc/idma_sync_256b_wr_channel.v
${PRJ_DIR}/rtl/idma_data_noc/idma_sync_256b_wdata_proc.sv
${PRJ_DIR}/rtl/idma_data_noc/idma_sync_256b_wr_if.sv
${PRJ_DIR}/rtl/idma_data_noc/idma_sync_256b_rd_if.sv
${PRJ_DIR}/rtl/idma_data_noc/idma_sync_256b_addr_manager.sv
${PRJ_DIR}/rtl/idma_data_noc/axi_addr_cross4k_256b.v
${PRJ_DIR}/rtl/idma_data_noc/fifo_with_flush.v
${PRJ_DIR}/rtl/idma_data_noc/idma_data_noc_if.sv
${PRJ_DIR}/rtl/idma_data_noc/idma_data_noc_regfile.v
${PRJ_DIR}/rtl/idma_data_noc/idma_data_noc_base_addr_regfile.v
${PRJ_DIR}/rtl/idma_data_noc/idma_data_noc_kernel.sv
${PRJ_DIR}/rtl/idma_data_noc/idma_data_noc_top.sv
${PRJ_DIR}/rtl/idma_data_noc/axi_data_fifo_sync_256b.v
${PRJ_DIR}/rtl/idma_data_noc/idma_data_rgb2rgba_256b.v
${PRJ_DIR}/rtl/idma_data_noc/idma_data_align_256b.v
${PRJ_DIR}/rtl/idma/idma_resi_raddr_gen.sv


//--ictrl dma
// axi
${PRJ_DIR}/rtl/idma_inoc/axi_ar_buffer.v
${PRJ_DIR}/rtl/idma_inoc/axi_aw_buffer.v
${PRJ_DIR}/rtl/idma_inoc/axi_b_buffer.v
${PRJ_DIR}/rtl/idma_inoc/axi_r_buffer.v
${PRJ_DIR}/rtl/idma_inoc/axi_w_buffer.v
${PRJ_DIR}/rtl/idma_inoc/axi2apb.sv
${PRJ_DIR}/rtl/idma_inoc/axi_to_mem.v
//ictrl
${PRJ_DIR}/rtl/idma_inoc/fifo.v
${PRJ_DIR}/rtl/idma_inoc/idma_inoc_regfile.v
${PRJ_DIR}/rtl/idma_inoc/idma_inoc_interface.sv
${PRJ_DIR}/rtl/idma_inoc/idma_write_ibuffer.v
${PRJ_DIR}/rtl/idma_inoc/idma_inoc_rd_ibuffer.v
${PRJ_DIR}/rtl/idma_inoc/idma_inoc_control.sv
${PRJ_DIR}/rtl/idma_inoc/idma_inoc_ibuffer_arbiter.v
${PRJ_DIR}/rtl/idma_inoc/ibuffer.v
${PRJ_DIR}/rtl/idma_inoc/idma_inoc_top.sv
//dma
${PRJ_DIR}/rtl/idma_inoc/idma_rd_sync_128b/fifo_sync_sram.v
${PRJ_DIR}/rtl/idma_inoc/idma_rd_sync_128b/fifo_sync_tpsram.v
${PRJ_DIR}/rtl/idma_inoc/idma_rd_sync_128b/axi_addr_fifo_sync.v
${PRJ_DIR}/rtl/idma_inoc/idma_rd_sync_128b/axi_data_fifo_sync_128b.v
${PRJ_DIR}/rtl/idma_inoc/idma_rd_sync_128b/idma_rd_sync_top.v
${PRJ_DIR}/rtl/idma_inoc/idma_rd_sync_128b/idma_rd_sync_resi_raddr_gen.sv
${PRJ_DIR}/rtl/idma_inoc/idma_rd_sync_128b/axi_rd_if.sv
${PRJ_DIR}/rtl/idma_inoc/idma_rd_sync_128b/axi_rdata_proc.sv
${PRJ_DIR}/rtl/idma_inoc/idma_rd_sync_128b/axi_addr_cross4k.sv
${PRJ_DIR}/rtl/idma_inoc/idma_rd_sync_128b/axi_addr_manager.sv

// top
${PRJ_DIR}/rtl/recuc/recuc.sv
${PRJ_DIR}/rtl/recuc/cluster_apb_decoder.v