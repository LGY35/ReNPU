hybrid_assembler_v4.5

使用说明：
1. hybrid_assembler_v4.5: cpu和npu混合汇编器，可通过-h查看usage。
2. inst_set_v4.5.s: 默认的输入文件，存放汇编指令。

功能更新：
1. 修改后的指令的同步更新


附录：
指令格式参考示例：
npu_load (we=wr, l1b_mode=norm, from_noc_or_sc=noc, sys_gap=1, sub_gap=0, sub_len=16, addr=1, sys_len=8, mv_last_dis=0, cfifo_en=1, bar=0)
npu_mv (we=rd, l1b_mode=norm, sys_gap=1, sub_gap=1, sub_len=1, addr=0, sys_len=1, mv_last_dis=0, cfifo_en=1, bar=0)
hid_load (we=rd, l1b_mode=norm, sys_gap=1, sub_gap=1, sub_len=1, addr=0, sys_len=1, cfifo_en=1, bar=0)
npu_store (bar=0)
MQ_cfg0 (gpu_mode=0, para_mode=0, tcache_mode=TRANS_DWCONV, one_ram_base_addr=1, tcache_trans_swbank=0, tcache_trans_prici=INT8, mv_cub_dst_sel=weight, wr_hl_mask=0)
MQ_cfg1 (sub_gap=0, sys_gap_ext=0b10001, iob_pric=INT8, iob_l2c_in_cfg=0, tcache_mvfmap_stride=0, tcache_mvfmap_offset=0)
MQ_cfg2 (hide_sub_gap=0, hide_sys_gap_ext=0b10001, l1b_norm_paral_mode=0)
MQ_NOP (bar=0, nop_cycle_num=1)
hid_load_chk_done
CVEC_cfg0 (kernel_size=3, dw_depth=1, fmap_bank_num=7, stride=0)
CVEC_cfg1 (routing_code=0b10000000010000001111, route_cfg_done=0)
CVEC_cfg2 (cal_mode=dw_conv, wreg_wr_cnt=0, fprec=INT8, wprec=INT8, v_tq=0)
conv3d_start (first_sub_flag=0, start_index=0, end_index=29, tcache_stride=0, tcache_offset=0, bc_mode=0, bc_len=16, rgba_mode=0, rgba_stride=0, rgba_shift=0, hl_op=0, bc_keep_2cycle_en=0, bc_group=0, pad0_sel=end, pad0_len=0, run_cycle_num=32, cfifo_en=1, bar=1)
dwconv_start (cross_right=0, cross_left=1, right_pad=0, left_pad=1, bottom_pad=1, top_pad=1, trans_num=3, scache_wr_size=word, scache_wr_addr=0, run_cycle_num=20, cfifo_en=1, bar=1)
eltwise_start(elt_mode=0, elt_pric=INT8, elt_bsel=0, elt_32ch_i16=0, scache_rd_en=0, scache_rd_addr=0, scache_rd_size=word, scache_sign_ext=0, tcache_stride=0, tcache_offset=0, bc_mode=0, bc_len=16, rgba_mode=0, rgba_stride=0, rgba_shift=0, hl_op=0, bc_keep_2cycle_en=0, pad0_sel=end, pad0_len=0, run_cycle_num=32, cfifo_en=1, bar=1)
Y_mode_pre_start (Y_mode_cram_sel=0, tcache_stride=0, tcache_offset=0, bc_mode=0, bc_len=16, rgba_mode=0, rgba_stride=0, rgba_shift=0, hl_op=0, bc_keep_2cycle_en=0, bc_group=0, pad0_sel=end, pad0_len=0, run_cycle_num=1, cfifo_en=1, bar=1)
psum_rd (rd_num=0, rd_ch_sel=0, rd_rgb_sel=0, scache_wr_en_mask=0, scache_wr_addr=0, scache_wr_size=word, run_cycle_num=0, cfifo_en=0, bar=1)
VQ_NOP (bar=0, nop_cycle_num=1)
VQ_alu_csrw (csr_addr=2, csr_wdata=0b001_0001_0001_0000)
VQ_alu_csrr (csr_addr=2, rd=x1)
VQ_alu_event_call (event_addr=1, bar=1)
VQ_scache_wr_en (addr=0, size=word, wr_cycle_num=0, wait_type=0, cfifo_en=0, bar=1)
VQ_scache_rd_en (addr=0, size=word, sign_ext=0, rd_cycle_num=0, wait_type=0, cfifo_en=0, bar=1)
cubank_mask (mask_sel=1, cubank_mask=0b1)
next_fetch_is_cpu
next_fetch_is_npu
storec x8, MQ 
storec x11, VQ

cub_alu_insn_fill(addr=1, num=1)
cub_alu_event_call(start_addr=1)
cub_alu_mask(mask_sel=1, cub_alu_mask=0b1)
cub.lp.starti 1, 0x01
cub.lp.endi 1, 0x01
cub.lp.counti 1, 0x01
cub.lp.setupi 1, 0x01, 0x01
cub.event_finish
cub.nop 1
cub.cflow_nop 1
cub.lci x5
cub.add x5, x1, x2
cub.sub x5, x1, x2
cub.slt x5, x1, x2
cub.sltu x5, x1, x2
cub.and x5, x1, x2
cub.or x5, x1, x2
cub.xor x5, x1, x2
cub.sll x5, x1, x2
cub.srl x5, x1, x2
cub.sra x5, x1, x2
cub.mul x5, x1, x2
cub.mulh x5, x1, x2
cub.mulhsu x5, x1, x2
cub.mulhu x5, x1, x2
cub.p.eq x5, x1, x2
cub.p.slet x5, x1, x2
cub.p.sletu x5, x1, x2
cub.p.vec.sgtb x5, x1, x2
cub.p.vec.sgth x5, x1, x2
cub.p.vec.sltb x5, x1, x2
cub.p.vec.slth x5, x1, x2
cub.p.exths x5, x1, x2
cub.p.exthz x5, x1, x2
cub.p.extbs x5, x1, x2
cub.p.extbz x5, x1, x2
cub.p.min x5, x1, x2
cub.p.minu x5, x1, x2
cub.p.max x5, x1, x2
cub.p.maxu x5, x1, x2
cub.p.vec.addh x5, x1, x2
cub.p.vec.addb x5, x1, x2
cub.p.vec.subh x5, x1, x2
cub.p.vec.subb x5, x1, x2
cub.p.vec.maxh x5, x1, x2
cub.p.vec.maxb x5, x1, x2
cub.p.vec.minh x5, x1, x2
cub.p.vec.minb x5, x1, x2
cub.p.abs x5, x1
cub.relu x5, x1, 1
cub.sb.l1b x2, 0x01(x1)
cub.sh.l1b x2, 0x01(x1)
cub.sw.l1b x2, 0x01(x1)
cub.sb.scache x2, 0x01(x1)
cub.sh.scache x2, 0x01(x1)
cub.sw.scache x2, 0x01(x1)
cub.sw.cram x2, 0x01(x1)
cub.addi x5, x1, 0x01
cub.slti x5, x1, 0x01
cub.sltiu x5, x1, 0x01
cub.xori x5, x1, 0x01
cub.ori x5, x1, 0x01
cub.andi x5, x1, 0x01
cub.lb.l1b x5, 0x01(x1)
cub.lbu.l1b x5, 0x01(x1)
cub.lh.l1b x5, 0x01(x1)
cub.lhu.l1b x5, 0x01(x1)
cub.lw.l1b x5, 0x01(x1)
cub.lb.scache x5, 0x01(x1)
cub.lbu.scache x5, 0x01(x1)
cub.lh.scache x5, 0x01(x1)
cub.lhu.scache x5, 0x01(x1)
cub.lw.scache x5, 0x01(x1)
cub.lw.cram x5, 0x01(x1)
cub.lui x5, 0x01
cub.addT8 x5, x1, x2, 3
cub.addT16 x5, x1, x2, 3
cub.subT8 x5, x1, x2, 3
cub.subT16 x5, x1, x2, 3
cub.csrw 3, 0b0000110000
cub.scache_wr_en 1, hword
cub.scache_rd_en 1, hword, 1

NOC_cfg (addr=1, wdata=1, cfifo_wdata=1, cfifo_en=1)
noc_req (comd_type=2, bar=0)
imm_ba(0x00000000)
imm_ba(0x00000001)
imm_ba(0x00000002)
imm_ba(0x00000003)
imm_ba(0x00000004)
imm_ba(0x00000005)
imm_ba(0x00000006)
imm_ba(0x00000007)
imm_ba(0x00000008)
imm_ba(0x00000009)
imm_ba(0x0000000a)
imm_ba(0x0000000b)
imm_wba(0x00000000)
imm_wba(0x00000001)
imm_wba(0x00000002)
imm_wba(0x00000003)
imm_wba(0x00000004)
imm_wba(0x00000005)
imm_wba(0x00000006)
imm_wba(0x00000007)
imm_wba(0x00000008)
imm_wba(0x00000009)
imm_wba(0x0000000a)
imm_wba(0x0000000b)
imm_gba(0xaaaaaaaa)
imm_cfg(0xffffffff)
normal_group(0x003)
imm_gba(0xbbbbbbbb)
imm_cfg(0xffffffff)
last_group(0x00c)
imm_ba(0x00000000)
imm_ba(0x00000001)
imm_ba(0x00000002)
imm_ba(0x00000003)
imm_ba(0x00000004)
imm_ba(0x00000005)
imm_ba(0x00000006)
imm_ba(0x00000007)
imm_ba(0x00000008)
imm_ba(0x00000009)
imm_ba(0x0000000a)
imm_ba(0x0000000b)
imm_wba(0x00000000)
imm_wba(0x00000001)
imm_wba(0x00000002)
imm_wba(0x00000003)
imm_wba(0x00000004)
imm_wba(0x00000005)
imm_wba(0x00000006)
imm_wba(0x00000007)
imm_wba(0x00000008)
imm_wba(0x00000009)
imm_wba(0x0000000a)
imm_wba(0x0000000b)
imm_gba(0xbbbbbbbb)
imm_cfg(0xffffffff)
finish_group(0x030)

p.lb x5, 1(x1!)
p.lbu x5, 1(x1!)
p.lh x5, 1(x1!)
p.lhu x5, 1(x1!)
p.lw x5, 1(x1!)
p.lb x5, x2(x1!)
p.lbu x5, x2(x1!)
p.lh x5, x2(x1!)
p.lhu x5, x2(x1!)
p.lw x5, x2(x1!)
p.lb x5, x2(x1)
p.lbu x5, x2(x1)
p.lh x5, x2(x1)
p.lhu x5, x2(x1)
p.lw x5, x2(x1)
p.sb x2, 1(x1!)
p.sh x2, 1(x1!)
p.sw x2, 1(x1!)
p.sb x2, x3(x1!)
p.sh x2, x3(x1!)
p.sh x2, x3(x1!)
p.sb x2, x3(x1)
p.sh x2, x3(x1)
p.sw x2, x3(x1)
lp.starti 1, 1
lp.endi 1, 1
lp.counti 1, 1
lp.count 1, x1
lp.setup 1, x1, 1
lp.setupi 1, 1, 1

wfi
