//------------------------------------------------------------------------
// Controls.v
//
// A simple example used to exercise various FrontPanel controls.
//
// This HDL contains two counters and several wired-through wires.
//
// Counter0[15:0]  -> WireOut 0x20
// Counter0[31:16] -> WireOut 0x21
// Counter1[15:0]  -> WireOut 0x22
// Counter1[31:16] -> WireOut 0x23
// xbus[15:0]      -> WireOut 0x24
// xbus[31:16]     -> WireOut 0x25
// xbus[35:32]     -> WireOut 0x26
// ybus[15:0]      -> WireOut 0x27
// ybus[31:16]     -> WireOut 0x28
// ybus[35:32]     -> WireOut 0x29
//
// WireIn 0x00     -> WireOut 0x30
// WireIn 0x01     -> WireOut 0x31
// WireIn 0x02     -> WireOut 0x32
// WireIn 0x03     -> WireOut 0x33
// WireIn 0x04     -> WireOut 0x34
// WireIn 0x05     -> WireOut 0x35
// WireIn 0x06     -> WireOut 0x36
// WireIn 0x07     -> WireOut 0x37
// WireIn 0x08     -> WireOut 0x38
// WireIn 0x09     -> WireOut 0x39
//
// WireIn 0x1F     -> {x, x, x, x, x, x, x, direction}
//
// ~Buttons, 0010  -> WireOut 0x3A
//
// TriggerIn 40 -> {x, x, x, x, x, countdown, countup, reset}
//
// Copyright (c) 2004-2006 Opal Kelly Incorporated
//------------------------------------------------------------------------

`default_nettype none

module Controls(
	input  wire [28:0]         okGH,
	output wire [27:0]         okHG,
	inout  wire                okAA,
	inout  wire [28:0] xbusp,
	inout  wire [28:0] xbusn,
	inout  wire [28:0] ybusp,
	inout  wire [28:0] ybusn,
	
	input  wire                sys_clkp,    
	input  wire                sys_clkn,     
	output wire [7:0]          led,
	output wire                init
	);

function [7:0] xem6110_led;
input [7:0] a;
integer i;
begin
	for (i=0; i<8; i=i+1) begin : u
		xem6110_led[i] = (a[i]==1'b1) ? (1'b0) : (1'bz);
	end
end
endfunction

// Target interface bus:
wire         ti_clk;
wire [46:0]  okHE;
wire [32:0]  okEH;
wire [43:0]  okHEO;
wire [102:0] okEHO;
wire [99:0]  okHEI;
wire [37:0]  okEHI;

wire clk1;
IBUFGDS #(.IOSTANDARD("LVDS_25")) osc_clk(.O(clk1), .I(sys_clkp), .IB(sys_clkn));

// Endpoint connections:
wire [31:0]  ep00wire, ep01wire, ep02wire, ep03wire;
wire [31:0]  ep04wire, ep05wire, ep06wire, ep07wire;
wire [31:0]  ep08wire, ep09wire;
wire [31:0]  ep1Fwire;
wire [31:0]  ep40wire;

// Counters:
reg  [31:0] count0;
reg  [31:0] count1;
wire        reset;
wire        countup;
wire        countdown;
wire [7:0]  scnt;
wire        direction;
wire [35:0] xbus;
wire [35:0] ybus;

assign init = 1'b1;
assign led        = xem6110_led(scnt);
assign {countdown, countup, reset} = ep40wire[2:0];
assign {xbusp,xbusn[6:0]} = xbus;
assign {ybusp,ybusn[6:0]} = ybus;

// direction=0 means drive the xbus.
assign direction = ep1Fwire[0];
assign scnt = count0[30:23];
assign xbus = (direction==1'b0) ? ({scnt[3:0], scnt, scnt, scnt, scnt})
								: (36'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz);
assign ybus = (direction==1'b0) ? ({scnt[3:0], scnt, scnt, scnt, scnt})
								: (36'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz);

// Counter0 - Always running.
always @(posedge clk1) begin
   count0 <= count0 + 1;
end

// Counter1 - Up/Down triggered counter.
always @(posedge clk1) begin
	if (reset == 1'b1) begin
		count1 <= 32'd0;
	end else if (countup == 1'b1) begin
		count1 <= count1 + 1;
	end else if (countdown == 1'b1) begin
		count1 <= count1 - 1;
	end
end


// Instantiate the okHost and connect endpoints.

okHost host (
	.okGH(okGH),
	.okHG(okHG),
	.okAA(okAA),
	.okHE(okHE),
	.okEH(okEH),
	.okHEO(okHEO),
	.okEHO(okEHO),
	.okHEI(okHEI),
	.okEHI(okEHI),
	.ti_clk(ti_clk)
	);

wire [33*21-1:0]  okEHx;
okWireOR # (.N(21)) wireOR (okEH, okEHx);

okWireIn    ep00 (.ok1(okHE),                           .ep_addr(8'h00), .ep_dataout(ep00wire));
okWireIn    ep01 (.ok1(okHE),                           .ep_addr(8'h01), .ep_dataout(ep01wire));
okWireIn    ep02 (.ok1(okHE),                           .ep_addr(8'h02), .ep_dataout(ep02wire));
okWireIn    ep03 (.ok1(okHE),                           .ep_addr(8'h03), .ep_dataout(ep03wire));
okWireIn    ep04 (.ok1(okHE),                           .ep_addr(8'h04), .ep_dataout(ep04wire));
okWireIn    ep05 (.ok1(okHE),                           .ep_addr(8'h05), .ep_dataout(ep05wire));
okWireIn    ep06 (.ok1(okHE),                           .ep_addr(8'h06), .ep_dataout(ep06wire));
okWireIn    ep07 (.ok1(okHE),                           .ep_addr(8'h07), .ep_dataout(ep07wire));
okWireIn    ep08 (.ok1(okHE),                           .ep_addr(8'h08), .ep_dataout(ep08wire));
okWireIn    ep09 (.ok1(okHE),                           .ep_addr(8'h09), .ep_dataout(ep09wire));
okWireIn    ep1F (.ok1(okHE),                           .ep_addr(8'h1f), .ep_dataout(ep1Fwire));

okTriggerIn ep40 (.ok1(okHE),                           .ep_addr(8'h40), .ep_clk(clk1), .ep_trigger(ep40wire));

okWireOut   ep30 (.ok1(okHE), .ok2(okEHx[ 0*33 +: 33 ]), .ep_addr(8'h30), .ep_datain(ep00wire));
okWireOut   ep31 (.ok1(okHE), .ok2(okEHx[ 1*33 +: 33 ]), .ep_addr(8'h31), .ep_datain(ep01wire));
okWireOut   ep32 (.ok1(okHE), .ok2(okEHx[ 2*33 +: 33 ]), .ep_addr(8'h32), .ep_datain(ep02wire));
okWireOut   ep33 (.ok1(okHE), .ok2(okEHx[ 3*33 +: 33 ]), .ep_addr(8'h33), .ep_datain(ep03wire));
okWireOut   ep34 (.ok1(okHE), .ok2(okEHx[ 4*33 +: 33 ]), .ep_addr(8'h34), .ep_datain(ep04wire));
okWireOut   ep35 (.ok1(okHE), .ok2(okEHx[ 5*33 +: 33 ]), .ep_addr(8'h35), .ep_datain(ep05wire));
okWireOut   ep36 (.ok1(okHE), .ok2(okEHx[ 6*33 +: 33 ]), .ep_addr(8'h36), .ep_datain(ep06wire));
okWireOut   ep37 (.ok1(okHE), .ok2(okEHx[ 7*33 +: 33 ]), .ep_addr(8'h37), .ep_datain(ep07wire));
okWireOut   ep38 (.ok1(okHE), .ok2(okEHx[ 8*33 +: 33 ]), .ep_addr(8'h38), .ep_datain(ep08wire));
okWireOut   ep39 (.ok1(okHE), .ok2(okEHx[ 9*33 +: 33 ]), .ep_addr(8'h39), .ep_datain(ep09wire));

okWireOut   ep20 (.ok1(okHE), .ok2(okEHx[ 10*33 +: 33 ]), .ep_addr(8'h20), .ep_datain({16'b0, count0[15:0]}));
okWireOut   ep21 (.ok1(okHE), .ok2(okEHx[ 11*33 +: 33 ]), .ep_addr(8'h21), .ep_datain({16'b0, count0[31:16]}));
okWireOut   ep22 (.ok1(okHE), .ok2(okEHx[ 12*33 +: 33 ]), .ep_addr(8'h22), .ep_datain({16'b0, count1[15:0]}));
okWireOut   ep23 (.ok1(okHE), .ok2(okEHx[ 13*33 +: 33 ]), .ep_addr(8'h23), .ep_datain({16'b0, count1[31:16]}));
okWireOut   ep24 (.ok1(okHE), .ok2(okEHx[ 14*33 +: 33 ]), .ep_addr(8'h24), .ep_datain({16'b0, xbus[15:0]}));
okWireOut   ep25 (.ok1(okHE), .ok2(okEHx[ 15*33 +: 33 ]), .ep_addr(8'h25), .ep_datain({16'b0, xbus[31:16]}));
okWireOut   ep26 (.ok1(okHE), .ok2(okEHx[ 16*33 +: 33 ]), .ep_addr(8'h26), .ep_datain({16'b0, 12'd0, xbus[35:32]}));
okWireOut   ep27 (.ok1(okHE), .ok2(okEHx[ 17*33 +: 33 ]), .ep_addr(8'h27), .ep_datain({16'b0, ybus[15:0]}));
okWireOut   ep28 (.ok1(okHE), .ok2(okEHx[ 18*33 +: 33 ]), .ep_addr(8'h28), .ep_datain({16'b0, ybus[31:16]}));
okWireOut   ep29 (.ok1(okHE), .ok2(okEHx[ 19*33 +: 33 ]), .ep_addr(8'h29), .ep_datain({16'b0, 12'd0, ybus[35:32]}));

endmodule
