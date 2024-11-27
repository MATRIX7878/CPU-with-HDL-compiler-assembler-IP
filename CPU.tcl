if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vlib compiled

vmap work rtl_work
vmap compiled rtl_work

vcom -work compiled [pwd]/compiled.vhd
vcom -work work [pwd]/assemble.vhd
#vcom -work work [pwd]/toplevel.vhd
#vcom -work work [pwd]/flash.vhd
#vcom -work work [pwd]/UART.vhd

vsim assemble

add wave -recursive *

force clk 0, 1 18.5 -r 37
force raw 'h434C522041430A53544120420A4A4D505A2031300A0A2E6F72672031300A41444420420A41444420310A53544120420A535441204C45440A505345203235300A505345203235300A505345203235300A505345203235300A434C522041430A4A4D505A203130 0

view structure
view signals

run 500 us

view -undock wave
wave zoomfull
