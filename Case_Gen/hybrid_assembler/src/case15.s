# 取数数量: 576  56  2048
# 2048 + 576 + 64 =  2688

next_fetch_is_npu
# dma wr 第一次直接传进来2048个数即可
NOC_cfg (addr=96  , wdata=0 )
NOC_cfg (addr=97  , wdata=0 )
NOC_cfg (addr=98  , wdata=0 )
NOC_cfg (addr=99  , wdata=0 )
NOC_cfg (addr=100 , wdata=0 )
NOC_cfg (addr=101 , wdata=0 )
NOC_cfg (addr=102 , wdata=0 )
NOC_cfg (addr=103 , wdata=512 )
NOC_cfg (addr=104 , wdata=0 )
NOC_cfg (addr=105 , wdata=0 )
NOC_cfg (addr=106 , wdata=0 )
NOC_cfg (addr=107 , wdata=0 )
NOC_cfg (addr=108 , wdata=1 )
NOC_cfg (addr=109 , wdata=0 )
NOC_cfg (addr=110 , wdata=0 )
NOC_cfg (addr=111 , wdata=0)
NOC_cfg (addr=112 , wdata=2687)   # loop lenth
NOC_cfg (addr=113 , wdata=0)
NOC_cfg (addr=114 , wdata=2687)   # ping lenth
NOC_cfg (addr=115 , wdata=0 )
NOC_cfg (addr=116 , wdata=0 ) 
NOC_cfg (addr=117 , wdata=0 )   
NOC_cfg (addr=118 , wdata=0 )
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
NOC_cfg (addr=0 , wdata=0 )
NOC_cfg (addr=1 , wdata=0 )
NOC_cfg (addr=2 , wdata=0 )
NOC_cfg (addr=3 , wdata=1 )    # 1片上读取
NOC_cfg (addr=4 , wdata=0 )
NOC_cfg (addr=5 , wdata=0 )
NOC_cfg (addr=6 , wdata=0 )    # ping基地址 0
NOC_cfg (addr=7 , wdata=0 )
NOC_cfg (addr=8 , wdata=0 )  # gap0
NOC_cfg (addr=9 , wdata=0 )  # gap1
NOC_cfg (addr=10 , wdata=0 )  # gap2 
NOC_cfg (addr=11 , wdata=1 )  # gap3
NOC_cfg (addr=12 , wdata=0 )  # lenth0
NOC_cfg (addr=13 , wdata=0 )  # lenth1
NOC_cfg (addr=14 , wdata=0)   # lenth2
NOC_cfg (addr=15 , wdata=575)   # lenth3
NOC_cfg (addr=16 , wdata=0)   
NOC_cfg (addr=17 , wdata=575)
NOC_cfg (addr=18 , wdata=0)
NOC_cfg (addr=19 , wdata=0)
NOC_cfg (addr=20 , wdata=0)
NOC_cfg (addr=21 , wdata=0)   
#NOC_cfg (addr=22 , wdata=2)
#NOC_cfg (addr=23 , wdata=2)
#NOC_cfg (addr=24 , wdata=4)
#NOC_cfg (addr=25 , wdata=4)
#NOC_cfg (addr=26 , wdata=2) #有效行数
#NOC_cfg (addr=27 , wdata=3) #有效列数
NOC_cfg (addr=28 , wdata=0) #pad mode
NOC_cfg (addr=29 , wdata=0) 
NOC_cfg (addr=30 , wdata=1) #单核取指
noc_req (comd_type=4, bar=0)
MQ_NOP(bar=0)
MQ_NOP(bar=0)
MQ_NOP(bar=0)
MQ_NOP(bar=0)
MQ_NOP(bar=0)
MQ_NOP(bar=0)
MQ_NOP(bar=0)

# core rd 第二次取64个
NOC_cfg (addr=0 , wdata=0 )
NOC_cfg (addr=1 , wdata=0 )
NOC_cfg (addr=2 , wdata=0 )
NOC_cfg (addr=3 , wdata=1 )    # 1片上读取
NOC_cfg (addr=4 , wdata=0 )
NOC_cfg (addr=5 , wdata=0 )
NOC_cfg (addr=6 , wdata=576 )    # ping基地址 0
NOC_cfg (addr=7 , wdata=0 )
NOC_cfg (addr=8 , wdata=0 )  # gap0
NOC_cfg (addr=9 , wdata=0 )  # gap1
NOC_cfg (addr=10 , wdata=0 )  # gap2 
NOC_cfg (addr=11 , wdata=1 )  # gap3
NOC_cfg (addr=12 , wdata=0 )  # lenth0
NOC_cfg (addr=13 , wdata=0 )  # lenth1
NOC_cfg (addr=14 , wdata=0)   # lenth2
NOC_cfg (addr=15 , wdata=63)   # lenth3
NOC_cfg (addr=16 , wdata=0)   
NOC_cfg (addr=17 , wdata=63)
NOC_cfg (addr=18 , wdata=0)
NOC_cfg (addr=19 , wdata=0)
NOC_cfg (addr=20 , wdata=0)
NOC_cfg (addr=21 , wdata=0)   
#NOC_cfg (addr=22 , wdata=2)
#NOC_cfg (addr=23 , wdata=2)
#NOC_cfg (addr=24 , wdata=4)
#NOC_cfg (addr=25 , wdata=4)
#NOC_cfg (addr=26 , wdata=2) #有效行数
#NOC_cfg (addr=27 , wdata=3) #有效列数
NOC_cfg (addr=28 , wdata=0) #pad mode
NOC_cfg (addr=29 , wdata=0) 
NOC_cfg (addr=30 , wdata=1) #单核取指
noc_req (comd_type=4, bar=0)
MQ_NOP(bar=0)
MQ_NOP(bar=0)
MQ_NOP(bar=0)
MQ_NOP(bar=0)
MQ_NOP(bar=0)
MQ_NOP(bar=0)
MQ_NOP(bar=0)

# core rd 第二次取64个
NOC_cfg (addr=0 , wdata=0 )
NOC_cfg (addr=1 , wdata=0 )
NOC_cfg (addr=2 , wdata=0 )
NOC_cfg (addr=3 , wdata=1 )    # 1片上读取
NOC_cfg (addr=4 , wdata=0 )
NOC_cfg (addr=5 , wdata=0 )
NOC_cfg (addr=6 , wdata=640 )    # ping基地址 0
NOC_cfg (addr=7 , wdata=0 )
NOC_cfg (addr=8 , wdata=0 )  # gap0
NOC_cfg (addr=9 , wdata=0 )  # gap1
NOC_cfg (addr=10 , wdata=0 )  # gap2 
NOC_cfg (addr=11 , wdata=1 )  # gap3
NOC_cfg (addr=12 , wdata=0 )  # lenth0
NOC_cfg (addr=13 , wdata=0 )  # lenth1
NOC_cfg (addr=14 , wdata=0)   # lenth2
NOC_cfg (addr=15 , wdata=2047)   # lenth3
NOC_cfg (addr=16 , wdata=0)   
NOC_cfg (addr=17 , wdata=2047)
NOC_cfg (addr=18 , wdata=0)
NOC_cfg (addr=19 , wdata=0)
NOC_cfg (addr=20 , wdata=0)
NOC_cfg (addr=21 , wdata=0)   
#NOC_cfg (addr=22 , wdata=2)
#NOC_cfg (addr=23 , wdata=2)
#NOC_cfg (addr=24 , wdata=4)
#NOC_cfg (addr=25 , wdata=4)
#NOC_cfg (addr=26 , wdata=2) #有效行数
#NOC_cfg (addr=27 , wdata=3) #有效列数
NOC_cfg (addr=28 , wdata=0) #pad mode
NOC_cfg (addr=29 , wdata=0) 
NOC_cfg (addr=30 , wdata=1) #单核取指
noc_req (comd_type=4, bar=0)
MQ_NOP(bar=0)
MQ_NOP(bar=0)
MQ_NOP(bar=0)
MQ_NOP(bar=0)
MQ_NOP(bar=0)
MQ_NOP(bar=0)
MQ_NOP(bar=0)

nop