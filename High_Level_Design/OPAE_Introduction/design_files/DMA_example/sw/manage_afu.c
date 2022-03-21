#include <stdio.h>
#include <uuid/uuid.h>
#include <opae/enum.h>
#include <opae/access.h>
#include <opae/mmio.h>
#include <opae/properties.h>
#include <opae/utils.h>

#include "afu_json_info.h"

// mandatory AFU register addresses (offsets)
#define AFU_DFH_REG   0x0
#define AFU_ID_LO     0x8 
#define AFU_ID_HI     0x10
#define AFU_NEXT      0x18
#define AFU_RESERVED  0x20

int print_AFU_regs (fpga_handle);
fpga_properties filter = NULL;
fpga_token token = NULL;

int open_AFU (fpga_handle *handle) {
    fpga_guid guid;
    uint32_t num_matches;
    fpga_result res = FPGA_OK;

    char *AFU_NAME = AFU_ACCEL_NAME;    // from json file
    char *UUID = AFU_ACCEL_UUID;        // from json file
    printf ("Opening %s\n", AFU_NAME);
    if (uuid_parse(AFU_ACCEL_UUID, guid) < 0) {
        fprintf(stderr, "Error parsing guid '%s'\n", UUID);
        return -1;
    }
    /* Look for AFU with MY_AFU_ID */
    if ((res = fpgaGetProperties (NULL, &filter)) != FPGA_OK) {
        fprintf(stderr, "Error creating properties object: %s\n", fpgaErrStr (res));
        return -1;
    }
    if ((res = fpgaPropertiesSetObjectType (filter, FPGA_ACCELERATOR)) != FPGA_OK) {
        fprintf(stderr, "Error setting object type: %s\n", fpgaErrStr (res));
        (void) fpgaDestroyProperties (&filter);
        return -1;
    }
    if ((res = fpgaPropertiesSetGUID (filter, guid)) != FPGA_OK) {
        fprintf(stderr, "Error setting GUID: %s\n", fpgaErrStr (res));
        (void) fpgaDestroyProperties (&filter);
        return -1;
    }
    if ((res = fpgaEnumerate (&filter, 1, &token, 1, &num_matches)) != FPGA_OK) {
        fprintf(stderr, "Error enumerating AFUs: %s\n", fpgaErrStr (res));
        (void) fpgaDestroyProperties (&filter);
        return -1;
    }
    if (num_matches < 1) {
        fprintf(stderr, "Error: AFU not found!\n");
        (void) fpgaDestroyProperties (&filter);
        return -1;
    }
    /* Open AFU and map MMIO */
    if ((res = fpgaOpen (token, handle, 0)) != FPGA_OK) {
        fprintf(stderr, "Error opening AFU: %s\n", fpgaErrStr (res));
        (void) fpgaDestroyToken (&token);
        (void) fpgaDestroyProperties (&filter);
        return -1;
    }
    if ((res = fpgaMapMMIO (*handle, 0, NULL)) != FPGA_OK) {
        fprintf(stderr, "Error mapping MMIO space: %s\n", fpgaErrStr (res));
        (void) fpgaClose (*handle);
        (void) fpgaDestroyToken (&token);
        (void) fpgaDestroyProperties (&filter);
        return -1;
    }
    /* Reset AFU */
    if ((res = fpgaReset (*handle)) != FPGA_OK) {
        fprintf(stderr, "Error resetting AFU: %s\n", fpgaErrStr (res));
        (void) fpgaUnmapMMIO (*handle, 0);
        (void) fpgaClose (*handle);
        (void) fpgaDestroyToken (&token);
        (void) fpgaDestroyProperties (&filter);
        return -1;
    }
    return print_AFU_regs (*handle);
}

// Displays the contents of mandatory AFU registers
int print_AFU_regs (fpga_handle handle) {
    uint64_t data = 0;
    bool fail = false;
    fpga_result res = FPGA_OK;

    if ((res = fpgaReadMMIO64 (handle, 0, AFU_DFH_REG, &data)) != FPGA_OK) {
        fprintf (stderr, "Error reading from MMIO: %s\n", fpgaErrStr (res));
        fail = true;
    }
    else
        printf("AFU DFH REG  = 0x%016lx\n", data);

    if ((res = fpgaReadMMIO64 (handle, 0, AFU_ID_HI, &data)) != FPGA_OK) {
        fprintf (stderr, "Error reading from MMIO: %s\n", fpgaErrStr (res));
        fail = true;
    }
    else
        printf("AFU ID HI    = 0x%016lx\n", data);
    if ((res = fpgaReadMMIO64 (handle, 0, AFU_ID_LO, &data)) != FPGA_OK) {
        fprintf (stderr, "Error reading from MMIO: %s\n", fpgaErrStr (res));
        fail = true;
    }
    else
        printf("AFU ID LO    = 0x%016lx\n", data);
    
    if ((res = fpgaReadMMIO64 (handle, 0, AFU_NEXT, &data)) != FPGA_OK) {
        fprintf (stderr, "Error reading from MMIO: %s\n", fpgaErrStr (res));
        fail = true;
    }
    else
        printf("AFU NEXT     = 0x%016lx\n", data);
    
    if ((res = fpgaReadMMIO64 (handle, 0, AFU_RESERVED, &data)) != FPGA_OK) {
        fprintf (stderr, "Error reading from MMIO: %s\n", fpgaErrStr (res));
        fail = true;
    }
    else
        printf("AFU RESERVED = 0x%016lx\n", data);

    if (fail) return -1;
    else return 0;
}
    
void close_AFU (fpga_handle handle) {
    /* Unmap MMIO space */
    (void) fpgaUnmapMMIO (handle, 0);
    /* Release accelerator */
    (void) fpgaClose (handle);
    /* Destroy token */
    (void) fpgaDestroyToken (&token);
    /* Destroy properties object */
    (void) fpgaDestroyProperties (&filter);
}

