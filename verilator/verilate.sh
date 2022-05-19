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
../rtl/65c02/ALU.v \
../rtl/65c02/cpu_65c02.v \
../rtl/65c02/cpu.v \
../rtl/new65c02/r65c02.sv
