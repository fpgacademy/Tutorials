// Copyright(c) 2017, Intel Corporation
//
// Redistribution  and  use  in source  and  binary  forms,  with  or  without
// modification, are permitted provided that the following conditions are met:
//
// * Redistributions of  source code  must retain the  above copyright notice,
//   this list of conditions and the following disclaimer.
// * Redistributions in binary form must reproduce the above copyright notice,
//   this list of conditions and the following disclaimer in the documentation
//   and/or other materials provided with the distribution.
// * Neither the name  of Intel Corporation  nor the names of its contributors
//   may be used to  endorse or promote  products derived  from this  software
//   without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,  BUT NOT LIMITED TO,  THE
// IMPLIED WARRANTIES OF  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMEdesc.  IN NO EVENT  SHALL THE COPYRIGHT OWNER  OR CONTRIBUTORS BE
// LIABLE  FOR  ANY  DIRECT,  INDIRECT,  INCIDENTAL,  SPECIAL,  EXEMPLARY,  OR
// CONSEQUENTIAL  DAMAGES  (INCLUDING,  BUT  NOT LIMITED  TO,  PROCUREMENT  OF
// SUBSTITUTE GOODS OR SERVICES;  LOSS OF USE,  DATA, OR PROFITS;  OR BUSINESS
// INTERRUPTION)  HOWEVER CAUSED  AND ON ANY THEORY  OF LIABILITY,  WHETHER IN
// CONTRACT,  STRICT LIABILITY,  OR TORT  (INCLUDING NEGLIGENCE  OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,  EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

#include <stdio.h>
#include <stdlib.h>
#include <opae/mmio.h>

// Application Logic register addresses (offsets)
#define NUM1_REG    0X10 << 2
#define NUM2_REG    0X12 << 2
#define SUM_REG     0X14 << 2
#define COUT_REG    0X16 << 2

int open_AFU (fpga_handle *);
void close_AFU (fpga_handle);

int main(int argc, char *argv[])
{
    if(argc < 3){
        printf("Usage: ./adder num1 num2\n");
        return -1;
    }
    fpga_handle handle = NULL;
    if (open_AFU (&handle) < 0)
        return -1;

    uint32_t num1, num2, sum, cout;
    num1 = atoi(argv[1]);
    num2 = atoi(argv[2]);

    (void) fpgaWriteMMIO32 (handle, 0, NUM1_REG, num1);   // set num1
    (void) fpgaWriteMMIO32 (handle, 0, NUM2_REG, num2);  // set num2
    
    (void) fpgaReadMMIO32 (handle, 0, SUM_REG, &sum);
    (void) fpgaReadMMIO32 (handle, 0, COUT_REG, &cout);
    printf ("Sum: %x, Carry-out: %x\n", sum, cout);

    close_AFU (handle);
    return 0;
}
