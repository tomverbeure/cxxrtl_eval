
**NOTE: These results are under review. Treat with care!**

# Yosys CXXRTL simulation backend (Yosim?) Benchmark

This project compares the simulation speed of the following open source simulators:

* Icarus Verilog (11.0)
* Verilator (rev 4.033)
* Yosys CXXRTL (b651352, 20200526)

I don't use any optimization settings for Yosys. It uses to be that CXXRTL performed often significantly better
after all kinds of optimization, but that doesn't seem to be the case anymore.

The test design is a VexRiscv CPU with some RAM and some LEDs that are toggling.

I run the simulation for 1M clock cycles, except on Icarus Verilog where I only do 100K. It's just too slow...

## Prepare Verilog

(This is optional: the generated Verilog and .bin files are part of the repo.)

```
cd sw
make
cd ../spinal
make sim
```

## Icarus Verilog

```
cd tb
make tb
time ./tb
```

Result:
```
...
real	0m26.389s
user	0m26.313s
sys	0m0.061s
```

## Verilator
```
cd verilator
./build.sh
time ./tb
```

Result:
```
real	0m0.551s
user	0m0.527s
sys	0m0.024s
```

## CXXRTL
```
cd cxxrtl
ln -s `which yosys` yosys
./build.sh
time ./example
```

Result:
```
real	0m5.314s
user	0m5.290s
sys	0m0.025s
```

At the time of writing this, the cxxrtl recipe was as follows:
```
read_verilog ../spinal/ExampleTop.sim.v
hierarchy -check -top ExampleTop
write_ilang ExampleTop.sim.ilang
write_cxxrtl ExampleTop.sim.cpp
```



