# Program that displays a binary counter on LEDR
.equ LEDR_BASE, 0xff200000
.equ MTIME_BASE, 0xff202100
.equ onesecond, 100000000

.global _start
_start:     li      sp, 0x40000      # initialize the stack location
            # Set timeout to 1 second
            jal     set_timer        # initialize the timer 
     
            # Set handler address, enable interrupts
            la      t0, handler
            ori     t0, t0, 0b1      # set vector mode
            csrw    mtvec, t0        # set trap address and mode
            li      t0, 0b10001000   # set the enable pattern
            csrs    mie, t0          # enable timer & software interrupts
            csrsi   mstatus, 0x8     # enable global interrupts

            # Make a software interrupt happen
            la      t0, MTIME_BASE   # base address
            li      t1, 1            # pattern to write to msip
            sw      t1, 0x10(t0)     # write to msip (sw interrupt)

            la      s0, counter      # pointer to counter
            la      s1, LEDR_BASE    # pointer to red lights
loop:       wfi
            lw      t0, (s0)         # load the counter value
            sw      t0, (s1)         # write to the lights
            j       loop

# Trap handler
handler:    j       exception
            .org    handler + 3 * 4  # IRQ 3: software interrupt
            j       IRQ_3
            .org    handler + 7 * 4  # IRQ 7: timer interrupt
            j       IRQ_7

exception:  j       exception        # not handled in this code
            
# software interrupt handler
IRQ_3:      addi    sp, sp, -8       # save regs that will be modified
            sw      t1, 4(sp)
            sw      t0, (sp)

            la      t0, counter      # pointer to red lights
            li      t1, 0b1111111110
            sw      t1, (t0)         # write to the counter
            la      t0, MTIME_BASE   # base address
            sw      zero, 0x10(t0)   # clear software interrupt in msip

            lw      t0, (sp)         # restore regs
            lw      t1, 4(sp)
            addi    sp, sp, 8
            mret

# timer interrupt handler
IRQ_7:      addi    sp, sp, -8       # save regs that will be modified
            sw      t1, 4(sp)
            sw      t0, (sp)
            
            # Restart the timer
            la      t0, MTIME_BASE
            sw      zero, 8(t0)      # write to mtime

            la      t0, counter      # pointer to counter
            lw      t1, (t0)         # read counter value
            addi    t1, t1, 1        # increment the counter
            sw      t1, (t0)         # store counter to memory

            lw      t0, (sp)         # restore regs
            lw      t1, 4(sp)
            addi    sp, sp, 8
            mret

set_timer:  la      t0, MTIME_BASE   # set address
            sw      zero, 8(t0)      # reset lower word of the timer
            sw      zero, 0xc(t0)    # reset upper word
            
            li      t1, onesecond
            sw      t1, (t0)         # set mtimecmp lower word
            sw      zero, 4(t0)      # set upper word
            ret

counter:    .word   0                # the counter to be displayed
