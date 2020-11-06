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

	assign red = red_i;
	assign green = green_i;
	assign blue = blue_i;

endmodule

`endif
