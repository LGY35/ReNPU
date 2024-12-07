CVEC_cfg2       (cal_mode=norm_conv,wreg_wr_cnt=0,fprec=INT8,wprec=INT8,v_tq=0)
MQ_cfg0         (gpu_mode=0,para_mode=0,tcache_mode=16CH_SFIFO,one_ram_base_addr=40,tcache_trans_swbank=0,tcache_trans_prici=INT8,mv_cub_dst_sel=weight,wr_hl_mask=0)
MQ_cfg1         (sub_gap=1, sys_gap_ext=0b00000, iob_pric=INT8, iob_l2c_in_cfg=0, tcache_mvfmap_stride=0, tcache_mvfmap_offset=0)
NOC_cfg (addr=2,wdata=0,cfifo_wdata=0,cfifo_en=0) // 关闭多节点合并读   
NOC_cfg (addr=3,wdata=0,cfifo_wdata=0,cfifo_en=0) // 直接从ddr读取数据
NOC_cfg (addr=4,wdata=0,cfifo_wdata=0,cfifo_en=0) // 关闭pingpong
NOC_cfg (addr=6,wdata=0,cfifo_wdata=0,cfifo_en=0) // 基地址偏移为0，地址为512
NOC_cfg (addr=11,wdata=1,cfifo_wdata=0,cfifo_en=0) //最内层循环递增，每次读入256bit
NOC_cfg (addr=15,wdata=575,cfifo_wdata=0,cfifo_en=0)  // weight总长度576-1
NOC_cfg (addr=16,wdata=0,cfifo_wdata=0,cfifo_en=0) //不采用pingpong
NOC_cfg (addr=17,wdata=575,cfifo_wdata=0,cfifo_en=0) // ping传输的长度
NOC_cfg (addr=19,wdata=0,cfifo_wdata=0,cfifo_en=0) //单播模式
NOC_cfg (addr=20,wdata=0,cfifo_wdata=0,cfifo_en=0) //不和任何节点同步
NOC_cfg (addr=21,wdata=1,cfifo_wdata=0,cfifo_en=0) // 读取base地址为cluster指令中的weight地址（每组统一的地址）
NOC_cfg (addr=31,wdata=1,cfifo_wdata=0,cfifo_en=0) //单独取指
npu_load        (we=wr,l1b_mode=norm ,from_noc_or_sc=noc,sys_gap=221,sub_gap=1,sub_len=36,addr=0,sys_len=16,mv_last_dis=0,cfifo_en=1,bar=0)
noc_req (comd_type=4, bar=0,cfifo_wdata=0,cfifo_en=0) // 检查是否完成weight搬运
NOC_cfg (addr=2,wdata=0,cfifo_wdata=0,cfifo_en=0) // 关闭多节点合并读
NOC_cfg (addr=3,wdata=0,cfifo_wdata=0,cfifo_en=0) // 直接从ddr读取数据
NOC_cfg (addr=4,wdata=0,cfifo_wdata=0,cfifo_en=0) // 关闭pingpong
NOC_cfg (addr=6,wdata=576,cfifo_wdata=0,cfifo_en=0) // 基地址偏移为575，地址为512+576
NOC_cfg (addr=11,wdata=1,cfifo_wdata=0,cfifo_en=0) //最内层循环递增，每次读入256bit
NOC_cfg (addr=15,wdata=63,cfifo_wdata=0,cfifo_en=0)  // bias总长度64-1
NOC_cfg (addr=16,wdata=0,cfifo_wdata=0,cfifo_en=0) //不采用pingpong
NOC_cfg (addr=17,wdata=63,cfifo_wdata=0,cfifo_en=0) // ping传输的长度64-1
NOC_cfg (addr=19,wdata=0,cfifo_wdata=0,cfifo_en=0) //单播模式
NOC_cfg (addr=20,wdata=0,cfifo_wdata=0,cfifo_en=0) //不和任何节点同步
NOC_cfg (addr=21,wdata=1,cfifo_wdata=0,cfifo_en=0) // 读取base地址为cluster指令中的fmap地址（每组统一的地址）
NOC_cfg (addr=31,wdata=1,cfifo_wdata=0,cfifo_en=0) //单独取指  
npu_load        (we=wr,l1b_mode=norm ,from_noc_or_sc=noc,sys_gap=253,sub_gap=1,sub_len=4,addr=36,sys_len=16,mv_last_dis=0,cfifo_en=1,bar=0)
noc_req (comd_type=4, bar=0) // 检查是否完成bias搬运
NOC_cfg (addr=98  , wdata=0,cfifo_wdata=0,cfifo_en=0) // 关闭多节点合并读
NOC_cfg (addr=99  , wdata=0,cfifo_wdata=0,cfifo_en=0) // 直接从ddr读取数据
NOC_cfg (addr=100 , wdata=0 ,cfifo_wdata=0,cfifo_en=0) // 关闭pingpong
NOC_cfg (addr=101 , wdata=0,cfifo_wdata=0,cfifo_en=0) // 本地ram ping 基地址
NOC_cfg (addr=103 , wdata=0,cfifo_wdata=0,cfifo_en=0) // ddr地址偏移
NOC_cfg (addr=104 , wdata=0,cfifo_wdata=0,cfifo_en=0) // ddr地址偏移
NOC_cfg (addr=108 , wdata=1,cfifo_wdata=0,cfifo_en=0) // 最内层循环递增，每次读入256bit
NOC_cfg (addr=112 , wdata=2047,cfifo_wdata=0,cfifo_en=0) // fmap总长度2048-1
NOC_cfg (addr=113 , wdata=0,cfifo_wdata=0,cfifo_en=0) //不采用pingpong
NOC_cfg (addr=114 , wdata=2047,cfifo_wdata=0,cfifo_en=0)  // fmap总长度2048-1
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
next_fetch_is_cpu
wfi
CVEC_cfg2       (cal_mode=norm_conv,wreg_wr_cnt=0,fprec=INT8,wprec=INT8,v_tq=0)
MQ_cfg0         (gpu_mode=0,para_mode=0,tcache_mode=16CH_SFIFO,one_ram_base_addr=40,tcache_trans_swbank=0,tcache_trans_prici=INT8,mv_cub_dst_sel=weight,wr_hl_mask=0)
MQ_cfg1         (sub_gap=1, sys_gap_ext=0b00000, iob_pric=INT8, iob_l2c_in_cfg=0, tcache_mvfmap_stride=0, tcache_mvfmap_offset=0)
NOC_cfg (addr=0,wdata=1,cfifo_wdata=0,cfifo_en=0) // 相对寻址
NOC_cfg (addr=1,wdata=0,cfifo_wdata=0,cfifo_en=0) //读取本地L2
NOC_cfg (addr=2,wdata=0,cfifo_wdata=0,cfifo_en=0) // 关闭多节点合并读
NOC_cfg (addr=3,wdata=1,cfifo_wdata=0,cfifo_en=0) // 从片上读取数据
NOC_cfg (addr=4,wdata=0,cfifo_wdata=0,cfifo_en=0) // 关闭pingpong
NOC_cfg (addr=6,wdata=0,cfifo_wdata=0,cfifo_en=0) // 基地址偏移为0
NOC_cfg (addr=11,wdata=1,cfifo_wdata=0,cfifo_en=0) //最内层循环递增，每次读入256bit
NOC_cfg (addr=15,wdata=2047,cfifo_wdata=0,cfifo_en=0)  // fmap总长度2048-1
NOC_cfg (addr=16,wdata=0,cfifo_wdata=0,cfifo_en=0) //不采用pingpong  
NOC_cfg (addr=17,wdata=2047,cfifo_wdata=0,cfifo_en=0) // ping传输的长度2048-1
NOC_cfg (addr=19,wdata=0,cfifo_wdata=0,cfifo_en=0) //单播模式
NOC_cfg (addr=20,wdata=0,cfifo_wdata=0,cfifo_en=0) //不和任何节点同步
NOC_cfg (addr=21,wdata=0,cfifo_wdata=0,cfifo_en=0) // 读取base地址为cluster指令中的weight地址（每组不同的地址）
NOC_cfg (addr=31,wdata=1,cfifo_wdata=0,cfifo_en=0) //单独取指   
npu_load        (we=wr,l1b_mode=cache,from_noc_or_sc=noc,sys_gap=1,sub_gap=1  ,sub_len=0 ,addr=0,sys_len=8,mv_last_dis=0,cfifo_en=1,bar=0)
noc_req (comd_type=4, bar=0) // 检查是否完成fmap搬运
npu_mv          (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=1, addr=0,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=30,addr=0,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1)
conv3d_start    (first_sub_flag=1,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=1)
npu_mv          (we=rd,l1b_mode=norm,sys_gap=1,sub_gap=1,sub_len=1,addr=1,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=1, addr=2,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=30,addr=1024,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=2)
npu_mv          (we=rd,l1b_mode=norm,sys_gap=1,sub_gap=1,sub_len=1,addr=3,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=1, addr=4,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=30,addr=1,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=1)
npu_mv          (we=rd,l1b_mode=norm,sys_gap=1,sub_gap=1,sub_len=1,addr=5,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=1, addr=6,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=30,addr=1025,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=2)
npu_mv          (we=rd,l1b_mode=norm,sys_gap=1,sub_gap=1,sub_len=1,addr=7,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=1, addr=8,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=30,addr=2,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=1)
npu_mv          (we=rd,l1b_mode=norm,sys_gap=1,sub_gap=1,sub_len=1,addr=9,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=1, addr=10,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=30,addr=1026,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=2)
npu_mv          (we=rd,l1b_mode=norm,sys_gap=1,sub_gap=1,sub_len=1,addr=11,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=1, addr=12,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=30,addr=32,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=1)
npu_mv          (we=rd,l1b_mode=norm,sys_gap=1,sub_gap=1,sub_len=1,addr=13,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=1, addr=14,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=30,addr=1056,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=2)
npu_mv          (we=rd,l1b_mode=norm,sys_gap=1,sub_gap=1,sub_len=1,addr=15,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=1, addr=16,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=30,addr=33,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=1)
npu_mv          (we=rd,l1b_mode=norm,sys_gap=1,sub_gap=1,sub_len=1,addr=17,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=1, addr=18,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=30,addr=1057,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=2)
npu_mv          (we=rd,l1b_mode=norm,sys_gap=1,sub_gap=1,sub_len=1,addr=19,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=1, addr=20,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=30,addr=34,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=1)
npu_mv          (we=rd,l1b_mode=norm,sys_gap=1,sub_gap=1,sub_len=1,addr=21,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=1, addr=22,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=30,addr=1058,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=2)
npu_mv          (we=rd,l1b_mode=norm,sys_gap=1,sub_gap=1,sub_len=1,addr=23,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=1, addr=24,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=30,addr=64,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=1)
npu_mv          (we=rd,l1b_mode=norm,sys_gap=1,sub_gap=1,sub_len=1,addr=25,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=1, addr=26,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=30,addr=1088,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=2)
npu_mv          (we=rd,l1b_mode=norm,sys_gap=1,sub_gap=1,sub_len=1,addr=27,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=1, addr=28,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=30,addr=65,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=1)
npu_mv          (we=rd,l1b_mode=norm,sys_gap=1,sub_gap=1,sub_len=1,addr=29,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=1, addr=30,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=30,addr=1089,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=2)
npu_mv          (we=rd,l1b_mode=norm,sys_gap=1,sub_gap=1,sub_len=1,addr=31,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=1, addr=32,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=30,addr=66,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=1)
npu_mv          (we=rd,l1b_mode=norm,sys_gap=1,sub_gap=1,sub_len=1,addr=33,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=1, addr=34,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=30,addr=1090,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=2)
npu_mv          (we=rd,l1b_mode=norm,sys_gap=1,sub_gap=1,sub_len=1,addr=35,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=0)cub_alu_insn_fill(addr=0,num=15)
cub.lw.l1b x1, 576(x0)
cub.lw.l1b x2, 580(x0)
cub.lw.l1b x3, 584(x0)
cub.lw.l1b x4, 588(x0)
cub.lw.l1b x5, 592(x0)
cub.lw.l1b x6, 596(x0)
cub.lw.l1b x7, 600(x0)
cub.lw.l1b x8, 604(x0)
cub.lw.l1b x9, 608(x0)
cub.lw.l1b x10, 612(x0)
cub.lw.l1b x11, 616(x0)
cub.lw.l1b x12, 620(x0)
cub.lw.l1b x13, 624(x0)
cub.lw.l1b x14, 628(x0)
cub.event_finish
VQ_alu_event_call(event_addr=0,bar=0)
VQ_alu_csrw(csr_addr=0,csr_wdata=0b11000)
VQ_NOP(bar=3,nop_cycle_num=0)
MQ_NOP(bar=3,nop_cycle_num=0)
VQ_alu_csrw(csr_addr=2,csr_wdata=0b001000100010000)
VQ_alu_csrw(csr_addr=3,csr_wdata=0b0000100010)
VQ_alu_csrw(csr_addr=4,csr_wdata=0b0000000)
VQ_alu_csrw(csr_addr=5,csr_wdata=0b0000000010001000)
VQ_alu_csrw(csr_addr=6,csr_wdata=0b111100)
VQ_alu_csrw(csr_addr=7,csr_wdata=0b100001111)
VQ_alu_csrw(csr_addr=8,csr_wdata=0b1)
psum_rd(rd_num=29,rd_ch_sel=0,rd_rgb_sel=0,scache_wr_addr=0,scache_wr_size=byte,run_cycle_num=37,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=1, addr=0,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=30,addr=32,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1)
conv3d_start    (first_sub_flag=1,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=1)
npu_mv          (we=rd,l1b_mode=norm,sys_gap=1,sub_gap=1,sub_len=1,addr=1,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=1, addr=2,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=30,addr=1056,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=2)
npu_mv          (we=rd,l1b_mode=norm,sys_gap=1,sub_gap=1,sub_len=1,addr=3,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=1, addr=4,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=30,addr=33,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=1)
npu_mv          (we=rd,l1b_mode=norm,sys_gap=1,sub_gap=1,sub_len=1,addr=5,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=1, addr=6,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=30,addr=1057,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=2)
npu_mv          (we=rd,l1b_mode=norm,sys_gap=1,sub_gap=1,sub_len=1,addr=7,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=1, addr=8,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=30,addr=34,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=1)
npu_mv          (we=rd,l1b_mode=norm,sys_gap=1,sub_gap=1,sub_len=1,addr=9,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=1, addr=10,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=30,addr=1058,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=2)
npu_mv          (we=rd,l1b_mode=norm,sys_gap=1,sub_gap=1,sub_len=1,addr=11,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=1, addr=12,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=30,addr=64,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=1)
npu_mv          (we=rd,l1b_mode=norm,sys_gap=1,sub_gap=1,sub_len=1,addr=13,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=1, addr=14,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=30,addr=1088,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=2)
npu_mv          (we=rd,l1b_mode=norm,sys_gap=1,sub_gap=1,sub_len=1,addr=15,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=1, addr=16,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=30,addr=65,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=1)
npu_mv          (we=rd,l1b_mode=norm,sys_gap=1,sub_gap=1,sub_len=1,addr=17,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=1, addr=18,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=30,addr=1089,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=2)
npu_mv          (we=rd,l1b_mode=norm,sys_gap=1,sub_gap=1,sub_len=1,addr=19,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=1, addr=20,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=30,addr=66,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=1)
npu_mv          (we=rd,l1b_mode=norm,sys_gap=1,sub_gap=1,sub_len=1,addr=21,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=1, addr=22,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=30,addr=1090,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=2)
npu_mv          (we=rd,l1b_mode=norm,sys_gap=1,sub_gap=1,sub_len=1,addr=23,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=1, addr=24,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=30,addr=96,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=1)
npu_mv          (we=rd,l1b_mode=norm,sys_gap=1,sub_gap=1,sub_len=1,addr=25,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=1, addr=26,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=30,addr=1120,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=2)
npu_mv          (we=rd,l1b_mode=norm,sys_gap=1,sub_gap=1,sub_len=1,addr=27,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=1, addr=28,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=30,addr=97,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=1)
npu_mv          (we=rd,l1b_mode=norm,sys_gap=1,sub_gap=1,sub_len=1,addr=29,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=1, addr=30,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=30,addr=1121,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=2)
npu_mv          (we=rd,l1b_mode=norm,sys_gap=1,sub_gap=1,sub_len=1,addr=31,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=1, addr=32,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=30,addr=98,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=1)
npu_mv          (we=rd,l1b_mode=norm,sys_gap=1,sub_gap=1,sub_len=1,addr=33,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=norm ,sys_gap=1,sub_gap=1,sub_len=1, addr=34,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv          (we=rd,l1b_mode=cache,sys_gap=1,sub_gap=1,sub_len=30,addr=1122,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=2)
npu_mv          (we=rd,l1b_mode=norm,sys_gap=1,sub_gap=1,sub_len=1,addr=35,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start    (first_sub_flag=0,start_index=0,end_index=29,tcache_stride=0,tcache_offset=0,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,bc_group=0,pad0_sel=end, pad0_len=0, run_cycle_num=32,cfifo_en=1,bar=0)
VQ_NOP(bar=0,nop_cycle_num=4)
psum_rd(rd_num=29,rd_ch_sel=0,rd_rgb_sel=0,scache_wr_addr=15,scache_wr_size=byte,run_cycle_num=37,cfifo_en=1,bar=0)
VQ_alu_csrw(csr_addr=0,csr_wdata=0b11001)
VQ_alu_csrw(csr_addr=2,csr_wdata=0b000000000000000)
VQ_alu_csrw(csr_addr=3,csr_wdata=0b0000110000)
VQ_alu_csrw(csr_addr=7,csr_wdata=0b0000000100001111)
VQ_alu_csrw(csr_addr=8,csr_wdata=0b1)
VQ_alu_csrw(csr_addr=10,csr_wdata=0b0000111100000010)
VQ_alu_csrw(csr_addr=11,csr_wdata=0b1111)
VQ_alu_csrw(csr_addr=12,csr_wdata=0b1111110010)
VQ_scache_wr_en(addr=256,size=byte,wr_cycle_num=36,wait_type=0,cfifo_en=1,bar=0)
VQ_scache_rd_en(addr=0,size=byte,sign_ext=1,rd_cycle_num=36,wait_type=1,cfifo_en=1,bar=0)
VQ_alu_csrw(csr_addr=0,csr_wdata=0b10000)
VQ_alu_csrw(csr_addr=10,csr_wdata=0b100001111)
VQ_alu_csrw(csr_addr=11,csr_wdata=0b1)
VQ_alu_csrw(csr_addr=12,csr_wdata=0b0)
NOC_cfg (addr=34,wdata=0,cfifo_wdata=0,cfifo_en=0)           // 数据直接输出到ddr
NOC_cfg (addr=35,wdata=0,cfifo_wdata=0,cfifo_en=0)            // 关闭pingpong
NOC_cfg (addr=37,wdata=0,cfifo_wdata=0,cfifo_en=0)           // 输出基地址偏移为0，地址为3200
NOC_cfg (addr=42,wdata=1,cfifo_wdata=0,cfifo_en=0)           //最内层循环递增，每次读入256bit
NOC_cfg (addr=46,wdata=14,cfifo_wdata=0,cfifo_en=0)             // 输出总长度15-1
NOC_cfg (addr=47,wdata=0,cfifo_wdata=0,cfifo_en=0)           //不采用pingpong
NOC_cfg (addr=48,wdata=14,cfifo_wdata=0,cfifo_en=0)            // ping传输的长度15-1
npu_store (cfifo_en=0, bar=0)
VQ_scache_rd_en(addr=256,size=byte,sign_ext=1,rd_cycle_num=15,wait_type=1,cfifo_en=1,bar=0)next_fetch_is_cpu
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