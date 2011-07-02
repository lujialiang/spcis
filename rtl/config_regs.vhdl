--------------------------------------------------------------------------------
--
-- config_regs.vhdl
--
-- Implements slave PCI configuration registers; performs base address   
-- decoding 
--
--------------------------------------------------------------------------------
--
--   -------------------------
-- --|clk                    |--
-- --|rst                    |--
-- --|                       |--
-- --|data_in[]    data_out[]|--
-- --|addr[]              ack|--
-- --|byte_en[]              |--
-- --|rd                     |--
-- --|wr                     |--
-- --|                       |--
-- --|pci_addr[]       en_mem|--
-- --|            bar0_decode|--
--   -------------------------
--
-- clk : 33MHz clock
-- rst : async reset
--
-- data_in : local bus data in
-- addr : local bus address
-- byte_en : local bus byte enables
-- rd : local bus read signal
-- wr : local bus write signal
-- data_out : local bus data out
-- ack : local bus acknowledgement
--
-- pci_addr : PCI address for base address decoding
-- en_mem : enable BAR0 memory region
-- bar0_decode : pci_addr decodes against base address 0
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
--
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity config_regs is
    generic (
        VENDOR_ID : std_logic_vector(15 downto 0);
        DEVICE_ID : std_logic_vector(15 downto 0);
        SUBSYSTEM_VENDOR_ID : std_logic_vector(15 downto 0);
        SUBSYSTEM_ID : std_logic_vector(15 downto 0);
        REVISION_ID : std_logic_vector(7 downto 0);
        CLASS_CODE : std_logic_vector(23 downto 0);
        BAR0_LSB : integer);    
    port (
        clk : in std_logic;
        rst : in std_logic;
    
        data_in : in std_logic_vector(31 downto 0); 
        addr : in std_logic_vector(3 downto 0);
        byte_en : in std_logic_vector(3 downto 0);
        rd : in std_logic;
        wr : in std_logic;
        data_out : out std_logic_vector(31 downto 0);
        ack : out std_logic;       

        pci_addr : in std_logic_vector(31 downto BAR0_LSB);
        en_mem : out std_logic;
        bar0_decode : out std_logic
    );
end entity config_regs;

architecture rtl of config_regs is

    -- slow devsel timing
    constant DEV_SEL_TIMING : std_logic_vector(1 downto 0) := "10";
    
    -- interrupt A
    constant INT_PIN : std_logic_vector(7 downto 0) := x"01";
    
    signal en_mem_s : std_logic;
    signal bar0 : std_logic_vector(31 downto BAR0_LSB);
    signal int_line : std_logic_vector(7 downto 0);
    
    -- writes data to a pci base address register
    procedure write_bar (
            signal bar : out std_logic_vector;
            constant BAR_LSB : in integer) is        
    begin
        if BAR_LSB < 16 then
            if byte_en(1) = '1' then
                bar(15 downto BAR_LSB) <= data_in(15 downto BAR_LSB);
            end if;
            if byte_en(2) = '1' then
                bar(23 downto 16) <= data_in(23 downto 16);
            end if;
            if byte_en(3) = '1' then
                bar(31 downto 24) <= data_in(31 downto 24);
            end if;
        elsif BAR_LSB < 24 then        
            if byte_en(2) = '1' then
                bar(23 downto BAR_LSB) <= data_in(23 downto BAR_LSB);
            end if;
            if byte_en(3) = '1' then
                bar(31 downto 24) <= data_in(31 downto 24);
            end if;
        else
            if byte_en(3) = '1' then
                bar <= data_in(31 downto BAR_LSB);
            end if;
        end if;
    end procedure;

begin

    bus_control : process (clk, rst)
        variable ack_v : std_logic;
    begin
        if rst = '1' then
            ack_v := '0';
            en_mem_s <= '0';
            bar0 <= (others => '0');
            int_line <= x"ff";
            data_out <= (others => '0');
            ack <= '0';
        elsif rising_edge(clk) then
            data_out <= (others => '0');
            if ack_v = '0' then
                case addr is

                    -- device ID/vendor ID
                    when x"0" => 
                        if rd = '1' then
                            data_out <= DEVICE_ID & VENDOR_ID;
                        end if;
                        
                    -- status/command registers
                    when x"1" => 
                        if rd = '1' then
                            data_out(26 downto 25) <= DEV_SEL_TIMING;
                            data_out(1) <= en_mem_s;
                        elsif wr = '1' then
                            if byte_en(0) = '1' then
                                en_mem_s <= data_in(1);
                            end if;
                        end if;
                        
                    -- class code/revision ID
                    when x"2" =>
                        if rd = '1' then
                            data_out <= CLASS_CODE & REVISION_ID;
                        end if;
                        
                    -- base address 0
                    when x"4" =>
                        if rd = '1' then
                            data_out(31 downto BAR0_LSB) <= bar0;
                        elsif wr = '1' then
                            write_bar(bar0, BAR0_LSB);
                        end if;

                    -- subsystem ID/subsystem vendor ID
                    when x"b" => 
                        if rd = '1' then 
                            data_out <= SUBSYSTEM_ID & SUBSYSTEM_VENDOR_ID;
                        end if;
                    
                    -- interrupt pin/interrupt line
                    when x"f" =>
                        if rd = '1' then
                            data_out(15 downto 0) <= INT_PIN & int_line;
                        elsif wr = '1' and byte_en(0) = '1' then
                            int_line <= data_in(7 downto 0);
                        end if;

                    when others =>
                        null;

                end case;
            end if;

            if ack_v = '0' and (rd = '1' or wr = '1') then
                ack_v := '1';
            else
                ack_v := '0';
            end if;
            ack <= ack_v;
        end if;
    end process;

    en_mem <= en_mem_s;
    bar0_decode <= '1' when bar0 = pci_addr(31 downto BAR0_LSB) else '0';
end;

