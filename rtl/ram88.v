
module ram88 (
  input clk,
  input [12:0] addr,
  input [12:0] addrb,
  input [7:0] din,
  input we,
  input cs,
  output reg [7:0] dout,
  output reg [7:0] doutb
);

reg [7:0] memory[8191:0] /*verilator public_flat_rd*/;

`ifdef XILINX_ISIM
  reg [12:0] ii;
  initial begin
    for (ii = 0; ii < 8191; ii = ii + 1) memory[ii] = 0;
  end
`endif

always @(posedge clk) begin
  if (~cs) begin
    if (~we) memory[addr] <= din;
    dout <= memory[addr];
  end
  doutb <= memory[addrb];
end

endmodule
