yosys proc.ys
clang++ -g -O3 -std=c++14 -DEXAMPLE_TOP=\"ExampleTop.sim.cpp\" -I `yosys-config --datdir`/include/backends/cxxrtl/runtime/ main.cpp -o example

