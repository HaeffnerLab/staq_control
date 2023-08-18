//------------------------------------------------------------------------
// test_okhi_tf.v
//
// This test fixture exercises the Opal Kelly RAMTester application of 
// the MIG DDR2 core.  Unlike the _oktb version, this includes the full
// FrontPanel simulation component.
//
//------------------------------------------------------------------------
// Copyright (c) 2009 Opal Kelly Incorporated
// $Rev$ $Date$
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

reg  [7:0]  hi_in;
wire [1:0]  hi_out;
wire [15:0] hi_inout;
wire        hi_muxsel;
reg         sys_clk;
wire        sys_clk_p;
wire        sys_clk_n;
wire [3:0]  led;

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


//------------------------------------------------------------------------
// This is the memory itself.
//------------------------------------------------------------------------
ddr2 #
	(
	.ADDR_BITS(13),
	.BA_BITS(2),
	.DEBUG(0)
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
// This is the RAMTester
//------------------------------------------------------------------------
ramtest #
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
u_ramtest
	(
	.hi_in                  (hi_in),
	.hi_out                 (hi_out),
	.hi_inout               (hi_inout),
	.hi_muxsel              (hi_muxsel),
	.sys_clk_p              (sys_clk_p),
	.sys_clk_n              (sys_clk_n),
	.led                    (led),

	.ddr2a_dq               (ddr2_dq),
	.ddr2a_dqs              (ddr2_dqs),
	.ddr2a_dqs_n            (ddr2_dqs_n),
	.ddr2a_a                (ddr2_a),
	.ddr2a_ba               (ddr2_ba),
	.ddr2a_ras_n            (ddr2_ras_n),
	.ddr2a_cas_n            (ddr2_cas_n),
	.ddr2a_we_n             (ddr2_we_n),
	.ddr2a_cs_n             (ddr2_cs_n),
	.ddr2a_odt              (ddr2_odt),
	.ddr2a_cke              (ddr2_cke),
	.ddr2a_ck               (ddr2_ck),
	.ddr2a_ck_n             (ddr2_ck_n),
	.ddr2a_dm               (ddr2_dm)
	);


//------------------------------------------------------------------------
// Begin okHost simulation user configurable global data
//------------------------------------------------------------------------
parameter BlockDelayStates = 5;   // REQUIRED: # of clocks between blocks of pipe data
parameter ReadyCheckDelay = 5;    // REQUIRED: # of clocks before block transfer before
                                  //           host interface checks for ready (0-255)
parameter PostReadyDelay = 5;     // REQUIRED: # of clocks after ready is asserted and
                                  //           check that the block transfer begins (0-255)
parameter pipeInSize = 16*1024;   // REQUIRED: byte (must be even) length of default
                                  //           PipeIn; Integer 0-2^32
parameter pipeOutSize = 16*1024;  // REQUIRED: byte (must be even) length of default
                                  //           PipeOut; Integer 0-2^32
integer k, e;
reg	[7:0]	pipeIn  [0:(pipeInSize-1)];
reg	[7:0]	pipeOut [0:(pipeOutSize-1)];


parameter N1data = 16;
parameter N2data = 256;
reg [15:0] Mem[0:N1data+N2data-1];


parameter tCLK = 10.0;
initial sys_clk = 0;
always #(tCLK/2.0) sys_clk = ~sys_clk;

assign sys_clk_p = sys_clk;
assign sys_clk_n = ~sys_clk;


// User configurable block of called FrontPanel operations.
integer i;
initial begin
	FrontPanelReset;
	$display("//// Beginning Tests ////");

	wait (led[0] == 1'b0);

	$display("//// DDR2 PHY initialization complete ////");

	// Assert then deassert RESET_FIFO
	SetWireInValue(8'h00, 16'h0004, 16'hffff);
	UpdateWireIns;
	SetWireInValue(8'h00, 16'h0000, 16'hffff);
	UpdateWireIns;

	// Write a block of data
	for (k=0; k<pipeInSize; k=k+1) pipeIn[k] = $random;
	for (k=0; k<pipeOutSize; k=k+1) pipeOut[k] = 8'h00;
	SetWireInValue(8'h00, 16'h0002, 16'hffff);
	UpdateWireIns;
	WriteToPipeIn(8'h80, 2048);


	// Switch to read mode
	SetWireInValue(8'h00, 16'h0001, 16'hffff);
	UpdateWireIns;

	#4000;

	// Read the block out
	ReadFromPipeOut(8'ha0, 2048);


//	$stop;
end


// Do not remove!
`include "okHostCalls.v"

endmodule
