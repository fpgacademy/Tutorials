#ifndef KEYS_H
#define KEYS_H

/**
 * Function KEY_open: opens the pushbutton KEY device
 * Return: 1 on success, else 0
 */
int KEY_open (void);

/**
 * Function KEY_read: reads the pushbutton KEY device
 * Parameter data: pointer for returning data. If no KEYs are pressed *data = 0. 
 * 	If all KEYs are pressed *data = 0b1111
 * Return: 1 on success, else 0
 */
int KEY_read (int * /*data*/);

/**
 * Function KEY_close: closes the KEY device
 * Return: void
 */
void KEY_close (void);

#endif
