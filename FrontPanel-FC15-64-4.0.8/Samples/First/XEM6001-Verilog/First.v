//------------------------------------------------------------------------
// First.v
//
// A simple example for getting started with FrontPanel.  This sample
// connects the on-board buttons to Wire Outs and the on-board LEDs
// to Wire Ins so that FrontPanel can observe the buttons and control
// the LEDs.
//
// Copyright (c) 2006 Opal Kelly Incorporated
//------------------------------------------------------------------------

`default_nettype none
`timescale 1ns / 1ps

module First(
	input  wire [7:0]  hi_in,
	output wire [1:0]  hi_out,
	inout  wire [15:0] hi_inout,
	
	output wire        hi_muxsel,
   
	output wire [7:0] led,
	input  wire [3:0] button
	);

// Opal Kelly Module Interface Connections
wire        ti_clk;
wire [30:0] ok1;
wire [16:0] ok2;

// Endpoint connections:
wire [15:0]  ep00wire;
wire [15:0]  ep01wire;
wire [15:0]  ep02wire;
wire [15:0]  ep20wire;
wire [15:0]  ep21wire;

assign hi_muxsel    = 1'b0;
assign led      = ~ep00wire[7:0];
assign ep20wire = {12'b0000, ~button};
assign ep21wire = ep01wire + ep02wire;

// Instantiate the okHost and connect endpoints.
wire [17*2-1:0]  ok2x;
okHost okHI(
	.hi_in(hi_in), .hi_out(hi_out), .hi_inout(hi_inout), .ti_clk(ti_clk),
	.ok1(ok1), .ok2(ok2));

okWireOR # (.N(2)) wireOR (.ok2(ok2), .ok2s(ok2x));

okWireIn     ep00 (.ok1(ok1),                          .ep_addr(8'h00), .ep_dataout(ep00wire));
okWireIn     ep01 (.ok1(ok1),                          .ep_addr(8'h01), .ep_dataout(ep01wire));
okWireIn     ep02 (.ok1(ok1),                          .ep_addr(8'h02), .ep_dataout(ep02wire));

okWireOut    ep20 (.ok1(ok1), .ok2(ok2x[ 0*17 +: 17 ]), .ep_addr(8'h20), .ep_datain(ep20wire));
okWireOut    ep21 (.ok1(ok1), .ok2(ok2x[ 1*17 +: 17 ]), .ep_addr(8'h21), .ep_datain(ep21wire));

endmodule