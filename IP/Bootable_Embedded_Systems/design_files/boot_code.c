/* This program sweeps a green light back and forth on the LEDG lights */
enum DIR { LEFT, RIGHT };
void sweep(int *, enum DIR *);

int main(void) {
    volatile int * LEDG_ptr  = (int *)0x10000010; // green LED address
    volatile int * timer_ptr = (int *)0x10002000; // interval timer address

    int      LEDG_bits = 1;    // pattern for the green lights
    enum DIR shift_dir = LEFT; // pattern shifting direction

    /* set the interval timer period */
    int counter      = 0x190000; // 1/(50 MHz) x 0x190000 = 33 msec
    *(timer_ptr + 2) = (counter & 0xFFFF);
    *(timer_ptr + 3) = (counter >> 16) & 0xFFFF;

    *(timer_ptr + 1) = 0x6; // START = 1, CONT = 1, ITO = 0

    while (1) {
        *LEDG_ptr = LEDG_bits;         // write to the green lights
        sweep(&LEDG_bits, &shift_dir); // shift the pattern left or right

        while ((*timer_ptr & 0x1) == 0)
            ;           // wait for timeout
        *timer_ptr = 0; // reset the timeout bit
    }
}

/* shift the pattern shown on the LEDs */
void sweep(int * pattern, enum DIR * dir) {
    if (*dir == LEFT)
        if (*pattern & 0x80)
            *dir = RIGHT;
        else
            *pattern = *pattern << 1;
    else if (*pattern & 0x01)
        *dir = LEFT;
    else
        *pattern = *pattern >> 1;
}
