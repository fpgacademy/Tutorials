
// ***************************************************************************
// Copyright (c) 2017, Intel Corporation
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

import ccip_if_pkg::*;
import ccip_avmm_pkg::*;
`include "platform_if.vh"

module dma_test_system_wrapper 
  #(
    parameter NUM_LOCAL_MEM_BANKS=2
    )
   (
	// ---------------------------global signals-------------------------------------------------
        input	host_clk_clk,	  //              in    std_logic;           Core clock. CCI interface is synchronous to this clock.
        input	reset_reset,	  //              in    std_logic;           CCI interface reset. The Accelerator IP must use this Reset. ACTIVE HIGH

        output	dma_irq_irq,

`ifdef PLATFORM_PROVIDES_LOCAL_MEMORY
    // Local memory interface
    avalon_mem_if.to_fiu local_mem[NUM_LOCAL_MEM_BANKS],
`endif
        output                                     ccip_avmm_mmio_waitrequest,         //       ccip_avmm_mmio.waitrequest
        output [CCIP_AVMM_MMIO_DATA_WIDTH-1:0]     ccip_avmm_mmio_readdata,            //                    .readdata
        output                                     ccip_avmm_mmio_readdatavalid,       //                    .readdatavalid
        input                                      ccip_avmm_mmio_burstcount,          //                    .burstcount
        input  [CCIP_AVMM_MMIO_DATA_WIDTH-1:0]     ccip_avmm_mmio_writedata,           //                    .writedata
        input  [CCIP_AVMM_MMIO_ADDR_WIDTH-1:0]     ccip_avmm_mmio_address,             //                    .address
        input                                      ccip_avmm_mmio_write,               //                    .write
        input                                      ccip_avmm_mmio_read,                //                    .read
        input  [(CCIP_AVMM_MMIO_DATA_WIDTH/8)-1:0] ccip_avmm_mmio_byteenable,          //                    .byteenable
        input                                      ccip_avmm_mmio_debugaccess,         //                    .debugaccess

        input                                           ccip_avmm_requestor_wr_waitrequest,   // ccip_avmm_requestor.waitrequest
        input  [CCIP_AVMM_REQUESTOR_DATA_WIDTH-1:0]     ccip_avmm_requestor_wr_readdata,      //                    .readdata
        input                                           ccip_avmm_requestor_wr_readdatavalid, //                    .readdatavalid
        output [CCIP_AVMM_REQUESTOR_BURST_WIDTH-1:0]    ccip_avmm_requestor_wr_burstcount,    //                    .burstcount
        output [CCIP_AVMM_REQUESTOR_DATA_WIDTH-1:0]     ccip_avmm_requestor_wr_writedata,     //                    .writedata
        output [CCIP_AVMM_REQUESTOR_WR_ADDR_WIDTH-1:0]  ccip_avmm_requestor_wr_address,       //                    .address
        output                                          ccip_avmm_requestor_wr_write,         //                    .write
        output                                          ccip_avmm_requestor_wr_read,          //                    .read
        output [(CCIP_AVMM_REQUESTOR_DATA_WIDTH/8)-1:0] ccip_avmm_requestor_wr_byteenable,    //                    .byteenable
        output                                          ccip_avmm_requestor_wr_debugaccess,   //                    .debugaccess
        
        input                                           ccip_avmm_requestor_rd_waitrequest,   // ccip_avmm_requestor.waitrequest
        input  [CCIP_AVMM_REQUESTOR_DATA_WIDTH-1:0]     ccip_avmm_requestor_rd_readdata,      //                    .readdata
        input                                           ccip_avmm_requestor_rd_readdatavalid, //                    .readdatavalid
        output [CCIP_AVMM_REQUESTOR_BURST_WIDTH-1:0]    ccip_avmm_requestor_rd_burstcount,    //                    .burstcount
        output [CCIP_AVMM_REQUESTOR_DATA_WIDTH-1:0]     ccip_avmm_requestor_rd_writedata,     //                    .writedata
        output [CCIP_AVMM_REQUESTOR_RD_ADDR_WIDTH-1:0]  ccip_avmm_requestor_rd_address,       //                    .address
        output                                          ccip_avmm_requestor_rd_write,         //                    .write
        output                                          ccip_avmm_requestor_rd_read,          //                    .read
        output [(CCIP_AVMM_REQUESTOR_DATA_WIDTH/8)-1:0] ccip_avmm_requestor_rd_byteenable,    //                    .byteenable
        output                                          ccip_avmm_requestor_rd_debugaccess    //                    .debugaccess
);

`ifdef PLATFORM_PROVIDES_LOCAL_MEMORY

    // memory map offset for byte address, used to align port concatination
    logic [5:0] 	   mm_byte_offset[NUM_LOCAL_MEM_BANKS];

    // DMA will send out bursts of 4 (max) to the memory controllers
    genvar n;
    generate
       for (n = 0; n < NUM_LOCAL_MEM_BANKS; n = n + 1)
 	begin : mem_burstcount
 	   assign local_mem[n].burstcount[6:3] = '0;
 	end
    endgenerate
   
`endif

    dma_test_system u0 (
`ifdef PLATFORM_PROVIDES_LOCAL_MEMORY
    	.ddr4a_clk_clk              (local_mem[0].clk),
        .ddr4a_master_waitrequest   (local_mem[0].waitrequest),        // dma_master.waitrequest
    	.ddr4a_master_readdata      (local_mem[0].readdata),           //           .readdata
    	.ddr4a_master_readdatavalid (local_mem[0].readdatavalid),      //           .readdatavalid
    	.ddr4a_master_burstcount    (local_mem[0].burstcount[2:0]),    //           .burstcount
    	.ddr4a_master_writedata     (local_mem[0].writedata),          //           .writedata
    	.ddr4a_master_address       ({local_mem[0].address,mm_byte_offset[0]}),       //           .address
    	.ddr4a_master_write         (local_mem[0].write),              //           .write
    	.ddr4a_master_read          (local_mem[0].read),               //           .read
    	.ddr4a_master_byteenable    (local_mem[0].byteenable),         //           .byteenable
    	.ddr4a_master_debugaccess   (),                                //           .debugaccess
    	
    	.ddr4b_clk_clk              (local_mem[1].clk),
    	.ddr4b_master_waitrequest   (local_mem[1].waitrequest),        // dma_master.waitrequest
    	.ddr4b_master_readdata      (local_mem[1].readdata),           //           .readdata
    	.ddr4b_master_readdatavalid (local_mem[1].readdatavalid),      //           .readdatavalid
    	.ddr4b_master_burstcount    (local_mem[1].burstcount[2:0]),    //           .burstcount
    	.ddr4b_master_writedata     (local_mem[1].writedata),          //           .writedata
    	.ddr4b_master_address       ({local_mem[1].address,mm_byte_offset[1]}),       //           .address
    	.ddr4b_master_write         (local_mem[1].write),              //           .write
    	.ddr4b_master_read          (local_mem[1].read),               //           .read
    	.ddr4b_master_byteenable    (local_mem[1].byteenable),         //           .byteenable
    	.ddr4b_master_debugaccess   (),                                //           .debugaccess
`endif
	.*
     );

	
endmodule

