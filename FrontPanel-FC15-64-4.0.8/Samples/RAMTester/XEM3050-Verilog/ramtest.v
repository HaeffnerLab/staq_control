//------------------------------------------------------------------------
// ramtest.v
//
// This sample includes a simple SDRAM controller and HDL to move data
// from the PC to the SDRAM and vice-versa.
//
// The SDRAM controller is designed for full-page SDRAM transactions.
// We instantiate two FIFOs at the top-level to buffer data going to
// and from the SDRAM:
//    + When the 'write' FIFO contains at least a full-page (512 words),
//      then the SDRAM controller is instructed to move that page to the
//      SDRAM.
//    + When the 'read' FIFO has room for at least a full-page, then
//      the SDRAM controller is instructed to fill that void by reading
//      a page from SDRAM.
//
// Host Interface registers:
// WireIn 0x00
//     0 - SDRAM read enable (0=disabled, 1=enabled)
//     1 - SDRAM write enable (0=disabled, 1=enabled)
//     2 - Reset
//
// PipeIn 0x80 - SDRAM write port
// PipeOut 0xA0 - SDRAM read port
//
// This sample is included for reference only.  No guarantees, either 
// expressed or implied, are to be drawn.
//------------------------------------------------------------------------
// tabstop 3
// Copyright (c) 2005-2007 Opal Kelly Incorporated
// $Rev: 470 $ $Date: 2010-05-11 13:34:43 -0700 (Tue, 11 May 2010) $
//------------------------------------------------------------------------


`default_nettype none
`timescale 1ns / 1ps
module ramtest(
   input  wire [7:0]  hi_in,
   output wire [1:0]  hi_out,
   inout  wire [15:0] hi_inout,

   output wire        hi_muxsel,
	output wire        i2c_scl,
	output wire        i2c_sda,
	
	input  wire        clk1,

	output wire        sdram0_clk,
	output wire        sdram0_cke,
	output wire        sdram0_cs_n,
	output wire        sdram0_we_n,
	output wire        sdram0_cas_n,
	output wire        sdram0_ras_n,
	output wire        sdram0_ldqm,
	output wire        sdram0_udqm,
	output wire [1:0]  sdram0_ba,
	output wire [12:0] sdram0_a,
	inout  wire [15:0] sdram0_d,
   
	output wire        sdram1_clk,
	output wire        sdram1_cke,
	output wire        sdram1_cs_n,
	output wire        sdram1_we_n,
	output wire        sdram1_cas_n,
	output wire        sdram1_ras_n,
	output wire        sdram1_ldqm,
	output wire        sdram1_udqm,
	output wire [1:0]  sdram1_ba,
	output wire [12:0] sdram1_a,
	inout  wire [15:0] sdram1_d,
   
	output wire [3:0]  led
	);


// Host interface connections
wire        ti_clk;
wire [30:0] ok1;
wire [16:0] ok2;
wire [15:0] ep00wire;
reg         reset;

wire        sdram_clk;
reg         sdram_rden;
reg         sdram_wren;

// SDRAM controller / FIFO connections.
wire        ep80_write, ep81_write;
wire [15:0] ep80_dout, ep81_dout;
wire        epA0_read, epA1_read;
wire [15:0] epA0_din, epA1_din;

reg         fault_ofull, fault_ifull, fault_oempty, fault_iempty;

assign hi_muxsel = 1'b0;
assign i2c_scl = 1'bz;
assign i2c_sda = 1'bz;

assign sdram0_cke = 1'b1;
assign sdram0_ldqm = 1'b0;
assign sdram0_udqm = 1'b0;
assign sdram1_cke = 1'b1;
assign sdram1_ldqm = 1'b0;
assign sdram1_udqm = 1'b0;

assign led = ~{4'b0000, fault_ofull, fault_ifull, fault_oempty, fault_iempty};


// These signals come in on TI_CLK from the host interface.  We need
// to make sure to resynchronize them to our state machine clock or
// things strange things can happen (like hopping to unexpected states).
always @(negedge sdram_clk) begin
	sdram_rden <= ep00wire[0];
	sdram_wren <= ep00wire[1];
	reset <= ep00wire[2];
end


//------------------------------------------------------------------------
// SDRAM CONTROLLER
//------------------------------------------------------------------------
ramxfer c0 (
		.clk(~sdram_clk),
		.ti_clk(ti_clk),
		.reset(reset),
		.en_read(sdram_rden),
		.en_write(sdram_wren),
		.pipeIn_write(ep80_write),
		.pipeIn_data(ep80_dout),
		.pipeOut_read(epA0_read),
		.pipeOut_data(epA0_din),
		.sdram_cmd({sdram0_cs_n, sdram0_ras_n, sdram0_cas_n, sdram0_we_n}),
		.sdram_ba(sdram0_ba),
		.sdram_a(sdram0_a),
		.sdram_d(sdram0_d));
ramxfer c1 (
		.clk(~sdram_clk),
		.ti_clk(ti_clk),
		.reset(reset),
		.en_read(sdram_rden),
		.en_write(sdram_wren),
		.pipeIn_write(ep81_write),
		.pipeIn_data(ep81_dout),
		.pipeOut_read(epA1_read),
		.pipeOut_data(epA1_din),
		.sdram_cmd({sdram1_cs_n, sdram1_ras_n, sdram1_cas_n, sdram1_we_n}),
		.sdram_ba(sdram1_ba),
		.sdram_a(sdram1_a),
		.sdram_d(sdram1_d));


assign sdram_clk = clk1;

// This bit is for source-synchronous configurations where the SDRAM clock
// comes from the FPGA rather than directly from the PLL.  We output the
// clock from an FPGA DDR register.
OFDDRCPE sdram0OutputClock (
	.Q(sdram0_clk),
	.C0(sdram_clk),
	.C1(~sdram_clk),
	.CE(1'b1),
	.CLR(1'b0),
	.D0(1'b1),
	.D1(1'b0),
	.PRE(1'b0) );
OFDDRCPE sdram1OutputClock (
	.Q(sdram1_clk),
	.C0(sdram_clk),
	.C1(~sdram_clk),
	.CE(1'b1),
	.CLR(1'b0),
	.D0(1'b1),
	.D1(1'b0),
	.PRE(1'b0) );


// Instantiate the okHost and connect endpoints.
wire [17*4-1:0]  ok2x;
okHost okHI(
	.hi_in(hi_in), .hi_out(hi_out), .hi_inout(hi_inout), .ti_clk(ti_clk),
	.ok1(ok1), .ok2(ok2));

okWireOR # (.N(4)) wireOR (ok2, ok2x);

okWireIn   ep00 (.ok1(ok1),                           .ep_addr(8'h00), .ep_dataout(ep00wire));
okPipeIn   ep80 (.ok1(ok1), .ok2(ok2x[ 0*17 +: 17 ]), .ep_addr(8'h80), .ep_write(ep80_write), .ep_dataout(ep80_dout));
okPipeIn   ep81 (.ok1(ok1), .ok2(ok2x[ 1*17 +: 17 ]), .ep_addr(8'h81), .ep_write(ep81_write), .ep_dataout(ep81_dout));
okPipeOut  epA0 (.ok1(ok1), .ok2(ok2x[ 2*17 +: 17 ]), .ep_addr(8'ha0), .ep_read(epA0_read), .ep_datain(epA0_din));
okPipeOut  epA1 (.ok1(ok1), .ok2(ok2x[ 3*17 +: 17 ]), .ep_addr(8'ha1), .ep_read(epA1_read), .ep_datain(epA1_din));

endmodule
