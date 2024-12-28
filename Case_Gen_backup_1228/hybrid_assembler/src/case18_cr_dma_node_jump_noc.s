# 取20行（16 + pad2行）

next_fetch_is_npu
# core rd
NOC_cfg ( addr=0 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 0 绝对寻址
NOC_cfg ( addr=1 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 
NOC_cfg ( addr=2 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 0 多节点读合并关 当一起读的时候开，不一起读的时候关 ==============
NOC_cfg ( addr=3 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 0 片外读取
NOC_cfg ( addr=4 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 0 pingpang 关
NOC_cfg ( addr=5 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 目标节点
NOC_cfg ( addr=6 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # ping基地址 ==============
NOC_cfg ( addr=7 , wdata=80, cfifo_wdata=0,cfifo_en=0 )     # pang 基地址作为base addr b
NOC_cfg ( addr=8 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # gap0 
NOC_cfg ( addr=9 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # gap1
NOC_cfg ( addr=10 , wdata=0, cfifo_wdata=0,cfifo_en=0 )    # gap2 
NOC_cfg ( addr=11 , wdata=1, cfifo_wdata=0,cfifo_en=0 )    # gap3
NOC_cfg ( addr=12 , wdata=0, cfifo_wdata=0,cfifo_en=0 )    # lenth0
NOC_cfg ( addr=13 , wdata=0, cfifo_wdata=0,cfifo_en=0 )    # lenth1
NOC_cfg ( addr=14 , wdata=0, cfifo_wdata=0,cfifo_en=0)     # lenth2
NOC_cfg ( addr=15 , wdata=39, cfifo_wdata=0,cfifo_en=0)   # loop lenth 640/8 = 80, 取一半40
NOC_cfg ( addr=16 , wdata=0, cfifo_wdata=0,cfifo_en=0)   
NOC_cfg ( addr=17 , wdata=799, cfifo_wdata=0,cfifo_en=0)   # ping lenth = 总长度20*40=800
NOC_cfg ( addr=18 , wdata=0, cfifo_wdata=0,cfifo_en=0)     # 
NOC_cfg ( addr=19 , wdata=0, cfifo_wdata=0,cfifo_en=0)     # 广播的范围 north_id, east_id, south_id, west_id centernode==============
NOC_cfg ( addr=20 , wdata=0, cfifo_wdata=0,cfifo_en=0)     # 同步的目标 ==============
NOC_cfg ( addr=21 , wdata=0, cfifo_wdata=0,cfifo_en=0)     # weight ==============
NOC_cfg ( addr=29 , wdata=39, cfifo_wdata=0,cfifo_en=0 )   # 单行长度
NOC_cfg ( addr=30 , wdata=321, cfifo_wdata=0,cfifo_en=0)     # dmaloop gap # gap2整行，也就是160  然后最低位是enable为1，所以160*2+1=321
NOC_cfg ( addr=31 , wdata=10, cfifo_wdata=0,cfifo_en=0 )   # dmaloop num    20/2  
npu_load (we=wr,l1b_mode=norm ,tcache_bank_num=0,sys_gap=221,sub_gap=1,sub_len=36,addr=0,sys_len=16,mv_last_dis=0,cfifo_en=0,bar=0) //load_weight
noc_req (comd_type=4, bar=0 )
MQ_NOP (bar=0, nop_cycle_num=1)
MQ_NOP (bar=0, nop_cycle_num=1)
MQ_NOP (bar=0, nop_cycle_num=1)
MQ_NOP (bar=0, nop_cycle_num=1)
MQ_NOP (bar=0, nop_cycle_num=1)
MQ_NOP (bar=0, nop_cycle_num=1)
MQ_NOP (bar=0, nop_cycle_num=1)


NOC_cfg ( addr=0 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 0 绝对寻址
NOC_cfg ( addr=1 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 
NOC_cfg ( addr=2 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 0 多节点读合并关 当一起读的时候开，不一起读的时候关 ==============
NOC_cfg ( addr=3 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 0 片外读取
NOC_cfg ( addr=4 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 0 pingpang 关
NOC_cfg ( addr=5 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 目标节点
NOC_cfg ( addr=6 , wdata=40, cfifo_wdata=0,cfifo_en=0 )     # ping基地址 ==============
NOC_cfg ( addr=7 , wdata=120, cfifo_wdata=0,cfifo_en=0 )     # pang 基地址作为base addr b
NOC_cfg ( addr=8 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # gap0 
NOC_cfg ( addr=9 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # gap1
NOC_cfg ( addr=10 , wdata=0, cfifo_wdata=0,cfifo_en=0 )    # gap2 
NOC_cfg ( addr=11 , wdata=1, cfifo_wdata=0,cfifo_en=0 )    # gap3
NOC_cfg ( addr=12 , wdata=0, cfifo_wdata=0,cfifo_en=0 )    # lenth0
NOC_cfg ( addr=13 , wdata=0, cfifo_wdata=0,cfifo_en=0 )    # lenth1
NOC_cfg ( addr=14 , wdata=0, cfifo_wdata=0,cfifo_en=0)     # lenth2
NOC_cfg ( addr=15 , wdata=39, cfifo_wdata=0,cfifo_en=0)   # loop lenth 640/8 = 80, 取一半40
NOC_cfg ( addr=16 , wdata=0, cfifo_wdata=0,cfifo_en=0)   
NOC_cfg ( addr=17 , wdata=799, cfifo_wdata=0,cfifo_en=0)   # ping lenth = 总长度20*40=800
NOC_cfg ( addr=18 , wdata=0, cfifo_wdata=0,cfifo_en=0)     # 
NOC_cfg ( addr=19 , wdata=0, cfifo_wdata=0,cfifo_en=0)     # 广播的范围 north_id, east_id, south_id, west_id centernode==============
NOC_cfg ( addr=20 , wdata=0, cfifo_wdata=0,cfifo_en=0)     # 同步的目标 ==============
NOC_cfg ( addr=21 , wdata=0, cfifo_wdata=0,cfifo_en=0)     # weight ==============
NOC_cfg ( addr=29 , wdata=39, cfifo_wdata=0,cfifo_en=0 )   # 单行长度
NOC_cfg ( addr=30 , wdata=321, cfifo_wdata=0,cfifo_en=0)     # dmaloop gap # gap2整行，也就是160  然后最低位是enable为1，所以160*2+1=321
NOC_cfg ( addr=31 , wdata=10, cfifo_wdata=0,cfifo_en=0 )   # dmaloop num    20/2  
noc_req (comd_type=4, bar=0 )
MQ_NOP (bar=0, nop_cycle_num=1)
MQ_NOP (bar=0, nop_cycle_num=1)
MQ_NOP (bar=0, nop_cycle_num=1)
MQ_NOP (bar=0, nop_cycle_num=1)
MQ_NOP (bar=0, nop_cycle_num=1)
MQ_NOP (bar=0, nop_cycle_num=1)
MQ_NOP (bar=0, nop_cycle_num=1)
next_fetch_is_cpu
wfi