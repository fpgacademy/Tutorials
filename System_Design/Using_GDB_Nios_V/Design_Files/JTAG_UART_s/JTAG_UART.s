.include    "address_map_niosv.s" 

/******************************************************************************
 * This program demonstrates use of the JTAG UART port
 *
 * It performs the following:
 *  1. sends a text string to the JTAG UART
 * 	2. reads character data from the JTAG UART
 * 	3. echos the character data back to the JTAG UART
 *****************************************************************************/

.global _start 
_start:                             
        la      s0, JTAG_UART_BASE  # JTAG UART base address

/* print a text string */
        la      s1, TEXT_STRING     
LOOP:                               
        lb      a0, 0(s1)           
        beqz    a0, GET_JTAG        # string is null-terminated
        jal     PUT_JTAG            
        addi    s1, s1, 1           
        j       LOOP                

/* read and echo characters */
GET_JTAG:                           
        lw      t0, 0(s0)           # read the JTAG UART data register
        li      t1, 0x8000
        and     t1, t1, t0          # check if there is new data
        beqz    t1, GET_JTAG        # if no data, wait
        andi    a0, t0, 0x00ff      # the data is in the least significant byte

        li      t2, 0xD             # carriage return (CR) ASCII code
        bne     a0, t2, SHOW
        jal     PUT_JTAG            # put CR followed by line feed (LF)
        li      a0, 0xA             # LF ASCII code
SHOW:   jal     PUT_JTAG            # echo character
        j       GET_JTAG            

/******************************************************************************
 * Subroutine to send a character to the JTAG UART
 *		a0	= character to send
 *		s0	= JTAG UART base address
 *****************************************************************************/
.global PUT_JTAG 
PUT_JTAG:                           
/* save any modified registers */
        lw      t0, 4(s0)           # read the JTAG UART control register
        lui     t1, 0xffff0         # t1 = 0xffff0000
        and     t0, t0, t1          # check for write space
        beqz    t0, END_PUT         # if no space, ignore the character
        sw      a0, 0(s0)           # send the character

END_PUT:                            
        ret                         

/*****************************************************************************/

TEXT_STRING:                        
        .asciz  "\nJTAG UART example code\n> " 
