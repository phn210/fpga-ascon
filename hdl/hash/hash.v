module Hash #(
    parameter r = 64, a = 12, b = 12, h = 256, l = 256, y = 40
)(
    input   clk, rst, start,
    input   [y-1:0] message,
    output  ready,
    output  [l-1:0] hash
);
    // Constants and State Definitions
    localparam c = 320-r, nz_m = ((y+1)%r == 0)? 0 : r-((y+1)%r), Y = y+1+nz_m, s = Y/r, t = l/r;
    localparam IDLE = 'd0, INITIALIZE = 'd1, ABSORB = 'd2, SQUEEZE = 'd3, DONE = 'd4;

    // Internal Registers and Wires
    reg     [319:0] S;
    reg     [2:0]   state = IDLE;
    reg     [4:0]   rounds;
    reg     [t:0]   block_ctr;
    reg     [h-1:0] H;
    reg             ready_1;
    reg     [319:0] P_in;
    wire    [319:0] P_out, IV, M;
    wire    [63:0]  Sr;
    wire    [c-1:0] Sc;
    wire    [4:0]   ctr, permutation_ready;
    reg             permutation_start;

    // Assignments
    assign {Sr, Sc} = S;
    assign IV = r << 48 | a << 40 | (a-b) << 12 | h;
    assign M = {message, 1'b1, {nz_m{1'b0}}};
    assign hash = ready? H[h-1 -: l] : 0;
    assign ready = ready_1;

    // FSM and Logic
    always @(posedge clk) begin
        if(rst) begin
            state <= IDLE;
            S <= 0;
            ready_1 <= 0;
            H <= 0;
            block_ctr <= 0;
        end
        else case (state)
            IDLE: if(start) state <= INITIALIZE;
            INITIALIZE: if(permutation_ready) begin 
                state <= ABSORB; 
                S <= P_out; 
            end
            ABSORB: begin
                if (block_ctr == s-1) begin 
                    state <= SQUEEZE; 
                    S <= {Sr ^ M[r-1 : 0], Sc};
                end
                else if(permutation_ready && block_ctr != s) S <= P_out;
                if (block_ctr == s-1) block_ctr <= 0; 
                else if(permutation_ready && block_ctr != s) block_ctr <= block_ctr + 1; 
            end
            SQUEEZE: begin
                if(permutation_ready && block_ctr == t-1) begin 
                    state <= DONE; 
                    block_ctr <= 0; 
                    H[r-1 : 0] <= P_out[319 -: r]; 
                end
                else if(permutation_ready && block_ctr != t) begin 
                    S <= P_out; 
                    H[(t-block_ctr)*r-1 -: r] <= P_out[319 -: r]; 
                    block_ctr <= block_ctr + 1; 
                end
            end
            DONE: begin 
                ready_1 <= 1; 
                if(start) state <= IDLE; 
            end
            default: state <= IDLE;
        endcase
    end

    always @(*) begin
        P_in = 0; rounds = a; permutation_start = 0;
        case (state)
            INITIALIZE: begin P_in = S; rounds = a; permutation_start = permutation_ready? 1'b0: 1'b1; end
            ABSORB: begin
                P_in = {Sr^M[(s-block_ctr)*r-1 -: r], Sc};
                rounds = b;
                permutation_start = (block_ctr == s-1)? 0 : 1;
            end
            SQUEEZE: begin 
                P_in = S; 
                rounds = (block_ctr == 0)? a : b; 
                permutation_start = 1; end
        endcase
    end

    // Permutation Block and Round Counter
    Permutation p1(
        .clk(clk), .reset(rst), .S(P_in), .out(P_out), .done(permutation_ready), .ctr(ctr), .rounds(rounds), .start(permutation_start)
    );
    RoundCounter RC(clk, rst, permutation_start, permutation_ready, ctr);
endmodule
