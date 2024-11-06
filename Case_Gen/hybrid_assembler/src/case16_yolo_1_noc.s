## write back 地址 起始地址以及每次生成数据的size  
## 1. 第一次可以输出16行，分2次输出。8行 8*320*256bit
## npu load 指令  顺序以及每次的长度 
## store 指令 
npu_store ( cfifo_en=1, bar=0)
## pad 最后补零时候的要求 外部还是内部填充 16*2 
## 2行pad不补


#### group 0 (node 8 9) 
# 取权重
next_fetch_is_npu
NOC_cfg (addr=0 , wdata=0 )     # 0 绝对寻址
NOC_cfg (addr=1 , wdata=0 )     # 
NOC_cfg (addr=2 , wdata=0 )     # 0 多节点读合并关 当一起读的时候开，不一起读的时候关 ==============
NOC_cfg (addr=3 , wdata=0 )     # 0 片外读取
NOC_cfg (addr=4 , wdata=0 )     # 0 pingpang 关
NOC_cfg (addr=5 , wdata=0 )     # 目标节点
NOC_cfg (addr=6 , wdata=0 )     # ping基地址 ==============
NOC_cfg (addr=7 , wdata=0 )
NOC_cfg (addr=8 , wdata=0 )     # gap0 
NOC_cfg (addr=9 , wdata=0 )     # gap1
NOC_cfg (addr=10 , wdata=0 )    # gap2 
NOC_cfg (addr=11 , wdata=1 )    # gap3
NOC_cfg (addr=12 , wdata=0 )    # lenth0
NOC_cfg (addr=13 , wdata=0 )    # lenth1
NOC_cfg (addr=14 , wdata=0)     # lenth2
NOC_cfg (addr=15 , wdata=575)   # lenth3 取权重576个 ==============
NOC_cfg (addr=16 , wdata=0)   
NOC_cfg (addr=17 , wdata=575)   # ping length ==============
NOC_cfg (addr=18 , wdata=0)     # 
NOC_cfg (addr=19 , wdata=0)     # 广播的范围 north_id, east_id, south_id, west_id centernode==============
NOC_cfg (addr=20 , wdata=0)     # 同步的目标 ==============
NOC_cfg (addr=21 , wdata=0)     # weight ==============
#NOC_cfg (addr=22 , wdata=0)    # 左边
#NOC_cfg (addr=23 , wdata=0)    # 右边
#NOC_cfg (addr=24 , wdata=0)    # 上
#NOC_cfg (addr=25 , wdata=0)    # 下
#NOC_cfg (addr=26 , wdata=0)    # 有效行数
#NOC_cfg (addr=27 , wdata=0)    # 有效列数
#NOC_cfg (addr=28 , wdata=0)    # pad mode 0是补0, 1是补边缘相同
NOC_cfg (addr=29 , wdata=0) 
NOC_cfg (addr=30 , wdata=1)     # 1单核取指
npu_load
# 取参数  
NOC_cfg (addr=6 , wdata=576 )   # ping基地址 取参数在weight的基础上加576==============
NOC_cfg (addr=15 , wdata=64)    # lenth3 取数据 ==============
NOC_cfg (addr=17 , wdata=64)    # ping length ==============
//TODO: 这里保持是取weight的地址吗？ 
# 取激活 32行+2
NOC_cfg (addr=2 , wdata=1 )     # 1 多节点读合并开  
NOC_cfg (addr=6 , wdata=0 )     # ping基地址 第一部分激活直接用基地址==============
NOC_cfg (addr=15 , wdata=2719)  # lenth3 取数据 ==============
NOC_cfg (addr=17 , wdata=2719)  # ping length ==============
NOC_cfg (addr=19 , wdata=3512)     # 广播的范围 north_id, east_id, south_id, west_id centernode 1101 1011 1000
NOC_cfg (addr=20 , wdata=768)   # 同步的目标 12bit中选取对应bit 0011 0000 0000
NOC_cfg (addr=21 , wdata=1)     # feature 
npu_load
# 取激活 16行+4
NOC_cfg (addr=6 , wdata= 2400)  # ping基地址 ============== 2720 - 160*2
NOC_cfg (addr=15 , wdata=1599)  # lenth3 取数据 
NOC_cfg (addr=17 , wdata=1599)  # ping length 
npu_load
# 取激活 16行+4
NOC_cfg (addr=6 , wdata= 3680)  # ping基地址 ============== 2560 + 1600-160*2 - 160
npu_load
# 取激活 16行+4
NOC_cfg (addr=6 , wdata= 4960)  # ping基地址 ==============
npu_load
# 取激活 16行+4
NOC_cfg (addr=6 , wdata= 6240)  # ping基地址 ==============
npu_load
# 取激活 16行+2  最后2行不用补
NOC_cfg (addr=6 , wdata= 7520)  # ping基地址 ==============
NOC_cfg (addr=15 , wdata=1439)  # lenth3 取数据 ==============
NOC_cfg (addr=17 , wdata=1439)  # ping length ==============
npu_load
noc_req (comd_type=4, bar=0)


npu_load (we=wr,l1b_mode=norm ,tcache_bank_num=0,sys_gap=221,sub_gap=1,sub_len=36,addr=0,sys_len=16,mv_last_dis=0,cfifo_en=1,bar=0) //load_weight  576
npu_load (we=wr,l1b_mode=norm ,tcache_bank_num=0,sys_gap=253,sub_gap=1,sub_len=4,addr=36,sys_len=16,mv_last_dis=0,cfifo_en=1,bar=0) //load_scale_param 64 每次取完权重就要取一次这个，跟weight一样
npu_load (we=wr,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1  ,sub_len=0 ,addr=0,sys_len=8,mv_last_dis=0,cfifo_en=1,bar=0) //load_fmap 34 640 4 


#### group 1 (node 0 2 4 6) 
# 取权重
next_fetch_is_npu
NOC_cfg (addr=0 , wdata=0 )     # 0 绝对寻址
NOC_cfg (addr=1 , wdata=0 )     # 
NOC_cfg (addr=2 , wdata=0 )     # 0 多节点读合并关 当一起读的时候开，不一起读的时候关 ==============
NOC_cfg (addr=3 , wdata=0 )     # 0 片外读取
NOC_cfg (addr=4 , wdata=0 )     # 0 pingpang 关
NOC_cfg (addr=5 , wdata=0 )     # 目标节点
NOC_cfg (addr=6 , wdata=0 )     # ping基地址 ==============
NOC_cfg (addr=7 , wdata=0 )
NOC_cfg (addr=8 , wdata=0 )     # gap0 
NOC_cfg (addr=9 , wdata=0 )     # gap1
NOC_cfg (addr=10 , wdata=0 )    # gap2 
NOC_cfg (addr=11 , wdata=1 )    # gap3
NOC_cfg (addr=12 , wdata=0 )    # lenth0
NOC_cfg (addr=13 , wdata=0 )    # lenth1
NOC_cfg (addr=14 , wdata=0)     # lenth2
NOC_cfg (addr=15 , wdata=575)   # lenth3 取权重576个 ==============
NOC_cfg (addr=16 , wdata=0)   
NOC_cfg (addr=17 , wdata=575)   # ping length ==============
NOC_cfg (addr=18 , wdata=0)     # 
NOC_cfg (addr=19 , wdata=0)     # 广播的范围 north_id, east_id, south_id, west_id centernode==============
NOC_cfg (addr=20 , wdata=0)     # 同步的目标 ==============
NOC_cfg (addr=21 , wdata=0)     # weight ==============
#NOC_cfg (addr=22 , wdata=0)    # 左边
#NOC_cfg (addr=23 , wdata=0)    # 右边
#NOC_cfg (addr=24 , wdata=0)    # 上
#NOC_cfg (addr=25 , wdata=0)    # 下
#NOC_cfg (addr=26 , wdata=0)    # 有效行数
#NOC_cfg (addr=27 , wdata=0)    # 有效列数
#NOC_cfg (addr=28 , wdata=0)    # pad mode 0是补0, 1是补边缘相同
NOC_cfg (addr=29 , wdata=0) 
NOC_cfg (addr=30 , wdata=1)     # 1单核取指
npu_load
# 取参数  
NOC_cfg (addr=6 , wdata=576 )   # ping基地址 取参数在weight的基础上加576==============
NOC_cfg (addr=15 , wdata=64)    # lenth3 取数据 ==============
NOC_cfg (addr=17 , wdata=64)    # ping length ==============
//TODO: 这里保持是取weight的地址吗？ 
# 取激活 32行+2
NOC_cfg (addr=2 , wdata=1 )     # 1 多节点读合并开  
NOC_cfg (addr=6 , wdata=0 )     # ping基地址 第一部分激活直接用基地址==============
NOC_cfg (addr=15 , wdata=2719)  # lenth3 取数据 ==============
NOC_cfg (addr=17 , wdata=2719)  # ping length ==============
NOC_cfg (addr=19 , wdata=3512)     # 广播的范围 north_id, east_id, south_id, west_id centernode 1101 1011 1000
NOC_cfg (addr=20 , wdata=768)   # 同步的目标 12bit中选取对应bit 0011 0000 0000
NOC_cfg (addr=21 , wdata=1)     # feature 
npu_load
# 取激活 16行+4
NOC_cfg (addr=6 , wdata= 2400)  # ping基地址 ============== 2720 - 160*2
NOC_cfg (addr=15 , wdata=1599)  # lenth3 取数据 
NOC_cfg (addr=17 , wdata=1599)  # ping length 
npu_load
# 取激活 16行+4
NOC_cfg (addr=6 , wdata= 3680)  # ping基地址 ============== 2560 + 1600-160*2 - 160
npu_load
# 取激活 16行+4
NOC_cfg (addr=6 , wdata= 4960)  # ping基地址 ==============
npu_load
# 取激活 16行+4
NOC_cfg (addr=6 , wdata= 6240)  # ping基地址 ==============
npu_load
# 取激活 16行+2  最后2行不用补
NOC_cfg (addr=6 , wdata= 7520)  # ping基地址 ==============
NOC_cfg (addr=15 , wdata=1439)  # lenth3 取数据 ==============
NOC_cfg (addr=17 , wdata=1439)  # ping length ==============
npu_load
noc_req (comd_type=4, bar=0)


npu_load                       (we=wr,l1b_mode=norm ,tcache_bank_num=0,sys_gap=221,sub_gap=1,sub_len=36,addr=0,sys_len=16,mv_last_dis=0,cfifo_en=1,bar=0) //load_weight
npu_load                       (we=wr,l1b_mode=norm ,tcache_bank_num=0,sys_gap=253,sub_gap=1,sub_len=4,addr=36,sys_len=16,mv_last_dis=0,cfifo_en=1,bar=0) //load_scale_param
npu_load                       (we=wr,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1  ,sub_len=0 ,addr=0,sys_len=8,mv_last_dis=0,cfifo_en=1,bar=0) //load_fmap


#### group 3 (node 10 11) 
# 取权重
next_fetch_is_npu
NOC_cfg (addr=0 , wdata=0 )     # 0 绝对寻址
NOC_cfg (addr=1 , wdata=0 )     # 
NOC_cfg (addr=2 , wdata=0 )     # 0 多节点读合并关 当一起读的时候开，不一起读的时候关 ==============
NOC_cfg (addr=3 , wdata=0 )     # 0 片外读取
NOC_cfg (addr=4 , wdata=0 )     # 0 pingpang 关
NOC_cfg (addr=5 , wdata=0 )     # 目标节点
NOC_cfg (addr=6 , wdata=0 )     # ping基地址 ==============
NOC_cfg (addr=7 , wdata=0 )
NOC_cfg (addr=8 , wdata=0 )     # gap0 
NOC_cfg (addr=9 , wdata=0 )     # gap1
NOC_cfg (addr=10 , wdata=0 )    # gap2 
NOC_cfg (addr=11 , wdata=1 )    # gap3
NOC_cfg (addr=12 , wdata=0 )    # lenth0
NOC_cfg (addr=13 , wdata=0 )    # lenth1
NOC_cfg (addr=14 , wdata=0)     # lenth2
NOC_cfg (addr=15 , wdata=575)   # lenth3 取权重576个 ==============
NOC_cfg (addr=16 , wdata=0)   
NOC_cfg (addr=17 , wdata=575)   # ping length ==============
NOC_cfg (addr=18 , wdata=0)     # 
NOC_cfg (addr=19 , wdata=0)     # 广播的范围 north_id, east_id, south_id, west_id centernode==============
NOC_cfg (addr=20 , wdata=0)     # 同步的目标 ==============
NOC_cfg (addr=21 , wdata=0)     # weight ==============
#NOC_cfg (addr=22 , wdata=0)    # 左边
#NOC_cfg (addr=23 , wdata=0)    # 右边
#NOC_cfg (addr=24 , wdata=0)    # 上
#NOC_cfg (addr=25 , wdata=0)    # 下
#NOC_cfg (addr=26 , wdata=0)    # 有效行数
#NOC_cfg (addr=27 , wdata=0)    # 有效列数
#NOC_cfg (addr=28 , wdata=0)    # pad mode 0是补0, 1是补边缘相同
NOC_cfg (addr=29 , wdata=0) 
NOC_cfg (addr=30 , wdata=1)     # 1单核取指
npu_load
# 取参数  
NOC_cfg (addr=6 , wdata=576 )   # ping基地址 取参数在weight的基础上加576==============
NOC_cfg (addr=15 , wdata=64)    # lenth3 取数据 ==============
NOC_cfg (addr=17 , wdata=64)    # ping length ==============
//TODO: 这里保持是取weight的地址吗？ 
# 取激活 32行+2
NOC_cfg (addr=2 , wdata=1 )     # 1 多节点读合并开  
NOC_cfg (addr=6 , wdata=0 )     # ping基地址 第一部分激活直接用基地址==============
NOC_cfg (addr=15 , wdata=2719)  # lenth3 取数据 ==============
NOC_cfg (addr=17 , wdata=2719)  # ping length ==============
NOC_cfg (addr=19 , wdata=3512)     # 广播的范围 north_id, east_id, south_id, west_id centernode 1101 1011 1000
NOC_cfg (addr=20 , wdata=768)   # 同步的目标 12bit中选取对应bit 0011 0000 0000
NOC_cfg (addr=21 , wdata=1)     # feature 
npu_load
# 取激活 16行+4
NOC_cfg (addr=6 , wdata= 2400)  # ping基地址 ============== 2720 - 160*2
NOC_cfg (addr=15 , wdata=1599)  # lenth3 取数据 
NOC_cfg (addr=17 , wdata=1599)  # ping length 
npu_load
# 取激活 16行+4
NOC_cfg (addr=6 , wdata= 3680)  # ping基地址 ============== 2560 + 1600-160*2 - 160
npu_load
# 取激活 16行+4
NOC_cfg (addr=6 , wdata= 4960)  # ping基地址 ==============
npu_load
# 取激活 16行+4
NOC_cfg (addr=6 , wdata= 6240)  # ping基地址 ==============
npu_load
# 取激活 16行+2  最后2行不用补
NOC_cfg (addr=6 , wdata= 7520)  # ping基地址 ==============
NOC_cfg (addr=15 , wdata=1439)  # lenth3 取数据 ==============
NOC_cfg (addr=17 , wdata=1439)  # ping length ==============
npu_load
noc_req (comd_type=4, bar=0)


npu_load                       (we=wr,l1b_mode=norm ,tcache_bank_num=0,sys_gap=221,sub_gap=1,sub_len=36,addr=0,sys_len=16,mv_last_dis=0,cfifo_en=1,bar=0) //load_weight
npu_load                       (we=wr,l1b_mode=norm ,tcache_bank_num=0,sys_gap=253,sub_gap=1,sub_len=4,addr=36,sys_len=16,mv_last_dis=0,cfifo_en=1,bar=0) //load_scale_param
npu_load                       (we=wr,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1  ,sub_len=0 ,addr=0,sys_len=8,mv_last_dis=0,cfifo_en=1,bar=0) //load_fmap




MQ_NOP(bar=0)
MQ_NOP(bar=0)
MQ_NOP(bar=0)
MQ_NOP(bar=0)
MQ_NOP(bar=0)
MQ_NOP(bar=0)
MQ_NOP(bar=0)
