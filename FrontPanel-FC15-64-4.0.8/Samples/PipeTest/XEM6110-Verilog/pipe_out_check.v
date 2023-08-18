//------------------------------------------------------------------------
// pipe_out_check.v
//
// Generates pseudorandom data for Pipe Out verifications.
//
// Copyright (c) 2010 Opal Kelly Incorporated
//------------------------------------------------------------------------

`default_nettype none

module pipe_out_check(
	input  wire            clk,
	input  wire            reset,
	input  wire            pipe_out_start,
	output reg             pipe_out_write,
	output reg  [63:0]     pipe_out_data,
	input  wire [8:0]      pipe_out_count,
	input  wire            throttle_set,
	input  wire [31:0]     throttle_val,
	input  wire            mode                // 0=Count, 1=LFSR
	);


reg          started;
reg  [31:0]  throttle;


//------------------------------------------------------------------------
// LFSR mode signals
//
// 32-bit: x^32 + x^22 + x^2 + 1
// lfsr_out_reg[0] <= r[31] ^ r[21] ^ r[1]
//------------------------------------------------------------------------
reg [31:0] temp;
always @(posedge clk) begin
	if (reset == 1'b1) begin
		started <= 1'b0;
		throttle <= throttle_val;
		pipe_out_write  <= 1'b0;
		
		if (mode == 1'b1) begin
			pipe_out_data  <= 64'h0D0C0B0A04030201;
		end else begin
			pipe_out_data  <= 64'h0000000100000001;
		end
	end else begin
		pipe_out_write <= 1'b0;

		// The throttle is a circular register.
		// 1 enabled read or write this cycle.
		// 0 disables read or write this cycle.
		// So a single bit (0x00000001) would lead to 1/32 data rate.
		// Similarly 0xAAAAAAAA would lead to 1/2 data rate.
		if (throttle_set == 1'b1) begin
			throttle <= throttle_val;
		end else begin
			throttle <= {throttle[0], throttle[31:1]};
		end
		
		
		if (pipe_out_start == 1'b1) begin
			started <= 1'b1;
		end
		
		// Produce data when there is space available.
		if ((started == 1'b1) && (pipe_out_count < 9'd500)) begin
			pipe_out_write <= throttle[0];
		end
		
		// Cycle the LFSR
		if (pipe_out_write == 1'b1) begin
			if (mode == 1'b1) begin
				temp = pipe_out_data[31:0];
				pipe_out_data[31:0]  <= {temp[30:0], temp[31] ^ temp[21] ^ temp[1]};
				temp = pipe_out_data[63:32];
				pipe_out_data[63:32] <= {temp[30:0], temp[31] ^ temp[21] ^ temp[1]};
			end else begin
				pipe_out_data[31:0]  <= pipe_out_data[31:0]  + 1'b1;
				pipe_out_data[63:32] <= pipe_out_data[63:32] + 1'b1;
			end
		end
	end
end

endmodule
