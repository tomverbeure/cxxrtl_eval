
YOSYS			= yosys
YOSYS_INCLUDE	= $(shell yosys-config --datdir)/include
GHDL 			= /opt/ghdl/bin/ghdl

all: tb
	./tb

tb: main.cpp blink.cpp
	clang++ -g -O3 -std=c++14 -I $(YOSYS_INCLUDE) $< -o $@

blink.cpp: blink.vhdl
	$(GHDL) analyse $<
	$(YOSYS) -m ghdl -p "ghdl blink; write_cxxrtl $@"

clean:
	\rm -f blink.cpp tb
