module control_ff (Clock, ff_in, Clear, Q);
	input Clock, ff_in, Clear;
	output reg Q;
	always @(posedge Clock)
		if (Clear)
			Q <= 0;
		else
			Q <= ff_in | Q;
endmodule
