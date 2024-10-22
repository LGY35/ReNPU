import argparse

data = []
byte_cnt = 0

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


def append_file(param2, output_file):
    global byte_cnt, data

    # 读取 param2 文件的内容并追加到 data
    with open(param2, "r") as f2:
        for line in f2.readlines():
            line = line.strip("\n")
            line = line.split()  # 按字节拆分
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

    # 将拼接后的 data 写入到输出文件
    with open(output_file, 'w') as f_out:
        f_out.writelines(data)


def middle(n):
    global byte_cnt, data
    if n == 1:
        data_base_addr = 8320   # 2080H
    else: 
        data_base_addr = 16384
    while(byte_cnt < data_base_addr):
        if(byte_cnt%16 == 15):
            data.append('00\n')
            # data.append('')
        else:
            data.append('00 ')
        byte_cnt = byte_cnt + 1
        # print('hit')

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
    # parser.add_argument('-i', '--input', required=True, help='Input file name')
    parser.add_argument('-i', '--inputs', nargs=3, required=True, help='Two input parameters')
    parser.add_argument('-o', '--output', required=True, help='Output file name')

    args = parser.parse_args()

    param1 = args.inputs[0] # idma_inoc
    param2 = args.inputs[1] # instr
    param3 = args.inputs[2] # data

    file1 = "temp_file1.txt"  # 临时文件1
    file2 = "temp_file2.txt"  # 临时文件2

    # 第一步
    inst_proc(param1, file1)
    middle(1)
    inst_proc(param2, file2)
    middle(2)
    data_proc(param3, args.output)

if __name__ == "__main__":
    main()