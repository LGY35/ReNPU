

SRC_DIR = ../hybrid_assembler/out_extract
OUT_DIR = ./out
HEX_GEN_DIR = ./hex_gen

# 源文件
SRC := $(wildcard $(SRC_DIR)/case*_extract.txt) 

# 将每个源文件的路径转换为目标.bc的文件路径——用于将源文件映射到输出文件，自动获得输出文件的名称
OBJECTS := $(patsubst $(SRC_DIR)/%_extract.txt, $(OUT_DIR)/%.txt, $(SRC))

HEX_OBJS1 := $(patsubst $(OUT_DIR)/%.txt, $(HEX_GEN_DIR)/%merge_inst.txt, $(OBJECTS))
HEX_OBJS2 := $(patsubst $(OUT_DIR)/%.txt, $(HEX_GEN_DIR)/%output_hex.txt, $(OBJECTS))
HEX_OBJS = $(HEX_OBJS1) $(HEX_OBJS2)  

all:  $(OBJECTS)  $(HEX_OBJS) 

inst_remake: $(OBJECTS) 
hex_gen: $(HEX_OBJS) 

$(OUT_DIR)/%.txt: $(SRC_DIR)/%_extract.txt
# $(OUT_DIR)/%.txt: $(SRC_DIR)/%.txt
	mkdir -p $(OUT_DIR)
	python3 inst_remake22.py -i $< -o $@

$(HEX_GEN_DIR)/%.txt: $(OUT_DIR)/%.txt
	mkdir -p $(HEX_GEN_DIR)
	python3 hex_gen.py -i $< -o $@

clean:
	rm -rf $(OUT_DIR)


	
# python3 hex_gen.py -i ./out/case5_dw_only.txt ./out/case5_dw_only_feishu.txt ../../DVcase/case9_nestloop/case9_data.txt -o ./merge_inst.txt ./output_hex.txt
# python3 hex_gen.py -i ./out/case13_twoloop_only.txt ./out/case13_twoloop.txt ../../DVcase/case9_nestloop/case9_data.txt -o ./merge_inst.txt ./output_hex.txt