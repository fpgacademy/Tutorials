// Copyright(c) 2018, Intel Corporation
//
// Redistribution  and	use  in source	and  binary  forms,  with  or  without
// modification, are permitted provided that the following conditions are met:
//
// * Redistributions of  source code  must retain the  above copyright notice,
//	 this list of conditions and the following disclaimer.
// * Redistributions in binary form must reproduce the above copyright notice,
//	 this list of conditions and the following disclaimer in the documentation
//	 and/or other materials provided with the distribution.
// * Neither the name  of Intel Corporation  nor the names of its contributors
//	 may be used to  endorse or promote  products derived  from this  software
//	 without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,  BUT NOT LIMITED TO,  THE
// IMPLIED WARRANTIES OF  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED.	IN NO EVENT  SHALL THE COPYRIGHT OWNER	OR CONTRIBUTORS BE
// LIABLE  FOR	ANY  DIRECT,  INDIRECT,  INCIDENTAL,  SPECIAL,	EXEMPLARY,	OR
// CONSEQUENTIAL  DAMAGES  (INCLUDING,	BUT  NOT LIMITED  TO,  PROCUREMENT	OF
// SUBSTITUTE GOODS OR SERVICES;  LOSS OF USE,	DATA, OR PROFITS;  OR BUSINESS
// INTERRUPTION)  HOWEVER CAUSED  AND ON ANY THEORY  OF LIABILITY,	WHETHER IN
// CONTRACT,  STRICT LIABILITY,  OR TORT  (INCLUDING NEGLIGENCE  OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,	EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
/**
 * \fpga_dma_st_test_utils.c
 * \brief Streaming DMA test utils
 */
#include <iostream>
#include <cmath>
#include <unistd.h>
#include "fpga_dma_st_test_utils.h"
#include "image_helper.h"

using namespace std;

volatile static uint64_t bytes_sent;
volatile static uint64_t bytes_rcvd;
volatile static bool eop_rcvd;
volatile static uint64_t cb_count;


static void stomCb(void *ctx, fpga_dma_transfer_status_t status) {
	// printf("stomCb %ld, %ld\n", cb_count, status.bytes_transferred);
	bytes_rcvd += status.bytes_transferred;
	eop_rcvd = status.eop_arrived;
	cb_count += 1;
	return;
}

static void mtosCb(void *ctx, fpga_dma_transfer_status_t status) {
	bytes_sent += status.bytes_transferred;
	return;
}


static double getBandwidth(size_t size, double seconds) {
	double throughput = (double)size/((double)seconds*1000*1000);
	return std::round(throughput);
}

// return elapsed time
double getTime(struct timespec start, struct timespec end) {
	uint64_t diff = 1000000000L * (end.tv_sec - start.tv_sec) + end.tv_nsec - start.tv_nsec;
	return (double) diff/(double)1000000000L;
}



void fill_buffer(unsigned char *buf, unsigned char *data, size_t size){
	memcpy(buf, data, size);
}


fpga_result allocate_buffer(fpga_handle afc_h, struct buf_attrs *attrs)
{
	fpga_result res;
	if(!attrs)
		return FPGA_INVALID_PARAM;

	res = fpgaPrepareBuffer(afc_h, attrs->size, (void **)&(attrs->va), &attrs->wsid, 0);
	if(res != FPGA_OK)
		return res;

	res = fpgaGetIOAddress(afc_h, attrs->wsid, &attrs->iova);
	if(res != FPGA_OK) {
		res = fpgaReleaseBuffer(afc_h, attrs->wsid);
		return res;
	}
	return FPGA_OK;
}

fpga_result free_buffer(fpga_handle afc_h, struct buf_attrs *attrs)
{
	if(!attrs)
		return FPGA_INVALID_PARAM;

	return fpgaReleaseBuffer(afc_h, attrs->wsid);
}

void * m2sworker(void* arg) {
	struct timespec start, end;
	struct dma_config *dma_config = (struct dma_config *)arg;
	struct config *test_config = dma_config->config;
	fpga_result res = FPGA_OK;

	// initialize DMA transfer
	fpga_dma_transfer_t transfer;
	res = fpgaDMATransferInit(&transfer);
	if(res != FPGA_OK){
		fprintf(stderr, "Error: allocating m2s transfer\n");
		return dma_config->dma_h;
	}
	fpgaDMATransferReset(transfer);


	// do memory to stream transfer
	size_t total_size = test_config->src_data_size;
	uint64_t max = ceil((double)test_config->src_data_size / (double)test_config->payload_size);
	uint64_t tid = 0; // transfer index
	uint64_t src = dma_config->battrs->iova;

	bytes_sent = 0;

	clock_gettime(CLOCK_MONOTONIC, &start);	

	while(total_size > 0) {
		uint64_t transfer_bytes = MIN(total_size, test_config->payload_size);

		fpgaDMATransferSetSrc(transfer, src);
		fpgaDMATransferSetDst(transfer, (uint64_t)0);
		fpgaDMATransferSetLen(transfer, transfer_bytes);
		fpgaDMATransferSetTransferType(transfer, HOST_MM_TO_FPGA_ST);


		if(max == 1)  // we only have a single buffer
			fpgaDMATransferSetTxControl(transfer, GENERATE_SOP_AND_EOP);
		else if(tid == 0) // first buffer, set SOP
			fpgaDMATransferSetTxControl(transfer, GENERATE_SOP);
		else if(tid == max-1) // last buffer, set EOP
			fpgaDMATransferSetTxControl(transfer, GENERATE_EOP);
		else // set NO_PACKET otherwise
			fpgaDMATransferSetTxControl(transfer, TX_NO_PACKET);
		
		fpgaDMATransferSetTransferCallback(transfer, mtosCb, NULL);

		if(tid == max-1) { // last transfer
			fpgaDMATransferSetLast(transfer, true);
		} else {
			fpgaDMATransferSetLast(transfer, false);
		}
		res = fpgaDMATransfer(dma_config->dma_h, transfer);
		if(res != FPGA_OK){
			fprintf(stderr, "Error: m2s transfer error\n");
			fpgaDMATransferDestroy(&transfer);
			return dma_config->dma_h;
		}

		total_size -= transfer_bytes;
		src += transfer_bytes;
		tid++;
	}

	while(bytes_sent < test_config->src_data_size);
	printf("sent all bytes\n");

	clock_gettime(CLOCK_MONOTONIC, &end);

	dma_config->bw = getBandwidth(test_config->src_data_size, getTime(start,end));

	res = fpgaDMATransferDestroy(&transfer);
	return dma_config->dma_h;
}



void * s2mworker(void* arg) {
	struct timespec start, end;
	struct dma_config *dma_config = (struct dma_config *)arg;
	struct config *test_config = dma_config->config;
	
	fpga_result res = FPGA_OK;	
	
	fpga_dma_transfer_t transfer;
	res = fpgaDMATransferInit(&transfer);
	if(res != FPGA_OK){
		fprintf(stderr, "Error: allocating s2m transfer\n");
		return dma_config->dma_h;
	}
	fpgaDMATransferReset(transfer);


	uint64_t expected_bytes = test_config->dst_data_size;
	uint64_t dst = dma_config->battrs->iova;

	cb_count = 0;	
	bytes_rcvd = 0;
	eop_rcvd = false;
	uint64_t transfer_bytes;


	clock_gettime(CLOCK_MONOTONIC, &start);

	while(!eop_rcvd) {

		transfer_bytes = test_config->payload_size;

		fpgaDMATransferSetSrc(transfer, (uint64_t)0);
		fpgaDMATransferSetDst(transfer, dst);
		fpgaDMATransferSetLen(transfer, transfer_bytes);
		fpgaDMATransferSetTransferType(transfer, FPGA_ST_TO_HOST_MM);
		fpgaDMATransferSetRxControl(transfer, END_ON_EOP);
		fpgaDMATransferSetTransferCallback(transfer, stomCb, NULL);


		res = fpgaDMATransfer(dma_config->dma_h, transfer);

		if(res != FPGA_OK){
			fprintf(stderr, "Error: s2m transfer error\n");
			fpgaDMATransferDestroy(&transfer);
			return dma_config->dma_h;
		}

		dst += transfer_bytes;
	}

	clock_gettime(CLOCK_MONOTONIC, &end);

	if(bytes_rcvd != expected_bytes) {
		cout << "Bytes rcvd = " << bytes_rcvd << " != Expected bytes = " << expected_bytes << endl;
	}
	dma_config->bw = getBandwidth(test_config->dst_data_size, getTime(start,end));

	// write result
	string temp = "result.bmp";
	char filename[11];
	strncpy(filename, temp.c_str(), sizeof(filename));
	write_rgba_bmp(filename, (unsigned char *)dma_config->image_header, (unsigned char *)dma_config->battrs->va);

	res = fpgaDMATransferDestroy(&transfer);
	return dma_config->dma_h;
}
