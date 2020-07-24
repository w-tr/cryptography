vlib crypto_lib

vcom ../rtl/lfsr_galois.vhd -2008 -work crypto_lib
vcom ../rtl/lfsr8_11d.vhd -2008 -work crypto_lib
vcom ../tb/tb_lfsr_galois.vhd -2008 -work crypto_lib

vsim crypto_lib.tb_lfsr_galois
