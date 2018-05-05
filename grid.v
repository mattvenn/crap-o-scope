module grid
#(
    parameter x_off = 0,
    parameter y_off = 0,
    parameter space = 100,
    parameter color = 6'b111111,
    parameter w = 100,
    parameter h = 100
)
(
    input wire        clk,        // System clock.
    input wire [9:0]  x_px,       // X position actual pixel.
    input wire [9:0]  y_px,       // Y position actual pixel.
    output reg [5:0]  color_px    // Actual pixel color.
);

    localparam N = $clog2(space);
    reg [N-1:0] xcounter = 0;
    reg [N-1:0] ycounter = 0;

    always @(posedge x_px[0]) begin
        xcounter <= xcounter + 1;
        if(xcounter == space - 1)
            xcounter <= 0;
        if(x_px - x_off  == 0)
            xcounter <= 0;
    end
    always @(posedge y_px[0]) begin
        ycounter <= ycounter + 1;
        if(ycounter == space - 1)
            ycounter <= 0;
        if(y_px - y_off  == 0)
            ycounter <= 0;
    end
    
    always @(posedge clk)
    begin
        // If we're inside the square
        if ((x_px > x_off) && (x_px <= x_off + w + 1) && (y_px > y_off) && (y_px <= y_off + h + 1))   
        begin
            if(xcounter == 0)
                color_px <= color;
            else if (ycounter == 0)
                color_px <= color;
            else
                color_px <= 0;
        end
        else
           color_px <= 0;
    end

endmodule
