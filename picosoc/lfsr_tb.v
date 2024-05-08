`include "circuit.v"

`timescale 1ns / 1ps

module lfsr_tb();
reg clock;
reg resetn;

// Pour le poistionnement du seed
reg [3:0] seed_we;
reg [31:0] seed_in;
wire [31:0] seed_out;

// Pour les échanges sur le bus de données
reg data_we;
reg data_re;
reg [31:0] data_in;
wire [31:0] data_out;
wire data_wait;

// Device Under Test
circuit dut(.clk(clock),.resetn(resetn),
            .reg_seed_we(seed_we), .reg_seed_di(seed_in), .reg_seed_do(seed_out),
            .reg_dat_we(data_we), .reg_dat_re(data_re), .reg_dat_di(data_in), .reg_dat_do(data_out),
            .reg_dat_wait(data_wait));


// Génération du signal d'horloge
initial begin
  clock = 1;
  forever #5 clock <= ~clock;
end

//Génération du signal de reset
initial begin
  resetn = 1;
  #5 resetn = 0;
  #5 resetn = 1;
end

initial begin
  $dumpfile("lfsr.vcd");
  $dumpvars(0, dut);
  #10 seed_we = 4'b 1111;
  seed_in = 32'h babecafe;
  #20 seed_we = 4'b 0000;
  data_re = 4'b 1111;
  #350 $finish;
end
endmodule
