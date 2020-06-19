
YOSYS			= yosys
YOSYS_INCLUDE	= $(shell yosys-config --datdir)/include

all: tb
	./tb

tb: main.cpp blink.cpp
	clang++ -g -O3 -std=c++14 -I $(YOSYS_INCLUDE) $< -o $@

blink.cpp: blink.v
	$(YOSYS) -p "read_verilog $<; hierarchy -top top; write_cxxrtl -Og $@"


clean:
	\rm -f blink.cpp tb *.vcd
