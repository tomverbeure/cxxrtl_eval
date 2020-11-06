#**************************************************************
# This .sdc file is created by Terasic Tool.
# Users are recommended to modify this file to match users logic.
#**************************************************************

#**************************************************************
# Create Clock
#**************************************************************
create_clock -period 5 [get_ports CLOCK_50]
create_clock -period 20 [get_ports CLOCK2_50]
create_clock -period 20 [get_ports CLOCK3_50]
create_clock -period 10.416 CAMERA_PIXCLK
create_clock -period 100000 I2C_CCD_Config:u8|mI2C_CTRL_CLK

#Opencores unconstrained problem
create_clock -name altera_reserved_tck -period 100.000 [get_ports {altera_reserved_tck}]
set_false_path -from [get_clocks {altera_reserved_tck}] -to [get_clocks {altera_reserved_tck}]

#**************************************************************
# Create Generated Clock
#**************************************************************
derive_pll_clocks



#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************
derive_clock_uncertainty



#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************
#set_output_delay -clock { qsys_system|altpll_0|sd1|pll7|clk[3] } -min 10 [get_ports  HC_DEN]
#set_output_delay -clock { qsys_system|altpll_0|sd1|pll7|clk[3] } -max 15 [get_ports  HC_DEN]
#set_output_delay -clock { qsys_system|altpll_0|sd1|pll7|clk[3] } -min 10 [get_ports {HC_R[*] HC_G[*] HC_B[*]}]
#set_output_delay -clock { qsys_system|altpll_0|sd1|pll7|clk[3] } -max 15 [get_ports {HC_R[*] HC_G[*] HC_B[*]}]
#set_output_delay -clock { qsys_system|altpll_0|sd1|pll7|clk[3] } -min  7.5 [get_ports {VGA_BLANK_N VGA_SYNC_N VGA_HS VGA_VS VGA_R[*] VGA_G[*] VGA_B[*]}]
#set_output_delay -clock { qsys_system|altpll_0|sd1|pll7|clk[3] } -max 17.5 [get_ports {VGA_BLANK_N VGA_SYNC_N VGA_HS VGA_VS VGA_R[*] VGA_G[*] VGA_B[*]}]


#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************
#set_false_path -to [get_keepers {*vbvip_planar2is:*|dcfifo:*}]
set_false_path -from [get_keepers {*Reset_Delay:*|oRST*}]

#Not sure what's going on in Nios here to make this necessary
#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************



#**************************************************************
# Set Load
#**************************************************************
