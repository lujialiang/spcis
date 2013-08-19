#
# spcis_test.tcl
#

source -normalize spcis_sim_lib.tcl

set pci [new PCIMaster]
set lb [new LBMonitor]
$pci connect -all
$lb connect -others {data_in data_out} {data_out data_in}

signal ad_pu %32 *0bh
signal n_devsel_pu 0bh
signal n_trdy_pu 0bh
signal n_stop_pu 0bh
signal n_inta_pu 0bh
signal par_pu 0bh
connect {ad_pu ad} {n_devsel_pu n_devsel} {n_trdy_pu n_trdy} \
        {n_stop_pu n_stop} {n_inta_pu n_inta} {par_pu par}

run * {in 15.151; inv clk}

set rst 0
in 1us

# -----------------------------------------------------------------------------

testcase "spcis testcase" -tests 6

check {[getbits -unresolved -bin {ad n_devsel n_trdy n_stop n_inta par}] == \
        [getbits -bin {%37 *0bz}]}
tested "all in/outs are z at reset"

$lb run
at +clk; set rst 0

check {[$pci readConfig DEVICE_VENDOR] == 0x321010ee} 
check {[$pci readConfig STATUS_CMD] == 0x04000000}
check {[$pci readConfig CLASS_REVISION] == 0xff000000} 
check {[$pci readConfig LATENCY_CACHE] == 0} 
for {set i 0} {$i < 6} {incr i} {
    check {[$pci readConfig BAR$i] == 0]} 
}
check {[$pci readConfig SUB_VENDOR] == 0xba987654} 
check {[$pci readConfig EX_PROM] == 0} 
check {[$pci readConfig CAPABILITIES_PTR] == 0} 
check {[$pci readConfig LATENCY_GRANT_PIN_LINE] == 0x000001ff} 
tested "configuration registers"

for {set i 0} {$i < 6} {incr i} {
    $pci writeConfig bar$i 0xffffffff 
    if {$i == 0} {
        check {[$pci readConfig BAR0] == 0xfe000000} 
    } else {
        check {[$pci readConfig BAR$i] == 0}
    }
}
tested "BAR memory decoder sizes"

# initialize access to local bus
set baseAddr 0xf0000000
$pci writeConfig bar0 $baseAddr
$pci setMemEn 1

$pci writeMem [expr {$baseAddr + 4}] 0x76543210  
check {[$lb get claimed type addr byteEn data] == \
        "yes wr 1 0xf 0x76543210"} 
check {[$pci readMem [expr {$baseAddr + 4}] == 0x77442200} 
check {[$lb get claimed type addr byteEn] == "yes read 1 0xf"} 
tested "local 32-bit bus cycles"

foreach be {0b1110 0b1101 0b1011 0b0111} {
    $pci writeMemBytes [expr {$baseAddr + 4}] $be 0x76543210
    check {[$lb get byteEn] == (!$be & 0xf)}
}
tested "local bus cycles with byte enables"

$pci writeMem [expr {$baseAddr + 8}] 0x76543210  
check {[$lb get claimed type addr] == "no wr 2"]} 
$pci readMem [expr {$baseAddr + 8}]
check [$lb get claimed type addr] == "no rd 2"] 
tested "missed local bus cycles"

testcase_complete

