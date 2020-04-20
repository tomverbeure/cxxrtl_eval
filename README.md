
# Yosys CXXRTL simulation backend (YoSim?) Benchmark

This project compares the simulation speed of the following open source simulations:

* Icarus Verilog
* Verilator
* Yosys CXXRTL

## Prepare Verilog

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
real	0m0.027s
user	0m0.024s
sys	0m0.004s
```

## cxxrtl
```
cd cxxrtl
./run.sh
time ./example
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

Result:
```
real	0m0.063s
user	0m0.059s
sys	0m0.004s
```


