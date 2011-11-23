--------------------------------------------------------------------------------
--
-- spcis_test_lib.vhdl
--
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package spcis_test_lib is

    constant PCI_CLK_PERIOD : time := 30.3 ns;
 
    -- PCI command codes
    constant PCI_MEM_RD : std_logic_vector(3 downto 0) := x"6";
    constant PCI_MEM_WR : std_logic_vector(3 downto 0) := x"7";
    constant PCI_CONFIG_RD : std_logic_vector(3 downto 0) := x"a";
    constant PCI_CONFIG_WR : std_logic_vector(3 downto 0) := x"b";
    
    -- PCI configuration register addresses
    constant PCI_DEVICE_VENDOR : std_logic_vector(3 downto 0) := x"0";
    constant PCI_STATUS_COMMAND : std_logic_vector(3 downto 0) := x"1";
    constant PCI_CLASS_REV : std_logic_vector(3 downto 0) := x"2";
    constant PCI_LATENCY_CACHE : std_logic_vector(3 downto 0) := x"3";
    constant PCI_BAR0 : std_logic_vector(3 downto 0) := x"4";
    constant PCI_BAR1 : std_logic_vector(3 downto 0) := x"5";
    constant PCI_BAR2 : std_logic_vector(3 downto 0) := x"6";
    constant PCI_BAR3 : std_logic_vector(3 downto 0) := x"7";
    constant PCI_BAR4 : std_logic_vector(3 downto 0) := x"8";
    constant PCI_BAR5 : std_logic_vector(3 downto 0) := x"9";
    constant PCI_CARDBUS : std_logic_vector(3 downto 0) := x"a";
    constant PCI_SUB_VENDOR : std_logic_vector(3 downto 0) := x"b";
    constant PCI_EXP_ROM : std_logic_vector(3 downto 0) := x"c";
    constant PCI_CAP_PTR : std_logic_vector(3 downto 0) := x"d";
    constant PCI_LAT_GNT_PIN_LINE : std_logic_vector(3 downto 0) := x"f";
 
    -- PCI bus signals
    type pci_bus_t is record
        idsel : std_logic;
        n_gnt : std_logic;
        ad : std_logic_vector(31 downto 0);
        c_n_be : std_logic_vector(3 downto 0);
        n_frame : std_logic;
        n_devsel : std_logic;  
        n_trdy : std_logic;
        n_irdy : std_logic;
        n_stop : std_logic;      
        n_inta : std_logic;
        par : std_logic;
        n_req : std_logic;
    end record;
      
    procedure reset_gen(
            signal clk : in std_logic;
            signal rst : out std_logic);
    procedure pci_clk_gen(
            signal stop : in boolean;
            signal clk : out std_logic);
    procedure pci_pull(
            signal pci_bus : out pci_bus_t); 
    procedure pci_z(
            signal pci_bus : out pci_bus_t); 

    -- for reading/writing to pci target config registers
    procedure pci_read_config(
            signal clk : in std_logic;
            signal pci_bus : inout pci_bus_t;
            constant address : in std_logic_vector(3 downto 0);
            variable data : out std_logic_vector(31 downto 0)); 
    procedure pci_write_config(
            signal clk : in std_logic;
            signal pci_bus : inout pci_bus_t;
            constant address : in std_logic_vector(3 downto 0);
            constant data : in std_logic_vector(31 downto 0));
    procedure pci_read_config(
            signal clk : in std_logic;
            signal pci_bus : inout pci_bus_t;
            constant address : in std_logic_vector(3 downto 0);
            constant n_byte_en : in std_logic_vector(3 downto 0);
            variable data : out std_logic_vector(31 downto 0)); 
    procedure pci_write_config(
            signal clk : in std_logic;
            signal pci_bus : inout pci_bus_t;
            constant address : in std_logic_vector(3 downto 0);
            constant n_byte_en : in std_logic_vector(3 downto 0);
            constant data : in std_logic_vector(31 downto 0));

    -- for generating bus cycles on internal bus
    procedure pci_read(
            signal clk : in std_logic;
            signal pci_bus : inout pci_bus_t;
            constant address : in std_logic_vector(31 downto 0);
            variable data : out std_logic_vector(31 downto 0));
    procedure pci_write(
            signal clk : in std_logic;
            signal pci_bus : inout pci_bus_t;
            constant address : in std_logic_vector(31 downto 0);
            constant data : in std_logic_vector(31 downto 0)); 
    procedure pci_read(
            signal clk : in std_logic;
            signal pci_bus : inout pci_bus_t;
            constant address : in std_logic_vector(31 downto 0);
            constant n_byte_en : in std_logic_vector(3 downto 0);
            variable data : out std_logic_vector(31 downto 0));
    procedure pci_write(
            signal clk : in std_logic;
            signal pci_bus : inout pci_bus_t;
            constant address : in std_logic_vector(31 downto 0);
            constant n_byte_en : in std_logic_vector(3 downto 0);
            constant data : in std_logic_vector(31 downto 0)); 

    -- base pci read and write procedures
    procedure pci_read(
            signal clk : in std_logic;
            signal pci_bus : inout pci_bus_t;
            constant cmd : in std_logic_vector(3 downto 0);
            constant address : in std_logic_vector(31 downto 0);
            constant delay : in integer;
            constant n_byte_en : in std_logic_vector(3 downto 0);
            variable data : out std_logic_vector(31 downto 0)); 
    procedure pci_write(
            signal clk : in std_logic;
            signal pci_bus : inout pci_bus_t;
            constant cmd : in std_logic_vector(3 downto 0);
            constant address : in std_logic_vector(31 downto 0);
            constant delay : in integer;
            constant n_byte_en : in std_logic_vector(3 downto 0);
            constant data : in std_logic_vector(31 downto 0));

    procedure set_mem_en(
            signal clk : in std_logic;
            signal pci_bus : inout pci_bus_t;
            constant en : in std_logic);

    procedure pci_master_slave_trans(
            signal clk : in std_logic;
            signal pci_bus : inout pci_bus_t;
            constant address : in std_logic_vector(31 downto 0)); 

    -- local bus monitor
    procedure lb_cycle_monitor(
            signal clk : in std_logic;
            signal data_in : in std_logic_vector(31 downto 0);        
            signal ack : in std_logic;
            signal data_out : in std_logic_vector(31 downto 0);
            signal addr : in std_logic_vector;
            signal byte_en : in std_logic_vector(3 downto 0);
            signal rd : in std_logic;
            signal wr : in std_logic;
            signal last_lb_data_in : out std_logic_vector(31 downto 0);
            signal last_lb_data_out : out std_logic_vector(31 downto 0);
            signal last_lb_acked : out std_logic;
            signal last_lb_addr : out std_logic_vector;
            signal last_lb_byte_en : out std_logic_vector(3 downto 0);
            signal last_lb_rd : out std_logic;
            signal last_lb_wr : out std_logic);

end;

package body spcis_test_lib is

    -- drive and then release reset
    procedure reset_gen(
            signal clk : in std_logic;
            signal rst : out std_logic) is
    begin
        rst <= '1';
        wait for 250 ns;
        wait until rising_edge(clk);
        rst <= '0';
        wait;
    end procedure;
    
    -- generate 33MHz clock
    procedure pci_clk_gen(
            signal stop : in boolean;
            signal clk : out std_logic) is
        variable clk_v : std_logic := '0';
    begin
        loop
            if stop then
                exit;
            end if;
            clk <= clk_v;
            wait for PCI_CLK_PERIOD / 2;
            clk_v := not clk_v;
        end loop;
        wait;
    end procedure;
    
    -- pull up/down PCI signals
    procedure pci_pull(
            signal pci_bus : out pci_bus_t) is
    begin
        pci_bus.idsel <= 'L';
        pci_bus.n_gnt <= 'H';
        pci_bus.ad <= (others => 'H');        
        pci_bus.c_n_be <= "HHHH";
        pci_bus.n_frame <= 'H';
        pci_bus.n_devsel <= 'H';  
        pci_bus.n_trdy <= 'H';
        pci_bus.n_irdy <= 'H';
        pci_bus.n_stop <= 'H';
        pci_bus.n_inta <= 'H';
        pci_bus.par <= 'H';
        pci_bus.n_req <= 'H';
    end procedure;

    -- set PCI signals to high impedance
    procedure pci_z(
            signal pci_bus : out pci_bus_t) is
    begin
        pci_bus.idsel <= 'Z';
        pci_bus.n_gnt <= 'Z';
        pci_bus.ad <= (others => 'Z');        
        pci_bus.c_n_be <= "ZZZZ";
        pci_bus.n_frame <= 'Z';
        pci_bus.n_devsel <= 'Z';  
        pci_bus.n_trdy <= 'Z';
        pci_bus.n_irdy <= 'Z';
        pci_bus.n_stop <= 'Z';
        pci_bus.n_inta <= 'Z';
        pci_bus.par <= 'Z';
        pci_bus.n_req <= 'Z';
    end procedure;

    -- read from PCI configuration memory
    procedure pci_read_config(
            signal clk : in std_logic;
            signal pci_bus : inout pci_bus_t;
            constant address : in std_logic_vector(3 downto 0);
            variable data : out std_logic_vector(31 downto 0)) is
    begin
        pci_read(clk, pci_bus, PCI_CONFIG_RD, "HHHH" & "HHHH" & "HHHH" & 
        "HHHH" & "HHHH" & "H000" & "00" & address & "00", 0, x"0", data);
    end procedure;

    -- write to PCI configuration memory
    procedure pci_write_config(
            signal clk : in std_logic;
            signal pci_bus : inout pci_bus_t;
            constant address : in std_logic_vector(3 downto 0);
            constant data : in std_logic_vector(31 downto 0)) is
    begin
        pci_write(clk, pci_bus, PCI_CONFIG_WR, "HHHH" & "HHHH" & "HHHH" & 
                "HHHH" & "HHHH" & "H000" & "00" & address & "00", 0, x"0", 
                data);
    end procedure;
 
    -- read from PCI configuration memory with byte enables
    procedure pci_read_config(
            signal clk : in std_logic;
            signal pci_bus : inout pci_bus_t;
            constant address : in std_logic_vector(3 downto 0);
            constant n_byte_en : in std_logic_vector(3 downto 0);
            variable data : out std_logic_vector(31 downto 0)) is
    begin
        pci_read(clk, pci_bus, PCI_CONFIG_RD, "HHHH" & "HHHH" & "HHHH" & 
                "HHHH" & "HHHH" & "H000" & "00" & address & "00", 0, 
                n_byte_en, data);
    end procedure;

    -- write to PCI configuration memory with byte enables
    procedure pci_write_config(
            signal clk : in std_logic;
            signal pci_bus : inout pci_bus_t;
            constant address : in std_logic_vector(3 downto 0);
            constant n_byte_en : in std_logic_vector(3 downto 0);
            constant data : in std_logic_vector(31 downto 0)) is
    begin
        pci_write(clk, pci_bus, PCI_CONFIG_WR, "HHHH" & "HHHH" & "HHHH" & 
                "HHHH" & "HHHH" & "H000" & "00" & address & "00", 0, 
                n_byte_en, data);
    end procedure;
 
    -- read from PCI target memory 
    procedure pci_read(
            signal clk : in std_logic;
            signal pci_bus : inout pci_bus_t;
            constant address : in std_logic_vector(31 downto 0);
            variable data : out std_logic_vector(31 downto 0)) is
    begin
        pci_read(clk, pci_bus, PCI_MEM_RD, address, 0, x"0", data);
    end procedure;

    -- write to PCI target memory
    procedure pci_write(
            signal clk : in std_logic;
            signal pci_bus : inout pci_bus_t;
            constant address : in std_logic_vector(31 downto 0);
            constant data : in std_logic_vector(31 downto 0)) is
    begin
        pci_write(clk, pci_bus, PCI_MEM_WR, address, 0, x"0", data);
    end procedure;
 
    -- read from PCI target memory with byte enables
    procedure pci_read(
            signal clk : in std_logic;
            signal pci_bus : inout pci_bus_t;
            constant address : in std_logic_vector(31 downto 0);
            constant n_byte_en : in std_logic_vector(3 downto 0);
            variable data : out std_logic_vector(31 downto 0)) is
    begin
        pci_read(clk, pci_bus, PCI_MEM_RD, address, 0, n_byte_en, data);
    end procedure;

    -- write to PCI target memory with byte enables
    procedure pci_write(
            signal clk : in std_logic;
            signal pci_bus : inout pci_bus_t;
            constant address : in std_logic_vector(31 downto 0);
            constant n_byte_en : in std_logic_vector(3 downto 0);
            constant data : in std_logic_vector(31 downto 0)) is
    begin
        pci_write(clk, pci_bus, PCI_MEM_WR, address, 0, n_byte_en, data);
    end procedure;

    -- read from PCI target with single data phase
    procedure pci_read(
            signal clk : in std_logic;
            signal pci_bus : inout pci_bus_t;
            constant cmd : in std_logic_vector(3 downto 0);
            constant address : in std_logic_vector(31 downto 0);
            constant delay : in integer;
            constant n_byte_en : in std_logic_vector(3 downto 0);
            variable data : out std_logic_vector(31 downto 0)) is
        variable i : integer;
    begin
        pci_bus.ad <= address; 
        pci_bus.n_frame <= '0';
        if cmd = PCI_CONFIG_RD then
            pci_bus.idsel <= '1';
        end if;
        pci_bus.c_n_be <= cmd;
        wait until falling_edge(clk);
        pci_bus.idsel <= 'L';
        pci_bus.ad <= (others => 'Z');
        pci_bus.c_n_be <= n_byte_en;
        i := delay;
        while i > 0 loop
            i := i - 1;
            wait until falling_edge(clk);
        end loop;
        pci_bus.n_frame <= 'Z';
        pci_bus.n_irdy <= '0';        
        loop
            wait until rising_edge(clk);
            if pci_bus.n_trdy = '0' then
                data := pci_bus.ad;
                exit;
            end if;
        end loop;
        wait until falling_edge(clk);
        pci_bus.c_n_be <= (others => 'Z');
        pci_bus.n_irdy <= 'Z';
        wait until falling_edge(clk);
    end procedure;
    
    -- write to PCI target with single data phase
    procedure pci_write(
            signal clk : in std_logic;
            signal pci_bus : inout pci_bus_t;
            constant cmd : in std_logic_vector(3 downto 0);
            constant address : in std_logic_vector(31 downto 0);
            constant delay : in integer;
            constant n_byte_en : in std_logic_vector(3 downto 0);
            constant data : in std_logic_vector(31 downto 0)) is
        variable i : integer;
    begin
        pci_bus.ad <= address;        
        pci_bus.n_frame <= '0';
        if cmd = PCI_CONFIG_WR then
            pci_bus.idsel <= '1';
        end if;
        pci_bus.c_n_be <= cmd;
        wait until falling_edge(clk);
        pci_bus.idsel <= 'L';
        pci_bus.ad <= data;
        pci_bus.c_n_be <= n_byte_en;
        i := delay;
        while i > 0 loop
            i := i - 1;
            wait until falling_edge(clk);
        end loop;
        pci_bus.n_frame <= 'Z';
        pci_bus.n_irdy <= '0'; 
        loop
            wait until rising_edge(clk);
            if pci_bus.n_trdy = '0' then
                exit;
            end if;
        end loop;
        wait until falling_edge(clk);
        pci_bus.ad <= (others => 'Z');
        pci_bus.c_n_be <= (others => 'Z');
        pci_bus.n_irdy <= 'Z';
        wait until falling_edge(clk);
    end procedure;

    -- set memory enable in command register
    procedure set_mem_en(
            signal clk : in std_logic;
            signal pci_bus : inout pci_bus_t;
            constant en : in std_logic) is
    begin
        pci_write_config(clk, pci_bus, PCI_STATUS_COMMAND, x"0000000" & "00" 
                & en & '0');
    end procedure;

    -- generate PCI transaction with master and target responding
    procedure pci_master_slave_trans(
            signal clk : in std_logic;
            signal pci_bus : inout pci_bus_t;
            constant address : in std_logic_vector(31 downto 0)) is
    begin
        pci_bus.ad <= address; 
        pci_bus.n_frame <= '0';
        pci_bus.c_n_be <= PCI_MEM_WR;
        wait until falling_edge(clk);
        pci_bus.ad <= x"00000000"; 
        pci_bus.c_n_be <= x"0";
        wait until falling_edge(clk);
        pci_bus.n_frame <= '1';
        pci_bus.n_irdy <= '0';        
        wait until falling_edge(clk);
        pci_bus.n_frame <= 'Z';
        wait until falling_edge(clk);
        pci_bus.n_trdy <= '0';        
        wait until falling_edge(clk);
        pci_bus.ad <= (others => 'Z');
        pci_bus.c_n_be <= (others => 'Z');
        pci_bus.n_irdy <= '1';        
        pci_bus.n_trdy <= '1';        
        wait until falling_edge(clk);
        pci_bus.n_irdy <= 'Z';        
        pci_bus.n_trdy <= 'Z';        
    end procedure;

    -- monitor local bus 
    procedure lb_cycle_monitor(
            signal clk : in std_logic;
            signal data_in : in std_logic_vector(31 downto 0);        
            signal ack : in std_logic;
            signal data_out : in std_logic_vector(31 downto 0);
            signal addr : in std_logic_vector;
            signal byte_en : in std_logic_vector(3 downto 0);
            signal rd : in std_logic;
            signal wr : in std_logic;
            signal last_lb_data_in : out std_logic_vector(31 downto 0);
            signal last_lb_data_out : out std_logic_vector(31 downto 0);
            signal last_lb_acked : out std_logic;
            signal last_lb_addr : out std_logic_vector;
            signal last_lb_byte_en : out std_logic_vector(3 downto 0);
            signal last_lb_rd : out std_logic;
            signal last_lb_wr : out std_logic) is
        variable i : integer := 0;
    begin
        loop
            wait until falling_edge(clk);
            if rd = '1' or wr = '1' then
                last_lb_rd <= rd;
                last_lb_wr <= wr;
                exit;
            end if;
        end loop;
        last_lb_data_out <= data_out;
        last_lb_addr <= addr;
        last_lb_byte_en <= byte_en;
        loop
            if ack = '1' then
                last_lb_acked <= '1';
                last_lb_data_in <= data_in;
                exit;
            else
                last_lb_acked <= '0';
            end if;
            if i = 3 then
                exit;
            end if;
            i := i + 1;
            wait until falling_edge(clk);
        end loop;
    end procedure;

end;

