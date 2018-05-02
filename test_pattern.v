module test_pattern (
	input wire clk,
    input wire [10:0] x,
    input wire [9:0] y,
    input wire [2:0] red,
    input wire [2:0] grn,
    input wire [2:0] blu,
    output wire debug
    );

    assign red = x[4:2] + count;
    assign grn = x[6:2] + count;
    assign blu = y[4:2] + count;

    assign debug = slow_clk;

    reg [2:0] count;
    wire start = x == 0 && y == 0;
    wire slow_clk;
    divM #(.M(4)) divM_0(.clk_in(start), .clk_out(slow_clk));

    always @(posedge slow_clk)
        count <= count + 1;


endmodule
