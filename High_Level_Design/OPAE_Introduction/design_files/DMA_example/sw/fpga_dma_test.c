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
// ARE DISCLAIMED.  IN NO EVENT  SHALL THE COPYRIGHT OWNER  OR CONTRIBUTORS BE
// LIABLE  FOR  ANY  DIRECT,  INDIRECT,  INCIDENTAL,  SPECIAL,  EXEMPLARY,  OR
// CONSEQUENTIAL  DAMAGES  (INCLUDING,  BUT  NOT LIMITED  TO,  PROCUREMENT  OF
// SUBSTITUTE GOODS OR SERVICES;  LOSS OF USE,  DATA, OR PROFITS;  OR BUSINESS
// INTERRUPTION)  HOWEVER CAUSED  AND ON ANY THEORY  OF LIABILITY,  WHETHER IN
// CONTRACT,  STRICT LIABILITY,  OR TORT  (INCLUDING NEGLIGENCE  OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,  EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

#include <string.h>
#include <time.h>
#include <stdio.h>
#include <hwloc.h>
#include <assert.h>

#include <opae/mmio.h>
#include "fpga_dma.h"
#include "image_helper.h"

// #define AFU_ID_H 0xfab1f76a1458428e
// #define AFU_ID_L 0xb37591819ffc6f4e

#define CTRL_REG 0x40
#define STAT_REG 0x48

int open_AFU (fpga_handle *);
void close_AFU (fpga_handle);

// Aligned malloc
static inline void *malloc_aligned(uint64_t align, size_t size){
	assert(align && ((align & (align - 1)) == 0)); // align must be power of 2 and not 0
	assert(align >= 2 * sizeof(void *));
	void *blk = NULL;
	blk = malloc(size + align + 2 * sizeof(void *));
	void **aptr = (void **)(((uint64_t)blk + 2 * sizeof(void *) + (align - 1))
			  & ~(align - 1)); // guarantee aptr is aligned (set last n bits 0)
	aptr[-1] = blk; // store the pointer to blk
	return aptr;
}

// Aligned free
static inline void free_aligned(void *ptr){
	void **aptr = (void **)ptr;
	free(aptr[-1]);
}


static inline void fill_buffer(char *buf, unsigned char *data, size_t size){
	memcpy(buf, data, size);
}

static void write_result(char *buf, unsigned char *header, int width, int height){
	write_bmp("result.bmp", header, (unsigned char *)buf, width, height);
}

static inline void clear_buffer(char *buf, size_t size){
	memset(buf, 0, size);
}


// return elapsed time
static inline double getTime(struct timespec start, struct timespec end)
{
	uint64_t diff = 1000000000L * (end.tv_sec - start.tv_sec) + end.tv_nsec
			- start.tv_nsec;
	return (double)diff / (double)1000000000L;
}

static inline void err_handle(fpga_handle afc_h, fpga_dma_handle dma_h, uint64_t *dma_buf_ptr){
	if (dma_buf_ptr)
		free_aligned(dma_buf_ptr);
	if (dma_h)
		fpgaDmaClose(dma_h);

	close_AFU(afc_h);
}




int main(int argc, char *argv[])
{
	if (argc < 2) {
		printf("Usage: fpga_dma_test <path to image>\n");
		return -1;
	}

	fpga_result res = FPGA_OK;
	fpga_dma_handle dma_h;
	fpga_handle afc_h;
	uint64_t *dma_buf_ptr = NULL;

	if(open_AFU(&afc_h) < 0)
		return -1;
		
	res = fpgaDmaOpen(afc_h, &dma_h);
	if(res != FPGA_OK || !dma_h){
		err_handle(afc_h, dma_h, dma_buf_ptr);
		return -1;
	}

	unsigned char * data;
	unsigned char * header;
	int width, height;

	if (read_grayscale(argv[1], &header, &data, &width, &height) < 0) {
	// if (read_grayscale("../images/brooklyn_bridge_720_540.bmp", &header, &data, &width, &height) < 0) {
		err_handle(afc_h, dma_h, dma_buf_ptr);
		return -1;
	}
	
	uint64_t count;
	count = width * height;

	dma_buf_ptr = (uint64_t *)malloc_aligned(getpagesize(), count*3);
	if (!dma_buf_ptr) {
		err_handle(afc_h, dma_h, dma_buf_ptr);
		return -1;
	}

	fill_buffer((char *)dma_buf_ptr, data, count);

	// copy from host to fpga
	res = fpgaDmaTransferSync(dma_h, 0x0 /*dst */,
				  (uint64_t)dma_buf_ptr /*src */, count,
				  HOST_TO_FPGA_MM);
	if(res != FPGA_OK){
		err_handle(afc_h, dma_h, dma_buf_ptr);
		return -1;
	}
	clear_buffer((char *)dma_buf_ptr, count);


	struct timespec start, end;
	clock_gettime(CLOCK_MONOTONIC, &start);


	res = fpgaWriteMMIO64 (afc_h, 0, CTRL_REG, count); 
	if(res != FPGA_OK){
		err_handle(afc_h, dma_h, dma_buf_ptr);
		return -1;
	}

	uint64_t converter_status = 0;
	while(converter_status != 1){
		res = fpgaReadMMIO64(afc_h, 0, STAT_REG, &converter_status);
		if(res != FPGA_OK){
			err_handle(afc_h, dma_h, dma_buf_ptr);
			return -1;
		}
	}
	
	clock_gettime(CLOCK_MONOTONIC, &end);
	printf("time: %f\n", getTime(start, end));
	printf("converter status: %ld\n", converter_status);

	// copy from fpga to host
	res = fpgaDmaTransferSync(dma_h, (uint64_t)dma_buf_ptr /*dst */,
				  count /*src */, count*3, FPGA_TO_HOST_MM);
	if(res != FPGA_OK){
		err_handle(afc_h, dma_h, dma_buf_ptr);
		return -1;
	}

	write_result((char *)dma_buf_ptr, header, width, height);

	if (dma_buf_ptr)
		free_aligned(dma_buf_ptr);
	if (dma_h)
		res = fpgaDmaClose(dma_h);

	close_AFU(afc_h);
	return 0;
}
