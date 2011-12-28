#
# spcis ttaskfile
#
config simulator modelsim
set tests {spcis_test}

task sim {sim build -exe gui -index 1}
task test {sim build -exe noGui -index 1}
task clean {rmdir build}

project add sim -type $simulator
sim src -add {rtl/*.vhdl sim/*.vhdl} 
sim build -buildDir build -tests $tests

