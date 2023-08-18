//------------------------------------------------------------------------
// ramtest.v
//
// This sample uses the Xilinx MIG DDR2 controller and HDL to move data
// from the PC to the DDR2 and vice-versa. Based on MIG generated example_top.v
//
// Host Interface registers:
// WireIn 0x00
//     0 - DDR2 read enable (0=disabled, 1=enabled)
//     1 - DDR2 write enable (0=disabled, 1=enabled)
//     2 - Reset
//
// PipeIn 0x80 - DDR2 write port (U11, DDR2)
// PipeOut 0xA0 - DDR2 read port (U11, DDR2)
//
// This sample is included for reference only.  No guarantees, either 
// expressed or implied, are to be drawn.
//------------------------------------------------------------------------
// tabstop 3
// Copyright (c) 2005-2009 Opal Kelly Incorporated
// $Rev: 303 $ $Date: 2007-05-16 19:13:24 -0700 (Wed, 16 May 2007) $
//------------------------------------------------------------------------
`timescale 1ns/1ps

module ramtest  #(
	parameter C3_P0_MASK_SIZE           = 4,
	parameter C3_P0_DATA_PORT_SIZE      = 32,
	parameter C3_P1_MASK_SIZE           = 4,
	parameter C3_P1_DATA_PORT_SIZE      = 32,
	parameter DEBUG_EN                  = 0,       
	parameter C3_MEMCLK_PERIOD          = 3200,       
	parameter C3_CALIB_SOFT_IP          = "TRUE",       
	parameter C3_SIMULATION             = "FALSE",       
	parameter C3_HW_TESTING             = "FALSE",       
	parameter C3_RST_ACT_LOW            = 0,       
	parameter C3_INPUT_CLK_TYPE         = "DIFFERENTIAL",       
	parameter C3_MEM_ADDR_ORDER         = "ROW_BANK_COLUMN",       
	parameter C3_NUM_DQ_PINS            = 16,       
	parameter C3_MEM_ADDR_WIDTH         = 13,       
	parameter C3_MEM_BANKADDR_WIDTH     = 3        
	)
	(

	input  wire [7:0]  hi_in,
	output wire [1:0]  hi_out,
	inout  wire [15:0] hi_inout,
	inout  wire        hi_aa,
	
	output wire        i2c_sda,
	output wire        i2c_scl,
	output wire        hi_muxsel,
	
	output wire [7:0]  led,
	
	input  wire                              clk1, // CY22393 CLKA @ 100MHz

	inout  wire [C3_NUM_DQ_PINS-1:0]         mcb3_dram_dq,
	output wire [C3_MEM_ADDR_WIDTH-1:0]      mcb3_dram_a,
	output wire [C3_MEM_BANKADDR_WIDTH-1:0]  mcb3_dram_ba,
	output wire                              mcb3_dram_ras_n,
	output wire                              mcb3_dram_cas_n,
	output wire                              mcb3_dram_we_n,
	output wire                              mcb3_dram_odt,
	output wire                              mcb3_dram_cke,
	output wire                              mcb3_dram_dm,
	inout  wire                              mcb3_dram_udqs,
	inout  wire                              mcb3_dram_udqs_n,
	inout  wire                              mcb3_rzq,
	inout  wire                              mcb3_zio,
	output wire                              mcb3_dram_udm,
	inout  wire                              mcb3_dram_dqs,
	inout  wire                              mcb3_dram_dqs_n,
	output wire                              mcb3_dram_ck,
	output wire                              mcb3_dram_ck_n,
	output wire                              mcb3_dram_cs_n
	);

   localparam C3_CLKOUT0_DIVIDE       = 1;       
   localparam C3_CLKOUT1_DIVIDE       = 1;       
   localparam C3_CLKOUT2_DIVIDE       = 16;       
   localparam C3_CLKOUT3_DIVIDE       = 8;       
   localparam C3_CLKFBOUT_MULT        = 2;       
   localparam C3_DIVCLK_DIVIDE        = 1;       
   localparam C3_ARB_NUM_TIME_SLOTS   = 12;       
   localparam C3_ARB_TIME_SLOT_0      = 3'o0;       
   localparam C3_ARB_TIME_SLOT_1      = 3'o0;       
   localparam C3_ARB_TIME_SLOT_2      = 3'o0;       
   localparam C3_ARB_TIME_SLOT_3      = 3'o0;       
   localparam C3_ARB_TIME_SLOT_4      = 3'o0;       
   localparam C3_ARB_TIME_SLOT_5      = 3'o0;       
   localparam C3_ARB_TIME_SLOT_6      = 3'o0;       
   localparam C3_ARB_TIME_SLOT_7      = 3'o0;       
   localparam C3_ARB_TIME_SLOT_8      = 3'o0;       
   localparam C3_ARB_TIME_SLOT_9      = 3'o0;       
   localparam C3_ARB_TIME_SLOT_10     = 3'o0;       
   localparam C3_ARB_TIME_SLOT_11     = 3'o0;       
   localparam C3_MEM_TRAS             = 40000;       
   localparam C3_MEM_TRCD             = 15000;       
   localparam C3_MEM_TREFI            = 7800000;       
   localparam C3_MEM_TRFC             = 127500;       
   localparam C3_MEM_TRP              = 15000;       
   localparam C3_MEM_TWR              = 15000;       
   localparam C3_MEM_TRTP             = 7500;       
   localparam C3_MEM_TWTR             = 7500;       
   localparam C3_MEM_TYPE             = "DDR2";       
   localparam C3_MEM_DENSITY          = "1Gb";       
   localparam C3_MEM_BURST_LEN        = 4;       
   localparam C3_MEM_CAS_LATENCY      = 5;       
   localparam C3_MEM_NUM_COL_BITS     = 10;       
   localparam C3_MEM_DDR1_2_ODS       = "FULL";       
   localparam C3_MEM_DDR2_RTT         = "50OHMS";       
   localparam C3_MEM_DDR2_DIFF_DQS_EN  = "YES";       
   localparam C3_MEM_DDR2_3_PA_SR     = "FULL";       
   localparam C3_MEM_DDR2_3_HIGH_TEMP_SR  = "NORMAL";       
   localparam C3_MEM_DDR3_CAS_LATENCY  = 6;       
   localparam C3_MEM_DDR3_ODS         = "DIV6";       
   localparam C3_MEM_DDR3_RTT         = "DIV2";       
   localparam C3_MEM_DDR3_CAS_WR_LATENCY  = 5;       
   localparam C3_MEM_DDR3_AUTO_SR     = "ENABLED";       
   localparam C3_MEM_DDR3_DYN_WRT_ODT  = "OFF";       
   localparam C3_MEM_MOBILE_PA_SR     = "FULL";       
   localparam C3_MEM_MDDR_ODS         = "FULL";       
   localparam C3_MC_CALIB_BYPASS      = "NO";       
   localparam C3_MC_CALIBRATION_MODE  = "CALIBRATION";       
   localparam C3_MC_CALIBRATION_DELAY  = "HALF";       
   localparam C3_SKIP_IN_TERM_CAL     = 0;       
   localparam C3_SKIP_DYNAMIC_CAL     = 0;       
   localparam C3_LDQSP_TAP_DELAY_VAL  = 0;       
   localparam C3_LDQSN_TAP_DELAY_VAL  = 0;       
   localparam C3_UDQSP_TAP_DELAY_VAL  = 0;       
   localparam C3_UDQSN_TAP_DELAY_VAL  = 0;       
   localparam C3_DQ0_TAP_DELAY_VAL    = 0;       
   localparam C3_DQ1_TAP_DELAY_VAL    = 0;       
   localparam C3_DQ2_TAP_DELAY_VAL    = 0;       
   localparam C3_DQ3_TAP_DELAY_VAL    = 0;       
   localparam C3_DQ4_TAP_DELAY_VAL    = 0;       
   localparam C3_DQ5_TAP_DELAY_VAL    = 0;       
   localparam C3_DQ6_TAP_DELAY_VAL    = 0;       
   localparam C3_DQ7_TAP_DELAY_VAL    = 0;       
   localparam C3_DQ8_TAP_DELAY_VAL    = 0;       
   localparam C3_DQ9_TAP_DELAY_VAL    = 0;       
   localparam C3_DQ10_TAP_DELAY_VAL   = 0;       
   localparam C3_DQ11_TAP_DELAY_VAL   = 0;       
   localparam C3_DQ12_TAP_DELAY_VAL   = 0;       
   localparam C3_DQ13_TAP_DELAY_VAL   = 0;       
   localparam C3_DQ14_TAP_DELAY_VAL   = 0;       
   localparam C3_DQ15_TAP_DELAY_VAL   = 0;       
   localparam C3_p0_BEGIN_ADDRESS                   = (C3_HW_TESTING == "TRUE") ? 32'h01000000:32'h00000100;
   localparam C3_p0_DATA_MODE                       = 4'b0010;
   localparam C3_p0_END_ADDRESS                     = (C3_HW_TESTING == "TRUE") ? 32'h02ffffff:32'h000002ff;
   localparam C3_p0_PRBS_EADDR_MASK_POS             = (C3_HW_TESTING == "TRUE") ? 32'hfc000000:32'hfffffc00;
   localparam C3_p0_PRBS_SADDR_MASK_POS             = (C3_HW_TESTING == "TRUE") ? 32'h01000000:32'h00000100;
  wire                              c3_sys_clk;
  wire                              c3_error;
  wire                              c3_calib_done;
  wire                              c3_clk0;
  reg                               c3_sys_rst_n;
  wire                              c3_rst0;
  wire                              c3_async_rst;
  wire                              c3_sysclk_2x;
  wire                              c3_sysclk_2x_180;
  wire                              c3_pll_ce_0;
  wire                              c3_pll_ce_90;
  wire                              c3_pll_lock;
  wire                              c3_mcb_drp_clk;
  wire                              c3_cmp_error;
  wire                              c3_cmp_data_valid;
  wire                              c3_vio_modify_enable;
  wire  [127:0]                     c3_error_status;
  wire  [2:0]                       c3_vio_data_mode_value;
  wire  [2:0]                       c3_vio_addr_mode_value;
  wire  [31:0]                      c3_cmp_data;
  wire                              c3_p0_cmd_en;
  wire [2:0]                        c3_p0_cmd_instr;
  wire [5:0]                        c3_p0_cmd_bl;
  wire [29:0]                       c3_p0_cmd_byte_addr;
  wire                              c3_p0_cmd_empty;
  wire                              c3_p0_cmd_full;
  wire                              c3_p0_wr_en;
  wire [C3_P0_MASK_SIZE - 1:0]      c3_p0_wr_mask;
  wire [C3_P0_DATA_PORT_SIZE - 1:0] c3_p0_wr_data;
  wire                              c3_p0_wr_full;
  wire                              c3_p0_wr_empty;
  wire [6:0]                        c3_p0_wr_count;
  wire                              c3_p0_wr_underrun;
  wire                              c3_p0_wr_error;
  wire                              c3_p0_rd_en;
  wire [C3_P0_DATA_PORT_SIZE - 1:0] c3_p0_rd_data;
  wire                              c3_p0_rd_full;
  wire                              c3_p0_rd_empty;
  wire [6:0]                        c3_p0_rd_count;
  wire                              c3_p0_rd_overflow;
  wire                              c3_p0_rd_error;
  wire                              selfrefresh_enter;          
  wire                              selfrefresh_mode; 


	// Front Panel

	// USB Host Interface
	wire        ti_clk;
	wire [30:0] ok1;
	wire [16:0] ok2;
	
	wire        pipe_in_start;
	wire        pipe_in_done;
	wire        pipe_in_read;
	wire [63:0] pipe_in_data;
	wire [8:0]  pipe_in_count;
	wire        pipe_in_valid;
	wire        pipe_in_empty;
	
	wire        pipe_out_start;
	wire        pipe_out_done;
	wire        pipe_out_write;
	wire [63:0] pipe_out_data;
	wire [8:0]  pipe_out_count;
	wire        pipe_out_full;
	
	// Pipe Fifos
	wire        pi0_ep_write, po0_ep_read;
	wire [15:0] pi0_ep_dataout, po0_ep_datain;

	assign led = ~{4'b0,ep00wire[0],ep00wire[1],c3_calib_done,c3_pll_lock};
	
	assign c3_sys_clk     = 1'b0;
	assign mcb3_dram_cs_n = 1'b0;
	
	assign i2c_sda    = 1'bz;
	assign i2c_scl    = 1'bz;
	assign hi_muxsel  = 1'b0;
	
	//MIG Infrastructure Reset
	reg [3:0] rst_cnt;
	initial rst_cnt = 4'b0;
	always @(posedge ti_clk) begin
		if(rst_cnt < 4'b1000) begin
		  rst_cnt <= rst_cnt + 1;
			c3_sys_rst_n <= 1'b1;
		end
		else begin
			c3_sys_rst_n <= 1'b0;
		end
	end

memc3_infrastructure #
	(
   .C_MEMCLK_PERIOD                  (C3_MEMCLK_PERIOD),
   .C_RST_ACT_LOW                    (C3_RST_ACT_LOW),
   .C_INPUT_CLK_TYPE                 (C3_INPUT_CLK_TYPE),
   .C_CLKOUT0_DIVIDE                 (C3_CLKOUT0_DIVIDE),
   .C_CLKOUT1_DIVIDE                 (C3_CLKOUT1_DIVIDE),
   .C_CLKOUT2_DIVIDE                 (C3_CLKOUT2_DIVIDE),
   .C_CLKOUT3_DIVIDE                 (C3_CLKOUT3_DIVIDE),
   .C_CLKFBOUT_MULT                  (C3_CLKFBOUT_MULT),
   .C_DIVCLK_DIVIDE                  (C3_DIVCLK_DIVIDE)
	)
memc3_infrastructure_inst
	(
   .sys_clk_p                      (clk1),
   .sys_clk                        (c3_sys_clk),
   .sys_rst_n                      (c3_sys_rst_n),
   .clk0                           (c3_clk0),
   .rst0                           (c3_rst0),
   .async_rst                      (c3_async_rst),
   .sysclk_2x                      (c3_sysclk_2x),
   .sysclk_2x_180                  (c3_sysclk_2x_180),
   .pll_ce_0                       (c3_pll_ce_0),
   .pll_ce_90                      (c3_pll_ce_90),
   .pll_lock                       (c3_pll_lock),
   .mcb_drp_clk                    (c3_mcb_drp_clk)
	);

// wrapper instantiation
 memc3_wrapper #
	(
   .C_MEMCLK_PERIOD                  (C3_MEMCLK_PERIOD),
   .C_CALIB_SOFT_IP                  (C3_CALIB_SOFT_IP),
   .C_SIMULATION                     (C3_SIMULATION),
   .C_ARB_NUM_TIME_SLOTS             (C3_ARB_NUM_TIME_SLOTS),
   .C_ARB_TIME_SLOT_0                (C3_ARB_TIME_SLOT_0),
   .C_ARB_TIME_SLOT_1                (C3_ARB_TIME_SLOT_1),
   .C_ARB_TIME_SLOT_2                (C3_ARB_TIME_SLOT_2),
   .C_ARB_TIME_SLOT_3                (C3_ARB_TIME_SLOT_3),
   .C_ARB_TIME_SLOT_4                (C3_ARB_TIME_SLOT_4),
   .C_ARB_TIME_SLOT_5                (C3_ARB_TIME_SLOT_5),
   .C_ARB_TIME_SLOT_6                (C3_ARB_TIME_SLOT_6),
   .C_ARB_TIME_SLOT_7                (C3_ARB_TIME_SLOT_7),
   .C_ARB_TIME_SLOT_8                (C3_ARB_TIME_SLOT_8),
   .C_ARB_TIME_SLOT_9                (C3_ARB_TIME_SLOT_9),
   .C_ARB_TIME_SLOT_10               (C3_ARB_TIME_SLOT_10),
   .C_ARB_TIME_SLOT_11               (C3_ARB_TIME_SLOT_11),
   .C_MEM_TRAS                       (C3_MEM_TRAS),
   .C_MEM_TRCD                       (C3_MEM_TRCD),
   .C_MEM_TREFI                      (C3_MEM_TREFI),
   .C_MEM_TRFC                       (C3_MEM_TRFC),
   .C_MEM_TRP                        (C3_MEM_TRP),
   .C_MEM_TWR                        (C3_MEM_TWR),
   .C_MEM_TRTP                       (C3_MEM_TRTP),
   .C_MEM_TWTR                       (C3_MEM_TWTR),
   .C_MEM_ADDR_ORDER                 (C3_MEM_ADDR_ORDER),
   .C_NUM_DQ_PINS                    (C3_NUM_DQ_PINS),
   .C_MEM_TYPE                       (C3_MEM_TYPE),
   .C_MEM_DENSITY                    (C3_MEM_DENSITY),
   .C_MEM_BURST_LEN                  (C3_MEM_BURST_LEN),
   .C_MEM_CAS_LATENCY                (C3_MEM_CAS_LATENCY),
   .C_MEM_ADDR_WIDTH                 (C3_MEM_ADDR_WIDTH),
   .C_MEM_BANKADDR_WIDTH             (C3_MEM_BANKADDR_WIDTH),
   .C_MEM_NUM_COL_BITS               (C3_MEM_NUM_COL_BITS),
   .C_MEM_DDR1_2_ODS                 (C3_MEM_DDR1_2_ODS),
   .C_MEM_DDR2_RTT                   (C3_MEM_DDR2_RTT),
   .C_MEM_DDR2_DIFF_DQS_EN           (C3_MEM_DDR2_DIFF_DQS_EN),
   .C_MEM_DDR2_3_PA_SR               (C3_MEM_DDR2_3_PA_SR),
   .C_MEM_DDR2_3_HIGH_TEMP_SR        (C3_MEM_DDR2_3_HIGH_TEMP_SR),
   .C_MEM_DDR3_CAS_LATENCY           (C3_MEM_DDR3_CAS_LATENCY),
   .C_MEM_DDR3_ODS                   (C3_MEM_DDR3_ODS),
   .C_MEM_DDR3_RTT                   (C3_MEM_DDR3_RTT),
   .C_MEM_DDR3_CAS_WR_LATENCY        (C3_MEM_DDR3_CAS_WR_LATENCY),
   .C_MEM_DDR3_AUTO_SR               (C3_MEM_DDR3_AUTO_SR),
   .C_MEM_DDR3_DYN_WRT_ODT           (C3_MEM_DDR3_DYN_WRT_ODT),
   .C_MEM_MOBILE_PA_SR               (C3_MEM_MOBILE_PA_SR),
   .C_MEM_MDDR_ODS                   (C3_MEM_MDDR_ODS),
   .C_MC_CALIB_BYPASS                (C3_MC_CALIB_BYPASS),
   .C_MC_CALIBRATION_MODE            (C3_MC_CALIBRATION_MODE),
   .C_MC_CALIBRATION_DELAY           (C3_MC_CALIBRATION_DELAY),
   .C_SKIP_IN_TERM_CAL               (C3_SKIP_IN_TERM_CAL),
   .C_SKIP_DYNAMIC_CAL               (C3_SKIP_DYNAMIC_CAL),
   .C_LDQSP_TAP_DELAY_VAL            (C3_LDQSP_TAP_DELAY_VAL),
   .C_LDQSN_TAP_DELAY_VAL            (C3_LDQSN_TAP_DELAY_VAL),
   .C_UDQSP_TAP_DELAY_VAL            (C3_UDQSP_TAP_DELAY_VAL),
   .C_UDQSN_TAP_DELAY_VAL            (C3_UDQSN_TAP_DELAY_VAL),
   .C_DQ0_TAP_DELAY_VAL              (C3_DQ0_TAP_DELAY_VAL),
   .C_DQ1_TAP_DELAY_VAL              (C3_DQ1_TAP_DELAY_VAL),
   .C_DQ2_TAP_DELAY_VAL              (C3_DQ2_TAP_DELAY_VAL),
   .C_DQ3_TAP_DELAY_VAL              (C3_DQ3_TAP_DELAY_VAL),
   .C_DQ4_TAP_DELAY_VAL              (C3_DQ4_TAP_DELAY_VAL),
   .C_DQ5_TAP_DELAY_VAL              (C3_DQ5_TAP_DELAY_VAL),
   .C_DQ6_TAP_DELAY_VAL              (C3_DQ6_TAP_DELAY_VAL),
   .C_DQ7_TAP_DELAY_VAL              (C3_DQ7_TAP_DELAY_VAL),
   .C_DQ8_TAP_DELAY_VAL              (C3_DQ8_TAP_DELAY_VAL),
   .C_DQ9_TAP_DELAY_VAL              (C3_DQ9_TAP_DELAY_VAL),
   .C_DQ10_TAP_DELAY_VAL             (C3_DQ10_TAP_DELAY_VAL),
   .C_DQ11_TAP_DELAY_VAL             (C3_DQ11_TAP_DELAY_VAL),
   .C_DQ12_TAP_DELAY_VAL             (C3_DQ12_TAP_DELAY_VAL),
   .C_DQ13_TAP_DELAY_VAL             (C3_DQ13_TAP_DELAY_VAL),
   .C_DQ14_TAP_DELAY_VAL             (C3_DQ14_TAP_DELAY_VAL),
   .C_DQ15_TAP_DELAY_VAL             (C3_DQ15_TAP_DELAY_VAL)
	)
memc3_wrapper_inst
	(
   .mcb3_dram_dq                        (mcb3_dram_dq),
   .mcb3_dram_a                         (mcb3_dram_a),
   .mcb3_dram_ba                        (mcb3_dram_ba),
   .mcb3_dram_ras_n                     (mcb3_dram_ras_n),
   .mcb3_dram_cas_n                     (mcb3_dram_cas_n),
   .mcb3_dram_we_n                      (mcb3_dram_we_n),
   .mcb3_dram_odt                       (mcb3_dram_odt),
   .mcb3_dram_cke                       (mcb3_dram_cke),
   .mcb3_dram_dm                        (mcb3_dram_dm),
   .mcb3_dram_udqs                      (mcb3_dram_udqs),
   .mcb3_dram_udqs_n                    (mcb3_dram_udqs_n),
   .mcb3_rzq                            (mcb3_rzq),
   .mcb3_zio                            (mcb3_zio),
   .mcb3_dram_udm                       (mcb3_dram_udm),
   .calib_done                          (c3_calib_done),
   .async_rst                           (c3_async_rst),
   .sysclk_2x                           (c3_sysclk_2x),
   .sysclk_2x_180                       (c3_sysclk_2x_180),
   .pll_ce_0                            (c3_pll_ce_0),
   .pll_ce_90                           (c3_pll_ce_90),
   .pll_lock                            (c3_pll_lock),
   .mcb_drp_clk                         (c3_mcb_drp_clk),
   .mcb3_dram_dqs                       (mcb3_dram_dqs),
   .mcb3_dram_dqs_n                     (mcb3_dram_dqs_n),
   .mcb3_dram_ck                        (mcb3_dram_ck),
   .mcb3_dram_ck_n                      (mcb3_dram_ck_n),
   .p0_cmd_clk                          (c3_clk0),
   .p0_cmd_en                           (c3_p0_cmd_en),
   .p0_cmd_instr                        (c3_p0_cmd_instr),
   .p0_cmd_bl                           (c3_p0_cmd_bl),
   .p0_cmd_byte_addr                    (c3_p0_cmd_byte_addr),
   .p0_cmd_empty                        (c3_p0_cmd_empty),
   .p0_cmd_full                         (c3_p0_cmd_full),
   .p0_wr_clk                           (c3_clk0),
   .p0_wr_en                            (c3_p0_wr_en),
   .p0_wr_mask                          (c3_p0_wr_mask),
   .p0_wr_data                          (c3_p0_wr_data),
   .p0_wr_full                          (c3_p0_wr_full),
   .p0_wr_empty                         (c3_p0_wr_empty),
   .p0_wr_count                         (c3_p0_wr_count),
   .p0_wr_underrun                      (c3_p0_wr_underrun),
   .p0_wr_error                         (c3_p0_wr_error),
   .p0_rd_clk                           (c3_clk0),
   .p0_rd_en                            (c3_p0_rd_en),
   .p0_rd_data                          (c3_p0_rd_data),
   .p0_rd_full                          (c3_p0_rd_full),
   .p0_rd_empty                         (c3_p0_rd_empty),
   .p0_rd_count                         (c3_p0_rd_count),
   .p0_rd_overflow                      (c3_p0_rd_overflow),
   .p0_rd_error                         (c3_p0_rd_error),
   .selfrefresh_enter                   (selfrefresh_enter),
   .selfrefresh_mode                    (selfrefresh_mode)
	);

 ddr2_test ddr2_tb
	(
	.clk(c3_clk0),
	.reset(ep00wire[2] | c3_rst0), 
	.reads_en(ep00wire[0]),
	.writes_en(ep00wire[1]),
	.calib_done(c3_calib_done), 

	.ib_re(pipe_in_read),
	.ib_data(pipe_in_data),
	.ib_count(pipe_in_count),
	.ib_valid(pipe_in_valid),
	.ib_empty(pipe_in_empty),
	
	.ob_we(pipe_out_write),
	.ob_data(pipe_out_data),
	.ob_count(pipe_out_count),
	
	.p0_rd_en_o(c3_p0_rd_en),  
	.p0_rd_empty(c3_p0_rd_empty), 
	.p0_rd_data(c3_p0_rd_data), 
	
	.p0_cmd_en(c3_p0_cmd_en),
	.p0_cmd_full(c3_p0_cmd_full), 
	.p0_cmd_instr(c3_p0_cmd_instr),
	.p0_cmd_byte_addr(c3_p0_cmd_byte_addr), 
	.p0_cmd_bl_o(c3_p0_cmd_bl), 
	
	.p0_wr_en(c3_p0_wr_en),
	.p0_wr_full(c3_p0_wr_full), 
	.p0_wr_data(c3_p0_wr_data), 
	.p0_wr_mask(c3_p0_wr_mask) 
	);
	

// Instantiate the okHost and connect endpoints.
okHost host (
	.hi_in(hi_in),
	.hi_out(hi_out),
	.hi_inout(hi_inout),
	.hi_aa(hi_aa),
	.ti_clk(ti_clk),
	.ok1(ok1), 
	.ok2(ok2)
	);

wire [17*2-1:0]  ok2x;
wire [15:0]  ep00wire;
okWireOR # (.N(2)) wireOR (ok2, ok2x);
okWireIn     wi00 (.ok1(ok1),                           .ep_addr(8'h00), .ep_dataout(ep00wire));
okPipeIn     pi0  (.ok1(ok1), .ok2(ok2x[ 0*17 +: 17 ]), .ep_addr(8'h80), .ep_write(pi0_ep_write), .ep_dataout(pi0_ep_dataout));
okPipeOut    po0  (.ok1(ok1), .ok2(ok2x[ 1*17 +: 17 ]), .ep_addr(8'ha0), .ep_read(po0_ep_read),   .ep_datain(po0_ep_datain));

fifo_w16_2048_r64_512 okPipeIn_fifo (
	.rst(ep00wire[2]),
	.wr_clk(ti_clk),
	.rd_clk(c3_clk0),
	.din(pi0_ep_dataout), // Bus [15 : 0] 
	.wr_en(pi0_ep_write),
	.rd_en(pipe_in_read),
	.dout(pipe_in_data), // Bus [63 : 0] 
	.full(),
	.empty(pipe_in_empty),
	.valid(pipe_in_valid),
	.rd_data_count(pipe_in_count), // Bus [8 : 0] 
	.wr_data_count()); // Bus [10 : 0] 

fifo_w64_512_r16_2048 okPipeOut_fifo (
	.rst(ep00wire[2]),
	.wr_clk(c3_clk0),
	.rd_clk(ti_clk),
	.din(pipe_out_data), // Bus [63 : 0] 
	.wr_en(pipe_out_write),
	.rd_en(po0_ep_read),
	.dout(po0_ep_datain), // Bus [15 : 0] 
	.full(pipe_out_full),
	.empty(),
	.valid(),
	.rd_data_count(), // Bus [10 : 0] 
	.wr_data_count(pipe_out_count)); // Bus [8 : 0] 

endmodule