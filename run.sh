export TOP=`pwd`

rm $TOP/results.txt

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

cd $TOP/verilator
./build.sh

echo >> $TOP/results.txt
echo "Verilator" >> $TOP/results.txt
echo >> $TOP/results.txt

(time ./tb) 2>> $TOP/results.txt


############################################################
# CXXRTL
############################################################

cd $TOP/cxxrtl

# Exclude 20200419: incompatible .h file
#ln -s ~/tools/yosys/yosys-20200419 ./yosys
#./build.sh
#
#echo >> $TOP/results.txt
#echo "CXXRTL 20200419" >> $TOP/results.txt
#echo >> $TOP/results.txt
#
#(time ./tb) 2>> $TOP/results.txt


#------------------------------------------------------------
#rm ./yosys
#ln -s ~/tools/yosys/yosys-20200422a ./yosys
#./build.sh
#
#echo >> $TOP/results.txt
#echo "CXXRTL 20200422a" >> $TOP/results.txt
#echo >> $TOP/results.txt
#
#(time ./example) 2>> $TOP/results.txt

#------------------------------------------------------------
#rm ./yosys
#ln -s ~/tools/yosys/yosys-20200422b ./yosys
#./build.sh
#
#echo >> $TOP/results.txt
#echo "CXXRTL 20200422b" >> $TOP/results.txt
#echo >> $TOP/results.txt
#
#(time ./example) 2>> $TOP/results.txt

#------------------------------------------------------------
rm ./yosys
ln -s ~/tools/yosys/yosys-20200526 ./yosys
./build.sh

echo >> $TOP/results.txt
echo "CXXRTL 20200526" >> $TOP/results.txt
echo >> $TOP/results.txt

(time ./example) 2>> $TOP/results.txt


