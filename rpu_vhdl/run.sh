
#git clone https://github.com/kammoh/ORCA-risc-v.git

RPU=./RPU/vhdl/

rm -f *.cf
rm -f *.bin

OPTIONS="--std=08 -fsynopsys"

ghdl -a $OPTIONS $RPU/constants.vhd
ghdl -a $OPTIONS $RPU/alu_int32_div.vhd
ghdl -a $OPTIONS $RPU/control_unit.vhd
ghdl -a $OPTIONS $RPU/csr_unit.vhd
ghdl -a $OPTIONS $RPU/lint_unit.vhd
ghdl -a $OPTIONS $RPU/mem_controller.vhd
ghdl -a $OPTIONS $RPU/pc_unit.vhd
ghdl -a $OPTIONS $RPU/register_set.vhd
ghdl -a $OPTIONS $RPU/unit_alu_RV32_I.vhd
ghdl -a $OPTIONS $RPU/unit_decoder_RV32I.vhd
ghdl -a $OPTIONS $RPU/core.vhd

cp ../spinal/*symbol*.bin .

##yosys -m ghdl -p "read_verilog ../spinal/ExampleTop.sim.v; delete VexRiscv; read_verilog VexRiscv_wrapper.v; ghdl --std=08 riscV; hierarchy -check -top ExampleTop;"
yosys -m ghdl -p "read_verilog ../spinal/ExampleTop.sim.v; delete VexRiscv; read_verilog VexRiscv_wrapper.v; ghdl --std=08 core; hierarchy -check -top ExampleTop; write_cxxrtl -Og -g1 ExampleTop.sim.cpp"
##yosys -m ghdl -p "ghdl --std=08 riscv; hierarchy -check -top riscV"
#
#
clang++-9 -g -O2 -I`yosys-config --datdir`/include -DEXAMPLE_TOP=\"ExampleTop.sim.cpp\" -std=c++14 -I../lib main.cpp ../lib/cxxrtl_lib.cpp -o tb
#./tb 2 waves.vcd
