module reg32_avalon_interface (clock, resetn, writedata, readdata, write, read,
byteenable, chipselect, Q_export);
// signals for connecting to the Avalon fabric
input clock, resetn, read, write, chipselect;
input [3:0] byteenable;
input [31:0] writedata;
output [31:0] readdata;
// signal for exporting register contents outside of the embedded system
output [31:0] Q_export;
wire [3:0] local_byteenable;
wire [31:0] to_reg, from_reg;
assign to_reg = writedata;
assign local_byteenable = (chipselect & write) ? byteenable : 4'd0;
reg32 U1 ( .clock(clock), .resetn(resetn), .D(to_reg), .byteenable(local_byteenable),
.Q(from_reg) );
assign readdata = from_reg;
assign Q_export = from_reg;
endmodule