# 取数数量: 576  56  2048
# 2048 + 576 + 64 =  2688

next_fetch_is_npu
# dma wr 第一次直接传进来2048个数即可
NOC_cfg (cfifo_en=0, addr=96  , wdata=0 )
NOC_cfg (cfifo_en=0, addr=97  , wdata=0 )
NOC_cfg (cfifo_en=0, addr=98  , wdata=0 )
NOC_cfg (cfifo_en=0, addr=99  , wdata=0 )
NOC_cfg (cfifo_en=0, addr=100 , wdata=0 )
NOC_cfg (cfifo_en=0, addr=101 , wdata=0 )
NOC_cfg (cfifo_en=0, addr=102 , wdata=0 )
NOC_cfg (cfifo_en=0, addr=103 , wdata=512 )
NOC_cfg (cfifo_en=0, addr=104 , wdata=0 )
NOC_cfg (cfifo_en=0, addr=105 , wdata=0 )
NOC_cfg (cfifo_en=0, addr=106 , wdata=0 )
NOC_cfg (cfifo_en=0, addr=107 , wdata=0 )
NOC_cfg (cfifo_en=0, addr=108 , wdata=1 )
NOC_cfg (cfifo_en=0, addr=109 , wdata=0 )
NOC_cfg (cfifo_en=0, addr=110 , wdata=0 )
NOC_cfg (cfifo_en=0, addr=111 , wdata=0)
NOC_cfg (cfifo_en=0, addr=112 , wdata=2687)   # loop lenth
NOC_cfg (cfifo_en=0, addr=113 , wdata=0)
NOC_cfg (cfifo_en=0, addr=114 , wdata=2687)   # ping lenth
NOC_cfg (cfifo_en=0, addr=115 , wdata=0 )
NOC_cfg (cfifo_en=0, addr=116 , wdata=0 ) 
NOC_cfg (cfifo_en=0, addr=117 , wdata=0 )   
NOC_cfg (cfifo_en=0, addr=118 , wdata=0 )
noc_req (comd_type=3, bar=0)
noc_req (comd_type=4, bar=0)
# MQ_NOP(bar=0)
# MQ_NOP(bar=0)
# MQ_NOP(bar=0)
# MQ_NOP(bar=0)
# MQ_NOP(bar=0)
# MQ_NOP(bar=0)
# MQ_NOP(bar=0)

#####################################
# core rd 第一次取576个
NOC_cfg (cfifo_en=0, addr=0 , wdata=0 )
NOC_cfg (cfifo_en=0, addr=1 , wdata=0 )
NOC_cfg (cfifo_en=0, addr=2 , wdata=0 )
NOC_cfg (cfifo_en=0, addr=3 , wdata=1 )    # 1片上读取
NOC_cfg (cfifo_en=0, addr=4 , wdata=0 )
NOC_cfg (cfifo_en=0, addr=5 , wdata=0 )
NOC_cfg (cfifo_en=0, addr=6 , wdata=0 )    # ping基地址 0
NOC_cfg (cfifo_en=0, addr=7 , wdata=0 )
NOC_cfg (cfifo_en=0, addr=8 , wdata=0 )  # gap0
NOC_cfg (cfifo_en=0, addr=9 , wdata=0 )  # gap1
NOC_cfg (cfifo_en=0, addr=10 , wdata=0 )  # gap2 
NOC_cfg (cfifo_en=0, addr=11 , wdata=1 )  # gap3
NOC_cfg (cfifo_en=0, addr=12 , wdata=0 )  # lenth0
NOC_cfg (cfifo_en=0, addr=13 , wdata=0 )  # lenth1
NOC_cfg (cfifo_en=0, addr=14 , wdata=0)   # lenth2
NOC_cfg (cfifo_en=0, addr=15 , wdata=575)   # lenth3
NOC_cfg (cfifo_en=0, addr=16 , wdata=0)   
NOC_cfg (cfifo_en=0, addr=17 , wdata=575)
NOC_cfg (cfifo_en=0, addr=18 , wdata=0)
NOC_cfg (cfifo_en=0, addr=19 , wdata=0)
NOC_cfg (cfifo_en=0, addr=20 , wdata=0)
NOC_cfg (cfifo_en=0, addr=21 , wdata=0)   
#NOC_cfg (cfifo_en=0, addr=22 , wdata=2)
#NOC_cfg (cfifo_en=0, addr=23 , wdata=2)
#NOC_cfg (cfifo_en=0, addr=24 , wdata=4)
#NOC_cfg (cfifo_en=0, addr=25 , wdata=4)
#NOC_cfg (cfifo_en=0, addr=26 , wdata=2) #有效行数
#NOC_cfg (cfifo_en=0, addr=27 , wdata=3) #有效列数
NOC_cfg (cfifo_en=0, addr=28 , wdata=0) #pad mode
NOC_cfg (cfifo_en=0, addr=29 , wdata=0) 
NOC_cfg (cfifo_en=0, addr=30 , wdata=1) #单核取指
noc_req (comd_type=4, bar=0)
MQ_NOP(bar=0)
MQ_NOP(bar=0)
MQ_NOP(bar=0)
MQ_NOP(bar=0)
MQ_NOP(bar=0)
MQ_NOP(bar=0)
MQ_NOP(bar=0)

# core rd 第二次取64个
NOC_cfg (cfifo_en=0, addr=0 , wdata=0 )
NOC_cfg (cfifo_en=0, addr=1 , wdata=0 )
NOC_cfg (cfifo_en=0, addr=2 , wdata=0 )
NOC_cfg (cfifo_en=0, addr=3 , wdata=1 )    # 1片上读取
NOC_cfg (cfifo_en=0, addr=4 , wdata=0 )
NOC_cfg (cfifo_en=0, addr=5 , wdata=0 )
NOC_cfg (cfifo_en=0, addr=6 , wdata=576 )    # ping基地址 0
NOC_cfg (cfifo_en=0, addr=7 , wdata=0 )
NOC_cfg (cfifo_en=0, addr=8 , wdata=0 )  # gap0
NOC_cfg (cfifo_en=0, addr=9 , wdata=0 )  # gap1
NOC_cfg (cfifo_en=0, addr=10 , wdata=0 )  # gap2 
NOC_cfg (cfifo_en=0, addr=11 , wdata=1 )  # gap3
NOC_cfg (cfifo_en=0, addr=12 , wdata=0 )  # lenth0
NOC_cfg (cfifo_en=0, addr=13 , wdata=0 )  # lenth1
NOC_cfg (cfifo_en=0, addr=14 , wdata=0)   # lenth2
NOC_cfg (cfifo_en=0, addr=15 , wdata=63)   # lenth3
NOC_cfg (cfifo_en=0, addr=16 , wdata=0)   
NOC_cfg (cfifo_en=0, addr=17 , wdata=63)
NOC_cfg (cfifo_en=0, addr=18 , wdata=0)
NOC_cfg (cfifo_en=0, addr=19 , wdata=0)
NOC_cfg (cfifo_en=0, addr=20 , wdata=0)
NOC_cfg (cfifo_en=0, addr=21 , wdata=0)   
#NOC_cfg (cfifo_en=0, addr=22 , wdata=2)
#NOC_cfg (cfifo_en=0, addr=23 , wdata=2)
#NOC_cfg (cfifo_en=0, addr=24 , wdata=4)
#NOC_cfg (cfifo_en=0, addr=25 , wdata=4)
#NOC_cfg (cfifo_en=0, addr=26 , wdata=2) #有效行数
#NOC_cfg (cfifo_en=0, addr=27 , wdata=3) #有效列数
NOC_cfg (cfifo_en=0, addr=28 , wdata=0) #pad mode
NOC_cfg (cfifo_en=0, addr=29 , wdata=0) 
NOC_cfg (cfifo_en=0, addr=30 , wdata=1) #单核取指
noc_req (comd_type=4, bar=0)
MQ_NOP(bar=0)
MQ_NOP(bar=0)
MQ_NOP(bar=0)
MQ_NOP(bar=0)
MQ_NOP(bar=0)
MQ_NOP(bar=0)
MQ_NOP(bar=0)

# core rd 第二次取64个
NOC_cfg (cfifo_en=0, addr=0 , wdata=0 )
NOC_cfg (cfifo_en=0, addr=1 , wdata=0 )
NOC_cfg (cfifo_en=0, addr=2 , wdata=0 )
NOC_cfg (cfifo_en=0, addr=3 , wdata=1 )    # 1片上读取
NOC_cfg (cfifo_en=0, addr=4 , wdata=0 )
NOC_cfg (cfifo_en=0, addr=5 , wdata=0 )
NOC_cfg (cfifo_en=0, addr=6 , wdata=640 )    # ping基地址 0
NOC_cfg (cfifo_en=0, addr=7 , wdata=0 )
NOC_cfg (cfifo_en=0, addr=8 , wdata=0 )  # gap0
NOC_cfg (cfifo_en=0, addr=9 , wdata=0 )  # gap1
NOC_cfg (cfifo_en=0, addr=10 , wdata=0 )  # gap2 
NOC_cfg (cfifo_en=0, addr=11 , wdata=1 )  # gap3
NOC_cfg (cfifo_en=0, addr=12 , wdata=0 )  # lenth0
NOC_cfg (cfifo_en=0, addr=13 , wdata=0 )  # lenth1
NOC_cfg (cfifo_en=0, addr=14 , wdata=0)   # lenth2
NOC_cfg (cfifo_en=0, addr=15 , wdata=2047)   # lenth3
NOC_cfg (cfifo_en=0, addr=16 , wdata=0)   
NOC_cfg (cfifo_en=0, addr=17 , wdata=2047)
NOC_cfg (cfifo_en=0, addr=18 , wdata=0)
NOC_cfg (cfifo_en=0, addr=19 , wdata=0)
NOC_cfg (cfifo_en=0, addr=20 , wdata=0)
NOC_cfg (cfifo_en=0, addr=21 , wdata=0)   
#NOC_cfg (cfifo_en=0, addr=22 , wdata=2)
#NOC_cfg (cfifo_en=0, addr=23 , wdata=2)
#NOC_cfg (cfifo_en=0, addr=24 , wdata=4)
#NOC_cfg (cfifo_en=0, addr=25 , wdata=4)
#NOC_cfg (cfifo_en=0, addr=26 , wdata=2) #有效行数
#NOC_cfg (cfifo_en=0, addr=27 , wdata=3) #有效列数
NOC_cfg (cfifo_en=0, addr=28 , wdata=0) #pad mode
NOC_cfg (cfifo_en=0, addr=29 , wdata=0) 
NOC_cfg (cfifo_en=0, addr=30 , wdata=1) #单核取指
noc_req (comd_type=4, bar=0)
MQ_NOP(bar=0)
MQ_NOP(bar=0)
MQ_NOP(bar=0)
MQ_NOP(bar=0)
MQ_NOP(bar=0)
MQ_NOP(bar=0)
MQ_NOP(bar=0)

nop