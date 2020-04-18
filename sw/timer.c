#include <stdint.h>

#include "reg.h"
#include "top_defines.h"
#include "timer.h"

void timer_prescaler_config(int prescaler_div)
{
    REG_WR(TIMER_PRESCALER_LIMIT, prescaler_div);
}

void timer_a_config(int limit, int ticks_ena)
{
    REG_WR(TIMER_A_LIMIT, limit);
    REG_WR_FIELD(TIMER_A_CONFIG, TICKS_ENABLE, ticks_ena);
}

void timer_b_config(int limit, int ticks_ena)
{
    REG_WR(TIMER_B_LIMIT, limit);
    REG_WR_FIELD(TIMER_B_CONFIG, TICKS_ENABLE, ticks_ena);
}

uint32_t timer_irq_pending()
{
    return REG_RD(TIMER_IRQ_STATUS);
}


void timer_irq_clr(int bits)
{
    REG_WR(TIMER_IRQ_STATUS, bits);
}


void timer_irq_config(int mask)
{
    REG_WR(TIMER_IRQ_MASK, mask);
}

