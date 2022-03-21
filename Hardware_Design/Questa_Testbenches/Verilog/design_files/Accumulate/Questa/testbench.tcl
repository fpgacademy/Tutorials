# stop any simulation that is currently running
quit -sim

# create the default "work" library
vlib work;

# compile the Verilog source code in the parent folder
vlog +acc ../*.v
# compile the Verilog code of the testbench
vlog +acc *.v
# start the Simulator, including some libraries that may be needed
vsim +acc work.testbench -Lf 220model_ver -Lf altera_mf_ver -Lf verilog
# show waveforms specified in wave.do
do wave.do
# advance the simulation the desired amount of time
run 300 ns
