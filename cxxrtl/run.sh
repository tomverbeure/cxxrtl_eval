#cp ../spinal/*.bin .
#~/tools/yosys/yosys proc.ys
clang++ -g -O3 -std=c++11 -I ~/tools/yosys/ main.cpp -o example

