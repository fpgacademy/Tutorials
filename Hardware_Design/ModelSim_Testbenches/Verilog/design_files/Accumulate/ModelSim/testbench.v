`timescale 1ns / 1ps

module testbench ( );
    // declare DUT inputs
    reg [0:0] KEY;
    reg CLOCK_50;
    reg [9:0] SW;
    // declare DUT outputs
    wire [9:0] LEDR;

    // instantiate the design under test
    Accumulate U1 (KEY, CLOCK_50, SW, LEDR);

    // generate a 50 MHz periodic clock waveform
    always
        #10 CLOCK_50 <= ~CLOCK_50;
    
    // assign inputs at various times
    initial 
    begin
        CLOCK_50 <= 1'b0;
        KEY[0] <= 1'b0;
        SW <= 0;
        #20 SW[9:5] <= 10;
        #20 KEY[0] <= 1'b1;
        		SW[4:0] <= 30;
    end // initial
endmodule
