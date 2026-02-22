-- Copyright 1986-2021 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2021.2 (win64) Build 3367213 Tue Oct 19 02:48:09 MDT 2021
-- Date        : Mon Jan 26 17:18:22 2026
-- Host        : ece-d4000-kazi running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub
--               C:/Users/kmejbaulislam/Documents/Research/Dipal_project/d_pin_skew/d_pin_skew.runs/systolic_4x4_0_synth_1/systolic_4x4_0_stub.vhdl
-- Design      : systolic_4x4_0
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7a100tftg256-1
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity systolic_4x4_0 is
  Port ( 
    ap_local_block : out STD_LOGIC;
    ap_local_deadlock : out STD_LOGIC;
    ap_clk : in STD_LOGIC;
    ap_rst : in STD_LOGIC;
    ap_start : in STD_LOGIC;
    ap_done : out STD_LOGIC;
    ap_idle : out STD_LOGIC;
    ap_ready : out STD_LOGIC;
    A_mem_Clk_A : out STD_LOGIC;
    A_mem_Rst_A : out STD_LOGIC;
    A_mem_EN_A : out STD_LOGIC;
    A_mem_WEN_A : out STD_LOGIC_VECTOR ( 0 to 0 );
    A_mem_Addr_A : out STD_LOGIC_VECTOR ( 31 downto 0 );
    A_mem_Din_A : out STD_LOGIC_VECTOR ( 7 downto 0 );
    A_mem_Dout_A : in STD_LOGIC_VECTOR ( 7 downto 0 );
    B_mem_Clk_A : out STD_LOGIC;
    B_mem_Rst_A : out STD_LOGIC;
    B_mem_EN_A : out STD_LOGIC;
    B_mem_WEN_A : out STD_LOGIC_VECTOR ( 0 to 0 );
    B_mem_Addr_A : out STD_LOGIC_VECTOR ( 31 downto 0 );
    B_mem_Din_A : out STD_LOGIC_VECTOR ( 7 downto 0 );
    B_mem_Dout_A : in STD_LOGIC_VECTOR ( 7 downto 0 );
    C_mem_Clk_A : out STD_LOGIC;
    C_mem_Rst_A : out STD_LOGIC;
    C_mem_EN_A : out STD_LOGIC;
    C_mem_WEN_A : out STD_LOGIC_VECTOR ( 3 downto 0 );
    C_mem_Addr_A : out STD_LOGIC_VECTOR ( 31 downto 0 );
    C_mem_Din_A : out STD_LOGIC_VECTOR ( 31 downto 0 );
    C_mem_Dout_A : in STD_LOGIC_VECTOR ( 31 downto 0 )
  );

end systolic_4x4_0;

architecture stub of systolic_4x4_0 is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "ap_local_block,ap_local_deadlock,ap_clk,ap_rst,ap_start,ap_done,ap_idle,ap_ready,A_mem_Clk_A,A_mem_Rst_A,A_mem_EN_A,A_mem_WEN_A[0:0],A_mem_Addr_A[31:0],A_mem_Din_A[7:0],A_mem_Dout_A[7:0],B_mem_Clk_A,B_mem_Rst_A,B_mem_EN_A,B_mem_WEN_A[0:0],B_mem_Addr_A[31:0],B_mem_Din_A[7:0],B_mem_Dout_A[7:0],C_mem_Clk_A,C_mem_Rst_A,C_mem_EN_A,C_mem_WEN_A[3:0],C_mem_Addr_A[31:0],C_mem_Din_A[31:0],C_mem_Dout_A[31:0]";
attribute X_CORE_INFO : string;
attribute X_CORE_INFO of stub : architecture is "systolic_4x4,Vivado 2021.2";
begin
end;
