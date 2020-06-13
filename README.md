
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


real	0m0.455s
user	0m0.455s
sys	0m0.000s

real	0m0.455s
user	0m0.455s
sys	0m0.000s

real	0m0.455s
user	0m0.455s
sys	0m0.000s

Verilator - VCD
Verilator 4.033 devel rev v4.032-73-gdef40fa


real	0m7.070s
user	0m3.302s
sys	0m2.137s

real	0m7.892s
user	0m3.585s
sys	0m2.509s

real	0m7.196s
user	0m3.382s
sys	0m2.403s
```

#  CXXRTL - Max Opt

```
CXXRTL - Max Opt - No Waves
Yosys 0.9+2406 (git sha1 dc6961f3, clang 6.0.0-1ubuntu2 -fPIC -Os)


real	0m1.231s
user	0m1.205s
sys	0m0.016s

real	0m1.198s
user	0m1.198s
sys	0m0.000s

real	0m1.193s
user	0m1.193s
sys	0m0.000s

CXXRTL - Max Opt - VCD full (incl Mem)
Yosys 0.9+2406 (git sha1 dc6961f3, clang 6.0.0-1ubuntu2 -fPIC -Os)


real	1m32.535s
user	1m30.890s
sys	0m1.368s

CXXRTL - Max Opt - VCD full (no Mem)
Yosys 0.9+2406 (git sha1 dc6961f3, clang 6.0.0-1ubuntu2 -fPIC -Os)


real	0m7.017s
user	0m5.922s
sys	0m0.972s

CXXRTL - Max Opt - VCD regs only
Yosys 0.9+2406 (git sha1 dc6961f3, clang 6.0.0-1ubuntu2 -fPIC -Os)


real	0m6.704s
user	0m5.728s
sys	0m0.951s
```

## CXXRTL - Max Debug

```
CXXRTL - Max Debug - No Waves
Yosys 0.9+2406 (git sha1 dc6961f3, clang 6.0.0-1ubuntu2 -fPIC -Os)


real	0m1.754s
user	0m1.741s
sys	0m0.004s

real	0m1.754s
user	0m1.750s
sys	0m0.004s

real	0m1.753s
user	0m1.753s
sys	0m0.000s

CXXRTL - Max Debug - VCD full (incl Mem)
Yosys 0.9+2406 (git sha1 dc6961f3, clang 6.0.0-1ubuntu2 -fPIC -Os)


real	1m45.319s
user	1m41.406s
sys	0m3.296s

CXXRTL - Max Debug - VCD full (no Mem)
Yosys 0.9+2406 (git sha1 dc6961f3, clang 6.0.0-1ubuntu2 -fPIC -Os)


real	0m19.562s
user	0m15.900s
sys	0m2.853s

CXXRTL - Max Debug - VCD regs only
Yosys 0.9+2406 (git sha1 dc6961f3, clang 6.0.0-1ubuntu2 -fPIC -Os)


real	0m8.426s
user	0m6.483s
sys	0m1.176s
```

## CXXRTL - Compiler Versions

```
CXXRTL - Max Opt - clang9
Yosys 0.9+2406 (git sha1 dc6961f3, clang 6.0.0-1ubuntu2 -fPIC -Os)


real	0m1.211s
user	0m1.205s
sys	0m0.000s

real	0m1.231s
user	0m1.223s
sys	0m0.008s

real	0m1.224s
user	0m1.223s
sys	0m0.000s

CXXRTL - Max Opt - clang6
Yosys 0.9+2406 (git sha1 dc6961f3, clang 6.0.0-1ubuntu2 -fPIC -Os)


real	0m1.185s
user	0m1.175s
sys	0m0.004s

real	0m1.172s
user	0m1.172s
sys	0m0.000s

real	0m1.166s
user	0m1.162s
sys	0m0.004s

CXXRTL - Max Opt - gcc10.1
Yosys 0.9+2406 (git sha1 dc6961f3, clang 6.0.0-1ubuntu2 -fPIC -Os)


real	0m1.415s
user	0m1.415s
sys	0m0.000s

real	0m1.412s
user	0m1.408s
sys	0m0.004s

real	0m1.413s
user	0m1.409s
sys	0m0.004s

CXXRTL - Max Opt - gcc7.5
Yosys 0.9+2406 (git sha1 dc6961f3, clang 6.0.0-1ubuntu2 -fPIC -Os)


real	0m1.513s
user	0m1.513s
sys	0m0.000s

real	0m1.517s
user	0m1.513s
sys	0m0.004s

real	0m1.517s
user	0m1.513s
sys	0m0.004s
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



