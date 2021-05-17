vlib work
vlib riviera

vlib riviera/xil_defaultlib

vmap xil_defaultlib riviera/xil_defaultlib

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../radar_emulate.srcs/sources_1/ip/vio_0_5/hdl/verilog" "+incdir+../../../../radar_emulate.srcs/sources_1/ip/vio_0_5/hdl" \
"../../../../radar_emulate.srcs/sources_1/ip/vio_0_5/sim/vio_0.v" \


vlog -work xil_defaultlib \
"glbl.v"

