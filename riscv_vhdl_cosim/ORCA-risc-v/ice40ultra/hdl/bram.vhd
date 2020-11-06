
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;
use IEEE.STD_LOGIC_TEXTIO.all;
use STD.TEXTIO.all;

library work;
use work.utils.all;


entity bram_lattice is
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
end bram_lattice;


architecture rtl of bram_lattice is
  type word_t is array (0 to RAM_WIDTH/BYTE_SIZE-1) of std_logic_vector(BYTE_SIZE-1 downto 0);
  type ram_type is array (0 to RAM_DEPTH-1) of std_logic_vector(BYTE_SIZE-1 downto 0);

  function to_slv (tmp_hexnum : string) return std_logic_vector is
    variable temp  : std_logic_vector(31 downto 0);
    variable digit : natural;
  begin
    for i in tmp_hexnum'range loop
      case tmp_hexnum(i) is
        when '0' to '9' =>
          digit := character'pos(tmp_hexnum(i)) - character'pos('0');
        when 'A' to 'F' =>
          digit := (character'pos(tmp_hexnum(i)) - character'pos('A'))+10;
        when 'a' to 'f' =>
          digit := (character'pos(tmp_hexnum(i)) - character'pos('a'))+10;
        when others => digit := 0;

      end case;
      temp(i*4+3 downto i*4) := std_logic_vector(to_unsigned(digit, 4));
    end loop;
    return temp;
  end function;

  impure function init_bram (ram_file_name : in string;
                             bytesel       : in integer)
    return ram_type is
    -- pragma translate_off
    file ramfile           : text is in ram_file_name;
    variable line_read     : line;
    variable my_line       : line;
    variable ss            : string(7 downto 0);
    -- pragma translate_on
    variable ram_to_return : ram_type;

  begin
    --ram_to_return := (others => (others => '0'));
    -- pragma translate_off
    for i in ram_type'range loop
      if not endfile(ramfile) then
        readline(ramfile, line_read);
        read(line_read, ss);
        ram_to_return(i) := to_slv(ss)(BYTE_SIZE*(bytesel+1) -1 downto BYTE_SIZE*bytesel);
      end if;
    end loop;
    -- pragma translate_on
    return ram_to_return;
  end function;

  -- instead of using a generate statement,do manually so we can figure out which
  -- physical rams belong to which byte during ram initialization.

  signal Q3       : std_logic_vector(BYTE_SIZE-1 downto 0);
  signal ram3     : ram_type := init_bram(INIT_FILE_NAME, 3);
  signal byte_we3 : std_logic;
  signal Q2       : std_logic_vector(BYTE_SIZE-1 downto 0);
  signal ram2     : ram_type := init_bram(INIT_FILE_NAME, 2);
  signal byte_we2 : std_logic;
  signal Q1       : std_logic_vector(BYTE_SIZE-1 downto 0);
  signal ram1     : ram_type := init_bram(INIT_FILE_NAME, 1);
  signal byte_we1 : std_logic;
  signal Q0       : std_logic_vector(BYTE_SIZE-1 downto 0);
  signal ram0     : ram_type := init_bram(INIT_FILE_NAME, 0);
  signal byte_we0 : std_logic;

begin  --architeture

  byte_we3 <= WE and be(3);
  process (clock)
  begin
    if rising_edge(clock) then
      Q3 <= ram3(to_integer(unsigned(address)));
      if byte_we3 = '1' then
        ram3(to_integer(unsigned(address))) <= data_in(BYTE_SIZE*(3+1)-1 downto BYTE_SIZE*3);
      end if;
    end if;
  end process;

  byte_we2 <= WE and be(2);
  process (clock)
  begin
    if rising_edge(clock) then
      Q2 <= ram2(to_integer(unsigned(address)));
      if byte_we2 = '1' then
        ram2(to_integer(unsigned(address))) <= data_in(BYTE_SIZE*(2+1)-1 downto BYTE_SIZE*2);
      end if;
    end if;
  end process;

  byte_we1 <= WE and be(1);
  process (clock)
  begin
    if rising_edge(clock) then
      Q1 <= ram1(to_integer(unsigned(address)));
      if byte_we1 = '1' then
        ram1(to_integer(unsigned(address))) <= data_in(BYTE_SIZE*(1+1)-1 downto BYTE_SIZE*1);
      end if;
    end if;
  end process;

  byte_we0 <= WE and be(0);
  process (clock)
  begin
    if rising_edge(clock) then
      Q0 <= ram0(to_integer(unsigned(address)));
      if byte_we0 = '1' then
        ram0(to_integer(unsigned(address))) <= data_in(BYTE_SIZE*(0+1)-1 downto BYTE_SIZE*0);
      end if;
    end if;
  end process;


  readdata <= Q3 & Q2 & Q1 & Q0;

  --byte_gen : for i in 0 to 3 generate
  --  signal byte_we : std_logic;
  --  signal ram     : ram_type := init_bram(INIT_FILE_NAME, i);
  --  signal Q       : std_logic_vector(BYTE_SIZE-1 downto 0);

  --begin
  --  byte_we <= WE and be(i);
  --  process (clock)
  --  begin
  --    if rising_edge(clock) then
  --      Q <= ram(to_integer(unsigned(address)));

  --      if byte_we = '1' then
  --        ram(to_integer(unsigned(address))) <= data_in(BYTE_SIZE*(i+1)-1 downto BYTE_SIZE*i);
  --      end if;
  --    end if;
  --  end process;
  --  readdata(BYTE_SIZE*(i+1)-1 downto BYTE_SIZE*i) <= Q;
  --end generate byte_gen;

end rtl;
