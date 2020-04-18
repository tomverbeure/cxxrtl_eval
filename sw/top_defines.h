
//============================================================
// Timer
//============================================================

//== TIMER PRESCALER

#define TIMER_PRESCALER_LIMIT_ADDR  0x00000000

#define TIMER_PRESCALER_LIMIT_VALUE_FIELD_START         0
#define TIMER_PRESCALER_LIMIT_VALUE_FIELD_LENGTH        16

//== TIMER IRQ

#define TIMER_IRQ_STATUS_ADDR       0x00000010

#define TIMER_IRQ_STATUS_PENDING_FIELD_START            0
#define TIMER_IRQ_STATUS_PENDING_FIELD_LENGTH           2

#define TIMER_IRQ_MASK_ADDR         0x00000014

#define TIMER_IRQ_MASK_VALUE_FIELD_START                0
#define TIMER_IRQ_MASK_VALUE_FIELD_LENGTH               2

//== TIMERS

#define TIMER_A_CONFIG_ADDR         0x00000040

#define TIMER_A_CONFIG_TICKS_ENABLE_FIELD_START         0
#define TIMER_A_CONFIG_TICKS_ENABLE_FIELD_LENGTH        16

#define TIMER_A_CONFIG_CLEARS_ENABLE_FIELD_START        16
#define TIMER_A_CONFIG_CLEARS_ENABLE_FIELD_LENGTH       16

#define TIMER_A_LIMIT_ADDR          0x00000044

#define TIMER_A_LIMIT_VALUE_FIELD_START                 0
#define TIMER_A_LIMIT_VALUE_FIELD_LENGTH                32

#define TIMER_A_VALUE_ADDR          0x00000048

#define TIMER_A_VALUE_VALUE_FIELD_START                 0
#define TIMER_A_VALUE_VALUE_FIELD_LENGTH                32

#define TIMER_B_CONFIG_ADDR         0x00000050

#define TIMER_B_CONFIG_TICKS_ENABLE_FIELD_START         0
#define TIMER_B_CONFIG_TICKS_ENABLE_FIELD_LENGTH        16

#define TIMER_B_CONFIG_CLEARS_ENABLE_FIELD_START        16
#define TIMER_B_CONFIG_CLEARS_ENABLE_FIELD_LENGTH       16

#define TIMER_B_LIMIT_ADDR          0x00000054

#define TIMER_B_LIMIT_VALUE_FIELD_START                 0
#define TIMER_B_LIMIT_VALUE_FIELD_LENGTH                32

#define TIMER_B_VALUE_ADDR          0x00000058

#define TIMER_B_VALUE_VALUE_FIELD_START                 0
#define TIMER_B_VALUE_VALUE_FIELD_LENGTH                32

//============================================================
// LEDs
//============================================================

#define LED_READ_ADDR               0x00010000
#define LED_WRITE_ADDR              0x00010004
#define	LED_DIR_ADDR                0x00010008

//============================================================
// UART
//============================================================
//
#define UART_RXTX_ADDR              0x00020000

#define UART_RXTX_DATA_FIELD_START                      0
#define UART_RXTX_DATA_FIELD_LENGTH                     8

#define UART_RXTX_RX_HAS_DATA_FIELD_START               16
#define UART_RXTX_RX_HAS_DATA_FIELD_LENGTH              0

#define UART_STATUS_ADDR            0x00020004

#define UART_STATUS_TX_AVAIL_FIELD_START           16
#define UART_STATUS_TX_AVAIL_FIELD_LENGTH          8

#define UART_CLK_DIV_ADDR           0x00020008

#define UART_CLK_DIV_DIVIDER_FIELD_START                0
#define UART_CLK_DIV_DIVIDER_FIELD_LENGTH               16

#define UART_FRAME_ADDR             0x0002000c

#define UART_FRAME_DATA_LENGTH_FIELD_START              0
#define UART_FRAME_DATA_LENGTH_FIELD_LENGTH             3

#define UART_FRAME_PARITY_FIELD_START                   8
#define UART_FRAME_PARITY_FIELD_LENGTH                  2

#define UART_FRAME_STOP_FIELD_START                     16
#define UART_FRAME_STOP_FIELD_LENGTH                    1


