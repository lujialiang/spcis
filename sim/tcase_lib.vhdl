--------------------------------------------------------------------------------
--
-- tcase_lib.vhdl
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package tcase_lib is

    procedure test_case(
            constant desc : in string;
            constant count : in natural);
    procedure test_case_complete;
    procedure test_complete(
          constant desc : in string);

end;

package body tcase_lib is
    
    shared variable total_tests : integer := -1;
    shared variable completed_tests : natural := 0;

    procedure test_case(
            constant desc : in string;
            constant count : in natural) is
    begin
        report "*** running testcase: " & desc;
        total_tests := count;
    end procedure;
 
    procedure test_case_complete is
    begin
        report "tests run: " & integer'image(completed_tests) & "/" &
                integer'image(total_tests);
    end procedure;

    procedure test_complete(
            constant desc : in string) is
    begin
        report "test completed: " & desc;
        completed_tests := completed_tests + 1;
    end procedure;

end;

