#include "address_map_niosv.h" 
#include "globals.h" 

extern void handler(void) __attribute__ ((interrupt ("machine")));
void SWI_ISR(void);
void mtimer_ISR(void);
void itimer_ISR(void);
void KEY_ISR(void);

extern volatile int counter;    // binary counter to be displayed
extern volatile int digit;      // decimal digit to be displayed
extern volatile int KEY_dir;    // digit counter direction
                                //
/*******************************************************************
 * Trap handler: determine what caused the interrupt and calls the 
 *  appropriate subroutine.
 ******************************************************************/
void handler (void){
    int mcause_value;
    __asm__ volatile ("csrr %0, mcause" : "=r"(mcause_value));
    if (mcause_value == 0x80000003) // software interrupt
        SWI_ISR();
    else if (mcause_value == 0x80000007) // machine timer
        mtimer_ISR();
    else if (mcause_value == 0x80000010) // interval timer
        itimer_ISR();
    else if (mcause_value == 0x80000012) // KEY port
        KEY_ISR();
    // else, ignore the trap
}

// Software interrupt service routine
void SWI_ISR(void){
    volatile int *mtime_ptr = (int *) MTIME_BASE;
    counter = 0b1111111100; // set global variable
    *(mtime_ptr + 4) = 0;   // clear interrupt
}

// Nios V machine timer interrupt service routine
typedef long long int64;

void mtimer_ISR(void){
    volatile unsigned int *mtime_ptr = (unsigned int *) MTIME_BASE;
    int64 mtimecmp64;
    mtimecmp64 = *(mtime_ptr + 3);  // read high word of 64-bit register
    mtimecmp64 = (mtimecmp64 << 32) | *(mtime_ptr + 2);     // read low word
    mtimecmp64 = mtimecmp64 + (int64) quarter_second;       // adjust timeout
    *(mtime_ptr + 2)  = (unsigned int) mtimecmp64;          // store low word
    *(mtime_ptr + 3)  = (unsigned int) (mtimecmp64 >> 32);  // store high word
    counter = counter + 1;
}

// FPGA interval timer interrupt service routine
void itimer_ISR(void){
    int new_digit;
    volatile int * timer_ptr = (int *) TIMER_BASE;
    *timer_ptr = 0; // clear the interrupt
    new_digit = digit + KEY_dir;    // inc/dec the digit
    if (new_digit < 10 && new_digit > -1)
        digit = new_digit;  // decimal (0 to 9)
}

// KEY port interrupt service routine
void KEY_ISR(void){
    int pressed;
    volatile int *KEY_ptr = (int *) KEY_BASE;
    pressed = *(KEY_ptr + 3);  // read EdgeCapture
    *(KEY_ptr + 3) = pressed;  // clear EdgeCapture register
    KEY_dir = -KEY_dir;        // reverse counting direction
}


