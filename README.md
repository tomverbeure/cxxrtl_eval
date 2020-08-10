
**NOTE: These results are still very much in flux as CXXRTL is under heavy development!**

# Yosys CXXRTL simulation backend (Yosim?) Benchmark

This project compares the simulation speed of the following open source simulators:

* Icarus Verilog (11.0)
* Verilator (rev 4.033)
* Yosys CXXRTL (version listed with results.)

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

Result (for 100K clock cycles):
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
user	0m0.452s
sys	0m0.004s

real	0m0.456s
user	0m0.456s
sys	0m0.000s

real	0m0.456s
user	0m0.456s
sys	0m0.000s

Verilator - VCD
Verilator 4.033 devel rev v4.032-73-gdef40fa


real	0m9.381s
user	0m3.371s
sys	0m2.406s

real	0m7.503s
user	0m3.484s
sys	0m2.447s

real	0m7.078s
user	0m3.421s
sys	0m2.521s
```

##  CXXRTL - Max Opt

```
CXXRTL - Max Opt - No Waves
Yosys 0.9+2406 (git sha1 334ec5fa, clang 6.0.0-1ubuntu2 -fPIC -Os)


real	0m1.473s
user	0m1.472s
sys	0m0.000s

real	0m1.470s
user	0m1.469s
sys	0m0.000s

real	0m1.472s
user	0m1.467s
sys	0m0.004s

CXXRTL - Max Opt - VCD full (incl Mem)
Yosys 0.9+2406 (git sha1 334ec5fa, clang 6.0.0-1ubuntu2 -fPIC -Os)


real	1m34.634s
user	1m32.743s
sys	0m1.759s

CXXRTL - Max Opt - VCD full (no Mem)
Yosys 0.9+2406 (git sha1 334ec5fa, clang 6.0.0-1ubuntu2 -fPIC -Os)


real	0m9.158s
user	0m7.337s
sys	0m1.170s

CXXRTL - Max Opt - VCD regs only
Yosys 0.9+2406 (git sha1 334ec5fa, clang 6.0.0-1ubuntu2 -fPIC -Os)


real	0m8.517s
user	0m6.740s
sys	0m1.146s
```

## CXXRTL - Max Debug

```
CXXRTL - Max Debug - No Waves
Yosys 0.9+2406 (git sha1 334ec5fa, clang 6.0.0-1ubuntu2 -fPIC -Os)


real	0m2.474s
user	0m2.384s
sys	0m0.008s

real	0m2.382s
user	0m2.381s
sys	0m0.000s

real	0m2.373s
user	0m2.371s
sys	0m0.000s

CXXRTL - Max Debug - VCD full (incl Mem)
Yosys 0.9+2406 (git sha1 334ec5fa, clang 6.0.0-1ubuntu2 -fPIC -Os)


real	2m3.533s
user	1m58.238s
sys	0m4.685s

CXXRTL - Max Debug - VCD full (no Mem)
Yosys 0.9+2406 (git sha1 334ec5fa, clang 6.0.0-1ubuntu2 -fPIC -Os)


real	0m39.661s
user	0m33.152s
sys	0m5.129s

CXXRTL - Max Debug - VCD regs only
Yosys 0.9+2406 (git sha1 334ec5fa, clang 6.0.0-1ubuntu2 -fPIC -Os)


real	0m10.470s
user	0m7.970s
sys	0m1.659s
```

## CXXRTL - Compiler Versions

```
CXXRTL - Max Opt - clang9
Yosys 0.9+2406 (git sha1 334ec5fa, clang 6.0.0-1ubuntu2 -fPIC -Os)


real	0m1.488s
user	0m1.474s
sys	0m0.012s

real	0m1.473s
user	0m1.472s
sys	0m0.000s

real	0m1.461s
user	0m1.457s
sys	0m0.004s

CXXRTL - Max Opt - clang6
Yosys 0.9+2406 (git sha1 334ec5fa, clang 6.0.0-1ubuntu2 -fPIC -Os)


real	0m1.455s
user	0m1.444s
sys	0m0.004s

real	0m1.450s
user	0m1.445s
sys	0m0.004s

real	0m1.447s
user	0m1.446s
sys	0m0.000s

CXXRTL - Max Opt - gcc10.1
Yosys 0.9+2406 (git sha1 334ec5fa, clang 6.0.0-1ubuntu2 -fPIC -Os)


real	0m1.736s
user	0m1.729s
sys	0m0.000s

real	0m1.726s
user	0m1.717s
sys	0m0.008s

real	0m1.727s
user	0m1.726s
sys	0m0.000s

CXXRTL - Max Opt - gcc7.5
Yosys 0.9+2406 (git sha1 334ec5fa, clang 6.0.0-1ubuntu2 -fPIC -Os)


real	0m1.688s
user	0m1.678s
sys	0m0.004s

real	0m1.678s
user	0m1.677s
sys	0m0.000s

real	0m1.674s
user	0m1.673s
sys	0m0.000s
```

## CXXRTL Recipe

At the time of writing this, the cxxrtl optimization recipe was as follows:
```
read_verilog ../spinal/ExampleTop.sim.v
hierarchy -check -top ExampleTop
write_ilang ExampleTop.sim.ilang
write_cxxrtl ExampleTop.sim.cpp
```

# Verilator Compile Time

```
real	0m3.671s
user	0m3.221s
sys	0m0.138s
```

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

```



