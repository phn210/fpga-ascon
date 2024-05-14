/*
 *  PicoSoC - A simple example SoC using PicoRV32
 *
 *  Copyright (C) 2017  Claire Xenia Wolf <claire@yosyshq.com>
 *
 *  Permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 *  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 *  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 *  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 *  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */

`ifndef PICORV32_REGS
`ifdef PICORV32_V
`error "picosoc.v must be read before picorv32.v!"
`endif

`define PICORV32_REGS picosoc_regs
`endif

`ifndef PICOSOC_MEM
`define PICOSOC_MEM picosoc_mem
`endif

// this macro can be used to check if the verilog files in your
// design are read in the correct order.
`define PICOSOC_V

module picosoc (
	input clk,
	input resetn,

	output        iomem_valid,
	input         iomem_ready,
	output [ 3:0] iomem_wstrb,
	output [31:0] iomem_addr,
	output [31:0] iomem_wdata,
	input  [31:0] iomem_rdata,

	input  irq_5,
	input  irq_6,
	input  irq_7,

	output ser_tx,
	input  ser_rx,
    input pll_locked

);
	parameter [0:0] BARREL_SHIFTER = 1;
	parameter [0:0] ENABLE_MUL = 1;
	parameter [0:0] ENABLE_DIV = 1;
	parameter [0:0] ENABLE_FAST_MUL = 0;
	parameter [0:0] ENABLE_COMPRESSED = 1;
	parameter [0:0] ENABLE_COUNTERS = 1;
	parameter [0:0] ENABLE_IRQ_QREGS = 0;

	parameter [31:0] STACKADDR = (32'h 0000_33f0);       // end of memory
	parameter [31:0] PROGADDR_RESET = 32'h 0000_0000; // 1 MB into flash
	parameter [31:0] PROGADDR_IRQ = 32'h 0000_0010;

	reg [31:0] irq;
	wire irq_stall = 0;
	wire irq_uart = 0;

	always @* begin
		irq = 0;
		irq[3] = irq_stall;
		irq[4] = irq_uart;
		irq[5] = irq_5;
		irq[6] = irq_6;
		irq[7] = irq_7;
	end

    wire cpu_mem_valid;
	wire mem_valid_combined;
    wire load_firmware_mem_valid;

	wire cpu_mem_instr;
	wire mem_ready;
	
    wire [31:0] mem_addr_combined;
	wire [31:0] mem_addr_cpu;
	wire [31:0] load_firmware_mem_addr;

	wire [31:0] mem_wdata_combined;
	wire [31:0] mem_wdata_cpu;
	wire [31:0] load_firmware_mem_wdata;
	
    wire [3:0] mem_wstrb_cpu;
	wire [3:0] load_firmware_mem_wstrb;
	wire [3:0] mem_wstrb_combined;
	
    wire [31:0] mem_rdata;

    reg processeur_actif;

	wire spimem_ready;
	wire [31:0] spimem_rdata;

	reg ram_ready;
	wire [31:0] ram_rdata;

	reg bram_ready;
	wire [31:0] bram_rdata;

    assign mem_valid_combined = cpu_mem_valid || load_firmware_mem_valid;
    assign mem_wdata_combined = processeur_actif ? mem_wdata_cpu : load_firmware_mem_wdata;
    assign mem_addr_combined = processeur_actif ? mem_addr_cpu : load_firmware_mem_addr;
    assign mem_wstrb_combined = processeur_actif ? mem_wstrb_cpu : load_firmware_mem_wstrb;

	assign iomem_valid = mem_valid_combined && (mem_addr_combined[31:24] > 8'h 01);
	assign iomem_wstrb = mem_wstrb_combined;
	assign iomem_addr = mem_addr_combined;
	assign iomem_wdata = mem_wdata_combined;

	wire        simpleuart_reg_div_sel = mem_valid_combined && (mem_addr_combined == 32'h 0200_0004);
	wire [31:0] simpleuart_reg_div_do;

	wire        simpleuart_reg_dat_sel = mem_valid_combined && (mem_addr_combined == 32'h 0200_0008);
	wire [31:0] simpleuart_reg_dat_do;
	wire        simpleuart_reg_dat_wait;

	wire        circuit_reg_seed_sel = mem_valid_combined && (mem_addr_combined == 32'h 0200_000a);
	wire [31:0] circuit_reg_seed_do;

	wire        circuit_reg_dat_sel = mem_valid_combined && (mem_addr_combined == 32'h 0200_000c);
	wire [31:0] circuit_reg_dat_do;
	wire        circuit_reg_dat_wait;

	wire        enc_input_sel = mem_valid_combined && (mem_addr_combined == 32'h 0200_000e);
	wire		enc_cipher_textxSO;
	wire		enc_tagxSO;

	wire        enc_encryption_start_sel = mem_valid_combined && (mem_addr_combined == 32'h 0200_0010);
	wire		enc_encryption_readyxSO;

	assign mem_ready = (iomem_valid && iomem_ready) 
                        || bram_ready 
                        || simpleuart_reg_div_sel 
                        || (simpleuart_reg_dat_sel && !simpleuart_reg_dat_wait) 
                        || circuit_reg_seed_sel 
                        || (circuit_reg_dat_sel && !circuit_reg_dat_wait)
                        || enc_input_sel
                        || (enc_encryption_start_sel && !enc_encryption_readyxSO);

	assign mem_rdata = (iomem_valid && iomem_ready) ? iomem_rdata 
      : simpleuart_reg_div_sel ? simpleuart_reg_div_do 
      : simpleuart_reg_dat_sel ? simpleuart_reg_dat_do 
      : circuit_reg_dat_sel ? circuit_reg_dat_do 
      : circuit_reg_seed_sel ? circuit_reg_seed_do 
      : bram_ready ? bram_rdata : 32'h 0000_0000;

    reg [1:0]boot_sequence = 0;

    always @(posedge clk) begin
      if (!resetn) begin
        activer_load_firmware <= 0;
        boot_sequence <= 0;
        processeur_actif <= 0;
      end
      case(boot_sequence)
        0:
        begin
          processeur_actif <= 0;
          boot_sequence <= 1;
        end
        1: begin
          processeur_actif <= 0;
          activer_load_firmware <= 1;
          if (load_firmware_fini)
            boot_sequence <= 2;
        end
        2:
          processeur_actif <= 1;
        default:
          boot_sequence <= 0;
      endcase
    end

	picorv32 #(
		.STACKADDR(STACKADDR),
		.PROGADDR_RESET(PROGADDR_RESET),
		.PROGADDR_IRQ(PROGADDR_IRQ),
		.BARREL_SHIFTER(BARREL_SHIFTER),
		.COMPRESSED_ISA(ENABLE_COMPRESSED),
		.ENABLE_COUNTERS(ENABLE_COUNTERS),
		.ENABLE_MUL(ENABLE_MUL),
		.ENABLE_DIV(ENABLE_DIV),
		.ENABLE_IRQ(1),
        .ENABLE_IRQ_TIMER(1),
		.ENABLE_IRQ_QREGS(ENABLE_IRQ_QREGS)
	) cpu (
		.clk         (clk        ),
		.resetn      (processeur_actif     ),
		.mem_valid   (cpu_mem_valid  ),
		.mem_instr   (cpu_mem_instr  ),
		.mem_ready   (mem_ready  ),
		.mem_addr    (mem_addr_cpu   ),
		.mem_wdata   (mem_wdata_cpu  ),
		.mem_wstrb   (mem_wstrb_cpu  ),
		.mem_rdata   (mem_rdata  ),
		.irq         (irq        )
	);

    reg activer_load_firmware;
    wire [31:0]load_firmware_addr;
    wire [31:0]load_firmware_wdata;
    wire [3:0]load_firmware_wen;
    wire load_firmware_fini;

    load_firmware load (
      .clk          (clk          ),
      .resetn       (activer_load_firmware),
      .mem_valid    (load_firmware_mem_valid),
      .mem_ready    (mem_ready),
      .mem_addr     (load_firmware_mem_addr),
      .mem_wdata    (load_firmware_mem_wdata),
      .mem_wstrb    (load_firmware_mem_wstrb),
      .mem_rdata    (mem_rdata),
      .fini         (load_firmware_fini)

    );

	simpleuart simpleuart (
		.clk         (clk         ),
		.resetn      (resetn      ),

		.ser_tx      (ser_tx      ),
		.ser_rx      (ser_rx      ),

		.reg_div_we  (simpleuart_reg_div_sel ? mem_wstrb_combined : 4'b 0000),
		.reg_div_di  (mem_wdata_combined),
		.reg_div_do  (simpleuart_reg_div_do),

		.reg_dat_we  (simpleuart_reg_dat_sel ? mem_wstrb_combined[0] : 1'b 0),
		.reg_dat_re  (simpleuart_reg_dat_sel && !mem_wstrb_combined),
		.reg_dat_di  (mem_wdata_combined),
		.reg_dat_do  (simpleuart_reg_dat_do),
		.reg_dat_wait(simpleuart_reg_dat_wait)
	);

	circuit circuit (
		.clk         (clk         ),
		.resetn      (resetn      ),

        .reg_seed_we (circuit_reg_seed_sel ? mem_wstrb_combined : 4'b 0000),
        .reg_seed_di (mem_wdata_combined),
        .reg_seed_do (circuit_reg_seed_do),

		.reg_dat_we  (circuit_reg_dat_sel ? mem_wstrb_combined[0] : 1'b 0),
		.reg_dat_re  (circuit_reg_dat_sel && !mem_wstrb_combined),
		.reg_dat_di  (mem_wdata_combined),
		.reg_dat_do  (circuit_reg_dat_do),
		.reg_dat_wait(circuit_reg_dat_wait)
	);

	AsconEncryption enc (
		.clk					(clk),
		.rst					(rst),
		
		.reg_input_we			(circuit_reg_seed_sel ? mem_wstrb_combined : 4'b 0000),
		.keyxSI					(mem_wdata_combined[0]),
		.noncexSI				(mem_wdata_combined[0]),
		.associated_dataxSI		(mem_wdata_combined[0]),
		.plain_textxSI			(mem_wdata_combined[0])
	)

	always @(posedge clk)
		bram_ready <= mem_valid_combined && !mem_ready && (mem_addr_combined >= 32'h 0x0000_0000) && (mem_addr_combined < 32'h 0000_3400);

    picosoc_mem_ram #( 
        .WORDS(3328)
      ) bram_only (
        .clk(clk),
        .wen(bram_ready ? mem_wstrb_combined : 4'b0),
        .addr(mem_addr_combined[23:2]),
        .wdata(mem_wdata_combined),
        .rdata(bram_rdata)
    );

endmodule


module picosoc_regs (
	input clk, wen,
	input [5:0] waddr,
	input [5:0] raddr1,
	input [5:0] raddr2,
	input [31:0] wdata,
	output [31:0] rdata1,
	output [31:0] rdata2
);
	reg [31:0] regs [0:31];

	always @(posedge clk)
		if (wen) regs[waddr[4:0]] <= wdata;

	assign rdata1 = regs[raddr1[4:0]];
	assign rdata2 = regs[raddr2[4:0]];
endmodule

module picosoc_mem #(
	parameter integer WORDS = 256
) (
	input clk,
	input [3:0] wen,
	input [21:0] addr,
	input [31:0] wdata,
	output reg [31:0] rdata
);
	reg [31:0] mem [0:WORDS-1];

	always @(posedge clk) begin
		rdata <= mem[addr];
		if (wen[0]) mem[addr][ 7: 0] <= wdata[ 7: 0];
		if (wen[1]) mem[addr][15: 8] <= wdata[15: 8];
		if (wen[2]) mem[addr][23:16] <= wdata[23:16];
		if (wen[3]) mem[addr][31:24] <= wdata[31:24];
	end
endmodule

module picosoc_mem_ram #(
	parameter integer WORDS = 3072
) (
	input clk,
	input [3:0] wen,
	input [21:0] addr,
	input [31:0] wdata,
	output reg [31:0] rdata
);
	reg [31:0] mem [0:WORDS-1];
	always @(posedge clk) begin
		rdata <= mem[addr[11:0]];
		if (wen[0]) mem[addr[11:0]][ 7: 0] <= wdata[ 7: 0];
		if (wen[1]) mem[addr[11:0]][15: 8] <= wdata[15: 8];
		if (wen[2]) mem[addr[11:0]][23:16] <= wdata[23:16];
		if (wen[3]) mem[addr[11:0]][31:24] <= wdata[31:24];
	end
endmodule
