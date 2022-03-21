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

module afu 
  #(
    parameter NUM_LOCAL_MEM_BANKS=2
    )
   (
	// ---------------------------global signals-------------------------------------------------
        input	afu_clk,	  //              in    std_logic;           Core clock. CCI interface is synchronous to this clock.
        input	reset,	  //              in    std_logic;           CCI interface reset. The Accelerator IP must use this Reset. ACTIVE HIGH
        
`ifdef PLATFORM_PROVIDES_LOCAL_MEMORY
    // Local memory interface
    avalon_mem_if.to_fiu local_mem[NUM_LOCAL_MEM_BANKS],
`endif
        
	// ---------------------------IF signals between CCI and AFU  --------------------------------
	input	t_if_ccip_Rx    cp2af_sRxPort,
	input	t_if_ccip_c0_Rx cp2af_mmio_c0rx,
	output	t_if_ccip_Tx	af2cp_sTxPort
);

    //ccip avmm signals
    wire requestor_avmm_wr_waitrequest;
    wire [CCIP_AVMM_REQUESTOR_DATA_WIDTH-1:0]	requestor_avmm_wr_writedata;
    wire [CCIP_AVMM_REQUESTOR_WR_ADDR_WIDTH-1:0]	requestor_avmm_wr_address;
    wire requestor_avmm_wr_write;
    wire [CCIP_AVMM_REQUESTOR_BURST_WIDTH-1:0]	requestor_avmm_wr_burstcount;
    
    wire requestor_avmm_rd_waitrequest;
    wire [CCIP_AVMM_REQUESTOR_DATA_WIDTH-1:0]	requestor_avmm_rd_readdata;
    wire requestor_avmm_rd_readdatavalid;
    wire [CCIP_AVMM_REQUESTOR_DATA_WIDTH-1:0]	requestor_avmm_rd_writedata;
    wire [CCIP_AVMM_REQUESTOR_RD_ADDR_WIDTH-1:0]	requestor_avmm_rd_address;
    wire requestor_avmm_rd_write;
    wire requestor_avmm_rd_read;
    wire [CCIP_AVMM_REQUESTOR_BURST_WIDTH-1:0]	requestor_avmm_rd_burstcount;
    
    wire mmio_avmm_waitrequest;
    wire [CCIP_AVMM_MMIO_DATA_WIDTH-1:0]	mmio_avmm_readdata;
    wire mmio_avmm_readdatavalid;
    wire [CCIP_AVMM_MMIO_DATA_WIDTH-1:0]	mmio_avmm_writedata;
    wire [CCIP_AVMM_MMIO_ADDR_WIDTH-1:0]	mmio_avmm_address;
    wire mmio_avmm_write;
    wire mmio_avmm_read;
    wire [(CCIP_AVMM_MMIO_DATA_WIDTH/8)-1:0]	mmio_avmm_byteenable;
    
    wire dma_irq;
    
    dma_test_system_wrapper 
    #(
        .NUM_LOCAL_MEM_BANKS(NUM_LOCAL_MEM_BANKS)
     )
     u0 
     (
`ifdef PLATFORM_PROVIDES_LOCAL_MEMORY
        // Local memory interface
        .local_mem               (local_mem),
`endif    
        .ccip_avmm_mmio_waitrequest         (mmio_avmm_waitrequest),         //       ccip_avmm_mmio.waitrequest
        .ccip_avmm_mmio_readdata            (mmio_avmm_readdata),            //                    .readdata
        .ccip_avmm_mmio_readdatavalid       (mmio_avmm_readdatavalid),       //                    .readdatavalid
        .ccip_avmm_mmio_burstcount          (1'b1),          //                    .burstcount
        .ccip_avmm_mmio_writedata           (mmio_avmm_writedata),           //                    .writedata
        .ccip_avmm_mmio_address             (mmio_avmm_address),             //                    .address
        .ccip_avmm_mmio_write               (mmio_avmm_write),               //                    .write
        .ccip_avmm_mmio_read                (mmio_avmm_read),                //                    .read
        .ccip_avmm_mmio_byteenable          (mmio_avmm_byteenable),          //                    .byteenable
        .ccip_avmm_mmio_debugaccess         (),         //                    .debugaccess
        .ccip_avmm_requestor_wr_waitrequest   (requestor_avmm_wr_waitrequest),   // ccip_avmm_requestor.waitrequest
        .ccip_avmm_requestor_wr_readdata      (),      //                    .readdata
        .ccip_avmm_requestor_wr_readdatavalid (), //                    .readdatavalid
        .ccip_avmm_requestor_wr_burstcount    (requestor_avmm_wr_burstcount),    //                    .burstcount
        .ccip_avmm_requestor_wr_writedata     (requestor_avmm_wr_writedata),     //                    .writedata
        .ccip_avmm_requestor_wr_address       (requestor_avmm_wr_address),       //                    .address
        .ccip_avmm_requestor_wr_write         (requestor_avmm_wr_write),         //                    .write
        .ccip_avmm_requestor_wr_read          (),          //                    .read
        .ccip_avmm_requestor_wr_byteenable    (),    //                    .byteenable
        .ccip_avmm_requestor_wr_debugaccess   (),   //                    .debugaccess
        
        .ccip_avmm_requestor_rd_waitrequest   (requestor_avmm_rd_waitrequest),   // ccip_avmm_requestor.waitrequest
        .ccip_avmm_requestor_rd_readdata      (requestor_avmm_rd_readdata),      //                    .readdata
        .ccip_avmm_requestor_rd_readdatavalid (requestor_avmm_rd_readdatavalid), //                    .readdatavalid
        .ccip_avmm_requestor_rd_burstcount    (requestor_avmm_rd_burstcount),    //                    .burstcount
        .ccip_avmm_requestor_rd_writedata     (),     //                    .writedata
        .ccip_avmm_requestor_rd_address       (requestor_avmm_rd_address),       //                    .address
        .ccip_avmm_requestor_rd_write         (),         //                    .write
        .ccip_avmm_requestor_rd_read          (requestor_avmm_rd_read),          //                    .read
        .ccip_avmm_requestor_rd_byteenable    (),    //                    .byteenable
        .ccip_avmm_requestor_rd_debugaccess   (),   //                    .debugaccess
    
        .dma_irq_irq(dma_irq),
    
    	.host_clk_clk(afu_clk),
    	.reset_reset(reset)         // reset.reset
    );

    avmm_ccip_host_rd avmm_ccip_host_rd_inst (
    	.clk            (afu_clk),            //   clk.clk
    	.reset        (reset),         // reset.reset
    	
    	.avmm_waitrequest(requestor_avmm_rd_waitrequest),
    	.avmm_readdata(requestor_avmm_rd_readdata),
    	.avmm_readdatavalid(requestor_avmm_rd_readdatavalid),
    	.avmm_address(requestor_avmm_rd_address),
    	.avmm_read(requestor_avmm_rd_read),
    	.avmm_burstcount(requestor_avmm_rd_burstcount),
    	
    	.c0TxAlmFull(cp2af_sRxPort.c0TxAlmFull),
    	.c0rx(cp2af_sRxPort.c0),
    	.c0tx(af2cp_sTxPort.c0)
    );
    
    avmm_ccip_host_wr #(
    	.ENABLE_INTR(1)
    ) avmm_ccip_host_wr_inst (
    	.clk            (afu_clk),            //   clk.clk
    	.reset        (reset),         // reset.reset
    	
    	.irq({3'b000, dma_irq}),
    	
    	.avmm_waitrequest(requestor_avmm_wr_waitrequest),
    	.avmm_writedata(requestor_avmm_wr_writedata),
    	.avmm_address(requestor_avmm_wr_address),
    	.avmm_write(requestor_avmm_wr_write),
    	.avmm_burstcount(requestor_avmm_wr_burstcount),
      .avmm_write_response      (),
      .avmm_write_responsevalid (),
    	
    	.c1TxAlmFull(cp2af_sRxPort.c1TxAlmFull),
	.c1rx                     (cp2af_sRxPort.c1),
    	.c1tx(af2cp_sTxPort.c1)
    );
    
    ccip_avmm_mmio ccip_avmm_mmio_inst (
        .avmm_waitrequest(mmio_avmm_waitrequest),
        .avmm_readdata(mmio_avmm_readdata),
        .avmm_readdatavalid(mmio_avmm_readdatavalid),
        .avmm_writedata(mmio_avmm_writedata),
        .avmm_address(mmio_avmm_address),
        .avmm_write(mmio_avmm_write),
        .avmm_read(mmio_avmm_read),
        .avmm_byteenable(mmio_avmm_byteenable),

        .clk            (afu_clk),            //   clk.clk
        .reset        (reset),         // reset.reset

        .c0rx(cp2af_mmio_c0rx),
        .c2tx(af2cp_sTxPort.c2)
    );
	
endmodule

