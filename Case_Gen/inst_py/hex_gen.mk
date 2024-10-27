


.PHONY:  hex_gen 

OUT_DIR = ./out


# 输入
SRC_IDMA := $(wildcard $(OUT_DIR)/*_idma.txt) 
SRC_NOC := $(wildcard $(OUT_DIR)/*_noc.txt) 
SRC_DATA := ../../DVcase/case9_nestloop/case9_data.txt

# 自动提取case号
CASES := $(sort $(patsubst $(OUT_DIR)/case%_idma.txt, %, $(SRC_IDMA)))

# 输出
HEX_GEN_DIR = ./hex_gen
# HEX_OBJS1 := $(patsubst %, $(HEX_GEN_DIR)/case%_merge_inst.txt, $(CASES))
# HEX_OBJS2 := $(patsubst %, $(HEX_GEN_DIR)/case%_out_hex.txt,   $(CASES))
HEX_OBJS1 := $(patsubst $(OUT_DIR)/case%_idma.txt, $(HEX_GEN_DIR)/case%_merge_inst.txt, $(SRC_IDMA))
HEX_OBJS2 := $(patsubst $(OUT_DIR)/case%_idma.txt, $(HEX_GEN_DIR)/case%_out_hex.txt,   $(SRC_IDMA))


HEX_OBJS = $(HEX_OBJS1) $(HEX_OBJS2)  

$(HEX_GEN_DIR)/%_out_hex.txt: $(OUT_DIR)/%_idma.txt | $(OUT_DIR)/%_noc.txt | $(SRC_DATA)
	mkdir -p $(HEX_GEN_DIR)
#	python3 hex_gen.py -i $^ -o $@ $(HEX_GEN_DIR)/$*_merge_inst.txt
	python3 hex_gen.py -i $(OUT_DIR)/case$*_idma.txt $(OUT_DIR)/case$*_noc.txt $(SRC_DATA) -o $(HEX_GEN_DIR)/$*_merge_inst.txt $(HEX_GEN_DIR)/$*_out_hex.txt


clean:
	rm -f $(HEX_GEN_DIR)/*.txt
