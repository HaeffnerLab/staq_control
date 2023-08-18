
`timescale 1ns/1ps
`default_nettype none

module ddr2_test
	(
	input  wire          clk,
	input  wire          reset,
	input  wire          writes_en,
	input  wire          reads_en,
	input  wire          phy_init_done,

	input  wire          rd_clk,
	input  wire          rd_en,
	output wire [15:0]   rd_data,

	input  wire          wr_clk,
	input  wire          wr_en,
	input  wire [15:0]   wr_data,

	input  wire          rd_data_valid,
	input  wire [31:0]   rd_data_fifo_out,
	input  wire          app_af_afull,
	input  wire          app_wdf_afull,
	output reg           app_af_wren,
	output reg  [2:0]    app_af_cmd,
	output reg  [30:0]   app_af_addr,
	output reg           app_wdf_wren,
	output wire [31:0]   app_wdf_data,
	output wire [3:0]    app_wdf_mask_data
	);

localparam BURST_LEN      = 4;
localparam BURST_LEN_DIV2 = BURST_LEN/2;

wire        wr_fifo_aempty;
reg         wr_fifo_rden;
wire [35:0] wr_fifo_dout;
wire        rd_fifo_afull;
wire [17:0] rd_fifo_dout;
reg  [30:0] app_af_addr_wr, app_af_addr_rd;
reg  [2:0]  burst_cnt;

reg         write_mode;
reg         read_mode;
reg         reset_d;

wire [8:0]  rd_wr_data_count;
reg  [10:0] reads_queued;
reg  [10:0] rd_fifo_used;


assign app_wdf_mask_data = 4'b0000;
assign app_wdf_data = {wr_fifo_dout[33:18], wr_fifo_dout[15:0]};
assign rd_data = rd_fifo_dout[15:0];

always @(posedge clk) write_mode <= writes_en;
always @(posedge clk) read_mode <= reads_en;
always @(posedge clk) reset_d <= reset;


integer state;
localparam s_idle  = 0,
           s_write1 = 10,
           s_write2 = 11,
           s_write3 = 12,
           s_write4 = 13,
           s_read1 = 20,
           s_read2 = 21;
always @(posedge clk) begin
	if (reset_d) begin
		state           <= s_idle;
		burst_cnt       <= 3'bxxx;

		reads_queued    <= 0;
		rd_fifo_used    <= 0;
		app_af_addr_wr  <= 0;
		app_af_addr_rd  <= 0;
	end else begin
		app_af_wren  <= 1'b0;
		app_wdf_wren <= 1'b0;
		wr_fifo_rden <= 1'b0;


		// We can't use FIFO fullness to throttle our reads due to latency of
		// requesting a read and completing it.  We need to keep track of
		// queued reads so that we don't overflow when those reads complete.
		if (rd_data_valid==0) begin
			if ( {app_af_wren, app_af_cmd} == 4'b1001 ) begin
				reads_queued <= reads_queued + 2;
			end
		end else begin
			if ( {app_af_wren, app_af_cmd} == 4'b1001 ) begin
				reads_queued <= reads_queued + 1;
			end else begin
				reads_queued <= reads_queued - 1;
			end
		end
		rd_fifo_used <= reads_queued + rd_wr_data_count;


		case (state)
			s_idle: begin
				burst_cnt <= BURST_LEN_DIV2 - 1;

				// only start writing when initialization done
				if (phy_init_done==1 && write_mode==1 && wr_fifo_aempty==0) begin
					state <= s_write1;
					wr_fifo_rden <= 1'b1;
				end else if (phy_init_done==1 && read_mode==1 && rd_fifo_used<500) begin
					state <= s_read1;
				end
			end


			s_write1: begin
				state <= s_write2;
				wr_fifo_rden <= 1'b1;
				app_wdf_wren   <= 1'b1;
			end


			s_write2: begin
				app_wdf_wren   <= 1'b1;
				app_af_addr    <= app_af_addr_wr;
				app_af_addr_wr <= app_af_addr_wr + 4;
				app_af_cmd     <= 3'b000;
				app_af_wren    <= 1'b1;

				if (burst_cnt == 3'd0) begin
					state <= s_idle;
				end else begin
					state <= s_write1;
					wr_fifo_rden  <= 1'b1;
					burst_cnt <= burst_cnt - 1;
				end
			end


			s_read1: begin
				if (burst_cnt == 3'd0) begin
					state <= s_idle;
				end else begin
					burst_cnt <= burst_cnt - 1;
				end

				app_af_addr    <= app_af_addr_rd;
				app_af_addr_rd <= app_af_addr_rd + 4;
				app_af_cmd     <= 3'b001;
				app_af_wren    <= 1'b1;
			end
		endcase
	end
end


// wr_fifo_aempty=1 when N <= 3
fifo_18kb_w18_r36 fifo_wr (
	.rst(reset_d),
	.wr_clk(wr_clk), .wr_en(wr_en),
	.din({2'b00, wr_data}),
	.rd_clk(clk), .rd_en(wr_fifo_rden),
	.dout(wr_fifo_dout),
	.prog_empty(wr_fifo_aempty), .prog_empty_thresh(9'd3),
	.empty(), .full()
	);


// rd_fifo_afull=1 when N >= 200
fifo_18kb_w36_r18 fifo_rd (
	.rst(reset_d),
	.wr_clk(clk), .wr_en(rd_data_valid), .wr_data_count(rd_wr_data_count),
	.din({2'b00, rd_data_fifo_out[31:16], 2'b00, rd_data_fifo_out[15:0]}),
	.rd_clk(rd_clk), .rd_en(rd_en),
	.dout(rd_fifo_dout),
	.prog_full(rd_fifo_afull), .prog_full_thresh(9'd200),
	.empty(), .full()
	);


endmodule
