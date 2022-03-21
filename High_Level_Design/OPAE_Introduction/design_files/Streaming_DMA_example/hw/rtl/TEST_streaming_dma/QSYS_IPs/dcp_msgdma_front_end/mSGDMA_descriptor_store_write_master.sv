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

This module recieves descriptors and responses and combines them before writing them back
to host memory.  The module writes descriptors to memory using 1CL bursts and optionally issues
interrutps to the host.


------------------
Author:  JCJB
Date:    10/24/2018
Version: 1.2
------------------

Version 1.2 - 10/24/2018 - Update to ensure when disabled that any current writes are allowed
                           to complete first.  FSM state bits also brought out so the host
                           can query them for debug purposes.

Version 1.1 - 10/01/2018 - Update to bring out the descriptor and response FIFO fill levels.
                           Also updated address logic to deal with next_descriptor arriving
                           at start of the descriptor block.

Version 1.0 - 9/13/2018 - Initial version of the module

*/

import mSGDMA_frontend_descriptor_format_pkg::*;


module mSGDMA_descriptor_store_write_master #
(
  parameter ADDRESS_WIDTH = 48,
  parameter BURST_WIDTH = 3,       // for now the master will always issue one beat bursts
  parameter FIFO_DEPTH_LOG2 = 4,   // used to size both FIFOs
  parameter IRQ_ENABLE = 1
)
(
  input clk,
  input reset,
  
  output logic [ADDRESS_WIDTH-1:0] m_address,
  output logic m_write,
  output logic [BURST_WIDTH-1:0] m_burst,
  output logic [DESCRIPTOR_FORMAT_A_WIDTH-1:0] m_writedata,
  output logic [(DESCRIPTOR_FORMAT_A_WIDTH/8)-1:0] m_byteenable,
  input m_waitrequest,

  output logic irq,
  
  input [ADDRESS_WIDTH-1:0] block_address,
  input block_address_valid,
  output logic block_address_ready,
  
  // after descriptors are issued to the dispatcher then need to be buffered in this block so that they can be written back to memory upon transfer completion
  input descriptor_format_A descriptor,
  input descriptor_valid,
  output logic descriptor_ready,
  
  // response information is mostly for ST to MM transfers that needs to be merged with decriptor (above) to form the descritor written back to host memory
  input response_format_A response,
  input response_valid,
  output logic response_ready,
  
  input sw_clear_irq,                                     // one cycle strobe from the parent that clear the IRQ output
  input irq_mask,                                         // will be used to mask the irq output
  
  input enable_store,                                     // master will not attempt to store any descriptors when disabled, software should disable and flush before setting a new descriptor location
  input flush,                                            // flush to clear out the internal buffers, use this first if abruptly setting a new descriptor location 

  output logic [ADDRESS_WIDTH-1:0] current_location,      // outputs address counter in case software wants to read it back
  output logic [FIFO_DEPTH_LOG2:0] descriptor_fill_level, // using FIFO_DEPTH_LOG2 so that the fifo full can be added to the MSB
  output logic [FIFO_DEPTH_LOG2:0] response_fill_level,   // using FIFO_DEPTH_LOG2 so that the fifo full can be added to the MSB
  output logic store_idle,
  output logic [1:0] current_state
);

  localparam DESCRIPTOR_INC_AMOUNT = (DESCRIPTOR_FORMAT_A_WIDTH/8);  // write master is issuing bursts of 1CL so only need to increment 64 bytes at a time

  // FSM returns to IDLE if enable_store is low or if there are no new descriptor blocks to store
  localparam IDLE = 2'b00;
  // one cycle state that simply loads the address counter, FSM will progress to LOAD_BLOCK one cycle later
  localparam LOAD_BLOCK_ADDRESS = 2'b01;
  // FSM remains in this state until the block of descriptors has been written back to memory
  localparam STORE_BLOCK = 2'b10;
  
  
  logic [1:0] state;

  
  descriptor_format_A final_descriptor_writeback;  // final merged copy of the original descriptor with response information merged into it


  logic [ADDRESS_WIDTH-1:0] address_counter;         // counter that increments through a block of descriptors and gets reloaded at the end of a block or host sets a new location
  logic increment_address_counter;
  logic load_next_descriptor_location;               // asserted when last descriptor in the block returns
  logic last_descriptor_in_block;                    // asserted when the last descriptor in the block is being written to memory

  // descriptor FIFO that will hold the descriptors as the DMA is operating on them so that they can be written back to memory when the DMA completes them
  descriptor_format_A descriptor_fifo_input;
  descriptor_format_A descriptor_fifo_output;
  logic descriptor_fifo_write;
  logic descriptor_fifo_read;
  logic descriptor_fifo_empty;
  logic descriptor_fifo_full;
  logic [FIFO_DEPTH_LOG2-1:0] descriptor_fifo_used;
  
  // response FIFO that will hold the responses from the dispatcher which get merged with the data from the descriptor FIFO
  response_format_A response_fifo_input;
  response_format_A response_fifo_output;
  logic response_fifo_write;
  logic response_fifo_read;
  logic response_fifo_empty;
  logic response_fifo_full;  
  logic [FIFO_DEPTH_LOG2-1:0] response_fifo_used;
  
  // if IRQ_ENABLE is set to 0 internal_irq will never assert
  logic internal_irq;
  logic set_internal_irq;
  logic clear_internal_irq;
  logic internal_irq_d1;
  logic internal_irq_d2;


/*
  FSM is fairly linear shifting between three states.
  
  IDLE --> LOAD_BLOCK_ADDRESS --> STORE_BLOCK
    ^              ^                |   |
    |              |                |   |
    |              |________________|   |
    |___________________________________|
    
  IDLE:  entered if store_enable is set or if the end of the block is stored and there is not another block of descriptors to store to memory
  
  LOAD_BLOCK_ADDRESS:  when there is a valid block address the FSM spends one clock cycle in this state loading the address counter.  This ensures
                       that the address counter is not being loaded at the same time a descriptor writeback operation is occuring.
  
  STORE_BLOCK:  this state is responsible for writing desciptors to memory.  The master write signal will only be asserted when the FSM is in this state.
*/
  always @ (posedge clk)
  begin
    if (reset | flush)
    begin
      state <= IDLE;
    end
    else if ((enable_store == 1'b0) & ((m_write == 1'b0) | ((m_write == 1'b1) & (m_waitrequest == 1'b0))))
    begin
      state <= IDLE;  // need to make sure that if a write burst starts then the FSM waits for it to complete before reaching IDLE state
    end
    else
    begin
      case (state)
        IDLE:
          if ((block_address_valid == 1'b1) & (enable_store == 1'b1))
          begin
            state <= LOAD_BLOCK_ADDRESS;
          end
          else
          begin
            state <= IDLE;
          end
        LOAD_BLOCK_ADDRESS:
            state <= STORE_BLOCK;          // one cycle state so block_address_ready is asserted here to pop the block address FIFO in the fetch engine, i.e. assume if there is a valid address it doesn't disappear
        STORE_BLOCK:
          if ((last_descriptor_in_block == 1'b1) & (block_address_valid == 1'b0))
          begin
            state <= IDLE;                 // next block is not ready so jump to IDLE state waiting for a new block address
          end
          else if ((last_descriptor_in_block == 1'b1) & (block_address_valid == 1'b1))
          begin
            state <= LOAD_BLOCK_ADDRESS;   // another block is ready to be written back to memory so skip the IDLE state
          end
          else
          begin
            state <= STORE_BLOCK;          // still more descriptors in the block to write out to memory
          end
      endcase
    end
  end
  
  assign current_state = state;   // debug signal the host can read back in the status register
  assign block_address_ready = (state == LOAD_BLOCK_ADDRESS);  // assumption made that block_address_valid is still asserted by the time FSM is in LOAD_BLOCK_ADDRESS state
  assign last_descriptor_in_block = (m_write == 1'b1) & (m_waitrequest == 1'b0) & (descriptor_fifo_output.format[1] == 1'b1);  // asserted when the last descriptor in the block is being written to memory
  

  always @ (posedge clk)
  begin
    if (load_next_descriptor_location == 1'b1)
    begin
      address_counter <= block_address;
    end
    else if (increment_address_counter == 1'b1)
    begin
      address_counter <= address_counter + DESCRIPTOR_INC_AMOUNT;
    end  
  end

  assign load_next_descriptor_location = (state == LOAD_BLOCK_ADDRESS);  // reload address_counter when last descriptor of block is written to memory
  assign increment_address_counter = (state == STORE_BLOCK) & (m_write == 1'b1) & (m_waitrequest == 1'b0);
  assign current_location = address_counter;
  

  always @ (posedge clk)
  begin
    if (reset)
    begin
      internal_irq <= 1'b0;
    end
    else if (clear_internal_irq)
    begin
      internal_irq <= 1'b0;
    end
    else if (set_internal_irq)
    begin
      internal_irq <= 1'b1;
    end
  end
  
  
  always @ (posedge clk)
  begin
    internal_irq_d1 <= internal_irq;
    internal_irq_d2 <= internal_irq_d1;
  end
  
  
  assign clear_internal_irq = sw_clear_irq;
  assign set_internal_irq = ((IRQ_ENABLE == 1) & (m_write == 1'b1) & (m_waitrequest == 1'b0)) & 
                              (
                                (response_fifo_output.transfer_complete_IRQ_mask == 1'b1) |
                                ((response_fifo_output.error_IRQ_mask & response_fifo_output.error) != 8'h0) |
                                (response_fifo_output.early_termination_IRQ_mask & response_fifo_output.early_termination) |
                                (response_fifo_output.eop_arrived_IRQ_mask & response_fifo_output.eop_arrived)
                              );
  assign irq = internal_irq_d2 & irq_mask;
  


  scfifo #
  (
		.lpm_width                (DESCRIPTOR_FORMAT_A_WIDTH),
		.lpm_widthu               (FIFO_DEPTH_LOG2),
		.lpm_numwords             (2**FIFO_DEPTH_LOG2),
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
    .full        (descriptor_fifo_full)
  );

  assign descriptor_fifo_input = descriptor;
  assign descriptor_fifo_write = descriptor_valid & descriptor_ready;
  assign descriptor_fifo_read = (m_write == 1'b1) & (m_waitrequest == 1'b0);
  assign descriptor_ready = ~descriptor_fifo_full;
  assign descriptor_fill_level = {descriptor_fifo_full, descriptor_fifo_used};  // tacking on fifo full so that software can tell the difference between a full and empty FIFO
  
  
  scfifo #
  (
		.lpm_width                (RESPONSE_FORMAT_A_WIDTH),
		.lpm_widthu               (FIFO_DEPTH_LOG2),
		.lpm_numwords             (2**FIFO_DEPTH_LOG2),
		.add_ram_output_register  ("ON"),
    .lpm_showahead            ("ON"),
		.overflow_checking        ("OFF"),
		.underflow_checking       ("OFF"),
    .ram_block_type           ("AUTO"),
		.use_eab                  ("ON") 
  ) response_fifo
  (
		.sclr        (reset | flush),
		.clock       (clk),
		.data        (response_fifo_input),
		.q           (response_fifo_output),
		.wrreq       (response_fifo_write),
		.rdreq       (response_fifo_read),
    .usedw       (response_fifo_used),
		.empty       (response_fifo_empty),
    .full        (response_fifo_full)
  );

  assign response_fifo_input = response;
  assign response_fifo_write = response_valid & response_ready;
  assign response_fifo_read = (m_write == 1'b1) & (m_waitrequest == 1'b0);
  assign response_ready = ~response_fifo_full;
  assign response_fill_level = {response_fifo_full, response_fifo_used};  // tacking on fifo full so that software can tell the difference between a full and empty FIFO


  // merge the contents of the descriptor and response FIFOs for the descriptor writeback operation
  assign final_descriptor_writeback.format = descriptor_fifo_output.format;
  assign final_descriptor_writeback.block_size = descriptor_fifo_output.block_size;
  assign final_descriptor_writeback.owned_by_hw = 1'b0;
  assign final_descriptor_writeback.rsvd0 = 'b0;
  assign final_descriptor_writeback.control = descriptor_fifo_output.control;
  assign final_descriptor_writeback.source = descriptor_fifo_output.source;
  assign final_descriptor_writeback.destination = descriptor_fifo_output.destination;
  assign final_descriptor_writeback.length = descriptor_fifo_output.length;
  assign final_descriptor_writeback.rsvd1 = 'b0;
  assign final_descriptor_writeback.sequence_num = descriptor_fifo_output.sequence_num;
  assign final_descriptor_writeback.read_burst = descriptor_fifo_output.read_burst;
  assign final_descriptor_writeback.write_burst = descriptor_fifo_output.write_burst;
  assign final_descriptor_writeback.read_stride = descriptor_fifo_output.read_stride;
  assign final_descriptor_writeback.write_stride = descriptor_fifo_output.write_stride;
  assign final_descriptor_writeback.actual_bytes_transferred = response_fifo_output.actual_bytes_transferred;
  assign final_descriptor_writeback.error = response_fifo_output.error;
  assign final_descriptor_writeback.eop_arrived = response_fifo_output.eop_arrived;
  assign final_descriptor_writeback.rsvd2 = 'b0;
  assign final_descriptor_writeback.early_termination = response_fifo_output.early_termination;
  assign final_descriptor_writeback.rsvd3 = 'b0;
  assign final_descriptor_writeback.next_descriptor = descriptor_fifo_output.next_descriptor;

  
  
  assign m_address = address_counter;
  assign m_byteenable = {(DESCRIPTOR_FORMAT_A_WIDTH/8){1'b1}};
  assign m_write = (state == STORE_BLOCK) & (descriptor_fifo_empty == 1'b0) & (response_fifo_empty == 1'b0);
  assign m_burst = 'h1;         // master is going to only write a descriptor back per burst to minimize completion latency and simplify this logic
  assign m_writedata = {
                        final_descriptor_writeback.next_descriptor,
                        final_descriptor_writeback.rsvd3,
                        final_descriptor_writeback.early_termination,
                        final_descriptor_writeback.rsvd2,
                        final_descriptor_writeback.eop_arrived,
                        final_descriptor_writeback.error,
                        final_descriptor_writeback.actual_bytes_transferred,
                        final_descriptor_writeback.write_stride,
                        final_descriptor_writeback.read_stride,
                        final_descriptor_writeback.write_burst,
                        final_descriptor_writeback.read_burst,
                        final_descriptor_writeback.sequence_num,
                        final_descriptor_writeback.rsvd1,
                        final_descriptor_writeback.length,
                        final_descriptor_writeback.destination,
                        final_descriptor_writeback.source,
                        final_descriptor_writeback.control,
                        final_descriptor_writeback.rsvd0,
                        final_descriptor_writeback.owned_by_hw,
                        final_descriptor_writeback.block_size,
                        final_descriptor_writeback.format
                       };
  
  assign store_idle = (state == IDLE);
  
endmodule
