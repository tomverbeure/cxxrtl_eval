library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.all;
library work;
use work.utils.all;


entity shifter is

  generic (
    REGISTER_SIZE : natural;
    SINGLE_CYCLE  : natural range 0 to 2
    );
  port(
    clk           : in  std_logic;
    shift_amt     : in  unsigned(log2(REGISTER_SIZE)-1 downto 0);
    shifted_value : in  signed(REGISTER_SIZE downto 0);
    left_result   : out unsigned(REGISTER_SIZE-1 downto 0);
    right_result  : out unsigned(REGISTER_SIZE-1 downto 0);
    enable        : in  std_logic;
    done          : out std_logic);
end entity shifter;

architecture rtl of shifter is

  constant SHIFT_AMT_SIZE : natural := shift_amt'length;
  signal left_tmp         : signed(REGISTER_SIZE downto 0);
  signal right_tmp        : signed(REGISTER_SIZE downto 0);
begin  -- architecture rtl
  cycle1 : if SINGLE_CYCLE = 0 generate
    left_tmp  <= SHIFT_LEFT(shifted_value, to_integer(shift_amt));
    right_tmp <= SHIFT_RIGHT(shifted_value, to_integer(shift_amt));
    done      <= '1';
  end generate cycle1;

  cycle4N : if SINGLE_CYCLE = 2 generate

    signal left_nxt   : signed(REGISTER_SIZE downto 0);
    signal right_nxt  : signed(REGISTER_SIZE downto 0);
    signal count      : unsigned(SHIFT_AMT_SIZE downto 0);
    signal count_next : unsigned(SHIFT_AMT_SIZE downto 0);
    signal count_sub4 : unsigned(SHIFT_AMT_SIZE downto 0);
    signal shift4     : std_logic;
    type state_t is (start, running, fini);
    signal state      : state_t := start;

  begin
    count_sub4 <= count -4;
    shift4     <= not count_sub4(count_sub4'left);
    count_next <= count_sub4                when shift4 = '1' else count -1;
    left_nxt   <= SHIFT_LEFT(left_tmp, 4)   when shift4 = '1' else SHIFT_LEFT(left_tmp, 1);
    right_nxt  <= SHIFT_RIGHT(right_tmp, 4) when shift4 = '1' else SHIFT_RIGHT(right_tmp, 1);

    process(clk)
    begin
      if rising_edge(clk) then
        case state is
          when start =>
            done <= '0';
            if enable = '1' then
              left_tmp  <= shifted_value;
              right_tmp <= shifted_value;
              count     <= unsigned("0"&shift_amt);
              if shift_amt /= 0 then
                state <= running;
              else
                state <= fini;
                done  <= '1';
              end if;
            end if;
          when running =>
            assert enable = '1' report "enable went low during shift" severity error;
            left_tmp  <= left_nxt;
            right_tmp <= right_nxt;
            count     <= count_next;
            if count = 1 or count = 4 then
              done  <= '1';
              state <= fini;
            end if;
          when others =>
            state <= start;
            done  <= '0';
        end case;
      end if;
    end process;

  end generate cycle4N;

  cycle1N : if SINGLE_CYCLE = 1 generate

    signal left_nxt  : signed(REGISTER_SIZE downto 0);
    signal right_nxt : signed(REGISTER_SIZE downto 0);
    signal count     : signed(SHIFT_AMT_SIZE-1 downto 0);
    type state_t is (start, running, fini);
    signal state     : state_t;
  begin
    left_nxt  <= SHIFT_LEFT(left_tmp, 1);
    right_nxt <= SHIFT_RIGHT(right_tmp, 1);
    process(clk)
    begin
      if rising_edge(clk) then
        case state is
          when start =>
            done <= '0';
            if enable = '1' then
              left_tmp  <= shifted_value;
              right_tmp <= shifted_value;
              count     <= signed(shift_amt);
              if shift_amt /= 0 then
                state <= running;
              else
                state <= fini;
                done  <= '1';
              end if;
            end if;
          when running =>
            assert enable = '1' report "enable went low during shift" severity error;
            left_tmp  <= left_nxt;
            right_tmp <= right_nxt;
            count     <= count -1;
            if count = 1 then
              done  <= '1';
              state <= fini;
            end if;
          when fini =>
            done  <= '0';
            state <= start;
          when others =>
            state <= start;
        end case;
      end if;
    end process;

  end generate cycle1N;

  right_result <= unsigned(right_tmp(REGISTER_SIZE-1 downto 0));
  left_result  <= unsigned(left_tmp(REGISTER_SIZE-1 downto 0));

end architecture rtl;


library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.all;
library work;
use work.utils.all;


entity operand_creation is
  generic (
    REGISTER_SIZE          : natural;
    INSTRUCTION_SIZE       : natural;
    SIGN_EXTENSION_SIZE    : natural;
    SHIFTER_USE_MULTIPLIER : boolean
    );
  port(
    rs1_data         : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
    rs2_data         : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
    instruction      : in     std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    sign_extension   : in     std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);
    data1            : buffer unsigned(REGISTER_SIZE-1 downto 0);
    data2            : buffer unsigned(REGISTER_SIZE-1 downto 0);
    sub              : out    signed(REGISTER_SIZE downto 0);
    shifter_multiply : buffer signed(REGISTER_SIZE downto 0);
    shift_amt        : buffer unsigned(log2(REGISTER_SIZE)-1 downto 0);
    shifted_value    : buffer signed(REGISTER_SIZE downto 0);
    mult_srca        : out    signed(REGISTER_SIZE downto 0);
    mult_srcb        : out    signed(REGISTER_SIZE downto 0);
    div_op1          : out    unsigned(REGISTER_SIZE-1 downto 0);
    div_op2          : out    unsigned(REGISTER_SIZE-1 downto 0);
    div_neg_op1      : buffer std_logic;
    div_neg_op2      : buffer std_logic
    );
end entity;

architecture rtl of operand_creation is
  constant MUL_F7 : std_logic_vector(6 downto 0) := "0000001";

  signal is_immediate    : std_logic;
  signal immediate_value : unsigned(REGISTER_SIZE-1 downto 0);
  signal op1             : signed(REGISTER_SIZE downto 0);
  signal op2             : signed(REGISTER_SIZE downto 0);

  signal m_op1_msk : std_logic;
  signal m_op2_msk : std_logic;
  signal m_op1     : signed(REGISTER_SIZE downto 0);
  signal m_op2     : signed(REGISTER_SIZE downto 0);
  signal mult_dest : signed((REGISTER_SIZE+1)*2-1 downto 0);

  signal unsigned_div : std_logic;

  signal op1_msb : std_logic;
  signal op2_msb : std_logic;

  signal is_add : boolean;

  alias func3 : std_logic_vector(2 downto 0) is instruction(14 downto 12);
  alias func7 : std_logic_vector(6 downto 0) is instruction(31 downto 25);

  constant OP_IMM_IMMEDIATE_SIZE : integer := 12;

begin  -- architecture rtl
  is_immediate <= not instruction(5);
  immediate_value <= unsigned(sign_extension(REGISTER_SIZE-OP_IMM_IMMEDIATE_SIZE-1 downto 0)&
                              instruction(31 downto 20));
  data1     <= unsigned(rs1_data);
  data2     <= unsigned(rs2_data)                              when is_immediate = '0' else immediate_value;
  shift_amt <= unsigned(data2(log2(REGISTER_SIZE)-1 downto 0)) when not SHIFTER_USE_MULTIPLIER else
               unsigned(data2(log2(REGISTER_SIZE)-1 downto 0)) when instruction(14) = '0'else
               32-unsigned(data2(log2(REGISTER_SIZE)-1 downto 0));

  shifted_value <= signed((instruction(30) and rs1_data(rs1_data'left)) & rs1_data);

--combine slt
  with instruction(14 downto 12) select
    op1_msb <=
    '0'               when "110",
    '0'               when "111",
    '0'               when "011",
    data1(data1'left) when others;
  with instruction(14 downto 12) select
    op2_msb <=
    '0'               when "110",
    '0'               when "111",
    '0'               when "011",
    data2(data1'left) when others;

  op1 <= signed(op1_msb & data1);
  op2 <= signed(op2_msb & data2);

  with instruction(6 downto 5) select
    is_add <=
    instruction(14 downto 12) = "000"                           when "00",
    instruction(14 downto 12) = "000" and instruction(30) = '0' when "01",
    false                                                       when others;
  sub <= op1+op2 when is_add else op1 - op2;


  shifter_multiply <=
    "0"&x"00000001" when shift_amt = x"00"else
    "0"&x"00000002" when shift_amt = x"01"else
    "0"&x"00000004" when shift_amt = x"02"else
    "0"&x"00000008" when shift_amt = x"03"else
    "0"&x"00000010" when shift_amt = x"04"else
    "0"&x"00000020" when shift_amt = x"05"else
    "0"&x"00000040" when shift_amt = x"06"else
    "0"&x"00000080" when shift_amt = x"07"else
    "0"&x"00000100" when shift_amt = x"08"else
    "0"&x"00000200" when shift_amt = x"09"else
    "0"&x"00000400" when shift_amt = x"0A"else
    "0"&x"00000800" when shift_amt = x"0B"else
    "0"&x"00001000" when shift_amt = x"0C"else
    "0"&x"00002000" when shift_amt = x"0D"else
    "0"&x"00004000" when shift_amt = x"0E"else
    "0"&x"00008000" when shift_amt = x"0F"else
    "0"&x"00010000" when shift_amt = x"10"else
    "0"&x"00020000" when shift_amt = x"11"else
    "0"&x"00040000" when shift_amt = x"12"else
    "0"&x"00080000" when shift_amt = x"13"else
    "0"&x"00100000" when shift_amt = x"14"else
    "0"&x"00200000" when shift_amt = x"15"else
    "0"&x"00400000" when shift_amt = x"16"else
    "0"&x"00800000" when shift_amt = x"17"else
    "0"&x"01000000" when shift_amt = x"18"else
    "0"&x"02000000" when shift_amt = x"19"else
    "0"&x"04000000" when shift_amt = x"1A"else
    "0"&x"08000000" when shift_amt = x"1B"else
    "0"&x"10000000" when shift_amt = x"1C"else
    "0"&x"20000000" when shift_amt = x"1D"else
    "0"&x"40000000" when shift_amt = x"1E"else
    "0"&x"80000000";

  m_op1_msk <= '0' when instruction(13 downto 12) = "11" else '1';
  m_op2_msk <= not instruction(13);
  m_op1     <= signed((m_op1_msk and rs1_data(data1'left)) & data1);
  m_op2     <= signed((m_op2_msk and rs2_data(data2'left)) & data2);

  mult_srca <= signed(m_op1) when func7 = mul_f7 or not SHIFTER_USE_MULTIPLIER else shifter_multiply;
  mult_srcb <= signed(m_op2) when func7 = mul_f7 or not SHIFTER_USE_MULTIPLIER else shifted_value;


  unsigned_div <= instruction(12);
  div_neg_op1  <= not unsigned_div when signed(rs1_data) < 0 else '0';
  div_neg_op2  <= not unsigned_div when signed(rs2_data) < 0 else '0';


  div_op1 <= unsigned(rs1_data) when div_neg_op1 = '0' else unsigned(-signed(rs1_data));
  div_op2 <= unsigned(rs2_data) when div_neg_op2 = '0' else unsigned(-signed(rs2_data));

end architecture rtl;


library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.all;
library work;
use work.utils.all;


entity divider is
  generic (
    REGISTER_SIZE : natural
    );
  port(
    clk         : in  std_logic;
    enable      : in  boolean;
    numerator   : in  unsigned(REGISTER_SIZE-1 downto 0);
    denominator : in  unsigned(REGISTER_SIZE-1 downto 0);
    quotient    : out unsigned(REGISTER_SIZE-1 downto 0);
    remainder   : out unsigned(REGISTER_SIZE-1 downto 0);
    done        : out std_logic
    );
end entity;

architecture rtl of divider is
  type FSM_state is (START, DIVIDING, FINISH);
  signal state : FSM_state := FINISH;
  signal count : natural range REGISTER_SIZE-1 downto 0;

begin  -- architecture rtl

  div_proc : process(clk)
    alias D        : unsigned(REGISTER_SIZE-1 downto 0) is denominator;
    variable N     : unsigned(REGISTER_SIZE-1 downto 0);
    variable R     : unsigned(REGISTER_SIZE-1 downto 0);
    variable Q     : unsigned(REGISTER_SIZE-1 downto 0);
    variable sub   : unsigned(REGISTER_SIZE downto 0);
    variable Q_lsb : std_logic;
  begin

    if RISING_EDGE(clk) then
      case state is
        when START =>

          if enable then
            R     := (others => '0');
            N     := numerator;
            state <= DIVIDING;
            count <= Q'length - 1;
          end if;
        when DIVIDING =>
          assert enable report "enable went low during divide" severity error;
          R(REGISTER_SIZE-1 downto 1) := R(REGISTER_SIZE-2 downto 0);
          R(0)                        := N(N'left);
          N                           := SHIFT_LEFT(N, 1);

          Q_lsb := '0';
          sub   := ("0"&R)-("0"&D);
          if sub(sub'left) = '0' then
            R     := sub(R'range);
            Q_lsb := '1';
          end if;
          Q := Q(Q'left-1 downto 0) & Q_lsb;
          if count /= 0 then
            count <= count - 1;
          else
            done  <= '1';
            state <= FINISH;
          end if;
        when FINISH =>
          done  <= '0';
          state <= START;
      end case;
      remainder <= R;
      quotient  <= Q;

    end if;  -- clk
  end process;

end architecture rtl;

library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.all;
library work;
use work.utils.all;
--use IEEE.std_logic_arith.all;

entity arithmetic_unit is

  generic (
    INSTRUCTION_SIZE     : integer;
    REGISTER_SIZE        : integer;
    SIGN_EXTENSION_SIZE  : integer;
    MULTIPLY_ENABLE      : boolean;
    DIVIDE_ENABLE        : boolean;
    SHIFTER_SINGLE_CYCLE : natural range 0 to 2);

  port (
    clk               : in  std_logic;
    stall_in          : in  std_logic;
    valid             : in  std_logic;
    rs1_data          : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    rs2_data          : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    instruction       : in  std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    sign_extension    : in  std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);
    program_counter   : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    data_out          : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    data_enable       : out std_logic;
    illegal_alu_instr : out std_logic;
    less_than         : out std_logic;
    stall_out         : out std_logic
    );

end entity arithmetic_unit;

architecture rtl of arithmetic_unit is

  constant SHIFTER_USE_MULTIPLIER : boolean := MULTIPLY_ENABLE;
  constant SHIFT_SC               : natural := conditional(SHIFTER_USE_MULTIPLIER,0, SHIFTER_SINGLE_CYCLE);

  --op codes
  constant OP     : std_logic_vector(6 downto 0) := "0110011";
  constant OP_IMM : std_logic_vector(6 downto 0) := "0010011";
  constant LUI    : std_logic_vector(6 downto 0) := "0110111";
  constant AUIPC  : std_logic_vector(6 downto 0) := "0010111";


  constant MUL_OP    : std_logic_vector(2 downto 0) := "000";
  constant MULH_OP   : std_logic_vector(2 downto 0) := "001";
  constant MULHSU_OP : std_logic_vector(2 downto 0) := "010";
  constant MULHU_OP  : std_logic_vector(2 downto 0) := "011";
  constant DIV_OP    : std_logic_vector(2 downto 0) := "100";
  constant DIVU_OP   : std_logic_vector(2 downto 0) := "101";
  constant REM_OP    : std_logic_vector(2 downto 0) := "110";
  constant REMU_OP   : std_logic_vector(2 downto 0) := "111";

  constant ADD_OP  : std_logic_vector(2 downto 0) := "000";
  constant SLL_OP  : std_logic_vector(2 downto 0) := "001";
  constant SLT_OP  : std_logic_vector(2 downto 0) := "010";
  constant SLTU_OP : std_logic_vector(2 downto 0) := "011";
  constant XOR_OP  : std_logic_vector(2 downto 0) := "100";
  constant SR_OP   : std_logic_vector(2 downto 0) := "101";
  constant OR_OP   : std_logic_vector(2 downto 0) := "110";
  constant AND_OP  : std_logic_vector(2 downto 0) := "111";
  constant MUL_F7  : std_logic_vector(6 downto 0) := "0000001";

  constant UP_IMM_IMMEDIATE_SIZE : integer := 20;

  alias func3  : std_logic_vector(2 downto 0) is instruction(14 downto 12);
  alias func7  : std_logic_vector(6 downto 0) is instruction(31 downto 25);
  alias opcode : std_logic_vector(6 downto 0) is instruction(6 downto 0);

  signal data1            : unsigned(REGISTER_SIZE-1 downto 0);
  signal data2            : unsigned(REGISTER_SIZE-1 downto 0);
  signal data_result      : unsigned(REGISTER_SIZE-1 downto 0);
  signal shifter_multiply : signed(REGISTER_SIZE downto 0);


  signal shift_amt       : unsigned(log2(REGISTER_SIZE)-1 downto 0);
  signal shifted_value   : signed(REGISTER_SIZE downto 0);
  signal rshifted_result : unsigned(REGISTER_SIZE-1 downto 0);
  signal lshifted_result : unsigned(REGISTER_SIZE-1 downto 0);
  signal sub             : signed(REGISTER_SIZE downto 0);
  signal slt_val         : unsigned(REGISTER_SIZE-1 downto 0);

  signal upp_imm_sel      : std_logic;
  signal upper_immediate1 : signed(REGISTER_SIZE-1 downto 0);
  signal upper_immediate  : signed(REGISTER_SIZE-1 downto 0);


  signal mult_srca : signed(REGISTER_SIZE downto 0);
  signal mult_srcb : signed(REGISTER_SIZE downto 0);

  signal mult_dest : signed((REGISTER_SIZE+1)*2-1 downto 0);
  signal mul_en    : std_logic;
  signal mul_done  : std_logic;
  signal mul_stall : std_logic;

  signal div_op1    : unsigned(REGISTER_SIZE-1 downto 0);
  signal div_op2    : unsigned(REGISTER_SIZE-1 downto 0);
  signal div_result : signed(REGISTER_SIZE-1 downto 0);
  signal rem_result : signed(REGISTER_SIZE-1 downto 0);
  signal quotient   : unsigned(REGISTER_SIZE-1 downto 0);
  signal remainder  : unsigned(REGISTER_SIZE-1 downto 0);

                                        --min signed value
  signal min_s : std_logic_vector(REGISTER_SIZE-1 downto 0);

  signal zero : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal neg1 : std_logic_vector(REGISTER_SIZE-1 downto 0);

  signal div_neg     : std_logic;
  signal div_neg_op1 : std_logic;
  signal div_neg_op2 : std_logic;
  signal div_done    : std_logic;
  signal div_stall   : std_logic;

  signal div_en       : boolean;
  signal div_zero     : boolean;
  signal div_overflow : boolean;

  signal sh_stall  : std_logic;
  signal sh_enable : std_logic;
  signal sh_done   : std_logic;

  component shifter is
    generic (
      REGISTER_SIZE : natural;
      SINGLE_CYCLE  : natural
      );
    port(
      clk           : in  std_logic;
      shift_amt     : in  unsigned(log2(REGISTER_SIZE)-1 downto 0);
      shifted_value : in  signed(REGISTER_SIZE downto 0);
      left_result   : out unsigned(REGISTER_SIZE-1 downto 0);
      right_result  : out unsigned(REGISTER_SIZE-1 downto 0);
      enable        : in  std_logic;
      done          : out std_logic);
  end component shifter;
  component divider is
    generic (
      REGISTER_SIZE : natural
      );
    port(
      clk         : in std_logic;
      enable      : in boolean;
      numerator   : in unsigned(REGISTER_SIZE-1 downto 0);
      denominator : in unsigned(REGISTER_SIZE-1 downto 0);

      quotient  : out unsigned(REGISTER_SIZE-1 downto 0);
      remainder : out unsigned(REGISTER_SIZE-1 downto 0);
      done      : out std_logic
      );
  end component;


  component operand_creation is
    generic (
      REGISTER_SIZE          : natural;
      SIGN_EXTENSION_SIZE    : natural;
      INSTRUCTION_SIZE       : natural;
      SHIFTER_USE_MULTIPLIER : boolean
      );
    port(
      rs1_data         : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
      rs2_data         : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
      instruction      : in     std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
      sign_extension   : in     std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);
      data1            : out    unsigned(REGISTER_SIZE-1 downto 0);
      data2            : out    unsigned(REGISTER_SIZE-1 downto 0);
      sub              : out    signed(REGISTER_SIZE downto 0);
      shifter_multiply : buffer signed(REGISTER_SIZE downto 0);
      shift_amt        : buffer unsigned(log2(REGISTER_SIZE)-1 downto 0);
      shifted_value    : buffer signed(REGISTER_SIZE downto 0);
      mult_srca        : out    signed(REGISTER_SIZE downto 0);
      mult_srcb        : out    signed(REGISTER_SIZE downto 0);
      div_op1          : out    unsigned(REGISTER_SIZE-1 downto 0);
      div_op2          : out    unsigned(REGISTER_SIZE-1 downto 0);
      div_neg_op1      : out    std_logic;
      div_neg_op2      : out    std_logic
      );
  end component;

begin  -- architecture rtl

  oc : component operand_creation
    generic map (
      REGISTER_SIZE          => REGISTER_SIZE,
      SIGN_EXTENSION_SIZE    => SIGN_EXTENSION_SIZE,
      SHIFTER_USE_MULTIPLIER => SHIFTER_USE_MULTIPLIER,
      INSTRUCTION_SIZE       => INSTRUCTION_SIZE)
    port map (
      rs1_data         => rs1_data,
      rs2_data         => rs2_data,
      instruction      => instruction,
      sign_extension   => sign_extension,
      data1            => data1,
      data2            => data2,
      sub              => sub,
      shifter_multiply => shifter_multiply,
      shift_amt        => shift_amt,
      shifted_value    => shifted_value,
      mult_srca        => mult_srca,
      mult_srcb        => mult_srcb,
      div_op1          => div_op1,
      div_op2          => div_op2,
      div_neg_op1      => div_neg_op1,
      div_neg_op2      => div_neg_op2
      );


  sh_enable <= valid       when (opcode = OP or opcode = OP_IMM) and (func3 = "001" or func3 = "101") else '0';
  sh_stall  <= not sh_done when sh_enable = '1'                                                       else '0';
  sh : component shifter
    generic map (
      REGiSTER_SIZE => REGISTER_SIZE,
      SINGLE_CYCLE  => SHIFT_SC)
    port map (
      clk           => clk,
      shift_amt     => shift_amt,
      shifted_value => shifted_value,
      left_result   => lshifted_result,
      right_result  => rshifted_result,
      enable        => sh_enable,
      done          => sh_done
      );

  less_than <= sub(sub'left);
--combine slt
  slt_val   <= to_unsigned(1, REGISTER_SIZE) when sub(sub'left) = '1' else to_unsigned(0, REGISTER_SIZE);

  upper_immediate(31 downto 12) <= signed(instruction(31 downto 12));
  upper_immediate(11 downto 0)  <= (others => '0');


  alu_proc : process(clk) is
    variable func        : std_logic_vector(2 downto 0);
    variable mul_result  : unsigned(REGISTER_SIZE-1 downto 0);
    variable base_result : unsigned(REGISTER_SIZE-1 downto 0);
    variable subtract    : std_logic;
  begin
    if rising_edge(clk) then
      func     := instruction(14 downto 12);
      subtract := instruction(30) and instruction(5);
      case func is
        when ADD_OP =>
          base_result := unsigned(sub(REGISTER_SIZE-1 downto 0));
        when SLL_OP =>
          if SHIFTER_USE_MULTIPLIER then
            base_result := unsigned(mult_dest(REGISTER_SIZE-1 downto 0));
          else
            base_result := lshifted_result;
          end if;

        when SLT_OP =>
          base_result := slt_val;
        when SLTU_OP =>
          base_result := slt_val;
        when XOR_OP =>
          base_result := data1 xor data2;
        when SR_OP =>
          if SHIFTER_USE_MULTIPLIER then
            if shift_amt = x"00" then
              base_result := unsigned(shifted_value(REGISTER_SIZE-1 downto 0));
            else
              base_result := unsigned(mult_dest(REGISTER_SIZE*2-1 downto REGISTER_SIZE));
            end if;
          else
            base_result := rshifted_result;
          end if;
        when OR_OP =>
          base_result := data1 or data2;
        when AND_OP =>
          base_result := data1 and data2;
        when others => null;
      end case;
      case func is
        when MUL_OP =>
          mul_result := unsigned(mult_dest(REGISTER_SIZE-1 downto 0));
        when MULH_OP=>
          mul_result := unsigned(mult_dest(REGISTER_SIZE*2-1 downto REGISTER_SIZE));
        when MULHSU_OP =>
          mul_result := unsigned(mult_dest(REGISTER_SIZE*2-1 downto REGISTER_SIZE));
        when MULHU_OP =>
          mul_result := unsigned(mult_dest(REGISTER_SIZE*2-1 downto REGISTER_SIZE));
        when DIV_OP =>
          if div_zero then
            mul_result := unsigned(neg1);
          elsif div_overflow then
            mul_result := unsigned(min_s);
          else
            mul_result := unsigned(div_result);
          end if;
        when DIVU_OP =>
          if div_zero then
                                        --this conforms with test, not standard
            mul_result := unsigned(neg1);
          else
            mul_result := unsigned(div_result);
          end if;
        when REM_OP =>
          if div_zero then
            mul_result := unsigned(rs1_data);
          elsif div_overflow then
            mul_result := unsigned(zero);
          else
            mul_result := unsigned(rem_result);
          end if;
        when others =>
          if div_zero then
            mul_result := unsigned(rs1_data);
          else
            mul_result := unsigned(rem_result);
          end if;
      end case;

      if stall_in = '0' then
        case OPCODE is
          when OP =>
            data_enable <= valid;
            if func7 = mul_f7 and MULTIPLY_ENABLE then
              data_out <= std_logic_vector(mul_result);
            else
              data_out <= std_logic_vector(base_result);
            end if;
          when OP_IMM =>
            data_enable <= valid;
            data_out    <= std_logic_vector(base_result);
          when LUI =>
            data_enable <= valid;
            data_out    <= std_logic_vector(upper_immediate);
          when AUIPC =>
            data_enable <= valid;
            data_out    <= std_logic_vector(upper_immediate + signed(program_counter));
          when others =>
            data_enable <= '0';
            data_out    <= (others => 'X');
        end case;
      end if;
    end if;  --clock
  end process;

  mul_en    <= '1' when func7 = mul_f7 and opcode = OP and instruction(14) = '0' else '0';
  mul_stall <= valid and (mul_en or sh_enable)and not mul_done;
  process(clk)
  begin
    if rising_edge(clk) then
      mul_done  <= mul_stall;
      mult_dest <= mult_srca * mult_srcb;
    end if;
  end process;
--min signed value
  min_s(min_s'left)            <= '1';
  min_s(min_s'left-1 downto 0) <= (others => '0');
  zero                         <= (others => '0');
  neg1                         <= (others => '1');

  d_en : if DIVIDE_ENABLE generate
  begin
    div_zero     <= rs2_data = zero;
    div_overflow <= rs1_data = min_s and rs2_data = neg1;
    div_en       <= (func7 = mul_f7 and opcode = OP and instruction(14) = '1')and not div_zero and valid = '1';
    div : component divider
      generic map (
        REGISTER_SIZE => REGISTER_SIZE)
      port map (
        clk         => clk,
        enable      => div_en,
        numerator   => div_op1,
        denominator => div_op2,
        quotient    => quotient,
        remainder   => remainder,
        done        => div_done);

    div_neg    <= div_neg_op1 xor div_neg_op2;
    div_result <= signed(quotient)  when div_neg = '0'     else -signed(quotient);
    rem_result <= signed(remainder) when div_neg_op1 = '0' else -signed(remainder);

    div_stall <= not div_done when div_en else '0';

  end generate d_en;
  nd_en : if not DIVIDE_ENABLE generate
  begin
    div_zero     <= false;
    div_overflow <= false;
    div_stall    <= '0';
    div_result   <= (others => 'X');
    rem_result   <= (others => 'X');

  end generate;
  stall_out <= '1' when ((div_stall = '1' and DIVIDE_ENABLE) or
                         (mul_stall = '1' and MULTIPLY_ENABLE) or
                         (sh_stall = '1'))
               else '0';

  illegal_alu_instr <= '0' when (instruction(31 downto 25) = "0000000" or
                                 (instruction(31 downto 25) = "0100000" and (instruction(14 downto 12) = "101" or
                                                                             instruction(14 downto 12) = "000"))or
                                 (instruction(31 downto 25) = "0000001" and MULTIPLY_ENABLE and (instruction(14) = '0' or DIVIDE_ENABLE)))

                       else '1';
end architecture;
