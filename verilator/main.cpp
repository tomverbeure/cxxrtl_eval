#include <stdlib.h>
#include "Vtb.h"
#include "verilated.h"

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);

    Vtb *tb = new Vtb;

    for(int i=0;i<10000;++i){
        tb->osc_clk = 1;
        tb->eval();
        tb->osc_clk = 0;
        tb->eval();
    } 
    
    exit(EXIT_SUCCESS);
}

