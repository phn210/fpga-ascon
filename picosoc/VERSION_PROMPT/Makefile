CROSS=/opt/riscv/bin/riscv32-unknown-elf-
CFLAGS=

firmware.elf: 
	$(CROSS)gcc $(CFLAGS) -mabi=ilp32 -march=rv32imc -Wl,-Bstatic,-T,sections.lds,--strip-debug -ffreestanding -nostdlib -o firmware.elf start.S main.c irq.c print.c irq_functions.c uart.c

firmware_serial: firmware.elf firmware.bin
	xxd -ps -e -c 0 firmware.bin | cut -d ' ' -f 2,3,4,5 | tr -d ' ' | tr -d '\n' > firmware.txt

firmware.bin: firmware.elf
	$(CROSS)objcopy -O binary firmware.elf firmware.bin

clean:
	rm firmware.elf firmware.bin firmware.txt

prog:
	stty 115200 -F /dev/ttyUSB0 raw -echo; cat firmware.txt > /dev/ttyUSB0

viewA:
	stty 115200 -F /dev/ttyUSB0 raw -echo; cat /dev/ttyACM0

viewB:
	stty 115200 -F /dev/ttyUSB0 raw -echo; cat /dev/ttyUSB0