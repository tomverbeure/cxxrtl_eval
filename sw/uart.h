#ifndef UART_H
#define UART_H


void uart_init();

void uart_tx_char(char c);
void uart_tx_str(char *str);
void uart_tx_byte(uint8_t b);
void uart_tx_short(uint16_t b);
void uart_tx_wait_avail(int nr_chars);

int  uart_rx_get_char();

#endif
