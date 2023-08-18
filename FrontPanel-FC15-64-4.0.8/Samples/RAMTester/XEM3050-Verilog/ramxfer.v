//------------------------------------------------------------------------
// ramxfer.v
//
// This sample is included for reference only.  No guarantees, either 
// expressed or implied, are to be drawn.
//------------------------------------------------------------------------
// tabstop 3
// Copyright (c) 2005-2007 Opal Kelly Incorporated
// $Rev: 303 $ $Date: 2007-05-16 19:13:24 -0700 (Wed, 16 May 2007) $
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

module ramxfer(
	input  wire        clk,
	input  wire        ti_clk,
	input  wire        reset,
	input  wire        en_read,
	input  wire        en_write,
	
	input  wire        pipeIn_write,
	input  wire [15:0] pipeIn_data,
	input  wire        pipeOut_read,
	output wire [15:0] pipeOut_data,
	
	output reg         fault_iempty,
	output reg         fault_ifull,
	output reg         fault_oempty,
	output reg         fault_ofull,
	
	output wire [3:0]  sdram_cmd,		// cs_n, ras_n, cas_n, we_n}
	output wire [1:0]  sdram_ba,
	output wire [12:0] sdram_a,
	inout  wire [15:0] sdram_d
	);


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
wire [15:0] in_fifo_dout;
wire [10:0] in_fifo_status;
wire        in_fifo_empty;
wire        in_fifo_full;
wire [10:0] out_fifo_status;
wire        out_fifo_empty;
wire        out_fifo_full;


//------------------------------------------------------------------------
// Transfer FIFOs.  These are wired directly to the pipes.
//------------------------------------------------------------------------
fifo16w16r_2048 in_fifo (
		.rst(reset), .rd_data_count(in_fifo_status), .wr_data_count(),
		.empty(in_fifo_empty), .full(in_fifo_full),
		.wr_clk(ti_clk), .wr_en(pipeIn_write), .din(pipeIn_data),
		.rd_clk(clk), .rd_en(c0_fifo_read), .dout(in_fifo_dout));

fifo16w16r_2048 out_fifo (
		.rst(reset), .rd_data_count(), .wr_data_count(out_fifo_status),
		.empty(out_fifo_empty), .full(out_fifo_full),
		.wr_clk(clk), .wr_en(c0_fifo_write), .din(c0_fifo_dout),
		.rd_clk(ti_clk), .rd_en(pipeOut_read), .dout(pipeOut_data));


// These will register a fault:
//   - Read from a FIFO that is empty
//   - Write to a FIFO that is full
// Since the Host Interface is operating at 48 MHz and the SDRAM is
// much faster than that, it should easily be able to keep up with 
// the PC transfers, so these faults should never occur.
always @(posedge clk) begin
	if (reset == 1'b1) begin
		fault_ofull <= 1'b0;
		fault_iempty <= 1'b0;
	end else begin
		if ((c0_fifo_write == 1'b1) && (out_fifo_full == 1'b1)) begin
			fault_ofull <= 1'b1;
		end
		if ((c0_fifo_read == 1'b1) && (in_fifo_empty == 1'b1)) begin
			fault_iempty <= 1'b1;
		end
	end
end

always @(posedge ti_clk) begin
	if (reset == 1'b1) begin
		fault_ifull <= 1'b0;
		fault_oempty <= 1'b0;
	end else begin
		if ((pipeIn_write == 1'b1) && (in_fifo_full == 1'b1)) begin
			fault_ifull <= 1'b1;
		end
		if ((pipeOut_read == 1'b1) && (out_fifo_empty == 1'b1)) begin
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
always @(posedge clk) begin
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
				if ((en_write == 1'b1) && (in_fifo_status[10:7] >= 4'b0100)) begin
					staten <= n_wackwait;
				end

				// If SDRAM READs are enabled, trigger a block read whenever
				// the Pipe Out buffer has room for at least 1 page (512 words).
				else if ((en_read == 1'b1) && (out_fifo_status[10:7] <= 4'b1000)) begin
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
sdramctrl ctl0 (
		.clk(clk),
		.clk_read(clk),
		.reset(reset),
		.cmd_pagewrite(cmd_pagewrite),
		.cmd_pageread(cmd_pageread),
		.cmd_ack(cmd_ack),
		.cmd_done(cmd_done),
		.rowaddr_in(rowaddr),
		.fifo_din(in_fifo_dout),
		.fifo_read(c0_fifo_read),
		.fifo_dout(c0_fifo_dout),
		.fifo_write(c0_fifo_write),
		.sdram_cmd(sdram_cmd),
		.sdram_ba(sdram_ba),
		.sdram_a(sdram_a),
		.sdram_d(sdram_d));

endmodule
