VERILOG_SRC=afficheur_hexa.v sync_reset.v pll.v icebreaker.v  simpleuart.v hex_converter.v circuit.v circuit_perm.v load_firmware.v picosoc_perm.v picorv32.v ../hdl/permutation/Permutation.v ../hdl/permutation/ConstAddLayer.v ../hdl/permutation/LinearLayer.v ../hdl/permutation/SubLayer.v ../hdl/RoundCounter.v
ARCH=hx8k
PACKAGE=tq144:4k
PCF=blackice-ii.pcf
CROSS=riscv32-unknown-elf-
CFLAGS=

all: icebreaker.bin

verify:
	iverilog -o lfsr lfsr_tb.v
	./lfsr && gtkwave lfsr.vcd --script=gtkwave.tcl

icebreaker.json: $(VERILOG_SRC) 
	yosys -ql icebreaker.log -p 'synth_ice40 -top icebreaker -json icebreaker.json -blif icebreaker.blif' $^

show: icebreaker.json
	nextpnr-ice40 --gui --freq 16 --$(ARCH) --package $(PACKAGE) --pcf $(PCF) --json icebreaker.json

icebreaker.asc: icebreaker.pcf icebreaker.json
	nextpnr-ice40 --freq 16 --$(ARCH) --package $(PACKAGE) --asc icebreaker.asc --pcf $(PCF) --json icebreaker.json

icebreaker.bin: icebreaker.asc
	icetime -d $(ARCH) -c 16 -mtr icebreaker.rpt icebreaker.asc
	icepack icebreaker.asc icebreaker.bin

pll.v:
	icepll -i $(INPUT_FREQ) -o $(OUTPUT_FREQ) -m -f $@

iceprog: icebreaker.bin
	stty 115200 -F /dev/ttyACM0 raw; cat icebreaker.bin > /dev/ttyACM0

clean:
	rm -f icebreaker.json icebreaker.log icebreaker.asc icebreaker.rpt icebreaker.bin

