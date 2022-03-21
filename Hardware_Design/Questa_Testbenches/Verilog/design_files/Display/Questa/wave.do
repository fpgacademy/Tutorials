onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -label KEY /testbench/KEY
add wave -noupdate -label SW /testbench/SW
add wave -noupdate -label LEDR -radix hexadecimal /testbench/LEDR
add wave -noupdate -label HEX0 /testbench/HEX0
add wave -noupdate -divider Display
add wave -noupdate -label Clock /testbench/U1/Clock
add wave -noupdate -label Resetn /testbench/U1/Resetn
add wave -noupdate -label Count -radix hexadecimal /testbench/U1/Count
add wave -noupdate -label char -radix ascii /testbench/U1/char
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {80000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 77
configure wave -valuecolwidth 49
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
WaveRestoreZoom {0 ps} {180 ns}
