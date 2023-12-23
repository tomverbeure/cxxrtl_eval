

SRC_FILES 			= tb.v ../spinal/ExampleTop.sim.v main.cpp

#VERILATOR_PREFIX	= /opt/verilator/
VERILATOR_PREFIX	= /usr/

# output directory
VERILATOR_OPTIONS 	+= --Mdir obj_dir
# generate c++ code
VERILATOR_OPTIONS 	+= --cc
# Don't bail on some Verilog warnings
VERILATOR_OPTIONS 	+= -Wno-fatal
# Create Makefile to generate executable (instead of an archive)
VERILATOR_OPTIONS 	+= --exe
# Kick off build automatically after Verilog code has been converted
VERILATOR_OPTIONS 	+= --build

#CFLAGS 				= -CFLAGS "-g -O3"


CXX					= clang++

all: tb_vcd tb_fst

#============================================================
# No tracing
#============================================================

tb: verilator

.PHONY: verilator
verilator: 
	rm -fr obj_dir
	verilator $(CFLAGS) $(VERILATOR_OPTIONS) --Mdir obj_dir $(SRC_FILES) 
	cp ../spinal/*.bin .

#============================================================
# VCD
#============================================================

tb_vcd: verilator_vcd

.PHONY: verilator_vcd
verilator_vcd: 
	rm -fr obj_dir_vcd
	verilator $(CFLAGS) $(VERILATOR_OPTIONS) --trace --Mdir obj_dir_vcd $(SRC_FILES) 
	cp ../spinal/*.bin .

#============================================================
# FST
#============================================================

tb_fst: verilator_fst

.PHONY: verilator_fst
verilator_fst: 
	rm -fr obj_dir_fst
	verilator $(CFLAGS) $(VERILATOR_OPTIONS) --trace-fst --Mdir obj_dir_fst $(SRC_FILES) 
	cp ../spinal/*.bin .

clean:
	\rm -fr *.bin obj_dir obj_dir_vcd obj_dir_fst tb
