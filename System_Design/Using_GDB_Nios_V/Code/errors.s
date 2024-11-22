.global _start
_start:     li      sp, 0x20000      # initialize the stack location
            la      t0, handler      # Set handler address
            csrw    mtvec, t0        # set trap address

            la      t0, data_word
            lw      t1, (t0)         # this load will work
            addi    t0, t0, 1
            lw      t1, (t0)         # this load will cause a trap
stop:       j       stop

data_word:  .word   0xa5a5a5a5       # example data

handler:    addi    sp, sp, -4       # save regs that will be modified
            sw      t0, (sp)

            csrr    t0, mcause       # cause of the trap
stay:       bnez    t0, stay         # stay here to allow inspection of exception
                                     # mepc points to the offending instruction
                                     # mtval has the offending address

            lw      t0, (sp)         # restore regs
            addi    sp, sp, 4
            mret
