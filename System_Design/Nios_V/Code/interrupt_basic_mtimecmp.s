# Program that displays a binary counter on LEDR
            .equ    LEDR_BASE, 0xff200000
            .equ    MTIME_BASE, 0xff202100
            .equ    onesecond, 100000000

            .text
            .global _start
_start:     li      sp, 0x40000      # initialize the stack location
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
handler:    addi    sp, sp, -12      # save regs that will be modified
            sw      t2, 8(sp)
            sw      t1, 4(sp)
            sw      t0, (sp)
            
            # check for cause of trap
            csrr    t0, mcause       # read mcause register
            li      t1, 0x80000007   # should have interrupt bit set (0x8...)
                                     # and IRQ = 7 (machine timer interrupt)
stay:       bne     t0, t1, stay     # unexpected cause of exception
            
            # update the timer for the next interrupt cycle
            la      t0, MTIME_BASE
            # read the current time
rloop:      lw      t1, (t0)         # read mtimecmp low
            li      t2, onesecond
            add     t2, t2, t1       # add one second to mtimecmp
            sw      t2, (t0)         # write to mtimecmp low
            sltu    t2, t2, t1       # check for addition overflow

            lw      t1, 4(t0)        # read mtimecmp high
            add     t1, t1, t2       # increment (t2 = 1 if overflow)
            sw      t1, 4(t0)        # write to mtimecmp high

            la      t0, counter      # pointer to counter
            lw      t1, (t0)         # read counter value
            addi    t1, t1, 1        # increment the counter
            sw      t1, (t0)         # store counter to memory

            lw      t0, (sp)         # restore regs
            lw      t1, 4(sp)
            lw      t2, 8(sp)
            addi    sp, sp, 12
            mret

# Set timeout to 1 second
set_timer:  la      t0, MTIME_BASE   # set address
            # read the current time
tloop:      lw      t2, 0xc(t0)      # read mtime high
            lw      t1, 8(t0)        # read mtime low
            lw      t3, 0xc(t0)      # read high again
            bne     t3, t2, tloop    # check for overflow from low to high
            
            # current time is t2:t1
            li      t3, onesecond
            add     t3, t3, t1       # add one second to current time
            sw      t3, (t0)         # write to mtimecmp low
            sltu    t3, t3, t1       # check for addition overflow
            add     t2, t2, t3       # increment (t3 = 1 if overflow)
            sw      t2, 4(t0)        # write to mtimecmp high

            ret
     
            .data
counter:    .word   0                # the counter to be displayed
