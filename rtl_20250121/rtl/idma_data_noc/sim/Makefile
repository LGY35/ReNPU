clean:
	rm -rf  *simv*  *.vpd DVEfiles csrc simv* ucli* *.log   vpd2fsdb* v* V* *fsdb* verdilog*

com:
	vcs -sverilog +v2k -timescale=1ns/1ns  -full64 -assert svaext +error+256 +lint=PCWM -notice -v2k_generate \
	-f ../tb/tb_idma_data_noc_top.f                                   \
	-debug_access                                 \
	-o tb_idma_data_noc_top.simv                                 \
	-l tb_idma_data_noc_top.log                             \

com2:
	vcs -sverilog +v2k -timescale=1ns/1ns  -full64 -assert svaext +error+256 +lint=PCWM -notice -v2k_generate \
	-f /home/linyx/project/ReCUC/rtl/filelist/recuc_fpga.f                                   \
	-debug_access                                 \
	-o recuc.simv                                 \
	-l recuc.log                             \

sim:
	./tb_idma_data_noc_top.simv -l sim.log  +nospecify +notimingcheck +fsdb+autoflush -ucli\
	-lca -cm line+tgl+cond+fsm \
	urg -dir tb_idma_data_noc_top.simv.vdb/ -report both  \

re: com sim

ver:
	verdi  tb_idma_data_noc_top.fsdb  -f ../tb/tb_idma_data_noc_top.f -ssf -sv -v2k &
