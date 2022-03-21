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

There are a lot of fields in the descriptor so this file provides structs
to make this easier to deal with.

------------------
Author:  JCJB
Date:    9/07/2018
Version: 1.0
------------------

Version 1.0 - Initial version of the package

*/

package mSGDMA_frontend_descriptor_format_pkg;



typedef struct packed {
  logic [7:0] transmit_channel;              // [7:0]
  logic generate_sop;                        // [8]
  logic generate_eop;                        // [9]
  logic park_reads;                          // [10]
  logic park_writes;                         // [11]
  logic end_on_eop;                          // [12]
  logic eop_received_irq_mask;               // [13]
  logic transfer_complete_irq_mask;          // [14]
  logic early_termination_irq_mask;          // [15]
  logic [7:0] transmit_error_error_irq_mask; // [23:16]
  logic early_done_enable;                   // [24]
  logic wait_for_write_response;             // [25]
  logic [4:0] rsvd;                          // [30:26]
  logic go;                                  // [31]  this bit is not used when the prefetcher pushes descriptors into the dispatcher over AvST 
} control_format_A;
parameter CONTROL_FORMAT_A_WIDTH = $bits(control_format_A);


/*
  Format table:
  
  2'b00 --> neither first or last descriptor of the block
  2'b01 --> first descriptor of the block
  2'b10 --> last descriptor of the block
  2'b11 --> first and last descriptor of the block (i.e. block_size = 0)
*/

typedef struct packed {
  logic [7:0] format;                    // [7:0]     see table above for formatting
  logic [7:0] block_size;                // [15:8]    set to block size -1 (i.e. the number of remaining descriptors in a block)
  logic owned_by_hw;                     // [16]      set only after the rest of the fields have been set so that DMA doesn't read partially populated descriptors
  logic [14:0] rsvd0;                    // [31:17]
  control_format_A control;              // [63:32]
  logic [63:0] source;                   // [127:64]
  logic [63:0] destination;              // [191:128]
  logic [31:0] length;                   // [223:192]
  logic [31:0] rsvd1;                    // [255:224]
  logic [15:0] sequence_num;             // [271:256]
  logic [7:0] read_burst;                // [279:272]
  logic [7:0] write_burst;               // [287:280]
  logic [15:0] read_stride;              // [303:288]
  logic [15:0] write_stride;             // [319:304]
  logic [31:0] actual_bytes_transferred; // [351:320]
  logic [7:0] error;                     // [359:352]
  logic eop_arrived;                     // [360]
  logic [6:0] rsvd2;                     // [367:361]
  logic early_termination;               // [368]
  logic [78:0] rsvd3;                    // [447:369]
  logic [63:0] next_descriptor;          // [511:448]
} descriptor_format_A;
parameter DESCRIPTOR_FORMAT_A_WIDTH = $bits(descriptor_format_A);



typedef struct packed {
  logic [31:0] actual_bytes_transferred; // [31:0]
  logic [7:0] error;                     // [39:32]
  logic early_termination;               // [40]
  logic transfer_complete_IRQ_mask;      // [41]
  logic [7:0] error_IRQ_mask;            // [49:42]
  logic early_termination_IRQ_mask;      // [50]
  logic eop_arrived_IRQ_mask;            // [51]
  logic eop_arrived;                     // [52]
  logic descriptor_buffer_full;          // [53]    this bit does not follow AvST flow control and toggles at any time
} response_format_A;
parameter RESPONSE_FORMAT_A_WIDTH = $bits(response_format_A);


endpackage 
