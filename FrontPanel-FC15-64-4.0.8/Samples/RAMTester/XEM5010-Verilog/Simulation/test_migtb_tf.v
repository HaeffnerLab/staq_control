//------------------------------------------------------------------------
// test_ssram_tf.v
//
//------------------------------------------------------------------------
// Copyright (c) 2009 Opal Kelly Incorporated
// $Id: test_tf.v 260 2007-03-07 22:55:47Z jake $
//------------------------------------------------------------------------

`default_nettype none
`timescale 1ns / 1ps

module test_ddr2_tf # (
	parameter C0_DDR2_BANK_WIDTH      = 2,       // # of memory bank addr bits.
	parameter C0_DDR2_CKE_WIDTH       = 1,       // # of memory clock enable outputs.
	parameter C0_DDR2_CLK_WIDTH       = 1,       // # of clock outputs.
	parameter C0_DDR2_COL_WIDTH       = 10,      // # of memory column bits.
	parameter C0_DDR2_CS_NUM          = 1,       // # of separate memory chip selects.
	parameter C0_DDR2_CS_WIDTH        = 1,       // # of total memory chip selects.
	parameter C0_DDR2_CS_BITS         = 0,       // set to log2(CS_NUM) (rounded up).
	parameter C0_DDR2_DM_WIDTH        = 2,       // # of data mask bits.
	parameter C0_DDR2_DQ_WIDTH        = 16,      // # of data width.
	parameter C0_DDR2_DQ_PER_DQS      = 8,       // # of DQ data bits per strobe.
	parameter C0_DDR2_DQS_WIDTH       = 2,       // # of DQS strobes.
	parameter C0_DDR2_DQ_BITS         = 4,       // set to log2(DQS_WIDTH*DQ_PER_DQS).
	parameter C0_DDR2_DQS_BITS        = 1,       // set to log2(DQS_WIDTH).
	parameter C0_DDR2_ODT_WIDTH       = 1,       // # of memory on-die term enables.
	parameter C0_DDR2_ROW_WIDTH       = 13,      // # of memory row and # of addr bits.
	parameter C0_DDR2_ADDITIVE_LAT    = 0,       // additive write latency.
	parameter C0_DDR2_BURST_LEN       = 4,       // burst length (in double words).
	parameter C0_DDR2_BURST_TYPE      = 0,       // burst type (=0 seq; =1 interleaved).
	parameter C0_DDR2_CAS_LAT         = 4,       // CAS latency.
	parameter C0_DDR2_ECC_ENABLE      = 0,       // enable ECC (=1 enable).
	parameter C0_DDR2_APPDATA_WIDTH   = 32,      // # of usr read/write data bus bits.
	parameter C0_DDR2_MULTI_BANK_EN   = 1,       // Keeps multiple banks open. (= 1 enable).
	parameter C0_DDR2_TWO_T_TIME_EN   = 0,       // 2t timing for unbuffered dimms.
	parameter C0_DDR2_ODT_TYPE        = 1,       // ODT (=0(none),=1(75),=2(150),=3(50)).
	parameter C0_DDR2_REDUCE_DRV      = 1,       // reduced strength mem I/O (=1 yes).
	parameter C0_DDR2_REG_ENABLE      = 0,       // registered addr/ctrl (=1 yes).
	parameter C0_DDR2_TREFI_NS        = 7800,    // auto refresh interval (ns).
	parameter C0_DDR2_TRAS            = 40000,   // active->precharge delay.
	parameter C0_DDR2_TRCD            = 15000,   // active->read/write delay.
	parameter C0_DDR2_TRFC            = 105000,  // refresh->refresh, refresh->active delay.
	parameter C0_DDR2_TRP             = 15000,   // precharge->command delay.
	parameter C0_DDR2_TRTP            = 7500,    // read->precharge delay.
	parameter C0_DDR2_TWR             = 15000,   // used to determine write->precharge.
	parameter C0_DDR2_TWTR            = 7500,    // write->read delay.
	parameter HIGH_PERFORMANCE_MODE   = "TRUE",  // # TRUE=IODELAY performance mode is set to high.
	parameter C0_DDR2_SIM_ONLY        = 1,       // = 1 to skip SDRAM power up delay.
	parameter C0_DDR2_DEBUG_EN        = 0,
	parameter DDR2_CLK_PERIOD         = 3750,    // Core/Memory clock period (in ps).
	parameter C0_DDR2_DQS_IO_COL      = 4'b1010, // I/O column location of DQS groups
	                                             // (=0, left; =1 center, =2 right).
	parameter C0_DDR2_DQ_IO_MS        = 16'b10100101_10100101  // Master/Slave location of DQ I/O (=0 slave).
	)
	( )
  ;

reg         sys_clk;
reg         clk200;
reg         sys_rst;

wire        phy_init_done;
wire        error;
wire        error_cmp;

wire        ddr2_ck;
wire        ddr2_ck_n;
wire        ddr2_cke;
wire        ddr2_cs_n;
wire        ddr2_ras_n;
wire        ddr2_cas_n;
wire        ddr2_we_n;
wire        ddr2_odt;
wire [12:0] ddr2_a;
wire [1:0]  ddr2_ba;
wire [15:0] ddr2_dq;
wire [1:0]  ddr2_dm;
wire [1:0]  ddr2_dqs;
wire [1:0]  ddr2_dqs_n;

reg         rst0, rst90, rstdiv0;
reg         clk0, clk90, clkdiv0;

wire                                  app_wdf_afull;
wire                                  app_af_afull;
wire                                  rd_data_valid;
wire                                  app_wdf_wren;
wire                                  app_af_wren;
wire [30:0]                           app_af_addr;
wire [2:0]                            app_af_cmd;
wire [C0_DDR2_APPDATA_WIDTH-1:0]      rd_data_fifo_out;
wire [C0_DDR2_APPDATA_WIDTH-1:0]      app_wdf_data;
wire [(C0_DDR2_APPDATA_WIDTH/8)-1:0]  app_wdf_mask_data;

//------------------------------------------------------------------------
// This is the memory itself.
//------------------------------------------------------------------------
ddr2 #
	(
	.ADDR_BITS(13),
	.BA_BITS(2)
	)
	mem0 (
	.ck(ddr2_ck),
	.ck_n(ddr2_ck_n),
	.cke(ddr2_cke),
	.cs_n(ddr2_cs_n),
	.ras_n(ddr2_ras_n),
	.cas_n(ddr2_cas_n),
	.we_n(ddr2_we_n),
	.odt(ddr2_odt),
	.dm_rdqs(ddr2_dm),
	.rdqs_n(),    // These only exist in x8 configurations?
	.ba(ddr2_ba),
	.addr(ddr2_a),
	.dq(ddr2_dq),
	.dqs(ddr2_dqs),
	.dqs_n(ddr2_dqs_n)
	);


//------------------------------------------------------------------------
// This is the MIG memory controller.
//------------------------------------------------------------------------
 ddr2_top #
 (
   .BANK_WIDTH             (C0_DDR2_BANK_WIDTH),
   .CKE_WIDTH              (C0_DDR2_CKE_WIDTH),
   .CLK_WIDTH              (C0_DDR2_CLK_WIDTH),
   .COL_WIDTH              (C0_DDR2_COL_WIDTH),
   .CS_NUM                 (C0_DDR2_CS_NUM),
   .CS_WIDTH               (C0_DDR2_CS_WIDTH),
   .CS_BITS                (C0_DDR2_CS_BITS),
   .DM_WIDTH               (C0_DDR2_DM_WIDTH),
   .DQ_WIDTH               (C0_DDR2_DQ_WIDTH),
   .DQ_PER_DQS             (C0_DDR2_DQ_PER_DQS),
   .DQS_WIDTH              (C0_DDR2_DQS_WIDTH),
   .DQ_BITS                (C0_DDR2_DQ_BITS),
   .DQS_BITS               (C0_DDR2_DQS_BITS),
   .ODT_WIDTH              (C0_DDR2_ODT_WIDTH),
   .ROW_WIDTH              (C0_DDR2_ROW_WIDTH),
   .ADDITIVE_LAT           (C0_DDR2_ADDITIVE_LAT),
   .BURST_LEN              (C0_DDR2_BURST_LEN),
   .BURST_TYPE             (C0_DDR2_BURST_TYPE),
   .CAS_LAT                (C0_DDR2_CAS_LAT),
   .ECC_ENABLE             (C0_DDR2_ECC_ENABLE),
   .APPDATA_WIDTH          (C0_DDR2_APPDATA_WIDTH),
   .MULTI_BANK_EN          (C0_DDR2_MULTI_BANK_EN),
   .TWO_T_TIME_EN          (C0_DDR2_TWO_T_TIME_EN),
   .ODT_TYPE               (C0_DDR2_ODT_TYPE),
   .REDUCE_DRV             (C0_DDR2_REDUCE_DRV),
   .REG_ENABLE             (C0_DDR2_REG_ENABLE),
   .TREFI_NS               (C0_DDR2_TREFI_NS),
   .TRAS                   (C0_DDR2_TRAS),
   .TRCD                   (C0_DDR2_TRCD),
   .TRFC                   (C0_DDR2_TRFC),
   .TRP                    (C0_DDR2_TRP),
   .TRTP                   (C0_DDR2_TRTP),
   .TWR                    (C0_DDR2_TWR),
   .TWTR                   (C0_DDR2_TWTR),
   .HIGH_PERFORMANCE_MODE  (HIGH_PERFORMANCE_MODE),
   .SIM_ONLY               (C0_DDR2_SIM_ONLY),
   .DEBUG_EN               (C0_DDR2_DEBUG_EN),
   .CLK_PERIOD             (DDR2_CLK_PERIOD),
   .DQS_IO_COL             (C0_DDR2_DQS_IO_COL),
   .DQ_IO_MS               (C0_DDR2_DQ_IO_MS),
   .USE_DM_PORT            (1)
   )
u_ddr2_top_0
(
   .ddr2_dq                (ddr2_dq),
   .ddr2_a                 (ddr2_a),
   .ddr2_ba                (ddr2_ba),
   .ddr2_ras_n             (ddr2_ras_n),
   .ddr2_cas_n             (ddr2_cas_n),
   .ddr2_we_n              (ddr2_we_n),
   .ddr2_cs_n              (ddr2_cs_n),
   .ddr2_odt               (ddr2_odt),
   .ddr2_cke               (ddr2_cke),
   .ddr2_dm                (ddr2_dm),
   .phy_init_done          (phy_init_done),
   .rst0                   (rst0),
   .rst90                  (rst90),
   .rstdiv0                (rstdiv0),
   .clk0                   (clk0),
   .clk90                  (clk90),
   .clkdiv0                (clkdiv0),
   .app_wdf_afull          (app_wdf_afull),
   .app_af_afull           (app_af_afull),
   .rd_data_valid          (rd_data_valid),
   .app_wdf_wren           (app_wdf_wren),
   .app_af_wren            (app_af_wren),
   .app_af_addr            (app_af_addr),
   .app_af_cmd             (app_af_cmd),
   .rd_data_fifo_out       (rd_data_fifo_out),
   .app_wdf_data           (app_wdf_data),
   .app_wdf_mask_data      (app_wdf_mask_data),
   .ddr2_dqs               (ddr2_dqs),
   .ddr2_dqs_n             (ddr2_dqs_n),
   .ddr2_ck                (ddr2_ck),
   .rd_ecc_error           (),
   .ddr2_ck_n              (ddr2_ck_n)
   );


//------------------------------------------------------------------------
// This is the test bench (from MIG).
//------------------------------------------------------------------------
 ddr2_tb_top #
 (
   .BANK_WIDTH             (C0_DDR2_BANK_WIDTH),
   .COL_WIDTH              (C0_DDR2_COL_WIDTH),
   .DM_WIDTH               (C0_DDR2_DM_WIDTH),
   .DQ_WIDTH               (C0_DDR2_DQ_WIDTH),
   .ROW_WIDTH              (C0_DDR2_ROW_WIDTH),
   .BURST_LEN              (C0_DDR2_BURST_LEN),
   .ECC_ENABLE             (C0_DDR2_ECC_ENABLE),
   .APPDATA_WIDTH          (C0_DDR2_APPDATA_WIDTH)
   )
u_ddr2_tb_top_0
(
   .phy_init_done          (phy_init_done),
   .error                  (error),
   .error_cmp              (error_cmp),
   .rst0                   (rst0),
   .clk0                   (clk0),
   .app_wdf_afull          (app_wdf_afull),
   .app_af_afull           (app_af_afull),
   .rd_data_valid          (rd_data_valid),
   .app_wdf_wren           (app_wdf_wren),
   .app_af_wren            (app_af_wren),
   .app_af_addr            (app_af_addr),
   .app_af_cmd             (app_af_cmd),
   .rd_data_fifo_out       (rd_data_fifo_out),
   .app_wdf_data           (app_wdf_data),
   .app_wdf_mask_data      (app_wdf_mask_data)
   );


parameter tCLK = 5.0;
initial sys_clk = 0;
initial clk200 = 0;
initial clk0 = 0;
initial clk90 = 0;
initial clkdiv0 = 0;
always #(tCLK/2.0) sys_clk = ~sys_clk;
always #(tCLK/2.0) clk0 = ~clk0;
always @(clk0) clk90 = #(tCLK/4) clk0;
always #(2.5) clk200 = ~clk200;
always @(posedge clk0) clkdiv0 = ~clkdiv0;

always @(clk0)     rst0 <= sys_rst;
always @(clk90)    rst90 <= sys_rst;
always @(clkdiv0)  rstdiv0 <= sys_rst;


// User configurable block of called FrontPanel operations.
initial begin
	$display(" ");
	$display("//// Beginning Tests ////");
	$display(" ");

	sys_rst = 1'b1;
	#200;
	sys_rst=1'b0;

//	$stop;
end

endmodule
