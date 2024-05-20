`timescale 1ns/1ns
module DecTBPicosoc;
    parameter period = 10;
    parameter max_input_len = (`k>=`y && `k>=`l)? `k: ((`y>=`l)? `y: `l);

    reg             clk = 0;
    reg             rst;
    reg             reg_inputxSS;
    reg [31:0]      inputxSI;

    reg             reg_startxSS;
    reg             decryption_startxSI;
    wire            decryption_readyxSO;

    reg             reg_outxSS;
    wire  [7:0]     plain_tagxSO;
    
    integer         ctr = 0;
    reg [`y-1:0]    plain_text;
    reg [127:0]     tag;
    reg [7:0]       data_out;
    
    integer         check_time;

    SocDecryption #(
        `k,`r,`a,`b,`l,`y
    ) dut (
        clk,
        rst,

        reg_inputxSS,
        inputxSI,

        reg_startxSS,
        decryption_startxSI,
        decryption_readyxSO,

        reg_outxSS,
        plain_tagxSO
    );

    // Generate clk signal
	always #(period) clk = ~clk;

    task write;
    input [max_input_len-1:0] i, key, nonce, ass_data, ct; 
    begin
        @(posedge clk);
        inputxSI = {
            i*8 <= (`y-1)   ? ct[`y-1-i*8-:8]       : 8'b 0000,
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
        data_out = plain_tagxSO;
        $display("Output:\t%h", data_out);
        if (i*8 > `y) begin
            tag = {tag[119:0], data_out};
        end
        else begin
            plain_text = {plain_text[`y-9:0], data_out};
        end
    end
    endtask

    initial begin
        $dumpfile("test_dec_soc.vcd");
        $dumpvars;
        $display("Start!");
		rst = 0;
		#(1.5*period)
        rst = 1;
        ctr = 0;
        repeat(max_input_len/8) begin
            #(4*period)
            reg_inputxSS = 1;
            write(ctr, `KEY, `NONCE, `AD, `CT);
            ctr = ctr + 1;
            // #(2*period)
            reg_inputxSS = 0;
        end
        ctr = 0;
        #(0.5*period)
        $display("Key:\t%h", dut.key);
        $display("Nonce:\t%h", dut.nonce);
        $display("AD:\t%h", dut.associated_data);
        $display("CT:\t%h", dut.cipher_text);
        check_time = $time;
        reg_startxSS = 1;
        decryption_startxSI = 1;
        #(4*period)
        decryption_startxSI = 0;
        reg_startxSS = 0;
    end

    always @(*) begin
        if(decryption_readyxSO) begin
            check_time = $time - check_time;
            $display("Decryption done! It took%d clk cycles", check_time/(2*period));
            #(6*period)
            repeat(`y/8 + 17) begin
                #(10*period)
                reg_outxSS = 1;
                read(ctr);
                ctr = ctr + 1;
                reg_outxSS = 0;
            end
            $display("PT:\t%h", plain_text);
            $display("Tag:\t%h", tag);
            // $display("CT:\t%h", dut.cipher_text);
            // $display("Tag:\t%h", dut.tag);
            $finish;
        end
    end
endmodule