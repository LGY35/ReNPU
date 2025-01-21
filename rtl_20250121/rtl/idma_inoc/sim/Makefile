INC_DIRS += ${DC_HOME}/dw/sim_ver

clean:
	rm -rf  *simv*  *.vpd DVEfiles csrc simv* ucli* *.log   vpd2fsdb* v* V* *fsdb* verdilog*

com:
	vcs -sverilog +v2k -timescale=1ns/1ns  -full64 -assert svaext +error+256 +lint=PCWM -notice -v2k_generate \
	-f ../tb/tb_idma_inoc_top.f                      \
	-debug_access                                 \
	-o tb_idma_inoc_top.simv                           \
	-l tb_idma_inoc_top.log                             \

sim:
	./tb_idma_inoc_top.simv -l sim.log  +nospecify +notimingcheck +fsdb+autoflush -ucli\
	-lca -cm line+tgl+cond+fsm \
	urg -dir tb_idma_inoc_top.simv.vdb/ -report both  \

ver:
	verdi  tb_idma_inoc_top.fsdb  -f ../tb/tb_idma_inoc_top.f -ssf -sv -v2k &

re: com sim
all: clean com sim

com2:
	vcs -sverilog +v2k -timescale=1ns/1ns  -full64 -assert svaext +error+256 +lint=PCWM -notice -v2k_generate \
	-f ../tb/tb_axi_to_ibuffer.f                      \
	-debug_access                                 \
	-o tb_axi_to_ibuffer.simv                           \
	-l tb_axi_to_ibuffer.log                             \

sim2:
	./tb_axi_to_ibuffer.simv -l sim.log  +nospecify +notimingcheck +fsdb+autoflush -ucli\
	-lca -cm line+tgl+cond+fsm \
	urg -dir tb_axi_to_ibuffer.simv.vdb/ -report both  \

ver2:
	verdi  tb_axi_to_ibuffer.fsdb  -f ../tb/tb_axi_to_ibuffer.f -ssf -sv -v2k &

re2: com2 sim2
all2: clean com2 sim2

com3:
	vcs -sverilog +v2k -timescale=1ns/1ns  -full64 -assert svaext +error+256 +lint=PCWM -notice -v2k_generate \
	-f ../tb/tb_fifo_sync_sram.f                      \
	-debug_access                                 \
	-o tb_fifo_sync_sram.simv                           \
	-l tb_fifo_sync_sram.log                             \

sim3:
	./tb_fifo_sync_sram.simv -l sim.log  +nospecify +notimingcheck +fsdb+autoflush -ucli\
	-lca -cm line+tgl+cond+fsm \
	urg -dir tb_fifo_sync_sram.simv.vdb/ -report both  \

ver3:
	verdi  tb_fifo_sync_sram.fsdb  -f ../tb/tb_fifo_sync_sram.f -ssf -sv -v2k &

re3: com3 sim3
all3: clean com3 sim3