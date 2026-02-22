vlib modelsim_lib/work
vlib modelsim_lib/msim

vlib modelsim_lib/msim/xil_defaultlib

vmap xil_defaultlib modelsim_lib/msim/xil_defaultlib

vlog -work xil_defaultlib  -incr -mfcu \
"../../../ipstatic/hdl/verilog/systolic_4x4_flow_control_loop_pipe_sequential_init.v" \
"../../../ipstatic/hdl/verilog/systolic_4x4_localA_V_RAM_AUTO_1R1W.v" \
"../../../ipstatic/hdl/verilog/systolic_4x4_localC_V_RAM_AUTO_1R1W.v" \
"../../../ipstatic/hdl/verilog/systolic_4x4_mac_muladd_8s_8s_32s_32_4_1.v" \
"../../../ipstatic/hdl/verilog/systolic_4x4_mux_647_8_1_1.v" \
"../../../ipstatic/hdl/verilog/systolic_4x4_mux_647_32_1_1.v" \
"../../../ipstatic/hdl/verilog/systolic_4x4_systolic_4x4_Pipeline_VITIS_LOOP_23_1_VITIS_LOOP_24_2.v" \
"../../../ipstatic/hdl/verilog/systolic_4x4_systolic_4x4_Pipeline_VITIS_LOOP_31_3_VITIS_LOOP_32_4.v" \
"../../../ipstatic/hdl/verilog/systolic_4x4_systolic_4x4_Pipeline_VITIS_LOOP_39_5_VITIS_LOOP_40_6.v" \
"../../../ipstatic/hdl/verilog/systolic_4x4_systolic_4x4_Pipeline_VITIS_LOOP_47_7_VITIS_LOOP_48_8.v" \
"../../../ipstatic/hdl/verilog/systolic_4x4_systolic_4x4_Pipeline_VITIS_LOOP_58_10_VITIS_LOOP_59_11.v" \
"../../../ipstatic/hdl/verilog/systolic_4x4.v" \
"../../../ip/systolic_4x4_0_1/sim/systolic_4x4_0.v" \


vlog -work xil_defaultlib \
"glbl.v"

