`timescale 1ns/1ns
module HashTB;
    parameter period = 20;          // Clock frequency
    parameter max_input_len = (`h>=`y && `h>=`l)? `h: ((`y>=`l)? `y: `l);

    reg       clk = 0;
    reg       rst;
    reg [2:0] messagexSI;
    reg       startxSI = 0;
    reg [6:0] r_64xSI;
    reg       r_faultxSI;
    integer ctr = 0;
    reg [`l-1:0] hash_text;

    wire  hash_textxSO;
    wire  readyxSO;
    integer check_time;

    Hashing #(
        `r,`a,`b,`h,`l,`y
    ) hash (
        clk,
        rst,
        messagexSI,
        startxSI,
        r_64xSI,
        r_faultxSI,

        hash_textxSO,
        readyxSO
    );

    // Clock Generator of 10ns
    always #(period) clk = ~clk;

    task write;
    input [max_input_len-1:0] rd, i, mes; 
    begin
        @(posedge clk);
        {r_faultxSI, r_64xSI, messagexSI[2:1]} = rd;
        messagexSI[0] = mes[`y-1-i];
    end
    endtask

    task read;
    input integer i;
    begin
        @(posedge clk);
        hash_text[i] = hash_textxSO;
    end
    endtask

    initial begin
        $dumpfile("test.vcd");
        $dumpvars;
        $display("Start!");
        rst = 1;
        #(2*period)
        rst = 0;
        ctr = 0;
        repeat(max_input_len) begin
            write($random, ctr, `MESSAGE);
            ctr = ctr + 1;
        end
        ctr = 0;
        startxSI = 1;
        check_time = $time;
        #(0.5*period)
        $display("Message:\t%h", hash.message);
        #(4.5*period)
        startxSI = 0;
    end

    always @(*) begin
        if(readyxSO) begin
            check_time = $time - check_time;
            $display("Hashing Done! It took%d clock cycles", check_time/(2*period));
            #(4*period)
            repeat(max_input_len) begin
                read(ctr);
                ctr = ctr + 1;
            end
            $display("Hash:\t%h", hash_text);
            $finish;
        end
    end
endmodule