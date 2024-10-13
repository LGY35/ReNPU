

INSTR_DIR = /home/lugy35/NPU/ReNPU_s12/hybrid_assembler_v3.6/src
OUT_DIR = /home/lugy35/NPU/ReNPU_s12/hybrid_assembler_v3.6/out

# 编译器路径
COMPILER_PATH := /home/lugy35/NPU/ReNPU_s12/hybrid_assembler_v3.6/hybrid_assembler_v3.8

# 源文件
INSTR := $(wildcard $(INSTR_DIR)/case*.s) 

# 将每个源文件的路径转换为目标.bc的文件路径——用于将源文件映射到输出文件，自动获得输出文件的名称
OBJECTS := $(patsubst $(INSTR_DIR)/%.s, $(OUT_DIR)/%.txt, $(INSTR))

# 参数
OUT_TYPE ?= hex # 默认输出hex

all: $(OBJECTS)	# $(OUT_DIR)/%.txt 都是OBJECTS的一员，所以这是直接运行全部的

$(OUT_DIR)/%.txt:  $(INSTR_DIR)/%.s
	mkdir -p $(OUT_DIR)
	./hybrid_assembler_v3.8 -i $< -o $@ -t $(OUT_TYPE)

clean:
	rm -rf $(OUT_DIR)
