-- top_component_pkg.vhd
-- Copyright (C) 2015 VectorBlox Computing, Inc.

-- Component declarations

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.top_util_pkg.all;

package top_component_pkg is

  component uart_core
    generic(
      CLK_IN_MHZ : integer := 25;
      BAUD_RATE  : integer := 115200;
      ADDRWIDTH  : integer := 3;
      DATAWIDTH  : integer := 8;
      MODEM_B    : boolean := true;
      FIFO       : boolean := false
      );
    port(
-- Global reset and clock
      CLK        : in  std_logic;
      RESET      : in  std_logic;
-- wishbone interface
      UART_ADR_I : in  std_logic_vector(7 downto 0);
      UART_DAT_I : in  std_logic_vector(15 downto 0);
      UART_DAT_O : out std_logic_vector(15 downto 0);
      UART_STB_I : in  std_logic;
      UART_CYC_I : in  std_logic;
      UART_WE_I  : in  std_logic;
      UART_SEL_I : in  std_logic_vector(3 downto 0);
      UART_CTI_I : in  std_logic_vector(2 downto 0);
      UART_BTE_I : in  std_logic_vector(1 downto 0);
      UART_ACK_O : out std_logic;
      INTR       : out std_logic;
-- Receiver interface
      SIN        : in  std_logic;
      RXRDY_N    : out std_logic;
-- Transmitter interface
--Generate --if MODEM

--begin
      DCD_N : in  std_logic;
      CTS_N : in  std_logic;
      DSR_N : in  std_logic;
      RI_N  : in  std_logic;
      DTR_N : out std_logic;
      RTS_N : out std_logic;

--end Generate ;
--
      SOUT    : out std_logic;
      TXRDY_N : out std_logic
      );
  end component;

  component my_led
    port (
      red_i   : in  std_logic;
      green_i : in  std_logic;
      blue_i  : in  std_logic;
      hp_i    : in  std_logic;
      red     : out std_logic;
      green   : out std_logic;
      blue    : out std_logic;
      hp      : out std_logic);
  end component;

  component riscV_wishbone is
    generic (
      REGISTER_SIZE        : integer              := 32;
      RESET_VECTOR         : natural              := 16#00000200#;
      MULTIPLY_ENABLE      : natural range 0 to 1 := 0;
      SHIFTER_SINGLE_CYCLE : natural range 0 to 2 := 0);
    port(
      clk   : in std_logic;
      reset : in std_logic;

      --conduit end point
      coe_to_host         : out std_logic_vector(REGISTER_SIZE -1 downto 0);
      coe_from_host       : in  std_logic_vector(REGISTER_SIZE -1 downto 0);
      coe_program_counter : out std_logic_vector(REGISTER_SIZE -1 downto 0);

      data_ADR_O   : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      data_DAT_I   : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      data_DAT_O   : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      data_WE_O    : out std_logic;
      data_SEL_O   : out std_logic_vector(REGISTER_SIZE/8 -1 downto 0);
      data_STB_O   : out std_logic;
      data_ACK_I   : in  std_logic;
      data_CYC_O   : out std_logic;
      data_CTI_O   : out std_logic_vector(2 downto 0);
      data_STALL_I : in  std_logic;

      instr_ADR_O   : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      instr_DAT_I   : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      instr_DAT_O   : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      instr_WE_O    : out std_logic;
      instr_SEL_O   : out std_logic_vector(REGISTER_SIZE/8 -1 downto 0);
      instr_STB_O   : out std_logic;
      instr_ACK_I   : in  std_logic;
      instr_CYC_O   : out std_logic;
      instr_CTI_O   : out std_logic_vector(2 downto 0);
      instr_STALL_I : in  std_logic

      );
  end component riscV_wishbone;

  component wb_ram is
    generic (
      size             : integer := 4096;
      DATA_WIDTH       : integer := 32;
      INIT_FILE_FORMAT : string  := "hex";
      INIT_FILE_NAME   : string  := "none";
      LATTICE_FAMILY   : string  := "ICE40");
    port (
      CLK_I : in std_logic;
      RST_I : in std_logic;

      ADR_I  : in std_logic_vector(31 downto 0);
      DAT_I  : in std_logic_vector(DATA_WIDTH-1 downto 0);
      WE_I   : in std_logic;
      CYC_I  : in std_logic;
      STB_I  : in std_logic;
      SEL_I  : in std_logic_vector(DATA_WIDTH/8-1 downto 0);
      CTI_I  : in std_logic_vector(2 downto 0);
      BTE_I  : in std_logic_vector(1 downto 0);
      LOCK_I : in std_logic;

      STALL_O : out std_logic;
      DAT_O   : out std_logic_vector(DATA_WIDTH-1 downto 0);
      ACK_O   : out std_logic;
      ERR_O   : out std_logic;
      RTY_O   : out std_logic);
  end component wb_ram;

  component wb_arbiter is
    generic (
      PRIORITY_SLAVE : integer := 1;    --slave which always gets priority
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
  end component;

  component wb_pio is
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
  end component;

  type address_array is array(1 downto 0) of natural;

  component wb_splitter is

    generic (
      master0_address : address_array := (0, 0);
      master1_address : address_array := (0, 0);
      master2_address : address_array := (0, 0);
      master3_address : address_array := (0, 0);
      master4_address : address_array := (0, 0);
      DATA_WIDTH      : natural       := 32
      );
    port(

      CLK_I : in std_logic;
      RST_I : in std_logic;

      slave_ADR_I   : in  std_logic_vector(31 downto 0);
      slave_DAT_I   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      slave_WE_I    : in  std_logic;
      slave_CYC_I   : in  std_logic;
      slave_STB_I   : in  std_logic;
      slave_SEL_I   : in  std_logic_vector(DATA_WIDTH/8-1 downto 0);
      slave_CTI_I   : in  std_logic_vector(2 downto 0);
      slave_BTE_I   : in  std_logic_vector(1 downto 0);
      slave_LOCK_I  : in  std_logic;
      slave_STALL_O : out std_logic;
      slave_DAT_O   : out std_logic_vector(DATA_WIDTH-1 downto 0);
      slave_ACK_O   : out std_logic;
      slave_ERR_O   : out std_logic;
      slave_RTY_O   : out std_logic;


      master0_ADR_O   : out std_logic_vector(31 downto 0);
      master0_DAT_O   : out std_logic_vector(DATA_WIDTH-1 downto 0);
      master0_WE_O    : out std_logic;
      master0_CYC_O   : out std_logic;
      master0_STB_O   : out std_logic;
      master0_SEL_O   : out std_logic_vector(DATA_WIDTH/8-1 downto 0);
      master0_CTI_O   : out std_logic_vector(2 downto 0);
      master0_BTE_O   : out std_logic_vector(1 downto 0);
      master0_LOCK_O  : out std_logic;
      master0_STALL_I : in  std_logic                               := '0';
      master0_DAT_I   : in  std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
      master0_ACK_I   : in  std_logic                               := '0';
      master0_ERR_I   : in  std_logic                               := '0';
      master0_RTY_I   : in  std_logic                               := '0';

      master1_ADR_O   : out std_logic_vector(31 downto 0);
      master1_DAT_O   : out std_logic_vector(DATA_WIDTH-1 downto 0);
      master1_WE_O    : out std_logic;
      master1_CYC_O   : out std_logic;
      master1_STB_O   : out std_logic;
      master1_SEL_O   : out std_logic_vector(DATA_WIDTH/8-1 downto 0);
      master1_CTI_O   : out std_logic_vector(2 downto 0);
      master1_BTE_O   : out std_logic_vector(1 downto 0);
      master1_LOCK_O  : out std_logic;
      master1_STALL_I : in  std_logic                               := '0';
      master1_DAT_I   : in  std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
      master1_ACK_I   : in  std_logic                               := '0';
      master1_ERR_I   : in  std_logic                               := '0';
      master1_RTY_I   : in  std_logic                               := '0';

      master2_ADR_O   : out std_logic_vector(31 downto 0);
      master2_DAT_O   : out std_logic_vector(DATA_WIDTH-1 downto 0);
      master2_WE_O    : out std_logic;
      master2_CYC_O   : out std_logic;
      master2_STB_O   : out std_logic;
      master2_SEL_O   : out std_logic_vector(DATA_WIDTH/8-1 downto 0);
      master2_CTI_O   : out std_logic_vector(2 downto 0);
      master2_BTE_O   : out std_logic_vector(1 downto 0);
      master2_LOCK_O  : out std_logic;
      master2_STALL_I : in  std_logic                               := '0';
      master2_DAT_I   : in  std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
      master2_ACK_I   : in  std_logic                               := '0';
      master2_ERR_I   : in  std_logic                               := '0';
      master2_RTY_I   : in  std_logic                               := '0';

      master3_ADR_O   : out std_logic_vector(31 downto 0);
      master3_DAT_O   : out std_logic_vector(DATA_WIDTH-1 downto 0);
      master3_WE_O    : out std_logic;
      master3_CYC_O   : out std_logic;
      master3_STB_O   : out std_logic;
      master3_SEL_O   : out std_logic_vector(DATA_WIDTH/8-1 downto 0);
      master3_CTI_O   : out std_logic_vector(2 downto 0);
      master3_BTE_O   : out std_logic_vector(1 downto 0);
      master3_LOCK_O  : out std_logic;
      master3_STALL_I : in  std_logic                               := '0';
      master3_DAT_I   : in  std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
      master3_ACK_I   : in  std_logic                               := '0';
      master3_ERR_I   : in  std_logic                               := '0';
      master3_RTY_I   : in  std_logic                               := '0';

      master4_ADR_O   : out std_logic_vector(31 downto 0);
      master4_DAT_O   : out std_logic_vector(DATA_WIDTH-1 downto 0);
      master4_WE_O    : out std_logic;
      master4_CYC_O   : out std_logic;
      master4_STB_O   : out std_logic;
      master4_SEL_O   : out std_logic_vector(DATA_WIDTH/8-1 downto 0);
      master4_CTI_O   : out std_logic_vector(2 downto 0);
      master4_BTE_O   : out std_logic_vector(1 downto 0);
      master4_LOCK_O  : out std_logic;
      master4_STALL_I : in  std_logic                               := '0';
      master4_DAT_I   : in  std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
      master4_ACK_I   : in  std_logic                               := '0';
      master4_ERR_I   : in  std_logic                               := '0';
      master4_RTY_I   : in  std_logic                               := '0');
  end component wb_splitter;

  component pmod_mic_wb is
    generic (
      PORTS          : positive range 1 to 8 := 1;
      CLK_FREQ_HZ    : positive              := 25000000;
      SAMPLE_RATE_HZ : positive              := 48000
      );
    port (
      clk   : in std_logic;
      reset : in std_logic;

      --PmodMic
      sdata : in  std_logic_vector(PORTS-1 downto 0);
      sclk  : out std_logic_vector(PORTS-1 downto 0);
      cs_n  : out std_logic_vector(PORTS-1 downto 0);

      --WISHBONE
      pmodmic_adr_i : in     std_logic_vector(7 downto 0);
      pmodmic_dat_i : in     std_logic_vector(15 downto 0);
      pmodmic_dat_o : out    std_logic_vector(15 downto 0);
      pmodmic_stb_i : in     std_logic;
      pmodmic_cyc_i : in     std_logic;
      pmodmic_we_i  : in     std_logic;
      pmodmic_sel_i : in     std_logic_vector(3 downto 0);
      pmodmic_cti_i : in     std_logic_vector(2 downto 0);
      pmodmic_bte_i : in     std_logic_vector(1 downto 0);
      pmodmic_ack_o : buffer std_logic
      );
  end component pmod_mic_wb;


end package;


package body top_component_pkg is
end top_component_pkg;
