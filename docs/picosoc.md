# PicoSoc Instruction Set

PicoSoc is a simple SoC that can run on an iCE40 FPGA. It is based on the PicoRV32 RISC-V core and includes a UART, SPI, and GPIOs. The PicoSoc is designed to be used with the [icestorm](http://www.clifford.at/icestorm/) toolchain.

In PicoSoc, there this BlackIce board, there are two input UARTs, ttyACM0 and ttyUSB0. ttyACM0 is used for uploading the hardware instructions to the FPGA, and ttyUSB0 is used for uploading and monitoring the firmware instructions.

## Instruction for working with PicoSoc

Side note: I'm currently working with the Permutation module only, so the affected files are marked with the '_perm' suffix (picosoc_perm.v and circuit_perm.v). If you want test your own module, copy it to a new file and add their name into the Makefile.

### Uploading the hardware instructions to the FPGA

1. Connect the BlackIce board to your computer using a USB cable, remmer to check the ttyACM0 port.

2. To clean the temporary files, run the following command:

```bash
sudo make clean
```

3. To compile the hardware instructions:

```bash
sudo make all
```

4. To upload the hardware instructions to the FPGA:

```bash
sudo make iceprog
```

### Uploading and monitoring the firmware instructions

After uploading the hardware instructions to the FPGA, you can upload and monitor the firmware instructions.

Open a new separate terminal in order the monitor the firmware instructions.
```bash
sudo make viewB
```

1. Connect the BlackIce board to your computer using a USB cable, remmer to check the ttyUSB0 port.

2. Go to the 'picosoc/VERSION_PROMPT' directory.

The firmware instructions are written in C, and start with the 'main.c' file. You can modify the 'main.c' file to change the firmware instructions.

3. Compile the firmware instructions will generate a 'firmware.txt' file, we will use this file to upload the firmware instructions to the FPGA. To compile:

```bash
sudo make firmware_serial
```

4. To upload the firmware instructions to the FPGA:

```bash
sudo make prog
```

Note: To compiple the firmware codes, you need to have the 'riscv32-unknown-elf-gcc' installed on your computer. For more information, see the [RISC-V toolchain](https://github.com/YosysHQ/picorv32/tree/master) repository.