
module video(

  input clk,
  output ce_pxl,

  // from lcd ctrl registers
  input ce,
  input [7:0] lcd_xsize,
  input [7:0] lcd_ysize,
  input [7:0] lcd_xscroll,
  input [7:0] lcd_yscroll,

  // to/from vram
  output [12:0] addr,
  input [7:0] data,

  // to vga interface
  output hsync,
  output vsync,
  output hblank,
  output vblank,
  output reg [7:0] red,
  output reg [7:0] green,
  output reg [7:0] blue,

  input pal_dl,
  input [7:0] pal_data,
  input pal_wr,
  input pal_en
);

reg [9:0] hcount;
reg [9:0] vcount;

// visible area | front porch <sync pulse> back porch
//     640      |     32      <    48    >     112
assign hsync = ~((hcount >= 672) && (hcount < 720));
assign vsync = ~((vcount >= 481) && (vcount < 484));

assign hblank = hcount > 639;
assign vblank = vcount > 479;

// convert vga coordinates to lcd coordinates (with borders)
wire [8:0] vgax = hcount < 640 ? hcount[9:1] : 9'd0; // 0 - 319
wire [8:0] vgay = vcount < 480 ? vcount[9:1] : 9'd0; // 0 - 239
wire [7:0] lcdx = vgax >= 80 && vgax < 240 ? vgax - 8'd80 : 8'd0; // 0-79(80)|80-239(160)|240-319(80)
wire [7:0] lcdy = vgay >= 40 && vgay < 200 ? vgay - 8'd40 : 8'd0; // 0-39(40)|40-199(160)|200-239(40)

// calcul vram address (TODO include xsize, ysize, xscroll[1:0] in calculation)
assign addr = lcd_yscroll * 8'h30 + lcd_xscroll[7:2] + lcdy * 8'h30 + lcdx[7:2];
//assign addr = lcdy * 8'h30 + lcdx[7:2];

assign ce_pxl = hcount[0] == 1;

// assign colors
wire [2:0] index = { lcdx[1:0], 1'b0 };

//reg [127:0] palette = 128'h828214517356305A5F1A3B4900000000; // old
reg [127:0] palette = 128'hffeffff7b58c84739c18101000000000; // new

always @(posedge clk) begin
	if (pal_dl & pal_wr) begin
			palette[127:0] <= {palette[119:0], pal_data[7:0]};
  end
end

wire [23:0] color_fg = {palette[127:104]};
wire [23:0] color_bg = {palette[55:32]};
wire [7:0] r_pal, g_pal, b_pal;

always @(posedge clk)
  if (ce && lcdx != 0 && lcdy != 0) begin
    if (ce_pxl) begin
		 case (data[index+:2])
			2'b00: { red, green, blue } <= 24'h87BA6B; 
			2'b01: begin { red, green, blue } <= 24'h6BA378; $display( "(2'b01) red: %x green: %x blue: %x fg %x bg %x", red, green, blue, color_fg[23:16], color_bg[23:16]); end
			2'b10: begin { red, green, blue } <= 24'h386B82; $display( "(2'b10) red: %x green: %x blue: %x fg %x bg %x", red, green, blue, color_fg[15:8], color_bg[15:8]); end
			2'b11: begin { red, green, blue } <= 24'h384052; $display( "(2'b11) red: %x green: %x blue: %x fg %x bg %x", red, green, blue, color_fg[7:0], color_bg[7:0]); end      
		 endcase

     if(pal_en) begin
        red   <= {red + color_fg[23:16]};
        green <= {green + color_fg[15:8]};
        blue  <= {blue + color_fg[7:0]};    
     end

	 end
  end
  else
    { red, green, blue } <= 24'h0;

always @(posedge clk) begin
  hcount <= hcount + 10'd1;
  if (hcount == 10'd799) hcount <= 0;
end

always @(posedge clk)
  if (hcount == 10'd799)
    vcount <= vcount + 10'd1;
  else if (vcount == 10'd509)
    vcount <= 0;


endmodule