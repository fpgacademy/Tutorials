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
 * \fpga_dma_st_test.c
 * \brief Streaming DMA test
 */

#include <getopt.h>
#include <unistd.h>
#include <uuid/uuid.h>
#include <opae/fpga.h>
#include "fpga_dma_st_test_utils.h"
#include "fpga_dma_st_internal.h"
#include "image_helper.h"



extern "C"{
	int open_AFU (fpga_handle *);
	void close_AFU (fpga_handle);
}


static int open_DMA_ST(fpga_handle afc_h, fpga_dma_handle_t *rx_dma_h, fpga_dma_handle_t *tx_dma_h){
	fpga_result res = FPGA_OK;

	uint64_t ch_count = 0;
	res = fpgaCountDMAChannels(afc_h, &ch_count);
	if(res != FPGA_OK){
		fprintf(stderr, "Error: Get FPGA DMA Channels\n");
		close_AFU(afc_h);
		return -1;
	}
	if(ch_count < 2) {
		fprintf(stderr, "DMA channels not found (found %ld, expected %d\n", ch_count, 2);
		close_AFU(afc_h);
		return -1;
	}

	res = fpgaDMAOpen(afc_h, 1, rx_dma_h);
	if(res != FPGA_OK){
		fprintf(stderr, "Error: FPGA DMA Open rx\n");
		close_AFU(afc_h);
		return -1;
	}

	res = fpgaDMAOpen(afc_h, 0, tx_dma_h);
	if(res != FPGA_OK){
		fprintf(stderr, "Error: FPGA DMA Open tx\n");
		res = fpgaDMAClose(*rx_dma_h);
		close_AFU(afc_h);
		return -1;
	}
}


static void close_DMA_ST(fpga_dma_handle_t rx_dma_h, fpga_dma_handle_t tx_dma_h){
	if(rx_dma_h) {
		fpgaDMAClose(rx_dma_h);
	}

	if(tx_dma_h) {
		fpgaDMAClose(tx_dma_h);
	}
}



int main(int argc, char *argv[]) {
	
	if(argc < 3){
		fprintf(stderr, "Usage: ./fgpa_dma_st_test [payload] [path to image]\n");
		return -1;
	}

	fpga_result res = FPGA_OK;
	fpga_handle afc_h;
	fpga_dma_handle_t tx_dma_h, rx_dma_h;

	uint64_t payload; 
	try{
		payload = std::stoi(argv[1]);
	}catch(const std::exception&){
		fprintf(stderr, "Error parsing payload size.\n");
		return -1;
	}


	// read image
	unsigned char * data;
	unsigned char * header;
	int width, height;

	if (read_grayscale(argv[2], &header, &data, &width, &height) < 0)
		return -1;

	// set transfer config
	struct config config = {
		.src_data_size = (uint64_t) width * height,
		.dst_data_size = (uint64_t) width * height * 4,
		.payload_size = payload
	};


	if(open_AFU(&afc_h) < 0)
		return -1;

	if(open_DMA_ST(afc_h, &rx_dma_h, &tx_dma_h) <0)
		return -1;


	// source buffer
	struct buf_attrs battrs_src = {
		.va = NULL,
		.iova = 0,
		.wsid = 0,
		.size = 0
	};
	battrs_src.size = config.src_data_size;
	res = allocate_buffer(afc_h, &battrs_src);
	if(res != FPGA_OK){
		fprintf(stderr, "allocating battrs_src buffer\n");
		close_DMA_ST(rx_dma_h, tx_dma_h);
		close_AFU(afc_h);
		return -1;
	}	
	fill_buffer((unsigned char *)battrs_src.va, data, config.src_data_size);

	// dst buffer
	struct buf_attrs battrs_dst = {
		.va = NULL,
		.iova = 0,
		.wsid = 0,
		.size = 0
	};
	battrs_dst.size = config.dst_data_size;
	res = allocate_buffer(afc_h, &battrs_dst);
	if(res != FPGA_OK){
		fprintf(stderr, "allocating battrs_dst buffer\n");
		close_DMA_ST(rx_dma_h, tx_dma_h);
		close_AFU(afc_h);
		return -1;
	}	
	memset(battrs_dst.va, 0, config.dst_data_size);

	struct timespec start, end;
	clock_gettime(CLOCK_MONOTONIC, &start);

	// Channels are launched from separate threads in loopback mode
	struct dma_config m2s_worker_struct, s2m_worker_struct;
	m2s_worker_struct.afc_h = afc_h;
	m2s_worker_struct.dma_h = tx_dma_h;
	m2s_worker_struct.config = &config;
	m2s_worker_struct.battrs = &battrs_src;
	m2s_worker_struct.image_header = header;

	// Start m2s worker threads
	pthread_t m2s_thread_id;
	if (pthread_create(&m2s_thread_id, NULL, m2sworker, (void*)&m2s_worker_struct) != 0) {
		fprintf(stderr, "pthread_create m2s worker\n");
		close_DMA_ST(rx_dma_h, tx_dma_h);
		close_AFU(afc_h);
		return -1;
	}

	s2m_worker_struct.afc_h = afc_h;
	s2m_worker_struct.dma_h = rx_dma_h;
	s2m_worker_struct.config = &config;
	s2m_worker_struct.battrs= &battrs_dst;
	s2m_worker_struct.image_header = header;
		
	// Start s2m worker threads
	pthread_t s2m_thread_id;
	if (pthread_create(&s2m_thread_id, NULL, s2mworker, (void*)&s2m_worker_struct) != 0) {
		fprintf(stderr, "pthread_create s2m worker\n");
		close_DMA_ST(rx_dma_h, tx_dma_h);
		close_AFU(afc_h);
		return -1;
	}

	pthread_join(m2s_thread_id, nullptr);
	pthread_join(s2m_thread_id, nullptr);

	clock_gettime(CLOCK_MONOTONIC, &end);
	double time = getTime(start, end);
	
	std::cout << "Memory to Stream BW = " << m2s_worker_struct.bw << " MBps, " \
			  << "Stream to Memory BW = " << s2m_worker_struct.bw << " MBps, " \
			  << "Time = " << time << " s" << endl;


	if(battrs_src.va) {
		free_buffer(afc_h, &battrs_src);
	}
	if(battrs_dst.va) {
		free_buffer(afc_h, &battrs_dst);
	}

	close_DMA_ST(rx_dma_h, tx_dma_h);
	close_AFU(afc_h);
	return 0;
}
