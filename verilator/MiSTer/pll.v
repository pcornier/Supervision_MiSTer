
module pll(
    input refclk,
    input rst,

    output outclk_0,
    output reg outclk_1,
    output reg outclk_2
);

assign outclk_0 = refclk; // 50

reg [9:0] div1, div2;
reg p1, p2;
always @(posedge refclk) begin
  { p1, div1 } <= div1 + 10'd1474;
  { p2, div2 } <= div2 + 10'd245;
end

always @(posedge p1)
  outclk_1 <= ~outclk_1; // 36
  
always @(posedge p2)
  outclk_2 <= ~outclk_2; // 6

endmodule