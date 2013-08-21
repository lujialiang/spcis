#
# spcis_sim_lib.tcl
#

# PCI master for generating PCI cycles to drive PCI slave
class PCIMaster {
    inport n_trdy 
    outport idsel n_frame n_irdy c_n_be  
    ioport ad

    variable irdyDelay 1

    # PCI command codes
    ro variable MEM_RD 0x6;
    ro variable MEM_WR 0x7;
    ro variable CONFIG_RD 0xa;
    ro variable CONFIG_WR 0xb;

    # PCI configuration register addresses
    ro variable DEVICE_VENDOR 0x0
    ro variable STATUS_COMMAND 0x1
    ro variable CLASS_REV 0x2
    ro variable LATENCY_CACHE 0x3 
    ro variable BAR0 0x4
    ro variable BAR1 0x5
    ro variable BAR2 0x6
    ro variable BAR3 0x7
    ro variable BAR4 0x8
    ro variable BAR5 0x9
    ro variable CARDBUS 0xa
    ro variable SUB_VENDOR 0xb
    ro variable EXP_ROM 0xc
    ro variable CAP_PTR 0xd
    ro variable LAT_GNT_PIN_LINE 0xf
 
    method readConfig {reg {nByteEn 0}} {
        return [readCycle $CONFIG_RD \
                0b[getbits -bin {%21 *0bz %5 0 %4 [set $reg] %2 0]} $nByteEn]
    }
    
    method writeConfig {reg data {nByteEn 0}} {
        return [writeCycle $CONFIG_WR \ 
                0b[getbits -bin {%21 *0bz %5 0 %4 [set $reg] %2 0]} $data \
                $nByteEn]
    }

    method readMem {addr {nByteEn 0}} {
        return [readCycle $MEM_RD $addr $nByteEn]
    }

    method writeMem {addr data {nByteEn 0}} {
        writeCycle $MEM_WR $addr $data $nByteEn
    }

    # set memory enable in command register
    method setMemEn {en} {
        writeConfig $STATUS_COMMAND [expr {$en << 1}]
    }

    # read from PCI target with single data phase
    private method readCycle {cmd addr nByteEn} {
        set ad $addr
        set n_frame 0
        if {$cmd == $CONFIG_RD}
            set idsel 1
        }
        set c_n_be $cmd
        at +clk
        set idsel 0
        set ad *0bz
        set c_n_be $nByteEn
        at $irdyDelay +clk
        set n_frame 0bz
        set n_irdy 0
        at +clk {!$n_trdy}
        set data $ad
        at +clk
        set c_n_be *0bz
        set n_irdy 0bz
        at +clk
        return $data
    }

    # write to PCI target with single data phase
    private method writeCycle {cmd addr data nByteEn} {
        set ad $addr
        set frame 0
        if {$cmd == $CONFIG_WR} {
            set idsel 1
        }
        set c_n_be $cmd
        at +clk
        set idsel 0bz
        set ad $data
        set c_n_be $nByteEn
        at $irdyDelay +clk
        set n_frame 0bz
        set n_rdy 0
        at +clk {!$n_trdy}
        set ad *0bz 
        set c_n_be *0bz
        set n_irdy 0bz
        at +clk
    }

    # generate PCI transaction with master and target responding
    private method masterWithNoSlave {addr} {
        set ad $addr
        set n_frame 0
        set c_n_be $MEM_WR
        at +clk
        set ad 0
        set c_n_be 0
        at +clk
        set n_frame 1
        set n_irdy 0
        at +clk
        set n_frame 0bz
        at +clk
        set n_trdy 0
        at +clk
        set ad *0bz
        set c_n_be *0bz
        set n_irdy 1
        set n_trdy 1
        at +clk
        set n_irdy 0bz
        set n_trdy 0bz
    }
}

# local bus monitor
class LBMonitor {
    inport clk rst data_in addr byte_en rd wr 
    outport data_out ack int

    ro variables lastRd lastWr lastAddr lastByteEn lastDataIn lastDataOut \
            lastAck 

    method start {} {
        run * {
            at +clk {$rd || $wr}
            set lastRd $rd
            set lastWr $wr
            set lastDataOut $data_out
            set lastAddr $addr
            set lastByteEn $byte_en
            if {$ack} {
                set lastAck 1
            } else {
                at +clk {$ack} -countout 3
                set lastAck [expr {![thread countout]}]
            }
            set lastDataIn $data_in
            at +clk
        }
    }
}

