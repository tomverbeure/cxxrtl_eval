

SRC_FILE 			= ../spinal/ExampleTop.sim.v
VERILATOR_PREFIX	= /opt/verilator/
CXX					= g++
NR_THREADS          = 2

all: tb_vcd tb_fst tb_vcd_threaded

#============================================================
# No tracing
#============================================================

tb: verilator
	$(CXX) -std=c++14 -g -O3 -I$(VERILATOR_PREFIX)/share/verilator/include/ -I$(VERILATOR_PREFIX)/share/verilator/include/vltstd -Iobj_dir \
	     main.cpp \
	    $(VERILATOR_PREFIX)/share/verilator/include/verilated.cpp \
	    ./obj_dir/Vtb__ALL.a -o tb

.PHONY: verilator
verilator: 
	rm -fr obj_dir
	verilator -CFLAGS "-g -O3" --Mdir obj_dir -Wno-fatal -cc tb.v $(SRC_FILE)
	cd obj_dir && make -f Vtb.mk
	cp ../spinal/*.bin .

#============================================================
# VCD
#============================================================

tb_vcd: verilator_vcd
	$(CXX) -std=c++14 -g -O3 -DTRACE_VCD -I$(VERILATOR_PREFIX)/share/verilator/include/ -I$(VERILATOR_PREFIX)/share/verilator/include/vltstd -Iobj_dir_vcd \
	     main.cpp \
	    $(VERILATOR_PREFIX)/share/verilator/include/verilated.cpp \
	    $(VERILATOR_PREFIX)/share/verilator/include/verilated_vcd_c.cpp \
	    ./obj_dir_vcd/Vtb__ALL.a -o tb_vcd

.PHONY: verilator_vcd
verilator_vcd: 
	rm -fr obj_dir_vcd
	verilator -CFLAGS "-g -O3" --trace --Mdir obj_dir_vcd -Wno-fatal -cc tb.v $(SRC_FILE)
	cd obj_dir_vcd && make -f Vtb.mk
	cp ../spinal/*.bin .

#============================================================
# VCD Threaded
#============================================================

tb_vcd_threaded: verilator_vcd_threaded
	$(CXX) -std=c++14 -g -O3 -DTRACE_VCD -DVL_THREADED -I$(VERILATOR_PREFIX)/share/verilator/include/ -I$(VERILATOR_PREFIX)/share/verilator/include/vltstd -Iobj_dir_vcd_threaded \
	    main.cpp \
	    $(VERILATOR_PREFIX)/share/verilator/include/verilated.cpp \
	    $(VERILATOR_PREFIX)/share/verilator/include/verilated_threads.cpp \
	    $(VERILATOR_PREFIX)/share/verilator/include/verilated_vcd_c.cpp \
	    -lpthread \
	    ./obj_dir_vcd_threaded/Vtb__ALL.a -o $@

.PHONY: verilator_vcd_threaded
verilator_vcd_threaded: 
	rm -fr obj_dir_vcd_threaded
	verilator -CFLAGS "-g -O3" --trace --threads $(NR_THREADS) --Mdir obj_dir_vcd_threaded -Wno-fatal -cc tb.v $(SRC_FILE)
	cd obj_dir_vcd_threaded && make -f Vtb.mk
	cp ../spinal/*.bin .

#============================================================
# FST
#============================================================

tb_fst: verilator_fst
	$(CXX) -std=c++14 -g -O3 -DTRACE_FST -I$(VERILATOR_PREFIX)/share/verilator/include/ -I$(VERILATOR_PREFIX)/share/verilator/include/vltstd -Iobj_dir_fst \
	     main.cpp \
	    $(VERILATOR_PREFIX)/share/verilator/include/verilated.cpp \
	    $(VERILATOR_PREFIX)/share/verilator/include/verilated_fst_c.cpp \
	    ./obj_dir_fst/Vtb__ALL.a -lz -o tb_fst

.PHONY: verilator_fst
verilator_fst: 
	rm -fr obj_dir_fst
	verilator -CFLAGS "-g -O3" --trace-fst --Mdir obj_dir_fst -Wno-fatal -cc tb.v $(SRC_FILE)
	cd obj_dir_fst && make -f Vtb.mk
	cp ../spinal/*.bin .

clean:
	\rm -fr *.bin obj_dir obj_dir_vcd obj_dir_vcd_threaded obj_dir_fst tb
