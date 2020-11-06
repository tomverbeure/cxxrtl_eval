#!usr/bin/tclsh8.4

# tcl flow script for iCEcube2
#############################################
# User Configurable section
#############################################
set device iCE5LP4K-SWG36
set top_module top
set proj_dir [pwd]
set output_dir "ice40ultra_Implmnt"
set edif_file "ice40ultra"
set sdc_constraints "constraints/lve_timing.sdc"
set pcf_constraints "constraints/lve_pcf_sbt.pcf"
set scf_constraints "$output_dir/ice40ultra.scf"

#The SCF file (created by synthesis from SDC) should work, but was
#causing PLL output clocks to be ignored.  Using SDC directly
#instead.
set tool_options ":edifparser -y $pcf_constraints"

###########################################
# Tool Interface
############################################
set ::env(SBT_DIR) ${::env(ICECUBE2)}/sbt_backend
set sbt_root ${::env(SBT_DIR)}

append sbt_tcl $sbt_root "/tcl/sbt_backend_synpl.tcl"
source $sbt_tcl


#Parse command line arguments, currently if non-zero then run interactive
if {$::argc == 2} {
    set mem_file_name [lindex $::argv 0]
    set list_file_name [lindex $::argv 1]
    set sp_list_file_name [lindex $::argv 1]
    if {![file exists $mem_file_name]} {
		  puts "Argument 0 should be memory file to initialize from; \"$mem_file_name\" doesn't exist."
		  exit -1
    } elseif {![file exists $list_file_name]} {
		  puts "Argument 1 should be memory list file; \"$list_file_name\" doesn't exist."
		  exit -1
    } else {
		  puts "Initializing memory from memory file $mem_file_name and list file $list_file_name."
		  set list_file [open $list_file_name]
		  set list_file_lines [read $list_file]
		  close $list_file
		  foreach list_line [split $list_file_lines "\n" ] {
				set file_start [expr [string last " " $list_line] + 1]
				if {$file_start < 1} {
					continue
				}
				set file_name [string range $list_line $file_start [expr [string length $list_line] - 1]]
				lappend ram_file_names $file_name
		  }
		  puts "Initializing memory files: $ram_file_names"

		  foreach ram_file_name $ram_file_names {
				lappend ram_contents "0:"
		#		set ram_file_name [lindex $ram_file_names $i]
				if {[file exists $ram_file_name]} {
					 file delete $ram_file_name
				}
				set ram_file [open $ram_file_name "w"]
				lappend ram_files $ram_file
				puts -nonewline $ram_file "0:"
		  }
		  set mem_file [open $mem_file_name "r"]
		  set line_number 1
		  while {[gets $mem_file mem_line] != -1 && $line_number < 2048} {
				if {[string length $mem_line] >= 8 && [string range $mem_line 0 0] != "#"} {
					 for {set i 0} {$i < 8} {incr i} {
						  set hex_value [expr 0x[string range $mem_line $i $i]]
						  puts -nonewline [lindex $ram_files [expr 2 * $i]] "[expr ($hex_value / 4) % 4]  "
						  puts -nonewline [lindex $ram_files [expr (2 * $i) + 1]] "[expr $hex_value % 4]  "
					 }
				}
				incr line_number
		  }
		  for {set i 0} {$i < 16} {incr i} {
				set ram_file [lindex $ram_files $i]
				puts $ram_file ""
				close $ram_file
		  }
		  while {[gets $mem_file mem_line] != -1} {
				if {[string length $mem_line] >= 8 && [string range $mem_line 0 0] != "#"} {
					 for {set i 0} {$i < 4} {incr i} {
						  set hex_value [expr 0x[string range $mem_line [expr 2 * $i] [expr 2 * $i]]]
						  set hex_value2 [expr 0x[string range $mem_line [expr 2 * $i + 1] [expr 2 * $i + 1]]]
						  puts -nonewline [lindex $ram_files [expr 16 + (3 * $i)]] "[format %01X [expr ($hex_value >> 1)]]  "
						  puts -nonewline [lindex $ram_files [expr 16 + (3 * $i) + 1]] "[format %01X [expr (($hex_value << 3) | ($hex_value2 >> 1)) & 0xF]]  "
						  puts -nonewline [lindex $ram_files [expr 16 + (3 * $i) + 2]] "[format %01X [expr ($hex_value2 & 0x1)]]  "
					 }
				}
		  }

    }
} elseif {$::argc == 1} {
    puts "One arguments passed, regenerating bits."
    sbt_init_env
    sbt_run_bitmap $top_module $device $output_dir $tool_options
} elseif {$::argc == 0} {
    puts "No arguments passed, running full backend."
    run_sbt_backend_auto $device $top_module $proj_dir $output_dir $tool_options $edif_file
} else {
    puts "Run with no arguments for full backend, 1 to regenerate ibts, 2 arguments for memory initialization."
    exit -1
}

exit
