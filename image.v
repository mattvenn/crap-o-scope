//////////////////////////////////////////////////////////////////////////////////
// Company: Ridotech
// Engineer: Juan Manuel Rico
// 
// Create Date: 09:30:32 01/10/2017 
// Module Name: image
// Description: Image with image for screen-saver.
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
//
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module image (
                input  wire clk,            // System clock.
                input  wire [7:0] x_img,    // X position in image. 
                input  wire [7:0] y_img,    // Y position in image.
                output reg  pixel           // Pixel (B&W) in x and y positon.
             );

wire [3:0] col_bit;      //Column bit in glyph line.
wire [11:0] addr_rom;

assign col_bit = x_img[3:0];
assign addr_rom = y_img;

fontROM 
#(
    .FONT_FILE("BRAM_16.list")
)
fontROM01
(
    .clk(clk),
    .write_en (0),
    .addr (addr_rom),
    .dout (glyph_line)
);

wire [0:15] glyph_line;

// Read memory.
always @(posedge clk)
begin
        pixel = glyph_line[col_bit] ? 1 : 0;
end

endmodule
