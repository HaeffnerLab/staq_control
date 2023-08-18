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
	parameter DEBUG_EN              = 0;                                                                     
	parameter C3_MEMCLK_PERIOD     = 3200;                                                                   
	parameter C3_RST_ACT_LOW        = 0;                                                                     
	parameter C3_INPUT_CLK_TYPE     = "DIFFERENTIAL";                                                        
	parameter C3_NUM_DQ_PINS        = 16;                                                                    
	parameter C3_MEM_ADDR_WIDTH     = 13;                                                                    
	parameter C3_MEM_BANKADDR_WIDTH = 3;                                                                     
	parameter C3_MEM_ADDR_ORDER     = "ROW_BANK_COLUMN";                                                     
	parameter C3_P0_MASK_SIZE       = 4;                                                                     
	parameter C3_P0_DATA_PORT_SIZE  = 32;                                                                    
	parameter C3_P1_MASK_SIZE       = 4;                                                                     
	parameter C3_P1_DATA_PORT_SIZE  = 32;                                                                    
	parameter C3_MEM_BURST_LEN	  = 4;                                                                       
	parameter C3_MEM_NUM_COL_BITS   = 10;                                                                    
	parameter C3_CALIB_SOFT_IP      = "FALSE";  // kz shut of calibration                                    
	parameter C3_SIMULATION      = "TRUE";                                                                   
	parameter C3_HW_TESTING      = "FALSE";                                                                  
	localparam C3_p0_BEGIN_ADDRESS                   = (C3_HW_TESTING == "TRUE") ? 32'h01000000:32'h00000100;
	localparam C3_p0_DATA_MODE                       = 4'b0010;                                              
	localparam C3_p0_END_ADDRESS                     = (C3_HW_TESTING == "TRUE") ? 32'h02ffffff:32'h000002ff;     
	localparam C3_p0_PRBS_EADDR_MASK_POS             = (C3_HW_TESTING == "TRUE") ? 32'hfc000000:32'hfffffc00;
	localparam C3_p0_PRBS_SADDR_MASK_POS             = (C3_HW_TESTING == "TRUE") ? 32'h01000000:32'h00000100;
	
// ========================================================================== //
// Signal Declarations                                                        //
// ========================================================================== //

	// Frontpanel Host Interface
	reg  [7:0]  hi_in;
	wire [1:0]  hi_out;
	wire [15:0] hi_inout;
	wire        hi_aa;
	
	wire        i2c_sda;
	wire        i2c_scl;
	wire        hi_muxsel;
	
	wire [7:0]  led;
	
	//Testbench
	reg         clk1; // CY22393 CLKA @ 100MHz
	
	// DDR2 
	wire [C3_NUM_DQ_PINS-1:0]           mcb3_dram_dq;
	wire [C3_MEM_ADDR_WIDTH-1:0]        mcb3_dram_a;
	wire [C3_MEM_BANKADDR_WIDTH-1:0]    mcb3_dram_ba;
	wire                                mcb3_dram_ras_n;
	wire                                mcb3_dram_cas_n;
	wire                                mcb3_dram_we_n;
	wire                                mcb3_dram_odt;
	wire                                mcb3_dram_cke;
	wire                                mcb3_dram_dm;
	wire                                mcb3_dram_udqs;
	wire                                mcb3_dram_udqs_n;
	wire                                mcb3_rzq;
	wire                                mcb3_zio;
	wire                                mcb3_dram_udm;
	wire                                mcb3_dram_dqs;
	wire                                mcb3_dram_dqs_n;
	wire                                mcb3_dram_ck;
	wire                                mcb3_dram_ck_n;
	wire                                mcb3_dram_cs_n;
	
	// The PULLDOWN component is connected to the ZIO signal primarily to avoid the
	// unknown state in simulation. In real hardware, ZIO should be a no connect(NC) pin.
	PULLDOWN zio_pulldown3 (.O(mcb3_zio));
	PULLDOWN rzq_pulldown3 (.O(mcb3_rzq));
	

	//------------------------------------------------------------------------
	// DDR2 Memory model.
	//------------------------------------------------------------------------
	generate
	if(C3_NUM_DQ_PINS == 16) begin : MEM_INST3
		ddr2_model_c3 u_mem_c3(
		.ck         (mcb3_dram_ck),
		.ck_n       (mcb3_dram_ck_n),
		.cke        (mcb3_dram_cke),
		.cs_n       (1'b0),
		.ras_n      (mcb3_dram_ras_n),
		.cas_n      (mcb3_dram_cas_n),
		.we_n       (mcb3_dram_we_n),
		.dm_rdqs    ({mcb3_dram_udm,mcb3_dram_dm}),
		.ba         (mcb3_dram_ba),
		.addr       (mcb3_dram_a),
		.dq         (mcb3_dram_dq),
		.dqs        ({mcb3_dram_udqs,mcb3_dram_dqs}),
		.dqs_n      ({mcb3_dram_udqs_n,mcb3_dram_dqs_n}),
		.rdqs_n     (),
		.odt        (mcb3_dram_odt)
		);
	end else begin
		ddr2_model_c3 u_mem_c3(
		.ck         (mcb3_dram_ck),
		.ck_n       (mcb3_dram_ck_n),
		.cke        (mcb3_dram_cke),
		.cs_n       (1'b0),
		.ras_n      (mcb3_dram_ras_n),
		.cas_n      (mcb3_dram_cas_n),
		.we_n       (mcb3_dram_we_n),
		.dm_rdqs    (mcb3_dram_dm),
		.ba         (mcb3_dram_ba),
		.addr       (mcb3_dram_a),
		.dq         (mcb3_dram_dq),
		.dqs        (mcb3_dram_dqs),
		.dqs_n      (mcb3_dram_dqs_n),
		.rdqs_n     (),
		.odt        (mcb3_dram_odt)
		);
	end
	endgenerate


	//------------------------------------------------------------------------
	// RAMTest DUT
	//------------------------------------------------------------------------
	ramtest #(
	.DEBUG_EN(DEBUG_EN),                                                                   
	.C3_MEMCLK_PERIOD(C3_MEMCLK_PERIOD),                                                                
	.C3_RST_ACT_LOW(C3_RST_ACT_LOW),                                                                   
	.C3_INPUT_CLK_TYPE(C3_INPUT_CLK_TYPE),                                                   
	.C3_NUM_DQ_PINS(C3_NUM_DQ_PINS),                                                            
	.C3_MEM_ADDR_WIDTH(C3_MEM_ADDR_WIDTH),                         
	.C3_MEM_BANKADDR_WIDTH(C3_MEM_BANKADDR_WIDTH),                                    
	.C3_MEM_ADDR_ORDER(C3_MEM_ADDR_ORDER),                                             
	.C3_P0_MASK_SIZE(C3_P0_MASK_SIZE),                                                        
	.C3_P0_DATA_PORT_SIZE(C3_P0_DATA_PORT_SIZE),                                                      
	.C3_P1_MASK_SIZE(C3_P1_MASK_SIZE),                                                            
	.C3_P1_DATA_PORT_SIZE(C3_P1_DATA_PORT_SIZE),                                                                                         
	.C3_CALIB_SOFT_IP(C3_CALIB_SOFT_IP),                                
	.C3_SIMULATION(C3_SIMULATION),                                                
	.C3_HW_TESTING(C3_HW_TESTING),                                         
	)
	 dut
		(
		.hi_in                  (hi_in),
		.hi_out                 (hi_out),
		.hi_inout               (hi_inout),
		.i2c_sda                (i2c_sda),
		.i2c_scl                (i2c_scl),
		.hi_aa                  (hi_aa),
		.hi_muxsel              (hi_muxsel),
	
		.led                    (led),
	
		.clk1                   (clk1),
				
		.mcb3_dram_dq           (mcb3_dram_dq),
		.mcb3_dram_a            (mcb3_dram_a),
		.mcb3_dram_ba           (mcb3_dram_ba),
		.mcb3_dram_ras_n        (mcb3_dram_ras_n),
		.mcb3_dram_cas_n        (mcb3_dram_cas_n),
		.mcb3_dram_we_n         (mcb3_dram_we_n),
		.mcb3_dram_odt          (mcb3_dram_odt),
		.mcb3_dram_cke          (mcb3_dram_cke),
		.mcb3_dram_dm           (mcb3_dram_dm),
		.mcb3_dram_udqs         (mcb3_dram_udqs),
		.mcb3_dram_udqs_n       (mcb3_dram_udqs_n),
		.mcb3_rzq               (mcb3_rzq),
		.mcb3_zio               (mcb3_zio),
		.mcb3_dram_udm          (mcb3_dram_udm),
		.mcb3_dram_dqs          (mcb3_dram_dqs),
		.mcb3_dram_dqs_n        (mcb3_dram_dqs_n),
		.mcb3_dram_ck           (mcb3_dram_ck),
		.mcb3_dram_ck_n         (mcb3_dram_ck_n),
		.mcb3_dram_cs_n         (mcb3_dram_cs_n)
		);


	//------------------------------------------------------------------------
	// Begin okHost simulation user configurable global data
	//------------------------------------------------------------------------
	parameter BlockDelayStates = 5;   // REQUIRED: # of clocks between blocks of pipe data
	parameter ReadyCheckDelay = 5;    // REQUIRED: # of clocks before block transfer before
	                                  //           host interface checks for ready (0-255)
	parameter PostReadyDelay = 5;     // REQUIRED: # of clocks after ready is asserted and
	                                  //           check that the block transfer begins (0-255)
	parameter pipeInSize = 1024;      // REQUIRED: byte (must be even) length of default
	                                  //           PipeIn; Integer 0-2^32
	parameter pipeOutSize = 1024;     // REQUIRED: byte (must be even) length of default
	                                  //           PipeOut; Integer 0-2^32
	integer k, e;
	reg	[7:0]	pipeIn  [0:(pipeInSize-1)];
	reg	[7:0]	pipeOut [0:(pipeOutSize-1)];
	reg [7:0] pipetmp [0:(pipeInSize-1)];  // Data Check Array
	
	// Clock Generation
	parameter tCLK = 10.0;
	initial clk1 = 0;
	always #(tCLK/2.0) clk1 = ~clk1;
	
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
	
		wait (tf.dut.c3_calib_done == 1'b1);
	
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
