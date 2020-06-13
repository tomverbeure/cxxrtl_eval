./yosys proc.ys
#clang++-9 -g -O3 -mllvm -inline-threshold=999999 -std=c++14 -DEXAMPLE_TOP=\"ExampleTop.sim.cpp\" -I ~/tools/yosys/ main.cpp -o example
clang++-9 -g -O3 -std=c++14 -DEXAMPLE_TOP=\"ExampleTop.sim.cpp\" -I ~/tools/yosys/ main.cpp -o example

