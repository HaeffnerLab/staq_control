//------------------------------------------------------------------------
// pipe_in_check.v
//
// Received data and checks against pseudorandom sequence for Pipe In.
//
// Copyright (c) 2010 Opal Kelly Incorporated
//------------------------------------------------------------------------

`default_nettype none

module pipe_in_check(
	input  wire            clk,
	input  wire            reset,
	output reg             pipe_in_read,
	input  wire [63:0]     pipe_in_data,
	input  wire            pipe_in_valid,
	input  wire            pipe_in_empty,
	input  wire            throttle_set,
	input  wire [31:0]     throttle_val,
	input  wire            mode,               // 0=Count, 1=LFSR
	output reg  [31:0]     error_count
	);


reg  [31:0]  throttle;
reg  [63:0]  lfsr;
reg  [31:0]  temp;


//------------------------------------------------------------------------
// LFSR mode signals
//
// 32-bit: x^32 + x^22 + x^2 + 1
// lfsr_out_reg[0] <= r[31] ^ r[21] ^ r[1]
//------------------------------------------------------------------------
always @(posedge clk) begin
	if (reset == 1'b1) begin
		throttle     <= throttle_val;
		error_count  <= 0;
		pipe_in_read <= 1'b0;
		
		if (mode == 1'b1) begin
			lfsr  <= 64'h0D0C0B0A04030201;
		end else begin
			lfsr  <= 64'h0000000100000001;
		end
	end else begin
		pipe_in_read <= 1'b0;


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
		
		
		// Consume data when there is data available.
		if (pipe_in_empty == 1'b0) begin
			pipe_in_read <= throttle[0];
		end
		
		
		// Check incoming data for validity
		if (pipe_in_valid == 1'b1) begin
			if (pipe_in_data[63:0] != lfsr) begin
				error_count <= error_count + 1'b1;
			end
		end

		// Cycle the LFSR
		if (pipe_in_valid == 1'b1) begin
			if (mode == 1'b1) begin
				temp = lfsr[31:0];
				lfsr[31:0]  <= {temp[30:0], temp[31] ^ temp[21] ^ temp[1]};
				temp = lfsr[63:32];
				lfsr[63:32] <= {temp[30:0], temp[31] ^ temp[21] ^ temp[1]};
			end else begin
				lfsr[31:0]  <= lfsr[31:0]  + 1'b1;
				lfsr[63:32] <= lfsr[63:32] + 1'b1;
			end
		end
	end
end

endmodule
