module BCD_stage (Clock, Clear, Ecount, BCDq, Value9);
	input Clock, Clear, Ecount;
	output reg [3:0] BCDq;
	output reg Value9;
	
	always @(posedge Clock)
	begin
		if (Clear)
			BCDq <= 0;
		else if (Ecount)
		begin
			if (BCDq == 4'b1001)
				BCDq <= 0;
			else
				BCDq <= BCDq + 1;
		end
	end
	
	always @(BCDq)
		if (BCDq == 4'b1001)
			Value9 <= 1'b1;
		else
			Value9 <= 1'b0;
endmodule
