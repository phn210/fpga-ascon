`timescale 1ns/1ns
module EncTBPicosoc;
    parameter period = 20;
    parameter max_input_len = (`k>=`y && `k>=`l)? `k: ((`y>=`l)? `y: `l);

    reg             clk = 0;
    reg             rst;
    reg [3:0]       reg_inputxSS;
    reg [31:0]      inputxSI;

    reg             reg_startxSS;
    reg             encryption_startxSI;
    wire            encryption_readyxSO;

    reg             reg_outxSS;
    wire  [7:0]     cipher_tagxSO;
    wire            output_readyxS0;
    wire            reg_data_waitxS0;
    
    integer         ctr = 0;
    reg [`y-1:0]    cipher_text;
    reg [127:0]     tag;
    reg [7:0]       data_out;
    
    integer         check_time;

    SocEncryption #(
        `k,`r,`a,`b,`l,`y
    ) dut (
        clk,
        rst,

        reg_inputxSS,
        inputxSI,

        reg_startxSS,
        encryption_startxSI,
        encryption_readyxSO,

        reg_outxSS,
        cipher_tagxSO
    );

    // Generate clk signal
	always #(period) clk = ~clk;

    task write;
    input [max_input_len-1:0] i, key, nonce, ass_data, pt; 
    begin
        @(posedge clk);
        inputxSI = {
            i*8 <= (`y-1)   ? pt[`y-1-i*8-:8]       : 8'b 0000,
            i*8 <= (`l-1)   ? ass_data[`l-1-i*8-:8] : 8'b 0000,
            i*8 <= (127)    ? nonce[127-i*8-:8]     : 8'b 0000,
            i*8 <= (`k-1)   ? key[`k-1-i*8-:8]      : 8'b 0000
        };
        $display("Input:\t%h", inputxSI);
    end
    endtask

    task read;
    input integer i;
    begin
        @(posedge clk);
        data_out = cipher_tagxSO;
        $display("Output:\t%h", data_out);
        if (i*8 > `y-1) begin
            tag = {tag[119:0], data_out};
        end
        else begin
            cipher_text = {cipher_text[`y-9:0], data_out};
        end
    end
    endtask

    initial begin
        $dumpfile("test_enc.vcd");
        $dumpvars;
        $display("Start!");
		rst = 0;
		#(1.5*period)
        rst = 1;
        ctr = 0;
        repeat(max_input_len/8) begin
            #period
            reg_inputxSS = 4'b 1111;
            write(ctr, `KEY, `NONCE, `AD, `PT);
            ctr = ctr + 1;
            reg_inputxSS = 4'b 0000;
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
        reg_startxSS = 1;
        encryption_startxSI = 1;
        #(4*period)
        reg_startxSS = 0;
        encryption_startxSI = 0;
    end

    always @(*) begin
        if(encryption_readyxSO) begin
            check_time = $time - check_time;
            $display("Encryption done! It took%d clk cycles", check_time/(2*period));
            reg_outxSS = 1;
            #(6*period)
            reg_outxSS = 0;
            repeat(`y/8 + 17) begin
                read(ctr);
                ctr = ctr + 1;
            end
            $display("CT:\t%h", cipher_text);
            $display("Tag:\t%h", tag);
            // $display("CT:\t%h", dut.cipher_text);
            // $display("Tag:\t%h", dut.tag);
            $finish;
        end
    end
endmodule