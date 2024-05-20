module SocHashing #(
    parameter r = 64,
    parameter a = 12,
    parameter b = 12,
    parameter h = 256,
    parameter l = 256,
    parameter y = 512
)(
    input           clk,
    input           rst,

    input           reg_inputxSS,
    input   [7:0]   messagexSI,

    input           reg_startxSS,
    input           hash_startxSI,
    output          hash_readyxSO,

    input           reg_outxSS,
    output  [7:0]   hash_digestxSO
);
    
    reg     [y-1:0]     message;
    reg     [15:0]      i,j;
    wire    [l-1:0]     hash_digest;
    wire                ready, hash_ready, start;
    wire                permutation_ready, permutation_start;
    reg     [7:0]       data_out;

    assign ready = i > (y-1) ? 1 : 0;
    assign start = ready && reg_startxSS && hash_startxSI;
    assign hash_readyxSO = hash_ready;
    assign hash_digestxSO = data_out;
    

    // Write inputs
    always @(posedge clk) begin
        if(!rst)
            {message, i, j, data_out} <= 0;

        else if (reg_inputxSS) begin
            if(i < y) begin
                message <= {message[y-9:0], messagexSI};
            end

            if (!ready) i <= i+8;
        end

        else if(hash_ready && reg_outxSS) begin
            if (j < l) begin
                j <= j + 8;
                data_out <= hash_digest[l-1-j-:8];
            end
            else begin
                j <= 0;
            end
        end
    end
    
    Hash #(
        r,a,b,h,l,y
    ) d1 (
        clk,
        rst,
        message,
        start,
        hash_ready,
        hash_digest
    );
    
endmodule