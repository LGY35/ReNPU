CVEC_cfg2          (cal_mode=sparse_conv,wreg_wr_cnt=2,fprec=INT8,wprec=INT8,v_tq=0)
MQ_cfg0            (gpu_mode=0,para_mode=0,tcache_mode=16CH_SFIFO,one_ram_base_addr=27,tcache_trans_swbank=0,tcache_trans_prici=INT8,mv_cub_dst_sel=weight,wr_hl_mask=0)
npu_load           (we=wr,l1b_mode=norm ,tcache_bank_num=0,sys_gap=230,sub_gap=1,sub_len=27,addr=0, sys_len=16,mv_last_dis=0,cfifo_en=1,bar=0) //load_weight， 576
npu_load           (we=wr,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,  sub_gap=1,sub_len=0 ,addr=0, sys_len=4 ,mv_last_dis=0,cfifo_en=1,bar=0) //load_fmap， 1024

cub_alu_insn_fill(addr=0,num=4)
cub.csrw 10, 0b1_01000000 //scache_rd0 (sub_len=64,sys_len=1)
cub.csrw 11, 0b1 //scache_rd1 (sub_gap=1)
cub.scache_rd_en 0, byte, 1 //store out of core
cub.event_finish

VQ_alu_csrw(csr_addr=0,csr_wdata=0b1_0_000) //cub_alu_din_cflow_sel
VQ_alu_csrw(csr_addr=2,csr_wdata=0b000000000000000) //crossbar
VQ_alu_csrw(csr_addr=3,csr_wdata=0b10000_00000) //crossbar
VQ_alu_csrw(csr_addr=7,csr_wdata=0b1_01100000) //scache wr0: sys_len=1,sub_len=32*3
VQ_alu_csrw(csr_addr=8,csr_wdata=0b1) //scache wr1: sub_gap=1

npu_mv             (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=3, addr=9,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0) //mv_weight
npu_mv             (we=rd,l1b_mode=cache,tcache_bank_num= 0,sys_gap=1,sub_gap=1,sub_len=31,addr=0, sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1) //mv_fmap
conv3d_start       (first_sub_flag=1,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=head,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=1)
VQ_NOP             (bar=2,nop_cycle_num=0)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=head,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=0)
npu_mv             (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=3, addr=12,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
npu_mv             (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=32,addr=0,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=3)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=32,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=34,cfifo_en=1,bar=3)
VQ_NOP             (bar=4,nop_cycle_num=0)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=32,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=34,cfifo_en=1,bar=0)
npu_mv             (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=3, addr=15,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=4)
npu_mv             (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=31,addr=1,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=1)
VQ_NOP             (bar=2,nop_cycle_num=0)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=0)
npu_mv             (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=3, addr=18,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
npu_mv             (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=31,addr=32,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=3)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=head,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=3)
VQ_NOP             (bar=4,nop_cycle_num=0)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=head,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=0)
npu_mv             (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=3, addr=21,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=4)
npu_mv             (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=32,addr=32,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=32,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=34,cfifo_en=1,bar=1)
VQ_NOP             (bar=2,nop_cycle_num=0)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=32,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=34,cfifo_en=1,bar=0)
npu_mv             (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=3, addr=24,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
npu_mv             (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=31,addr=33,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=3)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=3)
VQ_NOP             (bar=4,nop_cycle_num=0)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=0)

//VQ_NOP                         (bar=5,nop_cycle_num=5) //100_000000000000000000_010_0001

psum_rd                        (rd_num=31,rd_ch_sel=0,rd_rgb_sel=0,scache_wr_addr=10,scache_wr_size=byte,run_cycle_num=31,cfifo_en=1,bar=0)
psum_rd                        (rd_num=31,rd_ch_sel=1,rd_rgb_sel=0,scache_wr_addr=10,scache_wr_size=byte,run_cycle_num=7,cfifo_en=1,bar=0)


npu_mv             (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=3, addr=0,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=4) //mv_weight
npu_mv             (we=rd,l1b_mode=cache,tcache_bank_num= 0,sys_gap=1,sub_gap=1,sub_len=31,addr=0, sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1) //mv_fmap
conv3d_start       (first_sub_flag=1,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=head,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=1)
//npu_store //输出64个数
VQ_alu_csrw(csr_addr=0,csr_wdata=0b0_0_000)
VQ_alu_event_call(event_addr=0,bar=0)
VQ_NOP             (bar=2,nop_cycle_num=0)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=head,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=0)
npu_mv             (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=3, addr=3,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
npu_mv             (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=32,addr=0,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=3)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=32,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=34,cfifo_en=1,bar=3)
VQ_NOP             (bar=4,nop_cycle_num=0)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=32,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=34,cfifo_en=1,bar=0)
npu_mv             (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=3, addr=6,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=4)
npu_mv             (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=31,addr=1,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=1)
VQ_NOP             (bar=2,nop_cycle_num=0)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=0)
npu_mv             (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=3, addr=9,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
npu_mv             (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=31,addr=32,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=3)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=head,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=3)
VQ_NOP             (bar=4,nop_cycle_num=0)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=head,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=0)
npu_mv             (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=3, addr=12,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=4)
npu_mv             (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=32,addr=32,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=32,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=34,cfifo_en=1,bar=1)
VQ_NOP             (bar=2,nop_cycle_num=0)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=32,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=34,cfifo_en=1,bar=0)
npu_mv             (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=3, addr=15,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
npu_mv             (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=31,addr=33,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=3)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=3)
VQ_NOP             (bar=4,nop_cycle_num=0)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=0)
npu_mv             (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=3, addr=18,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=4)
npu_mv             (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=31,addr=64,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=3)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=head,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=3)
VQ_NOP             (bar=2,nop_cycle_num=0)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=head,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=0)
npu_mv             (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=3, addr=21,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
npu_mv             (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=32,addr=64,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=32,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=34,cfifo_en=1,bar=1)
VQ_NOP             (bar=4,nop_cycle_num=0)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=32,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=34,cfifo_en=1,bar=0)
npu_mv             (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=3, addr=24,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=4)
npu_mv             (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=31,addr=65,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=3)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=3)
VQ_NOP             (bar=2,nop_cycle_num=0)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=0)



//VQ_NOP                         (bar=5,nop_cycle_num=5) //100_000000000000000000_010_0001

psum_rd                        (rd_num=31,rd_ch_sel=0,rd_rgb_sel=0,scache_wr_addr=10,scache_wr_size=byte,run_cycle_num=31,cfifo_en=1,bar=0)
psum_rd                        (rd_num=31,rd_ch_sel=1,rd_rgb_sel=0,scache_wr_addr=10,scache_wr_size=byte,run_cycle_num=7,cfifo_en=1,bar=0)


npu_mv             (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=3, addr=0,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2) //mv_weight
npu_mv             (we=rd,l1b_mode=cache,tcache_bank_num= 0,sys_gap=1,sub_gap=1,sub_len=31,addr=32, sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1) //mv_fmap
conv3d_start       (first_sub_flag=1,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=head,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=1)
//npu_store //输出64个数
VQ_alu_csrw(csr_addr=0,csr_wdata=0b0_0_000)
VQ_alu_event_call(event_addr=0,bar=0)
VQ_NOP             (bar=2,nop_cycle_num=0)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=head,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=0)
npu_mv             (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=3, addr=3,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
npu_mv             (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=32,addr=32,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=3)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=32,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=34,cfifo_en=1,bar=3)
VQ_NOP             (bar=4,nop_cycle_num=0)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=32,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=34,cfifo_en=1,bar=0)
npu_mv             (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=3, addr=6,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=4)
npu_mv             (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=31,addr=33,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=1)
VQ_NOP             (bar=2,nop_cycle_num=0)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=0)
npu_mv             (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=3, addr=9,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
npu_mv             (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=31,addr=64,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=3)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=head,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=3)
VQ_NOP             (bar=4,nop_cycle_num=0)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=head,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=0)
npu_mv             (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=3, addr=12,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=4)
npu_mv             (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=32,addr=64,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=32,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=34,cfifo_en=1,bar=1)
VQ_NOP             (bar=2,nop_cycle_num=0)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=32,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=34,cfifo_en=1,bar=0)
npu_mv             (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=3, addr=15,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
npu_mv             (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=31,addr=65,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=3)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=3)
VQ_NOP             (bar=4,nop_cycle_num=0)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=0)
npu_mv             (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=3, addr=18,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=4)
npu_mv             (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=31,addr=96,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=3)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=head,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=3)
VQ_NOP             (bar=2,nop_cycle_num=0)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=head,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=0)
npu_mv             (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=3, addr=21,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
npu_mv             (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=32,addr=96,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=32,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=34,cfifo_en=1,bar=1)
VQ_NOP             (bar=4,nop_cycle_num=0)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=32,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=34,cfifo_en=1,bar=0)
npu_mv             (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=3, addr=24,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=4)
npu_mv             (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=31,addr=97,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=3)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=3)
VQ_NOP             (bar=2,nop_cycle_num=0)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=0)



//VQ_NOP                         (bar=5,nop_cycle_num=5) //100_000000000000000000_010_0001

psum_rd                        (rd_num=31,rd_ch_sel=0,rd_rgb_sel=0,scache_wr_addr=10,scache_wr_size=byte,run_cycle_num=31,cfifo_en=1,bar=0)
psum_rd                        (rd_num=31,rd_ch_sel=1,rd_rgb_sel=0,scache_wr_addr=10,scache_wr_size=byte,run_cycle_num=31,cfifo_en=1,bar=0)
//npu_store //输出64个数
VQ_alu_event_call(event_addr=0,bar=0)
