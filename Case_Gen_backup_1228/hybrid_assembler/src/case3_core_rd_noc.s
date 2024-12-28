next_fetch_is_npu
NOC_cfg ( addr=0 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=1 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=2 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=3 , wdata=0, cfifo_wdata=0,cfifo_en=0 )    # 0片外读取
NOC_cfg ( addr=4 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=5 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=6 , wdata=512, cfifo_wdata=0,cfifo_en=0 )    # ping基地址 4096/8
NOC_cfg ( addr=7 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=8 , wdata=0, cfifo_wdata=0,cfifo_en=0 )  # gap0
NOC_cfg ( addr=9 , wdata=0, cfifo_wdata=0,cfifo_en=0 )  # gap1
NOC_cfg ( addr=10 , wdata=0, cfifo_wdata=0,cfifo_en=0 )  # gap2 
NOC_cfg ( addr=11 , wdata=1, cfifo_wdata=0,cfifo_en=0 )  # gap3
NOC_cfg ( addr=12 , wdata=0, cfifo_wdata=0,cfifo_en=0 )  # lenth0
NOC_cfg ( addr=13 , wdata=0, cfifo_wdata=0,cfifo_en=0 )  # lenth1
NOC_cfg ( addr=14 , wdata=0, cfifo_wdata=0,cfifo_en=0)   # lenth2
NOC_cfg ( addr=15 , wdata=575, cfifo_wdata=0,cfifo_en=0)   # lenth3
NOC_cfg ( addr=16 , wdata=0, cfifo_wdata=0,cfifo_en=0)   
NOC_cfg ( addr=17 , wdata=575, cfifo_wdata=0,cfifo_en=0)
NOC_cfg ( addr=18 , wdata=0, cfifo_wdata=0,cfifo_en=0)
NOC_cfg ( addr=19 , wdata=0, cfifo_wdata=0,cfifo_en=0)
NOC_cfg ( addr=20 , wdata=0, cfifo_wdata=0,cfifo_en=0)
NOC_cfg ( addr=21 , wdata=0, cfifo_wdata=0,cfifo_en=0)   
#NOC_cfg ( addr=22 , wdata=2, cfifo_wdata=0,cfifo_en=0)
#NOC_cfg ( addr=23 , wdata=2, cfifo_wdata=0,cfifo_en=0)
#NOC_cfg ( addr=24 , wdata=4, cfifo_wdata=0,cfifo_en=0)
#NOC_cfg ( addr=25 , wdata=4, cfifo_wdata=0,cfifo_en=0)
#NOC_cfg ( addr=26 , wdata=2, cfifo_wdata=0,cfifo_en=0) #有效行数
#NOC_cfg ( addr=27 , wdata=3, cfifo_wdata=0,cfifo_en=0) #有效列数
#NOC_cfg ( addr=28 , wdata=0, cfifo_wdata=0,cfifo_en=0) #pad mode
NOC_cfg ( addr=29 , wdata=0, cfifo_wdata=0,cfifo_en=0) 
NOC_cfg ( addr=30 , wdata=1, cfifo_wdata=0,cfifo_en=0) #单核取指


# 第二次,取64个
NOC_cfg (addr=6 , wdata=1088, cfifo_wdata=0,cfifo_en=0 )    # ping基地址 512+576
NOC_cfg (addr=15 , wdata=63, cfifo_wdata=0,cfifo_en=0)   # lenth3
NOC_cfg (addr=17 , wdata=63, cfifo_wdata=0,cfifo_en=0)

# 第三次 取2048个
NOC_cfg (addr=6 , wdata=1152 , cfifo_wdata=0,cfifo_en=0)    # ping基地址 1088+64
NOC_cfg (addr=15 , wdata=2047, cfifo_wdata=0,cfifo_en=0)   # lenth3
NOC_cfg (addr=17 , wdata=2047, cfifo_wdata=0,cfifo_en=0)
















#MQ_NOP (bar=0, nop_cycle_num=1)
#MQ_NOP (bar=0, nop_cycle_num=1)
#MQ_NOP (bar=0, nop_cycle_num=1)
#MQ_NOP (bar=0, nop_cycle_num=1)
#MQ_NOP (bar=0, nop_cycle_num=1)
#MQ_NOP (bar=0, nop_cycle_num=1)
#next_fetch_is_cpu
#wfi