
vlib work
vcom ../rtl/io.vhdl
vcom ../rtl/slave_controller.vhdl 
vcom ../rtl/config_regs.vhdl 
vcom ../rtl/spcis.vhdl
vcom ../sim/spcis_test_lib.vhdl
vcom ../sim/spcis_test.vhdl
vsim spcis_test
add wave *
run -all

