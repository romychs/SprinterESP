#pragma nonrec

#define port_isa 0x9FBD
#define port_system 0x1FFD
#define isa_addr_base 0xC000
#define com3_addr_base 0x3E8
#define emm_win_p3 0xE2
#define port_serial 0xC3E8

#define RBR port_serial
#define THR port_serial
#define IER port_serial+1
#define IIR port_serial+2
#define FCR port_serial+2
#define LCR port_serial+3
#define MCR port_serial+4
#define LSR port_serial+5
#define MSR port_serial+6
#define SCR port_serial+7
#define DLL port_serial
#define DLM port_serial+1
#define AFR port_serial+2

#define BAUD_RATE 115200
#define XIN_FREQ 14745600
#define DIVISOR XIN_FREQ / (BAUD_RATE * 16)

   
/**
 * Small delay
 */
void delay();

/**
 * Reset ISA device
 */
void reset_isa();

/*
 * Open access to ISA ports as memory
 */
void open_isa();
   
/*
 * Close access to ISA ports
 */
void close_isa();

/*
 *  Init ISA device
 */
void init_isa();

/*
 * Init UART device TL16C550
 */
void init_serial();

/*
 * Read TL16C550 register
 */
char read_reg();

/*
 * Write TL16C550 register
 */
void write_reg();

/*
 * Wait for transmitter ready
 */
void wait_tr();

/*
 * Clear receiver FIFO buffer
 */
void empty_rs();

/*
 * Wait byte in receiver fifo
 */
void wait_rs();

