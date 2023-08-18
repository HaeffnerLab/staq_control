//------------------------------------------------------------------------
// destop.v
//
// Verilog source for the toplevel OpenCores.org DES tutorial.
// This source includes an instantiation of the DES module, hooks to 
// the FrontPanel host interface, as well as a short behavioral 
// description of the DES stepping to complete an encrypt/decrypt
// process.  This part includes PipeIn / PipeOut interfaces to allow block
// encryption and decryption.
//
// There are two block RAMs instantiated, one for the input side and
// one for the output side.  Each one is configured as 18-bits on 
// one port and 36-bits on the other port.  The parity bits are not 
// used.
//
// INPUT RAM: The 18-bit port is connected to the PipeIn.  Data is 
// written directly from the pipe to the RAM.  The 36-bit port is
// connected to the state machine and sources the 64-bit input to 
// the DES algorithm.
//
// OUTPUT RAM: The 36-bit port is connected to the state machine and
// is the destination for the 64-bit result from the DES algorithm.
// The 18-bit port is connected to the PipeOut.  Data is read directly
// from this RAM by the pipe.
//
// Copyright (c) 2005-2009  Opal Kelly Incorporated
// $Rev$ $Date$
//------------------------------------------------------------------------
`default_nettype none
`timescale 1ns / 1ps

module destop(
	input  wire [7:0]  hi_in,
	output wire [1:0]  hi_out,
	inout  wire [15:0] hi_inout,
   
	output wire        hi_muxsel,
   
	input  wire        clk1,
	output wire [7:0]  led
	);


wire        ti_clk;
wire [30:0] ok1;
wire [16:0] ok2;

wire [63:0] des_out;
reg  [63:0] des_in;
wire [63:0] des_key;
wire [55:0] des_keyshort;
wire        des_decrypt;
reg  [3:0]  des_roundSel;
reg  [63:0] des_result;
wire [15:0] WireIn10;
wire [15:0] TrigIn40;
wire [15:0] TrigIn41;
wire [15:0] TrigOut60;
wire        pipeI_write;
wire        pipeO_read;
wire [15:0] pipeI_data;
wire [15:0] pipeO_data;
wire        start;
wire        reset;
wire        ram_reset;
reg         done;

reg  [9:0]  ramI_addrA;
reg  [8:0]  ramI_addrB;
reg  [9:0]  ramO_addrA;
reg  [8:0]  ramO_addrB;
reg         ramO_write;
wire [31:0] ramI_dout;
reg  [31:0] ramO_din;

assign hi_muxsel    = 1'b0;
assign led          = ~{4'd0, des_roundSel[3:0]};
assign reset        = WireIn10[0];
assign des_decrypt  = WireIn10[4];
assign start        = TrigIn40[0];
assign ram_reset    = TrigIn41[0];
assign TrigOut60[0] = done;

// Remove KEY parity bits.
assign des_keyshort = {des_key[63:57], des_key[55:49],
                       des_key[47:41], des_key[39:33],
                       des_key[31:25], des_key[23:17],
                       des_key[15:9],  des_key[7:1]};


// Block DES state machine.
//
// This machine is triggered to perform the DES encrypt/decrypt algorithm
// on a full block RAM.  Upon triggering, it performs the DES algorithm
// on 64-bit sections for the entire 2048-byte block RAM.  When complete,
// it asserts DONE for a single cycle.
parameter s_idle = 0,
          s_loadinput1 = 10,
          s_loadinput2 = 11,
          s_loadinput3 = 12,
          s_dodes1 = 20,
          s_saveoutput1 = 30,
          s_saveoutput2 = 31,
          s_saveoutput3 = 32,
          s_done = 40;
integer state;

always @(posedge clk1) begin
	if (reset == 1'b1) begin
		done <= 1'b0;
		state <= s_idle;
	end else begin
		done <= 1'b0;
		ramO_write <= 1'b0;
		
		case (state)
			s_idle: begin
				if (start == 1'b1) begin
					state <= s_loadinput1;
					ramI_addrB <= 9'd0;
					ramO_addrB <= 9'd0;
				end
			end
		
			s_loadinput1: begin
				state <= s_loadinput2;
				ramI_addrB <= ramI_addrB + 1;
			end
			
			s_loadinput2: begin
				state <= s_loadinput3;
				des_in[31:0] <= ramI_dout;
				ramI_addrB <= ramI_addrB + 1;
			end
		
			s_loadinput3: begin
				state <= s_dodes1;
				des_in[63:32] <= ramI_dout;
				des_roundSel <= 4'd0;
			end

			s_dodes1: begin
				state <= s_dodes1;
				des_roundSel <= des_roundSel + 1;
				if (des_roundSel == 4'd15) begin
					des_result <= des_out;
					state <= s_saveoutput1;
				end
			end
		
			s_saveoutput1: begin
				state <= s_saveoutput2;
				ramO_din <= des_result[31:0];
				ramO_write <= 1'b1;
			end
		
			s_saveoutput2: begin
				state <= s_saveoutput3;
				ramO_din <= des_result[63:32];
				ramO_write <= 1'b1;
				ramO_addrB <= ramO_addrB + 1;
			end
			
			s_saveoutput3: begin
				ramO_addrB <= ramO_addrB + 1;
				if (ramI_addrB == 11'd0)
					state <= s_done;
				else
					state <= s_loadinput1;
			end
		
			s_done: begin
				state <= s_idle;
				done <= 1'b1;
			end
		endcase
	end
end


// Pipe <--> RAM addressing
//
// The PipeIn and PipeOut are connected directly to one port of each
// block RAM.  The only thing we need to take care of is the address
// pointers.  They are reset on RAM_RESET (a TriggerIn) and incremented
// on write and read operations, respectively.
always @(posedge ti_clk) begin
	if (ram_reset == 1'b1) begin
		ramI_addrA <= 10'd0;
		ramO_addrA <= 10'd0;
	end else begin
		if (pipeI_write == 1'b1)
			ramI_addrA <= ramI_addrA + 1;

		if (pipeO_read == 1'b1)
			ramO_addrA <= ramO_addrA + 1;
	end
end


// Instantiate the input block RAM
RAMB16_S18_S36 ram_I(.CLKA(ti_clk), .SSRA(reset), .ENA(1'b1),
                     .WEA(pipeI_write), .ADDRA(ramI_addrA),
                     .DIA(pipeI_data), .DIPA(2'b0), .DOA(), .DOPA(),
                     .CLKB(clk1), .SSRB(reset), .ENB(1'b1),
                     .WEB(1'b0), .ADDRB(ramI_addrB),
                     .DIB(32'b0), .DIPB(4'b0), .DOB(ramI_dout), .DOPB());

// Instantiate the output block RAM
RAMB16_S18_S36 ram_O(.CLKA(ti_clk), .SSRA(reset), .ENA(1'b1),
                     .WEA(1'b0), .ADDRA(ramO_addrA),
                     .DIA(16'b0), .DIPA(2'b0), .DOA(pipeO_data), .DOPA(),
                     .CLKB(clk1), .SSRB(reset), .ENB(1'b1),
                     .WEB(ramO_write), .ADDRB(ramO_addrB),
                     .DIB(ramO_din), .DIPB(4'b0), .DOB(), .DOPB());

// Instantiate the OpenCores.org DES module.
des desModule(
	.clk(clk1), .roundSel(des_roundSel),
	.desOut(des_out), .desIn(des_in),
	.key(des_keyshort), .decrypt(des_decrypt));

// Instantiate the okHost and connect endpoints.
wire [17*3-1:0]  ok2x;

okHost okHI(
	.hi_in(hi_in), .hi_out(hi_out), .hi_inout(hi_inout), .ti_clk(ti_clk),
	.ok1(ok1), .ok2(ok2));

okWireOR # (.N(3)) wireOR (ok2, ok2x);

okWireIn     ep08 (.ok1(ok1),                           .ep_addr(8'h08), .ep_dataout(des_key[15:0]));
okWireIn     ep09 (.ok1(ok1),                           .ep_addr(8'h09), .ep_dataout(des_key[31:16]));
okWireIn     ep0A (.ok1(ok1),                           .ep_addr(8'h0a), .ep_dataout(des_key[47:32]));
okWireIn     ep0B (.ok1(ok1),                           .ep_addr(8'h0b), .ep_dataout(des_key[63:48]));
okWireIn     ep10 (.ok1(ok1),                           .ep_addr(8'h10), .ep_dataout(WireIn10));
okTriggerIn  ep40 (.ok1(ok1),                           .ep_addr(8'h40), .ep_clk(clk1), .ep_trigger(TrigIn40));
okTriggerIn  ep41 (.ok1(ok1),                           .ep_addr(8'h41), .ep_clk(ti_clk), .ep_trigger(TrigIn41));
okTriggerOut ep60 (.ok1(ok1), .ok2(ok2x[ 0*17 +: 17 ]), .ep_addr(8'h60), .ep_clk(clk1), .ep_trigger(TrigOut60));
okPipeIn     ep80 (.ok1(ok1), .ok2(ok2x[ 1*17 +: 17 ]), .ep_addr(8'h80), .ep_write(pipeI_write), .ep_dataout(pipeI_data));
okPipeOut    epA0 (.ok1(ok1), .ok2(ok2x[ 2*17 +: 17 ]), .ep_addr(8'ha0), .ep_read(pipeO_read), .ep_datain(pipeO_data));

endmodule
