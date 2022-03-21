// avalon memory mapped interface for the reg16 module. The signal Q_export provides 
// the content of the register for exporting outside of the embedded system
module reg16_avalon_interface (clock, resetn, writedata, readdata, write, read, 
	byteenable, chipselect, Q_export);

	// signals for connecting to the Avalon fabric
	input clock, resetn, read, write, chipselect;
	input [1:0] byteenable;
	input [15:0] writedata;
	output [15:0] readdata;

	// signal for exporting register contents outside of the embedded system
	output [15:0] Q_export;

	wire [1:0] local_byteenable;
	wire [15:0] to_reg, from_reg;

	assign to_reg = writedata;

	assign local_byteenable = (chipselect & write) ? byteenable : 2'd0;

	reg16 U1 ( .clock(clock), .resetn(resetn), .D(to_reg), .byteenable(local_byteenable), 
		.Q(from_reg) );

	assign readdata = from_reg;
	assign Q_export = from_reg;
endmodule
