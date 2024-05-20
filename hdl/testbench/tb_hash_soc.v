`timescale 1ns/1ns
module HashTBPicosoc;
    parameter period = 10;
    parameter max_input_len = (`h>=`y && `h>=`l)? `h: ((`y>=`l)? `y: `l);

    reg             clk = 0;
    reg             rst;
    reg             reg_inputxSS;
    reg  [7:0]      messagexSI;

    reg             reg_startxSS;
    reg             hash_startxSI;
    wire            hash_readyxSO;

    reg             reg_outxSS;
    wire  [7:0]     hash_digestxSO;
    
    integer         ctr = 0;
    reg [`l-1:0]    hash_digest;
    reg [7:0]       data_out;
    
    integer         check_time;

    SocHashing #(
        `r,`a,`b,`h,`l,`y
    ) dut (
        clk,
        rst,

        reg_inputxSS,
        messagexSI,

        reg_startxSS,
        decryption_startxSI,
        decryption_readyxSO,

        reg_outxSS,
        hash_digestxSO
    );

    // Generate clk signal
	always #(period) clk = ~clk;

    task write;
    input [max_input_len-1:0] i, mes; 
    begin
        @(posedge clk);
        messagexSI = i*8 <= (`y-1) ? mes[`y-1-i*8-:8] : 8'b 0000;
        $display("Input:\t%h", messagexSI);
    end
    endtask

    task read;
    input integer i;
    begin
        @(posedge clk);
        data_out = hash_digestxSO;
        $display("Output:\t%h", data_out);
        hash_digest = {hash_digest[`l-9:0], data_out};
    end
    endtask

    initial begin
        $dumpfile("test_hash_soc.vcd");
        $dumpvars;
        $display("Start!");
		rst = 0;
		#(1.5*period)
        rst = 1;
        ctr = 0;
        repeat(max_input_len/8+1) begin
            #(4*period)
            reg_inputxSS = 1;
            write(ctr, `MESSAGE);
            ctr = ctr + 1;
            // #(2*period)
            reg_inputxSS = 0;
            $display("i:\t%d", dut.i);
        end
        ctr = 0;
        #(0.5*period)
        $display("Message:\t%h", dut.message);
        check_time = $time;
        reg_startxSS = 1;
        hash_startxSI = 1;
        #(4*period)
        hash_startxSI = 0;
        reg_startxSS = 0;
    end

    always @(*) begin
        if(hash_readyxSO) begin
            check_time = $time - check_time;
            $display("Hash done! It took%d clk cycles", check_time/(2*period));
            #(6*period)
            repeat(`y/8 + 17) begin
                #(10*period)
                reg_outxSS = 1;
                read(ctr);
                ctr = ctr + 1;
                reg_outxSS = 0;
            end
            $display("Hash:\t%h", hash_digest);
            $finish;
        end
    end
endmodule