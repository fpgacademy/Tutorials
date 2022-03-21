`timescale 1ns / 1ps

module testbench ( );
    // declare reg signals for inputs to the design under test
    reg Cin;
    reg [15:0] X, Y;
    // declare wire signals for outputs from the design under test
    wire [15:0] Sum;
    wire Cout;

    // instantiate the design under test
    Addern U1 (Cin, X, Y, Sum, Cout);

    // assign values to the DUT inputs at various simulation times
    initial 
    begin
        X <= 0; Y <= 0; Cin <= 0;
        #20 X <= 0; Y <= 10; Cin <= 0;
        #20 X <= 10; Y <= 10; Cin <= 0;
        #20 X <= 10; Y <= 10; Cin <= 1;
        #20 X <= 16'hFFF0; Y <= 16'hF; Cin <= 0;
        #20 X <= 16'hFFF0; Y <= 16'hF; Cin <= 1;
    end // initial
endmodule
