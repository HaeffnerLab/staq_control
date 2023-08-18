onerror {resume}
divider add "Testbench"
wave add                 /tf/clk1
wave add                 /tf/c3_sys_rst
wave add                 /tf/rst_xfer

wave add                 /tf/write_mode
wave add                 /tf/read_mode
#wave add                 /tf/rd_en_d
#wave add -radix unsigned /tf/j

divider add "Memory Interface"
wave add                 /tf/mcb3_dram_ck;  
#wave add                 /tf/mcb3_dram_ck_n
wave add -radix hex      /tf/mcb3_dram_a
wave add -radix hex      /tf/mcb3_dram_ba  
wave add -radix hex      /tf/mcb3_dram_dq   
wave add                 /tf/mcb3_dram_dqs  
#wave add                 /tf/mcb3_dram_dqs_n
#wave add                 /tf/mcb3_dram_dm
#wave add                 /tf/mcb3_dram_ras_n
#wave add                 /tf/mcb3_dram_cas_n 
#wave add                 /tf/mcb3_dram_we_n  
#wave add                 /tf/mcb3_dram_cke 
#wave add                 /tf/mcb3_dram_odt   
#wave add                 /tf/mcb3_dram_udqs   
#wave add                 /tf/mcb3_dram_udqs_n  
#wave add                 /tf/mcb3_dram_udm


divider add "ramtester/ddr2_test_ext"
wave add                 /tf/dut/clk
wave add                 /tf/dut/reset
wave add                 /tf/dut/reads_en
wave add                 /tf/dut/writes_en
wave add                 /tf/dut/calib_done
	
wave add                 /tf/dut/ib_re
wave add -radix hex      /tf/dut/ib_data
wave add -radix hex      /tf/dut/ib_count
wave add                 /tf/dut/ib_valid
wave add                 /tf/dut/ib_empty

wave add                 /tf/dut/ob_we
wave add -radix hex      /tf/dut/ob_data
wave add -radix hex      /tf/dut/ob_count
		
wave add                 /tf/dut/p0_rd_en_o
wave add                 /tf/dut/p0_rd_empty
wave add -radix hex      /tf/dut/p0_rd_data
	
wave add                 /tf/dut/p0_cmd_en
wave add                 /tf/dut/p0_cmd_full
wave add -radix hex      /tf/dut/p0_cmd_instr
wave add -radix hex      /tf/dut/p0_cmd_byte_addr
wave add -radix hex      /tf/dut/p0_cmd_bl_o
	
wave add                 /tf/dut/p0_wr_en
wave add                 /tf/dut/p0_wr_full
wave add -radix hex      /tf/dut/p0_wr_data
wave add -radix hex      /tf/dut/p0_wr_mask


   
run 100 us
quit