GTK_ENABLED = 0
ARCH=hx8k
PACKAGE=tq144:4k
PCF=blackice-ii.pcf
PORT=ttyACM0
VERILOG_SRC=./hdl/permutation/Permutation.v ./hdl/permutation/ConstAddLayer.v ./hdl/permutation/LinearLayer.v ./hdl/permutation/SubLayer.v 
TOP_MODULE=Permutation

all: permutation.bin

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

permutation.json: $(VERILOG_SRC)
	yosys -ql permutation.log -p 'synth_ice40 -top Permutation -json permutation.json -blif permutation.blif' $^

show: permutation.json permutation.pcf 
	nextpnr-ice40  --freq 16 --$(ARCH) --package $(PACKAGE) --pcf $(PCF) --json permutation.json

permutation.asc: permutation.json
	nextpnr-ice40 --freq 16 --$(ARCH) --package $(PACKAGE) --asc permutation.asc --pcf $(PCF) --json permutation.json

permutation.bin: permutation.asc
	icetime -d $(ARCH) -c 16 -mtr permutation.rpt permutation.asc
	icepack permutation.asc permutation.bin

pll.v:
	icepll -i $(INPUT_FREQ) -o $(OUTPUT_FREQ) -m -f $@

prog: permutation.bin
	stty 115200 -F /dev/ttyACM0 raw; cat permutation.bin > /dev/ttyACM0


	
clean:
	@echo "Removing all test files..."
	@rm -rf testbench/*test* testbench/*.pcd testbench/*output*
