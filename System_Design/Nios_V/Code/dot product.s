# Program that calculates a dot product of two vectors

            .text
            .global _start
_start:     la      s0, Avector     # pointer to vector A
            la      s1, Bvector     # pointer to vector B
            la      t0, N           # pointer to N
            lw      s2, (t0)        # s2 = N (number of vector elements)
            li      s3, 0           # s3 will hold the final result
            
loop:       lw      a0, (s0)        # load next element of vector A
            lw      a1, (s1)        # load next element of vector B
            jal     mult            # compute product
            add     s3, s3, a0      # add to the sum
            addi    s0, s0, 4       # point to next element of vector A
            addi    s1, s1, 4       # point to next element of vector B
            addi    s2, s2, -1      # count down
            bnez    s2, loop

            la      t0, dot_p       # pointer to the final result
            sw      s3, (t0)        # store the result
stop:       j       stop

# Multiplies a0 x a1, using successive addition
# Returns the product in a0
mult:       mv      t0, zero        # product
            mv      t1, zero        # for checking sign of result
            bgez    a1, mloop       # is a1 a positive value?
            neg     a1, a1          # ...if not, then negate a1
            li      t1, 1           # remember to negate the product
mloop:      beqz    a1, mdone       # done adding yet?
            add     t0, t0, a0      # add the multiplier to the product
            addi    a1, a1, -1      # decrement the multiplicand
            j       mloop
mdone:      beqz    t1, mult_ret    # is sign of product correct?
            neg     t0, t0          # flip sign of result
mult_ret:   mv      a0, t0          # return result
            ret

            .data
N:          .word   6
Avector:    .word   5, 3, -6, 19, 8, 12
Bvector:    .word   2, 14, -3, 2, -5, 36
dot_p:      .word   0
