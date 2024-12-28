## write back 地址 起始地址以及每次生成数据的size  
## 1. 第一次可以输出16行，分2次输出。8行 8*320*256bit
## npu load 指令  顺序以及每次的长度 
## store 指令 
## npu_store ( cfifo_en=1, bar=0)



#### group 0 (node 8 9) 
# 取权重
next_fetch_is_npu
NOC_cfg ( addr=0 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 0 绝对寻址
NOC_cfg ( addr=1 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 
NOC_cfg ( addr=2 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 0 多节点读合并关 当一起读的时候开，不一起读的时候关 ==============
NOC_cfg ( addr=3 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 0 片外读取
NOC_cfg ( addr=4 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 0 pingpang 关
NOC_cfg ( addr=5 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 目标节点
NOC_cfg ( addr=6 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # ping基地址 ==============
NOC_cfg ( addr=7 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=8 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # gap0 
NOC_cfg ( addr=9 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # gap1
NOC_cfg ( addr=10 , wdata=0, cfifo_wdata=0,cfifo_en=0 )    # gap2 
NOC_cfg ( addr=11 , wdata=1, cfifo_wdata=0,cfifo_en=0 )    # gap3
NOC_cfg ( addr=12 , wdata=0, cfifo_wdata=0,cfifo_en=0 )    # lenth0
NOC_cfg ( addr=13 , wdata=0, cfifo_wdata=0,cfifo_en=0 )    # lenth1
NOC_cfg ( addr=14 , wdata=0, cfifo_wdata=0,cfifo_en=0)     # lenth2
NOC_cfg ( addr=15 , wdata=575, cfifo_wdata=0,cfifo_en=0)   # lenth3 取权重576个 ==============
NOC_cfg ( addr=16 , wdata=0, cfifo_wdata=0,cfifo_en=0)   
NOC_cfg ( addr=17 , wdata=575, cfifo_wdata=0,cfifo_en=0)   # ping length ==============
NOC_cfg ( addr=18 , wdata=0, cfifo_wdata=0,cfifo_en=0)     # 
NOC_cfg ( addr=19 , wdata=0, cfifo_wdata=0,cfifo_en=0)     # 广播的范围 north_id, east_id, south_id, west_id centernode==============
NOC_cfg ( addr=20 , wdata=0, cfifo_wdata=0,cfifo_en=0)     # 同步的目标 ==============
NOC_cfg ( addr=21 , wdata=0, cfifo_wdata=0,cfifo_en=0)     # weight ==============
NOC_cfg ( addr=29 , wdata=0, cfifo_wdata=0,cfifo_en=0)     # loop disable ==============
#npu_load
# 取参数  
NOC_cfg ( addr=6 , wdata=576, cfifo_wdata=0,cfifo_en=0)    # ping基地址 取参数在weight的基础上加576==============
NOC_cfg ( addr=15 , wdata=63, cfifo_wdata=0,cfifo_en=0)    # lenth3 取数据 ==============
NOC_cfg ( addr=17 , wdata=63, cfifo_wdata=0,cfifo_en=0)    # ping length ==============
# 取激活 32行+2
NOC_cfg ( addr=2 , wdata=1, cfifo_wdata=0,cfifo_en=0 )     # 1 多节点读合并开  
NOC_cfg ( addr=6 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # ping基地址 第一部分激活直接用基地址==============
NOC_cfg ( addr=7 , wdata=80, cfifo_wdata=0,cfifo_en=0 )    # 比上一个地址+80==============
NOC_cfg ( addr=15 , wdata=39, cfifo_wdata=0,cfifo_en=0)   # lenth3 设置为单行要取的长度
NOC_cfg ( addr=17 , wdata=1359, cfifo_wdata=0,cfifo_en=0  )  # ping length   34*40=1360
NOC_cfg ( addr=19 , wdata=926, cfifo_wdata=0,cfifo_en=0)  # 广播的范围 north_id, east_id, south_id, west_id centernode  1110 0111 1000
NOC_cfg ( addr=20 , wdata=768, cfifo_wdata=0,cfifo_en=0)   # 同步的目标 12bit中选取对应bit 0011 0000 0000
NOC_cfg ( addr=21 , wdata=1, cfifo_wdata=0,cfifo_en=0)     # feature 
NOC_cfg ( addr=29 , wdata=39, cfifo_wdata=0,cfifo_en=0)     #  一行有：640*32/256 = 80；一次取40  十进制数80 40
NOC_cfg ( addr=30 , wdata=321, cfifo_wdata=0,cfifo_en=0)   # dmaloop gap # gap2整行，也就是160  然后最低位是enable为1，所以160*2+1=321
NOC_cfg ( addr=31 , wdata=17, cfifo_wdata=0,cfifo_en=0)    # loop num 取多少行 34/2 = 17==============
#npu_load
# 取激活 16行+4
NOC_cfg ( addr=6 , wdata= 2400, cfifo_wdata=0,cfifo_en=0)  # ping基地址 ============== 2720 - 160*2
NOC_cfg ( addr=7 , wdata= 2480, cfifo_wdata=0,cfifo_en=0)    # 比上一个地址+80==============
NOC_cfg ( addr=17 , wdata=799 , cfifo_wdata=0,cfifo_en=0)  # ping length   20*40=800
NOC_cfg ( addr=31 , wdata=10, cfifo_wdata=0,cfifo_en=0)    # loop num 取多少行 20/2 = 10==============
#npu_load
# 取激活 16行+4
NOC_cfg ( addr=6 , wdata= 3680, cfifo_wdata=0,cfifo_en=0)  # ping基地址 ============== 2560 + 1600-160*2 - 160
NOC_cfg ( addr=7 , wdata= 3760, cfifo_wdata=0,cfifo_en=0)    # 比上一个地址+80==============
#npu_load
# 取激活 16行+4
NOC_cfg ( addr=6 , wdata= 4960, cfifo_wdata=0,cfifo_en=0)  # ping基地址 ==============
NOC_cfg ( addr=7 , wdata= 5040, cfifo_wdata=0,cfifo_en=0)    # 比上一个地址+80==============
#npu_load
# 取激活 16行+4
NOC_cfg ( addr=6 , wdata= 6240, cfifo_wdata=0,cfifo_en=0)  # ping基地址 ==============
NOC_cfg ( addr=7 , wdata= 6320, cfifo_wdata=0,cfifo_en=0)    # 比上一个地址+80==============
#npu_load
# 取激活 16行+2  最后2行不用补
NOC_cfg ( addr=6 , wdata= 7520, cfifo_wdata=0,cfifo_en=0)  # ping基地址 ==============
NOC_cfg ( addr=7 , wdata= 7600, cfifo_wdata=0,cfifo_en=0)    # 比上一个地址+80==============
NOC_cfg ( addr=30 , wdata=9, cfifo_wdata=0,cfifo_en=0)    # loop num 取多少行 18/2 = 9==============
#npu_load
noc_req (comd_type=4, bar=0)


#npu_load (we=wr,l1b_mode=norm ,tcache_bank_num=0,sys_gap=221,sub_gap=1,sub_len=36,addr=0,sys_len=16,mv_last_dis=0,cfifo_en=1,bar=0) //load_weight  576
#npu_load (we=wr,l1b_mode=norm ,tcache_bank_num=0,sys_gap=253,sub_gap=1,sub_len=4,addr=36,sys_len=16,mv_last_dis=0,cfifo_en=1,bar=0) //load_scale_param 64 每次取完权重就要取一次这个，跟weight一样
#npu_load (we=wr,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1  ,sub_len=0 ,addr=0,sys_len=8,mv_last_dis=0,cfifo_en=1,bar=0) //load_fmap 34 640 4 


#### group 1 (node 0 2 4 6) 
# 取权重
next_fetch_is_npu
NOC_cfg ( addr=0 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 0 绝对寻址
NOC_cfg ( addr=1 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 
NOC_cfg ( addr=2 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 1 多节点读合并开 当一起读的时候开，不一起读的时候关 ==============
NOC_cfg ( addr=3 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 0 片外读取
NOC_cfg ( addr=4 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 0 pingpang 关
NOC_cfg ( addr=5 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 目标节点
NOC_cfg ( addr=6 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # ping基地址 ==============
NOC_cfg ( addr=7 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=8 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # gap0 
NOC_cfg ( addr=9 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # gap1
NOC_cfg ( addr=10 , wdata=0, cfifo_wdata=0,cfifo_en=0 )    # gap2 
NOC_cfg ( addr=11 , wdata=1, cfifo_wdata=0,cfifo_en=0 )    # gap3
NOC_cfg ( addr=12 , wdata=0, cfifo_wdata=0,cfifo_en=0 )    # lenth0
NOC_cfg ( addr=13 , wdata=0, cfifo_wdata=0,cfifo_en=0 )    # lenth1
NOC_cfg ( addr=14 , wdata=0, cfifo_wdata=0,cfifo_en=0)     # lenth2
NOC_cfg ( addr=15 , wdata=575, cfifo_wdata=0,cfifo_en=0)   # lenth3 取权重576个 ==============
NOC_cfg ( addr=16 , wdata=0, cfifo_wdata=0,cfifo_en=0)   
NOC_cfg ( addr=17 , wdata=575, cfifo_wdata=0,cfifo_en=0)   # ping length ==============
NOC_cfg ( addr=18 , wdata=0, cfifo_wdata=0,cfifo_en=0)     # 
NOC_cfg ( addr=19 , wdata=148, cfifo_wdata=0,cfifo_en=0)     # 广播的范围 north_id, east_id, south_id, west_id centernode  0000 1001 0100 ==============
NOC_cfg ( addr=20 , wdata=85, cfifo_wdata=0,cfifo_en=0)     # 同步的目标 0000 0101 0101==============
NOC_cfg ( addr=21 , wdata=0, cfifo_wdata=0,cfifo_en=0)     # weight ==============
NOC_cfg ( addr=29 , wdata=0, cfifo_wdata=0,cfifo_en=0)     # loop disable ==============
#npu_loadcfifo_en=0, 
# 取参数 cfifo_en=0,  
NOC_cfg ( addr=6 , wdata=576, cfifo_wdata=0,cfifo_en=0 )   # ping基地址 取参数在weight的基础上加576==============
NOC_cfg ( addr=15 , wdata=63, cfifo_wdata=0,cfifo_en=0)    # lenth3 取数据 ==============
NOC_cfg ( addr=17 , wdata=63, cfifo_wdata=0,cfifo_en=0)    # ping length ==============
# 取激活 cfifo_en=0, 32行+2
NOC_cfg ( addr=2 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 0 多节点读合并关   
NOC_cfg ( addr=6 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # ping基地址 第一部分激活直接用基地址==============
NOC_cfg ( addr=7 , wdata=80, cfifo_wdata=0,cfifo_en=0 )    # 比上一个地址+80==============
NOC_cfg ( addr=15 , wdata=39, cfifo_wdata=0,cfifo_en=0)   # lenth3 设置为单行要取的长度
NOC_cfg ( addr=17 , wdata=1359, cfifo_wdata=0,cfifo_en=0  )  # ping length   34*40=1360
NOC_cfg ( addr=19 , wdata=0, cfifo_wdata=0,cfifo_en=0)     # 广播的范围 north_id, east_id, south_id, west_id centernode 
NOC_cfg ( addr=20 , wdata=0, cfifo_wdata=0,cfifo_en=0)     # 同步的目标 12bit中选取对应bit 
NOC_cfg ( addr=21 , wdata=1, cfifo_wdata=0,cfifo_en=0)     # feature 
NOC_cfg ( addr=29 , wdata=39, cfifo_wdata=0,cfifo_en=0)     #  一行有：640*32/256 = 80；一次取40  十进制数80 40
NOC_cfg ( addr=30 , wdata=321, cfifo_wdata=0,cfifo_en=0)   # dmaloop gap # gap2整行，也就是160  然后最低位是enable为1，所以160*2+1=321
NOC_cfg ( addr=31 , wdata=17, cfifo_wdata=0,cfifo_en=0)    # loop num 取多少行 34/2 = 17==============
#npu_load
# 取激活 16行+4
NOC_cfg ( addr=6 , wdata= 2400, cfifo_wdata=0,cfifo_en=0)  # ping基地址 ============== 2720 - 160*2
NOC_cfg ( addr=7 , wdata= 2480, cfifo_wdata=0,cfifo_en=0)    # 比上一个地址+80==============
NOC_cfg ( addr=17 , wdata=799 , cfifo_wdata=0,cfifo_en=0)  # ping length   20*40=800
NOC_cfg ( addr=31 , wdata=10, cfifo_wdata=0,cfifo_en=0)    # loop num 取多少行 20/2 = 10==============
#npu_load
# 取激活 16行+4
NOC_cfg ( addr=6 , wdata= 3680, cfifo_wdata=0,cfifo_en=0)  # ping基地址 ============== 2560 + 1600-160*2 - 160
NOC_cfg ( addr=7 , wdata= 3760, cfifo_wdata=0,cfifo_en=0)    # 比上一个地址+80==============
#npu_load
# 取激活 16行+4
NOC_cfg ( addr=6 , wdata= 4960, cfifo_wdata=0,cfifo_en=0)  # ping基地址 ==============
NOC_cfg ( addr=7 , wdata= 5040, cfifo_wdata=0,cfifo_en=0)    # 比上一个地址+80==============
#npu_load
# 取激活 16行+4
NOC_cfg ( addr=6 , wdata= 6240, cfifo_wdata=0,cfifo_en=0)  # ping基地址 ==============
NOC_cfg ( addr=7 , wdata= 6320, cfifo_wdata=0,cfifo_en=0)    # 比上一个地址+80==============
#npu_load
# 取激活 16行+2  最后2行不用补
NOC_cfg ( addr=6 , wdata= 7520, cfifo_wdata=0,cfifo_en=0)  # ping基地址 ==============
NOC_cfg ( addr=7 , wdata= 7600, cfifo_wdata=0,cfifo_en=0)    # 比上一个地址+80==============
NOC_cfg ( addr=30 , wdata=9, cfifo_wdata=0,cfifo_en=0)    # loop num 取多少行 18/2 = 9==============
#npu_load
noc_req (comd_type=4, bar=0)


#### group 2 (node 1 3 5 7) 
# 取权重
next_fetch_is_npu
NOC_cfg ( addr=0 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 0 绝对寻址
NOC_cfg ( addr=1 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 
NOC_cfg ( addr=2 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 1 多节点读合并开 当一起读的时候开，不一起读的时候关 ==============
NOC_cfg ( addr=3 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 0 片外读取
NOC_cfg ( addr=4 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 0 pingpang 关
NOC_cfg ( addr=5 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 目标节点
NOC_cfg ( addr=6 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # ping基地址 ==============
NOC_cfg ( addr=7 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=8 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # gap0 
NOC_cfg ( addr=9 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # gap1
NOC_cfg ( addr=10 , wdata=0, cfifo_wdata=0,cfifo_en=0 )    # gap2 
NOC_cfg ( addr=11 , wdata=1, cfifo_wdata=0,cfifo_en=0 )    # gap3
NOC_cfg ( addr=12 , wdata=0, cfifo_wdata=0,cfifo_en=0 )    # lenth0
NOC_cfg ( addr=13 , wdata=0, cfifo_wdata=0,cfifo_en=0 )    # lenth1
NOC_cfg ( addr=14 , wdata=0, cfifo_wdata=0,cfifo_en=0)     # lenth2
NOC_cfg ( addr=15 , wdata=575, cfifo_wdata=0,cfifo_en=0)   # lenth3 取权重576个 ==============
NOC_cfg ( addr=16 , wdata=0, cfifo_wdata=0,cfifo_en=0)   
NOC_cfg ( addr=17 , wdata=575, cfifo_wdata=0,cfifo_en=0)   # ping length ==============
NOC_cfg ( addr=18 , wdata=0, cfifo_wdata=0,cfifo_en=0)     # 
NOC_cfg ( addr=19 , wdata=1495, cfifo_wdata=0,cfifo_en=0)     # 广播的范围 north_id, east_id, south_id, west_id centernode  0101 1101 0111 ==============
NOC_cfg ( addr=20 , wdata=170, cfifo_wdata=0,cfifo_en=0)     # 同步的目标 0000 1010 1010==============
NOC_cfg ( addr=21 , wdata=0, cfifo_wdata=0,cfifo_en=0)     # weight ==============
NOC_cfg ( addr=29 , wdata=0, cfifo_wdata=0,cfifo_en=0)     # loop disable ==============
#npu_load
# 取参数  
NOC_cfg ( addr=6 , wdata=576, cfifo_wdata=0,cfifo_en=0 )   # ping基地址 取参数在weight的基础上加576==============
NOC_cfg ( addr=15 , wdata=64, cfifo_wdata=0,cfifo_en=0)    # lenth3 取数据 ==============
NOC_cfg ( addr=17 , wdata=64, cfifo_wdata=0,cfifo_en=0)    # ping length ==============
# 取激活 32行+2
NOC_cfg ( addr=2 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 0 多节点读合并关  
NOC_cfg ( addr=6 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # ping基地址 第一部分激活直接用基地址==============
NOC_cfg ( addr=15 , wdata=39, cfifo_wdata=0,cfifo_en=0)   # lenth3 设置为单行要取的长度
NOC_cfg ( addr=17 , wdata=1359, cfifo_wdata=0,cfifo_en=0  )  # ping length   34*40=1360
NOC_cfg ( addr=19 , wdata=0, cfifo_wdata=0,cfifo_en=0)     # 广播的范围 north_id, east_id, south_id, west_id centernode 
NOC_cfg ( addr=20 , wdata=0, cfifo_wdata=0,cfifo_en=0)   # 同步的目标 12bit中选取对应bit 
NOC_cfg ( addr=21 , wdata=1, cfifo_wdata=0,cfifo_en=0)     # feature 
NOC_cfg ( addr=29 , wdata=39, cfifo_wdata=0,cfifo_en=0)     #  一行有：640*32/256 = 80；一次取40  十进制数80 40
NOC_cfg ( addr=30 , wdata=321, cfifo_wdata=0,cfifo_en=0)   # dmaloop gap # gap2整行，也就是160  然后最低位是enable为1，所以160*2+1=321
NOC_cfg ( addr=31 , wdata=17, cfifo_wdata=0,cfifo_en=0)    # loop num 取多少行 34/2 = 17==============
#npu_load
# 取激活 16行+4
NOC_cfg (addr=6 , wdata= 2400, cfifo_wdata=0,cfifo_en=0)  # ping基地址 ============== 2720 - 160*2
NOC_cfg (addr=7 , wdata= 2480, cfifo_wdata=0,cfifo_en=0)    # 比上一个地址+80==============
NOC_cfg (addr=17 , wdata=799 , cfifo_wdata=0,cfifo_en=0)  # ping length   20*40=800
NOC_cfg (addr=31 , wdata=10, cfifo_wdata=0,cfifo_en=0)    # loop num 取多少行 20/2 = 10==============
#npu_load
# 取激活 16行+4
NOC_cfg (addr=6 , wdata= 3680, cfifo_wdata=0,cfifo_en=0)  # ping基地址 ============== 2560 + 1600-160*2 - 160
NOC_cfg (addr=7 , wdata= 3760, cfifo_wdata=0,cfifo_en=0)    # 比上一个地址+80==============
#npu_load
# 取激活 16行+4
NOC_cfg (addr=6 , wdata= 4960, cfifo_wdata=0,cfifo_en=0)  # ping基地址 ==============
NOC_cfg (addr=7 , wdata= 5040, cfifo_wdata=0,cfifo_en=0)    # 比上一个地址+80==============
#npu_load
# 取激活 16行+4
NOC_cfg (addr=6 , wdata= 6240, cfifo_wdata=0,cfifo_en=0)  # ping基地址 ==============
NOC_cfg (addr=7 , wdata= 6320, cfifo_wdata=0,cfifo_en=0)    # 比上一个地址+80==============
#npu_load
# 取激活 16行+2  最后2行不用补
NOC_cfg (addr=6 , wdata= 7520, cfifo_wdata=0,cfifo_en=0)  # ping基地址 ==============
NOC_cfg (addr=7 , wdata= 7600, cfifo_wdata=0,cfifo_en=0)    # 比上一个地址+80==============
NOC_cfg (addr=30 , wdata=9  , cfifo_wdata=0,cfifo_en=0)    # loop num 取多少行 18/2 = 9==============
#npu_load
noc_req (comd_type=4, bar=0)


#### group 3 (node 10 11) 
# 取权重
next_fetch_is_npu
NOC_cfg (addr=0 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 0 绝对寻址
NOC_cfg (addr=1 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 
NOC_cfg (addr=2 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 0 多节点读合并关 当一起读的时候开，不一起读的时候关 ==============
NOC_cfg (addr=3 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 0 片外读取
NOC_cfg (addr=4 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 0 pingpang 关
NOC_cfg (addr=5 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 目标节点
NOC_cfg (addr=6 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # ping基地址 ==============
NOC_cfg (addr=7 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg (addr=8 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # gap0 
NOC_cfg (addr=9 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # gap1
NOC_cfg (addr=10 , wdata=0, cfifo_wdata=0,cfifo_en=0 )    # gap2 
NOC_cfg (addr=11 , wdata=1, cfifo_wdata=0,cfifo_en=0 )    # gap3
NOC_cfg (addr=12 , wdata=0, cfifo_wdata=0,cfifo_en=0 )    # lenth0
NOC_cfg (addr=13 , wdata=0, cfifo_wdata=0,cfifo_en=0 )    # lenth1
NOC_cfg (addr=14 , wdata=0, cfifo_wdata=0,cfifo_en=0)     # lenth2
NOC_cfg (addr=15 , wdata=575, cfifo_wdata=0,cfifo_en=0)   # lenth3 取权重576个 ==============
NOC_cfg (addr=16 , wdata=0, cfifo_wdata=0,cfifo_en=0)   
NOC_cfg (addr=17 , wdata=575, cfifo_wdata=0,cfifo_en=0)   # ping length ==============
NOC_cfg (addr=18 , wdata=0, cfifo_wdata=0,cfifo_en=0)     # 
NOC_cfg (addr=19 , wdata=155, cfifo_wdata=0,cfifo_en=0)     # 广播的范围 north_id, east_id, south_id, west_id centernode  0000 1001 1011 ==============
NOC_cfg (addr=20 , wdata=3072, cfifo_wdata=0,cfifo_en=0)     # 同步的目标 1100 0000 0000==============
NOC_cfg (addr=21 , wdata=0, cfifo_wdata=0,cfifo_en=0)     # weight ==============
NOC_cfg (addr=29 , wdata=0, cfifo_wdata=0,cfifo_en=0)     # loop disable ==============
#npu_load
# 取参数  
NOC_cfg (addr=6 , wdata=576, cfifo_wdata=0,cfifo_en=0 )   # ping基地址 取参数在weight的基础上加576==============
NOC_cfg (addr=15 , wdata=64, cfifo_wdata=0,cfifo_en=0)    # lenth3 取数据 ==============
NOC_cfg (addr=17 , wdata=64, cfifo_wdata=0,cfifo_en=0)    # ping length ==============
# 取激活 32行+2
NOC_cfg (addr=2 , wdata=1, cfifo_wdata=0,cfifo_en=0 )     # 1 多节点读合并开  
NOC_cfg (addr=6 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # ping基地址 第一部分激活直接用基地址==============
NOC_cfg (addr=7 , wdata=80, cfifo_wdata=0,cfifo_en=0 )    # 比上一个地址+80==============
NOC_cfg (addr=15 , wdata=39, cfifo_wdata=0,cfifo_en=0)   # lenth3 设置为单行要取的长度
NOC_cfg (addr=17 , wdata=1359, cfifo_wdata=0,cfifo_en=0  )  # ping length   34*40=1360
NOC_cfg (addr=19 , wdata=3704, cfifo_wdata=0,cfifo_en=0)  # 广播的范围 north_id, east_id, south_id, west_id centernode  1110 0111 1000
NOC_cfg (addr=20 , wdata=768, cfifo_wdata=0,cfifo_en=0)   # 同步的目标 12bit中选取对应bit 0011 0000 0000
NOC_cfg (addr=21 , wdata=1, cfifo_wdata=0,cfifo_en=0)     # feature 
NOC_cfg (addr=29 , wdata=39, cfifo_wdata=0,cfifo_en=0)     #  一行有：640*32/256 = 80；一次取40  十进制数80 40
NOC_cfg (addr=30 , wdata=321, cfifo_wdata=0,cfifo_en=0)   # dmaloop gap # gap2整行，也就是160  然后最低位是enable为1，所以160*2+1=321
NOC_cfg (addr=31 , wdata=17, cfifo_wdata=0,cfifo_en=0)    # loop num 取多少行 34/2 = 17==============
#npu_load
# 取激活 16行+4
NOC_cfg (addr=6 , wdata= 2400, cfifo_wdata=0,cfifo_en=0)  # ping基地址 ============== 2720 - 160*2
NOC_cfg (addr=7 , wdata= 2480, cfifo_wdata=0,cfifo_en=0)    # 比上一个地址+80==============
NOC_cfg (addr=17 , wdata=799 , cfifo_wdata=0,cfifo_en=0)  # ping length   20*40=800
NOC_cfg (addr=31 , wdata=10, cfifo_wdata=0,cfifo_en=0)    # loop num 取多少行 20/2 = 10==============
#npu_load
# 取激活 16行+4
NOC_cfg (addr=6 , wdata= 3680, cfifo_wdata=0,cfifo_en=0)  # ping基地址 ============== 2560 + 1600-160*2 - 160
NOC_cfg (addr=7 , wdata= 3760, cfifo_wdata=0,cfifo_en=0)    # 比上一个地址+80==============
#npu_load
# 取激活 16行+4
NOC_cfg (addr=6 , wdata= 4960, cfifo_wdata=0,cfifo_en=0)  # ping基地址 ==============
NOC_cfg (addr=7 , wdata= 5040, cfifo_wdata=0,cfifo_en=0)    # 比上一个地址+80==============
#npu_load
# 取激活 补pad
#NOC_cfg (addr=22 , wdata=0, cfifo_wdata=0,cfifo_en=0)    # 左边
#NOC_cfg (addr=23 , wdata=0, cfifo_wdata=0,cfifo_en=0)    # 右边
#NOC_cfg (addr=24 , wdata=0, cfifo_wdata=0,cfifo_en=0)    # 上
#NOC_cfg (addr=25 , wdata=0, cfifo_wdata=0,cfifo_en=0)    # 下
#NOC_cfg (addr=26 , wdata=0, cfifo_wdata=0,cfifo_en=0)    # 有效行数
#NOC_cfg (addr=27 , wdata=0, cfifo_wdata=0,cfifo_en=0)    # 有效列数
#NOC_cfg (addr=28 , wdata=0, cfifo_wdata=0,cfifo_en=0)    # pad mode 0是补0, 1是补边缘相同
#npu_load
noc_req (comd_type=4, bar=0)


#npu_load                       (we=wr,l1b_mode=norm ,tcache_bank_num=0,sys_gap=221,sub_gap=1,sub_len=36,addr=0,sys_len=16,mv_last_dis=0,cfifo_en=1,bar=0) //load_weight
#npu_load                       (we=wr,l1b_mode=norm ,tcache_bank_num=0,sys_gap=253,sub_gap=1,sub_len=4,addr=36,sys_len=16,mv_last_dis=0,cfifo_en=1,bar=0) //load_scale_param
#npu_load                       (we=wr,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1  ,sub_len=0 ,addr=0,sys_len=8,mv_last_dis=0,cfifo_en=1,bar=0) //load_fmap




#MQ_NOP (bar=0, nop_cycle_num=1)
#MQ_NOP (bar=0, nop_cycle_num=1)
#MQ_NOP (bar=0, nop_cycle_num=1)
#MQ_NOP (bar=0, nop_cycle_num=1)
#MQ_NOP (bar=0, nop_cycle_num=1)
#MQ_NOP (bar=0, nop_cycle_num=1)
#MQ_NOP (bar=0, nop_cycle_num=1)
