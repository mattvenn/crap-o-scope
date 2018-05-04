`default_nettype none
module numbers 
#(
    parameter x_off = 0,
    parameter y_off = 0,
    parameter background = black,
    parameter ink = white
)
(
    input wire        clk,        // System clock.
    input wire [15:0] var1,
    input wire [15:0] var2,
    input wire [15:0] var3,
    input wire [15:0] var4,
    input wire [9:0]  x_px,       // X position actual pixel.
    input wire [9:0]  y_px,       // Y position actual pixel.
    output reg [5:0]  color_px    // Actual pixel color.
);

    // Some colors.
    parameter [5:0] black  = 6'b000000;
    parameter [5:0] blue   = 6'b000011;
    parameter [5:0] green  = 6'b001100;
    parameter [5:0] red    = 6'b110000;
    parameter [5:0] yellow = 6'b111100;
    parameter [5:0] white  = 6'b111111;


    
	// Numbers dimension.
    parameter width_numbers = 16;
    parameter height_numbers = 16;

    // Position x and y from image.
    reg [7:0] x_img;
    reg [7:0] y_img;
    wire pixel;

    reg [3:0] number;
   
    // Instance of image numbers.
    image
    image01 (
            .clk (clk),
            .x_img (x_img),
            .y_img (y_img),
            .pixel (pixel)
            );


    // regs for which row and column we're in
    reg [1:0] row = 0;
    reg [1:0] col = 0;

    // calc for col

    always @(posedge clk) begin
        col = (x_px - x_off) >> 4; // divide by 16 as that is width of char

        // lookup table for row
        if(y_px - y_off >= height_numbers * 3) begin
            number = var1[(4-col)*4-1 -:4];
            row = 3;
        end else 
        if(y_px - y_off >= height_numbers * 2) begin
            number = var2[(4-col)*4-1 -:4];
            row = 2;
        end else
        if(y_px - y_off >=  height_numbers * 1) begin
            number = var3[(4-col)*4-1 -:4];
            row = 1;
        end else
        if(y_px - y_off >= height_numbers * 0) begin
            number = var4[(4-col)*4-1 -:4];
            row = 0;
        end
        // where to look up in the font BRAM
        x_img = (x_px - x_off - 1) - col * width_numbers;
        y_img = (y_px - y_off - (row * height_numbers)) + number * height_numbers;

    end
       

    wire drawing;
    assign drawing = color_px == ink;
    // Draw or not the number.
    always @(posedge clk)
    begin
        // If we're inside the number, get pixel from image block and
        if ((x_px > x_off + 1) && (x_px <= x_off + width_numbers * 4 + 1) && (y_px >= y_off) && (y_px < y_off + height_numbers * 4))   
        begin
            // if it's a pixel, draw in ink colour
            if (pixel)
                color_px <= ink;
            else
                color_px <= background;
        end
        else
           color_px <= background;
    end

endmodule
