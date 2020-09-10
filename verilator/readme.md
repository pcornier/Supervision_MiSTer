Verilator Simulation
--------------------

Because of the use of "public" keyword in configuration file (.vlt), please use at least Verilator v4.0.28.

Use `make run` to build the simulation then run `./obj_dir/VSupervision romfile.bin`

MiSTer Directory
----------------

The MiSTer directory contains fake MiSTer modules so I can run the simulation and focus on architecture without modifying the original core files.

- HPS_IO is completely fake but ports are public and exposed to the testbench file.
- PLL module is used for clock logic. Adjust to your needs.
- The video_cleaner is fake and just assigns inputs to outputs.

