def hex_to_little_endian(data):
    if len(data) == 4:
        num = int(data, 16)
        little_endian = num.to_bytes(2, byteorder='little')
        return little_endian.hex()
    elif len(data) == 8:
        num = int(data, 16)
        little_endian = num.to_bytes(4, byteorder='little')
        return little_endian.hex()
    else:
        return None

def process_file(input_file, output_file):
    data = []
    with open(input_file, 'r') as f_in:
        for line in f_in:
            line = line.strip()
            if len(line) <= 8:
                little_endian_data = hex_to_little_endian(line)
                if little_endian_data:
                    data.append(little_endian_data)

    with open(output_file, 'w') as f_out:
        line_count = 0
        for item in data:
            line_count += len(item) // 2
            if line_count == 16:
                f_out.write(item)
                f_out.write('\n')
                line_count = 0
            elif line_count > 16:
                f_out.write(item[0:4])
                f_out.write('\n')
                f_out.write(item[4:8])
                line_count = 2
            else:
                f_out.write(item)

# 调用函数，假设输入文件为 input.txt，输出文件为 output.txt
process_file('./case10.txt', './hex_file_little_endian.txt')

def process_file2(input_path, output_path):
    with open(input_path, 'r') as input_file:
        content = input_file.read().splitlines()  # 使用 read() 读取全部内容，再用 splitlines() 拆分，去除换行符
        new_content = []
        for line in content:
            line = line.upper()  # 将所有小写字母转换为大写
            spaced_line = ' '.join([line[i:i + 2] for i in range(0, len(line), 2)])  # 每两个字符后添加空格
            new_content.append(spaced_line)

    with open(output_path, 'w') as output_file:
        for line in new_content:
            output_file.write(line + '\n')  # 每行末尾添加换行符

input_file_path = './hex_file_little_endian.txt'  # 替换为您的输入文件路径
output_file_path = '../../DVcase/case10_relative_dmawr/case10_instr.txt'  # 替换为您的输出文件路径
process_file2(input_file_path, output_file_path)