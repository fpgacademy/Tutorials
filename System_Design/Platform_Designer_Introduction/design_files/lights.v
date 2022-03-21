// Top-level module for Qsys tutorial

module lights (CLOCK_50, SW, KEY, LEDG);
	input CLOCK_50;
	input [7:0] SW;
	input [0:0] KEY;
	output [7:0] LEDG;

// Instantiate the Nios II module
	
	nios_system  NiosII (
		.clk_clk(CLOCK_50), 
		.reset_reset_n(KEY),
		.switches_export(SW),
		.leds_export(LEDG)); 
	
endmodule