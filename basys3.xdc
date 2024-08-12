#  This file is a general .xdc for the Basys3 rev B board
#  To use it in a project:
#  - uncomment the lines corresponding to used pins
#  - rename the used ports (in each line, after get_ports) according to the top level signal names in the project

#  Clock signal
set_property PACKAGE_PIN W5 [get_ports CLK]
set_property IOSTANDARD LVCMOS18 [get_ports CLK]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports CLK]

set_property PACKAGE_PIN R2 [get_ports {reset}]					
	set_property IOSTANDARD LVCMOS18 [get_ports {reset}]
set_property PACKAGE_PIN T1   [get_ports {hiz_degisikligi}] 
    set_property IOSTANDARD LVCMOS18 [get_ports {hiz_degisikligi}]
    
# saniye ayarlanmasi 
set_property -dict { PACKAGE_PIN V17   IOSTANDARD LVCMOS33 } [get_ports {saniye_ayari[0]}]
set_property -dict { PACKAGE_PIN V16   IOSTANDARD LVCMOS33 } [get_ports {saniye_ayari[1]}]
set_property -dict { PACKAGE_PIN W16   IOSTANDARD LVCMOS33 } [get_ports {saniye_ayari[2]}]
set_property -dict { PACKAGE_PIN W17   IOSTANDARD LVCMOS33 } [get_ports {saniye_ayari[3]}]
set_property -dict { PACKAGE_PIN W15   IOSTANDARD LVCMOS33 } [get_ports {saniye_ayari[4]}]
set_property -dict { PACKAGE_PIN V15   IOSTANDARD LVCMOS33 } [get_ports {saniye_ayari[5]}]



#  LEDs
set_property -dict { PACKAGE_PIN U16   IOSTANDARD LVCMOS33 } [get_ports {led_gosterimi[0]}]
set_property -dict { PACKAGE_PIN E19   IOSTANDARD LVCMOS33 } [get_ports {led_gosterimi[1]}]
set_property -dict { PACKAGE_PIN U19   IOSTANDARD LVCMOS33 } [get_ports {led_gosterimi[2]}]
set_property -dict { PACKAGE_PIN V19   IOSTANDARD LVCMOS33 } [get_ports {led_gosterimi[3]}]
set_property -dict { PACKAGE_PIN W18   IOSTANDARD LVCMOS33 } [get_ports {led_gosterimi[4]}]
set_property -dict { PACKAGE_PIN U15   IOSTANDARD LVCMOS33 } [get_ports {led_gosterimi[5]}]


# 7 Segment Display
set_property -dict { PACKAGE_PIN W7   IOSTANDARD LVCMOS18 } [get_ports {seg[0]}]
set_property -dict { PACKAGE_PIN W6   IOSTANDARD LVCMOS18 } [get_ports {seg[1]}]
set_property -dict { PACKAGE_PIN U8   IOSTANDARD LVCMOS18 } [get_ports {seg[2]}]
set_property -dict { PACKAGE_PIN V8   IOSTANDARD LVCMOS18 } [get_ports {seg[3]}]
set_property -dict { PACKAGE_PIN U5   IOSTANDARD LVCMOS18 } [get_ports {seg[4]}]
set_property -dict { PACKAGE_PIN V5   IOSTANDARD LVCMOS18 } [get_ports {seg[5]}]
set_property -dict { PACKAGE_PIN U7   IOSTANDARD LVCMOS18 } [get_ports {seg[6]}]

# 7 Segment Display Anode
set_property -dict { PACKAGE_PIN U2   IOSTANDARD LVCMOS18 } [get_ports {an[0]}]
set_property -dict { PACKAGE_PIN U4   IOSTANDARD LVCMOS18 } [get_ports {an[1]}]
set_property -dict { PACKAGE_PIN V4   IOSTANDARD LVCMOS18 } [get_ports {an[2]}]
set_property -dict { PACKAGE_PIN W4   IOSTANDARD LVCMOS18 } [get_ports {an[3]}]

set_property -dict { PACKAGE_PIN V7  IOSTANDARD LVCMOS18 } [get_ports {dp}]
# Buttons
set_property -dict { PACKAGE_PIN U18   IOSTANDARD LVCMOS33 } [get_ports {butonlar[4]}] 
set_property -dict { PACKAGE_PIN T18   IOSTANDARD LVCMOS33 } [get_ports {butonlar[2]}] 
set_property -dict { PACKAGE_PIN W19   IOSTANDARD LVCMOS33 } [get_ports {butonlar[1]}]
set_property -dict { PACKAGE_PIN T17   IOSTANDARD LVCMOS33 } [get_ports {butonlar[0]}]
set_property -dict { PACKAGE_PIN U17   IOSTANDARD LVCMOS33 } [get_ports {butonlar[3]}]

set_property -dict { PACKAGE_PIN B18  IOSTANDARD LVCMOS33 } [get_ports {rx}]
set_property -dict { PACKAGE_PIN A18  IOSTANDARD LVCMOS33 } [get_ports {tx}]



#VGA Connector
set_property PACKAGE_PIN J19 [get_ports {rgb[2]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {rgb[2]}]

set_property PACKAGE_PIN G17 [get_ports {rgb[1]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {rgb[1]}]
		

set_property PACKAGE_PIN K18 [get_ports {rgb[0]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {rgb[0]}]


set_property -dict { PACKAGE_PIN P19  IOSTANDARD LVCMOS33 } [get_ports {hsync}]
set_property -dict { PACKAGE_PIN R19  IOSTANDARD LVCMOS33 } [get_ports {vsync}]