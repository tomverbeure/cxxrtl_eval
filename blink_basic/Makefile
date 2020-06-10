
YOSYS	= ~/tools/yosys/yosys

all: tb
	./tb

tb: blink.cpp main.cpp
	clang++ -g -O3 -std=c++14 -I ~/tools/yosys/ main.cpp -o tb

blink.cpp: blink.v
	$(YOSYS) -p "read_verilog blink.v; write_cxxrtl blink.cpp"


clean:
	\rm -f blink.cpp tb
