verilator \
-cc -exe --public --trace --savable \
--compiler msvc +define+SIMULATION=1 \
-O3 --x-assign fast --x-initial fast --noassert \
--converge-limit 6000 \
-Wno-fatal \
--top-module top sim.v \
../rtl/audio.v \
../rtl/dma.v \
../rtl/ram88.v \
../rtl/rom.v \
../rtl/video.v \
../rtl/new65c02/ncpu_65c02.v \
../rtl/new65c02/nALU.v
