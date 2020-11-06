library ieee;
use IEEE.std_logic_1164.all;

entity top_tb is
end entity;


architecture rtl of top_tb is
  component top is
    port(
      clk       : in std_logic;
      reset_btn : in std_logic;

      --uart
      rxd       : in    std_logic;
      txd       : out   std_logic;
      cts       : in    std_logic;
      rts       : out   std_logic;
      --uart_pmod : inout std_logic_vector(3 downto 0);
      --pmodmic0
      mic0_pmod : inout std_logic_vector(3 downto 0);
      mic1_pmod : inout std_logic_vector(3 downto 0);

      R_LED  : out std_logic;
      G_LED  : out std_logic;
      B_LED  : out std_logic;
      HP_LED : out std_logic

      );
  end component;

  signal reset     : std_logic;
  signal clk       : std_logic := '1';
  signal uart_pmod : std_logic_vector(3 downto 0);
  signal rxd       : std_logic;
  signal txd       : std_logic;
  signal cts       : std_logic;
  signal rts       : std_logic;

  signal mic0_pmod      : std_logic_vector(3 downto 0);
  signal mic1_pmod      : std_logic_vector(3 downto 0);
  constant CLOCK_PERIOD : time := 83.33 ns;
begin

  mic0_pmod(2) <= '0';
  mic1_pmod(2) <= '0';
  dut : component top
    port map(
      clk       => clk,
      reset_btn => reset,
      rxd       => rxd,
      txd       => txd,
      cts       => cts,
      rts       => rts,

      --pmodmic0
      mic1_pmod => mic1_pmod,
      mic0_pmod => mic0_pmod);
  cts <= '0';
  process
  begin
    clk <= not clk;
    wait for CLOCK_PERIOD/2;
  end process;

  process
  begin
    reset <= '0';
    wait for CLOCK_PERIOD*5;
    reset <= not reset;
    wait;
  end process;

end architecture;
