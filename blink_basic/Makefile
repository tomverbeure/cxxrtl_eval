
YOSYS			= yosys
YOSYS_INCLUDE	= $(shell yosys-config --datdir)/include/backends/cxxrtl/runtime

all: tb
	./tb

tb: main.cpp blink.cpp
	clang++ -g -O3 -std=c++14 -I $(YOSYS_INCLUDE) $< -o $@

blink.cpp: blink.v
	$(YOSYS) -p "read_verilog $<; write_cxxrtl $@"


clean:
	\rm -f blink.cpp tb
