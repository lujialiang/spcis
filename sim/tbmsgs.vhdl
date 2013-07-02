--------------------------------------------------------------------------------
--
-- tbmsgs.vhdl
--
-- test bench messages
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package tbmsgs is

    procedure testcase(
            constant desc : in string;
            constant count : in natural);
    procedure check(
            constant good : in boolean;
            constant desc : in string);
    procedure tested(
          constant desc : in string);
    procedure testcase_complete;

end;

package body tbmsgs is
    
    shared variable total_tests : natural := 0;
    shared variable total_errors : integer := 0;
    shared variable completed_tests : natural := 0;

    procedure testcase(
            constant desc : in string;
            constant count : in natural) is
    begin
        report "|tbmsgs| *** running test case: " & desc;
        total_tests := count;
    end procedure;
 
    procedure check(
            constant good : in boolean;
            constant desc : in string) is
    begin
        if not good then
            report "|tbmsgs| ERROR: " & desc;
            total_errors := total_errors + 1;
        end if;
    end procedure;

    procedure tested(
            constant desc : in string) is
    begin
        report "|tbmsgs| tested: " & desc;
        completed_tests := completed_tests + 1;
    end procedure;

    procedure testcase_complete is
    begin
        report "|tbmsgs| tests run: " & integer'image(completed_tests) & 
                "/" & integer'image(total_tests) & ", errors: " & 
                integer'image(total_errors);
    end procedure;

end;

