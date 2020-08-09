
YOSYS			= yosys
YOSYS_INCLUDE	= $(shell yosys-config --datdir)/include

all: waves
	./tb

waves: sim
	gtkwave waves.vcd waves.gtkw

sim: tb
	./tb

tb: main.cpp blink.cpp
	clang++ -g -std=c++14 -I $(YOSYS_INCLUDE) $< -o $@

blink.cpp: blink.v
	$(YOSYS) -p "read_verilog $<; write_cxxrtl $@"


clean:
	\rm -f blink.cpp tb *.vcd
