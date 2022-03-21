/********************************************************************************
 * Subroutine to get a character from the RS232 UART
 * R1 = RS232 UART base address
 * Returns the character read in R0
 ********************************************************************************/
        .global GET_CHAR 
GET_CHAR:                        
        LDR      R0, [R1]        // read the RS232 UART data register
        ANDS     R2, R0, #0x8000 // check if there is new data
        BNE      RETURN_CHAR     
        MOV      R0, #0          // if no data, return \0
RETURN_CHAR:                     
        AND      R0, R0, #0x00FF // return the character
        BX       LR  
            
/********************************************************************************
 * Subroutine to send a character to the RS232 UART
 * R0 = character to send
 * R1 = RS232 UART base address
 ********************************************************************************/
        .global PUT_CHAR 
PUT_CHAR:                        
        LDR      R2, [R1, #4]    // read the RS232 UART control register
        LDR      R3, =0x00FF0000 
        ANDS     R2, R2, R3      // check for write space
        BEQ      END_PUT         // if no space, ignore the character
        STR      R0, [R1]        // send the character
END_PUT:                         
        BX       LR              
