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
    wire [2:0] red;
    wire [2:0] grn;
    wire [2:0] blu;
    wire r0, g0, b0;


    vga vga_inst(.clk(vga_clk), .red({r2,r1,r0}), .green({g2,g1,g0}), .blue({b2,b1,b0}), .px_red(red), .px_grn(grn), .px_blu(blu), .hsync(hsync), .vsync(vsync), .hcounter(x), .vcounter(y));

    test_pattern test_patt01(.clk(vga_clk), .x(x), .y(y), .red(red), .blu(blu), .grn(grn), .debug(LED));
endmodule
