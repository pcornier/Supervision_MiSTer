//============================================================================
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//
//============================================================================

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [48:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	//if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
	output [12:0] VIDEO_ARX,
	output [12:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler

	input  [11:0] HDMI_WIDTH,
	input  [11:0] HDMI_HEIGHT,
	output        HDMI_FREEZE,

`ifdef MISTER_FB
	// Use framebuffer in DDRAM (USE_FB=1 in qsf)
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,

`ifdef MISTER_FB_PALETTE
	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,
`endif
`endif

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	// I/O board button press simulation (active high)
	// b[1]: user button
	// b[0]: osd button
	output  [1:0] BUTTONS,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

	//ADC
	inout   [3:0] ADC_BUS,

	//SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,

`ifdef MISTER_DUAL_SDRAM
	//Secondary SDRAM
	//Set all output SDRAM_* signals to Z ASAP if SDRAM2_EN is 0
	input         SDRAM2_EN,
	output        SDRAM2_CLK,
	output [12:0] SDRAM2_A,
	output  [1:0] SDRAM2_BA,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_nCS,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nWE,
`endif

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	input   [6:0] USER_IN,
	output  [6:0] USER_OUT,

	input         OSD_STATUS
);
///////// Default values for ports not used in this core /////////

assign ADC_BUS  = 'Z;
assign USER_OUT = '1;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;
assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = '0;

assign VGA_SL = 0;
assign VGA_F1 = 0;

assign AUDIO_S = 0;
assign AUDIO_L = { audio_ch2, 12'd0 };
assign AUDIO_R = { audio_ch1, 12'd0 };
assign AUDIO_MIX = 0;

assign LED_DISK = 0;
assign LED_POWER = 0;
assign BUTTONS = 0;

//////////////////////////////////////////////////////////////////

wire [1:0] ar = status[122:121];

assign VIDEO_ARX = (!ar) ? 12'd4 : (ar - 1'd1);
assign VIDEO_ARY = (!ar) ? 12'd3 : 12'd0;

`include "build_id.v"
localparam CONF_STR = {
	"Supervision;;",
	"-;",
	"F,binsv,Load Cartridge;",
	"-;",
	"O[122:121],Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
	"O[2],TV Mode,NTSC,PAL;",  
	"-;",
	"T0,Reset;",
	"R0,Reset and close OSD;",
	"J0,B,A,select,start;",
	"V,v",`BUILD_DATE
};

wire forced_scandoubler;
wire [15:0] joystick_0;
wire  [1:0] buttons;
wire [127:0] status;
wire [10:0] ps2_key;

wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire  [7:0] ioctl_index;
wire ioctl_wr;
wire ioctl_download;
wire ioctl_wait;

hps_io #(.CONF_STR(CONF_STR)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),
	.EXT_BUS(),
	.gamma_bus(),

	.forced_scandoubler(forced_scandoubler),

	.buttons(buttons),
	.status(status),
	.status_menumask({status[5]}),

	.ps2_key(ps2_key),
	.joystick_0(joystick_0),

	.ioctl_download(ioctl_download),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_wait(ioctl_wait),
	.ioctl_index(ioctl_index)
);


///////////////////////   CLOCKS   ///////////////////////////////

wire clk_sys;
wire clk_cpu;
wire clk_vid;

pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(clk_sys), // 50
	.outclk_1(clk_vid), // 36
	.outclk_2(clk_cpu) // 6
);

reg [15:0] nmi_clk;

wire nmi = nmi_clk == 0;
always @(posedge clk_cpu) nmi_clk <= nmi_clk + 16'b1;
wire reset = RESET | status[0] | buttons[1] | ioctl_download;

//////////////////////////////////////////////////////////////////

wire hsync;
wire vsync;
wire hblank;
wire vblank;
assign CLK_VIDEO = clk_vid;
wire [7:0] red, green, blue;

reg [7:0] sys_ctl;
reg [7:0] irq_timer; // 2023
reg [7:0] irq_status; // 2027 ??????DT 1=expired/finished
reg irq_tim;
reg irq_dma;

wire [15:0] cpu_addr;
wire [7:0] cpu_dout;
wire [7:0] wram_dout;
wire [7:0] vram_dout;
wire [7:0] rom_dout;
wire [7:0] sys_dout;

reg [7:0] dma_src_lo;
reg [7:0] dma_src_hi;
reg [7:0] dma_dst_lo;
reg [7:0] dma_dst_hi;
reg [7:0] dma_length;
reg [7:0] dma_ctrl;
wire [7:0] dma_dout;
wire [13:0] dma_addr;
wire dma_busy;
wire dma_sel;
wire dma_write;

reg [7:0] lcd_xscroll;
reg [7:0] lcd_yscroll;
reg [7:0] lcd_xsize;
reg [7:0] lcd_ysize;
wire [7:0] lcd_din;
wire lcd_pulse;
wire cpu_rdy = ~dma_busy;
wire dma_rdy = ~lcd_pulse;
wire cpu_we;
wire [15:0] lcd_addr;

reg [7:0] ch1_freq_hi, ch1_freq_low, ch1_length, ch1_vduty;
reg [7:0] ch2_freq_hi, ch2_freq_low, ch2_length, ch2_vduty;
reg [7:0] audio_dma_addr_low, audio_dma_addr_high;
reg [7:0] audio_dma_ctrl, audio_dma_length, audio_dma_trigger;
reg [7:0] noise_ctrl, noise_freq_vol, noise_length;
wire [3:0] audio_ch1, audio_ch2;

////////////////////// IRQ //////////////////////////


reg [13:0] timer_div;

// irq_tim
always @(posedge clk_sys)
  if (sys_ctl[1]) begin // irq enable flag
    if (irq_timer == 0 && ~irq_status[0]) irq_tim <= 1;
    else if (sys_cs && cpu_we && AB[2:0] == 3'h3 && cpu_dout == 0) irq_tim <= 1;
    else irq_tim <= 0;
  end

// irq status
always @(posedge clk_sys)
  if (sys_cs && ~cpu_we && AB[2:0] == 3'h4) // write to irq timer ack
    irq_status[0] <= 1'b0;
  else if (irq_tim) // change status on irq
    irq_status[0] <= 1'b1;

// timer prescaler
always @(posedge clk_cpu)
  if (timer_div > 0)
    timer_div <= timer_div - 14'b1;
  else if (sys_ctl[4])
    timer_div <= 14'h3fff;
  else
    timer_div <= 14'hff;

// irq_timer
always @(posedge clk_cpu)
  if (sys_cs && cpu_we && AB[2:0] == 3'h3)
    irq_timer <= cpu_dout;
  else if (timer_div == 0 && irq_timer > 0)
    irq_timer <= irq_timer - 8'b1;


/////////////////////////// MEMORY MAP /////////////////////

// 0000 - 1FFF - WRAM
// 2000 - 202F - CTRL
// 2030 - 3FFF - CTRL - mirrors ??
// 4000 - 5FFF - VRAM ??
// 6000 - 7FFF - VRAM - mirrors ??
// 8000 - BFFF - banks
// C000 - FFFF - last 16k of cartridge


wire wram_cs = AB ==? 16'b000x_xxxx_xxxx_xxxx;
wire lcd_cs  = AB ==? 16'b0010_0000_0000_0xxx; // match 2000-2007 LCD control registers
wire dma_cs  = AB ==? 16'b0010_0000_0000_1xxx; // match 2008-200F DMA control registers
wire snd_cs  = AB ==? 16'b0010_0000_0001_xxxx; // match 2010-201F sound registers
wire sys_cs  = AB ==? 16'b0010_0000_0010_0xxx; // match 2020-2027 sys registers
wire noi_cs  = AB ==? 16'b0010_0000_0010_1xxx; // match 2028-202F sound registers (noise)
wire vram_cs = AB ==? 16'b01xx_xxxx_xxxx_xxxx;
wire rom_cs  = AB ==? 16'b1xxx_xxxx_xxxx_xxxx;
wire rom_hi  = AB ==? 16'b11xx_xxxx_xxxx_xxxx;

wire [15:0] AB = dma_busy  ? { 2'b0, dma_addr } : cpu_addr;

reg [7:0] DI;

wire [7:0] DO = dma_busy ? dma_dout : cpu_dout;
wire wram_we = wram_cs ? dma_busy ? ~dma_write : ~cpu_we : 1'b1;
wire vram_we = vram_cs ? dma_busy ? ~dma_write : ~cpu_we : 1'b1;

wire [15:0] rom_addr = rom_hi ? AB : { sys_ctl[6:5], AB[13:0] };

always @(posedge clk_cpu)
  DI <= sys_cs ? sys_dout :
  wram_cs ? wram_dout :
  vram_cs ? vram_dout :
  rom_cs ? rom_dout : 8'hff;

// write to lcd registers
always @(posedge clk_sys)
  if (lcd_cs && cpu_we) begin
    case (AB[1:0])
      2'h0: lcd_xsize <= cpu_dout;
      2'h1: lcd_ysize <= cpu_dout;
      2'h2: lcd_xscroll <= cpu_dout;
      2'h3: lcd_yscroll <= cpu_dout;
    endcase
  end

// write to audio registers
always @(posedge clk_sys)
  if (snd_cs && cpu_we) begin
    case (AB[3:0])
      4'h0: ch1_freq_low <= cpu_dout;
      4'h1: ch1_freq_hi <= cpu_dout;
      4'h2: ch1_vduty <= cpu_dout;
      4'h3: ch1_length <= cpu_dout;
      4'h4: ch2_freq_low <= cpu_dout;
      4'h5: ch2_freq_hi <= cpu_dout;
      4'h6: ch2_vduty <= cpu_dout;
      4'h7: ch2_length <= cpu_dout;
      4'h8: audio_dma_addr_low <= cpu_dout;
      4'h9: audio_dma_addr_high <= cpu_dout;
      4'ha: audio_dma_length <= cpu_dout;
      4'hb: audio_dma_ctrl <= cpu_dout;
      4'hc: audio_dma_trigger <= cpu_dout;
    endcase
  end

// write to noise registers
always @(posedge clk_sys)
  if (noi_cs && cpu_we) begin
    case (AB[2:0])
      3'h0: noise_freq_vol <= cpu_dout;
      3'h1: noise_length <= cpu_dout;
      3'h2: noise_ctrl <= cpu_dout;
    endcase
  end


// write to dma registers
always @(posedge clk_sys)
  if (dma_cs && cpu_we)
    case (AB[2:0])
      3'h0: dma_src_lo <= cpu_dout;
      3'h1: dma_src_hi <= cpu_dout;
      3'h2: dma_dst_lo <= cpu_dout;
      3'h3: dma_dst_hi <= cpu_dout;
      3'h4: dma_length <= cpu_dout;
      3'h5: dma_ctrl   <= cpu_dout;
      default:
        dma_ctrl <= 8'd0;
    endcase

// write to sys registers
always @(posedge clk_sys)
  if (sys_cs && cpu_we)
    case (AB[2:0])
     // 3'h3: irq_timer = cpu_dout;
      3'h6: sys_ctl <= cpu_dout;
    endcase

// read sys registers
always @(posedge clk_sys)
  if (sys_cs && ~cpu_we)
    case (AB[2:0])
      3'h0: sys_dout <= {
          ~joystick_0[7],
          ~joystick_0[6],
          ~joystick_0[5],
          ~joystick_0[4],
          ~joystick_0[3],
          ~joystick_0[2],
          ~joystick_0[1],
          ~joystick_0[0]
        };
      3'h3: sys_dout <= irq_timer;
      3'h6: sys_dout <= sys_ctl;
    endcase


////////////////////////////////////////////////


rom cart(
  .clk(clk_sys),
  .addr(rom_addr),
  .dout(rom_dout),
  .cs(~rom_cs),
  .rom_init(ioctl_download),
  .rom_init_clk(clk_sys),
  .rom_init_address(ioctl_addr),
  .rom_init_data(ioctl_dout)
);


ram88 wram(
  .clk(clk_sys),
  .addr(AB[12:0]),
  .din(DO), // <= cpu or dma
  .dout(wram_dout),
  .we(wram_we),
  .cs(~wram_cs)
);

// dual port ram
ram88 vram(
  .clk(clk_sys),
  .addr(AB[12:0]),
  .din(DO), // <= cpu or dma
  .dout(vram_dout),
  .addrb(lcd_addr),
  .doutb(lcd_din),
  .we(vram_we),
  .cs(~vram_cs)
);

dma dma(
  .clk(clk_sys),
  .rdy(dma_rdy),
  .ctrl(dma_ctrl),
  .src_addr({ dma_src_hi, dma_src_lo }),
  .dst_addr({ dma_dst_hi, dma_dst_lo }),
  .addr(dma_addr), // => to AB
  .din(DI),
  .dout(dma_dout),
  .length(dma_length),
  .busy(dma_busy),
  .sel(dma_sel),
  .write(dma_write)
);

audio audio(
  .clk(clk_sys),
  .CH1_freq({ ch1_freq_hi[2:0], ch1_freq_low }),
  .CH1_vduty(ch1_vduty),
  .CH1_length(ch1_length),
  .CH2_freq({ ch2_freq_hi[2:0], ch2_freq_low }),
  .CH2_vduty(ch2_vduty),
  .CH2_length(ch2_length),
  .DMA_addr({ audio_dma_addr_high, audio_dma_addr_low }),
  .DMA_length(audio_dma_length),
  .DMA_ctrl(audio_dma_ctrl),
  .DMA_trigger(audio_dma_trigger),
  .noise_freq_vol(noise_freq_vol),
  .noise_length(noise_length),
  .noise_ctrl(noise_ctrl),
  .CH1(audio_ch1),
  .CH2(audio_ch2)
);

video video(
  .clk(clk_vid),
  .ce_pxl(CE_PIXEL),
  .ce(sys_ctl[3]),
  .lcd_xsize(lcd_xsize),
  .lcd_ysize(lcd_ysize),
  .lcd_xscroll(lcd_xscroll),
  .lcd_yscroll(lcd_yscroll),
  .addr(lcd_addr),
  .data(lcd_din),
  .hsync(hsync),
  .vsync(vsync),
  .hblank(hblank),
  .vblank(vblank),
  .red(red),
  .green(green),
  .blue(blue)
);

video_cleaner video_cleaner(
	.clk_vid(clk_vid),
	.ce_pix(CE_PIXEL),
	.R(red),
	.G(green),
	.B(blue),
	.HSync(~hsync),
	.VSync(~vsync),
	.HBlank(hblank),
	.VBlank(vblank),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS),
	.VGA_DE(VGA_DE)
);

//assign VGA_DE = ~(hblank | vblank);
//assign VGA_HS = hsync;
//assign VGA_VS = vsync;

/*
cpu_65c02 cpu(
  .clk(clk_cpu),
  .reset(reset),
  .AB(cpu_addr),
  .DI(DI),
  .DO(cpu_dout),
  .WE(cpu_we),
  .IRQ(irq_tim | irq_dma),
  .NMI(nmi),
  .RDY(cpu_rdy)
);
*/

ncpu_65c02 cpu(
  .clk(clk_cpu),
  .reset(reset),
  .AB(cpu_addr),
  .DI(DI),
  .DO(cpu_dout),
  .WE(cpu_we),
  .IRQ(irq_tim | irq_dma),
  .NMI(nmi),  
  .RDY(cpu_rdy)
);

/*
R65C02 cpu(
    .reset(reset),
    .clk(clk_cpu),
    .enable(cpu_we),
    .nmi_n(nmi),
    .irq_n(irq_tim | irq_dma),
    .di(DI),

    .dout(cpu_dout),
    .addr(cpu_addr),
    .nwe(),
    .sync(),
    .sync_irq(),
    .Regs()
);
*/

endmodule
