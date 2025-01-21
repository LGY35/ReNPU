// common
/home/linyx/project/ReCUC/rtl/common/pipeline/fwd_pipe.v
/home/linyx/project/ReCUC/rtl/common/pipeline/bwd_pipe.v
/home/linyx/project/ReCUC/rtl/common/pipeline/fwdbwd_pipe.v
/home/linyx/project/ReCUC/rtl/common/handshake/datapath_dst_mux2.sv
/home/linyx/project/ReCUC/rtl/common/handshake/datapath_src_mux2.sv
/home/linyx/project/ReCUC/rtl/common/stdcell/ts_stdcell.v

/home/linyx/project/ReCUC/rtl/common/ram_wrapper/std_spram512x128.v
/home/linyx/project/ReCUC/rtl/common/ram_wrapper/std_spram512x32.v
/home/linyx/project/ReCUC/rtl/common/ram_wrapper/std_spram128x32.v

/home/linyx/project/ReCUC/rtl/dram/dram_top.sv
/home/linyx/project/ReCUC/rtl/dram/dcache_ctrl.sv

//-----------------------core-----------------------------

/home/linyx/project/ReCUC/rtl/riscv_core/riscv_if_stage.sv
/home/linyx/project/ReCUC/rtl/riscv_core/riscv_prefetch_buffer.sv
/home/linyx/project/ReCUC/rtl/riscv_core/riscv_compressed_decoder.sv
/home/linyx/project/ReCUC/rtl/riscv_core/riscv_hwloop_controller.sv
/home/linyx/project/ReCUC/rtl/riscv_core/riscv_fetch_fifo.sv

/home/linyx/project/ReCUC/rtl/riscv_core/riscv_id_stage.sv
/home/linyx/project/ReCUC/rtl/riscv_core/riscv_register_file.sv
/home/linyx/project/ReCUC/rtl/riscv_core/riscv_decoder.sv
/home/linyx/project/ReCUC/rtl/riscv_core/npu_first_decoder.sv
/home/linyx/project/ReCUC/rtl/riscv_core/riscv_controller.sv
/home/linyx/project/ReCUC/rtl/riscv_core/riscv_int_controller.sv
/home/linyx/project/ReCUC/rtl/riscv_core/riscv_hwloop_regs.sv

/home/linyx/project/ReCUC/rtl/riscv_core/riscv_ex_stage.sv
/home/linyx/project/ReCUC/rtl/riscv_core/riscv_alu.sv
/home/linyx/project/ReCUC/rtl/riscv_core/riscv_alu_div.sv
/home/linyx/project/ReCUC/rtl/riscv_core/riscv_alu_div_ctrl.sv
/home/linyx/project/ReCUC/rtl/riscv_core/riscv_mult.sv

/home/linyx/project/ReCUC/rtl/riscv_core/riscv_load_store_unit.sv
/home/linyx/project/ReCUC/rtl/riscv_core/riscv_cs_registers.sv
/home/linyx/project/ReCUC/rtl/riscv_core/riscv_core.sv
/home/linyx/project/ReCUC/rtl/mu/accel_dispatch.sv
/home/linyx/project/ReCUC/rtl/mu/accel_decode.sv
/home/linyx/project/ReCUC/rtl/mu/accel_sequence_ctrl.sv
/home/linyx/project/ReCUC/rtl/mu/cub_alu_fetch.sv
/home/linyx/project/ReCUC/rtl/mu/cub_alu_pre_decode.sv
/home/linyx/project/ReCUC/rtl/mu/cub_alu_instr_ram.sv
/home/linyx/project/ReCUC/rtl/mu/cub_alu_loop_controller.sv
/home/linyx/project/ReCUC/rtl/mu/mu_top.sv
/home/linyx/project/ReCUC/rtl/CU_bank_alu/cub_alu_top.sv
/home/linyx/project/ReCUC/rtl/CU_bank_alu/cub_id_stage.sv
/home/linyx/project/ReCUC/rtl/CU_bank_alu/cub_decoder.sv
/home/linyx/project/ReCUC/rtl/CU_bank_alu/cub_general_regfile.sv
/home/linyx/project/ReCUC/rtl/CU_bank_alu/cub_cs_registers.sv
/home/linyx/project/ReCUC/rtl/CU_bank_alu/cub_scache.sv
/home/linyx/project/ReCUC/rtl/CU_bank_alu/cub_mem_addr_ctrl.sv
/home/linyx/project/ReCUC/rtl/CU_bank_alu/scache_cflow_ctrl.sv
/home/linyx/project/ReCUC/rtl/CU_bank_alu/cub_mult.sv
/home/linyx/project/ReCUC/rtl/CU_bank_alu/cub_arithmetic.sv
/home/linyx/project/ReCUC/rtl/CU_bank_alu/cub_activ.sv
/home/linyx/project/ReCUC/rtl/CU_bank_alu/cub_pooling.sv
/home/linyx/project/ReCUC/rtl/CU_bank_alu/cub_crossbar.sv
/home/linyx/project/ReCUC/rtl/vector_core/Cram_16x128.v
/home/linyx/project/ReCUC/rtl/vector_core/Cram_ctrl.v
/home/linyx/project/ReCUC/rtl/vector_core/pe_accu.v
/home/linyx/project/ReCUC/rtl/vector_core/pe_base_unit.v
/home/linyx/project/ReCUC/rtl/vector_core/pe_mac_array.v
/home/linyx/project/ReCUC/rtl/vector_core/psum_out_adder.v
/home/linyx/project/ReCUC/rtl/vector_core/Routing_array.v
/home/linyx/project/ReCUC/rtl/vector_core/Sparse_detect.v
/home/linyx/project/ReCUC/rtl/vector_core/Vector_core.v
/home/linyx/project/ReCUC/rtl/vector_core/Vector_crossbar.v
/home/linyx/project/ReCUC/rtl/vector_core/Weight_reg.v
/home/linyx/project/ReCUC/rtl/l1b/l1b_bank.sv
/home/linyx/project/ReCUC/rtl/l1b/l1b_ch_ram_wrapper.sv
/home/linyx/project/ReCUC/rtl/l1b/l1b_ch.sv
/home/linyx/project/ReCUC/rtl/l1b/l1b_core.sv
/home/linyx/project/ReCUC/rtl/l1b/l1b_sys.sv
/home/linyx/project/ReCUC/rtl/Tcache/conv3d_broadcast_fmap.sv
/home/linyx/project/ReCUC/rtl/Tcache/l1b_cache_addr_map_table.sv
/home/linyx/project/ReCUC/rtl/Tcache/l1b_cache_qw_addr_dichotomie_comp.sv
/home/linyx/project/ReCUC/rtl/Tcache/system_lsu.sv
/home/linyx/project/ReCUC/rtl/Tcache/tcache_core.sv
/home/linyx/project/ReCUC/rtl/Tcache/tcache_dfifo.sv
/home/linyx/project/ReCUC/rtl/Tcache/tcache_sys.sv
/home/linyx/project/ReCUC/rtl/Tcache/sys_lsu.sv
/home/linyx/project/ReCUC/rtl/Tcache/hid_lsu.sv
/home/linyx/project/ReCUC/rtl/Tcache/trans_latchram256x16.sv
/home/linyx/project/ReCUC/rtl/Tcache/iob_sw.sv
/home/linyx/project/ReCUC/rtl/common/ram_wrapper/std_spram256x128_b16.v
/home/linyx/project/ReCUC/rtl/common/ram_wrapper/std_spram16x64.v
/home/linyx/project/ReCUC/rtl/common/ram_wrapper/std_spram32x32.v
/home/linyx/project/ReCUC/rtl/common/ram_wrapper/std_spram64x32.v
/home/linyx/project/ReCUC/rtl/common/ram_wrapper/std_spram64x16.v
/home/linyx/project/ReCUC/rtl/common/ram_wrapper/std_spram64x32_b4.v

/home/linyx/project/ReCUC/rtl/CU_bank_top/CU_bank_top.sv
/home/linyx/project/ReCUC/rtl/CU_core_top/CU_core_top.sv
// /home/linyx/project/ReCUC/rtl/CU_sfu/sfu.v

//--------------------noc---------------------
/home/linyx/project/ReCUC/rtl/noc/arb_rr.sv
/home/linyx/project/ReCUC/rtl/noc/noc_vchannel_mux.sv
/home/linyx/project/ReCUC/rtl/noc/noc_pchannel_fbpipe.sv

//------------------------dnoc----------------------
/home/linyx/project/ReCUC/rtl/dnoc/dnoc_itf_ctr.sv
/home/linyx/project/ReCUC/rtl/dnoc/dnoc_itf_core_rd.sv
/home/linyx/project/ReCUC/rtl/dnoc/dnoc_core_rd_backpress.sv
/home/linyx/project/ReCUC/rtl/dnoc/dnoc_itf_core_wr.sv
/home/linyx/project/ReCUC/rtl/dnoc/dnoc_itf_dma_rd.sv
/home/linyx/project/ReCUC/rtl/dnoc/dnoc_itf_dma_wr.sv
/home/linyx/project/ReCUC/rtl/dnoc/dnoc_itf_in_c_channel.sv
/home/linyx/project/ReCUC/rtl/dnoc/dnoc_itf_in_d_channel.sv
/home/linyx/project/ReCUC/rtl/dnoc/dnoc_itf_out_c_channel.sv
/home/linyx/project/ReCUC/rtl/dnoc/dnoc_itf_out_d_channel.sv
/home/linyx/project/ReCUC/rtl/dnoc/dnoc_itf_pingpong.sv
/home/linyx/project/ReCUC/rtl/dnoc/L2_dmem_bank.sv
/home/linyx/project/ReCUC/rtl/dnoc/L2_dmem.sv
/home/linyx/project/ReCUC/rtl/dnoc/sync_collect.sv
/home/linyx/project/ReCUC/rtl/dnoc/addr_mu.sv
/home/linyx/project/ReCUC/rtl/dnoc/addr_mu_ns.sv
/home/linyx/project/ReCUC/rtl/dnoc/pad_addr_mu.sv
/home/linyx/project/ReCUC/rtl/dnoc/cu_node.sv
/home/linyx/project/ReCUC/rtl/dnoc/pc_debug.sv
/home/linyx/project/ReCUC/rtl/dnoc/ram_req_fifo.sv


//----------------ibus-------------------
/home/linyx/project/ReCUC/rtl/ibus/find_not_valid.sv
/home/linyx/project/ReCUC/rtl/ibus/plru.sv
/home/linyx/project/ReCUC/rtl/ibus/icache_refill_ctr.sv
/home/linyx/project/ReCUC/rtl/ibus/stream_buffer.sv
/home/linyx/project/ReCUC/rtl/ibus/tag_reg8x10.sv
/home/linyx/project/ReCUC/rtl/ibus/pri_icache.sv
/home/linyx/project/ReCUC/rtl/ibus/icache_L1_L2_itf.sv

//----------------------node top------------------
/home/linyx/project/ReCUC/rtl/CU_core_top/irq_ctr.sv
/home/linyx/project/ReCUC/rtl/CU_core_top/CU_core_wrapper.sv
