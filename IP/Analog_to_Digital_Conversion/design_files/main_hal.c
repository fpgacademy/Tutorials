#include "altera_up_avalon_parallel_port.h"
#include "altera_up_avalon_adc.h"
int main (void){
	alt_up_parallel_port_dev * led;
	alt_up_adc_dev * adc;
	unsigned int data;
	int count;
	int channel;
	data = 0;
	count = 0;
	channel = 0;
	
	led =alt_up_parallel_port_open_dev ("/dev/Green_LEDs");
	adc = alt_up_adc_open_dev ("/dev/ADC");
	
	while (led!=NULL&&adc!=NULL){
		alt_up_adc_update (adc);
		count += 1;
		data = alt_up_adc_read (adc, channel);
		data = data / 16;
		alt_up_parallel_port_write_data (led, data);
		if (count==500000){
			count = 0;
			channel = !channel;
		}
	}
	return 0;
}
