# This is a Modelsim simulation script.
# To use:
#  + Start Modelsim
#  + At the command-line, CD to the directory where this file is.
#  + Type: "do thisfilename.do"

set PATH ./oksim

# Source files and testfixture
vlib work
vcom $PATH/mappings.vhd
vcom $PATH/parameters.vhd
vcom $PATH/okLibrary_sim.vhd

vcom First_tf.vhd

vcom First.vhd

vcom $PATH/okHost.vhd
vcom $PATH/okWireIn.vhd
vcom $PATH/okWireOut.vhd
vcom $PATH/okWireOR.vhd

vsim -t ps FIRST_TEST -novopt +acc

#Setup waveforms
onerror {resume}
quietly WaveActivateNextPane {} 0

add wave -noupdate -divider {FrontPanel Control}
add wave -noupdate -format Logic {/FIRST_TEST/hi_in[0]}

add wave -noupdate -divider Simulation
add wave -noupdate -format Literal -radix hexadecimal /FIRST_TEST/sim_process/r1
add wave -noupdate -format Literal -radix hexadecimal /FIRST_TEST/sim_process/r2
add wave -noupdate -format Literal -radix hexadecimal /FIRST_TEST/sim_process/exp
add wave -noupdate -format Literal -radix hexadecimal /FIRST_TEST/sim_process/sum

add wave -noupdate -divider First
add wave -noupdate -format Literal -radix hexadecimal /FIRST_TEST/dut/ep01wire
add wave -noupdate -format Literal -radix hexadecimal /FIRST_TEST/dut/ep02wire
add wave -noupdate -format Literal -radix hexadecimal /FIRST_TEST/dut/ep21wire

TreeUpdate [SetDefaultTree]
configure wave -namecolwidth 261
configure wave -valuecolwidth 58
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0

update
WaveRestoreZoom {0 ns} {8 us}

run 8 us
