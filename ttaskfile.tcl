#
# spcis ttaskfile
#
set tests {spcis_test}

task sim {sim build -exe gui -index 1}
task test {sim build -exe noGui -index 1}
task clean {rmdir build}

project add sim -type modelsim
sim src -addRtl rtl/*.vhdl -addSim sim/*.vhdl 
sim build -buildDir build -tests $tests

