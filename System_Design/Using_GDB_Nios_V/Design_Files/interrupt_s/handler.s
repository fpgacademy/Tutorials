.include "address_map_niosv.s"

.global handler                      # Trap handler
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
            sw      zero, 0(t0)      # reset mtime low
            sw      zero, 4(t0)      # reset mtime high

            la      t0, counter      # pointer to counter
            lw      t1, (t0)         # read counter value
            addi    t1, t1, 1        # increment the counter
            sw      t1, (t0)         # store counter to memory

            lw      t0, (sp)         # restore regs
            lw      t1, 4(sp)
            addi    sp, sp, 8
            mret
