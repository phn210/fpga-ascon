module circuit_perm #(
  parameter r = 12,
  parameter start = 1
) (
  input clk,
  input resetn,

  input [3:0]   reg_perm_we1,
  input [31:0]  reg_perm_di1,
  output [31:0] reg_perm_do1,

  input [3:0]   reg_perm_we2,
  input [31:0]  reg_perm_di2,
  output [31:0] reg_perm_do2,

  input [3:0]   reg_perm_we3,
  input [31:0]  reg_perm_di3,
  output [31:0] reg_perm_do3,

  input [3:0]   reg_perm_we4,
  input [31:0]  reg_perm_di4,
  output [31:0] reg_perm_do4,

  input [3:0]   reg_perm_we5,
  input [31:0]  reg_perm_di5,
  output [31:0] reg_perm_do5,

  input [3:0]   reg_perm_we6,
  input [31:0]  reg_perm_di6,
  output [31:0] reg_perm_do6,

  input [3:0]   reg_perm_we7,
  input [31:0]  reg_perm_di7,
  output [31:0] reg_perm_do7,

  input [3:0]   reg_perm_we8,
  input [31:0]  reg_perm_di8,
  output [31:0] reg_perm_do8,

  input [3:0]   reg_perm_we9,
  input [31:0]  reg_perm_di9,
  output [31:0] reg_perm_do9,

  input [3:0]   reg_perm_we10,
  input [31:0]  reg_perm_di10,
  output [31:0] reg_perm_do10,

  input         reg_dat_we,
  input         reg_dat_re,
  input  [31:0] reg_dat_di,
  output [31:0] reg_dat_do,
  output        reg_dat_wait
);
reg fini;
reg [1:0] state;
reg [1:0] state1;
reg [31:0] data_out;
reg [31:0] compteur;

reg [31:0] perm_inp1;
reg [31:0] perm_inp2;
reg [31:0] perm_inp3;
reg [31:0] perm_inp4;
reg [31:0] perm_inp5;
reg [31:0] perm_inp6;
reg [31:0] perm_inp7;
reg [31:0] perm_inp8;
reg [31:0] perm_inp9;
reg [31:0] perm_inp10;

assign reg_dat_wait = !fini;
assign reg_dat_do = data_out;

assign reg_perm_do1 = perm_inp1;
assign reg_perm_do2 = perm_inp2;
assign reg_perm_do3 = perm_inp3;
assign reg_perm_do4 = perm_inp4;
assign reg_perm_do5 = perm_inp5;
assign reg_perm_do6 = perm_inp6;
assign reg_perm_do7 = perm_inp7;
assign reg_perm_do8 = perm_inp8;
assign reg_perm_do9 = perm_inp9;
assign reg_perm_do10 = perm_inp10;

reg [319:0] S_in;
wire [319:0] S_out;
wire [4:0] ctr;
reg permutation_start;
wire permutation_ready;
reg permutation_out;
reg [4:0] rounds;


always @(posedge clk) begin
  if (!resetn) begin
    perm_inp1 <= 32'h dead_beef;
    perm_inp2 <= 32'h dead_beef;
  end else begin
    if (reg_perm_we1[0]) perm_inp1[ 7: 0] <= reg_perm_di1[ 7: 0];
    if (reg_perm_we1[1]) perm_inp1[15: 8] <= reg_perm_di1[15: 8];
    if (reg_perm_we1[2]) perm_inp1[23:16] <= reg_perm_di1[23:16];
    if (reg_perm_we1[3]) perm_inp1[31:24] <= reg_perm_di1[31:24];

    if (reg_perm_we2[0]) perm_inp2[ 7: 0] <= reg_perm_di2[ 7: 0];
    if (reg_perm_we2[1]) perm_inp2[15: 8] <= reg_perm_di2[15: 8];
    if (reg_perm_we2[2]) perm_inp2[23:16] <= reg_perm_di2[23:16];
    if (reg_perm_we2[3]) perm_inp2[31:24] <= reg_perm_di2[31:24];

    if (reg_perm_we3[0]) perm_inp3[ 7: 0] <= reg_perm_di3[ 7: 0];
    if (reg_perm_we3[1]) perm_inp3[15: 8] <= reg_perm_di3[15: 8];
    if (reg_perm_we3[2]) perm_inp3[23:16] <= reg_perm_di3[23:16];
    if (reg_perm_we3[3]) perm_inp3[31:24] <= reg_perm_di3[31:24];

    if (reg_perm_we4[0]) perm_inp4[ 7: 0] <= reg_perm_di4[ 7: 0];
    if (reg_perm_we4[1]) perm_inp4[15: 8] <= reg_perm_di4[15: 8];
    if (reg_perm_we4[2]) perm_inp4[23:16] <= reg_perm_di4[23:16];
    if (reg_perm_we4[3]) perm_inp4[31:24] <= reg_perm_di4[31:24];
    
    if (reg_perm_we5[0]) perm_inp5[ 7: 0] <= reg_perm_di5[ 7: 0];
    if (reg_perm_we5[1]) perm_inp5[15: 8] <= reg_perm_di5[15: 8];
    if (reg_perm_we5[2]) perm_inp5[23:16] <= reg_perm_di5[23:16];
    if (reg_perm_we5[3]) perm_inp5[31:24] <= reg_perm_di5[31:24];
    
    if (reg_perm_we6[0]) perm_inp6[ 7: 0] <= reg_perm_di6[ 7: 0];
    if (reg_perm_we6[1]) perm_inp6[15: 8] <= reg_perm_di6[15: 8];
    if (reg_perm_we6[2]) perm_inp6[23:16] <= reg_perm_di6[23:16];
    if (reg_perm_we6[3]) perm_inp6[31:24] <= reg_perm_di6[31:24];
    
    if (reg_perm_we7[0]) perm_inp7[ 7: 0] <= reg_perm_di7[ 7: 0];
    if (reg_perm_we7[1]) perm_inp7[15: 8] <= reg_perm_di7[15: 8];
    if (reg_perm_we7[2]) perm_inp7[23:16] <= reg_perm_di7[23:16];
    if (reg_perm_we7[3]) perm_inp7[31:24] <= reg_perm_di7[31:24];
    
    if (reg_perm_we8[0]) perm_inp8[ 7: 0] <= reg_perm_di8[ 7: 0];
    if (reg_perm_we8[1]) perm_inp8[15: 8] <= reg_perm_di8[15: 8];
    if (reg_perm_we8[2]) perm_inp8[23:16] <= reg_perm_di8[23:16];
    if (reg_perm_we8[3]) perm_inp8[31:24] <= reg_perm_di8[31:24];
    
    if (reg_perm_we9[0]) perm_inp9[ 7: 0] <= reg_perm_di9[ 7: 0];
    if (reg_perm_we9[1]) perm_inp9[15: 8] <= reg_perm_di9[15: 8];
    if (reg_perm_we9[2]) perm_inp9[23:16] <= reg_perm_di9[23:16];
    if (reg_perm_we9[3]) perm_inp9[31:24] <= reg_perm_di9[31:24];
    
    if (reg_perm_we10[0]) perm_inp10[ 7: 0] <= reg_perm_di10[ 7: 0];
    if (reg_perm_we10[1]) perm_inp10[15: 8] <= reg_perm_di10[15: 8];
    if (reg_perm_we10[2]) perm_inp10[23:16] <= reg_perm_di10[23:16];
    if (reg_perm_we10[3]) perm_inp10[31:24] <= reg_perm_di10[31:24];
  end
end

assign S_in = {perm_inp1,perm_inp2,perm_inp3,perm_inp4,perm_inp5,perm_inp6,perm_inp7,perm_inp8,perm_inp9,perm_inp10};
assign rounds = r;

//output
always @(posedge clk) begin
  if (permutation_ready) begin
    if (!resetn) begin
      fini <= 0;
      state1 <= 0;
      compteur <= 0;
      permutation_out <= 0;
      data_out <= S_in[319:288];
    end
    case(state1)
      0: begin
        if (reg_dat_re) begin
          state1 <= 1;
          fini <= 0;
        end
      end 
      1: begin
        // if (permutation_ready) begin
          compteur <= compteur + 1;
          data_out <= S_in[319 - (compteur * 32) : 288 - (compteur * 32)];
          state1 <= 0;
          fini <= 1;
          if (compteur == 9) begin
            state1 <= 2;
          end
        // end
      end
      2: begin
        fini <= 1;
        permutation_out <= 1;
        state1 <= 0;
      end
      default: begin
        state1 <= 0;
        fini <= 1;
      end
    endcase
  end
end

always @(posedge clk) begin
  if(resetn) begin
      state <= 0;
  end
  // begin
    case(state)
      // IDLE Stage
      0: begin
        permutation_start <= 1;
        state <= 1;
      end
      // Initialization
      1: begin
        if(permutation_start) begin
          // permutation_ready <= 1;
          state <= 2;
        end
      end
      // Finalization
      2: begin
        if (permutation_out) begin
          // permutation_ready <= 0;
          state <= 3;
        end
      end
      // Done Stage
      3: begin
        permutation_start <= 0;
        permutation_ready <= 0;
        state <= 0;
      end
      // Invalid state? go to idle
      default: 
        state <= 0;
    endcase
  // end
end

//Combinational Block
// always @(*) begin
//     case (state)
//         0: begin
//           permutation_start = 1;
//         end
//         1: begin
//           permutation_start = 1;
//           permutation_ready = 1;
//         end
//         2: begin
//           if (permutation_out) begin
//             permutation_ready = 0;
//           end
//         end
//         3: begin
//             permutation_start = 0;
//             permutation_ready = 0;
//             // permutation_out = 0;
//         end
//         default: begin
//             permutation_start = 0;
//             permutation_ready = 0;
//         end
//     endcase
// end

Permutation p(
  .clk(clk),
  .rst(resetn),
  .ctr(ctr),
  .S(S_in),
  .rounds(rounds),
  .start(permutation_start),
  .out(S_out),
  .done(permutation_ready)
);

RoundCounter rc(
  .clk(clk),
  .rst(resetn),
  .permutation_start(permutation_start),
  .permutation_ready(permutation_ready),
  .counter(ctr)
);

// Debugger
    // always @(posedge clk or posedge resetn) begin
    //     $display("State: %d counter: %d seed: %h", state, compteur, lfsr);
    // end
endmodule