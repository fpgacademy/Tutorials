#include "address_map.h"

// display SW values on LEDR, and in hexadecimal on HEX3-0
char seg7[]= {0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07,
             0x7F, 0x67, 0x77, 0x7C, 0x39, 0x5E, 0x79, 0x71};

int main(void)
{
    int value;
    volatile unsigned int *SW_ptr = (unsigned int *) SW_BASE;
    volatile unsigned int *LEDR_ptr = (unsigned int *) LEDR_BASE;
    volatile unsigned int *HEX3_HEX0_ptr = (unsigned int *) HEX3_HEX0_BASE;
    
    while ( 1 ){
        value = *SW_ptr;    // read SW values
        *LEDR_ptr = value;  // display on LEDR

        // display on 7-segs
        *HEX3_HEX0_ptr = seg7[value & 0xF] | 
            seg7[value >> 4 & 0xF] << 8 |
            seg7[value >> 8] << 16;
   }
   return 0;
}
