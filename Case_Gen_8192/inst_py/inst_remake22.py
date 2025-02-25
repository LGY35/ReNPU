import argparse

def hex_to_little_endian(data):
    if len(data) == 4:
        num = int(data, 16)
        return num.to_bytes(2, byteorder='little').hex()
    elif len(data) == 8:
        num = int(data, 16)
        return num.to_bytes(4, byteorder='little').hex()
    return None

def process_and_format(input_file, output_file):
    # 第一步：小端序转换
    processed_data = []
    with open(input_file, 'r') as f_in:
        for line in f_in:
            line = line.strip()
            if len(line) <= 8:
                le_data = hex_to_little_endian(line)
                if le_data:
                    processed_data.append(le_data)

    # 第二步：格式化和大写转换（直接在内存中处理）
    formatted_lines = []
    line_buffer = []
    byte_count = 0

    for item in processed_data:
        # 处理字节对齐
        byte_count += len(item) // 2  # 每个字符代表半个字节
        line_buffer.append(item.upper())  # 直接转换为大写
        
        # 每16字节换行
        if byte_count >= 16:
            full_line = ''.join(line_buffer)
            # 添加空格格式
            formatted_line = ' '.join([full_line[i:i+2] for i in range(0, len(full_line), 2)])
            formatted_lines.append(formatted_line)
            line_buffer = []
            byte_count = 0

    # 写入剩余数据
    if line_buffer:
        full_line = ''.join(line_buffer)
        formatted_line = ' '.join([full_line[i:i+2] for i in range(0, len(full_line), 2)])
        formatted_lines.append(formatted_line)

    # 写入最终文件
    with open(output_file, 'w') as f_out:
        f_out.write('\n'.join(formatted_lines))

def main():
    parser = argparse.ArgumentParser(description="Instruction Remake.")
    parser.add_argument('-i', '--input', required=True, help='Input file name')
    parser.add_argument('-o', '--output', required=True, help='Output file name')
    
    args = parser.parse_args()
    
    # 直接一步处理
    process_and_format(args.input, args.output)

if __name__ == "__main__":
    main()