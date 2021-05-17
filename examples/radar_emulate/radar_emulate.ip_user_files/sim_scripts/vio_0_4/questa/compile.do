vlib questa_lib/work
vlib questa_lib/msim

vlib questa_lib/msim/xil_defaultlib

vmap xil_defaultlib questa_lib/msim/xil_defaultlib

vlog -work xil_defaultlib -64 "+incdir+../../../../radar_emulate.srcs/sources_1/ip/vio_0_4/hdl/verilog" "+incdir+../../../../radar_emulate.srcs/sources_1/ip/vio_0_4/hdl" \
"../../../../radar_emulate.srcs/sources_1/ip/vio_0_4/sim/vio_0.v" \


vlog -work xil_defaultlib \
"glbl.v"

