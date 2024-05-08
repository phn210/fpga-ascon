module circuit (
  input clk,
  input resetn,

  input [3:0]   reg_seed_we,
  input [31:0]  reg_seed_di,
  output [31:0] reg_seed_do,

  input         reg_dat_we,
  input         reg_dat_re,
  input  [31:0] reg_dat_di,
  output [31:0] reg_dat_do,
  output        reg_dat_wait
);
reg fini;
reg [31:0] seed;
reg [1:0] state;
reg [31:0] compteur;
reg [31:0] lfsr;
reg seed_modifie = 0;

assign reg_dat_wait = !fini;
assign reg_dat_do = lfsr; 
assign reg_seed_do = seed;
// wire bit_lfsr = lfsr[31] ^ lfsr[21] ^ lfsr[1] ^ lfsr[0];
wire bit_lfsr = lfsr[31] + lfsr[0];
always @(posedge clk) begin
  if (!resetn) begin
    seed <= 32'h dead_beef;
    seed_modifie <= 0;
  end else begin
    if (reg_seed_we[0]) seed[ 7: 0] <= reg_seed_di[ 7: 0];
    if (reg_seed_we[1]) seed[15: 8] <= reg_seed_di[15: 8];
    if (reg_seed_we[2]) seed[23:16] <= reg_seed_di[23:16];
    if (reg_seed_we[3]) seed[31:24] <= reg_seed_di[31:24];
    if (reg_seed_we != 4'b 0000) seed_modifie <= 1;
    else seed_modifie <= 0;
  end
end

// reg [31:0] sum;
// always @(posedge clk) begin
//   if (!resetn) begin
//     sum <= 0;
//   end else begin
//     if (reg_dat_re) begin
//       // sum <= 1 + 2;
//       sum <= reg_dat_di + reg_seed_di;
//     end
//   end
// end
// assign reg_dat_do = sum;

always @(posedge clk) begin
  if (!resetn) begin
    fini <= 0;
    state <= 0;
    compteur <= 0;
    lfsr <= seed;
  end
  case(state)
    0: begin
      if (seed_modifie) begin
        lfsr <= seed;
      end
      if (reg_dat_re) begin
        state <= 1;
        compteur <= 0;
        fini <= 0;
      end
    end 
    1: begin 
    compteur <= compteur +1;
    // lfsr <= {lfsr[30:0],bit_lfsr};
    lfsr <= lfsr + 1;
    if (compteur == 0) begin 
      state <= 2;
    end
  end
  2: begin
    fini <= 1;
    state <= 0;
  end
  default: begin
    state <= 0;
    fini <= 1;
  end
endcase
    end

endmodule