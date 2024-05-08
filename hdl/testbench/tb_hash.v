`timescale 1ns/1ns
module HashTB;
    parameter period = 20;          // Clock frequency
    parameter max_input_len = (`h>=`y && `h>=`l)? `h: ((`y>=`l)? `y: `l);

    reg             clk = 0;
    reg             rst;
    reg             messagexSI;
    reg             startxSI = 0;
    integer         ctr = 0;
    reg [`l-1:0]    hash_digest;

    wire  hash_digestxSO;
    wire  hash_readyxSO;
    integer check_time;

    Hashing #(
        `r,`a,`b,`h,`l,`y
    ) dut (
        clk,
        rst,
        messagexSI,
        startxSI,
        hash_digestxSO,
        hash_readyxSO
    );

    // Clock Generator of 10ns
    always #(period) clk = ~clk;

    task write;
    input [max_input_len-1:0] i, mes; 
    begin
        @(posedge clk);
        messagexSI = mes[`y-1-i];
    end
    endtask

    task read;
    input integer i;
    begin
        @(posedge clk);
        hash_digest[i] = hash_digestxSO;
    end
    endtask

    initial begin
        $dumpfile("test_hash.vcd");
        $dumpvars;
        $display("Start!");
        rst = 1;
        #(2*period)
        rst = 0;
        ctr = 0;
        repeat(max_input_len) begin
            write(ctr, `MESSAGE);
            ctr = ctr + 1;
        end
        ctr = 0;
        startxSI = 1;
        check_time = $time;
        #(0.5*period)
        $display("Message:\t%h", dut.message);
        #(4.5*period)
        startxSI = 0;
    end

    always @(*) begin
        if(hash_readyxSO) begin
            check_time = $time - check_time;
            $display("Hashing Done! It took%d clock cycles", check_time/(2*period));
            #(4*period)
            repeat(max_input_len) begin
                read(ctr);
                ctr = ctr + 1;
            end
            $display("Hash:\t%h", hash_digest);
            $finish;
        end
    end
endmodule