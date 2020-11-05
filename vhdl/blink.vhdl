
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity blink is
    port (
        clk     : in std_logic;
        led     : out std_logic
    );
end blink;

architecture RTL of blink is
    signal counter          : unsigned(11 downto 0) := "000000000000";
begin


    process(clk)
    begin
        if rising_edge(clk) then
            counter         <= counter + 1;
        end if;
    end process;

    led <= counter(7);

end RTL;
