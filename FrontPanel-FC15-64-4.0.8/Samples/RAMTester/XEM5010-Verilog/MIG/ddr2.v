//*****************************************************************************
// DISCLAIMER OF LIABILITY
//
// This file contains proprietary and confidential information of
// Xilinx, Inc. ("Xilinx"), that is distributed under a license
// from Xilinx, and may be used, copied and/or disclosed only
// pursuant to the terms of a valid license agreement with Xilinx.
//
// XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION
// ("MATERIALS") "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
// EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING WITHOUT
// LIMITATION, ANY WARRANTY WITH RESPECT TO NONINFRINGEMENT,
// MERCHANTABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE. Xilinx
// does not warrant that functions included in the Materials will
// meet the requirements of Licensee, or that the operation of the
// Materials will be uninterrupted or error-free, or that defects
// in the Materials will be corrected. Furthermore, Xilinx does
// not warrant or make any representations regarding use, or the
// results of the use, of the Materials in terms of correctness,
// accuracy, reliability or otherwise.
//
// Xilinx products are not designed or intended to be fail-safe,
// or for use in any application requiring fail-safe performance,
// such as life-support or safety devices or systems, Class III
// medical devices, nuclear facilities, applications related to
// the deployment of airbags, or any other applications that could
// lead to death, personal injury or severe property or
// environmental damage (individually and collectively, "critical
// applications"). Customer assumes the sole risk and liability
// of any use of Xilinx products in critical applications,
// subject only to applicable laws and regulations governing
// limitations on product liability.
//
// Copyright 2006, 2007, 2008 Xilinx, Inc.
// All rights reserved.
//
// This disclaimer and copyright notice must be retained as part
// of this file at all times.
//*****************************************************************************
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor: Xilinx
// \   \   \/     Version: 3.6.1
//  \   \         Application: MIG
//  /   /         Filename: ddr2.v
// /___/   /\     Date Last Modified: $Date: 2010/11/26 18:26:02 $
// \   \  /  \    Date Created: Wed Aug 16 2006
//  \___\/\___\
//
//Device: Virtex-5
//Design Name: DDR2
//Purpose:
//   Top-level  module. Simple model for what the user might use
//   Typically, the user will only instantiate MEM_INTERFACE_TOP in their
//   code, and generate all backend logic (test bench) and all the other infrastructure logic
//    separately.
//   In addition to the memory controller, the module instantiates:
//     1. Reset logic based on user clocks
//     2. IDELAY control block
//Reference:
//Revision History:
//   Rev 1.1 - Parameter USE_DM_PORT added. PK. 6/25/08
//   Rev 1.2 - Parameter HIGH_PERFORMANCE_MODE added. PK. 7/10/08
//   Rev 1.3 - Parameter IODELAY_GRP added. PK. 11/27/08
//*****************************************************************************

`timescale 1ns/1ps

(* X_CORE_INFO = "mig_v3_61_ddr2_v5, Coregen 12.4" , CORE_GENERATION_INFO = "ddr2_v5,mig_v3_61,{component_name=ddr2, C0_BANK_WIDTH=3, C0_CKE_WIDTH=1, C0_CLK_WIDTH=1, C0_COL_WIDTH=10, C0_CS_NUM=1, C0_CS_WIDTH=1, C0_DM_WIDTH=2, C0_DQ_WIDTH=16, C0_DQ_PER_DQS=8, C0_DQS_WIDTH=2, C0_ODT_WIDTH=1, C0_ROW_WIDTH=13, C0_ADDITIVE_LAT=0, C0_BURST_LEN=4, C0_BURST_TYPE=0, C0_CAS_LAT=4, C0_ECC_ENABLE=0, C0_MULTI_BANK_EN=1, C0_TWO_T_TIME_EN=0, C0_ODT_TYPE=1, C0_REDUCE_DRV=1, C0_REG_ENABLE=0, C0_TREFI_NS=7800, C0_TRAS=40000, C0_TRCD=15000, C0_TRFC=127500, C0_TRP=15000, C0_TRTP=7500, C0_TWR=15000, C0_TWTR=7500, F0_CLK_PERIOD=3750, RST_ACT_LOW=1, C0_INTERFACE_TYPE=DDR2_SDRAM,C1_BANK_WIDTH=3, C1_CKE_WIDTH=1, C1_CLK_WIDTH=1, C1_COL_WIDTH=10, C1_CS_NUM=1, C1_CS_WIDTH=1, C1_DM_WIDTH=2, C1_DQ_WIDTH=16, C1_DQ_PER_DQS=8, C1_DQS_WIDTH=2, C1_ODT_WIDTH=1, C1_ROW_WIDTH=13, C1_ADDITIVE_LAT=0, C1_BURST_LEN=4, C1_BURST_TYPE=0, C1_CAS_LAT=4, C1_ECC_ENABLE=0, C1_MULTI_BANK_EN=1, C1_TWO_T_TIME_EN=0, C1_ODT_TYPE=1, C1_REDUCE_DRV=1, C1_REG_ENABLE=0, C1_TREFI_NS=7800, C1_TRAS=40000, C1_TRCD=15000, C1_TRFC=127500, C1_TRP=15000, C1_TRTP=7500, C1_TWR=15000, C1_TWTR=7500, F0_CLK_PERIOD=3750, RST_ACT_LOW=1, C1_INTERFACE_TYPE=DDR2_SDRAM, LANGUAGE=Verilog, SYNTHESIS_TOOL=ISE, NO_OF_CONTROLLERS=2}" *)
module ddr2 #
  (
   parameter C0_DDR2_BANK_WIDTH      = 3,       
                                       // # of memory bank addr bits.
   parameter C0_DDR2_CKE_WIDTH       = 1,       
                                       // # of memory clock enable outputs.
   parameter C0_DDR2_CLK_WIDTH       = 1,       
                                       // # of clock outputs.
   parameter C0_DDR2_COL_WIDTH       = 10,       
                                       // # of memory column bits.
   parameter C0_DDR2_CS_NUM          = 1,       
                                       // # of separate memory chip selects.
   parameter C0_DDR2_CS_WIDTH        = 1,       
                                       // # of total memory chip selects.
   parameter C0_DDR2_CS_BITS         = 0,       
                                       // set to log2(CS_NUM) (rounded up).
   parameter C0_DDR2_DM_WIDTH        = 2,       
                                       // # of data mask bits.
   parameter C0_DDR2_DQ_WIDTH        = 16,       
                                       // # of data width.
   parameter C0_DDR2_DQ_PER_DQS      = 8,       
                                       // # of DQ data bits per strobe.
   parameter C0_DDR2_DQS_WIDTH       = 2,       
                                       // # of DQS strobes.
   parameter C0_DDR2_DQ_BITS         = 4,       
                                       // set to log2(DQS_WIDTH*DQ_PER_DQS).
   parameter C0_DDR2_DQS_BITS        = 1,       
                                       // set to log2(DQS_WIDTH).
   parameter C0_DDR2_ODT_WIDTH       = 1,       
                                       // # of memory on-die term enables.
   parameter C0_DDR2_ROW_WIDTH       = 13,       
                                       // # of memory row and # of addr bits.
   parameter C0_DDR2_ADDITIVE_LAT    = 0,       
                                       // additive write latency.
   parameter C0_DDR2_BURST_LEN       = 4,       
                                       // burst length (in double words).
   parameter C0_DDR2_BURST_TYPE      = 0,       
                                       // burst type (=0 seq; =1 interleaved).
   parameter C0_DDR2_CAS_LAT         = 4,       
                                       // CAS latency.
   parameter C0_DDR2_ECC_ENABLE      = 0,       
                                       // enable ECC (=1 enable).
   parameter C0_DDR2_APPDATA_WIDTH   = 32,       
                                       // # of usr read/write data bus bits.
   parameter C0_DDR2_MULTI_BANK_EN   = 1,       
                                       // Keeps multiple banks open. (= 1 enable).
   parameter C0_DDR2_TWO_T_TIME_EN   = 0,       
                                       // 2t timing for unbuffered dimms.
   parameter C0_DDR2_ODT_TYPE        = 1,       
                                       // ODT (=0(none),=1(75),=2(150),=3(50)).
   parameter C0_DDR2_REDUCE_DRV      = 1,       
                                       // reduced strength mem I/O (=1 yes).
   parameter C0_DDR2_REG_ENABLE      = 0,       
                                       // registered addr/ctrl (=1 yes).
   parameter C0_DDR2_TREFI_NS        = 7800,       
                                       // auto refresh interval (ns).
   parameter C0_DDR2_TRAS            = 40000,       
                                       // active->precharge delay.
   parameter C0_DDR2_TRCD            = 15000,       
                                       // active->read/write delay.
   parameter C0_DDR2_TRFC            = 127500,       
                                       // refresh->refresh, refresh->active delay.
   parameter C0_DDR2_TRP             = 15000,       
                                       // precharge->command delay.
   parameter C0_DDR2_TRTP            = 7500,       
                                       // read->precharge delay.
   parameter C0_DDR2_TWR             = 15000,       
                                       // used to determine write->precharge.
   parameter C0_DDR2_TWTR            = 7500,       
                                       // write->read delay.
   parameter C0_DDR2_HIGH_PERFORMANCE_MODE  = "TRUE",       
                              // # = TRUE, the IODELAY performance mode is set
                              // to high.
                              // # = FALSE, the IODELAY performance mode is set
                              // to low.
   parameter C0_DDR2_SIM_ONLY        = 0,       
                                       // = 1 to skip SDRAM power up delay.
   parameter C0_DDR2_DEBUG_EN        = 0,       
                                       // Enable debug signals/controls.
                                       // When this parameter is changed from 0 to 1,
                                       // make sure to uncomment the coregen commands
                                       // in ise_flow.bat or create_ise.bat files in
                                       // par folder.
   parameter F0_DDR2_CLK_PERIOD      = 3750,       
                                       // Core/Memory clock period (in ps).
   parameter F0_DDR2_DLL_FREQ_MODE   = "HIGH",       
                                       // DCM Frequency range.
   parameter CLK_TYPE                = "DIFFERENTIAL",       
                                       // # = "DIFFERENTIAL " ->; Differential input clocks ,
                                       // # = "SINGLE_ENDED" -> Single ended input clocks.
   parameter F0_DDR2_NOCLK200        = 0,       
                                       // clk200 enable and disable.
   parameter RST_ACT_LOW             = 1,       
                                       // =1 for active low reset, =0 for active high.
   parameter C1_DDR2_BANK_WIDTH      = 3,       
                                       // # of memory bank addr bits.
   parameter C1_DDR2_CKE_WIDTH       = 1,       
                                       // # of memory clock enable outputs.
   parameter C1_DDR2_CLK_WIDTH       = 1,       
                                       // # of clock outputs.
   parameter C1_DDR2_COL_WIDTH       = 10,       
                                       // # of memory column bits.
   parameter C1_DDR2_CS_NUM          = 1,       
                                       // # of separate memory chip selects.
   parameter C1_DDR2_CS_WIDTH        = 1,       
                                       // # of total memory chip selects.
   parameter C1_DDR2_CS_BITS         = 0,       
                                       // set to log2(CS_NUM) (rounded up).
   parameter C1_DDR2_DM_WIDTH        = 2,       
                                       // # of data mask bits.
   parameter C1_DDR2_DQ_WIDTH        = 16,       
                                       // # of data width.
   parameter C1_DDR2_DQ_PER_DQS      = 8,       
                                       // # of DQ data bits per strobe.
   parameter C1_DDR2_DQS_WIDTH       = 2,       
                                       // # of DQS strobes.
   parameter C1_DDR2_DQ_BITS         = 4,       
                                       // set to log2(DQS_WIDTH*DQ_PER_DQS).
   parameter C1_DDR2_DQS_BITS        = 1,       
                                       // set to log2(DQS_WIDTH).
   parameter C1_DDR2_ODT_WIDTH       = 1,       
                                       // # of memory on-die term enables.
   parameter C1_DDR2_ROW_WIDTH       = 13,       
                                       // # of memory row and # of addr bits.
   parameter C1_DDR2_ADDITIVE_LAT    = 0,       
                                       // additive write latency.
   parameter C1_DDR2_BURST_LEN       = 4,       
                                       // burst length (in double words).
   parameter C1_DDR2_BURST_TYPE      = 0,       
                                       // burst type (=0 seq; =1 interleaved).
   parameter C1_DDR2_CAS_LAT         = 4,       
                                       // CAS latency.
   parameter C1_DDR2_ECC_ENABLE      = 0,       
                                       // enable ECC (=1 enable).
   parameter C1_DDR2_APPDATA_WIDTH   = 32,       
                                       // # of usr read/write data bus bits.
   parameter C1_DDR2_MULTI_BANK_EN   = 1,       
                                       // Keeps multiple banks open. (= 1 enable).
   parameter C1_DDR2_TWO_T_TIME_EN   = 0,       
                                       // 2t timing for unbuffered dimms.
   parameter C1_DDR2_ODT_TYPE        = 1,       
                                       // ODT (=0(none),=1(75),=2(150),=3(50)).
   parameter C1_DDR2_REDUCE_DRV      = 1,       
                                       // reduced strength mem I/O (=1 yes).
   parameter C1_DDR2_REG_ENABLE      = 0,       
                                       // registered addr/ctrl (=1 yes).
   parameter C1_DDR2_TREFI_NS        = 7800,       
                                       // auto refresh interval (ns).
   parameter C1_DDR2_TRAS            = 40000,       
                                       // active->precharge delay.
   parameter C1_DDR2_TRCD            = 15000,       
                                       // active->read/write delay.
   parameter C1_DDR2_TRFC            = 127500,       
                                       // refresh->refresh, refresh->active delay.
   parameter C1_DDR2_TRP             = 15000,       
                                       // precharge->command delay.
   parameter C1_DDR2_TRTP            = 7500,       
                                       // read->precharge delay.
   parameter C1_DDR2_TWR             = 15000,       
                                       // used to determine write->precharge.
   parameter C1_DDR2_TWTR            = 7500,       
                                       // write->read delay.
   parameter C1_DDR2_HIGH_PERFORMANCE_MODE  = "TRUE",       
                              // # = TRUE, the IODELAY performance mode is set
                              // to high.
                              // # = FALSE, the IODELAY performance mode is set
                              // to low.
   parameter C1_DDR2_SIM_ONLY        = 0,       
                                       // = 1 to skip SDRAM power up delay.
   parameter C1_DDR2_DEBUG_EN        = 0        
                                       // Enable debug signals/controls.
                                       // When this parameter is changed from 0 to 1,
                                       // make sure to uncomment the coregen commands
                                       // in ise_flow.bat or create_ise.bat files in
                                       // par folder.
   )
  (
   inout  [C0_DDR2_DQ_WIDTH-1:0]               c0_ddr2_dq,
   output [C0_DDR2_ROW_WIDTH-1:0]              c0_ddr2_a,
   output [C0_DDR2_BANK_WIDTH-1:0]             c0_ddr2_ba,
   output                                      c0_ddr2_ras_n,
   output                                      c0_ddr2_cas_n,
   output                                      c0_ddr2_we_n,
   output [C0_DDR2_CS_WIDTH-1:0]               c0_ddr2_cs_n,
   output [C0_DDR2_ODT_WIDTH-1:0]              c0_ddr2_odt,
   output [C0_DDR2_CKE_WIDTH-1:0]              c0_ddr2_cke,
   output [C0_DDR2_DM_WIDTH-1:0]               c0_ddr2_dm,
   input                                       ddr2_sys_clk_f0_p,
   input                                       ddr2_sys_clk_f0_n,
   input                                       clk200_p,
   input                                       clk200_n,
   input                                       sys_rst_n,
   output                                      c0_phy_init_done,
   output                             f0_rst0_tb,
   output                             f0_ddr2_clk0_tb,
   output                                      c0_app_wdf_afull,
   output                                      c0_app_af_afull,
   output                                      c0_rd_data_valid,
   input                                       c0_app_wdf_wren,
   input                                       c0_app_af_wren,
   input  [30:0]                               c0_app_af_addr,
   input  [2:0]                                c0_app_af_cmd,
   output [(C0_DDR2_APPDATA_WIDTH)-1:0] c0_rd_data_fifo_out,
   input  [(C0_DDR2_APPDATA_WIDTH)-1:0] c0_app_wdf_data,
   input  [(C0_DDR2_APPDATA_WIDTH/8)-1:0] c0_app_wdf_mask_data,
   inout  [C0_DDR2_DQS_WIDTH-1:0]              c0_ddr2_dqs,
   inout  [C0_DDR2_DQS_WIDTH-1:0]              c0_ddr2_dqs_n,
   output [C0_DDR2_CLK_WIDTH-1:0]              c0_ddr2_ck,
   output [C0_DDR2_CLK_WIDTH-1:0]              c0_ddr2_ck_n,
   inout  [C1_DDR2_DQ_WIDTH-1:0]               c1_ddr2_dq,
   output [C1_DDR2_ROW_WIDTH-1:0]              c1_ddr2_a,
   output [C1_DDR2_BANK_WIDTH-1:0]             c1_ddr2_ba,
   output                                      c1_ddr2_ras_n,
   output                                      c1_ddr2_cas_n,
   output                                      c1_ddr2_we_n,
   output [C1_DDR2_CS_WIDTH-1:0]               c1_ddr2_cs_n,
   output [C1_DDR2_ODT_WIDTH-1:0]              c1_ddr2_odt,
   output [C1_DDR2_CKE_WIDTH-1:0]              c1_ddr2_cke,
   output [C1_DDR2_DM_WIDTH-1:0]               c1_ddr2_dm,
   output                                      c1_phy_init_done,
   output                                      c1_app_wdf_afull,
   output                                      c1_app_af_afull,
   output                                      c1_rd_data_valid,
   input                                       c1_app_wdf_wren,
   input                                       c1_app_af_wren,
   input  [30:0]                               c1_app_af_addr,
   input  [2:0]                                c1_app_af_cmd,
   output [(C1_DDR2_APPDATA_WIDTH)-1:0] c1_rd_data_fifo_out,
   input  [(C1_DDR2_APPDATA_WIDTH)-1:0] c1_app_wdf_data,
   input  [(C1_DDR2_APPDATA_WIDTH/8)-1:0] c1_app_wdf_mask_data,
   inout  [C1_DDR2_DQS_WIDTH-1:0]              c1_ddr2_dqs,
   inout  [C1_DDR2_DQS_WIDTH-1:0]              c1_ddr2_dqs_n,
   output [C1_DDR2_CLK_WIDTH-1:0]              c1_ddr2_ck,
   output [C1_DDR2_CLK_WIDTH-1:0]              c1_ddr2_ck_n
   );

  //***************************************************************************
  // IODELAY Group Name: Replication and placement of IDELAYCTRLs will be
  // handled automatically by software tools if IDELAYCTRLs have same refclk,
  // reset and rdy nets. Designs with a unique RESET will commonly create a
  // unique RDY. Constraint IODELAY_GROUP is associated to a set of IODELAYs
  // with an IDELAYCTRL. The parameter IODELAY_GRP value can be any string.
  //***************************************************************************

  localparam IODELAY_GRP = "IODELAY_MIG";



  localparam [C0_DDR2_DQ_BITS-1:0] C0_DQ_ZEROS = {C0_DDR2_DQ_BITS{1'b0}};
  localparam [C0_DDR2_DQS_BITS:0] C0_DQS_ZEROS = {C0_DDR2_DQS_BITS{1'b0}};
  localparam [C1_DDR2_DQ_BITS-1:0] C1_DQ_ZEROS = {C1_DDR2_DQ_BITS{1'b0}};
  localparam [C1_DDR2_DQS_BITS:0] C1_DQS_ZEROS = {C1_DDR2_DQS_BITS{1'b0}};

  wire                              ddr2_sys_clk_f0;
  wire                              idly_clk_200;
  wire                              f0_rst0;
  wire                              f0_rst90;
  wire                              f0_rstdiv0;
  wire                              rst200;
  wire                              f0_ddr2_clk0;
  wire                              f0_ddr2_clk90;
  wire                              f0_ddr2_clkdiv0;
  wire                              clk200;
  wire                              idelay_ctrl_rdy;





  //***************************************************************************

  assign  f0_rst0_tb = f0_rst0;
  assign  f0_ddr2_clk0_tb = f0_ddr2_clk0;
  assign ddr2_sys_clk_f0 = 1'b0;
  assign idly_clk_200 = 1'b0;

ddr2_idelay_ctrl #
   (
    .IODELAY_GRP         (IODELAY_GRP)
   )
   u_ddr2_idelay_ctrl
   (
   .rst200                 (rst200),
   .clk200                 (clk200),
   .idelay_ctrl_rdy        (idelay_ctrl_rdy)
   );

 ddr2_infrastructure #
 (
   .CLK_PERIOD             (F0_DDR2_CLK_PERIOD),
   .DLL_FREQ_MODE          (F0_DDR2_DLL_FREQ_MODE),
   .CLK_TYPE               (CLK_TYPE),
   .NOCLK200               (F0_DDR2_NOCLK200),
   .RST_ACT_LOW            (RST_ACT_LOW)
   )
u_ddr2_infrastructure_f0
 (
   .sys_clk_p              (ddr2_sys_clk_f0_p),
   .sys_clk_n              (ddr2_sys_clk_f0_n),
   .sys_clk                (ddr2_sys_clk_f0),
   .clk200_p               (clk200_p),
   .clk200_n               (clk200_n),
   .idly_clk_200           (idly_clk_200),
   .sys_rst_n              (sys_rst_n),
   .rst0                   (f0_rst0),
   .rst90                  (f0_rst90),
   .rstdiv0                (f0_rstdiv0),
   .rst200                 (rst200),
   .clk0                   (f0_ddr2_clk0),
   .clk90                  (f0_ddr2_clk90),
   .clkdiv0                (f0_ddr2_clkdiv0),
   .clk200                 (clk200),
   .idelay_ctrl_rdy        (idelay_ctrl_rdy)
   );

 ddr2_top #
 (
   .BANK_WIDTH             (C0_DDR2_BANK_WIDTH),
   .CKE_WIDTH              (C0_DDR2_CKE_WIDTH),
   .CLK_WIDTH              (C0_DDR2_CLK_WIDTH),
   .COL_WIDTH              (C0_DDR2_COL_WIDTH),
   .CS_NUM                 (C0_DDR2_CS_NUM),
   .CS_WIDTH               (C0_DDR2_CS_WIDTH),
   .CS_BITS                (C0_DDR2_CS_BITS),
   .DM_WIDTH               (C0_DDR2_DM_WIDTH),
   .DQ_WIDTH               (C0_DDR2_DQ_WIDTH),
   .DQ_PER_DQS             (C0_DDR2_DQ_PER_DQS),
   .DQS_WIDTH              (C0_DDR2_DQS_WIDTH),
   .DQ_BITS                (C0_DDR2_DQ_BITS),
   .DQS_BITS               (C0_DDR2_DQS_BITS),
   .ODT_WIDTH              (C0_DDR2_ODT_WIDTH),
   .ROW_WIDTH              (C0_DDR2_ROW_WIDTH),
   .ADDITIVE_LAT           (C0_DDR2_ADDITIVE_LAT),
   .BURST_LEN              (C0_DDR2_BURST_LEN),
   .BURST_TYPE             (C0_DDR2_BURST_TYPE),
   .CAS_LAT                (C0_DDR2_CAS_LAT),
   .ECC_ENABLE             (C0_DDR2_ECC_ENABLE),
   .APPDATA_WIDTH          (C0_DDR2_APPDATA_WIDTH),
   .MULTI_BANK_EN          (C0_DDR2_MULTI_BANK_EN),
   .TWO_T_TIME_EN          (C0_DDR2_TWO_T_TIME_EN),
   .ODT_TYPE               (C0_DDR2_ODT_TYPE),
   .REDUCE_DRV             (C0_DDR2_REDUCE_DRV),
   .REG_ENABLE             (C0_DDR2_REG_ENABLE),
   .TREFI_NS               (C0_DDR2_TREFI_NS),
   .TRAS                   (C0_DDR2_TRAS),
   .TRCD                   (C0_DDR2_TRCD),
   .TRFC                   (C0_DDR2_TRFC),
   .TRP                    (C0_DDR2_TRP),
   .TRTP                   (C0_DDR2_TRTP),
   .TWR                    (C0_DDR2_TWR),
   .TWTR                   (C0_DDR2_TWTR),
   .HIGH_PERFORMANCE_MODE  (C0_DDR2_HIGH_PERFORMANCE_MODE),
   .IODELAY_GRP            (IODELAY_GRP),
   .SIM_ONLY               (C0_DDR2_SIM_ONLY),
   .DEBUG_EN               (C0_DDR2_DEBUG_EN),
   .FPGA_SPEED_GRADE       (1),
   .USE_DM_PORT            (1),
   .CLK_PERIOD             (F0_DDR2_CLK_PERIOD)
   )
u_ddr2_top_0
(
   .ddr2_dq                (c0_ddr2_dq),
   .ddr2_a                 (c0_ddr2_a),
   .ddr2_ba                (c0_ddr2_ba),
   .ddr2_ras_n             (c0_ddr2_ras_n),
   .ddr2_cas_n             (c0_ddr2_cas_n),
   .ddr2_we_n              (c0_ddr2_we_n),
   .ddr2_cs_n              (c0_ddr2_cs_n),
   .ddr2_odt               (c0_ddr2_odt),
   .ddr2_cke               (c0_ddr2_cke),
   .ddr2_dm                (c0_ddr2_dm),
   .phy_init_done          (c0_phy_init_done),
   .rst0                   (f0_rst0),
   .rst90                  (f0_rst90),
   .rstdiv0                (f0_rstdiv0),
   .clk0                   (f0_ddr2_clk0),
   .clk90                  (f0_ddr2_clk90),
   .clkdiv0                (f0_ddr2_clkdiv0),
   .app_wdf_afull          (c0_app_wdf_afull),
   .app_af_afull           (c0_app_af_afull),
   .rd_data_valid          (c0_rd_data_valid),
   .app_wdf_wren           (c0_app_wdf_wren),
   .app_af_wren            (c0_app_af_wren),
   .app_af_addr            (c0_app_af_addr),
   .app_af_cmd             (c0_app_af_cmd),
   .rd_data_fifo_out       (c0_rd_data_fifo_out),
   .app_wdf_data           (c0_app_wdf_data),
   .app_wdf_mask_data      (c0_app_wdf_mask_data),
   .ddr2_dqs               (c0_ddr2_dqs),
   .ddr2_dqs_n             (c0_ddr2_dqs_n),
   .ddr2_ck                (c0_ddr2_ck),
   .rd_ecc_error           (),
   .ddr2_ck_n              (c0_ddr2_ck_n),

   .dbg_calib_done         (),
   .dbg_calib_err          (),
   .dbg_calib_dq_tap_cnt   (),
   .dbg_calib_dqs_tap_cnt  (),
   .dbg_calib_gate_tap_cnt  (),
   .dbg_calib_rd_data_sel  (),
   .dbg_calib_rden_dly     (),
   .dbg_calib_gate_dly     (),
   .dbg_idel_up_all        (1'b0),
   .dbg_idel_down_all      (1'b0),
   .dbg_idel_up_dq         (1'b0),
   .dbg_idel_down_dq       (1'b0),
   .dbg_idel_up_dqs        (1'b0),
   .dbg_idel_down_dqs      (1'b0),
   .dbg_idel_up_gate       (1'b0),
   .dbg_idel_down_gate     (1'b0),
   .dbg_sel_idel_dq        (C0_DQ_ZEROS),
   .dbg_sel_all_idel_dq    (1'b0),
   .dbg_sel_idel_dqs       (C0_DQS_ZEROS),
   .dbg_sel_all_idel_dqs   (1'b0),
   .dbg_sel_idel_gate      (C0_DQS_ZEROS),
   .dbg_sel_all_idel_gate  (1'b0)
   );
ddr2_top #
 (
   .BANK_WIDTH             (C1_DDR2_BANK_WIDTH),
   .CKE_WIDTH              (C1_DDR2_CKE_WIDTH),
   .CLK_WIDTH              (C1_DDR2_CLK_WIDTH),
   .COL_WIDTH              (C1_DDR2_COL_WIDTH),
   .CS_NUM                 (C1_DDR2_CS_NUM),
   .CS_WIDTH               (C1_DDR2_CS_WIDTH),
   .CS_BITS                (C1_DDR2_CS_BITS),
   .DM_WIDTH               (C1_DDR2_DM_WIDTH),
   .DQ_WIDTH               (C1_DDR2_DQ_WIDTH),
   .DQ_PER_DQS             (C1_DDR2_DQ_PER_DQS),
   .DQS_WIDTH              (C1_DDR2_DQS_WIDTH),
   .DQ_BITS                (C1_DDR2_DQ_BITS),
   .DQS_BITS               (C1_DDR2_DQS_BITS),
   .ODT_WIDTH              (C1_DDR2_ODT_WIDTH),
   .ROW_WIDTH              (C1_DDR2_ROW_WIDTH),
   .ADDITIVE_LAT           (C1_DDR2_ADDITIVE_LAT),
   .BURST_LEN              (C1_DDR2_BURST_LEN),
   .BURST_TYPE             (C1_DDR2_BURST_TYPE),
   .CAS_LAT                (C1_DDR2_CAS_LAT),
   .ECC_ENABLE             (C1_DDR2_ECC_ENABLE),
   .APPDATA_WIDTH          (C1_DDR2_APPDATA_WIDTH),
   .MULTI_BANK_EN          (C1_DDR2_MULTI_BANK_EN),
   .TWO_T_TIME_EN          (C1_DDR2_TWO_T_TIME_EN),
   .ODT_TYPE               (C1_DDR2_ODT_TYPE),
   .REDUCE_DRV             (C1_DDR2_REDUCE_DRV),
   .REG_ENABLE             (C1_DDR2_REG_ENABLE),
   .TREFI_NS               (C1_DDR2_TREFI_NS),
   .TRAS                   (C1_DDR2_TRAS),
   .TRCD                   (C1_DDR2_TRCD),
   .TRFC                   (C1_DDR2_TRFC),
   .TRP                    (C1_DDR2_TRP),
   .TRTP                   (C1_DDR2_TRTP),
   .TWR                    (C1_DDR2_TWR),
   .TWTR                   (C1_DDR2_TWTR),
   .HIGH_PERFORMANCE_MODE  (C1_DDR2_HIGH_PERFORMANCE_MODE),
   .IODELAY_GRP            (IODELAY_GRP),
   .SIM_ONLY               (C1_DDR2_SIM_ONLY),
   .DEBUG_EN               (C1_DDR2_DEBUG_EN),
   .FPGA_SPEED_GRADE       (1),
   .CLK_PERIOD             (F0_DDR2_CLK_PERIOD),
   .USE_DM_PORT            (1)
   )
u_ddr2_top_1
(
   .ddr2_dq                (c1_ddr2_dq),
   .ddr2_a                 (c1_ddr2_a),
   .ddr2_ba                (c1_ddr2_ba),
   .ddr2_ras_n             (c1_ddr2_ras_n),
   .ddr2_cas_n             (c1_ddr2_cas_n),
   .ddr2_we_n              (c1_ddr2_we_n),
   .ddr2_cs_n              (c1_ddr2_cs_n),
   .ddr2_odt               (c1_ddr2_odt),
   .ddr2_cke               (c1_ddr2_cke),
   .ddr2_dm                (c1_ddr2_dm),
   .phy_init_done          (c1_phy_init_done),
   .rst0                   (f0_rst0),
   .rst90                  (f0_rst90),
   .rstdiv0                (f0_rstdiv0),
   .clk0                   (f0_ddr2_clk0),
   .clk90                  (f0_ddr2_clk90),
   .clkdiv0                (f0_ddr2_clkdiv0),
   .app_wdf_afull          (c1_app_wdf_afull),
   .app_af_afull           (c1_app_af_afull),
   .rd_data_valid          (c1_rd_data_valid),
   .app_wdf_wren           (c1_app_wdf_wren),
   .app_af_wren            (c1_app_af_wren),
   .app_af_addr            (c1_app_af_addr),
   .app_af_cmd             (c1_app_af_cmd),
   .rd_data_fifo_out       (c1_rd_data_fifo_out),
   .app_wdf_data           (c1_app_wdf_data),
   .app_wdf_mask_data      (c1_app_wdf_mask_data),
   .ddr2_dqs               (c1_ddr2_dqs),
   .ddr2_dqs_n             (c1_ddr2_dqs_n),
   .ddr2_ck                (c1_ddr2_ck),
   .rd_ecc_error           (),
   .ddr2_ck_n              (c1_ddr2_ck_n),

   .dbg_calib_done         (),
   .dbg_calib_err          (),
   .dbg_calib_dq_tap_cnt   (),
   .dbg_calib_dqs_tap_cnt  (),
   .dbg_calib_gate_tap_cnt  (),
   .dbg_calib_rd_data_sel  (),
   .dbg_calib_rden_dly     (),
   .dbg_calib_gate_dly     (),
   .dbg_idel_up_all        (1'b0),
   .dbg_idel_down_all      (1'b0),
   .dbg_idel_up_dq         (1'b0),
   .dbg_idel_down_dq       (1'b0),
   .dbg_idel_up_dqs        (1'b0),
   .dbg_idel_down_dqs      (1'b0),
   .dbg_idel_up_gate       (1'b0),
   .dbg_idel_down_gate     (1'b0),
   .dbg_sel_idel_dq        (C1_DQ_ZEROS),
   .dbg_sel_all_idel_dq    (1'b0),
   .dbg_sel_idel_dqs       (C1_DQS_ZEROS),
   .dbg_sel_all_idel_dqs   (1'b0),
   .dbg_sel_idel_gate      (C1_DQS_ZEROS),
   .dbg_sel_all_idel_gate  (1'b0)
   );

 
 
endmodule
