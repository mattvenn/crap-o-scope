//////////////////////////////////////////////////////////////////////////////////
// Company: Ridotech
// Engineer: Juan Manuel Rico
//
// Create Date: 21:30:38 26/04/2018
// Module Name: fontROM
//
// Description: Font ROM for numbers (16x19 bits for numbers 0 to 9).
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
//
// Additional Comments:
//
//-----------------------------------------------------------------------------
//-- GPL license
//-----------------------------------------------------------------------------
module fontROM 
#(
    parameter FONT_FILE = "BRAM_16.list",
    parameter addr_width = 12,
    parameter data_width = 16
)
(
    input wire                  clk,
    input wire                  write_en,
    input wire [addr_width-1:0] addr,
    input wire [data_width-1:0] din,
    output reg [data_width-1:0] dout
);

reg [data_width-1:0] mem [(1 << addr_width)-1:0];

initial begin
  if (FONT_FILE) $readmemb(FONT_FILE, mem);
end

always @(posedge clk)
begin
    if (write_en)
        mem[addr] <= din;
    dout = mem[addr]; // Output register controlled by clock.
end

endmodule
