# Clock signal
set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports { clk }]; #IO_L12P_T1_MRCC_35 Sch=clk100mhz
# syc_clk will be constrained by the MIG IP; commenting it avoids double clock definition and overridden clock definition warnings
create_clock -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports {clk}];  

set_property -dict { PACKAGE_PIN C2    IOSTANDARD LVCMOS33 } [get_ports { reset}]; #IO_L16P_T2_35 Sch=sd_dat[0]

set_property -dict { PACKAGE_PIN D4    IOSTANDARD LVCMOS33 } [get_ports { rx }]; 

set_property -dict { PACKAGE_PIN C4   IOSTANDARD LVCMOS33 } [get_ports { tx }]; 
