vlib work
vlib activehdl

vlib activehdl/xil_defaultlib

vmap xil_defaultlib activehdl/xil_defaultlib

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../radar_emulate.srcs/sources_1/ip/vio_0_4/hdl/verilog" "+incdir+../../../../radar_emulate.srcs/sources_1/ip/vio_0_4/hdl" \
"../../../../radar_emulate.srcs/sources_1/ip/vio_0_4/sim/vio_0.v" \


vlog -work xil_defaultlib \
"glbl.v"

