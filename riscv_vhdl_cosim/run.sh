
#git clone https://github.com/kammoh/ORCA-risc-v.git

ORCA=./ORCA-risc-v

rm *.cf
rm *.bin

OPTIONS="--std=08 -fsynopsys"

ghdl -a $OPTIONS $ORCA/utils.vhd
ghdl -a $OPTIONS $ORCA/components.vhd
ghdl -a $OPTIONS $ORCA/branch_unit.vhd
ghdl -a $OPTIONS $ORCA/instruction_fetch.vhd
ghdl -a $OPTIONS $ORCA/decode.vhd
ghdl -a $OPTIONS $ORCA/execute.vhd
ghdl -a $OPTIONS $ORCA/load_store_unit.vhd
ghdl -a $OPTIONS $ORCA/alu.vhd
ghdl -a $OPTIONS $ORCA/register_file.vhd
ghdl -a $OPTIONS $ORCA/sys_call.vhd
ghdl -a $OPTIONS $ORCA/riscv.vhd

cp ../spinal/*symbol*.bin .

#yosys -m ghdl -p "read_verilog ../spinal/ExampleTop.sim.v; delete VexRiscv; read_verilog VexRiscv_wrapper.v; ghdl --std=08 riscV; hierarchy -check -top ExampleTop;"
yosys -m ghdl -p "read_verilog ../spinal/ExampleTop.sim.v; delete VexRiscv; read_verilog VexRiscv_wrapper.v; ghdl --std=08 riscV; hierarchy -check -top ExampleTop; write_cxxrtl -Og -g1 ExampleTop.sim.cpp"
#yosys -m ghdl -p "ghdl --std=08 riscv; hierarchy -check -top riscV"


clang++-9 -g -O2 -I`yosys-config --datdir`/include -DEXAMPLE_TOP=\"ExampleTop.sim.cpp\" -std=c++14 -I../lib main.cpp ../lib/cxxrtl_lib.cpp -o tb
./tb 2 waves.vcd
