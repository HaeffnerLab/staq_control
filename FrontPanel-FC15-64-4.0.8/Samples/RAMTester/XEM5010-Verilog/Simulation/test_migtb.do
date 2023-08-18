# This is a Modelsim simulation script.
# To use:
#  + Start Modelsim
#  + At the command-line, CD to the directory where this file is.
#  + Type: "do thisfilename.do"

# Source files and testfixture
vlib work
vlog test_migtb_tf.v
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
vlog ../MIG/ddr2_tb_test_addr_gen.v
vlog ../MIG/ddr2_tb_test_cmp.v
vlog ../MIG/ddr2_tb_test_data_gen.v
vlog ../MIG/ddr2_tb_test_gen.v
vlog ../MIG/ddr2_tb_top.v
vsim -L okFPsim_ver -L unisims_ver -t ps test_ddr2_tf okFPsim_ver.glbl

onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic /test_ddr2_tf/sys_clk
add wave -noupdate -format Logic /test_ddr2_tf/clk200
add wave -noupdate -format Logic /test_ddr2_tf/clk0
add wave -noupdate -format Logic /test_ddr2_tf/clk90
add wave -noupdate -format Logic /test_ddr2_tf/clkdiv0
add wave -noupdate -format Logic /test_ddr2_tf/sys_rst
add wave -noupdate -format Logic /test_ddr2_tf/phy_init_done
add wave -noupdate -format Logic /test_ddr2_tf/error
add wave -noupdate -format Logic /test_ddr2_tf/error_cmp

add wave -noupdate -divider scrap
add wave -noupdate -format Literal -radix hexadecimal /test_ddr2_tf/u_ddr2_top_0/u_mem_if_top/u_phy_top/u_phy_init/init_state_r
add wave -noupdate -format Literal -radix decimal /test_ddr2_tf/u_ddr2_top_0/u_mem_if_top/u_phy_top/u_phy_init/init_cnt_r
add wave -noupdate -format Logic /test_ddr2_tf/u_ddr2_top_0/u_mem_if_top/u_phy_top/u_phy_init/done_200us_r
add wave -noupdate -format Literal -radix decimal /test_ddr2_tf/u_ddr2_top_0/u_mem_if_top/u_phy_top/u_phy_init/cke_200us_cnt_r
add wave -noupdate -format Literal -radix decimal /test_ddr2_tf/u_ddr2_top_0/u_mem_if_top/u_phy_top/u_phy_init/cnt_200_cycle_r

add wave -noupdate -divider DDR2
add wave -noupdate -format Logic /test_ddr2_tf/ddr2_ck
add wave -noupdate -format Logic /test_ddr2_tf/ddr2_cke
add wave -noupdate -format Logic /test_ddr2_tf/ddr2_cs_n
add wave -noupdate -format Logic /test_ddr2_tf/ddr2_ras_n
add wave -noupdate -format Logic /test_ddr2_tf/ddr2_cas_n
add wave -noupdate -format Logic /test_ddr2_tf/ddr2_we_n
add wave -noupdate -format Logic /test_ddr2_tf/ddr2_odt
add wave -noupdate -format Literal -radix hexadecimal /test_ddr2_tf/ddr2_a
add wave -noupdate -format Literal -radix hexadecimal /test_ddr2_tf/ddr2_ba
add wave -noupdate -format Literal -radix hexadecimal /test_ddr2_tf/ddr2_dq
add wave -noupdate -format Literal -radix hexadecimal /test_ddr2_tf/ddr2_dm
add wave -noupdate -format Literal -radix hexadecimal /test_ddr2_tf/ddr2_dqs

add wave -noupdate -divider MemIF
add wave -noupdate -format Logic /test_ddr2_tf/app_wdf_afull
add wave -noupdate -format Logic /test_ddr2_tf/app_af_afull
add wave -noupdate -format Logic /test_ddr2_tf/rd_data_valid
add wave -noupdate -format Logic /test_ddr2_tf/app_wdf_wren
add wave -noupdate -format Logic /test_ddr2_tf/app_af_wren
add wave -noupdate -format Literal -radix hexadecimal /test_ddr2_tf/app_af_addr
add wave -noupdate -format Literal -radix hexadecimal /test_ddr2_tf/app_af_cmd
add wave -noupdate -format Literal -radix hexadecimal /test_ddr2_tf/rd_data_fifo_out
add wave -noupdate -format Literal -radix hexadecimal /test_ddr2_tf/app_wdf_data
add wave -noupdate -format Literal -radix hexadecimal /test_ddr2_tf/app_wdf_mask_data

update

run 100us
