module reg32 (clock, resetn, D, byteenable, Q);
input clock, resetn;
input [3:0] byteenable;
input [31:0] D;
output reg [31:0] Q;
always@(posedge clock)
if (!resetn)
Q <= 32'b0;
else
begin
// Enable writing to each byte separately
if (byteenable[0]) Q[7:0] <= D[7:0];
if (byteenable[1]) Q[15:8] <= D[15:8];
if (byteenable[2]) Q[23:16] <= D[23:16];
if (byteenable[3]) Q[31:24] <= D[31:24];
end
endmodule