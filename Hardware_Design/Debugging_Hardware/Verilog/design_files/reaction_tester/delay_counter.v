module delay_counter (Clock, Clear, Enable, Start);
	input Clock, Clear, Enable;
	output wire Start;
	
	reg [27:0] delay_count;
	
	always @(posedge Clock)
		if (Clear)
			delay_count <= 0;
		else if (Enable)
			delay_count <= delay_count + 1;
	
	assign Start = delay_count[27];
endmodule
