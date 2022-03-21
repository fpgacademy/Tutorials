/********************************************************************************
* Subroutine to read a character from the RS232 UART
* Returns \0 if no character, otherwise returns the character
********************************************************************************/
char get_char(void) {
    volatile int * RS232_UART_ptr = (int *)0xFF201000; // RS232 UART address
    int            data;
    data = *(RS232_UART_ptr); // read the RS232_UART data register
    if (data & 0x00008000)    // check RVALID to see if there is new data
        return ((char)data & 0xFF);
    else
        return ('\0');
}
/********************************************************************************
* Subroutine to send a character to the RS232 UART
********************************************************************************/
void put_char(char c) {
    volatile int * RS232_UART_ptr = (int *)0xFF201000; // RS232 UART address
    int            control;
    control = *(RS232_UART_ptr + 1); // read the RS232_UART control register
    if (control & 0x00FF0000)        // if space, write character, else ignore
        *(RS232_UART_ptr) = c;
}
