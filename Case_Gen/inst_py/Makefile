# 变量赋值，文件构建命令，系统命令 
#############################  变量定义  #############################
SRC_DIR = ../hybrid_assembler/out_extract
OUT_DIR = ./out
HEX_GEN_DIR = ./hex_gen

############################# 文件构建  #############################

SRC := $(wildcard $(SRC_DIR)/case*_extract.txt) 
OBJECTS := $(patsubst $(SRC_DIR)/%_extract.txt, $(OUT_DIR)/%.txt, $(SRC))

###### inst_remake规则 
$(OUT_DIR)/%.txt: $(SRC_DIR)/%_extract.txt
	mkdir -p $(OUT_DIR)
#	@echo $(OBJECTS)
	python3 inst_remake22.py -i $< -o $@

SRC_IDMA := $(wildcard $(OUT_DIR)/*_idma.txt) 
SRC_NOC := $(wildcard $(OUT_DIR)/*_noc.txt) 
SRC_DATA := ../../DVcase/case9_nestloop/case9_data.txt

# 提取case号
CASES := $(sort $(patsubst $(OUT_DIR)/case%_idma.txt, %, $(SRC_IDMA)))

HEX_OBJS1 := $(patsubst %, $(HEX_GEN_DIR)/case%_merge_inst.txt, $(CASES))
HEX_OBJS2 := $(patsubst %, $(HEX_GEN_DIR)/case%_out_hex.txt,   $(CASES))
# HEX_OBJS1 := $(patsubst $(OUT_DIR)/case%_idma.txt, $(HEX_GEN_DIR)/case%_merge_inst.txt, $(SRC_IDMA))
# HEX_OBJS2 := $(patsubst $(OUT_DIR)/case%_idma.txt, $(HEX_GEN_DIR)/case%_out_hex.txt,   $(SRC_IDMA))
HEX_OBJS :=  $(HEX_OBJS2)   $(HEX_OBJS1)

############################# 构建命令 #############################
# %必须相同才能匹配上
# $(HEX_GEN_DIR)/%_out_hex.txt: $(OUT_DIR)/%_idma.txt | $(OUT_DIR)/%_noc.txt | $(SRC_DATA)
$(HEX_GEN_DIR)/%_out_hex.txt: $(OUT_DIR)/%_idma.txt | $(OUT_DIR)/case%*_noc.txt | $(SRC_DATA)
# $(HEX_OBJS2): $(SRC_IDMA)  $(SRC_NOC)  $(SRC_DATA)
	mkdir -p $(HEX_GEN_DIR)
	python3 hex_gen.py -i $^ -o $@ $(HEX_GEN_DIR)/$*_merge_inst.txt
#	python3 hex_gen.py -i $(OUT_DIR)/case$*_idma.txt $(OUT_DIR)/case$*_noc.txt $(SRC_DATA) -o $(HEX_GEN_DIR)/$*_merge_inst.txt $(HEX_GEN_DIR)/$*_out_hex.txt

############################# PHONY目标 #############################
.PHONY: all  inst_remake hex_gen clean

all:  $(OBJECTS)  $(HEX_OBJS)

inst_remake: $(OBJECTS)

# hex_gen: $(HEX_OBJS2)

hex_gen:
	mkdir -p $(HEX_GEN_DIR)
	python3 hex_gen.py -i ./out/case3_idma.txt  ./out/case3_core_rd_noc.txt          ./input_data0.txt 						    -o ./hex_gen/case3_merge_inst.txt  ./hex_gen/case3_out_hex.txt
	python3 hex_gen.py -i ./out/case5_idma.txt  ./out/case5_dwcr_noc.txt             ./input_data0.txt							-o ./hex_gen/case5_merge_inst.txt  ./hex_gen/case5_out_hex.txt
	python3 hex_gen.py -i ./out/case8_idma.txt  ./out/case8_mc_dmawr_noc.txt         ../../DVcase/case9_nestloop/case9_data.txt -o ./hex_gen/case8_merge_inst.txt  ./hex_gen/case8_out_hex.txt
	python3 hex_gen.py -i ./out/case9_idma.txt  ./out/case9_nestloop_dmawr_noc.txt   ../../DVcase/case9_nestloop/case9_data.txt -o ./hex_gen/case9_merge_inst.txt  ./hex_gen/case9_out_hex.txt
	python3 hex_gen.py -i ./out/case10_idma.txt ./out/case10_relative_dmawr_noc.txt  ../../DVcase/case9_nestloop/case9_data.txt -o ./hex_gen/case10_merge_inst.txt ./hex_gen/case10_out_hex.txt
	python3 hex_gen.py -i ./out/case11_idma.txt ./out/case11_multi_filter_noc.txt    ../../DVcase/case9_nestloop/case9_data.txt -o ./hex_gen/case11_merge_inst.txt ./hex_gen/case11_out_hex.txt
	python3 hex_gen.py -i ./out/case12_idma.txt ./out/case12_dmawrrd_noc.txt         ../../DVcase/case9_nestloop/case9_data.txt -o ./hex_gen/case12_merge_inst.txt ./hex_gen/case12_out_hex.txt
	python3 hex_gen.py -i ./out/case13_idma.txt ./out/case13_twoloop_noc.txt         ../../DVcase/case9_nestloop/case9_data.txt -o ./hex_gen/case13_merge_inst.txt ./hex_gen/case13_out_hex.txt
	python3 hex_gen.py -i ./out/case14_idma.txt ./out/case14_feishu.txt         	 ./input_data0.txt 							-o ./hex_gen/case14_merge_inst.txt ./hex_gen/case14_out_hex.txt
	python3 hex_gen.py -i ./out/case15_idma.txt ./out/case15_core_rd_node_noc.txt    ./input_data0.txt 							-o ./hex_gen/case15_merge_inst.txt ./hex_gen/case15_out_hex.txt
	python3 hex_gen.py -i ./out/case16_idma.txt ./out/case16_yolo_1_noc.txt    		 ./input_data0.txt 							-o ./hex_gen/case16_merge_inst.txt ./hex_gen/case16_out_hex.txt
	python3 hex_gen.py -i ./out/case17_idma.txt ./out/case17_dma_node_jump_noc.txt   ./input_data0.txt 							-o ./hex_gen/case17_merge_inst.txt ./hex_gen/case17_out_hex.txt
	python3 hex_gen.py -i ./out/case18_idma.txt ./out/case18_cr_dma_node_jump_noc.txt ./input_data0.txt 						-o ./hex_gen/case18_merge_inst.txt ./hex_gen/case18_out_hex.txt
	python3 hex_gen.py -i ./out/case19_idma.txt ./out/case19_core_wr_noc.txt    	 ./input_data0.txt 							-o ./hex_gen/case19_merge_inst.txt ./hex_gen/case19_out_hex.txt
	python3 hex_gen.py -i ./out/case99_idma.txt ./out/case99_noc.txt    		 	 ./input_data0.txt 							-o ./hex_gen/case99_merge_inst.txt ./hex_gen/case99_out_hex.txt
	python3 hex_gen.py -i ./out/case991_idma.txt ./out/case991_conv_bottleneck_noccore_4.1_ins_noc.txt    		 	 ./input_data0.txt 							-o ./hex_gen/case991_merge_inst.txt ./hex_gen/case991_out_hex.txt
	python3 hex_gen.py -i ./out/case992_idma.txt ./out/case992_bottleneck_noccore_12cores_4.1_ins_noc.txt    		 ./bottleneck_combined_input_data.txt 		-o ./hex_gen/case992_merge_inst.txt ./hex_gen/case992_out_hex.txt
	python3 hex_gen.py -i ./out/case993_idma.txt ./out/case993_bottleneck_noccore_1cores_4.1_ins_noc.txt    		 ./bottleneck_combined_input_data_1core.txt -o ./hex_gen/case993_merge_inst.txt ./hex_gen/case993_out_hex.txt

clean:
	rm -rf $(HEX_GEN_DIR)
	rm -rf $(OUT_DIR)

#=====================================================================================================


# 指令示例：
# python3 hex_gen.py -i ./out/case5_idma.txt ./out/case5_dwcr_noc.txt ../../DVcase/case9_nestloop/case9_data.txt -o ./case5_merge_inst.txt ./case5_out_hex.txt
# 目的： 通过hex_gen.py 把out文件夹下的 带idma后缀的和带noc后缀的文件与SRC_DATA文件拼接在一起，并输出两个文件，一个是idma和noc拼接的指令文件，一个是指令+数据并把空行补零的文件

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
