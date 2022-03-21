# stop any simulation that is currently running
quit -sim

# create the default "work" library
vlib work;

# compile the VHDL source code in the parent folder
vcom +acc ../*.vhd
# compile the VHDL code of the testbench
vcom +acc *.vht
# start the Simulator, including some libraries that may be needed
vsim +acc work.testbench -Lf 220model -Lf altera_mf
# show waveforms specified in wave.do
do wave.do
# advance the simulation the desired amount of time
run 300 ns
