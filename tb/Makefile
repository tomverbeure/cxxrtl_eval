
CREATE_MIF 		= ../misc/create_mif.rb
HEX2BIN    		= ../misc/hex2bin.py
SW_DIR	   		= ../sw
VERILOG_FILES 	= tb.v ../spinal/ExampleTop.sim.v

ROM_FILES = ExampleTop.v_toplevel_cpu_u_cpu_u_cpu_ram_ram_symbol0.bin \
		    ExampleTop.v_toplevel_cpu_u_cpu_u_cpu_ram_ram_symbol1.bin \
		    ExampleTop.v_toplevel_cpu_u_cpu_u_cpu_ram_ram_symbol2.bin \
		    ExampleTop.v_toplevel_cpu_u_cpu_u_cpu_ram_ram_symbol3.bin

all: tb $(ROM_FILES)
	./tb

tb: $(VERILOG_FILES) $(ROM_FILES)
	iverilog -o $@ $(VERILOG_FILES)

ExampleTop.v_toplevel_cpu_u_cpu_u_cpu_ram_ram_symbol0.bin: ExampleTop.v_toplevel_cpu_u_cpu_u_cpu_ram_ram_symbol0.hex
	$(HEX2BIN) < $< > $@

ExampleTop.v_toplevel_cpu_u_cpu_u_cpu_ram_ram_symbol1.bin: ExampleTop.v_toplevel_cpu_u_cpu_u_cpu_ram_ram_symbol1.hex
	$(HEX2BIN) < $< > $@

ExampleTop.v_toplevel_cpu_u_cpu_u_cpu_ram_ram_symbol2.bin: ExampleTop.v_toplevel_cpu_u_cpu_u_cpu_ram_ram_symbol2.hex
	$(HEX2BIN) < $< > $@

ExampleTop.v_toplevel_cpu_u_cpu_u_cpu_ram_ram_symbol3.bin: ExampleTop.v_toplevel_cpu_u_cpu_u_cpu_ram_ram_symbol3.hex
	$(HEX2BIN) < $< > $@

ExampleTop.v_toplevel_cpu_u_cpu_u_cpu_ram_ram_symbol0.hex: $(SW_DIR)/progmem.bin
	$(CREATE_MIF) -f hex -d 1024 -w 8 -o 0 -i 4 $< > $@

ExampleTop.v_toplevel_cpu_u_cpu_u_cpu_ram_ram_symbol1.hex: $(SW_DIR)/progmem.bin
	$(CREATE_MIF) -f hex -d 1024 -w 8 -o 1 -i 4 $< > $@

ExampleTop.v_toplevel_cpu_u_cpu_u_cpu_ram_ram_symbol2.hex: $(SW_DIR)/progmem.bin
	$(CREATE_MIF) -f hex -d 1024 -w 8 -o 2 -i 4 $< > $@

ExampleTop.v_toplevel_cpu_u_cpu_u_cpu_ram_ram_symbol3.hex: $(SW_DIR)/progmem.bin
	$(CREATE_MIF) -f hex -d 1024 -w 8 -o 3 -i 4 $< > $@

waves:
	gtkwave waves.vcd waves.gtkw &

lint:
	verilator --lint-only ../spinal/ExampleTop.sim.v 

clean:
	\rm -f *.bin *.hex tb *.vcd

