#cp ../spinal/*.bin .
./yosys proc.ys
clang++ -g -O3 -std=c++11 -DEXAMPLE_TOP=\"ExampleTop.sim.cpp\" -I ~/tools/yosys/ main.cpp -o example
#g++ -g -O3 -std=c++11 -I ~/tools/yosys/ main.cpp -o example

