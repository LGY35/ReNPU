
# 先从一个addr0 取数
# 向addr1写出去

#第二个loop再从刚才写出去的地址读回来
next_fetch_is_npu
# dma wr
NOC_cfg (addr=96  , wdata=0 )
NOC_cfg (addr=97  , wdata=0 )
NOC_cfg (addr=98  , wdata=0 ) #广播
NOC_cfg (addr=99  , wdata=0 )
NOC_cfg (addr=100 , wdata=0 )
NOC_cfg (addr=101 , wdata=0 )
NOC_cfg (addr=102 , wdata=0 )
NOC_cfg (addr=103 , wdata=512)
NOC_cfg (addr=104 , wdata=0 )
NOC_cfg (addr=105 , wdata=0 )
NOC_cfg (addr=106 , wdata=0 )
NOC_cfg (addr=107 , wdata=0 )
NOC_cfg (addr=108 , wdata=1 )
NOC_cfg (addr=109 , wdata=0 )
NOC_cfg (addr=110 , wdata=0 )
NOC_cfg (addr=111 , wdata=0)
NOC_cfg (addr=112 , wdata=31)   # loop lenth
NOC_cfg (addr=113 , wdata=0)
NOC_cfg (addr=114 , wdata=31)   # ping lenth
NOC_cfg (addr=115 , wdata=0 )
NOC_cfg (addr=116 , wdata=0 )   
NOC_cfg (addr=117 , wdata=0 )   
NOC_cfg (addr=118 , wdata=0 )
noc_req (comd_type=3, bar=0 )
noc_req (comd_type=4, bar=0 )

# dma rd 
NOC_cfg (addr=64 , wdata=0 )
NOC_cfg (addr=65 , wdata=0 )
NOC_cfg (addr=66 , wdata=0 )
NOC_cfg (addr=67 , wdata=0 )
NOC_cfg (addr=68 , wdata=16 )   # 从第16个数开始
NOC_cfg (addr=69 , wdata=0 )
NOC_cfg (addr=70 , wdata=1024 )
NOC_cfg (addr=71 , wdata=0 )
NOC_cfg (addr=72 , wdata=0 )
NOC_cfg (addr=73 , wdata=0 )
NOC_cfg (addr=74 , wdata=0 )
NOC_cfg (addr=75 , wdata=1 )
NOC_cfg (addr=76 , wdata=0 )
NOC_cfg (addr=77 , wdata=0 )
NOC_cfg (addr=78 , wdata=0 )
NOC_cfg (addr=79 , wdata=15)    # 把后15个数写出去
NOC_cfg (addr=80 , wdata=0 )
NOC_cfg (addr=81 , wdata=15)
NOC_cfg (addr=82 , wdata=0 )
NOC_cfg (addr=83 , wdata=0 )
noc_req (comd_type=2, bar=0)
noc_req (comd_type=4, bar=0)


# 需要加@3000

# dma wr
NOC_cfg (addr=96  , wdata=0 )
NOC_cfg (addr=97  , wdata=0 )
NOC_cfg (addr=98  , wdata=0 ) #广播
NOC_cfg (addr=99  , wdata=0 )
NOC_cfg (addr=100 , wdata=0 )
NOC_cfg (addr=101 , wdata=0 )
NOC_cfg (addr=102 , wdata=0 )
NOC_cfg (addr=103 , wdata=1024)
NOC_cfg (addr=104 , wdata=0 )
NOC_cfg (addr=105 , wdata=0 )
NOC_cfg (addr=106 , wdata=0 )
NOC_cfg (addr=107 , wdata=0 )
NOC_cfg (addr=108 , wdata=1 )
NOC_cfg (addr=109 , wdata=0 )
NOC_cfg (addr=110 , wdata=0 )
NOC_cfg (addr=111 , wdata=0)
NOC_cfg (addr=112 , wdata=15)   # loop lenth
NOC_cfg (addr=113 , wdata=0)
NOC_cfg (addr=114 , wdata=15)   # ping lenth
NOC_cfg (addr=115 , wdata=0 )
NOC_cfg (addr=116 , wdata=0 )   
NOC_cfg (addr=117 , wdata=0 )   
NOC_cfg (addr=118 , wdata=0 )
noc_req (comd_type=3, bar=0 )
noc_req (comd_type=4, bar=0 )
next_fetch_is_cpu
wfi
