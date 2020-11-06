library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity wb_arbiter is
  generic (
    PRIORITY_SLAVE : integer := 1;      --slave which always gets priority
    DATA_WIDTH     : integer := 32
    );
  port (
    CLK_I : in std_logic;
    RST_I : in std_logic;

    slave1_ADR_I : in std_logic_vector(31 downto 0);
    slave1_DAT_I : in std_logic_vector(DATA_WIDTH-1 downto 0);
    slave1_WE_I  : in std_logic;
    slave1_CYC_I : in std_logic;
    slave1_STB_I : in std_logic;
    slave1_SEL_I : in std_logic_vector(DATA_WIDTH/8-1 downto 0);
    slave1_CTI_I : in std_logic_vector(2 downto 0);
    slave1_BTE_I : in std_logic_vector(1 downto 0);
    slave1_LOCK_I : in std_logic;

    slave1_STALL_O : out std_logic;
    slave1_DAT_O   : out std_logic_vector(DATA_WIDTH-1 downto 0);
    slave1_ACK_O   : out std_logic;
    slave1_ERR_O   : out std_logic;
    slave1_RTY_O   : out std_logic;

    slave2_ADR_I : in std_logic_vector(31 downto 0);
    slave2_DAT_I : in std_logic_vector(DATA_WIDTH-1 downto 0);
    slave2_WE_I  : in std_logic;
    slave2_CYC_I : in std_logic;
    slave2_STB_I : in std_logic;
    slave2_SEL_I : in std_logic_vector(DATA_WIDTH/8-1 downto 0);
    slave2_CTI_I : in std_logic_vector(2 downto 0);
    slave2_BTE_I : in std_logic_vector(1 downto 0);

    slave2_LOCK_I : in std_logic;

    slave2_STALL_O : out std_logic;
    slave2_DAT_O   : out std_logic_vector(DATA_WIDTH-1 downto 0);
    slave2_ACK_O   : out std_logic;
    slave2_ERR_O   : out std_logic;
    slave2_RTY_O   : out std_logic;

    master_ADR_O  : out std_logic_vector(31 downto 0);
    master_DAT_O  : out std_logic_vector(DATA_WIDTH-1 downto 0);
    master_WE_O   : out std_logic;
    master_CYC_O  : out std_logic;
    master_STB_O  : out std_logic;
    master_SEL_O  : out std_logic_vector(DATA_WIDTH/8-1 downto 0);
    master_CTI_O  : out std_logic_vector(2 downto 0);
    master_BTE_O  : out std_logic_vector(1 downto 0);
    master_LOCK_O : out std_logic;

    master_STALL_I : in std_logic;
    master_DAT_I   : in std_logic_vector(DATA_WIDTH-1 downto 0);
    master_ACK_I   : in std_logic;
    master_ERR_I   : in std_logic;
    master_RTY_I   : in std_logic

    );

end entity wb_arbiter;

architecture rtl of wb_arbiter is

  type pc_t is (CHOICE_SLAVE1, CHOICE_SLAVE2);

  signal port_choice      : pc_t;
  signal next_port_choice : pc_t;
  signal curr_port_choice : pc_t;

begin  -- architecture rtl

  PRIORITY_SLAVE_if : if PRIORITY_SLAVE = 1 generate
    next_port_choice <= CHOICE_SLAVE1 when curr_port_choice = CHOICE_SLAVE2 and slave1_STB_I = '1' else CHOICE_SLAVE2;

    slave2_ACK_O <= '0'          when curr_port_choice = CHOICE_SLAVE1 else master_ACK_I;
    slave1_ACK_O <= master_ACK_I when curr_port_choice = CHOICE_SLAVE1 else '0';


    --for control signals use different port choices based on ACK
    port_choice <= next_port_choice when master_ACK_I = '1' else curr_port_choice;

    slave2_STALL_O <= '1' when  port_choice = CHOICE_SLAVE1 else master_STALL_I;
    slave1_STALL_O <= '1' when  port_choice = CHOICE_SLAVE2 else master_STALL_I;
    master_ADR_O <= slave1_ADR_I when port_choice = CHOICE_SLAVE1 else slave2_ADR_I;
    master_DAT_O <= slave1_dat_I when port_choice = CHOICE_SLAVE1 else slave2_dat_I;
    master_WE_O  <= slave1_WE_I  when port_choice = CHOICE_SLAVE1 else slave2_WE_I;
    master_SEL_O <= slave1_SEL_I when port_choice = CHOICE_SLAVE1 else slave2_SEL_I;
    master_STB_O <= slave1_STB_I when port_choice = CHOICE_SLAVE1 else slave2_STB_I;
    master_CYC_O <= slave1_CYC_I when port_choice = CHOICE_SLAVE1 else slave2_CYC_I;

    slave1_DAT_O  <= master_DAT_I;
    slave2_DAT_O <= master_DAT_I;

    choice : process(CLK_I)
    begin
      if rising_edge(CLK_I) then
        if RST_I = '1' then
          curr_port_choice <= CHOICE_SLAVE2;
        end if;
        if master_ACK_I = '1' then
          curr_port_choice <= next_port_choice;
        end if;
      end if;
    end process;

  end generate PRIORITY_SLAVE_if;

  master_CTI_O  <= "000";
  master_LOCK_O <= '0';
  master_BTE_O  <= (others => '0');

  slave1_ERR_O <= '0';
  slave1_RTY_O <= '0';

  slave2_ERR_O <= '0';
  slave2_RTY_O <= '0';

end architecture;
