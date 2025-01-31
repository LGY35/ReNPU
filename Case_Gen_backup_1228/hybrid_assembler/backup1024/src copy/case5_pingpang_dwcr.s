
CVEC_cfg2                      (cal_mode=norm_conv,wreg_wr_cnt=0,fprec=INT8,wprec=INT8,v_tq=0)
MQ_cfg0                        (gpu_mode=0,para_mode=0,tcache_mode=16CH_SFIFO,one_ram_base_addr=40,tcache_trans_swbank=0,tcache_trans_prici=INT8,mv_cub_dst_sel=weight,wr_hl_mask=0)

NOC_cfg (addr=96  , wdata=0 )
NOC_cfg (addr=97  , wdata=0 )
NOC_cfg (addr=98  , wdata=0 )
NOC_cfg (addr=99  , wdata=0 )
NOC_cfg (addr=100 , wdata=1 )   # pingpang 使能
NOC_cfg (addr=101 , wdata=0 )   # 本地ram ping基地址    bank0
NOC_cfg (addr=102 , wdata=4096 )   # 本地ram pang基地址    bank4
NOC_cfg (addr=103 , wdata=512 )
NOC_cfg (addr=104 , wdata=0 )
NOC_cfg (addr=105 , wdata=0 )
NOC_cfg (addr=106 , wdata=0 )
NOC_cfg (addr=107 , wdata=0 )
NOC_cfg (addr=108 , wdata=1 )
NOC_cfg (addr=109 , wdata=0 )
NOC_cfg (addr=110 , wdata=0 )
NOC_cfg (addr=111 , wdata=0)
NOC_cfg (addr=112 , wdata=17)   # loop lenth
NOC_cfg (addr=113 , wdata=3)    # pingpangnum = 24/4*2 = 3
NOC_cfg (addr=114 , wdata=3)    # ping lenth  # 一次取4个数
NOC_cfg (addr=115 , wdata=3 )   # pang lenth
NOC_cfg (addr=116 , wdata=0 ) 
NOC_cfg (addr=117 , wdata=0 )   
NOC_cfg (addr=118 , wdata=0 )
noc_req (comd_type=3, bar=1)
noc_req (comd_type=4, bar=1)
NOC_cfg (addr=103 , wdata=530 )
NOC_cfg (addr=114 , wdata=1)    # ping lenth 一次取2两个数 一共6个
NOC_cfg (addr=115 , wdata=1 )   # pang lenth
NOC_cfg (addr=118 , wdata=1)
noc_req (comd_type=3, bar=1)
noc_req (comd_type=4, bar=1)


NOC_cfg (addr=0 , wdata=0 )
NOC_cfg (addr=1 , wdata=0 )
NOC_cfg (addr=2 , wdata=0 )
NOC_cfg (addr=3 , wdata=1 )    # 1片上读取
NOC_cfg (addr=4 , wdata=1 )    # 打开pingpang
NOC_cfg (addr=5 , wdata=0 )
NOC_cfg (addr=6 , wdata=0 )  # ping基地址
NOC_cfg (addr=7 , wdata=4096 ) # pang基地址
NOC_cfg (addr=8 , wdata=0 )  # gap0
NOC_cfg (addr=9 , wdata=0 )  # gap1
NOC_cfg (addr=10 , wdata=0 )  # gap2 
NOC_cfg (addr=11 , wdata=1 )  # gap3
NOC_cfg (addr=12 , wdata=0 )  # lenth0
NOC_cfg (addr=13 , wdata=0 )  # lenth1
NOC_cfg (addr=14 , wdata=0)   # lenth2
NOC_cfg (addr=15 , wdata=17)  # lenth3
NOC_cfg (addr=16 , wdata=3)   # pingpangnum = 24/4*2 = 3
NOC_cfg (addr=17 , wdata=3)
NOC_cfg (addr=18 , wdata=3)
NOC_cfg (addr=19 , wdata=0)     
NOC_cfg (addr=20 , wdata=0)
NOC_cfg (addr=21 , wdata=0)   # 取权重
NOC_cfg (addr=22 , wdata=2)
NOC_cfg (addr=23 , wdata=2)
NOC_cfg (addr=24 , wdata=4)
NOC_cfg (addr=25 , wdata=4)
NOC_cfg (addr=26 , wdata=2)   #有效行数
NOC_cfg (addr=27 , wdata=3)   #有效列数
NOC_cfg (addr=28 , wdata=0)   #pad mode
NOC_cfg (addr=29 , wdata=0)   
NOC_cfg (addr=30 , wdata=1)   #单核取指

npu_load                       (we=wr,l1b_mode=norm ,tcache_bank_num=0,sys_gap=221,sub_gap=1,sub_len=36,addr=0,sys_len=16,mv_last_dis=0,cfifo_en=1,bar=0) //load_weight
npu_load                       (we=wr,l1b_mode=norm ,tcache_bank_num=0,sys_gap=253,sub_gap=1,sub_len=4,addr=36,sys_len=16,mv_last_dis=0,cfifo_en=1,bar=0) //load_scale_param
npu_load                       (we=wr,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1  ,sub_len=0 ,addr=0,sys_len=8,mv_last_dis=0,cfifo_en=1,bar=0) //load_fmap
npu_mv                         (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1, addr=0,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv                         (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=30,addr=0,sys_len=1,mv_last_dis=0,cfifo_en=0,bar=1)
conv3d_start                   (first_sub_flag=1,start_index=0,end_index=29,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=1) //100000_00000_000_0_011110_0=0x20003C
npu_mv                         (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=1,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=0) //100000_00000_000_1_011110_0=0x2000BC

npu_mv                         (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1, addr=2,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv                         (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=30,addr=1024,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=2)
npu_mv                         (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=3,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=0)

npu_mv                         (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1, addr=4,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv                         (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=30,addr=1,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=16,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=1)
npu_mv                         (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=5,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=16,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=0)

npu_mv                         (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1, addr=6,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv                         (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=30,addr=1025,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=2)
npu_mv                         (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=7,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=0)

npu_mv                         (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1, addr=8,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv                         (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=30,addr=2,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=16,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=1)
npu_mv                         (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=9,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=16,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=0)

npu_mv                         (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1, addr=10,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv                         (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=30,addr=1026,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=2)
npu_mv                         (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=11,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=16,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=0)

npu_mv                         (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1, addr=12,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv                         (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=30,addr=32,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=16,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=1)
npu_mv                         (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=13,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=16,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=0)

npu_mv                         (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1, addr=14,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv                         (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=30,addr=1056,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=2)
npu_mv                         (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=15,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=16,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=0)

npu_mv                         (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1, addr=16,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv                         (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=30,addr=33,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=16,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=1)
npu_mv                         (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=17,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=16,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=0)

npu_mv                         (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1, addr=18,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv                         (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=30,addr=1057,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=2)
npu_mv                         (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=19,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=16,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=0)

npu_mv                         (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1, addr=20,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv                         (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=30,addr=34,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=16,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=1)
npu_mv                         (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=21,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=16,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=0)

npu_mv                         (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1, addr=22,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv                         (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=30,addr=1058,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=2)
npu_mv                         (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=23,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=16,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=0)

npu_mv                         (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1, addr=24,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv                         (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=30,addr=64,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=16,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=1)
npu_mv                         (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=25,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=16,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=0)

npu_mv                         (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1, addr=26,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv                         (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=30,addr=1088,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=2)
npu_mv                         (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=27,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=16,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=0)

npu_mv                         (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1, addr=28,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv                         (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=30,addr=65,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=16,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=1)
npu_mv                         (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=29,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=16,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=0)

npu_mv                         (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1, addr=30,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv                         (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=30,addr=1089,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=2)
npu_mv                         (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=31,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=16,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=0)

npu_mv                         (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1, addr=32,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv                         (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=30,addr=66,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=16,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=1)
npu_mv                         (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=33,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=16,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=0)

npu_mv                         (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1, addr=34,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv                         (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=30,addr=1090,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=2)
npu_mv                         (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=35,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=16,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=3)
cub_alu_insn_fill(addr=0,num=15) //post-processing
cub.lw.l1b x1, 576(x0)  //fill start 
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
cub.lw.l1b x14, 628(x0) //0_010 0111 0100_00000_010_01110_100_1101
cub.event_finish        //fill end
MQ_NOP(bar=3) //11_000000000000000000000_001_1001
MQ_cfg0(gpu_mode=1,para_mode=0,tcache_mode=16CH_SFIFO,one_ram_base_addr=40,tcache_trans_swbank=0,tcache_trans_prici=INT8,mv_cub_dst_sel=weight,wr_hl_mask=0)
VQ_alu_event_call(event_addr=0,bar=0)
VQ_alu_csrw(csr_addr=0,csr_wdata=0b1100) //alu_flow_cfg0: cflow_mode,scache_dout_flow_sel,alu_din_flow_sel
VQ_alu_csrw(csr_addr=2,csr_wdata=0b001000100010000) //crossbar cfg
VQ_alu_csrw(csr_addr=3,csr_wdata=0b0000100010) //crossbar cfg
VQ_alu_csrw(csr_addr=4,csr_wdata=0b0000000) //acti_work_mode 
VQ_alu_csrw(csr_addr=5,csr_wdata=0b0000000010001100) //pool_cfg
VQ_alu_csrw(csr_addr=6,csr_wdata=0b11110) //pool_cfg（pool_cflow_data_len=30）
VQ_alu_csrw(csr_addr=7,csr_wdata=0b100001111) //scache wr0
VQ_alu_csrw(csr_addr=8,csr_wdata=0b1) //scache wr1
psum_rd(rd_num=29,rd_ch_sel=0,scache_wr_addr=0,scache_wr_size=byte,run_cycle_num=37,cfifo_en=1,bar=0)

MQ_cfg0                        (gpu_mode=0,para_mode=0,tcache_mode=16CH_SFIFO,one_ram_base_addr=40,tcache_trans_swbank=0,tcache_trans_prici=INT8,mv_cub_dst_sel=weight,wr_hl_mask=0)
npu_mv                         (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1, addr=0,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv                         (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=30,addr=32,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1)
conv3d_start                   (first_sub_flag=1,start_index=0,end_index=29,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=1) //100000_00000_000_0_011110_0=0x20003C
npu_mv                         (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=1,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=0) //100000_00000_000_1_011110_0=0x2000BC

npu_mv                         (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1, addr=2,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv                         (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=30,addr=1056,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=2)
npu_mv                         (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=3,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=0)

npu_mv                         (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1, addr=4,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv                         (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=30,addr=33,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=16,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=1)
npu_mv                         (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=5,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=16,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=0)

npu_mv                         (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1, addr=6,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv                         (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=30,addr=1057,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=2)
npu_mv                         (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=7,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=0)

npu_mv                         (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1, addr=8,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv                         (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=30,addr=34,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=16,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=1)
npu_mv                         (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=9,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=16,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=0)

npu_mv                         (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1, addr=10,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv                         (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=30,addr=1058,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=2)
npu_mv                         (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=11,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=16,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=0)
         
npu_mv                         (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1, addr=12,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv                         (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=30,addr=64,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=16,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=1)
npu_mv                         (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=13,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=16,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=0)

npu_mv                         (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1, addr=14,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv                         (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=30,addr=1088,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=2)
npu_mv                         (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=15,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=16,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=0)

npu_mv                         (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1, addr=16,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv                         (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=30,addr=65,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=16,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=1)
npu_mv                         (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=17,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=16,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=0)

npu_mv                         (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1, addr=18,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv                         (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=30,addr=1089,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=2)
npu_mv                         (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=19,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=16,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=0)

npu_mv                         (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1, addr=20,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv                         (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=30,addr=66,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=16,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=1)
npu_mv                         (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=21,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=16,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=0)

npu_mv                         (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1, addr=22,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv                         (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=30,addr=1090,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=2)
npu_mv                         (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=23,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=16,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=0)

npu_mv                         (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1, addr=24,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv                         (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=30,addr=96,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=16,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=1)
npu_mv                         (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=25,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=16,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=0)

npu_mv                         (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1, addr=26,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv                         (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=30,addr=1120,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=2)
npu_mv                         (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=27,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=16,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=0)

npu_mv                         (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1, addr=28,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv                         (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=30,addr=97,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=16,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=1)
npu_mv                         (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=29,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=16,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=0)

npu_mv                         (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1, addr=30,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv                         (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=30,addr=1121,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=2)
npu_mv                         (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=31,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=16,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=0)

npu_mv                         (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1, addr=32,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv                         (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=30,addr=98,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=1)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=16,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=1)
npu_mv                         (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=33,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=16,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=0)

npu_mv                         (we=rd,l1b_mode=norm ,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1, addr=34,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
npu_mv                         (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=30,addr=1122,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=2)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=30,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=0,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=2)
npu_mv                         (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=35,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
conv3d_start                   (first_sub_flag=0,start_index=0,end_index=29,bc_mode=0,bc_len=16,rgba_mode=0,rgba_stride=0,rgba_shift=0,hl_op=1,bc_keep_2cycle_en=0,pad0_sel=end,pad0_len=0,run_cycle_num=32,cfifo_en=1,bar=0)
VQ_NOP(bar=0) //100_000000000000000000_010_0001
VQ_NOP(bar=0) //100_000000000000000000_010_0001
VQ_NOP(bar=0) //100_000000000000000000_010_0001
psum_rd(rd_num=29,rd_ch_sel=0,scache_wr_addr=0,scache_wr_size=byte,run_cycle_num=37,cfifo_en=1,bar=0)
VQ_alu_csrw(csr_addr=0,csr_wdata=0b1101) //alu_flow_cfg0: cflow_mode,scache_dout_flow_sel,alu_din_flow_sel
VQ_alu_csrw(csr_addr=2,csr_wdata=0b000000000000000) //crossbar_cfg0
VQ_alu_csrw(csr_addr=3,csr_wdata=0b0000110000) //crossbar_cfg1
VQ_alu_csrw(csr_addr=7,csr_wdata=0b0000000100001111) //scache_wr0
VQ_alu_csrw(csr_addr=8,csr_wdata=0b1) //scache_wr1
VQ_alu_csrw(csr_addr=10,csr_wdata=0b0000111100000010) //scache_rd0 (sub_len=2,sys_len=15)
VQ_alu_csrw(csr_addr=11,csr_wdata=0b1111) //scache_rd1 (sub_gap=15)
VQ_alu_csrw(csr_addr=12,csr_wdata=0b1111110010) //scache_rd2 (sys_gap=-14)
VQ_scache_wr_en(addr=256,size=byte,wr_cycle_num=36,wait_type=0,cfifo_en=0,bar=0)
VQ_scache_rd_en(addr=0,size=byte,sign_ext=1,rd_cycle_num=36,wait_type=1,cfifo_en=1,bar=0)
VQ_alu_csrw(csr_addr=0,csr_wdata=0b1000) //alu_flow_cfg0: cflow_mode,scache_dout_flow_sel,alu_din_flow_sel
VQ_alu_csrw(csr_addr=10,csr_wdata=0b100001111) //scache_rd0 (sub_len=1,sys_len=15)
VQ_alu_csrw(csr_addr=11,csr_wdata=0b1) //scache_rd1 (sub_gap=1)
VQ_alu_csrw(csr_addr=12,csr_wdata=0b0) //scache_rd2 (sys_gap=0)
VQ_scache_rd_en(addr=256,size=byte,sign_ext=1,rd_cycle_num=15,wait_type=1,cfifo_en=1,bar=0)
next_fetch_is_cpu
wfi