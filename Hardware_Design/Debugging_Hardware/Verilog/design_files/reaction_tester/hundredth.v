module hundredth (Clock, Load, pulse_500k);
	input Clock, Load;
	output wire pulse_500k;
	
	reg [19:0] count_500k;
	
	always @(posedge Clock)
		if (Load)
			count_500k <= 20'h7A120;
		else
			count_500k <= count_500k - 1;
	
	assign pulse_500k = (count_500k == 20'h00000);
endmodule
