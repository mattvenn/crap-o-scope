module color_sq
#(
    parameter x_off = 0,
    parameter y_off = 0,
    parameter w = 100,
    parameter h = 100
)
(
    input wire        clk,        // System clock.
    input wire [5:0]  color,
    input wire [9:0]  x_px,       // X position actual pixel.
    input wire [9:0]  y_px,       // Y position actual pixel.
    output reg [5:0]  color_px    // Actual pixel color.
);

    always @(posedge clk)
    begin
        // If we're inside the square
        if ((x_px > x_off) && (x_px <= x_off + w) && (y_px > y_off) && (y_px <= y_off + h))   
        begin
            color_px <= color;
        end
        else
           color_px <= 0;
    end

endmodule
