library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity sevseg_conv is

  port (
    input  : in  std_logic_vector(3 downto 0);
    output : out std_logic_vector(6 downto 0));

end entity sevseg_conv;

architecture rtl of sevseg_conv is

begin  -- architecture rtl

  with input select
    output <=
    "1000000" when x"0",
    "1111001" when x"1",
    "0100100" when x"2",
    "0110000" when x"3",
    "0011001" when x"4",
    "0010010" when x"5",
    "0000010" when x"6",
    "1111000" when x"7",
    "0000000" when x"8",
    "0011000" when x"9",
    "0001000" when x"a",
    "0000011" when x"b",
    "1000110" when x"c",
    "0100001" when x"d",
    "0000110" when x"e",
    "0001110" when x"f";
end architecture rtl;
