//------------------------------------------------------------------------
// PipeTest.v
//
// Copyright (c) 2010 Opal Kelly Incorporated
//------------------------------------------------------------------------

`default_nettype none

module PipeTest(
	input  wire [28:0]         okGH,
	output wire [27:0]         okHG,
	inout  wire                okAA,
	input  wire                sys_clkp,       // Running at 100 MHz
	input  wire                sys_clkn,       // Running at 100 MHz
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

wire sys_clk;
IBUFGDS #(.IOSTANDARD("LVDS_25")) osc_clk(.O(sys_clk), .I(sys_clkp), .IB(sys_clkn));

wire         ti_clk;
wire [46:0]  okHE;
wire [32:0]  okEH;
wire [43:0]  okHEO;
wire [102:0] okEHO;
wire [99:0]  okHEI;
wire [37:0]  okEHI;


wire [31:0]  rcv_errors;

// Endpoint connections:
wire [31:0]  ep00wire;
wire [31:0]  ep01wire;
wire [31:0]  ep02wire;
wire [31:0]  ep20wire;
reg          reset_sysclk;

assign ep20wire   = {32'd0};
assign led        = xem6110_led(rcv_errors[7:0]);
always @(posedge sys_clk) reset_sysclk <= ep00wire[2];


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


wire        pipe_in_read;
wire [63:0] pipe_in_data;
wire        pipe_in_valid;
wire        pipe_in_empty;
wire        pipe_in_start;
wire        pipe_in_done;
okPipeIn pi0 (.okHEI               (okHEI),
              .okEHI               (okEHI),
              .ep_clk              (sys_clk),
              .ep_start            (pipe_in_start),
              .ep_done             (pipe_in_done),
              .ep_fifo_reset       (pipe_in_start),
              .ep_read             (pipe_in_read),
              .ep_data             (pipe_in_data),
              .ep_count            (),
              .ep_valid            (pipe_in_valid),
              .ep_empty            (pipe_in_empty)
              );
pipe_in_check pic0 (.clk           (sys_clk),
                    .reset         (reset_sysclk),
                    .pipe_in_read  (pipe_in_read),
                    .pipe_in_data  (pipe_in_data),
                    .pipe_in_valid (pipe_in_valid),
                    .pipe_in_empty (pipe_in_empty),
                    .throttle_set  (ep00wire[5]),
                    .throttle_val  (ep02wire[31:0]),
                    .mode          (ep00wire[4]),
                    .error_count   (rcv_errors)
                    );


wire        pipe_out_start;
wire        pipe_out_write;
wire [63:0] pipe_out_data;
wire [8:0]  pipe_out_count;
okPipeOut po0 (.okHEO           (okHEO),
               .okEHO           (okEHO),
               .ep_clk          (sys_clk),
               .ep_start        (pipe_out_start),
               .ep_done         (),
               .ep_fifo_reset   (ep00wire[2]),
               .ep_write        (pipe_out_write),
               .ep_data         (pipe_out_data),
               .ep_count        (pipe_out_count),
               .ep_full         ()
               );
pipe_out_check poc0 (.clk            (sys_clk),
                     .reset          (reset_sysclk),
                     .pipe_out_start (pipe_out_start),
                     .pipe_out_write (pipe_out_write),
                     .pipe_out_data  (pipe_out_data),
                     .pipe_out_count (pipe_out_count),
                     .throttle_set   (ep00wire[5]),
                     .throttle_val   (ep01wire[31:0]),
                     .mode           (ep00wire[4])
                     );

wire [33*2-1:0]  okEHx;
okWireOR # (.N(2)) wireOR (okEH, okEHx);
okWireIn     wi00(.ok1(okHE),                             .ep_addr(8'h00), .ep_dataout(ep00wire));
okWireIn     wi01(.ok1(okHE),                             .ep_addr(8'h01), .ep_dataout(ep01wire));
okWireIn     wi02(.ok1(okHE),                             .ep_addr(8'h02), .ep_dataout(ep02wire));
okWireOut    wo20(.ok1(okHE), .ok2(okEHx[ 0*33 +: 33 ]),  .ep_addr(8'h20), .ep_datain(ep20wire));
okWireOut    wo21(.ok1(okHE), .ok2(okEHx[ 1*33 +: 33 ]),  .ep_addr(8'h21), .ep_datain(rcv_errors));

endmodule
