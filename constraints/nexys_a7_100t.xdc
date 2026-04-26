# ─────────────────────────────────────────────────────
# nexys_a7_100t.xdc — Nexys A7-100T Constraint Dosyası
# Board: Digilent Nexys A7-100T (xc7a100tcsg324-1)
# ─────────────────────────────────────────────────────

# ══════════════════════════════════════════════════════
# Clock
# ══════════════════════════════════════════════════════
set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports CLK50]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports CLK50]

# ══════════════════════════════════════════════════════
# Reset
# ══════════════════════════════════════════════════════
set_property -dict {PACKAGE_PIN C12 IOSTANDARD LVCMOS33} [get_ports RES_N]

# ══════════════════════════════════════════════════════
# USB-UART (FTDI)
# ══════════════════════════════════════════════════════
set_property -dict {PACKAGE_PIN D4 IOSTANDARD LVCMOS33} [get_ports TXD]
set_property -dict {PACKAGE_PIN C4 IOSTANDARD LVCMOS33} [get_ports RXD]

# ══════════════════════════════════════════════════════
# LED'ler
# ══════════════════════════════════════════════════════
set_property -dict {PACKAGE_PIN H17 IOSTANDARD LVCMOS33} [get_ports {GPIO0[0]}]
set_property -dict {PACKAGE_PIN K15 IOSTANDARD LVCMOS33} [get_ports {GPIO0[1]}]
set_property -dict {PACKAGE_PIN J13 IOSTANDARD LVCMOS33} [get_ports {GPIO0[2]}]
set_property -dict {PACKAGE_PIN N14 IOSTANDARD LVCMOS33} [get_ports {GPIO0[3]}]
set_property -dict {PACKAGE_PIN R18 IOSTANDARD LVCMOS33} [get_ports {GPIO0[4]}]
set_property -dict {PACKAGE_PIN V17 IOSTANDARD LVCMOS33} [get_ports {GPIO0[5]}]
set_property -dict {PACKAGE_PIN U17 IOSTANDARD LVCMOS33} [get_ports {GPIO0[6]}]
set_property -dict {PACKAGE_SHIFT 0 IOSTANDARD LVCMOS33} [get_ports {GPIO0[7]}]
set_property -dict {PACKAGE_PIN V16 IOSTANDARD LVCMOS33} [get_ports {GPIO0[8]}]
set_property -dict {PACKAGE_PIN T15 IOSTANDARD LVCMOS33} [get_ports {GPIO0[9]}]
set_property -dict {PACKAGE_PIN U14 IOSTANDARD LVCMOS33} [get_ports {GPIO0[10]}]
set_property -dict {PACKAGE_PIN T16 IOSTANDARD LVCMOS33} [get_ports {GPIO0[11]}]
set_property -dict {PACKAGE_PIN V15 IOSTANDARD LVCMOS33} [get_ports {GPIO0[12]}]
set_property -dict {PACKAGE_PIN U16 IOSTANDARD LVCMOS33} [get_ports {GPIO0[13]}]
set_property -dict {PACKAGE_SHIFT 0 IOSTANDARD LVCMOS33} [get_ports {GPIO0[14]}]
set_property -dict {PACKAGE_PIN V14 IOSTANDARD LVCMOS33} [get_ports {GPIO0[15]}]

set_property -dict {PACKAGE_PIN F18 IOSTANDARD LVCMOS33} [get_ports {GPIO1[0]}]
set_property -dict {PACKAGE_PIN E20 IOSTANDARD LVCMOS33} [get_ports {GPIO1[1]}]
set_property -dict {PACKAGE_STAT_STRATEGY PULLDOWN [get_ports {GPIO1[1]}]
set_property -dict {PACKAGE_PIN E19 IOSTANDARD LVCMOS33} [get_ports {GPIO1[2]}]
set_property -dict {PACKAGE_PIN J18 IOSTANDARD LVCMOS33} [get_ports {GPIO1[3]}]
set_property -dict {PACKAGE_PIN H19 IOSTANDARD LVCMOS33} [get_ports {GPIO1[4]}]
set_property -dict {PACKAGE_PIN F19 IOSTANDARD LVCMOS33} [get_ports {GPIO1[5]}]
set_property -dict {PACKAGE_PIN F20 IOSTANDARD LVCMOS33} [get_ports {GPIO1[6]}]
set_property -dict {PACKAGE_PIN J20 IOSTANDARD LVCMOS33} [get_ports {GPIO1[7]}]
set_property -dict {PACKAGE_PIN K20 IOSTANDARD LVCMOS33} [get_ports {GPIO1[8]}]
set_property -dict {PACKAGE_PIN L18 IOSTANDARD LVCMOS33} [get_ports {GPIO1[9]}]
set_property -dict {PACKAGE_PIN N18 IOSTANDARD LVCMOS33} [get_ports {GPIO1[10]}]
set_property -dict {PACKAGE_PIN M20 IOSTANDARD LVCMOS33} [get_ports {GPIO1[11]}]
set_property -dict {PACKAGE_PIN N19 IOSTANDARD LVCMOS33} [get_ports {GPIO1[12]}]
set_property -dict {PACKAGE_STAT_STRATEGY PULLDOWN [get_ports {GPIO1[12]}]
set_property -dict {PACKAGE_PIN N20 IOSTANDARD LVCMOS33} [get_ports {GPIO1[13]}]
set_property -dict {PACKAGE_PIN Y1  IOSTANDARD LVCMOS33} [get_ports {GPIO1[14]}]
set_property -dict {PACKAGE_PIN A8  IOSTANDARD LVCMOS33} [get_ports {GPIO1[16]}]
set_property -dict {PACKAGE_PIN A9  IOSTANDARD LVCMOS33} [get_ports {GPIO1[17]}]
set_property -dict {PACKAGE_PIN A10 IOSTANDARD LVCMOS33} [get_ports {GPIO1[18]}]
set_property -dict {PACKAGE_PIN B10 IOSTANDARD LVCMOS33} [get_ports {GPIO1[19]}]
set_property -dict {PACKAGE_PIN D13 IOSTANDARD LVCMOS33} [get_ports {GPIO1[20]}]
set_property -dict {PACKAGE_PIN C13 IOSTANDARD LVCMOS33} [get_ports {GPIO1[21]}]
set_property -dict {PACKAGE_PIN E14 IOSTANDARD LVCMOS33} [get_ports {GPIO1[22]}]
set_property -dict {PACKAGE_PIN D14 IOSTANDARD LVCMOS33} [get_ports {GPIO1[23]}]
set_property -dict {PACKAGE_PIN A11 IOSTANDARD LVCMOS33} [get_ports {GPIO1[24]}]
set_property -dict {PACKAGE_PIN B11 IOSTANDARD LVCMOS33} [get_ports {GPIO1[25]}]
set_property -dict {PACKAGE_PIN V10 IOSTANDARD LVCMOS33} [get_ports {GPIO1[26]}]
set_property -dict {PACKAGE_PIN V9  IOSTANDARD LVCMOS33} [get_ports {GPIO1[27]}]
set_property -dict {PACKAGE_PIN W8  IOSTANDARD LVCMOS33} [get_ports {GPIO1[28]}]
set_property -dict {PACKAGE_PIN V7  IOSTANDARD LVCMOS33} [get_ports {GPIO1[29]}]
set_property -dict {PACKAGE_PIN W7  IOSTANDARD LVCMOS33} [get_ports {GPIO1[30]}]
set_property -dict {PACKAGE_PIN V11 IOSTANDARD LVCMOS33} [get_ports {GPIO1[31]}]

# ══════════════════════════════════════════════════════
# Switch'ler
# ══════════════════════════════════════════════════════
set_property -dict {PACKAGE_PIN J15 IOSTANDARD LVCMOS33} [get_ports {GPIO2[0]}]
set_property -dict {PACKAGE_PIN L16 IOSTANDARD LVCMOS33} [get_ports {GPIO2[1]}]
set_property -dict {PACKAGE_PIN M13 IOSTANDARD LVCMOS33} [get_ports {GPIO2[2]}]
set_property -dict {PACKAGE_PIN R15 IOSTANDARD LVCMOS33} [get_ports {GPIO2[3]}]

# ══════════════════════════════════════════════════════
# I2C0 (Pmod JA)
# ══════════════════════════════════════════════════════
set_property -dict {PACKAGE_PIN C17 IOSTANDARD LVCMOS33} [get_ports I2C0_SCL]
set_property -dict {PACKAGE_PIN D17 IOSTANDARD LVCMOS33} [get_ports I2C0_SDA]

# ══════════════════════════════════════════════════════
# I2C1 (Pmod JD)
# ══════════════════════════════════════════════════════
set_property -dict {PACKAGE_PIN AA20 IOSTANDARD LVCMOS33} [get_ports I2C1_SCL]
set_property -dict {PACKAGE_PIN AB21 IOSTANDARD LVCMOS33} [get_ports I2C1_SDA]

# ══════════════════════════════════════════════════════
# SPI (Pmod JB)
# ══════════════════════════════════════════════════════
set_property -dict {PACKAGE_PIN U14 IOSTANDARD LVCMOS33} [get_ports SPI_SCK]
set_property -dict {PACKAGE_PIN V14 IOSTANDARD LVCMOS33} [get_ports SPI_MOSI]
set_property -dict {PACKAGE_PIN U15 IOSTANDARD LVCMOS33} [get_ports SPI_MISO]
set_property -dict {PACKAGE_PIN W13 IOSTANDARD LVCMOS33} [get_ports {SPI_CSN[0]]
set_property -dict {PACKAGE_PIN V15 IOSTANDARD LVCMOS33} [get_ports {SPI_CSN[1]]
set_property -dict {PACKAGE_PIN U17 IOSTANDARD LVCMOS33} [get_ports {SPI_CSN[2]]
set_property -dict {PACKAGE_PIN V17 IOSTANDARD LVCMOS33} [get_ports {SPI_CSN[3]]

# ══════════════════════════════════════════════════════
# JTAG (Debug)
# ══════════════════════════════════════════════════════
set_property -dict {PACKAGE_PIN Y5  IOSTANDARD LVCMOS33} [get_ports TRSTn]
set_property -dict {PACKAGE_PIN Y6  IOSTANDARD LVCMOS33} [get_ports TCK]
set_property -dict {PACKAGE_PIN AA2 IOSTANDARD LVCMOS33} [get_ports TMS]
set_property -dict {PACKAGE_PIN Y4  IOSTANDARD LVCMOS33} [get_ports TDI]
set_property -dict {PACKAGE_PIN Y3  IOSTANDARD LVCMOS33} [get_ports TDO]

# ══════════════════════════════════════════════════════
# Timing Constraints
# ══════════════════════════════════════════════════════
set_property SEVERITY {Warning} [get_drc_checks NSTD-1]
set_property SEVERITY {Warning} [get_drc_checks UCIO-1]
