## 先dma wr，再core rd三次 与case3相同

# 取数数量: 576  56  2048

next_fetch_is_npu
# dma wr 第一次直接传进来2048个数即可
NOC_cfg (addr=96  , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg (addr=97  , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg (addr=98  , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg (addr=99  , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg (addr=100 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg (addr=101 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg (addr=102 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg (addr=103 , wdata=512, cfifo_wdata=0,cfifo_en=0)
NOC_cfg (addr=104 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg (addr=105 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg (addr=106 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg (addr=107 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg (addr=108 , wdata=1, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg (addr=109 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg (addr=110 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg (addr=111 , wdata=0, cfifo_wdata=0,cfifo_en=0)
NOC_cfg (addr=112 , wdata=2047, cfifo_wdata=0,cfifo_en=0)   # loop lenth
NOC_cfg (addr=113 , wdata=0, cfifo_wdata=0,cfifo_en=0)
NOC_cfg (addr=114 , wdata=2047, cfifo_wdata=0,cfifo_en=0)   # ping lenth
NOC_cfg (addr=115 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg (addr=116 , wdata=0, cfifo_wdata=0,cfifo_en=0 ) 
NOC_cfg (addr=117 , wdata=0, cfifo_wdata=0,cfifo_en=0 )   
NOC_cfg (addr=118 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
noc_req (comd_type=3, bar=0)
noc_req (comd_type=4, bar=0)

#####################################
# core rd 第一次取576个
NOC_cfg (addr=0 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg (addr=1 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg (addr=2 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg (addr=3 , wdata=1, cfifo_wdata=0,cfifo_en=0 )    # 1片上读取
NOC_cfg (addr=4 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg (addr=5 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg (addr=6 , wdata=0, cfifo_wdata=0,cfifo_en=0 )    # ping基地址 0
NOC_cfg (addr=7 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg (addr=8 , wdata=0, cfifo_wdata=0,cfifo_en=0 )  # gap0
NOC_cfg (addr=9 , wdata=0, cfifo_wdata=0,cfifo_en=0 )  # gap1
NOC_cfg (addr=10 , wdata=0, cfifo_wdata=0,cfifo_en=0 )  # gap2 
NOC_cfg (addr=11 , wdata=1, cfifo_wdata=0,cfifo_en=0 )  # gap3
NOC_cfg (addr=12 , wdata=0, cfifo_wdata=0,cfifo_en=0 )  # lenth0
NOC_cfg (addr=13 , wdata=0, cfifo_wdata=0,cfifo_en=0 )  # lenth1
NOC_cfg (addr=14 , wdata=0, cfifo_wdata=0,cfifo_en=0)   # lenth2
NOC_cfg (addr=15 , wdata=575, cfifo_wdata=0,cfifo_en=0)   # lenth3
NOC_cfg (addr=16 , wdata=0, cfifo_wdata=0,cfifo_en=0)   
NOC_cfg (addr=17 , wdata=575, cfifo_wdata=0,cfifo_en=0)
NOC_cfg (addr=18 , wdata=0, cfifo_wdata=0,cfifo_en=0)
NOC_cfg (addr=19 , wdata=0, cfifo_wdata=0,cfifo_en=0)
NOC_cfg (addr=20 , wdata=0, cfifo_wdata=0,cfifo_en=0)
NOC_cfg (addr=21 , wdata=0, cfifo_wdata=0,cfifo_en=0)   # 0 weight
noc_req (comd_type=4, bar=0)
MQ_NOP (bar=0, nop_cycle_num=1)
MQ_NOP (bar=0, nop_cycle_num=1)
MQ_NOP (bar=0, nop_cycle_num=1)
MQ_NOP (bar=0, nop_cycle_num=1)
MQ_NOP (bar=0, nop_cycle_num=1)
MQ_NOP (bar=0, nop_cycle_num=1)
MQ_NOP (bar=0, nop_cycle_num=1)

# core rd 第二次取64个
NOC_cfg (addr=6 , wdata=576 , cfifo_wdata=0,cfifo_en=0)    # ping基地址 0  
NOC_cfg (addr=17 , wdata=63, cfifo_wdata=0,cfifo_en=0)
NOC_cfg (addr=21 , wdata=0, cfifo_wdata=0,cfifo_en=0)   # 0weight
noc_req (comd_type=4, bar=0)
MQ_NOP (bar=0, nop_cycle_num=1)
MQ_NOP (bar=0, nop_cycle_num=1)
MQ_NOP (bar=0, nop_cycle_num=1)
MQ_NOP (bar=0, nop_cycle_num=1)
MQ_NOP (bar=0, nop_cycle_num=1)
MQ_NOP (bar=0, nop_cycle_num=1)
MQ_NOP (bar=0, nop_cycle_num=1)

# core rd 第二次取64个
NOC_cfg (addr=6 , wdata=640, cfifo_wdata=0,cfifo_en=0 )    # ping基地址 0
NOC_cfg (addr=15 , wdata=2047, cfifo_wdata=0,cfifo_en=0)   # lenth3 
NOC_cfg (addr=17 , wdata=2047, cfifo_wdata=0,cfifo_en=0)
NOC_cfg (addr=21 , wdata=1, cfifo_wdata=0,cfifo_en=0)      # 1 取feature
noc_req (comd_type=4, bar=0)
MQ_NOP (bar=0, nop_cycle_num=1)
MQ_NOP (bar=0, nop_cycle_num=1)
MQ_NOP (bar=0, nop_cycle_num=1)
MQ_NOP (bar=0, nop_cycle_num=1)
MQ_NOP (bar=0, nop_cycle_num=1)
MQ_NOP (bar=0, nop_cycle_num=1)
MQ_NOP (bar=0, nop_cycle_num=1)