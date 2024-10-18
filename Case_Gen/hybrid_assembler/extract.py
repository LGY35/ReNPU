import argparse
import os

def extract_hex_instructions(input_filename, output_filename):
    try:
        with open(input_filename, 'r') as file:
            lines = file.readlines()

        hex_instructions = []
        finish_group_found = False
        zero_padding_needed = False

        for line in lines:
            line = line.strip()
            parts = line.split()
            if parts:
                hex_instruction = parts[0]
                # Check if the instruction is finish_group
                hex_instructions.append(hex_instruction)
                if 'finish_group' in line:
                    finish_group_found = True
                    num_instructions = len(hex_instructions)
                    # Check if the number of instructions is divisible by 4
                    if num_instructions % 4 != 0:
                        # Add a zero instruction to make it divisible by 4
                        zero_instruction = '00000000'  # Assuming the instruction length is 8 hex digits
                        hex_instructions.append(zero_instruction)

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