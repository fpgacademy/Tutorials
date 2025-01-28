# Program that displays SW switch settings on LEDR and HEX0

.include "address_map.s"

.global _start
_start: li      t0, LEDR_BASE       # pointer to LEDR port
        li      t1, SW_BASE         # pointer to SW port
        li      t2, HEX3_HEX0_BASE  # pointer to HEX port

loop:   lw      t3, (t1)            # read from SW
        sw      t3, (t0)            # write to LEDR
        sw      t3, (t2)            # write to HEX0
        j       loop

