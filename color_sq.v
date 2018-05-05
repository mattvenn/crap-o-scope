module color_sq
#(
    parameter x_off = 0,
    parameter y_off = 0,
    parameter w = 100,
    parameter h = 100,
    parameter color1 = 6'b000000,
    parameter color2 = 6'b111111
)
(
    input wire        clk,        // System clock.
    input wire [9:0]  x_px,       // X position actual pixel.
    input wire [9:0]  y_px,       // Y position actual pixel.
    output reg [5:0]  color_px,    // Actual pixel color.
    input wire [9:0]  div           // where to divide
);

    always @(posedge clk)
    begin
        // If we're inside the square
        if ((x_px > x_off) && (x_px <= x_off + w) && (y_px > y_off) && (y_px <= y_off + h))   
        begin
            if((x_px - x_off ) > div)
                color_px <= color1;
            else
                color_px <= color2;
        end
        else
           color_px <= 0;
    end

endmodule
