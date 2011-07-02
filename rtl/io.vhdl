--------------------------------------------------------------------------------
--
-- io.vhdl
--
-- PCI bus I/O 
--
--------------------------------------------------------------------------------
--
--   --------------------------
-- --|clk                     |--
-- --|rst                     |--
-- --|                        |--
-- --|idsel_i          ad_io[]|--
-- --|c_n_be_i[]    n_devsel_o|--
-- --|n_frame_i       n_trdy_o|--
-- --|n_irdy_i        n_stop_o|--
-- --|                n_inta_o|--
-- --|                   par_o|--
-- --|                        |--
-- --|int           idsel_in_o|--
-- --|           c_n_be_in_o[]|--
-- --|            n_frame_in_o|--
-- --|             n_irdy_in_o|--
-- --|               ad_in_o[]|--
-- --|                        |--
-- --|claim_trans             |--
-- --|pci_write               |--
-- --|ad_out_i[]              |--
-- --|next_phase              |--
--   --------------------------
--
-- clk : 33MHz PCI clock
-- rst : async reset
--
-- idsel_i : PCI IDSEL
-- c_n_be_i : PCI C/BE#
-- n_frame_i : PCI FRAME#
-- n_irdy_i : PCI IRDY#
-- ad_io : PCI AD
-- n_devsel_o : PCI DEVSEL#
-- n_trdy_o : PCI TRDY#
-- n_stop_o : PCI STOP#
-- n_inta_o : PCI INTA#
-- par_o : PCI PAR
-- 
-- int : local bus interrupt in
-- idsel_in_o : PCI IDSEL from PCI bus
-- c_n_be_in_o : PCI C/BE# from PCI bus
-- n_frame_in_o : PCI FRAME# from PCI bus
-- n_irdy_in_o : PCI IRDY# from PCI bus 
-- ad_in_o : PCI AD from PCI bus
--
-- claim_trans : claim slave transaction 
-- pci_write : transaction writes data on to PCI bus
-- ad_out_i : AD for driving out on PCI AD
-- next_phase : request move to next phase
-- 
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity io is
    port (
        clk : in std_logic;
        rst : in std_logic;
        
        idsel_i : in std_logic;
        c_n_be_i : in std_logic_vector(3 downto 0);
        n_frame_i : in std_logic;
        n_irdy_i : in std_logic;
        ad_io : inout std_logic_vector(31 downto 0);
        n_devsel_o : out std_logic;     
        n_trdy_o : out std_logic;
        n_stop_o : out std_logic;
        n_inta_o : out std_logic; 
        par_o : out std_logic;        
         
        int : in std_logic;
        idsel_in_o : out std_logic;
        c_n_be_in_o : out std_logic_vector(3 downto 0);
        n_frame_in_o : out std_logic;
        n_irdy_in_o : out std_logic;
        ad_in_o : out std_logic_vector(31 downto 0);
       
        claim_trans : in std_logic; 
        pci_write : in std_logic;
        ad_out_i : in std_logic_vector(31 downto 0);
        next_phase : in std_logic
    );
end io;

architecture rtl of io is
begin
    
    -- register PCI input signals
    pci_inputs : process (clk, rst) is
    begin
        if rst = '1' then
            idsel_in_o <= '0';
            c_n_be_in_o <= x"0";
            n_frame_in_o <= '1';
            n_irdy_in_o <= '1';
            ad_in_o <= x"00000000";
        elsif rising_edge(clk) then
            idsel_in_o <= to_x01(idsel_i);
            c_n_be_in_o <= to_x01(c_n_be_i);
            n_frame_in_o <= to_x01(n_frame_i);
            n_irdy_in_o <= to_x01(n_irdy_i);
            ad_in_o <= to_x01(ad_io);
        end if;
    end process;  
    
    -- drive PCI output signals
    pci_outputs : process(clk, rst) is
        variable target_mode : std_logic;
        variable drive_data : std_logic; 
        variable slave_end : std_logic;
        variable ad : std_logic_vector(31 downto 0);
        variable n_devsel : std_logic_vector(1 downto 0);
        variable n_trdy : std_logic_vector(1 downto 0);
        variable n_stop : std_logic_vector(1 downto 0);
        variable par : std_logic;
        variable drive_par : std_logic;
    begin
        if rst = '1' then
            target_mode := '0';
            drive_data := '0';
            slave_end := '0';
            ad := x"00000000";
            n_devsel := "11";
            n_trdy := "11";
            n_stop := "11";
            par := '0';
            drive_par := '0';
            ad_io <= (others => 'Z');
            n_devsel_o <= 'Z';
            n_trdy_o <= 'Z';
            n_stop_o <= 'Z';
            n_inta_o <= 'Z';
            par_o <= 'Z';
        elsif rising_edge(clk) then
            n_devsel(1) := n_devsel(0);
            n_trdy(1) := n_trdy(0);
            n_stop(1) := n_stop(0);

            -- claim target transaction
            if claim_trans = '1' then
                target_mode := '1';
                drive_data := pci_write;
                n_devsel(0) := '0';
            end if;

            -- slave mode 
            if target_mode = '1' then
                if slave_end = '1' then
                    if to_x01(n_frame_i) = '1' then
                        slave_end := '0';
                        target_mode := '0';
                        drive_data := '0';
                        n_devsel(0) := '1';
                        n_stop(0) := '1';
                    end if;
                elsif n_trdy(1) = '1' then
                    if next_phase = '1' then
                        n_trdy(0) := '0';
                        n_stop(0) := '0';
                        ad := ad_out_i;
                    end if;
                else
                    if to_x01(n_frame_i) = '1' then
                        target_mode := '0';
                        drive_data := '0';
                        n_devsel(0) := '1';
                        n_stop(0) := '1';
                    else
                        slave_end := '1';
                    end if;
                    n_trdy(0) := '1';
                end if;
            end if;

            -- drive ad_io
            if drive_data = '1' then
                ad_io <= ad; 
            else
                ad_io <= (others => 'Z');
            end if;

            -- drive n_devsel_o
            if n_devsel(0) = '0' then
                n_devsel_o <= '0';
            elsif n_devsel(1) = '0' then
                n_devsel_o <= '1';
            else
                n_devsel_o <= 'Z';
            end if;

            -- drive n_trdy_o
            if n_trdy(0) = '0' then
                n_trdy_o <= '0';
            elsif n_trdy(1) = '0' then
                n_trdy_o <= '1';
            else
                n_trdy_o <= 'Z';
            end if;

            -- drive n_stop_o
            if n_stop(0) = '0' then
                n_stop_o <= '0';
            elsif n_stop(1) = '0' then
                n_stop_o <= '1';
            else
                n_stop_o <= 'Z';
            end if;

            -- drive n_inta_o
            if int = '1' then
                n_inta_o <= '0';
            else
                n_inta_o <= 'Z';
            end if;

            -- drive par
            if drive_par = '1' then
                par_o <= par;
            else
                par_o <= 'Z';
            end if;

            -- calculate parity
            par := '0';
            for i in 0 to 31 loop
                par := par xor ad(i);      
            end loop;

            drive_par := drive_data;

        end if;
    end process;

end;
   
