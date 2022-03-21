module component_tutorial (CLOCK_50, KEY, HEX0, HEX1, HEX2, HEX3);
input CLOCK_50;
input [0:0] KEY;
output [0:6] HEX0, HEX1, HEX2, HEX3;
wire [31:0] to_HEX;
embedded_system U0 (
.clk_clk(CLOCK_50), .resetn_reset_n(KEY[0]), .to_hex_readdata(to_HEX) );
hex7seg h0(to_HEX[3:0], HEX0);
hex7seg h1(to_HEX[7:4], HEX1);
hex7seg h2(to_HEX[11:8], HEX2);
hex7seg h3(to_HEX[15:12], HEX3);
endmodule

module hex7seg (hex, display);
input [3:0] hex;
output [0:6] display;
reg [0:6] display;
/*
* – 0 –
* 5 | | 1
* – 6 –
* 4 | | 2
* – 3 –
*/
always @ (hex)
case (hex)
4'h0: display = 7'b0000001;
4'h1: display = 7'b1001111;
4'h2: display = 7'b0010010;
4'h3: display = 7'b0000110;
4'h4: display = 7'b1001100;
4'h5: display = 7'b0100100;
4'h6: display = 7'b0100000;
4'h7: display = 7'b0001111;
4'h8: display = 7'b0000000;
4'h9: display = 7'b0001100;
4'hA: display = 7'b0001000;
4'hb: display = 7'b1100000;
4'hC: display = 7'b0110001;
4'hd: display = 7'b1000010;
4'hE: display = 7'b0110000;
4'hF: display = 7'b0111000;
endcase
endmodule

