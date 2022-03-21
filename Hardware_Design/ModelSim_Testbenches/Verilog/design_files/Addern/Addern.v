// A multi-bit adder
module Addern (Cin, X, Y, Sum, Cout);
	parameter n = 16;
	input Cin;
	input [n-1:0] X, Y;
	output [n-1:0] Sum;
	output Cout;

	assign {Cout, Sum} = X + Y + Cin;

endmodule
