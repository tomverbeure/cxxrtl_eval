
**RISC-V** (pronounced "risk-five") is a new instruction set architecture (ISA)
that was originally designed to support computer architecture research and education, 
which we now hope will become a standard open architecture for industry implementations. 
RISC-V was originally developed in the Computer Science Division of the EECS Department at
the University of California, Berkeley.

This repository contains an FPGA optimized RISC-V RV32IM core. It is possible
to remove the divide and/or the multiplication to make a RV32I core, or even
to remove the timer instructions to create a RV32E core.


### Performance Numbers (On Altera's Cyclone IV)

|**Core** | **FMAX** | **LUT4s** |
|:--------|:--------:|:---------:|
| RV32E   | 138 MHz | 1700|
| RV32I   | 133.53 MHz  | 1900|
| RV32IM  | 97 MHz | 2500 |
|  RV32IM (sw div) | 101 MHz | 2100 |


For more information on RISC-V see http://riscv.org/
