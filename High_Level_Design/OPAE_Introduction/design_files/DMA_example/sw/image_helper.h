#ifndef __IMAGE_HELPER_H__
#define __IMAGE_HELPER_H__

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int read_grayscale(char* filename, unsigned char** header,  unsigned char **converted_data, int *width_ptr, int *height_ptr);
void write_bmp(char* filename, unsigned char* header, unsigned char* data, int width, int height);

#endif // __IMAGE_HELPER_H__