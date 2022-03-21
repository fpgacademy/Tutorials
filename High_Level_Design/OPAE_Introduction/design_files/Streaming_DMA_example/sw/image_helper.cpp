#include "image_helper.h"


struct pixel {
   unsigned char b;
   unsigned char g;
   unsigned char r;
};


int read_grayscale(char* filename, unsigned char** header,  unsigned char **converted_data, int *width_ptr, int *height_ptr) {
   struct pixel * data_temp;
   unsigned char * header_temp;
   FILE* file = fopen(filename, "rb");
   
   if (!file) return -1;
   
   // read the 54-byte header
   header_temp = (unsigned char *)malloc(54*sizeof(unsigned char));
   if (fread(header_temp, sizeof(unsigned char), 54, file) != 54){
		printf("Error reading BMP header\n");
		return -1;
   }   

   // get height and width of image
   int width = *(int*)&header_temp[18];
   int height = *(int*)&header_temp[22];

   // Read in the image
   unsigned int size = width * height;
   data_temp = (pixel *)malloc(size*sizeof(struct pixel)); 
   if (fread(data_temp, sizeof(struct pixel), size, file) != size){
		printf("Error reading BMP image\n");
		return -1;
   }   
   fclose(file);

   // convert to grayscale
   int i;
   *converted_data = (unsigned char*) malloc(width * height*sizeof(unsigned char));
   
   for (i = 0; i < width*height; i++) {
	   (*converted_data)[i] = (data_temp[i].r + data_temp[i].g + data_temp[i].b)/3;
   }

   *header = header_temp;
   *width_ptr = width;
   *height_ptr = height;
   
   return 0;
}



void write_rgba_bmp(char* filename, unsigned char* header, unsigned char* data) {
   FILE* file = fopen(filename, "wb");

   int width = *(int*)&header[18];
   int height = *(int*)&header[22];
   
   int size = width * height;
   struct pixel * data_temp = (pixel *)malloc(size*sizeof(struct pixel)); 
   
   // write the 54-byte header
   fwrite(header, sizeof(unsigned char), 54, file); 
   int y, x;
   int base;

   // the r field of the pixel has the grayscale value. copy to g and b.
   for (y = 0; y < height; y++) {
      for (x = 0; x < width; x++) {
         base = y*width + x;
         (*(data_temp + base)).b = (*(data + base*4+1));
         (*(data_temp + base)).g = (*(data + base*4+2));
         (*(data_temp + base)).r = (*(data + base*4+3));
      }
   }
   
   fwrite(data_temp, sizeof(struct pixel), size, file); 
   
   free(data_temp);
   fclose(file);

}




// Write the grayscale image to disk.
void write_grayscale_bmp(char* filename, unsigned char* header, unsigned char* data) {
   FILE* file = fopen(filename, "wb");

   int width = *(int*)&header[18];
   int height = *(int*)&header[22];
   
   int size = width * height;
   struct pixel * data_temp = (pixel *)malloc(size*sizeof(struct pixel)); 
   
   // write the 54-byte header
   fwrite(header, sizeof(unsigned char), 54, file); 
   int y, x;
   
   // the r field of the pixel has the grayscale value. copy to g and b.
   for (y = 0; y < height; y++) {
      for (x = 0; x < width; x++) {
         (*(data_temp + y*width + x)).b = (*(data + y*width + x));
         (*(data_temp + y*width + x)).g = (*(data + y*width + x));
         (*(data_temp + y*width + x)).r = (*(data + y*width + x));
      }
   }
   
   size = width * height;
   fwrite(data_temp, sizeof(struct pixel), size, file); 
   
   free(data_temp);
   fclose(file);
}
