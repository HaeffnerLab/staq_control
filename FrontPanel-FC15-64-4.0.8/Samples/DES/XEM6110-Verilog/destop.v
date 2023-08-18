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
// Copyright (c) 2005-2009  Opal Kelly Incorporated
// $Rev$ $Date$
//------------------------------------------------------------------------
`default_nettype none
`timescale 1ns / 1ps

module destop(
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
wire [43:0]  okHEO;
wire [102:0] okEHO;
wire [99:0]  okHEI;
wire [37:0]  okEHI;

wire clk1;
IBUFGDS #(.IOSTANDARD("LVDS_25")) osc_clk(.O(clk1), .I(sys_clkp), .IB(sys_clkn));

wire [63:0] des_out;
reg  [63:0] des_in;
wire [63:0] des_key;
wire [55:0] des_keyshort;
wire        des_decrypt;
reg  [3:0]  des_roundSel;
reg  [63:0] des_result;

wire [31:0] WireIn10;
wire [31:0] TrigIn40;
wire [31:0] TrigIn41;
wire [31:0] TrigOut60;

reg         pipe_in_read;
wire [63:0] pipe_in_data;
wire        pipe_in_valid;
wire        pipe_in_empty;
wire        pipe_in_start;
wire        pipe_in_done;

reg         pipe_out_write;
reg  [63:0] pipe_out_data;


wire        start;
wire        reset;
wire        ram_reset;
reg         done;

assign init = 1'b1;

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
// on a PipeIn FIFO. When complete, it asserts DONE for a single cycle.
parameter s_idle = 0,
          s_loadinput1 = 10,
          s_loadinput2 = 11,
          s_dodes1 = 20,
          s_saveoutput1 = 30,
          s_saveoutput2 = 31,
          s_saveoutput3 = 32,
          s_empty = 40,
          s_done = 50;
integer state;

always @(posedge clk1) begin
	if (reset == 1'b1) begin
		done <= 1'b0;
		state <= s_idle;
	end else begin
		done <= 1'b0;
		pipe_out_write <= 1'b0;
		pipe_in_read <= 1'b0;
		
		case (state)
			s_idle: begin
				if (start == 1'b1) begin
					state <= s_loadinput1;
					pipe_in_read <= 1'b1;
				end
			end
		
			s_loadinput1: begin
				if (pipe_in_valid == 1'b1) begin
					state <= s_dodes1;
					des_in <= pipe_in_data;
					des_roundSel <= 4'd0;
				end
				else begin
					state <= s_loadinput1;
				end
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
				state <= s_empty;
				pipe_out_data <= des_result;
				pipe_out_write <= 1'b1;
			end
			
			s_empty: begin
				if (pipe_in_empty == 1'b1)
					state <= s_done;
				else begin
					state <= s_loadinput1;
					pipe_in_read <= 1'b1;
				end
			end
		
			s_done: begin
				state <= s_idle;
				done <= 1'b1;
			end
		endcase
	end
end

// Instantiate the OpenCores.org DES module.
des desModule(
		.clk(clk1), .roundSel(des_roundSel),
		.desOut(des_out), .desIn(des_in),
		.key(des_keyshort), .decrypt(des_decrypt));

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

wire [15:0] msb0, msb1, msb2, msb3;
wire [33*1-1:0]  okEHx;
okWireOR # (.N(1)) wireOR (okEH, okEHx);

okWireIn     ep08 (.ok1(okHE),                             .ep_addr(8'h08), .ep_dataout({msb0, des_key[15:0]}));
okWireIn     ep09 (.ok1(okHE),                             .ep_addr(8'h09), .ep_dataout({msb1, des_key[31:16]}));
okWireIn     ep0A (.ok1(okHE),                             .ep_addr(8'h0a), .ep_dataout({msb2, des_key[47:32]}));
okWireIn     ep0B (.ok1(okHE),                             .ep_addr(8'h0b), .ep_dataout({msb3, des_key[63:48]}));
okWireIn     ep10 (.ok1(okHE),                             .ep_addr(8'h10), .ep_dataout(WireIn10));
okTriggerIn  ep40 (.ok1(okHE),                             .ep_addr(8'h40), .ep_clk(clk1), .ep_trigger(TrigIn40));
okTriggerIn  ep41 (.ok1(okHE),                             .ep_addr(8'h41), .ep_clk(ti_clk), .ep_trigger(TrigIn41));
okTriggerOut ep60 (.ok1(okHE), .ok2(okEHx[ 0*33  +: 33 ]), .ep_addr(8'h60), .ep_clk(clk1), .ep_trigger(TrigOut60));
okPipeIn ep80 (.okHEI               (okHEI),
               .okEHI               (okEHI),
               .ep_clk              (clk1),
               .ep_start            (pipe_in_start),
               .ep_done             (pipe_in_done),
               .ep_fifo_reset       (pipe_in_start),
               .ep_read             (pipe_in_read),
               .ep_data             (pipe_in_data),
               .ep_count            (),
               .ep_valid            (pipe_in_valid),
               .ep_empty            (pipe_in_empty)
               );
okPipeOut epA0 (.okHEO           (okHEO),
                .okEHO           (okEHO),
                .ep_clk          (clk1),
                .ep_start        (),
                .ep_done         (),
                .ep_fifo_reset   (pipe_in_done),
                .ep_write        (pipe_out_write),
                .ep_data         (pipe_out_data),
                .ep_count        (),
                .ep_full         ()
               );
endmodule
