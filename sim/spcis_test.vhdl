--------------------------------------------------------------------------------
--
-- spcis_test.vhdl
--
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.spcis_test_lib.all;
use work.tcase_lib.all;

entity spcis_test is
end entity;

architecture sim of spcis_test is

    -- for uut
    signal clk : std_logic;
    signal rst : std_logic; 
    signal pci_bus : pci_bus_t;
    signal data_in : std_logic_vector(31 downto 0);        
    signal ack : std_logic := '0';
    signal int : std_logic := '0';
    signal data_out : std_logic_vector(31 downto 0);
    signal addr : std_logic_vector(7 downto 0);
    signal byte_en : std_logic_vector(3 downto 0);
    signal rd : std_logic;
    signal wr : std_logic;
    
    -- for local bus monitor
    signal last_lb_data_in : std_logic_vector(31 downto 0);
    signal last_lb_data_out : std_logic_vector(31 downto 0);
    signal last_lb_acked : std_logic;
    signal last_lb_addr : std_logic_vector(7 downto 0);
    signal last_lb_byte_en : std_logic_vector(3 downto 0);
    signal last_lb_rd : std_logic;
    signal last_lb_wr : std_logic;

    signal stop : boolean := false;

begin
   
    uut : entity work.spcis port map (
        clk => clk,
        rst => rst,
        idsel => pci_bus.idsel, 
        c_n_be => pci_bus.c_n_be, 
        n_frame => pci_bus.n_frame,
        n_irdy => pci_bus.n_irdy, 
        ad => pci_bus.ad,
        n_devsel => pci_bus.n_devsel, 
        n_trdy => pci_bus.n_trdy,
        n_stop => pci_bus.n_stop,
        n_inta => pci_bus.n_inta,
        par => pci_bus.par,
        data_in => data_in,
        ack => ack,
        int => int,
        data_out => data_out,
        addr => addr,
        byte_en => byte_en,
        rd => rd,
        wr => wr
    );
    
    test : process
    begin
        test_case("spcis test case", 5);
        wait for 10 us;
        stop <= true;
        test_case_complete;
        wait;
    end process;
    
    process
        variable data : std_logic_vector(31 downto 0);
        constant BASE0 : std_logic_vector(15 downto 0) := x"f800";
    begin
        pci_z(pci_bus);
        wait for 1 us;
        wait until falling_edge(clk);

        -- check configuration register reset values
        pci_read_config(clk, pci_bus, PCI_DEVICE_VENDOR, data);
        assert data = x"321010ee" report "Error reading device/vendor ids";
        pci_read_config(clk, pci_bus, PCI_STATUS_COMMAND, data);
        assert data = x"04000000" report "Error reading status/command";
        pci_read_config(clk, pci_bus, PCI_CLASS_REV, data);
        assert data = x"ff000000" report "Error reading class/revision";
        pci_read_config(clk, pci_bus, PCI_LATENCY_CACHE, data);
        assert data = x"00000000" report "Error reading latency/cache";
        pci_read_config(clk, pci_bus, PCI_BAR0, data);
        assert data = x"00000000" report "Error reading BAR0";
        pci_read_config(clk, pci_bus, PCI_BAR1, data);
        assert data = x"00000000" report "Error reading BAR1";
        pci_read_config(clk, pci_bus, PCI_BAR2, data);
        assert data = x"00000000" report "Error reading BAR2";
        pci_read_config(clk, pci_bus, PCI_BAR3, data);
        assert data = x"00000000" report "Error reading BAR3";
        pci_read_config(clk, pci_bus, PCI_BAR4, data);
        assert data = x"00000000" report "Error reading BAR4";
        pci_read_config(clk, pci_bus, PCI_BAR5, data);
        assert data = x"00000000" report "Error reading BAR5";
        pci_read_config(clk, pci_bus, PCI_CARDBUS, data);
        assert data = x"00000000" report "Error reading cardbus";
        pci_read_config(clk, pci_bus, PCI_SUB_VENDOR, data);
        assert data = x"ba987654" report "Error reading subsystem ids";
        pci_read_config(clk, pci_bus, PCI_EXP_ROM, data);
        assert data = x"00000000" report "Error reading expansion rom";
        pci_read_config(clk, pci_bus, PCI_CAP_PTR, data);
        assert data = x"00000000" report "Error reading capabilities";
        pci_read_config(clk, pci_bus, PCI_LAT_GNT_PIN_LINE, data);
        assert data = x"000001ff" report "Error reading interrupt";
        test_complete("Register reset values test");

        -- test bar register block sizes 
        pci_write_config(clk, pci_bus, PCI_BAR0, x"ffffffff");
        pci_read_config(clk, pci_bus, PCI_BAR0, data);
        assert data = x"fe000000" report "Error reading BAR0 block size";
        pci_write_config(clk, pci_bus, PCI_BAR1, x"ffffffff");
        pci_read_config(clk, pci_bus, PCI_BAR1, data);
        assert data = x"00000000" report "Error reading BAR1 block size";
        pci_write_config(clk, pci_bus, PCI_BAR2, x"ffffffff");
        pci_read_config(clk, pci_bus, PCI_BAR2, data);
        assert data = x"00000000" report "Error reading BAR2 block size";
        pci_write_config(clk, pci_bus, PCI_BAR3, x"ffffffff");
        pci_read_config(clk, pci_bus, PCI_BAR3, data);
        assert data = x"00000000" report "Error reading BAR3 block size";
        pci_write_config(clk, pci_bus, PCI_BAR4, x"ffffffff");
        pci_read_config(clk, pci_bus, PCI_BAR4, data);
        assert data = x"00000000" report "Error reading BAR4 block size";
        pci_write_config(clk, pci_bus, PCI_BAR5, x"ffffffff");
        pci_read_config(clk, pci_bus, PCI_BAR5, data);
        assert data = x"00000000" report "Error reading BAR5 block size";
        test_complete("BAR sizes test");

        -- set up bar0 and enable memory decoding
        pci_write_config(clk, pci_bus, PCI_BAR0, BASE0 & x"0000");
        set_mem_en(clk, pci_bus, '1');

        -- test local bus read and write
        pci_write(clk, pci_bus, BASE0 & x"0004", x"76543210");
        assert last_lb_data_out = x"76543210" and last_lb_acked = '1' and 
                last_lb_addr = x"01" and last_lb_byte_en = "1111" and 
                last_lb_wr = '1'
                report "Error writing local bus";
        pci_read(clk, pci_bus, BASE0 & x"0004", data);
        assert last_lb_acked = '1' and last_lb_addr = x"01" and 
                last_lb_byte_en = "1111" and last_lb_rd = '1' and 
                data = x"77442200" 
                report "Error reading local bus";
        test_complete("LB test");

        -- test local bus timeout of four clock cycles 
        pci_write(clk, pci_bus, BASE0 & x"0008", x"76543210");
        assert last_lb_acked = '0' and last_lb_addr = x"02" and 
                last_lb_wr = '1'
                report "Error writing local bus with timeout";
        pci_read(clk, pci_bus, BASE0 & x"0008", data);
        assert last_lb_acked = '0' and last_lb_addr = x"02" and 
                last_lb_rd = '1'
                report "Error writing local bus with timeout";
        test_complete("LB timeout test");

        -- check individual byte enables appear on local bus
        pci_write(clk, pci_bus, BASE0 & x"0004", "1110", x"76543210");
        assert last_lb_byte_en = "0001" 
                report "Error testing byte enables";
        pci_read(clk, pci_bus, BASE0 & x"0004", "1101", data);
        assert last_lb_byte_en = "0010" 
                report "Error testing byte enables";
        pci_write(clk, pci_bus, BASE0 & x"0004", "1011", x"76543210");
        assert last_lb_byte_en = "0100" 
                report "Error testing byte enables";
        pci_read(clk, pci_bus, BASE0 & x"0004", "0111", data);
        assert last_lb_byte_en = "1000" 
                report "Error testing byte enables";
        test_complete("LB byte enables test");

        wait;
    end process;
    
    data_in <= x"77442200" when rd = '1' and addr = x"01" else (others => '0');
    ack <= '1' when (rd = '1' or wr = '1') and addr = x"01" else '0';
    
    -- monitor local bus 
    lb_cycle_monitor(clk, data_in, ack, data_out, addr, byte_en, rd, wr,
            last_lb_data_in, last_lb_data_out, last_lb_acked, last_lb_addr, 
            last_lb_byte_en, last_lb_rd, last_lb_wr);

    pci_pull(pci_bus);
    pci_clk_gen(stop, clk);
    reset_gen(clk, rst);
end;

