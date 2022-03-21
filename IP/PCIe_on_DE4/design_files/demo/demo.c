#include <stdio.h>
#include <string.h>
#include "alt_up_pci_lib.h"

#define ONCHIP_CONTROL  0x00000FFF
#define ONCHIP_DATA     0x00001000
#define DATA_SIZE 		4096
#define CTRLLER_ID 		0

int main()
{
	int fd, length_str;
	char buff[DATA_SIZE], control;

	// Open the device file
	if( alt_up_pci_open(&fd, "/dev/alt_up_pci0") ){
		return -1;
	}

	control = 'H';  // controlled by the host PC
	if( alt_up_pci_write(fd, BAR0, ONCHIP_CONTROL, &control, sizeof(control)) )
		return -1;

	while(1){

		// read string from the screen
		printf("Set data for FPGA\n");
		fgets(buff, DATA_SIZE, stdin);
		
		// get the length of the string, make it as a multiple of 8 to ensure the DMA Controller works correctly 
		length_str = strlen(buff) + (8 - (strlen(buff)%8));

		//check quit
		if( strcmp("quit\n", buff) == 0 )
			break;

		// set & go
		if( alt_up_pci_dma_add(fd, CTRLLER_ID, ONCHIP_DATA, buff, length_str, TO_DEVICE) )
			return -1;
		if( alt_up_pci_dma_go(fd, CTRLLER_ID, INTERRUPT) )
			return -1;

		// give the control to board
		control = 'B';  //board
		if( alt_up_pci_write(fd, BAR0, ONCHIP_CONTROL, &control, sizeof(control)) )
			return -1;

		// wait and poll the control byte
		while( control != 'H')
			if( alt_up_pci_read(fd, BAR0, ONCHIP_CONTROL, &control, sizeof(control)) )
				return -1;

		// read the data back
		if( alt_up_pci_dma_add(fd, CTRLLER_ID, ONCHIP_DATA, buff, length_str, FROM_DEVICE) )
			return -1;
		if( alt_up_pci_dma_go (fd, CTRLLER_ID, INTERRUPT) )
			return -1;

		// print the value
		printf("Received :\n%s\n", buff);
	}

	// close the dev_file
	alt_up_pci_close(fd);

	return 0;
}
