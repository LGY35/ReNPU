
#############################  inst_remake  #############################
SRC_DIR = ../hybrid_assembler/out_extract
OUT_DIR = ./out

# 源文件
SRC := $(wildcard $(SRC_DIR)/case*_extract.txt) 

# 将每个源文件的路径转换为目标.bc的文件路径——用于将源文件映射到输出文件，自动获得输出文件的名称
OBJECTS := $(patsubst $(SRC_DIR)/%_extract.txt, $(OUT_DIR)/%.txt, $(SRC))


all:  $(OBJECTS)  $(HEX_OBJS) 

inst_remake: $(OBJECTS) 

$(OUT_DIR)/%.txt: $(SRC_DIR)/%_extract.txt
# $(OUT_DIR)/%.txt: $(SRC_DIR)/%.txt
	mkdir -p $(OUT_DIR)
	@echo $(OBJECTS)
	python3 inst_remake22.py -i $< -o $@


############################# hex_gen #############################

# 指令示例：
# python3 hex_gen.py -i ./out/case5_idma.txt ./out/case5_dwcr_noc.txt ../../DVcase/case9_nestloop/case9_data.txt -o ./case5_merge_inst.txt ./case5_out_hex.txt
# 目的： 通过hex_gen.py 把out文件夹下的 带idma后缀的和带noc后缀的文件与SRC_DATA文件拼接在一起，并输出两个文件，一个是idma和noc拼接的指令文件，一个是指令+数据并把空行补零的文件

# 输入
SRC_IDMA := $(wildcard $(OUT_DIR)/*idma.txt) 
SRC_NOC := $(wildcard $(OUT_DIR)/*noc.txt) 
SRC_DATA := ../../DVcase/case9_nestloop/case9_data.txt

# 自动提取case号
CASES := $(sort $(patsubst $(OUT_DIR)/case%_idma.txt, %, $(SRC_IDMA)))

# 输出
HEX_GEN_DIR = ./hex_gen
# 把noc的替换为目标文件名
# 定义目标文件 (merge_inst 和 out_hex)
HEX_OBJS1 := $(patsubst %, $(HEX_GEN_DIR)/case%_merge_inst.txt, $(CASES))
HEX_OBJS2 := $(patsubst %, $(HEX_GEN_DIR)/case%_out_hex.txt,   $(CASES))

HEX_OBJS = $(HEX_OBJS1) $(HEX_OBJS2)  

#  不能加上 $(HEX_GEN_DIR)/case%_merge_inst.txt ，因为不能多个目标文件一起
$(HEX_GEN_DIR)/%.txt: $(OUT_DIR)/%_idma.txt $(OUT_DIR)/%_noc.txt $(SRC_DATA)
	mkdir -p $(HEX_GEN_DIR)
#	python3 hex_gen.py -i $^ -o $@ $(HEX_GEN_DIR)/$*_merge_inst.txt
	python3 hex_gen.py -i $(OUT_DIR)/case$*_idma.txt $(OUT_DIR)/case$*_noc.txt $(SRC_DATA) -o $(HEX_GEN_DIR)/$*_merge_inst.txt $(HEX_GEN_DIR)/$*_out_hex.txt
#	python3 hex_gen.py -i $(filter %.txt,$^) -o $(HEX_GEN_DIR)/$*_merge_inst.txt $(HEX_GEN_DIR)/$*_out_hex.txt

.PHONY: hex_gen
hex_gen: $(HEX_OBJS2)
#	@echo $(HEX_OBJS2)
#	@echo $(HEX_GEN_DIR)

clean:
	rm -f $(HEX_GEN_DIR)/*.txt
	rm -f $(OUT_DIR)/*.txt



#=====================================================================================================

# python3 hex_gen.py -i ./out/case5_idma.txt ./out/case5_dwcr_noc.txt ../../DVcase/case9_nestloop/case9_data.txt -o ./case5_merge_inst.txt ./case5_out_hex.txt
# python3 hex_gen.py -i ./out/case5_dw_only.txt ./out/case5_dw_only_feishu.txt ../../DVcase/case9_nestloop/case9_data.txt -o ./merge_inst.txt ./outut_hex.txt
# python3 hex_gen.py -i ./out/case13_twoloop_only.txt ./out/case13_twoloop.txt ../../DVcase/case9_nestloop/case9_data.txt -o ./merge_inst.txt ./outut_hex.txt



# OBJ_SRC_IDMA := $(patsubst $(OUT_DIR)/case*_idma_*.txt, $(HEX_GEN_DIR)/%case*_merge_inst.txt, $(SRC_IDMA))
# SRC_NOC		 := $(patsubst $(OUT_DIR)/case*_noc*.txt, 	$(HEX_GEN_DIR)/%case*_merge_inst.txt, $(SRC_IDMA))


# # 自动提取case号
# CASES := $(sort $(patsubst $(OUT_DIR)/case%_idma.txt, %, $(SRC_IDMA)))

# # 目标文件（根据 case 动态生成）
# define make_targets
# ./case$(1)_merge_inst.txt ./case$(1)_out_hex.txt: $(OUT_DIR)/case$(1)_idma.txt $(OUT_DIR)/case$(1)_noc.txt $(SRC_DATA)
# 	python3 hex_gen.py -i $(OUT_DIR)/case$(1)_idma.txt $(OUT_DIR)/case$(1)_noc.txt $(SRC_DATA) -o ./case$(1)_merge_inst.txt ./case$(1)_out_hex.txt
# endef

# # 对每一个自动提取的case号生成对应的规则
# $(foreach case,$(CASES),$(eval $(call make_targets,$(case))))

# .PHONY: all clean

# hex_gen: $(foreach case,$(CASES),./case$(case)_merge_inst.txt ./case$(case)_out_hex.txt)
