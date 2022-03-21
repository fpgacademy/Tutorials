# TBB_HOME = /glob/development-tools/versions/oneapi/beta10/inteloneapi/tbb/2021.1-beta10
# TBB_LIB = /glob/development-tools/versions/oneapi/beta10/inteloneapi/tbb/2021.1-beta10/lib

CXX = g++
LDFLAGS ?=

CXXFLAGS += -D FPGA_DMA_DEBUG=0 -g -O2 -fPIC -D EMU_MODE=0 -Wall -Wno-unknown-pragmas -I$(TBB_HOME)/include -fpermissive -std=c++11
CXXFLAGS += -DFPGA_DMA_MAX_BLOCKS=256 -DFPGA_DMA_BLOCK_SIZE=64

ifdef prefix
CXXFLAGS += -I$(prefix)/include
LDFLAGS += -L$(prefix)/lib -L$(prefix)/lib64 
AFU_JSON_MGR = $(prefix)/bin/afu_json_mgr
else
AFU_JSON_MGR = afu_json_mgr
endif


LDFLAGS += -luuid
LDFLAGS += -lsafestr
LDFLAGS += -lrt
LDFLAGS += -ltbb
# LDFLAGS += -L$(TBB_HOME)/lib/intel64/gcc4.8/
LDFLAGS += -L$(TBB_HOME)/lib/intel64_lin/gcc4.7/
LDFLAGS += -L$(TBB_LIB)

ifeq ($(USE_ASE),1)
	LDFLAGS += -lopae-c-ase
	CXXFLAGS += -DUSE_ASE
else
	LDFLAGS += -ljson-c
	LDFLAGS += -lopae-c
	LDFLAGS += -lhwloc
endif

LDFLAGS += -pthread
LDFLAGS += -lm

SRCS=$(wildcard *.cpp)
OBJS=$(SRCS:.cpp=.o)
all: $(OBJS) fpga_dma_st_test

afu_json_info.h: ../hw/rtl/streaming_dma_afu.json
	$(AFU_JSON_MGR) json-info --afu-json=$^ --c-hdr=$@

fpga_dma_st_test: $(OBJS) fpga_dma_st.a fpga_dma_st_test.o manage_afu.o image_helper.o
	$(CXX) -o $@ $^ $(LDFLAGS)

fpga_dma_st_test.o: fpga_dma_st_test.cpp afu_json_info.h
	$(CXX) $(CFLAGS) -o $@ -c fpga_dma_st_test.cpp

fpga_dma_st.a: fpga_dma_st.o x86-sse2.o
	ar rcs $@ $^

image_helper.o: image_helper.cpp
	${CXX} $(CFLAGS) -c -o $@ $^

manage_afu.o: manage_afu.c afu_json_info.h
	gcc $(CFLAGS) -c -o manage_afu.o manage_afu.c

clean:
	$(RM) fpga_dma_st_test *.o *.so *.a *.dat *.log afu_json_info.h

.PHONY:all clean
