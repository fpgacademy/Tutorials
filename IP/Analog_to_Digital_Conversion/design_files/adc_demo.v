module adc_demo (CLOCK_50, KEY, LED, ADC_SCLK,
			ADC_CONVST, ADC_SDO, ADC_SDI);
input CLOCK_50;
input [0:0] KEY;
output [7:0] LED;
input ADC_SDO;
output ADC_SCLK, ADC_CONVST, ADC_SDI;
nios_system NIOS (
	.clk_clk (CLOCK_50),
	.reset_reset (!KEY[0]),
	.leds_export (LED),
	.adc_sclk (ADC_SCLK),
	.adc_cs_n (ADC_CONVST),
	.adc_dout (ADC_SDO),
	.adc_din (ADC_SDI)
);
endmodule

