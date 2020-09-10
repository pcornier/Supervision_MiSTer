
module pll(
    input refclk,
    input rst,

    output outclk_0,
    output reg outclk_1,
    output reg outclk_2
);

assign outclk_0 = refclk;
always @(posedge refclk) outclk_1 <= ~outclk_1;
always @(posedge outclk_1) outclk_2 <= ~outclk_2;

endmodule