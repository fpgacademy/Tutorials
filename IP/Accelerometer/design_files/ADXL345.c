#include "ADXL345.h"

void Pinmux_Config(){
    // Set up pin muxing (in sysmgr) to connect ADXL345 wires to I2C0
    *SYSMGR_I2C0USEFPGA = 0;
    *SYSMGR_GENERALIO7 = 1;
    *SYSMGR_GENERALIO8 = 1;
}

// Initialize the I2C0 controller for use with the ADXL345 chip
void I2C0_Init(){

    // Abort any ongoing transmits and disable I2C0.
    *I2C0_ENABLE = 2;
    
    // Wait until I2C0 is disabled
    while(((*I2C0_ENABLE_STATUS)&0x1) == 1){}
    
    // Configure the config reg with the desired setting (act as 
    // a master, use 7bit addressing, fast mode (400kb/s)).
    *I2C0_CON = 0x65;
    
    // Set target address (disable special commands, use 7bit addressing)
    *I2C0_TAR = 0x53;
    
    // Set SCL high/low counts (Assuming default 100MHZ clock input to I2C0 Controller).
    // The minimum SCL high period is 0.6us, and the minimum SCL low period is 1.3us,
    // However, the combined period must be 2.5us or greater, so add 0.3us to each.
    *I2C0_FS_SCL_HCNT = 60 + 30; // 0.6us + 0.3us
    *I2C0_FS_SCL_LCNT = 130 + 30; // 1.3us + 0.3us
    
    // Enable the controller
    *I2C0_ENABLE = 1;
    
    // Wait until controller is enabled
    while(((*I2C0_ENABLE_STATUS)&0x1) == 0){}
    
}

// Function to allow components on the FPGA side (ex. Nios II processors) to 
// access the I2C0 controller through the F2H bridge. This function
// needs to be called from an ARM program, and to allow a Nios II program
// to access the I2C0 controller.
void I2C0_Enable_FPGA_Access(){

    // Deassert fpga bridge resets
    *RSTMGR_BRGMODRST = 0;
    
    // Enable non-secure masters to access I2C0
    *L3REGS_L4SP = *L3REGS_L4SP | 0x4;
    
    // Enable non-secure masters to access pinmuxing registers (in sysmgr)
    *L3REGS_L4OSC1 = *L3REGS_L4OSC1 | 0x10;
}

// Write value to internal register at address
void ADXL345_REG_WRITE(uint8_t address, uint8_t value){
    
    // Send reg address (+0x400 to send START signal)
    *I2C0_DATA_CMD = address + 0x400;
    
    // Send value
    *I2C0_DATA_CMD = value;
}

// Read value from internal register at address
void ADXL345_REG_READ(uint8_t address, uint8_t *value){

    // Send reg address (+0x400 to send START signal)
    *I2C0_DATA_CMD = address + 0x400;
    
    // Send read signal
    *I2C0_DATA_CMD = 0x100;
    
    // Read the response (first wait until RX buffer contains data)  
    while (*I2C0_RXFLR == 0){}
    *value = *I2C0_DATA_CMD;
}

// Read multiple consecutive internal registers
void ADXL345_REG_MULTI_READ(uint8_t address, uint8_t values[], uint8_t len){

    // Send reg address (+0x400 to send START signal)
    *I2C0_DATA_CMD = address + 0x400;
    
    // Send read signal len times
    int i;
    for (i=0;i<len;i++)
        *I2C0_DATA_CMD = 0x100;

    // Read the bytes
    int nth_byte=0;
    while (len){
        if ((*I2C0_RXFLR) > 0){
            values[nth_byte] = *I2C0_DATA_CMD;
            nth_byte++;
            len--;
        }
    }
}

// Initialize the ADXL345 chip
void ADXL345_Init(){

    // +- 16g range, full resolution
    ADXL345_REG_WRITE(ADXL345_REG_DATA_FORMAT, XL345_RANGE_16G | XL345_FULL_RESOLUTION);
    
    // Output Data Rate: 200Hz
    ADXL345_REG_WRITE(ADXL345_REG_BW_RATE, XL345_RATE_200);

    // NOTE: The DATA_READY bit is not reliable. It is updated at a much higher rate than the Data Rate
    // Use the Activity and Inactivity interrupts.
    //----- Enabling interrupts -----//
    ADXL345_REG_WRITE(ADXL345_REG_THRESH_ACT, 0x04);	//activity threshold
    ADXL345_REG_WRITE(ADXL345_REG_THRESH_INACT, 0x02);	//inactivity threshold
    ADXL345_REG_WRITE(ADXL345_REG_TIME_INACT, 0x02);	//time for inactivity
    ADXL345_REG_WRITE(ADXL345_REG_ACT_INACT_CTL, 0xFF);	//Enables AC coupling for thresholds
    ADXL345_REG_WRITE(ADXL345_REG_INT_ENABLE, XL345_ACTIVITY | XL345_INACTIVITY );	//enable interrupts
    //-------------------------------//
    
    // stop measure
    ADXL345_REG_WRITE(ADXL345_REG_POWER_CTL, XL345_STANDBY);
    
    // start measure
    ADXL345_REG_WRITE(ADXL345_REG_POWER_CTL, XL345_MEASURE);
}

// Calibrate the ADXL345. The DE1-SoC should be placed on a flat
// surface, and must remain stationary for the duration of the calibration.
void ADXL345_Calibrate(){
    
    int average_x = 0;
    int average_y = 0;
    int average_z = 0;
    int16_t XYZ[3];
    int8_t offset_x;
    int8_t offset_y;
    int8_t offset_z;
    
    // stop measure
    ADXL345_REG_WRITE(ADXL345_REG_POWER_CTL, XL345_STANDBY);
    
    // Get current offsets
    ADXL345_REG_READ(ADXL345_REG_OFSX, (uint8_t *)&offset_x);
    ADXL345_REG_READ(ADXL345_REG_OFSY, (uint8_t *)&offset_y);
    ADXL345_REG_READ(ADXL345_REG_OFSZ, (uint8_t *)&offset_z);
    
    // Use 100 hz rate for calibration. Save the current rate.
    uint8_t saved_bw;
    ADXL345_REG_READ(ADXL345_REG_BW_RATE, &saved_bw);
    ADXL345_REG_WRITE(ADXL345_REG_BW_RATE, XL345_RATE_100);
    
    // Use 16g range, full resolution. Save the current format.
    uint8_t saved_dataformat;
    ADXL345_REG_READ(ADXL345_REG_DATA_FORMAT, &saved_dataformat);
    ADXL345_REG_WRITE(ADXL345_REG_DATA_FORMAT, XL345_RANGE_16G | XL345_FULL_RESOLUTION);
    
    // start measure
    ADXL345_REG_WRITE(ADXL345_REG_POWER_CTL, XL345_MEASURE);
    
    // Get the average x,y,z accelerations over 32 samples (LSB 3.9 mg)
    int i = 0;
    while (i < 32){
		// Note: use DATA_READY here, can't use ACTIVITY because board is stationary.
        if (ADXL345_IsDataReady()){
            ADXL345_XYZ_Read(XYZ);
            average_x += XYZ[0];
            average_y += XYZ[1];
            average_z += XYZ[2];
            i++;
        }
    }
    average_x = ROUNDED_DIVISION(average_x, 32);
    average_y = ROUNDED_DIVISION(average_y, 32);
    average_z = ROUNDED_DIVISION(average_z, 32);
    
    // stop measure
    ADXL345_REG_WRITE(ADXL345_REG_POWER_CTL, XL345_STANDBY);
    
    // printf("Average X=%d, Y=%d, Z=%d\n", average_x, average_y, average_z);
    
    // Calculate the offsets (LSB 15.6 mg)
    offset_x += ROUNDED_DIVISION(0-average_x, 4);
    offset_y += ROUNDED_DIVISION(0-average_y, 4);
    offset_z += ROUNDED_DIVISION(256-average_z, 4);
    
    // printf("Calibration: offset_x: %d, offset_y: %d, offset_z: %d (LSB: 15.6 mg)\n",offset_x,offset_y,offset_z);
    
    // Set the offset registers
    ADXL345_REG_WRITE(ADXL345_REG_OFSX, offset_x);
    ADXL345_REG_WRITE(ADXL345_REG_OFSY, offset_y);
    ADXL345_REG_WRITE(ADXL345_REG_OFSZ, offset_z);
    
    // Restore original bw rate
    ADXL345_REG_WRITE(ADXL345_REG_BW_RATE, saved_bw);
    
    // Restore original data format
    ADXL345_REG_WRITE(ADXL345_REG_DATA_FORMAT, saved_dataformat);
    
    // start measure
    ADXL345_REG_WRITE(ADXL345_REG_POWER_CTL, XL345_MEASURE);
}

// Return true if there was activity since the last read (checks ACTIVITY bit).
bool ADXL345_WasActivityUpdated(){
	bool bReady = false;
    uint8_t data8;
    
    ADXL345_REG_READ(ADXL345_REG_INT_SOURCE,&data8);
    if (data8 & XL345_ACTIVITY)
        bReady = true;
    
    return bReady;
}

// Return true if there is new data (checks DATA_READY bit).
bool ADXL345_IsDataReady(){
    bool bReady = false;
    uint8_t data8;
    
    ADXL345_REG_READ(ADXL345_REG_INT_SOURCE,&data8);
    if (data8 & XL345_DATAREADY)
        bReady = true;
    
    return bReady;
}

// Read acceleration data of all three axes
void ADXL345_XYZ_Read(int16_t szData16[3]){
    uint8_t szData8[6];
    ADXL345_REG_MULTI_READ(0x32, (uint8_t *)&szData8, sizeof(szData8));

    szData16[0] = (szData8[1] << 8) | szData8[0]; 
    szData16[1] = (szData8[3] << 8) | szData8[2];
    szData16[2] = (szData8[5] << 8) | szData8[4];
}

// Read the ID register
void ADXL345_IdRead(uint8_t *pId){
    ADXL345_REG_READ(ADXL345_REG_DEVID, pId);
}
