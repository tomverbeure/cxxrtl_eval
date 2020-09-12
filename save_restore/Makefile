
YOSYS_DIR	= ~/projects/yosys

all: tb_save tb_restore
	./tb_save
	./tb_restore

tb_save: save.cpp blink.cpp 
	clang++ -g -O0 -std=c++14 -I $(YOSYS_DIR) -I../lib cxxrtl_lib.o $< -o $@

tb_restore: restore.cpp blink.cpp 
	clang++ -g -O0 -std=c++14 -I $(YOSYS_DIR) -I../lib cxxrtl_lib.o $< -o $@

blink.cpp: blink.v
	$(YOSYS_DIR)/yosys -p "read_verilog blink.v; hierarchy -top blink; write_cxxrtl -Og blink.cpp"


cxxrtl_lib.o: ../lib/cxxrtl_lib.cpp
	clang++ -c -g -std=c++14 -I $(YOSYS_DIR) -I../lib $< 

clean:
	\rm -f blink.cpp tb *.vcd
