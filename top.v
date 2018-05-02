`default_nettype none

module top (
	input  clk,
    output LED,
    output hsync,
    output vsync,
    output r1,
    output r2,
    output g1,
    output g2,
    output b1,
    output b2,
    output debug,
);

    wire vga_clk;

    //PLL details http://www.latticesemi.com/view_document?document_id=47778
    //vga clock freq is 25.2MHz (see vga.v)
    SB_PLL40_CORE #(
        .FEEDBACK_PATH("SIMPLE"),
        .PLLOUT_SELECT("GENCLK"),
        .DIVR(4'b0000),
        .DIVF(7'b1000010),
        .DIVQ(3'b101),
        .FILTER_RANGE(3'b001)
    ) uut (
        .RESETB(1'b1),
        .BYPASS(1'b0),
        .REFERENCECLK(clk),
        .PLLOUTCORE(vga_clk)
    );

    wire [10:0] x;
    wire [9:0] y;

    wire [5:0] color_px;

    vga vga_inst(.clk(vga_clk), .red({r2,r1}), .green({g2,g1}), .blue({b2,b1}), .color_px(color_px), .hsync(hsync), .vsync(vsync), .hcounter(x), .vcounter(y));

    wire start = x == 0 && y == 0;
    wire slow_clk;
    divM #(.M(20)) divM_0(.clk_in(start), .clk_out(slow_clk));
    reg [3:0] number;

    always @(posedge slow_clk) begin
        number <= number + 1;
        if(number == 9)
            number <= 0;
    end

   number number_0 (.clk(vga_clk), .x_px(x), .y_px(y), .x_numbers(100), .y_numbers(100), .number(number), .color_px(color_px));
endmodule
