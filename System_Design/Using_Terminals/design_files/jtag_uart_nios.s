/********************************************************************************
 * Subroutine to read a character from the JTAG UART
 * r4 = JTAG UART base address
 * Returns the character in r2. Returns \0 if no new character in RX FIFO.
 ********************************************************************************/
        .global GET_CHAR 
GET_CHAR:                            
        /* save any modified registers */
        subi     sp, sp, 8           /* reserve space on the stack */
        stw      r5, 0(sp)           /* save register */
        ldwio    r2, 0(r4)           /* read the JTAG UART Data register */
        andi     r5, r2, 0x8000      /* check if there is new data */
        bne      r5, r0, RETURN_CHAR 
        mov      r2, r0              /* if no new data, return \0 */
RETURN_CHAR:                         
        andi     r5, r2, 0x00ff      /* the data is in the least significant byte */
        mov      r2, r5              /* set r2 with the return value */
        /* restore registers */
        ldw      r5, 0(sp)           
        addi     sp, sp, 8  
         
        ret          
                
/********************************************************************************
 * Subroutine to send a character to the JTAG UART.
 * r4 = JTAG UART base address
 * r5 = character to send
 ********************************************************************************/
        .global PUT_CHAR 
PUT_CHAR:                            
        /* save any modified registers */
        subi     sp, sp, 4           /* reserve space on the stack */
        stw      r6, 0(sp)           /* save register */
        
        ldwio    r6, 4(r4)           /* read the JTAG UART Control register */
        andhi    r6, r6, 0xffff      /* check for write space */
        beq      r6, r0, END_PUT     /* if no space, ignore the character */
        stwio    r5, 0(r4)           /* send the character */
END_PUT:                             
        /* restore registers */
        ldw      r6, 0(sp)           
        addi     sp, sp, 4  
         
        ret                          
