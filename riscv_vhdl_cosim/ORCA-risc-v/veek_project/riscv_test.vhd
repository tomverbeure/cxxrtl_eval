library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
entity riscv_test is

  port(
    KEY      : in std_logic_vector(3 downto 0);
    SW       : in std_logic_vector(17 downto 0);
    clock_50 : in std_logic;

    LEDR : out std_logic_vector(17 downto 0);
    LEDG : out std_logic_vector(7 downto 0);
    HEX7 : out std_logic_vector(6 downto 0);
    HEX6 : out std_logic_vector(6 downto 0);
    HEX5 : out std_logic_vector(6 downto 0);
    HEX4 : out std_logic_vector(6 downto 0);
    HEX3 : out std_logic_vector(6 downto 0);
    HEX2 : out std_logic_vector(6 downto 0);
    HEX1 : out std_logic_vector(6 downto 0);
    HEX0 : out std_logic_vector(6 downto 0));


end entity riscv_test;

architecture rtl of riscv_test is

  component vblox1 is
    port (
      clk_clk                : in  std_logic                     := 'X';  -- clk
      from_host_export       : in  std_logic_vector(31 downto 0) := (others => 'X');  -- export
      program_counter_export : out std_logic_vector(31 downto 0);  -- export
      reset_reset_n          : in  std_logic                     := 'X';  -- reset_n
      ledg_export            : out std_logic_vector(31 downto 0);   -- export
      ledr_export            : out std_logic_vector(31 downto 0);  -- export
      hex0_export            : out std_logic_vector(31 downto 0);  -- export
      hex1_export            : out std_logic_vector(31 downto 0);  -- export
      hex2_export            : out std_logic_vector(31 downto 0);  -- export
      hex3_export            : out std_logic_vector(31 downto 0)   -- export
      );
  end component vblox1;


  component sevseg_conv is

    port (
      input  : in  std_logic_vector(3 downto 0);
      output : out std_logic_vector(6 downto 0));

  end component sevseg_conv;

  signal hex_input   : std_logic_vector(31 downto 0);
  signal pc          : std_logic_vector(31 downto 0);
  signal th          : std_logic_vector(31 downto 0);
  signal fh          : std_logic_vector(31 downto 0);
  signal clk         : std_logic;
  signal reset       : std_logic;
  signal ledg_export : std_logic_vector(31 downto 0);
  signal ledr_export : std_logic_vector(31 downto 0);
  signal hex3_export : std_logic_vector(31 downto 0);
  signal hex2_export : std_logic_vector(31 downto 0);
  signal hex1_export : std_logic_vector(31 downto 0);
  signal hex0_export : std_logic_vector(31 downto 0);

  function le2be (
    signal input : std_logic_vector)
    return std_logic_vector is
    variable to_ret : std_logic_vector(31 downto 0);
  begin  -- function le2be
to_ret :=  (input(7 downto 0) &
            input(15 downto 8) &
            input(23 downto 16) &
            input(31 downto 24));
return to_ret;
  end function le2be;
begin
  clk   <= clock_50;
  reset <= key(1);

  fh <= std_logic_vector(resize(signed(sw), fh'length));

  rv : component vblox1
    port map (
      clk_clk                => clk,
      reset_reset_n          => reset,
      from_host_export       => fh,
      program_counter_export => pc,
      ledg_export            => ledg_export,
      ledr_export            => ledr_export,
      hex3_export            => hex3_export,
      hex2_export            => hex2_export,
      hex1_export            => hex1_export,
      hex0_export            => hex0_export);



--  hex_input(15 downto 0)  <= pc(15 downto 0);
--  hex_input(31 downto 16) <= th(15 downto 0);
  hex_input <= hex3_export when sw(3) = '1' else
               hex2_export when sw(2) = '1' else
               hex1_export when sw(1) = '1' else
               hex0_export when sw(0) = '1' else
               pc;
  ss0 : component sevseg_conv
    port map (
      input  => hex_input(3 downto 0),
      output => HEX0);
  ss1 : component sevseg_conv
    port map (
      input  => hex_input(7 downto 4),
      output => HEX1);
  ss2 : component sevseg_conv
    port map (
      input  => hex_input(11 downto 8),
      output => HEX2);
  ss3 : component sevseg_conv
    port map (
      input  => hex_input(15 downto 12),
      output => HEX3);
  ss4 : component sevseg_conv
    port map (
      input  => hex_input(19 downto 16),
      output => HEX4);
  ss5 : component sevseg_conv
    port map (
      input  => hex_input(23 downto 20),
      output => HEX5);
  ss6 : component sevseg_conv
    port map (
      input  => hex_input(27 downto 24),
      output => HEX6);
  ss7 : component sevseg_conv
    port map (
      input  => hex_input(31 downto 28),
      output => HEX7);

  LEDR             <= ledr_export(17 downto 0);
  LEDG(6 downto 0) <= ledg_export(6 downto 0);
  LEDG(7)          <= reset;
end;
