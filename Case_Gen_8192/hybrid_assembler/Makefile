
INSTR_DIR = ./src
OUT_DIR = ./out
OUT_EXTRACT_DIR = ./out_extract

# 编译器路径
COMPILER_PATH := ./hybrid_assembler_v3.8

# 源文件
INSTR := $(wildcard $(INSTR_DIR)/case*.s) 

# 将每个源文件的路径转换为目标.bc的文件路径——用于将源文件映射到输出文件，自动获得输出文件的名称
OBJECTS := $(patsubst $(INSTR_DIR)/%.s, $(OUT_DIR)/%.txt, $(INSTR))

# 参数
OUT_TYPE ?= hex # 默认输出hex

$(OUT_DIR)/%.txt: $(INSTR_DIR)/%.s
	mkdir -p $(OUT_DIR)
	./hybrid_assembler_v4.6 -i $< -o $@ -t $(OUT_TYPE) -mv 2

## 第一次定义的时候，这里是从空的文件夹下面提取的，所以这里不会运行
EX_SRC := $(wildcard $(OUT_DIR)/*.out)

# 第三个参数是文件列表
OUT_EXTRACT := $(patsubst $(OUT_DIR)/%.txt, $(OUT_EXTRACT_DIR)/%_extract.txt, $(EX_SRC))

$(OUT_EXTRACT_DIR)/%_extract.txt: $(OUT_DIR)/%.txt
	mkdir -p $(OUT_EXTRACT_DIR)
	python3 extract.py -i $< -o $@


# all:  $(OBJECTS) $(OUT_EXTRACT) 
all: $(OUT_EXTRACT)

out: $(OBJECTS) 
	
# 仅生成 extract 文件，并确保在生成 $(OUT_EXTRACT) 之前，已经生成了 $(OBJECTS)
extract: $(OUT_EXTRACT)

clean:
	rm -rf $(OUT_DIR)
	rm -rf $(OUT_EXTRACT_DIR)