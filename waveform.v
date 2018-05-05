`default_nettype none
module waveform
#(
    parameter x_off = 0,
    parameter y_off = 0,
    parameter color = 6'b111111,
    parameter w = 100,
    parameter h = 100,
    parameter addr_width = 10,
    parameter data_width = 16
)
(
    input wire        clk,        // System clock.
    input wire [9:0]  x_px,       // X position actual pixel.
    input wire [9:0]  y_px,       // Y position actual pixel.
    output reg [5:0]  color_px,    // Actual pixel color.
    input wire [data_width-1:0] sample
);

    wire [addr_width-1:0] addr;
//    wire [data_width-1:0] sample;

    assign addr = x_px - x_off;

/*
    fontROM 
    #(
        .FONT_FILE("wave.list"),
        .addr_width(addr_width),
        .data_width(data_width)
    )
    fontROM01
    (
        .clk(clk),
        .write_en (0),
        .addr (addr),
        .dout (sample)
    );
    */
    reg [data_width-1:0] last, current;

    always @(posedge clk) begin
        current <= sample;
        last <= current;
    end


    always @(posedge clk)
    begin
        // If we're inside the square
        if ((x_px > x_off) && (x_px <= x_off + w + 1) && (y_px > y_off) && (y_px <= y_off + h + 1))   
        begin
            if(y_px - y_off == current)
                color_px <= color;
            else if((y_px - y_off) < current && (y_px - y_off) > last)
                color_px <= color;
            else if((y_px - y_off) > current && (y_px - y_off) < last)
                color_px <= color;
            else
                color_px <= 0;
        end
        else
           color_px <= 0;
    end

endmodule
