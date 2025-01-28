#include "address_map_niosv.h" 
#include "globals.h" 

extern void handler (void);
void set_mtimer(void);
void set_itimer(void);
void set_KEY(void);

/* Global variables are written by interrupt service routines; we declare
 * as volatile to avoid the compiler caching their values in registers */
volatile int counter = 0;    // binary counter to be displayed
volatile int digit = 0;      // decimal digit to be displayed
volatile int KEY_dir = 1;    // digit counter direction
// 7-segment codes for digits 0, 1, ..., 9
char bit_codes[] = {0x3f, 0x06, 0x5b, 0x4f, 0x66, 
    0x6d, 0x7d, 0x07, 0x7f, 0x67};

/***************************************************************************
 * This program demonstrates use of interrupts with assembly code. It first
 * sets up interrupts from three devices: the Nios V machine timer, an FPGA 
 * interval timer, and the pushbutton KEY port. Next, the program makes a 
 * software interrupt occur. Finally, the program loops while responding to 
 * interrupts from the timers and the pushbutton KEY port. 
 *
 * The interrupt service routine for the software interrupt turns on most
 * of the red lights in the LEDR port. 
 *
 * The interrupt service routine for the Nios V machine timer causes the
 * main program to display a binary counter that increments every 1/4 second
 * on the LEDR red lights.
 *
 * The interrupt service routine for the interval timer causes the main 
 * program to display a decimal counter on HEX0. The counter either 
 * increases or decreases once per second, in the range 0 to 9. When a KEY 
 * is pressed, the direction of counting on HEX0 is reversed. 
*****************************************************************************/
int main(void) {
    /* Declare volatile pointers to I/O registers (volatile means that the
     * accesses will always go to the memory (I/O) address */
    volatile int *mtime_ptr = (int *) MTIME_BASE;
    volatile int *LEDR_ptr = (int *) LEDR_BASE;
    volatile int *HEX3_HEX0_ptr = (int *) HEX3_HEX0_BASE;

    set_mtimer();
    set_itimer();
    set_KEY();

    int mstatus_value, mtvec_value, mie_value;
    mstatus_value = 0b1000;   // interrupt bit mask
    // disable interrupts
    __asm__ volatile ("csrc mstatus, %0" :: "r"(mstatus_value));
    mtvec_value  = (int) &handler; // set trap address
    __asm__ volatile ("csrw mtvec, %0" :: "r"(mtvec_value));
    // disable all interrupts that are currently enabled
    __asm__ volatile ("csrr %0, mie" : "=r"(mie_value));
    __asm__ volatile ("csrc mie, %0" :: "r"(mie_value));
    mie_value = 0x50088; // KEY, itimer, mtimer, SW interrupts
    // set interrupt enables
    __asm__ volatile ("csrs mie, %0" :: "r"(mie_value));
    // enable Nios V interrupts
    __asm__ volatile ("csrs mstatus, %0" :: "r"(mstatus_value));

    *(mtime_ptr + 4) = 1;   // cause a software interrupt

    *HEX3_HEX0_ptr = 0x3f;  // show 0 on HEX0

    while (1) {
        *LEDR_ptr = counter;
        *HEX3_HEX0_ptr = bit_codes[digit]; // display in decimal
    }
}

// Configure the Nios V machine timer
void set_mtimer(void){
    volatile int *mtime_ptr = (int *) MTIME_BASE;
    unsigned int mtime_h, mtime_l, carry, mtimecmp_l;
    do {
        mtime_h = *(mtime_ptr + 1);         // read mtime high word
        mtime_l = *(mtime_ptr + 0);         // read mtime low word
    } while (*(mtime_ptr + 1) != mtime_h);
    mtimecmp_l = mtime_l + quarter_second;  // add to current time
    carry = mtimecmp_l < mtime_l ? 1 : 0;   // check for carry-out
    *(mtime_ptr + 2) = mtimecmp_l;          // set mtimecmp low word
    *(mtime_ptr + 3) = mtime_h + carry;     // set mtimecmp high word
}

// Configure the FPGA interval timer
void set_itimer(void){
    volatile int *timer_ptr = (int *) TIMER_BASE;
    // set the interval timer period
    int load_val = one_second;
    *(timer_ptr + 0x2) = (load_val & 0xFFFF);
    *(timer_ptr + 0x3) = (load_val >> 16) & 0xFFFF;

    // start interval timer, enable its interrupts
    *(timer_ptr + 1) = 0x7; // STOP = 1, START = 1, CONT = 1, ITO = 1
}

// Configure the KEY port
void set_KEY(void){
    volatile int *KEY_ptr = (int *) KEY_BASE;
    *(KEY_ptr + 3) = 0xF; // clear EdgeCapture register
    *(KEY_ptr + 2) = 0xF; // enable interrupts for all KEYs
}
