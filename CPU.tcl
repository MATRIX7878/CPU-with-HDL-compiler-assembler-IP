if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vlib compiled

vmap work rtl_work
vmap compiled rtl_work

vcom -work compiled [pwd]/compiled.vhd
vcom -work work [pwd]/assemble.vhd -suppress 1339
#vcom -work work [pwd]/toplevel.vhd
#vcom -work work [pwd]/flash.vhd
#vcom -work work [pwd]/UART.vhd

vsim assemble

add wave -recursive *

force clk 0, 1 18.5 -r 37
force raw 'h434C522041430D0A53544120420D0A4A4D5A2031300D0A41444420420D0A41444420310D0A53544120420D0A535441204C45440D0A505345203235300D0A505345203235300D0A505345203235300D0A505345203235300D0A434C522041430D0A4A4D5A203130 0

view structure
view signals

run 500 us

view -undock wave
wave zoomfull
