`ifndef TOP_VHD
`define TOP_VHD

module my_led
  (
	//inputs
	red_i,green_i,blue_i,hp_i,
	//outputs
	red, green, blue,hp
	);


	input red_i;
	input green_i;
	input blue_i;
	input hp_i;

	output red;
	output green;
	output blue;
	output hp;


	SB_LED_DRV_CUR  LED_CUR_inst	(
											 .EN(1'b1),
											 .LEDPU(led_power_up)
											 );

	SB_RGB_DRV 	RGB_DRIVER 			(
											 .RGBLEDEN(1'b1),
											 .RGB0PWM(red_i),
											 .RGB1PWM(green_i),
											 .RGB2PWM(blue_i),
											 .RGBPU(led_power_up),
											 .RGB0(red),
											 .RGB1(green),
											 .RGB2(blue)
											 );

	defparam RGB_DRIVER.RGB0_CURRENT = "0b000111";
	defparam RGB_DRIVER.RGB1_CURRENT = "0b000111";
	defparam RGB_DRIVER.RGB2_CURRENT = "0b000111";


	SB_IR_DRV IRDRVinst (
								.IRLEDEN(1'b1),
								.IRPWM(hp_i),
								.IRPU(led_power_up),
								.IRLED(hp)
								);

	defparam IRDRVinst.IR_CURRENT = "0b0000000011";

endmodule

`endif
