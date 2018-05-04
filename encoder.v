module encoder (
    input a,
    input b,
    input clk,
    output reg [width-1:0] value
);
    parameter width = 4;

    initial begin
        value <= 0;
    end

    reg oa = 0;
    reg ob = 0;


    always@(posedge clk) begin
        if(a != oa || b != ob )
            case ({a,oa,b,ob})
                4'b1000: value <= value + 1;
                4'b0111: value <= value + 1;
                4'b0010: value <= value - 1;
                4'b1101: value <= value - 1;
            endcase 
    end

    always@(posedge clk) begin
        oa <= a;
        ob <= b;
    end
endmodule
