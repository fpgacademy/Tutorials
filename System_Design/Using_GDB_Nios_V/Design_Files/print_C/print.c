#include <stdio.h>
#include "address_map.h"

int main(void)
{
    int SW_value, KEY_value;
    volatile unsigned int *SW_ptr = (unsigned int *) SW_BASE;
    volatile unsigned int *KEY_ptr = (unsigned int *) KEY_BASE;
    volatile unsigned int *LEDR_ptr = (unsigned int *) LEDR_BASE;
    
    while ( 1 ){
        SW_value = *SW_ptr;    // read SW values
        *LEDR_ptr = SW_value;  // display on LEDR

        // display on Terminal
        if ((KEY_value = *(KEY_ptr+3)) != 0) {
            *(KEY_ptr+3) = KEY_value;               // clear KEY port
            printf ("SW: 0x%0x\n", SW_value);       // print in hexadecimal
        }
   }
   return 0;
}
