#ifndef HEX_H
#define HEX_H

/**
 * Function HEX_open: opens the 7-segment display HEX device
 * Return: 1 on success, else 0
 */
int HEX_open (void);

/**
 * Function HEX_set: sets the HEX displays to decimal digits from 0-9
 * Parameter data: the data to be displayed as a 6-digit decimal number. The upper
 * 	two digits will be displayed on HEX5-4, and the lower four digits on HEX3-0
 * Return: void
 */
void HEX_set (int /*data*/);

/**
 * Function HEX_raw: sets the HEX displays to any (raw) value
 * Parameter data_h: the lowest 16 bits are written to HEX5-4
 * Parameter data_l: a 32-bit value that is written to HEX3-0
 * Return: void
 */
void HEX_raw (int /*data_h*/, int /*data_l*/);

/**
 * Function HEX_close: closes the HEX device
 * Return: void
 */
void HEX_close (void);

#endif
