//------------------------------------------------------------------------
// ramtest.v
//
// A test sample for the RAM3001 daughterboard.  This sample includes a 
// simple SDRAM controller and HDL to move data from the PC to the 
// SDRAM and vice-versa.
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
//     2 - SSRAM read enable (0=disabled, 1=enabled)
//     3 - SSRAM write enable (0=disabled, 1=enabled)
// WireIn 0x01
//  14:0 - SDRAM row address
//
// TriggerIn 0x40 (on SDRAM_CLK, SSRAM_CLK, TI_CLK)
//     0 - Reset
//     1 - Set READ address pointer
//     2 - Set WRITE address pointer
//
// PipeIn 0x80 - SDRAM write port
// PipeIn 0x81 - SSRAM write port
// PipeOut 0xA0 - SDRAM read port
// PipeOut 0xA1 - SSRAM read port
//
// This sample is included for reference only.  No guarantees, either 
// expressed or implied, are to be drawn.
//------------------------------------------------------------------------
// tabstop 3
// Copyright (c) 2005 Opal Kelly Incorporated
//------------------------------------------------------------------------


`default_nettype none
`timescale 1ns / 1ps
module ramtest(
   input  wire [7:0]  hi_in,
   output wire [1:0]  hi_out,
   inout  wire [15:0] hi_inout,

	input  wire        clk1,
	input  wire        clk2,

	output wire        sdram_cke,
	output wire        sdram_cs_n,
	output wire        sdram_we_n,
	output wire        sdram_cas_n,
	output wire        sdram_ras_n,
	output wire [1:0]  sdram_ba,
	output wire [12:0] sdram_a,
	inout  wire [15:0] sdram_d,
   
	output wire [7:0]  led
	);


// Host interface connections
wire        ti_clk;
wire [30:0] ok1;
wire [16:0] ok2;
wire [15:0] ep00wire;
wire [15:0] ep01wire;
wire [15:0] ep20wire;
wire [15:0] ep40trigA;	// SDRAM_CLK
wire [15:0] ep40trigB;	// SSRAM_CLK
wire [15:0] ep40trigC;	// TI_CLK
wire        sdram_fiforeset = ep40trigA[0];
wire        ssram_fiforeset = ep40trigB[0];

wire        sdram_clk;
wire        sdram_clk_read;
wire        sdram_reset = ep40trigA[0];
wire        sdram_setrdaddr = ep40trigA[1];
wire        sdram_setwraddr = ep40trigA[2];
wire        sdram_rden = ep00wire[0];
wire        sdram_wren = ep00wire[1];

wire        ssram_clk;
wire        ssram_reset = ep40trigB[0];
wire        ssram_setrdaddr = ep40trigB[1];
wire        ssram_setwraddr = ep40trigB[2];
wire        ssram_rden = ep00wire[2];
wire        ssram_wren = ep00wire[3];

// SDRAM controller / negotiator connections
reg         cmd_pageread;
reg         cmd_pagewrite;
wire        cmd_ack;
wire        cmd_done;

// SDRAM controller / FIFO connections.
wire        c0_fifo_read;
wire        c0_fifo_write;
wire [15:0] c0_fifo_dout;
wire [15:0] ep80_dout;
wire [3:0]  ep80_status;
wire [3:0]  epA0_status;


// SSRAM controller / FIFO connections.
wire        c1_fifo_read;
wire        c1_fifo_write;
wire [15:0] c1_fifo_dout;
wire [15:0] ep81_dout;
wire [3:0]  ep81_status;
wire [3:0]  epA1_status;

parameter n_idle = 0,
          n_wackwait = 1,
          n_rackwait = 2,
			 n_busy = 3;
integer staten;

assign sdram_cke = 1'b1;
assign led = {epA0_status, ep80_status};

//------------------------------------------------------------------------
// SDRAM transfer negotiator
//   This block handles communication between the SDRAM controller and
//   the Buffered Pipes (FIFOs).  The FIFOs act as a simplified cache,
//   holding at least a full page on-chip while the PC reads the FIFO.
//   This dramatically increases DRAM access performance since full pages
//   can be read very quickly.  Since the PC transfers are slower than the
//   DRAM, there is no fear of underrun.
//------------------------------------------------------------------------
always @(posedge sdram_clk) begin
	if (sdram_reset == 1'b1) begin
		staten <= n_idle;
		cmd_pagewrite <= 1'b0;
		cmd_pageread <= 1'b0;
	end else begin

		case (staten)
			n_idle: begin
				cmd_pagewrite <= 1'b0;
				cmd_pageread <= 1'b0;
				staten <= n_idle;

				// If SDRAM WRITEs are enabled, trigger a block write whenever
				// the Pipe In buffer is at least 1/4 full (1 page, 512 words).
				if ((sdram_wren == 1'b1) && (ep80_status >= 4'b0100)) begin
					staten <= n_wackwait;
				end

				// If SDRAM READs are enabled, trigger a block read whenever
				// the Pipe Out buffer has room for at least 1 page (512 words).
				else if ((sdram_rden == 1'b1) && (epA0_status <= 4'b1000)) begin
					staten <= n_rackwait;
				end
			end

			n_wackwait: begin
				cmd_pagewrite <= 1'b1;
				staten <= n_wackwait;
				if (cmd_ack == 1'b1) begin
					cmd_pagewrite <= 1'b0;
					staten <= n_busy;
				end
			end

			n_rackwait: begin
				cmd_pageread <= 1'b1;
				staten <= n_rackwait;
				if (cmd_ack == 1'b1) begin
					cmd_pageread <= 1'b0;
					staten <= n_busy;
				end
			end

			n_busy: begin
				cmd_pagewrite <= 1'b0;
				cmd_pageread <= 1'b0;
				staten <= n_busy;
				if (cmd_done == 1'b1) begin
					staten <= n_idle;
				end
			end

		endcase
	end
end


//------------------------------------------------------------------------
// SDRAM CONTROLLER
//------------------------------------------------------------------------
sdramctrl c0 (
		.clk(sdram_clk),
		.clk_read(sdram_clk_read),
		.reset(sdram_reset),
		.cmd_setwraddr(sdram_setwraddr),
		.cmd_setrdaddr(sdram_setrdaddr),
		.cmd_pagewrite(cmd_pagewrite),
		.cmd_pageread(cmd_pageread),
		.cmd_ack(cmd_ack),
		.cmd_done(cmd_done),
		.rowaddr_in(ep01wire[14:0]),
		.fifo_din(ep80_dout),
		.fifo_read(c0_fifo_read),
		.fifo_dout(c0_fifo_dout),
		.fifo_write(c0_fifo_write),
		.sdram_cmd({sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n}),
		.sdram_ba(sdram_ba),
		.sdram_a(sdram_a),
		.sdram_d(sdram_d));


//------------------------------------------------------------------------
// SSRAM CONTROLLER
//------------------------------------------------------------------------
//ssramctrl c1 (
//		.clk(ssram_clk),
//		.reset(ssram_reset),
//		.cmd_setaddr(),
//		.cmd_pagewrite(cmd_pagewrite),
//		.cmd_pageread(cmd_pageread),
//		.cmd_ack(cmd_ack),
//		.cmd_done(cmd_done),
//		.rowaddr_in(ep01wire[14:0]),
//		.fifo_din(ep81_dout),
//		.fifo_read(c0_fifo_read),
//		.fifo_dout(c0_fifo_dout),
//		.fifo_write(c0_fifo_write),
//		.ssram_ce_n(ssram_ce1),
//		.ssram_we_n(ssram_we),
//		.ssram_a(ssram_a),
//		.ssram_d(ssram_d));


//------------------------------------------------------------------------
// DCM
//   This ensures that the internal FPGA fabric clock (CLK) is phase 
//   aligned with the provided PLL clock (PLL_CLK) that is shared with 
//   the SDRAM at the board level.
//
// Note that at higher frequencies, the setup time is not actually met
// because the SDRAM specs a -max- tAC (access time on reads) at 5.4ns.
// At 133 MHz, this leaves only 2.1ns setup.  The Spartan-3 (400) is 
// spec'd for 2.36ns setup.  One way to resolve this is to use the 90-deg
// phase clock to latch input data from the SDRAM.  This will cause the
// pipeline to be one off, though, so the SDRAM controller would need a 
// few changes.
//
// Our measurements showed that this was not necessary.  Perhaps this 
// long access is rarely required or only required at rated extremes.
//------------------------------------------------------------------------
BUFGDLL dcm0 (.I(clk1), .O(sdram_clk));
BUFGDLL dcm1 (.I(clk2), .O(ssram_clk));
assign sdram_clk_read = sdram_clk;
//wire sdram_clk_0;
//wire sdram_clk_90;
//DCM dcm0 (
//		.CLKIN(clk1),
//		.CLKFB(sdram_clk),
//		.CLK0(sdram_clk_0),
//		.CLK90(sdram_clk_90)
//		);
//BUFG bufg0 (.I(sdram_clk_0), .O(sdram_clk));
//BUFG bufg1 (.I(sdram_clk_90), .O(sdram_clk_read));


//------------------------------------------------------------------------
// USB HOST INTERFACE
//------------------------------------------------------------------------
okHostInterface okHI(
      .hi_in(hi_in), .hi_out(hi_out), .hi_inout(hi_inout),
      .ti_clk(ti_clk), .ok1(ok1), .ok2(ok2));

okTriggerIn ep40a (
      .ok1(ok1), .ok2(ok2),
      .ep_addr(8'h40), .ep_clk(sdram_clk), .ep_trigger(ep40trigA));
okTriggerIn ep40b (
      .ok1(ok1), .ok2(ok2),
      .ep_addr(8'h40), .ep_clk(ssram_clk), .ep_trigger(ep40trigB));
okTriggerIn ep40c (
      .ok1(ok1), .ok2(ok2),
      .ep_addr(8'h40), .ep_clk(ti_clk), .ep_trigger(ep40trigC));

okWireIn ep00 (
      .ok1(ok1), .ok2(ok2),
      .ep_addr(8'h00), .ep_dataout(ep00wire));
okWireIn ep01 (
      .ok1(ok1), .ok2(ok2),
      .ep_addr(8'h01), .ep_dataout(ep01wire));

// SDRAM pipes
okBufferedPipeIn ep80 (
      .ok1(ok1), .ok2(ok2),
		.ep_addr(8'h80), .ep_clk(sdram_clk), .ep_read(c0_fifo_read), .ep_dataout(ep80_dout),
		.ep_reset(sdram_fiforeset), .ep_full(), .ep_empty(), .ep_status(ep80_status));
okBufferedPipeOut epA0 (
      .ok1(ok1), .ok2(ok2),
		.ep_addr(8'ha0), .ep_clk(sdram_clk), .ep_write(c0_fifo_write), .ep_datain(c0_fifo_dout),
		.ep_reset(sdram_fiforeset), .ep_full(), .ep_empty(), .ep_status(epA0_status));

// SSRAM pipes
okBufferedPipeIn ep81 (
      .ok1(ok1), .ok2(ok2),
		.ep_addr(8'h81), .ep_clk(ssram_clk), .ep_read(c1_fifo_read), .ep_dataout(ep81_dout),
		.ep_reset(ssram_fiforeset), .ep_full(), .ep_empty(), .ep_status(ep81_status));
okBufferedPipeOut epA1 (
      .ok1(ok1), .ok2(ok2),
		.ep_addr(8'ha1), .ep_clk(ssram_clk), .ep_write(c1_fifo_write), .ep_datain(c1_fifo_dout),
		.ep_reset(ssram_fiforeset), .ep_full(), .ep_empty(), .ep_status(epA1_status));

endmodule
