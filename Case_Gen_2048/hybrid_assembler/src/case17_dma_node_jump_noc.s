# 取20行（16 + pad2行）

next_fetch_is_npu
# dma wr
NOC_cfg ( addr=96  , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=97  , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=98  , wdata=0, cfifo_wdata=0,cfifo_en=0 ) #广播
NOC_cfg ( addr=99  , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=100 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=101 , wdata=0, cfifo_wdata=0,cfifo_en=0 )   # ram base addr
NOC_cfg ( addr=102 , wdata=0, cfifo_wdata=0,cfifo_en=0 )   # ram base addr
NOC_cfg ( addr=103 , wdata=0, cfifo_wdata=0,cfifo_en=0 )   # noc_base addr     # Aaddr
NOC_cfg ( addr=104 , wdata=0, cfifo_wdata=0,cfifo_en=0 )   # noc_base addr
NOC_cfg ( addr=105 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=106 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=107 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=108 , wdata=1, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=109 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=110 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=111 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=112 , wdata=39, cfifo_wdata=0,cfifo_en=0)   # loop lenth 640/8 = 80, 取一半40
NOC_cfg ( addr=113 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=114 , wdata=799, cfifo_wdata=0,cfifo_en=0)   # ping lenth = 总长度20*40=800
NOC_cfg ( addr=115 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=116 , wdata=0, cfifo_wdata=0,cfifo_en=0 )   
NOC_cfg ( addr=117 , wdata=0, cfifo_wdata=0,cfifo_en=0 )   
NOC_cfg ( addr=118 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=119 , wdata=39, cfifo_wdata=0,cfifo_en=0 )   # 单行长度
NOC_cfg ( addr=120 , wdata=321, cfifo_wdata=0,cfifo_en=0 )  # dmaloop gap # gap2整行，也就是160  然后最低位是enable为1，所以160*2+1=321
NOC_cfg ( addr=121 , wdata=10, cfifo_wdata=0,cfifo_en=0 )   # dmaloop num    20/2   
NOC_cfg ( addr=122 , wdata=80, cfifo_wdata=0,cfifo_en=0 )  # dmaloop Baddr
noc_req (comd_type=3, bar=0 )
noc_req (comd_type=4, bar=0 )
MQ_NOP (bar=0, nop_cycle_num=1)
MQ_NOP (bar=0, nop_cycle_num=1)
MQ_NOP (bar=0, nop_cycle_num=1)
MQ_NOP (bar=0, nop_cycle_num=1)
MQ_NOP (bar=0, nop_cycle_num=1)
MQ_NOP (bar=0, nop_cycle_num=1)
MQ_NOP (bar=0, nop_cycle_num=1)
NOC_cfg ( addr=96  , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=97  , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=98  , wdata=0, cfifo_wdata=0,cfifo_en=0 )   #广播
NOC_cfg ( addr=99  , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=100 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=101 , wdata=799, cfifo_wdata=0,cfifo_en=0 )   # ram base addr       # 取另一半的数据
NOC_cfg ( addr=102 , wdata=0, cfifo_wdata=0,cfifo_en=0 )   # ram base addr
NOC_cfg ( addr=103 , wdata=40, cfifo_wdata=0,cfifo_en=0 )   # noc_base addr     # Aaddr
NOC_cfg ( addr=104 , wdata=0, cfifo_wdata=0,cfifo_en=0 )   # noc_base addr
NOC_cfg ( addr=105 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=106 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=107 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=108 , wdata=1, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=109 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=110 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=111 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=112 , wdata=39, cfifo_wdata=0,cfifo_en=0)   # loop lenth 640/8 = 80, 取一半40
NOC_cfg ( addr=113 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=114 , wdata=799, cfifo_wdata=0,cfifo_en=0)   # ping lenth = 总长度
NOC_cfg ( addr=115 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=116 , wdata=0, cfifo_wdata=0,cfifo_en=0 )   
NOC_cfg ( addr=117 , wdata=0, cfifo_wdata=0,cfifo_en=0 )   
NOC_cfg ( addr=118 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=119 , wdata=39, cfifo_wdata=0,cfifo_en=0 )   # 单行长度
NOC_cfg ( addr=120 , wdata=321, cfifo_wdata=0,cfifo_en=0 )  # dmaloop gap # gap2整行，也就是160  然后最低位是enable为1，所以160*2+1=321
NOC_cfg ( addr=121 , wdata=10, cfifo_wdata=0,cfifo_en=0 )   # dmaloop num    20/2   
NOC_cfg ( addr=122 , wdata=120, cfifo_wdata=0,cfifo_en=0 )  # dmaloop Baddr
noc_req (comd_type=3, bar=0 )
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