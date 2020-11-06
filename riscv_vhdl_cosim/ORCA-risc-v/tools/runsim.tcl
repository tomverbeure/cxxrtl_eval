cd vblox1/simulation/mentor
do msim_setup.tcl
ld
add wave -position insertpoint  sim:/vblox1/riscv_0/coe_to_host
add wave -position insertpoint  sim:/vblox1/riscv_0/clk
add wave -position insertpoint  sim:/vblox1/riscv_0/reset
add wave -position insertpoint  sim:/vblox1/riscv_0/coe_program_counter
add wave -noupdate -divider decode
add wave -position insertpoint  sim:/vblox1/riscv_0/D/register_file_1/registers(28)
add wave -noupdate -divider Execute
add wave -position insertpoint  sim:/vblox1/riscv_0/X/valid_input
add wave -position insertpoint sim:/vblox1/riscv_0/X/pc_current
set DefaultRadix hex
log -r /*
