

asm volatile ( //之后放在main内部for循环开始之前
        4401 c.li x8, 0
    02440413 addi x8, x8, 36
        0436 c.slli x8, 13
    0080105B storec x8, MQ; 
    0000005B next_fetch_is_npu
    40012222 CVEC_cfg2    (cal_mode=rgb,wreg_wr_cnt=0,fprec=INT8,wprec=INT8,v_tq=0)
    00028610 MQ_cfg0      (gpu_mode=0,para_mode=0,tcache_mode=32CH_SFIFO,one_ram_base_addr=40,tcache_trans_swbank=0,tcache_trans_prici=INT8,mv_cub_dst_sel=weight,wr_hl_mask=0)
    40000090 MQ_cfg1      (sub_gap=1, sys_gap_ext=0b00000)
);
// group 0
if(core_id == 8 || core_id == 9){
    asm volatile(
        NOC_cfg ( addr=0 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 0 绝对寻址
        NOC_cfg ( addr=1 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 
        NOC_cfg ( addr=2 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 0 多节点读合并关 当一起读的时候开，不一起读的时候关 ==============
        NOC_cfg ( addr=3 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 0 片外读取
        NOC_cfg ( addr=4 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 0 pingpang 关
        NOC_cfg ( addr=5 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 目标节点
        NOC_cfg ( addr=6 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # ping基地址 ==============
        NOC_cfg ( addr=7 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
        NOC_cfg ( addr=8 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # gap0 
        NOC_cfg ( addr=9 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # gap1
        NOC_cfg ( addr=10 , wdata=0, cfifo_wdata=0,cfifo_en=0 )    # gap2 
        NOC_cfg ( addr=11 , wdata=1, cfifo_wdata=0,cfifo_en=0 )    # gap3
        NOC_cfg ( addr=12 , wdata=0, cfifo_wdata=0,cfifo_en=0 )    # lenth0
        NOC_cfg ( addr=13 , wdata=0, cfifo_wdata=0,cfifo_en=0 )    # lenth1
        NOC_cfg ( addr=14 , wdata=0, cfifo_wdata=0,cfifo_en=0)     # lenth2
        NOC_cfg ( addr=15 , wdata=575, cfifo_wdata=0,cfifo_en=0)   # lenth3 取权重576个 ==============
        NOC_cfg ( addr=16 , wdata=0, cfifo_wdata=0,cfifo_en=0)   
        NOC_cfg ( addr=17 , wdata=575, cfifo_wdata=0,cfifo_en=0)   # ping length ==============
        NOC_cfg ( addr=18 , wdata=0, cfifo_wdata=0,cfifo_en=0)     # 
        NOC_cfg ( addr=21 , wdata=0, cfifo_wdata=0,cfifo_en=0)     # weight ==============
        NOC_cfg ( addr=29 , wdata=0, cfifo_wdata=0,cfifo_en=0)
        npu_load        (we=wr,l1b_mode=norm,tcache_bank_num=0,sys_gap=221,sub_gap=1,sub_len=36,addr=0,sys_len=16,mv_last_dis=0,cfifo_en=1,bar=0) //load_weight 6*6*16*8bit/128bit=36
        noc_req (comd_type=4, bar=0)
        MQ_NOP (bar=0, nop_cycle_num=1)
        MQ_NOP (bar=0, nop_cycle_num=1)
        MQ_NOP (bar=0, nop_cycle_num=1)
        MQ_NOP (bar=0, nop_cycle_num=1)
        MQ_NOP (bar=0, nop_cycle_num=1)
        MQ_NOP (bar=0, nop_cycle_num=1)
        MQ_NOP (bar=0, nop_cycle_num=1)
        //  TODO: 地址计算
        NOC_cfg ( addr=6 , wdata=576, cfifo_wdata=0,cfifo_en=0)    # ping基地址 取参数在weight的基础上加576==============
        NOC_cfg ( addr=15 , wdata=63, cfifo_wdata=0,cfifo_en=0)    # lenth3 取数据 ==============
        NOC_cfg ( addr=17 , wdata=63, cfifo_wdata=0,cfifo_en=0)    # ping length ==============
        npu_load        (we=wr,l1b_mode=norm ,tcache_bank_num=0,sys_gap=253,sub_gap=1,sub_len=4,addr=36,sys_len=16,mv_last_dis=0,cfifo_en=1,bar=0)
        noc_req (comd_type=4, bar=0)
    );
}
// group 3
else if(core_id == 10 || core_id == 11){
    asm volatile(
        NOC_cfg ( addr=0 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 0 绝对寻址
        NOC_cfg ( addr=1 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 
        NOC_cfg ( addr=2 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 0 多节点读合并关 当一起读的时候开，不一起读的时候关 ==============
        NOC_cfg ( addr=3 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 0 片外读取
        NOC_cfg ( addr=4 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 0 pingpang 关
        NOC_cfg ( addr=5 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 目标节点
        NOC_cfg ( addr=6 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # ping基地址 ==============
        NOC_cfg ( addr=7 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
        NOC_cfg ( addr=8 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # gap0 
        NOC_cfg ( addr=9 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # gap1
        NOC_cfg ( addr=10 , wdata=0, cfifo_wdata=0,cfifo_en=0 )    # gap2 
        NOC_cfg ( addr=11 , wdata=1, cfifo_wdata=0,cfifo_en=0 )    # gap3
        NOC_cfg ( addr=12 , wdata=0, cfifo_wdata=0,cfifo_en=0 )    # lenth0
        NOC_cfg ( addr=13 , wdata=0, cfifo_wdata=0,cfifo_en=0 )    # lenth1
        NOC_cfg ( addr=14 , wdata=0, cfifo_wdata=0,cfifo_en=0)     # lenth2
        NOC_cfg ( addr=15 , wdata=575, cfifo_wdata=0,cfifo_en=0)   # lenth3 取权重576个 ==============
        NOC_cfg ( addr=16 , wdata=0, cfifo_wdata=0,cfifo_en=0)   
        NOC_cfg ( addr=17 , wdata=575, cfifo_wdata=0,cfifo_en=0)   # ping length ==============
        NOC_cfg ( addr=18 , wdata=0, cfifo_wdata=0,cfifo_en=0)     # 
        NOC_cfg ( addr=21 , wdata=0, cfifo_wdata=0,cfifo_en=0)     # weight ==============
        NOC_cfg ( addr=29 , wdata=0, cfifo_wdata=0,cfifo_en=0)
        npu_load        (we=wr,l1b_mode=norm,tcache_bank_num=0,sys_gap=221,sub_gap=1,sub_len=36,addr=0,sys_len=16,mv_last_dis=0,cfifo_en=1,bar=0) //load_weight 6*6*16*8bit/128bit=36
        noc_req (comd_type=4, bar=0)
        MQ_NOP (bar=0, nop_cycle_num=1)
        MQ_NOP (bar=0, nop_cycle_num=1)
        MQ_NOP (bar=0, nop_cycle_num=1)
        MQ_NOP (bar=0, nop_cycle_num=1)
        MQ_NOP (bar=0, nop_cycle_num=1)
        MQ_NOP (bar=0, nop_cycle_num=1)
        MQ_NOP (bar=0, nop_cycle_num=1)
        //  TODO: 地址计算
        NOC_cfg ( addr=6 , wdata=576, cfifo_wdata=0,cfifo_en=0)    # ping基地址 取参数在weight的基础上加576==============
        NOC_cfg ( addr=15 , wdata=63, cfifo_wdata=0,cfifo_en=0)    # lenth3 取数据 ==============
        NOC_cfg ( addr=17 , wdata=63, cfifo_wdata=0,cfifo_en=0)    # ping length ==============
        npu_load        (we=wr,l1b_mode=norm ,tcache_bank_num=0,sys_gap=253,sub_gap=1,sub_len=4,addr=36,sys_len=16,mv_last_dis=0,cfifo_en=1,bar=0)
        noc_req (comd_type=4, bar=0)
    );
}
else if(core_id == 0 || core_id == 2 || core_id == 4 || core_id == 6){
    asm volatile(
        NOC_cfg ( addr=0 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 0 绝对寻址
        NOC_cfg ( addr=1 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 
        NOC_cfg ( addr=2 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 1 多节点读合并开 当一起读的时候开，不一起读的时候关 ==============
        NOC_cfg ( addr=3 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 0 片外读取
        NOC_cfg ( addr=4 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 0 pingpang 关
        NOC_cfg ( addr=5 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 目标节点
        NOC_cfg ( addr=6 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # ping基地址 ==============
        NOC_cfg ( addr=7 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
        NOC_cfg ( addr=8 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # gap0 
        NOC_cfg ( addr=9 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # gap1
        NOC_cfg ( addr=10 , wdata=0, cfifo_wdata=0,cfifo_en=0 )    # gap2 
        NOC_cfg ( addr=11 , wdata=1, cfifo_wdata=0,cfifo_en=0 )    # gap3
        NOC_cfg ( addr=12 , wdata=0, cfifo_wdata=0,cfifo_en=0 )    # lenth0
        NOC_cfg ( addr=13 , wdata=0, cfifo_wdata=0,cfifo_en=0 )    # lenth1
        NOC_cfg ( addr=14 , wdata=0, cfifo_wdata=0,cfifo_en=0)     # lenth2
        NOC_cfg ( addr=15 , wdata=575, cfifo_wdata=0,cfifo_en=0)   # lenth3 取权重576个 ==============
        NOC_cfg ( addr=16 , wdata=0, cfifo_wdata=0,cfifo_en=0)   
        NOC_cfg ( addr=17 , wdata=575, cfifo_wdata=0,cfifo_en=0)   # ping length ==============
        NOC_cfg ( addr=18 , wdata=0, cfifo_wdata=0,cfifo_en=0)     # 
        NOC_cfg ( addr=19 , wdata=148, cfifo_wdata=0,cfifo_en=0)   # 广播的范围 north_id, east_id, south_id, west_id centernode  0000 1001 0100 ==============
        NOC_cfg ( addr=20 , wdata=85, cfifo_wdata=0,cfifo_en=0)    # 同步的目标 0000 0101 0101==============
        NOC_cfg ( addr=21 , wdata=0, cfifo_wdata=0,cfifo_en=0)     # weight ==============
        NOC_cfg ( addr=29 , wdata=0, cfifo_wdata=0,cfifo_en=0) 
        npu_load        (we=wr,l1b_mode=norm,tcache_bank_num=0,sys_gap=221,sub_gap=1,sub_len=36,addr=0,sys_len=16,mv_last_dis=0,cfifo_en=1,bar=0) //load_weight 6*6*16*8bit/128bit=36
        noc_req (comd_type=4, bar=0)
        MQ_NOP (bar=0, nop_cycle_num=1)
        MQ_NOP (bar=0, nop_cycle_num=1)
        MQ_NOP (bar=0, nop_cycle_num=1)
        MQ_NOP (bar=0, nop_cycle_num=1)
        MQ_NOP (bar=0, nop_cycle_num=1)
        MQ_NOP (bar=0, nop_cycle_num=1)
        MQ_NOP (bar=0, nop_cycle_num=1)
        //  TODO: 地址计算
        NOC_cfg ( addr=6 , wdata=576, cfifo_wdata=0,cfifo_en=0 )   # ping基地址 取参数在weight的基础上加576==============
        NOC_cfg ( addr=15 , wdata=63, cfifo_wdata=0,cfifo_en=0)    # lenth3 取数据 ==============
        NOC_cfg ( addr=17 , wdata=63, cfifo_wdata=0,cfifo_en=0)    # ping length ==============
        npu_load        (we=wr,l1b_mode=norm ,tcache_bank_num=0,sys_gap=253,sub_gap=1,sub_len=4,addr=36,sys_len=16,mv_last_dis=0,cfifo_en=1,bar=0)
        noc_req (comd_type=4, bar=0)
    );
}
else if(core_id == 1 || core_id == 3 || core_id == 5 || core_id == 7){
    asm volatile(
        NOC_cfg ( addr=0 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 0 绝对寻址
        NOC_cfg ( addr=1 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 
        NOC_cfg ( addr=2 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 1 多节点读合并开 当一起读的时候开，不一起读的时候关 ==============
        NOC_cfg ( addr=3 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 0 片外读取
        NOC_cfg ( addr=4 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 0 pingpang 关
        NOC_cfg ( addr=5 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 目标节点
        NOC_cfg ( addr=6 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # ping基地址 ==============
        NOC_cfg ( addr=7 , wdata=0, cfifo_wdata=0,cfifo_en=0 )
        NOC_cfg ( addr=8 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # gap0 
        NOC_cfg ( addr=9 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # gap1
        NOC_cfg ( addr=10 , wdata=0, cfifo_wdata=0,cfifo_en=0 )    # gap2 
        NOC_cfg ( addr=11 , wdata=1, cfifo_wdata=0,cfifo_en=0 )    # gap3
        NOC_cfg ( addr=12 , wdata=0, cfifo_wdata=0,cfifo_en=0 )    # lenth0
        NOC_cfg ( addr=13 , wdata=0, cfifo_wdata=0,cfifo_en=0 )    # lenth1
        NOC_cfg ( addr=14 , wdata=0, cfifo_wdata=0,cfifo_en=0)     # lenth2
        NOC_cfg ( addr=15 , wdata=575, cfifo_wdata=0,cfifo_en=0)   # lenth3 取权重576个 ==============
        NOC_cfg ( addr=16 , wdata=0, cfifo_wdata=0,cfifo_en=0)   
        NOC_cfg ( addr=17 , wdata=575, cfifo_wdata=0,cfifo_en=0)   # ping length ==============
        NOC_cfg ( addr=18 , wdata=0, cfifo_wdata=0,cfifo_en=0)     # 
        NOC_cfg ( addr=19 , wdata=1495, cfifo_wdata=0,cfifo_en=0)     # 广播的范围 north_id, east_id, south_id, west_id centernode  0101 1101 0111 ==============
        NOC_cfg ( addr=20 , wdata=170, cfifo_wdata=0,cfifo_en=0)     # 同步的目标 0000 1010 1010==============
        NOC_cfg ( addr=21 , wdata=0, cfifo_wdata=0,cfifo_en=0)     # weight ==============
        NOC_cfg ( addr=29 , wdata=0, cfifo_wdata=0,cfifo_en=0) 
        npu_load        (we=wr,l1b_mode=norm,tcache_bank_num=0,sys_gap=221,sub_gap=1,sub_len=36,addr=0,sys_len=16,mv_last_dis=0,cfifo_en=1,bar=0) //load_weight 6*6*16*8bit/128bit=36
        noc_req (comd_type=4, bar=0)
        MQ_NOP (bar=0, nop_cycle_num=1)
        MQ_NOP (bar=0, nop_cycle_num=1)
        MQ_NOP (bar=0, nop_cycle_num=1)
        MQ_NOP (bar=0, nop_cycle_num=1)
        MQ_NOP (bar=0, nop_cycle_num=1)
        MQ_NOP (bar=0, nop_cycle_num=1)
        MQ_NOP (bar=0, nop_cycle_num=1)
        //  TODO: 地址计算
        NOC_cfg ( addr=6 , wdata=576, cfifo_wdata=0,cfifo_en=0 )   # ping基地址 取参数在weight的基础上加576==============
        NOC_cfg ( addr=15 , wdata=63, cfifo_wdata=0,cfifo_en=0)    # lenth3 取数据 ==============
        NOC_cfg ( addr=17 , wdata=63, cfifo_wdata=0,cfifo_en=0)    # ping length ==============
        npu_load        (we=wr,l1b_mode=norm ,tcache_bank_num=0,sys_gap=253,sub_gap=1,sub_len=4,addr=36,sys_len=16,mv_last_dis=0,cfifo_en=1,bar=0)
        noc_req (comd_type=4, bar=0)
    );
}
    asm volatile(
    00060040 cub_alu_insn_fill(addr=0,num=24) //post-processing
    240020CD cub.lw.l1b x1, 576(x0)  //fill start
    2440214D cub.lw.l1b x2, 580(x0)
    248021CD cub.lw.l1b x3, 584(x0)
    24C0224D cub.lw.l1b x4, 588(x0)
    250022CD cub.lw.l1b x5, 592(x0)
    2540234D cub.lw.l1b x6, 596(x0)
    258023CD cub.lw.l1b x7, 600(x0)
    25C0244D cub.lw.l1b x8, 604(x0)
    260024CD cub.lw.l1b x9, 608(x0)
    2640254D cub.lw.l1b x10, 612(x0)
    268025CD cub.lw.l1b x11, 616(x0)
    26C0264D cub.lw.l1b x12, 620(x0)
    270026CD cub.lw.l1b x13, 624(x0)
    2740274D cub.lw.l1b x14, 628(x0)
    00001044 cub.event_finish //fill end0
    
    00007047 cub.csrw 0, 0b0_0_000 //alu_flow_cfg0: cflow_mode,scache_dout_flow_sel,alu_din_flow_sel
    00107147 cub.csrw 2, 0b00000_00000_10000 //crossbar cfg
    020071C7 cub.csrw 3, 0b10000_00000 //crossbar cfg
    00007247 cub.csrw 4, 0b0000000 //acti_work_mode
    00017447 cub.csrw 8, 0b1 //scache_wr1 (sub_gap=1)
    000175C7 cub.csrw 11, 0b1 //scache_rd1 (sub_gap=1)
    00001044 cub.event_finish //fill end1
    
    E0804047 cub.scache_rd_en 0, byte, 1
    00001044 cub.event_finish //fill end2
    
    30000019 MQ_NOP(bar=3,nop_cycle_num=0)
    30000023 VQ_alu_event_call(event_addr=0,bar=3)
    00000020 VQ_alu_csrw(csr_addr=0,csr_wdata=0b0_0_000)
    400007A3 VQ_alu_event_call(event_addr=15,bar=4)
    40000019 MQ_NOP(bar=4,nop_cycle_num=0)
    00020020 VQ_alu_csrw(csr_addr=0,csr_wdata=0b1_0_000)//alu_flow_cfg0: cflow_mode,scache_dout_flow_sel,alu_din_flow_sel
    00000073 next_fetch_is_cpu
    j 0x1000
);

int main() {
int w_addr=0;
int f_addr=0;
int mv_len_w=1;
int mv_len_w_s=mv_len_w<<13;
int mv_len_f=2;
int mv_len_f_s=mv_len_f<<13;

int first_sub_flag=1;
int subch;
int bc_mode=0;
int bc_len=0;
int hl_op=0;
int bc_keep_2cycle_en=0;
int rgba_mode=1;
int rgba_stride=1;
int rgba_shift=0;
int run_cycle_num=17;
int pad0_sel=0;
int pad0_len=0;
int tcache_offset=0;
int scache_wr_addr = 0;

int mcfifo_mv_w_0=0;
int mcfifo_mv_w_1=0;
int mcfifo_mv_w_2=0;
int mcfifo_mv_w_3=0;
int mcfifo_mv_w_4=0;
int mcfifo_mv_w_5=0;
int mcfifo_mv_f=0;
int vcfifo_conv3d_0=0;
int vcfifo_conv3d_1=0;
int vcfifo_conv3d_2=0;
int vcfifo_conv3d_3=0;
int vcfifo_conv3d_4=0;
int vcfifo_conv3d_5=0;

int vcfifo_conv3d_base0=(run_cycle_num<<24)+(bc_keep_2cycle_en<<8)+(hl_op<<7)+bc_mode;
int vcfifo_conv3d_base1=0;

int load_addr=0;
int load_sub_len=128;
int load_sub_len_w=load_sub_len<<13;
int mcfifo_load_w=load_sub_len_w+load_addr;

int vcfifo_psum=0;
int vcfifo_scache_wr = 64*4;
int vcfifo_scache_rd_0 = 0;
int vcfifo_scache_rd_1 = 64*4;
//vcfifo_conv3d=first_sub_flag<<29+pad0_len<<25+pad0_sel<<24+run_cycle_num<<16+rgba_shift<<11+rgba_stride<<10+rgba_mode<<9+bc_keep_2cycle_en<<8+hl_op<<7+bc_len<<1+bc_mode;

int fmap_top_pad_en=0;//图片分割的第一块，需要上补pad
int fmap_bottom_pad_en=0;//图片分割的第六块，需要下补pad
int split_num=0;
int core_id;//这个是core真实的id号，可用于做判断
int param_zero=0;
asm volatile (
    "csrrs %0, 0xF14, %1\n"
    : "=r" (core_id)
    : "r" (param_zero)
);
split_num = (core_id>9) ? 3 : 4;    // core 10 和 11 只需要取3次， 32*2+32(24+8补零)；其他的core取4次：32*4

int addr[11][]

for(int k=0; k<split_num; k++) {
    fmap_top_pad_en=(k==0) && (core_id == 8 || core_id == 9);
    fmap_bottom_pad_en=(k==3) && (core_id>9);//由于分割的最后一块补零，需要的有效输出只有11个行，故不需要下补pad
    asm volatile (
        "storec %0, MQ\n"
        :: "r" (mcfifo_load_w));
    
    //load fmap+scache_len
    // core 8 or 9 的 k = 0
    if(fmap_top_pad_en){
        asm volatile (
            next_fetch_is_npu
            NOC_cfg ( addr=0 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 0 绝对寻址
            NOC_cfg ( addr=1 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 
            NOC_cfg ( addr=2 , wdata=1, cfifo_wdata=0,cfifo_en=0 )     # 1 多节点读合并开 
            NOC_cfg ( addr=3 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 0 片外读取
            NOC_cfg ( addr=4 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 0 pingpang 关 
            NOC_cfg ( addr=5 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 目标节点
            NOC_cfg ( addr=6 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # ping基地址 第一部分激活直接用基地址       取另一半数据的时候用40 ==============
            NOC_cfg ( addr=7 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 比上一个地址+80,跳到第二行(一行80个数据)  取另一半数据的时候用120 ==============
            // 普通模式通过dma读ddr没有跳转,对内部L2 SRAM才可以跳转,所以下面8条没有用
            NOC_cfg ( addr=8 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # gap0 
            NOC_cfg ( addr=9 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # gap1
            NOC_cfg ( addr=10 , wdata=0, cfifo_wdata=0,cfifo_en=0 )    # gap2 
            NOC_cfg ( addr=11 , wdata=1, cfifo_wdata=0,cfifo_en=0 )    # gap3
            NOC_cfg ( addr=12 , wdata=0, cfifo_wdata=0,cfifo_en=0 )    # lenth0
            NOC_cfg ( addr=13 , wdata=0, cfifo_wdata=0,cfifo_en=0 )    # lenth1
            NOC_cfg ( addr=14 , wdata=0, cfifo_wdata=0,cfifo_en=0)     # lenth2
            NOC_cfg ( addr=15 , wdata=2559, cfifo_wdata=0,cfifo_en=0)  # lenth3 dmaloop enable = 0时为ping length
            NOC_cfg ( addr=16 , wdata=0, cfifo_wdata=0,cfifo_en=0)   
            NOC_cfg ( addr=17 , wdata=2559, cfifo_wdata=0,cfifo_en=0)  # ping length   32*80=2560
            NOC_cfg ( addr=18 , wdata=0, cfifo_wdata=0,cfifo_en=0) 
            NOC_cfg ( addr=19 , wdata=926, cfifo_wdata=0,cfifo_en=0)   # 广播的范围 north_id, east_id, south_id, west_id centernode  1110 0111 1000
            NOC_cfg ( addr=20 , wdata=768, cfifo_wdata=0,cfifo_en=0)   # 同步的目标 12bit中选取对应bit 0011 0000 0000
            NOC_cfg ( addr=21 , wdata=1, cfifo_wdata=0,cfifo_en=0)     # feature 
            NOC_cfg ( addr=29 , wdata=0, cfifo_wdata=0,cfifo_en=0)    # 
            NOC_cfg ( addr=30 , wdata=0, cfifo_wdata=0,cfifo_en=0)     # dmaloop enable = 0
            npu_load     (we=wr,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=128,addr=0,sys_len=20,mv_last_dis=0,cfifo_en=1,bar=0) //load_fmap 640*32*4*8bit/256bit=2560
            noc_req (comd_type=4, bar=0) // 检查是否完成fmap搬运
            MQ_NOP (bar=0, nop_cycle_num=1)
            MQ_NOP (bar=0, nop_cycle_num=1)
            MQ_NOP (bar=0, nop_cycle_num=1)
            MQ_NOP (bar=0, nop_cycle_num=1)
            MQ_NOP (bar=0, nop_cycle_num=1)
            MQ_NOP (bar=0, nop_cycle_num=1)
            MQ_NOP (bar=0, nop_cycle_num=1)
            VQ_alu_csrw(csr_addr=7,csr_wdata=0b1_00111100)//scache_wr0 (sub_len=15*4,sys_len=1)
            VQ_alu_csrw(csr_addr=10,csr_wdata=0b1_00111100)//scache_rd0 (sub_len=1,sys_len=15*4)
            next_fetch_is_cpu
        );
    }
    else if(core_id == 8 || core_id == 9) {
        // core 8 9 的其他k
        asm volatile (
            next_fetch_is_npu  //TODO: 定义地址变量  (用2维数组)
            NOC_cfg ( addr=6 , wdata= 0+k*2240, cfifo_wdata=0,cfifo_en=0)    # ping基地址 ============== 2720 - 160*2
            npu_load     (we=wr,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=128,addr=0,sys_len=20,mv_last_dis=0,cfifo_en=1,bar=0) //load_fmap 640*32*4*8bit/256bit=2560
            noc_req (comd_type=4, bar=0) // 检查是否完成fmap搬运
            MQ_NOP (bar=0, nop_cycle_num=1)
            MQ_NOP (bar=0, nop_cycle_num=1)
            MQ_NOP (bar=0, nop_cycle_num=1)
            MQ_NOP (bar=0, nop_cycle_num=1)
            MQ_NOP (bar=0, nop_cycle_num=1)
            MQ_NOP (bar=0, nop_cycle_num=1)
            MQ_NOP (bar=0, nop_cycle_num=1)
            VQ_alu_csrw(csr_addr=7,csr_wdata=0b1_00111000)//scache_wr0 (sub_len=14*4,sys_len=1)
            VQ_alu_csrw(csr_addr=10,csr_wdata=0b1_00111000)//scache_rd0 (sub_len=1,sys_len=14*4)
            next_fetch_is_cpu
        );
    }
    // core 10 11
    else if(core_id == 10 || core_id == 11){
        // 前2次 32
        if(k < 2){
            asm volatile(
                next_fetch_is_npu
                NOC_cfg ( addr=0 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 0 绝对寻址
                NOC_cfg ( addr=1 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 
                NOC_cfg ( addr=2 , wdata=1, cfifo_wdata=0,cfifo_en=0 )     # 1 多节点读合并开 
                NOC_cfg ( addr=3 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 0 片外读取
                NOC_cfg ( addr=4 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 0 pingpang 关 
                NOC_cfg ( addr=5 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 目标节点
                NOC_cfg ( addr=6 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # ping基地址 第一部分激活直接用基地址       取另一半数据的时候用40 ==============
                NOC_cfg ( addr=7 , wdata=0, cfifo_wdata=0,cfifo_en=0 )    # 比上一个地址+80,跳到第二行(一行80个数据)  取另一半数据的时候用120 ==============
                NOC_cfg ( addr=8 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # gap0 
                NOC_cfg ( addr=9 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # gap1
                NOC_cfg ( addr=10 , wdata=0, cfifo_wdata=0,cfifo_en=0 )    # gap2 
                NOC_cfg ( addr=11 , wdata=1, cfifo_wdata=0,cfifo_en=0 )    # gap3
                NOC_cfg ( addr=12 , wdata=0, cfifo_wdata=0,cfifo_en=0 )    # lenth0
                NOC_cfg ( addr=13 , wdata=0, cfifo_wdata=0,cfifo_en=0 )    # lenth1
                NOC_cfg ( addr=14 , wdata=0, cfifo_wdata=0,cfifo_en=0)     # lenth2
                NOC_cfg ( addr=15 , wdata=2559, cfifo_wdata=0,cfifo_en=0)    # lenth3 设置为单行要取的长度
                NOC_cfg ( addr=16 , wdata=0, cfifo_wdata=0,cfifo_en=0)   
                NOC_cfg ( addr=17 , wdata=2559, cfifo_wdata=0,cfifo_en=0)  # ping length   32*80=2560
                NOC_cfg ( addr=18 , wdata=0, cfifo_wdata=0,cfifo_en=0) 
                NOC_cfg ( addr=19 , wdata=148, cfifo_wdata=0,cfifo_en=0)   # 广播的范围 north_id, east_id, south_id, west_id centernode  0000 1001 0100 ===========
                NOC_cfg ( addr=20 , wdata=85, cfifo_wdata=0,cfifo_en=0 )   # 同步的目标 0000 0101 0101==============
                NOC_cfg ( addr=21 , wdata=1, cfifo_wdata=0,cfifo_en=0)     # feature 
                NOC_cfg ( addr=29 , wdata=0, cfifo_wdata=0,cfifo_en=0)    # 
                NOC_cfg ( addr=30 , wdata=0, cfifo_wdata=0,cfifo_en=0)    # dmaloop enable = 0
                NOC_cfg ( addr=31 , wdata=0, cfifo_wdata=0,cfifo_en=0)    # 
                npu_load     (we=wr,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=128,addr=0,sys_len=20,mv_last_dis=0,cfifo_en=1,bar=0) //load_fmap 640*32*4*8bit/256bit=2560
                noc_req (comd_type=4, bar=0) // 检查是否完成fmap搬运
                VQ_alu_csrw(csr_addr=7,csr_wdata=0b1_00111100)//scache_wr0 (sub_len=15*4,sys_len=1)
                VQ_alu_csrw(csr_addr=10,csr_wdata=0b1_00111100)//scache_rd0 (sub_len=1,sys_len=15*4)
                next_fetch_is_cpu
            );
        }
        else if(k == 2){
             asm volatile(
                //TODO: 最后需要补pad的
                next_fetch_is_npu
                NOC_cfg ( addr=0 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 0 绝对寻址
                NOC_cfg ( addr=1 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 
                NOC_cfg ( addr=2 , wdata=1, cfifo_wdata=0,cfifo_en=0 )     # 1 多节点读合并开 
                NOC_cfg ( addr=3 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 0 片外读取
                NOC_cfg ( addr=4 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 0 pingpang 关 
                NOC_cfg ( addr=5 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 目标节点
                NOC_cfg ( addr=6 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # ping基地址 第一部分激活直接用基地址       取另一半数据的时候用40 ==============
                NOC_cfg ( addr=7 , wdata=0, cfifo_wdata=0,cfifo_en=0 )    # 比上一个地址+80,跳到第二行(一行80个数据)  取另一半数据的时候用120 ==============
                NOC_cfg ( addr=8 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # gap0 
                NOC_cfg ( addr=9 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # gap1
                NOC_cfg ( addr=10 , wdata=0, cfifo_wdata=0,cfifo_en=0 )    # gap2 
                NOC_cfg ( addr=11 , wdata=1, cfifo_wdata=0,cfifo_en=0 )    # gap3
                NOC_cfg ( addr=12 , wdata=0, cfifo_wdata=0,cfifo_en=0 )    # lenth0
                NOC_cfg ( addr=13 , wdata=0, cfifo_wdata=0,cfifo_en=0 )    # lenth1
                NOC_cfg ( addr=14 , wdata=0, cfifo_wdata=0,cfifo_en=0)     # lenth2
                NOC_cfg ( addr=15 , wdata=1919, cfifo_wdata=0,cfifo_en=0)  # lenth3 设置为单行要取的长度
                NOC_cfg ( addr=16 , wdata=0, cfifo_wdata=0,cfifo_en=0)   
                NOC_cfg ( addr=17 , wdata=1919, cfifo_wdata=0,cfifo_en=0)  # ping length 24*80=1920  用于给dma的,所以是纯数据,不包括补的pad,就是24行
                NOC_cfg ( addr=18 , wdata=0, cfifo_wdata=0,cfifo_en=0) 
                NOC_cfg ( addr=19 , wdata=148, cfifo_wdata=0,cfifo_en=0)   # 广播的范围 north_id, east_id, south_id, west_id centernode  0000 1001 0100 ===========
                NOC_cfg ( addr=20 , wdata=85, cfifo_wdata=0,cfifo_en=0 )   # 同步的目标 0000 0101 0101==============
                NOC_cfg ( addr=21 , wdata=1, cfifo_wdata=0,cfifo_en=0)     # feature 
                NOC_cfg ( addr=22 , wdata=0, cfifo_wdata=0,cfifo_en=0)    # 左   不用补,所以全是0
                NOC_cfg ( addr=23 , wdata=0, cfifo_wdata=0,cfifo_en=0)    # 右   不用补,所以全是0
                NOC_cfg ( addr=24 , wdata=0, cfifo_wdata=0,cfifo_en=0)    # 上    不用补,所以全是0
                NOC_cfg ( addr=25 , wdata=8, cfifo_wdata=0,cfifo_en=0)    # 下  8
                NOC_cfg ( addr=26 , wdata=24, cfifo_wdata=0,cfifo_en=0)    #有效行数
                NOC_cfg ( addr=27 , wdata=80, cfifo_wdata=0,cfifo_en=0)    #有效列数
                NOC_cfg ( addr=28 , wdata=1, cfifo_wdata=0,cfifo_en=0)    #pad mode  bit1 = 0 补零; bit0 = 1打开
                NOC_cfg ( addr=29 , wdata=0, cfifo_wdata=0,cfifo_en=0)    # 
                NOC_cfg ( addr=30 , wdata=0, cfifo_wdata=0,cfifo_en=0)    # dmaloop enable = 0
                NOC_cfg ( addr=31 , wdata=0, cfifo_wdata=0,cfifo_en=0)    # 
                npu_load     (we=wr,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=128,addr=0,sys_len=20,mv_last_dis=0,cfifo_en=1,bar=0) //load_fmap 640*32*4*8bit/256bit=2560
                noc_req (comd_type=4, bar=0) // 检查是否完成fmap搬运
                VQ_alu_csrw(csr_addr=7,csr_wdata=0b1_00111100)//scache_wr0 (sub_len=15*4,sys_len=1)
                VQ_alu_csrw(csr_addr=10,csr_wdata=0b1_00111100)//scache_rd0 (sub_len=1,sys_len=15*4)
                next_fetch_is_cpu
            );
        }
    }
    // core 0-7都是自己取自己的feature
    else {
        asm volatile (
            next_fetch_is_npu
            NOC_cfg ( addr=0 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 0 绝对寻址
            NOC_cfg ( addr=1 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 
            NOC_cfg ( addr=2 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 0 多节点读合并关 
            NOC_cfg ( addr=3 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 0 片外读取
            NOC_cfg ( addr=4 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 0 pingpang 关 
            NOC_cfg ( addr=5 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # 目标节点
            NOC_cfg ( addr=6 , wdata=0+k*2240, cfifo_wdata=0,cfifo_en=0 )     # ping基地址 第一部分激活直接用基地址       取另一半数据的时候用40 ==============
            NOC_cfg ( addr=7 , wdata=0, cfifo_wdata=0,cfifo_en=0 )    # 比上一个地址+80,跳到第二行(一行80个数据)  取另一半数据的时候用120 ==============
            NOC_cfg ( addr=8 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # gap0 
            NOC_cfg ( addr=9 , wdata=0, cfifo_wdata=0,cfifo_en=0 )     # gap1
            NOC_cfg ( addr=10 , wdata=0, cfifo_wdata=0,cfifo_en=0 )    # gap2 
            NOC_cfg ( addr=11 , wdata=1, cfifo_wdata=0,cfifo_en=0 )    # gap3
            NOC_cfg ( addr=12 , wdata=0, cfifo_wdata=0,cfifo_en=0 )    # lenth0
            NOC_cfg ( addr=13 , wdata=0, cfifo_wdata=0,cfifo_en=0 )    # lenth1
            NOC_cfg ( addr=14 , wdata=0, cfifo_wdata=0,cfifo_en=0)     # lenth2
            NOC_cfg ( addr=15 , wdata=2559, cfifo_wdata=0,cfifo_en=0)    # lenth3 设置为单行要取的长度
            NOC_cfg ( addr=16 , wdata=0, cfifo_wdata=0,cfifo_en=0)   
            NOC_cfg ( addr=17 , wdata=2559, cfifo_wdata=0,cfifo_en=0)  # ping length   32*80=2560
            NOC_cfg ( addr=18 , wdata=0, cfifo_wdata=0,cfifo_en=0) 
            NOC_cfg ( addr=21 , wdata=1, cfifo_wdata=0,cfifo_en=0)     # feature 
            NOC_cfg ( addr=29 , wdata=0, cfifo_wdata=0,cfifo_en=0)     #  一行有：640*32/256 = 80；一次取40  十进制数80 40
            NOC_cfg ( addr=30 , wdata=0, cfifo_wdata=0,cfifo_en=0)     # dmaloop gap # gap2整行，也就是160  然后最低位是enable为1，所以160*2+1=321
            NOC_cfg ( addr=31 , wdata=0, cfifo_wdata=0,cfifo_en=0)     # loop num 取多少行 32/2 = 16==============
            npu_load     (we=wr,l1b_mode=cache,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=128,addr=0,sys_len=20,mv_last_dis=0,cfifo_en=1,bar=0) //load_fmap 640*32*4*8bit/256bit=2560
            noc_req (comd_type=4, bar=0) // 检查是否完成fmap搬运
            VQ_alu_csrw(csr_addr=7,csr_wdata=0b1_00111000)//scache_wr0 (sub_len=14*4,sys_len=1)
            VQ_alu_csrw(csr_addr=10,csr_wdata=0b1_00111000)//scache_rd0 (sub_len=1,sys_len=14*4)
            next_fetch_is_cpu
        );
    }

    for(int j=0; j<80; j++) { //320/4=80
        if(j==0 || j==79){
            for(int i=0; i<2; i++) { //做完K6*6 输出:15*4/14*4
                f_addr=(j==0) ? i*80 : i*80+(j-1);
                mcfifo_mv_f=mv_len_f_s+f_addr;

                for(int l=0; l<3; l++) {
                    w_addr=i*6+l*6*2;
                    first_sub_flag=(i==0 && l==0);
                    tcache_offset=fmap_top_pad_en ? (l==2) : l;
                    rgba_shift=(j==0) ? -2 : 6;
                    pad0_len=(fmap_top_pad_en&&(l==0));
                    pad0_sel=fmap_top_pad_en&&(l==0);
                    bc_len=fmap_top_pad_en ? 15-pad0_len : 14;
                    vcfifo_conv3d_base1=vcfifo_conv3d_base0+(pad0_len<<12)+(pad0_sel<<16)+(tcache_offset<<8)+(bc_len<<1); //计算weight的一行，6个pixel，6次conv_start

                    //分别对应下面7条指令
                    mcfifo_mv_w_0=mv_len_w_s+w_addr;
                    vcfifo_conv3d_0=vcfifo_conv3d_base1+(first_sub_flag<<22)+((rgba_shift&0x1F)<<17);
                    mcfifo_mv_w_1=mcfifo_mv_w_0+1;
                    vcfifo_conv3d_1=vcfifo_conv3d_base1+(((rgba_shift+1)&0x1F)<<17);
                    mcfifo_mv_w_2=mcfifo_mv_w_1+1;
                    vcfifo_conv3d_2=vcfifo_conv3d_base1+(((rgba_shift+2)&0x1F)<<17);
                    mcfifo_mv_w_3=mcfifo_mv_w_2+1;
                    vcfifo_conv3d_3=vcfifo_conv3d_base1+(((rgba_shift+3)&0x1F)<<17);
                    mcfifo_mv_w_4=mcfifo_mv_w_3+1;
                    vcfifo_conv3d_4=vcfifo_conv3d_base1+(((rgba_shift+4)&0x1F)<<17);
                    mcfifo_mv_w_5=mcfifo_mv_w_4+1;
                    vcfifo_conv3d_5=vcfifo_conv3d_base1+(((rgba_shift+5)&0x1F)<<17);

                    asm volatile (
                        "storec %0, MQ\n"
                        :: "r" (mcfifo_mv_w_0));
                    if(l==0) {
                        asm volatile (
                            "storec %0, MQ\n"
                            :: "r" (mcfifo_mv_f));                    
                    }
                    asm volatile (
                        "storec %0, VQ\n"
                        :: "r" (vcfifo_conv3d_0));
                    asm volatile (
                        "storec %0, MQ\n"
                        :: "r" (mcfifo_mv_w_1));
                    asm volatile (
                        "storec %0, VQ\n"
                        :: "r" (vcfifo_conv3d_1));        
                    asm volatile (
                        "storec %0, MQ\n"
                        :: "r" (mcfifo_mv_w_2));
                    asm volatile (
                        "storec %0, VQ\n"
                        :: "r" (vcfifo_conv3d_2));
                    asm volatile (
                        "storec %0, MQ\n"
                        :: "r" (mcfifo_mv_w_3));
                    asm volatile (
                        "storec %0, VQ\n"
                        :: "r" (vcfifo_conv3d_3));
                    asm volatile (
                        "storec %0, MQ\n"
                        :: "r" (mcfifo_mv_w_4));
                    asm volatile (
                        "storec %0, VQ\n"
                        :: "r" (vcfifo_conv3d_4));
                    asm volatile (
                        "storec %0, MQ\n"
                        :: "r" (mcfifo_mv_w_5));
                    asm volatile (
                        "storec %0, VQ\n"
                        :: "r" (vcfifo_conv3d_5));

                    asm volatile (
                        next_fetch_is_npu
                        npu_mv       (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=0,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0));
                    if(l==0){
                    asm volatile (    
                        npu_mv       (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=159,sub_gap=1,sub_len=2,addr=0,sys_len=16,mv_last_dis=0,cfifo_en=1,bar=1)); //mv_fmap，addr=0
                    }
                    if(fmap_top_pad_en){
                        asm volatile (
                            conv3d_start (first_sub_flag=1, start_index=0, end_index=14, tcache_stride=0, tcache_offset=0, bc_mode=0, bc_len=14, rgba_mode=1, rgba_stride=1, rgba_shift=-2, hl_op=0, bc_keep_2cycle_en=0, pad0_sel=head, pad0_len=1, run_cycle_num=17, cfifo_en=1, bar=1) //shift=-1 k0* (-2,-1,0,1）
                            npu_mv       (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=1,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
                            conv3d_start (first_sub_flag=0, start_index=0, end_index=14, tcache_stride=0, tcache_offset=0, bc_mode=0, bc_len=14, rgba_mode=1, rgba_stride=1, rgba_shift=-1, hl_op=0, bc_keep_2cycle_en=0, pad0_sel=head, pad0_len=1, run_cycle_num=17, cfifo_en=1, bar=0) //shift=0  k1* (-1,0,1,2)
                            npu_mv       (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=2,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
                            conv3d_start (first_sub_flag=0, start_index=0, end_index=14, tcache_stride=0, tcache_offset=0, bc_mode=0, bc_len=14, rgba_mode=1, rgba_stride=1, rgba_shift=0 , hl_op=0, bc_keep_2cycle_en=0, pad0_sel=head, pad0_len=1, run_cycle_num=17, cfifo_en=1, bar=0) //shift=1  k2* (0,1,2,3)
                            npu_mv       (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=3,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0) 
                            conv3d_start (first_sub_flag=0, start_index=0, end_index=14, tcache_stride=0, tcache_offset=0, bc_mode=0, bc_len=14, rgba_mode=1, rgba_stride=1, rgba_shift=1 , hl_op=0, bc_keep_2cycle_en=0, pad0_sel=head, pad0_len=1, run_cycle_num=17, cfifo_en=1, bar=0) //shift=-1 k3* (1,2,3,4）
                            npu_mv       (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=4,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
                            conv3d_start (first_sub_flag=0, start_index=0, end_index=14, tcache_stride=0, tcache_offset=0, bc_mode=0, bc_len=14, rgba_mode=1, rgba_stride=1, rgba_shift=2 , hl_op=0, bc_keep_2cycle_en=0, pad0_sel=head, pad0_len=1, run_cycle_num=17, cfifo_en=1, bar=0) //shift=0  k4* (2,3,4,5)
                            npu_mv       (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=5,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
                            conv3d_start (first_sub_flag=0, start_index=0, end_index=14, tcache_stride=0, tcache_offset=0, bc_mode=0, bc_len=14, rgba_mode=1, rgba_stride=1, rgba_shift=3 , hl_op=0, bc_keep_2cycle_en=0, pad0_sel=head, pad0_len=1, run_cycle_num=17, cfifo_en=1, bar=0) //shift=1  k5* (3,4,5,6)
                            next_fetch_is_cpu
                        );
                    }
                    else{
                        asm volatile (
                            conv3d_start (first_sub_flag=1, start_index=0, end_index=13, tcache_stride=0, tcache_offset=0, bc_mode=0, bc_len=14, rgba_mode=1, rgba_stride=1, rgba_shift=-2, hl_op=0, bc_keep_2cycle_en=0, pad0_sel=head, pad0_len=1, run_cycle_num=17, cfifo_en=1, bar=1) //shift=-1 k0* (-2,-1,0,1）
                            npu_mv       (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=1,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
                            conv3d_start (first_sub_flag=0, start_index=0, end_index=13, tcache_stride=0, tcache_offset=0, bc_mode=0, bc_len=14, rgba_mode=1, rgba_stride=1, rgba_shift=-1, hl_op=0, bc_keep_2cycle_en=0, pad0_sel=head, pad0_len=1, run_cycle_num=17, cfifo_en=1, bar=0) //shift=0  k1* (-1,0,1,2)
                            npu_mv       (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=2,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
                            conv3d_start (first_sub_flag=0, start_index=0, end_index=13, tcache_stride=0, tcache_offset=0, bc_mode=0, bc_len=14, rgba_mode=1, rgba_stride=1, rgba_shift=0 , hl_op=0, bc_keep_2cycle_en=0, pad0_sel=head, pad0_len=1, run_cycle_num=17, cfifo_en=1, bar=0) //shift=1  k2* (0,1,2,3)
                            npu_mv       (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=3,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0) 
                            conv3d_start (first_sub_flag=0, start_index=0, end_index=13, tcache_stride=0, tcache_offset=0, bc_mode=0, bc_len=14, rgba_mode=1, rgba_stride=1, rgba_shift=1 , hl_op=0, bc_keep_2cycle_en=0, pad0_sel=head, pad0_len=1, run_cycle_num=17, cfifo_en=1, bar=0) //shift=-1 k3* (1,2,3,4）
                            npu_mv       (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=4,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
                            conv3d_start (first_sub_flag=0, start_index=0, end_index=13, tcache_stride=0, tcache_offset=0, bc_mode=0, bc_len=14, rgba_mode=1, rgba_stride=1, rgba_shift=2 , hl_op=0, bc_keep_2cycle_en=0, pad0_sel=head, pad0_len=1, run_cycle_num=17, cfifo_en=1, bar=0) //shift=0  k4* (2,3,4,5)
                            npu_mv       (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=5,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
                            conv3d_start (first_sub_flag=0, start_index=0, end_index=13, tcache_stride=0, tcache_offset=0, bc_mode=0, bc_len=14, rgba_mode=1, rgba_stride=1, rgba_shift=3 , hl_op=0, bc_keep_2cycle_en=0, pad0_sel=head, pad0_len=1, run_cycle_num=17, cfifo_en=1, bar=0) //shift=1  k5* (3,4,5,6)
                            next_fetch_is_cpu
                        );                        
                    }
                }
            }//3*3end

            if(fmap_top_pad_en){
                asm volatile (
                    //npu_store(cfifo_en=0,bar=0);
                    VQ_NOP       (bar=0,nop_cycle_num=4)
                    psum_rd      (rd_num=14,rd_ch_sel=0,rd_rgb_sel=0,scache_wr_addr=0,scache_wr_size=byte,run_cycle_num=17,cfifo_en=0,bar=0)
                    psum_rd      (rd_num=14,rd_ch_sel=0,rd_rgb_sel=1,scache_wr_addr=0,scache_wr_size=byte,run_cycle_num=17,cfifo_en=0,bar=0)
                    psum_rd      (rd_num=14,rd_ch_sel=1,rd_rgb_sel=0,scache_wr_addr=0,scache_wr_size=byte,run_cycle_num=17,cfifo_en=0,bar=0)
                    psum_rd      (rd_num=14,rd_ch_sel=1,rd_rgb_sel=1,scache_wr_addr=0,scache_wr_size=byte,run_cycle_num=17,cfifo_en=0,bar=0)
                    VQ_NOP       (bar=0,nop_cycle_num=4)
                    VQ_scache_rd_en(addr=0,size=byte,sign_ext=1,rd_cycle_num=16,wait_type=0,cfifo_en=0,bar=0)
                );
            }
            else{
                asm volatile (
                    //npu_store(cfifo_en=0,bar=0);
                    VQ_NOP       (bar=0,nop_cycle_num=4)
                    psum_rd      (rd_num=13,rd_ch_sel=0,rd_rgb_sel=0,scache_wr_addr=0,scache_wr_size=byte,run_cycle_num=17,cfifo_en=0,bar=0)
                    psum_rd      (rd_num=13,rd_ch_sel=0,rd_rgb_sel=1,scache_wr_addr=0,scache_wr_size=byte,run_cycle_num=17,cfifo_en=0,bar=0)
                    psum_rd      (rd_num=13,rd_ch_sel=1,rd_rgb_sel=0,scache_wr_addr=0,scache_wr_size=byte,run_cycle_num=17,cfifo_en=0,bar=0)
                    psum_rd      (rd_num=13,rd_ch_sel=1,rd_rgb_sel=1,scache_wr_addr=0,scache_wr_size=byte,run_cycle_num=17,cfifo_en=0,bar=0)
                    VQ_NOP       (bar=0,nop_cycle_num=4)
                    VQ_scache_rd_en(addr=0,size=byte,sign_ext=1,rd_cycle_num=16,wait_type=0,cfifo_en=0,bar=0)
                    
                );
            }
        }
        /*
        else if(j==79){ //最后一列，需要补右pad
            for(int i=0; i<2; i++) {
                f_addr=i*80+(j-1);
                mcfifo_mv_f=mv_len_f_s+f_addr;

                for(int l=0; l<3; l++) {
                    w_addr=i*6+l*6*2;
                    first_sub_flag=(i==0 && l==0);
                    tcache_offset=(l==2);
                    rgba_shift=6;
                    pad0_len=(l==0);
                    pad0_sel=(l==0);
                    bc_len=15-pad0_len;
                    vcfifo_conv3d_base1=vcfifo_conv3d_base0+(pad0_len<<12)+(pad0_sel<<16)+(tcache_offset<<8)+(bc_len<<1); //计算weight的一行，6个pixel，6次conv_start

                    //分别对应下面7条指令
                    mcfifo_mv_w_0=mv_len_w_s+w_addr;
                    vcfifo_conv3d_0=vcfifo_conv3d_base1+(first_sub_flag<<22)+((rgba_shift&0x1F)<<17);
                    mcfifo_mv_w_1=mcfifo_mv_w_0+1;
                    vcfifo_conv3d_1=vcfifo_conv3d_base1+(((rgba_shift+1)&0x1F)<<17);
                    mcfifo_mv_w_2=mcfifo_mv_w_1+1;
                    vcfifo_conv3d_2=vcfifo_conv3d_base1+(((rgba_shift+2)&0x1F)<<17);
                    mcfifo_mv_w_3=mcfifo_mv_w_2+1;
                    vcfifo_conv3d_3=vcfifo_conv3d_base1+(((rgba_shift+3)&0x1F)<<17);
                    mcfifo_mv_w_4=mcfifo_mv_w_3+1;
                    vcfifo_conv3d_4=vcfifo_conv3d_base1+(((rgba_shift+4)&0x1F)<<17);
                    mcfifo_mv_w_5=mcfifo_mv_w_4+1;
                    vcfifo_conv3d_5=vcfifo_conv3d_base1+(((rgba_shift+5)&0x1F)<<17);

                    asm volatile (
                        "storec %0, MQ\n"
                        :: "r" (mcfifo_mv_w_0));
                    if(l==0) {
                        asm volatile (
                            "storec %0, MQ\n"
                            :: "r" (mcfifo_mv_f));                    
                    }
                    asm volatile (
                        "storec %0, VQ\n"
                        :: "r" (vcfifo_conv3d_0));
                    asm volatile (
                        "storec %0, MQ\n"
                        :: "r" (mcfifo_mv_w_1));
                    asm volatile (
                        "storec %0, VQ\n"
                        :: "r" (vcfifo_conv3d_1));        
                    asm volatile (
                        "storec %0, MQ\n"
                        :: "r" (mcfifo_mv_w_2));
                    asm volatile (
                        "storec %0, VQ\n"
                        :: "r" (vcfifo_conv3d_2));
                    asm volatile (
                        "storec %0, MQ\n"
                        :: "r" (mcfifo_mv_w_3));
                    asm volatile (
                        "storec %0, VQ\n"
                        :: "r" (vcfifo_conv3d_3));
                    asm volatile (
                        "storec %0, MQ\n"
                        :: "r" (mcfifo_mv_w_4));
                    asm volatile (
                        "storec %0, VQ\n"
                        :: "r" (vcfifo_conv3d_4));
                    asm volatile (
                        "storec %0, MQ\n"
                        :: "r" (mcfifo_mv_w_5));
                    asm volatile (
                        "storec %0, VQ\n"
                        :: "r" (vcfifo_conv3d_5));

                    asm volatile (
                        next_fetch_is_npu
                        npu_mv       (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=0,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0));
                    if(l==0){
                    asm volatile (    
                        npu_mv       (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=159,sub_gap=1,sub_len=2,addr=0,sys_len=16,mv_last_dis=0,cfifo_en=1,bar=1)); //mv_fmap，addr=0
                    }
                    asm volatile (
                        conv3d_start (first_sub_flag=1, start_index=0, end_index=14, tcache_stride=0, tcache_offset=0, bc_mode=0, bc_len=14, rgba_mode=1, rgba_stride=1, rgba_shift=6, hl_op=0, bc_keep_2cycle_en=0, pad0_sel=head, pad0_len=1, run_cycle_num=17, cfifo_en=1, bar=1) //shift=-1 k0* (-2,-1,0,1）
                        npu_mv       (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=1,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
                        conv3d_start (first_sub_flag=0, start_index=0, end_index=14, tcache_stride=0, tcache_offset=0, bc_mode=0, bc_len=14, rgba_mode=1, rgba_stride=1, rgba_shift=7, hl_op=0, bc_keep_2cycle_en=0, pad0_sel=head, pad0_len=1, run_cycle_num=17, cfifo_en=1, bar=0) //shift=0  k1* (-1,0,1,2)
                        npu_mv       (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=2,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
                        conv3d_start (first_sub_flag=0, start_index=0, end_index=14, tcache_stride=0, tcache_offset=0, bc_mode=0, bc_len=14, rgba_mode=1, rgba_stride=1, rgba_shift=8 , hl_op=0, bc_keep_2cycle_en=0, pad0_sel=head, pad0_len=1, run_cycle_num=17, cfifo_en=1, bar=0) //shift=1  k2* (0,1,2,3)
                        npu_mv       (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=3,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0) 
                        conv3d_start (first_sub_flag=0, start_index=0, end_index=14, tcache_stride=0, tcache_offset=0, bc_mode=0, bc_len=14, rgba_mode=1, rgba_stride=1, rgba_shift=9 , hl_op=0, bc_keep_2cycle_en=0, pad0_sel=head, pad0_len=1, run_cycle_num=17, cfifo_en=1, bar=0) //shift=-1 k3* (1,2,3,4）
                        npu_mv       (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=4,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
                        conv3d_start (first_sub_flag=0, start_index=0, end_index=14, tcache_stride=0, tcache_offset=0, bc_mode=0, bc_len=14, rgba_mode=1, rgba_stride=1, rgba_shift=10 , hl_op=0, bc_keep_2cycle_en=0, pad0_sel=head, pad0_len=1, run_cycle_num=17, cfifo_en=1, bar=0) //shift=0  k4* (2,3,4,5)
                        npu_mv       (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=5,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
                        conv3d_start (first_sub_flag=0, start_index=0, end_index=14, tcache_stride=0, tcache_offset=0, bc_mode=0, bc_len=14, rgba_mode=1, rgba_stride=1, rgba_shift=11 , hl_op=0, bc_keep_2cycle_en=0, pad0_sel=head, pad0_len=1, run_cycle_num=17, cfifo_en=1, bar=0) //shift=1  k5* (3,4,5,6)
                        next_fetch_is_cpu
                    );
                }
            }//3*3end

            asm volatile (
                VQ_NOP       (bar=0,nop_cycle_num=4)
                psum_rd      (rd_num=14,rd_ch_sel=0,rd_rgb_sel=0,scache_wr_addr=0,scache_wr_size=byte,run_cycle_num=17,cfifo_en=0,bar=0)
                psum_rd      (rd_num=14,rd_ch_sel=0,rd_rgb_sel=1,scache_wr_addr=0,scache_wr_size=byte,run_cycle_num=17,cfifo_en=0,bar=0)
                psum_rd      (rd_num=14,rd_ch_sel=1,rd_rgb_sel=0,scache_wr_addr=0,scache_wr_size=byte,run_cycle_num=17,cfifo_en=0,bar=0)
                psum_rd      (rd_num=14,rd_ch_sel=1,rd_rgb_sel=1,scache_wr_addr=0,scache_wr_size=byte,run_cycle_num=17,cfifo_en=0,bar=0)
            );
        } //j==79 end
        */
        else{
            for(int i=0; i<2; i++) {
                f_addr=i*80+(j-1);
                mcfifo_mv_f=mv_len_f_s+f_addr;

                for(int l=0; l<3; l++) {
                    w_addr=i*6+l*6*2;
                    first_sub_flag=(i==0 && l==0);
                    tcache_offset=fmap_top_pad_en ? (l==2) : l;
                    rgba_shift=6;
                    pad0_len=(fmap_top_pad_en&&(l==0));
                    pad0_sel=(fmap_top_pad_en&&(l==0));
                    bc_len=fmap_top_pad_en ? 15-pad0_len : 14;
                    vcfifo_conv3d_base1=vcfifo_conv3d_base0+(pad0_len<<12)+(pad0_sel<<16)+(tcache_offset<<8)+(bc_len<<1); //计算weight的一行，6个pixel，6次conv_start

                    //分别对应下面7条指令
                    mcfifo_mv_w_0=mv_len_w_s+w_addr;
                    vcfifo_conv3d_0=vcfifo_conv3d_base1+(first_sub_flag<<22)+((rgba_shift&0x1F)<<17);
                    mcfifo_mv_w_1=mcfifo_mv_w_0+1;
                    vcfifo_conv3d_1=vcfifo_conv3d_base1+(((rgba_shift+1)&0x1F)<<17);
                    mcfifo_mv_w_2=mcfifo_mv_w_1+1;
                    vcfifo_conv3d_2=vcfifo_conv3d_base1+(((rgba_shift+2)&0x1F)<<17);
                    mcfifo_mv_w_3=mcfifo_mv_w_2+1;
                    vcfifo_conv3d_3=vcfifo_conv3d_base1+(((rgba_shift+3)&0x1F)<<17);

                    asm volatile (
                        "storec %0, MQ\n"
                        :: "r" (mcfifo_mv_w_0));
                    if(l==0){
                        asm volatile (
                            "storec %0, MQ\n"
                            :: "r" (mcfifo_mv_f));
                    }
                    asm volatile (
                        "storec %0, VQ\n"
                        :: "r" (vcfifo_conv3d_0));
                    asm volatile (
                        "storec %0, MQ\n"
                        :: "r" (mcfifo_mv_w_1));
                    asm volatile (
                        "storec %0, VQ\n"
                        :: "r" (vcfifo_conv3d_1));        
                    asm volatile (
                        "storec %0, MQ\n"
                        :: "r" (mcfifo_mv_w_2));
                    asm volatile (
                        "storec %0, VQ\n"
                        :: "r" (vcfifo_conv3d_2));
                    asm volatile (
                        "storec %0, MQ\n"
                        :: "r" (mcfifo_mv_w_3));
                    asm volatile (
                        "storec %0, VQ\n"
                        :: "r" (vcfifo_conv3d_3));

                    asm volatile (
                        next_fetch_is_npu
                        npu_mv       (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=0,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0));
                    if(l==0){
                    asm volatile (    
                        npu_mv       (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=159,sub_gap=1,sub_len=2,addr=0,sys_len=16,mv_last_dis=0,cfifo_en=1,bar=1)); //mv_fmap，addr=0
                    }
                    if(fmap_top_pad_en){
                        asm volatile (
                            conv3d_start (first_sub_flag=1, start_index=0, end_index=14, tcache_stride=0, tcache_offset=0, bc_mode=0, bc_len=14, rgba_mode=1, rgba_stride=1, rgba_shift=-2, hl_op=0, bc_keep_2cycle_en=0, pad0_sel=head, pad0_len=1, run_cycle_num=17, cfifo_en=1, bar=1) //shift=-1 k0* (-2,-1,0,1）
                            npu_mv       (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=1,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
                            conv3d_start (first_sub_flag=0, start_index=0, end_index=14, tcache_stride=0, tcache_offset=0, bc_mode=0, bc_len=14, rgba_mode=1, rgba_stride=1, rgba_shift=-1, hl_op=0, bc_keep_2cycle_en=0, pad0_sel=head, pad0_len=1, run_cycle_num=17, cfifo_en=1, bar=0) //shift=0  k1* (-1,0,1,2)
                            npu_mv       (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=2,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
                            conv3d_start (first_sub_flag=0, start_index=0, end_index=14, tcache_stride=0, tcache_offset=0, bc_mode=0, bc_len=14, rgba_mode=1, rgba_stride=1, rgba_shift=0 , hl_op=0, bc_keep_2cycle_en=0, pad0_sel=head, pad0_len=1, run_cycle_num=17, cfifo_en=1, bar=0) //shift=1  k2* (0,1,2,3)
                            npu_mv       (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=3,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0) 
                            conv3d_start (first_sub_flag=0, start_index=0, end_index=14, tcache_stride=0, tcache_offset=0, bc_mode=0, bc_len=14, rgba_mode=1, rgba_stride=1, rgba_shift=1 , hl_op=0, bc_keep_2cycle_en=0, pad0_sel=head, pad0_len=1, run_cycle_num=17, cfifo_en=1, bar=0) //shift=-1 k3* (1,2,3,4）
                            next_fetch_is_cpu
                        );
                    }
                    else{
                        asm volatile (
                            conv3d_start (first_sub_flag=1, start_index=0, end_index=13, tcache_stride=0, tcache_offset=0, bc_mode=0, bc_len=14, rgba_mode=1, rgba_stride=1, rgba_shift=-2, hl_op=0, bc_keep_2cycle_en=0, pad0_sel=head, pad0_len=1, run_cycle_num=17, cfifo_en=1, bar=1) //shift=-1 k0* (-2,-1,0,1）
                            npu_mv       (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=1,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
                            conv3d_start (first_sub_flag=0, start_index=0, end_index=13, tcache_stride=0, tcache_offset=0, bc_mode=0, bc_len=14, rgba_mode=1, rgba_stride=1, rgba_shift=-1, hl_op=0, bc_keep_2cycle_en=0, pad0_sel=head, pad0_len=1, run_cycle_num=17, cfifo_en=1, bar=0) //shift=0  k1* (-1,0,1,2)
                            npu_mv       (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=2,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
                            conv3d_start (first_sub_flag=0, start_index=0, end_index=13, tcache_stride=0, tcache_offset=0, bc_mode=0, bc_len=14, rgba_mode=1, rgba_stride=1, rgba_shift=0 , hl_op=0, bc_keep_2cycle_en=0, pad0_sel=head, pad0_len=1, run_cycle_num=17, cfifo_en=1, bar=0) //shift=1  k2* (0,1,2,3)
                            npu_mv       (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=3,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0) 
                            conv3d_start (first_sub_flag=0, start_index=0, end_index=13, tcache_stride=0, tcache_offset=0, bc_mode=0, bc_len=14, rgba_mode=1, rgba_stride=1, rgba_shift=1 , hl_op=0, bc_keep_2cycle_en=0, pad0_sel=head, pad0_len=1, run_cycle_num=17, cfifo_en=1, bar=0) //shift=-1 k3* (1,2,3,4）
                            next_fetch_is_cpu
                        );                    
                    }
                }
            }

            for(int i=0; i<2; i++) { //做完K6*6 输出:15*4/14*4
                f_addr=i*80++(j-1)+1;
                mcfifo_mv_f=mv_len_f_s+f_addr;

                w_addr=i*6+4;
                tcache_offset=l;
                rgba_shift=2;
                pad0_len=fmap_top_pad_en;
                pad0_sel=fmap_top_pad_en;
                bc_len=fmap_top_pad_en ? 15 : 14;
                vcfifo_conv3d_base1=vcfifo_conv3d_base0; //计算weight的一行，6个pixel，6次conv_start

                //分别对应下面7条指令
                mcfifo_mv_w_0=mv_len_w_s+w_addr;
                mcfifo_mv_w_1=mcfifo_mv_w_0+1;
                if(fmap_top_pad_en){
                    vcfifo_conv3d_0=vcfifo_conv3d_base1+((rgba_shift&0x1F)<<17)+(pad0_len<<12)+(pad0_sel<<16)+((bc_len-1)<<1);
                    vcfifo_conv3d_1=vcfifo_conv3d_base1+(((rgba_shift+1)&0x1F)<<17)+(pad0_len<<12)+(pad0_sel<<16)++((bc_len-1)<<1);
                }
                else{
                    vcfifo_conv3d_0=vcfifo_conv3d_base1+((rgba_shift&0x1F)<<17)+(pad0_len<<12)+(pad0_sel<<16)+(bc_len<<1);
                    vcfifo_conv3d_1=vcfifo_conv3d_base1+(((rgba_shift+1)&0x1F)<<17)+(pad0_len<<12)+(pad0_sel<<16)++(bc_len<<1);
                }
                
                mcfifo_mv_w_2=mcfifo_mv_w_1+11;
                mcfifo_mv_w_3=mcfifo_mv_w_2+1;                
                if(fmap_top_pad_en){
                    vcfifo_conv3d_2=vcfifo_conv3d_base1+((rgba_shift&0x1F)<<17)+(bc_len<<1);
                    vcfifo_conv3d_3=vcfifo_conv3d_base1+(((rgba_shift+1)&0x1F)<<17)+(bc_len<<1);
                }
                else{
                    vcfifo_conv3d_2=vcfifo_conv3d_base1+((rgba_shift&0x1F)<<17)+(bc_len<<1)+(tcache_offset<<8);
                    vcfifo_conv3d_3=vcfifo_conv3d_base1+(((rgba_shift+1)&0x1F)<<17)+(bc_len<<1)+(tcache_offset<<8);                
                }

                mcfifo_mv_w_4=mcfifo_mv_w_3+11;
                mcfifo_mv_w_5=mcfifo_mv_w_4+1;
                if(fmap_top_pad_en){
                    vcfifo_conv3d_4=vcfifo_conv3d_base1+((rgba_shift&0x1F)<<17)+(bc_len<<1)+(tcache_offset<<8); 
                    vcfifo_conv3d_5=vcfifo_conv3d_base1+(((rgba_shift+1)&0x1F)<<17)+(bc_len<<1)+(tcache_offset<<8);
                }
                else{
                    vcfifo_conv3d_4=vcfifo_conv3d_base1+((rgba_shift&0x1F)<<17)+(bc_len<<1)+((tcache_offset+1)<<8);
                    vcfifo_conv3d_5=vcfifo_conv3d_base1+(((rgba_shift+1)&0x1F)<<17)+(bc_len<<1)+((tcache_offset+1)<<8);                
                }
                
                asm volatile (
                    "storec %0, MQ\n"
                    :: "r" (mcfifo_mv_w_0));
                asm volatile (
                    "storec %0, MQ\n"
                    :: "r" (mcfifo_mv_f));                
                asm volatile (
                    "storec %0, VQ\n"
                    :: "r" (vcfifo_conv3d_0));
                asm volatile (
                    "storec %0, MQ\n"
                    :: "r" (mcfifo_mv_w_1));
                asm volatile (
                    "storec %0, VQ\n"
                    :: "r" (vcfifo_conv3d_1));        
                asm volatile (
                    "storec %0, MQ\n"
                    :: "r" (mcfifo_mv_w_2));
                asm volatile (
                    "storec %0, VQ\n"
                    :: "r" (vcfifo_conv3d_2));
                asm volatile (
                    "storec %0, MQ\n"
                    :: "r" (mcfifo_mv_w_3));
                asm volatile (
                    "storec %0, VQ\n"
                    :: "r" (vcfifo_conv3d_3));
                asm volatile (
                    "storec %0, MQ\n"
                    :: "r" (mcfifo_mv_w_4));
                asm volatile (
                    "storec %0, VQ\n"
                    :: "r" (vcfifo_conv3d_4));
                asm volatile (
                    "storec %0, MQ\n"
                    :: "r" (mcfifo_mv_w_5));
                asm volatile (
                    "storec %0, VQ\n"
                    :: "r" (vcfifo_conv3d_5));

                if(fmap_top_pad_en){
                    asm volatile (
                        next_fetch_is_npu
                        npu_mv       (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=4,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
                        npu_mv       (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=159,sub_gap=1,sub_len=2,addr=1,sys_len=16,mv_last_dis=0,cfifo_en=1,bar=1) //mv_fmap，addr=1
                        conv3d_start (first_sub_flag=0, start_index=0, end_index=14, tcache_stride=0, tcache_offset=0, bc_mode=0, bc_len=14, rgba_mode=1, rgba_stride=1, rgba_shift=2, hl_op=0, bc_keep_2cycle_en=0, pad0_sel=head, pad0_len=1, run_cycle_num=17, cfifo_en=1, bar=1) //shift=-1 k0* (-2,-1,0,1）
                        npu_mv       (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=5,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
                        conv3d_start (first_sub_flag=0, start_index=0, end_index=14, tcache_stride=0, tcache_offset=0, bc_mode=0, bc_len=14, rgba_mode=1, rgba_stride=1, rgba_shift=3, hl_op=0, bc_keep_2cycle_en=0, pad0_sel=head, pad0_len=1, run_cycle_num=17, cfifo_en=1, bar=0) //shift=0  k1* (-1,0,1,2)
    
                        npu_mv       (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=16,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0) 
                        conv3d_start (first_sub_flag=0, start_index=0, end_index=14, tcache_stride=0, tcache_offset=0, bc_mode=0, bc_len=15, rgba_mode=1, rgba_stride=1, rgba_shift=2, hl_op=0, bc_keep_2cycle_en=0, pad0_sel=end, pad0_len=0, run_cycle_num=17, cfifo_en=1, bar=0) //shift=-1 k0* (-2,-1,0,1）
                        npu_mv       (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=17,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
                        conv3d_start (first_sub_flag=0, start_index=0, end_index=14, tcache_stride=0, tcache_offset=0, bc_mode=0, bc_len=15, rgba_mode=1, rgba_stride=1, rgba_shift=3, hl_op=0, bc_keep_2cycle_en=0, pad0_sel=end, pad0_len=0, run_cycle_num=17, cfifo_en=1, bar=0) //shift=0  k1* (-1,0,1,2)
    
                        npu_mv       (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=28,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
                        conv3d_start (first_sub_flag=0, start_index=0, end_index=14, tcache_stride=0, tcache_offset=1, bc_mode=0, bc_len=15, rgba_mode=1, rgba_stride=1, rgba_shift=2, hl_op=0, bc_keep_2cycle_en=0, pad0_sel=end, pad0_len=0, run_cycle_num=17, cfifo_en=1, bar=0) //shift=-1 k0* (-2,-1,0,1）
                        npu_mv       (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=29,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
                        conv3d_start (first_sub_flag=0, start_index=0, end_index=14, tcache_stride=0, tcache_offset=1, bc_mode=0, bc_len=15, rgba_mode=1, rgba_stride=1, rgba_shift=3, hl_op=0, bc_keep_2cycle_en=0, pad0_sel=end, pad0_len=0, run_cycle_num=17, cfifo_en=1, bar=0) //shift=0  k1* (-1,0,1,2)
                        next_fetch_is_cpu
                    );
                }
                else{
                    asm volatile (
                        next_fetch_is_npu
                        npu_mv       (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=4,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
                        npu_mv       (we=rd,l1b_mode=cache,tcache_bank_num=0,sys_gap=159,sub_gap=1,sub_len=2,addr=1,sys_len=16,mv_last_dis=0,cfifo_en=1,bar=1) //mv_fmap，addr=1
                        conv3d_start (first_sub_flag=0, start_index=0, end_index=13, tcache_stride=0, tcache_offset=0, bc_mode=0, bc_len=14, rgba_mode=1, rgba_stride=1, rgba_shift=2, hl_op=0, bc_keep_2cycle_en=0, pad0_sel=end, pad0_len=0, run_cycle_num=17, cfifo_en=1, bar=1) //shift=-1 k0* (-2,-1,0,1）
                        npu_mv       (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=5,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
                        conv3d_start (first_sub_flag=0, start_index=0, end_index=13, tcache_stride=0, tcache_offset=0, bc_mode=0, bc_len=14, rgba_mode=1, rgba_stride=1, rgba_shift=3, hl_op=0, bc_keep_2cycle_en=0, pad0_sel=end, pad0_len=0, run_cycle_num=17, cfifo_en=1, bar=0) //shift=0  k1* (-1,0,1,2)
    
                        npu_mv       (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=16,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0) 
                        conv3d_start (first_sub_flag=0, start_index=0, end_index=13, tcache_stride=0, tcache_offset=0, bc_mode=0, bc_len=14, rgba_mode=1, rgba_stride=1, rgba_shift=2, hl_op=0, bc_keep_2cycle_en=0, pad0_sel=end, pad0_len=0, run_cycle_num=17, cfifo_en=1, bar=0) //shift=-1 k0* (-2,-1,0,1）
                        npu_mv       (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=17,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
                        conv3d_start (first_sub_flag=0, start_index=0, end_index=13, tcache_stride=0, tcache_offset=0, bc_mode=0, bc_len=14, rgba_mode=1, rgba_stride=1, rgba_shift=3, hl_op=0, bc_keep_2cycle_en=0, pad0_sel=end, pad0_len=0, run_cycle_num=17, cfifo_en=1, bar=0) //shift=0  k1* (-1,0,1,2)
    
                        npu_mv       (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=28,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
                        conv3d_start (first_sub_flag=0, start_index=0, end_index=13, tcache_stride=0, tcache_offset=1, bc_mode=0, bc_len=14, rgba_mode=1, rgba_stride=1, rgba_shift=2, hl_op=0, bc_keep_2cycle_en=0, pad0_sel=end, pad0_len=0, run_cycle_num=17, cfifo_en=1, bar=0) //shift=-1 k0* (-2,-1,0,1）
                        npu_mv       (we=rd,l1b_mode=norm,tcache_bank_num=0,sys_gap=1,sub_gap=1,sub_len=1,addr=29,sys_len=1,mv_last_dis=0,cfifo_en=1,bar=0)
                        conv3d_start (first_sub_flag=0, start_index=0, end_index=13, tcache_stride=0, tcache_offset=1, bc_mode=0, bc_len=14, rgba_mode=1, rgba_stride=1, rgba_shift=3, hl_op=0, bc_keep_2cycle_en=0, pad0_sel=end, pad0_len=0, run_cycle_num=17, cfifo_en=1, bar=0) //shift=0  k1* (-1,0,1,2)
                        next_fetch_is_cpu
                    );                
                }
            }
            if(fmap_top_pad_en){
                asm volatile (
                    /*配置数据输出*/
                    NOC_cfg (addr=32,wdata=0,cfifo_wdata=0,cfifo_en=0)           //绝对寻址
                    NOC_cfg (addr=33,wdata=0,cfifo_wdata=0,cfifo_en=0)           //
                    NOC_cfg (addr=34,wdata=0,cfifo_wdata=0,cfifo_en=0)           // 数据直接输出到ddr
                    NOC_cfg (addr=35,wdata=0,cfifo_wdata=0,cfifo_en=0)            // 关闭pingpong
                    NOC_cfg (addr=37,wdata=0,cfifo_wdata=0,cfifo_en=0)          // 输出基地址偏移，需要根据输出行数变量进行配置
                    NOC_cfg (addr=42,wdata=1,cfifo_wdata=0,cfifo_en=0)           //loop gap 3
                    NOC_cfg (addr=46,wdata=1199,cfifo_wdata=0,cfifo_en=0)             // 输出总长度 15*80=1200 -1
                    NOC_cfg (addr=47,wdata=0,cfifo_wdata=0,cfifo_en=0)           //pingpongnum = 0
                    NOC_cfg (addr=48,wdata=1199,cfifo_wdata=0,cfifo_en=0)            // ping传输的长度15*80=1200 -1
                    npu_store(cfifo_en=0,bar =0)
                    VQ_scache_rd_en(addr=0,size=byte,sign_ext=1,rd_cycle_num=170,wait_type=1,cfifo_en=1,bar=0)
                    noc_req (comd_type=4, bar=0) // 检查是否完成搬运
                    MQ_NOP(bar=0,nop_cycle_num=0)
                    MQ_NOP(bar=0,nop_cycle_num=0)
                    MQ_NOP(bar=0,nop_cycle_num=0)
                    MQ_NOP(bar=0,nop_cycle_num=0)
                    MQ_NOP(bar=0,nop_cycle_num=0)
                    MQ_NOP(bar=0,nop_cycle_num=0)
                    MQ_NOP(bar=0,nop_cycle_num=0)
                    MQ_NOP(bar=0,nop_cycle_num=0)
                    VQ_NOP       (bar=0,nop_cycle_num=4)
                    psum_rd      (rd_num=14,rd_ch_sel=0,rd_rgb_sel=0,scache_wr_addr=0,scache_wr_size=byte,run_cycle_num=17,cfifo_en=0,bar=0)
                    psum_rd      (rd_num=14,rd_ch_sel=0,rd_rgb_sel=1,scache_wr_addr=0,scache_wr_size=byte,run_cycle_num=17,cfifo_en=0,bar=0)
                    psum_rd      (rd_num=14,rd_ch_sel=1,rd_rgb_sel=0,scache_wr_addr=0,scache_wr_size=byte,run_cycle_num=17,cfifo_en=0,bar=0)
                    psum_rd      (rd_num=14,rd_ch_sel=1,rd_rgb_sel=1,scache_wr_addr=0,scache_wr_size=byte,run_cycle_num=17,cfifo_en=0,bar=0)
                    VQ_NOP       (bar=0,nop_cycle_num=4)
                    VQ_scache_rd_en(addr=0,size=byte,sign_ext=1,rd_cycle_num=16,wait_type=0,cfifo_en=0,bar=0)
                );
            } else if(core_id == 8){
                asm volatile (
                    /*配置数据输出*/
                    NOC_cfg (addr=32,wdata=0,cfifo_wdata=0,cfifo_en=0)           //绝对寻址
                    NOC_cfg (addr=33,wdata=0,cfifo_wdata=0,cfifo_en=0)           //
                    NOC_cfg (addr=34,wdata=0,cfifo_wdata=0,cfifo_en=0)           // 数据直接输出到ddr
                    NOC_cfg (addr=35,wdata=0,cfifo_wdata=0,cfifo_en=0)            // 关闭pingpong
                    NOC_cfg (addr=37,wdata=2400 + (k-1)*(1120*2),cfifo_wdata=0,cfifo_en=0)          // 输出基地址偏移，需要根据输出行数变量进行配置
                    NOC_cfg (addr=42,wdata=1,cfifo_wdata=0,cfifo_en=0)           //loop gap 3
                    NOC_cfg (addr=46,wdata=1199,cfifo_wdata=0,cfifo_en=0)             // 输出总长度 15*80=1200 -1
                    NOC_cfg (addr=47,wdata=0,cfifo_wdata=0,cfifo_en=0)           //pingpongnum = 0
                    NOC_cfg (addr=48,wdata=1199,cfifo_wdata=0,cfifo_en=0)            // ping传输的长度15*80=1200 -1
                    npu_store(cfifo_en=0,bar =0)
                    VQ_scache_rd_en(addr=0,size=byte,sign_ext=1,rd_cycle_num=170,wait_type=1,cfifo_en=1,bar=0)
                    noc_req (comd_type=4, bar=0) // 检查是否完成搬运
                    MQ_NOP(bar=0,nop_cycle_num=0)
                    MQ_NOP(bar=0,nop_cycle_num=0)
                    MQ_NOP(bar=0,nop_cycle_num=0)
                    MQ_NOP(bar=0,nop_cycle_num=0)
                    MQ_NOP(bar=0,nop_cycle_num=0)
                    MQ_NOP(bar=0,nop_cycle_num=0)
                    MQ_NOP(bar=0,nop_cycle_num=0)
                    MQ_NOP(bar=0,nop_cycle_num=0)
                    VQ_NOP       (bar=0,nop_cycle_num=4)
                    psum_rd      (rd_num=14,rd_ch_sel=0,rd_rgb_sel=0,scache_wr_addr=0,scache_wr_size=byte,run_cycle_num=17,cfifo_en=0,bar=0)
                    psum_rd      (rd_num=14,rd_ch_sel=0,rd_rgb_sel=1,scache_wr_addr=0,scache_wr_size=byte,run_cycle_num=17,cfifo_en=0,bar=0)
                    psum_rd      (rd_num=14,rd_ch_sel=1,rd_rgb_sel=0,scache_wr_addr=0,scache_wr_size=byte,run_cycle_num=17,cfifo_en=0,bar=0)
                    psum_rd      (rd_num=14,rd_ch_sel=1,rd_rgb_sel=1,scache_wr_addr=0,scache_wr_size=byte,run_cycle_num=17,cfifo_en=0,bar=0)
                    VQ_NOP       (bar=0,nop_cycle_num=4)
                    VQ_scache_rd_en(addr=0,size=byte,sign_ext=1,rd_cycle_num=16,wait_type=0,cfifo_en=0,bar=0)
                );
            }

            // group1 的其他k
            else if(core_id == 9){
                asm volatile (
                    /*配置数据输出*/
                    NOC_cfg (addr=32,wdata=0,cfifo_wdata=0,cfifo_en=0)           //绝对寻址
                    NOC_cfg (addr=33,wdata=0,cfifo_wdata=0,cfifo_en=0)           //
                    NOC_cfg (addr=34,wdata=0,cfifo_wdata=0,cfifo_en=0)           // 数据直接输出到ddr
                    NOC_cfg (addr=35,wdata=0,cfifo_wdata=0,cfifo_en=0)            // 关闭pingpong
                    NOC_cfg (addr=37,wdata=1200+1120 + (k-1)*(1120*2),cfifo_wdata=0,cfifo_en=0)          // 输出基地址偏移，需要根据输出行数变量进行配置
                    NOC_cfg (addr=42,wdata=1,cfifo_wdata=0,cfifo_en=0)           //loop gap 3
                    NOC_cfg (addr=46,wdata=1119,cfifo_wdata=0,cfifo_en=0)             // 输出总长度 14*80=1120 -1
                    NOC_cfg (addr=47,wdata=0,cfifo_wdata=0,cfifo_en=0)           //pingpongnum = 0
                    NOC_cfg (addr=48,wdata=1119,cfifo_wdata=0,cfifo_en=0)            // ping传输的长度14*80=1120 -1
                    npu_store(cfifo_en=0,bar =0)
                    VQ_scache_rd_en(addr=0,size=byte,sign_ext=1,rd_cycle_num=170,wait_type=1,cfifo_en=1,bar=0)
                    noc_req (comd_type=4, bar=0) // 检查是否完成搬运
                    MQ_NOP(bar=0,nop_cycle_num=0)
                    MQ_NOP(bar=0,nop_cycle_num=0)
                    MQ_NOP(bar=0,nop_cycle_num=0)
                    MQ_NOP(bar=0,nop_cycle_num=0)
                    MQ_NOP(bar=0,nop_cycle_num=0)
                    MQ_NOP(bar=0,nop_cycle_num=0)
                    MQ_NOP(bar=0,nop_cycle_num=0)
                    MQ_NOP(bar=0,nop_cycle_num=0)
                    VQ_NOP       (bar=0,nop_cycle_num=4)
                    psum_rd      (rd_num=14,rd_ch_sel=0,rd_rgb_sel=0,scache_wr_addr=0,scache_wr_size=byte,run_cycle_num=17,cfifo_en=0,bar=0)
                    psum_rd      (rd_num=14,rd_ch_sel=0,rd_rgb_sel=1,scache_wr_addr=0,scache_wr_size=byte,run_cycle_num=17,cfifo_en=0,bar=0)
                    psum_rd      (rd_num=14,rd_ch_sel=1,rd_rgb_sel=0,scache_wr_addr=0,scache_wr_size=byte,run_cycle_num=17,cfifo_en=0,bar=0)
                    psum_rd      (rd_num=14,rd_ch_sel=1,rd_rgb_sel=1,scache_wr_addr=0,scache_wr_size=byte,run_cycle_num=17,cfifo_en=0,bar=0)
                    VQ_NOP       (bar=0,nop_cycle_num=4)
                    VQ_scache_rd_en(addr=0,size=byte,sign_ext=1,rd_cycle_num=16,wait_type=0,cfifo_en=0,bar=0)
                );
            }
            // group 3的最后一组写回
            else if((core_id == 10 || core_id == 11) && k == 2) {
                asm volatile (
                    /*配置数据输出*/
                    NOC_cfg (addr=32,wdata=0,cfifo_wdata=0,cfifo_en=0)           //绝对寻址
                    NOC_cfg (addr=33,wdata=0,cfifo_wdata=0,cfifo_en=0)           //
                    NOC_cfg (addr=34,wdata=0,cfifo_wdata=0,cfifo_en=0)           // 数据直接输出到ddr
                    NOC_cfg (addr=35,wdata=0,cfifo_wdata=0,cfifo_en=0)            // 关闭pingpong
                    NOC_cfg (addr=37,wdata=k*2*1120,cfifo_wdata=0,cfifo_en=0)          // 输出基地址偏移，需要根据输出行数变量进行配置
                    NOC_cfg (addr=42,wdata=1,cfifo_wdata=0,cfifo_en=0)           //loop gap 3
                    NOC_cfg (addr=46,wdata=879,cfifo_wdata=0,cfifo_en=0)             // 输出总长度 11*80=880 -1
                    NOC_cfg (addr=47,wdata=0,cfifo_wdata=0,cfifo_en=0)           //pingpongnum = 0
                    NOC_cfg (addr=48,wdata=879,cfifo_wdata=0,cfifo_en=0)            // ping传输的长度11*80=880 -1
                    npu_store(cfifo_en=0,bar =0)
                    VQ_scache_rd_en(addr=0,size=byte,sign_ext=1,rd_cycle_num=170,wait_type=1,cfifo_en=1,bar=0)
                    noc_req (comd_type=4, bar=0) // 检查是否完成搬运
                    MQ_NOP(bar=0,nop_cycle_num=0)
                    MQ_NOP(bar=0,nop_cycle_num=0)
                    MQ_NOP(bar=0,nop_cycle_num=0)
                    MQ_NOP(bar=0,nop_cycle_num=0)
                    MQ_NOP(bar=0,nop_cycle_num=0)
                    MQ_NOP(bar=0,nop_cycle_num=0)
                    MQ_NOP(bar=0,nop_cycle_num=0)
                    MQ_NOP(bar=0,nop_cycle_num=0)
                    VQ_NOP       (bar=0,nop_cycle_num=4)
                    psum_rd      (rd_num=14,rd_ch_sel=0,rd_rgb_sel=0,scache_wr_addr=0,scache_wr_size=byte,run_cycle_num=17,cfifo_en=0,bar=0)
                    psum_rd      (rd_num=14,rd_ch_sel=0,rd_rgb_sel=1,scache_wr_addr=0,scache_wr_size=byte,run_cycle_num=17,cfifo_en=0,bar=0)
                    psum_rd      (rd_num=14,rd_ch_sel=1,rd_rgb_sel=0,scache_wr_addr=0,scache_wr_size=byte,run_cycle_num=17,cfifo_en=0,bar=0)
                    psum_rd      (rd_num=14,rd_ch_sel=1,rd_rgb_sel=1,scache_wr_addr=0,scache_wr_size=byte,run_cycle_num=17,cfifo_en=0,bar=0)
                    VQ_NOP       (bar=0,nop_cycle_num=4)
                    VQ_scache_rd_en(addr=0,size=byte,sign_ext=1,rd_cycle_num=16,wait_type=0,cfifo_en=0,bar=0)
                );
            }
            else{
                asm volatile (
                    /*配置数据输出*/
                    NOC_cfg (addr=32,wdata=0,cfifo_wdata=0,cfifo_en=0)           //绝对寻址
                    NOC_cfg (addr=33,wdata=0,cfifo_wdata=0,cfifo_en=0)           //
                    NOC_cfg (addr=34,wdata=0,cfifo_wdata=0,cfifo_en=0)           // 数据直接输出到ddr
                    NOC_cfg (addr=35,wdata=0,cfifo_wdata=0,cfifo_en=0)            // 关闭pingpong
                    NOC_cfg (addr=37,wdata=k*2*1120,cfifo_wdata=0,cfifo_en=0)          // 输出基地址偏移，需要根据输出行数变量进行配置
                    NOC_cfg (addr=42,wdata=1,cfifo_wdata=0,cfifo_en=0)           //loop gap 3
                    NOC_cfg (addr=46,wdata=1119,cfifo_wdata=0,cfifo_en=0)             // 输出总长度 14*80=1120 -1
                    NOC_cfg (addr=47,wdata=0,cfifo_wdata=0,cfifo_en=0)           //pingpongnum = 0
                    NOC_cfg (addr=48,wdata=1119,cfifo_wdata=0,cfifo_en=0)            // ping传输的长度14*80=1120 -1
                    npu_store(cfifo_en=0,bar =0)
                    VQ_scache_rd_en(addr=0,size=byte,sign_ext=1,rd_cycle_num=170,wait_type=1,cfifo_en=1,bar=0)
                    noc_req (comd_type=4, bar=0) // 检查是否完成搬运
                    MQ_NOP(bar=0,nop_cycle_num=0)
                    MQ_NOP(bar=0,nop_cycle_num=0)
                    MQ_NOP(bar=0,nop_cycle_num=0)
                    MQ_NOP(bar=0,nop_cycle_num=0)
                    MQ_NOP(bar=0,nop_cycle_num=0)
                    MQ_NOP(bar=0,nop_cycle_num=0)
                    MQ_NOP(bar=0,nop_cycle_num=0)
                    MQ_NOP(bar=0,nop_cycle_num=0)
                    VQ_NOP       (bar=0,nop_cycle_num=4)
                    psum_rd      (rd_num=14,rd_ch_sel=0,rd_rgb_sel=0,scache_wr_addr=0,scache_wr_size=byte,run_cycle_num=17,cfifo_en=0,bar=0)
                    psum_rd      (rd_num=14,rd_ch_sel=0,rd_rgb_sel=1,scache_wr_addr=0,scache_wr_size=byte,run_cycle_num=17,cfifo_en=0,bar=0)
                    psum_rd      (rd_num=14,rd_ch_sel=1,rd_rgb_sel=0,scache_wr_addr=0,scache_wr_size=byte,run_cycle_num=17,cfifo_en=0,bar=0)
                    psum_rd      (rd_num=14,rd_ch_sel=1,rd_rgb_sel=1,scache_wr_addr=0,scache_wr_size=byte,run_cycle_num=17,cfifo_en=0,bar=0)
                    VQ_NOP       (bar=0,nop_cycle_num=4)
                    VQ_scache_rd_en(addr=0,size=byte,sign_ext=1,rd_cycle_num=16,wait_type=0,cfifo_en=0,bar=0)
                );
            }
        }
    }
}
}//main end
