`timescale 1ns/1ns
module AEADTB;
    parameter period = 20;
    parameter max_input_len = (`k>=`y && `k>=`l)? `k: ((`y>=`l)? `y: `l);

    reg				clk = 0;
	reg 			rst;
    reg [4:0]       keyxSI;
    reg [4:0]       noncexSI;
    reg [4:0]       associated_dataxSI;
    reg [4:0]       plain_textxSI;
    reg             encryption_startxSI;
    reg             decryption_startxSI = 0;
    reg [2:0]       r_128xSI;
    reg [2:0]       r_ptxSI;
    integer         ctr = 0;
    reg [`y-1:0]    cipher_text, plain_text;
    reg [127:0]     tag, dec_tag;

    wire  cipher_textxSO, plain_textxSO;
    wire  tagxSO, dec_tagxSO;
    wire  encryption_readyxSO;
    wire  decryption_readyxSO;
    wire  message_authentication;
    integer check_time;
    integer flag = 0;

    AEAD #(
        `k,`r,`a,`b,`l,`y
    ) dut (
        clk,
        rst,
        keyxSI,
        noncexSI,
        associated_dataxSI,
        plain_textxSI,
        encryption_startxSI,
        decryption_startxSI,
        r_128xSI,
        r_ptxSI,
        cipher_textxSO,
        plain_textxSO,
        tagxSO, dec_tagxSO,
        encryption_readyxSO,
        decryption_readyxSO,
        message_authentication
    );

    // Generate clk signal
	always #(period) clk = ~clk;

    task write;
    input [max_input_len-1:0] rd, i, key, nonce, ass_data, pt; 
    begin
        @(posedge clk);
        {r_128xSI, r_ptxSI, keyxSI[4:1], associated_dataxSI[4:1], plain_textxSI[4:1], noncexSI[4:1]} = rd;
        keyxSI[0] = key[`k-1-i];
        noncexSI[0] = nonce[127-i];
        plain_textxSI[0] = pt[`y-1-i];
        associated_dataxSI[0] = ass_data[`l-1-i];
    end
    endtask

    task read;
    input integer i;
    begin
        @(posedge clk);
        cipher_text[i] = cipher_textxSO;
        tag[i] = tagxSO;
    end
    endtask

    task read_dec;
    input integer i;
    begin
        @(posedge clk);
        plain_text[i] = plain_textxSO;
        dec_tag[i] = dec_tagxSO;
    end
    endtask

    initial begin
        $dumpfile("test_aead.vcd");
        $dumpvars;
        $display("Start!");
		rst = 1;
		#(1.5*period)
        rst = 0;
        ctr = 0;
        repeat(max_input_len) begin
            write({$random, $random}, ctr, `KEY, `NONCE, `AD, `PT);
            ctr = ctr + 1;
        end
        ctr = 0;
        encryption_startxSI = 1;
        check_time = $time;
        #(0.5*period)
        $display("Key:\t%h", dut.key);
        $display("Nonce:\t%h", dut.nonce);
        $display("AD:\t%h", dut.associated_data);
        $display("PT:\t%h", dut.plain_text);
        #(5*period)
        encryption_startxSI = 0;
    end

    always @(*) begin

        if(encryption_readyxSO && flag == 0) begin
            flag = 1;
            check_time = $time - check_time;
            $display("Encryption done! It took%d clk cycles", check_time/(2*period));
            #(4*period)
            repeat(max_input_len) begin
                read(ctr);
                ctr = ctr + 1;
            end
            $display("CT:\t%h", cipher_text);
            $display("Tag:\t%h", tag);
            decryption_startxSI = 1;
            check_time = $time;
            ctr = 0;
            #(5*period)
            decryption_startxSI = 0;
        end

        if (decryption_readyxSO) begin
            check_time = $time - check_time;
            $display("Decryption done! It took%d clk cycles", check_time/(2*period));
            #(4*period)
            repeat(max_input_len) begin
                read_dec(ctr);
                ctr = ctr + 1;
            end
            $display("PT:\t%h", plain_text);
            $display("Tag:\t%h", dec_tag);
            $display("Is message authenticated:\t%b", message_authentication);
            $finish;
        end
    end
endmodule