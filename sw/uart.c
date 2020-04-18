#include <stdint.h>
#include <math.h>

#include "uart.h"

#include "top_defines.h"
#include "reg.h"

void uart_init()
{
    REG_WR(UART_FRAME,   (7 << UART_FRAME_DATA_LENGTH_FIELD_START)
                       | (0 << UART_FRAME_PARITY_FIELD_START)
                       | (0 << UART_FRAME_STOP_FIELD_START));

}

void uart_tx_char(char c)
{
    if (c == '\n'){
        REG_WR(UART_RXTX, '\r');
    }
    REG_WR(UART_RXTX, c);
}

void uart_tx_str(char *str)
{
    while(*str != 0){
        uart_tx_char(*str);
        ++str;
    }
}

void uart_tx_byte(uint8_t b)
{
    unsigned char hex[16] = "0123456789abcdef";

    uart_tx_char(hex[b>>4]);
    uart_tx_char(hex[b&0xf]);
}

void uart_tx_short(uint16_t c)
{
    unsigned char hex[16] = "0123456789abcdef";

    uint8_t b;

    b = (uint8_t)((c>> 8) & 0xff);
    uart_tx_char(hex[b>>4]);
    uart_tx_char(hex[b&0xf]);

    b = (uint8_t)(c & 0xff);
    uart_tx_char(hex[b>>4]);
    uart_tx_char(hex[b&0xf]);

}

void uart_tx_wait_avail(int nr_chars)
{
    while(REG_RD_FIELD(UART_STATUS, TX_AVAIL) < nr_chars);
}

int uart_rx_get_char()
{
    uint32_t rxtx_data = REG_RD(UART_RXTX);

    int has_data = (rxtx_data >> UART_RXTX_RX_HAS_DATA_FIELD_START) & ((1<<(UART_RXTX_RX_HAS_DATA_FIELD_START))-1);

    if (has_data){
        return (rxtx_data >> UART_RXTX_DATA_FIELD_START) & ((1<<(UART_RXTX_DATA_FIELD_LENGTH))-1);
    }
    else{
        return -1;
    }
}


