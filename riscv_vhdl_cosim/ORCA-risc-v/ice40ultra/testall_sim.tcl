do simulate.tcl

set files [lsort [glob ./test/*.mem]]

foreach f $files {
	 file copy -force $f test.mem
	 restart -f
	 onbreak {resume}
	 when {sim:/top_tb/dut/rv/coe_to_host /= x"00000000" } {stop}
	 run 2000 us
	 set v [examine -decimal sim:/top_tb/dut/rv/coe_to_host]
	 puts "$f = $v"
}

exit -f;
