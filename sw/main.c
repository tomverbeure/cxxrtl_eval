#include <stdint.h>
#include <math.h>

#include "lib.h"
#include "reg.h"
#include "top_defines.h"
#include "uart.h"
#include "timer.h"
#include "riscv.h"

void externalInterrupt()
{
/*
	uint32_t claim;
	//While there is pending interrupts
	while(claim = plic_claim(PLIC, PLIC_CPU_0)){
		switch(claim){
		case PLIC_I2C_INTERRUPT: externalInterrupt_i2c(); break;
		default: crash(); break;
		}
		plic_release(PLIC, PLIC_CPU_0, claim); //unmask the claimed interrupt
	}
*/

}

void crash(){
	while(1);
}

void trap()
{
    //timer_irq_clr(0xff);

	int32_t mcause = csr_read(mcause);
	int32_t interrupt   = mcause < 0;	//Interrupt if set, exception if cleared
	int32_t cause	    = mcause & 0xF;
	if(interrupt){

		switch(cause){
		    case CAUSE_MACHINE_EXTERNAL: externalInterrupt(); break;
		    default: crash(); break;
		}
	} 
	else {
		crash();
	}
}



int main() 
{
    // Enable global interrupt: set MIE bit in MSTATUS
    csr_set(mstatus, MSTATUS_MPP | MSTATUS_MIE);        // FIXME: what is MPP?

    // Enable timer interrupt
    //csr_set(mie, MIE_MTIE);

    // Enable external interrupt
    csr_set(mie, MIE_MEIE);

    REG_WR(LED_DIR, 0xff);
    for(int i=0;i<10;++i){
        REG_WR(LED_WRITE, 0x01);
        wait_cycles(100);
        REG_WR(LED_WRITE, 0x02);
        wait_cycles(100);
        REG_WR(LED_WRITE, 0x04);
        wait_cycles(100);
    }

    uart_init();
    uart_tx_str("\nHello World!\n");


    while(1);
}
