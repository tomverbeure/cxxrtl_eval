
library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.top_component_pkg.all;
use work.top_util_pkg.all;

entity top is
  port(
    clk       : in std_logic;
    reset_btn : in std_logic;

    --uart
    rxd : in std_logic;
    txd : out std_logic;
    cts : in std_logic;
    rts : out std_logic;
    --uart_pmod : inout std_logic_vector(3 downto 0);
    --pmodmic0
    mic0_pmod : inout std_logic_vector(3 downto 0);
    mic1_pmod : inout std_logic_vector(3 downto 0);

    R_LED  : out std_logic;
    G_LED  : out std_logic;
    B_LED  : out std_logic;
    HP_LED : out std_logic;

    led_out : out std_logic_vector(2 downto 0)
    );
end entity;

architecture rtl of top is



  constant REGISTER_SIZE : natural := 32;
  constant RAM_SIZE      : natural := 8*1024;

  signal reset : std_logic;

  signal RAM_ADR_I  : std_logic_vector(31 downto 0);
  signal RAM_DAT_I  : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal RAM_WE_I   : std_logic;
  signal RAM_CYC_I  : std_logic;
  signal RAM_STB_I  : std_logic;
  signal RAM_SEL_I  : std_logic_vector(REGISTER_SIZE/8-1 downto 0);
  signal RAM_CTI_I  : std_logic_vector(2 downto 0);
  signal RAM_BTE_I  : std_logic_vector(1 downto 0);
  signal RAM_LOCK_I : std_logic;

  signal RAM_STALL_O : std_logic;
  signal RAM_DAT_O   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal RAM_ACK_O   : std_logic;
  signal RAM_ERR_O   : std_logic;
  signal RAM_RTY_O   : std_logic;

  signal data_ADR_O  : std_logic_vector(31 downto 0);
  signal data_DAT_O  : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal data_WE_O   : std_logic;
  signal data_CYC_O  : std_logic;
  signal data_STB_O  : std_logic;
  signal data_SEL_O  : std_logic_vector(REGISTER_SIZE/8-1 downto 0);
  signal data_CTI_O  : std_logic_vector(2 downto 0);
  signal data_BTE_O  : std_logic_vector(1 downto 0);
  signal data_LOCK_O : std_logic;

  signal data_STALL_I : std_logic;
  signal data_DAT_I   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal data_ACK_I   : std_logic;
  signal data_ERR_I   : std_logic;
  signal data_RTY_I   : std_logic;

  signal instr_ADR_O  : std_logic_vector(31 downto 0);
  signal instr_DAT_O  : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal instr_WE_O   : std_logic;
  signal instr_CYC_O  : std_logic;
  signal instr_STB_O  : std_logic;
  signal instr_SEL_O  : std_logic_vector(REGISTER_SIZE/8-1 downto 0);
  signal instr_CTI_O  : std_logic_vector(2 downto 0);
  signal instr_BTE_O  : std_logic_vector(1 downto 0);
  signal instr_LOCK_O : std_logic;

  signal instr_STALL_I : std_logic;
  signal instr_DAT_I   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal instr_ACK_I   : std_logic;
  signal instr_ERR_I   : std_logic;
  signal instr_RTY_I   : std_logic;

  signal led_adr_i   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal led_dat_i   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal led_dat_o   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal led_stb_i   : std_logic;
  signal led_cyc_i   : std_logic;
  signal led_we_i    : std_logic;
  signal led_sel_i   : std_logic_vector(3 downto 0);
  signal led_cti_i   : std_logic_vector(2 downto 0);
  signal led_bte_i   : std_logic_vector(1 downto 0);
  signal led_ack_o   : std_logic;
  signal led_stall_o : std_logic;
  signal led_lock_i  : std_logic;
  signal led_err_o   : std_logic;
  signal led_rty_o   : std_logic;

  signal pmod_mic_adr_i   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal pmod_mic_dat_i   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal pmod_mic_dat_o   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal pmod_mic_stb_i   : std_logic;
  signal pmod_mic_cyc_i   : std_logic;
  signal pmod_mic_we_i    : std_logic;
  signal pmod_mic_sel_i   : std_logic_vector(3 downto 0);
  signal pmod_mic_cti_i   : std_logic_vector(2 downto 0);
  signal pmod_mic_bte_i   : std_logic_vector(1 downto 0);
  signal pmod_mic_ack_o   : std_logic;
  signal pmod_mic_stall_o : std_logic;
  signal pmod_mic_lock_i  : std_logic;
  signal pmod_mic_err_o   : std_logic;
  signal pmod_mic_rty_o   : std_logic;


  signal data_uart_adr_i   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal data_uart_dat_i   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal data_uart_dat_o   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal data_uart_stb_i   : std_logic;
  signal data_uart_cyc_i   : std_logic;
  signal data_uart_we_i    : std_logic;
  signal data_uart_sel_i   : std_logic_vector(3 downto 0);
  signal data_uart_cti_i   : std_logic_vector(2 downto 0);
  signal data_uart_bte_i   : std_logic_vector(1 downto 0);
  signal data_uart_ack_o   : std_logic;
  signal data_uart_stall_o : std_logic;
  signal data_uart_lock_i  : std_logic;
  signal data_uart_err_o   : std_logic;
  signal data_uart_rty_o   : std_logic;

  signal data_ram_adr_i   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal data_ram_dat_i   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal data_ram_dat_o   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal data_ram_stb_i   : std_logic;
  signal data_ram_cyc_i   : std_logic;
  signal data_ram_we_i    : std_logic;
  signal data_ram_sel_i   : std_logic_vector(3 downto 0);
  signal data_ram_cti_i   : std_logic_vector(2 downto 0);
  signal data_ram_bte_i   : std_logic_vector(1 downto 0);
  signal data_ram_ack_o   : std_logic;
  signal data_ram_lock_i  : std_logic;
  signal data_ram_stall_o : std_logic;
  signal data_ram_err_o   : std_logic;
  signal data_ram_rty_o   : std_logic;

  signal led_pio_out      : std_logic_vector(REGISTER_SIZE-1 downto 0);
  type data_port_choice_t is (RAM_CHOICE, LED_CHOICE, UART_CHOICE);
  signal data_port_choice : data_port_choice_t;

  constant DEBUG_ENABLE  : boolean := false;
  signal debug_en        : std_logic;
  signal debug_write     : std_logic;
  signal debug_writedata : std_logic_vector(7 downto 0);
  signal debug_address   : std_logic_vector(7 downto 0);

  signal serial_in  : std_logic;
  signal rxrdy_n    : std_logic;
  signal cts_n      : std_logic;
  signal serial_out : std_logic;
  signal txrdy_n    : std_logic;
  signal rts_n      : std_logic;
  signal dir_n      : std_logic;


  signal uart_adr_i     : std_logic_vector(7 downto 0);
  signal uart_dat_i     : std_logic_vector(15 downto 0);
  signal uart_dat_o     : std_logic_vector(15 downto 0);
  signal uart_data_32   : std_logic_vector(31 downto 0);
  signal uart_stb_i     : std_logic;
  signal uart_cyc_i     : std_logic;
  signal uart_we_i      : std_logic;
  signal uart_sel_i     : std_logic_vector(3 downto 0);
  signal uart_cti_i     : std_logic_vector(2 downto 0);
  signal uart_bte_i     : std_logic_vector(1 downto 0);
  signal uart_ack_o     : std_logic;
  signal uart_interrupt : std_logic;
  signal uart_debug_ack : std_logic;

  constant UART_ADDR_DAT         : std_logic_vector(7 downto 0) := "00000000";
  constant UART_ADDR_LSR         : std_logic_vector(7 downto 0) := "00000011";
  constant UART_LSR_8BIT_DEFAULT : std_logic_vector(7 downto 0) := "00000011";
  signal uart_stall              : std_logic;
  signal mem_instr_stall         : std_logic;
  signal mem_instr_ack           : std_logic;

  signal rgb_led     : std_logic_vector(2 downto 0);
  signal red_led     : std_logic;
  signal green_led   : std_logic;
  signal blue_led    : std_logic;
  signal coe_to_host : std_logic_vector(31 downto 0);
  signal hp_pwm      : std_logic;

  constant SYSCLK_FREQ_HZ         : natural                                     := 12000000;
  constant HEARTBEAT_COUNTER_BITS : positive                                    := log2(SYSCLK_FREQ_HZ);  -- ~1 second to roll over
  signal heartbeat_counter        : unsigned(HEARTBEAT_COUNTER_BITS-1 downto 0) := (others => '0');

  constant MICS    : natural := 2;
  signal mic_sdata : std_logic_vector(MICS-1 downto 0);
  signal mic_sclk  : std_logic_vector(MICS-1 downto 0);
  signal mic_cs_n  : std_logic_vector(MICS-1 downto 0);


  alias mic0_cs_n  : std_logic is mic0_pmod(0);  --pmod(0)
  alias mic0_nc    : std_logic is mic0_pmod(1);  --not connected
  alias mic0_sdata : std_logic is mic0_pmod(2);  --pmod(2)
  alias mic0_sclk  : std_logic is mic0_pmod(3);  --pmod(3)

  alias mic1_cs_n  : std_logic is mic1_pmod(0);  --pmod(0)
  alias mic1_nc    : std_logic is mic1_pmod(1);  --not connected
  alias mic1_sdata : std_logic is mic1_pmod(2);  --pmod(2)
  alias mic1_sclk  : std_logic is mic1_pmod(3);  --pmod(3)


begin


  reset <= not reset_btn;

  mem : component wb_ram
    generic map(
      SIZE             => RAM_SIZE,
      INIT_FILE_FORMAT => "hex",
      INIT_FILE_NAME   => "test.mem",
      LATTICE_FAMILY   => "iCE5LP")
    port map(
      CLK_I => clk,
      RST_I => reset,

      ADR_I  => RAM_ADR_I,
      DAT_I  => RAM_DAT_I,
      WE_I   => RAM_WE_I,
      CYC_I  => RAM_CYC_I,
      STB_I  => RAM_STB_I,
      SEL_I  => RAM_SEL_I,
      CTI_I  => RAM_CTI_I,
      BTE_I  => RAM_BTE_I,
      LOCK_I => RAM_LOCK_I,

      STALL_O => RAM_STALL_O,
      DAT_O   => RAM_DAT_O,
      ACK_O   => RAM_ACK_O,
      ERR_O   => RAM_ERR_O,
      RTY_O   => RAM_RTY_O);


  arbiter : component wb_arbiter
    port map (
      CLK_I => clk,
      RST_I => reset,

      slave1_ADR_I  => data_ram_ADR_I,
      slave1_DAT_I  => data_ram_DAT_I,
      slave1_WE_I   => data_ram_WE_I,
      slave1_CYC_I  => data_ram_CYC_I,
      slave1_STB_I  => data_ram_STB_I,
      slave1_SEL_I  => data_ram_SEL_I,
      slave1_CTI_I  => data_ram_CTI_I,
      slave1_BTE_I  => data_ram_BTE_I,
      slave1_LOCK_I => data_ram_LOCK_I,

      slave1_STALL_O => data_ram_STALL_O,
      slave1_DAT_O   => data_ram_DAT_O,
      slave1_ACK_O   => data_ram_ack_O,
--      slave1_ERR_O   => data_ERR_I,
--      slave1_RTY_O   => data_RTY_I,

      slave2_ADR_I  => instr_ADR_O,
      slave2_DAT_I  => instr_DAT_O,
      slave2_WE_I   => instr_WE_O,
      slave2_CYC_I  => instr_CYC_O,
      slave2_STB_I  => instr_STB_O,
      slave2_SEL_I  => instr_SEL_O,
      slave2_CTI_I  => instr_CTI_O,
      slave2_BTE_I  => instr_BTE_O,
      slave2_LOCK_I => instr_LOCK_O,

      slave2_STALL_O => mem_instr_stall,
      slave2_DAT_O   => instr_DAT_I,
      slave2_ACK_O   => mem_instr_ACK,
      slave2_ERR_O   => instr_ERR_I,
      slave2_RTY_O   => instr_RTY_I,

      master_ADR_O  => RAM_ADR_I,
      master_DAT_O  => RAM_DAT_I,
      master_WE_O   => RAM_WE_I,
      master_CYC_O  => RAM_CYC_I,
      master_STB_O  => RAM_STB_I,
      master_SEL_O  => RAM_SEL_I,
      master_CTI_O  => RAM_CTI_I,
      master_BTE_O  => RAM_BTE_I,
      master_LOCK_O => RAM_LOCK_I,

      master_STALL_I => ram_STALL_O,
      master_DAT_I   => RAM_DAT_O,
      master_ACK_I   => RAM_ACK_O,
      master_ERR_I   => RAM_ERR_O,
      master_RTY_I   => RAM_RTY_O);

  rv : component riscV_wishbone
    generic map (
      MULTIPLY_ENABLE => 0,
      SHIFTER_SINGLE_CYCLE => 1)
    port map(

      clk   => clk,
      reset => reset,

      --conduit end point
      coe_to_host   => coe_to_host,
      coe_from_host => (others => '0'),

      data_ADR_O   => data_ADR_O,
      data_DAT_I   => data_DAT_I,
      data_DAT_O   => data_DAT_O,
      data_WE_O    => data_WE_O,
      data_SEL_O   => data_SEL_O,
      data_STB_O   => data_STB_O,
      data_ACK_I   => data_ACK_I,
      data_CYC_O   => data_CYC_O,
      data_STALL_I => data_STALL_I,
      data_CTI_O   => data_CTI_O,

      instr_ADR_O   => instr_ADR_O,
      instr_DAT_I   => instr_DAT_I,
      instr_DAT_O   => instr_DAT_O,
      instr_WE_O    => instr_WE_O,
      instr_SEL_O   => instr_SEL_O,
      instr_STB_O   => instr_STB_O,
      instr_ACK_I   => instr_ACK_I,
      instr_CYC_O   => instr_CYC_O,
      instr_CTI_O   => instr_CTI_O,
      instr_STALL_I => instr_STALL_I);

  data_BTE_O   <= "00";
  data_LOCK_O  <= '0';
  instr_BTE_O  <= "00";
  instr_LOCK_O <= '0';

  split_wb_data : component wb_splitter
    generic map(
      master0_address => (16#00000000#, RAM_SIZE),  --RAM
      master1_address => (16#00010000#, 4*1024),    --led
      master2_address => (16#00020000#, 4*1024),    --uart
      master3_address => (16#00030000#, 4*1024))    --pmod
    port map(
      clk_i => clk,
      rst_i => reset,

      slave_ADR_I   => data_ADR_O,
      slave_DAT_I   => data_DAT_O,
      slave_WE_I    => data_WE_O,
      slave_CYC_I   => data_CYC_O,
      slave_STB_I   => data_STB_O,
      slave_SEL_I   => data_SEL_O,
      slave_CTI_I   => data_CTI_O,
      slave_BTE_I   => data_BTE_O,
      slave_LOCK_I  => data_LOCK_O,
      slave_STALL_O => data_STALL_I,
      slave_DAT_O   => data_DAT_I,
      slave_ACK_O   => data_ACK_I,
      slave_ERR_O   => data_ERR_I,
      slave_RTY_O   => data_RTY_I,

      master0_ADR_O   => data_ram_ADR_I,
      master0_DAT_O   => data_ram_DAT_I,
      master0_WE_O    => data_ram_WE_I,
      master0_CYC_O   => data_ram_CYC_I,
      master0_STB_O   => data_ram_STB_I,
      master0_SEL_O   => data_ram_SEL_I,
      master0_CTI_O   => data_ram_CTI_I,
      master0_BTE_O   => data_ram_BTE_I,
      master0_LOCK_O  => data_ram_LOCK_I,
      master0_STALL_I => data_ram_STALL_O,
      master0_DAT_I   => data_ram_DAT_O,
      master0_ACK_I   => data_ram_ACK_O,
      master0_ERR_I   => data_ram_ERR_O,
      master0_RTY_I   => data_ram_RTY_O,

      master1_ADR_O   => led_ADR_I,
      master1_DAT_O   => led_DAT_I,
      master1_WE_O    => led_WE_I,
      master1_CYC_O   => led_CYC_I,
      master1_STB_O   => led_STB_I,
      master1_SEL_O   => led_SEL_I,
      master1_CTI_O   => led_CTI_I,
      master1_BTE_O   => led_BTE_I,
      master1_LOCK_O  => led_LOCK_I,
      master1_STALL_I => led_STALL_O,

      master1_DAT_I => led_DAT_O,
      master1_ACK_I => led_ACK_O,
      master1_ERR_I => led_ERR_O,
      master1_RTY_I => led_RTY_O,


      master2_ADR_O   => data_uart_ADR_I,
      master2_DAT_O   => data_uart_DAT_I,
      master2_WE_O    => data_uart_WE_I,
      master2_CYC_O   => data_uart_CYC_I,
      master2_STB_O   => data_uart_STB_I,
      master2_SEL_O   => data_uart_SEL_I,
      master2_CTI_O   => data_uart_CTI_I,
      master2_BTE_O   => data_uart_BTE_I,
      master2_LOCK_O  => data_uart_LOCK_I,
      master2_STALL_I => data_uart_STALL_O,
      master2_DAT_I   => data_uart_DAT_O,
      master2_ACK_I   => data_uart_ACK_O,
      master2_ERR_I   => data_uart_ERR_O,
      master2_RTY_I   => data_uart_RTY_O,

      master3_ADR_O   => pmod_mic_ADR_I,
      master3_DAT_O   => pmod_mic_DAT_I,
      master3_WE_O    => pmod_mic_WE_I,
      master3_CYC_O   => pmod_mic_CYC_I,
      master3_STB_O   => pmod_mic_STB_I,
      master3_SEL_O   => pmod_mic_SEL_I,
      master3_CTI_O   => pmod_mic_CTI_I,
      master3_BTE_O   => pmod_mic_BTE_I,
      master3_LOCK_O  => pmod_mic_LOCK_I,
      master3_STALL_I => pmod_mic_STALL_O,
      master3_DAT_I   => pmod_mic_DAT_O,
      master3_ACK_I   => pmod_mic_ACK_O,
      master3_ERR_I   => pmod_mic_ERR_O,
      master3_RTY_I   => pmod_mic_RTY_O);


  instr_stall_i <= uart_stall or mem_instr_stall;
  instr_ack_i   <= not uart_stall and mem_instr_ack;

  led_pio : component wb_pio
    port map(
      CLK_I => clk,
      RST_I => reset,

      ADR_I   => led_ADR_I,
      DAT_I   => led_DAT_I,
      WE_I    => led_WE_I,
      CYC_I   => led_CYC_I,
      STB_I   => led_STB_I,
      SEL_I   => led_SEL_I,
      CTI_I   => led_CTI_I,
      BTE_I   => led_BTE_I,
      LOCK_I  => led_LOCK_I,
      ACK_O   => led_ACK_O,
      STALL_O => led_STALL_O,
      DATA_O  => led_DAT_O,
      ERR_O   => led_ERR_O,
      RTY_O   => led_RTY_O,
      output  => led_pio_out);

  pmod_mic : component pmod_mic_wb
    generic map(
      PORTS          => MICS,
      CLK_FREQ_HZ    => SYSCLK_FREQ_HZ,
      SAMPLE_RATE_HZ => 44100           --44.1kHz
      )
    port map(
      clk           => clk,
      reset         => reset,
      sdata         => mic_sdata,
      sclk          => mic_sclk,
      cs_n          => mic_cs_n,
      pmodmic_adr_i => pmod_mic_ADR_I(7 downto 0),
      pmodmic_dat_i => pmod_mic_DAT_I(15 downto 0),
      pmodmic_dat_o => pmod_mic_DAT_O(15 downto 0),
      pmodmic_stb_i => pmod_mic_STB_I,
      pmodmic_cyc_i => pmod_mic_CYC_I,
      pmodmic_we_i  => pmod_mic_WE_I,
      pmodmic_sel_i => pmod_mic_SEL_I,
      pmodmic_cti_i => pmod_mic_CTI_I,
      pmodmic_bte_i => pmod_mic_BTE_I,
      pmodmic_ack_o => pmod_mic_ACK_O);
  pmod_mic_STALL_O <= not pmod_mic_ACK_O;

  mic0_pmod(0) <= mic_cs_n(0);
  mic0_pmod(1) <= 'Z';
  mic0_pmod(2) <= 'Z';
  mic_sdata(0) <= mic0_pmod(2);
  mic0_pmod(3) <= mic_sclk(0);

  mic1_pmod(0) <= mic_cs_n(1);
  mic1_pmod(1) <= 'Z';
  mic1_pmod(2) <= 'Z';
  mic_sdata(1) <= mic1_pmod(2);
  mic1_pmod(3) <= mic_sclk(1);


-----------------------------------------------------------------------------
-- Debugging logic (PC over UART)
-----------------------------------------------------------------------------
  debug_gen : if DEBUG_ENABLE generate
    signal last_valid_address : std_logic_vector(31 downto 0);
    signal last_valid_data    : std_logic_vector(31 downto 0);
    type debug_state_type is (INIT, IDLE, SPACE, ADR, DAT, CR, LF);
    signal debug_state        : debug_state_type;
    signal debug_count        : unsigned(log2((last_valid_data'length+3)/4)-1 downto 0);
    signal debug_wait         : std_logic;

    --Convert a hex digit to ASCII for outputting on the UART
    function to_ascii_hex (
      signal hex_in : std_logic_vector)
      return std_logic_vector is
    begin
      if unsigned(hex_in) > to_unsigned(9, hex_in'length) then
        --value + 'A' - 10
        return std_logic_vector(resize(unsigned(hex_in), 8) + to_unsigned(55, 8));
      end if;

      --value + '0'
      return std_logic_vector(resize(unsigned(hex_in), 8) + to_unsigned(48, 8));
    end to_ascii_hex;


  begin
    process (clk)
    begin  -- process
      if clk'event and clk = '1' then   -- rising clock edge
        case debug_state is
          when INIT =>
            debug_address   <= UART_ADDR_LSR;
            debug_writedata <= UART_LSR_8BIT_DEFAULT;
            debug_write     <= '1';
            if debug_write = '1' and debug_wait = '0' then
              debug_state   <= IDLE;
              debug_address <= UART_ADDR_DAT;
              debug_write   <= '0';
            end if;
          when IDLE =>
            uart_stall <= '1';
            if instr_CYC_O = '1' then
              debug_write        <= '1';
              last_valid_address <= instr_ADR_O(instr_ADR_O'left-4 downto 0) & "0000";
              debug_writedata    <= to_ascii_hex(instr_ADR_O(last_valid_address'left downto last_valid_address'left-3));
              debug_state        <= ADR;
              debug_count        <= to_unsigned(0, debug_count'length);
            end if;
          when ADR =>
            if debug_wait = '0' then
              if debug_count = to_unsigned(((last_valid_address'length+3)/4)-1, debug_count'length) then
                debug_writedata <= std_logic_vector(to_unsigned(32, 8));
                debug_count     <= to_unsigned(0, debug_count'length);
                debug_state     <= SPACE;
                last_valid_data <= instr_DAT_I;
              else
                debug_writedata    <= to_ascii_hex(last_valid_address(last_valid_address'left downto last_valid_address'left-3));
                last_valid_address <= last_valid_address(last_valid_address'left-4 downto 0) & "0000";
                debug_count        <= debug_count + to_unsigned(1, debug_count'length);
              end if;
            end if;
          when SPACE =>
            if debug_wait = '0' then
              debug_writedata <= to_ascii_hex(last_valid_data(last_valid_data'left downto last_valid_data'left-3));
              last_valid_data <= last_valid_data(last_valid_data'left-4 downto 0) & "0000";
              debug_state     <= DAT;
            end if;
          when DAT =>
            if debug_wait = '0' then
              if debug_count = to_unsigned(((last_valid_data'length+3)/4)-1, debug_count'length) then
                debug_writedata <= std_logic_vector(to_unsigned(13, 8));
                debug_count     <= to_unsigned(0, debug_count'length);
                debug_state     <= CR;
              else
                debug_writedata <= to_ascii_hex(last_valid_data(last_valid_data'left downto last_valid_data'left-3));
                last_valid_data <= last_valid_data(last_valid_data'left-4 downto 0) & "0000";
                debug_count     <= debug_count + to_unsigned(1, debug_count'length);
              end if;
            end if;

          when CR =>
            if debug_wait = '0' then
              debug_writedata <= std_logic_vector(to_unsigned(10, 8));
              debug_state     <= LF;
            end if;
          when LF =>
            if debug_wait = '0' then
              debug_write <= '0';
              debug_state <= IDLE;
              uart_stall  <= '0';
            end if;

          when others =>
            debug_state <= IDLE;
        end case;

        if reset = '1' then
          debug_state <= INIT;
          debug_write <= '0';
          uart_stall  <= '1';
        end if;
      end if;
    end process;
    debug_wait <= not uart_ack_o;
  end generate debug_gen;
  no_debug_gen : if not DEBUG_ENABLE generate
    debug_write     <= '0';
    debug_writedata <= (others => '0');
    debug_address   <= (others => '0');
    uart_stall      <= '0';
  end generate no_debug_gen;

  -----------------------------------------------------------------------------
  -- UART signals and interface
  -----------------------------------------------------------------------------
  --PmodUSBUART (0->RTS, 1->RXD, 2->TXD, 3->CTS)
  cts_n     <= cts ;
  txd       <= serial_out;
  serial_in <= rxd;
  rts       <= rts_n;

  the_uart : uart_core
    generic map (
      CLK_IN_MHZ => (SYSCLK_FREQ_HZ+500000)/1000000,
      BAUD_RATE  => 115200,
      ADDRWIDTH  => 3,
      DATAWIDTH  => 8,
      MODEM_B    => false,              --true by default...
      FIFO       => false
      )
    port map (
                                        -- Global reset and clock
      CLK        => clk,
      RESET      => reset,
                                        -- WISHBONE interface
      UART_ADR_I => uart_adr_i,
      UART_DAT_I => uart_dat_i,
      UART_DAT_O => uart_dat_o,
      UART_STB_I => uart_stb_i,
      UART_CYC_I => uart_cyc_i,
      UART_WE_I  => uart_we_i,
      UART_SEL_I => uart_sel_i,
      UART_CTI_I => uart_cti_i,
      UART_BTE_I => uart_bte_i,
      UART_ACK_O => uart_ack_o,
      INTR       => uart_interrupt,
                                        -- Receiver interface
      SIN        => serial_in,
      RXRDY_N    => rxrdy_n,
                                        -- MODEM
      DCD_N      => '1',
      CTS_N      => cts_n,
      DSR_N      => '1',
      RI_N       => '1',
      DTR_N      => dir_n,
      RTS_N      => rts_n,
                                        -- Transmitter interface
      SOUT       => serial_out,
      TXRDY_N    => txrdy_n
      );


                                        -----------------------------------------------------------------------------
                                        --
                                        -----------------------------------------------------------------------------
  uart_pc : if DEBUG_ENABLE generate
  begin
    uart_dat_i(15 downto 8) <= (others => '0');
    uart_dat_i(7 downto 0)  <= debug_writedata;
    uart_we_i               <= debug_write;

    uart_stb_i <= uart_we_i and (not txrdy_n);
    uart_adr_i <= debug_address;
    uart_cyc_i <= uart_stb_i and (not txrdy_n);

    uart_cti_i <= WB_CTI_CLASSIC;

                                        --constant ack to the riscv port
    data_uart_ack_o   <= '1';
    data_uart_stall_o <= not data_uart_ack_O;
  end generate uart_pc;
  uart_data_bus : if not DEBUG_ENABLE generate
  begin
    uart_adr_i        <= data_uart_adr_i(9 downto 2);
    uart_dat_i        <= data_uart_dat_i(15 downto 0);
    data_uart_dat_o   <= x"0000" & uart_dat_o(15 downto 0);
    uart_stb_i        <= data_uart_stb_i;
    uart_cyc_i        <= data_uart_cyc_i;
    uart_we_i         <= data_uart_we_i;
    uart_sel_i        <= data_uart_sel_i;
    uart_cti_i        <= data_uart_cti_i;
    uart_bte_i        <= data_uart_bte_i;
    data_uart_ack_o   <= uart_ack_o;
    data_uart_stall_o <= not data_uart_ack_O;
  end generate uart_data_bus;

-------------------------------------------------------------------------------
-- LED and HEARTBEAT
-------------------------------------------------------------------------------

  rgb_led <=
    "111" when reset = '1' and heartbeat_counter(6 downto 0) = "0000001" else
    red_led & green_led & blue_led;

  red_led   <= '1' when unsigned(led_pio_out(23 downto 16)) > heartbeat_counter(7 downto 0) else '0';
  green_led <= '1' when unsigned(led_pio_out(15 downto 8)) > heartbeat_counter(7 downto 0)  else '0';
  blue_led  <= '1' when unsigned(led_pio_out(7 downto 0)) > heartbeat_counter(7 downto 0)   else '0';

  led_out <= led_pio_out(26 downto 24);

  led : component my_led
    port map(
      red_i   => rgb_led(2),
      green_i => rgb_led(1),
      blue_i  => rgb_led(0),
      hp_i    => hp_pwm,
      red     => R_LED,
      green   => G_LED,
      blue    => B_LED,
      hp      => HP_LED
      );

  hp_pwm <= heartbeat_counter(heartbeat_counter'left) when heartbeat_counter(7 downto 0) = "00000001" else '0';

  process(clk, reset)
  begin
    if rising_edge(clk) then
      heartbeat_counter <= heartbeat_counter + to_unsigned(1, heartbeat_counter'length);
    end if;
  end process;



end architecture rtl;
