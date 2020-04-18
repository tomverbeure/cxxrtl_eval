#ifndef LIB_H
#define LIB_H

uint64_t rdcycle(void);
void wait_cycles(unsigned int cycles);
void wait_ms(unsigned int ms);
void wait_us(unsigned int us);

#endif
