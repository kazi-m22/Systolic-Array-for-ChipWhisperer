onbreak {quit -f}
onerror {quit -f}

vsim -lib xil_defaultlib systolic_4x4_0_opt

set NumericStdNoWarnings 1
set StdArithNoWarnings 1

do {wave.do}

view wave
view structure
view signals

do {systolic_4x4_0.udo}

run -all

quit -force
