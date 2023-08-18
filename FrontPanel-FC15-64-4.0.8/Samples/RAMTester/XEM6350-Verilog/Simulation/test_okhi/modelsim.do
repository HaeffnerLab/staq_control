# This is a Modelsim simulation script.
# To use:
#  + Start Modelsim
#  + At the command-line, CD to the directory where this file is.
#  + Type: "do thisfilename.do"

# Source files and testfixture
vlib work
vlog test_okhi_tf.v
vlog +define+sg3 +define+x16 MT47H32M16/ddr2.v
vlog ../MIG/ddr2_ctrl.v
vlog ../MIG/ddr2_idelay_ctrl.v
vlog ../MIG/ddr2_mem_if_top.v
vlog ../MIG/ddr2_phy_calib.v
vlog ../MIG/ddr2_phy_ctl_io.v
vlog ../MIG/ddr2_phy_dm_iob.v
vlog ../MIG/ddr2_phy_dq_iob.v
vlog ../MIG/ddr2_phy_dqs_iob.v
vlog ../MIG/ddr2_phy_init.v
vlog ../MIG/ddr2_phy_io.v
vlog ../MIG/ddr2_phy_top.v
vlog ../MIG/ddr2_phy_write.v
vlog ../MIG/ddr2_top.v
vlog ../MIG/ddr2_usr_addr_fifo.v
vlog ../MIG/ddr2_usr_rd.v
vlog ../MIG/ddr2_usr_top.v
vlog ../MIG/ddr2_usr_wr.v
vlog ../Core/fifo_18kb_w18_r36.v
vlog ../Core/fifo_18kb_w36_r18.v
vlog ../ddr2_test.v
vlog ../infrastructure.v
vlog ../ramtest.v
vsim -L okFPsim_ver -L unisims_ver -L xilinxcorelib_ver -t ps test_ddr2_tf okFPsim_ver.glbl -novopt +acc

onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic                      /test_ddr2_tf/sys_clk
add wave -noupdate -format Literal -radix hexadecimal /test_ddr2_tf/led

add wave -noupdate -divider RAMXFER
add wave -noupdate -format Logic                      /test_ddr2_tf/u_ramtest/c0/clk
add wave -noupdate -format Logic                      /test_ddr2_tf/u_ramtest/c0/reset
add wave -noupdate -format Logic                      /test_ddr2_tf/u_ramtest/c0/reads_en
add wave -noupdate -format Logic                      /test_ddr2_tf/u_ramtest/c0/writes_en
add wave -noupdate -format Literal -radix unsigned    /test_ddr2_tf/u_ramtest/c0/state
add wave -noupdate -format Literal -radix unsigned    /test_ddr2_tf/u_ramtest/c0/burst_cnt
add wave -noupdate -format Literal -radix unsigned    /test_ddr2_tf/u_ramtest/c0/reads_queued
add wave -noupdate -format Literal -radix unsigned    /test_ddr2_tf/u_ramtest/c0/rd_wr_data_count
add wave -noupdate -format Literal -radix unsigned    /test_ddr2_tf/u_ramtest/c0/rd_fifo_used
add wave -noupdate -format Logic                      /test_ddr2_tf/u_ramtest/c0/rd_clk
add wave -noupdate -format Logic                      /test_ddr2_tf/u_ramtest/c0/rd_en
add wave -noupdate -format Literal -radix hexadecimal /test_ddr2_tf/u_ramtest/c0/rd_data
add wave -noupdate -format Logic                      /test_ddr2_tf/u_ramtest/c0/rd_data_valid
add wave -noupdate -format Logic                      /test_ddr2_tf/u_ramtest/c0/rd_fifo_afull
add wave -noupdate -format Literal -radix hexadecimal /test_ddr2_tf/u_ramtest/c0/app_af_addr_rd
add wave -noupdate -format Logic                      /test_ddr2_tf/u_ramtest/c0/wr_clk
add wave -noupdate -format Logic                      /test_ddr2_tf/u_ramtest/c0/wr_en
add wave -noupdate -format Literal -radix hexadecimal /test_ddr2_tf/u_ramtest/c0/wr_data
add wave -noupdate -format Logic                      /test_ddr2_tf/u_ramtest/c0/wr_fifo_rden
add wave -noupdate -format Logic                      /test_ddr2_tf/u_ramtest/c0/wr_fifo_aempty
add wave -noupdate -format Literal -radix hexadecimal /test_ddr2_tf/u_ramtest/c0/app_af_addr_wr

add wave -noupdate -divider MemIF
add wave -noupdate -format Logic                      /test_ddr2_tf/u_ramtest/a_app_wdf_afull
add wave -noupdate -format Logic                      /test_ddr2_tf/u_ramtest/a_app_af_afull
add wave -noupdate -format Logic                      /test_ddr2_tf/u_ramtest/a_rd_data_valid
add wave -noupdate -format Logic                      /test_ddr2_tf/u_ramtest/a_app_wdf_wren
add wave -noupdate -format Logic                      /test_ddr2_tf/u_ramtest/a_app_af_wren
add wave -noupdate -format Literal -radix hexadecimal /test_ddr2_tf/u_ramtest/a_app_af_addr
add wave -noupdate -format Literal -radix hexadecimal /test_ddr2_tf/u_ramtest/a_app_af_cmd
add wave -noupdate -format Literal -radix hexadecimal /test_ddr2_tf/u_ramtest/a_rd_data_fifo_out
add wave -noupdate -format Literal -radix hexadecimal /test_ddr2_tf/u_ramtest/a_app_wdf_data
add wave -noupdate -format Literal -radix hexadecimal /test_ddr2_tf/u_ramtest/a_app_wdf_mask_data

add wave -noupdate -divider DDR2
add wave -noupdate -format Logic                      /test_ddr2_tf/ddr2_ck
add wave -noupdate -format Logic                      /test_ddr2_tf/ddr2_cke
add wave -noupdate -format Logic                      /test_ddr2_tf/ddr2_cs_n
add wave -noupdate -format Logic                      /test_ddr2_tf/ddr2_ras_n
add wave -noupdate -format Logic                      /test_ddr2_tf/ddr2_cas_n
add wave -noupdate -format Logic                      /test_ddr2_tf/ddr2_we_n
add wave -noupdate -format Logic                      /test_ddr2_tf/ddr2_odt
add wave -noupdate -format Literal -radix hexadecimal /test_ddr2_tf/ddr2_a
add wave -noupdate -format Literal -radix hexadecimal /test_ddr2_tf/ddr2_ba
add wave -noupdate -format Literal -radix hexadecimal /test_ddr2_tf/ddr2_dq
add wave -noupdate -format Literal -radix hexadecimal /test_ddr2_tf/ddr2_dm
add wave -noupdate -format Literal -radix hexadecimal /test_ddr2_tf/ddr2_dqs

update

run 1us
