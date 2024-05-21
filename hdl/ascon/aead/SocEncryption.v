module SocEncryption #(
    parameter k = 128,            // Key size
    parameter r = 64,            // Rate
    parameter a = 12,             // Initialization round no.
    parameter b = 6,              // Intermediate round no.
    parameter l = 16,            // Length of associated data
    parameter y = 16             // Length of Plain Text
)(
    input           clk,
    input           rst,

    input           reg_inputxSS,
    input   [31:0]  inputxSI,

    input           reg_startxSS,
    input           encryption_startxSI,
    output          encryption_readyxSO,

    input           reg_outxSS,
    output  [7:0]   cipher_tagxSO
);
    
    reg     [k-1:0]     key;      
    reg     [127:0]     nonce;
    reg     [l-1:0]     associated_data; 
    reg     [y-1:0]     plain_text;
    reg     [7:0]       i, o;
    wire    [y-1:0]     cipher_text;
    wire    [127:0]     tag;
    wire                ready, encryption_start, encryption_ready;
    reg     [7:0]       data_out;

    assign ready = ((i>=k) && (i>=128) && (i>=l) && (i>=y)) ? 1 : 0;
    assign encryption_start = ready && reg_startxSS && encryption_startxSI;
    assign encryption_readyxSO = encryption_ready;
    assign cipher_tagxSO = data_out;
    

    // Write inputs
    always @(posedge clk) begin
        if(!rst)
            {key, nonce, associated_data, plain_text, i, o, data_out} <= 0;

        else if (reg_inputxSS) begin

            if(i < k) begin
                key <= {key[k-9:0], inputxSI[7:0]}; 
            end

            if(i < 128) begin
                nonce <= {nonce[119:0], inputxSI[15:8]};
            end

            if(i < l) begin
                associated_data <= {associated_data[l-9:0], inputxSI[23:16]};
            end

            if(i < y) begin
                plain_text <= {plain_text[y-9:0], inputxSI[31:24]};
            end

            if (!ready) i <= i+8;
        end

        else if(encryption_ready && reg_outxSS) begin
            if (o < y) begin
                o <= o + 8;
                data_out <= cipher_text[y-1-o-:8];
            end
            else if (o < y + 128) begin
                o <= o + 8;
                data_out <= tag[127-(o-y)-:8];
            end
            else begin
                o <= 0;
            end
        end
    end
    
    Encryption #(
        k,r,a,b,l,y
    ) d1 (
        clk,
        rst,
        key, 
        nonce, 
        associated_data,
        plain_text,
        encryption_start,
        cipher_text,
        tag,          
        encryption_ready
    );
    
endmodule