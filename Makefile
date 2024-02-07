GTK_ENABLED = 0

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

clean:
	@echo "Removing all test files..."
	@rm -rf testbench/*test* testbench/*.pcd testbench/*output*