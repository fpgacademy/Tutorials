/*
 * Configure the Generic Interrupt Controller (GIC)
 */
        .global CONFIG_GIC 
CONFIG_GIC:                          
        PUSH     {LR}                
        /* To configure the FPGA KEYS interrupt (ID 73):
         * 1. set the target to cpu0 in the ICDIPTRn register
         * 2. enable the interrupt in the ICDISERn register */
        /* CONFIG_INTERRUPT (int_ID (R0), CPU_target (R1)); */
        MOV      R0, #73             // KEY port (Interrupt ID = 73)
        MOV      R1, #1              // this field is a bit-mask; bit 0 targets cpu0
        BL       CONFIG_INTERRUPT    

        /* configure the GIC CPU Interface */
        LDR      R0, =0xFFFEC100     // base address of CPU Interface
        /* Set Interrupt Priority Mask Register (ICCPMR) */
        LDR      R1, =0xFFFF         // enable interrupts of all priorities levels
        STR      R1, [R0, #0x04]     
        /* Set the enable bit in the CPU Interface Control Register (ICCICR).
         * This allows interrupts to be forwarded to the CPU(s) */
        MOV      R1, #1              
        STR      R1, [R0]            

        /* Set the enable bit in the Distributor Control Register (ICDDCR).
         * This enables forwarding of interrupts to the CPU Interface(s) */
        LDR      R0, =0xFFFED000     
        STR      R1, [R0]            

        POP      {PC}                

/*
 * Configure registers in the GIC for an individual Interrupt ID
 * We configure only the Interrupt Set Enable Registers (ICDISERn) and
 * Interrupt Processor Target Registers (ICDIPTRn). The default (reset)
 * values are used for other registers in the GIC
 * Arguments: R0 = Interrupt ID (N), R1 = CPU target
 */
CONFIG_INTERRUPT:                    
        PUSH     {R4-R5, LR}       
  
        /* Configure Interrupt Set-Enable Registers (ICDISERn).
         * reg_offset = (integer_div(N / 32) * 4
         * value = 1 << (N mod 32) */
        LSR      R4, R0, #3          // calculate reg_offset
        BIC      R4, R4, #3          // R4 = reg_offset
        LDR      R2, =0xFFFED100     
        ADD      R4, R2, R4          // R4 = address of ICDISER

        AND      R2, R0, #0x1F       // N mod 32
        MOV      R5, #1              // enable
        LSL      R2, R5, R2          // R2 = value

        /* Using the register address in R4 and the value in R2 set the
         * correct bit in the GIC register */
        LDR      R3, [R4]            // read current register value
        ORR      R3, R3, R2          // set the enable bit
        STR      R3, [R4]            // store the new register value

        /* Configure Interrupt Processor Targets Register (ICDIPTRn)
         * reg_offset = integer_div(N / 4) * 4
         * index = N mod 4 */
        BIC      R4, R0, #3          // R4 = reg_offset
        LDR      R2, =0xFFFED800     
        ADD      R4, R2, R4          // R4 = word address of ICDIPTR
        AND      R2, R0, #0x3        // N mod 4
        ADD      R4, R2, R4          // R4 = byte address in ICDIPTR

        /* Using register address in R4 and the value in R2 write to
         * (only) the appropriate byte */
        STRB     R1, [R4]       
     
        POP      {R4-R5, PC}         
