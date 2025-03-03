if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vlib compiled
vlib translator
vlib bytes

vmap work rtl_work
vmap compiled rtl_work
vmap translator rtl_work
vmap bytes rtl_work

vcom -work compiled [pwd]/compiled.vhd
vcom -work translator [pwd]/translator.vhd
vcom -work bytes [pwd]/bytes.vhd
vcom -work work [pwd]/parser.vhd
vcom -work work [pwd]/assembler.vhd
vcom -work work [pwd]/toplevel.vhd
#vcom -work work [pwd]/flash.vhd
#vcom -work work [pwd]/UARTTX.vhd
vcom -work work [pwd]/CPU_TB.vhd

vsim CPU_TB

add wave -recursive *

view structure
view signals

run 10 us

view -undock wave
wave zoomfull