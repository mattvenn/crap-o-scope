`default_nettype none
module encoder #(
    parameter width = 4,
    parameter initial_val = 0,
    parameter increment = 1
)(
    input a,
    input b,
    input clk,
    output reg [width-1:0] value
);

    initial begin
        value <= initial_val;
    end

    reg oa = 0;
    reg ob = 0;


    always@(posedge clk) begin
        if(a != oa || b != ob )
            case ({a,oa,b,ob})
                4'b1000: value <= value + increment;
                4'b0111: value <= value + increment;
                4'b0010: value <= value - increment;
                4'b1101: value <= value - increment;
            endcase 
    end

    always@(posedge clk) begin
        oa <= a;
        ob <= b;
    end
endmodule
