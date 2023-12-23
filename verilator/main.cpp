#include <stdlib.h>
#include "Vtb.h"

#if VM_TRACE_VCD==1
#include "verilated_vcd_c.h"
#endif

#if VM_TRACE_FST==1
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
#if VM_TRACE_VCD==1
    VerilatedVcdC *trace;
#endif
#if VM_TRACE_FST==1
    VerilatedFstC *trace;
#endif

#if VM_TRACE_VCD==1 || VM_TRACE_FST==1
    Verilated::traceEverOn(true);
#endif

#if VM_TRACE_VCD==1
    trace = new VerilatedVcdC;
    tb->trace(trace, 99);
    trace->open("waves.vcd");
#endif

#if VM_TRACE_FST==1
    trace = new VerilatedFstC;
    tb->trace(trace, 99);
    trace->open("waves.fst");
#endif

    for(int i=0;i<nr_cycles;++i){
        tb->osc_clk = 1;
        tb->eval();
#if VM_TRACE_VCD==1 || VM_TRACE_FST==1
        trace->dump(i*2);
#endif

        tb->osc_clk = 0;
        tb->eval();

#if VM_TRACE_VCD==1 || VM_TRACE_FST==1
        trace->dump(i*2+1);
#endif

    } 

#if defined(VM_TRACE_VCD) || defined(VM_TRACE_FST)
    trace->flush();
    trace->close();
#endif
    
    exit(EXIT_SUCCESS);
}

