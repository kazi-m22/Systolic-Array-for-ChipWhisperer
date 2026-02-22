// Copyright 1986-2021 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2021.2 (win64) Build 3367213 Tue Oct 19 02:48:09 MDT 2021
// Date        : Mon Jan 26 17:18:22 2026
// Host        : ece-d4000-kazi running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               C:/Users/kmejbaulislam/Documents/Research/Dipal_project/d_pin_skew/d_pin_skew.runs/systolic_4x4_0_synth_1/systolic_4x4_0_stub.v
// Design      : systolic_4x4_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a100tftg256-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "systolic_4x4,Vivado 2021.2" *)
module systolic_4x4_0(ap_local_block, ap_local_deadlock, ap_clk, 
  ap_rst, ap_start, ap_done, ap_idle, ap_ready, A_mem_Clk_A, A_mem_Rst_A, A_mem_EN_A, A_mem_WEN_A, 
  A_mem_Addr_A, A_mem_Din_A, A_mem_Dout_A, B_mem_Clk_A, B_mem_Rst_A, B_mem_EN_A, B_mem_WEN_A, 
  B_mem_Addr_A, B_mem_Din_A, B_mem_Dout_A, C_mem_Clk_A, C_mem_Rst_A, C_mem_EN_A, C_mem_WEN_A, 
  C_mem_Addr_A, C_mem_Din_A, C_mem_Dout_A)
/* synthesis syn_black_box black_box_pad_pin="ap_local_block,ap_local_deadlock,ap_clk,ap_rst,ap_start,ap_done,ap_idle,ap_ready,A_mem_Clk_A,A_mem_Rst_A,A_mem_EN_A,A_mem_WEN_A[0:0],A_mem_Addr_A[31:0],A_mem_Din_A[7:0],A_mem_Dout_A[7:0],B_mem_Clk_A,B_mem_Rst_A,B_mem_EN_A,B_mem_WEN_A[0:0],B_mem_Addr_A[31:0],B_mem_Din_A[7:0],B_mem_Dout_A[7:0],C_mem_Clk_A,C_mem_Rst_A,C_mem_EN_A,C_mem_WEN_A[3:0],C_mem_Addr_A[31:0],C_mem_Din_A[31:0],C_mem_Dout_A[31:0]" */;
  output ap_local_block;
  output ap_local_deadlock;
  input ap_clk;
  input ap_rst;
  input ap_start;
  output ap_done;
  output ap_idle;
  output ap_ready;
  output A_mem_Clk_A;
  output A_mem_Rst_A;
  output A_mem_EN_A;
  output [0:0]A_mem_WEN_A;
  output [31:0]A_mem_Addr_A;
  output [7:0]A_mem_Din_A;
  input [7:0]A_mem_Dout_A;
  output B_mem_Clk_A;
  output B_mem_Rst_A;
  output B_mem_EN_A;
  output [0:0]B_mem_WEN_A;
  output [31:0]B_mem_Addr_A;
  output [7:0]B_mem_Din_A;
  input [7:0]B_mem_Dout_A;
  output C_mem_Clk_A;
  output C_mem_Rst_A;
  output C_mem_EN_A;
  output [3:0]C_mem_WEN_A;
  output [31:0]C_mem_Addr_A;
  output [31:0]C_mem_Din_A;
  input [31:0]C_mem_Dout_A;
endmodule
