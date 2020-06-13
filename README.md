
**NOTE: These results are still very much in flux as CXXRTL is under heavy development!**

# Yosys CXXRTL simulation backend (Yosim?) Benchmark

This project compares the simulation speed of the following open source simulators:

* Icarus Verilog (11.0)
* Verilator (rev 4.033)
* Yosys CXXRTL (version listed with results.)

The test design is a VexRiscv CPU with some RAM and some LEDs that are toggling.

I run the simulation for 1M clock cycles, except on Icarus Verilog where I only do 100K. It's just too slow...

I use the following Yosys optimization recipe: 

```
YOSYS_RECIPE  = "proc; flatten; clean; splitnets -driver; clean -purge"
```

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
Verilator - No Waves
Verilator 4.033 devel rev v4.032-73-gdef40fa


real	0m0.456s
user	0m0.456s
sys	0m0.000s

real	0m0.455s
user	0m0.451s
sys	0m0.004s

real	0m0.456s
user	0m0.456s
sys	0m0.000s

Verilator - VCD
Verilator 4.033 devel rev v4.032-73-gdef40fa


real	0m7.059s
user	0m3.452s
sys	0m2.016s

real	0m7.369s
user	0m3.393s
sys	0m2.364s

real	0m7.074s
user	0m3.511s
sys	0m2.242s
```

##  CXXRTL - Max Opt

```
CXXRTL - Max Opt - No Waves
Yosys 0.9+2406 (git sha1 971a7651, clang 6.0.0-1ubuntu2 -fPIC -Os)


real	0m1.117s
user	0m1.113s
sys	0m0.004s

real	0m1.116s
user	0m1.116s
sys	0m0.000s

real	0m1.113s
user	0m1.113s
sys	0m0.000s

CXXRTL - Max Opt - VCD full (incl Mem)
Yosys 0.9+2406 (git sha1 971a7651, clang 6.0.0-1ubuntu2 -fPIC -Os)


real	1m30.976s
user	1m29.215s
sys	0m1.148s

CXXRTL - Max Opt - VCD full (no Mem)
Yosys 0.9+2406 (git sha1 971a7651, clang 6.0.0-1ubuntu2 -fPIC -Os)


real	0m6.772s
user	0m5.732s
sys	0m0.767s

CXXRTL - Max Opt - VCD regs only
Yosys 0.9+2406 (git sha1 971a7651, clang 6.0.0-1ubuntu2 -fPIC -Os)


real	0m7.341s
user	0m5.551s
sys	0m0.839s
```

## CXXRTL - Max Debug

```
CXXRTL - Max Debug - No Waves
Yosys 0.9+2406 (git sha1 971a7651, clang 6.0.0-1ubuntu2 -fPIC -Os)


real	0m1.636s
user	0m1.608s
sys	0m0.000s

real	0m1.601s
user	0m1.597s
sys	0m0.004s

real	0m1.601s
user	0m1.589s
sys	0m0.012s

CXXRTL - Max Debug - VCD full (incl Mem)
Yosys 0.9+2406 (git sha1 971a7651, clang 6.0.0-1ubuntu2 -fPIC -Os)


real	1m45.124s
user	1m40.406s
sys	0m3.476s

CXXRTL - Max Debug - VCD full (no Mem)
Yosys 0.9+2406 (git sha1 971a7651, clang 6.0.0-1ubuntu2 -fPIC -Os)


real	0m18.731s
user	0m15.848s
sys	0m2.090s

CXXRTL - Max Debug - VCD regs only
Yosys 0.9+2406 (git sha1 971a7651, clang 6.0.0-1ubuntu2 -fPIC -Os)


real	0m8.480s
user	0m6.409s
sys	0m0.734s
```

## CXXRTL - Compiler Versions

```
CXXRTL - Max Opt - clang9
Yosys 0.9+2406 (git sha1 971a7651, clang 6.0.0-1ubuntu2 -fPIC -Os)


real	0m1.119s
user	0m1.119s
sys	0m0.000s

real	0m1.116s
user	0m1.116s
sys	0m0.000s

real	0m1.114s
user	0m1.114s
sys	0m0.000s

CXXRTL - Max Opt - clang6
Yosys 0.9+2406 (git sha1 971a7651, clang 6.0.0-1ubuntu2 -fPIC -Os)


real	0m1.116s
user	0m1.107s
sys	0m0.004s

real	0m1.111s
user	0m1.103s
sys	0m0.008s

real	0m1.114s
user	0m1.114s
sys	0m0.000s

CXXRTL - Max Opt - gcc10.1
Yosys 0.9+2406 (git sha1 971a7651, clang 6.0.0-1ubuntu2 -fPIC -Os)


real	0m1.328s
user	0m1.315s
sys	0m0.008s

real	0m1.320s
user	0m1.316s
sys	0m0.004s

real	0m1.320s
user	0m1.320s
sys	0m0.000s

CXXRTL - Max Opt - gcc7.5
Yosys 0.9+2406 (git sha1 971a7651, clang 6.0.0-1ubuntu2 -fPIC -Os)


real	0m1.350s
user	0m1.345s
sys	0m0.000s

real	0m1.344s
user	0m1.340s
sys	0m0.004s

real	0m1.346s
user	0m1.346s
sys	0m0.000s
```

## CXXRTL Recipe

At the time of writing this, the cxxrtl optimization recipe was as follows:
```
read_verilog ../spinal/ExampleTop.sim.v
hierarchy -check -top ExampleTop
proc; flatten; clean; splitnets -driver; clean -purge
write_ilang ExampleTop.sim.ilang
write_cxxrtl ExampleTop.sim.cpp
```

# Verilator Compile Time

real	0m3.671s
user	0m3.221s
sys	0m0.138s


## CXXRTL Compile Time

clang9 not only gives the best simulation results, but it also compiles
must faster than anything else.

```
Compile time example_default_clang9

real	0m7.321s
user	0m6.976s
sys	0m0.183s


Compile time example_Og_clang9

real	0m9.195s
user	0m9.020s
sys	0m0.142s


Compile time example_default_clang6

real	0m17.038s
user	0m16.562s
sys	0m0.181s


Compile time example_default_gcc10

real	0m32.420s
user	0m31.701s
sys	0m0.497s


Compile time example_default_gcc7

real	0m19.918s
user	0m19.277s
sys	0m0.425s


Compile time example_default_clang6_inline

real	0m48.867s
user	0m48.450s
sys	0m0.381s


Compile time example_default_clang9_inline

real	0m56.930s
user	0m56.328s
sys	0m0.521s


Compile time example_Og_clang9_inline

real	8m23.285s
user	8m18.564s
sys	0m2.349s
```



