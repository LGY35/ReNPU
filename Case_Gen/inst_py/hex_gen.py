import argparse
import os


data = []
byte_cnt = 0

def append_files_with_marker(file_list, address_list, output_file):
    """
    将多个文件拼接到一起，并在每两个文件之间加上地址分界行。
    file_list: 需要拼接的文件列表
    address_list: 用于在文件之间插入的地址分界符列表
    output_file: 拼接结果的输出文件
    """
    
    with open(output_file, 'w') as fout:
        for idx, file in enumerate(file_list):
            # 处理文件内容
            with open(file, 'r') as f:
                for line in f:
                    line = line.strip("\n")  # 去除换行符
                    fout.write(line + '\n')
            
            # 如果不是最后一个文件，插入一个地址分界符
            if idx < len(file_list) - 1:
                # 从地址列表中取出对应的地址分界符
                address_marker = address_list[idx]
                fout.write(address_marker + '\n')

def inst_proc(input_file, output_file):
    global byte_cnt, data  # 需要在函数中修改全局变量
    with open(input_file,"r") as f:
        for line in f.readlines():
            line = line.strip("\n")
            line = line.split() # line切分成了Byte为单位

            # segment
            if line[0][0] == '@':   # 每次遇到@时判断当前的byte数
                while(byte_cnt < int(line[0][1:9],16)): # 16表示16进制整数
                    if(byte_cnt%16 == 15):
                        data.append('00\n')
                        # data.append('')
                    else:
                        data.append('00 ')
                    byte_cnt = byte_cnt + 1
                if(byte_cnt > int(line[0][1:9],16)):
                    print('padding error')
            else:
                for i in line:  # i 是一个 Byte 单位
                    if(byte_cnt%16 == 15):
                        data.append(i + '\n')
                        # data.append('\n')
                    else:
                        data.append(i + ' ')
                        # data.append(' ')
                    byte_cnt = byte_cnt + 1
    # 将处理后的数据写入到输出文件
    with open(output_file, 'w') as f_out:
        f_out.writelines(data)                


def middle():
    global byte_cnt, data
    data_base_addr = 16384
    while(byte_cnt < data_base_addr):
        if(byte_cnt%16 == 15):
            data.append('00\n')
            # data.append('')
        else:
            data.append('00 ')
        byte_cnt = byte_cnt + 1


def data_proc(input_file, output_file):
    global byte_cnt, data  # 需要在函数中修改全局变量
    with open(input_file,"r") as fdata:
            for line in fdata.readlines():
                line = line.strip("\n")
                for i in range(32): # 32是一行的Bytes数
                    if(byte_cnt%16 == 15):
                        data.append(line[i*2:i*2+2] + '\n')
                        # data.append('\n')
                    else:   # 一次放2个Byte
                        data.append(line[i*2:i*2+2] + ' ')
                    byte_cnt = byte_cnt + 1
    # 将处理后的数据写入到输出文件
    with open(output_file, 'w') as f_out:
        f_out.writelines(data)       

# fout = open('hex_all.txt','+w')
# # for i in range(byte_cnt):
# #     if(i%16 == 15):
# #         fout.write(data[i])
# #         # fout.write('\n')
# #     else:
# #         fout.write(data[i])
# for i in data:
#     fout.write(i)
# fout.close()

# f.close()
# fdata.close()


def main():
    parser = argparse.ArgumentParser(description="Instruction Remake.")
    parser.add_argument('-i', '--inputs', nargs=3, required=True, help='Three input parameters (idma_inoc, instr, data)')
    parser.add_argument('-o', '--output', nargs=2, required=True, help='Two output file names')

    args = parser.parse_args()

    # 输入文件
    param1 = args.inputs[0] # idma_inoc
    param2 = args.inputs[1] # instr
    param3 = args.inputs[2] # data
    para_jmp = "./jmp.txt"
    
    files_to_merge = [param1, para_jmp, param2]  # 指令文件列表
    
    # 输出文件
    merge_inst = args.output[0]  
    hex_file   = args.output[1]  
    
    # 分界符列表
    address_list = ["@00002080", "@00002F48", "@00004000"]  #"@00004000"
    
    # 拼接文件
    append_files_with_marker(files_to_merge, address_list, merge_inst)

    
    file1 = "temp_file1.txt"  # 临时文件1
    
    inst_proc(merge_inst, file1)
    # middle(1)
    # inst_proc(param2, file2)
    middle()
    data_proc(param3, hex_file)
    os.remove(file1)


if __name__ == "__main__":
    main()