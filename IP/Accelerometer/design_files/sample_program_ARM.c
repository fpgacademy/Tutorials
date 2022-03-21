#include "ADXL345.h"
#include <stdio.h>

int main(void){

    uint8_t devid;
    int16_t mg_per_lsb = 4;
    int16_t XYZ[3];
    
    // Configure Pin Muxing
    Pinmux_Config();
    
    // Initialize I2C0 Controller
    I2C0_Init();
    
    // 0xE5 is read from DEVID(0x00) if I2C is functioning correctly
    ADXL345_REG_READ(0x00, &devid);
    
    // Correct Device ID
    if (devid == 0xE5){
        // Initialize accelerometer chip
        ADXL345_Init();
        
        while(1){
            if (ADXL345_WasActivityUpdated()){
                ADXL345_XYZ_Read(XYZ);
                printf("X=%d mg, Y=%d mg, Z=%d mg\n", XYZ[0]*mg_per_lsb, XYZ[1]*mg_per_lsb, XYZ[2]*mg_per_lsb);
            }
        }
    } else {
        printf("Incorrect device ID\n");
    }
    
    return 0;
}