//------------------------------------------------------------------------
// Counters.v
//
// HDL for the counters sample.  This HDL describes two counters operating
// on different board clocks and with slightly different functionality.
// The counter controls and counter values are connected to endpoints so
// that FrontPanel may control and observe them.
//
// Copyright (c) 2005-2011
// Opal Kelly Incorporated
//------------------------------------------------------------------------

`default_nettype none

module Counters(
	input  wire [28:0]         okGH,
	output wire [27:0]         okHG,
	inout  wire                okAA,
	input  wire                sys_clkp,       // Running at 100 Mhz (for the SDRAM)
	input  wire                sys_clkn,       // Running at 100 Mhz (for the SDRAM)
	output wire [7:0]          led,
	output wire                init
	);

wire         ti_clk;
wire [46:0]  okHE;
wire [32:0]  okEH;

// Endpoint connections:
wire [31:0]  ep00wire;
wire [31:0]  ep20wire, ep21wire, ep22wire;
wire [31:0]  ep40wire;
wire [31:0]  ep60trig, ep61trig;

assign init = 1'b1;
wire clk1;
IBUFGDS #(.IOSTANDARD("LVDS_25")) osc_clk(.O(clk1), .I(sys_clkp), .IB(sys_clkn));

function [7:0] xem6110_led;
input [7:0] a;
integer i;
begin
	for (i=0; i<8; i=i+1) begin : u
		xem6110_led[i] = (a[i]==1'b1) ? (1'b0) : (1'bz);
	end
end
endfunction

// Counter 1:
reg  [23:0] div1;
reg         clk1div;
reg  [7:0]  count1;
reg         count1eq00;
reg         count1eq80;
wire        reset1;
wire        disable1;

// Counter 2:
wire        clk2 = ti_clk;
reg  [23:0] div2;
reg         clk2div;
reg  [7:0]  count2;
reg         count2eqFF;
wire        reset2;
wire        up2;
wire        down2;
wire        autocount2;

assign reset1     = ep00wire[0];
assign disable1   = ep00wire[1];
assign autocount2 = ep00wire[2];
assign ep20wire   = {8'd0, count1};
assign ep21wire   = {8'd0, count2};
assign ep22wire   = {16'h0000};
assign reset2     = ep40wire[0];
assign up2        = ep40wire[1];
assign down2      = ep40wire[2];
assign ep60trig   = {14'b000000, count1eq80, count1eq00};
assign ep61trig   = {15'b0000000, count2eqFF};
assign led        = xem6110_led(count1);

// Counter #1
// + Counting using a divided CLK1.
// + Reset sets the counter to 0.
// + Disable turns off the counter.
always @(posedge clk1) begin
	div1 <= div1 - 1;
	if (div1 == 24'h000000) begin
		div1 <= 24'h400000;
		clk1div <= 1'b1;
	end else begin
		clk1div <= 1'b0;
	end
   
	if (clk1div == 1'b1) begin
		if (reset1 == 1'b1)
			count1 <= 8'h00;
		else if (disable1 == 1'b0)
			count1 <= count1 + 1;
		end
   
		if (count1 == 8'h00)
			count1eq00 <= 1'b1;
		else
			count1eq00 <= 1'b0;

		if (count1 == 8'h80)
			count1eq80 <= 1'b1;
		else
			count1eq80 <= 1'b0;
end


// Counter #2
// + Reset, up, and down control counter.
// + If autocount is enabled, a divided clk2 can also
//   upcount.
always @(posedge clk2) begin
	div2 <= div2 - 1;
	if (div2 == 24'h000000) begin
		div2 <= 24'h100000;
		clk2div <= 1'b1;
	end else begin
		clk2div <= 1'b0;
	end
   
	if (reset2 == 1'b1)
		count2 <= 8'h00;
	else if (up2 == 1'b1)
		count2 <= count2 + 1;
	else if (down2 == 1'b1)
		count2 <= count2 - 1;
	else if ((autocount2 == 1'b1) && (clk2div == 1'b1))
		count2 <= count2 + 1;

	if (count2 == 8'hff)
		count2eqFF <= 1'b1;
	else
		count2eqFF <= 1'b0;
end


// Instantiate the okHost and connect endpoints.
okHost host (
	.okGH(okGH),
	.okHG(okHG),
	.okAA(okAA),
	.okHE(okHE),
	.okEH(okEH),
	.okHEO(),
	.okEHO(103'b0),
	.okHEI(),
	.okEHI(38'b0),
	.ti_clk(ti_clk)
	);

wire [33*5-1:0]  okEHx;
okWireOR # (.N(5)) wireOR (okEH, okEHx);
okWireIn     wi00(.ok1(okHE),                             .ep_addr(8'h00), .ep_dataout(ep00wire));
okWireOut    wo20(.ok1(okHE), .ok2(okEHx[ 0*33  +: 33 ]), .ep_addr(8'h20), .ep_datain(ep20wire));
okWireOut    wo21(.ok1(okHE), .ok2(okEHx[ 1*33  +: 33 ]), .ep_addr(8'h21), .ep_datain(ep21wire));
okWireOut    wo22(.ok1(okHE), .ok2(okEHx[ 2*33  +: 33 ]), .ep_addr(8'h22), .ep_datain(ep22wire));
okTriggerIn  ti40(.ok1(okHE),                             .ep_addr(8'h40), .ep_clk(clk2), .ep_trigger(ep40wire));
okTriggerOut to60(.ok1(okHE), .ok2(okEHx[ 3*33 +: 33 ]),  .ep_addr(8'h60), .ep_clk(clk1), .ep_trigger(ep60trig));
okTriggerOut to61(.ok1(okHE), .ok2(okEHx[ 4*33 +: 33 ]),  .ep_addr(8'h61), .ep_clk(clk2), .ep_trigger(ep61trig));

endmodule