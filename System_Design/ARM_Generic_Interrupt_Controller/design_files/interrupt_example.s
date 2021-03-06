/* ********************************************************************************
 * This program demonstrates use of interrupts with assembly language code.
 * The program responds to interrupts from the pushbutton KEY port in the FPGA.
 *
 * The interrupt service routine for the pushbutton KEYs indicates which KEY has
 * been pressed on the HEX0 display.
 ********************************************************************************/

        .section .vectors, "ax" 
        B        _start              // reset vector
        B        SERVICE_UND         // undefined instruction vector
        B        SERVICE_SVC         // software interrrupt vector
        B        SERVICE_ABT_INST    // aborted prefetch vector
        B        SERVICE_ABT_DATA    // aborted data vector
        .word    0                   // unused vector
        B        SERVICE_IRQ         // IRQ interrupt vector
        B        SERVICE_FIQ         // FIQ interrupt vector

        .text        
        .global  _start 
_start:                              
        /* Set up stack pointers for IRQ and SVC processor modes */
        MOV      R1, #0b11010010     // interrupts masked, MODE = IRQ
        MSR      CPSR_c, R1          // change to IRQ mode
        LDR      SP, =0xFFFFFFFF - 3 // set IRQ stack to A9 onchip memory
        /* Change to SVC (supervisor) mode with interrupts disabled */
        MOV      R1, #0b11010011     // interrupts masked, MODE = SVC
        MSR      CPSR, R1            // change to supervisor mode
        LDR      SP, =0x3FFFFFFF - 3 // set SVC stack to top of DDR3 memory

        BL       CONFIG_GIC          // configure the ARM GIC
        /* Write to the pushbutton KEY interrupt mask register */
        LDR      R0, =0xFF200050     // pushbutton KEY base address
        MOV      R1, #0xF            // set interrupt mask bits
        STR      R1, [R0, #0x8]      // interrupt mask register (base + 8)
        /* Enable IRQ interrupts in the processor */
        MOV      R0, #0b01010011     // IRQ unmasked, MODE = SVC
        MSR      CPSR_c, R0          
IDLE:                                
        B        IDLE                // main program simply idles

/* Define the exception service routines */

/*--- Undefined instructions --------------------------------------------------*/
SERVICE_UND:                         
        B        SERVICE_UND         

/*--- Software interrupts -----------------------------------------------------*/
SERVICE_SVC:                         
        B        SERVICE_SVC    
     
/*--- Aborted data reads ------------------------------------------------------*/
SERVICE_ABT_DATA:                    
        B        SERVICE_ABT_DATA  
  
/*--- Aborted instruction fetch -----------------------------------------------*/
SERVICE_ABT_INST:                    
        B        SERVICE_ABT_INST   
 
/*--- IRQ ---------------------------------------------------------------------*/
SERVICE_IRQ:                         
        PUSH     {R0-R7, LR}  
       
        /* Read the ICCIAR from the CPU Interface */
        LDR      R4, =0xFFFEC100     
        LDR      R5, [R4, #0x0C]     // read from ICCIAR

FPGA_IRQ1_HANDLER:                   
        CMP      R5, #73             
UNEXPECTED:                          
        BNE      UNEXPECTED          // if not recognized, stop here

        BL       KEY_ISR             
EXIT_IRQ:                            
        /* Write to the End of Interrupt Register (ICCEOIR) */
        STR      R5, [R4, #0x10]     // write to ICCEOIR

        POP      {R0-R7, LR}         
        SUBS     PC, LR, #4          
/*--- FIQ ---------------------------------------------------------------------*/
SERVICE_FIQ:                         
        B        SERVICE_FIQ         

        .end         
