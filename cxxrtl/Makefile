

YOSYS		= ~/tools/yosys/yosys
SRC			= main.cpp
VERILOG		= ../spinal/ExampleTop.sim.v
MEM_FILES	= ../spinal/ExampleTop.v_toplevel_cpu_u_cpu_u_cpu_ram_ram_symbol0.bin 		\
				../spinal/ExampleTop.v_toplevel_cpu_u_cpu_u_cpu_ram_ram_symbol1.bin 		\
				../spinal/ExampleTop.v_toplevel_cpu_u_cpu_u_cpu_ram_ram_symbol2.bin 		\
				../spinal/ExampleTop.v_toplevel_cpu_u_cpu_u_cpu_ram_ram_symbol3.bin

all: example_O5_clang example_O4_clang example_O3_clang example_O2_clang example_O1_clang example_O0_clang example_O5_clang_db
	time ./example_O0_clang
	time ./example_O1_clang
	time ./example_O2_clang
	time ./example_O3_clang
	time ./example_O4_clang
	time ./example_O5_clang

example_O5_clang_db: ExampleTop.sim.O5.cpp $(SRC)
	clang++ -g -O0 -std=c++11 -DEXAMPLE_TOP=\"$<\" -I ~/tools/yosys/ $(SRC) -o $@

example_O5_clang: ExampleTop.sim.O5.cpp $(SRC)
	clang++ -g -O3 -std=c++11 -DEXAMPLE_TOP=\"$<\" -I ~/tools/yosys/ $(SRC) -o $@

example_O4_clang: ExampleTop.sim.O4.cpp $(SRC)
	clang++ -g -O3 -std=c++11 -DEXAMPLE_TOP=\"$<\" -I ~/tools/yosys/ $(SRC) -o $@

example_O3_clang: ExampleTop.sim.O3.cpp $(SRC)
	clang++ -g -O3 -std=c++11 -DEXAMPLE_TOP=\"$<\" -I ~/tools/yosys/ $(SRC) -o $@

example_O2_clang: ExampleTop.sim.O2.cpp $(SRC)
	clang++ -g -O3 -std=c++11 -DEXAMPLE_TOP=\"$<\" -I ~/tools/yosys/ $(SRC) -o $@

example_O1_clang: ExampleTop.sim.O1.cpp $(SRC)
	clang++ -g -O3 -std=c++11 -DEXAMPLE_TOP=\"$<\" -I ~/tools/yosys/ $(SRC) -o $@

example_O0_clang: ExampleTop.sim.O0.cpp $(SRC)
	clang++ -g -O3 -std=c++11 -DEXAMPLE_TOP=\"$<\" -I ~/tools/yosys/ $(SRC) -o $@

ExampleTop.sim.O5.cpp:
	cp $(MEM_FILES) .
	$(YOSYS)  -p "read_verilog $(VERILOG); write_cxxrtl -O5 $@"

ExampleTop.sim.O4.cpp:
	cp $(MEM_FILES) .
	$(YOSYS)  -p "read_verilog $(VERILOG); write_cxxrtl -O4 $@"

ExampleTop.sim.O3.cpp:
	cp $(MEM_FILES) .
	$(YOSYS)  -p "read_verilog $(VERILOG); write_cxxrtl -O3 $@"

ExampleTop.sim.O2.cpp:
	cp $(MEM_FILES) .
	$(YOSYS)  -p "read_verilog $(VERILOG); write_cxxrtl -O2 $@"

ExampleTop.sim.O1.cpp:
	cp $(MEM_FILES) .
	$(YOSYS)  -p "read_verilog $(VERILOG); write_cxxrtl -O1 $@"

ExampleTop.sim.O0.cpp:
	cp $(MEM_FILES) .
	$(YOSYS)  -p "read_verilog $(VERILOG); write_cxxrtl -O0 $@"

clean: 
	\rm -fr *.bin *.sim.* example_*_clang example_*_gcc example
