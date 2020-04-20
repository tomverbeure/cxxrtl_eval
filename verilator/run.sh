
rm -fr obj_dir
verilator -CFLAGS "-g -O3" -Wno-fatal -cc tb.v ../spinal/ExampleTop.sim.v 
cd obj_dir
make -f Vtb.mk
cd ..
g++ -std=c++11 -g -O3 -I/opt/verilator/share/verilator/include/ -I/opt/verilator/share/verilator/include/vltstd -Iobj_dir main.cpp /opt/verilator/share/verilator/include/verilated.cpp ./obj_dir/Vtb__ALL.a -o tb
cp ../spinal/*.bin .
