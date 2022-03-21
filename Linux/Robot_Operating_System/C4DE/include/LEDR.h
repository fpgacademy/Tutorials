#ifndef LEDR_H
#define LEDR_H

/**
 * Function LEDR_open: opens the red light LEDR device
 * Return: 1 on success, else 0
 */
int LEDR_open (void);

/**
 * Function LEDR_set: turns on/off the lights. If data = 0 all lights will be 
 * 	turned off. If data = 0b1111111111 all lights will be turned on
 * Parameter data: written to LEDR device
 * Return: void
 */
void LEDR_set (int /*data*/);

/**
 * Function LEDR_close: closes the LEDR device
 * Return: void
 */
void LEDR_close (void);

#endif
