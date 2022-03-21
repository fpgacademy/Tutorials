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

This module fetches descriptors from main memory and presents them to the mSGDMA
dispatcher IP.  Descriptors are grouped into blocks that can have a block size of
1-256 and each block forms a link in a linked-list.  So a block size of 1 will
cause the descriptors to form a typical linked-list which is fine in low latency
systems but not for high latency systems were the descriptor fetch may take longer
than the DMA transfers themselves.

This module fetches descriptors by reading the first descriptor in a block and
using the block size field to determine how many more sequential reads are needed
to complete reading the block.  The read master will issue these as full bursts
to improve the bandwidth across high latancy links.  The last descriptor in the block
stores a next descriptor field that points to the next block of descriptors.  As a
result the host must ensure there is an invalid descriptor at the end of the linked-list
to ensure the DMA stops.  Once the DMA stops (ran out of work to do)
this module will periodically re-fetch the same block it stopped on waiting for the
driver to make that block valid and the DMA will start performing more transfers
without any other intervention from the host.

The descriptors support four formats, depending on where the desriptor resides in
the block.  This allows the module to inspect the contents returned when they are
fetched and take different actions rather than this block needing to track this
internally.  The format field is 8-bit but only the two LSBs are used as follows:

2'b00 --> neither the first or last descriptor in the block
2'b01 --> first descriptor in the block
2'b10 --> last descriptor in the block
2'b11 --> first and only descriptor in the block

The output of this module is the buffered 512-bit descriptors fetched from memory.
The descriptors are presented as a AvST interface with a ready-valid handshake.
The depth of this FIFO should be configured to be at least 2x the maximum expected
descriptor block size.

Before the fetch unit can start fetching descriptors from memory it needs to be told
where the first block lives in memory.  The host must only update this location
while the module is enabled.  If the fetching operations must be stopped and a new
location be used, software should perform these steps:

Disable module --> assert flush --> wait for pending reads to reach 0 --> deassert flush

Then to set a new block location follow these steps:

Set new block address --> enable module


------------------
Author:  JCJB
Date:    10/24/2018
Version: 1.2
------------------

Version 1.2 - 10/24/2018 - Added check to enable_fetch to make sure the FSM doesn't return
                           to the idle state in the middle of a read.  The FSM state value
                           is also added so that software can queue the state of the hardware
                           for debug purposes.

Version 1.1 - 10/01/2018 - Updated next descriptor to live at start of block instead of
                           the end.  This allows fetch engine to move onto the next block
                           without waiting for the end of the previous block to return.

Version 1.0 - 9/07/2018 - Initial version of the module

*/

import mSGDMA_frontend_descriptor_format_pkg::*;


module mSGDMA_descriptor_fetch_read_master #
(
  parameter ADDRESS_WIDTH = 48,
  parameter BURST_WIDTH = 3,
  parameter FIFO_DEPTH_LOG2 = 6
)
(
  input clk,
  input reset,
  
  output logic [ADDRESS_WIDTH-1:0] m_address,
  output logic m_read,
  output logic [BURST_WIDTH-1:0] m_burst,
  input [DESCRIPTOR_FORMAT_A_WIDTH-1:0] m_readdata,  
  input m_readdatavalid,
  output logic [(DESCRIPTOR_FORMAT_A_WIDTH/8)-1:0] m_byteenable,
  input m_waitrequest,

  output descriptor_format_A descriptor,
  output logic descriptor_valid,
  input descriptor_ready,
  
  output logic [ADDRESS_WIDTH-1:0] block_address,
  output logic block_address_valid,
  input block_address_ready,
  
  input enable_fetch,                                     // master will not attempt to load any descriptors when disabled, software should disable and flush before setting a new descriptor location
  input flush,                                            // flush to clear out the internal buffer, use this first if abruptly setting a new descriptor location 
  input [63:0] new_descriptor_location,                   // used to load the first descriptor location or reload to a new location
  input load_new_descriptor_location,                     // enable_fetch should be low before load_new_descriptor_location strobes
  input [15:0] descriptor_timeout,                        // number of clock ticks after DMA runs out of descriptors that it attempts to re-fetch a descriptor
  input enable_descriptor_timeout,                        // if enabled FSM will reach RETRY_FIRST_LOAD state when no more descriptors are available, otherwise WAIT_FOR_ADDRESS_RELOAD is entered
  output logic [FIFO_DEPTH_LOG2-1:0] outstanding_reads,   // number outstanding descriptor reads
  output logic [ADDRESS_WIDTH-1:0] current_location,      // outputs address counter in case software wants to read it back
  output logic [FIFO_DEPTH_LOG2:0] descriptor_fill_level, // using FIFO_DEPTH_LOG2 so that the fifo full can be added to the MSB
  output logic fetch_idle,
  output logic [2:0] current_state
);

  // 64 bytes or 256 bytes depending on if the master is issuing a 1CL or 4CL read
  localparam INCREMENT_1CL = (DESCRIPTOR_FORMAT_A_WIDTH/8);
  localparam INCREMENT_4CL = INCREMENT_1CL << 2;
  
  // idle state where FSM sits if the block is disabled or if LOAD_FIRST state needs to be re-entered
  localparam IDLE = 3'h0;
  // a one clock cycle state used to make sure the address counter is loaded before reads are issued
  localparam LOAD_COUNTER = 3'h1;
  // loads the first descriptor in a block, if the descriptor is invalid then move to RETRY_FIRST_LOAD, otherwise move to LOAD_RESET if there is more descriptors
  localparam LOAD_FIRST = 3'h2;
  // loads the remaining descriptors in a block
  localparam LOAD_REST = 3'h3;
  // starts timeout period before re-entering the LOAD_FIRST state
  localparam RETRY_FIRST_LOAD = 3'h4;
  // if timeout polling is not enable this state is reached when the end of the descriptor chain is hit.  When address_counter is reloaded will return to LOAD_FIRST state
  localparam WAIT_FOR_ADDRESS_RELOAD = 3'h5;

  
  logic [2:0] state;   
  

  /* address counter starts at the next_descriptor_location and increments through the block, on the last descriptor of the block the counter is reloaded 
     with the next address field of the descriptor */
  logic [ADDRESS_WIDTH-1:0] address_counter;         // counter that increments through a block of descriptors and gets reloaded at the end of a block or host sets a new location
  logic increment_address_counter;
  logic load_next_descriptor_location;               // asserted when last descriptor in the block returns
  logic [ADDRESS_WIDTH-1:0] next_address;
  logic store_next_address;


  /* on the first descriptor of a block, the block counter is loaded with the block size field of the descriptor, after each descriptor load this counter 
     counts down until it hits 0.  When it's zero (last descriptor of the block) the FSM proceeds to load the next block of descriptors */
  logic [7:0] block_counter;
  logic load_block_counter;
  logic decrement_block_counter;
  
  logic enable_4cl_fetch;
  
  descriptor_format_A descriptor_fifo_input;
  descriptor_format_A descriptor_fifo_output;
  logic descriptor_fifo_write;
  logic descriptor_fifo_read;
  logic descriptor_fifo_empty;
  logic descriptor_fifo_almost_full;
  logic [FIFO_DEPTH_LOG2-1:0] descriptor_fifo_used;
  logic descriptor_fifo_full;
  
  logic [ADDRESS_WIDTH-1:0] address_fifo_input;
  logic [ADDRESS_WIDTH-1:0] address_fifo_output;
  logic address_fifo_write;
  logic address_fifo_read;
  logic address_fifo_empty;
  
  logic [FIFO_DEPTH_LOG2-1:0] reads_counter;
  logic increment_reads_counter;
  logic decrement_reads_counter;
  
  logic first_read_complete;
  logic set_first_read_complete;
  logic clear_first_read_complete;
  logic read_active;
  logic set_read_active;
  logic clear_read_active;
  
  logic [15:0] descriptor_timeout_counter;
  logic clear_descriptor_timeout_counter;
  logic trigger_descriptor_refetch;
  logic trigger_descriptor_refetch_d1;
  
  logic too_many_reads;

/*
FSM Details:
                  |----------------|
                  |                |
                 \|/               |      ------> RETRY_FIRST_LOAD ----> IDLE
IDLE ----> LOAD_COUNTER ----> LOAD_FIRST
                  ^                |      ------> WAIT_FOR_ADDRESS_RELOAD ----> IDLE
                  |                |
                  |               \|/
                  |----------- LOAD_REST

The FSM always returns to idle when fetching is disabled.

LOAD_COUNTER is a one clock cycle state that makes sure the address counter is loaded before a block is read

LOAD_FIRST issues a single 1CL read of the first descriptor of the block.  If the first descriptor of the block
is valid and there are more descriptors in the block then the FSM will proceed to LOAD_REST.  If the first descriptor
of the block is valid but is the only valid descriptor in the block the FSM will proceed to LOAD_COUNTER.  If the
first descriptor is invalid (owned_by_hw = 0) then the FSM will either proceed to RETRY_FIRST_LOAD or
WAIT_FOR_ADDRESS_RELOAD depending on whether the descriptor timeout is enabled.

LOAD_REST issues burst reads of 1 or 4CL until the last descriptor in the block has been fetched and then
the FSM returns to LOAD_COUNTER to prepare for the next descriptor block read.

RETRY_FIRST_LOAD counts until the timeout is reached before returning to LOAD_COUNTER

WAIT_FOR_ADDRESS_RELOAD stalls until the host writes a new descriptor block location
*/ 
  always @ (posedge clk)
  begin
    if (reset | flush)
    begin
      state <= IDLE;
    end
    else if ((enable_fetch == 1'b0) & ((m_read == 1'b0) | ((m_read == 1'b1) & (m_waitrequest == 1'b0))))
    begin
      state <= IDLE;  // need to make sure if read and waitrequest are asserted at the same time the FSM lets that read complete first
    end
    else
    begin
      case (state)
        IDLE:
            if (enable_fetch == 1'b1)
            begin
              state <= LOAD_COUNTER;  // host needs to make sure the first block location was stored before enabling the fetching
            end
        LOAD_COUNTER:
            state <= LOAD_FIRST;   // just a 1 cycle state
        LOAD_FIRST:
            if (m_readdatavalid & (descriptor_fifo_input.owned_by_hw == 1'b0))    // first descriptor in block was not valid so end of the descriptor chain was hit
            begin
              if (enable_descriptor_timeout == 1'b1)
              begin
                state <= RETRY_FIRST_LOAD;
              end
              else
              begin
                state <= WAIT_FOR_ADDRESS_RELOAD;  // timeout wasn't enabled so need to wait for host to reload address_counter
              end
            end
            else if (m_readdatavalid & (descriptor_fifo_input.owned_by_hw == 1'b1) & (descriptor_fifo_input.block_size == 8'h00) & (descriptor_fifo_input.format[0] == 1'b1))
            begin
              state <= LOAD_COUNTER;  // valid block but it only had one descriptor so skip LOAD_REST and return to LOAD_COUNTER state
            end
            else if (m_readdatavalid & (descriptor_fifo_input.owned_by_hw == 1'b1) & (descriptor_fifo_input.format[0] == 1'b1))
            begin
              state <= LOAD_REST;     // block is valid and the block contains 2 or more descriptors
            end
            else
            begin
              state <= LOAD_FIRST;    // spin waiting for the first descriptor to return
            end
        LOAD_REST:
            if ((block_counter == m_burst) & (m_read == 1'b1) & (m_waitrequest == 1'b0))
            begin
              state <= LOAD_COUNTER;  // issued read of the last descriptor in the block has been posted so move on to loading the next block
            end
            else
            begin
              state <= LOAD_REST;
            end
        RETRY_FIRST_LOAD:
            if (trigger_descriptor_refetch_d1)
            begin
              state <= IDLE;  // waited for the timeout period so go back to loading the first discriptor of the block
            end
            else
            begin
              state <= RETRY_FIRST_LOAD;  // spin waiting for timeout to occur
            end
        WAIT_FOR_ADDRESS_RELOAD:
            if (load_new_descriptor_location == 1'b1)
            begin
              state <= IDLE;   // host loaded the address_counter so go back to actively fetching descriptors
            end
            else
            begin
              state <= WAIT_FOR_ADDRESS_RELOAD;  // spin waiting for the host to load a first descriptor location
            end
      endcase
    end
  end

  assign current_state = state;  // sent to the top so that software can read this for debug purposes

  always @ (posedge clk)
  begin
    if (load_new_descriptor_location == 1'b1)
    begin
      next_address <= new_descriptor_location[ADDRESS_WIDTH-1:0];               // host loaded
    end
    else if (store_next_address == 1'b1)
    begin
      next_address <= descriptor_fifo_input.next_descriptor[ADDRESS_WIDTH-1:0]; // descriptor loaded (from first descriptor in block)
    end
  end
 
  // if the first descriptor isn't valid then keep the old current address around to reattempt to load the block if the timeout feature is enabled
  assign store_next_address = (m_readdatavalid == 1'b1) & (descriptor_fifo_input.owned_by_hw == 1'b1) & (descriptor_fifo_input.format[0] == 1'b1);
  // if the block_size is 0 then need to ignore next_address and load the next_descriptor into address_counter directly
  assign single_descriptor_block_returned = (m_readdatavalid == 1'b1) & (descriptor_fifo_input.owned_by_hw == 1'b1) & (descriptor_fifo_input.format[0] == 1'b1) & (descriptor_fifo_input.block_size == 8'h00);


  always @ (posedge clk)
  begin
    if (load_next_descriptor_location == 1'b1)
    begin
      address_counter <= next_address;
    end
    else if (increment_address_counter == 1'b1)
    begin
      address_counter <= address_counter + ((enable_4cl_fetch == 1'b1)? INCREMENT_4CL : INCREMENT_1CL);
    end  
  end
  
  assign load_next_descriptor_location = (state == LOAD_COUNTER);
  assign increment_address_counter = ((state == LOAD_FIRST) & (m_readdatavalid == 1'b1) & (descriptor_fifo_input.owned_by_hw == 1'b1) & (descriptor_fifo_input.format[0] == 1'b1)) |    // increment if block starts with a valid descriptor
                                     ((state == LOAD_REST) & (m_read == 1'b1) & (m_waitrequest == 1'b0));  // increment if read is posted while the rest of the block is being fetched
  assign current_location = address_counter;
  assign enable_4cl_fetch = (state == LOAD_REST) & (block_counter >= 3'h4) & (address_counter[8:6] == 3'h4);  // making sure address is aligned to 4CL before posting 4CL burst
  

  // when the first descriptor in block returns load block_counter and decrement it each time a read burst is posted
  always @ (posedge clk)
  begin
    if (reset)
    begin
      block_counter <= 8'h00;
    end
    else if (load_block_counter)
    begin
      block_counter <= descriptor_fifo_input.block_size;
    end
    else if (decrement_block_counter)
    begin
      block_counter <= block_counter - m_burst;
    end
  end

  assign load_block_counter = (m_readdatavalid == 1'b1) & (descriptor_fifo_input.owned_by_hw == 1'b1) & (descriptor_fifo_input.format[0] == 1'b1);
  assign decrement_block_counter = (state == LOAD_REST) & (m_read == 1'b1) & (m_waitrequest == 1'b0);
  
  
  scfifo #
  (
    .lpm_width                (DESCRIPTOR_FORMAT_A_WIDTH),
    .lpm_widthu               (FIFO_DEPTH_LOG2),
    .lpm_numwords             (2**FIFO_DEPTH_LOG2),
    .almost_full_value        ((2**FIFO_DEPTH_LOG2)/2),  // this will allow there to be up to (2**FIFO_DEPTH_LOG2)/2 descriptor reads to be inflight
    .add_ram_output_register  ("ON"),
    .lpm_showahead            ("ON"),
    .overflow_checking        ("OFF"),
    .underflow_checking       ("OFF"),
    .ram_block_type           ("AUTO"),
    .use_eab                  ("ON") 
  ) descriptor_fifo
  (
    .sclr        (reset | flush),
    .clock       (clk),
    .data        (descriptor_fifo_input),
    .q           (descriptor_fifo_output),
    .wrreq       (descriptor_fifo_write),
    .rdreq       (descriptor_fifo_read),
    .usedw       (descriptor_fifo_used),
    .empty       (descriptor_fifo_empty),
    .almost_full (descriptor_fifo_almost_full),
	  .full        (descriptor_fifo_full)
  );
  
  assign descriptor_fifo_write = m_readdatavalid & descriptor_fifo_input.owned_by_hw;  // only buffer valid descriptors
  assign descriptor_fifo_read = descriptor_valid & descriptor_ready;
  assign descriptor = descriptor_fifo_output;
  assign descriptor_valid = ~descriptor_fifo_empty;
  assign descriptor_fill_level = {descriptor_fifo_full, descriptor_fifo_used};  // tacking on fifo full so that software can tell the difference between a full and empty FIFO
  assign descriptor_fifo_input.format = m_readdata[7:0];
  assign descriptor_fifo_input.block_size = m_readdata[15:8];
  assign descriptor_fifo_input.owned_by_hw = m_readdata[16];
  assign descriptor_fifo_input.rsvd0 = 'b0;
  assign descriptor_fifo_input.control = m_readdata[63:32];
  assign descriptor_fifo_input.source = m_readdata[127:64];
  assign descriptor_fifo_input.destination = m_readdata[191:128];
  assign descriptor_fifo_input.length = m_readdata[223:192];
  assign descriptor_fifo_input.rsvd1 = 'b0;
  assign descriptor_fifo_input.sequence_num = m_readdata[271:256];
  assign descriptor_fifo_input.read_burst = m_readdata[279:272];
  assign descriptor_fifo_input.write_burst = m_readdata[287:280];
  assign descriptor_fifo_input.read_stride = m_readdata[303:288];
  assign descriptor_fifo_input.write_stride = m_readdata[319:304];
  assign descriptor_fifo_input.actual_bytes_transferred = 'b0;      // can ground this since it will be provided by response in descriptor writeback
  assign descriptor_fifo_input.error = m_readdata[359:352];
  assign descriptor_fifo_input.eop_arrived = 'b0;                   // can ground this since it will be provided by response in descriptor writeback
  assign descriptor_fifo_input.rsvd2 = 'b0;
  assign descriptor_fifo_input.early_termination = 'b0;             // can ground this since it will be provided by response in descriptor writeback
  assign descriptor_fifo_input.rsvd3 = 'b0;
  assign descriptor_fifo_input.next_descriptor = m_readdata[511:448];
  
  
  // every time a valid first descriptor of the block is loaded stuff it into this FIFO so that the store engine knows where to start writing
  scfifo #
  (
    .lpm_width                (ADDRESS_WIDTH),
    .lpm_widthu               (FIFO_DEPTH_LOG2),
    .lpm_numwords             (2**FIFO_DEPTH_LOG2),
    .add_ram_output_register  ("ON"),
    .lpm_showahead            ("ON"),
    .overflow_checking        ("OFF"),
    .underflow_checking       ("OFF"),
    .ram_block_type           ("AUTO"),
    .use_eab                  ("ON") 
  ) block_fifo
  (
    .sclr        (reset | flush),
    .clock       (clk),
    .data        (address_fifo_input),
    .q           (address_fifo_output),
    .wrreq       (address_fifo_write),
    .rdreq       (address_fifo_read),
    .empty       (address_fifo_empty)
  );
  
  assign address_fifo_input = address_counter;  // need to store this now before the address_counter increments on the next cycle
  assign address_fifo_write = (state == LOAD_FIRST) & (m_readdatavalid == 1'b1) & (descriptor_fifo_input.owned_by_hw == 1'b1) & (descriptor_fifo_input.format[0] == 1'b1);
  assign block_address = address_fifo_output;
  assign address_fifo_read = block_address_valid & block_address_ready;
  assign block_address_valid = ~address_fifo_empty;
  
  
  always @ (posedge clk)
  begin
    if (reset)
    begin
      reads_counter <= 'b0;
    end
    else
    begin
      case ({increment_reads_counter, decrement_reads_counter})
        2'b00:  reads_counter <= reads_counter;
        2'b01:  reads_counter <= reads_counter - 1'b1;
        2'b10:  reads_counter <= reads_counter + m_burst;
        2'b11:  reads_counter <= reads_counter + m_burst - 1'b1;
      endcase
    end
  end
  
  assign increment_reads_counter = (m_read == 1'b1) & (m_waitrequest == 1'b0);
  assign decrement_reads_counter = m_readdatavalid;
  /* If the FIFO is half full or there is a half of FIFO worth of reads in flight start backpressuring.  This isn't the most efficient use of the FIFO storage
     but it's very simple. */
  assign too_many_reads = reads_counter[FIFO_DEPTH_LOG2-1] | descriptor_fifo_almost_full;
  assign outstanding_reads = reads_counter;  // signal that host can query

  
  // this counter determines how many clock cycles the master should wait before re-attempting to fetch a new descriptor
  always @ (posedge clk)
  begin
    if (reset | clear_descriptor_timeout_counter)
    begin
      descriptor_timeout_counter <= 'h6;  // using 6 to account for pipelining and state transistions
    end
    else
    begin
      descriptor_timeout_counter <= descriptor_timeout_counter + 1'b1;
    end
  end
  
  assign clear_descriptor_timeout_counter = (state != RETRY_FIRST_LOAD);  // hold the timeout at 0 until FSM begins timeout process


  // since trigger_descriptor_refetch is pipeline host can subtrack 1 from this value to adjust for it
  always @ (posedge clk)
  begin
    trigger_descriptor_refetch_d1 <= trigger_descriptor_refetch;
  end
  
  assign trigger_descriptor_refetch = (state == RETRY_FIRST_LOAD) & (descriptor_timeout_counter >= descriptor_timeout);  // using >= in case software programs too low of a timeout


  always @ (posedge clk)
  begin
    if (reset | clear_first_read_complete)
    begin
      first_read_complete <= 1'b0;
    end
    else if (set_first_read_complete)
    begin
      first_read_complete <= 1'b1;
    end
  end
  
  // need to make sure first_read_complete is low before LOAD_FIRST is entered.  first_read_complete will be used to gate the read signal
  assign set_first_read_complete = (state == LOAD_FIRST) & (m_read == 1'b1) & (m_waitrequest == 1'b0);
  assign clear_first_read_complete = (state == LOAD_COUNTER);  // one cycle state so as the block address is being loaded read_complete will be cleared
  

  always @ (posedge clk)
  begin
    if (reset | clear_read_active)  // clearing must win
    begin
      read_active <= 1'b0;
    end
    else if (set_read_active)
    begin
      read_active <= 1'b1;
    end
  end
  
  
  assign clear_read_active = ((state == LOAD_FIRST) & (m_read == 1'b1) & (m_waitrequest == 1'b0)) |   // this state only issues one read so if it started we have to let it finish (no point gating with too_many_reads)
                             ((state == LOAD_REST) & (m_read == 1'b1) & (m_waitrequest == 1'b0) & (too_many_reads == 1'b1)) |  // cannot deassert read so backpressure after read is posted
                             ((state == LOAD_REST) & (m_read == 1'b1) & (m_waitrequest == 1'b0) & (block_counter == m_burst)) |   // last read of block issued so deassert read
			     ((state == IDLE));			     
  
  assign set_read_active = ((state == LOAD_FIRST) & (first_read_complete == 1'b0) & (too_many_reads == 1'b0)) |  // only start the read if there is room to buffer the first descriptor
                           ((state == LOAD_REST) & (too_many_reads == 1'b0));  // while in LOAD_REST, keep read asserted unless there is no room to catch the desriptors
  
  assign m_address = address_counter;
  assign m_read = read_active;
  assign m_burst = (enable_4cl_fetch == 1)? 'h4 : 'h1;
  assign m_byteenable = {(DESCRIPTOR_FORMAT_A_WIDTH/8){1'b1}};
  
  assign fetch_idle = (state == IDLE) | (state == WAIT_FOR_ADDRESS_RELOAD);
  
endmodule
