module Hashing #(
    parameter r = 64,
    parameter a = 12,
    parameter b = 12,
    parameter h = 256,
    parameter l = 256,
    parameter y = 32,
)(
    input       clk,
    input       rst,
    input [2:0] messagexSI,
    input       startxSI,
    input [6:0] r_64xSI,
    input       r_faultxSI,

    output reg  hash_textxSO,
    output      readyxSO
);

    reg     [y-1:0]     message;
    reg     [31:0]      i,j;
    wire    [l-1:0]     hash_text;
    wire                ready_1, ready, start;
    wire                permutation_ready, permutation_start;

    // Left shift for Inputs
    always @(posedge clk) begin
        if(rst)
            {message, i, j} <= 0;

        else begin
            if(i < y) begin
                message <= {message[y-2:0], messagexSI[0]};
            end

            i <= i+1;
        end

        // Right Shift for encryption outputs
        if(ready) begin
            if(j < l)
                hash_textxSO <= hash_text[j];

            j <= j + 1;
        end
    end

    assign ready_1 = ((i>y) && (i>l) && (i>64))? 1 : 0;
    assign start = ready_1 & startxSI;
    assign readyxSO = ready;

    Hash #(
        r,a,b,h,l,y
    ) d1 (
        clk,
        rst,
        message,
        start,
        ready,
        hash_text
    );
endmodule