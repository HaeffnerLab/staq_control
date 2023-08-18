//------------------------------------------------------------------------
// test_oktb_tf.v
//
// This test fixture exercises the Opal Kelly RAMTester application of 
// the MIG DDR2 core.  It does not use the FrontPanel host simulation
// but rather mimics the signals that would be sent from PipeIn and 
// PipeOut modules. Based on sim_tb_top.v (MIG 3.5)
//
//------------------------------------------------------------------------
// Copyright (c) 2009 Opal Kelly Incorporated
// $Id: test_tf.v 260 2007-03-07 22:55:47Z jake $
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

// Clocks
					// Clocks
   reg                              c3_sys_clk;
   wire                             c3_sys_clk_p;
   wire                             c3_sys_clk_n;
// System Reset
   reg                              c3_sys_rst;
   wire                             c3_sys_rst_n;



// Design-Top Port Map
   wire                             c3_error;
   wire                             c3_calib_done;
   wire [31:0]                      c3_cmp_data;
   wire                             c3_cmp_error;

   wire [C3_MEM_ADDR_WIDTH-1:0]      mcb3_dram_a;
   wire [C3_MEM_BANKADDR_WIDTH-1:0]  mcb3_dram_ba;  
   wire                             mcb3_dram_ck;  
   wire                             mcb3_dram_ck_n;
   wire [C3_NUM_DQ_PINS-1:0]        mcb3_dram_dq;   
   wire                             mcb3_dram_dqs;  
   wire                             mcb3_dram_dqs_n;
   wire                             mcb3_dram_dm;
   wire                             mcb3_dram_ras_n; 
   wire                             mcb3_dram_cas_n; 
   wire                             mcb3_dram_we_n;  
   wire                             mcb3_dram_cke; 
   wire				                mcb3_dram_odt;

   wire [127:0]       c3_error_status;
   wire                             mcb3_dram_udqs;    // for X16 parts
   wire                             mcb3_dram_udqs_n;  // for X16 parts
   wire                             mcb3_dram_udm;     // for X16 parts

  wire                              c3_vio_modify_enable;
  wire  [2:0]                       c3_vio_data_mode_value;
  wire  [2:0]                       c3_vio_addr_mode_value;


// User design  Sim
        wire                             c3_clk0;
   wire							 c3_rst0;

     wire		c3_p0_cmd_en;
  wire [2:0]	c3_p0_cmd_instr;
  wire [5:0]	c3_p0_cmd_bl;
  wire [29:0]	c3_p0_cmd_byte_addr;
  wire		c3_p0_cmd_empty;
  wire		c3_p0_cmd_full;
  wire		c3_p0_wr_en;
  wire [C3_P0_MASK_SIZE - 1:0]	c3_p0_wr_mask;
  wire [C3_P0_DATA_PORT_SIZE - 1:0]	c3_p0_wr_data;
  wire		c3_p0_wr_full;
  wire		c3_p0_wr_empty;
  wire [6:0]	c3_p0_wr_count;
  wire		c3_p0_wr_underrun;
  wire		c3_p0_wr_error;
  wire		c3_p0_rd_en;
  wire [C3_P0_DATA_PORT_SIZE - 1:0]	c3_p0_rd_data;
  wire		c3_p0_rd_full;
  wire		c3_p0_rd_empty;
  wire [6:0]	c3_p0_rd_count;
  wire		c3_p0_rd_overflow;
  wire		c3_p0_rd_error;



// Error & Calib Signals
   wire                             error;
   wire                             calib_done;
   wire				    rzq3;
     
   wire				    zio3;
   
   //TB Wires
	reg          hi_clk;
	reg          rst_xfer;
	reg          rd_en, wr_en;
	reg          read_mode, write_mode;
	reg  [63:0]  wr_data;
	wire [63:0]  rd_data;
  wire         pipe_out_valid;   
   
// ========================================================================== //
// Clocks Generation                                                          //
// ========================================================================== //


   initial
      c3_sys_clk = 1'b0;
   always
      //#(C3_MEMCLK_PERIOD/2) c3_sys_clk = ~c3_sys_clk;
      #(10/2) c3_sys_clk = ~c3_sys_clk; // 100MHz
   assign                c3_sys_clk_p = c3_sys_clk;
   assign                c3_sys_clk_n = ~c3_sys_clk;

// ========================================================================== //
// Reset Generation                                                           //
// ========================================================================== //
 
   initial begin
      c3_sys_rst = 1'b0;		
      #1000
      c3_sys_rst = 1'b1;
   end
   assign c3_sys_rst_n = C3_RST_ACT_LOW ? c3_sys_rst : ~c3_sys_rst;


// ========================================================================== //
// Error Grouping                                                           //
// ========================================================================== //

assign error = c3_error;
assign calib_done = c3_calib_done;


   // The PULLDOWN component is connected to the ZIO signal primarily to avoid the
   // unknown state in simulation. In real hardware, ZIO should be a no connect(NC) pin.
   PULLDOWN zio_pulldown3 (.O(zio3));
   PULLDOWN rzq_pulldown3 (.O(rzq3));
   

// ========================================================================== //
// DESIGN TOP INSTANTIATION                                                    //
// ========================================================================== //

ddr2 #(

.C3_P0_MASK_SIZE       (C3_P0_MASK_SIZE      ),
.C3_P0_DATA_PORT_SIZE  (C3_P0_DATA_PORT_SIZE ),
.C3_P1_MASK_SIZE       (C3_P1_MASK_SIZE      ),
.C3_P1_DATA_PORT_SIZE  (C3_P1_DATA_PORT_SIZE ),
	.C3_MEMCLK_PERIOD         (C3_MEMCLK_PERIOD    ),
.C3_RST_ACT_LOW        (C3_RST_ACT_LOW),
.C3_INPUT_CLK_TYPE     (C3_INPUT_CLK_TYPE),

 
.DEBUG_EN              (DEBUG_EN),

.C3_MEM_ADDR_ORDER     (C3_MEM_ADDR_ORDER    ),
.C3_NUM_DQ_PINS        (C3_NUM_DQ_PINS       ),
.C3_MEM_ADDR_WIDTH     (C3_MEM_ADDR_WIDTH    ),
.C3_MEM_BANKADDR_WIDTH (C3_MEM_BANKADDR_WIDTH),

.C3_SIMULATION         (C3_SIMULATION),
.C3_CALIB_SOFT_IP      (C3_CALIB_SOFT_IP )
)
design_top (


    .c3_sys_clk_p           (c3_sys_clk_p),
  .c3_sys_clk_n           (c3_sys_clk_n),
  .c3_sys_rst_n           (c3_sys_rst_n),                        

  .mcb3_dram_dq           (mcb3_dram_dq),  
  .mcb3_dram_a            (mcb3_dram_a),  
  .mcb3_dram_ba           (mcb3_dram_ba),
  .mcb3_dram_ras_n        (mcb3_dram_ras_n),                        
  .mcb3_dram_cas_n        (mcb3_dram_cas_n),                        
  .mcb3_dram_we_n         (mcb3_dram_we_n),                          
  .mcb3_dram_odt          (mcb3_dram_odt),
  .mcb3_dram_cke          (mcb3_dram_cke),                          
  .mcb3_dram_ck           (mcb3_dram_ck),                          
  .mcb3_dram_ck_n         (mcb3_dram_ck_n),       
  .mcb3_dram_dqs          (mcb3_dram_dqs),                          
  .mcb3_dram_dqs_n        (mcb3_dram_dqs_n),
  .mcb3_dram_udqs         (mcb3_dram_udqs),    // for X16 parts                        
  .mcb3_dram_udqs_n       (mcb3_dram_udqs_n),  // for X16 parts
  .mcb3_dram_udm          (mcb3_dram_udm),     // for X16 parts
  .mcb3_dram_dm           (mcb3_dram_dm),
    .c3_clk0		        (c3_clk0),
  .c3_rst0		        (c3_rst0),
	
 
  .c3_calib_done          (c3_calib_done),
     .mcb3_rzq               (rzq3),
               
     .mcb3_zio               (zio3),
               
     .c3_p0_cmd_clk                          (c3_clk0),
   .c3_p0_cmd_en                           (c3_p0_cmd_en),
   .c3_p0_cmd_instr                        (c3_p0_cmd_instr),
   .c3_p0_cmd_bl                           (c3_p0_cmd_bl),
   .c3_p0_cmd_byte_addr                    (c3_p0_cmd_byte_addr),
   .c3_p0_cmd_empty                        (c3_p0_cmd_empty),
   .c3_p0_cmd_full                         (c3_p0_cmd_full),
   .c3_p0_wr_clk                           (c3_clk0),
   .c3_p0_wr_en                            (c3_p0_wr_en),
   .c3_p0_wr_mask                          (c3_p0_wr_mask),
   .c3_p0_wr_data                          (c3_p0_wr_data),
   .c3_p0_wr_full                          (c3_p0_wr_full),
   .c3_p0_wr_empty                         (c3_p0_wr_empty),
   .c3_p0_wr_count                         (c3_p0_wr_count),
   .c3_p0_wr_underrun                      (c3_p0_wr_underrun),
   .c3_p0_wr_error                         (c3_p0_wr_error),
   .c3_p0_rd_clk                           (c3_clk0),
   .c3_p0_rd_en                            (c3_p0_rd_en),
   .c3_p0_rd_data                          (c3_p0_rd_data),
   .c3_p0_rd_full                          (c3_p0_rd_full),
   .c3_p0_rd_empty                         (c3_p0_rd_empty),
   .c3_p0_rd_count                         (c3_p0_rd_count),
   .c3_p0_rd_overflow                      (c3_p0_rd_overflow),
   .c3_p0_rd_error                         (c3_p0_rd_error)
);      

// user interface

ddr2_test dut
	(
	.clk(c3_clk0),
	.reset(c3_rst0 | rst_xfer ),               //Sub in TB signals rst_xfer
	.reads_en(read_mode),                      //Sub in TB signals
	.writes_en(write_mode),                    //Sub in TB signals
	.calib_done(c3_calib_done), 
	
	.wr_clk(hi_clk),
	.wr_en(wr_en), //(pipe_in_write),          //Sub in TB signals
	.wr_data(wr_data), //(pipe_in_data),       //Sub in TB signals
	
	.rd_clk(hi_clk),
	.rd_en(rd_en), //(pipe_out_read),          //Sub in TB signals
	.rd_data(rd_data), //(pipe_out_data),      //Sub in TB signals
	.rd_fifo_valid(pipe_out_valid), 
	
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

// ========================================================================== //
// Memory model instances                                                     // 
// ========================================================================== //

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

// ========================================================================== //
// Reporting the test case status 
// ========================================================================== //
parameter N1data = 128; //128x64bits=1024 Bytes
parameter N2data = 128;
reg [63:0] Mem[0:N1data+N2data-1];

parameter tHICLK = 20.0;
initial hi_clk = 0;
always #(tHICLK/2.0) hi_clk = ~hi_clk;


// User configurable block of called FrontPanel operations.
integer i;
initial begin
	$display(" ");
	$display("//// Beginning Tests ////");
	$display(" ");

	wr_data <= 0;
	wr_en <= 0;
	rd_en <= 0;
	write_mode <= 1;
	read_mode <= 0;

	//sys_rst = 1'b1;
	rst_xfer = 1'b1;
	#200;
	//sys_rst = 1'b0;
	rst_xfer = 1'b0;


	// 1. Wait for PHY_INIT_DONE -- controller is ready.
	wait (c3_calib_done == 1'b1);
	#500;


	// 2. Write N1 64-bit words 48 MHz.
	for (i=0; i<N1data; i=i+1) begin
		@(posedge hi_clk) #1;
		wr_data = 64'h600d123456780000 | i+1; //{$random,$random}; //$random returns 32bits
		wr_en   = 1'b1;
		Mem[i]  = wr_data;
	end
	@(posedge hi_clk) #1 wr_en <= 1'b0;
	#10000;
	
	write_mode <= 0;
	read_mode <= 1;
	#25000;

	// 3. Read N1 64-bit words.
	for (i=0; i<N1data; i=i+1) begin
		@(posedge hi_clk)
		rd_en <= 1'b1;
	end
	@(posedge hi_clk) #1 rd_en <= 1'b0;
	#10000;

	// Turn off reads, then wait a bit since there will still be a bunch
	// of reads queued to the DDR2 controller.
	write_mode <= 1;
	read_mode <= 0;
	#1000;


	// RESET the transfer state machine since we're going to start a 
	// new independent transfer.  This also resets the FIFOs so that they're
	// clear and we don't have residual read data.  It is important to note
	// the resultant timing of the RESET -- it must occur AFTER rd_data_valid
	// deasserts.  This means that the reset has occurred after all the 
	// read commands at the DDR2 controller have completed.
	rst_xfer = 1'b1;
	#100;
	rst_xfer = 1'b0;
	#500;
	

	// 4. Write N2 64-bit words 48 MHz.
	for (i=0; i<N2data; i=i+1) begin
		@(posedge hi_clk) #1;
		wr_data = 64'h600d123456780000 | i+1; //{$random,$random}; //$random returns 32bits
		wr_en   = 1'b1;
		Mem[i+N1data]  = wr_data;
	end
	@(posedge hi_clk) #1 wr_en <= 1'b0;
	#10000;
	
	write_mode <= 0;
	read_mode <= 1;
	#25000;

	// 5. Read N2 64-bit words.
	for (i=0; i<N2data; i=i+1) begin
		@(posedge hi_clk)
		rd_en <= 1'b1;
	end
	@(posedge hi_clk) #1 rd_en <= 1'b0;
	#1000;	

	//$stop;
end


reg rd_en_d;
integer j;
initial j=0;
always @(posedge hi_clk) begin
	rd_en_d <= rd_en;

	#1;
	if (rd_en_d == 1'b1) begin
		if (rd_data !== Mem[j]) begin
			$display("%t ERROR: Mem[%d]=0x%04h != 0x%04h", $time, j, Mem[j], rd_data);
		end else begin
			$display("%t  GOOD: Mem[%d]=0x%04h == 0x%04h", $time, j, Mem[j], rd_data);
		end
		j = j + 1;
	end
end  

endmodule