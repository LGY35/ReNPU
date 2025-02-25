CVEC_cfg2          (cal_mode=sparse_conv,wreg_wr_cnt=2,fprec=INT8,wprec=INT8,v_tq=0)
MQ_cfg0            (gpu_mode=0,para_mode=0,tcache_mode=16CH_DFIFO,one_ram_base_addr=108,tcache_trans_swbank=0,tcache_trans_prici=INT8,mv_cub_dst_sel=weight,wr_hl_mask=0)
NOC_cfg (addr=0,wdata=1,cfifo_wdata=0,cfifo_en=0) // 相对寻址
NOC_cfg (addr=1,wdata=0,cfifo_wdata=0,cfifo_en=0) //读取本地L2
NOC_cfg (addr=2,wdata=0,cfifo_wdata=0,cfifo_en=0) // 关闭多节点合并读
NOC_cfg (addr=3,wdata=1,cfifo_wdata=0,cfifo_en=0) // 从片上读取数据
NOC_cfg (addr=4,wdata=0,cfifo_wdata=0,cfifo_en=0) // 关闭pingpong
NOC_cfg (addr=6,wdata=0,cfifo_wdata=0,cfifo_en=0) // =====基地址偏移为0
NOC_cfg (addr=10,wdata=512,cfifo_wdata=0,cfifo_en=0) //=====第二层循环递增gap=512
NOC_cfg (addr=11,wdata=1,cfifo_wdata=0,cfifo_en=0) //=====最内层循环递增gap=1，每次读入256bit 
NOC_cfg (addr=14,wdata=3,cfifo_wdata=0,cfifo_en=0)  //=====lenth2 = 4
NOC_cfg (addr=15,wdata=159,cfifo_wdata=0,cfifo_en=0)  //=====lenth3 = 160
NOC_cfg (addr=16,wdata=0,cfifo_wdata=0,cfifo_en=0) //不采用pingpong  
NOC_cfg (addr=17,wdata=639,cfifo_wdata=0,cfifo_en=0) //=====ping传输的长度 160*4 = 640
NOC_cfg (addr=19,wdata=0,cfifo_wdata=0,cfifo_en=0) //单播模式
NOC_cfg (addr=20,wdata=0,cfifo_wdata=0,cfifo_en=0) //不和任何节点同步
NOC_cfg (addr=21,wdata=1,cfifo_wdata=0,cfifo_en=0) // 读取base地址为cluster指令中的weight地址（每组不同的地址）
NOC_cfg (addr=63,wdata=1,cfifo_wdata=0,cfifo_en=0) //单独取指   
npu_load           (we=wr,l1b_mode=cache,from_noc_or_sc=noc,sys_gap=353,  sub_gap=1,sub_len=160 ,addr=0, sys_len=4 ,mv_last_dis=0,cfifo_en=1,bar=0) //load_fmap
noc_req (comd_type=4, bar=0,cfifo_wdata=0,cfifo_en=0)// 检查是否完成fmap搬运
