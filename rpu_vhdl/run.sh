
# Fetch RPU
git submodule update --init

rm -f *.cf
rm -f *.bin

RPU=./RPU/vhdl/

OPTIONS="--std=08"

ghdl -a $OPTIONS $RPU/constants.vhd $RPU/alu_int32_div.vhd $RPU/control_unit.vhd $RPU/csr_unit.vhd \
                 $RPU/lint_unit.vhd $RPU/mem_controller.vhd $RPU/pc_unit.vhd $RPU/register_set.vhd \
                 $RPU/unit_alu_RV32_I.vhd $RPU/unit_decoder_RV32I.vhd $RPU/core.vhd

cp ../spinal/*symbol*.bin .

yosys -m ghdl -p "read_verilog ../spinal/ExampleTop.sim.v; delete VexRiscv; read_verilog VexRiscv_wrapper.v; ghdl --std=08 core; hierarchy -check -top ExampleTop; write_cxxrtl -Og ExampleTop.sim.cpp"

clang++-9 -g -O3 -I`yosys-config --datdir`/include/backends/cxxrtl/runtime -DEXAMPLE_TOP=\"ExampleTop.sim.cpp\" -std=c++14 -I../lib main.cpp ../lib/cxxrtl_lib.cpp -o tb
./tb 2 waves.vcd
