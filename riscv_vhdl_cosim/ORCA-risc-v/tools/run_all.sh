DATE=$(date +%x%T)

#task 1: creating a new sof with new program in it
#task 2: download and test that sof
#thes tasks can be done in parallel


#clear $! (pid of last background task)
:&
for i in test/*.gex
do

	 cp $i test.hex
	 quartus_cdb --update_mif vblox1.qpf
	 quartus_asm vblox1.qpf
	 wait $!
	 quartus_pgm -m JTAG -o P\;output_files/vblox1.sof
	 (
		  echo -n "$i =" | tee -a "test_results$DATE.txt"
		  k=$(system-console --script=system_console.tcl | grep to_host | sed 's/to_host=\(.*\)/\1/')
		  echo " $k" | tee -a "test_results$DATE.txt"
	 ) &
done
wait $!
