
#dma wr 用0接收，然后dma rd 写入1
#
#dma wr 用0和2，0接收，然后广播给2 —— 都给下一个节点写数。用dma_rd
#广播过滤 - 路由算法  单bit

next_fetch_is_npu
NOC_cfg ( addr=96  , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=97  , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=98  , wdata=1, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=99  , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=100 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=101 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=102 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=103 , wdata=512, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=104 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=105 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=106 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=107 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=108 , wdata=1, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=109 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=110 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=111 , wdata=0, cfifo_wdata=0,cfifo_en=0)
NOC_cfg ( addr=112 , wdata=18, cfifo_wdata=0,cfifo_en=0)


NOC_cfg ( addr=96  , wdata=0, cfifo_wdata=0,cfifo_en=0 )   
NOC_cfg ( addr=97  , wdata=0, cfifo_wdata=0,cfifo_en=0 )   
NOC_cfg ( addr=98  , wdata=1, cfifo_wdata=0,cfifo_en=0 )   # 广播开
NOC_cfg ( addr=99  , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=100 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=101 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=102 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=103 , wdata=512, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=104 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=105 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=106 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=107 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=108 , wdata=1, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=109 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=110 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=111 , wdata=0, cfifo_wdata=0,cfifo_en=0)
NOC_cfg ( addr=112 , wdata=17, cfifo_wdata=0,cfifo_en=0)   # 测试
NOC_cfg ( addr=113 , wdata=0, cfifo_wdata=0,cfifo_en=0)
NOC_cfg ( addr=114 , wdata=17, cfifo_wdata=0,cfifo_en=0)   # 测试
NOC_cfg ( addr=115 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=116 , wdata=128, cfifo_wdata=0,cfifo_en=0 ) # 0000 1000 0000 = 1413
NOC_cfg ( addr=117 , wdata=0, cfifo_wdata=0,cfifo_en=0 )   
NOC_cfg ( addr=118 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
noc_req (comd_type=3, bar=1)
noc_req (comd_type=4, bar=1)
NOC_cfg ( addr=103 , wdata=530, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=114 , wdata=5, cfifo_wdata=0,cfifo_en=0)    # 测试
NOC_cfg ( addr=118 , wdata=1, cfifo_wdata=0,cfifo_en=0)
noc_req (comd_type=3, bar=0)
noc_req (comd_type=4, bar=0)
# dma rd 
NOC_cfg ( addr=64 , wdata=1, cfifo_wdata=0,cfifo_en=0 )    # 相对寻址开
NOC_cfg ( addr=65 , wdata=1, cfifo_wdata=0,cfifo_en=0 )    # 每个节点都给下一个节点传递 0给1传, 1给2传   00001
NOC_cfg ( addr=66 , wdata=1, cfifo_wdata=0,cfifo_en=0 )    # 片上
NOC_cfg ( addr=67 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=68 , wdata=0, cfifo_wdata=0,cfifo_en=0 )    
NOC_cfg ( addr=69 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=70 , wdata=3072, cfifo_wdata=0,cfifo_en=0 )    # ram ping基地址 bank3 0 1100 0000 0000  = 3072
NOC_cfg ( addr=71 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=72 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=73 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=74 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=75 , wdata=1, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=76 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=77 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=78 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
NOC_cfg ( addr=79 , wdata=23, cfifo_wdata=0,cfifo_en=0)    //是不是可以直接23呢?顺着地址取即可
NOC_cfg ( addr=80 , wdata=0, cfifo_wdata=0,cfifo_en=0)
NOC_cfg ( addr=81 , wdata=23, cfifo_wdata=0,cfifo_en=0)
NOC_cfg ( addr=82 , wdata=0, cfifo_wdata=0,cfifo_en=0)
NOC_cfg ( addr=83 , wdata=0, cfifo_wdata=0,cfifo_en=0)
noc_req (comd_type=2, bar=0)
noc_req (comd_type=4, bar=0)

#NOC_cfg ( addr=70 , wdata=530, cfifo_wdata=0,cfifo_en=0 )
#NOC_cfg ( addr=81 , wdata=5, cfifo_wdata=0,cfifo_en=0)
#NOC_cfg ( addr=83 , wdata=1, cfifo_wdata=0,cfifo_en=0 )
#noc_req (comd_type=2, bar=0)    # 先设置成相同的barrier,这样上面的不执行完下面的不会执行
#noc_req (comd_type=4, bar=0)    # 先设置成相同的barrier,这样上面的不执行完下面的不会执行
