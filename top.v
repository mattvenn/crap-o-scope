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
    wire [5:0] square0_color_px;
    wire [5:0] square1_color_px;
    wire [5:0] grid_color_px;
    wire [5:0] wave_color_px;

    wire [5:0] color_px;
    // combine the outputs of all the modules that draw on the screen
    assign color_px = number_color_px|square0_color_px|square1_color_px|grid_color_px|wave_color_px;

    wire lower_blank; // signal for when the vga module is no longer drawing on the screen
    wire start = x_px == 0 && y_px == 0;
    reg [15:0] frames;
    reg [15:0] triggers;

    // vga instantiation
    vga vga_inst(.clk(vga_clk), .red({r2,r1}), .green({g2,g1}), .blue({b2,b1}), .color_px(color_px), .hsync(hsync), .vsync(vsync), .hcounter(x_px), .vcounter(y_px), .lower_blank(lower_blank));

    // state machine states
    localparam T_ARM_WAIT   = 0;
    localparam T_ARMED      = 1;
    localparam T_CAPTURE    = 2;
    localparam T_WAIT_END   = 3;

    // important values for tweaking
    localparam MAX_SAMPLES  = 600; // samples to capture, also sets the width of the grid
    localparam ADDR_WIDTH   = 10; //$clog2(MAX_SAMPLES);  // sample storage addr bit depth
    localparam SAMPLE_WIDTH = 16;  // sample bit depth - actually ADC is only 12 bit
    localparam X_OFFSET     = 20; // how far from the left of the screen should the modules start drawing
        
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

    // main graphics modules
    numbers  #( .x_off(X_OFFSET), .y_off(5)) numbers_0(.clk(vga_clk), .x_px(x_px), .y_px(y_px), .var1(triggers), .var2(pot), .var3(data_buf >> 3), .var4(data_buf), .color_px(number_color_px));
    color_sq #( .x_off(100), .y_off(5), .w(512), .h(32), .color1(blue0), .color2(blue2))  color_sq_0 (.clk(vga_clk), .x_px(x_px), .y_px(y_px), .div(data_buf >> 3), .color_px(square0_color_px));
    color_sq #( .x_off(100), .y_off(5+32), .w(512), .h(32), .color1(red), .color2(yellow))  color_sq_1 (.clk(vga_clk), .x_px(x_px), .y_px(y_px), .div(trigger_val >> 3), .color_px(square1_color_px));

    grid     #( .x_off(X_OFFSET), .y_off(70), .w(MAX_SAMPLES), .h(400), .space(20), .color(green1))  grid_0 (.clk(vga_clk), .x_px(x_px), .y_px(y_px), .color_px(grid_color_px));
    waveform #( .x_off(X_OFFSET), .y_off(70), .w(MAX_SAMPLES), .h(400), .color(white),
        .addr_width(ADDR_WIDTH),
        .data_width(SAMPLE_WIDTH))
        waveform_0 (.clk(vga_clk), .x_px(x_px), .y_px(y_px), .color_px(wave_color_px), .sample((wave_data >> 3)));

    // encoder
    wire debounce_clk;
    wire a_db, b_db;
    wire a_pullup, b_pullup;
    divM #(.M(256)) divM_1(.clk_in(clk), .clk_out(debounce_clk));
    debounce #(.hist_len(4)) debounce_a(.clk(debounce_clk), .button(a_pullup), .debounced(a_db));
    debounce #(.hist_len(4)) debounce_b(.clk(debounce_clk), .button(b_pullup), .debounced(b_db));

    // pullup config from https://github.com/nesl/ice40_examples/blob/master/buttons_bounce/top.v
    // a and b are connected to encoder, center pin to ground
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
    encoder #(.width(16), .initial_val(800)) encoder_inst(.clk(clk), .a(a_db), .b(b_db), .value(pot));
    assign LED = a_db;


    // adc
    wire adc_ready;
    wire [SAMPLE_WIDTH-1:0] adc_data;
    reg [SAMPLE_WIDTH-1:0] data_buf; // for display as number
    reg [SAMPLE_WIDTH-1:0] wave_data;// for waveform
    reg ram_wen = 0; // sample ram write enable
    reg [SAMPLE_WIDTH-1:0] trigger_val = 300;

    reg [2:0] trig_state = T_ARM_WAIT;

    wire [ADDR_WIDTH-1:0] ram_addr;
    reg  [ADDR_WIDTH-1:0] wr_addr, rd_addr;

    // mux for ram_addr - either the trigger state machine is writing or the waveform module is reading
    assign ram_addr = lower_blank ? wr_addr : rd_addr;

    adc adc_inst_0(.clk(vga_clk), .reset(0), .adc_clk(adc_clk), .adc_cs(adc_cs), .adc_sd(adc_sd), .ready(adc_ready), .data(adc_data));

    always @(posedge vga_clk) begin
        if(!lower_blank)
            rd_addr <= x_px - X_OFFSET;
    end

    // start of frame
    always @(posedge start)  begin
        frames <= frames + 1;
        data_buf <= adc_data;
    end


    /* state machine for trigger -
        - when the vga module is in screen blanking (at the bottom), wait for the adc to be below the trigger value (set by encoder)
        - when adc > trigger val start writing samples to the BRAM
        - after max samples captured, wait for top of screen to avoid overwriting the buffer
    */
    always @(posedge vga_clk) begin
        trigger_val <= pot;
        case (trig_state)
            T_ARM_WAIT: begin
                wr_addr <= 0;
                ram_wen <= 0;
                if(lower_blank) // only run the capture on the screen blank
                    if(adc_data < trigger_val)
                        trig_state <= T_ARMED;
            end
            T_ARMED: begin
                if(adc_data > trigger_val) begin
                    triggers <= triggers + 1;
                    trig_state <= T_CAPTURE;
                end
            end
            T_CAPTURE: begin
                if(adc_ready) begin
                    ram_wen <= 1;
                    wr_addr <= wr_addr + 1;
                 end else
                    ram_wen <= 0;
                
                if(wr_addr > MAX_SAMPLES)
                    trig_state <= T_WAIT_END;

            end
            // wait here till start of screen to arm again
            T_WAIT_END: begin
                if(y_px == 0)
                    trig_state <= T_ARM_WAIT;
            end
        endcase
    end


    // resuse the fontrom module for the sample buffer
    fontROM 
    #(
        .FONT_FILE("wave.list"),
        .addr_width(ADDR_WIDTH),
        .data_width(SAMPLE_WIDTH)
    )
    sample_RAM
    (
        .clk(vga_clk),
        .write_en (ram_wen),
        .addr (ram_addr),
        .dout (wave_data),
        .din  (adc_data)
    );


endmodule
