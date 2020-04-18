#include <stdint.h>

#include "reg.h"
#include "top_defines.h"

static inline uint32_t _rdcycle(void) {
    uint32_t cycle;
    asm volatile ("rdcycle %0" : "=r"(cycle));
    return cycle;
}

static inline uint32_t _rdcycleh(void) {
    uint32_t cycle;
    asm volatile ("rdcycleh %0" : "=r"(cycle));
    return cycle;
}

static inline int nop(void) {
    asm volatile ("addi x0, x0, 0");
    return 0;
}

uint64_t rdcycle(void) {

    uint32_t msw;
    uint32_t lsw;

    do{
        msw = _rdcycleh();
        lsw = _rdcycle();
    } while(msw != _rdcycleh());

    return ((uint64_t)msw << 32) | lsw;
}

void wait_cycles(unsigned int cycles)
{
    uint64_t start;

    start = rdcycle();
    while ((rdcycle() - start) <= (uint64_t)cycles);
}


void wait_ms(unsigned int ms)
{
    wait_cycles(CPU_FREQ * (uint64_t)ms / 1000);
}

void wait_us(unsigned int us)
{
    wait_cycles(CPU_FREQ * (uint64_t)us / 1000000);
}
