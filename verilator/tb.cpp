
#include <fstream> // ifstream
#include "VSupervision.h"
#include "VSupervision_emu.h"
#include "VSupervision_hps_io__S82.h"
#include "VSupervision_pll.h"
#include "verilated.h"
#include <verilated_vcd_c.h>
#include "SDL2/SDL.h"

VSupervision* sv;
SDL_Window* window;
SDL_Surface* screen;
SDL_Surface* canvas;
bool running = true;

void setPixel(SDL_Surface* dst, int x, int y, int color) {
  *((Uint32*)(dst->pixels) + x + y * dst->w) = color;
}

int main(int argc, char** argv, char** env) {

  Verilated::commandArgs(argc, argv);

  const char* romfile = (argc > 1) ? argv[1] : "rom.bin";

  window = SDL_CreateWindow(
    "svision",
    SDL_WINDOWPOS_UNDEFINED,
    SDL_WINDOWPOS_UNDEFINED,
    640, 480,
    SDL_WINDOW_SHOWN
    //SDL_WINDOW_OPENGL
    //SDL_WINDOW_VULKAN
  );

  if (window == NULL) {
    printf("Could not create window: %s\n", SDL_GetError());
    return 1;
  }

  screen = SDL_GetWindowSurface(window);
  canvas = SDL_CreateRGBSurfaceWithFormat(0, 640, 480, 16, SDL_PIXELFORMAT_RGB888);

  printf("creating instance\n");

  sv = new VSupervision;
  sv->eval();

  printf("loading ROM file\n");

  std::ifstream ifs(romfile, std::ios::in | std::ios::binary);
  if (!ifs) return -1;

  VSupervision_hps_io__S82* io = sv->emu->hps_io;
  VSupervision_pll* pll = sv->emu->pll;

  io->ioctl_addr = 0;
  io->ioctl_download = 1;
  io->ioctl_dout = ifs.get();
  sv->CLK_50M = !sv->CLK_50M;
  sv->eval();

  while (!ifs.eof()) {

    if (sv->CLK_50M) {
      io->ioctl_addr = io->ioctl_addr+1;
      io->ioctl_dout = ifs.get();
    }

    sv->CLK_50M = !sv->CLK_50M;
    sv->eval();
  }

  io->ioctl_download = 0;

  printf("ROM loaded\n");


  #if VM_TRACE			// If verilator was invoked with --trace
    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    sv->trace(tfp, 99);
    tfp->open("dump.vcd");	// Open the dump file
  #endif

  sv->RESET = 0;
  io->joystick_0 = 0;

  int cycles = 0;
  float vgax = 0;
  int vgay = 0;
  bool hs = true;
  bool vs = true;
  bool dirty;

  int start_trace = 120'000'000;
  int stop_sim    = 140'000'000;
  bool tracing = false;

  printf("running instance\n");

  while (running) {


    #if VM_TRACE
      if (cycles > start_trace) tracing = true;
      if (cycles > stop_sim) running = false;
    #endif

    if (cycles == 100) sv->RESET = 1;
    if (cycles == 200) sv->RESET = 0;

    #if VM_TRACE
      if (tfp && tracing) tfp->dump(cycles);
    #endif

    sv->eval();

    sv->CLK_50M = !sv->CLK_50M;

    if (dirty) {
      SDL_BlitSurface(canvas, NULL, screen, NULL);
      SDL_UpdateWindowSurface(window);
      SDL_FillRect(canvas, NULL, 0x0);
      printf("refresh\n");
      dirty = false;
    }


    if (pll->outclk_1) {

      if (!sv->VGA_HS && hs) { // start of hsync ¯¯\__
        hs = false;
      }
      else if (sv->VGA_HS && !hs) { // end of hsync __/¯¯
        hs = true;
        vgax = -192;
        vgay++;
      }
      else {
        vgax += 0.2;
      }

      if (!sv->VGA_VS && vs) { // start of vsync ¯¯\__
        vs = false;
      }
      else if (sv->VGA_VS && !vs) { // end of vsync __/¯¯
        vs = true;
        vgay = -31;
        dirty = true;
      }

      if (vgax >= 0 && vgax < 640 && vgay >= 0 && vgay < 480) {
        int c = sv->VGA_R << 16 | sv->VGA_G << 8 | sv->VGA_B;
        setPixel(canvas, vgax, vgay, !hs || !vs ? 0 : c);
      }
    }

    if (cycles % 1000000 == 0) printf("sim: %d %s\n", cycles, tracing == true ? "(tracing)" : "");
    cycles++;


  }

  #if VM_TRACE
    if (tfp) tfp->close();
  #endif

  SDL_FreeSurface(screen);
  SDL_DestroyWindow(window);
  SDL_Quit();

  return 0;
}
