#ifndef TIMER_H
#define TIMER_H

#include <stdint.h>

void timer_prescaler_config(int prescaler_div);
void timer_a_config(int limit, int ticks_ena);
void timer_b_config(int limit, int ticks_ena);
uint32_t timer_irq_pending();
void timer_irq_clr(int bits);
void timer_irq_config(int mask);



#endif
