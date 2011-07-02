--------------------------------------------------------------------------------
--
-- slave_controller.vhdl
--
-- controller for slave transactions
--
--------------------------------------------------------------------------------
--
--   --------------------------
-- --|clk                     |--
-- --|rst                     |--
-- --|                        |--
-- --|ad[]                    |--
-- --|idsel                   |--
-- --|c_n_be[]                |--
-- --|n_frame                 |--
-- --|n_irdy                  |--
-- --|                        |--
-- --|en_mem       claim_trans|--
-- --|bar0_decode    pci_write|--
-- --|              next_phase|--
-- --|            config_trans|--
-- --|              bar0_trans|--
-- --|                        |--
-- --|ack           data_out[]|--
-- --|                  addr[]|--
-- --|               byte_en[]|--
-- --|                      rd|--
-- --|                      wr|--
--   --------------------------
--
-- clk : 33MHz clock
-- rst : async reset
--
-- ad : PCI AD
-- idsel : PCI IDSEL
-- c_n_be : PCI C/BE#
-- n_frame : PCI FRAME#
-- n_irdy : PCI IRDY#
--
-- en_mem : enable memory i/o operations
-- bar0_decode : base address 0 decoded
-- claim_trans : claim PCI bus transaction
-- pci_write : transaction to claim writes data to PCI bus
-- next_phase : perform transaction data phase
-- config_trans : transaction addressing PCI configuration registers
-- bar0_trans : transaction addressing local bus
--
-- ack : local acknowledgement
-- data_out : local bus data out
-- addr : local bus address out
-- byte_en : local bus byte enables
-- rd : local bus read signal
-- wr : local bus write signal
--
--------------------------------------------------------------------------------
--
-- LB_ADDR_WIDTH : Local bus address width. Must be at least 4 bits wide.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity slave_controller is
    generic (
        LB_ADDR_WIDTH : integer := 8
    );    
    port (
        clk : in std_logic;
        rst : in std_logic;
        
        ad : in std_logic_vector(31 downto 0);
        idsel : in std_logic;
        c_n_be : in std_logic_vector(3 downto 0);        
        n_frame : in std_logic;
        n_irdy : in std_logic;
                        
        en_mem : in std_logic;
        bar0_decode : in std_logic;
        claim_trans : out std_logic;
        pci_write : out std_logic;
        next_phase : out std_logic;
        config_trans : out std_logic;
        bar0_trans : out std_logic;
                
        ack : in std_logic;
        data_out : out std_logic_vector(31 downto 0);
        addr : out std_logic_vector(LB_ADDR_WIDTH - 1 downto 0);
        byte_en : out std_logic_vector(3 downto 0);
        rd : out std_logic;
        wr : out std_logic
    );    
end slave_controller; 

architecture rtl of slave_controller is

    type STATE_t is (STATE0, STATE1, STATE2, STATE3);
    signal state : STATE_t;   
    signal lb_write_trans : std_logic;
    signal timeout_count : unsigned(1 downto 0);
    signal read_config_decode : std_logic;
    signal write_config_decode : std_logic;
    signal read_mem_decode : std_logic;
    signal write_mem_decode : std_logic;
    signal cfg_addr_hit : std_logic;
    signal mem_addr_hit : std_logic;
    
begin
    
    slave_cont : process(clk, rst)
    begin
        if rst = '1' then
            state <= STATE0;
            lb_write_trans <= '0';
            timeout_count <= "00";
            claim_trans <= '0';
            config_trans <= '0';
            bar0_trans <= '0';
            addr <= (others => '0');
            rd <= '0';
            wr <= '0';
        elsif rising_edge(clk) then
            claim_trans <= '0';
            pci_write <= '0';
            case state is

                -- idle state
                when STATE0 =>
                    timeout_count <= "00";
                    if n_frame = '0' then
                        if cfg_addr_hit = '1' or mem_addr_hit = '1' then
                            state <= STATE2;
                            lb_write_trans <= c_n_be(0);
                            claim_trans <= '1';
                            pci_write <= not c_n_be(0);
                            config_trans <= idsel;
                            bar0_trans <= not idsel;
                            addr <= ad(LB_ADDR_WIDTH + 1 downto 2);
                        else
                            state <= STATE1;
                        end if;
                    end if;

                -- wait until frame becomes inactive
                when STATE1 =>
                    if n_frame = '1' then
                        state <= STATE0;
                    end if;

                -- wait until master asserts irdy
                when STATE2 =>
                    if n_irdy = '0' then
                        state <= STATE3;
                        rd <= not lb_write_trans;
                        wr <= lb_write_trans;
                    end if;

                -- wait for local bus cycle to complete
                when STATE3 =>
                    if ack = '1' or timeout_count = "11" then
                        state <= STATE1;
                        rd <= '0';
                        wr <= '0';
                    end if;
                    timeout_count <= timeout_count + 1;

            end case;

        end if;
    end process;

    next_phase <= '1' when state = STATE3 and (ack = '1' or 
            timeout_count = "11") else '0';
    data_out <= ad;
    byte_en <= not c_n_be;

    -- command decode
    read_config_decode <= '1' when c_n_be = "1010" else '0';
    write_config_decode <= '1' when c_n_be = "1011" else '0';
    read_mem_decode <= '1' when c_n_be = "0110" or c_n_be = "1100" or 
            c_n_be = "1110" else '0';
    write_mem_decode <= '1' when c_n_be = "0111" or c_n_be = "1111" else '0';
    cfg_addr_hit <= '1' when idsel = '1' and ad(1 downto 0) = "00" and
            (read_config_decode = '1' or write_config_decode = '1') else '0';
    mem_addr_hit <= en_mem and bar0_decode and 
            (read_mem_decode or write_mem_decode);
    
end;

