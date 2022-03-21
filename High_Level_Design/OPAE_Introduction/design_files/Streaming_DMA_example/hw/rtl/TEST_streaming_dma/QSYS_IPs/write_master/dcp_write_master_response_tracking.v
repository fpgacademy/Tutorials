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
  This block accepts responses from the top level of the write master through the internal_response streaming
  port and buffers them internally.  The block also monitors outgoing write bursts being posted and the 
  responses to those write accesses.
  
  When the bus response to the last write burst returns this block will assert the external_response_valid
  signal notifying the dispatcher that a valid response is waiting.  This ensures that transfer responses
  are only buffered by the dispatcher until all the bus traffic for that transfer completes (i.e. all the write
  responses return).  By synchronizing transfer responses to bus responses the host will only be notified
  of transfer completion when all the bus responses complete.
  
  Since this module buffers the last_burst signal in a FIFO that means 3 cycles of response latency are necessary.
  The NoC provides one cycle and the top level of the write master will need to pipeline the write response
  by two more cycles.  This ensures the buffered copy of last_burst is available in time if the system write
  response latency is only 1 cycle.


  Revision History:

  1.0 Initial version - 10/25/2018

*/


// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

// turn off superfluous verilog processor warnings 
// altera message_level Level1 
// altera message_off 10034 10035 10036 10037 10230 10240 10030 

module dcp_write_master_response_tracking (
  clk,
  reset,
  
  last_burst,
  burst_complete,
  writeresponsevalid,

  internal_response,
  internal_response_valid,
  internal_response_ready,
  
  external_response,
  external_response_valid,
  external_response_ready
);

  parameter RESPONSE_FIFO_DEPTH_LOG2 = 5;  // 5 should fit in a group of MLABs which are at most 32 entries deep
  parameter BURST_FIFO_DEPTH_LOG2 = 10;    // tracks up to 1024 write bursts

  input clk;
  input reset;  // must be synchronous to clk

  input last_burst;
  input burst_complete;
  input writeresponsevalid;
  
  input [255:0] internal_response;
  input internal_response_valid;
  output wire internal_response_ready;
  
  output wire [255:0] external_response;
  output wire external_response_valid;
  input external_response_ready;
  
  /* The response fifo buffers responses from the DMA immediately then releases them to the dispatcher when all
     the write responses returns.  This makes sure writes are properly synchronized with the host.  The fifo stores
     data as:  {eop_arrived, response_early_termination, response_error, response_actual_bytes_transferred} bits */
  wire [41:0] response_fifo_input;
  wire [41:0] response_fifo_output;
  wire response_fifo_empty;
  wire response_fifo_full;
  wire response_fifo_write;
  wire response_fifo_read;
  
  /* The burst FIFO is used to track outstanding bursts and whether they are the last write of a transfer.  As the
     write responses returns the FIFO is popped and whether the popped output is high the response tracker is incremented
     representing */
  wire burst_fifo_input;
  wire burst_fifo_output;
  wire burst_fifo_empty;
  wire burst_fifo_write;
  wire burst_fifo_read;
  
  /* response counter increments each time all the write responses for a transfer return, and it decrements each time the
     a transfer response is forwarded to the dispatcher (external_response port) */
  reg [RESPONSE_FIFO_DEPTH_LOG2-1:0] response_counter;
  wire increment_response_counter;
  wire decrement_response_counter;


  
  always @ (posedge clk)
  begin
    if (reset)
    begin
      response_counter <= 'b0;    
    end
    else
    begin
      case ({increment_response_counter, decrement_response_counter})
        2'b00:  response_counter <= response_counter;
        2'b01:  response_counter <= response_counter - 1'b1;
        2'b10:  response_counter <= response_counter + 1'b1;
        2'b11:  response_counter <= response_counter;  // increment and decrement so net 0
      endcase
    end
  end

  // each time the last burst of a transfer completes increase the response counter, when the response is sent to the dispatch decrease the response counter
  assign increment_response_counter = (burst_fifo_output == 1'b1) & (burst_fifo_read == 1'b1);
  assign decrement_response_counter = external_response_valid & external_response_ready;
  

  scfifo response_fifo (
    .sclr  (reset),
    .clock (clk),
    .data  (response_fifo_input),
    .empty (response_fifo_empty),
    .full  (response_fifo_full),
    .q     (response_fifo_output),
    .rdreq (response_fifo_read),
    .wrreq (response_fifo_write)
  );
  defparam response_fifo.lpm_width = 42;
  defparam response_fifo.lpm_numwords = (2**RESPONSE_FIFO_DEPTH_LOG2);
  defparam response_fifo.lpm_widthu = RESPONSE_FIFO_DEPTH_LOG2;
  defparam response_fifo.lpm_showahead = "ON";
  defparam response_fifo.use_eab = "ON";
  defparam response_fifo.add_ram_output_register = "ON";
  defparam response_fifo.underflow_checking = "OFF";
  defparam response_fifo.overflow_checking = "OFF";  

  assign response_fifo_input = {internal_response[44], internal_response[42:34], internal_response[31:0]};  // bits 43, 33, 32 are done_strobe, stop_state, reset_delayed which don't need to be buffered
  assign response_fifo_write = internal_response_valid & internal_response_ready;
  assign response_fifo_read = external_response_valid & external_response_ready;


  scfifo burst_fifo (
    .sclr  (reset),
    .clock (clk),
    .data  (burst_fifo_input),
    .empty (burst_fifo_empty),
    .q     (burst_fifo_output),
    .rdreq (burst_fifo_read),
    .wrreq (burst_fifo_write)
  );
  defparam burst_fifo.lpm_width = 1;
  defparam burst_fifo.lpm_numwords = (2**BURST_FIFO_DEPTH_LOG2);
  defparam burst_fifo.lpm_widthu = BURST_FIFO_DEPTH_LOG2;
  defparam burst_fifo.lpm_showahead = "ON";     // this FIFO has a latency of 3 clock cycles so writeresponsevalid will need to be pipelined by 2 stages (NoC will provide the other 1 cycle)
  defparam burst_fifo.use_eab = "ON";
  defparam burst_fifo.add_ram_output_register = "ON";
  defparam burst_fifo.underflow_checking = "OFF";
  defparam burst_fifo.overflow_checking = "OFF"; 

  assign burst_fifo_input = last_burst;
  assign burst_fifo_write = burst_complete;     // one cycle pulse that asserts when the last beat of a burst is posted to the NoC
  assign burst_fifo_read = writeresponsevalid;  // one cycle pulse that asserts each time a burst completes (all beats responded)

  
  assign internal_response_ready = (response_fifo_full == 1'b0);
  assign external_response_valid = (response_counter != 'h0) & (response_fifo_empty == 1'b0);
  // since done_strobe, stop_state, and reset_delay are not buffered just loop them back up to the parent to send out the response port
  assign external_response = {{211{1'b0}}, response_fifo_output[41], internal_response[43], response_fifo_output[40:32], internal_response[33:32], response_fifo_output[31:0]};
  
endmodule
