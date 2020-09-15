
.PHONY: run

CFLAGS := $(shell pkg-config sdl2 --cflags)
LDFLAGS := $(shell pkg-config sdl2 --libs)

run:
	rm -rf ./obj_dir
	verilator -Wall -Irtl -Wno-fatal --cc ../Supervision.sv -y MiSTer -y ../rtl -y ../rtl/65c02 --exe tb.cpp -CFLAGS '${CFLAGS} -g' -LDFLAGS '${LDFLAGS}' run.vlt
	make -j -C ./obj_dir -f VSupervision.mk VSupervision
	# when running on termux:
	cp -R obj_dir ~

trace:
	rm -rf ./obj_dir
	verilator -Wall -Irtl -Wno-fatal --cc ../Supervision.sv -y MiSTer -y ../rtl -y ../rtl/65c02 --exe tb.cpp --trace -CFLAGS '${CFLAGS} -g' -LDFLAGS '${LDFLAGS}' trace.vlt
	make -j -C ./obj_dir -f VSupervision.mk VSupervision
	# when running on termux:
	cp -R obj_dir ~

