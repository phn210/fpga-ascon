module segments (input wire [3:0] value, output reg [6:0] status);
always @(*) begin
    case (value)
            4'h 0: status = 7'b 1000000;
            4'h 1: status = 7'b 1111001;
            4'h 2: status = 7'b 0100100;
            4'h 3: status = 7'b 0110000;
            4'h 4: status = 7'b 0011001;
            4'h 5: status = 7'b 0010010;
            4'h 6: status = 7'b 0000010;
            4'h 7: status = 7'b 1111000;
            4'h 8: status = 7'b 0000000;
            4'h 9: status = 7'b 0010000;
            4'h A: status = 7'b 0001000;
            4'h B: status = 7'b 0000011;
            4'h C: status = 7'b 1000110;
            4'h D: status = 7'b 0100001;
            4'h E: status = 7'b 0000110;
            4'h F: status = 7'b 0001110;
            default: status = 7'b 1111111;
    endcase
  end
endmodule

module afficheur_hexa (
  input clk,
  input resetn,
  input [7:0] value,
  output [7:0] pmod
);
reg selection;
assign pmod[7] = selection;
wire [3:0] valeur_segment = selection?value[3:0]:value[7:4];
segments s (.value(valeur_segment), .status(pmod[6:0]));
reg [17:0]compteur;

  always @(posedge clk) begin
    if (!resetn) begin
      selection <= 0;
      compteur <= 0;
    end
    else begin
      compteur <= compteur + 1;
      if (compteur[17]) begin
        compteur <= 0;
        selection <= ~selection;
      end
    end
end
  endmodule

