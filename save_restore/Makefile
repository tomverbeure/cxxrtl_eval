
YOSYS = yosys
YOSYS_INCLUDE	= $(shell yosys-config --datdir)/include/backends/cxxrtl/runtime

all: tb_save tb_restore
	./tb_save
	./tb_restore

tb_save: save.cpp blink.cpp cxxrtl_lib.o
	clang++ -g -O0 -std=c++14 -I $(YOSYS_INCLUDE) -I../lib cxxrtl_lib.o $< -o $@

tb_restore: restore.cpp blink.cpp cxxrtl_lib.o
	clang++ -g -O0 -std=c++14 -I $(YOSYS_INCLUDE) -I../lib cxxrtl_lib.o $< -o $@

blink.cpp: blink.v
	$(YOSYS) -p "read_verilog blink.v; hierarchy -top blink; write_cxxrtl -Og blink.cpp"


cxxrtl_lib.o: ../lib/cxxrtl_lib.cpp
	clang++ -c -g -std=c++14 -I $(YOSYS_INCLUDE) -I../lib $<

clean:
	\rm -f blink.cpp tb *.vcd
