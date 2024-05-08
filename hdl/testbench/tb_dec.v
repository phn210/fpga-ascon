`timescale 1ns/1ns
module DecTB;
    parameter period = 20;
    parameter max_input_len = (`k>=`y && `k>=`l)? `k: ((`y>=`l)? `y: `l);

    reg             clk = 0;
    reg             rst;
    reg             keyxSI;
    reg             noncexSI;
    reg             associated_dataxSI;
    reg             cipher_textxSI;
    reg             decryption_startxSI;
    integer         ctr = 0;
    reg [`y-1:0]    plain_text;
    reg [127:0]     tag;

    wire            plain_textxSO;
    wire            tagxSO;
    wire            decryption_readyxSO;
    integer         check_time;

    AEADDecryption #(
        `k,`r,`a,`b,`l,`y
    ) dut (
        clk,
        rst,
        keyxSI,
        noncexSI,
        associated_dataxSI,
        cipher_textxSI,
        decryption_startxSI,
        plain_textxSO,
        tagxSO, 
        decryption_readyxSO
    );

    // Generate clk signal
	always #(period) clk = ~clk;

    task write;
    input [max_input_len-1:0] i, key, nonce, ass_data, ct; 
    begin
        @(posedge clk);
        keyxSI = key[`k-1-i];
        noncexSI = nonce[127-i];
        cipher_textxSI = ct[`y-1-i];
        associated_dataxSI = ass_data[`l-1-i];
    end
    endtask

    task read;
    input integer i;
    begin
        @(posedge clk);
        plain_text[i] = plain_textxSO;
        tag[i] = tagxSO;
    end
    endtask

    initial begin
        $dumpfile("test_dec.vcd");
        $dumpvars;
        $display("Start!");
		rst = 1;
		#(1.5*period)
        rst = 0;
        ctr = 0;
        repeat(max_input_len) begin
            write(ctr, `KEY, `NONCE, `AD, `CT);
            ctr = ctr + 1;
        end
        ctr = 0;
        decryption_startxSI = 1;
        check_time = $time;
        #(0.5*period)
        $display("Key:\t%h", dut.key);
        $display("Nonce:\t%h", dut.nonce);
        $display("AD:\t%h", dut.associated_data);
        $display("CT:\t%h", dut.cipher_text);
        #(4.5*period)
        decryption_startxSI = 0;
    end

    always @(*) begin
        if(decryption_readyxSO) begin
            check_time = $time - check_time;
            $display("Decryption Done! It took%d clock cycles", check_time/(2*period));
            #(4*period)
            repeat(max_input_len) begin
                read(ctr);
                ctr = ctr + 1;
            end
            $display("PT:\t%h", plain_text);
            $display("Tag:\t%h", tag);
            $finish;
        end
    end
endmodule