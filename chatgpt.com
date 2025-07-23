module fir_filter (
    input clk,
    input reset,
    input signed [7:0] x,             // 8-bit input sample
    output reg signed [15:0] y        // 16-bit output sample
);

    // Coefficients (constant)
    parameter signed [7:0] h0 = 8'd1,
                           h1 = 8'd2,
                           h2 = 8'd3,
                           h3 = 8'd2,
                           h4 = 8'd1;

    // Shift Register to store input samples
    reg signed [7:0] x_reg [0:4]; // 5 samples

    integer i;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset all registers
            for (i = 0; i < 5; i = i + 1)
                x_reg[i] <= 8'd0;
            y <= 16'd0;
        end else begin
            // Shift input samples
            for (i = 4; i > 0; i = i - 1)
                x_reg[i] <= x_reg[i-1];
            x_reg[0] <= x;

            // Compute convolution (FIR Output)
            y <= (h0 * x_reg[0]) +
                 (h1 * x_reg[1]) +
                 (h2 * x_reg[2]) +
                 (h3 * x_reg[3]) +
                 (h4 * x_reg[4]);
        end
    end

endmodule

# test bench code:-

module fir_tb;
    reg clk, reset;
    reg signed [7:0] x;
    wire signed [15:0] y;

    fir_filter uut (.clk(clk), .reset(reset), .x(x), .y(y));

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz
    end

    initial begin
        reset = 1;
        x = 0;
        #10 reset = 0;

        // Input samples
        #10 x = 8'd1;
        #10 x = 8'd2;
        #10 x = 8'd3;
        #10 x = 8'd4;
        #10 x = 8'd5;
        #10 x = 8'd0;
        #50 $finish;
    end
endmodule
