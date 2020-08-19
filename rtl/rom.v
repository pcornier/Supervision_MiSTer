
module rom #(
  parameter ROMFILE = "rom"
) (
  input clk,
  input [15:0] addr,
  output reg [7:0] dout,
  input cs //
);

reg [7:0] memory[65535:0];
initial $readmemh(ROMFILE, memory, 0, 65535);

always @(posedge clk)
  if (~cs) dout <= memory[addr];


endmodule
