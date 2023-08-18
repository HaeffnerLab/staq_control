onerror {resume}
divider add "Testbench"
wave add                 /tf/clk1

wave add -radix hex      /tf/hi_in
wave add -radix hex      /tf/hi_out
wave add -radix hex      /tf/hi_inout


divider add "Memory Interface"
wave add                 /tf/mcb3_dram_ck;  
#wave add                 /tf/mcb3_dram_ck_n
wave add -radix hex      /tf/mcb3_dram_a
wave add -radix hex      /tf/mcb3_dram_ba  
wave add -radix hex      /tf/mcb3_dram_dq   
wave add                 /tf/mcb3_dram_dqs  
#wave add                 /tf/mcb3_dram_dqs_n
wave add                 /tf/mcb3_dram_dm
wave add                 /tf/mcb3_dram_ras_n
wave add                 /tf/mcb3_dram_cas_n 
wave add                 /tf/mcb3_dram_we_n  
wave add                 /tf/mcb3_dram_cke 
#wave add                 /tf/mcb3_dram_odt   
#wave add                 /tf/mcb3_dram_udqs   
#wave add                 /tf/mcb3_dram_udqs_n  
#wave add                 /tf/mcb3_dram_udm

divider add "ramtester/ddr2_test_ext"
wave add                 /tf/dut/ddr2_tb/clk
wave add                 /tf/dut/ddr2_tb/reset
wave add                 /tf/dut/ddr2_tb/reads_en
wave add                 /tf/dut/ddr2_tb/writes_en
wave add                 /tf/dut/ddr2_tb/calib_done
	
wave add                 /tf/dut/ddr2_tb/ib_re
wave add -radix hex      /tf/dut/ddr2_tb/ib_data
wave add -radix hex      /tf/dut/ddr2_tb/ib_count
wave add                 /tf/dut/ddr2_tb/ib_valid
wave add                 /tf/dut/ddr2_tb/ib_empty

wave add                 /tf/dut/ddr2_tb/ob_we
wave add -radix hex      /tf/dut/ddr2_tb/ob_data
wave add -radix hex      /tf/dut/ddr2_tb/ob_count
		
wave add                 /tf/dut/ddr2_tb/p0_rd_en_o
wave add                 /tf/dut/ddr2_tb/p0_rd_empty
wave add -radix hex      /tf/dut/ddr2_tb/p0_rd_data
	
wave add                 /tf/dut/ddr2_tb/p0_cmd_en
wave add                 /tf/dut/ddr2_tb/p0_cmd_full
wave add -radix hex      /tf/dut/ddr2_tb/p0_cmd_instr
wave add -radix hex      /tf/dut/ddr2_tb/p0_cmd_byte_addr
wave add -radix hex      /tf/dut/ddr2_tb/p0_cmd_bl_o
	
wave add                 /tf/dut/ddr2_tb/p0_wr_en
wave add                 /tf/dut/ddr2_tb/p0_wr_full
wave add -radix hex      /tf/dut/ddr2_tb/p0_wr_data
wave add -radix hex      /tf/dut/ddr2_tb/p0_wr_mask
   
run 50 us
quit