/*******************************************************************************
 * This file provides address values that exist in the DE10-Lite Computer
 ******************************************************************************/

/* Memory */
	.equ	SDRAM_BASE,				0x00000000
	.equ	SDRAM_END,				0x03FFFFFF
	.equ	FPGA_PIXEL_BUF_BASE,	0x08000000
	.equ	FPGA_PIXEL_BUF_END,		0x0800FFFF
	.equ	FPGA_CHAR_BASE,			0x09000000
	.equ	FPGA_CHAR_END,			0x09001FFF

/* Devices */
	.equ 	LED_BASE,				0xFF200000
	.equ	LEDR_BASE,				0xFF200000
	.equ	HEX3_HEX0_BASE,			0xFF200020
	.equ	HEX5_HEX4_BASE,			0xFF200030
	.equ	SW_BASE,				0xFF200040
	.equ	KEY_BASE,				0xFF200050
	.equ	JP1_BASE,				0xFF200060
	.equ  	ARDUINO_GPIO,			0xFF200100
	.equ	ARDUINO_RESET_N,		0xFF200110	
	.equ	JTAG_UART_BASE,			0xFF201000
	.equ	TIMER_BASE,				0xFF202000
	.equ	TIMER_2_BASE,			0xFF202020
	.equ	MTIMER_BASE,			0xFF202100
	.equ	PIXEL_BUF_CTRL_BASE,	0xFF203020
	.equ	CHAR_BUF_CTRL_BASE,		0xFF203030

/* Nios V memory-mapped registers */
    .equ    MTIME_BASE,             0xFF202100
