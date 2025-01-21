export DC_HOME=/tools/eda/synopsys/syn/U-2022.12-SP3
all: com

com:
	vcs -top CU_core_top \
	+define+DEBUG \
	+define+DUMP \
	+define+FSDB_ON \
	+define+FAST_COMPILE \
	-f file.f \
	-full64 \
    -debug_acc+all +v2k \
	+nospecify \
	+notimingchecks \
    -sverilog \
    -timescale=1ns/1ps \
    -l vcs.log \
    +lint=PCWM \
    +memcbk \
    +lint=TFIPC-L \
	-P ${NOVAS_HOME}/share/PLI/VCS/LINUX64/novas.tab \
	${NOVAS_HOME}/share/PLI/VCS/LINUX64/pli.a \
	+incdir+${DC_HOME}/dw/sim_ver+../include \
	-y ${DC_HOME}/dw/sim_ver +libext+.v

sim:
	./simv \
    -l sim.log  \
    -fsdb \
    +nospecify +notimingchecks +fsdb+autoflush +vcs+dumparrays

v:
	Verdi -nologo -f file.f -ssf testbench.fsdb &

v-sx:
	Verdi-SX -nologo -f file.f -ssf testbench.fsdb &

clear:
	rm -rf simv* csrc

clean:
	rm -rf  simv* *.fsdb* *.vpd DVEfiles csrc simv* ucli* *.log novas* *Verdi* vpd2fsdb* ./peline_out/*.txt

c:
	rm -rf  simv* *.fsdb* *.vpd DVEfiles csrc simv* ucli* *.log novas* *Verdi* vpd2fsdb* ./peline_out/*.txt *txt result/*txt verdiLog*

