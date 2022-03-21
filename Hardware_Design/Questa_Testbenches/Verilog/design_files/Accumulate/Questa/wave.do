onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -label KEY /testbench/KEY
add wave -noupdate -label CLOCK_50 /testbench/CLOCK_50
add wave -noupdate -label SW -radix hexadecimal /testbench/SW
add wave -noupdate -label LEDR -radix hexadecimal /testbench/LEDR
add wave -noupdate -divider Accumulate
add wave -noupdate -label Clock /testbench/U1/Clock
add wave -noupdate -label Resetn /testbench/U1/Resetn
add wave -noupdate -label X -radix unsigned /testbench/U1/X
add wave -noupdate -label Sum -radix unsigned /testbench/U1/Sum
add wave -noupdate -label Y -radix unsigned /testbench/U1/Y
add wave -noupdate -label Count -radix unsigned /testbench/U1/Count
add wave -noupdate -label z /testbench/U1/z
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {10000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 80
configure wave -valuecolwidth 40
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {15 ns} {315 ns}
