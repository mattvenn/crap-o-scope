`default_nettype none

module top (
	input  clk,
    input a,
    input b,
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

    wire [10:0] x_px;
    wire [9:0] y_px;

    wire [5:0] number_color_px;
    wire [5:0] number2_color_px;
    wire [5:0] square_color_px;
    wire [5:0] square2_color_px;

    vga vga_inst(.clk(vga_clk), .red({r2,r1}), .green({g2,g1}), .blue({b2,b1}), .color_px(number_color_px|number2_color_px|square_color_px|square2_color_px), .hsync(hsync), .vsync(vsync), .hcounter(x_px), .vcounter(y_px));

    wire start = x_px == 0 && y_px == 0;
    wire slow_clk;
    divM #(.M(16)) divM_0(.clk_in(start), .clk_out(slow_clk));

    reg [15:0] number0;
    reg [15:0] number1;
    reg [15:0] number2;
    always @(posedge start) 
        number2 <= number2 + 1;
        

    always @(posedge slow_clk) begin
        number0 <= number0 + 1;
        number1 <= number1 + 2;
    end

    // Some colors.
    parameter [5:0] black  = 6'b000000;
    parameter [5:0] blue   = 6'b000011;
    parameter [5:0] green  = 6'b001100;
    parameter [5:0] red    = 6'b110000;
    parameter [5:0] yellow = 6'b111100;
    parameter [5:0] white  = 6'b111111;

    numbers  #( .x_off(100), .y_off(100)) numbers_0(.clk(vga_clk), .x_px(x_px), .y_px(y_px), .var1(number0), .var2(number1), .var3(counter), .var4(number2), .color_px(number_color_px));
    color_sq #( .x_off(200), .y_off(100), .w(64), .h(64))  color_sq_0 (.clk(vga_clk), .x_px(x_px), .y_px(y_px), .color(counter), .color_px(square_color_px));

    numbers  #( .x_off(200), .y_off(200), .ink(green)) numbers_1(.clk(vga_clk), .x_px(x_px), .y_px(y_px), .var1(counter>>2), .var2(number1>>2), .var3(counter), .var4(number2>>2), .color_px(number2_color_px));
    color_sq #( .x_off(100), .y_off(200), .w(64), .h(64))  color_sq_1 (.clk(vga_clk), .x_px(x_px), .y_px(y_px), .color(number0), .color_px(square2_color_px));

    wire debounce_clk;
    wire a_db, b_db;
    wire a_pullup, b_pullup;
    divM #(.M(256)) divM_1(.clk_in(clk), .clk_out(debounce_clk));
    debounce #(.hist_len(4)) debounce_a(.clk(debounce_clk), .button(a_pullup), .debounced(a_db));
    debounce #(.hist_len(4)) debounce_b(.clk(debounce_clk), .button(b_pullup), .debounced(b_db));

    // pullup config from https://github.com/nesl/ice40_examples/blob/master/buttons_bounce/top.v
    SB_IO #(
        .PIN_TYPE(6'b0000_01),
        .PULLUP(1'b1)
    ) a_config (
        .PACKAGE_PIN(a),
        .D_IN_0(a_pullup)
    );
    SB_IO #(
        .PIN_TYPE(6'b0000_01),
        .PULLUP(1'b1)
    ) b_config (
        .PACKAGE_PIN(b),
        .D_IN_0(b_pullup)
    );

    reg [15:0] counter;
    encoder #(.width(16)) encoder_inst(.clk(clk), .a(a_db), .b(b_db), .value(counter));
    assign LED = a_db;
endmodule
