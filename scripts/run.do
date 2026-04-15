vlib work
vmap work work
vlog rtl/*.v
vlog tb/tb_riscv_pipeline.v
vsim work.tb_riscv_pipeline
add wave -r *
run 300ns