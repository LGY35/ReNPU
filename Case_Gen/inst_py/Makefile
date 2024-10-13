

SRC_DIR = ../hybrid_assembler/out_extract
OUT_DIR = ./out


# 源文件
SRC := $(wildcard $(SRC_DIR)/case*_extract.txt) 

# 将每个源文件的路径转换为目标.bc的文件路径——用于将源文件映射到输出文件，自动获得输出文件的名称
OBJECTS := $(patsubst $(SRC_DIR)/%_extract.txt, $(OUT_DIR)/%.txt, $(SRC))


all: $(OBJECTS) 

$(OUT_DIR)/%.txt: $(SRC_DIR)/%_extract.txt
# $(OUT_DIR)/%.txt: $(SRC_DIR)/%.txt
	mkdir -p $(OUT_DIR)
	python3 inst_remake22.py -i $< -o $@

clean:
	rm -rf $(OUT_DIR)