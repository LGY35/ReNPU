
imm_ba(0x80000000)
imm_ba(0x80000000)
imm_ba(0x80000000)
imm_ba(0x80000000)
imm_ba(0x80000000)
imm_ba(0x80000000)
imm_ba(0x80000000)
imm_ba(0x80000000)
imm_ba(0x80000000)
imm_ba(0x80000000)
imm_ba(0x80000000)
imm_ba(0x80000000)
imm_wba(0x80000000)
imm_wba(0x80000000)
imm_wba(0x80000000)
imm_wba(0x80000000)
imm_wba(0x80000000)
imm_wba(0x80000000)
imm_wba(0x80000000)
imm_wba(0x80000000)
imm_wba(0x80000000)
imm_wba(0x80000000)
imm_wba(0x80000000)
imm_wba(0x80000000)
imm_gba(0x80000000)
imm_cfg(0x80002080) # base addr
last_group(0x011)   # 启动节点04

imm_ba(0x80000000)
imm_ba(0x80000000)
imm_ba(0x80000000)
imm_ba(0x80000000)
imm_ba(0x80000000)
imm_ba(0x80000000)
imm_ba(0x80000000)
imm_ba(0x80000000)
imm_ba(0x80000000)
imm_ba(0x80000000)
imm_ba(0x80000000)
imm_ba(0x80000000)
imm_wba(0x80000000)
imm_wba(0x80000000)
imm_wba(0x80000000)
imm_wba(0x80000000)
imm_wba(0x80000000)
imm_wba(0x80000000)
imm_wba(0x80000000)
imm_wba(0x80000000)
imm_wba(0x80000000)
imm_wba(0x80000000)
imm_wba(0x80000000)
imm_wba(0x80000000)
imm_gba(0x80000000)
imm_cfg(0x8000303C) # base addr
finish_group(0x011) # 启动节点15


# 第一段 2080
# 一行就是一个10, 一行中的一个就是1
# 所以15行(包括看2F48那一行一共15行, 第16行是目标行)就是E0 , 因此2F48+E0 = 3028，3028表示的是这一行开始是，下一行就是3038开始， 然后再加4 = 303C
# 所以0到15，直接加F0即可
###