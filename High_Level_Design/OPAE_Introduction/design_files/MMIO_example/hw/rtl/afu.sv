// ***************************************************************************
// Copyright (c) 2013-2018, Intel Corporation
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
//
// Module Name:  afu.sv
//
// This AFU provides a 4-bit adder. The AFU
// has four registers at double-word (32-bit aligned) addresses 0 - 8 that 
// are required by the CCI-P protocol (see specification for more information)
// as well as three registers that are part of the application logic for this 
// AFU. The application logic registers and addresses are:
//     Num1 register:   address 0x0010
//     Num2 register:   address 0x0012
//     Sum register:    address 0x0014
//     Cout register:   address 0x0016
//
// Software has to use byte-addresses to access these AFU registers, so in 
// software code each of the above addresses would be shifted left two bit
// positions.


`include "platform_if.vh"
`include "afu_json_info.vh"

module afu (clock, reset, rx, tx);
    input clock;                    // CCI-P clock
    input reset;                    // CCI-P reset
    input  t_if_ccip_Rx rx;         // receive channel
    output t_if_ccip_Tx tx;         // transmit channel

    logic [15:0] A;                      // Address
    logic [31:0] D;                     // Data
    logic W;                          // Write signal
    logic [3:0] Num1;
    logic [3:0] Num2;
    logic [4:0] Sum;

    // The c0 header is used for memory read responses.
    // The header must be interpreted as an MMIO response when
    // c0 mmmioRdValid or mmioWrValid is set.  In these cases the
    // c0 header is cast into a ReqMmioHdr.
    t_ccip_c0_ReqMmioHdr mmioHdr;
    assign mmioHdr = t_ccip_c0_ReqMmioHdr'(rx.c0.hdr);

    assign A = mmioHdr.address;     // rename address signal
    assign D = rx.c0.data;          // rename data signal
    assign W = rx.c0.mmioWrValid;   // rename write signal

    // Receive memory-mapped IO writes
    always_ff @(posedge clock) begin
        if (reset) begin
            Num1 <= '0;
            Num2 <= '0;
        end
        else if (W) begin
            if(A == 16'h0010)
                Num1 <= D[3:0];
            else if (A == 16'h0012)
                Num2 <= D[3:0];
        end
    end

    always_comb begin
        if (reset) begin
            Sum = '0;
        end
        else begin
            Sum = Num1 + Num2;
        end
    end


    // The AFU must respond with its AFU ID in response to MMIO reads of
    // the CCI-P device feature header (DFH).  The AFU ID is a unique ID
    // for a given AFU.  Here we generated one with the "uuidgen"
    // program and stored it in the AFU's JSON file.  Compilation tools
    // automatically invoke the OPAE afu_json_mgr script to extract the 
    // UUID into afu_json_info.vh.
    logic [127:0] afu_id = `AFU_ACCEL_UUID;

    // respond to memory-mapped IO reads
    always_ff @(posedge clock) begin
        if (reset) begin
            tx.c1.hdr <= '0;
            tx.c1.valid <= '0;
            tx.c0.hdr <= '0;
            tx.c0.valid <= '0;
            tx.c2.hdr <= '0;
            tx.c2.mmioRdValid <= '0;
        end
        else begin
            // clear read response flag in case there was a response last cycle
            tx.c2.mmioRdValid <= 0;

            // serve MMIO read requests
            if (rx.c0.mmioRdValid == 1'b1) begin
                // copy TID, which the host needs to map the response to the request
                tx.c2.hdr.tid <= mmioHdr.tid;
                // Post response
                tx.c2.mmioRdValid <= 1;

                case (mmioHdr.address)
                    // AFU header
                    16'h0000: tx.c2.data <= {
                        4'b0001, // Feature type = AFU
                        8'b0,    // reserved
                        4'b0,    // afu minor revision = 0
                        7'b0,    // reserved
                        1'b1,    // end of DFH list = 1
                        24'b0,   // next DFH offset = 0
                        4'b0,    // afu major revision = 0
                        12'b0    // feature ID = 0
                        };

                    // AFU_ID_L
                    16'h0002: tx.c2.data <= afu_id[63:0];
                    // AFU_ID_H
                    16'h0004: tx.c2.data <= afu_id[127:64];
                    // DFH_RSVD0 and DFH_RSVD1
                    16'h0006: tx.c2.data <= 64'h0;
                    16'h0008: tx.c2.data <= 64'h0;

                    // application logic registers
                    16'h0010: tx.c2.data <= 64'(Num1);
                    16'h0012: tx.c2.data <= 64'(Num2);
                    16'h0014: tx.c2.data <= 64'(Sum[3:0]);
                    16'h0016: tx.c2.data <= 64'(Sum[4]);

                    default:  tx.c2.data <= 64'h0;
                endcase
            end
        end
    end
endmodule
