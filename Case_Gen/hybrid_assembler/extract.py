import argparse
import os

def extract_hex_instructions(input_filename, output_filename):
    try:
        with open(input_filename, 'r') as file:
            lines = file.readlines()

        hex_instructions = []
        # finish_group_found = False
        # zero_padding_needed = False
        wfi_found = False
        addr_compute = '80002F48'
        current_addr = int(addr_compute, 16) - 4  # 因为下面检测到第一条就会加，而第一条的起始是80002F48，所以这里减去4
        # 初始化 updated_addr
        updated_addr = current_addr
        for line in lines:
            line = line.strip()
            parts = line.split()
            if parts:
                hex_instruction = parts[0]
                # Check if the instruction is finish_group
                hex_instructions.append(hex_instruction)
                # 计算数量
                # num_instructions = len(hex_instructions)
                if len(parts[0]) == 8:
                    updated_addr += 4  # 一条指令是4B
                elif len(parts[0]) == 4:
                    updated_addr += 2  # 一条指令是2B

                if wfi_found:
                    if parts[1] != 'nop':
                        wfi_found = False
                        addr_compute = f"{updated_addr:X}" # 转换为大写十六进制，不带 `0x` 前缀
                        print(f"Updated Address: {addr_compute}") 
                    else:
                        print("nop found") 
                        wfi_found = True   
                        
                if 'wfi' in line:
                    wfi_found = True
                    print("wfi found")
                    
                    # if 'next_fetch_is_npu' in line:
                    #     print("next_fetch_is_npu found")
                    #     wfi_found = False
                    #     # 将结果转换回十六进制字符串格式，并保持与初始格式一致
                    #     addr_compute = f"{updated_addr:X}"  # 转换为大写十六进制，不带 `0x` 前缀
                    #     print(f"Updated Address: {addr_compute}")  # 输出更新后的十六进制地址
                
                # 用于idma指令在finish group 之后补零指令，最初用于对齐，后面更新脚本之后不再需要
                # if 'finish_group' in line:
                #     finish_group_found = True
                #     # Check if the number of instructions is divisible by 4
                #     if num_instructions % 4 != 0:
                #         # Add a zero instruction to make it divisible by 4
                #         zero_instruction = '00000000'  # Assuming the instruction length is 8 hex digits
                #         hex_instructions.append(zero_instruction)

        # Write all instructions to the output file
        with open(output_filename, 'w') as output_file:
            for instruction in hex_instructions:
                output_file.write(instruction + '\n')

        print(f"Instructions have been extracted and written to '{output_filename}'")

    except FileNotFoundError:
        print(f"The file {input_filename} was not found.")
    except Exception as e:
        print(f"An error occurred: {e}")

def main():
    parser = argparse.ArgumentParser(description="Extract hex instructions from a file and add a zero instruction if necessary.")
    parser.add_argument('-i', '--input', required=True, help='Input file name')
    parser.add_argument('-o', '--output', required=True, help='Output file name')

    args = parser.parse_args()

    extract_hex_instructions(args.input, args.output)

if __name__ == "__main__":
    main()