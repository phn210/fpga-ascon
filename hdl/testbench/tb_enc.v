`timescale 1ns/1ns
module EncTB;
    parameter period = 20;
    parameter max_input_len = (`k>=`y && `k>=`l)? `k: ((`y>=`l)? `y: `l);

    reg             clk = 0;
    reg             rst;
    reg             keyxSI;
    reg             noncexSI;
    reg             associated_dataxSI;
    reg             plain_textxSI;
    reg             encryption_startxSI;
    integer         ctr = 0;
    reg [`y-1:0]    cipher_text;
    reg [127:0]     tag;

    wire            cipher_textxSO;
    wire            tagxSO;
    wire            encryption_readyxSO;
    integer         check_time;

    AEADEncryption #(
        `k,`r,`a,`b,`l,`y
    ) dut (
        clk,
        rst,
        keyxSI,
        noncexSI,
        associated_dataxSI,
        plain_textxSI,
        encryption_startxSI,
        cipher_textxSO,
        tagxSO, 
        encryption_readyxSO
    );

    // Generate clk signal
	always #(period) clk = ~clk;

    task write;
    input [max_input_len-1:0] i, key, nonce, ass_data, pt; 
    begin
        @(posedge clk);
        keyxSI = key[`k-1-i];
        noncexSI = nonce[127-i];
        plain_textxSI = pt[`y-1-i];
        associated_dataxSI = ass_data[`l-1-i];
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

    initial begin
        $dumpfile("test_enc.vcd");
        $dumpvars;
        $display("Start!");
		rst = 1;
		#(1.5*period)
        rst = 0;
        ctr = 0;
        repeat(max_input_len) begin
            write(ctr, `KEY, `NONCE, `AD, `PT);
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
        #(4.5*period)
        encryption_startxSI = 0;
    end

    always @(*) begin
        if(encryption_readyxSO) begin
            check_time = $time - check_time;
            $display("Encryption done! It took%d clk cycles", check_time/(2*period));
            #(4*period)
            repeat(max_input_len) begin
                read(ctr);
                ctr = ctr + 1;
            end
            $display("CT:\t%h", cipher_text);
            $display("Tag:\t%h", tag);
            $finish;
        end
    end
endmodule