//------------------------------------------------------------------------
// ramtest.v
//
// This sample uses the Xilinx MIG DDR2 controller and HDL to move data
// from the PC to the DDR2 and vice-versa.
//
// Host Interface registers:
// WireIn 0x00
//     0 - DDR2 read enable (0=disabled, 1=enabled)
//     1 - DDR2 write enable (0=disabled, 1=enabled)
//     2 - Reset
//     3 - Reset tests
//
// PipeIn 0x80 - DDR2 write port (U15, DDR2 "A")
// PipeIn 0x81 - DDR2 write port (U14, DDR2 "B")
// PipeOut 0xA0 - DDR2 read port (U15, DDR2 "A")
// PipeOut 0xA1 - DDR2 read port (U14, DDR2 "B")
//
// This sample is included for reference only.  No guarantees, either 
// expressed or implied, are to be drawn.
//------------------------------------------------------------------------
// tabstop 3
// Copyright (c) 2005-2009 Opal Kelly Incorporated
// $Rev: 303 $ $Date: 2007-05-16 19:13:24 -0700 (Wed, 16 May 2007) $
//------------------------------------------------------------------------


`default_nettype none
`timescale 1ns / 1ps
module ramtest #
	(
	parameter BANK_WIDTH              = 3,       // # of memory bank addr bits
	parameter CKE_WIDTH               = 1,       // # of memory clock enable outputs
	parameter CLK_WIDTH               = 1,       // # of clock outputs
	parameter COL_WIDTH               = 10,      // # of memory column bits
	parameter CS_NUM                  = 1,       // # of separate memory chip selects
	parameter CS_WIDTH                = 1,       // # of total memory chip selects
	parameter CS_BITS                 = 0,       // set to log2(CS_NUM) (rounded up)
	parameter DM_WIDTH                = 2,       // # of data mask bits
	parameter DQ_WIDTH                = 16,      // # of data width
	parameter DQ_PER_DQS              = 8,       // # of DQ data bits per strobe
	parameter DQS_WIDTH               = 2,       // # of DQS strobes
	parameter DQ_BITS                 = 4,       // set to log2(DQS_WIDTH*DQ_PER_DQS)
	parameter DQS_BITS                = 1,       // set to log2(DQS_WIDTH)
	parameter ODT_WIDTH               = 1,       // # of memory on-die term enables
	parameter ROW_WIDTH               = 13,      // # of memory row and # of addr bits
	parameter ADDITIVE_LAT            = 0,       // additive write latency 
	parameter BURST_LEN               = 4,       // burst length (in double words)
	parameter BURST_TYPE              = 0,       // burst type (=0 seq; =1 interleaved)
	parameter CAS_LAT                 = 4,       // CAS latency
	parameter ECC_ENABLE              = 0,       // enable ECC (=1 enable)
	parameter APPDATA_WIDTH           = 32,      // # of usr read/write data bus bits
	parameter MULTI_BANK_EN           = 1,       // Keeps multiple banks open. (= 1 enable)
	parameter TWO_T_TIME_EN           = 0,       // 2t timing for unbuffered dimms
	parameter ODT_TYPE                = 1,       // ODT (=0(none),=1(75),=2(150),=3(50))
	parameter REDUCE_DRV              = 1,       // reduced strength mem I/O (=1 yes)
	parameter REG_ENABLE              = 0,       // registered addr/ctrl (=1 yes)
	parameter TREFI_NS                = 7800,    // auto refresh interval (ns)
	parameter TRAS                    = 40000,   // active->precharge delay
	parameter TRCD                    = 15000,   // active->read/write delay
	parameter TRFC                    = 127500,  // refresh->refresh, refresh->active delay
	parameter TRP                     = 15000,   // precharge->command delay
	parameter TRTP                    = 7500,    // read->precharge delay
	parameter TWR                     = 15000,   // used to determine write->precharge
	parameter TWTR                    = 7500,    // write->read delay
	parameter HIGH_PERFORMANCE_MODE   = "TRUE",  // # = TRUE, the IODELAY performance mode is set to high.
	                                             // # = FALSE, the IODELAY performance mode is set to low.
	parameter SIM_ONLY                = 0,       // = 1 to skip SDRAM power up delay
	parameter DEBUG_EN                = 2,       // Enable debug signals/controls. When this parameter is changed from 0 to 1,
	parameter CLK_PERIOD              = 3750,    // Core/Memory clock period (in ps)
	parameter RST_ACT_LOW             = 0,       // =1 for active low reset, =0 for active high
	parameter DLL_FREQ_MODE           = "HIGH"   // DCM Frequency range
	)
	(
	input  wire [7:0]   hi_in,
	output wire [1:0]   hi_out,
	inout  wire [15:0]  hi_inout,
	output wire         hi_muxsel,
	output wire [3:0]   led,
	
	input  wire         sys_clk_p,
	input  wire         sys_clk_n,

	inout  wire [DQ_WIDTH-1:0]   ddr2a_dq,
	output wire [ROW_WIDTH-1:0]  ddr2a_a,
	output wire [BANK_WIDTH-1:0] ddr2a_ba,
	output wire                  ddr2a_ras_n,
	output wire                  ddr2a_cas_n,
	output wire                  ddr2a_we_n,
	output wire [CS_WIDTH-1:0]   ddr2a_cs_n,
	output wire [ODT_WIDTH-1:0]  ddr2a_odt,
	output wire [CKE_WIDTH-1:0]  ddr2a_cke,
	output wire [DM_WIDTH-1:0]   ddr2a_dm,
	inout  wire [DQS_WIDTH-1:0]  ddr2a_dqs,
	inout  wire [DQS_WIDTH-1:0]  ddr2a_dqs_n,
	output wire [CLK_WIDTH-1:0]  ddr2a_ck,
	output wire [CLK_WIDTH-1:0]  ddr2a_ck_n,

	inout  wire [DQ_WIDTH-1:0]   ddr2b_dq,
	output wire [ROW_WIDTH-1:0]  ddr2b_a,
	output wire [BANK_WIDTH-1:0] ddr2b_ba,
	output wire                  ddr2b_ras_n,
	output wire                  ddr2b_cas_n,
	output wire                  ddr2b_we_n,
	output wire [CS_WIDTH-1:0]   ddr2b_cs_n,
	output wire [ODT_WIDTH-1:0]  ddr2b_odt,
	output wire [CKE_WIDTH-1:0]  ddr2b_cke,
	output wire [DM_WIDTH-1:0]   ddr2b_dm,
	inout  wire [DQS_WIDTH-1:0]  ddr2b_dqs,
	inout  wire [DQS_WIDTH-1:0]  ddr2b_dqs_n,
	output wire [CLK_WIDTH-1:0]  ddr2b_ck,
	output wire [CLK_WIDTH-1:0]  ddr2b_ck_n
	);


// Host interface connections
wire        ti_clk;
wire [30:0] ok1;
wire [16:0] ok2;
wire [15:0] ep00wire;

// SDRAM controller / FIFO connections.
wire        ep80_write, ep81_write;
wire [15:0] ep80_dout, ep81_dout;
wire        epA0_read, epA1_read;
wire [15:0] epA0_din, epA1_din;

wire                              rst0;
wire                              rst90;
wire                              rst200;
wire                              rstdiv0;
wire                              pll_lock;
wire                              clk0;
wire                              clk90;
wire                              clk200;
wire                              clkdiv0;
wire                              idelay_ctrl_rdy;
wire                              a_phy_init_done;
wire                              a_app_wdf_afull;
wire                              a_app_af_afull;
wire                              a_rd_data_valid;
wire                              a_app_wdf_wren;
wire                              a_app_af_wren;
wire  [30:0]                      a_app_af_addr;
wire  [2:0]                       a_app_af_cmd;
wire  [(APPDATA_WIDTH)-1:0]       a_rd_data_fifo_out;
wire  [(APPDATA_WIDTH)-1:0]       a_app_wdf_data;
wire  [(APPDATA_WIDTH/8)-1:0]     a_app_wdf_mask_data;

wire                              b_phy_init_done;
wire                              b_app_wdf_afull;
wire                              b_app_af_afull;
wire                              b_rd_data_valid;
wire                              b_app_wdf_wren;
wire                              b_app_af_wren;
wire  [30:0]                      b_app_af_addr;
wire  [2:0]                       b_app_af_cmd;
wire  [(APPDATA_WIDTH)-1:0]       b_rd_data_fifo_out;
wire  [(APPDATA_WIDTH)-1:0]       b_app_wdf_data;
wire  [(APPDATA_WIDTH/8)-1:0]     b_app_wdf_mask_data;

assign hi_muxsel = 1'b0;

assign led = ~{2'b00, pll_lock, a_phy_init_done};


//------------------------------------------------------------------------
// Clock generation and IDELAY from MIG
//------------------------------------------------------------------------
ddr2_idelay_ctrl u_idelay_ctrl
	(
	.rst200           (rst200),
	.clk200           (clk200),
	.idelay_ctrl_rdy  (idelay_ctrl_rdy)
	);

infrastructure #
	(
	.CLK_PERIOD       (10),
	.RST_ACT_LOW      (0),
	.DLL_FREQ_MODE    (DLL_FREQ_MODE)
	)
	u_infrastructure
	(
	.sys_clk_p        (sys_clk_p),
	.sys_clk_n        (sys_clk_n),
	.sys_rst_n        (ep00wire[3]),
	.rst0             (rst0),
	.rst90            (rst90),
	.rst200           (rst200),
	.rstdiv0          (rstdiv0),
	.clk0             (clk0),
	.clk90            (clk90),
	.clk200           (clk200),
	.clkdiv0          (clkdiv0),
	.idelay_ctrl_rdy  (idelay_ctrl_rdy),
	.pll_lock         (pll_lock)
	);


//------------------------------------------------------------------------
// DDR2 / FrontPanel transfer module
//------------------------------------------------------------------------
ddr2_test c0
	(
	.clk(clk0),
	.reset(ep00wire[2] | rst0),
	.reads_en(ep00wire[0]),
	.writes_en(ep00wire[1]),
	.phy_init_done(a_phy_init_done),
	.wr_clk(ti_clk),
	.wr_en(ep80_write),
	.wr_data(ep80_dout),
	.rd_clk(ti_clk),
	.rd_en(epA0_read),
	.rd_data(epA0_din),
	.rd_data_valid(a_rd_data_valid),
	.rd_data_fifo_out(a_rd_data_fifo_out),
	.app_af_wren(a_app_af_wren),
	.app_af_afull(a_app_af_afull),
	.app_af_cmd(a_app_af_cmd),
	.app_af_addr(a_app_af_addr),
	.app_wdf_wren(a_app_wdf_wren),
	.app_wdf_afull(a_app_wdf_afull),
	.app_wdf_data(a_app_wdf_data),
	.app_wdf_mask_data(a_app_wdf_mask_data)
	);

ddr2_test c1
	(
	.clk(clk0),
	.reset(ep00wire[2] | rst0),
	.reads_en(ep00wire[0]),
	.writes_en(ep00wire[1]),
	.phy_init_done(b_phy_init_done),
	.wr_clk(ti_clk),
	.wr_en(ep81_write),
	.wr_data(ep81_dout),
	.rd_clk(ti_clk),
	.rd_en(epA1_read),
	.rd_data(epA1_din),
	.rd_data_valid(b_rd_data_valid),
	.rd_data_fifo_out(b_rd_data_fifo_out),
	.app_af_wren(b_app_af_wren),
	.app_af_afull(b_app_af_afull),
	.app_af_cmd(b_app_af_cmd),
	.app_af_addr(b_app_af_addr),
	.app_wdf_wren(b_app_wdf_wren),
	.app_wdf_afull(b_app_wdf_afull),
	.app_wdf_data(b_app_wdf_data),
	.app_wdf_mask_data(b_app_wdf_mask_data)
	);


//------------------------------------------------------------------------
// MIG Controllers
//------------------------------------------------------------------------
ddr2_top #
	(
   .BANK_WIDTH             (BANK_WIDTH),
   .CKE_WIDTH              (CKE_WIDTH),
   .CLK_WIDTH              (CLK_WIDTH),
   .COL_WIDTH              (COL_WIDTH),
   .CS_NUM                 (CS_NUM),
   .CS_WIDTH               (CS_WIDTH),
   .CS_BITS                (CS_BITS),
   .DM_WIDTH               (DM_WIDTH),
   .DQ_WIDTH               (DQ_WIDTH),
   .DQ_PER_DQS             (DQ_PER_DQS),
   .DQS_WIDTH              (DQS_WIDTH),
   .DQ_BITS                (DQ_BITS),
   .DQS_BITS               (DQS_BITS),
   .ODT_WIDTH              (ODT_WIDTH),
   .ROW_WIDTH              (ROW_WIDTH),
   .ADDITIVE_LAT           (ADDITIVE_LAT),
   .BURST_LEN              (BURST_LEN),
   .BURST_TYPE             (BURST_TYPE),
   .CAS_LAT                (CAS_LAT),
   .ECC_ENABLE             (ECC_ENABLE),
   .APPDATA_WIDTH          (APPDATA_WIDTH),
   .MULTI_BANK_EN          (MULTI_BANK_EN),
   .TWO_T_TIME_EN          (TWO_T_TIME_EN),
   .ODT_TYPE               (ODT_TYPE),
   .REDUCE_DRV             (REDUCE_DRV),
   .REG_ENABLE             (REG_ENABLE),
   .TREFI_NS               (TREFI_NS),
   .TRAS                   (TRAS),
   .TRCD                   (TRCD),
   .TRFC                   (TRFC),
   .TRP                    (TRP),
   .TRTP                   (TRTP),
   .TWR                    (TWR),
   .TWTR                   (TWTR),
   .HIGH_PERFORMANCE_MODE  (HIGH_PERFORMANCE_MODE),
   .SIM_ONLY               (SIM_ONLY),
   .DEBUG_EN               (DEBUG_EN),
   .FPGA_SPEED_GRADE       (1),
   .CLK_PERIOD             (CLK_PERIOD),
   .USE_DM_PORT            (1)
	)
u_ddr2_top_0
	(
   .ddr2_ck                (ddr2a_ck),
   .ddr2_ck_n              (ddr2a_ck_n),
   .ddr2_cke               (ddr2a_cke),
   .ddr2_odt               (ddr2a_odt),
   .ddr2_ras_n             (ddr2a_ras_n),
   .ddr2_cas_n             (ddr2a_cas_n),
   .ddr2_we_n              (ddr2a_we_n),
   .ddr2_cs_n              (ddr2a_cs_n),
   .ddr2_a                 (ddr2a_a),
   .ddr2_ba                (ddr2a_ba),
   .ddr2_dm                (ddr2a_dm),
   .ddr2_dq                (ddr2a_dq),
   .ddr2_dqs               (ddr2a_dqs),
   .ddr2_dqs_n             (ddr2a_dqs_n),
   .rst0                   (rst0),
   .rst90                  (rst90),
   .rstdiv0                (rstdiv0),
   .clk0                   (clk0),
   .clk90                  (clk90),
   .clkdiv0                (clkdiv0),
   .phy_init_done          (a_phy_init_done),
   .app_wdf_afull          (a_app_wdf_afull),
   .app_af_afull           (a_app_af_afull),
   .rd_data_valid          (a_rd_data_valid),
   .app_wdf_wren           (a_app_wdf_wren),
   .app_af_wren            (a_app_af_wren),
   .app_af_addr            (a_app_af_addr),
   .app_af_cmd             (a_app_af_cmd),
   .rd_data_fifo_out       (a_rd_data_fifo_out),
   .app_wdf_data           (a_app_wdf_data),
   .app_wdf_mask_data      (a_app_wdf_mask_data),
   .rd_ecc_error           ()
	);


ddr2_top #
	(
   .BANK_WIDTH             (BANK_WIDTH),
   .CKE_WIDTH              (CKE_WIDTH),
   .CLK_WIDTH              (CLK_WIDTH),
   .COL_WIDTH              (COL_WIDTH),
   .CS_NUM                 (CS_NUM),
   .CS_WIDTH               (CS_WIDTH),
   .CS_BITS                (CS_BITS),
   .DM_WIDTH               (DM_WIDTH),
   .DQ_WIDTH               (DQ_WIDTH),
   .DQ_PER_DQS             (DQ_PER_DQS),
   .DQS_WIDTH              (DQS_WIDTH),
   .DQ_BITS                (DQ_BITS),
   .DQS_BITS               (DQS_BITS),
   .ODT_WIDTH              (ODT_WIDTH),
   .ROW_WIDTH              (ROW_WIDTH),
   .ADDITIVE_LAT           (ADDITIVE_LAT),
   .BURST_LEN              (BURST_LEN),
   .BURST_TYPE             (BURST_TYPE),
   .CAS_LAT                (CAS_LAT),
   .ECC_ENABLE             (ECC_ENABLE),
   .APPDATA_WIDTH          (APPDATA_WIDTH),
   .MULTI_BANK_EN          (MULTI_BANK_EN),
   .TWO_T_TIME_EN          (TWO_T_TIME_EN),
   .ODT_TYPE               (ODT_TYPE),
   .REDUCE_DRV             (REDUCE_DRV),
   .REG_ENABLE             (REG_ENABLE),
   .TREFI_NS               (TREFI_NS),
   .TRAS                   (TRAS),
   .TRCD                   (TRCD),
   .TRFC                   (TRFC),
   .TRP                    (TRP),
   .TRTP                   (TRTP),
   .TWR                    (TWR),
   .TWTR                   (TWTR),
   .HIGH_PERFORMANCE_MODE  (HIGH_PERFORMANCE_MODE),
   .SIM_ONLY               (SIM_ONLY),
   .DEBUG_EN               (DEBUG_EN),
   .FPGA_SPEED_GRADE       (1),
   .CLK_PERIOD             (CLK_PERIOD),
   .USE_DM_PORT            (1)
	)
u_ddr2_top_1
	(
   .ddr2_ck                (ddr2b_ck),
   .ddr2_ck_n              (ddr2b_ck_n),
   .ddr2_cke               (ddr2b_cke),
   .ddr2_odt               (ddr2b_odt),
   .ddr2_ras_n             (ddr2b_ras_n),
   .ddr2_cas_n             (ddr2b_cas_n),
   .ddr2_we_n              (ddr2b_we_n),
   .ddr2_cs_n              (ddr2b_cs_n),
   .ddr2_a                 (ddr2b_a),
   .ddr2_ba                (ddr2b_ba),
   .ddr2_dm                (ddr2b_dm),
   .ddr2_dq                (ddr2b_dq),
   .ddr2_dqs               (ddr2b_dqs),
   .ddr2_dqs_n             (ddr2b_dqs_n),
   .rst0                   (rst0),
   .rst90                  (rst90),
   .rstdiv0                (rstdiv0),
   .clk0                   (clk0),
   .clk90                  (clk90),
   .clkdiv0                (clkdiv0),
   .phy_init_done          (b_phy_init_done),
   .app_wdf_afull          (b_app_wdf_afull),
   .app_af_afull           (b_app_af_afull),
   .rd_data_valid          (b_rd_data_valid),
   .app_wdf_wren           (b_app_wdf_wren),
   .app_af_wren            (b_app_af_wren),
   .app_af_addr            (b_app_af_addr),
   .app_af_cmd             (b_app_af_cmd),
   .rd_data_fifo_out       (b_rd_data_fifo_out),
   .app_wdf_data           (b_app_wdf_data),
   .app_wdf_mask_data      (b_app_wdf_mask_data),
   .rd_ecc_error           ()
	);

// Instantiate the okHost and connect endpoints.
wire [17*4-1:0]  ok2x;
okHost okHI(
	.hi_in(hi_in), .hi_out(hi_out), .hi_inout(hi_inout), .ti_clk(ti_clk),
	.ok1(ok1), .ok2(ok2));

okWireOR # (.N(4)) wireOR (ok2, ok2x);

okWireIn   ep00 (.ok1(ok1),                           .ep_addr(8'h00), .ep_dataout(ep00wire));
okPipeIn   ep80 (.ok1(ok1), .ok2(ok2x[ 0*17 +: 17 ]), .ep_addr(8'h80), .ep_write(ep80_write), .ep_dataout(ep80_dout));
okPipeIn   ep81 (.ok1(ok1), .ok2(ok2x[ 1*17 +: 17 ]), .ep_addr(8'h81), .ep_write(ep81_write), .ep_dataout(ep81_dout));
okPipeOut  epA0 (.ok1(ok1), .ok2(ok2x[ 2*17 +: 17 ]), .ep_addr(8'ha0), .ep_read(epA0_read), .ep_datain(epA0_din));
okPipeOut  epA1 (.ok1(ok1), .ok2(ok2x[ 3*17 +: 17 ]), .ep_addr(8'ha1), .ep_read(epA1_read), .ep_datain(epA1_din));

endmodule