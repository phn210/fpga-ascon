GTK_ENABLED = 0
ARCH=hx8k
PACKAGE=tq144:4k
PCF=blackice-ii.pcf
PORT=ttyACM0
LDFLAGS="-L/opt/homebrew/opt/icu4c/lib"

MODE=0 # 0 = encryption, 1 = decryption, 2 = hash
VERILOG_ENC_SRC=./hdl/ascon/aead/Encryption.v \
				./hdl/ascon/aead/SocEncryption.v \
				./hdl/ascon/permutation/ConstAddLayer.v \
				./hdl/ascon/permutation/LinearLayer.v \
				./hdl/ascon/permutation/SubLayer.v \
				./hdl/ascon/permutation/Permutation.v \
				./hdl/ascon/RoundCounter.v \
				./hdl/sync_reset.v \
				./hdl/pll.v \
				./hdl/icebreaker.v \
				./hdl/simpleuart.v \
				./hdl/hex_converter.v \
				./hdl/load_firmware.v \
				./hdl/picosoc_enc.v \
				./hdl/picorv32.v
VERILOG_DEC_SRC=./hdl/ascon/aead/Decryption.v \
				./hdl/ascon/aead/SocDecryption.v \
				./hdl/ascon/permutation/ConstAddLayer.v \
				./hdl/ascon/permutation/LinearLayer.v \
				./hdl/ascon/permutation/SubLayer.v \
				./hdl/ascon/permutation/Permutation.v \
				./hdl/ascon/RoundCounter.v \
				./hdl/sync_reset.v \
				./hdl/pll.v \
				./hdl/icebreaker.v \
				./hdl/simpleuart.v \
				./hdl/hex_converter.v \
				./hdl/load_firmware.v \
				./hdl/picosoc_dec.v \
				./hdl/picorv32.v
VERILOG_HASH_SRC=./hdl/ascon/hash/Hash.v \
				./hdl/ascon/hash/SocHashing.v \
				./hdl/ascon/permutation/ConstAddLayer.v \
				./hdl/ascon/permutation/LinearLayer.v \
				./hdl/ascon/permutation/SubLayer.v \
				./hdl/ascon/permutation/Permutation.v \
				./hdl/ascon/RoundCounter.v \
				./hdl/sync_reset.v \
				./hdl/pll.v \
				./hdl/icebreaker.v \
				./hdl/simpleuart.v \
				./hdl/hex_converter.v \
				./hdl/load_firmware.v \
				./hdl/picosoc_hash.v \
				./hdl/picorv32.v
VERILOG_SRC=./hdl/ascon/aead/Encryption.v \
			./hdl/ascon/aead/SocEncryption.v \
			./hdl/ascon/aead/Decryption.v \
			./hdl/ascon/aead/SocDecryption.v \
			./hdl/ascon/hash/Hash.v \
			./hdl/ascon/hash/SocHashing.v \
			./hdl/ascon/permutation/ConstAddLayer.v \
			./hdl/ascon/permutation/LinearLayer.v \
			./hdl/ascon/permutation/SubLayer.v \
			./hdl/ascon/permutation/Permutation.v \
			./hdl/ascon/RoundCounter.v \
			./hdl/sync_reset.v \
			./hdl/pll.v \
			./hdl/icebreaker.v \
			./hdl/simpleuart.v \
			./hdl/hex_converter.v \
			./hdl/load_firmware.v \
			./hdl/picosoc.v \
			./hdl/picorv32.v

define SELECT_SRC
$(if $(filter $(1),0),$(VERILOG_ENC_SRC),\
$(if $(filter $(1),1),$(VERILOG_DEC_SRC),\
$(if $(filter $(1),2),$(VERILOG_HASH_SRC),\
$(if $(filter $(1),3),$(VERILOG_SRC)))))
endef

SELECTED_SRC := $(call SELECT_SRC,$(MODE))

all: icebreaker.bin

icebreaker.json: $(SELECTED_SRC) 
	yosys -ql icebreaker.log -p 'synth_ice40 -top icebreaker -dff -no-rw-check -json icebreaker.json -blif icebreaker.blif' $^

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

viewA:
	stty 115200 -F /dev/ttyUSB0 raw -echo; cat /dev/ttyACM0

viewB:
	stty 115200 -F /dev/ttyUSB0 raw -echo; cat /dev/ttyUSB0

clean:
	@echo "Removing all test files..."
	@rm -rf hdl/testbench/*test* hdl/testbench/*.pcd hdl/testbench/out/*output*
	@echo "Removing all build outputs..."
	@rm -f icebreaker.json icebreaker.log icebreaker.asc icebreaker.rpt icebreaker.bin icebreaker.blif

permutation:
	@echo "Running permutation test case..."
	@python3 ./python/test_permutation.py
	@cd hdl/testbench && \
	iverilog -o test_permutation -c program_files_perm.txt && \
	if [ "$(GTK_ENABLED)" = "1" ]; then \
		./test_permutation >> out/output_test_permutation.txt; \
		gtkwave test_permutation.vcd; \
	else \
		./test_permutation >> out/output_test_permutation.txt; \
	fi

aead:
	@echo "Running Ascon AEAD (encryption & decryption) test case..."
	@python3 ./python/test_aead.py
	@cd hdl/testbench && \
	iverilog -o test_aead -c program_files_aead.txt && \
	if [ "$(GTK_ENABLED)" = "1" ]; then \
		./test_aead >> out/output_test_aead.txt; \
		gtkwave test_aead.vcd; \
	else \
		./test_aead >> out/output_test_aead.txt; \
	fi

encryption:
	@echo "Running Ascon AEAD encryption test case..."
	@cd hdl/testbench && \
	iverilog -o test_enc -c program_files_enc.txt && \
	if [ "$(GTK_ENABLED)" = "1" ]; then \
		./test_enc >> out/output_test_enc.txt; \
		gtkwave test_enc.vcd; \
	else \
		./test_enc >> out/output_test_enc.txt; \
	fi

decryption:
	@echo "Running Ascon AEAD decryption test case..."
	@cd hdl/testbench && \
	iverilog -o test_dec -c program_files_dec.txt && \
	if [ "$(GTK_ENABLED)" = "1" ]; then \
		./test_dec >> out/output_test_dec.txt; \
		gtkwave test_dec.vcd; \
	else \
		./test_dec >> out/output_test_dec.txt; \
	fi

hash:
	@echo "Running Ascon hash test case..."
	@python3 ./python/test_hash.py
	@cd hdl/testbench && \
	iverilog -o test_hash -c program_files_hash.txt && \
	if [ "$(GTK_ENABLED)" = "1" ]; then \
		./test_hash >> out/output_test_hash.txt; \
		gtkwave test_hash.vcd; \
	else \
		./test_hash >> out/output_test_hash.txt; \
	fi

soc_encryption:
	@echo "Running Picosoc Ascon AEAD encryption test case..."
	@cd hdl/testbench && \
	iverilog -o test_enc_soc -c program_files_enc_soc.txt && \
	if [ "$(GTK_ENABLED)" = "1" ]; then \
		./test_enc_soc >> out/output_test_enc_soc.txt; \
		gtkwave test_enc_soc.vcd; \
	else \
		./test_enc_soc >> out/output_test_enc_soc.txt; \
	fi

soc_decryption:
	@echo "Running Picosoc Ascon AEAD decryption test case..."
	@cd hdl/testbench && \
	iverilog -o test_dec_soc -c program_files_dec_soc.txt && \
	if [ "$(GTK_ENABLED)" = "1" ]; then \
		./test_dec_soc >> out/output_test_dec_soc.txt; \
		gtkwave test_dec_soc.vcd; \
	else \
		./test_dec_soc >> out/output_test_dec_soc.txt; \
	fi

soc_hash:
	@echo "Running Picosoc Ascon hash test case..."
	@cd hdl/testbench && \
	iverilog -o test_hash_soc -c program_files_hash_soc.txt && \
	if [ "$(GTK_ENABLED)" = "1" ]; then \
		./test_hash_soc >> out/output_test_hash_soc.txt; \
		gtkwave test_hash_soc.vcd; \
	else \
		./test_hash_soc >> out/output_test_hash_soc.txt; \
	fi
	