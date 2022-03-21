module reg16 (clock, resetn, D, byteenable, Q);
	input clock, resetn;
	input [1:0] byteenable;
	input [15:0] D;
	output reg [15:0] Q;

	always@(posedge clock)
		if (!resetn)
			Q <= 16'b0;
		else
		begin
			// Enable writing to each byte separately
			if (byteenable[0]) Q[7:0] <= D[7:0];
			if (byteenable[1]) Q[15:8] <= D[15:8];
		end
endmodule

