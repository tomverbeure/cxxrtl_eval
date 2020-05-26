
**NOTE: These results are no more representative. A number of optimizations have been made since I ran the benchmark.**

# Yosys CXXRTL simulation backend (Yosim?) Benchmark

This project compares the simulation speed of the following open source simulators:

* Icarus Verilog (11.0)
* Verilator (rev 4.033)
* Yosys CXXRTL

The CXXRTL simulation backend is absolutely bleeding edge: it was merged in the the Yosys master on April 10th,
just 9 days after runnings these first test, and a bunch of bug fixes and additional features were added during
those 9 days. 

There's also no standard Yosys recipe yet for best results: I just played around to come up with what ran fastest
on my test design, which is a VexRiscv CPU with some RAM and some LEDs that are toggling.

Still, the simulation time is around 5x the simulation time of a single threaded Verilator simulation, which has
seen 20 years of optimizations.

It's going to be fun to play with this.

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
real	0m2.706s
user	0m2.695s
sys	0m0.008s
```

## Verilator
```
cd verilator
./run.sh
time ./tb
```

Result:
```
real	0m0.013s
user	0m0.013s
sys	0m0.000s
```

## CXXRTL
```
cd cxxrtl
./run.sh
time ./example
```

Result:
```
real	0m0.063s
user	0m0.059s
sys	0m0.004s
```

At the time of writing this, the cxxrtl recipe was as follows:
```
read_verilog ../spinal/ExampleTop.sim.v
hierarchy -check -top ExampleTop
proc
flatten
opt
write_ilang ExampleTop.sim.ilang
write_cxxrtl ExampleTop.sim.cpp
```



