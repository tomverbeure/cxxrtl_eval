

YOSYS			= yosys
YOSYS_INCLUDE	= $(shell yosys-config --datdir)/include

SRC				= main.cpp
OBJ 			= cxxrtl_lib.o
VERILOG			= ../spinal/ExampleTop.sim.v
MEM_FILES		= ../spinal/ExampleTop.v_toplevel_cpu_u_cpu_u_cpu_ram_ram_symbol0.bin 		\
					../spinal/ExampleTop.v_toplevel_cpu_u_cpu_u_cpu_ram_ram_symbol1.bin 		\
					../spinal/ExampleTop.v_toplevel_cpu_u_cpu_u_cpu_ram_ram_symbol2.bin 		\
					../spinal/ExampleTop.v_toplevel_cpu_u_cpu_u_cpu_ram_ram_symbol3.bin

CLANG6			= clang++-6.0
CLANG9			= clang++-9
GCC7			= g++
GCC10			= g++-10

CLANG_INLINE	= -mllvm -inline-threshold=10000 

YOSYS_PREPROC = "read_verilog $(VERILOG); hierarchy -check -top ExampleTop"
YOSYS_RECIPE  = ""

all: compile

.PHONY: compile
compile: \
	compile_time.txt \
	example_default_clang9 \
	example_Og_clang9 \
	example_default_clang6 \
	example_default_gcc10 \
	example_default_gcc7
#	example_default_clang6_inline \
#	example_default_clang9_inline \
#	example_Og_clang9_inline

.PHONY: compile_time.txt
compile_time.txt:
	rm -f $@
	touch $@

example_default_clang9: ExampleTop.sim.default.cpp $(SRC) $(OBJ)
	echo >> compile_time.txt
	echo "Compile time $@" >> compile_time.txt
	(time $(CLANG9) -g -O3 -std=c++14 -DEXAMPLE_TOP=\"$<\" -I $(YOSYS_INCLUDE) $(SRC) -I../lib $(OBJ) -o $@) 2>> compile_time.txt
	echo >> compile_time.txt

example_default_clang6: ExampleTop.sim.default.cpp $(SRC) $(OBJ)
	echo >> compile_time.txt
	echo "Compile time $@" >> compile_time.txt
	(time $(CLANG6) -g -O3 -std=c++14 -DEXAMPLE_TOP=\"$<\" -I $(YOSYS_INCLUDE) $(SRC) -I../lib $(OBJ) -o $@) 2>> compile_time.txt
	echo >> compile_time.txt

example_default_clang9_inline: ExampleTop.sim.default.cpp $(SRC) $(OBJ)
	echo >> compile_time.txt
	echo "Compile time $@" >> compile_time.txt
	(time $(CLANG9) -g -O3 $(CLANG_INLINE) -std=c++14 -DEXAMPLE_TOP=\"$<\" -I $(YOSYS_INCLUDE) $(SRC) -I../lib $(OBJ) -o $@) 2>> compile_time.txt
	echo >> compile_time.txt

example_default_clang6_inline: ExampleTop.sim.default.cpp $(SRC) $(OBJ)
	echo >> compile_time.txt
	echo "Compile time $@" >> compile_time.txt
	(time $(CLANG6) -g -O3 $(CLANG_INLINE) -std=c++14 -DEXAMPLE_TOP=\"$<\" -I $(YOSYS_INCLUDE) $(SRC) -I../lib $(OBJ) -o $@) 2>> compile_time.txt
	echo >> compile_time.txt

example_Og_clang9: ExampleTop.sim.Og.cpp $(SRC) $(OBJ)
	echo >> compile_time.txt
	echo "Compile time $@" >> compile_time.txt
	(time $(CLANG9) -g -O3 -std=c++14 -DEXAMPLE_TOP=\"$<\" -DSPY_UART_TX -I $(YOSYS_INCLUDE) $(SRC) -I../lib $(OBJ) -o $@) 2>> compile_time.txt
	echo >> compile_time.txt

example_Og_clang9_inline: ExampleTop.sim.Og.cpp $(SRC) $(OBJ)
	echo >> compile_time.txt
	echo "Compile time $@" >> compile_time.txt
	(time $(CLANG9) -g -O3 $(CLANG_INLINE) -std=c++14 -DEXAMPLE_TOP=\"$<\" -DSPY_UART_TX -I $(YOSYS_INCLUDE) $(SRC) -I../lib $(OBJ) -o $@) 2>> compile_time.txt
	echo >> compile_time.txt

example_default_gcc10: ExampleTop.sim.default.cpp $(SRC) $(OBJ)
	echo >> compile_time.txt
	echo "Compile time $@" >> compile_time.txt
	(time $(GCC10) -g -O3 -std=c++14 -DEXAMPLE_TOP=\"$<\" -I $(YOSYS_INCLUDE) $(SRC) -I../lib $(OBJ) -o $@) 2>> compile_time.txt
	echo >> compile_time.txt

example_default_gcc7: ExampleTop.sim.Og.cpp $(SRC) $(OBJ)
	echo >> compile_time.txt
	echo "Compile time $@" >> compile_time.txt
	(time $(GCC7) -g -O3 -std=c++14 -DEXAMPLE_TOP=\"$<\" -DSPY_UART_TX -I $(YOSYS_INCLUDE) $(SRC) -I../lib $(OBJ) -o $@) 2>> compile_time.txt
	echo >> compile_time.txt


.PHONY: ExampleTop.sim.default.cpp
ExampleTop.sim.default.cpp:
	cp $(MEM_FILES) .
	$(YOSYS) -l yosys.log -p $(YOSYS_PREPROC) -p $(YOSYS_RECIPE) -p "write_cxxrtl $@"

.PHONY: ExampleTop.sim.Og.cpp
ExampleTop.sim.Og.cpp:
	cp $(MEM_FILES) .
	$(YOSYS) -l yosys.log -p $(YOSYS_PREPROC) -p "write_cxxrtl -Og $@"

cxxrtl_lib.o: ../lib/cxxrtl_lib.cpp
	g++ -c --std=c++14 -I $(YOSYS_INCLUDE) $<

clean: 
	\rm -fr *.bin *.txt *.sim.* example_*_clang* example_*_gcc* example *.vcd
