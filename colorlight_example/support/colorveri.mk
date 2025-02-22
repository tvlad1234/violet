all: ${TOPMODULE}.bit

${TOPMODULE}.json : ${VERILOG_SRC}
	yosys -f "verilog -sv" -p "synth_ecp5 -top ${TOPMODULE} -json $@" ${VERILOG_SRC}

${TOPMODULE}_out.config : ${TOPMODULE}.json constraints/${TOPMODULE}.lpf
	nextpnr-ecp5 --json ${TOPMODULE}.json --textcfg $@ --25k --package CABGA256 --lpf constraints/${TOPMODULE}.lpf

${TOPMODULE}.bit : ${TOPMODULE}_out.config
	ecppack --compress --svf ${TOPMODULE}.svf $< $@  

${TOPMODULE}.svf : ${TOPMODULE}.bit

prog: ${TOPMODULE}.bit
	ecpdap prog $<

clean:
	rm -f *.svf *.bit *.config *.json *.cf *.vcd *.vvp

${SIM_TOP}.vvp : ${VERILOG_SRC} ${SIM_SRC}
	iverilog -g2012 -s ${SIM_TOP} -o ${SIM_TOP}.vvp ${VERILOG_SRC} ${SIM_SRC}

sim : ${SIM_TOP}.vvp
	vvp ${SIM_TOP}.vvp

.PHONY: sim prog clean
