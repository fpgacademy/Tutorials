#!/bin/bash
sudo ./fpga_dma_st_test -s 1048576 -p 4096 -l off -r mtos -t fixed
sudo ./fpga_dma_st_test -s 1048576 -p 4096 -l off -r mtos -t packet

sudo ./fpga_dma_st_test -s 1048576 -p 4096 -l off -r stom -t fixed
sudo ./fpga_dma_st_test -s 1048576 -p 4096 -l off -r stom -t packet

sudo ./fpga_dma_st_test -s 1048576 -p 4096 -l on -t fixed
sudo ./fpga_dma_st_test -s 1048576 -p 4096 -l on -t packet

sudo ./fpga_dma_st_test -s 1048576 -p 4096 -l on -t fixed
sudo ./fpga_dma_st_test -s 1048576 -p 4096 -l on -t packet