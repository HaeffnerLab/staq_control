//------------------------------------------------------------------------
// first.v
//
// The 'first' sample for the XEM6110.
//
// Copyright (c) 2010 Opal Kelly Incorporated
//------------------------------------------------------------------------

`default_nettype none

module First(
	input  wire [28:0]         okGH,
	output wire [27:0]         okHG,
	inout  wire                okAA,
	output wire [7:0]          led
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

wire         ti_clk;
wire [46:0]  okHE;
wire [32:0]  okEH;

// Endpoint connections:
wire [31:0]  ep00wire, ep01wire, ep02wire;
wire [31:0]  ep20wire, ep21wire;

assign ep20wire = {32'h0};
assign ep21wire = ep01wire + ep02wire;
assign led      = xem6110_led(ep00wire[7:0]);

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

wire [33*2-1:0]  okEHx;
okWireOR # (.N(2)) wireOR (okEH, okEHx);
okWireIn     wi00(.ok1(okHE),                             .ep_addr(8'h00), .ep_dataout(ep00wire));
okWireIn     wi01(.ok1(okHE),                             .ep_addr(8'h01), .ep_dataout(ep01wire));
okWireIn     wi02(.ok1(okHE),                             .ep_addr(8'h02), .ep_dataout(ep02wire));
okWireOut    wo20(.ok1(okHE), .ok2(okEHx[ 0*33  +: 33 ]), .ep_addr(8'h20), .ep_datain(ep20wire));
okWireOut    wo21(.ok1(okHE), .ok2(okEHx[ 1*33  +: 33 ]), .ep_addr(8'h21), .ep_datain(ep21wire));

endmodule
