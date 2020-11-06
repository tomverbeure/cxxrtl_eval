library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity wb_pio is
  generic (
    DATA_WIDTH : integer := 32
    );
  port (
    CLK_I : in std_logic;
    RST_I : in std_logic;

    ADR_I   : in  std_logic_vector(31 downto 0);
    DAT_I   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    WE_I    : in  std_logic;
    CYC_I   : in  std_logic;
    STB_I   : in  std_logic;
    SEL_I   : in  std_logic_vector(DATA_WIDTH/8-1 downto 0);
    CTI_I   : in  std_logic_vector(2 downto 0);
    BTE_I   : in  std_logic_vector(1 downto 0);
    LOCK_I  : in  std_logic;
    ACK_O   : out std_logic;
    STALL_O : out std_logic;
    DATA_O  : out std_logic_vector(DATA_WIDTH -1 downto 0);
    ERR_O   : out std_logic;
    RTY_O   : out std_logic;
    output  : out std_logic_vector(DATA_WIDTH -1 downto 0)
    );
end entity;



architecture output of wb_pio is
  signal reg         : std_logic_vector(DATA_WIDTH -1 downto 0);
  signal valid_cycle : std_logic;
begin
  valid_cycle <= STB_I and CYC_I;
  process(CLK_I)
  begin
    if rising_edge(CLK_I) then
      if RST_I = '1' then
        reg <= (others => '0');
        ACK_O <= '0';
      else
        ACK_O <= valid_cycle;
        if (WE_I and valid_cycle) = '1' then
          reg <= DAT_I;
        end if;
      end if;
    end if;
  end process;

  ERR_O   <= '0';
  RTY_O   <= '0';
  STALL_O <= '0';

  DATA_O <= reg;

  output <= reg;

end architecture output;
