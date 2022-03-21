.include    "nios_macros.s" 
.equ        GREEN_LED_BASE, 0xFF200010           /* Green_LEDs PIO */
.equ        HEX3_HEX0_BASE, 0xFF200020           /* Seven Segment PIO */
.equ        PUSHBUTTON_BASE, 0xFF200050          /* Pushbutton PIO */
.equ        INTERVAL_TIMER_BASE, 0xFF202000      /* Interval Timer */
.equ        stack_end, 0x007FFFFC                /* Initial stack address */
.section    .reset, "ax" 
            br       _start                      /* Upon reset go to start */
.section    .exceptions, "ax" 
/* Interrupt service routine */
            subi     sp, sp, 4                   /* Save registers on */
            stw      r2, 0(sp)                   /* the stack */
            subi     sp, sp, 4                   
            stw      r3, 0(sp)                   
            subi     sp, sp, 4                   
            stw      r4, 0(sp)                   
            subi     sp, sp, 4                   
            stw      ra, 0(sp)                   
            rdctl    et, ctl4                    /* Check if external */
            beq      et, r0, END_ISR             /* interrupt has occurred */
            subi     ea, ea, 4                   /* If yes, decrement ea */
            andi     r4, et, 1                   /* Check if timer irq0 has */
                                                 /* been asserted */
            beq      r4, r0, BUTTONIRQ           /* If not, do not call timer ISR */
            call     TIMERISR                    /* Call timer ISR */
BUTTONIRQ:  andi     r4, et, 2                   /* Check if pushbuttons irq1 */
                                                 /* has been asserted */
            beq      r4, r0, END_ISR             /* If not, end exception */
            movia    r4, PUSHBUTTON_BASE         /* Clear button edge capture */
            addi     r3, r0, 0                   
            stwio    r3, 12(r4)                  
            movia    r11, 0x1                    /* Set start flag to 1 */
END_ISR:    ldw      ra, 0(sp)                   /* Restore registers */
            addi     sp, sp, 4                   /* from the stack */
            ldw      r4, 0(sp)                   
            addi     sp, sp, 4                   
            ldw      r3, 0(sp)                   
            addi     sp, sp, 4                   
            ldw      r2, 0(sp)                   
            addi     sp, sp, 4                   
            eret                                 /* Return from Exception */ 
TIMERISR:   movia    r2, INTERVAL_TIMER_BASE     
            ldwio    r4, 0(r2)                   /* Load status register */
            andi     r4, r4, 1                   
            stwio    r4, 0(r2)                   /* Clear Timeout status */
            addi     r10, r10, 1                 /* Add one to counter value */
            ret                                  
.text        
.global     _start 
_start:     movia    sp, stack_end               /* Initialize the stack pointer */
            addi     r2, r0, 1                   /* Enable the processor to */
            wrctl    ctl0, r2                    /* accept external interrupts */
            addi     r2, r0, 3                   /* Enable irq1 and irq0 */
            wrctl    ctl3, r2                    
            movia    r2, PUSHBUTTON_BASE         /* Setup interrupt */
            addi     r3, r0, 2                   /* mask for push button PIO */
            stbio    r3, 8(r2)                   
            movia    r2, INTERVAL_TIMER_BASE     /* Setup Interval Timer */
            addi     r3, r0, 11                  /* Continous operation */
            stbio    r3, 4(r2)                   /* Timer interrupts are enabled */
            movia    r3, 0xa120                  /* Write Timer Period */
            stwio    r3, 8(r2)                   
            addi     r3, r0, 0x7                 
            stwio    r3, 12(r2)                  
            add      r10, r0, r0                 /* Initialize counter to 0 */
IDLE:       andi     r11, r11, 0x1               /* Check first bit of start flag */
                                                 /* only */
            beq      r11, r0, IDLE               /* Loop if start flag has not */
                                                 /* been set */
NEW_TEST:   andi     r11, r11, 0                 /* Reset start flag */
            addi     r2, r0, 1                   /* Disable IRQ1 interrupt */
            wrctl    ctl3, r2                    
            movia    r2, GREEN_LED_BASE          /* Turn the green */
            stbio    r0, 0(r2)                   /* light off */
            addi     r3, r0, 1                   /* Set the count of the */
            slli     r3, r3, 25                  /* delay loop */
DELAY:      subi     r3, r3, 1                   /* The delay loop */
            bgt      r3, r0, DELAY               
            addi     r3, r0, 1                   /* Turn the green */
            stbio    r3, 0(r2)                   /* light on */
            movia    r2, INTERVAL_TIMER_BASE     
            addi     r10, r0, 0                  /* Clear timer count value */
            movia    r3, 0xa120                  /* Reset timer */
            stwio    r3, 8(r2)                   
            addi     r3, r0, 0x7                 
            stwio    r3, 12(r2)                  
            addi     r3, r0, 0x7                 /* Start counter */
            stwio    r3, 4(r2)                   
            movia    r2, PUSHBUTTON_BASE         
WAIT:       ldbio    r3, 0(r2)                   /* Check if the Stop key */
            ble      r3, r0, WAIT                /* has been pressed */
            movia    r2, INTERVAL_TIMER_BASE     
            addi     r3, r0, 8                   /* Stop the timer */
            stbio    r3, 4(r2)                   
            movia    r2, GREEN_LED_BASE          /* Turn the green */
            stbio    r0, 0(r2)                   /* LED off */
            call     DECIMAL                     /* Prepare the 4-digit */
            call     DISPLAY                     /* decimal display */
            addi     r2, r0, 3                   /* Enable irq1 and irq0 */
            wrctl    ctl3, r2                    /* (Interval Timer and */
                                                 /* Pushbutton) */
            br       IDLE                        
DECIMAL:    add      r4, r0, r0                  
            addi     r5, r0, 8                   
            addi     r2, r0, 4                   
            addi     r6, r0, 10                  
LOOP:       divu     r7, r10, r6                 /* Divide by 10 */
            mul      r8, r7, r6                  
            sub      r8, r10, r8                 /* Remainder is in r8 */
            ldb      r9, PATTERN(r8)             /* The decoded hex display */
            or       r4, r4, r9                  /* dig is placed into proper */
            ror      r4, r4, r5                  /* position of the 4-digit */
                                                 /* display. */
            add      r10, r7, r0                 
            subi     r2, r2, 1                   
            bgt      r2, r0, LOOP                
            ret                                  
DISPLAY:    movia    r2, HEX3_HEX0_BASE          /* Display the 4-digit */
            stwio    r4, 0(r2)                   /* reaction time */
            ret                                  

PATTERN:         
/* Translation table */                                
.byte       0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F 
.end         
