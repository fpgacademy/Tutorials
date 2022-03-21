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
  This block recieves the burst count from the top level of the read master and buffers that value
  each time the master issues a burst transaction to the NoC.  As the read responses return
  the buffered burst counts are pulled from the FIFO since a read burst results in one or more
  read responses.  Along with the burst count, the last transfer marker is also buffered so that
  as the read responses return, this block will know when all the read data for a particular transfer
  has returned.
  
  When all the readdata for a transfer has returned the response_valid signal is asserted to signal
  to the dispatcher that all the bus responses have returned.  This allows the dispatcher to notify
  the host of transfer completion when all the bus responses have returned.
  
  This module requires a minimum of 3 cycles of read latency but the Avalon-MM specification requires
  all slaves to have at least 1 cycle of latency so the top level of the read master just needs to
  add two more pipeline stages to readdata and readdatavalid.


  Revision History:

  1.0 Initial version

*/


// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

// turn off superfluous verilog processor warnings 
// altera message_level Level1 
// altera message_off 10034 10035 10036 10037 10230 10240 10030 

module dcp_read_master_response_tracking (
  clk,
  reset,
  
  flush,

  first,
  last,
  burst,
  read,
  waitrequest,
  readdatavalid,
  
  first_beat_returning,
  last_beat_returning,
  generate_sop_in,
  generate_eop_in,
  generate_sop_out,
  generate_eop_out,

  response_valid,
  response_ready
);

  parameter FIFO_DEPTH_LOG2 = 12;   // handles up to 4096 clock cycles of read latency
  parameter BURST_WIDTH = 3;

  input clk;
  input reset;  // must be synchronous to clk
  
  input flush;
  
  input first;
  input last;
  input [BURST_WIDTH-1:0] burst;
  input read;
  input waitrequest;
  input readdatavalid;
  
  output wire first_beat_returning;
  output wire last_beat_returning;
  input generate_sop_in;
  input generate_eop_in;
  output wire generate_sop_out;
  output wire generate_eop_out;


  // not going to bother with data since the response sent back to the dispatcher is just a bunch of async signals
  output wire response_valid;
  input response_ready;


  reg [BURST_WIDTH-1:0] burst_counter;
  wire load_burst_counter;
  wire increment_burst_counter;

  wire [4+(BURST_WIDTH-1):0] fifo_input;  // +4 because the FIFO needs to track the first and last burst and the generate_sop and generate_eop bits
  wire [4+(BURST_WIDTH-1):0] fifo_output;
  wire fifo_empty;
  wire fifo_write;
  wire fifo_read;
  
  reg [FIFO_DEPTH_LOG2-1:0] response_counter;
  wire increment_response_counter;
  wire decrement_response_counter;
  
  // need to keep a copy of the generate eop around after the burst FIFO is popped for burst lengths of 2 or greater
  reg generate_eop_temp;

  
  /* Every time a read is posted to the NoC it gets buffered in this FIFO.  Since the FIFO has three cycles of latency this logic requires
     that the reads have a minimum of two clock cycles otherwise the contents may not be available at the FIFO output in time for the read
     data that is returning.  Avalon-MM already requires a minimum of 1 clock cycle so the read master parent just needs to pipeline
     readdata and readdatavalid with two additional stages to ensure a minimum read latency of 3 cycles.
  */
  scfifo burst_fifo (
    .sclr  (flush | reset),
    .clock (clk),
    .data  (fifo_input),
    .empty (fifo_empty),
    .q     (fifo_output),
    .rdreq (fifo_read),
    .wrreq (fifo_write)
  );
  defparam burst_fifo.lpm_width = (BURST_WIDTH+4);
  defparam burst_fifo.lpm_numwords = (2**FIFO_DEPTH_LOG2);
  defparam burst_fifo.lpm_widthu = FIFO_DEPTH_LOG2;
  defparam burst_fifo.lpm_showahead = "ON";
  defparam burst_fifo.use_eab = "ON";
  defparam burst_fifo.add_ram_output_register = "ON";  // when on the FIFO has three cycles of latency, off has two cycles but then logic may become part of the critical path
  defparam burst_fifo.underflow_checking = "OFF";  // surrounding logic will already check
  defparam burst_fifo.overflow_checking = "OFF";   // FIFO is deep enough to handle many inflight burst reads, the data FIFO in the top level should backpressure the reads much sooner than this one fills up

  // need to buffer all these in case early_done is enabled so that the logic remembers where the first and last beat are and whether SOP and EOP need to be generated
  assign fifo_input = {generate_eop_in, generate_sop_in, last, first, burst};
  assign fifo_write = (read == 1'b1) & (waitrequest == 1'b0);
  assign fifo_read = load_burst_counter; // asserts at the end of each burst for one clock cycle


  // burst_counter is used to keep track of the beats of the oldest posted burst that has not already been fully responded to
  always @ (posedge clk)
  begin
    if (reset | flush | load_burst_counter)
    begin
      burst_counter <= 'b1;  // loading the counter to 1 takes precedence over incrementing
    end
    else if (increment_burst_counter)
    begin
      burst_counter <= burst_counter + 1'b1;  // will only reach this if a multi-beat burst is returning
    end
  end

  // don't need to worry about incrementing an unloaded counter since the burst FIFO is always ahead of the read responses returning
  assign load_burst_counter = (fifo_empty == 1'b0) & (burst_counter == fifo_output[BURST_WIDTH-1:0]) & (readdatavalid == 1'b1);
  assign increment_burst_counter = readdatavalid;


  always @ (posedge clk)
  begin
    // need to register a copy of the generate eop so that on the last beat it is preserved (only needed if last burst length is 2 or greater)
    if (load_burst_counter)
    begin
      generate_eop_temp <= fifo_output[(BURST_WIDTH-1)+4];
    end
  end

  // response_counter is used to signal to the dispatcher that a valid response is ready (any time the counter is above 0)
  always @ (posedge clk)
  begin
    if (reset | flush)
    begin
      response_counter <= 'b0;
    end
    else
    begin
      case ({increment_response_counter, decrement_response_counter})
        2'b00:  response_counter <= response_counter;
        2'b01:  response_counter <= response_counter - 1'b1;
        2'b10:  response_counter <= response_counter + 1'b1;
        2'b11:  response_counter <= response_counter;
      endcase
    end
  end


  /* need to use <= 1 for the burst counter check in case the last burst was of size 1 and readdatavalid for that burst returns at the same time
     the burst counter is being loaded (read latency of 1 cycle).  When both happen at the same time the counter gets loaded with a value of 0 instead
     of 1 so that's why we need to check for the burst counter = 0 or 1.
  */
  assign increment_response_counter = last_beat_returning;
  assign decrement_response_counter = response_valid & response_ready;


  // these signals are sent to MM to ST adapter to time asserting the SOP and EOP signals.
  assign first_beat_returning = (fifo_empty == 1'b0) & (fifo_output[(BURST_WIDTH-1)+1] == 1'b1) & (burst_counter == 'b1) & (readdatavalid == 1'b1);  // first burst, first beat, and readdata returning
  assign last_beat_returning = (fifo_empty == 1'b0) & (fifo_output[(BURST_WIDTH-1)+2] == 1'b1) & (burst_counter == fifo_output[BURST_WIDTH-1:0]) & (readdatavalid == 1'b1);  // last burst, last beat, and readdata returning
  assign generate_sop_out = fifo_output[(BURST_WIDTH-1)+3];  // when the FIFO is popped the first time that is also when SOP is returning so do not need to use a registered copy of generate_sop
  assign generate_eop_out = (load_burst_counter == 1)? fifo_output[(BURST_WIDTH-1)+4] : generate_eop_temp;  // when loading burst counter need to use the raw generate_eop in case the last burst length is 1

  assign response_valid = (response_counter != 'b0);

endmodule
