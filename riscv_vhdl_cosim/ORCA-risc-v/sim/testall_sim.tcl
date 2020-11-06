cd vblox1/simulation/mentor
do msim_setup.tcl
ld
add wave -position insertpoint  sim:/vblox1/riscv_0/coe_to_host

set files [lsort [glob ../../../test/*.gex]]

foreach f $files {
	 file copy -force $f test.hex
	 restart -f
	 onbreak {resume}
	 when {sim:/vblox1/riscv_0/coe_to_host /= x"00000000" } {stop}
	 run 2000 ns
	 set v [examine -decimal sim:/vblox1/riscv_0/coe_to_host]
	 puts "$f = $v"
}

exit -f;
