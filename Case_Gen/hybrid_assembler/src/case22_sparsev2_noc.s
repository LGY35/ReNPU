CVEC_cfg2          (cal_mode=sparse_conv,wreg_wr_cnt=2,fprec=INT8,wprec=INT8,v_tq=0)
MQ_cfg0            (gpu_mode=0,para_mode=0,tcache_mode=16CH_SFIFO,one_ram_base_addr=27,tcache_trans_swbank=0,tcache_trans_prici=INT8,mv_cub_dst_sel=weight,wr_hl_mask=0)
NOC_cfg (addr=2,wdata=0,cfifo_wdata=0,cfifo_en=0) // 关闭多节点合并读   
NOC_cfg (addr=3,wdata=0,cfifo_wdata=0,cfifo_en=0) // 直接从ddr读取数据
NOC_cfg (addr=4,wdata=0,cfifo_wdata=0,cfifo_en=0) // 关闭pingpong
NOC_cfg (addr=6,wdata=0,cfifo_wdata=0,cfifo_en=0) // 基地址偏移为0，地址为512
NOC_cfg (addr=11,wdata=1,cfifo_wdata=0,cfifo_en=0) //最内层循环递增，每次读入256bit
NOC_cfg (addr=15,wdata=431,cfifo_wdata=0,cfifo_en=0)  // weight总长度576-1
NOC_cfg (addr=16,wdata=0,cfifo_wdata=0,cfifo_en=0) //不采用pingpong
NOC_cfg (addr=17,wdata=431,cfifo_wdata=0,cfifo_en=0) // ping传输的长度
NOC_cfg (addr=19,wdata=0,cfifo_wdata=0,cfifo_en=0) //单播模式
NOC_cfg (addr=20,wdata=0,cfifo_wdata=0,cfifo_en=0) //不和任何节点同步
NOC_cfg (addr=21,wdata=1,cfifo_wdata=0,cfifo_en=0) // 读取base地址为cluster指令中的weight地址（每组统一的地址）
NOC_cfg (addr=31,wdata=1,cfifo_wdata=0,cfifo_en=0) //单独取指
npu_load           (we=wr,l1b_mode=norm ,from_noc_or_sc=noc, sys_gap=230,sub_gap=1,sub_len=27,addr=0, sys_len=16,mv_last_dis=0,cfifo_en=1,bar=0) //load_weight， 432
noc_req (comd_type=4, bar=0,cfifo_wdata=0,cfifo_en=0) // 检查是否完成weight搬运
NOC_cfg (addr=98  , wdata=0,cfifo_wdata=0,cfifo_en=0) // 关闭多节点合并读
NOC_cfg (addr=99  , wdata=0,cfifo_wdata=0,cfifo_en=0) // 直接从ddr读取数据
NOC_cfg (addr=100 , wdata=0 ,cfifo_wdata=0,cfifo_en=0) // 关闭pingpong
NOC_cfg (addr=101 , wdata=0,cfifo_wdata=0,cfifo_en=0) // 本地ram ping 基地址
NOC_cfg (addr=103 , wdata=0,cfifo_wdata=0,cfifo_en=0) // ddr地址偏移
NOC_cfg (addr=104 , wdata=0,cfifo_wdata=0,cfifo_en=0) // ddr地址偏移
NOC_cfg (addr=108 , wdata=1,cfifo_wdata=0,cfifo_en=0) // 最内层循环递增，每次读入256bit
NOC_cfg (addr=112 , wdata=1023,cfifo_wdata=0,cfifo_en=0) // fmap总长度2048-1
NOC_cfg (addr=113 , wdata=0,cfifo_wdata=0,cfifo_en=0) //不采用pingpong
NOC_cfg (addr=114 , wdata=1023,cfifo_wdata=0,cfifo_en=0)  // fmap总长度2048-1
NOC_cfg (addr=116 , wdata=0,cfifo_wdata=0,cfifo_en=0)//单播模式
NOC_cfg (addr=117 , wdata=0,cfifo_wdata=0,cfifo_en=0) //不和任何节点同步
NOC_cfg (addr=118 , wdata=0,cfifo_wdata=0,cfifo_en=0) // 搬运fmap
noc_req (comd_type=3, bar=0,cfifo_wdata=0,cfifo_en=0) // 启动dma——wr
noc_req (comd_type=4, bar=0,cfifo_wdata=0,cfifo_en=0)// 检查是否完成fmap搬运
MQ_NOP(bar=0,nop_cycle_num=0)
MQ_NOP(bar=0,nop_cycle_num=0)
MQ_NOP(bar=0,nop_cycle_num=0)
MQ_NOP(bar=0,nop_cycle_num=0)
MQ_NOP(bar=0,nop_cycle_num=0)
MQ_NOP(bar=0,nop_cycle_num=0)
MQ_NOP(bar=0,nop_cycle_num=0)
MQ_NOP(bar=0,nop_cycle_num=0)
MQ_NOP(bar=0,nop_cycle_num=0)
wfi  
CVEC_cfg2          (cal_mode=sparse_conv,wreg_wr_cnt=2,fprec=INT8,wprec=INT8,v_tq=0)
MQ_cfg0            (gpu_mode=0,para_mode=0,tcache_mode=16CH_SFIFO,one_ram_base_addr=27,tcache_trans_swbank=0,tcache_trans_prici=INT8,mv_cub_dst_sel=weight,wr_hl_mask=0)
NOC_cfg (addr=0,wdata=1,cfifo_wdata=0,cfifo_en=0) // 相对寻址
NOC_cfg (addr=1,wdata=0,cfifo_wdata=0,cfifo_en=0) //读取本地L2
NOC_cfg (addr=2,wdata=0,cfifo_wdata=0,cfifo_en=0) // 关闭多节点合并读
NOC_cfg (addr=3,wdata=1,cfifo_wdata=0,cfifo_en=0) // 从片上读取数据
NOC_cfg (addr=4,wdata=0,cfifo_wdata=0,cfifo_en=0) // 关闭pingpong
NOC_cfg (addr=6,wdata=0,cfifo_wdata=0,cfifo_en=0) // 基地址偏移为0
NOC_cfg (addr=11,wdata=1,cfifo_wdata=0,cfifo_en=0) //最内层循环递增，每次读入256bit
NOC_cfg (addr=15,wdata=1023,cfifo_wdata=0,cfifo_en=0)  // fmap总长度1023
NOC_cfg (addr=16,wdata=0,cfifo_wdata=0,cfifo_en=0) //不采用pingpong  
NOC_cfg (addr=17,wdata=1023,cfifo_wdata=0,cfifo_en=0) // ping传输的长度1023
NOC_cfg (addr=19,wdata=0,cfifo_wdata=0,cfifo_en=0) //单播模式
NOC_cfg (addr=20,wdata=0,cfifo_wdata=0,cfifo_en=0) //不和任何节点同步
NOC_cfg (addr=21,wdata=0,cfifo_wdata=0,cfifo_en=0) // 读取base地址为cluster指令中的weight地址（每组不同的地址）
NOC_cfg (addr=31,wdata=1,cfifo_wdata=0,cfifo_en=0) //单独取指   
npu_load           (we=wr,l1b_mode=cache,from_noc_or_sc=noc, sys_gap=1,  sub_gap=1,sub_len=0 ,addr=0, sys_len=4 ,mv_last_dis=0,cfifo_en=1,bar=0) //load_fmap， 1024
noc_req (comd_type=4, bar=0) // 检查是否完成fmap搬运
NOC_cfg (addr=32,wdata=1,cfifo_wdata=0,cfifo_en=0)            // 相对寻址
NOC_cfg (addr=33,wdata=0,cfifo_wdata=0,cfifo_en=0)            // 设置为0即可，用ping addr
NOC_cfg (addr=34,wdata=1,cfifo_wdata=0,cfifo_en=0)           // 数据输出到本地
NOC_cfg (addr=35,wdata=0,cfifo_wdata=0,cfifo_en=0)            // 关闭pingpong
NOC_cfg (addr=37,wdata=1536,cfifo_wdata=0,cfifo_en=0)           // 因为fmap占了32KB，也就是bank0到3，所以结果输出到bank6
NOC_cfg (addr=42,wdata=1,cfifo_wdata=0,cfifo_en=0)           //最内层循环递增，每次读入256bit
NOC_cfg (addr=46,wdata=63,cfifo_wdata=0,cfifo_en=0)             // 输出总长度64
NOC_cfg (addr=47,wdata=0,cfifo_wdata=0,cfifo_en=0)           //不采用pingpong
NOC_cfg (addr=48,wdata=63,cfifo_wdata=0,cfifo_en=0)            // ping传输的长度64
cub_alu_insn_fill(addr=0,num=8)
cub.csrw 10, 0b101000000 //scache_rd0 (sub_len=64,sys_len=1)
cub.csrw 11, 0b1 //scache_rd1 (sub_gap=1)
cub.scache_rd_en 0, byte, 1 //store out of core
cub.event_finish
cub.scache_rd_en 64, byte, 1 //store out of core
cub.event_finish
cub.scache_rd_en 128, byte, 1 //store out of core
cub.event_finish

VQ_alu_csrw(csr_addr=0,csr_wdata=0b10000) //cub_alu_din_cflow_sel
VQ_alu_csrw(csr_addr=2,csr_wdata=0b000000000000000) //crossbar
VQ_alu_csrw(csr_addr=3,csr_wdata=0b1000000000) //crossbar
VQ_alu_csrw(csr_addr=7,csr_wdata=0b111000000) //scache wr0: sys_len=1,sub_len=32*2*3
VQ_alu_csrw(csr_addr=8,csr_wdata=0b1) //scache wr1: sub_gap=1
VQ_scache_wr_en(addr=0,size=byte,wr_cycle_num=0,wait_type=0,cfifo_en=0,bar=0)

npu_mv             (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=3, addr=9,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0) //mv_weight
npu_mv             (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=31,addr=0, sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1) //mv_fmap
conv3d_start       (first_sub_flag=1,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=head,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=1)
VQ_NOP             (bar=2,nop_cycle_num=0)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=head,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=0)
npu_mv             (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=3, addr=12,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
npu_mv             (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=32,addr=0,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=3)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=32,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end,pad0_len=0,run_cycle_num=34,cfifo_en=1,bar=3)
VQ_NOP             (bar=4,nop_cycle_num=0)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=32,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end,pad0_len=0,run_cycle_num=34,cfifo_en=1,bar=0)
npu_mv             (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=3, addr=15,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=4)
npu_mv             (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=31,addr=1,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=1)
VQ_NOP             (bar=2,nop_cycle_num=0)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=0)
npu_mv             (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=3, addr=18,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
npu_mv             (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=31,addr=32,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=3)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=head,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=3)
VQ_NOP             (bar=4,nop_cycle_num=0)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=head,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=0)
npu_mv             (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=3, addr=21,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=4)
npu_mv             (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=32,addr=32,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=32,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end,pad0_len=0,run_cycle_num=34,cfifo_en=1,bar=1)
VQ_NOP             (bar=2,nop_cycle_num=0)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=32,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end,pad0_len=0,run_cycle_num=34,cfifo_en=1,bar=0)
npu_mv             (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=3, addr=24,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
npu_mv             (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=31,addr=33,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=3)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=3)
VQ_NOP             (bar=4,nop_cycle_num=0)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=0)

VQ_NOP                         (bar=0,nop_cycle_num=5) //100_000000000000000000_010_0001

psum_rd                        (rd_num=31,rd_ch_sel=0,rd_rgb_sel=0,scache_wr_en_mask=1,scache_wr_addr=0,scache_wr_size=byte,run_cycle_num=31,cfifo_en=1,bar=0)
psum_rd                        (rd_num=31,rd_ch_sel=1,rd_rgb_sel=0,scache_wr_en_mask=1,scache_wr_addr=32,scache_wr_size=byte,run_cycle_num=7,cfifo_en=1,bar=0)

npu_mv             (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=3, addr=0,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=4) //mv_weight
npu_mv             (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=31,addr=0, sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1) //mv_fmap
conv3d_start       (first_sub_flag=1,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=head,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=1)
npu_store(bar=0)//输出64个数
noc_req (comd_type=4, bar=0,cfifo_wdata=0,cfifo_en=0) // 检查是否完成搬运
VQ_alu_csrw(csr_addr=0,csr_wdata=0b00000)
VQ_alu_event_call(event_addr=0,bar=0)
VQ_NOP             (bar=2,nop_cycle_num=0)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=head,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=0)
npu_mv             (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=3, addr=3,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
npu_mv             (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=32,addr=0,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=3)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=32,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end,pad0_len=0,run_cycle_num=34,cfifo_en=1,bar=3)
VQ_NOP             (bar=4,nop_cycle_num=0)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=32,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end,pad0_len=0,run_cycle_num=34,cfifo_en=1,bar=0)
npu_mv             (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=3, addr=6,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=4)
npu_mv             (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=31,addr=1,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=1)
VQ_NOP             (bar=2,nop_cycle_num=0)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=0)
npu_mv             (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=3, addr=9,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
npu_mv             (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=31,addr=32,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=3)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=head,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=3)
VQ_NOP             (bar=4,nop_cycle_num=0)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=head,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=0)
npu_mv             (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=3, addr=12,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=4)
npu_mv             (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=32,addr=32,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=32,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end,pad0_len=0,run_cycle_num=34,cfifo_en=1,bar=1)
VQ_NOP             (bar=2,nop_cycle_num=0)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=32,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end,pad0_len=0,run_cycle_num=34,cfifo_en=1,bar=0)
npu_mv             (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=3, addr=15,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
npu_mv             (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=31,addr=33,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=3)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=3)
VQ_NOP             (bar=4,nop_cycle_num=0)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=0)
npu_mv             (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=3, addr=18,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=4)
npu_mv             (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=31,addr=64,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=3)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=head,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=3)
VQ_NOP             (bar=2,nop_cycle_num=0)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=head,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=0)
npu_mv             (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=3, addr=21,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
npu_mv             (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=32,addr=64,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=32,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end,pad0_len=0,run_cycle_num=34,cfifo_en=1,bar=1)
VQ_NOP             (bar=4,nop_cycle_num=0)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=32,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end,pad0_len=0,run_cycle_num=34,cfifo_en=1,bar=0)
npu_mv             (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=3, addr=24,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=4)
npu_mv             (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=31,addr=65,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=3)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=3)
VQ_NOP             (bar=2,nop_cycle_num=0)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=0)



VQ_NOP                         (bar=0,nop_cycle_num=5) //100_000000000000000000_010_0001

psum_rd                        (rd_num=31,rd_ch_sel=0,rd_rgb_sel=0,scache_wr_en_mask=1,scache_wr_addr=64,scache_wr_size=byte,run_cycle_num=31,cfifo_en=1,bar=0)
psum_rd                        (rd_num=31,rd_ch_sel=1,rd_rgb_sel=0,scache_wr_en_mask=1,scache_wr_addr=96,scache_wr_size=byte,run_cycle_num=7,cfifo_en=1,bar=0)


npu_mv             (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=3, addr=0,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2) //mv_weight
npu_mv             (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=31,addr=32, sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1) //mv_fmap
conv3d_start       (first_sub_flag=1,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=head,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=1)
NOC_cfg (addr=37,wdata=1600,cfifo_wdata=0,cfifo_en=1)   
npu_store(bar=0)//输出64个数
VQ_alu_csrw(csr_addr=0,csr_wdata=0b00000)
VQ_alu_event_call(event_addr=4,bar=0)
VQ_NOP             (bar=2,nop_cycle_num=0)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=head,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=0)
noc_req (comd_type=4, bar=0,cfifo_wdata=0,cfifo_en=0) // 检查是否完成搬运
npu_mv             (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=3, addr=3,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
npu_mv             (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=32,addr=32,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=3)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=32,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end,pad0_len=0,run_cycle_num=34,cfifo_en=1,bar=3)
VQ_NOP             (bar=4,nop_cycle_num=0)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=32,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end,pad0_len=0,run_cycle_num=34,cfifo_en=1,bar=0)
npu_mv             (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=3, addr=6,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=4)
npu_mv             (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=31,addr=33,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=1)
VQ_NOP             (bar=2,nop_cycle_num=0)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=0)
npu_mv             (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=3, addr=9,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
npu_mv             (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=31,addr=64,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=3)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=head,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=3)
VQ_NOP             (bar=4,nop_cycle_num=0)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=head,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=0)
npu_mv             (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=3, addr=12,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=4)
npu_mv             (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=32,addr=64,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=32,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end,pad0_len=0,run_cycle_num=34,cfifo_en=1,bar=1)
VQ_NOP             (bar=2,nop_cycle_num=0)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=32,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end,pad0_len=0,run_cycle_num=34,cfifo_en=1,bar=0)
npu_mv             (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=3, addr=15,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
npu_mv             (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=31,addr=65,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=3)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=3)
VQ_NOP             (bar=4,nop_cycle_num=0)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=0)
npu_mv             (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=3, addr=18,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=4)
npu_mv             (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=31,addr=96,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=3)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=head,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=3)
VQ_NOP             (bar=2,nop_cycle_num=0)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=head,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=0)
npu_mv             (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=3, addr=21,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
npu_mv             (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=32,addr=96,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=32,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end,pad0_len=0,run_cycle_num=34,cfifo_en=1,bar=1)
VQ_NOP             (bar=4,nop_cycle_num=0)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=32,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end,pad0_len=0,run_cycle_num=34,cfifo_en=1,bar=0)
npu_mv             (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=3, addr=24,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=4)
npu_mv             (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=31,addr=97,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=3)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=3)
VQ_NOP             (bar=2,nop_cycle_num=0)
conv3d_start       (first_sub_flag=0,start_index=0,end_index=31,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=31,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end,pad0_len=1,run_cycle_num=34,cfifo_en=1,bar=0)

VQ_NOP                         (bar=0,nop_cycle_num=5) //100_000000000000000000_010_0001

psum_rd                        (rd_num=31,rd_ch_sel=0,rd_rgb_sel=0,scache_wr_en_mask=1,scache_wr_addr=128,scache_wr_size=byte,run_cycle_num=31,cfifo_en=1,bar=0)
psum_rd                        (rd_num=31,rd_ch_sel=1,rd_rgb_sel=0,scache_wr_en_mask=1,scache_wr_addr=160,scache_wr_size=byte,run_cycle_num=31,cfifo_en=1,bar=0)
NOC_cfg (addr=37,wdata=1664,cfifo_wdata=0,cfifo_en=1)   
npu_store(bar=0)
VQ_alu_event_call(event_addr=6,bar=0)
noc_req (comd_type=4, bar=0,cfifo_wdata=0,cfifo_en=0) // 检查是否完成搬运
MQ_NOP(bar=0,nop_cycle_num=0)
MQ_NOP(bar=0,nop_cycle_num=0)
MQ_NOP(bar=0,nop_cycle_num=0)
MQ_NOP(bar=0,nop_cycle_num=0)
MQ_NOP(bar=0,nop_cycle_num=0)
MQ_NOP(bar=0,nop_cycle_num=0)
MQ_NOP(bar=0,nop_cycle_num=0)
MQ_NOP(bar=0,nop_cycle_num=0)
MQ_NOP(bar=0,nop_cycle_num=0)
wfi  
CVEC_cfg2          (cal_mode=sparse_conv,wreg_wr_cnt=2,fprec=INT8,wprec=INT8,v_tq=0)
MQ_cfg0            (gpu_mode=0,para_mode=0,tcache_mode=16CH_SFIFO,one_ram_base_addr=27,tcache_trans_swbank=0,tcache_trans_prici=INT8,mv_cub_dst_sel=weight,wr_hl_mask=0)
NOC_cfg (addr=66,wdata=0,cfifo_wdata=0,cfifo_en=0)           // 输出到ddr
NOC_cfg (addr=67,wdata=0,cfifo_wdata=0,cfifo_en=0)            // 关闭pingpong
NOC_cfg (addr=68,wdata=6144,cfifo_wdata=0,cfifo_en=0)           // 输出基地址
NOC_cfg (addr=70,wdata=0,cfifo_wdata=0,cfifo_en=0)           //noc地址
NOC_cfg (addr=71,wdata=0,cfifo_wdata=0,cfifo_en=0)             // noc地址
NOC_cfg (addr=75,wdata=1,cfifo_wdata=0,cfifo_en=0)             // loop gap3
NOC_cfg (addr=79,wdata=191,cfifo_wdata=0,cfifo_en=0)             // loop lenth3 = 64*3
NOC_cfg (addr=80,wdata=0,cfifo_wdata=0,cfifo_en=0)           //piingpang num
NOC_cfg (addr=81,wdata=191,cfifo_wdata=0,cfifo_en=0)            // ping传输的长度64
noc_req (comd_type=2, bar=0,cfifo_wdata=0,cfifo_en=0)   // 启动dma rd
noc_req (comd_type=4, bar=0,cfifo_wdata=0,cfifo_en=0)
MQ_NOP(bar=0,nop_cycle_num=0)
MQ_NOP(bar=0,nop_cycle_num=0)
MQ_NOP(bar=0,nop_cycle_num=0)
MQ_NOP(bar=0,nop_cycle_num=0)
MQ_NOP(bar=0,nop_cycle_num=0)
MQ_NOP(bar=0,nop_cycle_num=0)
MQ_NOP(bar=0,nop_cycle_num=0)
MQ_NOP(bar=0,nop_cycle_num=0)
MQ_NOP(bar=0,nop_cycle_num=0)
wfi  