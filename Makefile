GTK_ENABLED = 0
ARCH=hx8k
PACKAGE=tq144:4k
PCF=blackice-ii.pcf
PORT=ttyACM0
VERILOG_SRC= Ascon.v ./hdl/permutation/Permutation.v ./hdl/permutation/ConstAddLayer.v ./hdl/permutation/LinearLayer.v ./hdl/permutation/SubLayer.v
# VERILOG_SRC=./hdl/permutation/Permutation.v ./hdl/permutation/ConstAddLayer.v ./hdl/permutation/LinearLayer.v ./hdl/permutation/SubLayer.v 
# VERILOG_SRC= permutation.v
# TOP_MODULE=Permutation

all: ascon.bin

permutation:
	@echo "Running permutation test case..."
	@python3 ./python/test_permutation.py
	@cd testbench && \
	iverilog -o test_permutation -c program_files_perm.txt && \
	if [ "$(GTK_ENABLED)" = "1" ]; then \
		./test_permutation >> output_test_permutation.txt; \
		gtkwave test_permutation.vcd; \
	else \
		./test_permutation >> output_test_permutation.txt; \
	fi

ascon.json: $(VERILOG_SRC)
	yosys -ql ascon.log -p 'synth_ice40 -top Ascon -json ascon.json -blif ascon.blif' $^

show: ascon.json ascon.pcf
	nextpnr-ice40  --freq 16 --$(ARCH) --package $(PACKAGE) --pcf $(PCF) --json ascon.json 

ascon.asc: ascon.json ascon.pcf
	nextpnr-ice40 --freq 16 --$(ARCH) --package $(PACKAGE) --asc ascon.asc --pcf $(PCF) --json ascon.json

ascon.bin: ascon.asc
	icetime -d $(ARCH) -c 16 -mtr ascon.rpt ascon.asc
	icepack ascon.asc ascon.bin

pll.v:
	icepll -i $(INPUT_FREQ) -o $(OUTPUT_FREQ) -m -f $@

prog: ascon.bin
	stty 115200 -F /dev/ttyACM0 raw; cat ascon.bin > /dev/ttyACM0
	
clean:
	@echo "Removing all test files..."
	@rm -rf testbench/*test* testbench/*.pcd testbench/*output*
	@rm -rf *.json *.asc *.bin *.rpt *.log
