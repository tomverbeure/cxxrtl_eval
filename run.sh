export TOP=`pwd`

rm $TOP/results.txt
touch $TOP/results.txt

#cd $TOP/sw
#make clean
#make
#cd $TOP/spinal
#make sim

############################################################
# Icarus Verilog
############################################################

#cd $TOP/tb
#make clean
#make tb
#echo >> $TOP/results.txt
#echo "Icarus Verilog" >> $TOP/results.txt
#echo >> $TOP/results.txt
#(time ./tb) &>> $TOP/results.txt


############################################################
# Verilator
############################################################

echo "Verilator..."
echo "## Verilator" >> $TOP/results.txt
echo >> $TOP/results.txt
echo "\`\`\`" >> $TOP/results.txt

cd $TOP/verilator
make tb

echo "Verilator - No Waves"
echo "Verilator - No Waves" >> $TOP/results.txt
verilator --version >> $TOP/results.txt
echo >> $TOP/results.txt

(time ./tb) 2>> $TOP/results.txt > /dev/null
(time ./tb) 2>> $TOP/results.txt > /dev/null
(time ./tb) 2>> $TOP/results.txt > /dev/null


cd $TOP/verilator
make tb_vcd

echo >> $TOP/results.txt
echo "Verilator - VCD"
echo "Verilator - VCD" >> $TOP/results.txt
verilator --version >> $TOP/results.txt
echo >> $TOP/results.txt

(time ./tb_vcd) 2>> $TOP/results.txt > /dev/null
(time ./tb_vcd) 2>> $TOP/results.txt > /dev/null
(time ./tb_vcd) 2>> $TOP/results.txt > /dev/null

echo "\`\`\`" >> $TOP/results.txt
echo >> $TOP/results.txt
############################################################
# CXXRTL - Build simulators
############################################################

#cd $TOP/cxxrtl
#ln -s ~/tools/yosys/yosys-20200612 ./yosys
#make compile

############################################################
# CXXRTL - Max Opt
############################################################

echo "CXXRTL - Max Opt..."
echo "##  CXXRTL - Max Opt" >> $TOP/results.txt

echo >> $TOP/results.txt
echo "\`\`\`" >> $TOP/results.txt

cd $TOP/cxxrtl

echo "CXXRTL - Max Opt - No Waves"
echo "CXXRTL - Max Opt - No Waves" >> $TOP/results.txt
./yosys --version >> $TOP/results.txt
echo >> $TOP/results.txt

(time ./example_default_clang9) 2>> $TOP/results.txt > /dev/null
(time ./example_default_clang9) 2>> $TOP/results.txt > /dev/null
(time ./example_default_clang9) 2>> $TOP/results.txt > /dev/null

echo >> $TOP/results.txt
echo "CXXRTL - Max Opt - VCD full (incl Mem)"
echo "CXXRTL - Max Opt - VCD full (incl Mem)" >> $TOP/results.txt
./yosys --version >> $TOP/results.txt
echo >> $TOP/results.txt

(time ./example_default_clang9 1 waves_full_incl_mem.vcd) 2>> $TOP/results.txt > /dev/null

echo >> $TOP/results.txt
echo "CXXRTL - Max Opt - VCD full (no Mem)"
echo "CXXRTL - Max Opt - VCD full (no Mem)" >> $TOP/results.txt
./yosys --version >> $TOP/results.txt
echo >> $TOP/results.txt

(time ./example_default_clang9 2 waves_full_no_mem.vcd) 2>> $TOP/results.txt > /dev/null

echo >> $TOP/results.txt
echo "CXXRTL - Max Opt - VCD regs only"
echo "CXXRTL - Max Opt - VCD regs only" >> $TOP/results.txt
./yosys --version >> $TOP/results.txt
echo >> $TOP/results.txt

(time ./example_default_clang9 3 waves_regs_only.vcd) 2>> $TOP/results.txt > /dev/null

echo "\`\`\`" >> $TOP/results.txt
echo >> $TOP/results.txt

############################################################
# CXXRTL - Max Debug
############################################################

echo "CXXRTL - Max Debug"
echo "## CXXRTL - Max Debug" >> $TOP/results.txt

echo >> $TOP/results.txt
echo "\`\`\`" >> $TOP/results.txt

cd $TOP/cxxrtl

echo "CXXRTL - Max Debug - No Waves"
echo "CXXRTL - Max Debug - No Waves" >> $TOP/results.txt
./yosys --version >> $TOP/results.txt
echo >> $TOP/results.txt

(time ./example_Og_clang9) 2>> $TOP/results.txt > /dev/null
(time ./example_Og_clang9) 2>> $TOP/results.txt > /dev/null
(time ./example_Og_clang9) 2>> $TOP/results.txt > /dev/null

echo >> $TOP/results.txt
echo "CXXRTL - Max Debug - VCD full (incl Mem)"
echo "CXXRTL - Max Debug - VCD full (incl Mem)" >> $TOP/results.txt
./yosys --version >> $TOP/results.txt
echo >> $TOP/results.txt

(time ./example_Og_clang9 1 waves_full_incl_mem.vcd) 2>> $TOP/results.txt > /dev/null

echo >> $TOP/results.txt
echo "CXXRTL - Max Debug - VCD full (no Mem)"
echo "CXXRTL - Max Debug - VCD full (no Mem)" >> $TOP/results.txt
./yosys --version >> $TOP/results.txt
echo >> $TOP/results.txt

(time ./example_Og_clang9 2 waves_full_no_mem.vcd) 2>> $TOP/results.txt > /dev/null

echo >> $TOP/results.txt
echo "CXXRTL - Max Debug - VCD regs only"
echo "CXXRTL - Max Debug - VCD regs only" >> $TOP/results.txt
./yosys --version >> $TOP/results.txt
echo >> $TOP/results.txt

(time ./example_Og_clang9 3 waves_regs_only.vcd) 2>> $TOP/results.txt > /dev/null

echo "\`\`\`" >> $TOP/results.txt
echo >> $TOP/results.txt

############################################################
# CXXRTL - Compiler Versions
############################################################

echo "CXXRTL - Compiler Versions"
echo "## CXXRTL - Compiler Versions" >> $TOP/results.txt

echo >> $TOP/results.txt
echo "\`\`\`" >> $TOP/results.txt

cd $TOP/cxxrtl

echo >> $TOP/results.txt
echo "CXXRTL - Max Opt - clang9"
echo "CXXRTL - Max Opt - clang9" >> $TOP/results.txt
./yosys --version >> $TOP/results.txt
echo >> $TOP/results.txt

(time ./example_default_clang9) 2>> $TOP/results.txt > /dev/null
(time ./example_default_clang9) 2>> $TOP/results.txt > /dev/null
(time ./example_default_clang9) 2>> $TOP/results.txt > /dev/null

echo >> $TOP/results.txt
echo "CXXRTL - Max Opt - clang6"
echo "CXXRTL - Max Opt - clang6" >> $TOP/results.txt
./yosys --version >> $TOP/results.txt
echo >> $TOP/results.txt

(time ./example_default_clang6) 2>> $TOP/results.txt > /dev/null
(time ./example_default_clang6) 2>> $TOP/results.txt > /dev/null
(time ./example_default_clang6) 2>> $TOP/results.txt > /dev/null

echo >> $TOP/results.txt
echo "CXXRTL - Max Opt - gcc10.1"
echo "CXXRTL - Max Opt - gcc10.1" >> $TOP/results.txt
./yosys --version >> $TOP/results.txt
echo >> $TOP/results.txt

(time ./example_default_gcc10) 2>> $TOP/results.txt > /dev/null
(time ./example_default_gcc10) 2>> $TOP/results.txt > /dev/null
(time ./example_default_gcc10) 2>> $TOP/results.txt > /dev/null

echo >> $TOP/results.txt
echo "CXXRTL - Max Opt - gcc7.5"
echo "CXXRTL - Max Opt - gcc7.5" >> $TOP/results.txt
./yosys --version >> $TOP/results.txt
echo >> $TOP/results.txt

(time ./example_default_gcc7) 2>> $TOP/results.txt > /dev/null
(time ./example_default_gcc7) 2>> $TOP/results.txt > /dev/null
(time ./example_default_gcc7) 2>> $TOP/results.txt > /dev/null

echo "\`\`\`" >> $TOP/results.txt

