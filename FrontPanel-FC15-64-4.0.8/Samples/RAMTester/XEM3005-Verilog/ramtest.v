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
module fifo16w16r_2048(
	input  [15:0] din,
	input         rd_clk,
	input         rd_en,
	input         rst,
	input         wr_clk,
	input         wr_en,
	output [15:0] dout,
	output        empty,
	output        full,
	output [10:0] rd_data_count,
	output [10:0] wr_data_count
);
// synthesis attribute box_type fifo16w16r_2048 "black_box"
endmodule

module ramtest(
   input  wire [7:0]  hi_in,
   output wire [1:0]  hi_out,
   inout  wire [15:0] hi_inout,

   output wire        hi_muxsel,
	output wire        i2c_scl,
	output wire        i2c_sda,
	
	input  wire        clk1,

	output wire        sdram_clk_out,
	output wire        sdram_cke,
	output wire        sdram_cs_n,
	output wire        sdram_we_n,
	output wire        sdram_cas_n,
	output wire        sdram_ras_n,
	output wire        sdram_ldqm,
	output wire        sdram_udqm,
	output wire [1:0]  sdram_ba,
	output wire [12:0] sdram_a,
	inout  wire [15:0] sdram_d,
   
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

// SDRAM controller / negotiator connections
reg         cmd_pageread;
reg         cmd_pagewrite;
wire        cmd_ack;
wire        cmd_done;
reg  [14:0] rowaddr;

// SDRAM controller / FIFO connections.
wire        c0_fifo_read;
wire        c0_fifo_write;
wire [15:0] c0_fifo_dout;
wire [15:0] ep80_dout;
wire        ep80_write;
wire [15:0] ep80fifo_dout;
wire [10:0] ep80fifo_status;
wire        ep80fifo_empty;
wire        ep80fifo_full;
wire        epA0_read;
wire [15:0] epA0_din;
wire [10:0] epA0fifo_status;
wire        epA0fifo_empty;
wire        epA0fifo_full;

reg         fault_ofull, fault_ifull, fault_oempty, fault_iempty;

assign hi_muxsel = 1'b0;
assign i2c_scl = 1'bz;
assign i2c_sda = 1'bz;

assign sdram_cke = 1'b1;
assign sdram_ldqm = 1'b0;
assign sdram_udqm = 1'b0;

assign led = ~{fault_ofull, fault_ifull, fault_oempty, fault_iempty};


// These signals come in on TI_CLK from the host interface.  We need
// to make sure to resynchronize them to our state machine clock or
// things strange things can happen (like hopping to unexpected states).
always @(negedge sdram_clk) begin
	sdram_rden <= ep00wire[0];
	sdram_wren <= ep00wire[1];
	reset <= ep00wire[2];
end


// These will register a fault:
//   - Read from a FIFO that is empty
//   - Write to a FIFO that is full
// Since the Host Interface is operating at 48 MHz and the SDRAM is
// much faster than that, it should easily be able to keep up with 
// the PC transfers, so these faults should never occur.
always @(negedge sdram_clk) begin
	if (reset == 1'b1) begin
		fault_ofull <= 1'b0;
		fault_iempty <= 1'b0;
	end else begin
		if ((c0_fifo_write == 1'b1) && (epA0fifo_full == 1'b1)) begin
			fault_ofull <= 1'b1;
		end
		if ((c0_fifo_read == 1'b1) && (ep80fifo_empty == 1'b1)) begin
			fault_iempty <= 1'b1;
		end
	end
end

always @(posedge ti_clk) begin
	if (reset == 1'b1) begin
		fault_ifull <= 1'b0;
		fault_oempty <= 1'b0;
	end else begin
		if ((ep80_write == 1'b1) && (ep80fifo_full == 1'b1)) begin
			fault_ifull <= 1'b1;
		end
		if ((epA0_read == 1'b1) && (epA0fifo_empty == 1'b1)) begin
			fault_oempty <= 1'b1;
		end
	end
end


//------------------------------------------------------------------------
// SDRAM transfer negotiator
//   This block handles communication between the SDRAM controller and
//   the FIFOs.  The FIFOs act as a simplified cache, holding at least
//   a full page on-chip while the PC reads the FIFO.  This dramatically
//   increases DRAM access performance since full pages can be read very
//   quickly.  Since the PC transfers are slower than the DRAM, there is
//   no fear of underrun.
//------------------------------------------------------------------------
parameter n_idle = 0,
          n_wackwait = 1,
          n_rackwait = 2,
			 n_busy = 3;
integer staten;
always @(negedge sdram_clk) begin
	if (reset == 1'b1) begin
		staten <= n_idle;
		cmd_pagewrite <= 1'b0;
		cmd_pageread <= 1'b0;
		rowaddr <= 15'h0000;
	end else begin
		cmd_pagewrite <= 1'b0;
		cmd_pageread <= 1'b0;

		case (staten)
			n_idle: begin
				staten <= n_idle;

				// If SDRAM WRITEs are enabled, trigger a block write whenever
				// the Pipe In buffer is at least 1/4 full (1 page, 512 words).
				if ((sdram_wren == 1'b1) && (ep80fifo_status[10:7] >= 4'b0100)) begin
					staten <= n_wackwait;
				end

				// If SDRAM READs are enabled, trigger a block read whenever
				// the Pipe Out buffer has room for at least 1 page (512 words).
				else if ((sdram_rden == 1'b1) && (epA0fifo_status[10:7] <= 4'b1000)) begin
					staten <= n_rackwait;
				end
			end


			n_wackwait: begin
				cmd_pagewrite <= 1'b1;
				staten <= n_wackwait;
				if (cmd_ack == 1'b1) begin
					rowaddr <= rowaddr + 1;
					staten <= n_busy;
				end
			end
			

			n_rackwait: begin
				cmd_pageread <= 1'b1;
				staten <= n_rackwait;
				if (cmd_ack == 1'b1) begin
					rowaddr <= rowaddr + 1;
					staten <= n_busy;
				end
			end
			

			n_busy: begin
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
		.clk(~sdram_clk),
		.clk_read(~sdram_clk),
		.reset(reset),
		.cmd_pagewrite(cmd_pagewrite),
		.cmd_pageread(cmd_pageread),
		.cmd_ack(cmd_ack),
		.cmd_done(cmd_done),
		.rowaddr_in(rowaddr),
		.fifo_din(ep80fifo_dout),
		.fifo_read(c0_fifo_read),
		.fifo_dout(c0_fifo_dout),
		.fifo_write(c0_fifo_write),
		.sdram_cmd({sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n}),
		.sdram_ba(sdram_ba),
		.sdram_a(sdram_a),
		.sdram_d(sdram_d));


//------------------------------------------------------------------------
// DCM
//   This ensures that the internal FPGA fabric clock (CLK) is phase 
//   aligned with the provided PLL clock (PLL_CLK) that is shared with 
//   the SDRAM at the board level.
//
//   The DCM here uses a phase delay to best align the fabric clock with
//   the SDRAM clock for optimum performance.  The phase delay was 
//   determined experimentally by testing the maximum "no-error" frequency
//   of RAMTester for various phase delays.
//------------------------------------------------------------------------
dcm_sys sdramDCM (
    .CLKIN_IN(clk1), 
    .RST_IN(1'b0), 
    .CLKIN_IBUFG_OUT(), 
    .CLK0_OUT(sdram_clk),
    .LOCKED_OUT() );


// This bit is for source-synchronous configurations where the SDRAM clock
// comes from the FPGA rather than directly from the PLL.  We output the
// clock from an FPGA DDR register.
OFDDRCPE sdramOutputClock (
	.Q(sdram_clk_out),
	.C0(sdram_clk),
	.C1(~sdram_clk),
	.CE(1'b1),
	.CLR(1'b0),
	.D0(1'b1),
	.D1(1'b0),
	.PRE(1'b0) );


fifo16w16r_2048 ep80fifo (
		.rst(reset), .rd_data_count(ep80fifo_status), .wr_data_count(),
		.empty(ep80fifo_empty), .full(ep80fifo_full),
		.wr_clk(ti_clk), .wr_en(ep80_write), .din(ep80_dout),
		.rd_clk(~sdram_clk), .rd_en(c0_fifo_read), .dout(ep80fifo_dout));
fifo16w16r_2048 epA0fifo (
		.rst(reset), .rd_data_count(), .wr_data_count(epA0fifo_status),
		.empty(epA0fifo_empty), .full(epA0fifo_full),
		.wr_clk(~sdram_clk), .wr_en(c0_fifo_write), .din(c0_fifo_dout),
		.rd_clk(ti_clk), .rd_en(epA0_read), .dout(epA0_din));


// Instantiate the okHost and connect endpoints.
wire [17*2-1:0]  ok2x;
okHost okHI(
	.hi_in(hi_in), .hi_out(hi_out), .hi_inout(hi_inout), .ti_clk(ti_clk),
	.ok1(ok1), .ok2(ok2));

okWireOR # (.N(2)) wireOR (ok2, ok2x);

okWireIn   ep00 (.ok1(ok1),                           .ep_addr(8'h00), .ep_dataout(ep00wire));
okPipeIn   ep80 (.ok1(ok1), .ok2(ok2x[ 0*17 +: 17 ]), .ep_addr(8'h80), .ep_write(ep80_write), .ep_dataout(ep80_dout));
okPipeOut  epA0 (.ok1(ok1), .ok2(ok2x[ 1*17 +: 17 ]), .ep_addr(8'ha0), .ep_read(epA0_read), .ep_datain(epA0_din));

endmodule
