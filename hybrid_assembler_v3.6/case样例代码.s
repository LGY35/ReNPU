

noc指令: 0000005B
休眠指令: 10500073

// dma wr
noc_req (comd_type=3, bar=1)
noc_req (comd_type=4, bar=1)

//设置长度
NOC_cfg (addr=114 , wdata=18)
//取权重orfeature
NOC_cfg (addr=118 , wdata=0 )

#########################################################################################################################################################

// dma rd
noc_req (comd_type=2, bar=2)
noc_req (comd_type=4, bar=2)


dma rd
NOC_cfg (addr=64 , wdata=0 )
NOC_cfg (addr=65 , wdata=0 )
NOC_cfg (addr=66 , wdata=0 )
NOC_cfg (addr=67 , wdata=0 )
NOC_cfg (addr=68 , wdata=0 )
NOC_cfg (addr=69 , wdata=0 )
NOC_cfg (addr=70 , wdata=512 )
NOC_cfg (addr=71 , wdata=0 )
NOC_cfg (addr=72 , wdata=0 )
NOC_cfg (addr=73 , wdata=0 )
NOC_cfg (addr=74 , wdata=0 )
NOC_cfg (addr=75 , wdata=1 )
NOC_cfg (addr=76 , wdata=0 )
NOC_cfg (addr=77 , wdata=0 )
NOC_cfg (addr=78 , wdata=0 )
NOC_cfg (addr=79 , wdata=18)
NOC_cfg (addr=80 , wdata=0)
NOC_cfg (addr=81 , wdata=18)
NOC_cfg (addr=82 , wdata=0)
NOC_cfg (addr=83 , wdata=0 )
noc_req (comd_type=3, bar=1)
noc_req (comd_type=4, bar=1)
NOC_cfg (addr=81 , wdata=6)
NOC_cfg (addr=83 , wdata=1 )
noc_req (comd_type=3, bar=1)
noc_req (comd_type=4, bar=1)

#########################################################################################################################################################

// core rd
npu_load (we=wr, l1b_mode=norm, tcache_bank_num=0, sys_gap=-4353, sub_gap=0, sub_len=16, addr=1, sys_len=8, mv_last_dis=0, cfifo_en=1, bar=3)
noc_req (comd_type=4, bar=3)


#########################################################################################################################################################



// core wr
npu_store (we=rd, l1b_mode=norm, tcache_bank_num=0, sys_gap=1, sub_gap=1, sub_len=1, addr=0, sys_len=1, mv_last_dis=0, cfifo_en=1, bar=4)
noc_req (comd_type=4, bar=4)