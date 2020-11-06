library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.utils.all;

entity wb_ram is

  generic (
    size             : integer := 4096;
    DATA_WIDTH       : integer := 32;
    INIT_FILE_FORMAT : string  := "hex";
    INIT_FILE_NAME   : string  := "none";
    LATTICE_FAMILY   : string  := "ICE40");
  port (
    CLK_I : in std_logic;
    RST_I : in std_logic;

    ADR_I : in std_logic_vector(31 downto 0);
    DAT_I : in std_logic_vector(DATA_WIDTH-1 downto 0);
    WE_I  : in std_logic;
    CYC_I : in std_logic;
    STB_I : in std_logic;
    SEL_I : in std_logic_vector(DATA_WIDTH/8-1 downto 0);
    CTI_I : in std_logic_vector(2 downto 0);
    BTE_I : in std_logic_vector(1 downto 0);

    LOCK_I : in std_logic;

    STALL_O : out std_logic;
    DAT_O   : out std_logic_vector(DATA_WIDTH-1 downto 0);
    ACK_O   : out std_logic;
    ERR_O   : out std_logic;
    RTY_O   : out std_logic);

end entity wb_ram;

architecture rtl of wb_ram is
  component bram_lattice is
    generic (
      RAM_DEPTH      : integer := 1024;
      RAM_WIDTH      : integer := 32;
      BYTE_SIZE      : integer := 8;
      INIT_FILE_NAME : string
      );
    port
      (
        address  : in  std_logic_vector(log2(RAM_DEPTH)-1 downto 0);
        clock    : in  std_logic;
        data_in  : in  std_logic_vector(RAM_WIDTH-1 downto 0);
        we       : in  std_logic;
        be       : in  std_logic_vector(RAM_WIDTH/BYTE_SIZE-1 downto 0);
        readdata : out std_logic_vector(RAM_WIDTH-1 downto 0)
        );
  end component bram_lattice;

  constant BYTES_PER_WORD : integer := DATA_WIDTH/8;

  signal address : std_logic_vector(log2(SIZE/BYTES_PER_WORD)-1 downto 0);
begin  -- architecture rtl

  address <= ADR_I(address'left+log2(BYTES_PER_WORD) downto log2(BYTES_PER_WORD));

  ram : component bram_lattice
    generic map (
      RAM_DEPTH      => SIZE/4,
      INIT_FILE_NAME => INIT_FILE_NAME)
    port map (
      address  => address,
      clock    => CLK_I,
      data_in  => DAT_I,
      we       => WE_I,
      be       => SEL_I,
      readdata => DAT_O);


  STALL_O <= '0';
  ERR_O   <= '0';
  RTY_O   <= '0';

  process(CLK_I)
  begin
    if rising_edge(CLK_I) then
      ACK_O <= STB_I and CYC_I;
    end if;
  end process;

end architecture rtl;
