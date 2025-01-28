# Program that displays a binary counter on LEDR
.include "address_map_niosv.s"

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
loop:       lw      t0, (s0)         # load the counter value
            sw      t0, (s1)         # write to the lights
            j       loop

# Set timeout to 1 second
set_timer:  la      t0, MTIME_BASE   # set address
            sw      zero, 0(t0)      # reset mtime lower word
            sw      zero, 4(t0)      # reset mtime upper word
            
            li      t1, clock_rate
            sw      t1, 8(t0)        # set mtimecmp low word
            sw      zero, 12(t0)     # set mtimecmp upper word
            ret

.global counter
counter:    .word   0                # the counter to be displayed

