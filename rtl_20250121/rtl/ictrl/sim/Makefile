INC_DIRS += ${DC_HOME}/dw/sim_ver

clean:
	rm -rf  *simv*  *.vpd DVEfiles csrc simv* ucli* *.log   vpd2fsdb* v* V* *fsdb* verdilog*

com:
	vcs -sverilog +v2k -timescale=1ns/1ns  -full64 -assert svaext +error+256 +lint=PCWM -notice -v2k_generate \
	-f ../tb/tb_axi_to_mem.f                                   \
	-debug_access                                 \
	-o tb_axi_to_mem.simv                                 \
	-l tb_axi_to_mem.log                             \

sim:
	./tb_axi_to_mem.simv -l sim.log  +nospecify +notimingcheck +fsdb+autoflush -ucli\
	-lca -cm line+tgl+cond+fsm \
	urg -dir tb_axi_to_mem.simv.vdb/ -report both  \

ver:
	verdi  tb_axi_to_mem.fsdb  -f ../tb/tb_axi_to_mem.f -ssf -sv -v2k &

re: com sim
all: clean com sim


com2:
	vcs -sverilog +v2k -timescale=1ns/1ns  -full64 -assert svaext +error+256 +lint=PCWM -notice -v2k_generate \
	-f ../tb/tb_axi_to_ibuffer.f                                   \
	-debug_access                                 \
	-o tb_axi_to_ibuffer.simv                                 \
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
	-f ../tb/tb_ictrl_kernel.f                                   \
	-debug_access                                 \
	-o tb_ictrl_kernel.simv                                 \
	-l tb_ictrl_kernel.log                             \

sim3:
	./tb_ictrl_kernel.simv -l sim.log  +nospecify +notimingcheck +fsdb+autoflush -ucli\
	-lca -cm line+tgl+cond+fsm \
	urg -dir tb_ictrl_kernel.simv.vdb/ -report both  \

ver3:
	verdi  tb_ictrl_kernel.fsdb  -f ../tb/tb_ictrl_kernel.f -ssf -sv -v2k &

re3: com3 sim3
all3: clean com3 sim3

com4:
	vcs -sverilog +v2k -timescale=1ns/1ns  -full64 -assert svaext +error+256 +lint=PCWM -notice -v2k_generate \
	$(addprefix +incdir+, $(INC_DIRS) ) \
	-y ${DC_HOME}/dw/sim_ver +libext+.v       \
	-f ../tb/tb_ictrl_top.f                                   \
	-debug_access                                 \
	-o tb_ictrl_top.simv                                 \
	-l tb_ictrl_top.log                             \

sim4:
	./tb_ictrl_top.simv -l sim.log  +nospecify +notimingcheck +fsdb+autoflush -ucli\
	-lca -cm line+tgl+cond+fsm \
	urg -dir tb_ictrl_top.simv.vdb/ -report both  \

ver4:
	verdi  tb_ictrl_top.fsdb  -f ../tb/tb_ictrl_top.f -ssf -sv -v2k &

re4: com4 sim4
all4: clean com4 sim4


com5:
	vcs -sverilog +v2k -timescale=1ns/1ns  -full64 -assert svaext +error+256 +lint=PCWM -notice -v2k_generate \
	-f ../tb/tb_ictrl_top_wrap.f                      \
	-debug_access                                 \
	-o tb_ictrl_top_wrap.simv                           \
	-l tb_ictrl_top_wrap.log                             \

sim5:
	./tb_ictrl_top_wrap.simv -l sim.log  +nospecify +notimingcheck +fsdb+autoflush -ucli\
	-lca -cm line+tgl+cond+fsm \
	urg -dir tb_ictrl_top_wrap.simv.vdb/ -report both  \

ver5:
	verdi  tb_ictrl_top_wrap.fsdb  -f ../tb/tb_ictrl_top_wrap.f -ssf -sv -v2k &

re5: com5 sim5
all5: clean com5 sim5