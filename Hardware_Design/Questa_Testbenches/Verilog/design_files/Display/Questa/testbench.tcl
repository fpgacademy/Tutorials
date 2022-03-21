# stop any simulation that is currently running
quit -sim

# if simulating with a MIF file, copy it to the working folder. Assumes inst_mem.mif
if {[file exists ../inst_mem.mif]} {
	file delete inst_mem.mif
	file copy ../inst_mem.mif .
}
# in case Quartus generated an "empty black box" file for the memory, delete it
if {[file exists ../inst_mem_bb.v]} {
	file delete ../inst_mem_bb.v
}

# create the default "work" library
vlib work;

# compile the Verilog source code in the parent folder
vlog +acc ../*.v
# compile the Verilog code of the testbench
vlog +acc *.v
# start the Simulator
vsim +acc work.testbench -Lf 220model_ver -Lf altera_mf_ver -Lf verilog
# show waveforms specified in wave.do
do wave.do
# advance the simulation the desired amount of time
run 180 ns
