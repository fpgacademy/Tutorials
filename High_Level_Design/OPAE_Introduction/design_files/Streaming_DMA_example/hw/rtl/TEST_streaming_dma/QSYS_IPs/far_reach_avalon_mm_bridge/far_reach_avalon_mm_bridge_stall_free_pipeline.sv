// (C) 2001-2018 Intel Corporation. All rights reserved.
// Your use of Intel Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files from any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Intel Program License Subscription 
// Agreement, Intel FPGA IP License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Intel and sold by 
// Intel or its authorized distributors.  Please refer to the applicable 
// agreement for further details.


/*
  Helper library that creates a variable width and depth pipeline.  This
  pipeline does not have any backpressure (i.e. stall free).  It is up
  to the logic pushing data into this module to make sure the output
  doesn't overwhelm the receiver.


  Revision History:

  1.0 Initial version

*/

// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on


module far_reach_avalon_mm_bridge_stall_free_pipeline # (
  parameter DATA_WIDTH = 32,
  parameter DEPTH = 1          // must be greater than 0
)
(
  input clk,
  input [DATA_WIDTH-1:0] input_data,
  output [DATA_WIDTH-1:0] output_data
);

logic [DATA_WIDTH-1:0] pipeline [DEPTH-1:0];

always @ (posedge clk)
begin
  pipeline[0] <= input_data;
end

genvar n;
generate
for (n = 0; n < (DEPTH-1); n = n+1)
begin: pipeline_stages

  always @ (posedge clk)
  begin
    pipeline[n+1] <= pipeline[n];
  end

end
endgenerate

assign output_data = pipeline[DEPTH-1];

endmodule
