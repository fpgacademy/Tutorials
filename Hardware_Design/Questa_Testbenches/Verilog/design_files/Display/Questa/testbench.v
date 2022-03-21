`timescale 1ns / 1ps

module testbench ( );

	reg [0:0] KEY;
	reg [0:0] SW;
   wire [6:0] HEX0;
	wire [9:0] LEDR;

	Display U1 (KEY, SW, HEX0, LEDR);

	always
	begin : Clock_Generator
		#10 KEY <= ~KEY;
	end
	
	initial
   begin
		KEY <= 1'b0; SW <= 1'h0;
		#20 SW[0] <= 1'b1;
	end // initial

endmodule
