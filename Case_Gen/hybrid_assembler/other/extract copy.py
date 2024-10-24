import argparse

def extract_hex_instructions(input_filename, output_filename):
    try:
        # 尝试打开输入文件读取数据
        with open(input_filename, 'r') as file:
            data = file.readlines()

        # 提取十六进制指令
        hex_instructions = []
        for line in data:
            parts = line.split()
            if parts:  # 确保行不为空
                hex_instruction = parts[0]
                hex_instructions.append(hex_instruction)

        # 将提取的指令写入文件
        with open(output_filename, 'w') as output_file:
            for instruction in hex_instructions:
                output_file.write(instruction + '\n')

        print(f"Instructions have been extracted and written to '{output_filename}'")

    except FileNotFoundError:
        print(f"The file {input_filename} was not found.")
    except Exception as e:
        print(f"An error occurred: {e}")

def main():
    parser = argparse.ArgumentParser(description="Extract hex instructions from a file.")
    parser.add_argument('-i', '--input', required=True, help='Input file name')
    parser.add_argument('-o', '--output', required=True, help='Output file name')

    args = parser.parse_args()

    extract_hex_instructions(args.input, args.output)

if __name__ == "__main__":
    main()