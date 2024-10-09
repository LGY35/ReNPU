def hex_to_bin(hex_str):
    decimal_num = int(hex_str, 16)
    return bin(decimal_num)[2:].zfill(4)  # 确保每个十六进制字符转换为 8 位二进制

def read_and_convert_hex_file(file_path, output_path):
    with open(file_path, 'r') as file_in:
        hex_lines = file_in.readlines()

    with open(output_path, 'w') as file_out:
        for hex_line in hex_lines:
            hex_line = hex_line.strip()
            bin_line = ''.join(hex_to_bin(hex_char) for hex_char in hex_line)
            file_out.write(bin_line + '\n')

# 替换为您的输入文件和输出文件路径
input_file = 'hex_file.txt'
output_file = 'bin_file.txt'
read_and_convert_hex_file(input_file, output_file)