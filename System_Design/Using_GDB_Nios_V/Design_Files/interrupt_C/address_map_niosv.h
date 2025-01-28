/*******************************************************************************
 * This file provides address values that exist in the DE1-SoC Computer
 ******************************************************************************/

#ifndef __SYSTEM_INFO__
#define __SYSTEM_INFO__

#define BOARD            "DE1-SoC"

/* Memory */
#define DDR_BASE               0x40000000
#define DDR_END                0x7FFFFFFF
#define SDRAM_BASE             0x00000000
#define SDRAM_END              0x03FFFFFF
#define FPGA_PIXEL_BUF_BASE    0x08000000
#define FPGA_PIXEL_BUF_END     0x0803FFFF
#define FPGA_CHAR_BASE         0x09000000
#define FPGA_CHAR_END          0x09001FFF

/* Cyclone V FPGA devices */
#define LED_BASE               0xFF200000
#define LEDR_BASE              0xFF200000
#define HEX3_HEX0_BASE         0xFF200020
#define HEX5_HEX4_BASE         0xFF200030
#define SW_BASE                0xFF200040
#define KEY_BASE               0xFF200050
#define JP1_BASE               0xFF200060
#define JP2_BASE               0xFF200070
#define PS2_BASE               0xFF200100
#define PS2_DUAL_BASE          0xFF200108
#define JTAG_UART_BASE         0xFF201000
#define IrDA_BASE              0xFF201020
#define TIMER_BASE             0xFF202000
#define TIMER_2_BASE           0xFF202020
#define AV_CONFIG_BASE         0xFF203000
#define RGB_RESAMPLER_BASE     0xFF203010
#define PIXEL_BUF_CTRL_BASE    0xFF203020
#define CHAR_BUF_CTRL_BASE     0xFF203030
#define AUDIO_BASE             0xFF203040
#define VIDEO_IN_BASE          0xFF203060
#define EDGE_DETECT_CTRL_BASE  0xFF203070
#define ADC_BASE               0xFF204000

/* Cyclone V HPS devices */
#define MTIME_BASE             0xFF202100

#endif
