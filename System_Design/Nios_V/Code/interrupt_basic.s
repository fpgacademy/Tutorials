# Program that displays a binary counter on LEDR
.equ LEDR_BASE, 0xff200000
.equ MTIME_BASE, 0xff202100
.equ onesecond, 100000000

.global _start
_start:     li      sp, 0x20000      # initialize the stack location
            jal     set_timer        # initialize the timer
     
            # Set handler address, enable interrupts
            la      t0, handler
            csrw    mtvec, t0        # set trap address
            li      t0, 0b10000000   # set the enable pattern
            csrs    mie, t0          # enable timer interrupts
            csrsi   mstatus, 0x8     # enable global interrupts

            la      s0, counter      # pointer to counter
            la      s1, LEDR_BASE    # pointer to red lights
            sw      zero, (s1)       # turn off all lights
loop:       wfi
            lw      t0, (s0)         # load the counter value
            sw      t0, (s1)         # write to the lights
            j       loop

# Trap handler
handler:    addi    sp, sp, -8       # save regs that will be modified
            sw      t1, 4(sp)
            sw      t0, (sp)
            
            # check for cause of trap
            csrr    t0, mcause       # read mcause register
            li      t1, 0x80000007   # should have interrupt bit set (0x8...)
                                     # and IRQ = 7 (machine timer interrupt)
stay:       bne     t0, t1, stay     # unexpected cause of exception
            
            # Restart the timer
            la      t0, MTIME_BASE
            sw      zero, 8(t0)      # reset mtime low
            sw      zero, 0xc(t0)    # reset mtime high

            la      t0, counter      # pointer to counter
            lw      t1, (t0)         # read counter value
            addi    t1, t1, 1        # increment the counter
            sw      t1, (t0)         # store counter to memory

            lw      t0, (sp)         # restore regs
            lw      t1, 4(sp)
            addi    sp, sp, 8
            mret

# Set timeout to 1 second
set_timer:  la      t0, MTIME_BASE   # set address
            sw      zero, 8(t0)      # reset lower word of mtime
            sw      zero, 0xc(t0)    # reset upper word of mtime
            
            li      t1, onesecond
            sw      t1, (t0)         # set mtimecmp low word
            sw      zero, 4(t0)      # set mtimecmp upper word
            ret
     
counter:    .word   0                # the counter to be displayed
