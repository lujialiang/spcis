--------------------------------------------------------------------------------
--
-- spcis.vhdl
--
-- Top level PCI slave module
--
--------------------------------------------------------------------------------
--
--   -------------------------
-- --|clk                    |--
-- --|rst                    |--
-- --|                       |--
-- --|idsel              ad[]|--
-- --|c_n_be[]       n_devsel|--
-- --|n_frame          n_trdy|--
-- --|n_irdy           n_stop|--
-- --|                 n_inta|--
-- --|                    par|--
-- --|                       |--
-- --|data_in[]    data_out[]|--
-- --|ack              addr[]|--
-- --|int           byte_en[]|--
-- --|                     rd|--
-- --|                     wr|--
--   -------------------------
--
-- clk : 33MHz PCI clock
-- rst : async reset
--
-- idsel : PCI IDSEL
-- c_n_be : PCI C/BE#
-- n_frame : PCI FRAME#
-- n_irdy : PCI IRDY#
-- ad : PCI AD
-- n_devsel : PCI DEVSEL#
-- n_trdy : PCI TRDY#
-- n_stop : PCI STOP#
-- n_inta : PCI INTA#
-- par : PCI PAR
--
-- data_in : local bus data in
-- ack : local bus acknowledgement
-- int : local bus interrupt
-- data_out : local bus data out
-- addr : local bus address
-- byte_en : local bus byte enables
-- rd : local bus read 
-- wr : local bus write 
--
--------------------------------------------------------------------------------
--
-- VENDOR_ID : PCI Vendor ID code
-- DEVICE_ID : PCI Device ID code
-- SUBSYSTEM_VENDOR_ID : PCI Subsystem Vendor ID code
-- SUBSYSTEM_ID : PCI Subsystem ID code
-- REVISION_ID : PCI Revision ID code
-- CLASS_CODE : PCI Class code
-- BAR0_LSB : least significant bit for BAR0 decoder 
-- LB_ADDR_WIDTH : local bus address width
--
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spcis is
    generic (
        VENDOR_ID : std_logic_vector(15 downto 0) := x"10ee"; -- Xilinx
        DEVICE_ID : std_logic_vector(15 downto 0) := x"3210";
        SUBSYSTEM_VENDOR_ID : std_logic_vector(15 downto 0) := x"7654";
        SUBSYSTEM_ID : std_logic_vector(15 downto 0) := x"ba98";
        REVISION_ID : std_logic_vector(7 downto 0) := x"00";
        CLASS_CODE : std_logic_vector(23 downto 0) := x"ff0000";
        BAR0_LSB : integer := 25;
        LB_ADDR_WIDTH : integer := 8
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
                
        idsel : in std_logic;
        c_n_be : in std_logic_vector(3 downto 0);       
        n_frame : in std_logic;
        n_irdy : in std_logic;
        ad : inout std_logic_vector(31 downto 0);
        n_devsel : out std_logic;     
        n_trdy : out std_logic;
        n_stop : out std_logic;   
        n_inta : out std_logic; 
        par : out std_logic; 
        
        data_in : in std_logic_vector(31 downto 0);        
        ack : in std_logic;
        int : in std_logic;
        data_out : out std_logic_vector(31 downto 0);
        addr : out std_logic_vector(LB_ADDR_WIDTH - 1 downto 0);
        byte_en : out std_logic_vector(3 downto 0);
        rd : out std_logic;
        wr : out std_logic        
    );
end spcis;

architecture rtl of spcis is

    -- for u1_io
    signal idsel_in : std_logic;
    signal c_n_be_in : std_logic_vector(3 downto 0);
    signal n_frame_in : std_logic;
    signal n_irdy_in : std_logic;
    signal ad_in : std_logic_vector(31 downto 0);
    signal ad_out : std_logic_vector(31 downto 0);
        
    -- for u2_slave_controller
    signal claim_trans : std_logic;
    signal pci_write : std_logic;
    signal next_phase : std_logic;
    signal config_trans : std_logic;
    signal bar0_trans : std_logic;
    signal sc_ack : std_logic;
    signal sc_data_out : std_logic_vector(31 downto 0);
    signal sc_addr : std_logic_vector(LB_ADDR_WIDTH - 1 downto 0);
    signal sc_byte_en : std_logic_vector(3 downto 0);
    signal sc_rd : std_logic;
    signal sc_wr : std_logic;
    
    -- for u3_config_regs
    signal config_rd : std_logic;
    signal config_wr : std_logic;
    signal config_data_out : std_logic_vector(31 downto 0);
    signal config_ack : std_logic;
    signal en_mem : std_logic;
    signal bar0_decode : std_logic;
    
begin           
    
    u1_io : entity work.io
    port map (
        clk => clk,
        rst => rst,         
        idsel_i => idsel,
        c_n_be_i => c_n_be,
        n_frame_i => n_frame,
        n_irdy_i => n_irdy,
        ad_io => ad,
        n_devsel_o => n_devsel,
        n_trdy_o => n_trdy,
        n_stop_o => n_stop, 
        n_inta_o => n_inta,
        par_o => par,
        int => int, 
        idsel_in_o => idsel_in,
        c_n_be_in_o => c_n_be_in,
        n_frame_in_o => n_frame_in,
        n_irdy_in_o => n_irdy_in,
        ad_in_o => ad_in,
        claim_trans => claim_trans,
        pci_write => pci_write,
        ad_out_i => ad_out,
        next_phase => next_phase
    );
    ad_out <= config_data_out when config_trans = '1' else data_in; 
    
    u2_slave_controller : entity work.slave_controller 
    generic map (
        LB_ADDR_WIDTH => LB_ADDR_WIDTH
    )
    port map (
        clk => clk,
        rst => rst,
        ad => ad_in,
        idsel => idsel_in,
        c_n_be => c_n_be_in,
        n_frame => n_frame_in,
        n_irdy => n_irdy_in,
        en_mem => en_mem,
        bar0_decode => bar0_decode,
        claim_trans => claim_trans,
        pci_write => pci_write,
        next_phase => next_phase,
        config_trans => config_trans,
        bar0_trans => bar0_trans,
        ack => sc_ack,
        data_out => sc_data_out,
        addr => sc_addr,
        byte_en => sc_byte_en,
        rd => sc_rd,
        wr => sc_wr
    );          
    sc_ack <= ack when bar0_trans = '1' else config_ack;
     
    u3_config_regs : entity work.config_regs 
    generic map (
        VENDOR_ID => VENDOR_ID,
        DEVICE_ID => DEVICE_ID,
        SUBSYSTEM_VENDOR_ID => SUBSYSTEM_VENDOR_ID,
        SUBSYSTEM_ID => SUBSYSTEM_ID,
        REVISION_ID => REVISION_ID,
        CLASS_CODE => CLASS_CODE,
        BAR0_LSB => BAR0_LSB
    )
    port map (
        clk => clk,
        rst => rst,
        data_in => sc_data_out, 
        addr => sc_addr(3 downto 0),
        byte_en => sc_byte_en,
        rd => config_rd,
        wr => config_wr,
        data_out => config_data_out,
        ack => config_ack,
        pci_addr => ad_in(31 downto BAR0_LSB),
        en_mem => en_mem,
        bar0_decode => bar0_decode
    );
    config_rd <= sc_rd and config_trans;
    config_wr <= sc_wr and config_trans;

    data_out <= sc_data_out;
    addr <= sc_addr;
    byte_en <= sc_byte_en;
    rd <= sc_rd and bar0_trans;
    wr <= sc_wr and bar0_trans; 
end;

