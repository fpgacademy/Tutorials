// ***************************************************************************
// Copyright (c) 2018, Intel Corporation
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice,
// this list of conditions and the following disclaimer.
// * Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.
// * Neither the name of Intel Corporation nor the names of its contributors
// may be used to endorse or promote products derived from this software
// without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
//
// ***************************************************************************



/*
This module is a CCIP friendly frontend for the mSGDMA so that descriptors can be load/stored
512-bit every clock cycle.  In most cases the host driver writes a start location pointer
to the hardware and enables this block and then rarely accesses it again.  When enabled the
block will load descriptors from memory and provide those to the dispatcher block.  When the
dispatcher block provides a completion response this module will perform a descriptor
writeback operation to store information about the transfer and change the descriptor ownership
back to the host so that the driver can inspect the descriptor.

So instead of the host accessing the dispatcher directly, the driver places control information
(descriptors) into host memory, sets the descriptor ownership to hardware (DMA), this block
fetches descriptors it owns, then this module writes status information back to the host
(overwrites descriptor).  The host never accesses the DMA hardware directly and essentially
participates in message passing through shared memory (descriptor).

Below is the address map of the slave port that the host can access to control this module:


Byte Offset    Access                Register
-----------    ------                --------                        
   0x00         R/W                  Control
   0x08         R/W         Set start location (64-bit)
   0x10          R          Current load location (64-bit)
   0x18          R          Current store location (64-bit)
   0x20        R/Wclr                 Status
   0x28          R               FIFO Fill Levels
   0x30         N/A                    N/A
   0x38         N/A                    N/A


Control register:

Bit Offset     Access                 Field
----------     ------                 -----
    0           R/W                   Enable
    1           R/W                   Flush
    2           R/W                  IRQ mask
    3           R/W                Enable timeout
   15-4         N/A            N/A will return zeros
   31-16        R/W                  Timeout
   63-32        N/A            N/A will return zeros


Status register:

Bit Offset     Access                 Field
----------     ------                 ----- 
    0          R/Wclr         IRQ (write 1 to clear)
    1            R                 Fetch idle
    2            R                 Store idle
   7-2          N/A            N/A will return zeros
  10-8           R               Fetch state bits
  12-11          R               Store state bits
  15-13         N/A            N/A will return zeros
  31-16          R           Outstanding descriptor fetches
  63-32         N/A            N/A will return zeros


FIFO Fill Levels register:

Bit Offset     Access                 Field
----------     ------                 ----- 
15-0             R       Fetch Descriptor FIFO fill level
31-16            R       Store Descriptor FIFO fill level
47-32            R        Store Response FIFO fill level
63:48           N/A            N/A will return zeros



------------------
Author:  JCJB
Date:    10/24/2018
Version: 1.2
------------------

Version 1.2 - 10/24/2018 - Updated to bring out store_idle, fetch_current_state, and store_current_state
                           out to the status register so that the driver can query the state of the hardware.

Version 1.1 - 10/01/2018 - Updated to bring out more software readable status fields

Version 1.0 - 9/14/2018 - Initial version of the module

*/


import mSGDMA_frontend_descriptor_format_pkg::*;


module mSGDMA_frontend #
(
  parameter ADDRESS_WIDTH = 48,         // CCIP requires this to be at least 48
  parameter BURST_WIDTH = 3,            // CCIP requires this to be 3
  parameter FETCH_FIFO_DEPTH_LOG2 = 6,  // this should be smaller than STORE_FIFO_DEPTH_LOG2, and set to at least 2x the expected descriptor block size and set no larger than 9
  parameter STORE_FIFO_DEPTH_LOG2 = 4,  // use 4 so that Quartus can place this FIFO into MLABs efficiently
  parameter IRQ_ENABLE = 1              // if driver doesn't need interrupts set this to 0 to omit interrupt logic
)
(
  input clk,
  input reset,
  
  input [2:0] s_address,
  input s_read,
  output logic [63:0] s_readdata,
  input s_write,
  input [63:0] s_writedata,
  input [7:0] s_byteenable,

  output logic irq,
  
  output logic [ADDRESS_WIDTH-1:0] m_fetch_address,
  output logic m_fetch_read,
  output logic [BURST_WIDTH-1:0] m_fetch_burst,
  input [DESCRIPTOR_FORMAT_A_WIDTH-1:0] m_fetch_readdata,  
  input m_fetch_readdatavalid,
  output logic [(DESCRIPTOR_FORMAT_A_WIDTH/8)-1:0] m_fetch_byteenable,
  input m_fetch_waitrequest, 

  output logic [ADDRESS_WIDTH-1:0] m_store_address,
  output logic m_store_write,
  output logic [BURST_WIDTH-1:0] m_store_burst,
  output logic [DESCRIPTOR_FORMAT_A_WIDTH-1:0] m_store_writedata,
  output logic [(DESCRIPTOR_FORMAT_A_WIDTH/8)-1:0] m_store_byteenable,
  input m_store_waitrequest,

  output logic [255:0] src_descriptor_data,
  output logic src_descriptor_valid,
  input src_descriptor_ready,

  input [255:0] snk_response_data,
  input snk_response_valid,
  output logic snk_response_ready
);

  descriptor_format_A internal_descriptor;
  logic fetch_descriptor_valid;
  logic fetch_descriptor_ready;
  logic store_descriptor_valid;
  logic store_descriptor_ready;

  response_format_A internal_response;
  
  logic [ADDRESS_WIDTH-1:0] block_address;
  logic block_address_valid;
  logic block_address_ready;


  logic enable;
  logic flush;
  logic irq_mask;
  logic [15:0] timeout;
  logic enable_timeout;
  logic [63:0] start_location;
  logic load_start_location;
  logic clear_irq;
  logic [FETCH_FIFO_DEPTH_LOG2-1:0] outstanding_reads;
  logic [ADDRESS_WIDTH-1:0] fetch_current_location;
  logic [ADDRESS_WIDTH-1:0] store_current_location;
  logic [63:0] fifo_fill_levels;
  logic [63:0] readdata;
  logic fetch_idle;
  logic store_idle;
  logic [FETCH_FIFO_DEPTH_LOG2:0] fetch_descriptor_fill_level;
  logic [2:0] fetch_current_state;
  logic [STORE_FIFO_DEPTH_LOG2:0] store_descriptor_fill_level;
  logic [STORE_FIFO_DEPTH_LOG2:0] store_response_fill_level;
  logic [1:0] store_current_state;
  
  

  // capture all the control registers
  always @ (posedge clk)
  begin
    if (reset)
    begin
      enable <= 1'b0;
      flush <= 1'b0;
      irq_mask <= 1'b0;
      timeout <= 16'h00FF;   // default timeout of 256 clock cycles
      enable_timeout <= 1'b0;
    end
    else if ((s_address == 3'b000) & (s_write == 1'b1))
    begin
      if (s_byteenable[0] == 1'b1)
      begin
        enable <= s_writedata[0];
        flush <= s_writedata[1];
        irq_mask <= s_writedata[2];
        enable_timeout <= s_writedata[3];
      end      
      if (s_byteenable[2] == 1'b1)
      begin
        timeout[7:0] <= s_writedata[23:16];
      end
      if (s_byteenable[3] == 1'b1)
      begin
        timeout[15:8] <= s_writedata[31:24];
      end
    end
  end

  
  // capture all the start location writes, writing the most significant byte lane causes the fetch engine to load a new address
  always @ (posedge clk)
  begin
    if ((s_address == 3'b001) & (s_write == 1'b1))
    begin
      if (s_byteenable[0] == 1'b1)
      begin
        start_location[7:0] <= s_writedata[7:0];
      end
      if (s_byteenable[1] == 1'b1)
      begin
        start_location[15:8] <= s_writedata[15:8];
      end
      if (s_byteenable[2] == 1'b1)
      begin
        start_location[23:16] <= s_writedata[23:16];
      end
      if (s_byteenable[3] == 1'b1)
      begin
        start_location[31:24] <= s_writedata[31:24];
      end
      if (s_byteenable[4] == 1'b1)
      begin
        start_location[39:32] <= s_writedata[39:32];
      end
      if (s_byteenable[5] == 1'b1)
      begin
        start_location[47:40] <= s_writedata[47:40];
      end
      if (s_byteenable[6] == 1'b1)
      begin
        start_location[55:48] <= s_writedata[55:48];
      end
      if (s_byteenable[7] == 1'b1)
      begin
        start_location[63:56] <= s_writedata[63:56];
      end
    end
  end

  
  // strobes for clearing the interrupt and loading new start_location into the fetch and store modules
  always @ (posedge clk)
  begin
    if (reset)
    begin
      load_start_location <= 1'b0;
      clear_irq <= 1'b0;
    end
    else
    begin
      load_start_location <= (s_address == 3'b001) & (s_write == 1'b1) & (s_byteenable[7] == 1'b1);
      clear_irq <= (s_address == 3'b100) & (s_write == 1'b1) & (s_byteenable[0] == 1'b1) & (s_writedata[0] == 1'b1);
    end
  end


  mSGDMA_descriptor_fetch_read_master #
  (
    .ADDRESS_WIDTH                  (ADDRESS_WIDTH),
    .BURST_WIDTH                    (BURST_WIDTH),
    .FIFO_DEPTH_LOG2                (FETCH_FIFO_DEPTH_LOG2)
  ) read_master
  (
    .clk                            (clk),
    .reset                          (reset),
    .m_address                      (m_fetch_address),
    .m_read                         (m_fetch_read),
    .m_burst                        (m_fetch_burst),
    .m_readdata                     (m_fetch_readdata),  
    .m_readdatavalid                (m_fetch_readdatavalid),
    .m_byteenable                   (m_fetch_byteenable),
    .m_waitrequest                  (m_fetch_waitrequest),
    .descriptor                     (internal_descriptor),
    .descriptor_valid               (fetch_descriptor_valid),
    .descriptor_ready               (fetch_descriptor_ready),
    .block_address                  (block_address),
    .block_address_valid            (block_address_valid),
    .block_address_ready            (block_address_ready),
    .enable_fetch                   (enable),
    .flush                          (flush),
    .new_descriptor_location        (start_location),
    .load_new_descriptor_location   (load_start_location),
    .descriptor_timeout             (timeout),
    .enable_descriptor_timeout      (enable_timeout),
    .outstanding_reads              (outstanding_reads),
    .current_location               (fetch_current_location),
    .descriptor_fill_level          (fetch_descriptor_fill_level),
    .fetch_idle                     (fetch_idle),
    .current_state                  (fetch_current_state)
  );

  // sending reformated descriptor data to dispatcher.  Dispatcher using 256-bit (enhanced) descriptors and this module is using 512-bit descriptors.
  assign src_descriptor_data = { internal_descriptor.control,
                                 internal_descriptor.destination[63:32],
                                 internal_descriptor.source[63:32],
                                 internal_descriptor.write_stride,
                                 internal_descriptor.read_stride,
                                 internal_descriptor.write_burst,
                                 internal_descriptor.read_burst,
                                 internal_descriptor.sequence_num,
                                 internal_descriptor.length,
                                 internal_descriptor.destination[31:0],
                                 internal_descriptor.source[31:0]
                               };
  assign fetch_descriptor_ready = src_descriptor_ready & store_descriptor_ready;  // descriptor sent to two sinks so need to wait for them both to be ready
  assign src_descriptor_valid = fetch_descriptor_valid & fetch_descriptor_ready;  // need to make sure both sinks are ready before sending the descriptor to the dispatcher (and store unit)
  
  
  assign internal_response.actual_bytes_transferred = snk_response_data[31:0];
  assign internal_response.error = snk_response_data[39:32];
  assign internal_response.early_termination = snk_response_data[40];
  assign internal_response.transfer_complete_IRQ_mask = snk_response_data[41];
  assign internal_response.error_IRQ_mask = snk_response_data[49:42];
  assign internal_response.early_termination_IRQ_mask = snk_response_data[50];
  assign internal_response.eop_arrived_IRQ_mask = snk_response_data[51];
  assign internal_response.eop_arrived = snk_response_data[52];
  assign internal_response.descriptor_buffer_full = snk_response_data[53];

  
  mSGDMA_descriptor_store_write_master #
  (
    .ADDRESS_WIDTH                  (ADDRESS_WIDTH),
    .BURST_WIDTH                    (BURST_WIDTH),
    .FIFO_DEPTH_LOG2                (STORE_FIFO_DEPTH_LOG2),
    .IRQ_ENABLE                     (IRQ_ENABLE)
  ) write_master
  (
    .clk                            (clk),
    .reset                          (reset),
    .m_address                      (m_store_address),
    .m_write                        (m_store_write),
    .m_burst                        (m_store_burst),
    .m_writedata                    (m_store_writedata),
    .m_byteenable                   (m_store_byteenable),
    .m_waitrequest                  (m_store_waitrequest),
    .irq                            (irq),
    .block_address                  (block_address),
    .block_address_valid            (block_address_valid),
    .block_address_ready            (block_address_ready),
    .descriptor                     (internal_descriptor),
    .descriptor_valid               (store_descriptor_valid),
    .descriptor_ready               (store_descriptor_ready),
    .response                       (internal_response),
    .response_valid                 (snk_response_valid),
    .response_ready                 (snk_response_ready),
    .sw_clear_irq                   (clear_irq),
    .irq_mask                       (irq_mask),
    .enable_store                   (enable),
    .flush                          (flush),
    .current_location               (store_current_location),
    .descriptor_fill_level          (store_descriptor_fill_level),
    .response_fill_level            (store_response_fill_level),
    .store_idle                     (store_idle),
    .current_state                  (store_current_state)
  );

  assign store_descriptor_valid = fetch_descriptor_valid & fetch_descriptor_ready;  // need to make sure dispatcher is ready before sending descriptor to store unit
  
  
  assign fifo_fill_levels = {16'h0000, 
                             {(16-STORE_FIFO_DEPTH_LOG2){1'b0}},  // need to pad the extra MSBs
                             store_response_fill_level,
                             {(16-STORE_FIFO_DEPTH_LOG2){1'b0}},  // need to pad the extra MSBs
                             store_descriptor_fill_level,
                             {(16-FETCH_FIFO_DEPTH_LOG2){1'b0}},  // need to pad the extra MSBs
                             fetch_descriptor_fill_level};
  
  always @ (posedge clk)
  begin
    case (s_address)
      3'b000:  readdata <= {32'h00000000 , timeout, 12'h000, enable_timeout, irq_mask, flush, enable};
      3'b001:  readdata <= start_location;
      3'b010:  readdata <= {{(64-ADDRESS_WIDTH){1'b0}}, fetch_current_location};
      3'b011:  readdata <= {{(64-ADDRESS_WIDTH){1'b0}}, store_current_location};
      3'b100:  readdata <= {{(32+16-FETCH_FIFO_DEPTH_LOG2){1'b0}}, outstanding_reads, 3'h0, store_current_state, fetch_current_state, 5'h00,store_idle, fetch_idle, irq};
      default: readdata <= fifo_fill_levels;
    endcase
  end

  assign s_readdata = readdata;


endmodule
