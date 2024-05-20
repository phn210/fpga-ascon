# Ascon Integration on FPGA PicoSoC

## Testing Verilog modules with simulation

To simulate Verilog test benches, run one of the following commands.

```
make aead
make encryption
make decryption
make hash

make soc_encryption
make soc_decryption
```

To update the parameters and inputs, modify these files

- `parameters_aead.v` for AEAD modules
- `parameters_hash.v` for hashing modules

## FPGA programs

To build FPGA programs, run:

```
# mode: 0 = encryption, 1 = decryption, 2 = hash
make MODE=<mode>
```

## Firmware

To build firmware programs, run:

```
cd firmware && make firmware_serial
```

## Debugging

Firmware can be used to debug the FPGA programs by watching serial I/O signal.

```
make viewA \\ Serial I/O from FPGA
make viewB \\ Serial I/O from RiscV
```
