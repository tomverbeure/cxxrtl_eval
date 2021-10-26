#include <stdlib.h>
#include "Vtb.h"

#ifdef TRACE_VCD
#include "verilated_vcd_c.h"
#endif

#ifdef TRACE_FST
#include "verilated_fst_c.h"
#endif

#include "verilated.h"

int main(int argc, char **argv) 
{
    Verilated::commandArgs(argc, argv);

    int nr_cycles = 1000000;
    if (argc ==2)
        nr_cycles = atoi(argv[1]);

    Vtb *tb = new Vtb;
#if defined(TRACE_VCD)
    VerilatedVcdC *trace;
#endif
#if defined(TRACE_FST)
    VerilatedFstC *trace;
#endif

#if defined(TRACE_VCD) || defined(TRACE_FST)
    Verilated::traceEverOn(true);
#endif

#if defined(TRACE_VCD)
    trace = new VerilatedVcdC;
    tb->trace(trace, 99);
    trace->open("waves.vcd");
#endif

#if defined(TRACE_FST)
    trace = new VerilatedFstC;
    tb->trace(trace, 99);
    trace->open("waves.fst");
#endif

    for(int i=0;i<nr_cycles;++i){
        tb->osc_clk = 1;
        tb->eval();
#if defined(TRACE_VCD) || defined(TRACE_FST)
        trace->dump(i*2);
#endif

        tb->osc_clk = 0;
        tb->eval();

#if defined(TRACE_VCD) || defined(TRACE_FST)
        trace->dump(i*2+1);
    trace->flush();
#endif

    } 

#if defined(TRACE_VCD) || defined(TRACE_FST)
    trace->flush();
    trace->close();
#endif
    
    exit(EXIT_SUCCESS);
}

