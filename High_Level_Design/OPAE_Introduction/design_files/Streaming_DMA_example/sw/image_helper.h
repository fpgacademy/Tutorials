#ifndef __IMAGE_HELPER_H__
#define __IMAGE_HELPER_H__

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int read_grayscale(char* filename, unsigned char** header,  unsigned char **converted_data, int *width_ptr, int *height_ptr);
void write_grayscale_bmp(char* filename, unsigned char* header, unsigned char* data);
void write_rgba_bmp(char* filename, unsigned char* header, unsigned char* data);

#endif // __IMAGE_HELPER_H__