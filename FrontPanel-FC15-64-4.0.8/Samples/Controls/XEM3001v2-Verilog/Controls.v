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
// zbus[13:0]      -> WireOut 0x2a
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
   input  wire [7:0]  hi_in,
   output wire [1:0]  hi_out,
   inout  wire [15:0] hi_inout,
   
   input  wire        clk1,

   inout  wire [35:0] ybus,
   inout  wire [35:0] xbus,
   inout  wire [13:0] zbus,
   
   output wire [7:0]  led,
   input  wire [3:0]  button
   );

// Target interface bus:
wire        ti_clk;
wire [30:0] ok1;
wire [16:0] ok2;

// Endpoint connections:
wire [15:0]  ep00wire, ep01wire, ep02wire, ep03wire;
wire [15:0]  ep04wire, ep05wire, ep06wire, ep07wire;
wire [15:0]  ep08wire, ep09wire;
wire [15:0]  ep1Fwire;
wire [15:0]  ep40wire;

// Counters:
reg  [31:0] count0;
reg  [31:0] count1;
wire        reset;
wire        countup;
wire        countdown;
wire [7:0]  scnt;
wire        direction;

assign led = ~scnt;
assign {countdown, countup, reset} = ep40wire[2:0];

// direction=0 means drive the xbus.
assign direction = ep1Fwire[0];
assign scnt = count0[30:23];
assign xbus = (direction==1'b0) ? ({scnt[3:0], scnt, scnt, scnt, scnt})
								: (36'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz);
assign ybus = (direction==1'b0) ? ({scnt[3:0], scnt, scnt, scnt, scnt})
								: (36'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz);
assign zbus = (direction==1'b0) ? ({scnt[5:0], scnt})
								: (14'bzzzzzzzzzzzzzz);

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
wire [17*22-1:0]  ok2x;
okHost okHI(
	.hi_in(hi_in), .hi_out(hi_out), .hi_inout(hi_inout), .ti_clk(ti_clk),
	.ok1(ok1), .ok2(ok2));

okWireOR # (.N(22)) wireOR (ok2, ok2x);

okWireIn    ep00 (.ok1(ok1),                           .ep_addr(8'h00), .ep_dataout(ep00wire));
okWireIn    ep01 (.ok1(ok1),                           .ep_addr(8'h01), .ep_dataout(ep01wire));
okWireIn    ep02 (.ok1(ok1),                           .ep_addr(8'h02), .ep_dataout(ep02wire));
okWireIn    ep03 (.ok1(ok1),                           .ep_addr(8'h03), .ep_dataout(ep03wire));
okWireIn    ep04 (.ok1(ok1),                           .ep_addr(8'h04), .ep_dataout(ep04wire));
okWireIn    ep05 (.ok1(ok1),                           .ep_addr(8'h05), .ep_dataout(ep05wire));
okWireIn    ep06 (.ok1(ok1),                           .ep_addr(8'h06), .ep_dataout(ep06wire));
okWireIn    ep07 (.ok1(ok1),                           .ep_addr(8'h07), .ep_dataout(ep07wire));
okWireIn    ep08 (.ok1(ok1),                           .ep_addr(8'h08), .ep_dataout(ep08wire));
okWireIn    ep09 (.ok1(ok1),                           .ep_addr(8'h09), .ep_dataout(ep09wire));
okWireIn    ep1F (.ok1(ok1),                           .ep_addr(8'h1f), .ep_dataout(ep1Fwire));

okTriggerIn ep40 (.ok1(ok1),                           .ep_addr(8'h40), .ep_clk(clk1), .ep_trigger(ep40wire));

okWireOut   ep30 (.ok1(ok1), .ok2(ok2x[ 0*17 +: 17 ]), .ep_addr(8'h30), .ep_datain(ep00wire));
okWireOut   ep31 (.ok1(ok1), .ok2(ok2x[ 1*17 +: 17 ]), .ep_addr(8'h31), .ep_datain(ep01wire));
okWireOut   ep32 (.ok1(ok1), .ok2(ok2x[ 2*17 +: 17 ]), .ep_addr(8'h32), .ep_datain(ep02wire));
okWireOut   ep33 (.ok1(ok1), .ok2(ok2x[ 3*17 +: 17 ]), .ep_addr(8'h33), .ep_datain(ep03wire));
okWireOut   ep34 (.ok1(ok1), .ok2(ok2x[ 4*17 +: 17 ]), .ep_addr(8'h34), .ep_datain(ep04wire));
okWireOut   ep35 (.ok1(ok1), .ok2(ok2x[ 5*17 +: 17 ]), .ep_addr(8'h35), .ep_datain(ep05wire));
okWireOut   ep36 (.ok1(ok1), .ok2(ok2x[ 6*17 +: 17 ]), .ep_addr(8'h36), .ep_datain(ep06wire));
okWireOut   ep37 (.ok1(ok1), .ok2(ok2x[ 7*17 +: 17 ]), .ep_addr(8'h37), .ep_datain(ep07wire));
okWireOut   ep38 (.ok1(ok1), .ok2(ok2x[ 8*17 +: 17 ]), .ep_addr(8'h38), .ep_datain(ep08wire));
okWireOut   ep39 (.ok1(ok1), .ok2(ok2x[ 9*17 +: 17 ]), .ep_addr(8'h39), .ep_datain(ep09wire));

okWireOut   ep20 (.ok1(ok1), .ok2(ok2x[ 10*17 +: 17 ]), .ep_addr(8'h20), .ep_datain(count0[15:0]));
okWireOut   ep21 (.ok1(ok1), .ok2(ok2x[ 11*17 +: 17 ]), .ep_addr(8'h21), .ep_datain(count0[31:16]));
okWireOut   ep22 (.ok1(ok1), .ok2(ok2x[ 12*17 +: 17 ]), .ep_addr(8'h22), .ep_datain(count1[15:0]));
okWireOut   ep23 (.ok1(ok1), .ok2(ok2x[ 13*17 +: 17 ]), .ep_addr(8'h23), .ep_datain(count1[31:16]));
okWireOut   ep24 (.ok1(ok1), .ok2(ok2x[ 14*17 +: 17 ]), .ep_addr(8'h24), .ep_datain(xbus[15:0]));
okWireOut   ep25 (.ok1(ok1), .ok2(ok2x[ 15*17 +: 17 ]), .ep_addr(8'h25), .ep_datain(xbus[31:16]));
okWireOut   ep26 (.ok1(ok1), .ok2(ok2x[ 16*17 +: 17 ]), .ep_addr(8'h26), .ep_datain({12'd0, xbus[35:32]}));
okWireOut   ep27 (.ok1(ok1), .ok2(ok2x[ 17*17 +: 17 ]), .ep_addr(8'h27), .ep_datain(ybus[15:0]));
okWireOut   ep28 (.ok1(ok1), .ok2(ok2x[ 18*17 +: 17 ]), .ep_addr(8'h28), .ep_datain(ybus[31:16]));
okWireOut   ep29 (.ok1(ok1), .ok2(ok2x[ 19*17 +: 17 ]), .ep_addr(8'h29), .ep_datain({12'd0, ybus[35:32]}));
okWireOut   ep2a (.ok1(ok1), .ok2(ok2x[ 20*17 +: 17 ]), .ep_addr(8'h2a), .ep_datain({2'd0, zbus[13:0]}));
okWireOut   ep3a (.ok1(ok1), .ok2(ok2x[ 21*17 +: 17 ]), .ep_addr(8'h3a), .ep_datain({8'd0, ~button, 4'b0010}));

endmodule
