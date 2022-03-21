#ifndef SW_H
#define SW_H

/**
 * Function SW_open: opens the slide switch SW device
 * Return: 1 on success, else 0
 */
int SW_open (void);

/**
 * Function SW_read: reads the SW device
 * Parameter data: pointer for returning data. If no switches are set *data = 0.
 * 	If all switches are set *data = 0b1111111111
 * Return: 1 on success, else 0
 */
int SW_read (int * /*data*/);

/**
 * Function SW_close: closes the SW device
 * Return: void
 */
void SW_close (void);

#endif
