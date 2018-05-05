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

    output adc_clk,
    output adc_cs,
    input adc_sd
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
    wire [5:0] square_color_px;
    wire [5:0] grid_color_px;
    wire [5:0] wave_color_px;

    vga vga_inst(.clk(vga_clk), .red({r2,r1}), .green({g2,g1}), .blue({b2,b1}), .color_px(number_color_px|square_color_px|grid_color_px|wave_color_px), .hsync(hsync), .vsync(vsync), .hcounter(x_px), .vcounter(y_px));

    wire adc_ready;
    wire [11:0] adc_data;
    reg [11:0] data_buf; // for display as number
    reg [11:0] wave_data;// for waveform
    adc adc_inst_0(.clk(vga_clk), .reset(0), .adc_clk(adc_clk), .adc_cs(adc_cs), .adc_sd(adc_sd), .ready(adc_ready), .data(adc_data));



    wire start = x_px == 0 && y_px == 0;
    reg [15:0] frames;
    always @(posedge start)  begin
        frames <= frames + 1;
        data_buf <= adc_data;
    end
    always @(posedge adc_ready)
        wave_data <= adc_data;
        
        
    // Some colors.
    parameter [5:0] black   = 6'b000000;

    parameter [5:0] blue0   = 6'b000001;
    parameter [5:0] blue1   = 6'b000010;
    parameter [5:0] blue2   = 6'b000011;


    parameter [5:0] green0  = 6'b000100;
    parameter [5:0] green1  = 6'b001000;
    parameter [5:0] green2  = 6'b001100;
    parameter [5:0] red     = 6'b110000;
    parameter [5:0] yellow  = 6'b111100;
    parameter [5:0] white   = 6'b111111;

    numbers  #( .x_off(20), .y_off(5)) numbers_0(.clk(vga_clk), .x_px(x_px), .y_px(y_px), .var1(frames), .var2(pot), .var3(data_buf >> 3), .var4(data_buf), .color_px(number_color_px));
    color_sq #( .x_off(100), .y_off(5), .w(512), .h(64), .color1(blue0), .color2(blue2))  color_sq_0 (.clk(vga_clk), .x_px(x_px), .y_px(y_px), .div(data_buf >> 3), .color_px(square_color_px));

    grid     #( .x_off(20), .y_off(70), .w(600), .h(400), .space(20), .color(green1))  grid_0 (.clk(vga_clk), .x_px(x_px), .y_px(y_px), .color_px(grid_color_px));
    waveform #( .x_off(20), .y_off(70), .w(600), .h(400), .color(white))  waveform_0 (.clk(vga_clk), .x_px(x_px), .y_px(y_px), .color_px(wave_color_px), .sample((wave_data >> 3) + pot));

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

    reg [15:0] pot;
    encoder #(.width(16)) encoder_inst(.clk(clk), .a(a_db), .b(b_db), .value(pot));
    assign LED = a_db;
endmodule
