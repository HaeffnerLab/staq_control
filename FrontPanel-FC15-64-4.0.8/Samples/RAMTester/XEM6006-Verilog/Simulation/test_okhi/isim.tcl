onerror {resume}
divider add "Testbench"
wave add                 /tf/sys_clk

wave add -radix hex      /tf/hi_in
wave add -radix hex      /tf/hi_out
wave add -radix hex      /tf/hi_inout

wave add                 /tf/dut/calib_done


divider add "Memory Interface"
wave add                 /tf/ddr2_ck;  
#wave add                 /tf/ddr2_ck_n
wave add -radix hex      /tf/ddr2_a
wave add -radix hex      /tf/ddr2_ba  
wave add -radix hex      /tf/ddr2_dq   
wave add                 /tf/ddr2_dqs  
#wave add                 /tf/ddr2_dqs_n
wave add                 /tf/ddr2_dm
wave add                 /tf/ddr2_ras_n
wave add                 /tf/ddr2_cas_n 
wave add                 /tf/ddr2_we_n  
wave add                 /tf/ddr2_cke 
#wave add                 /tf/ddr2_odt   
#wave add                 /tf/ddr2_udqs   
#wave add                 /tf/ddr2_udqs_n  
#wave add                 /tf/ddr2_udm

divider add "ramtester/ddr2_test_ext"
wave add                 /tf/dut/ddr2_tb/clk
wave add                 /tf/dut/ddr2_tb/reset
wave add                 /tf/dut/ddr2_tb/reads_en
wave add                 /tf/dut/ddr2_tb/writes_en
wave add                 /tf/dut/ddr2_tb/calib_done
	
wave add                 /tf/dut/ddr2_tb/ib_re
wave add -radix hex      /tf/dut/ddr2_tb/ib_data
wave add -radix unsigned /tf/dut/ddr2_tb/ib_count
wave add                 /tf/dut/ddr2_tb/ib_valid
wave add                 /tf/dut/ddr2_tb/ib_empty

wave add                 /tf/dut/ddr2_tb/ob_we
wave add -radix hex      /tf/dut/ddr2_tb/ob_data
wave add -radix unsigned /tf/dut/ddr2_tb/ob_count
		
wave add                 /tf/dut/ddr2_tb/p0_rd_en_o
wave add                 /tf/dut/ddr2_tb/p0_rd_empty
wave add -radix hex      /tf/dut/ddr2_tb/p0_rd_data
	
wave add                 /tf/dut/ddr2_tb/p0_cmd_en
wave add                 /tf/dut/ddr2_tb/p0_cmd_full
wave add -radix hex      /tf/dut/ddr2_tb/p0_cmd_instr
wave add -radix hex      /tf/dut/ddr2_tb/p0_cmd_byte_addr
wave add -radix unsigned /tf/dut/ddr2_tb/p0_cmd_bl_o
	
wave add                 /tf/dut/ddr2_tb/p0_wr_en
wave add                 /tf/dut/ddr2_tb/p0_wr_full
wave add -radix hex      /tf/dut/ddr2_tb/p0_wr_data
wave add -radix hex      /tf/dut/ddr2_tb/p0_wr_mask

divider add "ramtester/ddr2_test_int"
wave add -radix unsigned /tf/dut/ddr2_tb/state
wave add                 /tf/dut/ddr2_tb/rd_fifo_afull
wave add -radix unsigned /tf/dut/ddr2_tb/cmd_byte_addr_wr
wave add -radix unsigned /tf/dut/ddr2_tb/cmd_byte_addr_rd
wave add -radix unsigned /tf/dut/ddr2_tb/burst_cnt;

wave add                 /tf/dut/ddr2_tb/write_mode;
wave add                 /tf/dut/ddr2_tb/read_mode;
wave add                 /tf/dut/ddr2_tb/reset_d;
   
run 50 us
quit