## This file is a general .xdc for the CmodA7 rev. B
## To use it in a project:
## - uncomment the lines corresponding to used pins
## - rename the used ports (in each line, after get_ports) according to the top level signal names in the project

# LEDs
set_property -dict {PACKAGE_PIN A17 IOSTANDARD LVCMOS33} [get_ports {led[0]}]
set_property -dict {PACKAGE_PIN C16 IOSTANDARD LVCMOS33} [get_ports {led[1]}]
set_property -dict {PACKAGE_PIN B17 IOSTANDARD LVCMOS33} [get_ports blue]
set_property -dict {PACKAGE_PIN B16 IOSTANDARD LVCMOS33} [get_ports green]
set_property -dict {PACKAGE_PIN C17 IOSTANDARD LVCMOS33} [get_ports red]


# Buttons
set_property -dict {PACKAGE_PIN A18 IOSTANDARD LVCMOS33} [get_ports btn0]
set_property -dict {PACKAGE_PIN B18 IOSTANDARD LVCMOS33} [get_ports btn1]

## GPIO Pins
set_property -dict { PACKAGE_PIN A16   IOSTANDARD LVCMOS33 } [get_ports { send_frame }]; #IO_L12P_T1_MRCC_16 Sch=pio[03]
set_property -dict {PACKAGE_PIN R3 IOSTANDARD LVCMOS33} [get_ports can_tx]
set_property -dict {PACKAGE_PIN A14 IOSTANDARD LVCMOS33} [get_ports { can_rx_buf }]
set_property -dict {PACKAGE_PIN T3 IOSTANDARD LVCMOS33} [get_ports {dlc_rx[0]}]
set_property -dict {PACKAGE_PIN R2 IOSTANDARD LVCMOS33} [get_ports {dlc_rx[1]}]
set_property -dict {PACKAGE_PIN T1 IOSTANDARD LVCMOS33} [get_ports {dlc_rx[2]}]
set_property -dict {PACKAGE_PIN T2 IOSTANDARD LVCMOS33} [get_ports {dlc_rx[3]}]
set_property -dict { PACKAGE_PIN U1    IOSTANDARD LVCMOS33 } [get_ports { can_rx }]; #IO_L3N_T0_DQS_34 Sch=pio[31]

set_property SLEW SLOW [get_ports can_tx]
set_property DRIVE 12 [get_ports can_tx]


set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk_1]
