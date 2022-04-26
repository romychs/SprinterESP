#pragma nonrec

#include <stdio.h>
#include <conio.h>
#include <dos.h>

unsigned port;
char b;
char save_mmu3;

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
  
/*
 #define BAUD_RATE 115200
 #define XIN_FREQ 14745600
 #define DIVISOR XIN_FREQ / (BAUD_RATE * 16)
*/
   
/**
 * Small delay
 */
delay() {
   unsigned ctr;
   for (ctr=0; ctr<2000; ctr++) {
   }
}

/**
 * Reset ISA device
 */
reset_isa() {
   outp(port_isa, 0xc0); // RESET=1 AEN=1
   delay();
   outp(port_isa,0); // RESET=0 AEN=0
   delay();
   delay();
}

/*
 * Open access to ISA ports as memory
 */
open_isa() {
   save_mmu3 = inp(emm_win_p3);
   outp(port_system, 0x11);
   outp(emm_win_p3, 0xd4);
   outp(port_isa, 0);
}                              
   
/*
 * Close access to ISA ports
 */
close_isa() {
   outp(port_system, 0x01);
   outp(emm_win_p3, save_mmu3);
}

/*
 *  Init ISA device
 */
init_isa() {
   reset_isa();    // just only reset
}            

unsigned addr;
char lcr;
char *ptr;

/*
 * Init UART device TL16C550
 */
init_serial() {
   open_isa(); 
   mset(FCR, 0x01);  // 8 byte FIFO buffer
   mset(FCR, 0x81);
   mset(IER, 0x00);  // Disable interrupts

   mset(LCR, 0x83);  // enable Baud rate latch
   mset(DLL, 0x08);  // 8 - 115200;
   mset(DLM, 0x00);

   mset(LCR, 0x03);  // dis Baud rate latch & 8N1
   
   // reset ESP
   mset(MCR, 0x06); // ESP -PGM=1, -RTS=0
   delay();
   mset(MCR, 0x02); // ESP -RST=1, -RTS=0
   delay();
   close_isa();
}
   
char read_reg(reg)
unsigned reg;
{  
   char rb;
   open_isa();
   rb = mget(reg);
   close_isa();
   return rb;
}   


void write_reg(reg, b)
unsigned reg;
char b;
{
   open_isa();
   mset(reg, b);
   close_isa();
}

char *scr_ptr = SCR;

void write_sr(b)
char b;
{
   open_isa();
   *scr_ptr = b;
   close_isa();
}              

char read_sr() {
   char rb;
   open_isa();
   rb = *scr_ptr;
   close_isa();
   return rb;
}

void wait_tr() {
   unsigned w;
   char ls;
   w = 0;
   ls = read_reg(LSR);
   while ((ls & 0x20) == 0 && w<100) {
     delay(20);
     ls = read_reg(LSR);
     w++;
   }
}              

/*
 * Empty receiver FIFO buffer
 */
void empty_rs() {
   open_isa();
   mset(FCR, 0x83);
   close_isa();
}                            

/*
 * Wait byte in receiver fifo
 */
void wait_rs() {
   unsigned w;
   char ls;
   w = 0;
   ls = read_reg(LSR);
   while ((ls & 0x01) == 0 && w<1000) {
     delay();
     ls = read_reg(LSR);
     w++;
   }
}

char tb;
char rr;
unsigned ctr;
unsigned r;

char* buff = "AT+GMR\r\n\0";
char* tbuf;
char rbuf[1024];

main() {
    char ok;

    printf("\nInit ISA\n");
    	
    init_isa();
    
    printf("\nInit serial\n");
    init_serial();
    
    r = port_serial;
    rr = 0;
    for (ctr=0; ctr<=7; ctr++) {
      tb = read_reg(r);
      printf("REG["); hex8(rr);
      printf("]="); hex8(tb);
      printf("\n");
      r++;
      rr++;
    }     
                      
    r = port_serial; 
    rr = 0;
    write_reg(LCR,0x83);
    for (ctr=0; ctr<3; ctr++) {
       tb = read_reg(r);
       printf("REG[1"); 
       hex8(rr);
       printf("]="); 
       hex8(tb);
       printf("\n");
       r++;   
       rr++;
    }
    write_reg(LCR,0x03);
                 
   // Wait ESP reload

   for (ctr=0; ctr<400; ctr++) {
     delay();
   }                  
   
   printf("\nClear receiver buffer");
   empty_rs();

   printf("\nGet version\n");

   tbuf = buff;
   while (*tbuf != '\0') {
      wait_tr();
      tb = read_reg(LSR);
      if ((tb & 0x20) == 0) {
         printf(".TXNR.");
      } else {
         write_reg(THR, *tbuf++);
      }
   }

   ctr = 0;
   r = 0;
   ok = 0;

   disable();
   open_isa();
   do {
      rr = mget(LSR);
      if ((rr & 0x80) != 0) {
         close_isa();
         printf("\nReceiver error:");
         rr = (rr>>1) & 0x07;
         hex8(rr);  
         break;
      } else {
         if ((rr & 0x01) == 1) {
            tb = mget(RBR);
            rbuf[ctr++] = tb;
            if (ok == 0 && tb == 'O') {
              ok = 1;
            }
            if (ok == 1 && tb == 'K') {
              ok = 2;
            } else {
              ok = 0;
            }
            r = 0;
         } else {
            r++;
         }
      }
   } while (ok<2 && r<10000 && ctr<1024);
   enable();
   close_isa();                 

   printf("\nctr="); dec16(ctr);
   printf("\nr="); dec16(r);

   printf("\nReceived:\n");
   printf(rbuf);

}



