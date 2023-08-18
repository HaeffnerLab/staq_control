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

module tf;
// ========================================================================== //
// Parameters                                                                 //
// ========================================================================== //
	parameter DEBUG_EN                = 0;
	localparam DBG_WR_STS_WIDTH       = 32;
	localparam DBG_RD_STS_WIDTH       = 32;
	parameter C1_MEMCLK_PERIOD     = 3200;
	parameter C1_RST_ACT_LOW        = 0;
	parameter C1_INPUT_CLK_TYPE     = "SINGLE_ENDED";
	parameter C1_NUM_DQ_PINS        = 16;
	parameter C1_MEM_ADDR_WIDTH     = 13;
	parameter C1_MEM_BANKADDR_WIDTH = 3;
	parameter C1_MEM_ADDR_ORDER     = "ROW_BANK_COLUMN"; 
	parameter C1_P0_MASK_SIZE       = 4;
	parameter C1_P0_DATA_PORT_SIZE  = 32;  
	parameter C1_P1_MASK_SIZE       = 4;
	parameter C1_P1_DATA_PORT_SIZE  = 32;
	parameter C1_CALIB_SOFT_IP      = "FALSE"; // OK Shut of Calibration for Simulation
	parameter C1_SIMULATION      = "TRUE";
	parameter C1_HW_TESTING      = "FALSE";

// ========================================================================== //
// Signal Declarations                                                        //
// ========================================================================== //

	//FP Host
	reg  [7:0]  hi_in;
	wire [1:0]  hi_out;
	wire [15:0] hi_inout;
	wire        hi_aa;
	
	wire [3:0]  led;
	
	//Testbench
	reg         sys_clk; 
	
	wire [C1_NUM_DQ_PINS-1:0]           ddr2_dq;
	wire [C1_MEM_ADDR_WIDTH-1:0]        ddr2_a;
	wire [C1_MEM_BANKADDR_WIDTH-1:0]    ddr2_ba;
	wire                                ddr2_ras_n;
	wire                                ddr2_cas_n;
	wire                                ddr2_we_n;
	wire                                ddr2_odt;
	wire                                ddr2_cke;
	wire                                ddr2_dm;
	wire                                ddr2_udqs;
	wire                                ddr2_udqs_n;
	wire                                ddr2_rzq;
	wire                                ddr2_zio;
	wire                                ddr2_udm;
	wire                                ddr2_dqs;
	wire                                ddr2_dqs_n;
	wire                                ddr2_ck;
	wire                                ddr2_ck_n;
	wire                                ddr2_cs_n;
	
	// The PULLDOWN component is connected to the ZIO signal primarily to avoid the
	// unknown state in simulation. In real hardware, ZIO should be a no connect(NC) pin.
	PULLDOWN zio_pulldown3 (.O(ddr2_zio));
	PULLDOWN rzq_pulldown3 (.O(ddr2_rzq));


//------------------------------------------------------------------------
// DDR2 Memory Model
//------------------------------------------------------------------------
	generate
		if(C1_NUM_DQ_PINS == 16) begin : MEM_INST1
			ddr2_model_c1 u_mem_c1(
				.ck         (ddr2_ck),
				.ck_n       (ddr2_ck_n),
				.cke        (ddr2_cke),
				.cs_n       (1'b0),
				.ras_n      (ddr2_ras_n),
				.cas_n      (ddr2_cas_n),
				.we_n       (ddr2_we_n),
				.dm_rdqs    ({ddr2_udm,ddr2_dm}),
				.ba         (ddr2_ba),
				.addr       (ddr2_a),
				.dq         (ddr2_dq),
				.dqs        ({ddr2_udqs,ddr2_dqs}),
				.dqs_n      ({ddr2_udqs_n,ddr2_dqs_n}),
				.rdqs_n     (),
				.odt        (ddr2_odt)
			);
		end else begin
			ddr2_model_c1 u_mem_c1(
				.ck         (ddr2_ck),
				.ck_n       (ddr2_ck_n),
				.cke        (ddr2_cke),
				.cs_n       (1'b0),
				.ras_n      (ddr2_ras_n),
				.cas_n      (ddr2_cas_n),
				.we_n       (ddr2_we_n),
				.dm_rdqs    (ddr2_dm),
				.ba         (ddr2_ba),
				.addr       (ddr2_a),
				.dq         (ddr2_dq),
				.dqs        (ddr2_dqs),
				.dqs_n      (ddr2_dqs_n),
				.rdqs_n     (),
				.odt        (ddr2_odt)
			);
		end
	endgenerate


//------------------------------------------------------------------------
// RAMTest DUT
//------------------------------------------------------------------------
ramtest #(
.C1_P0_MASK_SIZE       (C1_P0_MASK_SIZE      ),
.C1_P0_DATA_PORT_SIZE  (C1_P0_DATA_PORT_SIZE ),
.C1_P1_MASK_SIZE       (C1_P1_MASK_SIZE      ),
.C1_P1_DATA_PORT_SIZE  (C1_P1_DATA_PORT_SIZE ),
.C1_MEMCLK_PERIOD      (C1_MEMCLK_PERIOD),
.C1_RST_ACT_LOW        (C1_RST_ACT_LOW),
.C1_INPUT_CLK_TYPE     (C1_INPUT_CLK_TYPE),

 
.DEBUG_EN              (DEBUG_EN),

.C1_MEM_ADDR_ORDER     (C1_MEM_ADDR_ORDER    ),
.C1_NUM_DQ_PINS        (C1_NUM_DQ_PINS       ),
.C1_MEM_ADDR_WIDTH     (C1_MEM_ADDR_WIDTH    ),
.C1_MEM_BANKADDR_WIDTH (C1_MEM_BANKADDR_WIDTH),

.C1_HW_TESTING         (C1_HW_TESTING),
.C1_SIMULATION         (C1_SIMULATION),
.C1_CALIB_SOFT_IP      (C1_CALIB_SOFT_IP )
	)
	dut(
		.hi_in                  (hi_in),
		.hi_out                 (hi_out),
		.hi_inout               (hi_inout),
		.hi_aa                  (hi_aa),
	
		.led                    (led),
		
		.sys_clk                   (sys_clk),
		
		.ddr2_dq(ddr2_dq),
		.ddr2_a(ddr2_a),
		.ddr2_ba(ddr2_ba),
		.ddr2_ras_n(ddr2_ras_n),
		.ddr2_cas_n(ddr2_cas_n),
		.ddr2_we_n(ddr2_we_n),
		.ddr2_odt(ddr2_odt),
		.ddr2_cke(ddr2_cke),
		.ddr2_dm(ddr2_dm),
		.ddr2_udqs(ddr2_udqs),
		.ddr2_udqs_n(ddr2_udqs_n),
		.ddr2_rzq(ddr2_rzq),
		.ddr2_zio(ddr2_zio),
		.ddr2_udm(ddr2_udm),
	   
		.ddr2_dqs(ddr2_dqs),
		.ddr2_dqs_n(ddr2_dqs_n),
		.ddr2_ck(ddr2_ck),
		.ddr2_ck_n(ddr2_ck_n),
		.ddr2_cs_n(ddr2_cs_n)
	);


	//------------------------------------------------------------------------
	// Begin okHost simulation user configurable global data
	//------------------------------------------------------------------------
	parameter BlockDelayStates = 5;   // REQUIRED: # of clocks between blocks of pipe data
	parameter ReadyCheckDelay = 5;    // REQUIRED: # of clocks before block transfer before
	                                  //           host interface checks for ready (0-255)
	parameter PostReadyDelay = 5;     // REQUIRED: # of clocks after ready is asserted and
	                                  //           check that the block transfer begins (0-255)
	parameter pipeInSize = 	1024;     // REQUIRED: byte (must be even) length of default
	                                  //           PipeIn; Integer 0-2^32
	parameter pipeOutSize = 1024;     // REQUIRED: byte (must be even) length of default
	                                  //           PipeOut; Integer 0-2^32
	integer k, e;
	reg	[7:0]	pipeIn  [0:(pipeInSize-1)];
	reg	[7:0]	pipeOut [0:(pipeOutSize-1)];
	reg	[7:0]	pipetmp [0:(pipeInSize-1)];   // Data Check Array
	
	
	// Clock Generation
	parameter tCLK = 20.833; // FX2 CLKOUT @ 48Mhz
	initial sys_clk = 0;
	always #(tCLK/2.0) sys_clk = ~sys_clk;
	
	
	// FrontPanel API Task Calls.
	integer i;
	initial begin
		
		FrontPanelReset;
		$display("//// Beginning Tests at:                           %dns   /////", $time);
		
		// Assert then deassert RESET_FIFO
		SetWireInValue(8'h00, 16'h0004, 16'hffff);
		UpdateWireIns;
		SetWireInValue(8'h00, 16'h0000, 16'hffff);
		UpdateWireIns;
	
		wait (tf.dut.calib_done == 1'b1);
	
		$display("//// DDR2 PHY initialization complete at:          %dns   /////", $time);

		// Initialize PipeIn with random data
		for (k=0; k<pipeInSize; k=k+1) pipeIn[k] = $random;
		// Store the pipeIn data into a tmp array
		for (k=0; k<pipeInSize; k=k+1) pipetmp[k] = pipeIn[k];
		// Clear PipeOut
		for (k=0; k<pipeOutSize; k=k+1) pipeOut[k] = 8'h00;
		
		// Write a block of data
		SetWireInValue(8'h00, 16'h0002, 16'hffff);
		UpdateWireIns;
		WriteToPipeIn(8'h80, pipeInSize);
		$display("//// Write to DDR2 complete at:                    %dns   /////", $time);
	
		// Switch to read mode
		SetWireInValue(8'h00, 16'h0001, 16'hffff);
		UpdateWireIns;
	
		#10000;
	
		// Read the block out
		ReadFromPipeOut(8'ha0, pipeInSize);
	$display("//// Read From DDR2 complete at:                   %dns   /////", $time);
	
		// Test read-back data.
		e=0;
		for (k=0; k<pipeInSize; k=k+1) begin 
			if (pipeOut[k] != pipetmp[k]) begin
				e=e+1;	// Keep track of the number of errors
				$display(" ");
				$display("Error! Data mismatch at byte %d:  Expected: 0x%08x Read: 0x%08x", k, pipetmp[k], pipeOut[k]);
			end
		end
		
		if (e == 0) begin
			$display(" ");
			$display("Success! All data passes readback.");
		end

	$display("Simulation done at: %dns", $time);
	$stop;

	end
	
	// Do not remove!
	`include "./oksim/okHostCalls.v"

endmodule