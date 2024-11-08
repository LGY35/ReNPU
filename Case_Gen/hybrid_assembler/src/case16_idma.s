imm_ba(0x80006848) #base addr 0     # group 1  取激活
imm_ba(0x80008B48) #base addr 1     # group 2  取激活
imm_ba(0x80006848) #base addr 2     # group 1  取激活
imm_ba(0x80008B48) #base addr 3     # group 2  取激活
imm_ba(0x80006848) #base addr 4     # group 1  取激活
imm_ba(0x80008B48) #base addr 5     # group 2  取激活
imm_ba(0x80006848) #base addr 6     # group 1  取激活
imm_ba(0x80008B48) #base addr 7     # group 2  取激活
imm_ba(0x80004000) #base addr 8     # group 0  取权重
imm_ba(0x800042A4) #base addr 9     # group 0  取权重
imm_ba(0x80004000) #base addr 10    # group 3  取权重
imm_ba(0x800042A4) #base addr 11    # group 3  取权重
imm_wba(0x8000D080)
imm_wba(0x8000D080)
imm_wba(0x8000D080)
imm_wba(0x8000D080)
imm_wba(0x8000D080)
imm_wba(0x8000D080)
imm_wba(0x8000D080)
imm_wba(0x8000D080)
imm_wba(0x8000D080)
imm_wba(0x8000D080)
imm_wba(0x8000D080)
imm_wba(0x8000D080)
imm_gba(0x80004480)  # group 0 取激活
imm_cfg(0x80002080)  #TODO: base addr
normal_group(0x300)  # 启动节点 8 9 //0011 0000 0000
imm_gba(0x80004000)  # group 1 取权重
imm_cfg(0x80000000)  #TODO: base addr
normal_group(0x055)  # 启动节点0 2 4 6 //0000 0101 0101
imm_gba(0x800042A4)  # group 2 取权重
imm_cfg(0x80000000)  #TODO: base addr
normal_group(0x0AA)  # 启动节点1 3 5 7 //0000 1010 1010
imm_gba(0x8000AE48)  # group 3 取激活
imm_cfg(0x80000000)  #TODO: base addr
finish_group(0xC00)  # 启动节点10 11 //1100 0000 0000
