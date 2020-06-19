./yosys proc.ys
clang++-9 -g -O3 -std=c++14 -DEXAMPLE_TOP=\"ExampleTop.sim.cpp\" -I `yosys-config --datdir`/include main.cpp -o example

